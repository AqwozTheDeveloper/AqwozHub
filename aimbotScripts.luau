-- aimbotScripts.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local function getCamera()
    return workspace.CurrentCamera
end

local module = {}

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
local debugMode = false

-- Debug logging function
local function debugLog(...)
    if debugMode then
        print("[Aimbot Debug]", ...)
    end
end

local function getTargetPart(character)
    local part = character:FindFirstChild(targetPartName)
    if part then return part end
    
    -- R6 Compatibility: If we wanted UpperTorso but it's missing, try Torso
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

    if currentTarget and isValidPlayer(currentTarget) then
        return currentTarget
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local part = getTargetPart(player.Character)

            if humanoid and humanoid.Health > 0 and part then
                if teamCheckEnabled and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
                    continue
                end

                local Camera = getCamera()
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

                if onScreen and isVisible(player.Character, part) then
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

    return closestPlayer
end

-- Move mouse cursor to target position
local function moveCursorToTarget(screenPos, factor)
    local Camera = getCamera()
    if not Camera then 
        debugLog("moveCursorToTarget: Camera not found")
        return false 
    end
    
    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local guiInset = GuiService:GetGuiInset()
    
    local deltaX = (screenPos.X - center.X) * factor
    local deltaY = (screenPos.Y - center.Y - guiInset.Y) * factor
    
    debugLog("moveCursorToTarget: deltaX=", math.floor(deltaX), "deltaY=", math.floor(deltaY))
    
    -- Try mousemoverel (most common executor function)
    if mousemoverel then
        local success = pcall(function()
            mousemoverel(deltaX, deltaY)
        end)
        if success then 
            debugLog("mousemoverel succeeded")
            return true 
        end
    end
    
    -- Try Input.MouseMove
    if Input and Input.MouseMove then
        local success = pcall(function()
            Input.MouseMove(deltaX, deltaY)
        end)
        if success then 
            debugLog("Input.MouseMove succeeded")
            return true 
        end
    end
    
    -- Try mouse_move
    if mouse_move then
        local success = pcall(function()
            mouse_move(deltaX, deltaY)
        end)
        if success then 
            debugLog("mouse_move succeeded")
            return true 
        end
    end
    
    debugLog("No mouse movement function available")
    return false
end

-- Aimbot loop (Smooth)
local function aimbotLoop()
    if not aimbotEnabled then 
        return 
    end
    
    -- If hold-to-aim is enabled, only aim when holding RMB
    if aimHoldEnabled and not aimHoldActive then
        currentTarget = nil
        return
    end

    local Camera = getCamera()
    if not Camera then 
        debugLog("Camera not found")
        return 
    end
    
    local target = getClosestPlayer()

    if target and target.Character then
        local part = getTargetPart(target.Character)

        if part then
            debugLog("Target:", target.Name, "Part:", part.Name)
            
            -- Check angle to target
            local toTarget = (part.Position - Camera.CFrame.Position).Unit
            local angle = math.deg(math.acos(math.clamp(Camera.CFrame.LookVector:Dot(toTarget), -1, 1)))
            
            debugLog("Angle:", math.floor(angle), "MaxAngle:", maxAngleDeg)
            
            if angle > maxAngleDeg then 
                debugLog("Angle exceeds max, skipping")
                currentTarget = nil
                return 
            end
            
            -- Calculate smoothing factor
            local factor = aimbotSmoothing
            if dynamicSmoothingEnabled and maxAngleDeg > 0 then
                local ratio = math.clamp(angle / maxAngleDeg, 0.2, 1)
                factor = math.clamp(factor * ratio, 0.01, 1)
                debugLog("Dynamic smoothing factor:", factor)
            end
            
            -- Get target screen position
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                -- Try to move cursor to target (works if executor supports it)
                local cursorMoved = moveCursorToTarget(Vector2.new(screenPos.X, screenPos.Y), factor)
                
                -- If cursor move failed, use camera-based aiming as fallback
                if not cursorMoved then
                    debugLog("Using camera-based aiming fallback")
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, factor)
                end
            else
                debugLog("Target not on screen")
            end
            
            currentTarget = target
        else
            debugLog("No valid target part")
            currentTarget = nil
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
        -- Clear current target so FOV circle color resets
        currentTarget = nil
    end
end

function module.setFOV(value)
    aimbotFOV = math.max(1, tonumber(value) or aimbotFOV)
    print("[Aimbot] FOV set to:", aimbotFOV)
    -- Update FOV circle size immediately if visible
    if fovFrame and fovCircleEnabled then
        fovFrame.Size = UDim2.fromOffset(aimbotFOV * 2, aimbotFOV * 2)
    end
end

function module.setSmoothing(value)
    local v = tonumber(value) or 1
    -- Map 1-10 to roughly 0.05 - 0.8
    -- 1 -> 0.05 (Very smooth)
    -- 5 -> 0.25 (Medium)
    -- 10 -> 0.8 (Fast)
    aimbotSmoothing = math.clamp(v * 0.08, 0.05, 1)
    print("[Aimbot] Smoothing set to:", value, "(Internal:", aimbotSmoothing, ")")
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
    
    -- Cleanup existing GUI
    local oldGui = pg:FindFirstChild("AqwozHubFOV")
    if oldGui then
        oldGui:Destroy()
    end

    fovGui = Instance.new("ScreenGui")
    fovGui.Name = "AqwozHubFOV"
    fovGui.IgnoreGuiInset = true
    fovGui.ResetOnSpawn = false
    fovGui.Parent = pg
    fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVCircle"
    fovFrame.BackgroundTransparency = 1
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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
    pointerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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
    
    local Camera = getCamera()
    if not Camera then return end
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local guiInset = GuiService:GetGuiInset()
    
    fovFrame.Size = UDim2.fromOffset(aimbotFOV * 2, aimbotFOV * 2)
    fovFrame.Position = UDim2.fromOffset(center.X, center.Y + guiInset.Y)
    
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
    local Camera = getCamera()
    if not Camera then return end
    
    local guiInset = GuiService:GetGuiInset()
    local pos

    -- If aimbot is enabled and we have a target, show pointer on target
    if aimbotEnabled and currentTarget and currentTarget.Character then
        local part = getTargetPart(currentTarget.Character)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                pos = Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    end
    
    -- Fallback to screen center if no target
    if not pos then
        local viewport = Camera.ViewportSize
        pos = Vector2.new(viewport.X / 2, viewport.Y / 2 + guiInset.Y)
    end
    
    pointerFrame.Position = UDim2.fromOffset(pos.X, pos.Y)
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

function module.toggleDebugMode(state)
    debugMode = state and true or false
    print("[Aimbot] DebugMode:", debugMode)
    if debugMode then
        debugLog("Debug logs enabled")
    end
end

function module.getStats()
    return {
        enabled = aimbotEnabled,
        currentTarget = currentTarget and currentTarget.Name or "None",
        fov = aimbotFOV,
        smoothing = aimbotSmoothing,
        targetPart = targetPartName,
        holdActive = aimHoldActive
    }
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
        fovStroke = nil
        pointerFrame = nil
    end
    print("[Aimbot] Module destroyed")
end

return module
