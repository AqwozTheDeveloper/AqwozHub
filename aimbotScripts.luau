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
local aimbotSmoothing = 0.5 -- Daha agresif lock için (başlangıç değeri)
local teamCheckEnabled = false
local wallCheckEnabled = false
local silentAimEnabled = false
local silentAimConnection = nil

-- Mouse objesini güvenli şekilde al
local mouse = nil
local function getMouse()
    if not mouse then
        local success, result = pcall(function()
            return LocalPlayer:GetMouse()
        end)
        if success then
            mouse = result
        end
    end
    return mouse
end

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

    if not Camera then
        Camera = workspace.CurrentCamera
        if not Camera then return nil end
    end

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
    
    if not Camera then
        Camera = workspace.CurrentCamera
        if not Camera then return end
    end

    local target = getClosestPlayer()

    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        local humanoidRootPart = target.Character:FindFirstChild("HumanoidRootPart")

        if head then
            -- Kamerayı hedefin kafasına yönlendir
            local cameraPos = Camera.CFrame.Position
            local headPos = head.Position
            local targetCFrame = CFrame.new(cameraPos, headPos)
            
            -- Smoothing uygula - daha agresif lock için
            local success, err = pcall(function()
                -- Eğer smoothing çok düşükse direkt lock yap
                if aimbotSmoothing > 0.3 then
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, aimbotSmoothing)
                else
                    -- Daha agresif lock
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.max(aimbotSmoothing, 0.15))
                end
            end)
            
            if not success then
                -- Hata varsa direkt lock dene
                pcall(function()
                    Camera.CFrame = targetCFrame
                end)
            end
        end
    end
end

-- Silent Aim - Mouse.Hit hook
local originalMouseHit = nil
local lastHitCFrame = nil
local mouseMeta = nil

local function setupSilentAim()
    if not silentAimEnabled or originalMouseHit then return end
    
    -- Mouse objesini al
    local mouseObj = getMouse()
    if not mouseObj then
        warn("[Aimbot] Failed to get mouse object")
        return
    end
    
    -- Mouse objesini hook et
    local success, meta = pcall(function()
        return getrawmetatable(mouseObj)
    end)
    
    if not success or not meta then 
        warn("[Aimbot] Failed to get mouse metatable")
        return 
    end
    
    mouseMeta = meta
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
    if originalMouseHit and mouseMeta then
        mouseMeta.__index = originalMouseHit
        originalMouseHit = nil
        lastHitCFrame = nil
        mouseMeta = nil
        print("[Aimbot] Silent Aim hook removed")
    end
end

function module.init()
    print("[Aimbot] Module initialized")
    
    -- Mouse'u başlat
    task.spawn(function()
        task.wait(1)
        getMouse()
        if mouse then
            print("[Aimbot] Mouse object loaded")
        else
            warn("[Aimbot] Mouse object not found - Silent Aim may not work")
        end
    end)
    
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

        -- Camera'yı güncelle
        Camera = workspace.CurrentCamera
        
        if silentAimEnabled then
            setupSilentAim()
        else
            -- RenderStepped yerine Heartbeat kullan (daha iyi performans)
            aimbotConnection = RunService.Heartbeat:Connect(aimbotLoop)
            print("[Aimbot] Aimbot loop started")
        end
    else
        -- Aimbot kapalı
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        removeSilentAim()
        print("[Aimbot] Aimbot disabled")
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
        -- Aimbot açık değilse uyar
        if not aimbotEnabled then
            warn("[Aimbot] Silent Aim requires Aimbot to be enabled!")
            return
        end
        setupSilentAim()
    else
        -- Silent aim kapalı - normal aimbot'a geç
        removeSilentAim()
        if aimbotEnabled then
            if aimbotConnection then
                aimbotConnection:Disconnect()
            end
            Camera = workspace.CurrentCamera
            aimbotConnection = RunService.Heartbeat:Connect(aimbotLoop)
            print("[Aimbot] Switched to normal aimbot")
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
    -- Slider 1-10 arası değer gönderiyor, 0.1-1.0 arasına çevir (daha agresif lock için)
    -- 1 = çok smooth, 10 = çok agresif/direkt lock
    aimbotSmoothing = math.clamp(value / 10, 0.1, 1.0)
    print("[Aimbot] Smoothing set to:", aimbotSmoothing, "(Value:", value, ")")
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
