RegisterNUICallback('close', function(_, cb)
    Photo.Disable()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getCharacters', function(_, cb)
    local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
    Preview.SpawnAll(characters or {})
    cb({ characters = characters, slotLimit = slotLimit })
end)

RegisterNUICallback('selectSlot', function(data, cb)
    Photo.SetSlot(data.slotIndex)

    local characters, _ = lib.callback.await('ryn-multichar:server:getCharacters', false)
    local character = nil

    for _, char in ipairs(characters or {}) do
        if (char.cid or char.slot) == data.slotIndex then
            character = char
            break
        end
    end

    if not character then
        character = characters and characters[data.slotIndex]
    end

    Preview.RefreshSlot(data.slotIndex, character)
    cb('ok')
end)

RegisterNUICallback('previewSpawn', function(data, cb)
    if data and data.coords then
        Spawn.PreviewLocation(data.coords)
    end
    cb('ok')
end)

RegisterNUICallback('photoMode', function(data, cb)
    if data.enabled then
        Photo.Enable(data.slotIndex)
    else
        Photo.Disable()
    end
    cb({ success = true, active = Photo.active })
end)

RegisterNUICallback('photoModeInput', function(data, cb)
    Photo.Adjust(data or {})
    cb('ok')
end)

RegisterNUICallback('photoModeReset', function(_, cb)
    Photo.Reset()
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
        SetNuiFocus(true, true)
        local locations = Spawn.GetAvailableLocations(data.citizenid)
        SendNUIMessage({
            action = 'open',
            screen = 'spawnSelect',
            data = {
                theme = Config.UI,
                features = Scene.GetFeaturesForNui(),
                posePresets = Scene.GetPosePresetsForNui(),
                locations = locations,
                citizenid = data.citizenid,
            },
        })
    end
    cb({ success = success })
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    local result = lib.callback.await('ryn-multichar:server:deleteCharacter', false, data)
    local success = type(result) == 'table' and result.success or result == true

    if success then
        local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
        Preview.SpawnAll(characters or {})
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
    local character, err = lib.callback.await('ryn-multichar:server:createCharacter', false, data)
    if character then
        Creation.StartAppearance(character)
    elseif err then
        lib.notify(source, {
            title = 'ryn-multichar',
            description = localeError(err),
            type = 'error',
        })
    end
    cb({ success = character ~= nil, error = err })
end)

RegisterNUICallback('selectSpawn', function(data, cb)
    local success = lib.callback.await('ryn-multichar:server:selectSpawn', false, data)
    if success then
        SetNuiFocus(false, false)
        TriggerEvent('ryn-multichar:client:close')
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
