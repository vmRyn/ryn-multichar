Housing = {}

local function isProviderEnabled(name)
    if not Config.SpawnOptions.housing then return false end

    for _, provider in ipairs(Config.Housing.providers) do
        if provider == name and GetResourceState(name):find('start') then
            return true
        end
    end

    return false
end

local function makeLocation(id, label, icon, coords, housingType, extra)
    return {
        id = id,
        label = label,
        icon = icon or 'home',
        coords = coords,
        housingType = housingType,
        extra = extra or {},
    }
end

local function parseCoords(data)
    if not data then return nil end
    if type(data) == 'vector4' then return data end
    if type(data) == 'vector3' then return vector4(data.x, data.y, data.z, 0.0) end

    if type(data) == 'string' then
        data = json.decode(data)
    end

    if type(data) ~= 'table' then return nil end

    if data.coords then
        return parseCoords(data.coords)
    end

    if data.enter then
        return parseCoords(data.enter)
    end

    local x = data.x or data[1]
    local y = data.y or data[2]
    local z = data.z or data[3]
    local w = data.w or data.h or data.a or data[4] or 0.0

    if not x or not y or not z then return nil end
    return vector4(x + 0.0, y + 0.0, z + 0.0, w + 0.0)
end

function Housing.GetQbHouses(citizenid)
    if not isProviderEnabled('qb-houses') then return {} end

    local locations = {}
    local rows = MySQL.query.await([[
        SELECT ph.house, hl.label, hl.coords
        FROM player_houses ph
        LEFT JOIN houselocations hl ON hl.name = ph.house
        WHERE ph.citizenid = ?
    ]], { citizenid })

    if not rows then return locations end

    for _, row in ipairs(rows) do
        local coordsData = row.coords and json.decode(row.coords) or nil
        local coords = nil

        if coordsData then
            coords = parseCoords(coordsData.enter or coordsData)
        end

        if not coords and row.house then
            local ok, houseCoords = pcall(function()
                return exports['qb-houses']:getHouseCoords(row.house)
            end)
            if ok then coords = parseCoords(houseCoords) end
        end

        if coords then
            locations[#locations + 1] = makeLocation(
                ('housing:qb-houses:%s'):format(row.house),
                row.label or row.house,
                'home',
                coords,
                'qb-houses',
                { house = row.house }
            )
        end
    end

    return locations
end

function Housing.GetQbApartments(citizenid)
    local apartmentResource = nil
    if isProviderEnabled('qbx_apartments') then
        apartmentResource = 'qbx_apartments'
    elseif isProviderEnabled('qb-apartments') then
        apartmentResource = 'qb-apartments'
    end

    if not apartmentResource then return {} end

    local locations = {}
    local rows = MySQL.query.await('SELECT * FROM apartments WHERE citizenid = ?', { citizenid })
    if not rows then return locations end

    for _, row in ipairs(rows) do
        local aptType = row.type or row.name
        local coords = nil
        local label = row.label or aptType

        local ok, aptData = pcall(function()
            return exports[apartmentResource]:GetApartmentCoords(aptType)
        end)
        if ok and aptData then
            coords = parseCoords(aptData)
        end

        if not coords then
            ok, aptData = pcall(function()
                return exports[apartmentResource]:GetApartmentInfo(aptType)
            end)
            if ok and aptData and aptData.coords then
                coords = parseCoords(aptData.coords.enter or aptData.coords)
                label = aptData.label or label
            end
        end

        if coords then
            locations[#locations + 1] = makeLocation(
                ('housing:qb-apartments:%s'):format(aptType),
                label,
                'building',
                coords,
                'qb-apartments',
                { apartmentType = aptType }
            )
        end
    end

    return locations
end

function Housing.GetPsHousing(citizenid)
    if not isProviderEnabled('ps-housing') then return {} end

    local locations = {}
    local rows = MySQL.query.await(
        'SELECT property_id, street, apartment, door_data FROM properties WHERE owner_citizenid = ?',
        { citizenid }
    )
    if not rows then return locations end

    for _, row in ipairs(rows) do
        local doorData = row.door_data and json.decode(row.door_data) or nil
        local coords = parseCoords(doorData)

        local label = row.street or ('Property %s'):format(row.property_id)
        if row.apartment and row.apartment ~= '' then
            label = ('%s - %s'):format(label, row.apartment)
        end

        if coords then
            locations[#locations + 1] = makeLocation(
                ('housing:ps-housing:%s'):format(row.property_id),
                label,
                'home',
                coords,
                'ps-housing',
                { propertyId = row.property_id }
            )
        end
    end

    return locations
end

function Housing.GetOwned(source, citizenid)
    local locations = {}

    local providers = {
        Housing.GetQbHouses,
        Housing.GetQbApartments,
        Housing.GetPsHousing,
    }

    for _, provider in ipairs(providers) do
        local result = provider(citizenid)
        for _, loc in ipairs(result) do
            locations[#locations + 1] = loc
        end
    end

    local custom = Config.Housing.custom.getOwned(source, citizenid)
    if custom then
        for _, loc in ipairs(custom) do
            locations[#locations + 1] = loc
        end
    end

    return locations
end

function Housing.Resolve(locationId, citizenid)
    local owned = Housing.GetOwned(0, citizenid)

    for _, loc in ipairs(owned) do
        if loc.id == locationId then
            return loc
        end
    end

    return nil
end
