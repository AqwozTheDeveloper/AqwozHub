-- aimbotScripts.luau (ACTUALLY SILENT AIM - for Rivals)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local enabled = false
local fov = 200
local isHooked = false
local connection = nil

-- Get screen pos of a world point
local function worldToScreen(pos)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local v, onScreen = cam:WorldToViewportPoint(pos)
    return onScreen and Vector2.new(v.X, v.Y) or nil
end

-- Find closest enemy screen position
local function getClosestTargetScreen()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local bestPos = nil
    local bestDist = fov

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end

        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        local target = plr.Character:FindFirstChild("UpperTorso")  -- Rivals uses this
                     or plr.Character:FindFirstChild("Head")
                     or plr.Character:FindFirstChild("HumanoidRootPart")
        if not (hum and target and hum.Health > 0) then continue end

        local screenPos = worldToScreen(target.Position)
        if not screenPos then continue end

        local dist = (screenPos - mousePos).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestPos = screenPos
        end
    end

    return bestPos
end

-- Silent aim on mouse click
local function onInputBegan(input, gameProcessed)
    if not enabled or gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local target = getClosestTargetScreen()
    if not target then return end

    local original = UserInputService:GetMouseLocation()
    UserInputService:SetMousePosition(target.X, target.Y)

    -- Restore instantly next frame
    spawn(function()
        RunService.Heartbeat:Wait()
        UserInputService:SetMousePosition(original.X, original.Y)
    end)
end

-- Public API (matches your main.luau)
local module = {}

function module.init()
    print("[SilentAim] Loaded.")
end

function module.toggleAimbot(state)  -- Must match your main.luau
    enabled = state
    print("[SilentAim]", state and "Enabled" or "Disabled")

    if state and not isHooked then
        connection = UserInputService.InputBegan:Connect(onInputBegan)
        isHooked = true
    elseif not state and isHooked then
        if connection then
            connection:Disconnect()
            connection = nil
        end
        isHooked = false
    end
end

function module.setFOV(value)  -- Must match your main.luau
    fov = math.clamp(value, 10, 1000)
    print("[SilentAim] FOV:", fov)
end

function module.destroy()
    module.toggleAimbot(false)
end

return module
