-- aimbotScripts.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local module = {}

-- Settings
local aimbotEnabled = false
local teamCheckEnabled = false
local wallCheckEnabled = false
local aimbotFOV = 200
local aimbotSmoothing = 0.5 -- 0.1 to 1 (1 is instant snap)
local aimKey = Enum.UserInputType.MouseButton2

local aimbotConnection = nil

-- Check if player is visible (Wall Check)
local function isVisible(targetPart)
    if not wallCheckEnabled then return true end

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, raycastParams)

    if result then
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        else
            return false
        end
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
            -- Team Check
            if teamCheckEnabled then
                if player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
                    continue
                end
            end

            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            if humanoid and humanoid.Health > 0 and head then
                -- Wall Check
                if not isVisible(head) then continue end

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
    if not aimbotEnabled or not UserInputService:IsMouseButtonPressed(aimKey) then return end

    local target = getClosestPlayer()

    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")

        if head then
            -- Kamerayı hedefin kafasına yönlendir
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, head.Position)

            -- Smoothness interpolation
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, aimbotSmoothing)
        end
    end
end

-- Module API
function module.init()
    print("[Aimbot] Module initialized")
end

function module.toggleAimbot(state)
    aimbotEnabled = state
    print("[Aimbot] Toggled:", state)

    if state then
        if aimbotConnection then aimbotConnection:Disconnect() end
        aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end

function module.setFOV(value)
    aimbotFOV = value
end

function module.setSmoothing(value)
    -- Convert 1-10 slider to 0.1-1 lerp alpha
    aimbotSmoothing = math.clamp(value / 10, 0.05, 1)
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state
    print("[Aimbot] TeamCheck:", state)
end

function module.toggleWallCheck(state)
    wallCheckEnabled = state
    print("[Aimbot] WallCheck:", state)
end

function module.destroy()
    module.toggleAimbot(false)
end

return module
