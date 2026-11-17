-- The lib inside rnv-core itself
-- lib.x loads lib/x_shared.lua + lib/x_<client|server>.lua the first time it's used
-- A function the lib/core_*.lua files put on lib (lib.notify = ...) is also exported for other resources

local debug_getinfo = debug.getinfo
local loadStatus = 'rnv-core lib has not loaded yet.'

function noop() end

lib = setmetatable({
    name = GetCurrentResourceName(),
    context = IsDuplicityVersion() and 'server' or 'client',
}, {
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        if debug_getinfo(2, 'S').short_src:find('@rnv-core/lib/core', 1, true) then
            exports(key, fn)
        end
    end,

    __index = function(self, key)
        local chunk = LoadResourceFile(self.name, ('lib/%s_%s.lua'):format(key, self.context))
        local shared = LoadResourceFile(self.name, ('lib/%s_shared.lua'):format(key))

        if shared then
            chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
        end

        if chunk then
            local fn, err = load(chunk, ('@@rnv-core/lib/%s_%s.lua'):format(key, self.context))

            if not fn or err then
                return error(('\n^1Error loading lib module (%s): %s^0'):format(key, err), 3)
            end

            rawset(self, key, fn() or noop)

            return self[key]
        end
    end
})

function lib.hasLoaded() return loadStatus end

cache = {
    resource = lib.name,
    game = GetGameName(),
}

if not LoadResourceFile(lib.name, 'web/build/index.html') then
    local err = '^1Unable to load the lib UI: rnv-core/web/build/index.html is missing^0'
    loadStatus = err

    error(err)
end

load(LoadResourceFile(lib.name, 'lib/require.lua'), '@@rnv-core/lib/require.lua')()

loadStatus = true
