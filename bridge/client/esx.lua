local adapter = {}
local playerLoaded = false
local playerData = nil

local function getESX()
    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok then return obj end
    return nil
end

local function refreshPlayerData()
    local esx = getESX()
    if not esx then return end

    if esx.GetPlayerData then
        playerData = esx.GetPlayerData()
        return
    end

    if esx.PlayerData then
        playerData = esx.PlayerData
    end
end

function adapter.OnPlayerLoaded(cb)
    RegisterNetEvent('esx:playerLoaded', function(xPlayer, _isNew, _skin)
        playerLoaded = true
        playerData = xPlayer
        if not playerData then
            refreshPlayerData()
        end
        cb()
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        playerLoaded = false
        playerData = nil
    end)
end

function adapter.TriggerPlayerLoaded()
    refreshPlayerData()
    TriggerEvent('esx:playerLoaded', playerData or {})

    -- Some ESX resources also listen for this after spawn.
    pcall(function()
        TriggerServerEvent('esx:onPlayerSpawn')
    end)
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

Bridge.client.esx = adapter
