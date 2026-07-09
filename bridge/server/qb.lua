local adapter = {}
local QBCore = exports['qb-core']:GetCoreObject()

adapter.HandlesStarterItems = false

local function decodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or fallback
end

local function normalizeLicense(source)
    return GetPlayerIdentifierByType(source, 'license2')
        or GetPlayerIdentifierByType(source, 'license')
end

function adapter.GetIdentifier(source)
    return normalizeLicense(source)
end

function adapter.GetCharacters(source)
    local license = adapter.GetIdentifier(source)
    local slotLimit = Slots.GetLimit(license)
    local rows = MySQL.query.await(
        'SELECT citizenid, cid, charinfo, money, job FROM players WHERE license = ? ORDER BY cid ASC',
        { license }
    ) or {}

    local characters = {}
    for _, row in ipairs(rows) do
        characters[#characters + 1] = {
            citizenid = row.citizenid,
            cid = row.cid,
            charinfo = decodeJson(row.charinfo, {}),
            money = decodeJson(row.money, {}),
            job = decodeJson(row.job, {}),
        }
    end

    return characters, slotLimit
end

function adapter.CreateCharacter(source, data)
    local gender = data.gender
    if type(gender) == 'string' then
        gender = gender:lower() == 'female' and 1 or 0
    end

    local newData = {
        cid = data.slotIndex or data.cid,
        charinfo = {
            firstname = data.firstname,
            lastname = data.lastname,
            nationality = data.nationality or 'American',
            gender = gender or 0,
            birthdate = data.birthdate,
            cid = data.slotIndex or data.cid,
        },
    }

    for key, value in pairs(data) do
        if key ~= 'slotIndex' and key ~= 'cid' and newData.charinfo[key] == nil then
            newData.charinfo[key] = value
        end
    end

    local success = QBCore.Player.Login(source, false, newData)
    if not success then
        return nil, 'create_failed'
    end

    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return nil, 'create_failed'
    end

    return player.PlayerData, nil
end

function adapter.LoadCharacter(source, citizenid)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        QBCore.Player.Logout(source)
        Wait(250)
    end

    return QBCore.Player.Login(source, citizenid) == true
end

function adapter.DeleteCharacter(source, citizenid)
    QBCore.Player.DeleteCharacter(source, citizenid)
    return true
end

function adapter.GetLastLocation(_source, citizenid)
    local row = MySQL.single.await('SELECT position FROM players WHERE citizenid = ?', { citizenid })
    if not row or not row.position then return nil end

    local pos = decodeJson(row.position, nil)
    if not pos then return nil end

    return vector4(pos.x, pos.y, pos.z, pos.w or pos.a or pos.h or 0.0)
end

function adapter.GetPreviewData(_source, citizenid)
    local row = MySQL.single.await('SELECT skin FROM players WHERE citizenid = ?', { citizenid })
    if not row or not row.skin then return nil, nil end

    local skin = decodeJson(row.skin, nil)
    return skin, skin and skin.model or nil
end

function adapter.GiveStarterItems(source)
    if not Config.StarterItems.enabled then return end

    for _, item in ipairs(Config.StarterItems.items) do
        pcall(function()
            exports.ox_inventory:AddItem(source, item.name, item.amount)
        end)
    end
end

function adapter.Logout(source)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        QBCore.Player.Logout(source)
    end
end

Bridge.server.qb = adapter
