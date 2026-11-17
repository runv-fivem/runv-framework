-- This resource is part of the default Cfx.re asset pack (cfx-server-data)
-- Altering or recreating for local use only is strongly discouraged

version '1.0.0'
author 'Cfx.re <root@cfx.re>'
description 'Provides baseline chat functionality using a NUI-based interface.'
repository 'https://github.com/citizenfx/cfx-server-data'

ui_page 'dist/ui.html'

client_script 'cl_chat.lua'
server_scripts {
  'sv_chat.lua',
  'sv_rnv.lua',
}

files {
  'dist/ui.html',
  'dist/index.css',
  'dist/chat.js',
  'html/vendor/*.css',
  'html/vendor/fonts/*.woff2',
  'rnv/style.css',
  'rnv/fonts/*.otf',
}

-- RNV theme (opens with Enter, Global + Party modes)
chat_theme 'rnv' {
  styleSheet = 'rnv/style.css',
  msgTemplates = {
    default = '<span class="time">{0}</span><span class="author">{1}:</span> {2}',
    defaultAlt = '<span class="time">{0}</span>{1}',
  },
}

fx_version 'adamant'
games { 'rdr3', 'gta5' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
nui_callback_strict_mode 'true'
