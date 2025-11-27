-- silentAim.luau (Rivals-Compatible Silent Aim)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local SilentAim = {}

local enabled = false
local fov = 200
local ignoreWalls = false
local isHooked = false
local connection = nil

-- Helper: Get screen position of a world point
local function worldToScreen(worldPos)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local pos, onScreen = cam:WorldToViewportPoint(worldPos)
    return onScreen and Vector2.new(pos.X, pos.Y) or nil
end

-- Helper: Check if enemy is visible (not behind wall)
local function isVisible(fromPos, toPos)
    local ray = Ray.new(fromPos, (toPos - fromPos).unit * (toPos - fromPos).magnitude)
    local part, _ = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return not part
end

-- Find closest valid enemy's screen position
local function getClosestTargetScreen()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local bestPos = nil
    local bestDist = fov

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end

        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local targetPart = player.Character:FindFirstChild("UpperTorso")  -- Rivals uses this
            or player.Character:FindFirstChild("Head")
            or player.Character:FindFirstChild("HumanoidRootPart")

        if not (hum and targetPart and hum.Health > 0) then continue end

        local screenPos = worldToScreen(targetPart.Position)
        if not screenPos then continue end

        -- Wall check (optional)
        if not ignoreWalls then
            local camPos = cam.CFrame.Position
            if not isVisible(camPos, targetPart.Position) then continue end
        end

        local dist = (screenPos - mousePos).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestPos = screenPos
        end
    end

    return bestPos
end

-- Hook: Only move mouse on left-click
local function onInputBegan(input, gameProcessed)
    -- Only fire if enabled, not typing, and left mouse button
    if not enabled or gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    local targetScreen = getClosestTargetScreen()
    if not targetScreen then return end

    -- Save original mouse position
    local orig = UserInputService:GetMouseLocation()

    -- Move mouse to target (for this shot)
    UserInputService:SetMousePosition(targetScreen.X, targetScreen.Y)

    -- Restore original position NEXT FRAME (so player sees no flicker)
    spawn(function()
        RunService.Heartbeat:Wait()
        UserInputService:SetMousePosition(orig.X, orig.Y)
    end)
end

-- Public API
function SilentAim.toggle(state)
    enabled = state
    print("[Silent Aim] " .. (state and "Enabled" or "Disabled"))

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

function SilentAim.setFOV(value)
    fov = math.clamp(value, 10, 1000)
    print("[Silent Aim] FOV:", fov)
end

function SilentAim.setIgnoreWalls(state)
    ignoreWalls = state
    print("[Silent Aim] Ignore Walls:", state)
end

function SilentAim.destroy()
    SilentAim.toggle(false)
end

return SilentAim
