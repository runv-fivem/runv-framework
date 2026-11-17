

lib.ringbuffer = Class('RingBuffer')

function lib.ringbuffer:constructor(capacity)
    if type(capacity) ~= 'number' or capacity < 1 or capacity % 1 ~= 0 then
        error("capacity must be a positive integer", 2)
    end

    self.private.items = table.create(capacity, 0)
    self.private.capacity = capacity
    self.private.count = 0
    self.private.nextIndex = 1
end

function lib.ringbuffer:push(value)
    local items = self.private.items
    local capacity = self.private.capacity
    local nextIndex = self.private.nextIndex

    local evicted
    if self.private.count == capacity then
        evicted = items[nextIndex]
    else
        self.private.count = self.private.count + 1
    end

    items[nextIndex] = value
    self.private.nextIndex = nextIndex % capacity + 1

    return evicted
end

local function oldestIndex(self)
    if self.private.count < self.private.capacity then return 1 end
    return self.private.nextIndex
end

function lib.ringbuffer:get(i)
    if type(i) ~= 'number' or i % 1 ~= 0 then
        error("index must be an integer", 2)
    end

    local count = self.private.count
    if i < 0 then i = count + i + 1 end
    if i < 1 or i > count then return nil end

    local start = oldestIndex(self)
    local capacity = self.private.capacity
    return self.private.items[((start - 1 + i - 1) % capacity) + 1]
end

function lib.ringbuffer:size()
    return self.private.count
end

function lib.ringbuffer:capacity()
    return self.private.capacity
end

function lib.ringbuffer:isFull()
    return self.private.count == self.private.capacity
end

function lib.ringbuffer:isEmpty()
    return self.private.count == 0
end

function lib.ringbuffer:clear()
    table.wipe(self.private.items)
    self.private.count = 0
    self.private.nextIndex = 1
    return self
end

function lib.ringbuffer:each()
    local count = self.private.count
    local capacity = self.private.capacity
    local items = self.private.items
    local start = oldestIndex(self)
    local i = 0

    return function()
        i = i + 1
        if i > count then return nil end
        return items[((start - 1 + i - 1) % capacity) + 1]
    end
end

function lib.ringbuffer:__pairs()
    return self:each(), nil, nil
end

lib.ringbuffer.__len = lib.ringbuffer.size

function lib.ringbuffer:toArray()
    return lib.array:from(self:each())
end

return lib.ringbuffer
