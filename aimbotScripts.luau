-- aimbotScripts.luau (FIXED: Head lock + Scriptable camera)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local module = {}

local aimbotEnabled = false
local aimbotFOV = 200
local aimbotSmoothing = 0.15
local aimbotConnection = nil

local originalCameraType = nil

local function getCamera()
    return Workspace.CurrentCamera
end

local function getLocalPlayer()
    return Players.LocalPlayer
end

local function getClosestTarget()
    local Camera = getCamera()
    if not Camera then return nil end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest = nil
    local shortest = aimbotFOV

    local LocalPlayer = getLocalPlayer()
    if not LocalPlayer then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(head.Position)
                if vis then
                    local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if distance < shortest then
                        closest = head
                        shortest = distance
                    end
                end
            end
        end
    end

    return closest
end

local function applyAim(target)
    local Camera = getCacheCamera()
    if not Camera or not target then return end

    local currentPos = Camera.CFrame.Position
    local lookAtCFrame = CFrame.lookAt(currentPos, target.Position)
    Camera.CFrame = Camera.CFrame:Lerp(lookAtCFrame, aimbotSmoothing)
end

local function aimbotLoop()
    if not aimbotEnabled then return end
    local target = getClosestTarget()
    if target then
        applyAim(target)
    end
end

-- Camera management
local function enableScriptableCamera()
    local Camera = getCamera()
    if Camera and Camera.CameraType ~= Enum.CameraType.Scriptable then
        originalCameraType = Camera.CameraType
        Camera.CameraType = Enum.CameraType.Scriptable
    end
end

local function restoreOriginalCamera()
    local Camera = getCamera()
    if Camera and originalCameraType then
        Camera.CameraType = originalCameraType
        originalCameraType = nil
    end
end

-- Public API
function module.init()
    print("[Aimbot] Module loaded.")
end

function module.toggleAimbot(state)
    aimbotEnabled = state
    print("[Aimbot]:", state and "Enabled" or "Disabled")

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end

    if state then
        enableScriptableCamera()
        aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
    else
        restoreOriginalCamera()
    end
end

function module.setFOV(value)
    aimbotFOV = value
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
