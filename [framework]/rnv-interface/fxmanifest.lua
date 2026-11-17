fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-interface'
description 'RUN V - HUD, notifications, progress bar'
version '0.1.0'

shared_scripts {
    '@rnv-core/lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/minimap.lua',
    'client/hud.lua',
    'client/notify.lua',
    'client/progress.lua',
    'client/prompt.lua',
    'client/tags.lua',
}

server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/vue.global.prod.js',
    'html/fonts/*.otf',
}

dependencies { 'rnv-core' }
