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
local aimbotSmoothing = 0.1 -- Daha smooth aim için
local teamCheckEnabled = false
local wallCheckEnabled = false
local silentAimEnabled = false
local silentAimConnection = nil
local mouse = LocalPlayer:GetMouse()

-- FOV Circle
local fovCircle = nil
local fovCircleVisible = false
local fovCircleColor = Color3.fromRGB(255, 255, 255)
local fovCircleConnection = nil

-- FOV Circle oluştur
local function createFOVCircle()
    if fovCircle then
        fovCircle:Remove()
    end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = fovCircleVisible
    fovCircle.Thickness = 2
    fovCircle.Color = fovCircleColor
    fovCircle.Transparency = 1
    fovCircle.NumSides = 64
    fovCircle.Filled = false
end

-- FOV Circle güncelle
local function updateFOVCircle()
    if not fovCircle then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = mousePos
    fovCircle.Radius = aimbotFOV
    fovCircle.Visible = fovCircleVisible
end

-- FOV Circle loop
local function fovCircleLoop()
    if fovCircle then
        updateFOVCircle()
    end
end

-- Raycast ile duvar kontrolü
local function isVisible(targetPosition)
    if not wallCheckEnabled then return true end
    
    local cameraPosition = Camera.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local raycastResult = workspace:Raycast(cameraPosition, (targetPosition - cameraPosition), raycastParams)
    
    if raycastResult then
        return false
    end
    
    return true
end

-- Takım kontrolü
local function isEnemy(player)
    if not teamCheckEnabled then return true end
    
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    
    return true
end

-- En yakın oyuncuyu bul
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = aimbotFOV

    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Takım kontrolü
            if isEnemy(player) then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                local head = player.Character:FindFirstChild("Head")

                if humanoid and humanoid.Health > 0 and head then
                    -- Duvar kontrolü
                    if isVisible(head.Position) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                        if onScreen then
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

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

    return closestPlayer
end

-- Aimbot loop (Smooth) - Normal aimbot
local function aimbotLoop()
    if not aimbotEnabled or silentAimEnabled then return end

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

-- Silent Aim - Mouse.Hit hook
local originalMouseHit = nil
local lastHitCFrame = nil

local function setupSilentAim()
    if not silentAimEnabled or originalMouseHit then return end
    
    -- Mouse objesini hook et
    local success, mouseMeta = pcall(getrawmetatable, mouse)
    if not success or not mouseMeta then 
        warn("[Aimbot] Failed to get mouse metatable")
        return 
    end
    
    originalMouseHit = mouseMeta.__index
    
    mouseMeta.__index = newcclosure(function(self, key)
        if key == "Hit" and silentAimEnabled and aimbotEnabled then
            local target = getClosestPlayer()
            
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                
                if head then
                    local cameraPosition = Camera.CFrame.Position
                    local targetPosition = head.Position
                    local direction = (targetPosition - cameraPosition).Unit
                    
                    -- Smoothing için mevcut hit'i al
                    local currentHit = originalMouseHit(self, key)
                    if not lastHitCFrame then
                        lastHitCFrame = currentHit
                    end
                    
                    local currentDirection = (lastHitCFrame.Position - cameraPosition).Unit
                    local smoothedDirection = currentDirection:Lerp(direction, aimbotSmoothing)
                    
                    local newHit = CFrame.new(cameraPosition, cameraPosition + smoothedDirection * 1000)
                    lastHitCFrame = newHit
                    
                    return newHit
                end
            end
        end
        
        return originalMouseHit(self, key)
    end)
    
    print("[Aimbot] Silent Aim hook installed")
end

local function removeSilentAim()
    if originalMouseHit then
        local success, mouseMeta = pcall(getrawmetatable, mouse)
        if success and mouseMeta then
            mouseMeta.__index = originalMouseHit
        end
        originalMouseHit = nil
        lastHitCFrame = nil
        print("[Aimbot] Silent Aim hook removed")
    end
end

function module.init()
    print("[Aimbot] Module initialized")
    createFOVCircle()
end

function module.toggleAimbot(state)
    aimbotEnabled = state
    print("[Aimbot] Toggled:", state)

    if state then
        -- Aimbot açık
        if aimbotConnection then
            aimbotConnection:Disconnect()
        end

        if silentAimEnabled then
            setupSilentAim()
        else
            aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
        end
    else
        -- Aimbot kapalı
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        removeSilentAim()
    end
end

function module.toggleSilentAim(state)
    silentAimEnabled = state
    print("[Aimbot] Silent Aim:", state)
    
    if state then
        -- Silent aim açık - normal aimbot'u kapat
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        setupSilentAim()
    else
        -- Silent aim kapalı - normal aimbot'a geç
        removeSilentAim()
        if aimbotEnabled then
            if aimbotConnection then
                aimbotConnection:Disconnect()
            end
            aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
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
    -- Slider 1-10 arası değer gönderiyor, 0.01-0.1 arasına çevir
    aimbotSmoothing = value / 100
    print("[Aimbot] Smoothing set to:", aimbotSmoothing)
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state
    print("[Aimbot] Team Check:", state)
end

function module.toggleWallCheck(state)
    wallCheckEnabled = state
    print("[Aimbot] Wall Check:", state)
end

function module.toggleFOVCircle(state)
    fovCircleVisible = state
    print("[Aimbot] FOV Circle:", state)
    
    if state then
        if fovCircleConnection then
            fovCircleConnection:Disconnect()
        end
        fovCircleConnection = RunService.RenderStepped:Connect(fovCircleLoop)
        if fovCircle then
            fovCircle.Visible = true
        end
    else
        if fovCircleConnection then
            fovCircleConnection:Disconnect()
            fovCircleConnection = nil
        end
        if fovCircle then
            fovCircle.Visible = false
        end
    end
end

function module.setFOVCircleColor(color)
    fovCircleColor = color
    if fovCircle then
        fovCircle.Color = color
    end
    print("[Aimbot] FOV Circle Color updated")
end

function module.destroy()
    aimbotEnabled = false
    silentAimEnabled = false

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    
    if silentAimConnection then
        silentAimConnection:Disconnect()
        silentAimConnection = nil
    end
    
    removeSilentAim()
    
    if fovCircleConnection then
        fovCircleConnection:Disconnect()
        fovCircleConnection = nil
    end
    
    if fovCircle then
        fovCircle:Remove()
        fovCircle = nil
    end
end

return module
