-- main.luau - Aqwoz Hub
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

-- Vision module
local visionURL = "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/visionScripts.luau"
local visionScripts = loadstring(game:HttpGet(visionURL))()
visionScripts.init()

-- Aimbot module
local aimbotURL = "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/aimbotScripts.luau"
local aimbotScripts = loadstring(game:HttpGet(aimbotURL))()
aimbotScripts.init()

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
    Name = "Enable SilentAim",
    Default = false,
    Callback = function(Value)
        aimbotScripts.toggleAimbot(Value)
    end
})

AimSection:AddSlider({
    Name = "SilentAim FOV",
    Min = 50,
    Max = 500,
    Default = 200,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 10,
    Callback = function(Value)
        aimbotScripts.setFOV(Value)
    end
})

-- Initialize
OrionLib:Init()

