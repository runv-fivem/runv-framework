fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rnv-core'
author 'Ata Scripts'
description 'RUN V (RNV) Framework - Core'
version '0.1.0'

-- lib/ = the shared lib (lib.callback, lib.points, cache...)
-- Other resources: shared_script '@rnv-core/lib/init.lua'
ui_page 'web/build/index.html'

shared_scripts {
    'lib/core.lua',
    'lib/core_callbacks_shared.lua',
    'lib/core_version_shared.lua',
    'shared/config.lua',
}

client_scripts {
    'lib/core_client.lua',
    'lib/core_cache_client.lua',
    'lib/core_locale_client.lua',
    'lib/core_vehicleprops_client.lua',
    'lib/core_zone_client.lua',
    'lib/core_ui_alert_client.lua',
    'lib/core_ui_clipboard_client.lua',
    'lib/core_ui_context_client.lua',
    'lib/core_ui_input_client.lua',
    'lib/core_ui_client.lua',
    'lib/core_ui_menu_client.lua',
    'lib/core_ui_notify_client.lua',
    'lib/core_ui_progress_client.lua',
    'lib/core_ui_radial_client.lua',
    'lib/core_ui_skillcheck_client.lua',
    'lib/core_ui_textui_client.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'lib/callback_server.lua',
    'lib/hook_shared.lua',
    'lib/registerHook_shared.lua',
    'lib/getFilesInDirectory_server.lua',
    'lib/core_server.lua',
    'lib/core_acl_server.lua',
    'lib/core_locale_server.lua',
    'lib/core_logger_server.lua',
    'lib/core_state_server.lua',
    'lib/core_vehicleprops_server.lua',
    'lib/core_version_server.lua',
    'lib/core_zone_server.lua',
    'lib/core_ui_progress_server.lua',
    'lib/core_ui_txadmin_server.lua',
    'server/main.lua',
    'server/player.lua',
    'server/money.lua',
    'server/events.lua',
    'server/commands.lua',
}

-- What other resources may load from here (lib modules on the client, the UI, the locales)
files {
    'lib/init.lua',
    'lib/require.lua',
    'lib/package.lua',
    'lib/core_settings.lua',
    'lib/mod_*.lua',
    'lib/*_client.lua',
    'lib/*_shared.lua',
    'locales/*.json',
    'web/build/index.html',
    'web/build/**/*',
}

dependencies {
    '/server:7290',
    '/onesync',
    'oxmysql',
}
