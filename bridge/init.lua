Bridge = {
    name = nil,
    server = {},
    client = {},
}

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end

    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end

    return nil
end

function Bridge.Init()
    Bridge.name = detectFramework()

    if not Bridge.name then
        print('^1[ryn-multichar] No supported framework detected. Set Config.Framework manually.^0')
        return false
    end

    Utils.Debug('Framework detected:', Bridge.name)
    return true
end

function Bridge.GetServer()
    return Bridge.server[Bridge.name]
end

function Bridge.GetClient()
    return Bridge.client[Bridge.name]
end

CreateThread(function()
    Bridge.Init()
end)
