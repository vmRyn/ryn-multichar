local adapter = {}
local playerLoaded = false
local playerData = nil

function adapter.OnPlayerLoaded(cb)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        playerLoaded = true
        playerData = exports.qbx_core:GetPlayerData()
        cb()
    end)

    RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
        playerLoaded = false
        playerData = nil
    end)
end

function adapter.TriggerPlayerLoaded()
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end

function adapter.GetPlayerData()
    if playerLoaded then
        playerData = exports.qbx_core:GetPlayerData()
    end
    return playerData
end

function adapter.IsPlayerLoaded()
    return playerLoaded
end

Bridge.client.qbox = adapter
