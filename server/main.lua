lib.callback.register('ryn-multichar:server:getCharacters', function(source)
    return Characters.GetAll(source)
end)

lib.callback.register('ryn-multichar:server:prepareCharacterSelect', function(source)
    Characters.ClearSession(source)
    local adapter = Bridge.GetServer()
    if adapter and adapter.Logout then
        adapter.Logout(source)
        Wait(200)
    end
    return true
end)

lib.callback.register('ryn-multichar:server:createCharacter', function(source, data)
    return Characters.Create(source, data)
end)

lib.callback.register('ryn-multichar:server:loadCharacter', function(source, citizenid)
    return Characters.Load(source, citizenid)
end)

lib.callback.register('ryn-multichar:server:deleteCharacter', function(source, data)
    local citizenid = type(data) == 'table' and data.citizenid or data
    local confirmName = type(data) == 'table' and data.confirmName or nil
    local success, err = Characters.Delete(source, citizenid, confirmName)
    return { success = success, error = err }
end)

lib.callback.register('ryn-multichar:server:abandonCharacter', function(source, citizenid)
    local success, err = Characters.Abandon(source, citizenid)
    return { success = success, error = err }
end)

lib.callback.register('ryn-multichar:server:clearPendingCharacter', function(source, citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then return false end
    if not Characters.Owns(source, citizenid) then return false end
    Characters.ClearPending(source, citizenid)
    return true
end)

lib.callback.register('ryn-multichar:server:getSpawnLocations', function(source, citizenid)
    return ServerSpawn.GetAvailable(source, citizenid)
end)

lib.callback.register('ryn-multichar:server:getPreviewData', function(source, citizenid)
    if not Characters.Owns(source, citizenid) then
        return nil, nil
    end

    local adapter = Bridge.GetServer()
    if adapter and adapter.GetPreviewData then
        return adapter.GetPreviewData(source, citizenid)
    end

    return nil, nil
end)

--- Normalized appearance for spawning the local player (single table, model always set).
lib.callback.register('ryn-multichar:server:getPlayerAppearance', function(source, citizenid)
    if not citizenid or citizenid == '' then return nil end
    if not Characters.Owns(source, citizenid) then return nil end

    local row
    local ok = pcall(function()
        row = MySQL.single.await(
            'SELECT model, skin FROM playerskins WHERE citizenid = ? AND active = 1',
            { citizenid }
        )
    end)

    if ok and row then
        local skin = row.skin
        if type(skin) == 'string' and skin ~= '' then
            local decodedOk, decoded = pcall(json.decode, skin)
            skin = decodedOk and decoded or nil
        end
        if type(skin) ~= 'table' then
            skin = {}
        end
        skin.model = skin.model or row.model or 'mp_m_freemode_01'
        return skin
    end

    local adapter = Bridge.GetServer()
    if adapter and adapter.GetPreviewData then
        local clothing, model = adapter.GetPreviewData(source, citizenid)
        if type(clothing) == 'string' then
            local decodedOk, decoded = pcall(json.decode, clothing)
            clothing = decodedOk and decoded or nil
        end
        if type(clothing) == 'table' then
            if not clothing.model then
                if type(model) == 'string' then
                    clothing.model = model
                elseif model == `mp_f_freemode_01` then
                    clothing.model = 'mp_f_freemode_01'
                else
                    clothing.model = 'mp_m_freemode_01'
                end
            end
            return clothing
        end
    end

    return nil
end)

lib.callback.register('ryn-multichar:server:selectSpawn', function(source, data)
    return ServerSpawn.Select(source, data)
end)

lib.callback.register('ryn-multichar:server:saveScenePose', function(source, data)
    if type(data) ~= 'table' then
        return { success = false, error = 'invalid_data' }
    end
    local success, result = SceneData.SavePose(
        source,
        data.citizenid,
        data.poseId,
        data.sceneId,
        data.portrait
    )
    return {
        success = success,
        error = type(result) == 'string' and result or nil,
        scene_data = type(result) == 'table' and result or nil,
    }
end)

lib.callback.register('ryn-multichar:server:admin:canOpen', function(source)
    return AdminPanel.CanOpen(source)
end)

lib.callback.register('ryn-multichar:server:admin:listEntries', function(source, search)
    if not AdminPanel.CanOpen(source) then return {} end
    return AdminPanel.ListEntries(search)
end)

lib.callback.register('ryn-multichar:server:admin:getOnlinePlayers', function(source)
    if not AdminPanel.CanOpen(source) then return {} end
    return AdminPanel.GetOnlinePlayers()
end)

lib.callback.register('ryn-multichar:server:admin:setEntry', function(source, data)
    local success, err = AdminPanel.SetEntry(source, data.license, data.slots)
    return { success = success, error = err }
end)

lib.callback.register('ryn-multichar:server:admin:deleteEntry', function(source, license)
    local success, err = AdminPanel.DeleteEntry(source, license)
    return { success = success, error = err }
end)

if Config.Relog.enabled and Config.Relog.permission ~= 'none' then
    lib.addCommand('relog', {
        help = 'Return to character selection',
        restricted = Config.Relog.permission == 'admin' and 'group.admin' or false,
    }, function(source)
        if source == 0 then return end

        -- Tell the client to ignore framework logout reopen events; we own the flow.
        TriggerClientEvent('ryn-multichar:client:prepareRelog', source)
        Wait(50)

        pcall(Playtime.Flush, source)

        local adapter = Bridge.GetServer()
        if adapter and adapter.Logout then
            adapter.Logout(source)
            Wait(300)
        end

        TriggerClientEvent('ryn-multichar:client:relog', source)
    end)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Bridge.Init()
end)
