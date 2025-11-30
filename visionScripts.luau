-- visionScripts.luau - ESP Module (Debug Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local module = {}

local espFolder = nil
local espEnabled = false
local teamCheckEnabled = false
local characterConnections = {}
local espColor = Color3.fromRGB(0, 255, 100)
local LocalPlayer = Players.LocalPlayer
local debugMode = false

-- Debug logging function
local function debugLog(...)
    if debugMode then
        print("[Vision Debug]", ...)
    end
end

print("[Vision] Module loaded")

-- ESP oluşturma fonksiyonu
local function createESP(character)
    if not character then return end
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    debugLog("Creating ESP for:", player.Name)

    -- Team check
    if teamCheckEnabled and player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
        debugLog("Skipping teammate:", player.Name)
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        debugLog("HumanoidRootPart not found for:", player.Name)
        return
    end

    if not espEnabled then
        debugLog("ESP is disabled")
        return
    end

    -- Eski ESP'leri temizle
    if espFolder then
        local oldBox = espFolder:FindFirstChild(player.Name .. "_Box")
        if oldBox then
            oldBox:Destroy()
        end
    end

    local oldHighlight = character:FindFirstChild("ESPHighlight")
    if oldHighlight then
        oldHighlight:Destroy()
    end

    -- BoxHandleAdornment
    local box = Instance.new("BoxHandleAdornment")
    box.Name = player.Name .. "_Box"
    box.Size = Vector3.new(4, 6, 4)
    box.Color3 = espColor
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Adornee = hrp
    box.ZIndex = 10
    box.Visible = true
    box.Parent = espFolder

    debugLog("Box created for:", player.Name)

    -- Highlight ekle
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Adornee = character
    highlight.FillColor = espColor
    highlight.OutlineColor = espColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character

    debugLog("Highlight created for:", player.Name)
    
    -- Cleanup on Death
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            if box then box:Destroy() end
            if highlight then highlight:Destroy() end
        end)
    end
end

-- Oyuncu için ESP setup
local function setupPlayer(plr)
    if plr == Players.LocalPlayer then return end

    debugLog("Setting up player:", plr.Name)

    -- Character spawn olduğunda ESP oluştur
    characterConnections[plr] = plr.CharacterAdded:Connect(function(char)
        debugLog("Character added for:", plr.Name)
        task.wait(0.5)
        if espEnabled then
            createESP(char)
        end
    end)

    -- Eğer karakter zaten varsa
    if plr.Character then
        debugLog("Character already exists for:", plr.Name)
        if espEnabled then
            task.spawn(function()
                createESP(plr.Character)
            end)
        end
    end
end

-- MODULE API
function module.init()
    print("[Vision] Initializing module...")

    -- Cleanup existing folder if any
    local oldFolder = workspace:FindFirstChild("VisionESP")
    if oldFolder then
        oldFolder:Destroy()
    end

    espFolder = Instance.new("Folder")
    espFolder.Name = "VisionESP"
    espFolder.Parent = workspace

    debugLog("ESP Folder created in workspace")

    for _, plr in ipairs(Players:GetPlayers()) do
        setupPlayer(plr)
    end

    Players.PlayerAdded:Connect(function(plr)
        debugLog("New player joined:", plr.Name)
        setupPlayer(plr)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        debugLog("Player leaving:", plr.Name)
        if characterConnections[plr] then
            characterConnections[plr]:Disconnect()
            characterConnections[plr] = nil
        end
    end)

    print("[Vision] Module initialized successfully!")
end

function module.toggleESP(state)
    print("[Vision] Toggle ESP:", state)
    espEnabled = state

    if not state then
        debugLog("Disabling ESP, clearing all...")
        -- Tüm ESP'leri temizle
        if espFolder then
            espFolder:ClearAllChildren()
        end

        -- Highlight'ları temizle
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local highlight = plr.Character:FindFirstChild("ESPHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
        debugLog("ESP disabled and cleared")
        return
    end

    -- ESP ON → mevcut oyuncular için oluştur
    debugLog("Enabling ESP for all players...")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            debugLog("Creating ESP for existing player:", plr.Name)
            createESP(plr.Character)
        end
    end
    print("[Vision] ESP enabled!")
end

function module.destroy()
    print("[Vision] Destroying module...")
    espEnabled = false
    if espFolder then
        espFolder:Destroy()
        espFolder = nil
    end

    for plr, conn in pairs(characterConnections) do
        conn:Disconnect()
    end
    characterConnections = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local highlight = plr.Character:FindFirstChild("ESPHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
    print("[Vision] Module destroyed")
end

function module.toggleTeamCheck(state)
    teamCheckEnabled = state and true or false
    print("[Vision] TeamCheck:", teamCheckEnabled)
    
    -- ESP'yi yeniden oluştur
    if espEnabled then
        module.toggleESP(false)
        module.toggleESP(true)
    end
end

function module.setESPColor(color)
    debugLog("Setting ESP color to:", tostring(color))
    espColor = color

    if espFolder then
        for _, child in ipairs(espFolder:GetChildren()) do
            if child:IsA("BoxHandleAdornment") then
                child.Color3 = color
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local highlight = plr.Character:FindFirstChild("ESPHighlight")
            if highlight then
                highlight.FillColor = color
                highlight.OutlineColor = color
            end
        end
    end
    print("[Vision] ESP color updated")
end

function module.toggleDebugMode(state)
    debugMode = state and true or false
    print("[Vision] DebugMode:", debugMode)
end

function module.getStats()
    local playerCount = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            playerCount = playerCount + 1
        end
    end
    return {
        enabled = espEnabled,
        teamCheck = teamCheckEnabled,
        trackedPlayers = playerCount,
        color = espColor
    }
end

return module
