fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'rnv-inventory'
author 'Ata Scripts'
description 'RUN V grid inventory'
version '0.1.0'

dependencies {
    '/server:6116',
    '/onesync',
    'oxmysql',
    'rnv-core',
}

shared_script '@rnv-core/lib/init.lua'

rnv_libs {
    'locale',
    'table',
    'math',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/init.lua',
}

client_script 'shared/init.lua'

-- extras: for the redesigned UI (bags, vests, hotbar keys, tiers)
shared_script 'extras/config.lua'
client_script 'extras/client.lua'
server_script 'extras/server.lua'

ui_page 'web/build/index.html'

-- Files the client loads with require / data() / the UI
files {
    'client/*.lua',
    'shared/*.lua',
    'data/*.lua',
    'extras/tier.lua',
    'extras/category.lua',
    'extras/items.lua',
    'locales/*.json',
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
    'web/build/assets/fonts/*.otf',
    'web/images/*.png',
}
