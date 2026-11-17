local hooks = {}

AddEventHandler('onResourceStop', function(resource)
    for i = 1, #hooks do
        hooks[i]:remove(resource)
    end
end)

lib.hook = Class('HookPipeline')

function lib.hook:constructor(event, filter)
    self.hooks = {}
    self.event = event
    self.filter = filter

    hooks[#hooks + 1] = self

    exports(('registerHook:%s'):format(event), function(funcref, options)
        return self:registerHook(funcref, options)
    end)

    exports(('removeHook:%s'):format(event), function(hookId)
        local resource = GetInvokingResource() or cache.resource

        self:remove(resource, hookId)
    end)
end

function lib.hook:registerHook(cb, options)
    local idx = #self.hooks + 1
    local resource = GetInvokingResource()
    local hook = {}

    if options then
        for k, v in pairs(options) do
            hook[k] = v
        end
    end

    hook.cb = cb
    hook.resource = resource or cache.resource
    hook.hookId = ('%s:%s:%s'):format(hook.resource, self.event, idx)

    self.hooks[idx] = hook

    return hook.hookId
end

function lib.hook:remove(resource, hookId)
    for i = #self.hooks, 1, -1 do
        local hook = self.hooks[i]

        if hook.resource == resource and (not hookId or hook.hookId == hookId) then
            table.remove(self.hooks, i)
        end
    end
end

function lib.hook:dispatch(payload)
    local events = {};
    local result = setmetatable({ ok = true, size = 0 }, {
        __close = function(result, err)
            if err then
                result.ok = false
            end

            local packed = msgpack.pack_args(result.ok, payload)
            local packedLength = #packed

            for i = 1, #events do
                TriggerEventInternal(events[i], packed, packedLength)
            end
        end
    })

    for i = 1, #self.hooks do
        local hook = self.hooks[i]
        local runHook = self.filter and self.filter(hook, payload) ~= false
        local rejected = runHook and hook.cb and hook.cb(payload) == false

        if runHook then
            events[#events + 1] = hook.hookId
        end

        if rejected then
            result.ok = false
            break
        end
    end

    result.size = #events

    return result
end


return lib.hook
