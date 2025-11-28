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
local dynamicSmoothingEnabled = false
local aimbotMaxDistance = 0
local currentTarget = nil
local teamCheckEnabled = true
local friendExcludeEnabled = false
local wallCheckEnabled = false
local aimHoldEnabled = false
local aimHoldActive = false
local inputBeganConn = nil
local inputEndedConn = nil
local toggleKeyEnabled = false
local toggleKeyCode = Enum.KeyCode.F
local fovCircleEnabled = false
local fovGui = nil
local fovFrame = nil
local fovConnection = nil
local fovStroke = nil
local fovDefaultColor = Color3.fromRGB(255, 255, 255)
local fovLockedColor = Color3.fromRGB(0, 255, 100)
local pointerLockEnabled = false
local pointerFrame = nil
local pointerConnection = nil
local pointerADSOnlyEnabled = false
local debugEnabled = false
local debugGui = nil
local debugLabel = nil
local debugConnection = nil
local leadEnabled = false
local projectileSpeed = 0
local stickyLockMs = 200
local lastSeenTime = 0
local snapAngleDeg = 6
local maxTurnRateDeg = 0
local aimCurveMode = "Linear"
local adsOnlyLockEnabled = false
local priorityWeightedEnabled = false
local angleWeight = 0.5
local pixelWeight = 1.0
local distanceWeight = 0.2
local blacklistEnabled = false
local blacklist = {}

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

-- En yakın oyuncuyu bul
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = aimbotFOV

    local mousePos = UserInputService:GetMouseLocation()

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

    local function isTeammate(player)
        local lpTeam = LocalPlayer.Team
        local pTeam = player.Team
        if lpTeam and pTeam then
            if pTeam == lpTeam then return true end
        end
        local lpColor = LocalPlayer.TeamColor
        local pColor = player.TeamColor
        if lpColor and pColor then
            if lpColor == pColor then return true end
        end
        return false
    end

    local function isFriend(player)
        local ok, res = pcall(function()
            return LocalPlayer:IsFriendsWith(player.UserId)
        end)
        return ok and res == true
    end

    local function isValidPlayer(player)
        if player == LocalPlayer or not player.Character then return false end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local part = getTargetPart(player.Character)
        if not humanoid or humanoid.Health <= 0 or not part then return false end
        if teamCheckEnabled and isTeammate(player) then return false end
        if friendExcludeEnabled and isFriend(player) then return false end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen or not isVisible(player.Character, part) then return false end
        local distancePixels = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if distancePixels >= shortestDistance then return false end
        if aimbotMaxDistance and aimbotMaxDistance > 0 then
            local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
            if worldDist > aimbotMaxDistance then return false end
        end
        return true
    end

    local function isSeen(player)
        if not player or not player.Character then return false end
        local part = getTargetPart(player.Character)
        if not part then return false end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then return false end
        return isVisible(player.Character, part)
    end

    if currentTarget then
        if teamCheckEnabled and isTeammate(currentTarget) then
            currentTarget = nil
        elseif friendExcludeEnabled and isFriend(currentTarget) then
            currentTarget = nil
        end
        if isSeen(currentTarget) then
            lastSeenTime = tick()
            return currentTarget
        elseif stickyLockMs > 0 and (tick() - lastSeenTime) * 1000 < stickyLockMs then
            return currentTarget
        end
    end

    local bestScore = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local part = getTargetPart(player.Character)

            if humanoid and humanoid.Health > 0 and part then
                if teamCheckEnabled and isTeammate(player) then
                    
                else
                    if friendExcludeEnabled and isFriend(player) then
                        
                    else
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

                    if onScreen and isVisible(player.Character, part) then
                        if blacklistEnabled and blacklist[player.Name] then
                            
                        else
                            if priorityWeightedEnabled then
                                local px = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                local wd = (part.Position - Camera.CFrame.Position).Magnitude
                                if aimbotMaxDistance and aimbotMaxDistance > 0 and wd > aimbotMaxDistance then
                                    px = math.huge
                                    wd = math.huge
                                end
                                local toTarget = (part.Position - Camera.CFrame.Position).Unit
                                local ang = math.deg(math.acos(math.clamp(Camera.CFrame.LookVector:Dot(toTarget), -1, 1)))
                                local score = ang * angleWeight + px * pixelWeight + wd * distanceWeight
                                if score < bestScore then
                                    bestScore = score
                                    closestPlayer = player
                                end
                            else
                                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                if aimbotMaxDistance and aimbotMaxDistance > 0 then
                                    local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
                                    if worldDist > aimbotMaxDistance then
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
            end
        end
    end

    return closestPlayer
end

local function getClosestOnScreenToCenter()
    local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    local best = nil
    local bestDist = math.huge

    local function isVisible(targetChar, targetPart)
        if not wallCheckEnabled then return true end
        local origin = Camera.CFrame.Position
        local direction = (targetPart.Position - origin)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        local result = workspace:Raycast(origin, direction, params)
        if not result then return true end
        return result.Instance and result.Instance:IsDescendantOf(targetChar)
    end

    local function isTeammate(player)
        local lpTeam = LocalPlayer.Team
        local pTeam = player.Team
        if lpTeam and pTeam and pTeam == lpTeam then return true end
        local lpColor = LocalPlayer.TeamColor
        local pColor = player.TeamColor
        if lpColor and pColor and lpColor == pColor then return true end
        return false
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if teamCheckEnabled and isTeammate(player) then
            else
                local head = player.Character:FindFirstChild("Head")
                local part = head or getTargetPart(player.Character)
                if part then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen and isVisible(player.Character, part) then
                            local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
                            if aimbotMaxDistance and aimbotMaxDistance > 0 and worldDist > aimbotMaxDistance then
                            else
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    best = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Aimbot loop (Smooth)
local function aimbotLoop()
    if not aimbotEnabled then return end
    if aimHoldEnabled and not aimHoldActive then return end
    if adsOnlyLockEnabled and not aimHoldActive then return end

    local target = getClosestPlayer()

    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        local part
        if aimHoldActive and head then
            part = head
        else
            part = getTargetPart(target.Character)
        end

        if part then
            local pos = part.Position
            if leadEnabled and projectileSpeed > 0 and _G and _G.AqwozAimUtils then
                pos = _G.AqwozAimUtils.leadPosition(part, Camera.CFrame.Position, projectileSpeed)
            end
            local toTarget = (pos - Camera.CFrame.Position).Unit
            local angle = math.deg(math.acos(math.clamp(Camera.CFrame.LookVector:Dot(toTarget), -1, 1)))
            if angle > maxAngleDeg then return end
            if angle <= snapAngleDeg then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, pos)
            else
                local factor = aimbotSmoothing
                if dynamicSmoothingEnabled and maxAngleDeg > 0 then
                    local ratio = math.clamp(angle / maxAngleDeg, 0.2, 1)
                    factor = math.clamp(aimbotSmoothing * ratio, 0.01, 1)
                end
                if maxTurnRateDeg and maxTurnRateDeg > 0 and angle > 0 then
                    factor = math.min(factor, maxTurnRateDeg / angle)
                end
                local targetCFrame = CFrame.new(Camera.CFrame.Position, pos)
                local t = math.clamp(factor, 0, 1)
                if aimCurveMode == "EaseIn" then
                    t = t * t
                elseif aimCurveMode == "EaseOut" then
                    local u = 1 - t
                    t = 1 - (u * u)
                elseif aimCurveMode == "EaseInOut" then
                    if t < 0.5 then
                        t = 2 * t * t
                    else
                        local u = 1 - t
                        t = 1 - 2 * u * u
                    end
                end
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, t)
            end
            currentTarget = target
            lastSeenTime = tick()
        end
    else
        currentTarget = nil
    end
end

function module.init()
    print("[Aimbot] Module initialized")
    if not inputBeganConn then
        inputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                aimHoldActive = true
            elseif input.KeyCode == toggleKeyCode then
                if toggleKeyEnabled then
                    module.toggleAimbot(not aimbotEnabled)
                end
            end
        end)
    end
    if not inputEndedConn then
        inputEndedConn = UserInputService.InputEnded:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                aimHoldActive = false
            end
        end)
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
    aimbotFOV = math.max(1, tonumber(value) or aimbotFOV)
    print("[Aimbot] FOV set to:", value)
end

function module.setSmoothing(value)
    local v = tonumber(value) or 1
    aimbotSmoothing = math.clamp(v / 10, 0.05, 1)
    print("[Aimbot] Smoothing set to:", value)
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state and true or false
    print("[Aimbot] TeamCheck:", teamCheckEnabled)
end

function module.toggleWallCheck(state)
    wallCheckEnabled = state and true or false
    print("[Aimbot] WallCheck:", wallCheckEnabled)
end

function module.toggleHoldToAim(state)
    aimHoldEnabled = state and true or false
    print("[Aimbot] HoldToAim:", aimHoldEnabled)
end

function module.toggleKeyToggle(state)
    toggleKeyEnabled = state and true or false
    print("[Aimbot] KeyToggle:", toggleKeyEnabled, "Key:", tostring(toggleKeyCode))
end

function module.setToggleKey(key)
    local newKey = toggleKeyCode
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        newKey = key
    elseif type(key) == "string" and Enum.KeyCode[key] then
        newKey = Enum.KeyCode[key]
    end
    toggleKeyCode = newKey
    print("[Aimbot] Toggle key set to:", tostring(toggleKeyCode))
end

function module.setTargetPart(name)
    local allowed = {
        Head = true,
        UpperTorso = true
    }
    if type(name) == "string" and allowed[name] then
        targetPartName = name
    end
    print("[Aimbot] TargetPart:", targetPartName)
end

function module.setMaxAngle(deg)
    local v = tonumber(deg) or maxAngleDeg
    maxAngleDeg = math.clamp(v, 5, 180)
    print("[Aimbot] MaxAngle:", maxAngleDeg)
end

local function ensureFOVGui()
    if fovGui and fovFrame then return true end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    if not pg then return false end
    fovGui = Instance.new("ScreenGui")
    fovGui.Name = "AqwozHubFOV"
    fovGui.IgnoreGuiInset = true
    fovGui.ResetOnSpawn = false
    fovGui.Parent = pg
    fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVCircle"
    fovFrame.BackgroundTransparency = 1
    fovFrame.Position = UDim2.fromOffset(0, 0)
    fovFrame.Size = UDim2.fromOffset(aimbotFOV * 2, aimbotFOV * 2)
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
    pointerFrame = Instance.new("Frame")
    pointerFrame.Name = "PointerDot"
    pointerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pointerFrame.BackgroundTransparency = 0
    pointerFrame.Size = UDim2.fromOffset(6, 6)
    pointerFrame.Position = UDim2.fromOffset(0, 0)
    pointerFrame.ZIndex = 101
    pointerFrame.Visible = false
    pointerFrame.Parent = fovGui
    local pcorner = Instance.new("UICorner")
    pcorner.CornerRadius = UDim.new(1, 0)
    pcorner.Parent = pointerFrame
    return true
end

local function updateFOVCircle()
    if not fovCircleEnabled then return end
    if not fovGui or not fovFrame then return end
    local mouse = UserInputService:GetMouseLocation()
    fovFrame.Size = UDim2.fromOffset(aimbotFOV * 2, aimbotFOV * 2)
    fovFrame.Position = UDim2.fromOffset(mouse.X - aimbotFOV, mouse.Y - aimbotFOV)
    if fovStroke then
        if currentTarget then
            fovStroke.Color = fovLockedColor
        else
            fovStroke.Color = fovDefaultColor
        end
    end
end

local function updatePointerDot()
    if not pointerLockEnabled then return end
    if not pointerFrame or not fovGui then return end
    if pointerADSOnlyEnabled and not aimHoldActive then
        pointerFrame.Visible = false
        return
    else
        pointerFrame.Visible = true
    end
    local pos
    local targetPlayer = currentTarget or getClosestOnScreenToCenter()
    if targetPlayer and targetPlayer.Character then
        local head = targetPlayer.Character:FindFirstChild("Head")
        local part = head or getTargetPart(targetPlayer.Character)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                pos = Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    end
    if not pos then
        local mouse = UserInputService:GetMouseLocation()
        pos = Vector2.new(mouse.X, mouse.Y)
    end
    pointerFrame.Position = UDim2.fromOffset(pos.X - 3, pos.Y - 3)
end

function module.toggleFOVCircle(state)
    fovCircleEnabled = state and true or false
    print("[Aimbot] FOVCircle:", fovCircleEnabled)
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

function module.togglePointerLock(state)
    pointerLockEnabled = state and true or false
    if pointerLockEnabled then
        if ensureFOVGui() then
            pointerFrame.Visible = true
            UserInputService.MouseIconEnabled = false
            module.setTargetPart("Head")
            updatePointerDot()
            if not pointerConnection then
                pointerConnection = RunService.RenderStepped:Connect(updatePointerDot)
            end
        end
    else
        if pointerConnection then
            pointerConnection:Disconnect()
            pointerConnection = nil
        end
        if pointerFrame then
            pointerFrame.Visible = false
        end
        UserInputService.MouseIconEnabled = true
    end
    print("[Aimbot] PointerLock:", pointerLockEnabled)
end

function module.togglePointerADSOnly(state)
    pointerADSOnlyEnabled = state and true or false
    print("[Aimbot] PointerADSOnly:", pointerADSOnlyEnabled)
end

function module.toggleLead(state)
    leadEnabled = state and true or false
    print("[Aimbot] Lead:", leadEnabled)
end

function module.setProjectileSpeed(value)
    local v = tonumber(value) or 0
    projectileSpeed = math.max(0, v)
    print("[Aimbot] ProjectileSpeed:", projectileSpeed)
end

function module.setStickyLockMs(value)
    local v = tonumber(value) or stickyLockMs
    stickyLockMs = math.clamp(v, 0, 2000)
    print("[Aimbot] StickyLockMs:", stickyLockMs)
end

function module.setSnapAngle(deg)
    local v = tonumber(deg) or snapAngleDeg
    snapAngleDeg = math.clamp(v, 0, 30)
    print("[Aimbot] SnapAngle:", snapAngleDeg)
end

function module.setMaxTurnRateDeg(deg)
    local v = tonumber(deg) or maxTurnRateDeg
    maxTurnRateDeg = math.clamp(v, 0, 90)
    print("[Aimbot] MaxTurnRateDeg:", maxTurnRateDeg)
end

function module.setAimCurve(mode)
    local allowed = { Linear = true, EaseIn = true, EaseOut = true, EaseInOut = true }
    if type(mode) == "string" and allowed[mode] then
        aimCurveMode = mode
    end
    print("[Aimbot] AimCurve:", aimCurveMode)
end

function module.toggleADSOnlyLock(state)
    adsOnlyLockEnabled = state and true or false
    print("[Aimbot] ADSOnlyLock:", adsOnlyLockEnabled)
end

function module.toggleFriendExclude(state)
    friendExcludeEnabled = state and true or false
    print("[Aimbot] FriendExclude:", friendExcludeEnabled)
end

function module.togglePriorityWeighted(state)
    priorityWeightedEnabled = state and true or false
    print("[Aimbot] WeightedPriority:", priorityWeightedEnabled)
end

function module.setAngleWeight(value)
    local v = tonumber(value) or angleWeight
    angleWeight = math.clamp(v, 0, 2)
    print("[Aimbot] AngleWeight:", angleWeight)
end

function module.setPixelWeight(value)
    local v = tonumber(value) or pixelWeight
    pixelWeight = math.clamp(v, 0, 2)
    print("[Aimbot] PixelWeight:", pixelWeight)
end

function module.setDistanceWeight(value)
    local v = tonumber(value) or distanceWeight
    distanceWeight = math.clamp(v, 0, 2)
    print("[Aimbot] DistanceWeight:", distanceWeight)
end

function module.toggleBlacklist(state)
    blacklistEnabled = state and true or false
    print("[Aimbot] BlacklistEnabled:", blacklistEnabled)
end

function module.blacklistCurrentTarget()
    if currentTarget and currentTarget.Name then
        blacklist[currentTarget.Name] = true
        print("[Aimbot] Blacklisted:", currentTarget.Name)
    end
end

function module.blacklistClear()
    blacklist = {}
    print("[Aimbot] Blacklist cleared")
end

function module.setFOVCircleColor(name)
    local map = {
        White = Color3.fromRGB(255, 255, 255),
        Green = Color3.fromRGB(0, 255, 100),
        Red = Color3.fromRGB(255, 60, 60),
        Blue = Color3.fromRGB(80, 160, 255)
    }
    local c = map[name] or fovDefaultColor
    fovDefaultColor = c
    if fovStroke then fovStroke.Color = c end
end

function module.setFOVStrokeThickness(value)
    local v = tonumber(value) or 2
    v = math.clamp(v, 1, 6)
    if fovStroke then fovStroke.Thickness = v end
end

function module.setPointerSize(value)
    local v = tonumber(value) or 6
    v = math.clamp(v, 2, 24)
    if pointerFrame then pointerFrame.Size = UDim2.fromOffset(v, v) end
end

function module.setPointerColor(name)
    local map = {
        White = Color3.fromRGB(255, 255, 255),
        Green = Color3.fromRGB(0, 255, 100),
        Red = Color3.fromRGB(255, 60, 60),
        Blue = Color3.fromRGB(80, 160, 255)
    }
    local c = map[name] or Color3.fromRGB(255, 255, 255)
    if pointerFrame then pointerFrame.BackgroundColor3 = c end
end

local function ensureDebugGui()
    if debugGui and debugLabel then return true end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    if not pg then return false end
    debugGui = Instance.new("ScreenGui")
    debugGui.Name = "AqwozHubDebug"
    debugGui.IgnoreGuiInset = true
    debugGui.ResetOnSpawn = false
    debugGui.Parent = pg
    debugLabel = Instance.new("TextLabel")
    debugLabel.Name = "DebugLabel"
    debugLabel.BackgroundTransparency = 0.4
    debugLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    debugLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    debugLabel.Size = UDim2.fromOffset(220, 70)
    debugLabel.Position = UDim2.fromOffset(20, 20)
    debugLabel.TextScaled = false
    debugLabel.Font = Enum.Font.Code
    debugLabel.Text = ""
    debugLabel.ZIndex = 200
    debugLabel.Parent = debugGui
    return true
end

local function updateDebugOverlay()
    if not debugEnabled then return end
    if not ensureDebugGui() then return end
    local info = ""
    if currentTarget and currentTarget.Character then
        local part = getTargetPart(currentTarget.Character)
        if part then
            local toTarget = (part.Position - Camera.CFrame.Position).Unit
            local angle = math.deg(math.acos(math.clamp(Camera.CFrame.LookVector:Dot(toTarget), -1, 1)))
            local dist = (part.Position - Camera.CFrame.Position).Magnitude
            info = string.format("Target: %s\nAngle: %.1f\nDist: %.1f", currentTarget.Name, angle, dist)
        end
    else
        info = "No target"
    end
    debugLabel.Text = info
end

function module.toggleDebug(state)
    debugEnabled = state and true or false
    if debugEnabled then
        if ensureDebugGui() then
            updateDebugOverlay()
            if not debugConnection then
                debugConnection = RunService.RenderStepped:Connect(updateDebugOverlay)
            end
        end
    else
        if debugConnection then
            debugConnection:Disconnect()
            debugConnection = nil
        end
        if debugGui then
            debugGui:Destroy()
            debugGui = nil
            debugLabel = nil
        end
    end
    print("[Aimbot] Debug:", debugEnabled)
end

function module.setMaxDistance(value)
    local v = tonumber(value) or 0
    aimbotMaxDistance = math.max(0, v)
    print("[Aimbot] MaxDistance:", aimbotMaxDistance)
end

function module.toggleDynamicSmoothing(state)
    dynamicSmoothingEnabled = state and true or false
    print("[Aimbot] DynamicSmoothing:", dynamicSmoothingEnabled)
end

function module.destroy()
    aimbotEnabled = false

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    if inputBeganConn then
        inputBeganConn:Disconnect()
        inputBeganConn = nil
    end
    if inputEndedConn then
        inputEndedConn:Disconnect()
        inputEndedConn = nil
    end
    if fovConnection then
        fovConnection:Disconnect()
        fovConnection = nil
    end
    if pointerConnection then
        pointerConnection:Disconnect()
        pointerConnection = nil
    end
    if debugConnection then
        debugConnection:Disconnect()
        debugConnection = nil
    end
    if debugGui then
        debugGui:Destroy()
        debugGui = nil
        debugLabel = nil
    end
    if fovGui then
        fovGui:Destroy()
        fovGui = nil
        fovFrame = nil
        pointerFrame = nil
    end
end

return module
