local isOpen = false
local hidePedThreadActive = false
local relogExpected = false
local openGen = 0

local function shutdownLoadingScreen()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
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

local function closeCharacterSelect()
    if not isOpen then return end
    openGen = openGen + 1
    isOpen = false

    Photo.Disable()
    SetNuiFocus(false, false)
    Camera.Deactivate()
    Preview.Cleanup()
    Scene.Unload()

    SendNUIMessage({ action = 'close' })
end

local function openCharacterSelect()
    if isOpen then return false end

    openGen = openGen + 1
    local gen = openGen
    isOpen = true

    local ok, err = pcall(function()
        pcall(function() exports.spawnmanager:setAutoSpawn(false) end)

        fadeOutForSelect()
        if gen ~= openGen then return end

        prepareCharacterSelect()
        if gen ~= openGen then return end

        Scene.Load()
        if gen ~= openGen then return end

        startPlayerPedHideLoop()

        local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
        if gen ~= openGen then return end

        Preview.SpawnAll(characters or {}, 1)
        Camera.Activate(1)

        DoScreenFadeIn(500)

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
            },
        })
    end)

    if not ok then
        isOpen = false
        SetNuiFocus(false, false)
        if IsScreenFadedOut() then
            DoScreenFadeIn(500)
        end
        print(('^1[ryn-multichar] Failed to open character select: %s^0'):format(err))
        return false
    end

    if gen ~= openGen then
        isOpen = false
        return false
    end

    return true
end

local function relogToCharacterSelect()
    CreateThread(function()
        if isOpen then
            closeCharacterSelect()
            Wait(100)
        end

        fadeOutForSelect()
        isOpen = false

        local opened = openCharacterSelect()
        relogExpected = false

        if not opened then
            isOpen = false
            print('^1[ryn-multichar] Relog failed to reopen character select^0')
            if IsScreenFadedOut() then
                DoScreenFadeIn(500)
            end
        end
    end)
end

RegisterNetEvent('ryn-multichar:client:open', function()
    openCharacterSelect()
end)

RegisterNetEvent('ryn-multichar:client:prepareRelog', function()
    relogExpected = true
end)

RegisterNetEvent('ryn-multichar:client:relog', function()
    relogToCharacterSelect()
end)

RegisterNetEvent('ryn-multichar:client:close', function()
    closeCharacterSelect()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end
    if relogExpected or isOpen then return end
    openCharacterSelect()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if GetInvokingResource() then return end
    if relogExpected or isOpen then return end
    if Bridge.name == 'qb' then
        openCharacterSelect()
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    if GetInvokingResource() then return end
    if relogExpected or isOpen then return end
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
exports('OpenSpawnSelector', function(characterData)
    SendNUIMessage({
        action = 'open',
        screen = 'spawnSelect',
        data = characterData,
    })
    SetNuiFocus(true, true)
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
