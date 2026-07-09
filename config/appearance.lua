Config.Appearance = {
    provider = 'auto',

    providers = {
        ['illenium-appearance'] = {
            detect = function()
                return GetResourceState('illenium-appearance') == 'started'
            end,
        },
        ['fivem-appearance'] = {
            detect = function()
                return GetResourceState('fivem-appearance') == 'started'
            end,
        },
        ['qb-clothing'] = {
            detect = function()
                return GetResourceState('qb-clothing') == 'started'
            end,
        },
        ['skinchanger'] = {
            detect = function()
                return GetResourceState('skinchanger') == 'started'
            end,
        },
    },
}

-- Custom appearance hooks (used when provider = 'custom' or as fallback)
Config.CustomAppearance = {
    applyPreview = function(_ped, _skinData)
        -- Server owners: apply saved skin data to preview ped
    end,
    openCreator = function(_isNew, _data, _cb)
        -- Server owners: open their appearance creator
    end,
}
