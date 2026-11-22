local addonName, ns = ...
local Storage = ns.Storage

local DEFAULTS = {
    running = true,
    threshold = 3,
    channels = "table",
    log = "table",
    logLevel = 1,
    monitorSay = true,
    monitorYell = true,
    monitorWhisper = true,
    hideAboveSkill = false,
    greeting = "Hi %NAME%, saw you needed a box opened. Invite incoming.",
    announce = "CHAT",
    alertSound = true,
    alertChat = true,
    windowScale = 1.0,
    minimap = "table",
}

local SCHEMA = 2

local function migrate(store)
    if store.schema == SCHEMA then return end
    store.monitorTrade, store.monitorGeneral = nil, nil
    store.monitorLFG, store.monitorOther = nil, nil
    store.monitorYell = nil
    store.schema = SCHEMA
end

local function applyDefaults(store, defaults)
    for key, value in pairs(defaults) do
        if store[key] == nil then
            store[key] = (value == "table") and {} or value
        end
    end
end

function Storage.Initialise()
    TrickTurnerDB = TrickTurnerDB or {}
    migrate(TrickTurnerDB)
    applyDefaults(TrickTurnerDB, DEFAULTS)
    Storage.account = TrickTurnerDB
end

function Storage.Threshold()
    local value = tonumber(Storage.account.threshold)
    if not value then return ns.Parser.SENSITIVITY.NORMAL end
    return value
end

function Storage.LogLevel()
    local value = tonumber(Storage.account.logLevel)
    if not value then return 1 end
    return value
end

function Storage.SourceEnabled(tag, channelName)
    local account = Storage.account
    if tag == "CHANNEL" then return ns.Channels.Enabled(channelName) end
    if tag == "SAY" then return account.monitorSay end
    if tag == "YELL" then return account.monitorYell end
    if tag == "WHISPER" then return account.monitorWhisper end
    return false
end
