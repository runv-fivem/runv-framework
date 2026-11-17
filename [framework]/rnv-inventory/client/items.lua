if not lib then return end

local Items = require 'shared.items'

local function sendDisplayMetadata(data)
    SendNUIMessage({
		action = 'displayMetadata',
		data = data
	})
end

local function displayMetadata(metadata, value)
	local data = {}

	if type(metadata) == 'string' then
        if not value then return end

        data = { { metadata = metadata, value = value } }
	elseif table.type(metadata) == 'array' then
		for i = 1, #metadata do
			for k, v in pairs(metadata[i]) do
				data[i] = {
					metadata = k,
					value = v,
				}
			end
		end
	else
		for k, v in pairs(metadata) do
			data[#data + 1] = {
				metadata = k,
				value = v,
			}
		end
	end

    if client.uiLoaded then
        return sendDisplayMetadata(data)
    end

    CreateThread(function()
        repeat Wait(100) until client.uiLoaded

        sendDisplayMetadata(data)
    end)
end

exports('displayMetadata', displayMetadata)

local function getItem(_, name)
    if not name then return Items end

	if type(name) ~= 'string' then return end

    name = name:lower()

    if name:sub(0, 7) == 'weapon_' then
        name = name:upper()
    end

    return Items[name]
end

setmetatable(Items, {
	__call = getItem
})


local function Item(name, cb)
	local item = Items[name]
	if item then
		if not (item.client and item.client.export) and not (item.client and item.client.event) then
			item.effect = cb
		end
	end
end

local inventory = exports[shared.resource]
-- Clientside item use functions

Item('bandage', function(data, slot)
	local maxHealth = GetEntityMaxHealth(cache.ped)
	local health = GetEntityHealth(cache.ped)
	inventory:useItem(data, function(data)
		if data then
			SetEntityHealth(cache.ped, math.min(maxHealth, math.floor(health + maxHealth / 16)))
			lib.notify({ description = 'You feel better already' })
		end
	end)
end)

-- RUN V: plays an animation with the rnv-interface progress bar; true when it ran to the end
local function useWithAnim(label, dict, clip, flag, duration)
	lib.requestAnimDict(dict)
	TaskPlayAnim(cache.ped, dict, clip, 3.0, 3.0, -1, flag, 0, false, false, false)
	local ok = exports['rnv-interface']:Progress({ label = label, duration = duration, canCancel = true })
	StopAnimTask(cache.ped, dict, clip, 1.0)
	RemoveAnimDict(dict)
	return ok
end

local function rnvNotify(text)
	exports['rnv-interface']:Notify({ text = text, type = 'error', duration = 3000 })
end

-- Steel Plate (ROB RUN 'Armor segments' 1 / 2, use 1.3 s / 1.6 s): fills the worn vest that many bars (25 each)
local function steelPlate(bars, time)
	return function(data, slot)
		local vest = exports['rnv-inventory']:GetVest()
		if not vest then return rnvNotify('Put on [[body armor]] first') end
		if GetPedArmour(cache.ped) >= vest.max then return rnvNotify('Your armor is [[full]]') end
		if not useWithAnim('INSERTING PLATE...', 'clothingtie', 'try_tie_neutral_a', 49, time) then return end
		inventory:useItem(data, function(used)
			if used then SetPedArmour(cache.ped, math.min(vest.max, (math.floor(GetPedArmour(cache.ped) / 25) + bars) * 25)) end
		end)
	end
end
Item('steel_plate_1', steelPlate(1, 1300))
Item('steel_plate_2', steelPlate(2, 1600))

-- Medicine (ROB RUN 'Healing amount' / 'Use' time). Health is 100-200 on the freemode ped, so +N heals N
local function heal(amount, time, label)
	return function(data, slot)
		if GetEntityHealth(cache.ped) >= GetEntityMaxHealth(cache.ped) then return rnvNotify('You are already at [[full health]]') end
		if not useWithAnim(label, 'missheistdockssetup1clipboard@idle_a', 'idle_a', 49, time) then return end
		inventory:useItem(data, function(used)
			if used then SetEntityHealth(cache.ped, math.min(GetEntityMaxHealth(cache.ped), GetEntityHealth(cache.ped) + amount)) end
		end)
	end
end
Item('afak', heal(100, 9000, 'HEALING...'))
Item('painkillers_1', heal(25, 1800, 'TAKING PILLS...'))
Item('painkillers_2', heal(40, 1800, 'TAKING PILLS...'))

-- Injector: heals over 5 ticks of 1 s (ROB RUN 'Effect ticks' 5); no healing amount in the data: 10 / 15 per tick
local function injector(perTick)
	return function(data, slot)
		if not useWithAnim('INJECTING...', 'missheistdockssetup1clipboard@idle_a', 'idle_a', 49, 900) then return end
		inventory:useItem(data, function(used)
			if not used then return end
			for _ = 1, 5 do
				SetEntityHealth(cache.ped, math.min(GetEntityMaxHealth(cache.ped), GetEntityHealth(cache.ped) + perTick))
				Wait(1000)
			end
		end)
	end
end
Item('injector_1', injector(10))
Item('injector_2', injector(15))

client.parachute = false
Item('parachute', function(data, slot)
	if not client.parachute then
		inventory:useItem(data, function(data)
			if data then
				local chute = joaat('GADGET_PARACHUTE')
				SetPlayerParachuteTintIndex(PlayerData.id, -1)
				GiveWeaponToPed(cache.ped, chute, 0, true, false)
				SetPedGadget(cache.ped, chute, true)
				lib.requestModel(1269906701)
				client.parachute = {CreateParachuteBagObject(cache.ped, true, true), ((slot and slot.metadata) and (slot and slot.metadata).type) or -1}
				if slot.metadata.type then
					SetPlayerParachuteTintIndex(PlayerData.id, slot.metadata.type)
				end
			end
		end)
	end
end)

Item('phone', function(data, slot)
	local success, result = pcall(function()
		return exports.npwd:isPhoneVisible()
	end)

	if success then
		exports.npwd:setPhoneVisible(not result)
	end
end)

Item('clothing', function(data, slot)
	local metadata = slot.metadata

	if not metadata.drawable then return print('Clothing is missing drawable in metadata') end
	if not metadata.texture then return print('Clothing is missing texture in metadata') end

	if metadata.prop then
		if not SetPedPreloadPropData(cache.ped, metadata.prop, metadata.drawable, metadata.texture) then
			return print('Clothing has invalid prop for this ped')
		end
	elseif metadata.component then
		if not IsPedComponentVariationValid(cache.ped, metadata.component, metadata.drawable, metadata.texture) then
			return print('Clothing has invalid component for this ped')
		end
	else
		return print('Clothing is missing prop/component id in metadata')
	end

	inventory:useItem(data, function(data)
		if data then
			metadata = data.metadata

			if metadata.prop then
				local prop = GetPedPropIndex(cache.ped, metadata.prop)
				local texture = GetPedPropTextureIndex(cache.ped, metadata.prop)

				if metadata.drawable == prop and metadata.texture == texture then
					return ClearPedProp(cache.ped, metadata.prop)
				end

				-- { prop = 0, drawable = 2, texture = 1 } = grey beanie
				SetPedPropIndex(cache.ped, metadata.prop, metadata.drawable, metadata.texture, false);
			elseif metadata.component then
				local drawable = GetPedDrawableVariation(cache.ped, metadata.component)
				local texture = GetPedTextureVariation(cache.ped, metadata.component)

				if metadata.drawable == drawable and metadata.texture == texture then
					return -- item matches (setup defaults so we can strip?)
				end

				-- { component = 4, drawable = 4, texture = 1 } = jeans w/ belt
				SetPedComponentVariation(cache.ped, metadata.component, metadata.drawable, metadata.texture, 0);
			end
		end
	end)
end)


exports('Items', function(item) return getItem(nil, item) end)
exports('ItemList', function(item) return getItem(nil, item) end)

return Items
