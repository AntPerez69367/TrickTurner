local addonName, ns = ...
local Monitor = ns.Monitor
local Storage, Queue, Parser = ns.Storage, ns.Queue, ns.Parser

local frame

local function consider(message, sender, tag, channelName)
    if not Storage.account.running then return end
    if not Storage.SourceEnabled(tag, channelName) then return end

    local text = ns.PlainString(message)
    local name = ns.PlainString(sender)
    if not text or not name then
        Queue.scrubbed = Queue.scrubbed + 1
        return
    end

    local key = ns.NameKey(name)
    if not key then return end
    if key == ns.NameKey(ns.UnitAddress("player")) then return end
    if ns.IsGroupMember(name) then return end
    if Queue.IsIgnored(name) then return end

    local result = Parser.Scan(text)
    if not result then return end

    local matched = Parser.Matches(result, Storage.Threshold())
    if matched or result.score >= Storage.LogLevel() then
        ns.Log.Record(name, text, channelName or tag, result, matched)
    end
    if not matched then return end

    local job, fresh, chime = Queue.Add(name, text, tag, channelName, result)
    if not job then return end

    if chime then Monitor.Alert(job) end
    if ns.UI and ns.UI.Refresh then ns.UI.Refresh() end
end

Monitor.Consider = consider

function Monitor.Alert(job)
    if Storage.account.alertSound then
        local play = ns.Namespaced(nil, nil, "PlaySound")
        if play then
            local kit = SOUNDKIT and SOUNDKIT.TELL_MESSAGE
            pcall(play, kit or "TellMessage")
        end
    end
    if Storage.account.alertChat then
        local box = job.box and ns.Boxes.Label(job.box, job.quantity) or "?"
        ns.Announce(string.format(ns.L.ANNOUNCE_MATCH, job.name,
            ns.L["CHANNEL_" .. job.channel] or job.channel, box))
    end
end

local function onChannel(...)
    local message, sender = ...
    local zone = ns.Plain(select(7, ...))
    if type(zone) ~= "number" or zone <= 0 then return end
    local baseName = ns.PlainString(select(9, ...))
    if not baseName then return end
    consider(message, sender, "CHANNEL", baseName)
end

local function onRoster()
    for _, job in ipairs(Queue.List()) do
        if job.state ~= "grouped" and ns.IsGroupMember(job.name) then
            Queue.SetState(job.name, "grouped")
        end
    end
    if ns.UI and ns.UI.Refresh then ns.UI.Refresh() end
end

function Monitor.Initialise()
    if frame then return end
    frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_CHANNEL")
    frame:RegisterEvent("CHAT_MSG_WHISPER")
    frame:RegisterEvent("CHAT_MSG_SAY")
    frame:RegisterEvent("CHAT_MSG_YELL")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("CHANNEL_UI_UPDATE")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_CHANNEL" then
            onChannel(...)
        elseif event == "GROUP_ROSTER_UPDATE" then
            onRoster()
        elseif event == "CHANNEL_UI_UPDATE" then
            if ns.UI and ns.UI.Refresh then ns.UI.Refresh() end
        else
            local message, sender = ...
            local tag = event:match("^CHAT_MSG_(%u+)$")
            if tag then consider(message, sender, tag) end
        end
    end)
end

function Monitor.ActiveChannels()
    local total = ns.Channels.EnabledCount()
    for _, tag in ipairs({ "SAY", "YELL", "WHISPER" }) do
        if Storage.SourceEnabled(tag) then total = total + 1 end
    end
    return total
end

function Monitor.SetRunning(value)
    Storage.account.running = value and true or false
    if ns.UI and ns.UI.Refresh then ns.UI.Refresh() end
end
