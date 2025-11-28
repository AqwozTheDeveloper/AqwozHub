local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local module = {}

local fastReloadEnabled = false
local reloadSpeedMultiplier = 1.5
local reloadCancelEnabled = false
local reloadCancelDelayMs = 150

local inputBeganConn = nil
local watchConn = nil
local cancelDebounce = false

local function getEquippedTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then return child end
    end
    return nil
end

local function getAnimator()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:FindFirstChild("Animator")
    return animator
end

local function isReloadTrack(track)
    local n = tostring(track.Name or "")
    n = string.lower(n)
    if string.find(n, "reload") then return true end
    return false
end

local function doCancel()
    if cancelDebounce then return end
    cancelDebounce = true
    task.delay(reloadCancelDelayMs / 1000, function()
        local tool = getEquippedTool()
        local backpack = LocalPlayer:FindFirstChildOfClass("PlayerGui") and LocalPlayer.Backpack or LocalPlayer:FindFirstChild("Backpack")
        if tool and backpack then
            tool.Parent = backpack
            task.wait(0.05)
            local char = LocalPlayer.Character
            if char then tool.Parent = char end
        end
        cancelDebounce = false
    end)
end

local function watchReload()
    if not fastReloadEnabled and not reloadCancelEnabled then return end
    local animator = getAnimator()
    if not animator then return end
    local tracks = animator:GetPlayingAnimationTracks()
    for _, track in ipairs(tracks) do
        if isReloadTrack(track) then
            if fastReloadEnabled and reloadSpeedMultiplier and reloadSpeedMultiplier > 0 then
                track:AdjustSpeed(reloadSpeedMultiplier)
            end
            if reloadCancelEnabled then
                doCancel()
            end
        end
    end
end

function module.init()
    if not inputBeganConn then
        inputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.R then
                watchReload()
            end
        end)
    end
    if not watchConn then
        watchConn = RunService.RenderStepped:Connect(function()
            watchReload()
        end)
    end
end

function module.toggleFastReload(state)
    fastReloadEnabled = state and true or false
end

function module.setReloadAnimSpeed(value)
    local v = tonumber(value) or reloadSpeedMultiplier
    reloadSpeedMultiplier = math.clamp(v, 1, 5)
end

function module.toggleReloadCancel(state)
    reloadCancelEnabled = state and true or false
end

function module.setReloadCancelDelay(ms)
    local v = tonumber(ms) or reloadCancelDelayMs
    reloadCancelDelayMs = math.clamp(v, 0, 1000)
end

function module.destroy()
    if inputBeganConn then
        inputBeganConn:Disconnect()
        inputBeganConn = nil
    end
    if watchConn then
        watchConn:Disconnect()
        watchConn = nil
    end
end

return module
