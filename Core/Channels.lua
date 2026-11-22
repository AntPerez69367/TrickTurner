local addonName, ns = ...
local Channels = ns.Channels

local DEFAULT_ON = {
    general = true,
    trade = true,
    services = true,
    tradelocal = true,
}

function Channels.Key(name)
    local text = ns.PlainString(name)
    if type(text) ~= "string" then return nil end
    text = text:match("^%s*(.-)%s*$"):lower()
    if text == "" then return nil end
    return text
end

local function zoneOf(name)
    local info = ns.Namespaced("C_ChatInfo", "GetChannelInfoFromIdentifier")
    if not info then return nil end
    local ok, id = pcall(function()
        local _, full = GetChannelName(name)
        if type(full) ~= "string" then return nil end
        local details = info(full)
        return details and details.zoneChannelID
    end)
    if not ok then return nil end
    id = ns.Plain(id)
    if type(id) ~= "number" then return nil end
    return id
end

function Channels.Live()
    local list = { pcall(GetChannelList) }
    local out = {}
    if not list[1] then return out end
    for index = 2, #list, 3 do
        local name = ns.PlainString(list[index + 1])
        local disabled = ns.Plain(list[index + 2]) == true
        if type(name) == "string" and name ~= "" and not disabled then
            local zone = zoneOf(name)
            if zone == nil or zone > 0 then
                out[#out + 1] = { name = name, zone = zone }
            end
        end
    end
    return out
end

function Channels.Enabled(name)
    local key = Channels.Key(name)
    if not key then return false end
    local store = ns.Storage.account and ns.Storage.account.channels
    local value = store and store[key]
    if value == nil then return DEFAULT_ON[key] == true end
    return value and true or false
end

function Channels.SetEnabled(name, value)
    local key = Channels.Key(name)
    if not key then return end
    local account = ns.Storage.account
    account.channels = account.channels or {}
    account.channels[key] = value and true or false
end

function Channels.EnabledCount()
    local total = 0
    for _, entry in ipairs(Channels.Live()) do
        if Channels.Enabled(entry.name) then total = total + 1 end
    end
    return total
end
