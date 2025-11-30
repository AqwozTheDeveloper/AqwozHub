-- silentAimScripts.luau - Silent Aim Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local module = {}

local silentAimEnabled = false
local silentAimFOV = 200
local silentAimMaxDistance = 0
local teamCheckEnabled = false
local targetPartName = "Head"
local maxAngleDeg = 180

local function getTargetPart(character)
    local part = character:FindFirstChild(targetPartName)
    if part then return part end
    if targetPartName ~= "Head" then
        local fallback = character:FindFirstChild("Head")
        if fallback then return fallback end
    end
    return character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
end

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = silentAimFOV

    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local part = getTargetPart(player.Character)

            if humanoid and humanoid.Health > 0 and part then
                -- Team check
                if teamCheckEnabled and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
                    continue
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                    -- Max distance check
                    if silentAimMaxDistance and silentAimMaxDistance > 0 then
                        local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
                        if worldDist > silentAimMaxDistance then
                            continue
                        end
                    end

                    -- Max angle check
                    local toTarget = (part.Position - Camera.CFrame.Position).Unit
                    local angle = math.deg(math.acos(math.clamp(Camera.CFrame.LookVector:Dot(toTarget), -1, 1)))
                    if angle > maxAngleDeg then
                        continue
                    end

                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Hook için kullanılacak fonksiyon
local function getSilentAimTarget()
    if not silentAimEnabled then return nil end
    
    local target = getClosestPlayer()
    if target and target.Character then
        local part = getTargetPart(target.Character)
        if part then
            return part.Position
        end
    end
    return nil
end

function module.init()
    print("[SilentAim] Module initialized - Rivals Edition")
    
    -- __index hook (Mouse.Hit, Mouse.Target, UnitRay)
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if not silentAimEnabled then
            return oldIndex(self, key)
        end
        
        if self:IsA("Mouse") then
            local targetPos = getSilentAimTarget()
            if targetPos then
                if key == "Hit" then
                    return CFrame.new(targetPos)
                elseif key == "Target" then
                    local target = getClosestPlayer()
                    if target and target.Character then
                        return getTargetPart(target.Character)
                    end
                elseif key == "UnitRay" then
                    local origin = Camera.CFrame.Position
                    local direction = (targetPos - origin).Unit
                    return Ray.new(origin, direction)
                elseif key == "X" or key == "Y" then
                    local screenPos = Camera:WorldToViewportPoint(targetPos)
                    return key == "X" and screenPos.X or screenPos.Y
                end
            end
        end
        
        return oldIndex(self, key)
    end))
    
    -- __namecall hook (Raycast, FindPartOnRay, FireServer)
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if not silentAimEnabled then
            return oldNamecall(self, ...)
        end
        
        -- Workspace Raycast hook
        if self == workspace then
            if method == "Raycast" then
                local targetPos = getSilentAimTarget()
                if targetPos and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                    local origin = args[1]
                    local newDirection = (targetPos - origin).Unit * args[2].Magnitude
                    return oldNamecall(self, origin, newDirection, args[3])
                end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                local targetPos = getSilentAimTarget()
                if targetPos and typeof(args[1]) == "Ray" then
                    local ray = args[1]
                    local newDir = (targetPos - ray.Origin).Unit * ray.Direction.Magnitude
                    args[1] = Ray.new(ray.Origin, newDir)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        
        -- Camera:WorldToScreenPoint / ViewportPointToRay hook
        if self == Camera then
            if method == "ViewportPointToRay" or method == "ScreenPointToRay" then
                local targetPos = getSilentAimTarget()
                if targetPos then
                    local origin = Camera.CFrame.Position
                    local direction = (targetPos - origin).Unit
                    return Ray.new(origin, direction)
                end
            end
        end
        
        return oldNamecall(self, ...)
    end))
    
    print("[SilentAim] Hooks installed successfully")
end

function module.toggleSilentAim(state)
    silentAimEnabled = state and true or false
    print("[SilentAim] Toggled:", silentAimEnabled)
end

function module.setFOV(value)
    silentAimFOV = math.max(1, tonumber(value) or silentAimFOV)
    print("[SilentAim] FOV set to:", silentAimFOV)
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state and true or false
    print("[SilentAim] TeamCheck:", teamCheckEnabled)
end

function module.setTargetPart(name)
    local allowed = {
        Head = true,
        UpperTorso = true
    }
    if type(name) == "string" and allowed[name] then
        targetPartName = name
    end
    print("[SilentAim] TargetPart:", targetPartName)
end

function module.setMaxAngle(deg)
    local v = tonumber(deg) or maxAngleDeg
    maxAngleDeg = math.clamp(v, 5, 180)
    print("[SilentAim] MaxAngle:", maxAngleDeg)
end

function module.setMaxDistance(value)
    local v = tonumber(value) or 0
    silentAimMaxDistance = math.max(0, v)
    print("[SilentAim] MaxDistance:", silentAimMaxDistance)
end

function module.destroy()
    silentAimEnabled = false
    print("[SilentAim] Module destroyed")
end

return module
