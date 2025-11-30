-- visionScripts.luau - ESP Module (Debug Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local module = {}

local espFolder = nil
local espEnabled = false
local teamCheckEnabled = false
local showHealthEnabled = true -- Show health bars
local characterConnections = {}
local espColor = Color3.fromRGB(0, 255, 100)
local LocalPlayer = Players.LocalPlayer
local debugMode = false
local healthConnections = {}

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
    
    -- Health Bar & Name Display
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if head and showHealthEnabled then
        -- Remove old billboard if exists
        local oldBillboard = head:FindFirstChild("ESPBillboard")
        if oldBillboard then oldBillboard:Destroy() end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBillboard"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        -- Player Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = espColor
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.Parent = billboard
        
        -- Health Bar Background
        local healthBg = Instance.new("Frame")
        healthBg.Name = "HealthBg"
        healthBg.Size = UDim2.new(0.8, 0, 0.15, 0)
        healthBg.Position = UDim2.new(0.1, 0, 0.45, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        healthBg.BorderSizePixel = 0
        healthBg.Parent = billboard
        
        local healthBgCorner = Instance.new("UICorner")
        healthBgCorner.CornerRadius = UDim.new(0, 3)
        healthBgCorner.Parent = healthBg
        
        -- Health Bar Fill
        local healthBar = Instance.new("Frame")
        healthBar.Name = "HealthBar"
        healthBar.Size = UDim2.new(1, 0, 1, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = healthBg
        
        local healthBarCorner = Instance.new("UICorner")
        healthBarCorner.CornerRadius = UDim.new(0, 3)
        healthBarCorner.Parent = healthBar
        
        -- Health Text
        local healthText = Instance.new("TextLabel")
        healthText.Name = "HealthText"
        healthText.Size = UDim2.new(1, 0, 0.4, 0)
        healthText.Position = UDim2.new(0, 0, 0.6, 0)
        healthText.BackgroundTransparency = 1
        healthText.Text = "100/100"
        healthText.TextColor3 = Color3.new(1, 1, 1)
        healthText.TextStrokeTransparency = 0.5
        healthText.TextStrokeColor3 = Color3.new(0, 0, 0)
        healthText.Font = Enum.Font.GothamBold
        healthText.TextScaled = true
        healthText.Parent = billboard
        
        -- Update health bar function
        local function updateHealth()
            if not humanoid or not healthBar or not healthText then return end
            local health = humanoid.Health
            local maxHealth = humanoid.MaxHealth
            local percent = math.clamp(health / maxHealth, 0, 1)
            
            healthBar.Size = UDim2.new(percent, 0, 1, 0)
            healthText.Text = math.floor(health) .. "/" .. math.floor(maxHealth)
            
            -- Color based on health (green -> yellow -> red)
            if percent > 0.5 then
                healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif percent > 0.25 then
                healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            else
                healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
        
        -- Initial update
        updateHealth()
        
        -- Connect to health changes
        if humanoid then
            local conn = humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealth)
            healthConnections[player] = conn
        end
        
        debugLog("Health bar created for:", player.Name)
    end
    
    -- Cleanup on Death
    if humanoid then
        humanoid.Died:Connect(function()
            if box then box:Destroy() end
            if highlight then highlight:Destroy() end
            if healthConnections[player] then
                healthConnections[player]:Disconnect()
                healthConnections[player] = nil
            end
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
    
    for plr, conn in pairs(healthConnections) do
        conn:Disconnect()
    end
    healthConnections = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local highlight = plr.Character:FindFirstChild("ESPHighlight")
            if highlight then
                highlight:Destroy()
            end
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("ESPBillboard")
                if billboard then
                    billboard:Destroy()
                end
            end
        end
    end
    print("[Vision] Module destroyed")
end

function module.toggleShowHealth(state)
    showHealthEnabled = state and true or false
    print("[Vision] ShowHealth:", showHealthEnabled)
    
    -- Refresh ESP to apply changes
    if espEnabled then
        module.toggleESP(false)
        module.toggleESP(true)
    end
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
    if debugMode then
        debugLog("Debug logs enabled")
    end
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
