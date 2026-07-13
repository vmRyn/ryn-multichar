Photo = {
    active = false,
    slotIndex = 1,
}

function Photo.Enable(slotIndex)
    if not Config.PhotoMode.enabled then return false end

    Photo.active = true
    Photo.slotIndex = slotIndex or Photo.slotIndex or 1
    Camera.EnablePhotoMode(Photo.slotIndex)
    return true
end

function Photo.Disable()
    local slotIndex = Photo.slotIndex or Camera.focusSlot or Preview.activeSlot or 1
    Photo.active = false
    Camera.DisablePhotoMode(slotIndex)
end

function Photo.Adjust(data)
    if not Photo.active then return end
    Camera.AdjustOrbit(data.yaw, data.pitch, data.zoom, data.fov)
end

function Photo.Reset()
    if not Photo.active then return end
    Camera.ResetOrbit(Photo.slotIndex)
end

function Photo.SetSlot(slotIndex)
    Photo.slotIndex = slotIndex
    if Photo.active then
        Camera.EnablePhotoMode(slotIndex)
    end
end

--- Optional portrait capture (requires screenshot-basic). Returns data URL or nil.
function Photo.CapturePortrait()
    if not Utils.CanCapturePortrait() then
        return nil
    end

    local p = promise.new()
    local ok = pcall(function()
        exports['screenshot-basic']:requestScreenshot({
            encoding = 'jpg',
            quality = 0.55,
        }, function(data)
            p:resolve(data)
        end)
    end)

    if not ok then
        return nil
    end

    local result = Citizen.Await(p)
    if type(result) ~= 'string' or result == '' then
        return nil
    end
    if not result:find('^data:image/', 1, false) then
        result = 'data:image/jpeg;base64,' .. result
    end
    if #result > 180000 then
        Utils.Debug('Portrait too large, skipped')
        return nil
    end
    return result
end

CreateThread(function()
    while true do
        if Photo.active then
            if IsDisabledControlPressed(0, 34) then
                Camera.AdjustOrbit(-1.0, 0.0, 0.0)
            end
            if IsDisabledControlPressed(0, 35) then
                Camera.AdjustOrbit(1.0, 0.0, 0.0)
            end
            if IsDisabledControlPressed(0, 32) then
                Camera.AdjustOrbit(0.0, -0.5, 0.0)
            end
            if IsDisabledControlPressed(0, 33) then
                Camera.AdjustOrbit(0.0, 0.5, 0.0)
            end
            if IsDisabledControlJustPressed(0, 241) then
                Camera.AdjustOrbit(0.0, 0.0, -0.15)
            end
            if IsDisabledControlJustPressed(0, 242) then
                Camera.AdjustOrbit(0.0, 0.0, 0.15)
            end
            if IsDisabledControlJustPressed(0, 45) then
                Photo.Reset()
            end

            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            Wait(0)
        else
            Wait(250)
        end
    end
end)
