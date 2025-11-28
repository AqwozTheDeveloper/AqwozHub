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

-- En yakın oyuncuyu bul
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = aimbotFOV

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

-- Aimbot loop (Smooth)
local function aimbotLoop()
    if not aimbotEnabled then return end

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

return module
