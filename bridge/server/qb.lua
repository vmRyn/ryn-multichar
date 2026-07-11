local adapter = {}
local QBCore

local function getQBCore()
    if not QBCore then
        QBCore = exports['qb-core']:GetCoreObject()
    end
    return QBCore
end

adapter.HandlesStarterItems = false

local function decodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or fallback
end

local function tableExists(name)
    local ok, row = pcall(function()
        return MySQL.single.await(
            'SELECT 1 AS ok FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? LIMIT 1',
            { name }
        )
    end)
    return ok and row ~= nil
end

function adapter.GetIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license2')
        or GetPlayerIdentifierByType(source, 'license')
end

function adapter.GetCharacters(source)
    local license = adapter.GetIdentifier(source)
    if not license then return {} end

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

    return characters
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

    local success = getQBCore().Player.Login(source, false, newData)
    if not success then
        return nil, 'create_failed'
    end

    local player = getQBCore().Functions.GetPlayer(source)
    if not player then
        return nil, 'create_failed'
    end

    return player.PlayerData, nil
end

function adapter.LoadCharacter(source, citizenid)
    local player = getQBCore().Functions.GetPlayer(source)
    if player then
        getQBCore().Player.Logout(source)
        Wait(250)
    end

    return getQBCore().Player.Login(source, citizenid) == true
end

function adapter.DeleteCharacter(source, citizenid)
    local deleted = false

    local ok = pcall(function()
        getQBCore().Player.DeleteCharacter(source, citizenid)
        deleted = true
    end)

    if ok and deleted then
        -- Confirm row is gone; some QB builds don't return a status.
        local stillThere = MySQL.scalar.await('SELECT 1 FROM players WHERE citizenid = ?', { citizenid })
        if not stillThere then return true end
    end

    local result = MySQL.update.await('DELETE FROM players WHERE citizenid = ?', { citizenid })
    return (result or 0) > 0
end

function adapter.GetLastLocation(_source, citizenid)
    local row = MySQL.single.await('SELECT position FROM players WHERE citizenid = ?', { citizenid })
    if not row or not row.position then return nil end

    local pos = decodeJson(row.position, nil)
    if not pos then return nil end

    return vector4(pos.x, pos.y, pos.z, pos.w or pos.a or pos.h or 0.0)
end

function adapter.GetPreviewData(_source, citizenid)
    -- illenium / modern QB: playerskins
    if tableExists('playerskins') then
        local skinRow = MySQL.single.await(
            'SELECT model, skin FROM playerskins WHERE citizenid = ? AND active = 1',
            { citizenid }
        )

        if skinRow and skinRow.skin then
            local skin = decodeJson(skinRow.skin, nil)
            if skin then
                return skin, skinRow.model and joaat(skinRow.model) or nil
            end
        end
    end

    -- metadata.skin (some QB forks)
    local metaRow = MySQL.single.await(
        'SELECT metadata FROM players WHERE citizenid = ?',
        { citizenid }
    )
    if metaRow and metaRow.metadata then
        local metadata = decodeJson(metaRow.metadata, {})
        if metadata and metadata.skin then
            return metadata.skin, metadata.model
        end
    end

    -- Legacy players.skin column
    local row = MySQL.single.await('SELECT skin FROM players WHERE citizenid = ?', { citizenid })
    if not row or not row.skin then return nil, nil end

    local skin = decodeJson(row.skin, nil)
    return skin, skin and skin.model or nil
end

function adapter.GiveStarterItems(source)
    if not Config.StarterItems.enabled then return end

    local player = getQBCore().Functions.GetPlayer(source)

    for _, item in ipairs(Config.StarterItems.items) do
        local given = false

        if GetResourceState('ox_inventory') == 'started' then
            given = pcall(function()
                exports.ox_inventory:AddItem(source, item.name, item.amount)
            end)
        end

        if not given and GetResourceState('qb-inventory') == 'started' then
            given = pcall(function()
                exports['qb-inventory']:AddItem(source, item.name, item.amount)
            end)
        end

        if not given and player and player.Functions and player.Functions.AddItem then
            pcall(function()
                player.Functions.AddItem(item.name, item.amount)
            end)
        end
    end
end

function adapter.Logout(source)
    local player = getQBCore().Functions.GetPlayer(source)
    if player then
        getQBCore().Player.Logout(source)
    end
end

Bridge.server.qb = adapter
