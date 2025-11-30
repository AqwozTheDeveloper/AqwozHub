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
local debugMode = false

-- Debug logging function
local function debugLog(...)
    if debugMode then
        print("[SilentAim Debug]", ...)
    end
end

-- Visuals
local fovCircleEnabled = false
local fovGui = nil
local fovFrame = nil
local fovStroke = nil
local fovConnection = nil
local fovColor = Color3.fromRGB(255, 0, 0) -- Red for Silent Aim to distinguish from Legit

local function ensureFOVGui()
    if fovGui and fovFrame then return true end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pg then 
        warn("[SilentAim] PlayerGui not found, retrying on next toggle")
        return false 
    end
    
    -- Cleanup
    local old = pg:FindFirstChild("AqwozHubSilentFOV")
    if old then old:Destroy() end

    fovGui = Instance.new("ScreenGui")
    fovGui.Name = "AqwozHubSilentFOV"
    fovGui.IgnoreGuiInset = true
    fovGui.ResetOnSpawn = false
    fovGui.DisplayOrder = 999 -- Ensure it's on top
    fovGui.Parent = pg
    
    fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVCircle"
    fovFrame.BackgroundTransparency = 1
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.Position = UDim2.fromOffset(0, 0)
    fovFrame.Size = UDim2.fromOffset(silentAimFOV * 2, silentAimFOV * 2)
    fovFrame.ZIndex = 100
    fovFrame.Parent = fovGui
    
    fovStroke = Instance.new("UIStroke")
    fovStroke.Thickness = 2
    fovStroke.Transparency = 0.3
    fovStroke.Color = fovColor
    fovStroke.Parent = fovFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovFrame
    
    print("[SilentAim] FOV GUI elements created successfully")
    return true
end

local function updateFOVCircle()
    if not fovCircleEnabled then return end
    if not fovGui or not fovFrame or not fovFrame.Parent then return end
    
    -- FOV circle should be at screen center (where crosshair is)
    local camera = getCamera()
    if not camera then return end
    
    local viewportSize = camera.ViewportSize
    local guiInset = game:GetService("GuiService"):GetGuiInset()
    
    -- Center of viewport + GuiInset offset = Center of Screen (Crosshair)
    -- Correct formula: (ViewportSize + GuiInset) / 2
    local centerX = (viewportSize.X + guiInset.X) / 2
    local centerY = (viewportSize.Y + guiInset.Y) / 2
    
    fovFrame.Size = UDim2.fromOffset(silentAimFOV * 2, silentAimFOV * 2)
    fovFrame.Position = UDim2.fromOffset(centerX, centerY)
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

    local camera = getCamera()
    if not camera then return nil end
    
    -- Use screen center (crosshair position) for Silent Aim FOV check
    local viewportSize = camera.ViewportSize
    local guiInset = game:GetService("GuiService"):GetGuiInset()
    local screenCenter = Vector2.new((viewportSize.X + guiInset.X) / 2, (viewportSize.Y + guiInset.Y) / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local part = getTargetPart(player.Character)

            if humanoid and humanoid.Health > 0 and part then
                -- Team check
                if teamCheckEnabled and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
                    continue
                end

                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                
                -- For silent aim, check if target is in front of camera (Z > 0)
                if screenPos.Z > 0 then
                    -- Distance from screen center (crosshair) to target
                    -- Adjust screenPos to match screenCenter (add GuiInset)
                    local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y + guiInset.Y)
                    local distance = (targetScreenPos - screenCenter).Magnitude

                    -- Max distance check (world distance)
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
                        debugLog("Found target:", player.Name, "Distance:", math.floor(distance))
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Prediction settings
local PREDICTION_STRENGTH = 0.135 -- Adjust for Rivals (0.13 - 0.15 usually good)

-- Get target position for silent aim (with Prediction)
local function getSilentAimTarget()
    if not silentAimEnabled then return nil end
    
    local target = getClosestPlayer()
    if target and target.Character then
        local part = getTargetPart(target.Character)
        if part then
            debugLog("Target found:", target.Name, "Part:", part.Name)
            
            -- Calculate Prediction
            local velocity = part.Velocity
            local prediction = velocity * PREDICTION_STRENGTH
            
            return part.Position + prediction
        end
    end
    return nil
end

-- Get the target part itself (not just position)
local function getSilentAimTargetPart()
    if not silentAimEnabled then return nil end
    
    local target = getClosestPlayer()
    if target and target.Character then
        local part = getTargetPart(target.Character)
        if part then
            return part
        end
    end
    return nil
end

-- Modify arguments to redirect to target
local function modifyArgs(args, targetPos)
    local camera = getCamera()
    if not camera then return args end
    
    local newArgs = {}
    for i, arg in ipairs(args) do
        if typeof(arg) == "Vector3" then
            -- Check if this looks like a direction vector (normalized or small magnitude)
            local mag = arg.Magnitude
            if mag <= 1.1 and mag > 0 then
                -- This is likely a direction, redirect it
                local origin = camera.CFrame.Position
                newArgs[i] = (targetPos - origin).Unit
                debugLog("Modified direction Vector3 at index", i)
            else
                newArgs[i] = arg
            end
        elseif typeof(arg) == "CFrame" then
            -- Redirect CFrame to look at target
            newArgs[i] = CFrame.new(arg.Position, targetPos)
            debugLog("Modified CFrame at index", i)
        elseif typeof(arg) == "Ray" then
            -- Redirect ray to target
            local newDir = (targetPos - arg.Origin).Unit * arg.Direction.Magnitude
            newArgs[i] = Ray.new(arg.Origin, newDir)
            debugLog("Modified Ray at index", i)
        elseif typeof(arg) == "table" then
            -- Recursively check tables for Vector3/CFrame
            newArgs[i] = {}
            for k, v in pairs(arg) do
                if typeof(v) == "Vector3" then
                    local mag = v.Magnitude
                    if mag <= 1.1 and mag > 0 then
                        newArgs[i][k] = (targetPos - camera.CFrame.Position).Unit
                    else
                        newArgs[i][k] = v
                    end
                elseif typeof(v) == "CFrame" then
                    newArgs[i][k] = CFrame.new(v.Position, targetPos)
                else
                    newArgs[i][k] = v
                end
            end
        else
            newArgs[i] = arg
        end
    end
    return newArgs
end

function module.init()
    print("[SilentAim] Module initialized - Rivals Edition")
    
    -- Check if executor functions are available
    local hasHookmetamethod = typeof(hookmetamethod) == "function"
    local hasNewcclosure = typeof(newcclosure) == "function"
    local hasCheckcaller = typeof(checkcaller) == "function"
    local hasGetnamecallmethod = typeof(getnamecallmethod) == "function"
    
    print("[SilentAim] Executor Check:")
    print("  hookmetamethod:", hasHookmetamethod and "YES" or "NO")
    print("  newcclosure:", hasNewcclosure and "YES" or "NO")
    print("  checkcaller:", hasCheckcaller and "YES" or "NO")
    print("  getnamecallmethod:", hasGetnamecallmethod and "YES" or "NO")
    
    if not hasHookmetamethod then
        warn("[SilentAim] hookmetamethod not available - Silent Aim will not work")
        warn("[SilentAim] Your executor does not support this feature")
        return
    end
    if not hasNewcclosure then
        warn("[SilentAim] newcclosure not available - using regular function")
    end
    if not hasCheckcaller then
        warn("[SilentAim] checkcaller not available - Silent Aim may cause issues")
    end
    if not hasGetnamecallmethod then
        warn("[SilentAim] getnamecallmethod not available - Some hooks may not work")
    end
    
    -- If critical functions missing, still try to install hooks
    if not hasHookmetamethod then
        return
    end
    
    local wrapFunction = hasNewcclosure and newcclosure or function(f) return f end
    
    -- __index hook (Mouse.Hit, Mouse.Target, UnitRay)
    local oldIndex
    local indexSuccess, indexErr = pcall(function()
        oldIndex = hookmetamethod(game, "__index", wrapFunction(function(self, key)
            if checkcaller() then return oldIndex(self, key) end
            if not silentAimEnabled then
                return oldIndex(self, key)
            end
            
            -- Mouse property hooks
            if typeof(self) == "Instance" and self:IsA("Mouse") then
                local targetPos = getSilentAimTarget()
                if targetPos then
                    local camera = getCamera()
                    if not camera then
                        return oldIndex(self, key)
                    end
                    
                    if key == "Hit" then
                        debugLog("Mouse.Hit redirected")
                        return CFrame.new(targetPos)
                    elseif key == "Target" then
                        debugLog("Mouse.Target redirected")
                        return getSilentAimTargetPart()
                    elseif key == "UnitRay" then
                        debugLog("Mouse.UnitRay redirected")
                        local origin = camera.CFrame.Position
                        local direction = (targetPos - origin).Unit
                        return Ray.new(origin, direction)
                    elseif key == "X" then
                        local screenPos = camera:WorldToViewportPoint(targetPos)
                        return screenPos.X
                    elseif key == "Y" then
                        local screenPos = camera:WorldToViewportPoint(targetPos)
                        local guiInset = game:GetService("GuiService"):GetGuiInset()
                        return screenPos.Y + guiInset.Y
                    end
                end
            end
            
            return oldIndex(self, key)
        end))
    end)
    
    if not indexSuccess then
        warn("[SilentAim] Failed to hook __index:", indexErr)
    else
        print("[SilentAim] __index hook installed")
    end
    
    -- __namecall hook (Raycast, FindPartOnRay, FireServer, InvokeServer)
    local oldNamecall
    local namecallSuccess, namecallErr = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", wrapFunction(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if checkcaller() then return oldNamecall(self, ...) end
            if not silentAimEnabled then
                return oldNamecall(self, ...)
            end
            
            local targetPos = getSilentAimTarget()
            if not targetPos then
                return oldNamecall(self, ...)
            end
            
            -- Workspace Raycast hook
            if self == workspace then
                if method == "Raycast" then
                    if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                        local origin = args[1]
                        local newDirection = (targetPos - origin).Unit * args[2].Magnitude
                        debugLog("workspace:Raycast redirected")
                        return oldNamecall(self, origin, newDirection, args[3])
                    end
                elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    if typeof(args[1]) == "Ray" then
                        local ray = args[1]
                        local newDir = (targetPos - ray.Origin).Unit * ray.Direction.Magnitude
                        args[1] = Ray.new(ray.Origin, newDir)
                        debugLog(method .. " redirected")
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
            
            -- Camera ray hooks
            local camera = getCamera()
            if camera and self == camera then
                if method == "ViewportPointToRay" or method == "ScreenPointToRay" then
                    local origin = camera.CFrame.Position
                    local direction = (targetPos - origin).Unit
                    debugLog("Camera:" .. method .. " redirected")
                    return Ray.new(origin, direction)
                end
            end
            
            -- RemoteEvent/RemoteFunction hooks for shooting
            if typeof(self) == "Instance" then
                if self:IsA("RemoteEvent") and method == "FireServer" then
                    -- Modify arguments that contain Vector3/CFrame/Ray
                    local modifiedArgs = modifyArgs(args, targetPos)
                    debugLog("RemoteEvent:FireServer modified -", self.Name)
                    return oldNamecall(self, unpack(modifiedArgs))
                elseif self:IsA("RemoteFunction") and method == "InvokeServer" then
                    local modifiedArgs = modifyArgs(args, targetPos)
                    debugLog("RemoteFunction:InvokeServer modified -", self.Name)
                    return oldNamecall(self, unpack(modifiedArgs))
                end
            end
            
            return oldNamecall(self, ...)
        end))
    end)
    
    if not namecallSuccess then
        warn("[SilentAim] Failed to hook __namecall:", namecallErr)
    else
        print("[SilentAim] __namecall hook installed")
    end
    
    if indexSuccess and namecallSuccess then
        print("[SilentAim] All hooks installed successfully!")
        print("[SilentAim] Bullets will now curve to " .. targetPartName)
    else
        warn("[SilentAim] Some hooks failed - Silent Aim may not work properly")
    end
end

function module.updateSettings()
    -- Update settings individually to match the function signature in main.luau
    if _G.updateSetting then
        _G.updateSetting("SilentAim", "SilentAimToggle", silentAimEnabled)
        _G.updateSetting("SilentAim", "FOV", silentAimFOV)
        _G.updateSetting("SilentAim", "MaxDistance", silentAimMaxDistance)
        _G.updateSetting("SilentAim", "TeamCheck", teamCheckEnabled)
        _G.updateSetting("SilentAim", "TargetPart", targetPartName)
        _G.updateSetting("SilentAim", "MaxAngle", maxAngleDeg)
        _G.updateSetting("SilentAim", "FOVCircle", fovCircleEnabled)
        print("[SilentAim] Settings updated to profile")
    else
        warn("[SilentAim] Could not find settings update function")
    end
end

function module.toggleSilentAim(state)
    silentAimEnabled = state and true or false
    print("[SilentAim] Toggled:", silentAimEnabled)
    debugLog("Attempting to update settings after toggle")
    local success, errorMsg = pcall(function()
        module.updateSettings()
    end)
    if not success then
        warn("[SilentAim] Error updating settings:", errorMsg)
    else
        debugLog("Settings updated successfully")
    end
end

function module.toggleFOVCircle(state)
    fovCircleEnabled = state and true or false
    print("[SilentAim] FOVCircle toggled:", fovCircleEnabled)
    
    if fovCircleEnabled then
        local success = ensureFOVGui()
        print("[SilentAim] FOV GUI created:", success)
        if success then
            fovFrame.Visible = true
            updateFOVCircle() -- Position immediately
            if not fovConnection then
                fovConnection = RunService.RenderStepped:Connect(updateFOVCircle)
                print("[SilentAim] FOV update connection started")
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
    module.updateSettings()
end

function module.setFOV(value)
    silentAimFOV = math.max(1, tonumber(value) or silentAimFOV)
    print("[SilentAim] FOV set to:", silentAimFOV)
    -- Update FOV circle size immediately if visible
    if fovFrame and fovCircleEnabled then
        fovFrame.Size = UDim2.fromOffset(silentAimFOV * 2, silentAimFOV * 2)
    end
    module.updateSettings()
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state and true or false
    print("[SilentAim] TeamCheck:", teamCheckEnabled)
    module.updateSettings()
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
    module.updateSettings()
end

function module.setMaxAngle(deg)
    local v = tonumber(deg) or maxAngleDeg
    maxAngleDeg = math.clamp(v, 5, 180)
    print("[SilentAim] MaxAngle:", maxAngleDeg)
    module.updateSettings()
end

function module.setMaxDistance(value)
    local v = tonumber(value) or 0
    silentAimMaxDistance = math.max(0, v)
    print("[SilentAim] MaxDistance:", silentAimMaxDistance)
    module.updateSettings()
end

function module.toggleDebugMode(state)
    debugMode = state and true or false
    print("[SilentAim] DebugMode:", debugMode)
    if debugMode then
        debugLog("Debug logs enabled")
    end
end

function module.getStats()
    return {
        enabled = silentAimEnabled,
        fov = silentAimFOV,
        maxDistance = silentAimMaxDistance,
        targetPart = targetPartName,
        teamCheck = teamCheckEnabled
    }
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
        fovFrame = nil
        fovStroke = nil
    end
    
    print("[SilentAim] Module destroyed")
end

return module
