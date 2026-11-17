-- Settings: RNV rows (config.lua) are stored per player machine (resource KVP). Other resources read them with
-- GetSetting or listen to 'rnv-menu:client:settingsChanged'
-- GTA rows come live from the hidden GTA pause menu (client/gta.lua) while the screen is open: every change goes
-- to GTA at once (like GTA's own menu), CONFIRM applies graphics, BACK puts the old values back

local settings = {}
local isOpen = false
local closing = false
local fromPause = false
local jobs = {}
local working = false
local original = {} -- [tab .. prefId] = { tab, prefId, value, codeBuilt }
local steps = {}    -- [tab .. prefId] = net STEP_PREF steps on code built lists (to undo on BACK)
local changed = {}   -- [tab .. prefId] = true: rows changed with SET_PREF on this screen
local fullRevert = false -- Restore Defaults ran: BACK compares every row
local lastPages = nil -- GTA rows from the last open: shown at once next time, then refreshed

-- GTA's own prompts on the key bindings page (their texts)
local WARNING_TEXTS = {
    keepSettings = 'Keep these graphics settings?',
    restartRequired = 'The game must be restarted to apply these settings.',
    onlineWarning = 'This change may affect the online session. Continue?',
    keymapConflict = 'This key is already in use. Replace it?',
    keymapUnmappable = 'This key cannot be replaced.',
    keymapAutosave = 'An autosave of the key bindings exists. Load it?',
    keymapRestore = 'Reset all key bindings to their defaults?',
    keymapCantLeave = 'A key conflict prevents leaving this page.',
    keymapLeaveConflict = 'Some keys are in conflict. Leave anyway?',
    keymapLeaveUnmapped = 'Some controls have no key. Leave anyway?',
    unknown = 'The game is asking for a confirmation.',
}

local function defaults()
    local values = {}
    for _, tab in ipairs(Config.Tabs) do
        for _, row in ipairs(tab.rows) do values[row.key] = row.default end
    end
    return values
end

local function load()
    settings = defaults()
    local saved = json.decode(GetResourceKvpString('settings') or '{}') or {}
    for key, value in pairs(saved) do
        if settings[key] ~= nil then settings[key] = value end
    end
end

local function apply()
    exports['pma-voice']:setRadioVolume(math.floor(settings.radioVolume * 100 + 0.5))
    TriggerEvent('rnv-menu:client:settingsChanged', settings)
end

local function close()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'settings:close' })
    if fromPause then OpenPause() end
end

-- GTA rows -> rows in the RNV screen format (lists, sliders, actions, video memory)
local function toUi(gtaRows)
    local rows = {}
    for _, r in ipairs(gtaRows) do
        local row = {
            key = 'gta:' .. r.tab .. ':' .. r.row, label = r.label, desc = '',
            gta = { tab = r.tab, prefId = r.prefId, row = r.row, codeBuilt = r.codeBuilt },
            disabled = r.active == 0,
        }
        if r.kind == 'action' then
            row.type = 'action'
        elseif r.kind == 'display' then
            row.type, row.value, row.max = 'display', r.value, r.max
        elseif r.control == 'slider' then
            row.type, row.min, row.max, row.step, row.value = 'slider', 0, r.max, 1, r.value
        else
            row.type, row.options = 'select', r.options
            row.value = r.codeBuilt and r.options[1] or r.options[r.value + 1]
            row.index = r.value
        end
        rows[#rows + 1] = row
    end
    return rows
end

local function sendTab(tab, gtaRows)
    if lastPages then lastPages[tab] = gtaRows end
    SendNUIMessage({ action = 'settings:gtaRows', tab = tab, rows = toUi(gtaRows) })
end

-- Key bindings page, or GTA's prompt when one is up (the player answers it)
local function sendKeymap(page)
    local warning = GtaWarning()
    if warning then
        SendNUIMessage({ action = 'settings:gtaWarning', kind = warning, text = WARNING_TEXTS[warning] or WARNING_TEXTS.unknown, alt = warning == 'keymapAutosave' or warning == 'unknown' })
    elseif page then
        SendNUIMessage({ action = 'settings:keymap', page = page })
    end
end

-- While waiting for a new key the game must get the keyboard: keep NUI focus but pass input through
local function setCapture(on)
    SetNuiFocus(true, not on)
    SetNuiFocusKeepInput(on)
    SendNUIMessage({ action = 'settings:capturing', on = on })
end

-- Jobs run one after another: the hidden GTA menu can only do one thing at a time
local function runJob(job)
    if job.type == 'load' then
        local pages = GtaReadAll()
        if not pages then return end
        lastPages = pages
        original, steps, changed, fullRevert = {}, {}, {}, false
        for tab, rows in pairs(pages) do
            for _, r in ipairs(rows) do
                if r.kind == 'pref' then
                    original[tab .. r.prefId] = { tab = tab, prefId = r.prefId, value = r.value, codeBuilt = r.codeBuilt }
                end
            end
        end
        for tab, rows in pairs(pages) do sendTab(tab, rows) end
    elseif job.type == 'set' then
        changed[job.tab .. job.prefId] = true
        local rows = GtaSet(job.tab, job.prefId, job.value)
        if rows then sendTab(job.tab, rows) end
    elseif job.type == 'step' then
        local key = job.tab .. job.prefId
        steps[key] = (steps[key] or 0) + job.direction
        local rows = GtaStep(job.tab, job.prefId, job.direction)
        if rows then sendTab(job.tab, rows) end
    elseif job.type == 'trigger' then
        fullRevert = true
        local rows = GtaTrigger(job.tab, job.row)
        if rows then sendTab(job.tab, rows) end
    elseif job.type == 'keymap' then
        sendKeymap(GtaKeymap(job.category))
    elseif job.type == 'rebind' then
        setCapture(true)
        local page = GtaRebind(job.row, job.slot)
        setCapture(false)
        sendKeymap(page)
    elseif job.type == 'clearKey' then
        sendKeymap(GtaClearKey(job.row, job.slot))
    elseif job.type == 'restoreKeys' then
        sendKeymap(GtaRestoreKeys())
    elseif job.type == 'answer' then
        sendKeymap(GtaAnswer(job.choice))
    elseif job.type == 'defaults' then
        fullRevert = true
        for tab, rows in pairs(GtaRestoreDefaults()) do sendTab(tab, rows) end
    elseif job.type == 'confirm' then
        local warnings = GtaApplyGraphics()
        GtaClose()
        for kind in pairs(warnings) do print('[rnv-menu] GTA prompt: ' .. kind) end
        if warnings.restartRequired then
            exports['rnv-interface']:Notify({ text = 'Restart the game to apply the new [[graphics]] settings', type = 'warning', duration = 8000 })
        end
        close()
    elseif job.type == 'back' then
        -- the screen is already closed: undo this screen's GTA changes in the background
        for key, n in pairs(steps) do
            local o = original[key]
            for i = 1, math.abs(n) do GtaStep(o.tab, o.prefId, n > 0 and -1 or 1) end
        end
        if fullRevert then
            for tab, rows in pairs(GtaReadAll() or {}) do
                for _, r in ipairs(rows) do
                    local o = original[tab .. r.prefId]
                    if o and not o.codeBuilt and r.kind == 'pref' and o.value ~= r.value then GtaSet(tab, r.prefId, o.value) end
                end
            end
        else
            for key in pairs(changed) do
                local o = original[key]
                if o then GtaSet(o.tab, o.prefId, o.value) end
            end
        end
        GtaApplyGraphics() -- graphics may already be applied (GTA applies them when its page is left)
        GtaClose()
    end
end

local function queue(job)
    jobs[#jobs + 1] = job
    if working then return end
    working = true
    CreateThread(function()
        while #jobs > 0 do runJob(table.remove(jobs, 1)) end
        working = false
    end)
end

function OpenSettings(pause)
    if isOpen then return end
    isOpen = true
    closing = false
    fromPause = pause == true
    SendNUIMessage({ action = 'settings:open', tabs = Config.Tabs, values = settings, defaults = defaults(), sections = Config.GtaSections })
    SetNuiFocus(true, true)
    if lastPages then
        for tab, rows in pairs(lastPages) do sendTab(tab, rows) end
    end
    queue({ type = 'load' })
end

RegisterNUICallback('settings:gtaSet', function(data, cb)
    cb(1)
    queue({ type = 'set', tab = data.tab, prefId = data.prefId, value = data.value })
end)

RegisterNUICallback('settings:gtaStep', function(data, cb)
    cb(1)
    queue({ type = 'step', tab = data.tab, prefId = data.prefId, direction = data.direction })
end)

RegisterNUICallback('settings:gtaTrigger', function(data, cb)
    cb(1)
    queue({ type = 'trigger', tab = data.tab, row = data.row })
end)

RegisterNUICallback('settings:keymap', function(data, cb)
    cb(1)
    queue({ type = 'keymap', category = data.category })
end)

RegisterNUICallback('settings:rebind', function(data, cb)
    cb(1)
    queue({ type = 'rebind', row = data.row, slot = data.slot })
end)

RegisterNUICallback('settings:clearKey', function(data, cb)
    cb(1)
    queue({ type = 'clearKey', row = data.row, slot = data.slot })
end)

RegisterNUICallback('settings:restoreKeys', function(_, cb)
    cb(1)
    queue({ type = 'restoreKeys' })
end)

RegisterNUICallback('settings:answer', function(data, cb)
    cb(1)
    queue({ type = 'answer', choice = data.choice })
end)

RegisterNUICallback('settings:default', function(_, cb)
    cb(1)
    queue({ type = 'defaults' })
end)

RegisterNUICallback('settings:confirm', function(values, cb)
    cb(1)
    if not isOpen or closing then return end
    closing = true
    for key in pairs(settings) do
        if values[key] ~= nil then settings[key] = values[key] end
    end
    SetResourceKvp('settings', json.encode(settings))
    apply()
    queue({ type = 'confirm' })
end)

RegisterNUICallback('settings:back', function(_, cb)
    cb(1)
    if not isOpen or closing then return end
    closing = true
    close()
    queue({ type = 'back' })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then close() end
end)

CreateThread(function()
    load()
    apply()
end)

exports('OpenSettings', OpenSettings)
exports('GetSetting', function(key) return settings[key] end)
-- dev: switch the open settings screen to a tab and scroll its rows
exports('ShowSettingsTab', function(tab, scroll) SendNUIMessage({ action = 'settings:tab', tab = tab, scroll = scroll }) end)
