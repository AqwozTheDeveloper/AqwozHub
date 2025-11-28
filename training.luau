local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local module = {}

local folder = nil
local targets = {}
local moveEnabled = false
local moveConn = nil
local statsEnabled = false
local statsGui = nil
local statsLabel = nil
local statsConn = nil
local shots = 0
local hits = 0
local inputConn = nil

local function ensureFolder()
    if folder and folder.Parent == workspace then return true end
    folder = Instance.new("Folder")
    folder.Name = "AqwozTraining"
    folder.Parent = workspace
    return true
end

function module.init()
    ensureFolder()
    if not inputConn then
        inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shots += 1
                local mouse = UserInputService:GetMouseLocation()
                local origin = Camera.CFrame.Position
                local dir = (Camera:ScreenPointToRay(mouse.X, mouse.Y).Direction) * 1000
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {}
                local result = workspace:Raycast(origin, dir, params)
                if result and result.Instance and result.Instance:IsDescendantOf(folder) then
                    hits += 1
                end
            end
        end)
    end
end

local function clearTargets()
    for _, t in ipairs(targets) do
        if t and t.Parent then t:Destroy() end
    end
    targets = {}
end

function module.spawnTargets(count)
    ensureFolder()
    clearTargets()
    local c = math.clamp(tonumber(count) or 1, 1, 20)
    for i = 1, c do
        local p = Instance.new("Part")
        p.Size = Vector3.new(3, 6, 1)
        p.Color = Color3.fromRGB(255, 60, 60)
        p.Anchored = true
        p.CanCollide = false
        p.Name = "Target" .. tostring(i)
        p.Position = Vector3.new(math.random(-50, 50), 5 + math.random(0, 10), math.random(-50, 50))
        p.Parent = folder
        table.insert(targets, p)
    end
end

local function updateMovement(dt)
    if not moveEnabled then return end
    for idx, p in ipairs(targets) do
        local t = tick() + idx
        local x = math.sin(t * 0.7) * 15
        local z = math.cos(t * 0.6) * 15
        local y = 5 + math.sin(t * 1.1) * 2
        local base = Vector3.new(0, 0, 0)
        p.Position = Vector3.new(base.X + x, y, base.Z + z) + Vector3.new(idx * 4, 0, 0)
    end
end

function module.toggleMovement(state)
    moveEnabled = state and true or false
    if moveEnabled then
        if not moveConn then
            moveConn = RunService.RenderStepped:Connect(function(dt)
                updateMovement(dt)
            end)
        end
    else
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end
    end
end

local function ensureStatsGui()
    if statsGui and statsLabel then return true end
    local pg = Players.LocalPlayer:FindFirstChild("PlayerGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
    if not pg then return false end
    statsGui = Instance.new("ScreenGui")
    statsGui.Name = "AqwozTrainingStats"
    statsGui.IgnoreGuiInset = true
    statsGui.ResetOnSpawn = false
    statsGui.Parent = pg
    statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.fromOffset(180, 50)
    statsLabel.Position = UDim2.fromOffset(20, 100)
    statsLabel.BackgroundTransparency = 0.4
    statsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsLabel.Font = Enum.Font.Code
    statsLabel.TextScaled = false
    statsLabel.Text = ""
    statsLabel.ZIndex = 200
    statsLabel.Parent = statsGui
    return true
end

local function updateStats()
    if shots <= 0 then
        statsLabel.Text = "Shots: 0\nHits: 0\nAcc: 0%"
        return
    end
    local acc = math.floor((hits / shots) * 100)
    statsLabel.Text = string.format("Shots: %d\nHits: %d\nAcc: %d%%", shots, hits, acc)
end

function module.toggleStats(state)
    statsEnabled = state and true or false
    if statsEnabled then
        if ensureStatsGui() then
            updateStats()
            if not statsConn then
                statsConn = RunService.RenderStepped:Connect(updateStats)
            end
        end
    else
        if statsConn then
            statsConn:Disconnect()
            statsConn = nil
        end
        if statsGui then
            statsGui:Destroy()
            statsGui = nil
            statsLabel = nil
        end
    end
end

function module.reset()
    clearTargets()
    shots = 0
    hits = 0
    if statsEnabled then
        updateStats()
    end
end

function module.destroy()
    if moveConn then
        moveConn:Disconnect()
        moveConn = nil
    end
    if statsConn then
        statsConn:Disconnect()
        statsConn = nil
    end
    if inputConn then
        inputConn:Disconnect()
        inputConn = nil
    end
    if statsGui then
        statsGui:Destroy()
        statsGui = nil
        statsLabel = nil
    end
    if folder then
        folder:Destroy()
        folder = nil
    end
    targets = {}
end

return module
