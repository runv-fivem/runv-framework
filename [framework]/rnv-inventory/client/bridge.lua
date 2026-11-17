if not lib then return end

function client.setPlayerData(key, value)
	PlayerData[key] = value
	OnPlayerData(key, value)
end

function client.hasGroup(group)
	if not PlayerData.loaded then return end

	if type(group) == 'table' then
		for name, requiredRank in pairs(group) do
			local groupRank = PlayerData.groups[name]
			if groupRank then
				if type(requiredRank) == 'table' then
					if lib.table.contains(requiredRank, groupRank) then
						return name, groupRank
					end
				else
					if groupRank >= (requiredRank or 0) then
						return name, groupRank
					end
				end
			end
		end
	else
		local groupRank = PlayerData.groups[group]
		if groupRank then
			return group, groupRank
		end
	end
end

local Utils = require 'client.utils'
local Weapon = require 'client.weapon'
local Items = require 'client.items'

function client.onLogout()
	if not PlayerData.loaded then return end

	if client.parachute then
		Utils.DeleteEntity(client.parachute[1])
		client.parachute = false
	end

	for _, point in pairs(client.drops) do
		if point.entity then
			Utils.DeleteEntity(point.entity)
		end

		point:remove()
	end

    for _, v in pairs(Items) do
        v.count = 0
    end

	PlayerData.loaded = false
	client.drops = nil

	client.closeInventory()

    if client.interval then
        ClearInterval(client.interval)
        ClearInterval(client.tick)
    end

	Weapon.Disarm()
end

local success, result = pcall(lib.load, ('client.bridge_%s'):format(shared.framework))

if not success then
    lib.print.error(result)
    lib = nil
    return
end