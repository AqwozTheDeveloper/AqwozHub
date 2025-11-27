-- aimbotScripts.luau (Round-Start Safe)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local module = {}

local aimbotEnabled = false
local aimbotFOV = 200
local aimbotSmoothing = 0.15
local aimbotConnection = nil

-- No caching of camera or player
local function getClosestTarget()
    local Camera = Workspace.CurrentCamera
    if not Camera then return nil end

    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then return nil end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest = nil
    local shortest = aimbotFOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local head = player.Character:FindFirstChild("Head")
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not (head and humanoid) then continue end
        if humanoid.Health <= 0 then continue end

        local viewportPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local screenPos = Vector2.new(viewportPos.X, viewportPos.Y)
        local distance = (screenPos - screenCenter).Magnitude

        if distance < shortest then
            shortest = distance
            closest = head
        end
    end

    return closest
end

local function aimbotLoop()
    if not aimbotEnabled then return end

    local Camera = Workspace.CurrentCamera
    if not Camera then return end

    -- 🔥 CRITICAL: Re-enforce Scriptable mode every frame
    -- (in case game resets it at round start)
    if Camera.CameraType ~= Enum.CameraType.Scriptable then
        Camera.CameraType = Enum.CameraType.Scriptable
    end

    local target = getClosestTarget()
    if target then
        local currentPos = Camera.CFrame.Position
        local goalCFrame = CFrame.lookAt(currentPos, target.Position)
        Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, aimbotSmoothing)
    end
end

-- Public API
function module.init()
    print("[Aimbot] Module loaded (round-safe).")
end

function module.toggleAimbot(state)
    aimbotEnabled = state
    print("[Aimbot]:", state and "Enabled" or "Disabled")

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end

    if state then
        aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
    end
end

function module.setFOV(value)
    aimbotFOV = math.clamp(value, 10, 1000)
    print("[Aimbot] FOV:", aimbotFOV)
end

function module.setSmoothing(value)
    aimbotSmoothing = math.clamp(value, 0.01, 1)
    print("[Aimbot] Smoothing:", aimbotSmoothing)
end

function module.destroy()
    module.toggleAimbot(false)
end

return module
