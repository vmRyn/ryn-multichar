if Config.AdminCommands.enabled then
    local function clampSlots(amount)
        if Config.Slots.max then
            amount = math.min(amount, Config.Slots.max)
        end
        return math.max(1, amount)
    end

    lib.addCommand(Config.AdminCommands.setSlots, {
        help = 'Set character slot limit for a player',
        restricted = Config.AdminCommands.permission,
        params = {
            { name = 'target', type = 'playerId', help = 'Player server ID' },
            { name = 'amount', type = 'number', help = 'Slot count' },
        },
    }, function(source, args)
        local target = args.target
        local amount = tonumber(args.amount)
        if not target or not amount or amount < 1 then return end

        local adapter = Bridge.GetServer()
        if not adapter then return end

        amount = clampSlots(amount)

        local license = adapter.GetIdentifier(target)
        Slots.SetLimit(license, amount, 'admin')

        if source > 0 then
            lib.notify(source, {
                title = 'ryn-multichar',
                description = L('slots_set', amount, target),
                type = 'success',
            })
        end
    end)

    lib.addCommand(Config.AdminCommands.addSlots, {
        help = 'Add character slots to a player',
        restricted = Config.AdminCommands.permission,
        params = {
            { name = 'target', type = 'playerId', help = 'Player server ID' },
            { name = 'amount', type = 'number', help = 'Slots to add' },
        },
    }, function(source, args)
        local target = args.target
        local amount = tonumber(args.amount)
        if not target or not amount or amount < 1 then return end

        local adapter = Bridge.GetServer()
        if not adapter then return end

        local license = adapter.GetIdentifier(target)
        local current = Slots.GetLimit(license)
        local nextLimit = clampSlots(current + amount)

        Slots.SetLimit(license, nextLimit, 'admin')

        if source > 0 then
            lib.notify(source, {
                title = 'ryn-multichar',
                description = L('slots_added', amount, nextLimit),
                type = 'success',
            })
        end
    end)

    lib.addCommand(Config.AdminCommands.enableChar, {
        help = 'Enable extra character slot(s) for a player',
        restricted = Config.AdminCommands.permission,
        params = {
            { name = 'target', type = 'playerId', help = 'Player server ID' },
            { name = 'amount', type = 'number', help = 'Slots to enable', optional = true },
        },
    }, function(source, args)
        local target = args.target
        local amount = tonumber(args.amount) or 1
        if not target or amount < 1 then return end

        local adapter = Bridge.GetServer()
        if not adapter then return end

        local license = adapter.GetIdentifier(target)
        local current = Slots.GetLimit(license)
        local nextLimit = clampSlots(current + amount)

        Slots.SetLimit(license, nextLimit, 'admin')

        if source > 0 then
            lib.notify(source, {
                title = 'ryn-multichar',
                description = L('slots_enabled', amount, target, nextLimit),
                type = 'success',
            })
        end
    end)
end
