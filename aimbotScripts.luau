local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
-- local Camera = workspace.CurrentCamera -- Removed global camera dependency
local LocalPlayer = Players.LocalPlayer

local module = {}

local function getCamera()
    return workspace.CurrentCamera
end

local aimbotEnabled = false
local aimbotFOV = 200
local aimbotConnection = nil
local aimbotSmoothing = 0.1
local dynamicSmoothingEnabled = false
local aimbotMaxDistance = 0
local currentTarget = nil
local teamCheckEnabled = false
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

local targetPartName = "Head"
local maxAngleDeg = 180
local predictionEnabled = false
local predictionMultiplier = 1.0
local stickyTargetEnabled = false
local triggerBotEnabled = false
local triggerBotDelay = 0.1
local aimOffsetX = 0
local aimOffsetY = 0
local aimOffsetZ = 0
local targetPriority = "closest" -- "closest", "lowest_health", "highest_threat"
local ignoreList = {}
local lastTriggerTime = 0

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

local function isPlayerIgnored(player)
    return ignoreList[player.UserId] ~= nil
end

local function getPlayerHealth(player)
    if not player.Character then return 0 end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health or 0
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
        local Camera = getCamera()
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

    local function isValidPlayer(player)
        if player == LocalPlayer or not player.Character then return false end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local part = getTargetPart(player.Character)
        if not humanoid or humanoid.Health <= 0 or not part then return false end
        if teamCheckEnabled and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then return false end
        
        local Camera = getCamera()
        if not Camera then return false end

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

    if stickyTargetEnabled and currentTarget and isValidPlayer(currentTarget) then
        return currentTarget
    end

    local candidates = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local part = getTargetPart(player.Character)

            if humanoid and humanoid.Health > 0 and part then
                if teamCheckEnabled and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
                    
                else
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

                    if onScreen and isVisible(player.Character, part) then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if aimbotMaxDistance and aimbotMaxDistance > 0 then
        if aimbotMaxDistance and aimbotMaxDistance > 0 then
            local Camera = getCamera()
            if Camera then
                local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
                if worldDist > aimbotMaxDistance then return false end
            end
        end
        return true
    end
                        if distance < shortestDistance then
                            table.insert(candidates, {player = player, distance = distance, health = getPlayerHealth(player)})
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    -- Apply target priority
    if targetPriority == "lowest_health" and #candidates > 0 then
        table.sort(candidates, function(a, b) return a.health < b.health end)
        return candidates[1].player
    elseif targetPriority == "highest_threat" and #candidates > 0 then
        -- Threat is based on distance + health (closer + lower health = higher threat)
        table.sort(candidates, function(a, b) 
            local threatA = a.distance / (a.health + 1)
            local threatB = b.distance / (b.health + 1)
            return threatA > threatB
        end)
        return candidates[1].player
    end
    
    return closestPlayer
end

-- Aimbot loop (Smooth)
local function aimbotLoop()
    if not aimbotEnabled then return end
    if aimHoldEnabled and not aimHoldActive then return end
    
    -- Update camera reference dynamically
    local Camera = getCamera()
    if not Camera then return end

    local target = getClosestPlayer()

    if target and target.Character then
        if currentTarget ~= target then
             -- New target acquired
             print("[Aimbot] Locked on:", target.Name)
        end
        
        local part = getTargetPart(target.Character)

        if part then
            -- Get predicted position
            local targetPos = predictionEnabled and getPredictedPosition(part) or part.Position
            
            -- Apply aim offset
            targetPos = targetPos + Vector3.new(aimOffsetX, aimOffsetY, aimOffsetZ)
            
            -- Kamerayı hedefin kafasına yönlendir
            local toTarget = (targetPos - Camera.CFrame.Position).Unit
            local angle = math.deg(math.acos(math.clamp(Camera.CFrame.LookVector:Dot(toTarget), -1, 1)))
            if angle > maxAngleDeg then return end
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            local factor = aimbotSmoothing
            if dynamicSmoothingEnabled and maxAngleDeg > 0 then
                local ratio = math.clamp(angle / maxAngleDeg, 0.2, 1)
                factor = math.clamp(aimbotSmoothing * ratio, 0.01, 1)
            end
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, factor)
            currentTarget = target
            
            -- Move cursor to target position (executor-specific)
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
            if onScreen and mousemoverel then
                local mousePos = UserInputService:GetMouseLocation()
                local deltaX = screenPos.X - mousePos.X
                local deltaY = screenPos.Y - mousePos.Y
                
                -- Apply smoothing to cursor movement
                local cursorFactor = factor * 0.5 -- Slightly slower than camera for smoothness
                mousemoverel(deltaX * cursorFactor, deltaY * cursorFactor)
            end
            
            -- Trigger bot logic (executor-specific)
            if triggerBotEnabled and mouse1click and tick() - lastTriggerTime > triggerBotDelay then
                local screenPos2, onScreen2 = Camera:WorldToViewportPoint(targetPos)
                if onScreen2 then
                    local mousePos2 = UserInputService:GetMouseLocation()
                    local distToCenter = (Vector2.new(screenPos2.X, screenPos2.Y) - mousePos2).Magnitude
                    if distToCenter < 5 then -- Within 5 pixels of crosshair
                        mouse1click()
                        lastTriggerTime = tick()
                    end
                end
            end
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
    local pos
    if currentTarget and currentTarget.Character then
        local part = getTargetPart(currentTarget.Character)
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

function module.setMaxDistance(value)
    local v = tonumber(value) or 0
    aimbotMaxDistance = math.max(0, v)
    print("[Aimbot] MaxDistance:", aimbotMaxDistance)
end

function module.toggleDynamicSmoothing(state)
    dynamicSmoothingEnabled = state and true or false
    print("[Aimbot] DynamicSmoothing:", dynamicSmoothingEnabled)
end

function module.togglePrediction(state)
    predictionEnabled = state and true or false
    print("[Aimbot] Prediction:", predictionEnabled)
end

function module.setPredictionMultiplier(value)
    local v = tonumber(value) or 1.0
    predictionMultiplier = math.clamp(v, 0.1, 5.0)
    print("[Aimbot] PredictionMultiplier:", predictionMultiplier)
end

function module.toggleStickyTarget(state)
    stickyTargetEnabled = state and true or false
    if not state then
        currentTarget = nil
    end
    print("[Aimbot] StickyTarget:", stickyTargetEnabled)
end

function module.toggleTriggerBot(state)
    triggerBotEnabled = state and true or false
    print("[Aimbot] TriggerBot:", triggerBotEnabled)
end

function module.setTriggerDelay(value)
    local v = tonumber(value) or 0.1
    triggerBotDelay = math.clamp(v, 0, 1)
    print("[Aimbot] TriggerDelay:", triggerBotDelay)
end

function module.setAimOffset(x, y, z)
    aimOffsetX = tonumber(x) or 0
    aimOffsetY = tonumber(y) or 0
    aimOffsetZ = tonumber(z) or 0
    print("[Aimbot] AimOffset:", aimOffsetX, aimOffsetY, aimOffsetZ)
end

function module.setTargetPriority(priority)
    local allowed = {
        closest = true,
        lowest_health = true,
        highest_threat = true
    }
    if type(priority) == "string" and allowed[priority] then
        targetPriority = priority
    end
    print("[Aimbot] TargetPriority:", targetPriority)
end

function module.addToIgnoreList(userId)
    if type(userId) == "number" then
        ignoreList[userId] = true
        print("[Aimbot] Added to ignore list:", userId)
    end
end

function module.removeFromIgnoreList(userId)
    if type(userId) == "number" then
        ignoreList[userId] = nil
        print("[Aimbot] Removed from ignore list:", userId)
    end
end

function module.clearIgnoreList()
    ignoreList = {}
    print("[Aimbot] Ignore list cleared")
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
    if fovGui then
        fovGui:Destroy()
        fovGui = nil
        fovFrame = nil
        pointerFrame = nil
    end
end

return module
