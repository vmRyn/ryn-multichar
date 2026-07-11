Characters = {}

local function findCharacter(characters, citizenid)
    for _, char in ipairs(characters or {}) do
        if char.citizenid == citizenid then
            return char
        end
    end
    return nil
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

    local license = adapter.GetIdentifier(source)
    local _, slotLimit = Characters.GetAll(source)
    local characters = adapter.GetCharacters(source)

    if #characters >= slotLimit then
        return nil, 'slot_limit_reached'
    end

    local character, err = adapter.CreateCharacter(source, data)
    if not character then return nil, err end

    MySQL.insert.await(
        'INSERT INTO ryn_multichar_metadata (character_id) VALUES (?) ON DUPLICATE KEY UPDATE last_played = CURRENT_TIMESTAMP',
        { character.citizenid }
    )

    if Config.StarterItems.enabled and not adapter.HandlesStarterItems then
        adapter.GiveStarterItems(source)
    end

    Discord.CharacterCreated(source, character)
    return character, nil
end

function Characters.Load(source, citizenid)
    local adapter = Bridge.GetServer()
    if not adapter then return false end

    Playtime.Flush(source)

    local success = adapter.LoadCharacter(source, citizenid)
    if not success then return false end

    MySQL.insert.await(
        'INSERT INTO ryn_multichar_metadata (character_id) VALUES (?) ON DUPLICATE KEY UPDATE last_played = CURRENT_TIMESTAMP',
        { citizenid }
    )

    local characters = adapter.GetCharacters(source)
    local character = findCharacter(characters, citizenid)
    Discord.CharacterLoaded(source, citizenid, Utils.GetCharacterFullName(character and character.charinfo))

    TriggerEvent('ryn-multichar:server:characterLoaded', source, citizenid)
    return true
end

function Characters.Delete(source, citizenid, confirmName)
    local adapter = Bridge.GetServer()
    if not adapter then return false, 'no_framework' end

    local characters = adapter.GetCharacters(source)
    local character = findCharacter(characters, citizenid)
    if not character then return false, 'not_found' end

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
    Discord.CharacterDeleted(source, citizenid, fullName)

    TriggerEvent('ryn-multichar:server:characterDeleted', source, citizenid)
    return true, nil
end

--- Delete a just-created character without name confirmation (appearance cancel).
function Characters.Abandon(source, citizenid)
    local adapter = Bridge.GetServer()
    if not adapter or not citizenid then return false, 'no_framework' end

    local characters = adapter.GetCharacters(source)
    local character = findCharacter(characters, citizenid)
    if not character then return false, 'not_found' end

    if Playtime.sessions[source] and Playtime.sessions[source].citizenid == citizenid then
        Playtime.Flush(source)
    end

    local success = adapter.DeleteCharacter(source, citizenid)
    if not success then return false, 'delete_failed' end

    MySQL.query.await('DELETE FROM ryn_multichar_metadata WHERE character_id = ?', { citizenid })
    TriggerEvent('ryn-multichar:server:characterDeleted', source, citizenid)
    return true, nil
end
