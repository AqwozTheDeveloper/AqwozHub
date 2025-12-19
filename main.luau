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
            toggleSilentAim = function() end,
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
            togglePointerLock = function() end,
            toggleDistance = function() end,
            toggleHealth = function() end,
            toggleTracers = function() end,
            toggleNames = function() end,
            setTracerOrigin = function() end,
            setBoxThickness = function() end,
            -- Advanced aimbot functions
            togglePrediction = function() end,
            setPredictionMultiplier = function() end,
            toggleStickyTarget = function() end,
            toggleTriggerBot = function() end,
            setTriggerDelay = function() end,
            setAimOffset = function() end,
            setTargetPriority = function() end,
            addToIgnoreList = function() end,
            removeFromIgnoreList = function() end,
            clearIgnoreList = function() end,
            -- Silent aim functions (already had toggleSilentAim above)
            getCurrentTarget = function() end,
            destroy = function() end
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

CombatTab:CreateToggle({
   Name = "Target Head",
   CurrentValue = true,
   Flag = "TargetHead",
   Callback = function(Value)
        if Value then aimbotScripts.setTargetPart("Head") end
   end,
})

CombatTab:CreateToggle({
   Name = "Target UpperTorso",
   CurrentValue = false,
   Flag = "TargetUpperTorso",
   Callback = function(Value)
        if Value then aimbotScripts.setTargetPart("UpperTorso") end
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

CombatTab:CreateSection("Advanced Aimbot")

CombatTab:CreateToggle({
   Name = "Prediction (Velocity Leading)",
   CurrentValue = false,
   Flag = "Prediction",
   Callback = function(Value)
        aimbotScripts.togglePrediction(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Prediction Strength",
   Range = {0.1, 5},
   Increment = 0.1,
   Suffix = "x",
   CurrentValue = 1.0,
   Flag = "PredictionMultiplier",
   Callback = function(Value)
        aimbotScripts.setPredictionMultiplier(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Sticky Target (Stay Locked)",
   CurrentValue = false,
   Flag = "StickyTarget",
   Callback = function(Value)
        aimbotScripts.toggleStickyTarget(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Trigger Bot",
   CurrentValue = false,
   Flag = "TriggerBot",
   Callback = function(Value)
        aimbotScripts.toggleTriggerBot(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Trigger Delay",
   Range = {0, 1},
   Increment = 0.05,
   Suffix = "s",
   CurrentValue = 0.1,
   Flag = "TriggerDelay",
   Callback = function(Value)
        aimbotScripts.setTriggerDelay(Value)
   end,
})

CombatTab:CreateDropdown({
   Name = "Target Priority",
   Options = {"closest", "lowest_health", "highest_threat"},
   CurrentOption = "closest",
   Flag = "TargetPriority",
   Callback = function(Value)
        aimbotScripts.setTargetPriority(Value)
   end,
})

CombatTab:CreateSection("Silent Aim")

CombatTab:CreateToggle({
   Name = "Enable Silent Aim",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
        silentAimScripts.toggleSilentAim(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Silent Aim FOV",
   Range = {10, 500},
   Increment = 10,
   Suffix = "px",
   CurrentValue = 200,
   Flag = "SilentAimFOV",
   Callback = function(Value)
        silentAimScripts.setFOV(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Silent Aim Team Check",
   CurrentValue = false,
   Flag = "SilentAimTeamCheck",
   Callback = function(Value)
        silentAimScripts.toggleTeamCheck(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Silent Aim Wall Check",
   CurrentValue = false,
   Flag = "SilentAimWallCheck",
   Callback = function(Value)
        silentAimScripts.toggleWallCheck(Value)
   end,
})

CombatTab:CreateDropdown({
   Name = "Silent Aim Target Part",
   Options = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"},
   CurrentOption = "Head",
   Flag = "SilentAimTargetPart",
   Callback = function(Value)
        silentAimScripts.setTargetPart(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Silent Aim Max Distance",
   Range = {0, 1000},
   Increment = 50,
   Suffix = " studs",
   CurrentValue = 0,
   Flag = "SilentAimMaxDistance",
   Callback = function(Value)
        silentAimScripts.setMaxDistance(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Show Silent Aim FOV Circle",
   CurrentValue = false,
   Flag = "SilentAimFOVCircle",
   Callback = function(Value)
        silentAimScripts.toggleFOVCircle(Value)
   end,
})

-- Vision Tab Enhancements
VisionTab:CreateSection("ESP Options")

VisionTab:CreateToggle({
   Name = "Show Distance",
   CurrentValue = false,
   Flag = "ShowDistance",
   Callback = function(Value)
        visionScripts.toggleDistance(Value)
   end,
})

VisionTab:CreateToggle({
   Name = "Show Health Bars",
   CurrentValue = false,
   Flag = "ShowHealth",
   Callback = function(Value)
        visionScripts.toggleHealth(Value)
   end,
})

VisionTab:CreateToggle({
   Name = "Show Name Tags",
   CurrentValue = false,
   Flag = "ShowNames",
   Callback = function(Value)
        visionScripts.toggleNames(Value)
   end,
})

VisionTab:CreateToggle({
   Name = "Show Tracers",
   CurrentValue = false,
   Flag = "ShowTracers",
   Callback = function(Value)
        visionScripts.toggleTracers(Value)
   end,
})

VisionTab:CreateDropdown({
   Name = "Tracer Origin",
   Options = {"Bottom", "Center", "Mouse"},
   CurrentOption = "Bottom",
   Flag = "TracerOrigin",
   Callback = function(Value)
        visionScripts.setTracerOrigin(Value)
   end,
})

VisionTab:CreateSlider({
   Name = "Max ESP Distance",
   Range = {100, 2000},
   Increment = 50,
   Suffix = " studs",
   CurrentValue = 500,
   Flag = "MaxESPDistance",
   Callback = function(Value)
        visionScripts.setMaxDistance(Value)
   end,
})
