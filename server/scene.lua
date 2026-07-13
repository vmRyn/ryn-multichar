SceneData = {}

local function decodeSceneData(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return nil end
    local ok, decoded = pcall(json.decode, raw)
    return ok and decoded or nil
end

function SceneData.GetPosePresets()
    if not Config.ScenePoses.enabled then return {} end

    local presets = {}
    for id, preset in pairs(Config.ScenePoses.presets) do
        presets[#presets + 1] = {
            id = id,
            label = preset.label or id,
        }
    end

    table.sort(presets, function(a, b)
        return a.label < b.label
    end)

    return presets
end

function SceneData.GetPreset(poseId)
    if not poseId then return nil end
    return Config.ScenePoses.presets[poseId]
end

function SceneData.ResolveForCharacter(character, slotIndex)
    if not Config.ScenePoses.enabled then return nil end

    local poseId = Config.ScenePoses.defaultPreset

    if character and character.scene_data and character.scene_data.poseId then
        poseId = character.scene_data.poseId
    else
        local slotConfig = Config.Scene.slots[slotIndex]
        if slotConfig and slotConfig.posePreset then
            poseId = slotConfig.posePreset
        end
    end

    return poseId, SceneData.GetPreset(poseId)
end

function SceneData.GetForCharacter(citizenid)
    local row = MySQL.single.await(
        'SELECT scene_data FROM ryn_multichar_metadata WHERE character_id = ?',
        { citizenid }
    )
    return decodeSceneData(row and row.scene_data)
end

function SceneData.SavePose(source, citizenid, poseId, sceneId)
    if not Config.ScenePoses.enabled then return false, 'disabled' end
    if not Config.ScenePoses.presets[poseId] then return false, 'invalid_pose' end

    local adapter = Bridge.GetServer()
    if not adapter then return false, 'no_framework' end

    if not Characters.Owns(source, citizenid) then return false, 'not_found' end

    local sceneData = SceneData.GetForCharacter(citizenid) or {}
    sceneData.poseId = poseId
    if sceneId and Config.ScenePresets and Config.ScenePresets[sceneId] then
        sceneData.sceneId = sceneId
    end

    MySQL.insert.await([[
        INSERT INTO ryn_multichar_metadata (character_id, scene_data)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE scene_data = VALUES(scene_data)
    ]], { citizenid, json.encode(sceneData) })

    return true, sceneData
end

function SceneData.AttachMetadata(characters)
    if not characters or #characters == 0 then return end

    local ids = {}
    local byId = {}
    for _, char in ipairs(characters) do
        if char.citizenid then
            ids[#ids + 1] = char.citizenid
            byId[char.citizenid] = char
        end
    end

    if #ids == 0 then return end

    local placeholders = {}
    for i = 1, #ids do
        placeholders[i] = '?'
    end

    local rows = MySQL.query.await(
        ('SELECT character_id, last_played, playtime, scene_data FROM ryn_multichar_metadata WHERE character_id IN (%s)'):format(
            table.concat(placeholders, ',')
        ),
        ids
    )

    if not rows then return end

    for _, row in ipairs(rows) do
        local char = byId[row.character_id]
        if char then
            char.last_played = row.last_played
            char.playtime = row.playtime
            char.scene_data = decodeSceneData(row.scene_data)
        end
    end
end
