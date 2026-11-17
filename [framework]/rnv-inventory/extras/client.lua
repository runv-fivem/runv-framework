-- Wardrobe rail ---------------------------------------------------------------------------------------------------------
-- The icons next to the character take one piece of clothing off, and put it back on. What was taken off is remembered
-- for this session only; nothing is saved, so a relog (or the clothing menu) brings the outfit back. It lives in the
-- player's state bag rather than a plain variable, so a restart of this resource does not forget it
local takenOff = LocalPlayer.state.ataTakenOff or {} -- piece id -> what was worn there: { [tostring(index)] = { drawable, texture } }
local dressing = false

local function isFemale(ped)
    return GetEntityModel(ped) == joaat('mp_f_freemode_01')
end

local function wornNow(ped, piece)
    local worn = {}
    if piece.prop then
        worn[tostring(piece.prop)] = { GetPedPropIndex(ped, piece.prop), GetPedPropTextureIndex(ped, piece.prop) }
    else
        for component in pairs(piece.off.male) do
            worn[tostring(component)] = { GetPedDrawableVariation(ped, component), GetPedTextureVariation(ped, component) }
        end
    end
    return worn
end

local function pieceState(ped, piece)
    if takenOff[piece.id] then return 'bare' end
    if piece.prop then return GetPedPropIndex(ped, piece.prop) ~= -1 and 'worn' or 'none' end

    local bare = isFemale(ped) and piece.off.female or piece.off.male
    return GetPedDrawableVariation(ped, piece.main) ~= bare[piece.main] and 'worn' or 'none'
end

local function wearStates()
    local ped, states = cache.ped, {}
    local model = GetEntityModel(ped)
    -- Only the online characters have clothes that come apart like this
    if model ~= joaat('mp_m_freemode_01') and model ~= joaat('mp_f_freemode_01') then return states end
    for _, piece in ipairs(Extras.Wear.pieces) do states[piece.id] = pieceState(ped, piece) end
    return states
end

local function apply(ped, piece)
    if takenOff[piece.id] then
        for index, worn in pairs(takenOff[piece.id]) do
            index = tonumber(index)
            if piece.prop then SetPedPropIndex(ped, index, worn[1], worn[2], true)
            else SetPedComponentVariation(ped, index, worn[1], worn[2], 0) end
        end
        takenOff[piece.id] = nil
        return
    end

    takenOff[piece.id] = wornNow(ped, piece)
    if piece.prop then return ClearPedProp(ped, piece.prop) end
    for component, drawable in pairs(isFemale(ped) and piece.off.female or piece.off.male) do
        SetPedComponentVariation(ped, component, drawable, 0, 0)
    end
end

local function toggleWear(id)
    if dressing then return end
    local ped, piece = cache.ped
    for _, entry in ipairs(Extras.Wear.pieces) do
        if entry.id == id then piece = entry break end
    end
    if not piece or pieceState(ped, piece) == 'none' then return end

    dressing = true
    local anim = piece.anim
    local loaded = lib.requestAnimDict(anim[1], 2000)
    if loaded then
        -- Upper body only and on top of whatever else plays, on the player and on the character shown in the inventory
        TaskPlayAnim(ped, anim[1], anim[2], 3.0, 3.0, anim[3], 51, 0.0, false, false, false)
        Wait(anim[3] * 0.55)
    end

    apply(ped, piece)
    LocalPlayer.state:set('ataTakenOff', takenOff, false)

    if loaded then
        Wait(anim[3] * 0.45)
        StopAnimTask(ped, anim[1], anim[2], 3.0)
        RemoveAnimDict(anim[1])
    end
    dressing = false
end

exports('toggleWear', function(id)
    toggleWear(id)
    return wearStates()
end)

RegisterNUICallback('ataWear', function(id, cb)
    if id then toggleWear(id) end
    cb(Extras.Wear.enabled and wearStates() or false)
end)

-- rnv-inventory lets the game keep the keyboard while the inventory is open, so typing in a box of the page would also
-- fire the game's key binds. While a box has the cursor, the keyboard belongs to the page alone
RegisterNUICallback('ataTyping', function(typing, cb)
    cb(1)
    if LocalPlayer.state.invOpen then SetNuiFocusKeepInput(not typing) end
end)

-- World blur behind the inventory: on unless the player turned it off in the settings of the page
Extras.wantBlur = true -- on the shared table, because the views above read it too
RegisterNUICallback('ataBlur', function(on, cb)
    cb(1)
    Extras.wantBlur = on ~= false
    if not client.screenblur or not LocalPlayer.state.invOpen then return end
    if IsScreenblurFadeRunning() then DisableScreenblurFade() end
    if Extras.wantBlur then TriggerScreenblurFadeIn(150) else TriggerScreenblurFadeOut(150) end
end)

local catalog

AddStateBagChangeHandler('invOpen', ('player:%s'):format(cache.serverId), function(_, _, open)
    if not open then return end

    -- Categories and tiers of items (extras/category.lua, tier.lua), asked from the server once
    CreateThread(function()
        catalog = catalog or lib.callback.await('rnv-inventory:extras:catalog', false)
        if catalog then SendNUIMessage({ action = 'ataCatalog', data = catalog }) end
    end)

end)

-- Hotbar slots above 5 ------------------------------------------------------------------------------------------------
for slot, key in pairs(Extras.HotbarKeys) do
    lib.addKeybind({
        name = ('hotkey%s'):format(slot),
        description = locale('use_hotbar', slot),
        defaultKey = key,
        onPressed = function()
            local state = LocalPlayer.state
            if state.invOpen or not state.invHotkeys or IsNuiFocused() then return end
            exports['rnv-inventory']:useSlot(slot)
        end
    })
end

-- Weapon attachments ---------------------------------------------------------------------------------------------------
-- The page shows a weapon from the bag as a real 3D model: a weapon object held in front of the camera, where the page
-- left a free area. Every frame we tell the page where the attachment bones of the model are on screen, so it can draw
-- its lines to them. Attaching and removing go through the server code of rnv-inventory itself (rnv-inventory:updateWeapon)
local attach -- { slot, hash, object, components, slots, view }
local componentItems

local function itemData(name) return exports['rnv-inventory']:Items(name) end

-- Every item that is a weapon component, by name
local function getComponentItems()
    if componentItems then return componentItems end
    componentItems = {}
    for name, data in pairs(exports['rnv-inventory']:Items()) do
        if data.type and type((data.client and data.client.component)) == 'table' then componentItems[name] = data end
    end
    return componentItems
end

local function fittingComponent(hash, data)
    for i = 1, #data.client.component do
        if DoesWeaponTakeWeaponComponent(hash, data.client.component[i]) then return data.client.component[i] end
    end
end

local function removeWeaponModel()
    if (attach and attach.object) and DoesEntityExist(attach.object) then DeleteEntity(attach.object) end
    if attach then attach.object = nil end
end

local function buildWeaponModel(weapon)
    removeWeaponModel()
    lib.requestWeaponAsset(attach.hash, 5000, 31, 0)

    -- A finish like "Pearl" or "Luxe" is not an add-on: it is a whole other model of the weapon, and a weapon object only
    -- shows it when it is created from that model. Camo skins are add-ons and go on below like every other part
    local finish = 0
    for _, name in ipairs((weapon.metadata and weapon.metadata.components) or {}) do
        local data = itemData(name)
        local component = (data and data.type) == 'skin' and (data.client and data.client.component) and fittingComponent(attach.hash, data)
        local model = component and GetWeaponComponentTypeModel(component) or 0
        if model ~= 0 and IsModelValid(model) and lib.requestModel(model, 5000) then
            finish = model
            break
        end
    end

    local object = CreateWeaponObject(attach.hash, 0, 0.0, 0.0, -50.0, true, 1.0, finish)
    -- Not a full weapon after all (no grip bone): start again from the plain model
    if finish ~= 0 and object and object ~= 0 and GetEntityBoneIndexByName(object, 'Gun_GripR') == -1 then
        DeleteEntity(object)
        object = CreateWeaponObject(attach.hash, 0, 0.0, 0.0, -50.0, true, 1.0, 0)
    end
    if finish ~= 0 then SetModelAsNoLongerNeeded(finish) end
    RemoveWeaponAsset(attach.hash)
    if not object or object == 0 then return end

    for _, name in ipairs((weapon.metadata and weapon.metadata.components) or {}) do
        local data = itemData(name)
        local component = ((data and data.client) and (data and data.client).component) and fittingComponent(attach.hash, data)
        if component then
            local model = GetWeaponComponentTypeModel(component)
            if model ~= 0 then lib.requestModel(model, 5000) end
            GiveWeaponComponentToWeaponObject(object, component)
            if model ~= 0 then SetModelAsNoLongerNeeded(model) end
        end
    end
    if (weapon.metadata and weapon.metadata.tint) then SetWeaponObjectTintIndex(object, weapon.metadata.tint) end

    SetEntityCollision(object, false, false)
    FreezeEntityPosition(object, true)

    local min, max = GetModelDimensions(GetEntityModel(object))
    attach.center = (min + max) / 2
    attach.length = math.max(max.x - min.x, max.z - min.z, 0.1)
    attach.bones = {}
    for _, slot in ipairs(attach.slots) do
        for _, bone in ipairs(slot.bones) do
            local index = GetEntityBoneIndexByName(object, bone)
            if index ~= -1 then
                attach.bones[slot.type] = index
                break
            end
        end
    end
    attach.object = object
end

-- Holds the model where the page wants it and reports the bone positions
local function attachLoop()
    local sent
    -- The game blurs the whole world behind the inventory, the model included; not while the weapon is on show
    if IsScreenblurFadeRunning() then DisableScreenblurFade() end
    TriggerScreenblurFadeOut(150)
    while attach do
        local weapon = exports['rnv-inventory']:GetPlayerItems()[attach.slot]
        if not weapon or (exports['rnv-inventory']:Items(weapon.name) or {}).hash ~= attach.hash then break end

        -- Rebuilt whenever a component was added or removed
        local signature = json.encode((weapon.metadata and weapon.metadata.components) or {})
        if signature ~= attach.components or not attach.object then
            attach.components = signature
            buildWeaponModel(weapon)
            sent = nil
            if not attach then break end
        end

        InvalidateIdleCam()
        local object, view = attach.object, attach.view
        if object then
            local cam, rot, fov = GetFinalRenderedCamCoord(), GetFinalRenderedCamRot(2), GetFinalRenderedCamFov()
            local half, aspect = math.tan(math.rad(fov) / 2), GetAspectRatio(false)
            local rz, rx = math.rad(rot.z), math.rad(rot.x)
            local forward = vec3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
            local right = vec3(math.cos(rz), math.sin(rz), 0.0)
            local up = vec3(right.y * forward.z - right.z * forward.y, right.z * forward.x - right.x * forward.z, right.x * forward.y - right.y * forward.x)

            -- Far enough that the weapon takes the configured share of the screen, whatever its size
            local distance = math.max(0.3, attach.length / (Extras.Attach.fill * 2 * half * aspect)) / view.zoom
            local at = cam + forward * distance + right * ((view.x - 0.5) * 2 * distance * half * aspect) - up * ((view.y - 0.5) * 2 * distance * half)

            -- The weapon faces the screen side-on (its length along the right of the camera), then turns with the mouse
            local yaw, pitch = math.rad(view.yaw), math.rad(view.pitch)
            local x = right * math.cos(yaw) + forward * math.sin(yaw)
            local y = forward * math.cos(yaw) - right * math.sin(yaw)
            local z = up
            y, z = y * math.cos(pitch) + z * math.sin(pitch), z * math.cos(pitch) - y * math.sin(pitch)

            local c = attach.center
            at = at - (x * c.x + y * c.y + z * c.z)
            SetEntityMatrix(object, y.x, y.y, y.z, x.x, x.y, x.z, z.x, z.y, z.z, at.x, at.y, at.z)
            DrawLightWithRange(cam.x, cam.y, cam.z, 255, 255, 255, distance + 2.0, Extras.Attach.light)

            local points, text = {}, {}
            for slotType, index in pairs(attach.bones) do
                local world = GetWorldPositionOfEntityBone(object, index)
                local onScreen, sx, sy = GetScreenCoordFromWorldCoord(world.x, world.y, world.z)
                if onScreen then
                    points[slotType] = { sx, sy }
                    text[#text + 1] = ('%s%.3f%.3f'):format(slotType, sx, sy)
                end
            end
            table.sort(text)
            text = table.concat(text)
            if text ~= sent then
                sent = text
                SendNUIMessage({ action = 'ataAttachPts', data = points })
            end
        end
        Wait(0)
    end
    removeWeaponModel()
    attach = nil
    -- Blur comes back only if the inventory is still open a moment later; closing the inventory from this view must
    -- not leave the world blurred
    Wait(300)
    if client.screenblur and not attach then
        if IsScreenblurFadeRunning() then DisableScreenblurFade() end
        if LocalPlayer.state.invOpen and Extras.wantBlur ~= false then TriggerScreenblurFadeIn(150) else TriggerScreenblurFadeOut(0) end
    end
end

local function validView(view)
    if type(view) ~= 'table' then return end
    for _, key in ipairs({ 'x', 'y', 'yaw', 'pitch', 'zoom' }) do
        if type(view[key]) ~= 'number' then return end
    end
    view.zoom = math.max(0.75, math.min(1.6, view.zoom))
    return view
end

-- Opens the view for the weapon in a bag slot (or closes it with joaat('false')); answers with the slots this weapon has
local function openAttachments(slot, view)
    if not slot then
        removeWeaponModel()
        attach = nil
        return false
    end

    local weapon = exports['rnv-inventory']:GetPlayerItems()[slot]
    local weaponData = weapon and itemData(weapon.name)
    if not (weaponData and weaponData.weapon) then return false end

    local hash, fitted = weaponData.hash, {}
    for _, name in ipairs((weapon.metadata and weapon.metadata.components) or {}) do
        local componentType = (getComponentItems()[name] and getComponentItems()[name].type)
        if componentType then fitted[componentType] = true end
    end

    local slots, answer = {}, {}
    for _, slot in ipairs(Extras.Attach.slots) do
        local accepts = {}
        for name, item in pairs(getComponentItems()) do
            if item.type == slot.type and fittingComponent(hash, item) then accepts[#accepts + 1] = name end
        end
        if #accepts > 0 or fitted[slot.type] then
            slots[#slots + 1] = slot
            answer[#answer + 1] = { type = slot.type, label = slot.label, row = slot.row, accepts = accepts }
        end
    end
    if #slots == 0 then return false end

    local running = attach ~= nil
    removeWeaponModel()
    attach = { slot = slot, hash = hash, slots = slots, view = validView(view) or { x = 0.67, y = 0.54, yaw = 0.0, pitch = 0.0, zoom = 1.0 } }
    if not running then CreateThread(attachLoop) end
    return answer
end

RegisterNUICallback('ataAttach', function(data, cb)
    cb(openAttachments(data and data.slot, data and data.view))
end)
exports('openAttachments', openAttachments)

-- A restart of the resource must not leave the model, the camera or the test NPC behind
AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    removeWeaponModel()
end)

RegisterNUICallback('ataAttachView', function(view, cb)
    cb(1)
    if attach and validView(view) then attach.view = view end
end)

-- A component item from the bag goes onto the weapon on show. Same checks as using the item with the weapon in hand
local function attachComponent(itemSlot)
    if not attach then return false end

    local items = exports['rnv-inventory']:GetPlayerItems()
    local weapon, item = items[attach.slot], items[itemSlot]
    local component = item and getComponentItems()[item.name]
    if not weapon or not component then return 'Not a weapon part: ' end

    for _, name in ipairs((weapon.metadata and weapon.metadata.components) or {}) do
        if (getComponentItems()[name] and getComponentItems()[name].type) == component.type then return 'That slot is taken: ' end
    end

    local hash = fittingComponent(attach.hash, component)
    if not hash then return 'Does not fit this weapon: ' end

    if not lib.callback.await('rnv-inventory:updateWeapon', false, 'component', tostring(item.slot), attach.slot) then return false end

    -- If that weapon is the one in hand, it changes right away (rnv-inventory does the same when the item is used)
    local current = exports['rnv-inventory']:getCurrentWeapon()
    if (current and current.slot) == attach.slot then
        GiveWeaponComponentToPed(cache.ped, attach.hash, hash)
        TriggerEvent('rnv-inventory:updateWeaponComponent', 'added', hash, item.name)
    end
    return true
end

RegisterNUICallback('ataAttachAdd', function(data, cb) cb(attachComponent(data.item)) end)
exports('attachComponent', attachComponent)

-- Extra items -----------------------------------------------------------------------------------------------------------
-- extras/items.lua is read by the server; this side receives the list and adds it to rnv-inventory's item table the same
-- way data/items.lua entries are prepared for the client
CreateThread(function()
    local items = lib.callback.await('rnv-inventory:extras:items', false)
    if type(items) ~= 'table' then return end
    local list = require 'shared.items'
    local forUi = {}
    for name, data in pairs(items) do
        data.name = name
        data.server = nil
        data.count = exports['rnv-inventory']:Search('count', name) or 0
        if (data.client and data.client.image) and not data.client.image:match('^[%w]+://') then
            data.client.image = ('%s/%s'):format(client.imagepath, data.client.image)
        end
        list[name] = data
        forUi[name] = { label = data.label, stack = data.stack, size = data.size, image = (data.client and data.client.image) }
    end
    SendNUIMessage({ action = 'ataItems', data = forUi })
end)

-- Bags ----------------------------------------------------------------------------------------------------------------
-- The bag in slot 58 (see config.lua) shows on the character's back
local SLOT_BAG = 58
local bagOnBack

CreateThread(function()
    if not Extras.Bag.enabled then return end
    while true do
        Wait(1500)
        local ped = cache.ped
        local model = GetEntityModel(ped)
        local item = exports['rnv-inventory']:GetPlayerItems()[SLOT_BAG]
        local bag = item and Extras.Bag.items[item.name]
        local look = bag and bag.back and (model == joaat('mp_f_freemode_01') and bag.back.female or model == joaat('mp_m_freemode_01') and bag.back.male)

        -- Checks the ped itself: loading the skin after join puts component 5 back to 0
        if look and GetPedDrawableVariation(ped, 5) ~= look[1] then
            SetPedComponentVariation(ped, 5, look[1], look[2] or 0, 0)
            bagOnBack = look[1]
        elseif not look and bagOnBack then
            -- Only taken off again if it is still the one we put on
            if GetPedDrawableVariation(ped, 5) == bagOnBack then SetPedComponentVariation(ped, 5, 0, 0, 0) end
            bagOnBack = nil
        end
    end
end)

-- Armour ---------------------------------------------------------------------------------------------------------------
-- The vest in slot 57 sets the max armour (level x 25) and keeps what is left of it in metadata.armour. Armour plates
-- fill it one bar (25) at a time (modules/items/client.lua). No vest = no armour
local SLOT_ARMOUR = 57
local worn, sent = nil, nil -- vest name worn, armour last saved on it

CreateThread(function()
    while true do
        Wait(500)
        local item = exports['rnv-inventory']:GetPlayerItems()[SLOT_ARMOUR]
        local level = item and Extras.Vests[item.name]
        local name = level and item.name or nil
        if name ~= worn then
            worn = name
            SetPlayerMaxArmour(cache.playerId, (level or 0) * 25)
            sent = level and math.min((item.metadata and item.metadata.armour) or 0, level * 25) or 0
            SetPedArmour(cache.ped, sent)
        else
            -- the game doesn't cap armour by itself: no vest = 0, never above the vest's max
            local armour = GetPedArmour(cache.ped)
            local max = (level or 0) * 25
            if armour > max then
                armour = max
                SetPedArmour(cache.ped, max)
            end
            if worn and armour ~= sent then
                sent = armour
                TriggerServerEvent('rnv-inventory:extras:vestArmour', armour)
            end
        end
    end
end)

exports('GetVest', function()
    local item = exports['rnv-inventory']:GetPlayerItems()[SLOT_ARMOUR]
    local level = item and Extras.Vests[item.name]
    return level and { name = item.name, level = level, max = level * 25 } or nil
end)

-- Destroy confirmed on the page (item dropped outside the inventory)
RegisterNUICallback('ataDestroy', function(slot, cb)
    cb(lib.callback.await('rnv-inventory:extras:destroy', false, slot) or false)
end)

-- Pickup feed: every 'ui_added' (AddItem, taking from a container) shows a card in rnv-interface
RegisterNetEvent('rnv-inventory:itemNotify', function(data)
    if type(data) ~= 'table' or data[2] ~= 'ui_added' or not data[1] or not data[1].name then return end
    if GetResourceState('rnv-interface') ~= 'started' then return end
    local item = data[1]
    local info = exports['rnv-inventory']:Items(item.name) or {}
    exports['rnv-interface']:Pickup({ name = item.name, label = info.label or item.name, count = data[3] or 1, rarity = info.rnv and info.rnv.rarity })
end)
