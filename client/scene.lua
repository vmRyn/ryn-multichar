Scene = {
    loaded = false,
    syncActive = false,
    weatherPaused = false,
}

local function getSceneWeather()
    if Config.SceneSync.weather then return Config.SceneSync.weather end
    return Config.Scene.weather
end

local function getSceneTime()
    if Config.SceneSync.time then return Config.SceneSync.time end
    return Config.Scene.time
end

local function applyWeather(weather)
    if not weather then return end
    SetWeatherTypePersist(weather)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
    SetRainLevel(0.0)
    ClearOverrideWeather()
    SetOverrideWeather(weather)
end

local function applyTime(timeConfig)
    if not timeConfig then return end
    NetworkOverrideClockTime(timeConfig.hour or 12, timeConfig.minute or 0, timeConfig.second or 0)
    if Config.SceneSync.freezeTime then
        PauseClock(true)
    end
end

local function pauseWeatherResources()
    if Scene.weatherPaused then return end

    for _, resource in ipairs(Config.SceneSync.weatherResources or {}) do
        if GetResourceState(resource) == 'started' then
            pcall(function() exports[resource]:setSyncEnabled(false) end)
            pcall(function() exports[resource]:SetSyncEnabled(false) end)
            pcall(function() exports[resource]:DisableSync() end)
        end
    end

    Scene.weatherPaused = true
end

local function resumeWeatherResources()
    if not Scene.weatherPaused then return end

    for _, resource in ipairs(Config.SceneSync.weatherResources or {}) do
        if GetResourceState(resource) == 'started' then
            pcall(function() exports[resource]:setSyncEnabled(true) end)
            pcall(function() exports[resource]:SetSyncEnabled(true) end)
            pcall(function() exports[resource]:EnableSync() end)
        end
    end

    Scene.weatherPaused = false
end

local function waitForCollision(coords, ped, timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 10000)
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        if ped and HasCollisionLoadedAroundEntity(ped) then
            return true
        end
        Wait(0)
    end
    return false
end

local function loadSceneWorld(scene)
    if scene.ipl then
        if GetResourceState('bob74_ipl') == 'started' and scene.ipl == 'apa_v_mp_h_01_a' then
            pcall(function()
                local apartment = exports['bob74_ipl']:GetExecApartment1Object()
                apartment.Enable(true)
                apartment.Style.Set(apartment.Style.Theme.modern, true)
            end)
        else
            RequestIpl(scene.ipl)
            local deadline = GetGameTimer() + 10000
            while not IsIplActive(scene.ipl) and GetGameTimer() < deadline do
                Wait(0)
            end
        end
    end

    local coords = scene.coords
    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

    NewLoadSceneStart(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z, 120.0, 0)
    local loadDeadline = GetGameTimer() + 10000
    while IsNewLoadSceneActive() and GetGameTimer() < loadDeadline do
        Wait(0)
    end
    NewLoadSceneStop()

    local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interior ~= 0 then
        PinInteriorInMemory(interior)
        RefreshInterior(interior)
        SetInteriorActive(interior, true)

        local readyDeadline = GetGameTimer() + 10000
        while not IsInteriorReady(interior) and GetGameTimer() < readyDeadline do
            PinInteriorInMemory(interior)
            RefreshInterior(interior)
            Wait(0)
        end
    end
end

function Scene.ApplyEnvironment()
    applyWeather(getSceneWeather())
    applyTime(getSceneTime())
end

function Scene.StartSyncLoop()
    if not Config.SceneSync.override or Scene.syncActive then return end
    Scene.syncActive = true

    if Config.SceneSync.override then
        pauseWeatherResources()
    end

    CreateThread(function()
        while Scene.loaded and Scene.syncActive do
            Scene.ApplyEnvironment()
            Wait(1000)
        end
    end)
end

function Scene.StopSyncLoop()
    Scene.syncActive = false
    PauseClock(false)
    ClearOverrideWeather()
    resumeWeatherResources()
end

function Scene.HidePlayerPed()
    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then return end

    SetEntityVisible(ped, false, false)
    SetEntityLocallyInvisible(ped)
    SetLocalPlayerVisibleLocally(false)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
end

function Scene.KeepPlayerPedHidden()
    if not Scene.loaded then return end

    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then return end

    Scene.HidePlayerPed()

    local scene = Config.Scene
    if scene and scene.coords then
        local pedCoords = GetEntityCoords(ped)
        if #(pedCoords - scene.coords) > 2.0 then
            SetEntityCoords(ped, scene.coords.x, scene.coords.y, scene.coords.z, false, false, false, false)
        end
    end
end

function Scene.Load()
    if Scene.loaded then return end

    local scene = Config.Scene
    loadSceneWorld(scene)
    Scene.ApplyEnvironment()

    local ped = cache.ped
    SetEntityCoords(ped, scene.coords.x, scene.coords.y, scene.coords.z, false, false, false, false)
    waitForCollision(scene.coords, ped, 10000)
    Scene.HidePlayerPed()

    NetworkStartSoloTutorialSession()
    while not NetworkIsInTutorialSession() do Wait(0) end

    DisplayRadar(false)
    SetFollowPedCamViewMode(0)

    if scene.lighting then
        SetArtificialLightsState(true)
    end

    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end

    Scene.loaded = true
    Scene.StartSyncLoop()
    Utils.Debug('Scene loaded:', scene.type)
end

function Scene.Unload()
    Scene.StopSyncLoop()

    local ped = cache.ped
    ResetEntityAlpha(ped)
    SetLocalPlayerVisibleLocally(true)
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)

    if Config.Scene.lighting then
        SetArtificialLightsState(false)
    end

    ClearFocus()
    NetworkEndTutorialSession()
    Scene.loaded = false
end

function Scene.RequestSlotCollision(slotIndex)
    if not Scene.loaded then return end

    local scene = Config.Scene
    local slot = scene.slots[slotIndex]
    if not slot then return end

    local sceneCoords = scene.coords
    local pedCoords = slot.ped

    SetFocusPosAndVel(sceneCoords.x, sceneCoords.y, sceneCoords.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(sceneCoords.x, sceneCoords.y, sceneCoords.z)
    RequestCollisionAtCoord(pedCoords.x, pedCoords.y, pedCoords.z)

    if slot.camera then
        RequestCollisionAtCoord(slot.camera.pos.x, slot.camera.pos.y, slot.camera.pos.z)
    end
end

-- Backwards-compatible alias (no blocking scene reload).
function Scene.EnsureStreamed(slotIndex)
    Scene.RequestSlotCollision(slotIndex)
end

function Scene.GetSlotCoords(slotIndex)
    local slot = Config.Scene.slots[slotIndex]
    return slot and slot.ped or nil
end

function Scene.GetSlotCamera(slotIndex)
    local slot = Config.Scene.slots[slotIndex]
    return slot and slot.camera or nil
end

function Scene.GetPosePresetsForNui()
    if not Config.ScenePoses.enabled then return {} end

    local presets = {}
    for id, preset in pairs(Config.ScenePoses.presets) do
        presets[#presets + 1] = {
            id = id,
            label = preset.label or id,
        }
    end

    table.sort(presets, function(a, b)
        return a.label < b.label
    end)

    return presets
end

function Scene.GetFeaturesForNui()
    return {
        photoMode = Config.PhotoMode.enabled,
        scenePoses = Config.ScenePoses.enabled,
    }
end
