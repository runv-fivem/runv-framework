-- Daily jobs at a set time of the server clock
--   exports['rnv-cronAPI']:RunAt(4, 30, function(weekday, h, m) ... end)
--   TriggerEvent('rnv-cronAPI:runAt', 4, 30, function(weekday, h, m) ... end)
-- weekday: 1 = Sunday ... 7 = Saturday (os.date '*t' wday)

local cronJobs = {}
local lastTimestamp = false

function RunAt(h, m, cb)
    cronJobs[#cronJobs + 1] = {
        h = h,
        m = m,
        cb = cb,
    }
end

function GetUnixTimestamp()
    return os.time()
end

-- The time this job should run today (or another day, by dayOffset)
local function scheduledAt(job, timestamp, dayOffset)
    local dateTable = os.date('*t', timestamp)
    dateTable.hour = job.h
    dateTable.min = job.m
    dateTable.sec = 0
    dateTable.day = dateTable.day + dayOffset

    return os.time(dateTable)
end

-- Runs every job whose time came since the last check
function OnTime(timestamp)
    for i = 1, #cronJobs do
        local job = cronJobs[i]
        local scheduledTimestamp = scheduledAt(job, timestamp, 0)

        -- Not reached today yet: look at yesterday's time
        if scheduledTimestamp > timestamp then
            scheduledTimestamp = scheduledAt(job, timestamp, -1)
        end

        if not lastTimestamp or lastTimestamp < scheduledTimestamp then
            local weekday = os.date('*t', scheduledTimestamp).wday
            local ok, err = pcall(job.cb, weekday, job.h, job.m)

            if not ok then
                print(('[^1ERROR^7] cron job at ^5%02d:%02d^7 errored, skipping it: %s'):format(job.h, job.m, tostring(err)))
            end
        end
    end
end

-- Checks once a minute, right after the minute changes
function Tick()
    local timestamp = GetUnixTimestamp()

    if not lastTimestamp or os.date('%M', timestamp) ~= os.date('%M', lastTimestamp) then
        OnTime(timestamp)
        lastTimestamp = timestamp
    end

    local seconds = tonumber(os.date('%S', timestamp)) or 0
    local msToNextMinute = math.max(1000, (60 - seconds) * 1000)

    SetTimeout(msToNextMinute, Tick)
end

lastTimestamp = GetUnixTimestamp()
Tick()

-- A function, or a table you can call (export functions from other resources)
local function isCallable(cb)
    if type(cb) == 'function' then return true end
    if type(cb) ~= 'table' then return false end

    local meta = getmetatable(cb)
    return meta ~= nil and type(meta.__call) == 'function'
end

local function addJob(h, m, cb)
    local invokingResource = GetInvokingResource() or 'Unknown'

    assert(type(h) == 'number', ("Expected number for h, got %s. Invoking Resource: '%s'"):format(type(h), invokingResource))
    assert(type(m) == 'number', ("Expected number for m, got %s. Invoking Resource: '%s'"):format(type(m), invokingResource))
    assert(isCallable(cb), ("Expected function for cb, got %s. Invoking Resource: '%s'"):format(type(cb), invokingResource))

    RunAt(h, m, cb)
end

AddEventHandler('rnv-cronAPI:runAt', addJob)
exports('RunAt', addJob)
