local adapter = {}
local playerLoaded = false
local playerData = nil

function adapter.OnPlayerLoaded(cb)
    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        playerLoaded = true
        playerData = xPlayer
        cb()
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        playerLoaded = false
        playerData = nil
    end)
end

function adapter.TriggerPlayerLoaded()
    TriggerEvent('esx:playerLoaded', playerData or {})
end

function adapter.GetPlayerData()
    return playerData
end

function adapter.IsPlayerLoaded()
    return playerLoaded
end

Bridge.client.esx = adapter
