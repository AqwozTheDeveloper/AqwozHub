-- [[ PRIVATE ADMIN SCRIPT - DO NOT SHARE ]]
-- Run this script in your executor to generate today's key and send it to Discord.

local HttpService = game:GetService("HttpService")

-- ==================================================================
-- CONFIGURATION (MUST MATCH MAIN.LUAU)
-- ==================================================================
local KEY_ROTATION = "daily"
local KEY_PREFIX = "Aqwoz" 
local KEY_SECRET = ".AqwozsKey3169!" -- MUST MATCH main.luau EXACTLY

local WEBHOOK_URL = "https://discord.com/api/webhooks/1444687844068032544/simFozs7KofTf8-7yM_JQHhkVcZTUg1nVYY-Vj82WhMoYe9Gjapav8aJ97K6HxKkde7P"
-- ==================================================================

-- Generate key (Same logic as main.luau)
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

-- Send to Discord
local function sendToDiscord()
    local req = (http_request or request or HttpPost or syn.request)
    if not req then
        warn("Executor does not support HTTP requests.")
        print("TODAYS KEY: " .. TODAYS_KEY)
        return
    end

    local data = {
        content = "",
        embeds = {{
            title = "🔑 Aqwoz Hub Key Generated",
            description = "**Date:** " .. os.date("%Y-%m-%d") .. "\n**Key:** `" .. TODAYS_KEY .. "`",
            color = 65280,
            footer = { text = "Admin Generator" }
        }}
    }

    req({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    })
    print("Key sent to Discord: " .. TODAYS_KEY)
end

sendToDiscord()
