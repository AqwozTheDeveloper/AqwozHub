local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

-- VISION MODULE DEVRE DIŞI (Hatalı olduğu için)
-- local visionURL = "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/visionScripts.luau"
-- local visionScripts = loadstring(game:HttpGet(visionURL))()
-- visionScripts.init()

local Window = OrionLib:MakeWindow({
    Name = "Aqwoz Hub - Fixed", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "OrionConfig"
})

OrionLib:MakeNotification({
    Name = "Welcome to AqwozHub",
    Content = "Fixed version - Vision module disabled due to errors.",
    Image = "rbxassetid://139804491781132",
    Time = 5
})

local AqwozHub = Window:MakeTab({
    Name = "AqwozHub",
    Icon = "rbxassetid://12905962634",
    PremiumOnly = false
})

AqwozHub:AddParagraph("Welcome to AqwozHub!", "This is a fixed version with basic features.")

-- BASIT ESP SİSTEMİ (Vision modülü olmadan)
local ESPEnabled = false
local ESPColor = Color3.fromRGB(255, 255, 255)
local ESPBoxes = {}

local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.Adornee = player.Character
        highlight.FillColor = ESPColor
        highlight.OutlineColor = ESPColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = player.Character
        ESPBoxes[player.Name] = highlight
    end
end

local function removeESP(player)
    if ESPBoxes[player.Name] then
        ESPBoxes[player.Name]:Destroy()
        ESPBoxes[player.Name] = nil
    end
end

local function toggleESP(value)
    ESPEnabled = value
    if value then
        for _, player in pairs(game.Players:GetPlayers()) do
            createESP(player)
        end
    else
        for _, highlight in pairs(ESPBoxes) do
            highlight:Destroy()
        end
        ESPBoxes = {}
    end
end

local VisionTab = Window:MakeTab({
    Name = "Player Vision",
    Icon = "rbxassetid://10906937488",
    PremiumOnly = false
})

VisionTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(Value)
        toggleESP(Value)
    end
})

VisionTab:AddColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        ESPColor = Value
        if ESPEnabled then
            toggleESP(false)
            toggleESP(true)
        end
    end
})

-- Yeni oyuncular için ESP
game.Players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        player.CharacterAdded:Connect(function()
            wait(0.5)
            createESP(player)
        end)
    end
end)

-- Oyuncular ayrıldığında temizle
game.Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

local AimSectionTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://10906937488",
    PremiumOnly = false
})

local AimSection = AimSectionTab:AddSection({
    Name = "Aim Section"
})

AimSection:AddLabel("Aimbot features coming soon...")

-- Initialize Orion
OrionLib:Init()
