local Players = game:GetService("Players")

local module = {}

local espFolder = nil
local espEnabled = false

local function createESP(character)
    if not espEnabled then return end

    task.wait(0.1)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 4)
    box.Color3 = Color3.fromRGB(0, 255, 100)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Adornee = hrp
    box.Parent = espFolder
end

function module.init()
    espFolder = Instance.new("Folder", workspace)
    espFolder.Name = "VisionESP"

    -- If player respawns, ESP again
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(char)
            if espEnabled then
                createESP(char)
            end
        end)
    end)
end

function module.toggleESP(state)
    espEnabled = state

    if not state then
        -- ❗ ESP OFF → everything gets deleted
        espFolder:ClearAllChildren()
        return
    end

    -- ESP ON → recreate
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            createESP(plr.Character)
        end
    end
end

return module
