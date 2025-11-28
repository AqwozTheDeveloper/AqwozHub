-- aimbotScripts.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local module = {}

local aimbotEnabled = false
local aimbotFOV = 200
local aimbotConnection = nil
local aimbotSmoothing = 0.1
local teamCheckEnabled = false
local wallCheckEnabled = false
local silentAimEnabled = false
local namecallHooked = false
local originalNamecall = nil
local silentAimRequireMouse = false
local silentAimLead = 0.05
local silentAimHitPart = "Head"
local silentAimStickFrames = 6
local silentAimOnScreenOnly = true
local lastTarget = nil
local stickCounter = 0
local silentAimUpdateConn = nil
local aimHoldEnabled = false
local aimHoldKey = Enum.KeyCode.Q
local targetPriorityMode = "Mouse"
local fovCircleEnabled = false
local fovCircle = nil
local fovCircleConn = nil

-- En yakın oyuncuyu bul
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = aimbotFOV
    local bestWorldDist = math.huge
    local bestHealth = math.huge

    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            if humanoid and humanoid.Health > 0 and head then
                if teamCheckEnabled and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    
                else
                    local obstructed = false
                    if wallCheckEnabled then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = {LocalPlayer.Character}
                        local direction = head.Position - Camera.CFrame.Position
                        local result = workspace:Raycast(Camera.CFrame.Position, direction, params)
                        if result and not result.Instance:IsDescendantOf(player.Character) then
                            obstructed = true
                        end
                    end

                    if not obstructed then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if not silentAimOnScreenOnly or onScreen then
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if distance < shortestDistance then
                                if targetPriorityMode == "Mouse" then
                                    closestPlayer = player
                                    shortestDistance = distance
                                else
                                    local lpRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    local worldDist = lpRoot and (lpRoot.Position - head.Position).Magnitude or (Camera.CFrame.Position - head.Position).Magnitude
                                    local health = humanoid.Health
                                    if targetPriorityMode == "Distance" then
                                        if worldDist < bestWorldDist then
                                            bestWorldDist = worldDist
                                            closestPlayer = player
                                            shortestDistance = distance
                                        end
                                    elseif targetPriorityMode == "Health" then
                                        if health < bestHealth then
                                            bestHealth = health
                                            closestPlayer = player
                                            shortestDistance = distance
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Aimbot loop (Smooth)
local function aimbotLoop()
    if not aimbotEnabled or silentAimEnabled then return end
    if aimHoldEnabled and not UserInputService:IsKeyDown(aimHoldKey) then return end

    local target = getClosestPlayer()

    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")

        if head then
            -- Kamerayı hedefin kafasına yönlendir
            local targetCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, aimbotSmoothing)
        end
    end
end

function module.init()
    print("[Aimbot] Module initialized")
    if typeof(Drawing) == "table" and typeof(Drawing.new) == "function" then
        fovCircle = Drawing.new("Circle")
        fovCircle.Radius = aimbotFOV
        fovCircle.Thickness = 1
        fovCircle.Filled = false
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Visible = false
    end
end

function module.toggleAimbot(state)
    aimbotEnabled = state
    print("[Aimbot] Toggled:", state)

    if state then
        -- Aimbot açık
        if aimbotConnection then
            aimbotConnection:Disconnect()
        end

        aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
    else
        -- Aimbot kapalı
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end

function module.setFOV(value)
    aimbotFOV = value
    print("[Aimbot] FOV set to:", value)
    if fovCircle then
        fovCircle.Radius = value
    end
end

function module.setSmoothing(value)
    local alpha = math.clamp(value / 10, 0.01, 1)
    aimbotSmoothing = alpha
    print("[Aimbot] Smoothing set to:", alpha)
end

function module.destroy()
    aimbotEnabled = false

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state
    print("[Aimbot] TeamCheck:", state)
end

function module.toggleWallCheck(state)
    wallCheckEnabled = state
    print("[Aimbot] WallCheck:", state)
end

local function getAimPoint()
    local target = lastTarget or getClosestPlayer()
    if target and target.Character then
        local part = target.Character:FindFirstChild(silentAimHitPart)
        if not part then
            part = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("HumanoidRootPart")
        end
        if part then
            local pos = part.Position
            local root = target.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local vel = root.Velocity
                pos = pos + vel * silentAimLead
            end
            return pos
        end
    end
    return nil
end

local function ensureSilentAimHook()
    if namecallHooked then return end
    if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" and typeof(checkcaller) == "function" then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if silentAimEnabled and not checkcaller() then
                if silentAimRequireMouse and not UserInputService:IsMouseButtonPressed(Enum.MouseButton1) then
                    return old(self, ...)
                end
                if aimHoldEnabled and not UserInputService:IsKeyDown(aimHoldKey) then
                    return old(self, ...)
                end
                if method == "Raycast" then
                    local origin, direction, params = ...
                    if origin and direction then
                        local aim = getAimPoint()
                        if aim then
                            local newDirection = (aim - origin).Unit * direction.Magnitude
                            return old(self, origin, newDirection, params)
                        end
                    end
                elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local ray, a2, a3, a4 = ...
                    if ray and ray.Origin and ray.Direction then
                        local aim = getAimPoint()
                        if aim then
                            local newDirection = (aim - ray.Origin).Unit * ray.Direction.Magnitude
                            local newRay = Ray.new(ray.Origin, newDirection)
                            return old(self, newRay, a2, a3, a4)
                        end
                    end
                end
            end
            return old(self, ...)
        end)
        originalNamecall = old
        namecallHooked = true
        return
    end
    local mt = getrawmetatable and getrawmetatable(game)
    if mt and typeof(getnamecallmethod) == "function" and typeof(newcclosure) == "function" then
        local old = mt.__namecall
        if typeof(setreadonly) == "function" then setreadonly(mt, false) end
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if silentAimEnabled then
                if silentAimRequireMouse and not UserInputService:IsMouseButtonPressed(Enum.MouseButton1) then
                    return old(self, ...)
                end
                if aimHoldEnabled and not UserInputService:IsKeyDown(aimHoldKey) then
                    return old(self, ...)
                end
                if method == "Raycast" then
                    local origin, direction, params = ...
                    if origin and direction then
                        local aim = getAimPoint()
                        if aim then
                            local newDirection = (aim - origin).Unit * direction.Magnitude
                            return old(self, origin, newDirection, params)
                        end
                    end
                elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local ray, a2, a3, a4 = ...
                    if ray and ray.Origin and ray.Direction then
                        local aim = getAimPoint()
                        if aim then
                            local newDirection = (aim - ray.Origin).Unit * ray.Direction.Magnitude
                            local newRay = Ray.new(ray.Origin, newDirection)
                            return old(self, newRay, a2, a3, a4)
                        end
                    end
                end
            end
            return old(self, ...)
        end)
        if typeof(setreadonly) == "function" then setreadonly(mt, true) end
        originalNamecall = old
        namecallHooked = true
    end
end

function module.toggleSilentAim(state)
    silentAimEnabled = state
    print("[Aimbot] SilentAim:", state)
    if state then
        ensureSilentAimHook()
        if silentAimUpdateConn then silentAimUpdateConn:Disconnect() end
        silentAimUpdateConn = RunService.RenderStepped:Connect(function()
            local current = getClosestPlayer()
            if current then
                if current ~= lastTarget then
                    lastTarget = current
                    stickCounter = silentAimStickFrames
                elseif stickCounter > 0 then
                    stickCounter = stickCounter - 1
                end
            else
                lastTarget = nil
                stickCounter = 0
            end
        end)
    else
        if silentAimUpdateConn then
            silentAimUpdateConn:Disconnect()
            silentAimUpdateConn = nil
        end
        lastTarget = nil
        stickCounter = 0
    end
end

function module.toggleSilentAimRequireMouse(state)
    silentAimRequireMouse = state
    print("[Aimbot] SilentAim require LMB:", state)
end

function module.setSilentAimLeadMs(ms)
    silentAimLead = math.clamp((ms or 0) / 1000, 0, 0.3)
    print("[Aimbot] SilentAim lead:", silentAimLead)
end

function module.setSilentAimHitPart(part)
    if type(part) == "string" and #part > 0 then
        silentAimHitPart = part
        print("[Aimbot] SilentAim hit part:", part)
    end
end

function module.setSilentAimStickiness(frames)
    silentAimStickFrames = math.clamp(frames or 0, 0, 30)
    print("[Aimbot] SilentAim stickiness frames:", silentAimStickFrames)
end

function module.toggleSilentAimOnScreenOnly(state)
    silentAimOnScreenOnly = state
    print("[Aimbot] SilentAim on-screen only:", state)
end

function module.setAimHoldEnabled(state)
    aimHoldEnabled = state
    print("[Aimbot] Aim hold enabled:", state)
end

function module.setAimHoldKey(key)
    local map = Enum.KeyCode
    local kc = map[key] or map.Q
    aimHoldKey = kc
    print("[Aimbot] Aim hold key:", key)
end

function module.setTargetPriority(mode)
    if mode == "Mouse" or mode == "Distance" or mode == "Health" then
        targetPriorityMode = mode
        print("[Aimbot] Target priority:", mode)
    end
end

function module.toggleFOVCircle(state)
    fovCircleEnabled = state
    print("[Aimbot] FOV circle:", state)
    if not fovCircle then return end
    if state then
        if fovCircleConn then fovCircleConn:Disconnect() end
        fovCircle.Visible = true
        fovCircleConn = RunService.RenderStepped:Connect(function()
            local m = UserInputService:GetMouseLocation()
            fovCircle.Position = Vector2.new(m.X, m.Y)
        end)
    else
        if fovCircleConn then fovCircleConn:Disconnect() end
        fovCircle.Visible = false
    end
end

return module
