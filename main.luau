-- main.luau - Aqwoz Hub (Clean Version)
print("[Main] Script starting...")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Load OrionLib
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
print("[Main] OrionLib loaded")

-- Vision module
local visionURL = "https://raw.githubusercontent.com/AqwozTheDeveloper/AqwozHub/refs/heads/main/visionScripts.luau"
print("[Main] Loading vision module...")

local success, visionScripts = pcall(function()
    return loadstring(game:HttpGet(visionURL))()
end)

if success then
    print("[Main] Vision module loaded!")
    pcall(function()
        visionScripts.init()
        print("[Main] Vision module initialized!")
    end)
else
    warn("[Main] Failed to load vision module:", visionScripts)
end

-- Window
local Window = OrionLib:MakeWindow({
    Name = "Aqwoz Hub", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "OrionConfig"
})
print("[Main] Window created")

-- Notification
OrionLib:MakeNotification({
    Name = "Aqwoz Hub",
    Content = "Loaded successfully!",
    Image = "rbxassetid://4483345998",
    Time = 3
})

-- Home Tab
local HomeTab = Window:MakeTab({
    Name = "Home",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

HomeTab:AddParagraph("Welcome!", "Aqwoz Hub loaded. Use ESP tab to enable player vision.")

-- ESP Tab
local ESPTab = Window:MakeTab({
    Name = "ESP",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ESPTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(Value)
        print("[Main] ESP Toggle:", Value)
        if success and visionScripts then
            pcall(function()
                visionScripts.toggleESP(Value)
            end)
        else
            warn("[Main] Vision module not available")
        end
    end
})

ESPTab:AddColorpicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(0, 255, 100),
    Callback = function(Value)
        print("[Main] ESP Color:", Value)
        if success and visionScripts then
            pcall(function()
                visionScripts.setESPColor(Value)
            end)
        end
    end
})

ESPTab:AddButton({
    Name = "Refresh ESP",
    Callback = function()
        if success and visionScripts then
            print("[Main] Refreshing ESP...")
            visionScripts.toggleESP(false)
            wait(0.1)
            visionScripts.toggleESP(true)
        end
    end
})

-- Debug Section
local DebugSection = ESPTab:AddSection({
    Name = "Debug"
})

DebugSection:AddButton({
    Name = "Check Players",
    Callback = function()
        print("=== PLAYER CHECK ===")
        for _, plr in pairs(Players:GetPlayers()) do
            local hasChar = plr.Character ~= nil
            local hasHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") ~= nil
            print(string.format("%s | Char: %s | HRP: %s", plr.Name, tostring(hasChar), tostring(hasHRP)))
        end
        print("====================")
    end
})

DebugSection:AddButton({
    Name = "Check ESP Folder",
    Callback = function()
        local folder = workspace:FindFirstChild("VisionESP")
        if folder then
            print("[Main] ESP Folder found!")
            print("[Main] Children:", #folder:GetChildren())
            for _, child in pairs(folder:GetChildren()) do
                print("  -", child.Name)
            end
        else
            warn("[Main] ESP Folder not found!")
        end
    end
})

-- Aimbot Tab
local AimbotTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AimbotTab:AddLabel("Coming soon...")

-- Initialize
OrionLib:Init()
print("[Main] Script fully loaded!")
