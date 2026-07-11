Appearance = {
    activeProvider = nil,
}

local DETECT_ORDER = { 'illenium-appearance', 'fivem-appearance', 'qb-clothing', 'skinchanger' }
local STORY_PEDS = {
    [`player_zero`] = true,
    [`player_one`] = true,
    [`player_two`] = true,
}

function Appearance.Detect()
    if Config.Appearance.provider ~= 'auto' then
        return Config.Appearance.provider
    end

    for _, name in ipairs(DETECT_ORDER) do
        local provider = Config.Appearance.providers[name]
        if provider and provider.detect and provider.detect() then
            return name
        end
    end

    return 'custom'
end

function Appearance.GetProvider()
    -- Re-detect when previously unresolved so late-starting appearance resources work.
    if not Appearance.activeProvider or Appearance.activeProvider == 'custom' then
        Appearance.activeProvider = Appearance.Detect()
        Utils.Debug('Appearance provider:', Appearance.activeProvider)
    end
    return Appearance.activeProvider
end

---@param ped number
---@param appearance table|string
---@param model? number
function Appearance.ApplyToPed(ped, appearance, model)
    if not ped or not DoesEntityExist(ped) then return end

    if model then
        lib.requestModel(model)
        if GetEntityModel(ped) ~= model then
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            DeleteEntity(ped)
            ped = CreatePed(4, model, coords.x, coords.y, coords.z, heading, false, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetModelAsNoLongerNeeded(model)
        end
    end

    if not appearance then return ped end

    local skinData = type(appearance) == 'string' and json.decode(appearance) or appearance
    local provider = Appearance.GetProvider()

    local applied = false

    if provider == 'illenium-appearance' then
        applied = pcall(function()
            exports['illenium-appearance']:setPedAppearance(ped, skinData)
        end)
    elseif provider == 'fivem-appearance' then
        applied = pcall(function()
            exports['fivem-appearance']:setPedAppearance(ped, skinData)
        end)
    elseif provider == 'qb-clothing' then
        applied = pcall(function()
            TriggerEvent('qb-clothing:client:loadPlayerClothing', skinData, ped)
        end)
    elseif provider == 'skinchanger' then
        applied = pcall(function()
            if exports['skinchanger'].ApplySkinToPed then
                exports['skinchanger']:ApplySkinToPed(ped, skinData)
            else
                exports['skinchanger']:ApplySkin(ped, skinData)
            end
        end)
    end

    if not applied and Config.CustomAppearance.applyPreview then
        Config.CustomAppearance.applyPreview(ped, skinData)
    end

    return ped
end

---@param citizenid string
---@return table|nil appearance
function Appearance.FetchPlayerAppearance(citizenid)
    if not citizenid then return nil end

    -- Single normalized payload from our server (model always included).
    local appearance = lib.callback.await('ryn-multichar:server:getPlayerAppearance', false, citizenid)
    if type(appearance) == 'table' and (appearance.model or appearance.components) then
        return appearance
    end

    -- Fallback through the active framework adapter (QB / ESX / QBox).
    local clothing, model = lib.callback.await('ryn-multichar:server:getPreviewData', false, citizenid)

    if type(clothing) == 'string' then
        local ok, decoded = pcall(json.decode, clothing)
        clothing = ok and decoded or nil
    end

    if type(clothing) ~= 'table' then
        clothing = {}
    end

    if not clothing.model then
        if type(model) == 'string' and model ~= '' then
            clothing.model = model
        elseif model == `mp_f_freemode_01` then
            clothing.model = 'mp_f_freemode_01'
        elseif type(model) == 'number' and model ~= 0 then
            clothing.model = 'mp_m_freemode_01'
        end
    end

    if clothing.model or clothing.components then
        return clothing
    end

    return nil
end

---@param citizenid string
---@return table|string|nil appearance
---@return number|nil model
function Appearance.FetchPreviewData(citizenid)
    local appearance = Appearance.FetchPlayerAppearance(citizenid)
    if not appearance then return nil, nil end

    local model = appearance.model
    if type(model) == 'string' then
        model = joaat(model)
    end

    return appearance, model
end

local function resolveFallbackModel()
    local gender
    local adapter = Bridge.GetClient()
    local playerData = adapter and adapter.GetPlayerData and adapter.GetPlayerData()

    if Bridge.name == 'qbox' and (not playerData or not playerData.charinfo) then
        local ok, data = pcall(function()
            return exports.qbx_core:GetPlayerData()
        end)
        if ok then playerData = data end
    end

    if playerData then
        if playerData.charinfo and playerData.charinfo.gender ~= nil then
            gender = playerData.charinfo.gender
        elseif playerData.sex ~= nil then
            gender = playerData.sex
        elseif playerData.gender ~= nil then
            gender = playerData.gender
        end
    end

    if gender == 1 or gender == 'female' or gender == 'f' then
        return 'mp_f_freemode_01'
    end

    return 'mp_m_freemode_01'
end

local function isStoryPed(ped)
    if not ped or not DoesEntityExist(ped) then return true end
    return STORY_PEDS[GetEntityModel(ped)] == true
end

local function setLocalPlayerModel(modelName)
    local modelHash = type(modelName) == 'number' and modelName or joaat(modelName)
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        modelHash = `mp_m_freemode_01`
        modelName = 'mp_m_freemode_01'
    end

    lib.requestModel(modelHash, 5000)
    SetPlayerModel(PlayerId(), modelHash)
    Wait(250)
    SetModelAsNoLongerNeeded(modelHash)

    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    return ped, modelName
end

local function applySkinToLocalPed(ped, appearance)
    if not ped or not appearance then return end

    local provider = Appearance.GetProvider()

    if provider == 'illenium-appearance' then
        pcall(function()
            exports['illenium-appearance']:setPedAppearance(ped, appearance)
        end)
    elseif provider == 'fivem-appearance' then
        pcall(function()
            exports['fivem-appearance']:setPedAppearance(ped, appearance)
        end)
    elseif provider == 'qb-clothing' then
        TriggerEvent('qb-clothing:client:loadPlayerClothing', appearance, ped)
    elseif provider == 'skinchanger' then
        TriggerEvent('skinchanger:loadSkin', appearance)
    elseif Config.CustomAppearance.applyPreview then
        Config.CustomAppearance.applyPreview(ped, appearance)
    end
end

--- Apply saved skin to the local player (not a preview ped).
--- Always forces SetPlayerModel — never trust provider helpers alone.
---@param citizenid string
---@return boolean
function Appearance.ApplyToLocalPlayer(citizenid)
    if not citizenid then
        print('^1[ryn-multichar] ApplyToLocalPlayer: missing citizenid^0')
        return false
    end

    -- Tutorial session can block model swaps.
    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
        local deadline = GetGameTimer() + 5000
        while NetworkIsInTutorialSession() and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    local appearance = Appearance.FetchPlayerAppearance(citizenid)
    local modelName = (appearance and appearance.model) or resolveFallbackModel()
    if type(modelName) == 'number' then
        if modelName == `mp_f_freemode_01` then
            modelName = 'mp_f_freemode_01'
        else
            modelName = 'mp_m_freemode_01'
        end
    end

    Utils.Debug('ApplyToLocalPlayer', citizenid, modelName, Appearance.GetProvider())

    local ped = setLocalPlayerModel(modelName)

    -- If still a story ped, force freemode once more.
    if isStoryPed(ped) then
        print(('^3[ryn-multichar] Model swap failed (still story ped), forcing freemode for %s^0'):format(citizenid))
        ped = setLocalPlayerModel(resolveFallbackModel())
    end

    if appearance then
        applySkinToLocalPed(ped, appearance)
    end

    ped = PlayerPedId()
    local success = not isStoryPed(ped)
    if not success then
        print(('^1[ryn-multichar] Failed to leave story ped for %s (model=%s)^0'):format(
            citizenid,
            GetEntityModel(ped)
        ))
    end

    return success
end

function Appearance.OpenCreator(isNew, data, cb)
    local provider = Appearance.GetProvider()

    local function invokeIllenium()
        local config = isNew and {
            ped = true,
            headBlend = true,
            faceFeatures = true,
            headOverlays = true,
            components = true,
            props = true,
            tattoos = true,
        } or nil

        -- Illenium blocks until these are clear; SetPlayerModel can leave switch flags set.
        local deadline = GetGameTimer() + 8000
        while GetGameTimer() < deadline do
            if IsScreenFadedIn() and not IsPlayerTeleportActive() and not IsPlayerSwitchInProgress() then
                break
            end
            if not IsScreenFadedIn() then
                DoScreenFadeIn(0)
            end
            Wait(50)
        end

        if config then
            exports['illenium-appearance']:startPlayerCustomization(function(appearance)
                if cb then cb(appearance) end
            end, config)
        else
            exports['illenium-appearance']:startPlayerCustomization(function(appearance)
                if cb then cb(appearance) end
            end)
        end
    end

    if provider == 'illenium-appearance' then
        CreateThread(function()
            local ok, err = pcall(invokeIllenium)
            if not ok then
                print(('^1[ryn-multichar] illenium-appearance failed: %s^0'):format(err))
                if cb then cb(nil) end
            end
        end)
        return true
    elseif provider == 'fivem-appearance' then
        CreateThread(function()
            local ok, err = pcall(function()
                exports['fivem-appearance']:startPlayerCustomization(function(appearance)
                    if cb then cb(appearance) end
                end)
            end)
            if not ok then
                print(('^1[ryn-multichar] fivem-appearance failed: %s^0'):format(err))
                if cb then cb(nil) end
            end
        end)
        return true
    elseif provider == 'qb-clothing' then
        CreateThread(function()
            local finished = false
            local function finish(result)
                if finished then return end
                finished = true
                if cb then cb(result) end
            end

            TriggerEvent('qb-clothes:client:CreateFirstCharacter')

            -- qb-clothing has no reliable completion callback; wait for its NUI
            -- to open then close (player finished or backed out).
            local opened = false
            local deadline = GetGameTimer() + 300000
            while GetGameTimer() < deadline do
                local focused = IsNuiFocused()
                if focused then opened = true end
                if opened and not focused then
                    Wait(400)
                    if not IsNuiFocused() then
                        finish(true)
                        return
                    end
                end
                Wait(200)
            end

            finish(true)
        end)
        return true
    elseif provider == 'skinchanger' then
        TriggerEvent('esx_skin:openSaveableMenu', function()
            if cb then cb(true) end
        end, function()
            if cb then cb(nil) end
        end)
        return true
    end

    if Config.CustomAppearance.openCreator then
        Config.CustomAppearance.openCreator(isNew, data, cb)
        return true
    end

    print(('^1[ryn-multichar] No appearance creator for provider "%s"^0'):format(tostring(provider)))
    return false
end
