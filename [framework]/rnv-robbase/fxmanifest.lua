fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-robbase'
description 'RUN V - robbery animation library (synced scenes, props, cameras). No items, no money.'
version '0.1.0'

shared_script 'config.lua'
client_scripts { 'client/util.lua', 'client/rope.lua', 'client/scenes.lua', 'client/people.lua', 'client/world.lua' }

-- rope piece model, drawn by client/rope.lua
data_file 'DLC_ITYP_REQUEST' 'stream/whip_rope_seg.ytyp'

dependencies { 'rnv-interface' }
