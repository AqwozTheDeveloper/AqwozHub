
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
        return {
            init = function() end,
            toggleESP = function() end,
            toggleAimbot = function() end,
            setFOV = function() end,
            setSmoothing = function() end,
            toggleTeamCheck = function() end,
            toggleWallCheck = function() end,
            toggleHoldToAim = function() end,
            toggleFOVCircle = function() end,
            toggleKeyToggle = function() end,
            setToggleKey = function() end,
            setTargetPart = function() end,
            setMaxAngle = function() end,
            setMaxDistance = function() end,
            toggleDynamicSmoothing = function() end,
            togglePointerLock = function() end
        }
    end
end

-- Vision module
local visionScripts = loadModule("visionScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHubLegacy/refs/heads/main/AqwozHub-main/visionScripts.luau")
visionScripts.init()

-- Aimbot module
local aimbotScripts = loadModule("aimbotScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHubLegacy/refs/heads/main/AqwozHub-main/aimbotScripts.luau")
aimbotScripts.init()

-- Silent Aim module
local silentAimScripts = loadModule("silentAimScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHubLegacy/refs/heads/main/AqwozHub-main/silentAimScripts.luau")
silentAimScripts.init()

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
local SilentAimTab = Window:CreateTab("Silent Aim", 4483362458)

-- Home Tab
MainTab:CreateParagraph({Title = "Welcome!", Content = "Hello, this script is developed by Aqwoz. Updates are on the way."})

-- Vision Tab
VisionTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESPToggle",
   Callback = function(Value)
        visionScripts.toggleESP(Value)
   end,
})

VisionTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Flag = "ESP_TeamCheck",
   Callback = function(Value)
        visionScripts.toggleTeamCheck(Value)
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

CombatTab:CreateSection("Targeting")

CombatTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "UpperTorso"},
   CurrentOption = "Head",
   Flag = "TargetPart",
   Callback = function(Option)
        aimbotScripts.setTargetPart(Option)
   end,
})

CombatTab:CreateSlider({
   Name = "Max Angle",
   Range = {5, 180},
   Increment = 5,
   Suffix = "deg",
   CurrentValue = 180,
   Flag = "MaxAngle",
   Callback = function(Value)
        aimbotScripts.setMaxAngle(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Max Distance",
   Range = {0, 1000},
   Increment = 50,
   Suffix = "studs",
   CurrentValue = 0,
   Flag = "MaxDistance",
   Callback = function(Value)
        aimbotScripts.setMaxDistance(Value)
   end,
})

CombatTab:CreateSection("Aim Assist UI")

CombatTab:CreateToggle({
   Name = "Hold to Aim (RMB)",
   CurrentValue = false,
   Flag = "HoldAim",
   Callback = function(Value)
        aimbotScripts.toggleHoldToAim(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Flag = "FOVCircle",
   Callback = function(Value)
        aimbotScripts.toggleFOVCircle(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Dynamic Smoothing",
   CurrentValue = false,
   Flag = "DynamicSmoothing",
   Callback = function(Value)
        aimbotScripts.toggleDynamicSmoothing(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Lock Cursor to Target",
   CurrentValue = false,
   Flag = "PointerLock",
   Callback = function(Value)
        aimbotScripts.togglePointerLock(Value)
   end,
})

CombatTab:CreateSection("Key Toggle")

CombatTab:CreateToggle({
   Name = "Enable F Key Toggle",
   CurrentValue = false,
   Flag = "KeyToggle",
   Callback = function(Value)
        aimbotScripts.toggleKeyToggle(Value)
   end,
})

-- Silent Aim Tab
SilentAimTab:CreateSection("Aimbot Settings")

SilentAimTab:CreateToggle({
   Name = "Enable Silent Aim",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
        silentAimScripts.toggleSilentAim(Value)
   end,
})

SilentAimTab:CreateSection("Targeting")

SilentAimTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "UpperTorso"},
   CurrentOption = "Head",
   Flag = "SilentAim_TargetPart",
   Callback = function(Option)
        silentAimScripts.setTargetPart(Option)
   end,
})

SilentAimTab:CreateSlider({
   Name = "Max Angle",
   Range = {5, 180},
   Increment = 5,
   Suffix = "deg",
   CurrentValue = 180,
   Flag = "SilentAim_MaxAngle",
   Callback = function(Value)
        silentAimScripts.setMaxAngle(Value)
   end,
})

SilentAimTab:CreateSlider({
   Name = "Max Distance",
   Range = {0, 1000},
   Increment = 50,
   Suffix = "studs",
   CurrentValue = 0,
   Flag = "SilentAim_MaxDistance",
   Callback = function(Value)
        silentAimScripts.setMaxDistance(Value)
   end,
})
