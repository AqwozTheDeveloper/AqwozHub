-- [[ PRIVATE ADMIN SCRIPT - DO NOT SHARE ]]
-- Run this in VS Code (Lua) OR Roblox Executor

-- ==================================================================
-- CONFIGURATION (MUST MATCH MAIN.LUAU)
-- ==================================================================
local KEY_ROTATION = "daily"
local KEY_PREFIX = "Aqwoz" 
local KEY_SECRET = ".AqwozsKey3169!" -- MUST MATCH main.luau EXACTLY

local WEBHOOK_URL = "https://discord.com/api/webhooks/1444687844068032544/simFozs7KofTf8-7yM_JQHhkVcZTUg1nVYY-Vj82WhMoYe9Gjapav8aJ97K6HxKkde7P"
-- ==================================================================

-- Generate key (Standard Lua Compatible)
local function generateKey()
    local date = os.date("!*t")
    local seed
    
    if KEY_ROTATION == "hourly" then
        seed = date.year * 1000000 + date.month * 10000 + date.day * 100 + date.hour
    elseif KEY_ROTATION == "daily" then
        seed = date.year * 10000 + date.month * 100 + date.day
    elseif KEY_ROTATION == "weekly" then
        local weekNum = math.floor(date.yday / 7)
        seed = date.year * 100 + weekNum
    else
        return KEY_PREFIX .. "-Static-Key"
    end
    
    local hash = 0
    local combined = tostring(seed) .. KEY_SECRET
    for i = 1, #combined do
        hash = (hash * 31 + string.byte(combined, i)) % 999999
    end
    
    return KEY_PREFIX .. "-" .. string.format("%06d", hash)
end

local TODAYS_KEY = generateKey()

-- Environment Check
local isRoblox = (game ~= nil and script ~= nil)
local http_request = (http_request or request or HttpPost or syn and syn.request)

print("\n===========================================")
print("          AQWOZ HUB KEY GENERATOR          ")
print("===========================================")
print("DATE: " .. os.date("%Y-%m-%d"))
print("KEY:  " .. TODAYS_KEY)
print("===========================================\n")

if isRoblox and http_request then
    local HttpService = game:GetService("HttpService")
    local data = {
        content = "",
        embeds = {{
            title = "🔑 Aqwoz Hub Key Generated",
            description = "**Date:** " .. os.date("%Y-%m-%d") .. "\n**Key:** `" .. TODAYS_KEY .. "`",
            color = 65280,
            footer = { text = "Admin Generator" }
        }}
    }

    http_request({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    })
    print(">> Sent to Discord Webhook!")
else
    print(">> Running in Standard Lua / No HTTP support.")
    print(">> Copy the key above and update work.ink manually.")
end
