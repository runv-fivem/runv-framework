

lib.heap = Class('Heap')

local function defaultLess(a, b) return a < b end

local function siftUp(items, i, lt)
    while i > 1 do
        local parent = i >> 1
        if not lt(items[i], items[parent]) then return end
        items[i], items[parent] = items[parent], items[i]
        i = parent
    end
end

local function siftDown(items, i, n, lt)
    while true do
        local left = i * 2
        if left > n then return end

        local smallest = i
        if lt(items[left], items[smallest]) then smallest = left end

        local right = left + 1
        if right <= n and lt(items[right], items[smallest]) then smallest = right end

        if smallest == i then return end

        items[i], items[smallest] = items[smallest], items[i]
        i = smallest
    end
end

function lib.heap:constructor(comparator)
    if comparator ~= nil and type(comparator) ~= 'function' then
        error("comparator must be a function or nil", 2)
    end

    self.private.items = {}
    self.private.lt = comparator or defaultLess
end

function lib.heap:push(...)
    local n = select('#', ...)
    if n == 0 then return self end

    local items = self.private.items
    local lt = self.private.lt
    local startIndex = #items

    table.move({ ... }, 1, n, startIndex + 1, items)

    for i = 1, n do
        siftUp(items, startIndex + i, lt)
    end

    return self
end

function lib.heap:pop()
    local items = self.private.items
    local n = #items
    if n == 0 then return nil end

    local top = items[1]

    if n == 1 then
        items[1] = nil
    else
        items[1] = items[n]
        items[n] = nil
        siftDown(items, 1, n - 1, self.private.lt)
    end

    return top
end

function lib.heap:peek()
    return self.private.items[1]
end

function lib.heap:size()
    return #self.private.items
end

function lib.heap:isEmpty()
    return #self.private.items == 0
end

function lib.heap:clear()
    table.wipe(self.private.items)
    return self
end

function lib.heap:drain()
    local out = lib.array:new()
    local n = 0
    while #self.private.items > 0 do
        n = n + 1
        out[n] = self:pop()
    end
    return out
end

lib.heap.__len = lib.heap.size

return lib.heap
