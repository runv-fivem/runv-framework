


local isOpen = false

local isDisabled = false

local menus = {}

local menuItems = {}

local menuHistory = {}

local currentRadial = nil

local rootRadial = nil

local function showRadial(id, option)
    local radial = id and menus[id]

    if id and not radial then
        return error('No radial menu with such id found.')
    end

    currentRadial = radial

    -- Hide current menu and allow for transition
    SendNUIMessage({
        action = 'openRadialMenu',
        data = false
    })

    Wait(100)

    -- If menu was closed during transition, don't open the submenu
    if not isOpen then return end

    SendNUIMessage({
        action = 'openRadialMenu',
        data = {
            items = radial and radial.items or menuItems,
            sub = radial and radial ~= rootRadial or nil,
            option = option
        }
    })
end

local function refreshRadial(menuId)
    if not isOpen then return end

    if currentRadial and menuId then
        if menuId == currentRadial.id then
            return showRadial(menuId)
        else
            for i = 1, #menuHistory do
                local subMenu = menuHistory[i]

                if subMenu.id == menuId then
                    local parent = menus[subMenu.id]

                    for j = 1, #parent.items do
                        -- If we still have a path to the current submenu, refresh instead of returning
                        if parent.items[j].menu == currentRadial.id then
                            return -- showRadial(currentRadial.id)
                        end
                    end

                    currentRadial = parent

                    for j = #menuHistory, i, -1 do
                        menuHistory[j] = nil
                    end

                    return showRadial(currentRadial.id)
                end
            end
        end

        return
    end

    table.wipe(menuHistory)
    showRadial()
end

local function onRadialOpen(id)
    local radial = id and menus[id]

    if isDisabled or (id and not radial) then return end

    if isOpen then
        if rootRadial == radial then
            return lib.hideRadial()
        end

        rootRadial = radial
        table.wipe(menuHistory)
        return showRadial(id)
    end

    local items = radial and radial.items or menuItems
    if #items == 0 or IsNuiFocused() or IsPauseMenuActive() then return end

    isOpen = true
    rootRadial = radial
    table.wipe(menuHistory)

    lib.setNuiFocus(true)
    SetCursorLocation(0.5, 0.5)

    showRadial(id)

    while isOpen do
        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(2, 199, true)
        DisableControlAction(2, 200, true)
        Wait(0)
    end
end

function lib.registerRadial(radial)
    menus[radial.id] = radial
    radial.resource = GetInvokingResource()

    if currentRadial then
        refreshRadial(radial.id)
    end
end

function lib.getCurrentRadialId()
    return currentRadial and currentRadial.id
end

function lib.hideRadial()
    if not isOpen then return end

    SendNUIMessage({
        action = 'openRadialMenu',
        data = false
    })

    lib.resetNuiFocus()
    table.wipe(menuHistory)

    isOpen = false
    currentRadial = nil
    rootRadial = nil
end

function lib.addRadialItem(items, parentMenuId)
    local targetMenu
    if parentMenuId then
        if not menus[parentMenuId] then
            return error('No radial submenu with such parent id found.')
        end

        targetMenu = menus[parentMenuId].items
    else
        targetMenu = menuItems
    end

    local menuSize = #targetMenu
    local invokingResource = GetInvokingResource()

    items = table.type(items) == 'array' and items or { items }

    for i = 1, #items do
        local item = items[i]
        item.resource = invokingResource

        if menuSize == 0 then
            menuSize = menuSize + 1
            targetMenu[menuSize] = item
        else
            for j = 1, menuSize do
                if targetMenu[j].id == item.id then
                    targetMenu[j] = item
                    break
                end

                if j == menuSize then
                    menuSize = menuSize + 1
                    targetMenu[menuSize] = item
                end
            end
        end
    end

    if isOpen and not currentRadial then
        refreshRadial()
    end
end

function lib.removeRadialItem(id, parentMenuId)
    local menuItem
    local targetMenu
    if parentMenuId then
        if not menus[parentMenuId] then
            return error('No radial sub menu with such parent id found.')
        end

        targetMenu = menus[parentMenuId].items
    else
        targetMenu = menuItems
    end

    for i = 1, #targetMenu do
        menuItem = targetMenu[i]

        if menuItem.id == id then
            table.remove(targetMenu, i)
            break
        end
    end

    if not isOpen then return end

    refreshRadial()
end

function lib.clearRadialItems()
    table.wipe(menuItems)

    if isOpen then
        refreshRadial()
    end
end

RegisterNUICallback('radialClick', function(index, cb)
    cb(1)

    local itemIndex = index + 1
    local item, currentMenu

    if currentRadial then
        item = currentRadial.items[itemIndex]
        currentMenu = currentRadial.id
    else
        item = menuItems[itemIndex]
    end

    local menuResource = item.resource or currentRadial and currentRadial.resource

    if item.menu then
        menuHistory[#menuHistory + 1] = { id = currentRadial and currentRadial.id, option = item.menu }
        showRadial(item.menu)
    elseif not item.keepOpen then
        lib.hideRadial()
    end

    local onSelect = item.onSelect

    if onSelect then
        if type(onSelect) == 'string' then
            return exports[menuResource][onSelect](0, currentMenu, itemIndex)
        end

        onSelect(currentMenu, itemIndex)
    end
end)

RegisterNUICallback('radialBack', function(_, cb)
    cb(1)

    local numHistory = #menuHistory
    local lastMenu = numHistory > 0 and menuHistory[numHistory]

    if not lastMenu then return end

    menuHistory[numHistory] = nil

    if lastMenu.id then
        return showRadial(lastMenu.id, lastMenu.option)
    end

    currentRadial = nil

    -- Hide current menu and allow for transition
    SendNUIMessage({
        action = 'openRadialMenu',
        data = false
    })

    Wait(100)

    -- If menu was closed during transition, don't open the submenu
    if not isOpen then return end

    SendNUIMessage({
        action = 'openRadialMenu',
        data = {
            items = menuItems,
            option = lastMenu.option
        }
    })
end)

RegisterNUICallback('radialClose', function(_, cb)
    cb(1)

    if not isOpen then return end

    lib.resetNuiFocus()

    isOpen = false
    currentRadial = nil
    rootRadial = nil
end)

RegisterNUICallback('radialTransition', function(_, cb)
    Wait(100)

    -- If menu was closed during transition, don't open the submenu
    if not isOpen then return cb(false) end

    cb(true)
end)

function lib.disableRadial(state)
    isDisabled = state

    if isOpen and state then
        return lib.hideRadial()
    end
end

function lib.showRadialMenu(id)
    onRadialOpen(id)
end

lib.addKeybind({
    name = 'rnv-core-radial',
    description = locale('open_radial_menu'),
    defaultKey = 'z',
    onPressed = function()
        onRadialOpen()
    end,
    -- onReleased = lib.hideRadial,
})

AddEventHandler('onClientResourceStop', function(resource)
    for i = #menuItems, 1, -1 do
        local item = menuItems[i]

        if item.resource == resource then
            table.remove(menuItems, i)
        end
    end
end)