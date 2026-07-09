Spawn = {
    activeSlot = 1,
}

function Spawn.GetAvailableLocations(citizenid)
    return lib.callback.await('ryn-multichar:server:getSpawnLocations', false, citizenid) or {}
end

function Spawn.SetActiveSlot(slotIndex)
    Spawn.activeSlot = slotIndex or 1
end

function Spawn.PreviewLocation(coords)
    if not coords then return end
    Camera.PreviewCoords(coords)
end

function Spawn.TriggerFrameworkLoaded()
    local adapter = Bridge.GetClient()
    if adapter and adapter.TriggerPlayerLoaded then
        adapter.TriggerPlayerLoaded()
        return
    end

    if Bridge.name == 'qbox' or Bridge.name == 'qb' then
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
    elseif Bridge.name == 'esx' then
        TriggerEvent('esx:playerLoaded', {})
    end
end

function Spawn.TeleportTo(spawnData)
    if not spawnData or not spawnData.coords then return end

    local coords = spawnData.coords

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local ped = cache.ped
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)

    Spawn.TriggerFrameworkLoaded()

    if spawnData.housingType == 'ps-housing' and spawnData.extra and spawnData.extra.propertyId then
        TriggerServerEvent('ps-housing:server:enterProperty', tostring(spawnData.extra.propertyId))
    elseif spawnData.housingType == 'qb-houses' and spawnData.extra and spawnData.extra.house then
        TriggerEvent('qb-houses:client:enterOwnedHouse', spawnData.extra.house)
    elseif spawnData.housingType == 'qb-apartments' and spawnData.extra and spawnData.extra.apartmentType then
        TriggerEvent('apartments:client:SetHomeBlip', spawnData.extra.apartmentType)
        TriggerEvent('qb-apartments:client:LastLocationHouse', spawnData.extra.apartmentType)
    end

    if Bridge.name == 'qbox' or Bridge.name == 'qb' then
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    end

    Wait(500)
    DoScreenFadeIn(500)
    DisplayRadar(true)
end

RegisterNetEvent('ryn-multichar:client:spawnSelected', function(spawnData)
    Camera.Deactivate()
    Spawn.TeleportTo(spawnData)
end)
