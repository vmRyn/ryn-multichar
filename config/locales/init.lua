Locale = {}

for key, value in pairs(LocaleEn or {}) do
    Locale[key] = value
end

local localeCode = Config.UI and Config.UI.locale or 'en'
if localeCode == 'es' and LocaleEs then
    for key, value in pairs(LocaleEs) do
        Locale[key] = value
    end
end

function L(key, ...)
    local template = Locale[key] or (LocaleEn and LocaleEn[key]) or key
    if select('#', ...) > 0 then
        return template:format(...)
    end
    return template
end
