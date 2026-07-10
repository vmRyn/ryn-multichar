if not Config.SceneTools or not Config.SceneTools.enabled then return end

lib.addCommand(Config.SceneTools.pedCommand, {
    help = 'Copy current ped position as vector4 (scene tuning)',
    restricted = Config.SceneTools.permission,
}, function(source)
    TriggerClientEvent('ryn-multichar:client:sceneTools:copyPed', source)
end)

lib.addCommand(Config.SceneTools.camCommand, {
    help = 'Copy active scene camera pos/rot/fov (scene tuning)',
    restricted = Config.SceneTools.permission,
}, function(source)
    TriggerClientEvent('ryn-multichar:client:sceneTools:copyCam', source)
end)
