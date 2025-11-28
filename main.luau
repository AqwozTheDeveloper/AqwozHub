-- main.luau - Aqwoz Hub (Rayfield Edition)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
local Window = Rayfield:CreateWindow({
    Name = "Aqwoz Hub",
    LoadingTitle = "Aqwoz Hub",
    LoadingSubtitle = "by AqwozTheDeveloper",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "AqwozHubConfig",
       FileName = "AqwozHub"
    },
    Discord = {
       Enabled = false,
       Invite = "noinvitelink",
       RememberJoins = true
    },
    KeySystem = false,
})

-- Notification
Rayfield:Notify({
   Title = "Welcome to AqwozHub",
   Content = "Script loaded successfully! Testing version.",
   Duration = 5,
   Image = 4483362458,
})

-- Tabs
local MainTab = Window:CreateTab("Home", 4483362458) -- Title, Image
local VisionTab = Window:CreateTab("Visuals", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)

-- Home Tab
MainTab:CreateParagraph({Title = "Welcome!", Content = "Hello, this script is developed by Aqwoz. Updates are on the way."})

-- Vision Tab
VisionTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESPToggle", -- A flag is the identifier for the configuration file
   Callback = function(Value)
        visionScripts.toggleESP(Value)
   end,
})

-- Combat Tab
CombatTab:CreateSection("Aimbot Settings")

CombatTab:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
        aimbotScripts.toggleAimbot(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Silent Aim",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
        aimbotScripts.toggleSilentAim(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Flag = "TeamCheck",
   Callback = function(Value)
        aimbotScripts.toggleTeamCheck(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = false,
   Flag = "WallCheck",
   Callback = function(Value)
        aimbotScripts.toggleWallCheck(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Smoothing",
   Range = {1, 10},
   Increment = 1,
   Suffix = "",
   CurrentValue = 5,
   Flag = "Smoothing",
   Callback = function(Value)
        aimbotScripts.setSmoothing(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Aimbot FOV",
   Range = {10, 500},
   Increment = 10,
   Suffix = "px",
   CurrentValue = 200,
   Flag = "FOV",
   Callback = function(Value)
        aimbotScripts.setFOV(Value)
   end,
})

CombatTab:CreateSection("FOV Circle Settings")

CombatTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Flag = "FOVCircleToggle",
   Callback = function(Value)
        aimbotScripts.toggleFOVCircle(Value)
   end,
})

CombatTab:CreateColorPicker({
   Name = "FOV Circle Color",
   Color = Color3.fromRGB(255, 255, 255),
   Flag = "FOVCircleColor",
   Callback = function(Value)
        aimbotScripts.setFOVCircleColor(Value)
   end,
})