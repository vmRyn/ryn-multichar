if not Config.Slots.tebex.enabled then return end

--- Tebex console command (add to Tebex package actions):
--- ryn_multichar_tebex {packageId} {license}
---
--- Online player grant:
--- ryn_multichar_tebex_player {playerId} {packageId}
---
--- Or with explicit slot count:
--- ryn_multichar_tebex {packageId} {license} {slotCount}

Tebex = {}

local function resolveSlotAmount(packageId, explicitAmount)
    if explicitAmount and explicitAmount > 0 then
        return explicitAmount
    end

    local mapped = Config.Slots.tebex.packages[packageId]
    if mapped then
        return mapped
    end

    local numericPackage = tonumber(packageId)
    if numericPackage and Config.Slots.tebex.packages[numericPackage] then
        return Config.Slots.tebex.packages[numericPackage]
    end

    return nil
end

function Tebex.GrantSlots(license, amount, source_type)
    if not license or not amount or amount <= 0 then
        print('^1[ryn-multichar] Tebex: invalid license or slot amount^0')
        return false
    end

    if not license:find('license') then
        license = ('license:%s'):format(license)
    end

    Slots.AddTebexSlots(license, amount)
    print(('^2[ryn-multichar] Tebex: added %d slot(s) for %s (%s)^0'):format(amount, license, source_type))
    return true
end

function Tebex.QueuePending(license, amount, packageId)
    if not license or not amount or amount <= 0 then return false end

    if not license:find('license') then
        license = ('license:%s'):format(license)
    end

    MySQL.insert.await(
        'INSERT INTO ryn_multichar_tebex_pending (license, slots, package_id) VALUES (?, ?, ?)',
        { license, amount, packageId or '' }
    )

    print(('^2[ryn-multichar] Tebex: queued %d slot(s) for %s^0'):format(amount, license))
    return true
end

function Tebex.FlushPending(source)
    if not Config.Slots.tebex.autoApplyOnConnect then return end

    local adapter = Bridge.GetServer()
    if not adapter then return end

    local license = adapter.GetIdentifier(source)
    if not license then return end

    local rows = MySQL.query.await(
        'SELECT id, slots FROM ryn_multichar_tebex_pending WHERE license = ? ORDER BY id ASC',
        { license }
    ) or {}

    if #rows == 0 then return end

    local total = 0
    for _, row in ipairs(rows) do
        total = total + row.slots
        MySQL.query.await('DELETE FROM ryn_multichar_tebex_pending WHERE id = ?', { row.id })
    end

    if total > 0 then
        Slots.AddTebexSlots(license, total)
        if source > 0 then
            lib.notify(source, {
                title = 'ryn-multichar',
                description = L('tebex_applied', total),
                type = 'success',
            })
        end
    end
end

RegisterCommand('ryn_multichar_tebex', function(source, args)
    if source ~= 0 then return end

    local packageId = args[1]
    local license = args[2]
    local explicitAmount = tonumber(args[3])

    if not packageId or not license then
        print('^1[ryn-multichar] Usage: ryn_multichar_tebex {packageId} {license} [slotCount]^0')
        return
    end

    local amount = resolveSlotAmount(packageId, explicitAmount)
    if not amount then
        print(('^1[ryn-multichar] Tebex: no slot mapping for package %s^0'):format(packageId))
        return
    end

    Tebex.GrantSlots(license, amount, 'tebex')
end, true)

RegisterCommand('ryn_multichar_tebex_player', function(source, args)
    if source ~= 0 then return end

    local target = tonumber(args[1])
    local packageId = args[2]
    if not target or not packageId then
        print('^1[ryn-multichar] Usage: ryn_multichar_tebex_player {playerId} {packageId}^0')
        return
    end

    local adapter = Bridge.GetServer()
    if not adapter then return end

    local amount = resolveSlotAmount(packageId, nil)
    if not amount then
        print(('^1[ryn-multichar] Tebex: no slot mapping for package %s^0'):format(packageId))
        return
    end

    local license = adapter.GetIdentifier(target)
    if not license then return end

    Tebex.GrantSlots(license, amount, 'tebex_player')
    if target > 0 then
        lib.notify(target, {
            title = 'ryn-multichar',
            description = L('tebex_applied', amount),
            type = 'success',
        })
    end
end, true)

RegisterCommand('ryn_multichar_slots', function(source, args)
    if source ~= 0 then return end

    local license = args[1]
    local amount = tonumber(args[2])

    if not license or not amount then
        print('^1[ryn-multichar] Usage: ryn_multichar_slots {license} {slotCount}^0')
        return
    end

    Tebex.GrantSlots(license, amount, 'tebex')
end, true)

AddEventHandler('tebex:subscribe', function(packageName, username)
    local amount = Config.Slots.tebex.packages[packageName]
    if not amount then return end

    if username and type(username) == 'string' and username:find('license') then
        Tebex.QueuePending(username, amount, packageName)
        Tebex.GrantSlots(username, amount, 'tebex_subscribe')
        return
    end

    print(('^3[ryn-multichar] Tebex package "%s" purchased — run ryn_multichar_tebex %s {license}^0'):format(packageName, packageName))
end)

exports('AddTebexSlots', function(license, amount)
    return Tebex.GrantSlots(license, amount, 'export')
end)

exports('GrantTebexPackage', function(license, packageId)
    local amount = resolveSlotAmount(packageId, nil)
    if not amount then return false end
    return Tebex.GrantSlots(license, amount, 'export')
end)

exports('GrantTebexPackageToPlayer', function(source, packageId)
    local adapter = Bridge.GetServer()
    if not adapter then return false end

    local amount = resolveSlotAmount(packageId, nil)
    if not amount then return false end

    local license = adapter.GetIdentifier(source)
    if not license then return false end

    return Tebex.GrantSlots(license, amount, 'export_player')
end)
