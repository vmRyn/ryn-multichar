Creation = {}

local function getSlotIndex(characterData, fallback)
    if not characterData then return fallback or 1 end
    return characterData.cid or characterData.slot or (characterData.charinfo and characterData.charinfo.cid) or fallback or 1
end

function Creation.ReturnToCharacterSelect(slotIndex)
    lib.callback.await('ryn-multichar:server:prepareCharacterSelect', false)

    if not Scene.loaded then
        Scene.Load()
    else
        local scene = Config.Scene
        local ped = cache.ped
        SetEntityCoords(ped, scene.coords.x, scene.coords.y, scene.coords.z, false, false, false, false)
        Scene.HidePlayerPed()
    end

    local characters, slotLimit = lib.callback.await('ryn-multichar:server:getCharacters', false)
    local focusSlot = slotIndex or 1

    Preview.SpawnAll(characters or {}, focusSlot)
    Preview.FocusSlot(focusSlot)
    Camera.Activate(focusSlot)

    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        screen = 'characterSelect',
        data = {
            theme = Config.UI,
            creationFields = Config.CreationFields,
            characters = characters,
            slotLimit = slotLimit,
            features = Scene.GetFeaturesForNui(),
            posePresets = Scene.GetPosePresetsForNui(),
        },
    })
end

function Creation.Open(slotIndex)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        screen = 'creation',
        data = {
            slotIndex = slotIndex,
            fields = Config.CreationFields,
        },
    })
end

function Creation.StartAppearance(characterData)
    SetNuiFocus(false, false)

    local slotIndex = getSlotIndex(characterData)

    Appearance.OpenCreator(true, characterData, function(appearance)
        if not appearance then
            Creation.ReturnToCharacterSelect(slotIndex)
            return
        end

        local locations = Spawn.GetAvailableLocations(characterData.citizenid)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            screen = 'spawnSelect',
            data = {
                theme = Config.UI,
                features = Scene.GetFeaturesForNui(),
                posePresets = Scene.GetPosePresetsForNui(),
                locations = locations,
                citizenid = characterData.citizenid,
            },
        })
    end)
end
