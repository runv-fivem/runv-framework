
local SemVer = Class('SemVer')
local components = { 'major', 'minor', 'patch' }

local function parseNumber(value)
    local number = tonumber(value)

    assert(number and number <= math.maxinteger, 'semantic version component out of range')

    return number
end

function SemVer:constructor(version)
    assert(type(version) == 'string', 'version must be a string')

    version = version:match('^%s*(.-)%s*$')
    version = version:gsub('^[v=]', '')

    local major, minor, patch = version:match('^(%d+)%.(%d+)%.(%d+)$')

    assert(major and minor and patch, ('invalid semantic version: %s'):format(version))

    self.major = parseNumber(major)
    self.minor = parseNumber(minor)
    self.patch = parseNumber(patch)

    return self
end

function SemVer:compare(other)
    other = type(other) == 'string' and SemVer:new(other) or other

    for _, key in ipairs(components) do
        if self[key] < other[key] then
            return -1
        elseif self[key] > other[key] then
            return 1
        end
    end

    return 0
end

function SemVer:equals(other)
    return self:compare(other) == 0
end

function SemVer:__tostring()
    return ('%d.%d.%d'):format(self.major, self.minor, self.patch)
end

return SemVer
