local addonName, ns = ...
local Commands = ns.Commands
local Storage, Queue, Parser, Monitor = ns.Storage, ns.Queue, ns.Parser, ns.Monitor

local NEAR_MISS_LIMIT = 40

local nearMisses = {}

function Commands.RecordNearMiss(name, message, result)
    if not result.box then return end
    nearMisses[#nearMisses + 1] = {
        name = name,
        message = Queue.DisplayCopy(message),
        score = result.score,
        veto = result.veto,
        explain = Parser.Explain(result),
        at = time(),
    }
    while #nearMisses > NEAR_MISS_LIMIT do table.remove(nearMisses, 1) end
end

function Commands.NearMisses()
    return nearMisses
end

local function describe(result)
    local verdict
    if result.veto then
        verdict = "|cffff6666vetoed|r"
    elseif Parser.Matches(result, Storage.Threshold()) then
        verdict = "|cff66ff66match|r"
    else
        verdict = "|cffffcc33below threshold|r"
    end
    ns.Print(string.format("score %d vs %d  %s", result.score, Storage.Threshold(), verdict))
    ns.Print("  " .. (Parser.Explain(result) ~= "" and Parser.Explain(result) or "no signals"))
    if result.box then
        ns.Print("  box: " .. ns.Boxes.Label(result.box, result.quantity)
            .. (result.box.skill and ("  needs " .. result.box.skill) or "  skill unknown"))
    end
end

local function devCommand(argument)
    if argument == "" then
        ns.Print("usage: /tt dev <a chat message to score>")
        return
    end
    local result = Parser.Scan(argument)
    if not result then
        ns.Print("nothing to score")
        return
    end
    describe(result)
end

local function missesCommand()
    if #nearMisses == 0 then
        ns.Print("no near misses recorded")
        return
    end
    ns.Print(string.format("%d near misses, newest last:", #nearMisses))
    for _, miss in ipairs(nearMisses) do
        ns.Print(string.format("  |cff888888%s|r %s", miss.name, miss.message))
        ns.Print(string.format("    score %d%s  %s", miss.score,
            miss.veto and " (vetoed)" or "", miss.explain))
    end
end

SLASH_TRICKTURNER1, SLASH_TRICKTURNER2 = "/trick", "/tt"

SlashCmdList.TRICKTURNER = function(message)
    if not Storage.account then return end
    local command, argument = (message or ""):match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()

    if command == "" then
        if ns.UI.Toggle then ns.UI.Toggle() end
    elseif command == "dev" then
        devCommand(argument)
    elseif command == "misses" then
        missesCommand()
    elseif command == "start" then
        Monitor.SetRunning(true)
        ns.Print("watching " .. Monitor.ActiveChannels() .. " channels")
    elseif command == "stop" then
        Monitor.SetRunning(false)
        ns.Print("stopped")
    elseif command == "clear" then
        Queue.Clear()
        ns.Print("board cleared")
        if ns.UI.Refresh then ns.UI.Refresh() end
    else
        ns.Print("/trick, /tt — open the board")
        ns.Print("/tt start | stop — watch chat, or do not")
        ns.Print("/tt dev <message> — score a message and show every signal")
        ns.Print("/tt misses — messages that named a box but scored too low")
        ns.Print("/tt clear — empty the board")
    end
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("ADDON_LOADED")
bootstrap:SetScript("OnEvent", function(self, _, loaded)
    if loaded ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    Storage.Initialise()
    ns.LoadLocale()
    ns.Skill.Initialise()
    ns.Minimap.Initialise()
    Monitor.Initialise()
    ns.UI.RegisterOptions()
end)
