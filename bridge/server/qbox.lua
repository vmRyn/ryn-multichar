local adapter = {}

local function decodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or fallback
end

-- QBox grants starter items through qbx_core on character login.
adapter.HandlesStarterItems = true

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

    local success = exports.qbx_core:Login(source, nil, newData)
    if not success then
        return nil, 'create_failed'
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return nil, 'create_failed'
    end

    return player.PlayerData, nil
end

function adapter.LoadCharacter(source, citizenid)
    local player = exports.qbx_core:GetPlayer(source)
    if player then
        exports.qbx_core:Logout(source)
        Wait(250)
    end

    return exports.qbx_core:Login(source, citizenid) == true
end

function adapter.DeleteCharacter(source, citizenid)
    local deleted = false

    local ok = pcall(function()
        deleted = exports.qbx_core:DeleteCharacter(source, citizenid) == true
    end)

    if ok and deleted then return true end

    ok = pcall(function()
        deleted = exports.qbx_core:ForceDeleteCharacter(citizenid) == true
    end)

    if ok and deleted then return true end

    local result = MySQL.update.await('DELETE FROM players WHERE citizenid = ?', { citizenid })
    return (result or 0) > 0
end

function adapter.GetLastLocation(_source, citizenid)
    local player = exports.qbx_core:GetOfflinePlayer(citizenid)
    if not player or not player.PlayerData or not player.PlayerData.position then
        return nil
    end

    local pos = player.PlayerData.position
    return vector4(pos.x, pos.y, pos.z, pos.w or pos.a or 0.0)
end

function adapter.GetPreviewData(_source, citizenid)
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

    local row = MySQL.single.await(
        'SELECT metadata FROM players WHERE citizenid = ?',
        { citizenid }
    )

    if row and row.metadata then
        local metadata = decodeJson(row.metadata, {})
        if metadata and metadata.skin then
            return metadata.skin, metadata.model
        end
    end

    local ok, clothing, model = pcall(function()
        return exports.qbx_core:GetPreviewPedData(citizenid)
    end)

    if ok and clothing then
        return clothing, model
    end

    return nil, nil
end

function adapter.GiveStarterItems(_source)
    -- Handled by qbx_core
end

function adapter.Logout(source)
    local player = exports.qbx_core:GetPlayer(source)
    if player then
        exports.qbx_core:Logout(source)
    end
end

Bridge.server.qbox = adapter
