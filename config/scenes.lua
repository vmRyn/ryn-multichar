Config.ActiveScene = 'yacht'

--[[
    Scene presets — switch with Config.ActiveScene.
    Tune in-game with admin commands:
      /ryn_scene_pos  — copy ped vector4 to clipboard
      /ryn_scene_cam  — copy camera block to clipboard

    Presets: apartment | yacht
    idleAnim is the default look per slot when the character has no saved pose.
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
                    flag = 1,
                },
            },
            [2] = {
                ped = vector4(-785.33, 329.19, 217.04, 99.42),
                -- ~4.14m in front of ped (same framing as slot 1)
                camera = {
                    pos = vector3(-781.25, 328.51, 217.75),
                    rot = vector3(-4.0, 0.0, 279.42),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'amb@world_human_hang_out_street@male_c@idle_a',
                    name = 'idle_a',
                    flag = 1,
                },
            },
            [3] = {
                ped = vector4(-796.08, 327.22, 217.04, 140.80),
                -- ~4.14m in front of ped (same framing as slot 1)
                camera = {
                    pos = vector3(-793.47, 324.00, 217.75),
                    rot = vector3(-4.0, 0.0, 320.80),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a',
                    name = 'idle_a',
                    flag = 1,
                },
            },
        },
        lighting = true,
        weather = 'CLEAR',
        time = { hour = 14, minute = 0 },
    },

    yacht = {
        type = 'yacht',
        coords = vector3(-2058.27, -1024.50, 9.95),
        ipl = nil,
        slots = {
            [1] = {
                ped = vector4(-2045.73, -1023.99, 11.91, 140.26),
                camera = {
                    pos = vector3(-2047.98, -1026.67, 12.56),
                    rot = vector3(-4.0, 0.0, 320.26),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
                    name = 'idle_a',
                    flag = 1,
                },
            },
            [2] = {
                ped = vector4(-2092.80, -1015.54, 8.98, 250.55),
                camera = {
                    pos = vector3(-2089.22, -1016.81, 9.69),
                    rot = vector3(-4.0, 0.0, 70.55),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a',
                    name = 'idle_a',
                    flag = 1,
                },
            },
            [3] = {
                ped = vector4(-2036.27, -1033.98, 8.97, 68.33),
                camera = {
                    pos = vector3(-2039.80, -1032.58, 9.68),
                    rot = vector3(-4.0, 0.0, 248.33),
                    fov = 44.0,
                },
                idleAnim = {
                    dict = 'amb@world_human_stand_guard@male@base',
                    name = 'base',
                    flag = 1,
                },
            },
        },
        lighting = false,
        weather = 'CLEAR',
        time = { hour = 14, minute = 0 },
    },
}

Config.Scene = Config.ScenePresets[Config.ActiveScene] or Config.ScenePresets.apartment
