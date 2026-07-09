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
    SetWeatherTypePersist(weather)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
    SetRainLevel(0.0)
    ClearOverrideWeather()
    SetOverrideWeather(weather)
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

    CreateThread(function()
        while Scene.loaded and Scene.syncActive do
            Scene.ApplyEnvironment()
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

function Scene.Load()
    if Scene.loaded then return end

    local scene = Config.Scene

    if scene.ipl then
        RequestIpl(scene.ipl)
        while not IsIplActive(scene.ipl) do
            Wait(0)
        end
    end

    Scene.ApplyEnvironment()

    local ped = cache.ped
    SetEntityCoords(ped, scene.coords.x, scene.coords.y, scene.coords.z, false, false, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)

    NetworkStartSoloTutorialSession()
    while not NetworkIsInTutorialSession() do Wait(0) end

    DisplayRadar(false)
    SetFollowPedCamViewMode(0)

    if scene.lighting then
        SetArtificialLightsState(true)
    end

    Scene.loaded = true
    Scene.StartSyncLoop()
    Utils.Debug('Scene loaded:', scene.type)
end

function Scene.Unload()
    Scene.StopSyncLoop()

    local ped = cache.ped
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)

    if Config.Scene.lighting then
        SetArtificialLightsState(false)
    end

    NetworkEndTutorialSession()
    Scene.loaded = false
end

function Scene.GetSlotCoords(slotIndex)
    local slot = Config.Scene.slots[slotIndex]
    return slot and slot.ped or nil
end

function Scene.GetSlotCamera(slotIndex)
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

function Scene.GetFeaturesForNui()
    return {
        photoMode = Config.PhotoMode.enabled,
        scenePoses = Config.ScenePoses.enabled,
    }
end
