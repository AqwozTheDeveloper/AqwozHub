-- silentAim_remote.luau (Rivals-Compatible - Safe Hook)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local SilentAim = {}

local enabled = false
local fov = 200
local ignoreWalls = false
local originalFire = nil
local fireRemote = nil

-- Helper: Get screen position of world point
local function worldToScreen(worldPos)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local pos, onScreen = cam:WorldToViewportPoint(worldPos)
    return onScreen and Vector2.new(pos.X, pos.Y) or nil
end

-- Helper: Check line of sight
local function isVisible(fromPos, toPos)
    local ray = Ray.new(fromPos, (toPos - fromPos).unit * (toPos - fromPos).magnitude)
    local part, _ = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return not part
end

-- Find closest enemy's position
local function getClosestTargetPosition()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local bestPos = nil
    local bestDist = fov

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end

        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local targetPart = player.Character:FindFirstChild("UpperTorso")
            or player.Character:FindFirstChild("Head")
            or player.Character:FindFirstChild("HumanoidRootPart")

        if not (hum and targetPart and hum.Health > 0) then continue end

        local screenPos = worldToScreen(targetPart.Position)
        if not screenPos then continue end

        -- Wall check
        if not ignoreWalls then
            local camPos = cam.CFrame.Position
            if not isVisible(camPos, targetPart.Position) then continue end
        end

        local dist = (screenPos - mousePos).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestPos = targetPart.Position
        end
    end

    return bestPos
end

-- 🔍 Auto-detect fire remote (common names in Rivals)
local function findFireRemote()
    local remotes = {
        ReplicatedStorage:FindFirstChild("WeaponFire"),
        ReplicatedStorage:FindFirstChild("Shoot"),
        ReplicatedStorage:FindFirstChild("Attack"),
        ReplicatedStorage:FindFirstChild("Fire"),
        ReplicatedStorage:FindFirstChild("Hit"),
        game.ReplicatedStorage.Remotes:FindFirstChild("WeaponFire") -- Try nested folder
    }

    for _, remote in ipairs(remotes) do
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
            return remote
        end
    end

    -- Wait for it to appear (if not loaded yet)
    local waitCount = 0
    while waitCount < 50 and not fireRemote do
        waitCount = waitCount + 1
        for _, remote in ipairs(remotes) do
            if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                fireRemote = remote
                print("[Silent Aim] Found fire remote:", remote.Name)
                return remote
            end
        end
        task.wait(0.1)
    end

    warn("[Silent Aim] Could not find fire remote. Falling back to mouse method.")
    return nil
end

-- Hook fire remote
local function hookFireRemote()
    if not fireRemote then
        fireRemote = findFireRemote()
        if not fireRemote then return end
    end

    if originalFire then return end -- Already hooked

    originalFire = fireRemote.FireServer
    fireRemote.FireServer = function(self, ...)
        if enabled then
            local targetPos = getClosestTargetPosition()
            if targetPos then
                -- Modify args: replace hit position with target position
                local args = {...}
                -- Assuming first arg is hit position (adjust based on Rivals' structure)
                args[1] = targetPos  -- ⚠️ This may need adjustment!
                return originalFire(self, unpack(args))
            end
        end
        return originalFire(self, ...)
    end

    print("[Silent Aim] Fire remote hooked successfully.")
end

-- Public API
function SilentAim.toggle(state)
    enabled = state
    print("[Silent Aim] " .. (state and "Enabled" or "Disabled"))

    if state then
        hookFireRemote() -- Ensure remote is hooked
    else
        if originalFire and fireRemote then
            fireRemote.FireServer = originalFire
            originalFire = nil
        end
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

-- Auto-initialize when character loads
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(2) -- Give time for remotes to load
    if enabled then
        hookFireRemote()
    end
end)

return SilentAim
