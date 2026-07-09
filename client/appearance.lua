Appearance = {
    activeProvider = nil,
}

local DETECT_ORDER = { 'illenium-appearance', 'fivem-appearance', 'qb-clothing', 'skinchanger' }

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
    if not Appearance.activeProvider then
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
---@return table|string|nil appearance
---@return number|nil model
function Appearance.FetchPreviewData(citizenid)
    if Bridge.name == 'qbox' then
        local clothing, model = lib.callback.await('qbx_core:server:getPreviewPedData', false, citizenid)
        return clothing, model
    end

  -- Fallback: request from our server for other frameworks
    return lib.callback.await('ryn-multichar:server:getPreviewData', false, citizenid)
end

function Appearance.OpenCreator(isNew, data, cb)
    local provider = Appearance.GetProvider()

    if provider == 'illenium-appearance' then
        local ok = pcall(function()
            if isNew then
                exports['illenium-appearance']:startPlayerCustomization(function(appearance)
                    if cb then cb(appearance) end
                end, {
                    ped = true,
                    headBlend = true,
                    faceFeatures = true,
                    headOverlays = true,
                    components = true,
                    props = true,
                })
            else
                exports['illenium-appearance']:startPlayerCustomization(function(appearance)
                    if cb then cb(appearance) end
                end)
            end
        end)
        if ok then return end
    elseif provider == 'fivem-appearance' then
        local ok = pcall(function()
            exports['fivem-appearance']:startPlayerCustomization(function(appearance)
                if cb then cb(appearance) end
            end)
        end)
        if ok then return end
    elseif provider == 'qb-clothing' then
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')
        if cb then cb(true) end
        return
    elseif provider == 'skinchanger' then
        TriggerEvent('esx_skin:openSaveableMenu', function()
            if cb then cb(true) end
        end)
        return
    end

    if Config.CustomAppearance.openCreator then
        Config.CustomAppearance.openCreator(isNew, data, cb)
    end
end
