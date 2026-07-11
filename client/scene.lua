Scene = {
    loaded = false,
    syncActive = false,
    weatherPaused = false,
}

local function getSceneWeather()
    if Config.SceneSync.weather then return Config.SceneSync.weather end
    return Config.Scene.weather
end

local function getSceneTime()
    if Config.SceneSync.time then return Config.SceneSync.time end
    return Config.Scene.time
end

local function applyWeather(weather)
    if not weather then return end
    -- Do not ClearOverrideWeather here — outdoors that briefly lets night/weather flash through.
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetOverrideWeather(weather)
    SetRainLevel(0.0)
end

local function applyTime(timeConfig)
    if not timeConfig then return end
    NetworkOverrideClockTime(timeConfig.hour or 12, timeConfig.minute or 0, timeConfig.second or 0)
    if Config.SceneSync.freezeTime then
        PauseClock(true)
    end
end

local function pauseWeatherResources()
    if Scene.weatherPaused then return end

    for _, resource in ipairs(Config.SceneSync.weatherResources or {}) do
        if GetResourceState(resource) == 'started' then
            pcall(function() exports[resource]:setSyncEnabled(false) end)
            pcall(function() exports[resource]:SetSyncEnabled(false) end)
            pcall(function() exports[resource]:DisableSync() end)
        end
    end

    Scene.weatherPaused = true
end

local function resumeWeatherResources()
    if not Scene.weatherPaused then return end

    for _, resource in ipairs(Config.SceneSync.weatherResources or {}) do
        if GetResourceState(resource) == 'started' then
            pcall(function() exports[resource]:setSyncEnabled(true) end)
            pcall(function() exports[resource]:SetSyncEnabled(true) end)
            pcall(function() exports[resource]:EnableSync() end)
        end
    end

    Scene.weatherPaused = false
end

local function waitForCollision(coords, ped, timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 10000)
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        if ped and HasCollisionLoadedAroundEntity(ped) then
            return true
        end
        Wait(0)
    end
    return false
end

local function loadSceneWorld(scene, focusSlot)
    local focusCoords = scene.coords
    if focusSlot and scene.slots and scene.slots[focusSlot] and scene.slots[focusSlot].ped then
        local ped = scene.slots[focusSlot].ped
        focusCoords = vector3(ped.x, ped.y, ped.z)
    end

    if scene.ipl then
        if GetResourceState('bob74_ipl') == 'started' and scene.ipl == 'apa_v_mp_h_01_a' then
            pcall(function()
                local apartment = exports['bob74_ipl']:GetExecApartment1Object()
                apartment.Enable(true)
                apartment.Style.Set(apartment.Style.Theme.modern, true)
            end)
            -- bob74 enables immediately; don't burn seconds waiting on RequestIpl.
            Wait(0)
        else
            RequestIpl(scene.ipl)
            local deadline = GetGameTimer() + 2500
            while not IsIplActive(scene.ipl) and GetGameTimer() < deadline do
                Wait(0)
            end
        end
    end

    SetFocusPosAndVel(focusCoords.x, focusCoords.y, focusCoords.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(focusCoords.x, focusCoords.y, focusCoords.z)

    -- Prefetch every slot so switching 1→2→3 doesn't wait on streaming.
    if scene.slots then
        for _, slot in pairs(scene.slots) do
            if slot.ped then
                RequestCollisionAtCoord(slot.ped.x, slot.ped.y, slot.ped.z)
            end
            if slot.camera and slot.camera.pos then
                RequestCollisionAtCoord(slot.camera.pos.x, slot.camera.pos.y, slot.camera.pos.z)
            end
        end
    end

    NewLoadSceneStart(focusCoords.x, focusCoords.y, focusCoords.z, focusCoords.x, focusCoords.y, focusCoords.z, 80.0, 0)
    local loadDeadline = GetGameTimer() + 2500
    while IsNewLoadSceneActive() and GetGameTimer() < loadDeadline do
        Wait(0)
    end
    NewLoadSceneStop()

    local interior = GetInteriorAtCoords(focusCoords.x, focusCoords.y, focusCoords.z)
    if interior ~= 0 then
        PinInteriorInMemory(interior)
        RefreshInterior(interior)
        SetInteriorActive(interior, true)

        local readyDeadline = GetGameTimer() + 2500
        while not IsInteriorReady(interior) and GetGameTimer() < readyDeadline do
            PinInteriorInMemory(interior)
            RefreshInterior(interior)
            Wait(0)
        end
    end
end

function Scene.ApplyEnvironment()
    applyWeather(getSceneWeather())
    applyTime(getSceneTime())
end

function Scene.StartSyncLoop()
    if not Config.SceneSync.override or Scene.syncActive then return end
    Scene.syncActive = true

    if Config.SceneSync.override then
        pauseWeatherResources()
    end

    -- Clock must be forced every frame or weathersync/network time will flicker outdoors.
    CreateThread(function()
        while Scene.loaded and Scene.syncActive do
            applyTime(getSceneTime())
            Wait(0)
        end
    end)

    CreateThread(function()
        while Scene.loaded and Scene.syncActive do
            applyWeather(getSceneWeather())
            pauseWeatherResources()
            Wait(1000)
        end
    end)
end

function Scene.StopSyncLoop()
    Scene.syncActive = false
    PauseClock(false)
    ClearOverrideWeather()
    resumeWeatherResources()
end

function Scene.HidePlayerPed()
    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then return end

    SetEntityVisible(ped, false, false)
    SetEntityLocallyInvisible(ped)
    SetLocalPlayerVisibleLocally(false)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
end

function Scene.KeepPlayerPedHidden()
    if not Scene.loaded then return end

    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then return end

    Scene.HidePlayerPed()

    local scene = Config.Scene
    if scene and scene.coords then
        local pedCoords = GetEntityCoords(ped)
        if #(pedCoords - scene.coords) > 2.0 then
            SetEntityCoords(ped, scene.coords.x, scene.coords.y, scene.coords.z, false, false, false, false)
        end
    end
end

function Scene.Load()
    if Scene.loaded then return end

    local scene = Config.Scene
    loadSceneWorld(scene, 1)
    Scene.ApplyEnvironment()

    local ped = cache.ped
    SetEntityCoords(ped, scene.coords.x, scene.coords.y, scene.coords.z, false, false, false, false)
    waitForCollision(scene.coords, ped, 10000)
    Scene.HidePlayerPed()

    NetworkStartSoloTutorialSession()
    while not NetworkIsInTutorialSession() do Wait(0) end

    DisplayRadar(false)
    SetFollowPedCamViewMode(0)

    if scene.lighting then
        -- Native is inverted: true = blackout (artificial lights OFF). We want lights ON.
        SetArtificialLightsState(false)
    end

    -- Keep the screen faded until the script camera is active (avoids a black/empty flash).
    Scene.loaded = true
    Scene.StartSyncLoop()
    Utils.Debug('Scene loaded:', scene.type)
end

function Scene.Unload()
    Scene.StopSyncLoop()

    local ped = cache.ped
    if ped and DoesEntityExist(ped) then
        ResetEntityAlpha(ped)
        SetLocalPlayerVisibleLocally(true)
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
    end

    SetArtificialLightsState(false)

    ClearFocus()

    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
        local deadline = GetGameTimer() + 5000
        while NetworkIsInTutorialSession() and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    Scene.loaded = false
end

function Scene.RequestSlotCollision(slotIndex)
    if not Scene.loaded then return end

    slotIndex = tonumber(slotIndex) or slotIndex
    local scene = Config.Scene
    local slot = scene.slots[slotIndex]
    if not slot then return end

    -- Focus the slot itself — scene.coords is often near slot 1, which leaves 2/3 unstreamed.
    local pedCoords = slot.ped
    SetFocusPosAndVel(pedCoords.x, pedCoords.y, pedCoords.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(pedCoords.x, pedCoords.y, pedCoords.z)

    if slot.camera and slot.camera.pos then
        RequestCollisionAtCoord(slot.camera.pos.x, slot.camera.pos.y, slot.camera.pos.z)
    end
end

-- Backwards-compatible alias (no blocking scene reload).
function Scene.EnsureStreamed(slotIndex)
    Scene.RequestSlotCollision(slotIndex)
end

function Scene.GetSlotCoords(slotIndex)
    slotIndex = tonumber(slotIndex) or slotIndex
    local slot = Config.Scene.slots[slotIndex]
    return slot and slot.ped or nil
end

function Scene.GetSlotCamera(slotIndex)
    slotIndex = tonumber(slotIndex) or slotIndex
    local slot = Config.Scene.slots[slotIndex]
    return slot and slot.camera or nil
end

function Scene.GetPosePresetsForNui()
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

local function formatSceneLabel(id)
    if type(id) ~= 'string' or id == '' then return 'Scene' end
    return (id:gsub('^%l', string.upper):gsub('_', ' '))
end

function Scene.GetScenePresetsForNui()
    local presets = {}
    for id, preset in pairs(Config.ScenePresets or {}) do
        presets[#presets + 1] = {
            id = id,
            label = (preset and preset.label) or formatSceneLabel(id),
        }
    end

    table.sort(presets, function(a, b)
        return a.label < b.label
    end)

    return presets
end

function Scene.GetActiveId()
    return Config.ActiveScene
end

local function unloadSceneWorld(scene)
    if not scene then return end

    if scene.ipl then
        if GetResourceState('bob74_ipl') == 'started' and scene.ipl == 'apa_v_mp_h_01_a' then
            pcall(function()
                local apartment = exports['bob74_ipl']:GetExecApartment1Object()
                apartment.Enable(false)
            end)
        else
            RemoveIpl(scene.ipl)
        end
    end
end

local function waitForPreviewPed(slotIndex, timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 1200)
    while GetGameTimer() < deadline do
        local previewPed = Preview.peds and Preview.peds[slotIndex]
        if previewPed and DoesEntityExist(previewPed) then
            return previewPed
        end
        Wait(0)
    end
    return Preview.peds and Preview.peds[slotIndex] or nil
end

local function settlePreviewPed(slotIndex)
    local slotCoords = Scene.GetSlotCoords(slotIndex)
    local previewPed = waitForPreviewPed(slotIndex, 1200)
    if not previewPed or not DoesEntityExist(previewPed) then
        return nil
    end

    if slotCoords then
        SetFocusPosAndVel(slotCoords.x, slotCoords.y, slotCoords.z, 0.0, 0.0, 0.0)
        RequestCollisionAtCoord(slotCoords.x, slotCoords.y, slotCoords.z)

        local deadline = GetGameTimer() + 1200
        while GetGameTimer() < deadline do
            RequestCollisionAtCoord(slotCoords.x, slotCoords.y, slotCoords.z)
            if HasCollisionLoadedAroundEntity(previewPed) then
                break
            end
            Wait(0)
        end

        SetEntityCoordsNoOffset(previewPed, slotCoords.x, slotCoords.y, slotCoords.z, false, false, false)
        SetEntityHeading(previewPed, slotCoords.w or 0.0)
        FreezeEntityPosition(previewPed, true)
    end

    return previewPed
end

local function snapSceneCamera(slotIndex, usePhoto)
    if not Camera then return end

    Camera.transitioning = false
    Camera.previewing = false
    Camera._transitionId = (Camera._transitionId or 0) + 1

    if usePhoto then
        Camera.ResetOrbit(slotIndex)
    else
        Camera.Activate(slotIndex)
    end
end

local function prefetchSceneSlots(scene)
    if not scene or not scene.slots then return end
    for _, slot in pairs(scene.slots) do
        if slot.ped then
            RequestCollisionAtCoord(slot.ped.x, slot.ped.y, slot.ped.z)
        end
        if slot.camera and slot.camera.pos then
            RequestCollisionAtCoord(slot.camera.pos.x, slot.camera.pos.y, slot.camera.pos.z)
        end
    end
end

--- Hot-swap character-select backdrop while keeping tutorial session / NUI open.
function Scene.SwitchPreset(presetId, slotIndex)
    local nextScene = Config.ScenePresets and Config.ScenePresets[presetId]
    if not nextScene then return false end

    slotIndex = tonumber(slotIndex) or Preview.activeSlot or 1
    if Config.ActiveScene == presetId and Scene.loaded then
        return true
    end

    local wasPhoto = Photo and Photo.active
    local shouldFade = wasPhoto or (Camera and Camera.active)

    local function ensureFadeIn()
        if IsScreenFadedOut() then
            DoScreenFadeIn(120)
        end
    end

    local ok, err = pcall(function()
        if shouldFade and not IsScreenFadedOut() then
            DoScreenFadeOut(80)
            local fadeDeadline = GetGameTimer() + 500
            while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
                Wait(0)
            end
        end

        -- Soft-exit photo mode: don't Activate the old scene camera mid-swap.
        if wasPhoto then
            Photo.active = false
            if Camera then
                Camera.photoMode = false
                Camera.previewing = false
                Camera.transitioning = false
                if Camera.cam then
                    StopCamPointing(Camera.cam)
                end
            end
        end

        local previous = Config.Scene
        ClearFocus()
        unloadSceneWorld(previous)

        Config.ActiveScene = presetId
        Config.Scene = nextScene

        loadSceneWorld(nextScene, slotIndex)
        Scene.ApplyEnvironment()
        SetArtificialLightsState(false)
        prefetchSceneSlots(nextScene)

        local ped = cache.ped
        if ped and DoesEntityExist(ped) then
            local anchor = nextScene.coords
            local slot = nextScene.slots and nextScene.slots[slotIndex]
            if slot and slot.ped then
                anchor = vector3(slot.ped.x, slot.ped.y, slot.ped.z)
            end
            SetEntityCoords(ped, anchor.x, anchor.y, anchor.z, false, false, false, false)
            waitForCollision(anchor, ped, 1500)
            Scene.HidePlayerPed()
        end

        if not Scene.loaded then
            Scene.loaded = true
            Scene.StartSyncLoop()
        end

        -- Reuse freemode peds — relocating is much faster than delete+create.
        local characters = Preview.characters or {}
        if Preview.RelayoutForScene then
            Preview.RelayoutForScene(characters, slotIndex)
        else
            Preview.SpawnAll(characters, slotIndex)
        end

        Scene.RequestSlotCollision(slotIndex)
        prefetchSceneSlots(nextScene)
        settlePreviewPed(slotIndex)

        snapSceneCamera(slotIndex, false)
        if wasPhoto then
            Photo.Enable(slotIndex)
            snapSceneCamera(slotIndex, true)
        end

        -- Interior IPLs often settle after the first snap — re-pin ped + cam briefly.
        CreateThread(function()
            local guardScene = presetId
            local guardSlot = slotIndex
            for _, delay in ipairs({ 100, 350, 700 }) do
                Wait(delay)
                if not Scene.loaded or Config.ActiveScene ~= guardScene then return end
                settlePreviewPed(guardSlot)
                snapSceneCamera(guardSlot, Photo and Photo.active)
            end
        end)
    end)

    ensureFadeIn()

    if not ok then
        Utils.Debug('Scene switch failed:', err)
        return false
    end

    Utils.Debug('Scene switched:', presetId)
    return true
end

function Scene.GetFeaturesForNui()
    return {
        photoMode = Config.PhotoMode.enabled,
        scenePoses = Config.ScenePoses.enabled,
    }
end

function Scene.GetNuiPayload()
    return {
        features = Scene.GetFeaturesForNui(),
        posePresets = Scene.GetPosePresetsForNui(),
        scenePresets = Scene.GetScenePresetsForNui(),
        activeScene = Scene.GetActiveId(),
    }
end
