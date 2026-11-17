
lib.set = Class('Set')

function lib.set:constructor(...)
    self.private.map = lib.map:new()

    local args = { ... }
    for i = 1, select('#', ...) do
        self:add(args[i])
    end
end

function lib.set:add(value)
    if value ~= nil and not self.private.map:has(value) then
        self.private.map:set(value, true)
    end
    return self
end

function lib.set:remove(value)
    return self.private.map:delete(value)
end

function lib.set:has(value)
    return self.private.map:has(value)
end

function lib.set:size()
    return self.private.map:size()
end

function lib.set:isEmpty()
    return self.private.map:isEmpty()
end

function lib.set:clear()
    self.private.map:clear()
    return self
end

function lib.set:each()
    return self.private.map:keys()
end

function lib.set:__pack()
    return msgpack.pack(self:toArray()), true
end

function lib.set:__tojson()
    return json.encode(self:toArray())
end

function lib.set:__pairs()
    local it = self.private.map:keys()
    local i = 0
    return function()
        local v = it()
        if v == nil then return nil end
        i = i + 1
        return i, v
    end
end

lib.set.__ipairs = lib.set.__pairs
lib.set.__len = lib.set.size

function lib.set:toArray()
    return lib.array:from(self:each())
end

function lib.set:union(other)
    local result = lib.set:new()
    for v in self:each() do result:add(v) end
    for v in other:each() do result:add(v) end
    return result
end

function lib.set:intersection(other)
    local result = lib.set:new()
    for v in self:each() do
        if other:has(v) then result:add(v) end
    end
    return result
end

function lib.set:difference(other)
    local result = lib.set:new()
    for v in self:each() do
        if not other:has(v) then result:add(v) end
    end
    return result
end

function lib.set:equals(other)
    if self:size() ~= other:size() then return false end
    for v in self:each() do
        if not other:has(v) then return false end
    end
    return true
end

function lib.set:isSubsetOf(other)
    if self:size() > other:size() then return false end
    for v in self:each() do
        if not other:has(v) then return false end
    end
    return true
end

return lib.set
