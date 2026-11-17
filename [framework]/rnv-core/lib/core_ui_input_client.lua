local input



function lib.inputDialog(heading, rows, options)
    if input then return end
    input = promise.new()

    -- Old string rows still work (a copy is made, the caller's rows stay as they are)
    local normalized = table.create(#rows, 0)

    for i = 1, #rows do
        local row = rows[i]
        normalized[i] = type(row) == 'string'
            and { type = 'input', label = row }
            or row
    end

    lib.setNuiFocus(false)
    SendNUIMessage({
        action = 'openDialog',
        data = {
            heading = heading,
            rows = normalized,
            options = options
        }
    })

    return Citizen.Await(input)
end

function lib.closeInputDialog()
    if not input then return end

    lib.resetNuiFocus()
    SendNUIMessage({
        action = 'closeInputDialog'
    })

    input:resolve(nil)
    input = nil
end

RegisterNUICallback('inputData', function(data, cb)
    cb(1)
    lib.resetNuiFocus()

    local promise = input
    input = nil

    promise:resolve(data)
end)
