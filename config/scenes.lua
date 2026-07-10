Config.ActiveScene = 'apartment'

--[[
    Scene presets — switch with Config.ActiveScene.
    Tune in-game with admin commands:
      /ryn_scene_pos  — copy ped vector4 to clipboard
      /ryn_scene_cam  — copy camera block to clipboard

    Presets: apartment | studio | rooftop | void
]]

Config.ScenePresets = {
    apartment = {
        type = 'apartment',
        coords = vector3(-787.3, 315.79, 217.64),
        ipl = 'apa_v_mp_h_01_a',
        slots = {
            [1] = {
                ped = vector4(-786.49, 315.79, 217.64, 270.0),
                camera = {
                    pos = vector3(-782.35, 315.79, 218.35),
                    rot = vector3(-4.0, 0.0, 90.0),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
                    name = 'idle_a',
                },
            },
            [2] = {
                ped = vector4(-788.65, 315.79, 217.64, 90.0),
                camera = {
                    pos = vector3(-786.0, 315.79, 218.35),
                    rot = vector3(-4.0, 0.0, 270.0),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'amb@world_human_leaning@male@wall@back@mobile@base',
                    name = 'base',
                },
            },
            [3] = {
                ped = vector4(-787.3, 318.15, 217.64, 180.0),
                camera = {
                    pos = vector3(-787.3, 320.0, 218.35),
                    rot = vector3(-4.0, 0.0, 180.0),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'anim@amb@casino@hangout@ped_female@stand@02a@idles',
                    name = 'idle_a',
                },
            },
        },
        lighting = true,
        weather = 'CLEAR',
        time = { hour = 21, minute = 0 },
    },

    studio = {
        type = 'studio',
        coords = vector3(-75.0, -818.0, 326.0),
        ipl = nil,
        slots = {
            [1] = {
                ped = vector4(-75.0, -818.0, 326.0, 180.0),
                camera = {
                    pos = vector3(-75.0, -820.5, 326.8),
                    rot = vector3(-5.0, 0.0, 0.0),
                    fov = 40.0,
                },
                idleAnim = {
                    dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
                    name = 'idle_a',
                },
            },
            [2] = {
                ped = vector4(-77.2, -818.0, 326.0, 140.0),
                camera = {
                    pos = vector3(-78.5, -820.0, 326.8),
                    rot = vector3(-5.0, 0.0, 25.0),
                    fov = 42.0,
                },
            },
            [3] = {
                ped = vector4(-72.8, -818.0, 326.0, 220.0),
                camera = {
                    pos = vector3(-71.5, -820.0, 326.8),
                    rot = vector3(-5.0, 0.0, -25.0),
                    fov = 42.0,
                },
            },
        },
        lighting = true,
        weather = 'EXTRASUNNY',
        time = { hour = 14, minute = 0 },
    },

    rooftop = {
        type = 'rooftop',
        coords = vector3(-141.50, -620.95, 168.82),
        ipl = nil,
        slots = {
            [1] = {
                ped = vector4(-143.20, -618.40, 168.82, 200.0),
                posePreset = 'standing',
                camera = {
                    pos = vector3(-141.80, -621.80, 169.55),
                    rot = vector3(-4.0, 0.0, 20.0),
                    fov = 38.0,
                },
                idleAnim = {
                    dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
                    name = 'idle_a',
                },
            },
            [2] = {
                ped = vector4(-139.10, -622.60, 168.82, 110.0),
                posePreset = 'lean_phone',
                camera = {
                    pos = vector3(-141.20, -624.40, 169.55),
                    rot = vector3(-4.0, 0.0, 290.0),
                    fov = 40.0,
                },
            },
            [3] = {
                ped = vector4(-144.80, -624.10, 168.82, 30.0),
                camera = {
                    pos = vector3(-146.60, -621.50, 169.55),
                    rot = vector3(-4.0, 0.0, 210.0),
                    fov = 40.0,
                },
                idleAnim = {
                    dict = 'anim@amb@casino@hangout@ped_female@stand@02a@idles',
                    name = 'idle_a',
                },
            },
        },
        lighting = false,
        weather = 'CLEAR',
        time = { hour = 20, minute = 30 },
    },

    void = {
        type = 'void',
        coords = vector3(0.0, 0.0, 500.0),
        ipl = nil,
        slots = {
            [1] = {
                ped = vector4(-1.5, 0.0, 500.0, 90.0),
                camera = {
                    pos = vector3(-4.0, 0.0, 500.8),
                    rot = vector3(-2.0, 0.0, 90.0),
                    fov = 35.0,
                },
            },
            [2] = {
                ped = vector4(0.0, 0.0, 500.0, 180.0),
                camera = {
                    pos = vector3(0.0, -3.0, 500.8),
                    rot = vector3(-2.0, 0.0, 0.0),
                    fov = 35.0,
                },
            },
            [3] = {
                ped = vector4(1.5, 0.0, 500.0, 270.0),
                camera = {
                    pos = vector3(4.0, 0.0, 500.8),
                    rot = vector3(-2.0, 0.0, 270.0),
                    fov = 35.0,
                },
            },
        },
        lighting = false,
        weather = 'CLEAR',
        time = { hour = 0, minute = 0 },
    },
}

Config.Scene = Config.ScenePresets[Config.ActiveScene] or Config.ScenePresets.apartment
