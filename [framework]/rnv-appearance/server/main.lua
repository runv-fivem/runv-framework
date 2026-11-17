-- Skin storage (playerskins table)

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `playerskins` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `citizenid` varchar(255) NOT NULL,
          `model` varchar(255) NOT NULL,
          `skin` text NOT NULL,
          `active` tinyint(4) NOT NULL DEFAULT 1,
          PRIMARY KEY (`id`),
          KEY `citizenid` (`citizenid`),
          KEY `active` (`active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function getSkin(citizenid)
    local skin = MySQL.scalar.await('SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1', { citizenid })
    return skin and json.decode(skin)
end

local function saveSkin(citizenid, appearance)
    local skin = json.encode(appearance)
    local updated = MySQL.update.await('UPDATE playerskins SET model = ?, skin = ? WHERE citizenid = ? AND active = 1',
        { appearance.model, skin, citizenid })
    if updated == 0 then
        MySQL.insert.await('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, 1)',
            { citizenid, appearance.model, skin })
    end
end

local function citizenidOf(src)
    local player = exports['rnv-core']:GetPlayer(src)
    return player and player.citizenid
end

lib.callback.register('rnv-appearance:getSkin', function(src)
    local citizenid = citizenidOf(src)
    return citizenid and getSkin(citizenid)
end)

lib.callback.register('rnv-appearance:saveSkin', function(src, appearance)
    local citizenid = citizenidOf(src)
    if not citizenid or type(appearance) ~= 'table' then return false end
    if appearance.model ~= Config.Models.male and appearance.model ~= Config.Models.female then return false end
    saveSkin(citizenid, appearance)
    return true
end)

exports('GetSkin', getSkin)
exports('SaveSkin', saveSkin)
