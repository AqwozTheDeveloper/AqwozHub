local module = {}

function module.leadPosition(part, origin, speed)
    local v = Vector3.zero
    local p = part.Position
    if part.AssemblyLinearVelocity then
        v = part.AssemblyLinearVelocity
    end
    local s = tonumber(speed) or 0
    if s <= 0 then
        return p
    end
    local t = (p - origin).Magnitude / s
    return p + v * t
end

_G.AqwozAimUtils = module
return module
