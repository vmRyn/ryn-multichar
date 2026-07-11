local adapter = {}
local ESX

local function getESX()
    if not ESX then
        ESX = exports['es_extended']:getSharedObject()
    end
    return ESX
end

adapter.HandlesStarterItems = false

local function decodeJson(value, fallback)
    return Utils.DecodeJson(value, fallback)
end

local function tableExists(name)
    return Utils.TableExists(name)
end

local function getLicenseHash(source)
    local identifier = GetPlayerIdentifierByType(source, 'license2')
        or GetPlayerIdentifierByType(source, 'license')
    if not identifier then return nil end
    return identifier:gsub('license2:', ''):gsub('license:', '')
end

function adapter.GetIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license2')
        or GetPlayerIdentifierByType(source, 'license')
end

function adapter.GetCharacters(source)
    local licenseHash = getLicenseHash(source)
    if not licenseHash then return {} end

    local rows = MySQL.query.await(
        "SELECT * FROM users WHERE identifier LIKE ? ORDER BY identifier ASC",
        { 'char%:' .. licenseHash }
    ) or {}

    local characters = {}
    for _, row in ipairs(rows) do
        local slot = tonumber(row.identifier:match('char(%d+):')) or #characters + 1
        local accounts = decodeJson(row.accounts, {})
        local job = decodeJson(row.job, {})
        if type(job) ~= 'table' then
            job = { name = row.job, label = row.job or 'Unemployed', grade = row.job_grade or 0 }
        end
        local metadata = decodeJson(row.metadata, {})

        characters[#characters + 1] = {
            citizenid = row.identifier,
            cid = slot,
            charinfo = {
                firstname = row.firstname,
                lastname = row.lastname,
                gender = (row.sex == 'f' or row.sex == 'female') and 1 or 0,
                birthdate = row.dateofbirth,
                nationality = metadata.nationality or row.nationality,
            },
            money = {
                cash = accounts.money or 0,
                bank = accounts.bank or 0,
            },
            job = {
                label = job.label or 'Unemployed',
                grade = {
                    name = job.grade_label or job.grade_name or tostring(job.grade or row.job_grade or ''),
                },
            },
        }
    end

    return characters
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
    local metadata = json.encode({
        nationality = data.nationality or 'American',
    })
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
        -- Minimal schemas often lack metadata; best-effort nationality update.
        pcall(function()
            MySQL.update.await('UPDATE users SET metadata = ? WHERE identifier = ?', { metadata, identifier })
        end)
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
            metadata,
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

    return {
        citizenid = identifier,
        cid = slot,
        charinfo = {
            firstname = data.firstname,
            lastname = data.lastname,
            gender = sex == 'f' and 1 or 0,
            birthdate = data.birthdate,
        },
    }, nil
end

function adapter.LoadCharacter(source, citizenid)
    local xPlayer = getESX().GetPlayerFromId(source)
    if xPlayer then
        adapter.Logout(source)
        Wait(250)
    end

    TriggerEvent('esx:onPlayerJoined', source, citizenid)
    return true
end

function adapter.DeleteCharacter(source, citizenid)
    local xPlayer = getESX().GetPlayerFromId(source)
    if xPlayer and xPlayer.identifier == citizenid then
        adapter.Logout(source)
        Wait(250)
    end

    local result = MySQL.update.await('DELETE FROM users WHERE identifier = ?', { citizenid })
    return (result or 0) > 0
end

function adapter.GetLastLocation(_source, citizenid)
    local row = MySQL.single.await('SELECT position FROM users WHERE identifier = ?', { citizenid })
    if not row or not row.position then return nil end

    local pos = decodeJson(row.position, nil)
    if not pos then return nil end

    return vector4(pos.x, pos.y, pos.z, pos.heading or pos.w or 0.0)
end

function adapter.GetPreviewData(_source, citizenid)
    -- illenium on ESX often still uses playerskins keyed by identifier/citizenid
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

    local row = MySQL.single.await('SELECT skin, sex FROM users WHERE identifier = ?', { citizenid })
    if not row then return nil, nil end

    local skin = decodeJson(row.skin, nil)
    if not skin then
        local model = (row.sex == 'f' or row.sex == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
        return { model = model }, joaat(model)
    end

    if not skin.model then
        skin.model = (row.sex == 'f' or row.sex == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    end

    return skin, skin.model
end

function adapter.GiveStarterItems(source)
    if not Config.StarterItems.enabled then return end

    CreateThread(function()
        local xPlayer
        local deadline = GetGameTimer() + 15000
        while GetGameTimer() < deadline do
            xPlayer = getESX().GetPlayerFromId(source)
            if xPlayer then break end
            Wait(250)
        end
        if not xPlayer then return end

        for _, item in ipairs(Config.StarterItems.items) do
            if GetResourceState('ox_inventory') == 'started' then
                pcall(function()
                    exports.ox_inventory:AddItem(source, item.name, item.amount)
                end)
            else
                pcall(function()
                    xPlayer.addInventoryItem(item.name, item.amount)
                end)
            end
        end
    end)
end

function adapter.Logout(source)
    local xPlayer = getESX().GetPlayerFromId(source)
    if not xPlayer then return end

    -- Prefer modern ESX logout export when available.
    local ok = pcall(function()
        getESX().Logout(source)
    end)

    if not ok then
        TriggerEvent('esx:playerLogout', source)
        Wait(250)
    end
end

Bridge.server.esx = adapter
