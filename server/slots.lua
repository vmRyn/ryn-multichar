Slots = {}

function Slots.GetLimit(license)
    local limit

    if Config.Slots.overrides[license] then
        limit = Config.Slots.overrides[license]
    else
        local row = MySQL.single.await('SELECT slots FROM ryn_multichar_slots WHERE license = ?', { license })
        limit = row and row.slots or Config.Slots.default
    end

    if Config.Slots.max then
        limit = math.min(limit, Config.Slots.max)
    end

    return limit
end

function Slots.SetLimit(license, amount, source_type)
    source_type = source_type or 'admin'

    if Config.Slots.max then
        amount = math.min(amount, Config.Slots.max)
    end

    amount = math.max(1, amount)
    MySQL.insert.await(
        'INSERT INTO ryn_multichar_slots (license, slots, source) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE slots = ?, source = ?',
        { license, amount, source_type, amount, source_type }
    )
end

function Slots.AddTebexSlots(license, amount)
    local current = Slots.GetLimit(license)
    Slots.SetLimit(license, current + amount, 'tebex')
end

exports('GetSlotLimit', function(source)
    local adapter = Bridge.GetServer()
    if not adapter then return Config.Slots.default end
    return Slots.GetLimit(adapter.GetIdentifier(source))
end)

exports('SetSlotLimit', function(source, amount)
    local adapter = Bridge.GetServer()
    if not adapter then return end
    Slots.SetLimit(adapter.GetIdentifier(source), amount, 'admin')
end)
