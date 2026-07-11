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
        crossed_arms = {
            label = 'Crossed Arms',
            anim = {
                dict = 'amb@world_human_hang_out_street@female_arms_crossed@idle_a',
                name = 'idle_a',
                flag = 1,
            },
        },
        lean_wall = {
            label = 'Lean Wall',
            anim = {
                dict = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a',
                name = 'idle_a',
                flag = 1,
            },
        },
        lean_phone = {
            label = 'Lean & Phone',
            anim = {
                dict = 'amb@world_human_leaning@male@wall@back@mobile@base',
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
        smoking = {
            label = 'Smoking',
            anim = {
                dict = 'amb@world_human_aa_smoke@male@idle_a',
                name = 'idle_c',
                flag = 49,
            },
            props = {
                {
                    model = 'prop_cs_ciggy_01',
                    bone = 28422,
                    offset = vector3(0.0, 0.0, 0.0),
                    rot = vector3(0.0, 0.0, 0.0),
                },
            },
        },
        bong = {
            label = 'Hitting the Bong',
            anim = {
                dict = 'anim@safehouse@bong',
                name = 'bong_stage3',
                flag = 1,
            },
            props = {
                {
                    model = 'hei_heist_sh_bong_01',
                    bone = 18905,
                    offset = vector3(0.10, -0.25, 0.0),
                    rot = vector3(95.0, 190.0, 180.0),
                },
            },
        },
        coffee = {
            label = 'Coffee',
            anim = {
                dict = 'amb@world_human_drinking@coffee@male@idle_a',
                name = 'idle_c',
                flag = 49,
            },
            props = {
                {
                    model = 'p_amb_coffeecup_01',
                    bone = 28422,
                    offset = vector3(0.0, 0.0, 0.0),
                    rot = vector3(0.0, 0.0, 0.0),
                },
            },
        },
        beer = {
            label = 'Beer',
            anim = {
                dict = 'amb@world_human_drinking@beer@male@idle_a',
                name = 'idle_c',
                flag = 49,
            },
            props = {
                {
                    model = 'prop_amb_beer_bottle',
                    bone = 28422,
                    offset = vector3(0.0, 0.0, 0.0),
                    rot = vector3(0.0, 0.0, 0.0),
                },
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
