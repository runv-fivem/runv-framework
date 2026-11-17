fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-party'
description 'RUN V - parties: invite by ID, max 3 members'
version '0.1.0'

shared_scripts {
    '@rnv-core/lib/init.lua',
    'config.lua',
}
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/vue.global.prod.js',
    'html/fonts/*.otf',
}

dependencies { 'rnv-core', 'rnv-interface' }
