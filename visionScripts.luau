-- visionScripts.luau - ESP Module (Drawing API Kaldırıldı)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local module = {}

local espFolder = nil
local espEnabled = false
local characterConnections = {}
local espColor = Color3.fromRGB(0, 255, 100)

-- ESP oluşturma fonksiyonu
local function createESP(character)
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    if not hrp or not espEnabled then return end

    -- Eski ESP'leri temizle
    local oldBox = espFolder:FindFirstChild(character.Parent.Name .. "_Box")
    if oldBox then oldBox:Destroy() end
    
    local oldHighlight = character:FindFirstChild("ESPHighlight")
    if oldHighlight then oldHighlight:Destroy() end

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

    -- Highlight ekle (daha modern görünüm)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Adornee = character
    highlight.FillColor = espColor
    highlight.OutlineColor = espColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
end

-- Oyuncu için ESP setup
local function setupPlayer(plr)
    if plr == Players.LocalPlayer then return end

    -- Character spawn olduğunda ESP oluştur
    characterConnections[plr] = plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if espEnabled then
            createESP(char)
        end
    end)

    -- Eğer karakter zaten varsa
    if plr.Character and espEnabled then
        task.spawn(function()
            createESP(plr.Character)
        end)
    end
end

-- MODULE API
function module.init()
    espFolder = Instance.new("Folder")
    espFolder.Name = "VisionESP"
    espFolder.Parent = workspace

    for _, plr in ipairs(Players:GetPlayers()) do
        setupPlayer(plr)
    end

    Players.PlayerAdded:Connect(setupPlayer)
    
    Players.PlayerRemoving:Connect(function(plr)
        if characterConnections[plr] then
            characterConnections[plr]:Disconnect()
            characterConnections[plr] = nil
        end
    end)
end

function module.toggleESP(state)
    espEnabled = state

    if not state then
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
        return
    end

    -- ESP ON → mevcut oyuncular için oluştur
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            createESP(plr.Character)
        end
    end
end

function module.destroy()
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
end

function module.setESPColor(color)
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
end

return module
