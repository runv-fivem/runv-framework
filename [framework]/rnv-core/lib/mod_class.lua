
local getinfo = debug.getinfo

local function assertType(id, var, expected)
    local received = type(var)

    if received ~= expected then
        error(("expected %s %s to have type '%s' (received %s)")
            :format(type(id) == 'string' and 'field' or 'argument', id, expected, received), 3)
    end

    if expected == 'table' and table.type(var) ~= 'hash' then
        error(("expected argument %s to have table.type 'hash' (received %s)")
            :format(id, table.type(var)), 3)
    end

    return true
end

local weakkeys = { __mode = 'k' }

local classes = setmetatable({}, weakkeys)


local mixins = {}
local constructors = setmetatable({}, weakkeys)

local function getConstructor(class)
    local constructor = constructors[class] or class.constructor

    if class.constructor then
        constructors[class] = class.constructor
        class.constructor = nil
    end

    return constructor
end

local function void() return '' end

local function validatePrivateAccess(class)
    local level = 3

    while true do
        local di = getinfo(level, 'f')

        if not di or not di.func then return false end

        local currentClass = class

        while currentClass do
            local classMethods = classes[currentClass]
            local method = classMethods and classMethods[di.func]

            if classMethods and not method then
                for k, v in pairs(currentClass) do
                    if v == di.func then
                        method = v
                        classMethods[method] = k
                        break
                    end
                end
            end

            if method then return true end

            currentClass = getmetatable(currentClass)
        end

        level = level + 1
    end
end

function mixins.new(class, ...)
    local constructor = getConstructor(class)
    local private = {}
    local obj = setmetatable({ private = private }, class)

    if constructor then
        local parent = class

        rawset(obj, 'super', function(self, ...)
            parent = getmetatable(parent)
            constructor = getConstructor(parent)

            if constructor then return constructor(self, ...) end
        end)

        constructor(obj, ...)
    end

    rawset(obj, 'super', nil)

    if private ~= obj.private or next(obj.private) then
        private = table.clone(obj.private)

        table.wipe(obj.private)
        setmetatable(obj.private, {
            __metatable = 'private',
            __tostring = void,
            __index = function(self, index)
                if not validatePrivateAccess(class) then return end

                return private[index]
            end,
            __newindex = function(self, index, value)
                if not validatePrivateAccess(class) then
                    error(("cannot set value of private field '%s'"):format(index), 2)
                end

                private[index] = value
            end
        })
    else
        obj.private = nil
    end

    return obj
end

function mixins:isClass(class)
    return getmetatable(self) == class
end

function mixins:instanceOf(class)
    local mt = getmetatable(self)

    while mt do
        if mt == class then return true end

        mt = getmetatable(mt)
    end

    return false
end

local function Class(name, super)
    assertType(1, name, 'string')

    local class = table.clone(mixins)

    class.__name = name
    class.__index = class

    if super then
        assertType('super', super, 'table')
        setmetatable(class, super)
    end

    classes[class] = setmetatable({}, weakkeys)

    return class
end

_ENV.Class = Class

return Class
