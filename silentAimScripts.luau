-- silentAimScripts.luau - Silent Aim Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local module = {}

local silentAimEnabled = false
local silentAimFOV = 200
local silentAimConnection = nil
local teamCheckEnabled = false
local wallCheckEnabled = false
local targetPartName = "Head"
local currentTarget = nil
local silentAimMaxDistance = 0

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

local function isVisible(targetChar, targetPart)
    if not wallCheckEnabled then
        return true
    end
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
    
    -- Hook into namecall for silent aim
    mt.__namecall = newcclosure(function(...)
        local args = {...}
        local self = args[1]
        local method = getnamecallmethod()
        
        if silentAimEnabled and method == "FireServer" or method == "InvokeServer" then
            -- Find target
            local target = getClosestPlayerToMouse()
            if target and target.Character then
                local targetPart = getTargetPart(target.Character)
                if targetPart then
                    -- Modify the arguments to redirect to target
                    -- This varies by game, but common patterns:
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = targetPart.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(targetPart.Position)
                        elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            args[i] = targetPart
                        end
                    end
                end
            end
        end
        
        return namecall(...)
    end)
    
    setreadonly(mt, true)
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
    
    -- Restore original namecall
    if oldNamecall then
        setreadonly(mt, false)
        mt.__namecall = namecall
        setreadonly(mt, true)
    end
end

return module
