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

function SceneData.SavePose(source, citizenid, poseId)
    if not Config.ScenePoses.enabled then return false, 'disabled' end
    if not Config.ScenePoses.presets[poseId] then return false, 'invalid_pose' end

    local adapter = Bridge.GetServer()
    if not adapter then return false, 'no_framework' end

    local characters = adapter.GetCharacters(source)
    local owned = false
    for _, char in ipairs(characters) do
        if char.citizenid == citizenid then
            owned = true
            break
        end
    end

    if not owned then return false, 'not_found' end

    local sceneData = SceneData.GetForCharacter(citizenid) or {}
    sceneData.poseId = poseId

    MySQL.insert.await([[
        INSERT INTO ryn_multichar_metadata (character_id, scene_data)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE scene_data = VALUES(scene_data)
    ]], { citizenid, json.encode(sceneData) })

    return true, sceneData
end

function SceneData.AttachMetadata(characters)
    for _, char in ipairs(characters) do
        local row = MySQL.single.await(
            'SELECT last_played, playtime, scene_data FROM ryn_multichar_metadata WHERE character_id = ?',
            { char.citizenid }
        )
        if row then
            char.last_played = row.last_played
            char.playtime = row.playtime
            char.scene_data = decodeSceneData(row.scene_data)
        end
    end
end
