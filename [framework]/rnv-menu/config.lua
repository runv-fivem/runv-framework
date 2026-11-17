Config = {}

-- JOIN OUR DISCORD in the pause menu. Empty = button hidden
Config.DiscordUrl = ''

-- RNV settings rows, by tab. type: 'slider' (min..max), 'select' (options), 'check'
-- enabledWhen: row is greyed unless another key has that value
Config.Tabs = {
    { id = 'graphics', label = 'GRAPHICS', rows = {} },
    {
        id = 'sound', label = 'SOUND',
        rows = {
            { key = 'radioVolume', label = 'Radio', desc = 'Radio voice volume', type = 'slider', min = 0, max = 1, step = 0.05, default = 0.3 },
        },
    },
    { id = 'controls', label = 'CONTROLS', rows = {} },
    { id = 'keys', label = 'KEY BINDINGS', rows = {} }, -- GTA key bindings (client/gta.lua keymap)
    {
        id = 'social', label = 'SOCIAL',
        rows = {
            { key = 'partyInvites', label = 'Party Invitations', desc = 'Who can send you party invitations', type = 'select', options = { 'Everybody', 'Nobody' }, default = 'Everybody' },
        },
    },
    {
        id = 'other', label = 'OTHER',
        rows = {
            { key = 'keyMarkers', label = 'Display Key Markers in HUD', desc = 'Show key hints under HUD icons', type = 'check', default = true },
            { key = 'metrics', label = 'Display performance metrics', desc = 'FPS and ping in the top left corner', type = 'select', options = { 'Default', 'Custom', 'Off' }, default = 'Default' },
            { key = 'showPing', label = 'Network Latency (PING)', desc = 'Show ping (Custom metrics only)', type = 'check', default = true, enabledWhen = { key = 'metrics', value = 'Custom' } },
            { key = 'showFps', label = 'Frame Rate (FPS)', desc = 'Show frame rate (Custom metrics only)', type = 'check', default = true, enabledWhen = { key = 'metrics', value = 'Custom' } },
        },
    },
}

-- GTA settings pages shown as sections under the RNV tabs (rows, names and options come from GTA itself)
-- page = client/gta.lua GtaTabs key
Config.GtaSections = {
    graphics = { { page = 'display', title = 'DISPLAY' }, { page = 'graphics', title = 'GRAPHICS' }, { page = 'advgfx', title = 'ADVANCED GRAPHICS' } },
    sound = { { page = 'audio', title = 'AUDIO' }, { page = 'voice', title = 'VOICE CHAT' } },
    controls = { { page = 'controls', title = 'GAMEPAD' }, { page = 'keyboard', title = 'KEYBOARD / MOUSE' }, { page = 'camera', title = 'CAMERA' } },
    other = { { page = 'editor', title = 'ROCKSTAR EDITOR' } },
}
