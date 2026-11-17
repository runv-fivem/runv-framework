-- Shared table for all rnv-core server files
RNV = {}

RNV.Players = {}
RNV.ByCitizenId = {}

RNV.Cycle = nil ---@type integer?

function RNV.Debug(...)
    if Config.Debug then lib.print.info(...) end
end

function RNV.Actor(src)
    if not src or src == 0 then return GetInvokingResource() or 'console' end
    local player = RNV.Players[tonumber(src)]
    return player and player.citizenid or ('src:%s'):format(src)
end

function RNV.Audit(actor, action, target, data)
    MySQL.insert('INSERT INTO audit_log (actor, action, target, data) VALUES (?, ?, ?, ?)', {
        actor, action, target, data and json.encode(data) or nil,
    })
end

-- runs sql/runv.sql on start, it only creates what's missing
local function migrate()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/runv.sql')
    sql = sql:gsub('%-%-[^\n]*', '')
    for statement in sql:gmatch('[^;]+') do
        if statement:find('%S') then MySQL.query.await(statement) end
    end
end

local function loadCycle()
    local id = MySQL.scalar.await('SELECT id FROM cycles WHERE ended_at IS NULL ORDER BY id DESC LIMIT 1')
    if not id then
        id = MySQL.insert.await('INSERT INTO cycles () VALUES ()')
    end
    RNV.Cycle = id
    GlobalState.rnvCycle = id
end

MySQL.ready(function()
    migrate()
    loadCycle()
    RNV.Ready = true
    lib.print.info(('[%s] core ready (cycle %s)'):format(Config.Prefix, RNV.Cycle))
end)

function RNV.HasPermission(src, perm)
    return IsPlayerAceAllowed(tostring(src), perm)
end

exports('HasPermission', RNV.HasPermission)
exports('GetCycle', function() return RNV.Cycle end)
