local EventHook = Class('EventHook')

function EventHook:constructor(hookId, resource, event)
    self.hookId = hookId
    self.resource = resource
    self.event = event
end

function EventHook:on(handler)
    self:off()
    self.handler = AddEventHandler(self.hookId, handler)
end

function EventHook:off()
    if self.handler then
        RemoveEventHandler(self.handler)
        self.handler = nil
    end
end

function EventHook:remove()
    self:off()
    exports[self.resource][('removeHook:%s'):format(self.event)](nil, self.hookId)
end

function lib.registerHook(eventName, handler, options)
    local resource, event = string.strsplit(':', eventName, 2)

    if not resource or not event then
        error(('Invalid event format: %s (expected "resourceName:eventName")'):format(event))
    end

    if type(handler) == 'table' and not options then
        options = handler
        handler = nil
    end

    local hookId = exports[resource][('registerHook:%s'):format(event)](nil, handler, options)

    return EventHook:new(hookId, resource, event)
end

return lib.registerHook
