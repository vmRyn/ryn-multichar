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

local function getCharacterJobName(character)
    if not character or type(character.job) ~= 'table' then return nil end
    local name = character.job.name
    if type(name) == 'string' and name ~= '' then
        return name:lower()
    end
    return nil
end

local function characterHasJob(character, jobs)
    if not jobs or #jobs == 0 then return true end
    local jobName = getCharacterJobName(character)
    if not jobName then return false end
    for _, allowed in ipairs(jobs) do
        if type(allowed) == 'string' and allowed:lower() == jobName then
            return true
        end
    end
    return false
end

local function getOwnedCharacter(source, citizenid)
    local owns, character = Characters.Owns(source, citizenid)
    if not owns then return nil end
    return character
end

function ServerSpawn.GetAvailable(source, citizenid)
    local character = getOwnedCharacter(source, citizenid)
    if not character then
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
            group = 'last',
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
                group = 'housing',
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
            local jobs = spawn.jobs
            if characterHasJob(character, jobs) then
                local isJobSpawn = type(jobs) == 'table' and #jobs > 0
                locations[#locations + 1] = {
                    id = id,
                    label = spawn.label,
                    description = spawn.description,
                    icon = spawn.icon,
                    group = isJobSpawn and 'job' or 'public',
                    coords = coordsToTable(spawn.coords),
                }
            end
        end
    end

    return locations
end

function ServerSpawn.Resolve(source, citizenid, locationId)
    local adapter = Bridge.GetServer()
    if not adapter or type(locationId) ~= 'string' or locationId == '' then return nil end

    local character = getOwnedCharacter(source, citizenid)
    if not character then return nil end

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
        if not characterHasJob(character, spawn.jobs) then
            return nil
        end
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
