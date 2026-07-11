Spawn = {
    activeSlot = 1,
    selectMode = false,
    previewGen = 0,
    citizenid = nil,
}

function Spawn.GetAvailableLocations(citizenid)
    return lib.callback.await('ryn-multichar:server:getSpawnLocations', false, citizenid) or {}
end

function Spawn.SetActiveSlot(slotIndex)
    Spawn.activeSlot = slotIndex or 1
end

function Spawn.ApplyPreviewEnvironment()
    -- Keep spawn previews stable: no blackout, fixed daytime, clear weather.
    -- Do not ClearOverrideWeather here — that briefly lets night/weather flash through.
    SetArtificialLightsState(false)
    NetworkOverrideClockTime(12, 0, 0)
    if PauseClock then PauseClock(true) end
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNowPersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')
    SetOverrideWeather('EXTRASUNNY')
    SetRainLevel(0.0)
end

local function startPreviewEnvironmentLoop()
    CreateThread(function()
        while Spawn.selectMode do
            Spawn.ApplyPreviewEnvironment()
            Wait(500)
        end
    end)
end

function Spawn.EnterSelectMode(locations)
    Spawn.selectMode = true
    Preview.Cleanup()

    -- Stop apartment scene time/weather from fighting outdoor spawn previews.
    Scene.StopSyncLoop()
    SetArtificialLightsState(false)
    ClearFocus()
    Spawn.ApplyPreviewEnvironment()
    startPreviewEnvironmentLoop()

    local first
    if locations then
        for _, location in ipairs(locations) do
            if location.coords then
                first = location
                break
            end
        end
    end

    if first and first.coords then
        Spawn.PreviewLocation(first.coords)
    end
end

function Spawn.PreviewLocation(coords)
    if not coords then return end

    local x = coords.x or coords[1]
    local y = coords.y or coords[2]
    local z = coords.z or coords[3]
    local w = coords.w or coords[4] or 0.0
    if not x or not y or not z then return end

    Spawn.previewGen = (Spawn.previewGen or 0) + 1
    local gen = Spawn.previewGen

    -- Move the camera immediately — never block on NewLoadScene (that caused lag + lighting flashes).
    Spawn.ApplyPreviewEnvironment()
    SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(x, y, z)
    Camera.PreviewCoords({ x = x, y = y, z = z, w = w })
    RenderScriptCams(true, false, 0, true, true)

    CreateThread(function()
        if not Spawn.selectMode or gen ~= Spawn.previewGen then return end

        local ped = cache.ped
        if ped and DoesEntityExist(ped) then
            SetEntityCoords(ped, x, y, z + 50.0, false, false, false, false)
            Scene.HidePlayerPed()
        end

        -- Soft stream in the background; cancel if the player picks another location.
        for _ = 1, 12 do
            if not Spawn.selectMode or gen ~= Spawn.previewGen then return end
            RequestCollisionAtCoord(x, y, z)
            Spawn.ApplyPreviewEnvironment()
            Wait(50)
        end
    end)
end

function Spawn.TriggerFrameworkLoaded()
    local adapter = Bridge.GetClient()
    if adapter and adapter.TriggerPlayerLoaded then
        adapter.TriggerPlayerLoaded()
        return
    end

    if Bridge.name == 'qbox' or Bridge.name == 'qb' then
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
    elseif Bridge.name == 'esx' then
        TriggerEvent('esx:playerLoaded', {})
    end
end

local function restorePlayerPed()
    local ped = PlayerPedId()
    if not ped or not DoesEntityExist(ped) then return ped end

    ResetEntityAlpha(ped)
    SetLocalPlayerVisibleLocally(true)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    return ped
end

local function isStoryPed(ped)
    if not ped or not DoesEntityExist(ped) then return true end
    local model = GetEntityModel(ped)
    return model == `player_zero` or model == `player_one` or model == `player_two`
end

function Spawn.TeleportTo(spawnData)
    if not spawnData or not spawnData.coords then return end

    Spawn.selectMode = false

    local coords = spawnData.coords
    local citizenid = spawnData.citizenid or Spawn.citizenid

    if not citizenid then
        print('^1[ryn-multichar] Spawn.TeleportTo missing citizenid — cannot apply appearance^0')
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    -- Tear down char-select scene before swapping the local player model.
    TriggerEvent('ryn-multichar:client:close')
    Wait(100)

    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
        local deadline = GetGameTimer() + 5000
        while NetworkIsInTutorialSession() and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    -- Character select uses a hidden story-mode ped + separate preview peds.
    -- Force freemode model + saved skin onto the local player before fade-in.
    if citizenid then
        Appearance.ApplyToLocalPlayer(citizenid)
    else
        -- Last resort: never leave the player as Michael.
        lib.requestModel(`mp_m_freemode_01`, 5000)
        SetPlayerModel(PlayerId(), `mp_m_freemode_01`)
        Wait(250)
        SetModelAsNoLongerNeeded(`mp_m_freemode_01`)
    end

    local ped = restorePlayerPed()

    SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, false)
    SetEntityHeading(ped, (coords.w or 0.0) + 0.0)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local collideDeadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < collideDeadline do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(0)
    end

    Spawn.TriggerFrameworkLoaded()

    -- Illenium/QB may re-apply skin on OnPlayerLoaded; if something reverted to a
    -- story ped, force freemode again.
    Wait(100)
    ped = PlayerPedId()
    if isStoryPed(ped) and citizenid then
        Appearance.ApplyToLocalPlayer(citizenid)
        ped = restorePlayerPed()
        SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, false)
        SetEntityHeading(ped, (coords.w or 0.0) + 0.0)
    end

    if spawnData.housingType == 'ps-housing' and spawnData.extra and spawnData.extra.propertyId then
        TriggerServerEvent('ps-housing:server:enterProperty', tostring(spawnData.extra.propertyId))
    elseif spawnData.housingType == 'qb-houses' and spawnData.extra and spawnData.extra.house then
        TriggerEvent('qb-houses:client:enterOwnedHouse', spawnData.extra.house)
    elseif spawnData.housingType == 'qb-apartments' and spawnData.extra and spawnData.extra.apartmentType then
        TriggerEvent('apartments:client:SetHomeBlip', spawnData.extra.apartmentType)
        TriggerEvent('qb-apartments:client:LastLocationHouse', spawnData.extra.apartmentType)
    end

    if Bridge.name == 'qbox' or Bridge.name == 'qb' then
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    end

    Wait(500)
    DoScreenFadeIn(500)
    DisplayRadar(true)
    Spawn.citizenid = nil
end

RegisterNetEvent('ryn-multichar:client:spawnSelected', function(spawnData)
    Spawn.selectMode = false
    Camera.Deactivate()
    Spawn.TeleportTo(spawnData)
end)
