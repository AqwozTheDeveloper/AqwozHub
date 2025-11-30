-- silentAimScripts.luau - Silent Aim Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local function getCamera()
    return workspace.CurrentCamera
end
local LocalPlayer = Players.LocalPlayer

local module = {}

local silentAimEnabled = false
local silentAimFOV = 200
local silentAimMaxDistance = 0
local teamCheckEnabled = false
local targetPartName = "Head"
local maxAngleDeg = 180

-- Visuals
local fovCircleEnabled = false
local fovGui = nil
local fovFrame = nil
local fovStroke = nil
local fovConnection = nil
local fovColor = Color3.fromRGB(255, 0, 0) -- Red for Silent Aim to distinguish from Legit

local function ensureFOVGui()
    if fovGui and fovFrame then return true end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    if not pg then return false end
    
    -- Cleanup
    local old = pg:FindFirstChild("AqwozHubSilentFOV")
    if old then old:Destroy() end

    fovGui = Instance.new("ScreenGui")
    fovGui.Name = "AqwozHubSilentFOV"
    fovGui.IgnoreGuiInset = true
    fovGui.ResetOnSpawn = false
    fovGui.Parent = pg
    
    fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVCircle"
    fovFrame.BackgroundTransparency = 1
    fovFrame.Position = UDim2.fromOffset(0, 0)
    fovFrame.Size = UDim2.fromOffset(silentAimFOV * 2, silentAimFOV * 2)
    fovFrame.Parent = fovGui
    
    fovStroke = Instance.new("UIStroke")
    fovStroke.Thickness = 2
    fovStroke.Transparency = 0.3
    fovStroke.Color = fovColor
    fovStroke.Parent = fovFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovFrame
    
    return true
end

local function updateFOVCircle()
    if not fovCircleEnabled then return end
    if not fovGui or not fovFrame or not fovFrame.Parent then return end
    
    local mouse = UserInputService:GetMouseLocation()
    fovFrame.Size = UDim2.fromOffset(silentAimFOV * 2, silentAimFOV * 2)
    -- With AnchorPoint 0.5,0.5, we just set position to mouse coords
    fovFrame.Position = UDim2.fromOffset(mouse.X, mouse.Y)
end

local function getTargetPart(character)
    local part = character:FindFirstChild(targetPartName)
    if part then return part end
    
    -- R6 Compatibility
    if targetPartName == "UpperTorso" then
        local torso = character:FindFirstChild("Torso")
        if torso then return torso end
    end
    
    if targetPartName ~= "Head" then
        local fallback = character:FindFirstChild("Head")
        if fallback then return fallback end
    end
    return character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
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

                local camera = getCamera()
                if not camera then continue end
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)

                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                    -- Max distance check
                    if silentAimMaxDistance and silentAimMaxDistance > 0 then
                        local worldDist = (part.Position - camera.CFrame.Position).Magnitude
                        if worldDist > silentAimMaxDistance then
                            continue
                        end
                    end

                    -- Max angle check
                    local toTarget = (part.Position - camera.CFrame.Position).Unit
                    local angle = math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(toTarget), -1, 1)))
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
        if checkcaller() then return oldIndex(self, key) end
        if not silentAimEnabled then
            return oldIndex(self, key)
        end
        
        if self:IsA("Mouse") then
            local targetPos = getSilentAimTarget()
            if targetPos then
                local camera = getCamera()
                if not camera then
                    return oldIndex(self, key)
                end
                if key == "Hit" then
                    return CFrame.new(targetPos)
                elseif key == "Target" then
                    local target = getClosestPlayer()
                    if target and target.Character then
                        return getTargetPart(target.Character)
                    end
                elseif key == "UnitRay" then
                    local origin = camera.CFrame.Position
                    local direction = (targetPos - origin).Unit
                    return Ray.new(origin, direction)
                elseif key == "X" or key == "Y" then
                    local screenPos = camera:WorldToViewportPoint(targetPos)
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
        
        if checkcaller() then return oldNamecall(self, ...) end
        if not silentAimEnabled then
            return oldNamecall(self, ...)
        
        if 
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
        local camera = getCamera()
        if camera and self == camera then
            if method == "ViewportPointToRay" or method == "ScreenPointToRay" then
                local targetPos = getSilentAimTarget()
                if targetPos then
                    local origin = camera.CFrame.Position
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

function module.toggleFOVCircle(state)
    fovCircleEnabled = state and true or false
    if fovCircleEnabled then
        if ensureFOVGui() then
            fovFrame.Visible = true
            if not fovConnection then
                fovConnection = RunService.RenderStepped:Connect(updateFOVCircle)
            end
        end
    else
        if fovConnection then
            fovConnection:Disconnect()
            fovConnection = nil
        end
        if fovFrame then
            fovFrame.Visible = false
        end
    end
    print("[SilentAim] FOVCircle:", fovCircleEnabled)
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
    
    if fovConnection then
        fovConnection:Disconnect()
        fovConnection = nil
    end
    if fovGui then
        fovGui:Destroy()
        fovGui = nil
    end
    
    print("[SilentAim] Module destroyed")
end

return module
