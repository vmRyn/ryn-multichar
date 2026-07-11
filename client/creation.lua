Creation = {
    customizing = false,
}

-- Always stage new-character appearance in scene slot 1 (best framed camera/ped pose).
local CREATOR_SCENE_SLOT = 1

local function getSlotIndex(characterData, fallback)
    if not characterData then return fallback or 1 end
    return characterData.cid or characterData.slot or (characterData.charinfo and characterData.charinfo.cid) or fallback or 1
end

local function getGenderModel(characterData)
    local gender = characterData
        and (
            characterData.charinfo and characterData.charinfo.gender
            or characterData.gender
        )

    if gender == 1 or gender == 'female' then
        return `mp_f_freemode_01`
    end

    return `mp_m_freemode_01`
end

local function preparePedForCreator(characterData)
    Preview.Cleanup()

    if not Scene.loaded then
        Scene.Load()
    end

    if not NetworkIsInTutorialSession() then
        NetworkStartSoloTutorialSession()
        local deadline = GetGameTimer() + 5000
        while not NetworkIsInTutorialSession() and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    Scene.ApplyEnvironment()
    Scene.StartSyncLoop()

    local model = getGenderModel(characterData)
    lib.requestModel(model, 5000)
    SetPlayerModel(PlayerId(), model)
    Wait(250)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    ResetEntityAlpha(ped)
    SetLocalPlayerVisibleLocally(true)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    local coords = Scene.GetSlotCoords(CREATOR_SCENE_SLOT) or (Config.Scene and Config.Scene.coords)
    if coords then
        local x = coords.x or coords[1]
        local y = coords.y or coords[2]
        local z = coords.z or coords[3]
        local w = coords.w or coords[4] or 0.0
        SetEntityCoords(ped, x, y, z, false, false, false, false)
        SetEntityHeading(ped, w)
        Scene.RequestSlotCollision(CREATOR_SCENE_SLOT)
    end

    -- Frame with the scene's slot-1 camera before the appearance resource takes over.
    Camera.Activate(CREATOR_SCENE_SLOT)

    return ped
end

function Creation.ReturnToCharacterSelect(slotIndex)
    Creation.customizing = false

    lib.callback.await('ryn-multichar:server:prepareCharacterSelect', false)

    if not Scene.loaded then
        Scene.Load()
    else
        local scene = Config.Scene
        local ped = PlayerPedId()
        SetEntityCoords(ped, scene.coords.x, scene.coords.y, scene.coords.z, false, false, false, false)
        Scene.HidePlayerPed()
        Scene.ApplyEnvironment()
        Scene.StartSyncLoop()
    end

    if Config.Scene and Config.Scene.lighting then
        SetArtificialLightsState(false)
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
    CreateThread(function()
        local slotIndex = getSlotIndex(characterData)
        Creation.customizing = true

        -- UI should already be hidden by createCharacter; reinforce it.
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close', immediate = true })

        DoScreenFadeOut(300)
        while not IsScreenFadedOut() do Wait(0) end

        local okPrep, prepErr = pcall(preparePedForCreator, characterData)
        if not okPrep then
            Creation.customizing = false
            print(('^1[ryn-multichar] Failed to prepare ped for appearance: %s^0'):format(prepErr))
            Creation.ReturnToCharacterSelect(slotIndex)
            return
        end

        DoScreenFadeIn(400)
        local fadeDeadline = GetGameTimer() + 5000
        while not IsScreenFadedIn() and GetGameTimer() < fadeDeadline do
            Wait(0)
        end
        Wait(300)

        local opened = Appearance.OpenCreator(true, characterData, function(appearance)
            CreateThread(function()
                Creation.customizing = false
                Camera.Deactivate()

                if not appearance then
                    Creation.ReturnToCharacterSelect(slotIndex)
                    return
                end

                SetNuiFocus(false, false)
                Scene.HidePlayerPed()

                local locations = Spawn.GetAvailableLocations(characterData.citizenid)
                Spawn.citizenid = characterData.citizenid
                Spawn.EnterSelectMode(locations)
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
        end)

        if not opened then
            Creation.customizing = false
            print('^1[ryn-multichar] No appearance creator available — returning to character select^0')
            lib.notify({
                title = 'ryn-multichar',
                description = 'Appearance creator is not available. Is illenium-appearance started?',
                type = 'error',
            })
            Creation.ReturnToCharacterSelect(slotIndex)
        end
    end)
end
