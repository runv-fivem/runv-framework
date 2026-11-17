-- GTA settings, read and changed through the real GTA pause menu, hidden
-- GTA settings in the RNV screen. The patched pause menu
-- movies in stream/ add methods we call with the scaleform natives: SET_STEALTH (hide), GET_MENU_STATE,
-- ENTER_TAB, GET_SETTINGS_COUNT / _ROW / _TEXT, SET_PREF, STEP_PREF, TRIGGER_ROW, GET_SETTINGS_REVISION
-- The patched movies load on join: after changing stream/, players must reconnect

GtaDriving = false

local LANDING_MENU = 'FE_MENU_VERSION_LANDING_MENU' -- settings only: no GAME tab, so no "Disconnect"
local MENU_UNIQUE_ID_SETTINGS = 6
local PM_READY, PM_SHUTTING_DOWN = 15, 30
local FRONTEND_CONTROL = 2
local INPUT_LEFT, INPUT_RIGHT, INPUT_ACCEPT, INPUT_X = 189, 190, 201, 203
local TEXT_CHUNK_FULL_BYTES = 57
local MUTE_SCENE = 'MUTES_FRONTEND_SCENE' -- silences GTA's menu sounds (open, close, option changes) while we drive it
local MAX_PENDING_RETURNS = 20

-- GTA settings pages (menu ids)
GtaTabs = {
    display = 1023, graphics = 1137, advgfx = 1138,
    audio = 1022, voice = 1139,
    controls = 1024, keyboard = 1140, camera = 1136,
    editor = 1146,
}
local GRAPHICS_TABS = { graphics = true, advgfx = true }

local INPUT_CANCEL, INPUT_DELETE = 202, 214
local REBIND_TIMEOUT_MS = 30000

local WARNING_KINDS = {
    [GetHashKey('GFX_WARNING_BODY')] = 'keepSettings',
    [GetHashKey('GFX_RESTART_BODY')] = 'restartRequired',
    [GetHashKey('GFX_WARNING_MP')] = 'onlineWarning',
    [GetHashKey('MAPPING_CONFLICT_BODY')] = 'keymapConflict',
    [GetHashKey('MAPPING_MULTI_CONFLICT_BODY')] = 'keymapConflict',
    [GetHashKey('UNMAPPABLE_CONFLICT_BODY')] = 'keymapUnmappable',
    [GetHashKey('MAPPING_AUTOSAVE_LOADED')] = 'keymapAutosave',
    [GetHashKey('MAPPING_RESTORE_DEFAULTS')] = 'keymapRestore',
    [GetHashKey('UNMAPPED_WARNING_NO_ESCAPE')] = 'keymapCantLeave',
    [GetHashKey('CONFLICT_WARNING')] = 'keymapLeaveConflict',
    [GetHashKey('UNMAPPED_WARNING')] = 'keymapLeaveUnmapped',
}

local menuOpen = false
local inKeymap = false
local currentTab = nil
local concealUntil = 0
local textCache = {}
local sessionWarnings = {} -- GTA prompts seen since the menu opened (e.g. restartRequired)
local restoreRows = {} -- [tab] = row index of the page's "Restore Defaults"

-- pmx.ts ------------------------------------------------------------------

local function begin(name, args)
    if not BeginScaleformMovieMethodOnFrontend(name) then return false end
    for _, arg in ipairs(args or {}) do
        if type(arg) == 'boolean' then
            ScaleformMovieMethodAddParamBool(arg)
        elseif type(arg) == 'string' then
            ScaleformMovieMethodAddParamTextureNameString(arg)
        elseif math.floor(arg) == arg then
            ScaleformMovieMethodAddParamInt(arg)
        else
            ScaleformMovieMethodAddParamFloat(arg)
        end
    end
    return true
end

-- calls = { { name, args } }. Sends up to 20 at once and waits for all returns (one frame instead of 20)
local function batch(calls, asInt)
    local results = {}
    for offset = 0, #calls - 1, MAX_PENDING_RETURNS do
        local handles = {}
        for i = offset + 1, math.min(offset + MAX_PENDING_RETURNS, #calls) do
            handles[i] = begin(calls[i][1], calls[i][2]) and EndScaleformMovieMethodReturnValue() or false
        end
        local timeout = GetGameTimer() + 1000
        local ready = false
        while not ready and GetGameTimer() < timeout do
            ready = true
            for _, handle in pairs(handles) do
                if handle and not IsScaleformMovieMethodReturnValueReady(handle) then ready = false end
            end
            if not ready then Wait(0) end
        end
        for i, handle in pairs(handles) do
            if handle and IsScaleformMovieMethodReturnValueReady(handle) then
                results[i] = asInt and GetScaleformMovieMethodReturnValueInt(handle) or GetScaleformMovieMethodReturnValueString(handle)
            end
        end
    end
    return results
end

local function call(name, args, asInt)
    return batch({ { name, args } }, asInt)[1]
end

-- Navigation calls: at most one per frame
local lastNavigationFrame = -1
local function navigate(name, args)
    while GetFrameCount() == lastNavigationFrame do Wait(0) end
    lastNavigationFrame = GetFrameCount()
    return call(name, args)
end

local function isError(result)
    return result == nil or result:sub(1, 4) == 'ERR|'
end

local function split(text)
    local parts = {}
    for part in (text .. '|'):gmatch('([^|]*)|') do parts[#parts + 1] = part end
    return parts
end

-- texts = { { row, part } } -> strings. Long texts come back in chunks of up to 57 bytes
local function readTexts(requests)
    local calls = {}
    for i, request in ipairs(requests) do calls[i] = { 'GET_SETTINGS_TEXT', { request[1], request[2], 0 } } end
    local first = batch(calls)
    local texts = {}
    for i, request in ipairs(requests) do
        local text = isError(first[i]) and '' or first[i]
        local chunk = text
        while #chunk >= TEXT_CHUNK_FULL_BYTES do
            chunk = call('GET_SETTINGS_TEXT', { request[1], request[2], #text })
            if isError(chunk) then break end
            text = text .. chunk
        end
        texts[i] = text
    end
    return texts
end

-- pause_menu.ts -------------------------------------------------------------

local function waitUntil(check, timeoutMs)
    local timeout = GetGameTimer() + timeoutMs
    while not check() do
        if GetGameTimer() > timeout then return false end
        Wait(0)
    end
    return true
end

local function waitFrames(count)
    local target = GetFrameCount() + count
    while GetFrameCount() < target do Wait(0) end
end

-- Hides the menu until SET_STEALTH works, and keeps the mouse cursor hidden while it is open
local function startTick()
    CreateThread(function()
        while menuOpen do
            if GetGameTimer() < concealUntil then SuppressFrontendRenderingThisFrame() end
            SetMouseCursorVisible(false)
            SetMouseCursorVisibleInMenus(false) -- else GTA's menu cursor can show as a square over our screen
            Wait(0)
        end
    end)
end

-- Real menu input (needed for STEP_PREF and GTA's prompts): unlock the frontend for a few frames
local function withMenuInput(fn)
    ReleaseControlOfFrontend()
    waitFrames(1)
    local result = fn()
    waitFrames(3)
    if menuOpen and IsPauseMenuActive() then TakeControlOfFrontend() end
    return result
end

local function pressFrontend(input)
    withMenuInput(function()
        for i = 1, 3 do
            EnableControlAction(FRONTEND_CONTROL, input, true)
            SetControlNormal(FRONTEND_CONTROL, input, 1.0)
            Wait(0)
        end
    end)
end

local function openMenu()
    if menuOpen and IsPauseMenuActive() then return true end
    GtaDriving = true
    if IsPauseMenuActive() or GetPauseMenuState() ~= 0 then
        SetFrontendActive(false)
        waitUntil(function() return GetPauseMenuState() == 0 end, 3000)
    end

    StartAudioScene(MUTE_SCENE)
    ActivateFrontendMenu(GetHashKey(LANDING_MENU), false, MENU_UNIQUE_ID_SETTINGS)
    menuOpen = true
    sessionWarnings = {}
    currentTab = nil
    concealUntil = GetGameTimer() + 5000
    startTick()
    SetMouseCursorVisibleInMenus(false)

    local hidden = waitUntil(function() return call('SET_STEALTH', { true }) == 'OK' end, 5000)
    concealUntil = math.min(concealUntil, GetGameTimer() + 1500)
    local ready = hidden and waitUntil(function() return GetPauseMenuState() == PM_READY and IsFrontendReadyForControl() end, 5000)
    -- GET_MENU_STATE: menuId|level|...; level >= 1 = the settings category list is up
    local listed = ready and waitUntil(function()
        return (tonumber(split(call('GET_MENU_STATE') or '')[2]) or 0) >= 1
    end, 2000)
    concealUntil = 0
    if not listed then
        print('[rnv-menu] GTA pause menu did not load (reconnect after a stream/ change)')
        GtaClose()
        return false
    end
    TakeControlOfFrontend()
    return true
end

local answerWarnings

-- X = "Apply Changes" on the open graphics page. The menu ignores it for a moment after a change: retry while dirty
-- GTA drops unapplied Advanced Graphics changes when the page is left, so this runs before every page switch
local function applyCurrent()
    if not GRAPHICS_TABS[currentTab] then return end
    for i = 1, 3 do
        if not PauseMenuIsContextActive(GetHashKey('GFX_Dirty')) then return end
        Wait(300)
        pressFrontend(INPUT_X)
        answerWarnings(sessionWarnings)
    end
end

local function enterTab(tab)
    if currentTab == tab then return true end
    -- leaving the key bindings page: close and reopen the menu
    if inKeymap then
        GtaClose()
        if not openMenu() then return false end
    end
    applyCurrent()
    local timeout = GetGameTimer() + 3000
    while GetGameTimer() < timeout do
        -- leaving a graphics page with unapplied changes: GTA asks "apply them now?" -> Yes
        if IsWarningMessageActive() then answerWarnings(sessionWarnings, 0) end
        local result = navigate('ENTER_TAB', { GtaTabs[tab] })
        if result == 'ALREADY' or result == 'ENTERED' then
            if result == 'ENTERED' then call('SET_STEALTH', { true }) end
            currentTab = tab
            return waitUntil(function() return (call('GET_SETTINGS_COUNT', nil, true) or 0) > 0 end, 1500)
        end
        if result ~= 'ERR|list_not_ready' and isError(result) then return false end
    end
    return false
end

-- style 1 / 10-19 = list, 2 / 20-29 = slider
local function controlOf(style)
    if style == 1 or (style >= 10 and style < 20) then return 'list' end
    if style == 2 or (style >= 20 and style < 30) then return 'slider' end
    return 'none'
end

-- Rows of the current tab. GET_SETTINGS_ROW: prefId|style|value|max|active|?|optionCount|codeBuilt|kind
-- kind: pref (list / slider), action (Restore Defaults, music scans), display (video memory), separator, empty
-- Code built lists (resolution, MSAA, devices...) only give the current text: they change with STEP_PREF
local function readRows(tab)
    local count = call('GET_SETTINGS_COUNT', nil, true) or 0
    local calls = {}
    for i = 0, count - 1 do calls[#calls + 1] = { 'GET_SETTINGS_ROW', { i } } end
    local raws = batch(calls)

    local rows, requests, targets = {}, {}, {}
    for i = 0, count - 1 do
        local raw = raws[i + 1]
        local p = isError(raw) and {} or split(raw)
        local kind = p[9]
        if kind == 'action' then restoreRows[tab] = i end -- the last action row is Restore Defaults
        if kind == 'pref' or kind == 'action' or kind == 'display' then
            local row = {
                tab = tab, row = i, kind = kind, prefId = tonumber(p[1]),
                control = kind == 'pref' and controlOf(tonumber(p[2])) or 'none',
                value = tonumber(p[3]), max = tonumber(p[4]), active = tonumber(p[5]),
                optionCount = tonumber(p[7]), codeBuilt = p[8] == '1',
            }
            local key = tab .. '|' .. i .. '|' .. row.prefId .. '|' .. p[2] .. '|' .. row.optionCount
            local cached = textCache[key]
            -- display rows (video memory) change their text, so they are read every time
            if not cached or kind == 'display' then
                cached = { label = '', options = {} }
                textCache[key] = cached
                requests[#requests + 1] = { i, -1 }
                targets[#targets + 1] = { cached, 'label' }
                if row.control == 'list' and not row.codeBuilt then
                    for part = 0, row.optionCount - 1 do
                        requests[#requests + 1] = { i, part }
                        targets[#targets + 1] = { cached.options, part + 1 }
                    end
                end
            end
            row.cache = cached
            if row.codeBuilt and row.control == 'list' then
                requests[#requests + 1] = { i, 0 }
                targets[#targets + 1] = { row, 'text' }
            end
            rows[#rows + 1] = row
        end
    end

    local texts = readTexts(requests)
    for i, target in ipairs(targets) do target[1][target[2]] = texts[i] end
    for _, row in ipairs(rows) do
        row.label = row.cache.label
        row.options = row.codeBuilt and { row.text } or row.cache.options
        row.cache, row.text = nil, nil
    end

    -- graphics pages: GTA's video memory bar on top (GET_VIDEO_MEMORY: used|total|percent)
    if GRAPHICS_TABS[tab] then
        local m = split(call('GET_VIDEO_MEMORY') or '')
        local used, total = tonumber(m[1]), tonumber(m[2])
        if used and total and total > 0 then
            table.insert(rows, 1, {
                tab = tab, row = -1, kind = 'display', prefId = -1, control = 'none', value = used, max = total, active = 1,
                label = ('Video Memory: %d MB / %d MB'):format(used, total), options = {},
            })
        end
    end
    return rows
end

local function changeAndWait(fn)
    local before = call('GET_SETTINGS_REVISION', nil, true)
    local result = fn()
    if isError(result) then
        print('[rnv-menu] GTA refused the change: ' .. tostring(result))
        return false
    end
    waitUntil(function() return call('GET_SETTINGS_REVISION', nil, true) ~= before end, 1000)
    waitFrames(1)
    return true
end

-- Answers GTA's own prompts with Yes. Collects the kinds that showed up
function answerWarnings(found, waitMs)
    for i = 1, 5 do
        if not waitUntil(function() return IsWarningMessageActive() end, waitMs or 1500) then return end
        local hash = GetWarningMessageTitleHash()
        local kind = WARNING_KINDS[hash] or 'unknown'
        if kind == 'unknown' then print('[rnv-menu] GTA prompt hash ' .. hash) end
        found[kind] = true
        pressFrontend(INPUT_ACCEPT)
        waitUntil(function() return not IsWarningMessageActive() end, 1000)
        waitFrames(2)
    end
end

-- Public: the menu stays open (hidden) between these calls, while the RNV settings screen is open ---------

-- { [tab] = rows } for every tab in GtaTabs
function GtaReadAll()
    local pages = {}
    if not openMenu() then return nil end
    for tab in pairs(GtaTabs) do
        if enterTab(tab) then pages[tab] = readRows(tab) end
    end
    return pages
end

-- Sets a list index / slider value. Returns the tab's rows again (other rows can turn on/off)
function GtaSet(tab, prefId, value)
    if not openMenu() or not enterTab(tab) then return nil end
    changeAndWait(function() return call('SET_PREF', { prefId, value }) end)
    answerWarnings({}, 100) -- e.g. "more than your allotted graphics card memory": OK
    return readRows(tab)
end

-- One step left (-1) or right (1): the only way to change code built lists
function GtaStep(tab, prefId, direction)
    if not openMenu() or not enterTab(tab) then return nil end
    -- STEP_PREF only highlights the row; a real left/right press then changes it
    if isError(navigate('STEP_PREF', { prefId, direction < 0 and -1 or 1 })) then return readRows(tab) end
    waitFrames(2)
    pressFrontend(direction < 0 and INPUT_LEFT or INPUT_RIGHT)
    answerWarnings({}, 100)
    return readRows(tab)
end

-- Runs an action row (Restore Defaults, Perform Quick / Full Scan for Music)
function GtaTrigger(tab, row)
    if not openMenu() or not enterTab(tab) then return nil end
    changeAndWait(function() return navigate('TRIGGER_ROW', { row }) end)
    answerWarnings(sessionWarnings)
    return readRows(tab)
end

-- Runs "Restore Defaults" on every page. Returns { [tab] = rows }
function GtaRestoreDefaults()
    local pages = {}
    if not openMenu() then return pages end
    for tab in pairs(GtaTabs) do
        if enterTab(tab) then
            readRows(tab)
            if restoreRows[tab] then
                changeAndWait(function() return navigate('TRIGGER_ROW', { restoreRows[tab] }) end)
                answerWarnings({})
            end
            pages[tab] = readRows(tab)
        end
    end
    return pages
end

-- Applies changed graphics (other graphics pages were applied when the menu left them)
-- Returns the GTA prompts seen since the menu opened: { restartRequired = true, ... }
function GtaApplyGraphics()
    if menuOpen then applyCurrent() end
    return sessionWarnings
end

-- Closing the menu throws away graphics changes that were not applied
function GtaClose()
    if not menuOpen then
        GtaDriving = false
        return
    end
    ReleaseControlOfFrontend()
    if GetPauseMenuState() ~= PM_SHUTTING_DOWN then SetFrontendActive(false) end
    waitUntil(function() return not IsPauseMenuActive() and GetPauseMenuState() == 0 end, 2000)
    menuOpen = false
    inKeymap = false
    currentTab = nil
    SetMouseCursorVisibleInMenus(true)
    GtaDriving = false
    -- keep the close sound muted too, then give GTA its sounds back
    SetTimeout(500, function()
        if not menuOpen then StopAudioScene(MUTE_SCENE) end
    end)
end

-- Key Bindings (pause_menu.ts keymap part) ------------------------------------------

-- name + args + text offset, read in 57 byte chunks
local function readChunks(name, argLists)
    local texts = {}
    for i, args in ipairs(argLists) do
        local text = ''
        for n = 1, 20 do
            local callArgs = { table.unpack(args) }
            callArgs[#callArgs + 1] = #text
            local chunk = call(name, callArgs)
            if isError(chunk) then break end
            text = text .. chunk
            if #chunk < TEXT_CHUNK_FULL_BYTES then break end
        end
        texts[i] = text
    end
    return texts
end

-- GET_KEYMAP_STATE: inKeymap|menuLevel|categoryRow|?|?|capturing
local function keymapState()
    local p = split(call('GET_KEYMAP_STATE') or '')
    return { inKeymap = p[1] == '1', menuLevel = tonumber(p[2]) or 0, categoryRow = tonumber(p[3]) or 0, capturing = p[6] == '1' }
end

local function navigateUntil(name, args, done)
    local timeout = GetGameTimer() + 3000
    while GetGameTimer() < timeout do
        local result = navigate(name, args)
        if done[result] then return result end
        if result ~= 'ERR|list_not_ready' and isError(result) then return nil end
    end
    return nil
end

local function ensureKeymap()
    if inKeymap and menuOpen and IsPauseMenuActive() and keymapState().inKeymap then return true end
    if not openMenu() then return false end
    applyCurrent()
    if not navigateUntil('ENTER_KEYMAP', {}, { ENTERED = true, ALREADY = true }) then return false end
    if not waitUntil(function() return keymapState().inKeymap end, 3000) then return false end
    inKeymap = true
    currentTab = 'keymap'
    call('SET_STEALTH', { true })
    return true
end

local function enterKeymapCategory(index)
    local state = keymapState()
    if state.menuLevel == 2 and state.categoryRow == index then return end
    navigateUntil('ENTER_KEYMAP_CATEGORY', { index }, { ENTERED = true, ALREADY = true })
end

-- { categories = { { index, label, alert, restore } }, category, rows = { { row, label, alert, mappable, keys = { k1, k2 } } } }
local function readKeymap()
    local state = keymapState()
    local categories = {}
    local count = call('GET_KEYMAP_CATEGORY_COUNT', nil, true) or 0
    local calls, argLists = {}, {}
    for i = 0, count - 1 do
        calls[#calls + 1] = { 'GET_KEYMAP_CATEGORY', { i } }
        argLists[#argLists + 1] = { i }
    end
    local raws = batch(calls)
    local labels = readChunks('GET_KEYMAP_CATEGORY_TEXT', argLists)
    for i = 0, count - 1 do
        local p = split(raws[i + 1] or '')
        categories[#categories + 1] = { index = i, label = StripMarkup(labels[i + 1] or ''), alert = p[2] == '1', restore = p[4] == 'restore' }
    end

    local rows = {}
    if state.menuLevel == 2 then
        -- GET_KEYMAP_ROWS(from): ?|count|state,alert,mappable;...
        local flags, nextRow = {}, 0
        for n = 1, 50 do
            local raw = call('GET_KEYMAP_ROWS', { nextRow })
            if isError(raw) then break end
            local p = split(raw)
            local got = tonumber(p[2]) or 0
            if got == 0 then break end
            for f in ((p[3] or '') .. ';'):gmatch('([^;]*);') do
                if f ~= '' then flags[#flags + 1] = f end
            end
            nextRow = nextRow + got
        end
        local labelArgs, tokenArgs, keyCalls = {}, {}, {}
        for i = 0, #flags - 1 do
            labelArgs[#labelArgs + 1] = { i, -1 }
            tokenArgs[#tokenArgs + 1] = { i, 0 }
            tokenArgs[#tokenArgs + 1] = { i, 1 }
            keyCalls[#keyCalls + 1] = { 'GET_KEYMAP_KEY', { i, 0 } }
            keyCalls[#keyCalls + 1] = { 'GET_KEYMAP_KEY', { i, 1 } }
        end
        local labels = readChunks('GET_KEYMAP_TEXT', labelArgs)
        local tokens = readChunks('GET_KEYMAP_TEXT', tokenArgs)
        local keys = batch(keyCalls)
        for i = 0, #flags - 1 do
            local f = {}
            for v in (flags[i + 1] .. ','):gmatch('([^,]*),') do f[#f + 1] = tonumber(v) end
            rows[#rows + 1] = {
                row = i, label = StripMarkup(labels[i + 1] or ''), alert = f[2] == 1, mappable = f[3] == 1,
                keys = { ResolveBoundKey(keys[i * 2 + 1], tokens[i * 2 + 1], 0), ResolveBoundKey(keys[i * 2 + 2], tokens[i * 2 + 2], 1) },
            }
        end
    end
    return { categories = categories, category = state.menuLevel == 2 and state.categoryRow or nil, rows = rows }
end

-- GTA's prompt on screen right now (key conflict, ...), or nil
function GtaWarning()
    if not IsWarningMessageActive() then return nil end
    return WARNING_KINDS[GetWarningMessageTitleHash()] or 'unknown'
end

-- choice: 'yes' (Enter), 'no' (Esc), 'alt' (Space). Returns the key bindings page when on it
function GtaAnswer(choice)
    if IsWarningMessageActive() then
        pressFrontend(choice == 'no' and INPUT_CANCEL or choice == 'alt' and INPUT_X or INPUT_ACCEPT)
        waitUntil(function() return not IsWarningMessageActive() end, 500)
        waitFrames(2)
    end
    if inKeymap then return readKeymap() end
end

function GtaKeymap(category)
    if not ensureKeymap() then return nil end
    if category then enterKeymapCategory(category) end
    return readKeymap()
end

-- Waits for the player to press the new key (the game must get the input: see settings.lua). Returns the page
function GtaRebind(row, slot)
    if not ensureKeymap() then return nil end
    if navigate('BEGIN_REBIND', { row, slot }) ~= 'OK' then return readKeymap() end
    waitUntil(function() return keymapState().capturing end, 1000)
    local done = waitUntil(function() return IsWarningMessageActive() or not keymapState().capturing end, REBIND_TIMEOUT_MS)
    if not done then pressFrontend(INPUT_CANCEL) end
    waitFrames(2)
    return readKeymap()
end

function GtaClearKey(row, slot)
    if not ensureKeymap() then return nil end
    if navigate('SELECT_KEYMAP_SLOT', { row, slot }) ~= 'OK' then return readKeymap() end
    waitFrames(1)
    pressFrontend(INPUT_DELETE)
    waitUntil(function() return call('GET_KEYMAP_TEXT', { row, slot, 0 }) == '' end, 400)
    waitFrames(1)
    return readKeymap()
end

function GtaRestoreKeys()
    if not ensureKeymap() then return nil end
    navigateUntil('RESTORE_KEYMAP_DEFAULTS', {}, { TRIGGERED = true })
    waitFrames(2)
    return readKeymap()
end

-- True while the player has GTA's own SETTINGS tab open (P map -> tabs), not our hidden one
function IsGtaSettingsTab()
    if GtaDriving or not IsPauseMenuActive() then return false end
    return GetPauseMenuSelectionData() == MENU_UNIQUE_ID_SETTINGS
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then StopAudioScene(MUTE_SCENE) end
    if resource == GetCurrentResourceName() and menuOpen then
        ReleaseControlOfFrontend()
        SetFrontendActive(false)
        SetMouseCursorVisibleInMenus(true)
    end
end)

-- dev: read every GTA page
exports('GtaReadAll', function() local pages = GtaReadAll() GtaClose() return pages end)
