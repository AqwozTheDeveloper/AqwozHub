local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local module = {}

local espFolder = nil
local espEnabled = false
local characterConnections = {}
local lineCache = {}

-- ESP oluşturma fonksiyonu
local function createESP(character)
    task.wait(0.1)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or not espEnabled then return end

    -- BoxHandleAdornment
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPBox"
    box.Size = Vector3.new(4, 6, 4)
    box.Color3 = Color3.fromRGB(0, 255, 100)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Adornee = hrp
    box.Parent = espFolder

    -- Drawing line
    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(0,255,100)
    line.Thickness = 1.5
    line.Transparency = 1
    line.Visible = true
    lineCache[character.Parent] = line

    -- Render loop for line
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not hrp or not espEnabled or hrp.Parent ~= character then
            line.Visible = false
            line:Remove()
            lineCache[character.Parent] = nil
            conn:Disconnect()
            return
        end

        local screenPos, vis = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        if vis then
            line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y)
            line.To = Vector2.new(screenPos.X, screenPos.Y)
            line.Visible = true
        else
            line.Visible = false
        end
    end)
end

local function setupPlayer(plr)
    if plr == Players.LocalPlayer then return end

    characterConnections[plr] = plr.CharacterAdded:Connect(function(char)
        if espEnabled then
            createESP(char)
        end
    end)

    if plr.Character and espEnabled then
        createESP(plr.Character)
    end
end

-- MODULE API
function module.init()
    espFolder = Instance.new("Folder", workspace)
    espFolder.Name = "VisionESP"

    for _,plr in ipairs(Players:GetPlayers()) do
        setupPlayer(plr)
    end

    Players.PlayerAdded:Connect(setupPlayer)
end

function module.toggleESP(state)
    espEnabled = state

    if not state then
        -- Tüm box ve çizgileri temizle
        if espFolder then espFolder:ClearAllChildren() end
        for _,line in pairs(lineCache) do
            line:Remove()
        end
        lineCache = {}
        return
    end

    -- ESP ON → recreate
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            createESP(plr.Character)
        end
    end
end

function module.destroy()
    espEnabled = false
    if espFolder then espFolder:Destroy() espFolder=nil end
    for plr,conn in pairs(characterConnections) do
        conn:Disconnect()
    end
    characterConnections = {}

    for _,line in pairs(lineCache) do
        line:Remove()
    end
    lineCache = {}
end

return module
