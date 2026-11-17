-- rnv-core lib (credits and license: lib/NOTICE.md)
-- Other resources load it with shared_script '@rnv-core/lib/init.lua', then use lib.x and cache
-- lib.x loads lib/x_shared.lua + lib/x_<client|server>.lua the first time it's used

local resourceName = GetCurrentResourceName()
local lib = {
    name = debug.getinfo(1, 'S').source:match('^@@([^/]+)/.+'),
    context = IsDuplicityVersion() and 'server' or 'client',
}

-- rnv-core has its own lib (lib/core.lua)
if resourceName == lib.name then return end

if _ENV.lib and _ENV.lib.name == lib.name then return end

if GetResourceState(lib.name) ~= 'started' then
    error('^1rnv-core must be started before this resource.^0', 0)
end

local export = exports[lib.name]
local status = export.hasLoaded()

if status ~= true then error(status, 1) end

-- No errors when encoding unknown data types (userdata, glm_polygon...)
msgpack.setoption('ignore_invalid', true)

_ENV.lib = lib
function noop() end

local LoadResourceFile = LoadResourceFile

local function loadModule(self, module)
    local chunk = LoadResourceFile(lib.name, ('lib/%s_%s.lua'):format(module, lib.context))
    local shared = LoadResourceFile(lib.name, ('lib/%s_shared.lua'):format(module))

    if shared then
        chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
    end

    if not chunk then return end

    local fn, err = load(chunk, ('@@rnv-core/lib/%s_%s.lua'):format(module, lib.context))

    if not fn or err then
        if shared then
            lib.print.warn(("An error happened while loading '@rnv-core/lib/%s'.\n%s'"):format(module, err))
            fn, err = load(shared, ('@@rnv-core/lib/%s_shared.lua'):format(module))
        end

        if not fn or err then
            return error(('\n^1Error loading lib module (%s): %s^0'):format(module, err), 3)
        end
    end

    local result = fn()
    self[module] = result or noop
    return self[module]
end

-- lib.x: a lib file, or else a function exported by rnv-core (lib.notify, lib.progressBar...)
local function call(self, index, ...)
    local module = rawget(self, index)

    if not module then
        self[index] = noop
        module = loadModule(self, index)

        if not module then
            local function method(...)
                return export[index](nil, ...)
            end

            if not ... then
                self[index] = method
            end

            return method
        end
    end

    return module
end

-- the one metatable of the lib: modules load the first time they're used
setmetatable(lib, { __index = call, __call = call })

local intervals = {}

function SetInterval(callback, interval, ...)
    interval = interval or 0

    if type(interval) ~= 'number' then
        return error(('Interval must be a number. Received %s'):format(json.encode(interval)))
    end

    local cbType = type(callback)

    if cbType == 'number' and intervals[callback] then
        intervals[callback] = interval or 0
        return
    end

    if cbType ~= 'function' then
        return error(('Callback must be a function. Received %s'):format(cbType))
    end

    local args, id = { ... }

    Citizen.CreateThreadNow(function(ref)
        id = ref
        intervals[id] = interval or 0
        repeat
            interval = intervals[id]
            Wait(interval)

            if interval < 0 then break end
            callback(table.unpack(args))
        until false
        intervals[id] = nil
    end)

    return id
end

function ClearInterval(id)
    if type(id) ~= 'number' then
        return error(('Interval id must be a number. Received %s'):format(json.encode(id)))
    end

    if not intervals[id] then
        return error(('No interval exists with id %s'):format(id))
    end

    intervals[id] = -1
end

-- cache.x: the value rnv-core keeps (ped, vehicle, weapon...), kept up to date by 'rnv-lib:cache:x'
-- cache(key, fn, timeout): keeps the result of fn, cleared after timeout ms
local cacheEvents = {}

local cache = setmetatable({ game = GetGameName(), resource = resourceName }, {
    __index = function(self, key)
        cacheEvents[key] = {}

        AddEventHandler(('rnv-lib:cache:%s'):format(key), function(value)
            local oldValue = self[key]
            local events = cacheEvents[key]

            for i = 1, #events do
                Citizen.CreateThreadNow(function()
                    events[i](value, oldValue)
                end)
            end

            self[key] = value
        end)

        return rawset(self, key, export.cache(nil, key) or false)[key]
    end,

    __call = function(self, key, func, timeout)
        local value = rawget(self, key)

        if value == nil then
            value = func()

            rawset(self, key, value)

            if timeout then SetTimeout(timeout, function() self[key] = nil end) end
        end

        return value
    end,
})

function lib.onCache(key, cb)
    if not cacheEvents[key] then
        getmetatable(cache).__index(cache, key)
    end

    table.insert(cacheEvents[key], cb)
end

_ENV.cache = cache

local notifyEvent = ('__rnv_notify_%s'):format(cache.resource)

if lib.context == 'client' then
    RegisterNetEvent(notifyEvent, function(data)
        if locale then
            if data.title then
                data.title = locale(data.title) or data.title
            end

            if data.description then
                data.description = locale(data.description) or data.description
            end
        end

        return export:notify(data)
    end)

    cache.playerId = PlayerId()
    cache.serverId = GetPlayerServerId(cache.playerId)
else
    -- Server side: show a lib notify on that player
    function lib.notify(playerId, data)
        TriggerClientEvent(notifyEvent, playerId, data)
    end

    -- Server version of the GetActivePlayers client native
    function GetActivePlayers()
        local playerNum = GetNumPlayerIndices()
        local players = table.create(playerNum, 0)

        for i = 1, playerNum do
            players[i] = tonumber(GetPlayerFromIndex(i - 1))
        end

        return players
    end
end

load(LoadResourceFile(lib.name, 'lib/require.lua'), '@@rnv-core/lib/require.lua')()

-- rnv_libs { 'locale', 'table' } in a manifest loads those modules right away
for i = 1, GetNumResourceMetadata(cache.resource, 'rnv_lib') do
    local name = GetResourceMetadata(cache.resource, 'rnv_lib', i - 1)

    if not rawget(lib, name) then
        local module = loadModule(lib, name)

        if type(module) == 'function' then pcall(module) end
    end
end
