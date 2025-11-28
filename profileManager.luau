local HttpService = game:GetService("HttpService")

local module = {}

local profiles = {}
local folder = "AqwozHubConfig"
local path = folder .. "/Profiles.json"

local function safeIsFolder()
    local ok, res = pcall(function()
        return isfolder and isfolder(folder)
    end)
    return ok and res
end

local function safeMakeFolder()
    pcall(function()
        if makefolder then makefolder(folder) end
    end)
end

local function safeIsFile()
    local ok, res = pcall(function()
        return isfile and isfile(path)
    end)
    return ok and res
end

local function safeWrite(text)
    pcall(function()
        if writefile then writefile(path, text) end
    end)
end

local function safeRead()
    local ok, res = pcall(function()
        if readfile then return readfile(path) end
        return nil
    end)
    if ok then return res end
    return nil
end

function module.init()
    if not safeIsFolder() then
        safeMakeFolder()
    end
    if safeIsFile() then
        local content = safeRead()
        if content and #content > 0 then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if ok and type(data) == "table" then
                profiles = data
            end
        end
    end
end

function module.save(name, flags)
    if type(name) ~= "string" or name == "" then return false end
    if type(flags) ~= "table" then return false end
    profiles[name] = flags
    local ok, text = pcall(function()
        return HttpService:JSONEncode(profiles)
    end)
    if ok then
        safeWrite(text)
        return true
    end
    return false
end

function module.load(name)
    if type(name) ~= "string" or name == "" then return {} end
    local entry = profiles[name]
    if type(entry) == "table" then
        return entry
    end
    return {}
end

function module.delete(name)
    if type(name) ~= "string" or name == "" then return false end
    profiles[name] = nil
    local ok, text = pcall(function()
        return HttpService:JSONEncode(profiles)
    end)
    if ok then
        safeWrite(text)
        return true
    end
    return false
end

function module.list()
    local names = {}
    for k, _ in pairs(profiles) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

return module
