-- visionScripts.luau (Safe Version - No Nil Errors)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ESPFolder = nil

local module = {}

local espEnabled = false
local espColor = Color3.fromRGB(255, 255, 255)

-- Initialize ESP folder safely
local function initESP()
    if ESPFolder then return end
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "ESP"
    ESPFolder.Parent = Workspace
end

-- Create ESP box for player
local function createESP(player)
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local espBox = Instance.new("BoxHandleAdornment")
    espBox.Adornee = head
    espBox.Size = Vector3.new(2, 2, 2)
    espBox.Color3 = espColor
    espBox.Transparency = 0.5
    espBox.AlwaysOnTop = true
    espBox.ZIndex = 1
    espBox.Parent = ESPFolder
    return espBox
end

-- Update all ESPs
local function updateESP()
    if not espEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Check if ESP already exists
            local existing = ESPFolder:FindFirstChild(player.Name)
            if not existing then
                local esp = createESP(player)
                if esp then
                    esp.Name = player.Name
                end
            end
        end
    end
end

-- Public API
function module.init()
    print("[Vision] Initializing...")
    initESP()
    print("[Vision] Module initialized successfully!")
end

function module.toggleESP(state)
    espEnabled = state
    print("[Vision] ESP:", state and "Enabled" or "Disabled")

    if state then
        RunService.RenderStepped:Connect(updateESP)
    else
        -- Clean up ESP
        if ESPFolder then
            for _, child in ipairs(ESPFolder:GetChildren()) do
                child:Destroy()
            end
        end
    end
end

function module.setESPColor(color)
    espColor = color
    print("[Vision] ESP color set to:", color)
end

return module
