-- World prompts: diamonds nearby, the looked-at one opens at a fixed spot; E selects

local MARK_RANGE = 10.0 -- diamonds within this distance
local LOOK = 0.22       -- max distance from the screen centre to count as looked at
local RARITY = { [1] = '#f0f0f0', [2] = '#69f938', [4] = '#b06ef3', [5] = '#ffcb3d', [6] = '#e8453c' }

local prompts = {}
local shown = nil
local marked = false

local function hide()
    if shown then
        shown = nil
        SendNUIMessage({ action = 'prompt', prompt = false })
    end
end

local function unmark()
    if marked then
        marked = false
        SendNUIMessage({ action = 'marks', marks = {} })
    end
end

local function allowed()
    return LocalPlayer.state['rnv:spawned'] and not IsPauseMenuActive() and not LocalPlayer.state['rnv:screen']
        and not LocalPlayer.state['rnv:map'] and not LocalPlayer.state.invOpen and not exports['rnv-interface']:IsBusy()
end

CreateThread(function()
    while true do
        local sleep = 500
        if allowed() then
            local pos = GetEntityCoords(PlayerPedId())
            local aspect = GetAspectRatio(false)
            local best, bestScore, marks = nil, nil, {}
            for _, p in pairs(prompts) do
                local d = #(pos - p.coords)
                if d <= MARK_RANGE then
                    sleep = 0
                    local onScreen, x, y = GetScreenCoordFromWorldCoord(p.coords.x, p.coords.y, p.coords.z)
                    if onScreen then
                        marks[#marks + 1] = { x = x * 100, y = y * 100 }
                        local score = math.sqrt(((x - 0.5) * aspect) ^ 2 + (y - 0.5) ^ 2)
                        if d <= (p.distance or 1.5) and score <= LOOK and (not bestScore or score < bestScore) then
                            best, bestScore = p, score
                        end
                    end
                end
            end
            if #marks > 0 or marked then
                SendNUIMessage({ action = 'marks', marks = marks })
                marked = #marks > 0
            end

            if best then
                local options = best.options
                if options then
                    best.sel = math.min(best.sel or 1, #options)
                    DisableControlAction(0, 14, true)
                    DisableControlAction(0, 15, true)
                    DisableControlAction(0, 16, true)
                    DisableControlAction(0, 17, true)
                    if IsDisabledControlJustPressed(0, 14) then best.sel = best.sel % #options + 1 end -- wheel down
                    if IsDisabledControlJustPressed(0, 15) then best.sel = (best.sel - 2) % #options + 1 end -- wheel up
                end
                shown = best.id
                local list = nil
                if options then
                    list = {}
                    for i, o in ipairs(options) do list[i] = { label = o.label, price = o.price, icon = o.icon } end
                end
                SendNUIMessage({ action = 'prompt', prompt = { title = best.title, label = best.label, key = 'E', options = list, sel = best.sel, rarity = best.rarity } })
                if IsControlJustPressed(0, 38) then -- E
                    hide()
                    if options then options[best.sel].onSelect() else best.onSelect() end
                    Wait(500)
                end
            else
                hide()
            end
        else
            hide()
            unmark()
        end
        Wait(sleep)
    end
end)

-- tests: press E on the shown prompt (n = option)
exports('SelectPrompt', function(n)
    local p = shown and prompts[shown]
    if not p then return false end
    hide()
    if p.options then p.options[n or p.sel or 1].onSelect() else p.onSelect() end
    return true
end)

exports('AddPrompt', function(data)
    if data.item then
        local item = exports['rnv-inventory']:Items(data.item)
        data.title = data.title or (item and item.label) or data.item
        data.rarity = item and item.rnv and RARITY[item.rnv.rarity] or RARITY[1]
    end
    prompts[data.id] = data
end)

exports('RemovePrompt', function(id)
    prompts[id] = nil
    if shown == id then hide() end
end)

-- JAIL TIME banner: years, or nil to hide
exports('SetJailTime', function(years)
    SendNUIMessage({ action = 'jail', years = years })
end)
