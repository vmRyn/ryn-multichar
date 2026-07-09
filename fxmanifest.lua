fx_version 'cerulean'
game 'gta5'

name 'ryn-multichar'
description '3D interactive multicharacter and spawn selector for QB / ESX / QBox'
author 'ryn'
version '1.0.0'

lua54 'yes'

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/nationalities.lua',
    'config/shared.lua',
    'config/scenes.lua',
    'config/premium.lua',
    'config/appearance.lua',
    'config/locales/en.lua',
    'config/locales/es.lua',
    'config/locales/init.lua',
    'shared/utils.lua',
    'bridge/init.lua',
    'shared/validate.lua',
}

client_scripts {
    'bridge/client/qb.lua',
    'bridge/client/esx.lua',
    'bridge/client/qbox.lua',
    'client/bridge_hooks.lua',
    'client/scene.lua',
    'client/camera.lua',
    'client/appearance.lua',
    'client/preview.lua',
    'client/photo.lua',
    'client/scene_tools.lua',
    'client/spawn.lua',
    'client/creation.lua',
    'client/nui.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/qb.lua',
    'bridge/server/esx.lua',
    'bridge/server/qbox.lua',
    'server/slots.lua',
    'server/housing.lua',
    'server/discord.lua',
    'server/playtime.lua',
    'server/characters.lua',
    'server/scene.lua',
    'server/spawn.lua',
    'server/tebex.lua',
    'server/admin.lua',
    'server/admin_panel.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}
