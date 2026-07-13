Characters = {
    ---@type table<number, string>
    loaded = {},
    ---@type table<number, table<string, number>> source -> citizenid -> expiresAt
    pending = {},
}

local PENDING_TTL_MS = 30 * 60 * 1000

local function findCharacter(characters, citizenid)
    for _, char in ipairs(characters or {}) do
        if char.citizenid == citizenid then
            return char
        end
    end
    return nil
end

local function clearPending(source, citizenid)
    local bucket = Characters.pending[source]
    if not bucket then return end
    if citizenid then
        bucket[citizenid] = nil
        if not next(bucket) then
            Characters.pending[source] = nil
        end
        return
    end
    Characters.pending[source] = nil
end

local function markPending(source, citizenid)
    if not source or not citizenid then return end
    Characters.pending[source] = Characters.pending[source] or {}
    Characters.pending[source][citizenid] = GetGameTimer() + PENDING_TTL_MS
end

local function isPending(source, citizenid)
    local bucket = Characters.pending[source]
    if not bucket then return false end
    local expiresAt = bucket[citizenid]
    if not expiresAt then return false end
    if GetGameTimer() > expiresAt then
        bucket[citizenid] = nil
        if not next(bucket) then
            Characters.pending[source] = nil
        end
        return false
    end
    return true
end

function Characters.ClearSession(source)
    Characters.loaded[source] = nil
    clearPending(source)
end

function Characters.GetLoaded(source)
    return Characters.loaded[source]
end

function Characters.Owns(source, citizenid)
    if not citizenid or citizenid == '' then return false, nil end

    local adapter = Bridge.GetServer()
    if not adapter then return false, nil end

    local characters = adapter.GetCharacters(source)
    local character = findCharacter(characters, citizenid)
    if not character then return false, nil end
    return true, character
end

local function optionAllowed(field, value)
    if not field.options or #field.options == 0 then return true end
    local asString = tostring(value):lower()
    for _, option in ipairs(field.options) do
        if tostring(option):lower() == asString then
            return true
        end
    end
    return false
end

--- Sanitize create payload against Config.CreationFields (server-side).
function Characters.ValidateCreateData(data)
    if type(data) ~= 'table' then return nil, 'invalid_data' end

    local sanitized = {}
    for _, field in ipairs(Config.CreationFields or {}) do
        local value = data[field.name]

        if (value == nil or value == '') and field.required then
            return nil, 'invalid_data'
        end

        if value ~= nil and value ~= '' then
            if field.type == 'text' or field.type == 'autocomplete' then
                if type(value) ~= 'string' then return nil, 'invalid_data' end
                value = value:gsub('^%s*(.-)%s*$', '%1')
                if value == '' and field.required then return nil, 'invalid_data' end
                if #value > 50 then return nil, 'invalid_data' end
                if field.type == 'text' and value:find('[^%w%s%-\'%.]') then
                    return nil, 'invalid_data'
                end
            elseif field.type == 'date' then
                if type(value) ~= 'string' then return nil, 'invalid_data' end
                value = value:gsub('^%s*(.-)%s*$', '%1')
                if not value:match('^%d%d%d%d%-%d%d%-%d%d$') and not value:match('^%d%d/%d%d/%d%d%d%d$') then
                    return nil, 'invalid_data'
                end
            elseif field.type == 'select' then
                if not optionAllowed(field, value) then
                    return nil, 'invalid_data'
                end
            else
                if type(value) == 'string' then
                    value = value:gsub('^%s*(.-)%s*$', '%1')
                    if #value > 80 then return nil, 'invalid_data' end
                end
            end

            sanitized[field.name] = value
        end
    end

    local slotIndex = tonumber(data.slotIndex) or tonumber(data.cid)
    if slotIndex then
        sanitized.slotIndex = math.floor(slotIndex)
        sanitized.cid = sanitized.slotIndex
    end

    return sanitized, nil
end

function Characters.GetAll(source)
    local adapter = Bridge.GetServer()
    if not adapter then return {}, Config.Slots.default end

    Tebex.FlushPending(source)

    local license = adapter.GetIdentifier(source)
    local slotLimit = Slots.GetLimit(license)
    local characters = adapter.GetCharacters(source)
    SceneData.AttachMetadata(characters)

    return characters, slotLimit
end

function Characters.Create(source, data)
    local adapter = Bridge.GetServer()
    if not adapter then return nil, 'no_framework' end

    local sanitized, validateErr = Characters.ValidateCreateData(data)
    if not sanitized then return nil, validateErr end

    local _, slotLimit = Characters.GetAll(source)
    local characters = adapter.GetCharacters(source)

    if #characters >= slotLimit then
        return nil, 'slot_limit_reached'
    end

    local character, err = adapter.CreateCharacter(source, sanitized)
    if not character then return nil, err end

    MySQL.insert.await(
        'INSERT INTO ryn_multichar_metadata (character_id) VALUES (?) ON DUPLICATE KEY UPDATE last_played = CURRENT_TIMESTAMP',
        { character.citizenid }
    )

    Characters.loaded[source] = character.citizenid
    markPending(source, character.citizenid)

    if Config.StarterItems.enabled and not adapter.HandlesStarterItems then
        adapter.GiveStarterItems(source)
    end

    Discord.CharacterCreated(source, character)
    return character, nil
end

function Characters.Load(source, citizenid)
    local adapter = Bridge.GetServer()
    if not adapter then return false end

    local owns, character = Characters.Owns(source, citizenid)
    if not owns then return false end

    Playtime.Flush(source)

    local success = adapter.LoadCharacter(source, citizenid)
    if not success then return false end

    MySQL.insert.await(
        'INSERT INTO ryn_multichar_metadata (character_id) VALUES (?) ON DUPLICATE KEY UPDATE last_played = CURRENT_TIMESTAMP',
        { citizenid }
    )

    Characters.loaded[source] = citizenid
    clearPending(source, citizenid)

    Discord.CharacterLoaded(source, citizenid, Utils.GetCharacterFullName(character and character.charinfo))

    TriggerEvent('ryn-multichar:server:characterLoaded', source, citizenid)
    return true
end

function Characters.Delete(source, citizenid, confirmName)
    local adapter = Bridge.GetServer()
    if not adapter then return false, 'no_framework' end

    local owns, character = Characters.Owns(source, citizenid)
    if not owns then return false, 'not_found' end

    local fullName = Utils.GetCharacterFullName(character.charinfo)
    if not confirmName or confirmName:gsub('^%s*(.-)%s*$', '%1') ~= fullName then
        return false, 'name_mismatch'
    end

    if Playtime.sessions[source] and Playtime.sessions[source].citizenid == citizenid then
        Playtime.Flush(source)
    end

    local success = adapter.DeleteCharacter(source, citizenid)
    if not success then return false, 'delete_failed' end

    MySQL.query.await('DELETE FROM ryn_multichar_metadata WHERE character_id = ?', { citizenid })
    if Characters.loaded[source] == citizenid then
        Characters.loaded[source] = nil
    end
    clearPending(source, citizenid)
    Discord.CharacterDeleted(source, citizenid, fullName)

    TriggerEvent('ryn-multichar:server:characterDeleted', source, citizenid)
    return true, nil
end

--- Delete a just-created character without name confirmation (appearance cancel only).
function Characters.Abandon(source, citizenid)
    local adapter = Bridge.GetServer()
    if not adapter or not citizenid then return false, 'no_framework' end

    local owns = Characters.Owns(source, citizenid)
    if not owns then return false, 'not_found' end

    if not isPending(source, citizenid) then
        return false, 'not_pending'
    end

    if Playtime.sessions[source] and Playtime.sessions[source].citizenid == citizenid then
        Playtime.Flush(source)
    end

    local success = adapter.DeleteCharacter(source, citizenid)
    if not success then return false, 'delete_failed' end

    MySQL.query.await('DELETE FROM ryn_multichar_metadata WHERE character_id = ?', { citizenid })
    if Characters.loaded[source] == citizenid then
        Characters.loaded[source] = nil
    end
    clearPending(source, citizenid)
    TriggerEvent('ryn-multichar:server:characterDeleted', source, citizenid)
    return true, nil
end

--- Mark appearance complete so Abandon can no longer delete the character.
function Characters.ClearPending(source, citizenid)
    clearPending(source, citizenid)
end

AddEventHandler('playerDropped', function()
    Characters.ClearSession(source)
end)
