Config = {}

-- 'auto' | 'qb' | 'esx' | 'qbox'
Config.Framework = 'qbox'

Config.Debug = false

Config.ESX = {
    -- 'legacy' = full users insert (older ESX + ox_inventory)
    -- 'minimal' = core columns only (modern ESX; inventory via ox_inventory after join)
    mode = 'legacy',
    identifierFormat = 'char%d:%s',
}

Config.SceneTools = {
    enabled = true,
    permission = 'group.admin',
    pedCommand = 'ryn_scene_pos',
    camCommand = 'ryn_scene_cam',
    snapPedsToGround = true,
}

Config.Slots = {
    default = 3,
    max = nil, -- nil = unlimited, enforced per license only
    overrides = {
        -- ['license2:abc123...'] = 5,
    },
    tebex = {
        enabled = true,
        autoApplyOnConnect = true,
        packages = {
            -- [packageId] = slotsToAdd,
            -- ['1234567'] = 2,
        },
    },
}

Config.AdminCommands = {
    enabled = true,
    permission = 'group.admin',
    setSlots = 'setslots',
    addSlots = 'addslots',
    enableChar = 'enablechar', -- legacy alias: grant extra character slot(s)
}

Config.CreationFields = {
    { name = 'firstname',   label = 'First Name',    type = 'text',   required = true },
    { name = 'lastname',    label = 'Last Name',     type = 'text',   required = true },
    { name = 'birthdate',   label = 'Date of Birth', type = 'date',   required = true },
    { name = 'gender',      label = 'Gender',        type = 'select', required = true, options = { 'male', 'female' } },
    { name = 'nationality', label = 'Nationality',   type = 'autocomplete', required = false, options = NationalityOptions },
}

Config.Spawns = {
    ['legion'] = {
        label = 'Legion Square',
        coords = vector4(195.17, -933.77, 29.7, 144.5),
        icon = 'map-pin',
    },
    ['policedp'] = {
        label = 'Police Department',
        coords = vector4(428.23, -984.28, 29.76, 3.5),
        icon = 'shield',
    },
    ['paleto'] = {
        label = 'Paleto Bay',
        coords = vector4(80.35, 6424.12, 31.67, 45.5),
        icon = 'map-pin',
    },
}

Config.SpawnOptions = {
    lastLocation = true,
    publicSpawns = true,
    housing = true,
}

Config.Housing = {
    providers = { 'qb-houses', 'qb-apartments', 'qbx_apartments', 'ps-housing' },
    custom = {
        getOwned = function(_source, _citizenid)
            return {}
        end,
    },
}

Config.StarterItems = {
    enabled = true,
    items = {
        { name = 'phone', amount = 1 },
        { name = 'id_card', amount = 1 },
    },
}

Config.Relog = {
    enabled = true,
    permission = 'user', -- 'user' | 'admin' | 'none'
}

Config.Discord = {
    enabled = false,
    webhooks = {
        create = '',
        delete = '',
        login = '',
    },
}

Config.UI = {
    locale = 'en', -- 'en' | 'es'
    theme = 'royal-blue',
    colors = {
        primary = '#2D7FF9',
        background = 'rgba(5, 8, 13, 0.92)',
        surface = 'rgba(15, 22, 32, 0.88)',
        border = 'rgba(45, 127, 249, 0.14)',
        text = '#F0F4FA',
        textMuted = '#6B7A94',
        success = '#10B981',
        warning = '#F59E0B',
        danger = '#DC2626',
    },
    -- Optional server logo (URL or nui:// path). Leave empty for default RYN mark.
    logo = '',
    -- Kenney UI Audio (CC0) — bundled in web/public/sounds/kenney/
    -- Leave empty to use defaults; override with nui:// paths if needed
    sounds = {
        enabled = true,
        volume = 0.28,
        slotSelect = '',
        transition = '',
        confirm = '',
        error = '',
    },
}
