local isOpen = false

local function shutdownLoadingScreen()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

local function openCharacterSelect()
    if isOpen then return end
    isOpen = true

    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)

    Scene.Load()

    local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
    Preview.SpawnAll(characters or {})
    Preview.FocusSlot(1)

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
end

local function closeCharacterSelect()
    if not isOpen then return end
    isOpen = false

    Photo.Disable()
    SetNuiFocus(false, false)
    Camera.Deactivate()
    Preview.Cleanup()
    Scene.Unload()

    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('ryn-multichar:client:open', function()
    openCharacterSelect()
end)

RegisterNetEvent('ryn-multichar:client:close', function()
    closeCharacterSelect()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end
    openCharacterSelect()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if GetInvokingResource() then return end
    if Bridge.name == 'qb' then
        openCharacterSelect()
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    if GetInvokingResource() then return end
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
    openCharacterSelect()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeCharacterSelect()
end)
