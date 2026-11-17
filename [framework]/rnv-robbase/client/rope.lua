-- A drawn rope: Verlet nodes held to length,
-- drawn with the rope piece whip_rope_seg, one per gap,
-- placed with SetEntityMatrix (client/mesh.lua Frames/Update). Trimmed to one rope with pinned points
--   local rope = RB.RopeNew(from, length)   -- hangs straight down from `from`
--   RB.RopePin(rope, i, pos) / RB.RopeUnpin(rope, i), RB.RopeStep(rope, dt, floorZ), RB.RopeDraw(rope), RB.RopeDelete(rope)

local LINK = 0.25          -- metres between nodes (= the model's own length)
local DAMPING = 0.99       -- per 1/60 s
local ITERATIONS = 16
local REF_DT = 1.0 / 60.0
local GRAVITY = vector3(0.0, 0.0, -9.8)
local MODEL = 'whip_rope_seg'

RB.RopeLink = LINK

local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local function cross(a, b) return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x) end

local function startRight(t)
    local r = cross(t, vector3(0.0, 0.0, 1.0))
    if #r < 1e-4 then r = cross(t, vector3(1.0, 0.0, 0.0)) end
    return r / #r
end

function RB.RopeNew(from, length)
    local count = math.max(2, math.floor(length / LINK) + 1)
    local rope = { nodes = {}, segs = {} }
    for i = 1, count do
        local p = from - vector3(0.0, 0.0, (i - 1) * LINK)
        rope.nodes[i] = { pos = p, prev = p, pinned = false }
    end
    local hash = RB.LoadModel(MODEL)
    for _ = 1, count - 1 do
        local prop = CreateObject(hash, from.x, from.y, from.z, false, false, false)
        SetEntityCollision(prop, false, false)
        FreezeEntityPosition(prop, true)
        SetEntityLodDist(prop, 500)
        rope.segs[#rope.segs + 1] = prop
    end
    return rope
end

function RB.RopePin(rope, i, pos)
    local n = rope.nodes[i]
    if not n then return end
    n.pinned = true
    n.pos = pos
    n.prev = pos
end

function RB.RopeUnpin(rope, i)
    if rope.nodes[i] then rope.nodes[i].pinned = false end
end

-- One step: Verlet with gravity, then the links pulled back to length (all of a stretch, 30% of a squash)
-- floorZ: free nodes never go below it
function RB.RopeStep(rope, dt, floorZ)
    local nodes = rope.nodes
    local count = #nodes
    local carry = math.min(math.max(dt / (rope.lastDt or dt), 0.5), 2.0) * (DAMPING ^ (dt / REF_DT))
    rope.lastDt = dt
    local g = GRAVITY * (dt * dt)
    for i = 1, count do
        local n = nodes[i]
        if not n.pinned then
            local v = (n.pos - n.prev) * carry
            n.prev = n.pos
            n.pos = n.pos + v + g
        end
    end
    for _ = 1, ITERATIONS do
        for i = 1, count - 1 do
            local a, b = nodes[i], nodes[i + 1]
            local delta = b.pos - a.pos
            local dist = #delta
            if dist > 0.001 then
                local k = (LINK - dist) / dist * (dist < LINK and 0.3 or 1.0)
                if not a.pinned and not b.pinned then
                    a.pos = a.pos - delta * (k * 0.5)
                    b.pos = b.pos + delta * (k * 0.5)
                elseif not a.pinned then
                    a.pos = a.pos - delta * k
                elseif not b.pinned then
                    b.pos = b.pos + delta * k
                end
            end
        end
    end
    if floorZ then
        for i = 1, count do
            local n = nodes[i]
            if not n.pinned and n.pos.z < floorZ + 0.05 then
                n.pos = vector3(n.pos.x, n.pos.y, floorZ + 0.05)
                n.prev = vector3(n.pos.x - (n.pos.x - n.prev.x) * 0.3, n.pos.y - (n.pos.y - n.prev.y) * 0.3, n.pos.z)
            end
        end
    end
end

-- Every piece onto its gap: centre between the nodes, +Y along the gap (scaled to its length), X/Z the
-- same thickness, roll carried on from piece to piece (rotation-minimising frame)
function RB.RopeDraw(rope)
    local nodes = rope.nodes
    local right, lastT = nil, vector3(0.0, 1.0, 0.0)
    for k, prop in ipairs(rope.segs) do
        local a, b = nodes[k].pos, nodes[k + 1].pos
        local d = b - a
        local len = #d
        local t = len > 1e-5 and d / len or lastT
        lastT = t
        if right then
            local r = right - t * dot(right, t)
            right = #r > 1e-4 and r / #r or startRight(t)
        else
            right = startRight(t)
        end
        local up = cross(right, t)
        local f = t * (len / LINK)
        local at = (a + b) * 0.5
        SetEntityMatrix(prop, f.x, f.y, f.z, right.x, right.y, right.z, up.x, up.y, up.z, at.x, at.y, at.z)
    end
end

function RB.RopeDelete(rope)
    for _, prop in ipairs(rope.segs) do
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end
    rope.segs = {}
end
