-- Bank accounts and the money ledger
-- Cash in hand is not here, the inventory owns it
-- Amounts are whole numbers, and a unique ref stops the same payment from going through twice

local MAX_AMOUNT = 1000000000000

local function validAmount(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 or amount > MAX_AMOUNT or amount ~= math.floor(amount) then return end
    return math.floor(amount)
end

local function notify(account, amount, balance, reason)
    TriggerEvent('rnv:server:moneyChanged', account.id, account.owner_type, account.owner_id, amount, balance, reason)
    if account.owner_type == 'player' then
        local src = RNV.ByCitizenId[account.owner_id]
        if src then
            TriggerClientEvent('rnv:client:moneyChanged', src, account.type, amount, balance, reason)
        end
    end
end

function RNV.OpenAccount(ownerType, ownerId, accountType, actor)
    accountType = accountType or 'bank'
    if not Config.OwnerTypes[ownerType] or not Config.AccountTypes[accountType] or not ownerId then
        return nil, 'invalid'
    end
    local id = MySQL.insert.await(
        'INSERT IGNORE INTO accounts (cycle_id, owner_type, owner_id, type) VALUES (?, ?, ?, ?)',
        { RNV.Cycle, ownerType, tostring(ownerId), accountType })
    if not id or id == 0 then return nil, 'exists' end
    RNV.Audit(actor or RNV.Actor(), 'account_open', tostring(id), { ownerType = ownerType, ownerId = ownerId, type = accountType })
    return id
end

function RNV.GetAccount(ownerType, ownerId, accountType)
    return MySQL.single.await(
        'SELECT id, owner_type, owner_id, type, balance, status FROM accounts WHERE cycle_id = ? AND owner_type = ? AND owner_id = ? AND type = ?',
        { RNV.Cycle, ownerType, tostring(ownerId), accountType or 'bank' })
end

function RNV.GetBalance(accountId)
    return MySQL.scalar.await('SELECT balance FROM accounts WHERE id = ? AND cycle_id = ?', { accountId, RNV.Cycle })
end

-- locks the row so two payments can't spend the same balance
local function lockAccount(query, accountId)
    local rows = query('SELECT id, cycle_id, owner_type, owner_id, type, balance, status FROM accounts WHERE id = ? FOR UPDATE', { accountId })
    local account = rows and rows[1]
    if not account then return nil, 'no_account' end
    if account.cycle_id ~= RNV.Cycle then return nil, 'stale_cycle' end
    if account.status ~= 'open' then return nil, 'account_' .. account.status end
    return account
end

local function writeLedger(query, account, delta, reason, ref, actor)
    local balance = account.balance + delta
    query('UPDATE accounts SET balance = ? WHERE id = ?', { balance, account.id })
    query('INSERT INTO transactions (account_id, cycle_id, amount, balance_after, reason, ref, actor) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { account.id, account.cycle_id, delta, balance, reason, ref, actor })
    return balance
end

local function isDuplicate(query, ref)
    if not ref then return false end
    local rows = query('SELECT 1 FROM transactions WHERE ref = ? LIMIT 1', { ref })
    return rows and rows[1] ~= nil
end

local function change(accountId, delta, reason, ref, actor)
    accountId = tonumber(accountId)
    if not accountId then return false, 'invalid' end
    local err, account, balance
    local ok = MySQL.startTransaction(function(query)
        if isDuplicate(query, ref) then err = 'duplicate' return false end
        account, err = lockAccount(query, accountId)
        if not account then return false end
        if account.balance + delta < 0 then err = 'insufficient_funds' return false end
        balance = writeLedger(query, account, delta, reason, ref, actor)
        return true
    end)
    if not ok then return false, err or 'db_error' end
    notify(account, delta, balance, reason)
    return true, balance
end

function RNV.AddMoney(accountId, amount, reason, ref, actor)
    amount = validAmount(amount)
    if not amount or type(reason) ~= 'string' then return false, 'invalid' end
    return change(accountId, amount, reason, ref, actor or RNV.Actor())
end

function RNV.RemoveMoney(accountId, amount, reason, ref, actor)
    amount = validAmount(amount)
    if not amount or type(reason) ~= 'string' then return false, 'invalid' end
    return change(accountId, -amount, reason, ref, actor or RNV.Actor())
end

function RNV.Transfer(fromId, toId, amount, reason, ref, actor)
    amount, fromId, toId = validAmount(amount), tonumber(fromId), tonumber(toId)
    if not amount or not fromId or not toId or type(reason) ~= 'string' or fromId == toId then return false, 'invalid' end
    actor = actor or RNV.Actor()

    local err, from, to, fromBalance, toBalance
    local ok = MySQL.startTransaction(function(query)
        if isDuplicate(query, ref and ref .. ':out') then err = 'duplicate' return false end
        -- always lock the lower id first so two transfers can't get stuck on each other
        local first, second = math.min(fromId, toId), math.max(fromId, toId)
        local a, b
        a, err = lockAccount(query, first)
        if not a then return false end
        b, err = lockAccount(query, second)
        if not b then return false end
        from, to = (a.id == fromId) and a or b, (a.id == fromId) and b or a
        if from.balance < amount then err = 'insufficient_funds' return false end
        fromBalance = writeLedger(query, from, -amount, reason, ref and ref .. ':out', actor)
        toBalance = writeLedger(query, to, amount, reason, ref and ref .. ':in', actor)
        return true
    end)
    if not ok then return false, err or 'db_error' end
    notify(from, -amount, fromBalance, reason)
    notify(to, amount, toBalance, reason)
    return true, fromBalance
end

exports('OpenAccount', RNV.OpenAccount)
exports('GetAccount', RNV.GetAccount)
exports('GetBalance', RNV.GetBalance)
exports('AddMoney', RNV.AddMoney)
exports('RemoveMoney', RNV.RemoveMoney)
exports('Transfer', RNV.Transfer)
