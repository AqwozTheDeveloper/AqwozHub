-- main.luau - Aqwoz Hub
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

-- Module Loader
local function loadModule(path, url)
    -- 1. Try local file
    if isfile and isfile(path) then
        print("[AqwozHub] Found local file: " .. path)
        local success, result = pcall(function()
            return loadstring(readfile(path))()
        end)

        if success then
            print("[AqwozHub] Successfully loaded local module: " .. path)
            return result
        else
            warn("[AqwozHub] Error loading local file: " .. tostring(result))
        end
    else
        print("[AqwozHub] Local file not found: " .. path)
    end

    -- 2. Fallback to GitHub URL with cache busting
    print("[AqwozHub] Fetching from URL: " .. url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url .. "?t=" .. tostring(math.random(1, 1000000))))()
    end)

    if success then
        print("[AqwozHub] Successfully loaded remote module")
        return result
    else
        warn("[AqwozHub] Critical Error loading module: " .. tostring(result))
        -- Return dummy object to prevent crash
        return { init = function() end, toggleESP = function() end, toggleAimbot = function() end, setFOV = function() end }
    end
end

-- Vision module
local visionScripts = loadModule("AqwozHub/visionScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/visionScripts.luau")
visionScripts.init()

-- Aimbot module
local aimbotScripts = loadModule("AqwozHub/aimbotScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/aimbotScripts.luau")
aimbotScripts.init()

-- Window
local Window = OrionLib:MakeWindow({
    Name = "Aqwoz Hub",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "OrionConfig",
    IntroEnabled = false
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
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(Value)
        aimbotScripts.toggleAimbot(Value)
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
        aimbotScripts.setFOV(Value)
    end
})

-- Initialize
OrionLib:Init()
