lib.callback.register('ryn-multichar:server:getCharacters', function(source)
    return Characters.GetAll(source)
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

lib.callback.register('ryn-multichar:server:getSpawnLocations', function(source, citizenid)
    return ServerSpawn.GetAvailable(source, citizenid)
end)

lib.callback.register('ryn-multichar:server:getPreviewData', function(source, citizenid)
    if Bridge.name == 'qbox' then
        return lib.callback.await('qbx_core:server:getPreviewPedData', source, citizenid)
    end

    local adapter = Bridge.GetServer()
    if adapter and adapter.GetPreviewData then
        return adapter.GetPreviewData(source, citizenid)
    end

    return nil, nil
end)

lib.callback.register('ryn-multichar:server:selectSpawn', function(source, data)
    return ServerSpawn.Select(source, data)
end)

lib.callback.register('ryn-multichar:server:saveScenePose', function(source, data)
    local success, result = SceneData.SavePose(source, data.citizenid, data.poseId)
    return { success = success, error = type(result) == 'string' and result or nil, scene_data = type(result) == 'table' and result or nil }
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
        Playtime.Flush(source)

        local adapter = Bridge.GetServer()
        if adapter and adapter.Logout then
            adapter.Logout(source)
            Wait(500)
        end
        TriggerClientEvent('ryn-multichar:client:open', source)
    end)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Bridge.Init()
end)
