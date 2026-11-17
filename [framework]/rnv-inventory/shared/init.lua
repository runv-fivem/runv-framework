local function addDeferral(err)
    err = err:gsub("%^%d", "")

    AddEventHandler('playerConnecting', function(_, _, deferrals)
        deferrals.defer()
        deferrals.done(err)
    end)
end

-- Settings come from the inventory:* convars (rnv.cfg), not from this file

shared = {
    resource = GetCurrentResourceName(),
    framework = GetConvar('inventory:framework', 'runv'),
    playerslots = GetConvarInt('inventory:slots', 56),
    playerweight = GetConvarInt('inventory:weight', 30000),
    police = json.decode(GetConvar('inventory:police', '["police", "sheriff"]')),
    networkdumpsters = GetConvarBool('inventory:networkdumpsters', false)
}

shared.dropslots = GetConvarInt('inventory:dropslots', shared.playerslots)
shared.dropweight = GetConvarInt('inventory:dropweight', shared.playerweight)

do
    if type(shared.police) == 'string' then
        shared.police = { shared.police }
    end

    local police = table.create(0, shared.police and #shared.police or 0)

    for i = 1, #shared.police do
        police[shared.police[i]] = 0
    end

    shared.police = police
end

if IsDuplicityVersion() then
    server = {
        loghookrejection = GetConvarBool('inventory:loghookrejection', true),
        bulkstashsave = GetConvarBool('inventory:bulkstashsave', true),
        loglevel = GetConvarInt('inventory:loglevel', 1),
        randomprices = GetConvarBool('inventory:randomprices', false),
        randomloot = GetConvarBool('inventory:randomloot', true),
        evidencegrade = GetConvarInt('inventory:evidencegrade', 2),
        trimplate = GetConvarBool('inventory:trimplate', true),
        vehicleloot = json.decode(GetConvar('inventory:vehicleloot', [[
			[
				["sprunk", 1, 1],
				["water", 1, 1],
				["garbage", 1, 2, 50],
				["panties", 1, 1, 5],
				["money", 1, 50],
				["money", 200, 400, 5],
				["bandage", 1, 1]
			]
		]])),
        dumpsterloot = json.decode(GetConvar('inventory:dumpsterloot', [[
			[
				["mustard", 1, 1],
				["garbage", 1, 3],
				["money", 1, 10],
				["burger", 1, 1]
			]
		]])),
        validhosts = json.decode(GetConvar('inventory:validhosts', [[
			{
                "r2.fivemanage.com": true,
                "i.fmfile.com": true
            }
		]])),
    }

    local accounts = json.decode(GetConvar('inventory:accounts', '["money"]'))
    server.accounts = table.create(0, #accounts)

    for i = 1, #accounts do
        server.accounts[accounts[i]] = 0
    end
else
    PlayerData = {}
    client = {
        player = lib.player:new(-1),
        autoreload = GetConvarBool('inventory:autoreload', false),
        screenblur = GetConvarBool('inventory:screenblur', true),
        keys = json.decode(GetConvar('inventory:keys', '')) or { 'F2', 'K', 'TAB' },
        enablekeys = json.decode(GetConvar('inventory:enablekeys', '[249]')),
        aimedfiring = GetConvarBool('inventory:aimedfiring', false),
        giveplayerlist = GetConvarBool('inventory:giveplayerlist', false),
        weaponanims = GetConvarBool('inventory:weaponanims', true),
        itemnotify = GetConvarBool('inventory:itemnotify', true),
        weaponnotify = GetConvarBool('inventory:weaponnotify', true),
        imagepath = GetConvar('inventory:imagepath', 'nui://rnv-inventory/web/images'),
        dropprops = GetConvarBool('inventory:dropprops', false),
        dropmodel = joaat(GetConvar('inventory:dropmodel', 'prop_med_bag_01b')),
        weaponmismatch = GetConvarBool('inventory:weaponmismatch', true),
        ignoreweapons = json.decode(GetConvar('inventory:ignoreweapons', '[]')),
        suppresspickups = GetConvarBool('inventory:suppresspickups', true),
        disableweapons = GetConvarBool('inventory:disableweapons', false),
        disablesetupnotification = GetConvarBool('inventory:disablesetupnotification', false),
        enablestealcommand = GetConvarBool('inventory:enablestealcommand', true),
        gloveboxseatrestriction = GetConvarInt('inventory:gloveboxseatrestriction', 0) == 1
    }

    local ignoreweapons = table.create(0, (client.ignoreweapons and #client.ignoreweapons or 0) + 3)

    for i = 1, #client.ignoreweapons do
        local weapon = client.ignoreweapons[i]
        ignoreweapons[tonumber(weapon) or joaat(weapon)] = true
    end

    ignoreweapons[joaat('WEAPON_UNARMED')] = true
    ignoreweapons[joaat('WEAPON_HANDCUFFS')] = true
    ignoreweapons[joaat('WEAPON_GARBAGEBAG')] = true
    ignoreweapons[joaat('OBJECT')] = true
    ignoreweapons[joaat('WEAPON_HOSE')] = true

    client.ignoreweapons = ignoreweapons

    local fallbackmarker = {
        type = 0,
        colour = { 150, 150, 150 },
        scale = { 0.5, 0.5, 0.5 }
    }

    client.shopmarker = json.decode(GetConvar('inventory:shopmarker', [[
        {
            "type": 29,
            "colour": [30, 150, 30],
            "scale": [0.5, 0.5, 0.5]
        }
    ]])) or fallbackmarker

    client.evidencemarker = json.decode(GetConvar('inventory:evidencemarker', [[
        {
            "type": 2,
            "colour": [30, 30, 150],
            "scale": [0.3, 0.2, 0.15]
        }
    ]])) or fallbackmarker

    client.craftingmarker = json.decode(GetConvar('inventory:craftingmarker', [[
        {
            "type": 2,
            "colour": [150, 150, 30],
            "scale": [0.3, 0.2, 0.15]
        }
    ]])) or fallbackmarker

    client.dropmarker = json.decode(GetConvar('inventory:dropmarker', [[
        {
            "type": 2,
            "colour": [150, 30, 30],
            "scale": [0.3, 0.2, 0.15]
        }
    ]])) or fallbackmarker
end

function shared.print(...) print(string.strjoin(' ', ...)) end

function shared.info(...) lib.print.info(string.strjoin(' ', ...)) end

function TypeError(variable, expected, received)
    error(("expected %s to have type '%s' (received %s)"):format(variable, expected, received))
end

-- Keeps showing the error, so it can't be missed
local function spamError(err)
    shared.ready = false

    CreateThread(function()
        while true do
            Wait(10000)
            CreateThread(function()
                error(err, 0)
            end)
        end
    end)

    addDeferral(err)
    error(err, 0)
end

function data(name)
    if shared.server and shared.ready == nil then return {} end
    local file = ('data/%s.lua'):format(name)
    local datafile = LoadResourceFile(shared.resource, file)
    local path = ('@@%s/%s'):format(shared.resource, file)

    if not datafile then
        warn(('no datafile found at path %s'):format(path:gsub('@@', '')))
        return {}
    end

    local func, err = load(datafile, path)

    if not func or err then
        shared.ready = false
        return spamError(err)
    end

    return func()
end

if not lib then
    return spamError('rnv-inventory needs rnv-core (its lib) to start first.')
end

local success, msg = lib.checkDependency('oxmysql', '2.7.3')

if not success then
    return spamError(msg)
end

if not LoadResourceFile(shared.resource, 'web/build/index.html') then
    return spamError(
        'rnv-inventory/web/build/index.html is missing')
end

if lib.context == 'server' then
    shared.ready = false
    return require 'server.main'
end

require 'client.main'
