fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-appearance'
description 'RUN V - appearance + character creator (based on illenium-appearance)'
version '0.1.0'

shared_scripts {
    '@rnv-core/lib/init.lua',
    'config.lua',
}

client_scripts {
    'game/constants.lua',
    'game/util.lua',
    'client/creator.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

-- autoshot/ (clothing image capture) is kept but not loaded
-- Enable later: needs screenshot-basic and a capture UI

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/vue.global.prod.js',
    'html/fonts/*.otf',
}

dependencies { 'oxmysql', 'rnv-core', 'rnv-interface' }
