ServerSpawn = {}

local function coordsToTable(coords)
    if not coords then return nil end
    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0,
        w = coords.w or coords.h or coords.a or 0.0,
    }
end

function ServerSpawn.GetAvailable(source, citizenid)
    local locations = {}
    local adapter = Bridge.GetServer()

    if Config.SpawnOptions.lastLocation and adapter then
        locations[#locations + 1] = {
            id = 'lastLocation',
            label = L('last_location'),
            description = L('last_location_desc'),
            icon = 'history',
            coords = coordsToTable(adapter.GetLastLocation(source, citizenid)),
        }
    end

    if Config.SpawnOptions.housing then
        local housing = Housing.GetOwned(source, citizenid)
        for _, loc in ipairs(housing) do
            locations[#locations + 1] = {
                id = loc.id,
                label = loc.label,
                description = loc.description or L('housing_spawn_desc'),
                icon = loc.icon,
                coords = coordsToTable(loc.coords),
            }
        end
    end

    if Config.SpawnOptions.publicSpawns then
        for id, spawn in pairs(Config.Spawns) do
            locations[#locations + 1] = {
                id = id,
                label = spawn.label,
                description = spawn.description,
                icon = spawn.icon,
                coords = coordsToTable(spawn.coords),
            }
        end
    end

    return locations
end

function ServerSpawn.Resolve(source, citizenid, locationId)
    local adapter = Bridge.GetServer()
    if not adapter then return nil end

    if locationId == 'lastLocation' then
        return {
            id = locationId,
            coords = adapter.GetLastLocation(source, citizenid),
        }
    end

    if locationId:find('^housing:') then
        local housing = Housing.Resolve(locationId, citizenid)
        if housing then
            return {
                id = housing.id,
                coords = housing.coords,
                housingType = housing.housingType,
                extra = housing.extra,
            }
        end
        return nil
    end

    local spawn = Config.Spawns[locationId]
    if spawn then
        return {
            id = locationId,
            coords = spawn.coords,
        }
    end

    return nil
end

function ServerSpawn.Select(source, data)
    local spawnData = ServerSpawn.Resolve(source, data.citizenid, data.locationId)
    if not spawnData or not spawnData.coords then return false end

    spawnData.citizenid = data.citizenid
    Playtime.Start(source, data.citizenid)
    TriggerClientEvent('ryn-multichar:client:spawnSelected', source, spawnData)
    return true
end
