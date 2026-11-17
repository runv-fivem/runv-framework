fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-basics'
description 'RUN V - default world settings'
version '0.1.0'

client_scripts {
    '@rnv-core/lib/init.lua',
    'config.lua',
    'client/*.lua',
}

dependency 'rnv-core'
