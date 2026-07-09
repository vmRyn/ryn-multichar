local adapter = {}
local playerLoaded = false
local playerData = nil

local function refreshPlayerData()
    local ok, core = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and core then
        playerData = core.Functions.GetPlayerData()
    end
end

function adapter.OnPlayerLoaded(cb)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        playerLoaded = true
        refreshPlayerData()
        cb()
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
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

Bridge.client.qb = adapter
