-- aimbotScripts.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local module = {}

local aimbotEnabled = false
local aimbotFOV = 200
local aimbotConnection = nil
local fovCircle = nil

-- FOV Circle oluştur
local function createFOVCircle()
    if fovCircle then fovCircle:Remove() end

    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.NumSides = 50
    fovCircle.Radius = aimbotFOV
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.5
    fovCircle.Visible = false
    fovCircle.Filled = false
end

-- En yakın oyuncuyu bul
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = aimbotFOV

    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            if humanoid and humanoid.Health > 0 and head then
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

    return closestPlayer
end

-- Aimbot loop
local function aimbotLoop()
    if not aimbotEnabled then return end

    local target = getClosestPlayer()

    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")

        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        end
    end
end

function module.init()
    createFOVCircle()

    -- FOV Circle güncelleme
    RunService.RenderStepped:Connect(function()
        if fovCircle then
            local mousePos = UserInputService:GetMouseLocation()
            fovCircle.Position = mousePos
            fovCircle.Radius = aimbotFOV
            fovCircle.Visible = aimbotEnabled
        end
    end)
end

function module.toggleAimbot(state)
    aimbotEnabled = state

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
    if fovCircle then
        fovCircle.Radius = value
    end
end

function module.destroy()
    aimbotEnabled = false

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end

    if fovCircle then
        fovCircle:Remove()
        fovCircle = nil
    end
end

return module
