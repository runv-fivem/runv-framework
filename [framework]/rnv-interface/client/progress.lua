-- Progress({ label, duration, canCancel, cancel }): blocks, false if cancelled

local busy = false

local function progress(data)
    if busy then return false end
    busy = true
    SendNUIMessage({ action = 'progress', label = data.label or '', duration = data.duration })

    local endAt = GetGameTimer() + data.duration
    local done = true
    while GetGameTimer() < endAt do
        if (data.canCancel and IsControlJustPressed(0, 73)) or (data.cancel and data.cancel()) then -- X
            done = false
            break
        end
        Wait(0)
    end

    SendNUIMessage({ action = 'progress:stop' })
    busy = false
    return done
end

exports('Progress', progress)
exports('IsBusy', function() return busy end)
