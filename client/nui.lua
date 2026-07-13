RegisterNUICallback('close', function(_, cb)
    local ok = pcall(function()
        exports[GetCurrentResourceName()]:CloseCharacterSelect()
    end)
    if not ok then
        TriggerEvent('ryn-multichar:client:close')
    end
    cb('ok')
end)

RegisterNUICallback('getCharacters', function(_, cb)
    -- Data only — do not respawn preview peds (that caused a dark flash + hid warmed slots).
    local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
    if characters then
        Preview.characters = characters
    end
    cb({ characters = characters, slotLimit = slotLimit })
end)

RegisterNUICallback('selectSlot', function(data, cb)
    cb('ok')

    local slotIndex = tonumber(data and data.slotIndex) or 1
    CreateThread(function()
        Photo.SetSlot(slotIndex)
        Preview.SwitchSlot(slotIndex)
    end)
end)

RegisterNUICallback('previewSpawn', function(data, cb)
    if data and data.coords then
        Spawn.PreviewLocation(data.coords)
    end
    cb('ok')
end)

RegisterNUICallback('photoMode', function(data, cb)
    if data.enabled then
        local slotIndex = tonumber(data.slotIndex) or Preview.activeSlot or 1
        -- Do not auto-swap scenes on open — that caused black screens when the
        -- saved scene IPL was still streaming. Photo UI picks the saved sceneId;
        -- the player switches explicitly via the scene dropdown.
        Photo.Enable(slotIndex)
        SendNUIMessage({
            action = 'photoMode',
            enabled = true,
            activeScene = Config.ActiveScene,
        })
        cb({ success = true, active = Photo.active, activeScene = Config.ActiveScene })
        return
    end

    Photo.Disable()
    if IsScreenFadedOut() then
        DoScreenFadeIn(200)
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'photoMode', enabled = false, activeScene = Config.ActiveScene })
    cb({ success = true, active = Photo.active, activeScene = Config.ActiveScene })
end)

RegisterNUICallback('photoModeInput', function(data, cb)
    Photo.Adjust(data or {})
    cb('ok')
end)

RegisterNUICallback('photoModeReset', function(_, cb)
    Photo.Reset()
    cb('ok')
end)

RegisterNUICallback('setScene', function(data, cb)
    local sceneId = data and data.sceneId
    local slotIndex = tonumber(data and data.slotIndex) or Preview.activeSlot or 1
    local ok = Scene.SwitchPreset(sceneId, slotIndex)
    cb({ success = ok, activeScene = Config.ActiveScene })
end)

RegisterNUICallback('previewPose', function(data, cb)
    if data and data.citizenid and data.poseId then
        local sceneData = {
            poseId = data.poseId,
            sceneId = data.sceneId,
        }
        Preview.UpdateCharacterPose(data.citizenid, sceneData)
    end
    cb('ok')
end)

RegisterNUICallback('saveScenePose', function(data, cb)
    local result = lib.callback.await('ryn-multichar:server:saveScenePose', false, data)
    if result and result.success and result.scene_data then
        Preview.UpdateCharacterPose(data.citizenid, result.scene_data)
    end
    cb(result or { success = false })
end)

RegisterNUICallback('playCharacter', function(data, cb)
    Photo.Disable()
    local success = lib.callback.await('ryn-multichar:server:loadCharacter', false, data.citizenid)
    if success then
        Spawn.citizenid = data.citizenid
        SetNuiFocus(true, true)
        local locations = Spawn.GetAvailableLocations(data.citizenid)
        Spawn.EnterSelectMode(locations)
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
                citizenid = data.citizenid,
                nameFilter = Config.NameFilter,
            },
        })
    end
    cb({ success = success })
end)

RegisterNUICallback('cancelSpawn', function(_, cb)
    Spawn.selectMode = false
    Spawn.citizenid = nil
    Creation.ReturnToCharacterSelect(Preview.activeSlot or Spawn.activeSlot or 1)
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    local result = lib.callback.await('ryn-multichar:server:deleteCharacter', false, data)
    local success = type(result) == 'table' and result.success or result == true

    if success then
        local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
        Preview.SpawnAll(characters or {}, Preview.activeSlot or 1)
        cb({ success = true, characters = characters, slotLimit = slotLimit })
        return
    end

    cb(result or { success = false, error = 'delete_failed' })
end)

local ERROR_LOCALE_KEYS = {
    slot_limit_reached = 'slot_limit_reached',
    create_failed = 'error_create_failed',
    no_license = 'error_no_license',
    slot_taken = 'error_slot_taken',
    not_found = 'error_not_found',
    delete_failed = 'error_delete_failed',
    no_framework = 'error_no_framework',
    invalid_data = 'error_invalid_data',
    not_pending = 'error_not_pending',
    name_mismatch = 'error_name_mismatch',
    name_blocked = 'error_name_blocked',
}

local function localeError(code)
    if not code then return L('error_create_failed') end
    local key = ERROR_LOCALE_KEYS[code] or code
    local message = L(key)
    if message == key then
        return L('error_create_failed')
    end
    return message
end

RegisterNUICallback('createCharacter', function(data, cb)
    -- Drop focus + hide UI immediately so a slow Login / appearance handoff
    -- can never leave the creation form frozen and untouchable.
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close', immediate = true })

    local character, err = lib.callback.await('ryn-multichar:server:createCharacter', false, data)
    if character then
        cb({ success = true, pending = true })
        Creation.StartAppearance(character)
        return
    end

    local errorCode = err or 'create_failed'
    cb({ success = false, error = errorCode })

    lib.notify({
        title = 'ryn-multichar',
        description = localeError(errorCode),
        type = 'error',
    })

    -- Restore the creation form so the player isn't stuck.
    Wait(100)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        screen = 'creation',
        data = {
            slotIndex = data and data.slotIndex or 1,
            fields = Config.CreationFields,
            nameFilter = Config.NameFilter,
            error = errorCode,
        },
    })
end)

RegisterNUICallback('selectSpawn', function(data, cb)
    local success = lib.callback.await('ryn-multichar:server:selectSpawn', false, data)
    -- Teardown + appearance apply happen in spawnSelected / TeleportTo
    if success then
        -- Hide NUI (and clear toasts) before releasing focus — CEF freezes timers after.
        SendNUIMessage({ action = 'close', immediate = true })
        SetNuiFocus(false, false)
    end
    cb({ success = success })
end)

RegisterNUICallback('openCreation', function(data, cb)
    Creation.Open(data.slotIndex)
    cb('ok')
end)

RegisterNUICallback('adminListEntries', function(data, cb)
    local entries = lib.callback.await('ryn-multichar:server:admin:listEntries', false, data and data.search)
    cb({ entries = entries or {} })
end)

RegisterNUICallback('adminGetOnlinePlayers', function(_, cb)
    local players = lib.callback.await('ryn-multichar:server:admin:getOnlinePlayers', false)
    cb({ players = players or {} })
end)

RegisterNUICallback('adminSetEntry', function(data, cb)
    local result = lib.callback.await('ryn-multichar:server:admin:setEntry', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('adminDeleteEntry', function(data, cb)
    local result = lib.callback.await('ryn-multichar:server:admin:deleteEntry', false, data.license)
    cb(result or { success = false })
end)

RegisterNUICallback('adminClose', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdmin' })
    cb('ok')
end)
