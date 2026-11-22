local addonName, ns = ...
local Storage = ns.Storage

local DEFAULTS = {
    running = true,
    threshold = 3,
    monitorTrade = true,
    monitorGeneral = true,
    monitorLFG = true,
    monitorOther = true,
    monitorSay = true,
    monitorYell = false,
    monitorWhisper = true,
    hideAboveSkill = false,
    greeting = "Hi %NAME%, saw you needed a box opened. Invite incoming.",
    announce = "CHAT",
    alertSound = true,
    alertChat = true,
    windowScale = 1.0,
    minimap = "table",
}

local function applyDefaults(store, defaults)
    for key, value in pairs(defaults) do
        if store[key] == nil then
            store[key] = (value == "table") and {} or value
        end
    end
end

function Storage.Initialise()
    TrickTurnerDB = TrickTurnerDB or {}
    applyDefaults(TrickTurnerDB, DEFAULTS)
    Storage.account = TrickTurnerDB
end

function Storage.Threshold()
    local value = tonumber(Storage.account.threshold)
    if not value then return ns.Parser.SENSITIVITY.NORMAL end
    return value
end

function Storage.ChannelEnabled(tag)
    local account = Storage.account
    if tag == "TRADE" then return account.monitorTrade end
    if tag == "GENERAL" then return account.monitorGeneral end
    if tag == "LFG" then return account.monitorLFG end
    if tag == "OTHER" then return account.monitorOther end
    if tag == "SAY" then return account.monitorSay end
    if tag == "YELL" then return account.monitorYell end
    if tag == "WHISPER" then return account.monitorWhisper end
    return false
end
