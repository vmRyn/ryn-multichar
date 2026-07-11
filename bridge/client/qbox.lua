local adapter = {}
local playerLoaded = false
local playerData = nil

local function refreshPlayerData()
    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)
    if ok and data then
        playerData = data
    end
end

function adapter.OnPlayerLoaded(cb)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        playerLoaded = true
        refreshPlayerData()
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
        refreshPlayerData()
    end
    return playerData
end

function adapter.IsPlayerLoaded()
    return playerLoaded
end

Bridge.client.qbox = adapter
