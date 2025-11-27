-- main.luau - Aqwoz Hub
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

-- Vision module'u GitHub'dan çek (senin fixed versiyonunu kullan)
local visionURL = "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/visionScripts.luau"
local visionScripts = loadstring(game:HttpGet(visionURL))()

-- Module'u başlat
visionScripts.init()

-- Window
local Window = OrionLib:MakeWindow({
    Name = "Aqwoz Hub", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "OrionConfig"
})

-- Notification
OrionLib:MakeNotification({
    Name = "Welcome to AqwozHub",
    Content = "Welcome to AqwozHub, it's a testing version.",
    Image = "rbxassetid://139804491781132",
    Time = 5
})

-- Ana Tab
local AqwozHub = Window:MakeTab({
    Name = "AqwozHub",
    Icon = "rbxassetid://12905962634",
    PremiumOnly = false
})

AqwozHub:AddParagraph("Welcome to AqwozHub!", "Hello, this script is only getting developed by one person. Updates are on the way.")

-- Vision Tab
local VisionTab = Window:MakeTab({
    Name = "Player Vision",
    Icon = "rbxassetid://10906937488",
    PremiumOnly = false
})

VisionTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(Value)
        visionScripts.toggleESP(Value)
    end
})

VisionTab:AddColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        visionScripts.setESPColor(Value)
    end
})

-- Aimbot Tab
local AimSectionTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://10906937488",
    PremiumOnly = false
})

local AimSection = AimSectionTab:AddSection({
    Name = "Aim Section"
})

AimSection:AddToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(Value)
        print("Aimbot: " .. tostring(Value))
        -- Aimbot fonksiyonu buraya gelecek
    end
})

AimSection:AddSlider({
    Name = "Aimbot FOV",
    Min = 50,
    Max = 500,
    Default = 200,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 10,
    Callback = function(Value)
        print("FOV: " .. Value)
    end
})

-- Initialize
OrionLib:Init()
