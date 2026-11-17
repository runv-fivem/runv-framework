-- require / loadfile / dofile / json.load for every resource (lib/package.lua)

if not package or not runtime then
    load(LoadResourceFile('rnv-core', 'lib/package.lua'), '@@rnv-core/lib/package.lua')()
end

-- Old names
lib.require = require
lib.loadJson = json.load

-- Loads and runs a Lua file each time (not kept like require)
function lib.load(filePath, env)
    return loadfile(filePath, 't', env)()
end

-- require 'Rnv.Class' and the other lib/mod_*.lua classes
local classFiles = {
    ['Rnv.Class'] = '@rnv-core.lib.mod_class',
    ['Rnv.DataView'] = '@rnv-core.lib.mod_dataview',
    ['Rnv.Logger'] = '@rnv-core.lib.mod_logger',
    ['Rnv.SemVer'] = '@rnv-core.lib.mod_semver',
    ['Rnv.Game.Entity'] = '@rnv-core.lib.mod_game_entity',
    ['Rnv.Game.Ped'] = '@rnv-core.lib.mod_game_ped',
    ['Rnv.Game.Player'] = '@rnv-core.lib.mod_game_player',
    ['Rnv.Game.Prop'] = '@rnv-core.lib.mod_game_prop',
    ['Rnv.Game.Vehicle'] = '@rnv-core.lib.mod_game_vehicle',
}

table.insert(package.searchers, 1, function(modName)
    local file = classFiles[modName]

    if file then
        return function() return require(file) end
    end
end)

require 'Rnv.Class'

-- fx_dependencies { 'resource: 1.2.3' } in a manifest: check those versions
local SemVer = require 'Rnv.SemVer'
local errors = {}

for i = 0, GetNumResourceMetadata(cache.resource, 'fx_dependencie') - 1 do
    local resource, required = string.strsplit(':', GetResourceMetadata(cache.resource, 'fx_dependencie', i), 2)
    local version = SemVer:new(GetResourceMetadata(resource, 'version', 0))
    required = SemVer:new(required)

    if required:compare(version) == 1 then
        local url = GetResourceMetadata(resource, 'repository', 0) or GetResourceMetadata(resource, 'url', 0)
        errors[#errors + 1] = ("- %s: required %s, installed %s%s"):format(
            resource,
            required,
            version,
            url and (' (%s)'):format(url) or ''
        )
    end
end

if #errors > 0 then
    error(([[The following resource dependencies do not meet the required version:
    %s

Please update the listed resources to their required versions and restart.]]):format(table.concat(errors, '\n\t')), 0)
end

return require
