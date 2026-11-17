-- Admin commands, only for group.admin

local function reply(src, msg)
    if src == 0 then return print(msg) end
    TriggerClientEvent('chat:addMessage', src, { args = { Config.Prefix, msg } })
end

local function target(src, id)
    local player = RNV.GetPlayer(id)
    if not player then reply(src, 'Player not loaded.') end
    return player
end

local function bankOf(player)
    return RNV.GetAccount('player', player.citizenid, 'bank')
end

lib.addCommand('rnv_info', {
    help = 'Show core data of a player',
    params = { { name = 'target', type = 'playerId', help = 'Player id or "me"' } },
    restricted = 'group.admin',
}, function(src, args)
    local player = target(src, args.target)
    if not player then return end
    local bank = bankOf(player)
    reply(src, ('%s | %s | role=%s life=%s | bank=%s | cycle=%s'):format(
        player.name, player.citizenid, player.role, player.lifeState,
        bank and ('#%s $%s (%s)'):format(bank.id, bank.balance, bank.status) or 'not opened', RNV.Cycle))
end)

lib.addCommand('rnv_openbank', {
    help = 'Open a bank account for a player (no fee, dev only)',
    params = { { name = 'target', type = 'playerId', help = 'Player id or "me"' } },
    restricted = 'group.admin',
}, function(src, args)
    local player = target(src, args.target)
    if not player then return end
    local id, err = RNV.OpenAccount('player', player.citizenid, 'bank', RNV.Actor(src))
    reply(src, id and ('Bank account #%s opened.'):format(id) or ('Failed: %s'):format(err))
end)

local function moneyCommand(name, help, fn)
    lib.addCommand(name, {
        help = help,
        params = {
            { name = 'target', type = 'playerId', help = 'Player id or "me"' },
            { name = 'amount', type = 'number', help = 'Whole dollars' },
        },
        restricted = 'group.admin',
    }, function(src, args)
        local player = target(src, args.target)
        if not player then return end
        local bank = bankOf(player)
        if not bank then return reply(src, 'Player has no bank account.') end
        local ok, result = fn(bank.id, args.amount, 'admin:' .. name, nil, RNV.Actor(src))
        reply(src, ok and ('Done. Balance: $%s'):format(result) or ('Failed: %s'):format(result))
    end)
end

moneyCommand('rnv_addbank', 'Add money to a player bank account', RNV.AddMoney)
moneyCommand('rnv_removebank', 'Remove money from a player bank account', RNV.RemoveMoney)

lib.addCommand('rnv_setrole', {
    help = 'Set the current role of a player',
    params = {
        { name = 'target', type = 'playerId', help = 'Player id or "me"' },
        { name = 'role', type = 'string', help = 'civilian | criminal | cop' },
    },
    restricted = 'group.admin',
}, function(src, args)
    local player = target(src, args.target)
    if not player then return end
    if not RNV.SetRole(player.source, args.role, 'admin') then return reply(src, 'Invalid role.') end
    RNV.Audit(RNV.Actor(src), 'set_role', player.citizenid, { role = args.role })
    reply(src, ('Role set to %s.'):format(args.role))
end)
