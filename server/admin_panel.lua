AdminPanel = {}

local function isAdmin(source)
    if source == 0 then return true end
    return IsPlayerAceAllowed(source, Config.AdminPanel.permission)
end

function AdminPanel.CanOpen(source)
    return Config.AdminPanel.enabled and isAdmin(source)
end

function AdminPanel.ListEntries(search)
    local limit = Config.AdminPanel.maxResults or 100
    search = search and search:gsub('^%s*(.-)%s*$', '%1') or ''

    if search ~= '' then
        return MySQL.query.await(
            'SELECT license, slots, source, updated_at FROM ryn_multichar_slots WHERE license LIKE ? ORDER BY updated_at DESC LIMIT ?',
            { '%' .. search .. '%', limit }
        ) or {}
    end

    return MySQL.query.await(
        'SELECT license, slots, source, updated_at FROM ryn_multichar_slots ORDER BY updated_at DESC LIMIT ?',
        { limit }
    ) or {}
end

function AdminPanel.GetOnlinePlayers()
    local players = {}
    local adapter = Bridge.GetServer()
    if not adapter then return players end

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local license = adapter.GetIdentifier(source)
        if license then
            players[#players + 1] = {
                source = source,
                name = GetPlayerName(source) or ('Player %d'):format(source),
                license = license,
                slots = Slots.GetLimit(license),
            }
        end
    end

    table.sort(players, function(a, b)
        return a.source < b.source
    end)

    return players
end

function AdminPanel.SetEntry(source, license, amount)
    if not isAdmin(source) then return false, 'no_permission' end
    if not license or license == '' then return false, 'invalid_license' end

    amount = tonumber(amount)
    if not amount or amount < 1 then return false, 'invalid_amount' end

    if Config.Slots.max then
        amount = math.min(amount, Config.Slots.max)
    end

    Slots.SetLimit(license, amount, 'admin')
    return true
end

function AdminPanel.DeleteEntry(source, license)
    if not isAdmin(source) then return false, 'no_permission' end
    if not license or license == '' then return false, 'invalid_license' end

    MySQL.query.await('DELETE FROM ryn_multichar_slots WHERE license = ?', { license })
    return true
end

if Config.AdminPanel.enabled then
    lib.addCommand(Config.AdminPanel.command, {
        help = 'Open character slot management panel',
        restricted = Config.AdminPanel.permission,
    }, function(source)
        if source < 1 then return end
        TriggerClientEvent('ryn-multichar:client:openAdmin', source)
    end)
end
