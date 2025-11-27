local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local module = {}

local espEnabled = false
local espCache = {} -- player -> {gui, box, name, health, line}

-- 3D -> 2D
local function to2D(pos)
    local screenPos, visible = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), visible
end

local BOX_COLOR_ENEMY = Color3.fromRGB(255, 80, 80)
local BOX_COLOR_TEAM = Color3.fromRGB(80, 180, 255)
local TEXT_COLOR = Color3.new(1,1,1)

local function removeESP(player)
    if espCache[player] then
        espCache[player].gui:Destroy()
        if espCache[player].line then espCache[player].line:Remove() end
        espCache[player] = nil
    end
end

local function createESP(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == Players.LocalPlayer then return end

    removeESP(player) -- eski ESP varsa temizle

    local hrp = character:WaitForChild("HumanoidRootPart")
    local hum = character:WaitForChild("Humanoid")

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.IgnoreGuiInset = true
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Box
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5,0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 2
    box.Size = UDim2.new(0,100,0,150)
    box.Parent = gui

    -- Name
    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Size = UDim2.new(1,0,0,20)
    name.Position = UDim2.new(0,0,-0.15,0)
    name.TextScaled = true
    name.TextColor3 = TEXT_COLOR
    name.Font = Enum.Font.GothamBold
    name.Text = player.Name
    name.Parent = box

    -- Health bar
    local health = Instance.new("Frame")
    health.Size = UDim2.new(0.1,0,1,0)
    health.Position = UDim2.new(-0.15,0,0,0)
    health.BackgroundColor3 = Color3.fromRGB(0,255,0)
    health.BorderSizePixel = 0
    health.Parent = box

    -- Line
    local line = Drawing.new("Line")
    line.Color = BOX_COLOR_ENEMY
    line.Thickness = 1.5
    line.Transparency = 1

    espCache[player] = {gui=gui, box=box, name=name, health=health, line=line}
end

-- Tüm mevcut oyuncular için ESP oluştur
local function refreshESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            createESP(plr.Character)
        end
    end
end

-- Module init
function module.init()
    -- Mevcut oyuncular
    refreshESP()

    -- Yeni oyuncular
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(char)
            if espEnabled then createESP(char) end
        end)
    end)

    -- Round veya respawn sonrası eski ESP sil ve yenile
    for _,plr in ipairs(Players:GetPlayers()) do
        plr.CharacterAdded:Connect(function(char)
            if espEnabled then createESP(char) end
        end)
    end

    -- Oyuncu çıktıysa ESP sil
    Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
    end)
end

-- Toggle ESP
function module.toggleESP(state)
    espEnabled = state
    if not state then
        for _,ui in pairs(espCache) do
            ui.gui:Destroy()
            if ui.line then ui.line:Remove() end
        end
        espCache = {}
    else
        refreshESP()
    end
end

-- Render loop
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    for player, ui in pairs(espCache) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if hrp and hum and hum.Health>0 then
            local size = char:GetExtentsSize()
            local top = hrp.Position + Vector3.new(0,size.Y/2,0)
            local bottom = hrp.Position - Vector3.new(0,size.Y/2,0)

            local top2D, vis1 = to2D(top)
            local bot2D, vis2 = to2D(bottom)

            if vis1 or vis2 then
                ui.box.Visible = true
                local midY = (top2D.Y + bot2D.Y)/2
                ui.box.Position = UDim2.new(0, top2D.X, 0, midY)
                local height = math.abs(top2D.Y - bot2D.Y)
                local width = height * 0.45
                ui.box.Size = UDim2.new(0,width,0,height)

                ui.health.Size = UDim2.new(0.1,0, hum.Health/hum.MaxHealth, 0)
                ui.name.Text = player.Name

                if player.Team==Players.LocalPlayer.Team then
                    ui.box.BorderColor3 = BOX_COLOR_TEAM
                    ui.line.Color = BOX_COLOR_TEAM
                else
                    ui.box.BorderColor3 = BOX_COLOR_ENEMY
                    ui.line.Color = BOX_COLOR_ENEMY
                end

                -- Line
                if ui.line then
                    ui.line.Visible = true
                    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    local boxCenter = Vector2.new(top2D.X, midY)
                    ui.line.From = screenCenter
                    ui.line.To = boxCenter
                end
            else
                ui.box.Visible = false
                if ui.line then ui.line.Visible = false end
            end
        else
            ui.box.Visible = false
            if ui.line then ui.line.Visible = false end
        end
    end
end)

return module
