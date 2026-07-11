Camera = {
    active = false,
    cam = nil,
    transitioning = false,
    previewing = false,
    photoMode = false,
    focusSlot = 1,
    orbit = {
        yaw = 0.0,
        pitch = -8.0,
        distance = Config.PhotoMode.defaultDistance,
        fov = Config.PhotoMode.defaultFov,
    },
}

local function easeOutCubic(t)
    return 1 - ((1 - t) ^ 3)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function ensureCam()
    if Camera.cam then return Camera.cam end

    Camera.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    RenderScriptCams(true, false, 0, true, true)
    Camera.active = true
    return Camera.cam
end

local function getFocusPosition(slotIndex)
    local ped = Preview.peds[slotIndex]
    if ped and DoesEntityExist(ped) then
        return GetEntityCoords(ped) + vector3(0.0, 0.0, 0.55)
    end

    local slotCoords = Scene.GetSlotCoords(slotIndex)
    if slotCoords then
        return vector3(slotCoords.x, slotCoords.y, slotCoords.z + 0.55)
    end

    return Config.Scene.coords + vector3(0.0, 0.0, 0.55)
end

local function getOrbitPosition(focusPos, yaw, pitch, distance)
    local yawRad = math.rad(yaw)
    local pitchRad = math.rad(pitch)
    local cosPitch = math.cos(pitchRad)

    return vector3(
        focusPos.x + distance * cosPitch * math.sin(yawRad),
        focusPos.y + distance * cosPitch * math.cos(yawRad),
        focusPos.z + distance * math.sin(pitchRad)
    )
end

function Camera.ApplyOrbit(slotIndex)
    if not Camera.cam then ensureCam() end
    if not Camera.cam then return end

    slotIndex = slotIndex or Camera.focusSlot
    Camera.focusSlot = slotIndex

    local focusPos = getFocusPosition(slotIndex)
    local camPos = getOrbitPosition(focusPos, Camera.orbit.yaw, Camera.orbit.pitch, Camera.orbit.distance)

    SetCamCoord(Camera.cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(Camera.cam, focusPos.x, focusPos.y, focusPos.z)
    SetCamFov(Camera.cam, Camera.orbit.fov)
end

function Camera.ResetOrbit(slotIndex)
    local camConfig = Scene.GetSlotCamera(slotIndex or Camera.focusSlot)
    Camera.orbit = {
        yaw = camConfig and camConfig.rot.z or 0.0,
        pitch = camConfig and camConfig.rot.x or -8.0,
        distance = Config.PhotoMode.defaultDistance,
        fov = camConfig and (camConfig.fov or Config.PhotoMode.defaultFov) or Config.PhotoMode.defaultFov,
    }
    Camera.ApplyOrbit(slotIndex)
end

function Camera.EnablePhotoMode(slotIndex)
    if not Config.PhotoMode.enabled then return false end

    Camera.photoMode = true
    Camera.previewing = false
    Camera.transitioning = false
    Camera.focusSlot = slotIndex or Camera.focusSlot or 1

    ensureCam()
    Camera.ResetOrbit(Camera.focusSlot)
    return true
end

function Camera.DisablePhotoMode(slotIndex)
    Camera.photoMode = false
    Camera.previewing = false
    Camera.transitioning = false
    Camera.Activate(slotIndex or Camera.focusSlot or 1)
end

function Camera.AdjustOrbit(deltaYaw, deltaPitch, deltaZoom, deltaFov)
    if not Camera.photoMode or not Camera.cam then return end

    Camera.orbit.yaw = Camera.orbit.yaw + (deltaYaw or 0.0) * Config.PhotoMode.rotateSpeed
    Camera.orbit.pitch = clamp(
        Camera.orbit.pitch + (deltaPitch or 0.0) * Config.PhotoMode.rotateSpeed,
        Config.PhotoMode.pitchMin,
        Config.PhotoMode.pitchMax
    )
    Camera.orbit.distance = clamp(
        Camera.orbit.distance + (deltaZoom or 0.0) * Config.PhotoMode.zoomSpeed,
        Config.PhotoMode.minDistance,
        Config.PhotoMode.maxDistance
    )

    if deltaFov then
        Camera.orbit.fov = clamp(
            Camera.orbit.fov + deltaFov,
            Config.PhotoMode.minFov,
            Config.PhotoMode.maxFov
        )
    end

    Camera.ApplyOrbit(Camera.focusSlot)
end

function Camera.Activate(slotIndex)
    slotIndex = tonumber(slotIndex) or slotIndex
    local camConfig = Scene.GetSlotCamera(slotIndex)
    if not camConfig then return end

    -- Reuse the existing cam so we never drop RenderScriptCams (that flash is black/dark).
    ensureCam()
    SetCamCoord(Camera.cam, camConfig.pos.x, camConfig.pos.y, camConfig.pos.z)
    SetCamRot(Camera.cam, camConfig.rot.x, camConfig.rot.y, camConfig.rot.z, 2)
    SetCamFov(Camera.cam, camConfig.fof or camConfig.fov or 40.0)
    RenderScriptCams(true, false, 0, true, true)

    Camera.active = true
    Camera.focusSlot = slotIndex
    Camera.transitioning = false
end

function Camera.Deactivate()
    if Camera.cam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(Camera.cam, false)
        Camera.cam = nil
    end
    Camera.active = false
    Camera.transitioning = false
    Camera.previewing = false
    Camera.photoMode = false
end

function Camera.TransitionTo(targetPos, targetRot, targetFov, duration)
    if Camera.photoMode then return end
    if not targetPos then return end

    if not Camera.cam then
        ensureCam()
        SetCamCoord(Camera.cam, targetPos.x, targetPos.y, targetPos.z)
        if targetRot then
            SetCamRot(Camera.cam, targetRot.x, targetRot.y, targetRot.z, 2)
        end
        if targetFov then
            SetCamFov(Camera.cam, targetFov)
        end
        RenderScriptCams(true, false, 0, true, true)
        return
    end

    -- Interrupt any in-flight transition so rapid slot switches stay responsive.
    Camera.transitioning = true
    local transitionId = (Camera._transitionId or 0) + 1
    Camera._transitionId = transitionId

    local fromPos = GetCamCoord(Camera.cam)
    local fromRot = GetCamRot(Camera.cam, 2)
    local fromFov = GetCamFov(Camera.cam)
    local toRot = targetRot or fromRot
    local toFov = targetFov or fromFov
    duration = duration or 750
    local start = GetGameTimer()

    CreateThread(function()
        while Camera.cam and not Camera.photoMode and Camera._transitionId == transitionId do
            local elapsed = GetGameTimer() - start
            local progress = math.min(elapsed / duration, 1.0)
            local eased = easeOutCubic(progress)

            SetCamCoord(
                Camera.cam,
                lerp(fromPos.x, targetPos.x, eased),
                lerp(fromPos.y, targetPos.y, eased),
                lerp(fromPos.z, targetPos.z, eased)
            )
            SetCamRot(
                Camera.cam,
                lerp(fromRot.x, toRot.x, eased),
                lerp(fromRot.y, toRot.y, eased),
                lerp(fromRot.z, toRot.z, eased),
                2
            )
            SetCamFov(Camera.cam, lerp(fromFov, toFov, eased))

            if progress >= 1.0 then break end
            Wait(0)
        end

        if Camera._transitionId == transitionId then
            Camera.transitioning = false
        end
    end)
end

function Camera.FocusSlot(slotIndex)
    slotIndex = tonumber(slotIndex) or slotIndex
    Camera.focusSlot = slotIndex
    Camera.previewing = false

    if Camera.photoMode then
        Camera.ApplyOrbit(slotIndex)
        return
    end

    local camConfig = Scene.GetSlotCamera(slotIndex)
    if not camConfig then return end

    -- Interiors: snap instantly. Lerping between slot cams flies through walls (black flash).
    local scene = Config.Scene
    local interior = scene and (
        scene.ipl
        or scene.type == 'apartment'
        or scene.type == 'interior'
        or scene.type == 'studio'
    )

    if interior or not Camera.cam or not Camera.active then
        Camera.Activate(slotIndex)
        return
    end

    Camera.TransitionTo(camConfig.pos, camConfig.rot, camConfig.fov or 40.0, 400)
end

function Camera.PreviewCoords(coords)
    if Camera.photoMode then return end
    if not coords then return end

    local x = coords.x or coords[1]
    local y = coords.y or coords[2]
    local z = coords.z or coords[3]
    local heading = coords.w or coords[4] or 0.0
    if not x or not y or not z then return end

    local preview = Config.SpawnPreview or {}
    local height = preview.height or 55.0
    local pullback = preview.pullback or 32.0
    local fov = preview.fov or 42.0
    local pitch = preview.pitch or -52.0
    local duration = preview.transitionMs or 700

    Camera.previewing = true
    SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(x, y, z)

    -- Angled bird's-eye: high and behind the spawn, looking down at it.
    local headingRad = math.rad(heading)
    local previewPos = vector3(
        x - math.sin(headingRad) * pullback,
        y - math.cos(headingRad) * pullback,
        z + height
    )
    local previewRot = vector3(pitch, 0.0, heading)

    if not Camera.cam or not Camera.active then
        ensureCam()
        SetCamCoord(Camera.cam, previewPos.x, previewPos.y, previewPos.z)
        SetCamRot(Camera.cam, previewRot.x, previewRot.y, previewRot.z, 2)
        SetCamFov(Camera.cam, fov)
        PointCamAtCoord(Camera.cam, x, y, z + 0.8)
        RenderScriptCams(true, false, 0, true, true)
        Camera.active = true
        return
    end

    Camera.TransitionTo(previewPos, previewRot, fov, duration)

    -- Keep the look-at locked on the spawn during/after the move.
    local transitionId = Camera._transitionId
    CreateThread(function()
        local endAt = GetGameTimer() + (duration or 350) + 50
        while Camera.cam and Camera._transitionId == transitionId and GetGameTimer() < endAt do
            PointCamAtCoord(Camera.cam, x, y, z + 0.8)
            Wait(0)
        end
        if Camera.cam and Camera._transitionId == transitionId then
            PointCamAtCoord(Camera.cam, x, y, z + 0.8)
        end
    end)
end

function Camera.ResetPreview(slotIndex)
    if Camera.photoMode then
        Camera.ResetOrbit(slotIndex)
        return
    end

    if not Camera.previewing then return end
    Camera.FocusSlot(slotIndex or 1)
end
