-- Thin client bridge registration. Kept so framework adapters can attach
-- OnPlayerLoaded hooks without scattering CreateThreads in each file.
BridgeHooks = {
    registered = false,
}

function BridgeHooks.Register()
    if BridgeHooks.registered then return end

    local adapter = Bridge.GetClient()
    if not adapter or not adapter.OnPlayerLoaded then return end

    adapter.OnPlayerLoaded(function()
        Utils.Debug('Framework player loaded')
    end)

    BridgeHooks.registered = true
end

CreateThread(function()
    while not Bridge.name do
        Wait(100)
    end
    BridgeHooks.Register()
end)
