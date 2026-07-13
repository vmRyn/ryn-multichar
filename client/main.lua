local isOpen = false
local hidePedThreadActive = false
local relogExpected = false
local relogExpectedAt = 0
local openGen = 0

local function shutdownLoadingScreen()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

local function resetSpawnSelectState()
    Spawn.selectMode = false
    Spawn.citizenid = nil
    Spawn.previewGen = (Spawn.previewGen or 0) + 1
end

local function startPlayerPedHideLoop()
    if hidePedThreadActive then return end
    hidePedThreadActive = true

    CreateThread(function()
        while isOpen do
            if not Creation.customizing then
                Scene.KeepPlayerPedHidden()
            end
            Wait(0)
        end
        hidePedThreadActive = false
    end)
end

local function prepareCharacterSelect()
    lib.callback.await('ryn-multichar:server:prepareCharacterSelect', false)
end

local function fadeOutForSelect()
    if IsScreenFadedOut() then return end
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
end

local function teardownCharacterSelect()
    resetSpawnSelectState()
    Photo.Disable()
    SetNuiFocus(false, false)
    Camera.Deactivate()
    Preview.Cleanup()
    Scene.Unload()
    SendNUIMessage({ action = 'close' })
end

local function closeCharacterSelect()
    if not isOpen then
        resetSpawnSelectState()
        return
    end
    openGen = openGen + 1
    isOpen = false
    teardownCharacterSelect()
end

local function openCharacterSelect()
    if isOpen then return false end

    openGen = openGen + 1
    local gen = openGen
    isOpen = true
    resetSpawnSelectState()

    local function aborted()
        return gen ~= openGen
    end

    local ok, err = pcall(function()
        pcall(function() exports.spawnmanager:setAutoSpawn(false) end)

        fadeOutForSelect()
        if aborted() then return end

        prepareCharacterSelect()
        if aborted() then return end

        Scene.Load()
        if aborted() then return end

        startPlayerPedHideLoop()

        local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
        if aborted() then return end

        Preview.SpawnAll(characters or {}, 1)
        if aborted() then return end

        Camera.Activate(1)
        if aborted() then return end

        DoScreenFadeIn(500)
        if aborted() then return end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            screen = 'characterSelect',
            data = {
                theme = Config.UI,
                creationFields = Config.CreationFields,
                characters = characters,
                slotLimit = slotLimit,
                features = Scene.GetFeaturesForNui(),
                posePresets = Scene.GetPosePresetsForNui(),
                scenePresets = Scene.GetScenePresetsForNui(),
                activeScene = Scene.GetActiveId(),
                nameFilter = Config.NameFilter,
            },
        })

        if aborted() then return end
    end)

    if not ok then
        isOpen = false
        openGen = openGen + 1
        teardownCharacterSelect()
        if IsScreenFadedOut() then
            DoScreenFadeIn(500)
        end
        print(('^1[ryn-multichar] Failed to open character select: %s^0'):format(err))
        return false
    end

    if aborted() then
        -- closeCharacterSelect may have cleaned already; ensure no leftover UI/cams.
        isOpen = false
        teardownCharacterSelect()
        return false
    end

    return true
end

local function clearRelogExpected()
    relogExpected = false
    relogExpectedAt = 0
end

local function relogToCharacterSelect()
    CreateThread(function()
        resetSpawnSelectState()

        if isOpen then
            closeCharacterSelect()
            Wait(100)
        end

        fadeOutForSelect()
        isOpen = false

        local opened = openCharacterSelect()
        clearRelogExpected()

        if not opened then
            isOpen = false
            print('^1[ryn-multichar] Relog failed to reopen character select^0')
            if IsScreenFadedOut() then
                DoScreenFadeIn(500)
            end
        end
    end)
end

local function isRelogExpected()
    if not relogExpected then return false end
    if relogExpectedAt > 0 and (GetGameTimer() - relogExpectedAt) > 10000 then
        clearRelogExpected()
        return false
    end
    return true
end

RegisterNetEvent('ryn-multichar:client:open', function()
    openCharacterSelect()
end)

RegisterNetEvent('ryn-multichar:client:prepareRelog', function()
    relogExpected = true
    relogExpectedAt = GetGameTimer()
end)

RegisterNetEvent('ryn-multichar:client:relog', function()
    relogToCharacterSelect()
end)

RegisterNetEvent('ryn-multichar:client:close', function()
    closeCharacterSelect()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end
    if isRelogExpected() or isOpen then return end
    openCharacterSelect()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if GetInvokingResource() then return end
    if isRelogExpected() or isOpen then return end
    if Bridge.name == 'qb' then
        openCharacterSelect()
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    if GetInvokingResource() then return end
    if isRelogExpected() or isOpen then return end
    if Bridge.name == 'esx' then
        openCharacterSelect()
    end
end)

RegisterNetEvent('ryn-multichar:client:openAdmin', function()
    local allowed = lib.callback.await('ryn-multichar:server:admin:canOpen', false)
    if not allowed then return end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdmin',
    })
end)

exports('OpenCharacterSelect', openCharacterSelect)
exports('CloseCharacterSelect', closeCharacterSelect)

exports('OpenSpawnSelector', function(characterData)
    local citizenid = type(characterData) == 'table' and characterData.citizenid or characterData
    if not citizenid then
        print('^1[ryn-multichar] OpenSpawnSelector requires a citizenid^0')
        return
    end

    Spawn.citizenid = citizenid
    local locations = Spawn.GetAvailableLocations(citizenid)
    Spawn.EnterSelectMode(locations)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        screen = 'spawnSelect',
        data = {
            theme = Config.UI,
            features = Scene.GetFeaturesForNui(),
            posePresets = Scene.GetPosePresetsForNui(),
            scenePresets = Scene.GetScenePresetsForNui(),
            activeScene = Scene.GetActiveId(),
            locations = locations,
            citizenid = citizenid,
            nameFilter = Config.NameFilter,
        },
    })
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(0) end

    shutdownLoadingScreen()

    while not Bridge.name do Wait(100) end
    Wait(500)

    if not openCharacterSelect() then
        print('^1[ryn-multichar] Failed to open character select on join^0')
        shutdownLoadingScreen()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeCharacterSelect()
end)
