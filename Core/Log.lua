local addonName, ns = ...
local Log = ns.Log

local LIMIT = 300

function Log.Record(name, message, channel, result, matched)
    local store = ns.Storage.account.log
    if not store then return end
    store[#store + 1] = {
        at = time(),
        name = name,
        channel = channel,
        text = ns.Queue.DisplayCopy(message),
        score = result.score,
        veto = result.veto and true or nil,
        matched = matched and true or nil,
        explain = ns.Parser.Explain(result),
        vote = nil,
    }
    while #store > LIMIT do table.remove(store, 1) end
end

function Log.Entries()
    return ns.Storage.account.log or {}
end

function Log.Count()
    return #Log.Entries()
end

function Log.Clear()
    ns.Storage.account.log = {}
end

function Log.Vote(entry, vote)
    if entry.vote == vote then
        entry.vote = nil
    else
        entry.vote = vote
    end
end

function Log.Tally()
    local up, down = 0, 0
    for _, entry in ipairs(Log.Entries()) do
        if entry.vote == "up" then up = up + 1
        elseif entry.vote == "down" then down = down + 1 end
    end
    return up, down
end

function Log.Verdict(entry)
    if entry.veto then return "veto" end
    if entry.matched then return "match" end
    return "below"
end
