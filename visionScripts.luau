-- visionScripts.luau - ESP Module (Debug Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local module = {}

local espFolder = nil
local espEnabled = false
local characterConnections = {}
local espColor = Color3.fromRGB(0, 255, 100)
local showDistance = false
local showHealth = false
local showTracers = false
local showNames = false
local boxThickness = 2
local maxDistance = 500
local tracerOrigin = "Bottom" -- "Bottom", "Center", "Mouse"
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

print("[Vision] Module loaded")

-- ESP oluşturma fonksiyonu
local function createESP(character)
    print("[Vision] Creating ESP for:", character.Parent.Name)

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        print("[Vision] HumanoidRootPart not found!")
        return
    end

    if not espEnabled then
        print("[Vision] ESP is disabled")
        return
    end

    -- Eski ESP'leri temizle
    if espFolder then
        for _, child in pairs(espFolder:GetChildren()) do
            if child.Name:find(character.Parent.Name) then
                child:Destroy()
            end
        end
    end

    local oldHighlight = character:FindFirstChild("ESPHighlight")
    if oldHighlight then
        oldHighlight:Destroy()
    end

    -- BoxHandleAdornment
    local box = Instance.new("BoxHandleAdornment")
    box.Name = character.Parent.Name .. "_Box"
    box.Size = Vector3.new(4, 6, 4)
    box.Color3 = espColor
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Adornee = hrp
    box.ZIndex = 10
    box.Visible = true
    box.Parent = espFolder

    print("[Vision] Box created for:", character.Parent.Name)

    -- Highlight ekle
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Adornee = character
    highlight.FillColor = espColor
    highlight.OutlineColor = espColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character

    print("[Vision] Highlight created for:", character.Parent.Name)
    
    -- Distance Text
    if showDistance then
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = character.Parent.Name .. "_Distance"
        billboardGui.Adornee = hrp
        billboardGui.Size = UDim2.new(0, 100, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.Parent = espFolder
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0.5
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 14
        textLabel.Text = "0m"
        textLabel.Parent = billboardGui
    end
    
    -- Health Bar
    if showHealth then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local healthGui = Instance.new("BillboardGui")
            healthGui.Name = character.Parent.Name .. "_Health"
            healthGui.Adornee = hrp
            healthGui.Size = UDim2.new(0, 100, 0, 10)
            healthGui.StudsOffset = Vector3.new(0, 4, 0)
            healthGui.AlwaysOnTop = true
            healthGui.Parent = espFolder
            
            local healthFrame = Instance.new("Frame")
            healthFrame.Size = UDim2.new(1, 0, 1, 0)
            healthFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            healthFrame.BorderSizePixel = 0
            healthFrame.Parent = healthGui
            
            local healthBar = Instance.new("Frame")
            healthBar.Name = "HealthBar"
            healthBar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            healthBar.BorderSizePixel = 0
            healthBar.Parent = healthFrame
        end
    end
    
    -- Name Tag
    if showNames then
        local nameGui = Instance.new("BillboardGui")
        nameGui.Name = character.Parent.Name .. "_Name"
        nameGui.Adornee = hrp
        nameGui.Size = UDim2.new(0, 200, 0, 50)
        nameGui.StudsOffset = Vector3.new(0, 2, 0)
        nameGui.AlwaysOnTop = true
        nameGui.Parent = espFolder
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = espColor
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.Text = character.Parent.Name
        nameLabel.Parent = nameGui
    end
    
    -- Tracer Line
    if showTracers then
        local line = Instance.new("Line")
        line.Name = character.Parent.Name .. "_Tracer"
        line.Thickness = 2
        line.Color = espColor
        line.Transparency = 0.5
        line.ZIndex = 5
        line.Visible = false
        line.Parent = espFolder
    end
end

-- Oyuncu için ESP setup
local function setupPlayer(plr)
    if plr == Players.LocalPlayer then return end

    print("[Vision] Setting up player:", plr.Name)

    -- Character spawn olduğunda ESP oluştur
    characterConnections[plr] = plr.CharacterAdded:Connect(function(char)
        print("[Vision] Character added for:", plr.Name)
        task.wait(0.5)
        if espEnabled then
            createESP(char)
        end
    end)

    -- Eğer karakter zaten varsa
    if plr.Character then
        print("[Vision] Character already exists for:", plr.Name)
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

    espFolder = Instance.new("Folder")
    espFolder.Name = "VisionESP"
    espFolder.Parent = workspace

    print("[Vision] ESP Folder created in workspace")

    for _, plr in ipairs(Players:GetPlayers()) do
        setupPlayer(plr)
    end

    Players.PlayerAdded:Connect(function(plr)
        print("[Vision] New player joined:", plr.Name)
        setupPlayer(plr)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        print("[Vision] Player leaving:", plr.Name)
        if characterConnections[plr] then
            characterConnections[plr]:Disconnect()
            characterConnections[plr] = nil
        end
    end)

    print("[Vision] Module initialized successfully!")
    
    -- Update loop for distance/health/tracers
    RunService.RenderStepped:Connect(function()
        if not espEnabled or not espFolder then return end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
                    
                    -- Update distance
                    if showDistance then
                        local distGui = espFolder:FindFirstChild(plr.Name .. "_Distance")
                        if distGui and distGui:FindFirstChild("TextLabel") then
                            distGui.TextLabel.Text = math.floor(distance) .. "m"
                        end
                    end
                    
                    -- Update health bar
                    if showHealth then
                        local humanoid = plr.Character:FindFirstChild("Humanoid")
                        local healthGui = espFolder:FindFirstChild(plr.Name .. "_Health")
                        if healthGui and humanoid then
                            local healthBar = healthGui:FindFirstChild("Frame") and healthGui.Frame:FindFirstChild("HealthBar")
                            if healthBar then
                                local healthPercent = humanoid.Health / humanoid.MaxHealth
                                healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                                healthBar.BackgroundColor3 = Color3.fromRGB(
                                    255 * (1 - healthPercent),
                                    255 * healthPercent,
                                    0
                                )
                            end
                        end
                    end
                    
                    -- Update tracers
                    if showTracers then
                        local tracer = espFolder:FindFirstChild(plr.Name .. "_Tracer")
                        if tracer and tracer:IsA("Line") then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                            if onScreen and distance <= maxDistance then
                                local startPos
                                if tracerOrigin == "Bottom" then
                                    startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                elseif tracerOrigin == "Center" then
                                    startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                                else
                                    startPos = game:GetService("UserInputService"):GetMouseLocation()
                                end
                                tracer.From = startPos
                                tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                                tracer.Visible = true
                            else
                                tracer.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end)
end

function module.toggleESP(state)
    print("[Vision] Toggle ESP:", state)
    espEnabled = state

    if not state then
        print("[Vision] Disabling ESP, clearing all...")
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
        print("[Vision] ESP disabled and cleared")
        return
    end

    -- ESP ON → mevcut oyuncular için oluştur
    print("[Vision] Enabling ESP for all players...")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            print("[Vision] Creating ESP for existing player:", plr.Name)
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

function module.setESPColor(color)
    print("[Vision] Setting ESP color to:", color)
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

function module.toggleDistance(state)
    showDistance = state and true or false
    print("[Vision] Distance display:", showDistance)
    -- Refresh ESP if enabled
    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                createESP(plr.Character)
            end
        end
    end
end

function module.toggleHealth(state)
    showHealth = state and true or false
    print("[Vision] Health display:", showHealth)
    -- Refresh ESP if enabled
    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                createESP(plr.Character)
            end
        end
    end
end

function module.toggleTracers(state)
    showTracers = state and true or false
    print("[Vision] Tracers:", showTracers)
    -- Refresh ESP if enabled
    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                createESP(plr.Character)
            end
        end
    end
end

function module.toggleNames(state)
    showNames = state and true or false
    print("[Vision] Name tags:", showNames)
    -- Refresh ESP if enabled
    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                createESP(plr.Character)
            end
        end
    end
end

function module.setBoxThickness(value)
    boxThickness = math.clamp(tonumber(value) or 2, 1, 10)
    print("[Vision] Box thickness:", boxThickness)
end

function module.setMaxDistance(value)
    maxDistance = math.max(0, tonumber(value) or 500)
    print("[Vision] Max distance:", maxDistance)
end

function module.setTracerOrigin(origin)
    local allowed = {Bottom = true, Center = true, Mouse = true}
    if type(origin) == "string" and allowed[origin] then
        tracerOrigin = origin
    end
    print("[Vision] Tracer origin:", tracerOrigin)
end

return module
