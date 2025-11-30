local module = {}

local rageFolder = nil

-- Module Scripts 

function module.init()
    print("[AQWOZ HUB] Loading rage scripts...")
    rageFolder = Instance.new("Folder")
    rageFolder.Name = "RageScripts"
    rageFolder.Parent = workspace

    print("[AQWOZ HUB] RageFolder installed to workspace.")
end

function module.destroy()
    if rageFolder then
        rageFolder:Destroy()
        rageFolder = nil
    end
end

return module