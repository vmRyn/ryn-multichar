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
    if not Characters.Owns(source, citizenid) then
        return {}
    end

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
        local publicIds = {}
        for id in pairs(Config.Spawns) do
            publicIds[#publicIds + 1] = id
        end
        table.sort(publicIds)

        for _, id in ipairs(publicIds) do
            local spawn = Config.Spawns[id]
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
    if not adapter or type(locationId) ~= 'string' or locationId == '' then return nil end

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
    if type(data) ~= 'table' then return false end

    local citizenid = data.citizenid
    local locationId = data.locationId
    if type(citizenid) ~= 'string' or citizenid == '' then return false end
    if type(locationId) ~= 'string' or locationId == '' then return false end

    if not Characters.Owns(source, citizenid) then return false end
    if Characters.GetLoaded(source) ~= citizenid then return false end

    local spawnData = ServerSpawn.Resolve(source, citizenid, locationId)
    if not spawnData or not spawnData.coords then return false end

    spawnData.citizenid = citizenid
    Characters.ClearPending(source, citizenid)
    Playtime.Start(source, citizenid)
    TriggerClientEvent('ryn-multichar:client:spawnSelected', source, spawnData)
    return true
end
