-- Runs after all config files load. Logs warnings only; never blocks startup.

local function warn(message)
    print(('^3[ryn-multichar] Config: %s^0'):format(message))
end

CreateThread(function()
    Wait(500)

    if not Bridge.name then
        warn('No framework detected — set Config.Framework manually if needed')
    end

    if Config.Slots.default < 1 then
        warn('Config.Slots.default should be at least 1')
    end

    if Config.ScenePresets and Config.ActiveScene and not Config.ScenePresets[Config.ActiveScene] then
        warn(('Unknown Config.ActiveScene "%s"'):format(Config.ActiveScene))
    end

    if Config.Discord.enabled then
        for key, url in pairs(Config.Discord.webhooks or {}) do
            if not url or url == '' then
                warn(('Discord enabled but webhooks.%s is empty'):format(key))
            end
        end
    end

    if Config.Slots.tebex.enabled then
        local packageCount = 0
        for _ in pairs(Config.Slots.tebex.packages or {}) do
            packageCount = packageCount + 1
        end
        if packageCount == 0 then
            warn('Tebex enabled but Config.Slots.tebex.packages is empty')
        end
    end

    if Config.UI and Config.UI.locale ~= 'en' and Config.UI.locale ~= 'es' then
        warn(('Unknown Config.UI.locale "%s" — using English'):format(tostring(Config.UI.locale)))
    end

    Utils.Debug('Config validation complete')
end)
