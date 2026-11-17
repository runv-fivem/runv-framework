-- head names: party = dot + name, others "Unknown"; colour by role

local RANGE, PARTY_RANGE = 40.0, 150.0
local mates = {} -- server id -> { name, color }
local sent = false

AddEventHandler('rnv-party:client:updated', function(party)
    mates = {}
    for _, m in ipairs(party and party.members or {}) do mates[m.id] = { name = m.name, color = m.color } end
end)

CreateThread(function()
    while true do
        local tags = {}
        if LocalPlayer.state['rnv:spawned'] and not IsPauseMenuActive() and not LocalPlayer.state['rnv:screen'] and not LocalPlayer.state['rnv:map'] then
            local me = PlayerPedId()
            local myPos = GetEntityCoords(me)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if ped ~= me and IsEntityVisible(ped) then
                    local id = GetPlayerServerId(player)
                    local mate = mates[id]
                    local dist = #(GetEntityCoords(ped) - myPos)
                    if dist < (mate and PARTY_RANGE or RANGE) and (mate or HasEntityClearLosToEntity(me, ped, 17)) then
                        local head = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0) -- SKEL_Head
                        local onScreen, x, y = GetScreenCoordFromWorldCoord(head.x, head.y, head.z + 0.35)
                        if onScreen then
                            tags[#tags + 1] = {
                                x = x * 100, y = y * 100,
                                name = mate and mate.name or 'Unknown',
                                dot = mate and mate.color or false,
                                role = Player(id).state['rnv:role'] or 'civilian',
                            }
                        end
                    end
                end
            end
        end
        if #tags > 0 or sent then
            SendNUIMessage({ action = 'tags', tags = tags })
            sent = #tags > 0
        end
        Wait(#tags > 0 and 0 or 250)
    end
end)
