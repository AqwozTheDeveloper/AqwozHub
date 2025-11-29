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
            togglePointerLock = function() end,
            togglePointerADSOnly = function() end,
            setFOVCircleColor = function() end,
            setFOVStrokeThickness = function() end,
            setPointerSize = function() end,
            setPointerColor = function() end,
            toggleDebug = function() end,
            toggleLead = function() end,
            setProjectileSpeed = function() end,
            setStickyLockMs = function() end,
            setSnapAngle = function() end,
            setMaxTurnRateDeg = function() end,
            setAimCurve = function() end,
            toggleADSOnlyLock = function() end,
            toggleFastReload = function() end,
            setReloadAnimSpeed = function() end,
            toggleReloadCancel = function() end,
            setReloadCancelDelay = function() end
        }
    end
end

-- Vision module
local visionScripts = loadModule("visionScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/visionScripts.luau")
visionScripts.init()

-- Aim utils
local aimUtils = loadModule("aimUtils.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/aimUtils.luau")
local profileManager = loadModule("profileManager.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/profileManager.luau")

-- Aimbot module
local aimbotScripts = loadModule("aimbotScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/aimbotScripts.luau")
aimbotScripts.init()
local currentAimbot = aimbotScripts
local gameplayScripts = loadModule("gameplayScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/gameplayScripts.luau")
gameplayScripts.init()
profileManager.init()

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
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local DebugTab = Window:CreateTab("Debug", 4483362458)
local TrainingTab = Window:CreateTab("Training", 4483362458)
local WeaponsTab = Window:CreateTab("Weapons", 4483362458)
local ProfilesTab = Window:CreateTab("Profiles", 4483362458)

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
   CurrentValue = true,
   Flag = "TeamCheck",
   Callback = function(Value)
        aimbotScripts.toggleTeamCheck(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "Exclude Friends",
   CurrentValue = false,
   Flag = "FriendExclude",
   Callback = function(Value)
        aimbotScripts.toggleFriendExclude(Value)
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

CombatTab:CreateToggle({
   Name = "Enable Velocity Lead",
   CurrentValue = false,
   Flag = "LeadEnable",
   Callback = function(Value)
        aimbotScripts.toggleLead(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Projectile Speed",
   Range = {0, 1000},
   Increment = 25,
   Suffix = "u/s",
   CurrentValue = 0,
   Flag = "ProjectileSpeed",
   Callback = function(Value)
        aimbotScripts.setProjectileSpeed(Value)
   end,
})

CombatTab:CreateSection("Aim Tuning")

CombatTab:CreateSlider({
   Name = "Sticky Lock Window",
   Range = {0, 2000},
   Increment = 50,
   Suffix = "ms",
   CurrentValue = 200,
   Flag = "StickyLockMs",
   Callback = function(Value)
        aimbotScripts.setStickyLockMs(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Snap Angle",
   Range = {0, 30},
   Increment = 1,
   Suffix = "deg",
   CurrentValue = 6,
   Flag = "SnapAngle",
   Callback = function(Value)
        aimbotScripts.setSnapAngle(Value)
   end,
})

CombatTab:CreateSlider({
   Name = "Max Turn Rate",
   Range = {0, 90},
   Increment = 5,
   Suffix = "deg/frame",
   CurrentValue = 0,
   Flag = "MaxTurnRate",
   Callback = function(Value)
        aimbotScripts.setMaxTurnRateDeg(Value)
   end,
})

CombatTab:CreateDropdown({
   Name = "Aim Curve",
   Options = {"Linear", "EaseIn", "EaseOut", "EaseInOut"},
   CurrentOption = "Linear",
   Flag = "AimCurve",
   Callback = function(Value)
        aimbotScripts.setAimCurve(Value)
   end,
})

CombatTab:CreateToggle({
   Name = "ADS-only Aim Lock",
   CurrentValue = false,
   Flag = "ADSOnlyLock",
   Callback = function(Value)
        aimbotScripts.toggleADSOnlyLock(Value)
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

CombatTab:CreateToggle({
   Name = "Use Legacy Aimbot",
   CurrentValue = false,
   Flag = "LegacyAimbot",
   Callback = function(Value)
        local flags = collectFlags()
        if Value then
            if currentAimbot and currentAimbot.destroy then currentAimbot.destroy() end
            local legacy = loadModule("oldworkingaim.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/oldworkingaim.luau")
            legacy.init()
            aimbotScripts = legacy
            currentAimbot = legacy
            applyFlags(flags)
        else
            if currentAimbot and currentAimbot.destroy then currentAimbot.destroy() end
            local modern = loadModule("aimbotScripts.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/aimbotScripts.luau")
            modern.init()
            aimbotScripts = modern
            currentAimbot = modern
            applyFlags(flags)
        end
   end,
})

SettingsTab:CreateSection("FOV Circle")

SettingsTab:CreateDropdown({
   Name = "FOV Circle Color",
   Options = {"White", "Green", "Red", "Blue"},
   CurrentOption = "White",
   Flag = "FOVColor",
   Callback = function(Value)
        aimbotScripts.setFOVCircleColor(Value)
   end,
})

SettingsTab:CreateSlider({
   Name = "FOV Stroke Thickness",
   Range = {1, 6},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 2,
   Flag = "FOVStroke",
   Callback = function(Value)
        aimbotScripts.setFOVStrokeThickness(Value)
   end,
})

SettingsTab:CreateSection("Pointer")

SettingsTab:CreateSlider({
   Name = "Pointer Size",
   Range = {2, 24},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 6,
   Flag = "PointerSize",
   Callback = function(Value)
        aimbotScripts.setPointerSize(Value)
   end,
})

SettingsTab:CreateDropdown({
   Name = "Pointer Color",
   Options = {"White", "Green", "Red", "Blue"},
   CurrentOption = "White",
   Flag = "PointerColor",
   Callback = function(Value)
        aimbotScripts.setPointerColor(Value)
   end,
})

SettingsTab:CreateToggle({
   Name = "Pointer Only While ADS (RMB)",
   CurrentValue = false,
   Flag = "PointerADSOnly",
   Callback = function(Value)
        aimbotScripts.togglePointerADSOnly(Value)
   end,
})

DebugTab:CreateSection("Overlay")

DebugTab:CreateToggle({
   Name = "Show Debug Overlay",
   CurrentValue = false,
   Flag = "DebugOverlay",
   Callback = function(Value)
        aimbotScripts.toggleDebug(Value)
   end,
})

TrainingTab:CreateSection("Targets")

do
    local targetCount = 5
    TrainingTab:CreateSlider({
       Name = "Target Count",
       Range = {1, 20},
       Increment = 1,
       Suffix = "",
       CurrentValue = 5,
       Flag = "TargetCount",
       Callback = function(Value)
            targetCount = Value
       end,
    })
    local training = loadModule("training.luau", "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/training.luau")
    training.init()
    TrainingTab:CreateButton({
        Name = "Spawn Targets",
        Callback = function()
            training.spawnTargets(targetCount)
        end,
    })
    TrainingTab:CreateToggle({
        Name = "Enable Movement",
        CurrentValue = false,
        Flag = "TrainingMove",
        Callback = function(Value)
            training.toggleMovement(Value)
        end,
    })
    TrainingTab:CreateToggle({
        Name = "Show Stats",
        CurrentValue = false,
        Flag = "TrainingStats",
        Callback = function(Value)
            training.toggleStats(Value)
        end,
    })
    TrainingTab:CreateButton({
        Name = "Reset Training",
        Callback = function()
            training.reset()
        end,
    })
end

 

WeaponsTab:CreateSection("Fast Reload")

WeaponsTab:CreateToggle({
   Name = "Enable Fast Reload",
   CurrentValue = false,
   Flag = "FastReload",
   Callback = function(Value)
        gameplayScripts.toggleFastReload(Value)
   end,
})

WeaponsTab:CreateSlider({
   Name = "Reload Anim Speed",
   Range = {1, 5},
   Increment = 0.1,
   Suffix = "x",
   CurrentValue = 1.5,
   Flag = "ReloadSpeed",
   Callback = function(Value)
        gameplayScripts.setReloadAnimSpeed(Value)
   end,
})

WeaponsTab:CreateToggle({
   Name = "Reload Cancel",
   CurrentValue = false,
   Flag = "ReloadCancel",
   Callback = function(Value)
        gameplayScripts.toggleReloadCancel(Value)
   end,
})

WeaponsTab:CreateSlider({
   Name = "Cancel Delay",
   Range = {0, 1000},
   Increment = 25,
   Suffix = "ms",
   CurrentValue = 150,
   Flag = "CancelDelay",
   Callback = function(Value)
        gameplayScripts.setReloadCancelDelay(Value)
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

-- Load saved configuration and apply states
pcall(function()
    if Rayfield and Rayfield.LoadConfiguration then
        Rayfield:LoadConfiguration()
    end
end)

local ALL_FLAGS = {
    "ESPToggle","AimbotToggle","TeamCheck","FriendExclude","WallCheck","Smoothing","FOV",
    "TargetHead","TargetUpperTorso","MaxAngle","LeadEnable","ProjectileSpeed",
    "StickyLockMs","SnapAngle","MaxTurnRate","AimCurve","ADSOnlyLock","MaxDistance",
    "HoldAim","FOVCircle","DynamicSmoothing","PointerLock","FOVColor","FOVStroke",
    "PointerSize","PointerColor","PointerADSOnly","DebugOverlay","FastReload",
    "ReloadSpeed","ReloadCancel","CancelDelay","KeyToggle"
}

local function getFlagValue(flag)
    local val = nil
    local ok, entry = pcall(function()
        return Rayfield and Rayfield.Flags and Rayfield.Flags[flag]
    end)
    if ok and entry ~= nil then
        if typeof(entry) == "table" then
            val = entry.CurrentValue
            if val == nil then val = entry.Value end
            if val == nil then val = entry.CurrentOption end
        else
            val = entry
        end
    end
    return val
end

local function collectFlags()
    local out = {}
    for _, f in ipairs(ALL_FLAGS) do
        local v = getFlagValue(f)
        if v ~= nil then out[f] = v end
    end
    return out
end

local APPLY = {
    ESPToggle = function(v) visionScripts.toggleESP(v) end,
    AimbotToggle = function(v) aimbotScripts.toggleAimbot(v) end,
    TeamCheck = function(v) aimbotScripts.toggleTeamCheck(v) end,
    FriendExclude = function(v) aimbotScripts.toggleFriendExclude(v) end,
    WallCheck = function(v) aimbotScripts.toggleWallCheck(v) end,
    Smoothing = function(v) aimbotScripts.setSmoothing(v) end,
    FOV = function(v) aimbotScripts.setFOV(v) end,
    MaxAngle = function(v) aimbotScripts.setMaxAngle(v) end,
    LeadEnable = function(v) aimbotScripts.toggleLead(v) end,
    ProjectileSpeed = function(v) aimbotScripts.setProjectileSpeed(v) end,
    StickyLockMs = function(v) aimbotScripts.setStickyLockMs(v) end,
    SnapAngle = function(v) aimbotScripts.setSnapAngle(v) end,
    MaxTurnRate = function(v) aimbotScripts.setMaxTurnRateDeg(v) end,
    AimCurve = function(v) aimbotScripts.setAimCurve(v) end,
    ADSOnlyLock = function(v) aimbotScripts.toggleADSOnlyLock(v) end,
    MaxDistance = function(v) aimbotScripts.setMaxDistance(v) end,
    HoldAim = function(v) aimbotScripts.toggleHoldToAim(v) end,
    FOVCircle = function(v) aimbotScripts.toggleFOVCircle(v) end,
    DynamicSmoothing = function(v) aimbotScripts.toggleDynamicSmoothing(v) end,
    PointerLock = function(v) aimbotScripts.togglePointerLock(v) end,
    FOVColor = function(v) aimbotScripts.setFOVCircleColor(v) end,
    FOVStroke = function(v) aimbotScripts.setFOVStrokeThickness(v) end,
    PointerSize = function(v) aimbotScripts.setPointerSize(v) end,
    PointerColor = function(v) aimbotScripts.setPointerColor(v) end,
    PointerADSOnly = function(v) aimbotScripts.togglePointerADSOnly(v) end,
    DebugOverlay = function(v) aimbotScripts.toggleDebug(v) end,
    FastReload = function(v) gameplayScripts.toggleFastReload(v) end,
    ReloadSpeed = function(v) gameplayScripts.setReloadAnimSpeed(v) end,
    ReloadCancel = function(v) gameplayScripts.toggleReloadCancel(v) end,
    CancelDelay = function(v) gameplayScripts.setReloadCancelDelay(v) end,
    KeyToggle = function(v) aimbotScripts.toggleKeyToggle(v) end,
}

local function applyFlags(flags)
    for k, v in pairs(flags or {}) do
        local fn = APPLY[k]
        if fn then
            fn(v)
        end
    end
    local wantHead = flags and flags.TargetHead == true
    local wantTorso = flags and flags.TargetUpperTorso == true
    local part = nil
    if wantHead then
        part = "Head"
    elseif wantTorso then
        part = "UpperTorso"
    end
    if part then
        aimbotScripts.setTargetPart(part)
    end
end

ProfilesTab:CreateSection("Presets")

do
    local selected = "Casual"
    ProfilesTab:CreateDropdown({
       Name = "Profile",
       Options = {"Casual", "Ranked", "Controller"},
       CurrentOption = "Casual",
       Flag = "ProfileName",
       Callback = function(Value)
            selected = Value
       end,
    })
    ProfilesTab:CreateButton({
        Name = "Save Profile",
        Callback = function()
            local flags = collectFlags()
            profileManager.save(selected, flags)
        end,
    })
    ProfilesTab:CreateButton({
        Name = "Load Profile",
        Callback = function()
            local flags = profileManager.load(selected)
            applyFlags(flags)
        end,
    })
    ProfilesTab:CreateButton({
        Name = "Delete Profile",
        Callback = function()
            profileManager.delete(selected)
        end,
    })
end
