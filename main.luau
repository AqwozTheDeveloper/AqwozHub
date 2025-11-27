-- main.luau - Aqwoz Hub (Debug Version)
print("[Main] Script starting...")

local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
print("[Main] OrionLib loaded")

-- Vision module'u GitHub'dan çek
local visionURL = "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/visionScripts.luau"
print("[Main] Loading vision module from:", visionURL)

local success, visionScripts = pcall(function()
    return loadstring(game:HttpGet(visionURL))()
end)

if not success then
    print("[Main] ERROR: Vision module failed to load!")
    print("[Main] Error:", visionScripts)
    -- Fallback sistemi kullan
    warn("[Main] Using fallback ESP system...")
else
    print("[Main] Vision module loaded successfully!")
    -- Module'u başlat
    local initSuccess = pcall(function()
        visionScripts.init()
    end)
    if initSuccess then
        print("[Main] Vision module initialized!")
    else
        print("[Main] ERROR: Failed to initialize vision module")
    end
end

-- Window
local Window = OrionLib:MakeWindow({
    Name = "Aqwoz Hub [DEBUG]", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "OrionConfig"
})
print("[Main] Window created")

-- Notification
OrionLib:MakeNotification({
    Name = "Welcome to AqwozHub",
    Content = "Debug version - Check console (F9) for errors",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Ana Tab
local AqwozHub = Window:MakeTab({
    Name = "AqwozHub",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AqwozHub:AddParagraph("Debug Mode", "Check F9 console for debug messages. ESP should work now!")

AqwozHub:AddButton({
    Name = "Print Player List",
    Callback = function()
        print("=== PLAYER LIST ===")
        for _, plr in pairs(game.Players:GetPlayers()) do
            print("Player:", plr.Name, "| Character:", plr.Character and "YES" or "NO")
        end
        print("==================")
    end
})

-- Vision Tab
local VisionTab = Window:MakeTab({
    Name = "Player Vision",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

VisionTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(Value)
        print("[Main] ESP Toggle clicked:", Value)
        if success and visionScripts then
            local toggleSuccess = pcall(function()
                visionScripts.toggleESP(Value)
            end)
            if not toggleSuccess then
                print("[Main] ERROR: Failed to toggle ESP")
            end
        else
            print("[Main] ERROR: Vision module not loaded!")
        end
    end
})

VisionTab:AddColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(0, 255, 100),
    Callback = function(Value)
        print("[Main] Color changed to:", Value)
        if success and visionScripts then
            pcall(function()
                visionScripts.setESPColor(Value)
            end)
        end
    end
})

VisionTab:AddButton({
    Name = "Check ESP Folder",
    Callback = function()
        local folder = workspace:FindFirstChild("VisionESP")
        if folder then
            print("[Main] ESP Folder found! Children:", #folder:GetChildren())
            for _, child in pairs(folder:GetChildren()) do
                print("  -", child.Name, child.ClassName)
            end
        else
            print("[Main] ERROR: ESP Folder not found in workspace!")
        end
    end
})

-- Aimbot Tab
local AimSectionTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local AimSection = AimSectionTab:AddSection({
    Name = "Aim Section"
})

AimSection:AddLabel("Coming soon...")

-- Initialize
OrionLib:Init()
print("[Main] Script loaded successfully!")
