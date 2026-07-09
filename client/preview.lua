Preview = {
    peds = {},
    props = {},
    vehicles = {},
    characters = {},
}

local function resolvePedCoords(coords)
    if not Config.SceneTools or not Config.SceneTools.snapPedsToGround then
        return coords
    end

    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 2.0, false)
    if found then
        return vector4(coords.x, coords.y, groundZ, coords.w)
    end

    return coords
end

local function getCharacterForSlot(characters, slotIndex)
    if not characters then return nil end

    for _, character in ipairs(characters) do
        local cid = character.cid or character.slot
        if cid == slotIndex then
            return character
        end
    end

    return characters[slotIndex]
end

local function resolvePose(character, slotIndex)
    if not Config.ScenePoses.enabled then return nil, nil end

    local poseId = Config.ScenePoses.defaultPreset

    if character and character.scene_data and character.scene_data.poseId then
        poseId = character.scene_data.poseId
    else
        local slotConfig = Config.Scene.slots[slotIndex]
        if slotConfig and slotConfig.posePreset then
            poseId = slotConfig.posePreset
        end
    end

    return poseId, Config.ScenePoses.presets[poseId]
end

local function playAnim(ped, animConfig)
    if not animConfig or not DoesEntityExist(ped) then return end

    lib.requestAnimDict(animConfig.dict)
    TaskPlayAnim(
        ped,
        animConfig.dict,
        animConfig.name,
        8.0,
        -8.0,
        -1,
        animConfig.flag or 1,
        0.0,
        false,
        false,
        false
    )
end

local function configurePreviewPed(ped)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityCollision(ped, false, false)
end

local function attachProp(ped, propConfig)
    local model = joaat(propConfig.model)
    lib.requestModel(model)

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityCollision(prop, false, false)
    FreezeEntityPosition(prop, true)

    if propConfig.world then
        local offset = propConfig.offset or vector3(0.0, 0.0, 0.0)
        local rot = propConfig.rot or vector3(0.0, 0.0, 0.0)
        local pedCoords = GetEntityCoords(ped)
        local heading = math.rad(GetEntityHeading(ped))
        local worldX = pedCoords.x + offset.x * math.cos(heading) - offset.y * math.sin(heading)
        local worldY = pedCoords.y + offset.x * math.sin(heading) + offset.y * math.cos(heading)
        SetEntityCoords(prop, worldX, worldY, pedCoords.z + offset.z, false, false, false, false)
        SetEntityRotation(prop, rot.x, rot.y, rot.z + GetEntityHeading(ped), 2, true)
    else
        AttachEntityToEntity(
            prop,
            ped,
            GetPedBoneIndex(ped, propConfig.bone or 28422),
            propConfig.offset and propConfig.offset.x or 0.0,
            propConfig.offset and propConfig.offset.y or 0.0,
            propConfig.offset and propConfig.offset.z or 0.0,
            propConfig.rot and propConfig.rot.x or 0.0,
            propConfig.rot and propConfig.rot.y or 0.0,
            propConfig.rot and propConfig.rot.z or 0.0,
            true,
            true,
            false,
            true,
            1,
            true
        )
    end

    SetModelAsNoLongerNeeded(model)
    return prop
end

local function spawnVehicle(vehicleConfig, pedCoords)
    if not vehicleConfig or not vehicleConfig.model then return nil end

    local model = joaat(vehicleConfig.model)
    lib.requestModel(model)

    local offset = vehicleConfig.offset or vector4(0.0, 0.0, 0.0, 0.0)
    local heading = math.rad(pedCoords.w or 0.0)
    local spawnX = pedCoords.x + offset.x * math.cos(heading) - offset.y * math.sin(heading)
    local spawnY = pedCoords.y + offset.x * math.sin(heading) + offset.y * math.cos(heading)
    local spawnZ = pedCoords.z + offset.z
    local spawnHeading = (pedCoords.w or 0.0) + offset.w

    local vehicle = CreateVehicle(model, spawnX, spawnY, spawnZ, spawnHeading, false, false)
    SetEntityInvincible(vehicle, true)
    FreezeEntityPosition(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleEngineOn(vehicle, false, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetEntityCollision(vehicle, false, false)
    SetModelAsNoLongerNeeded(model)

    return vehicle
end

local function clearSlotExtras(slotIndex)
    if Preview.props[slotIndex] then
        for _, prop in ipairs(Preview.props[slotIndex]) do
            if DoesEntityExist(prop) then DeleteEntity(prop) end
        end
        Preview.props[slotIndex] = nil
    end

    if Preview.vehicles[slotIndex] and DoesEntityExist(Preview.vehicles[slotIndex]) then
        DeleteEntity(Preview.vehicles[slotIndex])
        Preview.vehicles[slotIndex] = nil
    end
end

local function applyPoseExtras(slotIndex, ped, pose, pedCoords)
    clearSlotExtras(slotIndex)

    if not pose then return end

    if pose.vehicle then
        Preview.vehicles[slotIndex] = spawnVehicle(pose.vehicle, pedCoords)
    end

    if pose.props then
        Preview.props[slotIndex] = {}
        for _, propConfig in ipairs(pose.props) do
            Preview.props[slotIndex][#Preview.props[slotIndex] + 1] = attachProp(ped, propConfig)
        end
    end
end

local function spawnGhostPed(coords, slotIndex)
    coords = resolvePedCoords(coords)
    local model = `mp_m_freemode_01`
    lib.requestModel(model)

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    configurePreviewPed(ped)
    SetEntityAlpha(ped, 110, false)
    SetPedDefaultComponentVariation(ped)

    for i = 0, 11 do
        SetPedComponentVariation(ped, i, 0, 0, 0)
    end

    local _, pose = resolvePose(nil, slotIndex)
    playAnim(ped, pose and pose.anim)

    return ped
end

local function spawnCharacterPed(coords, character, slotIndex)
    coords = resolvePedCoords(coords)
    local model = `mp_m_freemode_01`
    if character and character.charinfo then
        local gender = character.charinfo.gender
        if gender == 1 or gender == 'female' then
            model = `mp_f_freemode_01`
        end
    end

    lib.requestModel(model)

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    configurePreviewPed(ped)
    ResetEntityAlpha(ped)

    if character and character.citizenid then
        local appearance, pedModel = Appearance.FetchPreviewData(character.citizenid)
        ped = Appearance.ApplyToPed(ped, appearance, pedModel) or ped
    end

    local _, pose = resolvePose(character, slotIndex)
    playAnim(ped, pose and pose.anim)
    applyPoseExtras(slotIndex, ped, pose, coords)

    return ped
end

function Preview.SpawnAll(characters)
    Preview.Cleanup()
    Preview.characters = characters or {}

    for slotIndex, slotConfig in pairs(Config.Scene.slots) do
        local character = getCharacterForSlot(characters, slotIndex)
        local coords = slotConfig.ped

        Preview.peds[slotIndex] = character
            and spawnCharacterPed(coords, character, slotIndex)
            or spawnGhostPed(coords, slotIndex)
    end
end

function Preview.Cleanup()
    for slotIndex in pairs(Preview.peds) do
        clearSlotExtras(slotIndex)
    end

    for _, ped in pairs(Preview.peds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    Preview.peds = {}
    Preview.props = {}
    Preview.vehicles = {}
    Preview.characters = {}
end

function Preview.FocusSlot(slotIndex)
    Camera.FocusSlot(slotIndex)

    local ped = Preview.peds[slotIndex]
    if ped and DoesEntityExist(ped) then
        local character = getCharacterForSlot(Preview.characters, slotIndex)
        local _, pose = resolvePose(character, slotIndex)
        playAnim(ped, pose and pose.anim)
    end
end

function Preview.RefreshSlot(slotIndex, character)
    local slotConfig = Config.Scene.slots[slotIndex]
    if not slotConfig then return end

    clearSlotExtras(slotIndex)

    if Preview.peds[slotIndex] and DoesEntityExist(Preview.peds[slotIndex]) then
        DeleteEntity(Preview.peds[slotIndex])
    end

    Preview.peds[slotIndex] = character
        and spawnCharacterPed(slotConfig.ped, character, slotIndex)
        or spawnGhostPed(slotConfig.ped, slotIndex)

    if character then
        for index, existing in ipairs(Preview.characters) do
            if existing.citizenid == character.citizenid then
                Preview.characters[index] = character
                break
            end
        end
    end

    Camera.FocusSlot(slotIndex)
end

function Preview.UpdateCharacterPose(citizenid, sceneData)
    for index, character in ipairs(Preview.characters) do
        if character.citizenid == citizenid then
            character.scene_data = sceneData
            Preview.characters[index] = character

            local slotIndex = character.cid or character.slot
            if slotIndex and Preview.peds[slotIndex] then
                Preview.RefreshSlot(slotIndex, character)
            end
            break
        end
    end
end

function Preview.GetActiveCharacter(slotIndex)
    return getCharacterForSlot(Preview.characters, slotIndex)
end
