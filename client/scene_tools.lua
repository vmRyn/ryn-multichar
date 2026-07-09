SceneTools = {}

local function formatVector4(coords, heading)
    return ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z, heading)
end

local function formatVector3(coords)
    return ('vector3(%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z)
end

function SceneTools.CopyPedPosition()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local formatted = formatVector4(coords, heading)

    lib.setClipboard(formatted)
    lib.notify({
        title = 'ryn-multichar',
        description = ('Ped position copied: %s'):format(formatted),
        type = 'success',
    })
end

function SceneTools.CopyCameraPosition()
    if not Camera.cam or not DoesCamExist(Camera.cam) then
        lib.notify({
            title = 'ryn-multichar',
            description = 'No active scene camera. Open character select first.',
            type = 'error',
        })
        return
    end

    local pos = GetCamCoord(Camera.cam)
    local rot = GetCamRot(Camera.cam, 2)
    local fov = GetCamFov(Camera.cam)
    local block = table.concat({
        'pos = ' .. formatVector3(pos) .. ',',
        ('rot = vector3(%.2f, %.2f, %.2f),'):format(rot.x, rot.y, rot.z),
        ('fov = %.1f,'):format(fov),
    }, '\n')

    lib.setClipboard(block)
    lib.notify({
        title = 'ryn-multichar',
        description = 'Camera block copied to clipboard.',
        type = 'success',
    })
end

function SceneTools.RegisterCommands()
    if not Config.SceneTools or not Config.SceneTools.enabled then return end

    lib.addCommand(Config.SceneTools.pedCommand, {
        help = 'Copy current ped position as vector4 (scene tuning)',
        restricted = Config.SceneTools.permission,
    }, function()
        SceneTools.CopyPedPosition()
    end)

    lib.addCommand(Config.SceneTools.camCommand, {
        help = 'Copy active scene camera pos/rot/fov (scene tuning)',
        restricted = Config.SceneTools.permission,
    }, function()
        SceneTools.CopyCameraPosition()
    end)
end

CreateThread(function()
    while not Bridge.name do Wait(100) end
    SceneTools.RegisterCommands()
end)
