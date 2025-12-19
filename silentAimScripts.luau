-- silentAimScripts.luau - Silent Aim Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
-- local Camera = workspace.CurrentCamera -- Removed
local LocalPlayer = Players.LocalPlayer

local module = {}

local function getCamera()
    return workspace.CurrentCamera
end

local silentAimEnabled = false
local silentAimFOV = 200
local silentAimConnection = nil
local teamCheckEnabled = false
local wallCheckEnabled = false
local targetPartName = "Head"
local currentTarget = nil
local silentAimMaxDistance = 0
local fovCircleEnabled = false
local predictionEnabled = false
local predictionMultiplier = 1.0

local fovGui = nil
local fovFrame = nil
local fovConnection = nil
local fovStroke = nil
local fovDefaultColor = Color3.fromRGB(255, 0, 0)
local fovLockedColor = Color3.fromRGB(255, 100, 100)

-- Namecall hook for silent aim
local oldNamecall
local mt = getrawmetatable(game)
local namecall = mt.__namecall
setreadonly(mt, false)

local function getTargetPart(character)
    local part = character:FindFirstChild(targetPartName)
    if part then return part end
    if targetPartName ~= "Head" then
        local fallback = character:FindFirstChild("Head")
        if fallback then return fallback end
    end
    return character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
end

local function getPredictedPosition(part)
    if not predictionEnabled or not part then return part.Position end
    local Camera = getCamera()
    if not Camera then return part.Position end
    local velocity = part.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
    local distance = (part.Position - Camera.CFrame.Position).Magnitude
    local timeToReach = distance / 1000 -- Approximate bullet speed
    return part.Position + (velocity * timeToReach * predictionMultiplier)
end

local function isVisible(targetChar, targetPart)
    if not wallCheckEnabled then
        return true
    end
    local Camera = workspace.CurrentCamera
    if not Camera then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, params)
    if not result then
        return true
    end
    return result.Instance and result.Instance:IsDescendantOf(targetChar)
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = silentAimFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    local Camera = workspace.CurrentCamera
    if not Camera then return nil end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local part = getTargetPart(player.Character)

            if humanoid and humanoid.Health > 0 and part then
                if teamCheckEnabled and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
                    -- Skip teammates
                else
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

                    if onScreen and isVisible(player.Character, part) then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        if silentAimMaxDistance and silentAimMaxDistance > 0 then
                            local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
                            if worldDist > silentAimMaxDistance then
                                distance = math.huge
                            end
                        end
                        
                        if distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

function module.init()
    print("[SilentAim] Module initialized")
    
    -- Check if required metatable functions exist
    if not getrawmetatable or not getnamecallmethod or not setreadonly then
        warn("[SilentAim] Critical: Executor does not support required metatable functions")
        warn("[SilentAim] Silent aim will NOT work on this executor")
        return
    end
    
    -- Use hookmetamethod if available (Modern/Better)
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if silentAimEnabled and (method == "FireServer" or method == "InvokeServer") then
                -- Debug: Check if hook fires
                -- print("[SilentAim] FireServer detected") 
                
                local target = getClosestPlayerToMouse()
                if target and target.Character then
                    print("[SilentAim] Target found:", target.Name)
                    local targetPart = getTargetPart(target.Character)
                    if targetPart then
                        local aimPos = getPredictedPosition(targetPart)
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" then
                                print("[SilentAim] Modifying Vector3 arg")
                                args[i] = aimPos
                            elseif typeof(arg) == "CFrame" then
                                print("[SilentAim] Modifying CFrame arg")
                                args[i] = CFrame.new(aimPos)
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                else
                    -- print("[SilentAim] No target in FOV")
                end
            end
            
            return oldNamecall(self, ...)
        end)
        print("[SilentAim] Hooked using hookmetamethod")
    else
        -- Fallback to old metatable hook
        local string_lower = string.lower
        local hookFunction = function(...)
            local args = {...}
            local self = args[1]
            local method = getnamecallmethod()
            
            if silentAimEnabled and (method == "FireServer" or method == "InvokeServer") then
                local target = getClosestPlayerToMouse()
                if target and target.Character then
                    print("[SilentAim] Target found:", target.Name)
                    if targetPart then
                        -- Calculate predicted position
                        local aimPos = getPredictedPosition(targetPart)
                        
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" then
                                print("[SilentAim] Modifying Vector3 arg")
                                args[i] = aimPos
                            elseif typeof(arg) == "CFrame" then
                                print("[SilentAim] Modifying CFrame arg")
                                args[i] = CFrame.new(aimPos)
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end
                 return namecall(unpack(args))
            end
            
            return namecall(...)
        end
        
        if newcclosure then
            mt.__namecall = newcclosure(hookFunction)
        else
            mt.__namecall = hookFunction
        end
        print("[SilentAim] Hooked using mt.__namecall")
    end
    
    setreadonly(mt, true)
    print("[SilentAim] Namecall hook installed successfully")
end

function module.toggleSilentAim(state)
    silentAimEnabled = state
    print("[SilentAim] Toggled:", state)
    
    if state then
        -- Update loop to track current target
        if silentAimConnection then
            silentAimConnection:Disconnect()
        end
        silentAimConnection = RunService.RenderStepped:Connect(function()
            currentTarget = getClosestPlayerToMouse()
        end)
    else
        if silentAimConnection then
            silentAimConnection:Disconnect()
            silentAimConnection = nil
        end
        currentTarget = nil
    end
end

function module.setFOV(value)
    silentAimFOV = math.max(1, tonumber(value) or silentAimFOV)
    print("[SilentAim] FOV set to:", value)
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state and true or false
    print("[SilentAim] TeamCheck:", teamCheckEnabled)
end

function module.toggleWallCheck(state)
    wallCheckEnabled = state and true or false
    print("[SilentAim] WallCheck:", wallCheckEnabled)
end

function module.setTargetPart(name)
    local allowed = {
        Head = true,
        UpperTorso = true,
        Torso = true,
        HumanoidRootPart = true
    }
    if type(name) == "string" and allowed[name] then
        targetPartName = name
    end
    print("[SilentAim] TargetPart:", targetPartName)
end

function module.togglePrediction(state)
    predictionEnabled = state
    print("[SilentAim] Prediction:", state)
end

function module.setPredictionMultiplier(value)
    predictionMultiplier = tonumber(value) or 1
    print("[SilentAim] Pred Mult:", predictionMultiplier)
end

local function ensureFOVGui()
    if fovGui and fovFrame then return true end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    if not pg then return false end
    fovGui = Instance.new("ScreenGui")
    fovGui.Name = "SilentAimFOV"
    fovGui.IgnoreGuiInset = true
    fovGui.ResetOnSpawn = false
    fovGui.Parent = pg
    fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVCircle"
    fovFrame.BackgroundTransparency = 1
    fovFrame.Position = UDim2.fromOffset(0, 0)
    fovFrame.Size = UDim2.fromOffset(silentAimFOV * 2, silentAimFOV * 2)
    fovFrame.ZIndex = 100
    fovFrame.Parent = fovGui
    fovStroke = Instance.new("UIStroke")
    fovStroke.Thickness = 2
    fovStroke.Transparency = 0.3
    fovStroke.Color = fovDefaultColor
    fovStroke.Parent = fovFrame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovFrame
    return true
end

local function updateFOVCircle()
    if not fovCircleEnabled then return end
    if not fovGui or not fovFrame then return end
    local mouse = UserInputService:GetMouseLocation()
    fovFrame.Size = UDim2.fromOffset(silentAimFOV * 2, silentAimFOV * 2)
    fovFrame.Position = UDim2.fromOffset(mouse.X - silentAimFOV, mouse.Y - silentAimFOV)
    if fovStroke then
        if currentTarget then
            fovStroke.Color = fovLockedColor
        else
            fovStroke.Color = fovDefaultColor
        end
    end
end

function module.toggleFOVCircle(state)
    fovCircleEnabled = state and true or false
    print("[SilentAim] FOVCircle:", fovCircleEnabled)
    if fovCircleEnabled then
        if ensureFOVGui() then
            fovFrame.Visible = true
            updateFOVCircle()
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
end

function module.setMaxDistance(value)
    local v = tonumber(value) or 0
    silentAimMaxDistance = math.max(0, v)
    print("[SilentAim] MaxDistance:", silentAimMaxDistance)
end

function module.getCurrentTarget()
    return currentTarget
end

function module.destroy()
    silentAimEnabled = false
    
    if silentAimConnection then
        silentAimConnection:Disconnect()
        silentAimConnection = nil
    end
    
    if fovConnection then
        fovConnection:Disconnect()
        fovConnection = nil
    end
    
    if fovGui then
        fovGui:Destroy()
        fovGui = nil
        fovFrame = nil
    end
    
    -- Restore original namecall
    if oldNamecall then
        setreadonly(mt, false)
        mt.__namecall = namecall
        setreadonly(mt, true)
    end
end

return module
