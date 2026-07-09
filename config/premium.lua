Config.PhotoMode = {
    enabled = true,
    minFov = 18.0,
    maxFov = 65.0,
    defaultFov = 35.0,
    minDistance = 1.2,
    maxDistance = 6.0,
    defaultDistance = 2.8,
    rotateSpeed = 0.35,
    zoomSpeed = 1.5,
    pitchMin = -25.0,
    pitchMax = 20.0,
}

Config.SceneSync = {
    override = true,
    freezeTime = true,
    -- nil = use active scene preset values
    weather = nil,
    time = nil,
    weatherResources = {
        'qb-weathersync',
        'qbx_weathersync',
        'cd_easytime',
        'Renewed-Weathersync',
        'av_weather',
    },
}

Config.ScenePoses = {
    enabled = true,
    defaultPreset = 'standing',
    presets = {
        standing = {
            label = 'Standing',
            anim = {
                dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
                name = 'idle_a',
                flag = 1,
            },
        },
        lean_phone = {
            label = 'Lean & Phone',
            anim = {
                dict = 'anim@amb@world_human_leaning@male@wall@back@mobile@base',
                name = 'base',
                flag = 1,
            },
            props = {
                {
                    model = 'prop_phone_ing',
                    bone = 28422,
                    offset = vector3(0.0, 0.0, 0.0),
                    rot = vector3(0.0, 0.0, 0.0),
                },
            },
        },
        sit_chair = {
            label = 'Seated',
            anim = {
                dict = 'timetable@ron@ig_5_p3',
                name = 'ig_5_p3_base',
                flag = 1,
            },
            props = {
                {
                    model = 'prop_chair_01a',
                    world = true,
                    offset = vector3(0.0, -0.45, -0.55),
                    rot = vector3(0.0, 0.0, 180.0),
                },
            },
        },
        sports_car = {
            label = 'Sports Car',
            vehicle = {
                model = 'sultanrs',
                offset = vector4(0.0, 1.8, -0.95, 90.0),
            },
            anim = {
                dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
                name = 'idle_a',
                flag = 1,
            },
        },
        muscle_car = {
            label = 'Muscle Car',
            vehicle = {
                model = 'dominator',
                offset = vector4(0.0, 1.6, -0.95, 90.0),
            },
            anim = {
                dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
                name = 'idle_a',
                flag = 1,
            },
        },
    },
}

Config.AdminPanel = {
    enabled = true,
    permission = 'group.admin',
    command = 'charslots',
    maxResults = 100,
}
