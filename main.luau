
local HttpService = game:GetService("HttpService")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Settings persistence
local CONFIG_FILE = "AqwozHubSettings.json"

local defaultSettings = {
    Vision = {
        ESPToggle = false,
        ESP_TeamCheck = false
    },
    Aimbot = {
        AimbotToggle = false,
        TeamCheck = false,
        WallCheck = false,
        Smoothing = 5,
        FOV = 200,
        TargetPart = "Head",
        MaxAngle = 180,
        MaxDistance = 0,
        HoldAim = false,
        FOVCircle = false,
        DynamicSmoothing = false,
        PointerLock = false,
        KeyToggle = false
    },
    SilentAim = {
        SilentAimToggle = false,
        TargetPart = "Head",
        MaxAngle = 180,
        MaxDistance = 0,
        FOVCircle = false
    }
}

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function mergeSettings(base, overrides)
    for k, v in pairs(overrides) do
        if type(v) == "table" and type(base[k]) == "table" then
            mergeSettings(base[k], v)
        else
            base[k] = v
        end
    end
end

local function loadSettings()
    local data = deepCopy(defaultSettings)
    if isfile and isfile(CONFIG_FILE) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and type(decoded) == "table" then
            mergeSettings(data, decoded)
        else
            warn("[AqwozHub] Failed to decode settings:", decoded)
        end
    end
    return data
end

local settings = loadSettings()

local function saveSettings()
    if not writefile then return end
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(settings)
    end)
    if success then
        local ok, err = pcall(function()
            writefile(CONFIG_FILE, encoded)
        end)
        if not ok then
            warn("[AqwozHub] Failed to save settings:", err)
        end
    else
        warn("[AqwozHub] Failed to encode settings:", encoded)
    end
end

local function updateSetting(section, key, value)
    if not settings[section] then
        settings[section] = {}
    end
    settings[section][key] = value
    saveSettings()
end

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

local function setFlagValue(flag, value)
    if Rayfield.Flags and Rayfield.Flags[flag] and Rayfield.Flags[flag].Set then
        Rayfield.Flags[flag]:Set(value)
    end
end

-- Home Tab
MainTab:CreateParagraph({Title = "Welcome!", Content = "Hello, this script is developed by Aqwoz. Updates are on the way."})

-- Vision Tab
VisionTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = settings.Vision.ESPToggle,
   Flag = "ESPToggle",
   Callback = function(Value)
        updateSetting("Vision", "ESPToggle", Value)
        visionScripts.toggleESP(Value)
   end,
})

VisionTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = settings.Vision.ESP_TeamCheck,
   Flag = "ESP_TeamCheck",
   Callback = function(Value)
        updateSetting("Vision", "ESP_TeamCheck", Value)
        visionScripts.toggleTeamCheck(Value)
   end,
})

-- Combat Tab
CombatTab:CreateSection("Aimbot Settings")

CombatTab:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = settings.Aimbot.AimbotToggle,
   Flag = "AimbotToggle",
   Callback = function(Value)
        updateSetting("Aimbot", "AimbotToggle", Value)
        aimbotScripts.toggleAimbot(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = settings.Aimbot.TeamCheck,
   Flag = "TeamCheck",
   Callback = function(Value)
        updateSetting("Aimbot", "TeamCheck", Value)
        aimbotScripts.toggleTeamCheck(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = settings.Aimbot.WallCheck,
   Flag = "WallCheck",
   Callback = function(Value)
        updateSetting("Aimbot", "WallCheck", Value)
        aimbotScripts.toggleWallCheck(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Smoothing",
   Range = {1, 10},
   Increment = 1,
   Suffix = "",
   CurrentValue = settings.Aimbot.Smoothing,
   Flag = "Smoothing",
   Callback = function(Value)
        updateSetting("Aimbot", "Smoothing", Value)
        aimbotScripts.setSmoothing(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Aimbot FOV",
   Range = {10, 500},
   Increment = 10,
   Suffix = "px",
   CurrentValue = settings.Aimbot.FOV,
   Flag = "FOV",
   Callback = function(Value)
        updateSetting("Aimbot", "FOV", Value)
        aimbotScripts.setFOV(Value)
   end,
})

CombatTab:CreateSection("Targeting")

CombatTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "UpperTorso"},
   CurrentOption = settings.Aimbot.TargetPart,
   Flag = "TargetPart",
   Callback = function(Option)
        updateSetting("Aimbot", "TargetPart", Option)
        aimbotScripts.setTargetPart(Option)
   end,
})

CombatTab:CreateSlider({
   Name = "Max Angle",
   Range = {5, 180},
   Increment = 5,
   Suffix = "deg",
   CurrentValue = settings.Aimbot.MaxAngle,
   Flag = "MaxAngle",
   Callback = function(Value)
        updateSetting("Aimbot", "MaxAngle", Value)
        aimbotScripts.setMaxAngle(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Max Distance",
   Range = {0, 1000},
   Increment = 50,
   Suffix = "studs",
   CurrentValue = settings.Aimbot.MaxDistance,
   Flag = "MaxDistance",
   Callback = function(Value)
        updateSetting("Aimbot", "MaxDistance", Value)
        aimbotScripts.setMaxDistance(Value)
   end,
})

CombatTab:CreateSection("Aim Assist UI")

CombatTab:CreateToggle({
   Name = "Hold to Aim (RMB)",
   CurrentValue = settings.Aimbot.HoldAim,
   Flag = "HoldAim",
   Callback = function(Value)
        updateSetting("Aimbot", "HoldAim", Value)
        aimbotScripts.toggleHoldToAim(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = settings.Aimbot.FOVCircle,
   Flag = "FOVCircle",
   Callback = function(Value)
        updateSetting("Aimbot", "FOVCircle", Value)
        aimbotScripts.toggleFOVCircle(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Dynamic Smoothing",
   CurrentValue = settings.Aimbot.DynamicSmoothing,
   Flag = "DynamicSmoothing",
   Callback = function(Value)
        updateSetting("Aimbot", "DynamicSmoothing", Value)
        aimbotScripts.toggleDynamicSmoothing(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Lock Cursor to Target",
   CurrentValue = settings.Aimbot.PointerLock,
   Flag = "PointerLock",
   Callback = function(Value)
        updateSetting("Aimbot", "PointerLock", Value)
        aimbotScripts.togglePointerLock(Value)
   end,
})

CombatTab:CreateSection("Key Toggle")

CombatTab:CreateToggle({
   Name = "Enable F Key Toggle",
   CurrentValue = settings.Aimbot.KeyToggle,
   Flag = "KeyToggle",
   Callback = function(Value)
        updateSetting("Aimbot", "KeyToggle", Value)
        aimbotScripts.toggleKeyToggle(Value)
   end,
})

-- Silent Aim Tab
SilentAimTab:CreateSection("Aimbot Settings")

SilentAimTab:CreateToggle({
   Name = "Enable Silent Aim",
   CurrentValue = settings.SilentAim.SilentAimToggle,
   Flag = "SilentAimToggle",
   Callback = function(Value)
        updateSetting("SilentAim", "SilentAimToggle", Value)
        silentAimScripts.toggleSilentAim(Value)
   end,
})

SilentAimTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = settings.SilentAim.FOVCircle or false,
   Flag = "SilentAim_FOVCircle",
   Callback = function(Value)
        updateSetting("SilentAim", "FOVCircle", Value)
        silentAimScripts.toggleFOVCircle(Value)
   end,
})

SilentAimTab:CreateSection("Targeting")

SilentAimTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "UpperTorso"},
   CurrentOption = settings.SilentAim.TargetPart,
   Flag = "SilentAim_TargetPart",
   Callback = function(Option)
        updateSetting("SilentAim", "TargetPart", Option)
        silentAimScripts.setTargetPart(Option)
   end,
})

SilentAimTab:CreateSlider({
   Name = "Max Angle",
   Range = {5, 180},
   Increment = 5,
   Suffix = "deg",
   CurrentValue = settings.SilentAim.MaxAngle,
   Flag = "SilentAim_MaxAngle",
   Callback = function(Value)
        updateSetting("SilentAim", "MaxAngle", Value)
        silentAimScripts.setMaxAngle(Value)
   end,
})

SilentAimTab:CreateSlider({
   Name = "Max Distance",
   Range = {0, 1000},
   Increment = 50,
   Suffix = "studs",
   CurrentValue = settings.SilentAim.MaxDistance,
   Flag = "SilentAim_MaxDistance",
   Callback = function(Value)
        updateSetting("SilentAim", "MaxDistance", Value)
        silentAimScripts.setMaxDistance(Value)
   end,
})

local function applySavedSettings()
    -- Vision
    visionScripts.toggleESP(settings.Vision.ESPToggle)
    visionScripts.toggleTeamCheck(settings.Vision.ESP_TeamCheck)

    -- Aimbot
    aimbotScripts.setSmoothing(settings.Aimbot.Smoothing)
    aimbotScripts.setFOV(settings.Aimbot.FOV)
    aimbotScripts.setTargetPart(settings.Aimbot.TargetPart)
    aimbotScripts.setMaxAngle(settings.Aimbot.MaxAngle)
    aimbotScripts.setMaxDistance(settings.Aimbot.MaxDistance)
    aimbotScripts.toggleTeamCheck(settings.Aimbot.TeamCheck)
    aimbotScripts.toggleWallCheck(settings.Aimbot.WallCheck)
    aimbotScripts.toggleHoldToAim(settings.Aimbot.HoldAim)
    aimbotScripts.toggleFOVCircle(settings.Aimbot.FOVCircle)
    aimbotScripts.toggleDynamicSmoothing(settings.Aimbot.DynamicSmoothing)
    aimbotScripts.togglePointerLock(settings.Aimbot.PointerLock)
    aimbotScripts.toggleKeyToggle(settings.Aimbot.KeyToggle)
    if settings.Aimbot.AimbotToggle then
        aimbotScripts.toggleAimbot(true)
    end

    -- Silent Aim
    silentAimScripts.setTargetPart(settings.SilentAim.TargetPart)
    silentAimScripts.setMaxAngle(settings.SilentAim.MaxAngle)
    silentAimScripts.setMaxDistance(settings.SilentAim.MaxDistance)
    silentAimScripts.toggleSilentAim(settings.SilentAim.SilentAimToggle)
    silentAimScripts.toggleFOVCircle(settings.SilentAim.FOVCircle)
end

local function syncUIWithSettings()
    local flagValues = {
        ESPToggle = settings.Vision.ESPToggle,
        ESP_TeamCheck = settings.Vision.ESP_TeamCheck,
        AimbotToggle = settings.Aimbot.AimbotToggle,
        TeamCheck = settings.Aimbot.TeamCheck,
        WallCheck = settings.Aimbot.WallCheck,
        Smoothing = settings.Aimbot.Smoothing,
        FOV = settings.Aimbot.FOV,
        TargetPart = settings.Aimbot.TargetPart,
        MaxAngle = settings.Aimbot.MaxAngle,
        MaxDistance = settings.Aimbot.MaxDistance,
        HoldAim = settings.Aimbot.HoldAim,
        FOVCircle = settings.Aimbot.FOVCircle,
        DynamicSmoothing = settings.Aimbot.DynamicSmoothing,
        PointerLock = settings.Aimbot.PointerLock,
        KeyToggle = settings.Aimbot.KeyToggle,
        SilentAimToggle = settings.SilentAim.SilentAimToggle,
        SilentAim_TargetPart = settings.SilentAim.TargetPart,
        SilentAim_MaxAngle = settings.SilentAim.MaxAngle,
        SilentAim_MaxDistance = settings.SilentAim.MaxDistance
    }

    for flagName, value in pairs(flagValues) do
        setFlagValue(flagName, value)
    end
end

applySavedSettings()
syncUIWithSettings()
