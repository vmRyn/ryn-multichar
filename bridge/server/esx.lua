local adapter = {}
local ESX = exports['es_extended']:getSharedObject()

adapter.HandlesStarterItems = false

local function decodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or fallback
end

local function getLicenseHash(source)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not identifier then return nil end
    return identifier:gsub('license:', '')
end

function adapter.GetIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license')
end

function adapter.GetCharacters(source)
    local licenseHash = getLicenseHash(source)
    if not licenseHash then return {}, Config.Slots.default end

    local slotLimit = Slots.GetLimit(adapter.GetIdentifier(source))
    local rows = MySQL.query.await(
        "SELECT * FROM users WHERE identifier LIKE ? ORDER BY identifier ASC",
        { 'char%:' .. licenseHash }
    ) or {}

    local characters = {}
    for _, row in ipairs(rows) do
        local slot = tonumber(row.identifier:match('char(%d+):')) or #characters + 1
        local accounts = decodeJson(row.accounts, {})
        local job = decodeJson(row.job, {})

        characters[#characters + 1] = {
            citizenid = row.identifier,
            cid = slot,
            charinfo = {
                firstname = row.firstname,
                lastname = row.lastname,
                gender = row.sex == 'f' and 1 or 0,
                birthdate = row.dateofbirth,
            },
            money = {
                cash = accounts.money or 0,
                bank = accounts.bank or 0,
            },
            job = {
                label = job.label or 'Unemployed',
                grade = { name = job.grade_label or job.grade_name or '' },
            },
        }
    end

    return characters, slotLimit
end

function adapter.CreateCharacter(source, data)
    local licenseHash = getLicenseHash(source)
    if not licenseHash then return nil, 'no_license' end

    local slot = data.slotIndex or data.cid
    local identifierFormat = Config.ESX and Config.ESX.identifierFormat or 'char%d:%s'
    local identifier = identifierFormat:format(slot, licenseHash)
    local existing = MySQL.scalar.await('SELECT 1 FROM users WHERE identifier = ?', { identifier })
    if existing then return nil, 'slot_taken' end

    local gender = data.gender
    local sex = 'm'
    if type(gender) == 'string' and gender:lower() == 'female' then
        sex = 'f'
    elseif gender == 1 then
        sex = 'f'
    end

    local spawnPos = Config.Scene.coords
    local position = json.encode({ x = spawnPos.x, y = spawnPos.y, z = spawnPos.z, heading = 0.0 })
    local accounts = json.encode({ money = 0, bank = 5000, black_money = 0 })
    local job = json.encode({
        name = 'unemployed',
        label = 'Unemployed',
        grade = 0,
        grade_name = 'Freelancer',
        grade_label = 'Freelancer',
        grade_salary = 0,
    })

    if Config.ESX and Config.ESX.mode == 'minimal' then
        MySQL.insert.await([[
            INSERT INTO users (identifier, firstname, lastname, dateofbirth, sex, accounts, job, job_grade, `group`, position)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            identifier,
            data.firstname,
            data.lastname,
            data.birthdate or '01/01/1990',
            sex,
            accounts,
            job,
            0,
            'user',
            position,
        })
    else
        MySQL.insert.await([[
            INSERT INTO users
                (identifier, firstname, lastname, dateofbirth, sex, height, accounts, job, job_grade, `group`, position, skin, status, inventory, loadout, metadata, is_dead, disabled)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            identifier,
            data.firstname,
            data.lastname,
            data.birthdate or '01/01/1990',
            sex,
            180,
            accounts,
            job,
            0,
            'user',
            position,
            json.encode({}),
            json.encode({}),
            json.encode({}),
            json.encode({}),
            json.encode({}),
            0,
            0,
        })
    end

    TriggerEvent('esx:onPlayerJoined', source, identifier)

    local characters = adapter.GetCharacters(source)
    for _, character in ipairs(characters) do
        if character.citizenid == identifier then
            return character, nil
        end
    end

    return { citizenid = identifier, cid = slot, charinfo = { firstname = data.firstname, lastname = data.lastname } }, nil
end

function adapter.LoadCharacter(source, citizenid)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        adapter.Logout(source)
        Wait(250)
    end

    TriggerEvent('esx:onPlayerJoined', source, citizenid)
    return true
end

function adapter.DeleteCharacter(source, citizenid)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.identifier == citizenid then
        adapter.Logout(source)
        Wait(250)
    end

    MySQL.query.await('DELETE FROM users WHERE identifier = ?', { citizenid })
    return true
end

function adapter.GetLastLocation(_source, citizenid)
    local row = MySQL.single.await('SELECT position FROM users WHERE identifier = ?', { citizenid })
    if not row or not row.position then return nil end

    local pos = decodeJson(row.position, nil)
    if not pos then return nil end

    return vector4(pos.x, pos.y, pos.z, pos.heading or pos.w or 0.0)
end

function adapter.GetPreviewData(_source, citizenid)
    local row = MySQL.single.await('SELECT skin FROM users WHERE identifier = ?', { citizenid })
    if not row or not row.skin then return nil, nil end

    local skin = decodeJson(row.skin, nil)
    return skin, skin and skin.model or nil
end

function adapter.GiveStarterItems(source)
    if not Config.StarterItems.enabled then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    for _, item in ipairs(Config.StarterItems.items) do
        if GetResourceState('ox_inventory') == 'started' then
            pcall(function()
                exports.ox_inventory:AddItem(source, item.name, item.amount)
            end)
        else
            xPlayer.addInventoryItem(item.name, item.amount)
        end
    end
end

function adapter.Logout(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    TriggerEvent('esx:playerLogout', source)
    Wait(250)
end

Bridge.server.esx = adapter
