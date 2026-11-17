-- Categories and tiers: the two lists are turned into item -> category / item -> tier number for the page
local function buildCatalog()
    local category, tier = {}, {}
    for name, items in pairs(require 'extras.category') do
        for _, item in ipairs(items) do category[item] = name end
    end
    for level, name in ipairs({ 'rare', 'epic', 'legendary', 'mythic' }) do
        for _, item in ipairs((require 'extras.tier')[name] or {}) do tier[item] = level end
    end
    for _, item in ipairs((require 'extras.tier').common or {}) do tier[item] = -1
    end
    local bags = {}
    for name, bag in pairs(Extras.Bag.enabled and Extras.Bag.items or {}) do bags[name] = { kind = bag.kind, rows = bag.rows, cells = bag.cells } end
    return { category = category, tier = tier, bags = bags, baseRows = Extras.Bag.baseRows, vests = Extras.Vests }
end

lib.callback.register('rnv-inventory:extras:catalog', function()
    local ok, result = pcall(buildCatalog)
    if not ok then return { error = tostring(result) } end
    return result
end)

-- Extra items: extras/items.lua is added to rnv-inventory's own item list, prepared the way data/items.lua entries are ---
local extraItems = require 'extras.items'
do
    local list = require 'shared.items'
    for name, source in pairs(extraItems) do
        local data = table.deepclone(source)
        data.name = name
        data.weight = data.weight or 0
        if data.close == nil then data.close = true end
        if data.stack == nil then data.stack = true end
        data.client = nil
        list[name] = data
    end
end

lib.callback.register('rnv-inventory:extras:items', function()
    local items = {}
    for name, source in pairs(extraItems) do
        local data = table.deepclone(source)
        data.weight = data.weight or 0
        if data.close == nil then data.close = true end
        if data.stack == nil then data.stack = true end
        items[name] = data
    end
    return items
end)



-- Destroy: the page asks after the player dropped an own item outside the inventory and confirmed it (no ground drops)
lib.callback.register('rnv-inventory:extras:destroy', function(source, slot)
    local item = exports['rnv-inventory']:GetSlot(source, tonumber(slot) or 0)
    if not item then return false end
    return exports['rnv-inventory']:RemoveItem(source, item.name, item.count, nil, item.slot) == true
end)

-- The armour left in the worn vest (slot 57) is kept on the vest, so it survives taking it off
RegisterNetEvent('rnv-inventory:extras:vestArmour', function(armour)
    local src = source
    local vest = exports['rnv-inventory']:GetSlot(src, 57)
    armour = math.floor(tonumber(armour) or 0)
    if not vest or not Extras.Vests[vest.name] then return end
    armour = math.max(0, math.min(armour, Extras.Vests[vest.name] * 25))
    local meta = vest.metadata or {}
    if meta.armour == armour then return end
    meta.armour = armour
    exports['rnv-inventory']:SetMetadata(src, 57, meta)
end)
