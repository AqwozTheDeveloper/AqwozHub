-- aimbotScripts.luau (OPTIMIZED)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local module = {}

local aimbotEnabled = false
local aimbotFOV = 200
local aimbotSmoothing = 0.15
local aimbotConnection = nil

-- En yakın hedefi al
local function getClosestTarget()
    local mouse = UserInputService:GetMouseLocation()
    local closest = nil
    local shortest = aimbotFOV

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")

            if head and hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(head.Position)

                if vis then
                    local distance = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude

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

local function aimTo(target)
    local camPos = Camera.CFrame.Position
    local targetCF = CFrame.new(camPos, target.Position)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, aimbotSmoothing)
end

local function aimbotLoop()
    if not aimbotEnabled then return end

    local target = getClosestTarget()
    if target then
        aimTo(target)
    end
end

-- Public API
function module.init()
    print("[Aimbot] Loaded.")
end

function module.toggleAimbot(state)
    aimbotEnabled = state
    print("[Aimbot]:", state and "Enabled" or "Disabled")

    if state then
        if aimbotConnection then aimbotConnection:Disconnect() end
        aimbotConnection = RunService.RenderStepped:Connect(aimbotLoop)
    else
        if aimbotConnection then aimbotConnection:Disconnect() end
        aimbotConnection = nil
    end
end

function module.setFOV(value)
    aimbotFOV = value
    print("[Aimbot] FOV:", aimbotFOV)
end

function module.setSmoothing(value)
    aimbotSmoothing = value
    print("[Aimbot] Smoothing:", aimbotSmoothing)
end

function module.destroy()
    module.toggleAimbot(false)
end

return module
