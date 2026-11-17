fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-menu'
description 'RUN V - pause menu + settings'
version '0.1.0'

shared_script 'config.lua'
client_scripts {
    'client/keys.lua',
    'client/gta.lua',
    'client/settings.lua',
    'client/pause.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/vue.global.prod.js',
    'html/fonts/*.otf',
}

dependency 'pma-voice'
