if not lib then return end

local Inventory = {}

local Inventories = {}

local OxInventory = {}
OxInventory.__index = OxInventory

function OxInventory:openInventory(inv)
	if not (self and self.player) then return end

	inv = inv and inv ~= self and Inventory(inv) or nil
	self.open = (inv and inv.id) or self.id

    if inv then
        inv:set('open', true)
        inv.openedBy[self.id] = true
    end

    TriggerEvent('rnv-inventory:openedInventory', self.id, (inv and inv.id))
end

function OxInventory:closeInventory(noEvent)
	if not self.player or not self.open then return end

	local inv = self.open ~= self.id and Inventory(self.open)

    if inv then
        inv.openedBy[self.id] = nil
        inv:set('open', false)
    end

    self.open = false
    self.currentShop = nil
    self.containerSlot = nil

	if not noEvent then
		TriggerClientEvent('rnv-inventory:closeInventory', self.id, true)
	end

	TriggerEvent('rnv-inventory:closedInventory', self.id, (inv and inv.id))
end


function OxInventory:syncSlotsWithPlayer(slots, weight)
	TriggerClientEvent('rnv-inventory:updateSlots', self.id, slots, weight)
end

function OxInventory:syncSlotsWithClients(slots, syncOwner)
	for playerId in pairs(self.openedBy) do
		if self.id ~= playerId then
            local target = Inventories[playerId]

            if target then
			    TriggerClientEvent('rnv-inventory:updateSlots', playerId, slots, target.weight)
            end
		end
	end

	if syncOwner and self.player then
		TriggerClientEvent('rnv-inventory:updateSlots', self.id, slots, self.weight)
	end
end

local Vehicles = lib.load('data.vehicles')
local RegisteredStashes = {}

for _, stash in pairs(lib.load('data.stashes') or {}) do
	RegisteredStashes[stash.name] = {
		name = stash.name,
		label = stash.label,
		owner = stash.owner,
		slots = stash.slots,
		maxWeight = stash.weight,
		groups = stash.groups or stash.jobs,
		coords = stash.coords,
        distance = stash.distance or 10
	}
end

local GetVehicleNumberPlateText = GetVehicleNumberPlateText


local function loadInventoryData(data, player, ignoreSecurityChecks)
	local source = source
	local inventory

	if not data.type and type(data.id) == 'string' then
		if data.id:find('^glove') then
			data.type = 'glovebox'
		elseif data.id:find('^trunk') then
			data.type = 'trunk'
		elseif data.id:find('^evidence-') then
			data.type = 'policeevidence'
		end
	end

	if data.type == 'trunk' or data.type == 'glovebox' then
		local plate = data.id:sub(6)

		if server.trimplate then
			plate = string.strtrim(plate)
			data.id = ('%s%s'):format(data.id:sub(1, 5), plate)
		end

		inventory = Inventories[data.id]

		if not inventory then
			local entity

			if data.netid then
				entity = NetworkGetEntityFromNetworkId(data.netid)

				if not entity then
					return shared.info('Failed to load vehicle inventory data (no entity exists with given netid).')
				end

                data.entityId = entity
			else
				local vehicles = GetAllVehicles()

				for i = 1, #vehicles do
					local vehicle = vehicles[i]
					local _plate = GetVehicleNumberPlateText(vehicle)

					if _plate:find(plate) then
						entity = vehicle
                        data.entityId = entity
						data.netid = NetworkGetNetworkIdFromEntity(entity)
						break
					end
				end

				if not entity then
					return shared.info('Failed to load vehicle inventory data (no entity exists with given plate).')
				end
			end

			if not source then
				source = NetworkGetEntityOwner(entity)

				if not source then
					return shared.info('Failed to load vehicle inventory data (entity is unowned).')
				end
			end

			local model, class = lib.callback.await('rnv-inventory:getVehicleData', source, data.netid)
			local storage = Vehicles[data.type].models[model] or Vehicles[data.type][class]
            local dbId

            if server.getOwnedVehicleId then
                dbId = server.getOwnedVehicleId(entity)
            else
                dbId = data.id:sub(6)
            end

            inventory = Inventory.Create(data.id, plate, data.type, storage[1], 0, storage[2], false, nil, nil, dbId)
		end
	elseif data.type == 'policeevidence' then
		inventory = Inventory.Create(data.id, locale('police_evidence'), data.type, 100, 0, 100000, false)
	else
		local stash = RegisteredStashes[data.id]

		if stash then
			if stash.jobs then stash.groups = stash.jobs end
			if not ignoreSecurityChecks and player and stash.groups and not server.hasGroup(player, stash.groups) then return end

			local owner

			if stash.owner then
				if stash.owner == true then
					owner = data.owner or (player and player.owner)
				else
					owner = stash.owner
				end
			end

			inventory = Inventories[owner and ('%s:%s'):format(stash.name, owner) or stash.name]

			if not inventory then
				inventory = Inventory.Create(stash.name, stash.label or stash.name, 'stash', stash.slots, 0, stash.maxWeight, owner, nil, stash.groups)
                inventory.coords = stash.coords
                inventory.distance = stash.distance
                inventory.instance = stash.instance
			end
		end
	end

	if data.netid then
        inventory.entityId = data.entityId or NetworkGetEntityFromNetworkId(data.netid)
		inventory.netid = data.netid
	end

	return inventory or false
end

setmetatable(Inventory, {
	__call = function(self, inv, player, ignoreSecurityChecks)
        if Inventory.Lock then return false end

		if not inv then
			return self
		elseif type(inv) == 'table' then
			if inv.__index then return inv end

			return not inv.owner and Inventories[inv.id] or loadInventoryData(inv, player, ignoreSecurityChecks)
		end

		return Inventories[inv] or loadInventoryData({ id = inv }, player, ignoreSecurityChecks)
	end
})


local function getInventory(inv, owner)
	if not inv then return Inventory end

	local type = type(inv)

	if type == 'table' or type == 'number' then
		return Inventory(inv)
	else
		return Inventory({ id = inv, owner = owner })
	end
end

exports('Inventory', getInventory)
exports('GetInventory', getInventory)

function Inventory.GetInventories(invType, detailed)
	if type(invType) ~= 'string' then
		return error(('expected invType to be a string (received %s)'):format(type(invType)))
	end

	local returnData = {}

	for _, inv in pairs(Inventories) do
		if inv.type == invType then
			returnData[#returnData + 1] = detailed and inv or inv.id
		end
	end

	return returnData
end

exports('GetInventories', Inventory.GetInventories)

exports('GetInventoryItems', function(inv, owner)
	return (getInventory(inv, owner) and getInventory(inv, owner).items)
end)

function Inventory.GetContainerFromSlot(inv, slotId)
	local inventory = Inventory(inv)
	local slotData = inventory and inventory.items[slotId]

	if not slotData then return end

	local container = Inventory(slotData.metadata.container)

	if not container then
		container = Inventory.Create(slotData.metadata.container, slotData.label, 'container', slotData.metadata.size[1], 0, slotData.metadata.size[2], false)
	end

	return container
end

exports('GetContainerFromSlot', Inventory.GetContainerFromSlot)

function Inventory.CloseAll(inv, ignoreId)
	if not inv then
		for _, data in pairs(Inventories) do
			for playerId in pairs(data.openedBy) do
				local playerInv = Inventory(playerId)

				if playerInv then playerInv:closeInventory(true) end
			end
		end

		return TriggerClientEvent('rnv-inventory:closeInventory', -1, true)
	end

	local inventory = Inventory(inv)

	if not inventory then return end

	for playerId in pairs(inv.openedBy) do
		local playerInv = Inventory(playerId)

		if playerInv and playerId ~= ignoreId then
            playerInv:closeInventory()
        end
	end
end

function Inventory.Set(inv, k, v)
	inv = Inventory(inv)

	if inv then
		if type(v) == 'number' then
			v = math.floor(v + 0.5)
		end

		if k == 'open' and v == false then
			if inv.type ~= 'player' then
				if inv.player then
					inv.type = 'player'
				elseif inv.type == 'drop' and not next(inv.items) and not next(inv.openedBy) then
					return Inventory.Remove(inv)
				else
					inv.time = os.time()
				end
			end

			if inv.player then
				inv.containerSlot = nil
			end
		elseif k == 'maxWeight' and v < 1000 then
			v = v * 1000
		end

		inv[k] = v
	end
end

function Inventory.Get(inv, key)
	inv = Inventory(inv)
	if inv then
		return inv[key]
	end
end


local function minimal(inv)
	inv = Inventory(inv)
	local inventory, count = {}, 0
	for k, v in pairs(inv.items) do
		if v.name and v.count > 0 then
			count = count + 1
			inventory[count] = {
				name = v.name,
				count = v.count,
				slot = k,
				metadata = next(v.metadata) and v.metadata or nil
			}
		end
	end
	return inventory
end

local Items = require 'server.items'

-- RUN V grid: slot N is a cell in a 6 column grid, an item sits at its top-left cell and covers size = { w, h }
-- Player inventories also have fixed slots after the grid (see extras/config.lua)
local GRID_COLS = 6
local GRID_CELLS = 54
local SLOT_WEAPON1, SLOT_WEAPON2, SLOT_ARMOR, SLOT_BAG, SLOT_POUCH = 55, 56, 57, 58, 59
local POUCH_FIRST, POUCH_LAST = 60, 63

local function itemSize(name)
	local item = Items(name)
	local size = item and item.size
	return size and size[1] or 1, size and size[2] or 1
end

local function bagInfo(name)
	return name and Extras.Bag.items[name]
end

-- Open grid rows: players get them from the worn bag, other inventories use all their slots
local function openRows(inv)
	if inv.type ~= 'player' then return math.ceil(inv.slots / GRID_COLS) end
	if inv.rowsOverride then return inv.rowsOverride end
	local bag = inv.items[SLOT_BAG]
	local info = bag and bagInfo(bag.name)
	return info and info.rows or Extras.Bag.baseRows
end

local function pouchCells(inv)
	if inv.cellsOverride then return inv.cellsOverride end
	local pouch = inv.items[SLOT_POUCH]
	local info = pouch and bagInfo(pouch.name)
	return info and info.cells or 0
end

local function gridLimit(inv)
	return inv.type == 'player' and GRID_CELLS or inv.slots
end

local function rectsOverlap(slotA, wA, hA, slotB, wB, hB)
	local ax, ay = (slotA - 1) % GRID_COLS, (slotA - 1) // GRID_COLS
	local bx, by = (slotB - 1) % GRID_COLS, (slotB - 1) // GRID_COLS
	return ax < bx + wB and bx < ax + wA and ay < by + hB and by < ay + hA
end

-- Fixed player slots: one item each, only the right kind
local function fixedSlotFits(inv, slot, name, ignore)
	local current = inv.items[slot]
	if current and not (ignore and ignore[slot]) then return false end
	local item = Items(name)
	if not item then return false end
	local bag = bagInfo(name)

	if slot == SLOT_WEAPON1 or slot == SLOT_WEAPON2 then return item.weapon == true end
	if slot == SLOT_ARMOR then return Extras.Vests[name] ~= nil end
	if slot == SLOT_BAG then return bag ~= nil and bag.kind == 'back' end
	if slot == SLOT_POUCH then return bag ~= nil and bag.kind == 'pouch' end
	if slot >= POUCH_FIRST and slot <= POUCH_LAST then
		local w, h = itemSize(name)
		return slot - POUCH_FIRST < pouchCells(inv) and w == 1 and h == 1 and not bag
	end
	return false
end

local function fits(inv, slot, w, h, ignore, extra, name)
	if inv.type == 'player' and slot > GRID_CELLS then
		return name ~= nil and fixedSlotFits(inv, slot, name, ignore)
	end

	local limit = gridLimit(inv)
	local x, y = (slot - 1) % GRID_COLS, (slot - 1) // GRID_COLS
	if x + w > GRID_COLS or y + h > openRows(inv) or (y + h) * GRID_COLS > limit then return false end

	for otherSlot, other in pairs(inv.items) do
		if otherSlot <= limit and not (ignore and ignore[otherSlot]) then
			local ow, oh = itemSize(other.name)
			if rectsOverlap(slot, w, h, otherSlot, ow, oh) then return false end
		end
	end

	for i = 1, extra and #extra or 0 do
		local e = extra[i]
		if rectsOverlap(slot, w, h, e[1], e[2], e[3]) then return false end
	end

	return true
end

local function findFit(inv, name, extra)
	local w, h = itemSize(name)
	for slot = 1, gridLimit(inv) do
		if fits(inv, slot, w, h, nil, extra) then return slot end
	end
end

local function layoutStillFits(inv, rows, cells, skip)
	for slot, item in pairs(inv.items) do
		if not (skip and skip[slot]) then
			if slot <= GRID_CELLS then
				local _, h = itemSize(item.name)
				if (slot - 1) // GRID_COLS + h > rows then return false end
			elseif slot >= POUCH_FIRST and slot <= POUCH_LAST and slot - POUCH_FIRST >= cells then
				return false
			end
		end
	end
	return true
end

Inventory.GridFits = fits
Inventory.GridItemSize = itemSize
Inventory.GridOpenRows = openRows
Inventory.GridPouchCells = pouchCells

function Inventory.SetSlot(inv, item, count, metadata, slot)
	inv = Inventory(inv)

    if not (inv and inv.slots) then return false, 'invalid_inventory' end

   	if type(count) ~= 'number' then return false, 'invalid_count' end

    count = math.floor(count + 0.5)

    if type(item) ~= 'table' then
        item = Items(item)

        if not item then return false, 'invalid_item' end
    end

	local currentSlot = inv.items[slot]
	local newCount = currentSlot and currentSlot.count + count or count
	local newWeight = currentSlot and inv.weight - currentSlot.weight or inv.weight

	if currentSlot and newCount < 1 then
		TriggerClientEvent('rnv-inventory:itemNotify', inv.id, { currentSlot, 'ui_removed', currentSlot.count })
		currentSlot = nil
	else
		currentSlot = {name = item.name, label = item.label, weight = item.weight, slot = slot, count = newCount, description = item.description, metadata = metadata, stack = item.stack, close = item.close}
		local slotWeight = Inventory.SlotWeight(item, currentSlot)
		currentSlot.weight = slotWeight
		newWeight = newWeight + slotWeight

		if not inv.quiet then TriggerClientEvent('rnv-inventory:itemNotify', inv.id, { currentSlot, count < 0 and 'ui_removed' or 'ui_added', math.abs(count) }) end
	end

	inv.weight = newWeight
	inv.items[slot] = currentSlot
	inv.changed = true

	return true, currentSlot
end

CreateThread(function()
    Inventory.accounts = server.accounts
    TriggerEvent('rnv-inventory:loadInventory', Inventory)
end)

function Inventory.GetAccountItemCounts(inv)
    local inventory = Inventory(inv)

    if not inventory then return end

    local accounts = table.clone(server.accounts)

	for _, v in pairs(inventory.items) do
		if accounts[v.name] then
			accounts[v.name] = accounts[v.name] + v.count
		end
	end

    return accounts
end

function Inventory.SlotWeight(item, slot, ignoreCount)
	local weight = ignoreCount and item.weight or item.weight * (slot.count or 1)

	if not slot.metadata then slot.metadata = {} end

	if item.ammoname and slot.metadata.ammo then
		local ammoWeight = (Items(item.ammoname) and Items(item.ammoname).weight)

		if ammoWeight then
			weight = weight + ((ammoWeight * slot.metadata.ammo))
		end
	end

    if item.hash == joaat('WEAPON_PETROLCAN') then
        slot.metadata.weight = 15000 * (slot.metadata.ammo / 100)
    end

	if slot.metadata.components then
		for i = #slot.metadata.components, 1, -1 do
			local componentWeight = (Items(slot.metadata.components[i]) and Items(slot.metadata.components[i]).weight)

			if componentWeight then
				weight = weight + componentWeight
			end
		end
	end

	if slot.metadata.weight then
		weight = weight + (ignoreCount and slot.metadata.weight or (slot.metadata.weight * (slot.count or 1)))
	end

	return weight
end

function Inventory.CalculateWeight(items)
	local weight = 0
	for _, v in pairs(items) do
		local item = Items(v.name)
		if item then
			weight = weight + Inventory.SlotWeight(item, v)
		end
	end
	return weight
end

-- This should be handled by frameworks, but sometimes isn't or is exploitable in some way
local activeIdentifiers = {}

local function hasActiveInventory(playerId, owner)
	local activePlayer = activeIdentifiers[owner]

	if activePlayer then
        if activePlayer == playerId then
            error('attempted to load active player\'s inventory a secondary time', 0)
        end

		local inventory = Inventory(activePlayer)

		if inventory then
			local endpoint = GetPlayerEndpoint(activePlayer)

			if endpoint then
				DropPlayer(playerId, ("Character identifier '%s' is already active."):format(owner))

                -- Supposedly still getting stuck? Print info and hope somebody reports back (lol)
				print(('kicked player.%s (charid is already in use)'):format(playerId), json.encode({
					oldId = activePlayer,
					newId = playerId,
					charid = owner,
					endpoint = endpoint,
					playerName = GetPlayerName(activePlayer),
					fivem = GetPlayerIdentifierByType(activePlayer, 'fivem'),
					license = GetPlayerIdentifierByType(activePlayer, 'license2') or GetPlayerIdentifierByType(activePlayer, 'license'),
				}, {
					indent = true,
                    sort_keys = true
				}))

				return true
			end

			Inventory.CloseAll(inventory)
			db.savePlayer(owner, json.encode(inventory:minimal()))
			Inventory.Remove(inventory)
			Wait(100)
		end
	end

	activeIdentifiers[owner] = playerId
end

RegisterCommand('clearActiveIdentifier', function(source, args)
    if source ~= 0 then return end

	local activePlayer = activeIdentifiers[args[1]] or activeIdentifiers[tonumber(args[1])]
    local inventory = activePlayer and Inventory(activePlayer)

    if not inventory then return end

    local endpoint = GetPlayerEndpoint(activePlayer)

    if endpoint then
        DropPlayer(activePlayer, 'Kicked')

        -- Supposedly still getting stuck? Print info and hope somebody reports back (lol)
        print(('kicked player.%s (clearActiveIdentifier)'):format(activePlayer), json.encode({
            oldId = activePlayer,
            charid = inventory.owner,
            endpoint = endpoint,
            playerName = GetPlayerName(activePlayer),
            fivem = GetPlayerIdentifierByType(activePlayer, 'fivem'),
            license = GetPlayerIdentifierByType(activePlayer, 'license2') or GetPlayerIdentifierByType(activePlayer, 'license'),
        }, {
            indent = true,
            sort_keys = true
        }))
    end

    Inventory.CloseAll(inventory)
    db.savePlayer(inventory.owner, json.encode(inventory:minimal()))
    Inventory.Remove(inventory)
end, true)

function Inventory.Create(id, label, invType, slots, weight, maxWeight, owner, items, groups, dbId)
	if invType == 'player' and hasActiveInventory(id, owner) then return end

	local self = {
		id = id,
		label = label or id,
		type = invType,
		slots = slots,
		weight = weight,
		maxWeight = 1000000000, -- ponytail: RUN V has no weight, the grid is the only limit
		owner = owner,
		items = type(items) == 'table' and items,
		open = false,
		set = Inventory.Set,
		get = Inventory.Get,
		minimal = minimal,
		time = os.time(),
		groups = groups,
		openedBy = {},
        dbId = dbId
	}

	if invType == 'drop' or invType == 'temp' or invType == 'dumpster' then
		self.datastore = true
	else
		self.changed = false

		if invType ~= 'glovebox' and invType ~= 'trunk' then
			self.dbId = id

			if invType ~= 'player' and owner and type(owner) ~= 'boolean' then
				self.id = ('%s:%s'):format(self.id, owner)
			end
		end
	end

	if not items then
		self.items, self.weight = Inventory.Load(self.dbId, invType, owner)
	elseif weight == 0 and next(items) then
		self.weight = Inventory.CalculateWeight(items)
	end

	Inventories[self.id] = setmetatable(self, OxInventory)
	return Inventories[self.id]
end

function Inventory.Remove(inv)
	inv = Inventory(inv)

	if not inv then return end

    if inv.type == 'drop' then
        TriggerClientEvent('rnv-inventory:removeDrop', -1, inv.id)
        Inventory.Drops[inv.id] = nil
    elseif inv.player then
        activeIdentifiers[inv.owner] = nil
    end

    for playerId in pairs(inv.openedBy) do
        if inv.id ~= playerId then
            local target = Inventories[playerId]

            if target then
                target:closeInventory()
            end
        end
    end

    if not inv.datastore and (inv.changed or inv.player) then
        Inventory.Save(inv)
    end

    Inventories[inv.id] = nil
end

exports('RemoveInventory', Inventory.Remove)

function Inventory.UpdateVehicle(oldPlate, newPlate)
	oldPlate = oldPlate:upper()
	newPlate = newPlate:upper()

	if server.trimplate then
		oldPlate = string.strtrim(oldPlate)
		newPlate = string.strtrim(newPlate)
	end

	local trunk = Inventory(('trunk%s'):format(oldPlate))
	local glove = Inventory(('glove%s'):format(oldPlate))

	if trunk then
		Inventory.CloseAll(trunk)

		Inventories[trunk.id] = nil
		trunk.label = newPlate
		trunk.dbId = type(trunk.id) == 'number' and trunk.dbId or newPlate
		trunk.id = ('trunk%s'):format(newPlate)
		Inventories[trunk.id] = trunk
	end

	if glove then
		Inventory.CloseAll(glove)

		Inventories[glove.id] = nil
		glove.label = newPlate
		glove.dbId = type(glove.id) == 'number' and glove.dbId or newPlate
		glove.id = ('glove%s'):format(newPlate)
		Inventories[glove.id] = glove
	end
end

exports('UpdateVehicle', Inventory.UpdateVehicle)

function Inventory.Save(inv)
	inv = Inventory(inv)

	if not inv or inv.datastore then return end

    local buffer, n = {}, 0

    for k, v in pairs(inv.items) do
        if not Items.UpdateDurability(inv, v, Items(v.name), nil, os.time()) then
            n = n + 1
            buffer[n] = {
                name = v.name,
                count = v.count,
                slot = k,
                metadata = next(v.metadata) and v.metadata or nil
            }
        end
    end

    local data = next(buffer) and json.encode(buffer) or nil
    inv.changed = false

    if inv.player then
        return shared.framework ~= 'esx' and db.savePlayer(inv.owner, data)
    elseif inv.type == 'trunk' then
        return db.saveTrunk(inv.dbId, data)
    elseif inv.type == 'glovebox' then
        return db.saveGlovebox(inv.dbId, data)
    end

    return db.saveStash(inv.owner, inv.dbId, data)
end


local function randomItem(loot, items, size)
    local itemIndex = math.random(1, size)
    local selectedItem = nil

    for _ = 1, size do
        selectedItem = loot[itemIndex]
        local found = false

        for i = 1, #items do
            if items[i][1] == selectedItem[1] then
                found = true
                break
            end
        end

        if not found then break end

        itemIndex = ((itemIndex - 1) % size) + 1
    end

    return selectedItem
end

local function randomLoot(loot)
    local items = {}
    local size = #loot
    local itemCount = math.random(0, 3)

    for _ = 1, itemCount do
        if #items >= size then break end

        local item = randomItem(loot, items, size)

        if item and math.random(1, 100) <= (item[4] or 80) then
            local count = math.random(item[2], item[3])

            if count > 0 then
                items[#items + 1] = { item[1], count }
            end
        end
    end

    return items
end

local function generateItems(inv, invType, items)
	if items == nil then
		if invType == 'dumpster' then
			items = randomLoot(server.dumpsterloot)
		elseif invType == 'vehicle' then
			items = randomLoot(server.vehicleloot)
		end
	end

	if not items then
		items = {}
	end

	local returnData, totalWeight = table.create(#items, 0), 0
	for i = 1, #items do
		local v = items[i]
		local item = Items(v[1])
		if not item then
			warn('unable to generate', v[1], 'item does not exist')
		else
			local metadata, count = Items.Metadata(inv, item, v[3] or {}, v[2])
			local weight = Inventory.SlotWeight(item, {count=count, metadata=metadata})
			totalWeight = totalWeight + weight
			returnData[i] = {name = item.name, label = item.label, weight = weight, slot = i, count = count, description = item.description, metadata = metadata, stack = item.stack, close = item.close}
		end
	end

	return returnData, totalWeight
end

function Inventory.Load(id, invType, owner)
    if not invType then return end

	local result

    if invType == 'trunk' or invType == 'glovebox' then
        result = id and (invType == 'trunk' and db.loadTrunk(id) or db.loadGlovebox(id))

        if not result then
            if server.randomloot then
                return generateItems(id, 'vehicle')
            end
        else
            result = result[invType]
        end
	elseif invType == 'dumpster' then
		if server.randomloot then
			return generateItems(id, invType)
		end
	elseif id then
		result = db.loadStash(owner or '', id)
	end

	local returnData, weight = {}, 0

	if result and type(result) == 'string' then
		result = json.decode(result)
	end

	if result then
		local ostime = os.time()

		for _, v in pairs(result) do
			local item = Items(v.name)
			if item then
				v.metadata = Items.CheckMetadata(v.metadata or {}, item, v.name, ostime)
				local slotWeight = Inventory.SlotWeight(item, v)
				weight = weight + slotWeight
				returnData[v.slot] = {name = item.name, label = item.label, weight = slotWeight, slot = v.slot, count = v.count, description = item.description, metadata = v.metadata, stack = item.stack, close = item.close}
			end
		end
	end

	return returnData, weight
end

local function assertMetadata(metadata)
	if metadata and type(metadata) ~= 'table' then
		metadata = metadata and { type = metadata or nil }
	end

	return metadata
end

function Inventory.GetItem(inv, item, metadata, returnsCount)
	if type(item) ~= 'table' then item = Items(item) end

	if item then
		item = returnsCount and item or table.clone(item)
		inv = Inventory(inv)
		local count = 0

		if inv then
			local ostime = os.time()
			metadata = assertMetadata(metadata)

			for _, v in pairs(inv.items) do
				if v.name == item.name and (not metadata or table.contains(v.metadata, metadata)) and not Items.UpdateDurability(inv, v, item, nil, ostime) then
                    count = count + v.count
				end
			end
		end

		if returnsCount then return count else
			item.count = count
			return item
		end
	end
end
exports('GetItem', Inventory.GetItem)

function Inventory.SwapSlots(fromInventory, toInventory, slot1, slot2)
	local fromSlot = fromInventory.items[slot1] and table.clone(fromInventory.items[slot1]) or nil
	local toSlot = toInventory.items[slot2] and table.clone(toInventory.items[slot2]) or nil

	if fromSlot then fromSlot.slot = slot2 end
	if toSlot then toSlot.slot = slot1 end

	fromInventory.items[slot1], toInventory.items[slot2] = toSlot, fromSlot
	fromInventory.changed, toInventory.changed = true, true

	return fromSlot, toSlot
end
exports('SwapSlots', Inventory.SwapSlots)

function Inventory.ContainerWeight(container, metaWeight, playerInventory)
	playerInventory.weight = playerInventory.weight - container.weight
	container.weight = Items(container.name).weight
	container.weight = container.weight + metaWeight
	container.metadata.weight = metaWeight
	playerInventory.weight = playerInventory.weight + container.weight
end

function Inventory.SetItem(inv, item, count, metadata)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end
	if type(count) ~= 'number' then return false, 'invalid_count' end

	count = math.floor(count + 0.5)
	if count < 0 then return false, 'negative_count' end

	inv = Inventory(inv)

	if not inv then return false, 'invalid_inventory' end

	inv.changed = true
	local itemCount = Inventory.GetItem(inv, item.name, metadata, true)

	if count > itemCount then
		count = count - itemCount
		return Inventory.AddItem(inv, item.name, count, metadata)
	elseif count < itemCount then
		itemCount = itemCount - count
		return Inventory.RemoveItem(inv, item.name, itemCount, metadata)
	end
end
exports('SetItem', Inventory.SetItem)

function Inventory.GetCurrentWeapon(inv)
	inv = Inventory(inv)

	if (inv and inv.player) then
		local weapon = inv.items[inv.weapon]

		if weapon and Items(weapon.name).weapon then
			return weapon
		end

		inv.weapon = nil
	end
end
exports('GetCurrentWeapon', Inventory.GetCurrentWeapon)

function Inventory.GetSlot(inv, slotId)
	if not inv or type(slotId) ~= 'number' then return end

	inv = Inventory(inv)
	local slot = inv and (inv.items and inv.items[slotId])

	if slot and not Items.UpdateDurability(inv, slot, Items(slot.name), nil, os.time()) then
        return slot
	end
end
exports('GetSlot', Inventory.GetSlot)

function Inventory.SetDurability(inv, slotId, durability)
	if not inv or type(slotId) ~= 'number' or type(durability) ~= 'number' then return end

	inv = Inventory(inv)
	local slot = inv and (inv.items and inv.items[slotId])

	if not slot then return end

    Items.UpdateDurability(inv, slot, Items(slot.name), durability)

    if inv.player and server.syncInventory then
        server.syncInventory(inv)
    end
end
exports('SetDurability', Inventory.SetDurability)

local Utils = require 'server.utils'

function Inventory.SetMetadata(inv, slotId, metadata)
	if not inv or type(slotId) ~= 'number' then return end

	inv = Inventory(inv)
	local slot = inv and (inv.items and inv.items[slotId])

	if not slot then return end

    local item = Items(slot.name)
    local imageurl = slot.metadata.imageurl
    slot.metadata = type(metadata) == 'table' and metadata or { type = metadata or nil }
    inv.changed = true

    if metadata.weight then
        inv.weight = inv.weight - slot.weight
        slot.weight = Inventory.SlotWeight(item, slot)
        inv.weight = inv.weight + slot.weight
    end

    if metadata.durability ~= slot.metadata.durability then
        Items.UpdateDurability(inv, slot, item, metadata.durability)
    else
        inv:syncSlotsWithClients({
            {
                item = slot,
                inventory = inv.id
            }
        }, true)
    end

    if inv.player and server.syncInventory then
        server.syncInventory(inv)
    end

    if metadata.imageurl ~= imageurl and Utils.IsValidImageUrl then
        if Utils.IsValidImageUrl(metadata.imageurl) then
            Utils.DiscordEmbed('Valid image URL', ('Updated item "%s" (%s) with valid url in "%s".\n%s\nid: %s\nowner: %s'):format(metadata.label or slot.label, slot.name, inv.label, metadata.imageurl, inv.id, inv.owner, metadata.imageurl), metadata.imageurl, 65280)
        else
            Utils.DiscordEmbed('Invalid image URL', ('Updated item "%s" (%s) with invalid url in "%s".\n%s\nid: %s\nowner: %s'):format(metadata.label or slot.label, slot.name, inv.label, metadata.imageurl, inv.id, inv.owner, metadata.imageurl), metadata.imageurl, 16711680)
            metadata.imageurl = nil
        end
    end
end

exports('SetMetadata', Inventory.SetMetadata)

function Inventory.SetSlotCount(inv, slots)
	inv = Inventory(inv)

	if not inv then return end
	if type(slots) ~= 'number' then return end

	inv.changed = true
	inv.slots = slots

	if inv.player then
        TriggerClientEvent('rnv-inventory:refreshSlotCount', inv.id, {inventoryId = inv.id, slots = inv.slots})
    end

    for playerId in pairs(inv.openedBy) do
        if playerId ~= inv.id then
            TriggerClientEvent('rnv-inventory:refreshSlotCount', playerId, {inventoryId = inv.id, slots = inv.slots})
        end
	end
end

exports('SetSlotCount', Inventory.SetSlotCount)

function Inventory.SetMaxWeight(inv, maxWeight)
	inv = Inventory(inv)

	if not inv then return end
	if type(maxWeight) ~= 'number' then return end

	inv.maxWeight = maxWeight

    if inv.player then
        TriggerClientEvent('rnv-inventory:refreshMaxWeight', inv.id, {inventoryId = inv.id, maxWeight = inv.maxWeight})
    end

    for playerId in pairs(inv.openedBy) do
        if playerId ~= inv.id then
            TriggerClientEvent('rnv-inventory:refreshMaxWeight', playerId, {inventoryId = inv.id, maxWeight = inv.maxWeight})
        end
	end
end

exports('SetMaxWeight', Inventory.SetMaxWeight)

-- RUN V cash: where joaat('count') money goes (top up stacks below Extras.MoneyStack, then new 1x1 slots). nil = no room
local function moneyPlan(inv, count)
	local cap, plan, taken = Extras.MoneyStack, {}, {}
	for i = 1, gridLimit(inv) do
		local data = inv.items[i]
		if count <= 0 then break end
		if data and data.name == 'money' and data.count < cap then
			local add = math.min(cap - data.count, count)
			plan[#plan + 1] = { slot = i, count = add }
			count = count - add
		end
	end
	while count > 0 do
		local slot = findFit(inv, 'money', taken)
		if not slot then return nil end
		local add = math.min(cap, count)
		plan[#plan + 1] = { slot = slot, count = add }
		taken[#taken + 1] = { slot, 1, 1 }
		count = count - add
	end
	return plan
end

function Inventory.AddItem(inv, item, count, metadata, slot, cb)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end
	if type(count) ~= 'number' then return false, 'invalid_count' end

	count = math.floor(count + 0.5)
	if count <= 0 then return false, 'negative_count' end

	inv = Inventory(inv)

	if not (inv and inv.slots) then return false, 'invalid_inventory' end

	local toSlot, slotMetadata, slotCount
	local success, response = false
	local invokingResource = server.loglevel > 1 and GetInvokingResource()

	metadata = assertMetadata(metadata)

	if item.name == 'money' and Extras.MoneyStack and not (slot and slot > gridLimit(inv)) then
		local plan = moneyPlan(inv, count)
		if not plan then
			if cb then return cb(false, 'inventory_full') end
			return false, 'inventory_full'
		end
		inv.changed = true
		local changed = {}
		inv.quiet = true -- one pickup card for the whole amount, not one per slot
		for i = 1, #plan do
			Inventory.SetSlot(inv, item, plan[i].count, {}, plan[i].slot)
			changed[i] = { item = inv.items[plan[i].slot], inventory = inv.id }
		end
		inv.quiet = nil
		TriggerClientEvent('rnv-inventory:itemNotify', inv.id, { inv.items[plan[1].slot], 'ui_added', count })
		if inv.player and server.syncInventory then server.syncInventory(inv) end
		inv:syncSlotsWithClients(changed, true)
		local first = inv.items[plan[1].slot]
		if cb then return cb(true, first) end
		return true, first
	end

	if slot then
		local slotData = inv.items[slot]
		slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

		local sw, sh = itemSize(item.name)
		if (not slotData and fits(inv, slot, sw, sh, nil, nil, item.name)) or (slotData and item.stack and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata)) then
			toSlot = slot
		end
	end

	if not toSlot then
		local items = inv.items
		local w, h = itemSize(item.name)
		local taken = {}
		local done = false
		slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

		for i = 1, gridLimit(inv) do
			local slotData = items[i]

			if item.stack and slotData ~= nil and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata) then
				toSlot = i
				break
			elseif not item.stack and not slotData and fits(inv, i, w, h, nil, taken) then
				if not toSlot then toSlot = {} end

				toSlot[#toSlot + 1] = { slot = i, count = slotCount, metadata = slotMetadata }
				taken[#taken + 1] = { i, w, h }

				if count == slotCount then
					done = true
					break
				end

				count = count - 1
				slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)
			elseif not toSlot and not slotData and fits(inv, i, w, h) then
				toSlot = i
			end
		end

		-- Not every unstackable copy found a place: add nothing rather than part of it
		if type(toSlot) == 'table' and not done then toSlot = nil end
	end

	if not toSlot then return false, 'inventory_full' end

	inv.changed = true

	local toSlotType = type(toSlot)

	if toSlotType == 'number' then
		Inventory.SetSlot(inv, item, slotCount, slotMetadata, toSlot)

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		inv:syncSlotsWithClients({
			{
				item = inv.items[toSlot],
				inventory = inv.id
			}
		}, true)

		if invokingResource then
			lib.logger(inv.owner, 'addItem', ('"%s" added %sx %s to "%s"'):format(invokingResource, count, item.name, inv.label))
		end

		success = true
		response = inv.items[toSlot]
	elseif toSlotType == 'table' then
		local added = 0

		for i = 1, #toSlot do
			local data = toSlot[i]
			added = added + data.count
			Inventory.SetSlot(inv, item, data.count, data.metadata, data.slot)
			toSlot[i] = { item = inv.items[data.slot], inventory = inv.id }
		end

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		inv:syncSlotsWithClients(toSlot, true)

		if invokingResource then
			lib.logger(inv.owner, 'addItem', ('"%s" added %sx %s to "%s"'):format(invokingResource, added, item.name, inv.label))
		end

		for i = 1, #toSlot do
			toSlot[i] = toSlot[i].item
		end

		success = true
		response = toSlot
	end

	if cb then
		return cb(success, response)
	end

	return success, response
end

exports('AddItem', Inventory.AddItem)

function Inventory.Search(inv, search, items, metadata)
	if items then
		inv = Inventory(inv)

		if inv then
			inv = inv.items

			if search == 'slots' then search = 1 elseif search == 'count' then search = 2 end
			if type(items) == 'string' then items = {items} end

			metadata = assertMetadata(metadata)
			local itemCount = #items
			local returnData = {}

			for i = 1, itemCount do
				local item = string.lower(items[i])
				if item:sub(0, 7) == 'weapon_' then item = string.upper(item) end

				if search == 1 then
					returnData[item] = {}
				elseif search == 2 then
					returnData[item] = 0
				end

				for _, v in pairs(inv) do
					if v.name == item then
						if not v.metadata then v.metadata = {} end

						if not metadata or table.contains(v.metadata, metadata) then
							if search == 1 then
								returnData[item][#returnData[item]+1] = inv[v.slot]
							elseif search == 2 then
								returnData[item] = returnData[item] + v.count
							end
						end
					end
				end
			end

			if next(returnData) then return itemCount == 1 and returnData[items[1]] or returnData end
		end
	end

	return false
end
exports('Search', Inventory.Search)

function Inventory.GetItemSlots(inv, item, metadata, strict)
	if type(item) ~= 'table' then item = Items(item) end
	if not item then return end

	inv = Inventory(inv)
	if not (inv and inv.slots) then return end

	local totalCount, slots, emptySlots = 0, {}, inv.slots

	if strict == nil then strict = true end
	local tablematch = strict and table.matches or table.contains

	for k, v in pairs(inv.items) do
		emptySlots = emptySlots - 1
		if v.name == item.name then
			if metadata and v.metadata == nil then
				v.metadata = {}
			end
			if not metadata or tablematch(v.metadata, metadata) then
				totalCount = totalCount + v.count
				slots[k] = v.count
			end
		end
	end

	return slots, totalCount, emptySlots
end
exports('GetItemSlots', Inventory.GetItemSlots)

function Inventory.RemoveItem(inv, item, count, metadata, slot, ignoreTotal, strict)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end
	if type(count) ~= 'number' then return false, 'invalid_count' end

	count = math.floor(count + 0.5)
	if count <= 0 then return false, 'negative_count' end

	inv = Inventory(inv)

    if not (inv and inv.slots) then return false, 'invalid_inventory' end

    if slot then
        local slotItem = inv.items[slot]

        if not slotItem then
            return false, 'no_item_in_slot'
        end

        if count > slotItem.count then
            if not ignoreTotal then return false, 'not_enough_items_in_slot' end

            count = slotItem.count
        end
    end

	metadata = assertMetadata(metadata)
	if strict == nil then strict = true end
	local itemSlots, totalCount = Inventory.GetItemSlots(inv, item, metadata, strict)

	if not itemSlots then return false end

	if totalCount and count > totalCount then
		if not ignoreTotal then return false, 'not_enough_items' end

		count = totalCount
	end

	local removed, total, slots = 0, count, {}

	if slot and itemSlots[slot] then
		removed = count
		local ok, result = Inventory.SetSlot(inv, item, -count, inv.items[slot].metadata, slot)

		if not ok then
		    error(('Failed to remove %sx %s from inventory-%s:slot-%s (%s).'):format(count, item.name, inv.id, slot, result))
		end

		slots[#slots+1] = inv.items[slot] or slot
	elseif itemSlots and totalCount > 0 then
		for k, v in pairs(itemSlots) do
			if removed < total then
				if v == count then
					TriggerClientEvent('rnv-inventory:itemNotify', inv.id, { inv.items[k], 'ui_removed', v })

					removed = total
					inv.weight = inv.weight - (inv.items[k].weight)
					inv.items[k] = nil
					slots[#slots+1] = inv.items[k] or k
				elseif v > count then
					local ok, result = Inventory.SetSlot(inv, item, -count, inv.items[k].metadata, k)

					if not ok then
					    error(('Failed to remove %sx %s from inventory-%s:slot-%s (%s).'):format(count, item.name, inv.id, k, result))
					end

					slots[#slots+1] = inv.items[k] or k
					removed = total
					count = v - count
				else
					TriggerClientEvent('rnv-inventory:itemNotify', inv.id, { inv.items[k], 'ui_removed', v })

					removed = removed + v
					count = count - v
					inv.weight = inv.weight - (inv.items[k].weight)
					inv.items[k] = nil
					slots[#slots+1] = k
				end
			else break end
		end
	end

	if removed > 0 then
		inv.changed = true

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		local array = table.create(#slots, 0)

		for k, v in pairs(slots) do
			array[k] = {item = type(v) == 'number' and { slot = v } or v, inventory = inv.id}
		end

		inv:syncSlotsWithClients(array, true)

		local invokingResource = server.loglevel > 1 and GetInvokingResource()

		if invokingResource then
			lib.logger(inv.owner, 'removeItem', ('"%s" removed %sx %s from "%s"'):format(invokingResource, removed, item.name, inv.label))
		end

		return true
	end

	return false, 'not_enough_items'
end
exports('RemoveItem', Inventory.RemoveItem)

function Inventory.CanCarryItem(inv, item, count, metadata)
	if type(item) ~= 'table' then item = Items(item) end

	if item then
		inv = Inventory(inv)

		if inv then
			local itemSlots = Inventory.GetItemSlots(inv, item, type(metadata) == 'table' and metadata or { type = metadata or nil })

			if not itemSlots then return end
			if item.name == 'money' and Extras.MoneyStack then return moneyPlan(inv, count or 1) ~= nil end
			if item.stack and next(itemSlots) then return true end

			-- Grid: every copy that needs its own place must fit
			local w, h = itemSize(item.name)
			local taken = {}
			for _ = 1, item.stack and 1 or (count or 1) do
				local slot = findFit(inv, item.name, taken)
				if not slot then return false end
				taken[#taken + 1] = { slot, w, h }
			end
			return true
		end
	end
end
exports('CanCarryItem', Inventory.CanCarryItem)

function Inventory.CanCarryAmount(inv, item)
    if type(item) ~= 'table' then item = Items(item) end
	inv = Inventory(inv)

    if inv and item then
		local availableWeight = inv.maxWeight - inv.weight
		return math.floor(availableWeight / item.weight)
    end
end

exports('CanCarryAmount', Inventory.CanCarryAmount)

function Inventory.CanCarryWeight(inv, weight)
	inv = Inventory(inv)

	if not inv then return end

	return true, inv.maxWeight -- RUN V: no weight
end
exports('CanCarryWeight', Inventory.CanCarryWeight)

function Inventory.CanSwapItem(inv, firstItem, firstItemCount, testItem, testItemCount)
	inv = Inventory(inv)

	if not inv then return end

	local firstItemData = Inventory.GetItem(inv, firstItem)
	local testItemData = Inventory.GetItem(inv, testItem)

	if firstItemData and testItemData and firstItemData.count >= firstItemCount then
		local weightWithoutFirst = inv.weight - (firstItemData.weight * firstItemCount)
		local weightWithTest = weightWithoutFirst + (testItemData.weight * testItemCount)
		return weightWithTest <= inv.maxWeight
	end
end
exports('CanSwapItem', Inventory.CanSwapItem)

RegisterServerEvent('rnv-inventory:removeItem', function(name, count, metadata, slot)
	Inventory.RemoveItem(source, name, count, metadata, slot)
end)

Inventory.Drops = {}

local function generateInvId(prefix)
	while true do
		local invId = ('%s-%s'):format(prefix or 'drop', math.random(100000, 999999))

		if not Inventories[invId] then return invId end

		Wait(0)
	end
end

local function CustomDrop(prefix, items, coords, slots, maxWeight, instance, model)
	local dropId = generateInvId()
	local inventory = Inventory.Create(dropId, ('%s %s'):format(prefix, dropId:gsub('%D', '')), 'drop', slots or shared.dropslots, 0, maxWeight or shared.dropweight, false, {})

	if not inventory then return end

	inventory.items, inventory.weight = generateItems(inventory, 'drop', items)
	inventory.coords = coords
	Inventory.Drops[dropId] = {
		coords = inventory.coords,
		instance = instance,
		model = model,
	}

	TriggerClientEvent('rnv-inventory:createDrop', -1, dropId, Inventory.Drops[dropId])

    return dropId
end

AddEventHandler('rnv-inventory:customDrop', CustomDrop)
exports('CustomDrop', CustomDrop)

exports('CreateDropFromPlayer', function(playerId)
	local playerInventory = Inventory(playerId)

	if not playerInventory or not next(playerInventory.items) then return end

	local dropId = generateInvId()
	local inventory = Inventory.Create(dropId, ('Drop %s'):format(dropId:gsub('%D', '')), 'drop', playerInventory.slots, playerInventory.weight, playerInventory.maxWeight, false, table.clone(playerInventory.items))

	if not inventory then return end

	local coords = GetEntityCoords(GetPlayerPed(playerId))
	inventory.coords = vec3(coords.x, coords.y, coords.z-0.2)
	Inventory.Drops[dropId] = {
		coords = inventory.coords,
		instance = Player(playerId).state.instance
	}

	Inventory.Clear(playerInventory)
	TriggerClientEvent('rnv-inventory:createDrop', -1, dropId, Inventory.Drops[dropId])

	return dropId
end)

local TriggerEventHooks = require 'server.hooks'


local function dropItem(source, playerInventory, fromData, data)
    if not fromData then return end

	local toData = table.clone(fromData)
	toData.slot = data.toSlot
	toData.count = data.count
	toData.weight = Inventory.SlotWeight(Items(toData.name), toData)

    if toData.weight > shared.dropweight then return end

    local dropId = generateInvId('drop')

	local hooks <close> = TriggerEventHooks('swapItems', {
		source = source,
		fromInventory = playerInventory.id,
		fromSlot = fromData,
		fromType = playerInventory.type,
		toInventory = 'newdrop',
		toSlot = data.toSlot,
		toType = 'drop',
		count = data.count,
        action = 'move',
        dropId = dropId,
	})

	if not hooks.success then return end
	if Inventories[playerInventory.id] ~= playerInventory then hooks.success = false return end

    fromData.count = fromData.count - data.count
    fromData.weight = Inventory.SlotWeight(Items(fromData.name), fromData)

    if fromData.count < 1 then
        fromData = nil
    else
        toData.metadata = table.clone(toData.metadata)
    end

	local slot = data.fromSlot
	playerInventory.weight = playerInventory.weight - toData.weight
	playerInventory.items[slot] = fromData

	if slot == playerInventory.weapon then
		playerInventory.weapon = nil
	end

	local inventory = Inventory.Create(dropId, ('Drop %s'):format(dropId:gsub('%D', '')), 'drop', shared.dropslots, toData.weight, shared.dropweight, false, {[data.toSlot] = toData})

	if not inventory then hooks.success = false return end

	inventory.coords = data.coords
	Inventory.Drops[dropId] = {coords = inventory.coords, instance = data.instance}
	playerInventory.changed = true

	TriggerClientEvent('rnv-inventory:createDrop', -1, dropId, Inventory.Drops[dropId], playerInventory.open and source, slot)

	if server.loglevel > 0 then
		lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s"'):format(data.count, toData.name, playerInventory.label, dropId))
	end

	if server.syncInventory then server.syncInventory(playerInventory) end

	return true, {
		weight = playerInventory.weight,
		items = {
			{
				item = fromData or { slot = data.fromSlot },
				inventory = playerInventory.id
			}
		}
	}
end

local GetLocks = require 'shared.locks'

lib.callback.register('rnv-inventory:swapItems', function(source, data)
	if data.fromType ~= data.toType and data.toType ~= 'player' and data.fromType ~= 'player' then
        Utils.LogExploit(source, 'swapItems', 'Triggered event with invalid data', true)
        return
    end

	data.count = math.max(1, math.floor(data.count or 1))

	local playerInventory = Inventory(source)

	if not playerInventory or not playerInventory.open then return end

	local toInventory = (data.toType == 'player' and playerInventory) or Inventory(playerInventory.open)
	local fromInventory = (data.fromType == 'player' and playerInventory) or Inventory(playerInventory.open)

	if not fromInventory or not toInventory then
		playerInventory:closeInventory()
		return
	end

    if data.toType == 'inspect' or data.fromType == 'inspect' then return end

    local activeSlots <close> = GetLocks({
       	('inventory-%s:slot-%s'):format(fromInventory.id, data.fromSlot),
        ('inventory-%s:slot-%s'):format(toInventory.id, data.toSlot)
    })

	if not activeSlots then
		return false, {
			{
				item = toInventory.items[data.toSlot] or { slot = data.toSlot },
				inventory = toInventory.id
			},
			{
				item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
				inventory = fromInventory.id
			}
		}
	end

	local sameInventory = fromInventory.id == toInventory.id
	local fromOtherPlayer = fromInventory.player and fromInventory ~= playerInventory
	local toOtherPlayer = toInventory.player and toInventory ~= playerInventory
	local toData = toInventory.items[data.toSlot]

	local function partiesPresent()
		return Inventories[playerInventory.id] == playerInventory
			and Inventories[fromInventory.id] == fromInventory
			and Inventories[toInventory.id] == toInventory
	end

	if not sameInventory and (fromInventory.type == 'policeevidence' or (toInventory.type == 'policeevidence' and toData)) then
		local group, rank = server.hasGroup(playerInventory, shared.police)

		if not group or server.evidencegrade > rank then
			return false, 'evidence_cannot_take'
		end
	end

	if toInventory and (data.toType == 'newdrop' or fromInventory ~= toInventory or data.fromSlot ~= data.toSlot) then
		local fromData = fromInventory.items[data.fromSlot]

		if not fromData then
			return false, {
				{
					item = { slot = data.fromSlot },
					inventory = fromInventory.id
				},
				{
					item = toData or { slot = data.toSlot },
					inventory = toInventory.id
				}
			}
		end

        if data.count > fromData.count then
            data.count = fromData.count
        end

        if data.toType == 'newdrop' then
            return dropItem(source, fromInventory, fromData, data)
        end

		-- RUN V cash: a stack never goes over Extras.MoneyStack; only what fits moves, the rest stays
		if toData and fromData.name == 'money' and toData.name == 'money' and Extras.MoneyStack then
			local room = Extras.MoneyStack - toData.count
			if room <= 0 then return false end
			if data.count > room then data.count = room end
		end

		-- RUN V grid: the moved item (and a swapped one) must fit where it lands
		local stacking = toData and toData.name == fromData.name and toData.stack and table.matches(toData.metadata, fromData.metadata)
		if not stacking then
			local fw, fh = itemSize(fromData.name)
			local wholeStack = data.count >= fromData.count
			local refused = {
				{ item = fromData, inventory = fromInventory.id },
				{ item = toData or { slot = data.toSlot }, inventory = toInventory.id },
			}

			-- Bag / pouch changes resize the player's grid or pouch: everything left must still fit
			for _, inv in ipairs({ fromInventory, toInventory }) do
				if inv.type == 'player' then
					local newBag, newPouch = inv.items[SLOT_BAG], inv.items[SLOT_POUCH]
					local skip = {}
					if inv == fromInventory and wholeStack then
						skip[data.fromSlot] = true
						if data.fromSlot == SLOT_BAG then newBag = sameInventory and toData or nil end
						if data.fromSlot == SLOT_POUCH then newPouch = sameInventory and toData or nil end
					end
					if inv == toInventory then
						skip[data.toSlot] = true
						if data.toSlot == SLOT_BAG then newBag = fromData end
						if data.toSlot == SLOT_POUCH then newPouch = fromData end
					end
					local bag, pouch = newBag and bagInfo(newBag.name), newPouch and bagInfo(newPouch.name)
					inv.rowsOverride = bag and bag.rows or Extras.Bag.baseRows
					inv.cellsOverride = pouch and pouch.cells or 0
					if not layoutStillFits(inv, inv.rowsOverride, inv.cellsOverride, skip) then
						fromInventory.rowsOverride, fromInventory.cellsOverride = nil, nil
						toInventory.rowsOverride, toInventory.cellsOverride = nil, nil
						return false, refused
					end
				end
			end

			local ignoreTo = { [data.toSlot] = true }
			if sameInventory and wholeStack then ignoreTo[data.fromSlot] = true end
			local ok = fits(toInventory, data.toSlot, fw, fh, ignoreTo, nil, fromData.name)

			if ok and toData then
				local tw, th = itemSize(toData.name)
				local ignoreFrom = { [data.fromSlot] = true }
				if sameInventory then ignoreFrom[data.toSlot] = true end
				local extra = (sameInventory and data.toSlot <= gridLimit(toInventory)) and { { data.toSlot, fw, fh } } or nil
				ok = wholeStack and fits(fromInventory, data.fromSlot, tw, th, ignoreFrom, extra, toData.name)
			end

			fromInventory.rowsOverride, fromInventory.cellsOverride = nil, nil
			toInventory.rowsOverride, toInventory.cellsOverride = nil, nil

			if not ok then
				return false, {
					{ item = fromData, inventory = fromInventory.id },
					{ item = toData or { slot = data.toSlot }, inventory = toInventory.id },
				}
			end
		end

		if fromData then
            if fromData.metadata.container and toInventory.type == 'container' then return false end
            if toData and toData.metadata.container and fromInventory.type == 'container' then return false end

			local container, containerItem = (not sameInventory and playerInventory.containerSlot) and (fromInventory.type == 'container' and fromInventory or toInventory)

			if container then
				containerItem = playerInventory.items[playerInventory.containerSlot]
			end

			local hookPayload = {
				source = source,
				fromInventory = fromInventory.id,
				fromSlot = fromData,
				fromType = fromInventory.type,
				toInventory = toInventory.id,
				toSlot = toData or data.toSlot,
				toType = toInventory.type,
				count = data.count,
			}

			if toData and ((toData.name ~= fromData.name) or not toData.stack or (not table.matches(toData.metadata, fromData.metadata))) then
				-- Swap items
				local toWeight = not sameInventory and (toInventory.weight - toData.weight + fromData.weight) or 0
				local fromWeight = not sameInventory and (fromInventory.weight + toData.weight - fromData.weight) or 0
				hookPayload.action = 'swap'

				if not sameInventory then
					if (toWeight <= toInventory.maxWeight and fromWeight <= fromInventory.maxWeight) then
						local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

						if not hooks.success then return end
						if not partiesPresent() then hooks.success = false return end

						if containerItem then
							local toContainer = toInventory.type == 'container'
							local whitelist = (Items.containers[containerItem.name] and Items.containers[containerItem.name].whitelist)
							local blacklist = (Items.containers[containerItem.name] and Items.containers[containerItem.name].blacklist)
							local checkItem = toContainer and fromData.name or toData.name

							if (whitelist and not whitelist[checkItem]) or (blacklist and blacklist[checkItem]) then
								hooks.success = false
								return
							end

							Inventory.ContainerWeight(containerItem, toContainer and toWeight or fromWeight, playerInventory)
						end

						if fromOtherPlayer then
							TriggerClientEvent('rnv-inventory:itemNotify', fromInventory.id, { fromData, 'ui_removed', fromData.count })
							TriggerClientEvent('rnv-inventory:itemNotify', fromInventory.id, { toData, 'ui_added', toData.count })
						elseif toOtherPlayer then
							TriggerClientEvent('rnv-inventory:itemNotify', toInventory.id, { fromData, 'ui_added', fromData.count })
							TriggerClientEvent('rnv-inventory:itemNotify', toInventory.id, { toData, 'ui_removed', toData.count })
						end

						fromInventory.weight = fromWeight
						toInventory.weight = toWeight
						toData, fromData = Inventory.SwapSlots(fromInventory, toInventory, data.fromSlot, data.toSlot)

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s" for %sx %s'):format(fromData.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id, toData.count, toData.name))
						end
					else return false, 'cannot_carry' end
				else
					local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

					if not hooks.success then return end
					if not partiesPresent() then hooks.success = false return end

					toData, fromData = Inventory.SwapSlots(fromInventory, toInventory, data.fromSlot, data.toSlot)
				end

			elseif toData and toData.name == fromData.name and table.matches(toData.metadata, fromData.metadata) then
				local originalFromCount, originalToCount = fromData.count, toData.count
				local fromCount, toCount = originalFromCount - data.count, originalToCount + data.count
				local originalFromWeight = fromData.weight

				fromData.count, toData.count = fromCount, toCount
				local fromSlotWeight = Inventory.SlotWeight(Items(fromData.name), fromData)
				local toSlotWeight = Inventory.SlotWeight(Items(toData.name), toData)
				fromData.count, toData.count = originalFromCount, originalToCount

				local totalWeight = toInventory.weight - toData.weight + toSlotWeight

				if fromInventory.type == 'container' or sameInventory or totalWeight <= toInventory.maxWeight then
					hookPayload.action = 'stack'

					local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

					if not hooks.success then return end
					if not partiesPresent() then hooks.success = false return end

					fromData.count, toData.count = fromCount, toCount
					toData.weight = toSlotWeight

					if not sameInventory then
						fromInventory.weight = fromInventory.weight - originalFromWeight + fromSlotWeight
						toInventory.weight = totalWeight

						if container then
							Inventory.ContainerWeight(containerItem, toInventory.type == 'container' and toInventory.weight or fromInventory.weight, playerInventory)
						end

						if fromOtherPlayer then
							TriggerClientEvent('rnv-inventory:itemNotify', fromInventory.id, { fromData, 'ui_removed', data.count })
						elseif toOtherPlayer then
							TriggerClientEvent('rnv-inventory:itemNotify', toInventory.id, { toData, 'ui_added', data.count })
						end

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s"'):format(data.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id))
						end
					end

					fromData.weight = fromSlotWeight
				else
					return false, 'cannot_carry'
				end
			elseif data.count <= fromData.count then
				-- Move item to an empty slot
				toData = table.clone(fromData)
				toData.count = data.count
				toData.slot = data.toSlot
				toData.weight = Inventory.SlotWeight(Items(toData.name), toData)

				if fromInventory.type == 'container' or sameInventory or (toInventory.weight + toData.weight <= toInventory.maxWeight) then
					hookPayload.action = 'move'

					local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

					if not hooks.success then return end
					if not partiesPresent() then hooks.success = false return end

					if not sameInventory then
						local toContainer = toInventory.type == 'container'

						if container then
							if toContainer and containerItem then
								local whitelist = (Items.containers[containerItem.name] and Items.containers[containerItem.name].whitelist)
								local blacklist = (Items.containers[containerItem.name] and Items.containers[containerItem.name].blacklist)

								if (whitelist and not whitelist[fromData.name]) or (blacklist and blacklist[fromData.name]) then
									hooks.success = false
									return
								end
							end
						end

						fromInventory.weight = fromInventory.weight - toData.weight
						toInventory.weight = toInventory.weight + toData.weight

						if container then
							Inventory.ContainerWeight(containerItem, toContainer and toInventory.weight or fromInventory.weight, playerInventory)
						end

						if fromOtherPlayer then
							TriggerClientEvent('rnv-inventory:itemNotify', fromInventory.id, { fromData, 'ui_removed', data.count })
						elseif toOtherPlayer then
							TriggerClientEvent('rnv-inventory:itemNotify', toInventory.id, { fromData, 'ui_added', data.count })
						end

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s"'):format(data.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id))
						end
					end

					fromData.count = fromData.count - data.count
					fromData.weight = Inventory.SlotWeight(Items(fromData.name), fromData)

					if fromData.count > 0 then
						toData.metadata = table.clone(toData.metadata)
					end
				else return false, 'cannot_carry_other' end
			end

			if fromData and fromData.count < 1 then fromData = nil end

			local items = {}

			if fromInventory.player and not fromOtherPlayer then
				if toInventory.type == 'container' and containerItem then
					items[#items + 1] = {
						item = containerItem,
						inventory = playerInventory.id
					}
				end
			end

			if toInventory.player and not toOtherPlayer then
				if fromInventory.type == 'container' and containerItem then
					items[#items + 1] = {
						item = containerItem,
						inventory = playerInventory.id
					}
				end
			end

			fromInventory.items[data.fromSlot] = fromData
			toInventory.items[data.toSlot] = toData

			if fromInventory.changed ~= nil then fromInventory.changed = true end
			if toInventory.changed ~= nil then toInventory.changed = true end

            CreateThread(function()
                if sameInventory then
                    fromInventory:syncSlotsWithClients({
                        {
                            item = fromInventory.items[data.toSlot] or { slot = data.toSlot },
                            inventory = fromInventory.id
                        },
                        {
                            item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
                            inventory = fromInventory.id
                        }
                    }, true)
                else
                    toInventory:syncSlotsWithClients({
                        {
                            item = toInventory.items[data.toSlot] or { slot = data.toSlot },
                            inventory = toInventory.id
                        }
                    }, true)

                    fromInventory:syncSlotsWithClients({
                        {
                            item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
                            inventory = fromInventory.id
                        }
                    }, true)
                end
            end)

			if server.syncInventory then
				if fromInventory.player then
					server.syncInventory(fromInventory)
				end

				if toInventory.player and not sameInventory then
					server.syncInventory(toInventory)
				end
			end

			local weaponSlot

			if toInventory.weapon == data.toSlot then
				if not sameInventory then
					toInventory.weapon = nil
					TriggerClientEvent('rnv-inventory:disarm', toInventory.id)
				else
					weaponSlot = data.fromSlot
					toInventory.weapon = weaponSlot
				end
			end

			if fromInventory.weapon == data.fromSlot then
				if not sameInventory then
					fromInventory.weapon = nil
					TriggerClientEvent('rnv-inventory:disarm', fromInventory.id)
				elseif not weaponSlot then
					weaponSlot = data.toSlot
					fromInventory.weapon = weaponSlot
				end
			end

			return containerItem and containerItem.weight or true, nil, weaponSlot
		end
	end
end)

function Inventory.Confiscate(source)
	local inv = Inventory(source)

	if not inv or not inv.player then return end

	db.saveStash(inv.owner, inv.owner, json.encode(minimal(inv)))
	table.wipe(inv.items)
	inv.weight = 0
	inv.changed = true

	TriggerClientEvent('rnv-inventory:inventoryConfiscated', inv.id)

	if server.syncInventory then server.syncInventory(inv) end
end
exports('ConfiscateInventory', Inventory.Confiscate)

function Inventory.Return(source)
	local inv = Inventory(source)

	if not inv or not inv.player then return end

	local items = MySQL.scalar.await('SELECT data FROM rnv-inventory WHERE name = ?', { inv.owner })

    if not items then return end

	MySQL.update.await('DELETE FROM rnv-inventory WHERE name = ?', { inv.owner })

    items = json.decode(items)
    local inventory, totalWeight = {}, 0

    if table.type(items) == 'array' then
        for i = 1, #items do
            local data = items[i]
            if type(data) == 'number' then break end

            local item = Items(data.name)

            if item then
                local weight = Inventory.SlotWeight(item, data)
                totalWeight = totalWeight + weight
                inventory[data.slot] = {name = data.name, label = item.label, weight = weight, slot = data.slot, count = data.count, description = item.description, metadata = data.metadata, stack = item.stack, close = item.close}
            end
        end
    end

    inv.changed = true
    inv.weight = totalWeight
    inv.items = inventory

    TriggerClientEvent('rnv-inventory:inventoryReturned', source, { inventory, totalWeight })

    if server.syncInventory then server.syncInventory(inv) end
end

exports('ReturnInventory', Inventory.Return)

function Inventory.Clear(inv, keep)
	inv = Inventory(inv)

	if not inv or not next(inv.items) then return end

	local updateSlots = {}
	local newWeight = 0
	local inc = 0

	if keep then
		local keptItems = {}
		local keepType = type(keep)

		if keepType == 'string' then
			for slot, v in pairs(inv.items) do
				if v.name == keep then
					keptItems[v.slot] = v
					newWeight = newWeight + v.weight
				elseif updateSlots then
					inc = inc + 1
					updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
				end
			end
		elseif keepType == 'table' and table.type(keep) == 'array' then
			for slot, v in pairs(inv.items) do
				for i = 1, #keep do
					if v.name == keep[i] then
						keptItems[v.slot] = v
						newWeight = newWeight + v.weight
						goto foundItem
					end
				end

				if updateSlots then
					inc = inc + 1
					updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
				end

				::foundItem::
			end
		end

		table.wipe(inv.items)
		inv.items = keptItems
	else
		if updateSlots then
			for slot in pairs(inv.items) do
				inc = inc + 1
				updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
			end
		end

		table.wipe(inv.items)
	end

	inv.weight = newWeight
	inv.changed = true

	inv:syncSlotsWithClients(updateSlots, true)

	if not inv.player then
		if inv.open then
			local playerInv = Inventory(inv.open)

			if not playerInv then return end

			playerInv:closeInventory()
		end

		inv:openInventory()

		return
	end

	if server.syncInventory then server.syncInventory(inv) end

	inv.weapon = nil
end

exports('ClearInventory', Inventory.Clear)

function Inventory.GetEmptySlot(inv)
	local inventory = Inventory(inv)

	if not inventory then return end

	for i = 1, gridLimit(inventory) do
		if fits(inventory, i, 1, 1) then
			return i
		end
	end
end

exports('GetEmptySlot', Inventory.GetEmptySlot)

function Inventory.GetSlotForItem(inv, itemName, metadata)
	local inventory = Inventory(inv)
	local item = Items(itemName)

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local items = inventory.items

	if item.stack then
		for i = 1, gridLimit(inventory) do
			local slotData = items[i]
			if slotData and slotData.name == item.name and table.matches(slotData.metadata, metadata) then
				return i
			end
		end
	end

	return findFit(inventory, item.name)
end

exports('GetSlotForItem', Inventory.GetSlotForItem)

function Inventory.GetSlotWithItem(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName)

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
            if not Items.UpdateDurability(inventory, slotData, item, nil, os.time()) then
                return slotData
            end
		end
	end
end

exports('GetSlotWithItem', Inventory.GetSlotWithItem)

function Inventory.GetSlotIdWithItem(inv, itemName, metadata, strict)
	return (Inventory.GetSlotWithItem(inv, itemName, metadata, strict) and Inventory.GetSlotWithItem(inv, itemName, metadata, strict).slot)
end

exports('GetSlotIdWithItem', Inventory.GetSlotIdWithItem)

function Inventory.GetSlotsWithItem(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName)

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local response = {}
	local n = 0
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
            if not Items.UpdateDurability(inventory, slotData, item, nil, os.time()) then
                n = n + 1
                response[n] = slotData
            end
		end
	end

	return response
end

exports('GetSlotsWithItem', Inventory.GetSlotsWithItem)

function Inventory.GetSlotIdsWithItem(inv, itemName, metadata, strict)
	local items = Inventory.GetSlotsWithItem(inv, itemName, metadata, strict)

	if items then
		for i = 1, #items do
			items[i] = items[i].slot
		end

		return items
	end
end

exports('GetSlotIdsWithItem', Inventory.GetSlotIdsWithItem)

function Inventory.GetItemCount(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName)

	if not inventory or not item then return 0 end

	metadata = assertMetadata(metadata)
	local count = 0
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
			count = count + slotData.count
		end
	end

	return count
end

exports('GetItemCount', Inventory.GetItemCount)


local function prepareInventorySave(inv, buffer, time)
    local shouldSave = not inv.datastore and inv.changed
    local n = 0

    for k, v in pairs(inv.items) do
        if not Items.UpdateDurability(inv, v, Items(v.name), nil, time) and shouldSave then
            n = n + 1
            buffer[n] = {
                name = v.name,
                count = v.count,
                slot = k,
                metadata = next(v.metadata) and v.metadata or nil
            }
        end
	end

    if not shouldSave then return end

    local data = next(buffer) and json.encode(buffer) or nil
    inv.changed = false
    table.wipe(buffer)

    if inv.player then
        return 1, { data, inv.owner }
    end

    if inv.type == 'trunk' then
        return 2, { data, inv.dbId }
    end

    if inv.type == 'glovebox' then
        return 3, { data, inv.dbId }
    end

    return 4, { data, inv.owner and tostring(inv.owner) or '', inv.dbId }
end

local isSaving = false
local inventoryClearTime = GetConvarInt('inventory:cleartime', 5) * 60

local function saveInventories(clearInventories)
	if isSaving then return end

	local time = os.time()
	local parameters = { {}, {}, {}, {} }
	local total = { 0, 0, 0, 0, 0 }
    local buffer = {}

	for _, inv in pairs(Inventories) do
        local index, data = prepareInventorySave(inv, buffer, time)

        if index and data then
            total[5] = total[5] + 1

            if index == 4 and server.bulkstashsave then
                for i = 1, 3 do
					total[index] = total[index] + 1
                    parameters[index][total[index]] = data[i]
                end
            else
				total[index] = total[index] + 1
                parameters[index][total[index]] = data
            end
        end
	end

    if total[5] > 0 then
        isSaving = true
        local ok, err = pcall(db.saveInventories, parameters[1], parameters[2], parameters[3], parameters[4], total)
        isSaving = false

        if not ok and err then return lib.print.error(err) end
    end

    if not clearInventories then return end

    for _, inv in pairs(Inventories) do
        if not inv.open and not inv.player then
            -- clear inventory from memory if unused for x minutes, or on entity/netid mismatch
            if inv.type == 'glovebox' or inv.type == 'trunk' then
                if NetworkGetEntityFromNetworkId(inv.netid) ~= inv.entityId then
                    Inventory.Remove(inv)
                end
            elseif time - inv.time >= inventoryClearTime then
                Inventory.Remove(inv)
            end
        end
    end
end

lib.cron.new('*/5 * * * *', function()
    saveInventories(true)
end)

function Inventory.SaveInventories(lock, clearInventories)
	Inventory.Lock = lock or nil

	Inventory.CloseAll()
    saveInventories(clearInventories)
end

AddEventHandler('playerDropped', function()
	server.playerDropped(source)

	if GetNumPlayerIndices() == 0 then
		Inventory.SaveInventories(false, true)
	end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
	Inventory.SaveInventories(true, false)
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining ~= 60 then return end

	Inventory.SaveInventories(true, true)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == shared.resource then
		Inventory.SaveInventories(true, false)
	end
end)

RegisterServerEvent('rnv-inventory:closeInventory', function()
	local inventory = Inventories[source]

	if (inventory and inventory.open) then
		local secondary = Inventories[inventory.open]

		if secondary then
			secondary:closeInventory()
		end

		inventory:closeInventory(true)
	end
end)

local function giveItem(playerId, slot, target, count)
	local fromInventory = Inventory(playerId)
	local toInventory = Inventory(target)

	if not fromInventory or not toInventory then return end

	count = math.max(1, math.floor(count or 1))

	if toInventory.player then
		local data = fromInventory.items[slot]

		if not data then return end

        local targetState = Player(target).state

        if targetState.invBusy then
            return { 'cannot_give', count, data.label }
        end

		local item = Items(data.name)

		if not item or data.count < count or not Inventory.CanCarryItem(toInventory, item, count, data.metadata) or #(GetEntityCoords(fromInventory.player.ped) - GetEntityCoords(toInventory.player.ped)) > 15 then
			return { 'cannot_give', count, data.label }
		end

		local toSlot = Inventory.GetSlotForItem(toInventory, data.name, data.metadata)

		if not toSlot then return { 'cannot_give', count, data.label } end

        local activeSlots <close> = GetLocks({
            ('inventory-%s:slot-%s'):format(fromInventory.id, slot),
            ('inventory-%s:slot-%s'):format(toInventory.id, toSlot)
        })

		if not activeSlots then
			return { 'cannot_give', count, data.label }
		end

		local hooks <close> = TriggerEventHooks('swapItems', {
			source = fromInventory.id,
			fromInventory = fromInventory.id,
			fromType = fromInventory.type,
			toInventory = toInventory.id,
			toType = toInventory.type,
			count = count,
			action = 'give',
			fromSlot = data,
		})

		if hooks.success then
			if Inventory.AddItem(toInventory, item, count, data.metadata, toSlot) then
				if Inventory.RemoveItem(fromInventory, item, count, data.metadata, slot) then
					if server.loglevel > 0 then
						lib.logger(fromInventory.owner, 'giveItem', ('"%s" gave %sx %s to "%s"'):format(fromInventory.label, count, data.name, toInventory.label))
					end

					return
				else
					hooks.success = false

					Inventory.RemoveItem(toInventory, item, count, data.metadata, toSlot)
				end
			end
		end

		return { 'cannot_give', count, data.label }
	end
end

lib.callback.register('rnv-inventory:giveItem', giveItem)
RegisterServerEvent('rnv-inventory:giveItem', function(...) giveItem(source, ...) end)

local function updateWeapon(source, action, value, slot, specialAmmo)
	local inventory = Inventory(source)

	if not inventory then return end

	if not action then
		inventory.weapon = nil
		return
	end

	local vtype = type(value)

	if vtype == 'table' and action == 'component' then
		local item = inventory.items[value.slot]

		if item then
			if item.metadata.components then
				for k, v in pairs(item.metadata.components) do
					if v == value.component then
						if not Inventory.AddItem(inventory, value.component, 1) then return end

						table.remove(item.metadata.components, k)
						inventory:syncSlotsWithPlayer({
							{ item = item }
						}, inventory.weight)

			            if server.syncInventory then server.syncInventory(inventory) end

						return true
					end
				end
			end
		end
	else
		if not slot then slot = inventory.weapon end

		local weapon = inventory.items[slot]

		if weapon and weapon.metadata then
			local item = Items(weapon.name)

			if not item.weapon then
				inventory.weapon = nil
				return
			end

			if vtype == 'number' and value < 0 then
				value = 0
			end

			if action == 'load' and weapon.metadata.durability > 0 then
				local ammo = Items(weapon.name).ammoname
				local diff = value - (weapon.metadata.ammo or 0)

				if not Inventory.RemoveItem(inventory, ammo, diff, specialAmmo) then return end

				weapon.metadata.ammo = value
				weapon.metadata.specialAmmo = specialAmmo
				weapon.weight = Inventory.SlotWeight(item, weapon)
			elseif action == 'throw' then
				if not Inventory.RemoveItem(inventory, weapon.name, 1, weapon.metadata, weapon.slot) then return end
			elseif action == 'component' then
				if vtype == 'number' then
					if not Inventory.AddItem(inventory, weapon.metadata.components[value], 1) then return false end

					table.remove(weapon.metadata.components, value)
					weapon.weight = Inventory.SlotWeight(item, weapon)
				elseif vtype == 'string' then
					local component = inventory.items[tonumber(value)]

					if not Inventory.RemoveItem(inventory, component.name, 1) then return false end

					table.insert(weapon.metadata.components, component.name)
					weapon.weight = Inventory.SlotWeight(item, weapon)
				end
			elseif action == 'ammo' then
				if item.hash == joaat('WEAPON_FIREEXTINGUISHER') or item.hash == joaat('WEAPON_PETROLCAN') or item.hash == joaat('WEAPON_HAZARDCAN') or item.hash == joaat('WEAPON_FERTILIZERCAN') then
                    local safeValue = math.max(0, math.min(100, math.floor(value)))
                    weapon.metadata.durability = safeValue
                    weapon.metadata.ammo = safeValue
				elseif value < weapon.metadata.ammo then
					local durability = Items(weapon.name).durability * math.abs((weapon.metadata.ammo or 0.1) - value)
					weapon.metadata.ammo = value
					weapon.metadata.durability = weapon.metadata.durability - durability
					weapon.weight = Inventory.SlotWeight(item, weapon)
				end
			elseif action == 'melee' then
				weapon.metadata.durability = weapon.metadata.durability - ((Items(weapon.name).durability or 1) * value)
			end

            if (weapon.metadata.durability or 0) < 0 then
                weapon.metadata.durability = 0
            end

            if item.hash == joaat('WEAPON_PETROLCAN') then
                weapon.weight = Inventory.SlotWeight(item, weapon)
            end

			if action ~= 'throw' then
				inventory:syncSlotsWithPlayer({
					{ item = weapon }
				}, inventory.weight)
			end

			if server.syncInventory then server.syncInventory(inventory) end

			return true
		end
	end
end

lib.callback.register('rnv-inventory:updateWeapon', updateWeapon)

RegisterNetEvent('rnv-inventory:updateWeapon', function(action, value, slot, specialAmmo)
	updateWeapon(source, action, value, slot, specialAmmo)
end)

lib.callback.register('rnv-inventory:removeAmmoFromWeapon', function(source, slot)
	local inventory = Inventory(source)

	if not inventory or inventory.usingItem then return end

	local slotData = inventory.items[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo < 1 then return end

	local item = Items(slotData.name)

	if not item or not item.ammoname then return end
	local specialAmmo = slotData.metadata.specialAmmo and { type = slotData.metadata.specialAmmo } or nil


	if Inventory.AddItem(inventory, item.ammoname, slotData.metadata.ammo, specialAmmo) then
		slotData.metadata.ammo = 0
		slotData.weight = Inventory.SlotWeight(item, slotData)

		inventory:syncSlotsWithPlayer({
			{ item = slotData }
		}, inventory.weight)

		if server.syncInventory then server.syncInventory(inventory) end

		return true
	end
end)

local function checkStashProperties(properties)
	local name = properties.name
	local slots = properties.slots
	local maxWeight = properties.maxWeight
	local coords = properties.coords

	if type(name) ~= 'string' then
		error(('received %s for stash name (expected string)'):format(type(name)))
	end

	if type(slots) ~= 'number' then
		error(('received %s for stash slots (expected number)'):format(type(slots)))
	end

	if type(maxWeight) ~= 'number' then
		error(('received %s for stash maxWeight (expected number)'):format(type(maxWeight)))
	end

	if coords then
		local typeof = type(coords)

		if typeof ~= 'vector3' then
			if typeof == 'table' and table.type(coords) ~= 'array' then
				coords = vec3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
			else
				if table.type(coords) == 'array' then
					for i = 1, #coords do
						coords[i] = vec3(coords[i].x, coords[i].y, coords[i].z)
					end
				else
					error(('received %s for stash coords (expected vector3 or array of vector3)'):format(typeof))
				end
			end
		end
	end

	return name, slots, maxWeight, coords
end

local function registerStash(name, label, slots, maxWeight, owner, groups, coords, instance)
	name, slots, maxWeight, coords = checkStashProperties({
		name = name,
		slots = slots,
		maxWeight = maxWeight,
		coords = coords,
	})

	local curStash = RegisteredStashes[name]

	if curStash then
		for _, stash in pairs(Inventories) do
			if stash.type == 'stash' and stash.dbId == name then
				stash.label = label or stash.label
				stash.owner = (owner and owner ~= true) and stash.owner or owner
				stash.slots = slots or stash.slots
				stash.maxWeight = maxWeight or stash.maxWeight
				stash.groups = groups or stash.groups
				stash.coords = coords or stash.coords
				stash.instance = instance or stash.instance
			end
		end
	end

	RegisteredStashes[name] = {
		name = name,
		label = label,
		owner = owner,
		slots = slots,
		maxWeight = maxWeight,
		groups = groups,
		coords = coords,
		instance = instance
	}
end

exports('RegisterStash', registerStash)

function Inventory.CreateTemporaryStash(properties)
	properties.name = generateInvId('temp')

	local name, slots, maxWeight, coords = checkStashProperties(properties)
	local inventory = Inventory.Create(name, properties.label, 'temp', slots, 0, maxWeight, properties.owner, {}, properties.groups)

	if not inventory then return end

	inventory.items, inventory.weight = generateItems(inventory, 'drop', properties.items)
	inventory.coords = coords
	inventory.instance = properties.instance

	return inventory.id
end

exports('CreateTemporaryStash', Inventory.CreateTemporaryStash)

function Inventory.InspectInventory(playerId, invId)
	local inventory = invId ~= playerId and Inventory(invId)
	local playerInventory = Inventory(playerId)

	if playerInventory and inventory then
		playerInventory:openInventory(inventory)
		TriggerClientEvent('rnv-inventory:viewInventory', playerId, playerInventory, inventory)
	end
end

exports('InspectInventory', Inventory.InspectInventory)

return Inventory
