Creation = {}

function Creation.Open(slotIndex)
    SendNUIMessage({
        action = 'open',
        screen = 'creation',
        data = {
            slotIndex = slotIndex,
            fields = Config.CreationFields,
        },
    })
end

function Creation.StartAppearance(characterData)
    SetNuiFocus(false, false)

    Appearance.OpenCreator(true, characterData, function()
        local locations = Spawn.GetAvailableLocations(characterData.citizenid)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            screen = 'spawnSelect',
            data = { locations = locations, citizenid = characterData.citizenid },
        })
    end)
end
