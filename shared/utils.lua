Utils = {}

function Utils.Debug(...)
    if Config.Debug then
        print('[ryn-multichar]', ...)
    end
end

function Utils.GetTableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function Utils.DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = Utils.DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

function Utils.FormatPlaytime(seconds)
    if not seconds or seconds <= 0 then return '0h' end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return ('%dh %dm'):format(hours, minutes)
    end
    return ('%dm'):format(minutes)
end

function Utils.DecodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or fallback
end

function Utils.TableExists(name)
    local ok, row = pcall(function()
        return MySQL.single.await(
            'SELECT 1 AS ok FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? LIMIT 1',
            { name }
        )
    end)
    return ok and row ~= nil
end

function Utils.GetCharacterFullName(charinfo)
    if not charinfo then return '' end
    return ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')
end

--- Merged Brand + UI theme payload for NUI.
function Utils.GetUiTheme()
    local ui = Config.UI or {}
    local brand = Config.Brand or {}
    local colors = Utils.DeepCopy(ui.colors or {})

    if type(brand.accent) == 'string' and brand.accent ~= '' then
        colors.primary = brand.accent
    end

    local wordmark = brand.wordmark
    if type(wordmark) ~= 'string' or wordmark == '' then
        wordmark = ui.serverName or 'RYN'
    end

    local logo = brand.logo
    if type(logo) ~= 'string' or logo == '' then
        logo = ui.logo or ''
    end

    return {
        theme = ui.theme or 'royal-blue',
        locale = ui.locale or 'en',
        serverName = wordmark,
        logo = logo,
        tip = type(brand.tip) == 'string' and brand.tip or '',
        colors = colors,
        sounds = ui.sounds,
    }
end

function Utils.CanCapturePortrait()
    return GetResourceState('screenshot-basic') == 'started'
end
