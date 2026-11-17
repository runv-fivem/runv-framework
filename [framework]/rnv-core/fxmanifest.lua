fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-core'
author 'Ata Scripts'
description 'RUN V (RNV) Framework - Core'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/player.lua',
    'server/money.lua',
    'server/events.lua',
    'server/commands.lua',
}

dependencies {
    '/onesync',
    'oxmysql',
    'ox_lib',
}
