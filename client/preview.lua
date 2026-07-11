Preview = {
    peds = {},
    props = {},
    vehicles = {},
    characters = {},
    activeSlot = 1,
}

local function isInteriorScene()
    local scene = Config.Scene
    if not scene then return false end
    if scene.ipl or scene.type == 'apartment' or scene.type == 'interior' or scene.type == 'studio' then
        return true
    end

    local coords = scene.coords
    if coords and GetInteriorAtCoords(coords.x, coords.y, coords.z) ~= 0 then
        return true
    end

    return false
end

local function deletePedSafe(ped)
    if ped and DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        DeleteEntity(ped)
    end
end

local function finalizePedPlacement(ped, coords)
    if not ped or not DoesEntityExist(ped) then return end

    -- IPL slot coords are hand-placed; interior raycasts often hit the wrong mesh and bury the ped.
    local z = coords.z

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, z, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)
    FreezeEntityPosition(ped, true)
end

local function resolvePedCoords(coords)
    if not Config.SceneTools or not Config.SceneTools.snapPedsToGround then
        return coords
    end

    -- Ground snap finds world surfaces below IPL interiors and teleports peds outdoors.
    if isInteriorScene() then
        return coords
    end

    if GetInteriorAtCoords(coords.x, coords.y, coords.z) ~= 0 then
        return coords
    end

    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 2.0, false)
    if found then
        return vector4(coords.x, coords.y, groundZ, coords.w)
    end

    return coords
end

local function normalizeSlotIndex(slotIndex)
    local slot = tonumber(slotIndex)
    if slot then return math.floor(slot) end
    return slotIndex or 1
end

local function getCharacterForSlot(characters, slotIndex)
    if not characters then return nil end

    local slot = normalizeSlotIndex(slotIndex)
    for _, character in ipairs(characters) do
        local cid = tonumber(character.cid or character.slot)
        if cid and cid == slot then
            return character
        end
    end

    return nil
end

local function resolvePose(character, slotIndex)
    if not Config.ScenePoses.enabled then return nil, nil end

    -- Only use a saved per-character pose. Slot idleAnim handles the default look.
    if character and character.scene_data and character.scene_data.poseId then
        local poseId = character.scene_data.poseId
        local pose = Config.ScenePoses.presets[poseId]
        if pose then
            return poseId, pose
        end
    end

    return nil, nil
end

local function playAnim(ped, animConfig)
    if not animConfig or not DoesEntityExist(ped) then return end
    if not animConfig.dict or not animConfig.name then return end

    -- DoesAnimDictExist can false-negative before the dict is requested; just load it.
    local loaded = pcall(function()
        lib.requestAnimDict(animConfig.dict)
    end)
    if not loaded or not HasAnimDictLoaded(animConfig.dict) then return end

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

local function playSlotIdle(ped, slotIndex, character)
    local slotConfig = Config.Scene.slots[slotIndex]
    local _, pose = resolvePose(character, slotIndex)

    if character and pose and pose.anim then
        playAnim(ped, pose.anim)
        return
    end

    if slotConfig and slotConfig.idleAnim then
        playAnim(ped, slotConfig.idleAnim)
        return
    end

    playAnim(ped, {
        dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
        name = 'idle_a',
        flag = 1,
    })
end

local function setSlotPropsVisible(slotIndex, visible)
    local props = Preview.props[slotIndex]
    if not props then return end

    for _, prop in ipairs(props) do
        if prop and DoesEntityExist(prop) then
            SetEntityVisible(prop, visible, false)
            if visible then
                ResetEntityAlpha(prop)
            else
                SetEntityAlpha(prop, 0, false)
            end
        end
    end
end

local function setPedSlotVisible(ped, visible, isGhost, slotIndex)
    if not ped or not DoesEntityExist(ped) then return end

    if visible then
        ResetEntityAlpha(ped)
        SetEntityAlpha(ped, 255, false)
        SetEntityVisible(ped, true, false)
        SetEntityLocallyVisible(ped)
        SetEntityCollision(ped, false, false)
    else
        SetEntityAlpha(ped, 0, false)
    end

    if slotIndex then
        setSlotPropsVisible(slotIndex, visible)
    end
end

local function configurePreviewPed(ped)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityCollision(ped, false, false)
end

local function attachProp(ped, propConfig)
    if not ped or not DoesEntityExist(ped) or not propConfig or not propConfig.model then
        return nil
    end

    local model = type(propConfig.model) == 'number' and propConfig.model or joaat(propConfig.model)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        Utils.Debug('Invalid pose prop model:', propConfig.model)
        return nil
    end

    local ok = pcall(function()
        lib.requestModel(model)
    end)
    if not ok or not HasModelLoaded(model) then
        Utils.Debug('Failed to load pose prop model:', propConfig.model)
        return nil
    end

    local coords = GetEntityCoords(ped)
    local prop = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
    if not prop or prop == 0 or not DoesEntityExist(prop) then
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    SetEntityAsMissionEntity(prop, true, true)
    SetEntityCollision(prop, false, false)
    SetEntityVisible(prop, true, false)
    ResetEntityAlpha(prop)

    local offset = propConfig.offset or vector3(0.0, 0.0, 0.0)
    local rot = propConfig.rot or vector3(0.0, 0.0, 0.0)

    if propConfig.world then
        local pedCoords = GetEntityCoords(ped)
        local heading = math.rad(GetEntityHeading(ped))
        local worldX = pedCoords.x + offset.x * math.cos(heading) - offset.y * math.sin(heading)
        local worldY = pedCoords.y + offset.x * math.sin(heading) + offset.y * math.cos(heading)
        SetEntityCoordsNoOffset(prop, worldX, worldY, pedCoords.z + offset.z, false, false, false)
        SetEntityRotation(prop, rot.x, rot.y, rot.z + GetEntityHeading(ped), 2, true)
        FreezeEntityPosition(prop, true)
    else
        -- Do not freeze attached props — freezing breaks AttachEntityToEntity.
        AttachEntityToEntity(
            prop,
            ped,
            GetPedBoneIndex(ped, propConfig.bone or 28422),
            offset.x or 0.0,
            offset.y or 0.0,
            offset.z or 0.0,
            rot.x or 0.0,
            rot.y or 0.0,
            rot.z or 0.0,
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
            local prop = attachProp(ped, propConfig)
            if prop then
                Preview.props[slotIndex][#Preview.props[slotIndex] + 1] = prop
            end
        end
    end
end

local function spawnGhostPed(coords, slotIndex)
    coords = resolvePedCoords(coords)
    local model = `mp_m_freemode_01`
    lib.requestModel(model)

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    configurePreviewPed(ped)
    SetEntityVisible(ped, true, false)
    SetEntityLocallyVisible(ped)
    ResetEntityAlpha(ped)
    SetPedDefaultComponentVariation(ped)

    -- Simple readable outfit (not naked component-0 freemode).
    SetPedComponentVariation(ped, 0, 0, 0, 0)  -- head
    SetPedComponentVariation(ped, 2, 1, 0, 0)  -- hair
    SetPedComponentVariation(ped, 3, 1, 0, 0)  -- torso
    SetPedComponentVariation(ped, 4, 1, 0, 0)  -- legs
    SetPedComponentVariation(ped, 6, 1, 0, 0)  -- shoes
    SetPedComponentVariation(ped, 8, 1, 0, 0)  -- undershirt
    SetPedComponentVariation(ped, 11, 1, 0, 0) -- top

    finalizePedPlacement(ped, coords)

    -- Standing idle only — wall-lean anims clip empty-slot peds into geometry.
    playAnim(ped, {
        dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
        name = 'idle_a',
        flag = 1,
    })

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
        configurePreviewPed(ped)
    end

    finalizePedPlacement(ped, coords)

    local _, pose = resolvePose(character, slotIndex)
    playSlotIdle(ped, slotIndex, character)
    applyPoseExtras(slotIndex, ped, pose, coords)

    return ped
end

local function clearActiveSlotPed()
    local slotIndex = Preview.activeSlot
    if not slotIndex then return end

    clearSlotExtras(slotIndex)
    deletePedSafe(Preview.peds[slotIndex])
    Preview.peds[slotIndex] = nil
end

local function resolveSlotIndex(character, fallback)
    if not character then return fallback end
    return character.cid
        or character.slot
        or (character.charinfo and character.charinfo.cid)
        or fallback
end

local function getPedCoordsForPose(ped)
    local coords = GetEntityCoords(ped)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(ped))
end

function Preview.ApplyPose(slotIndex, character)
    slotIndex = slotIndex or Preview.activeSlot or 1
    local ped = Preview.peds[slotIndex]

    if not ped or not DoesEntityExist(ped) then
        Preview.RefreshSlot(slotIndex, character)
        return
    end

    clearSlotExtras(slotIndex)
    ClearPedTasksImmediately(ped)

    local _, pose = resolvePose(character, slotIndex)
    if pose and pose.anim then
        playAnim(ped, pose.anim)
        applyPoseExtras(slotIndex, ped, pose, getPedCoordsForPose(ped))
    else
        playSlotIdle(ped, slotIndex, character)
    end
end

local function spawnSlotPed(slotIndex)
    local slotConfig = Config.Scene.slots[slotIndex]
    if not slotConfig then return nil end

    local character = getCharacterForSlot(Preview.characters, slotIndex)
    local coords = resolvePedCoords(slotConfig.ped)

    return character
        and spawnCharacterPed(coords, character, slotIndex)
        or spawnGhostPed(coords, slotIndex)
end

function Preview.SwitchSlot(slotIndex, characters)
    if characters then Preview.characters = characters end
    slotIndex = normalizeSlotIndex(slotIndex or Preview.activeSlot or 1)

    local previousSlot = Preview.activeSlot and normalizeSlotIndex(Preview.activeSlot) or nil
    if previousSlot and previousSlot ~= slotIndex then
        local previousPed = Preview.peds[previousSlot]
        local previousCharacter = getCharacterForSlot(Preview.characters, previousSlot)
        setPedSlotVisible(previousPed, false, not previousCharacter, previousSlot)
    end

    Preview.activeSlot = slotIndex
    Scene.RequestSlotCollision(slotIndex)

    local character = getCharacterForSlot(Preview.characters, slotIndex)
    local isGhost = not character
    local slotConfig = Config.Scene.slots[slotIndex]
    if not slotConfig then
        Utils.Debug('SwitchSlot: missing slot config for', slotIndex)
        return
    end

    -- Empty slots: always respawn a fresh ghost so alpha-hide can't leave a stuck invisible ped.
    if isGhost then
        clearSlotExtras(slotIndex)
        deletePedSafe(Preview.peds[slotIndex])
        Preview.peds[slotIndex] = spawnGhostPed(resolvePedCoords(slotConfig.ped), slotIndex)
    elseif not Preview.peds[slotIndex] or not DoesEntityExist(Preview.peds[slotIndex]) then
        Preview.peds[slotIndex] = spawnSlotPed(slotIndex)
    else
        finalizePedPlacement(Preview.peds[slotIndex], resolvePedCoords(slotConfig.ped))
        playSlotIdle(Preview.peds[slotIndex], slotIndex, character)
    end

    local ped = Preview.peds[slotIndex]
    setPedSlotVisible(ped, true, isGhost, slotIndex)

    if Camera.photoMode then
        Camera.DisablePhotoMode(slotIndex)
    elseif Camera.cam and Camera.active then
        Camera.FocusSlot(slotIndex)
    else
        Camera.Activate(slotIndex)
    end
end

function Preview.WarmRemainingSlots()
    -- Always respect the *current* active slot. Using a stale index from SpawnAll
    -- would hide the ped the player just switched to.
    for slotIndex in pairs(Config.Scene.slots) do
        slotIndex = normalizeSlotIndex(slotIndex)
        if not Preview.peds[slotIndex] or not DoesEntityExist(Preview.peds[slotIndex]) then
            Preview.peds[slotIndex] = spawnSlotPed(slotIndex)
        end

        local character = getCharacterForSlot(Preview.characters, slotIndex)
        local isActive = slotIndex == normalizeSlotIndex(Preview.activeSlot)
        setPedSlotVisible(Preview.peds[slotIndex], isActive, not character, slotIndex)
    end
end

function Preview.SpawnAll(characters, slotIndex)
    Preview.Cleanup()
    Preview.characters = characters or {}
    slotIndex = normalizeSlotIndex(slotIndex or 1)

    Preview.activeSlot = slotIndex
    Scene.RequestSlotCollision(slotIndex)
    Preview.peds[slotIndex] = spawnSlotPed(slotIndex)

    local character = getCharacterForSlot(Preview.characters, slotIndex)
    setPedSlotVisible(Preview.peds[slotIndex], true, not character, slotIndex)

    CreateThread(function()
        Preview.WarmRemainingSlots()
    end)
end

--- Move existing preview peds into the current scene slots (no full respawn).
function Preview.RelayoutForScene(characters, slotIndex)
    if characters then Preview.characters = characters end
    slotIndex = normalizeSlotIndex(slotIndex or Preview.activeSlot or 1)
    Preview.activeSlot = slotIndex
    Scene.RequestSlotCollision(slotIndex)

    local keep = {}
    for rawIndex, slotConfig in pairs(Config.Scene.slots) do
        local idx = normalizeSlotIndex(rawIndex)
        keep[idx] = true

        local character = getCharacterForSlot(Preview.characters, idx)
        local coords = resolvePedCoords(slotConfig.ped)
        local ped = Preview.peds[idx]

        clearSlotExtras(idx)

        if ped and DoesEntityExist(ped) then
            finalizePedPlacement(ped, coords)
            if character then
                Preview.ApplyPose(idx, character)
            else
                playSlotIdle(ped, idx, nil)
            end
        else
            Preview.peds[idx] = spawnSlotPed(idx)
            ped = Preview.peds[idx]
        end

        setPedSlotVisible(ped, idx == slotIndex, not character, idx)
    end

    for idx, ped in pairs(Preview.peds) do
        local n = normalizeSlotIndex(idx)
        if not keep[n] then
            clearSlotExtras(n)
            deletePedSafe(ped)
            Preview.peds[idx] = nil
        end
    end
end

function Preview.Cleanup()
    for slotIndex in pairs(Preview.peds) do
        clearSlotExtras(slotIndex)
    end

    for _, ped in pairs(Preview.peds) do
        deletePedSafe(ped)
    end

    Preview.peds = {}
    Preview.props = {}
    Preview.vehicles = {}
    Preview.characters = {}
end

function Preview.FocusSlot(slotIndex)
    Preview.SwitchSlot(slotIndex)
end

function Preview.RefreshSlot(slotIndex, character)
    if character then
        local found = false
        for index, existing in ipairs(Preview.characters) do
            if existing.citizenid == character.citizenid then
                Preview.characters[index] = character
                found = true
                break
            end
        end
        if not found then
            Preview.characters[#Preview.characters + 1] = character
        end
    end

    clearSlotExtras(slotIndex)
    deletePedSafe(Preview.peds[slotIndex])
    Preview.peds[slotIndex] = spawnSlotPed(slotIndex)

    local isActive = Preview.activeSlot == slotIndex
    local slotCharacter = getCharacterForSlot(Preview.characters, slotIndex)
    setPedSlotVisible(Preview.peds[slotIndex], isActive, not slotCharacter, slotIndex)

    if isActive then
        if Camera.cam and Camera.active then
            Camera.FocusSlot(slotIndex)
        else
            Camera.Activate(slotIndex)
        end
    end
end

function Preview.UpdateCharacterPose(citizenid, sceneData)
    for index, character in ipairs(Preview.characters) do
        if character.citizenid == citizenid then
            character.scene_data = sceneData
            Preview.characters[index] = character

            local slotIndex = resolveSlotIndex(character, Preview.activeSlot)
            Preview.ApplyPose(slotIndex, character)
            break
        end
    end
end

function Preview.GetActiveCharacter(slotIndex)
    return getCharacterForSlot(Preview.characters, slotIndex)
end
