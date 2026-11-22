local addonName, ns = ...
local Parser = ns.Parser
local Boxes = ns.Boxes

local LINK_WEIGHT = 5
local BOX_WEIGHT = 3
local QUANTITY_CEILING = 40

Parser.SENSITIVITY = { LOOSE = 2, NORMAL = 3, STRICT = 4 }

local RULES = {
    {
        kind = "service",
        weight = 3,
        terms = {
            "lockpick", "lockpicking", "lock pick", "lock picking", "pick lock",
            "picklock", "unlock", "open my", "pick my", "opened", "crack",
        },
    },
    {
        kind = "intent",
        weight = 2,
        terms = {
            "need", "needed", "anyone", "anybody", "any1", "lf", "looking for",
            "wtb", "can someone", "can anyone", "someone", "who can", "who has",
            "who", "please", "pls", "plz", "help", "pst", "whisper me", "msg me",
            "available", "around",
        },
    },
    {
        kind = "class",
        weight = 1,
        terms = { "rogue", "rouge", "locksmith", "lockpicker" },
    },
    {
        kind = "tip",
        weight = 1,
        terms = { "tip", "paying", "will pay", "pay", "gold", "reward" },
    },
    {
        kind = "offer",
        weight = 0,
        veto = true,
        terms = {
            "i can open", "ill open", "i will open", "let me open", "i open",
            "i can unlock", "ill unlock", "open your", "your box", "your junkbox",
            "your lockbox", "at your service", "free lockpicking", "lockpicker here",
            "locksmith here", "lockpicking available", "pst me for", "whisper for",
            "tips appreciated", "tip appreciated", "tips welcome",
        },
    },
    {
        kind = "price",
        weight = 0,
        veto = true,
        patterns = {
            "%d+g each", "%d+g a ", " each ", " per box ", " per junkbox ", " a box ",
        },
    },
    {
        kind = "reject",
        weight = -7,
        terms = {
            "wts", "wtt", "lfm", "lfg", "selling", "sell", "boost", "boosting",
            "carry", "dungeon", "raid", "tank", "healer", "heals", "dps", "arena",
            "recruiting", "enchant", "enchanter", "portal", "summon", "warlock",
            "sm", "brd", "lbrs", "ubrs", "zf", "mara", "rfc", "rfd", "wc",
            "gnomer", "uldaman", "scholo", "strat", "mc", "bwl", "aq", "naxx",
            "wsg", "ab", "av", "brm", "dm", "st",
        },
    },
}

for _, rule in ipairs(RULES) do
    if rule.terms then
        for index = #rule.terms, 1, -1 do
            local clean = ns.NormaliseTerm(rule.terms[index])
            if clean then
                rule.terms[index] = clean
            else
                table.remove(rule.terms, index)
            end
        end
    end
end

Parser.RULES = RULES

local function itemIDs(message)
    local ids = {}
    for id in message:gmatch("|Hitem:(%d+)") do
        ids[#ids + 1] = tonumber(id)
    end
    return ids
end

local function flatten(message)
    local text = message
        :gsub("|c%x%x%x%x%x%x%x%x", " ")
        :gsub("|H.-|h.-|h", " ")
        :gsub("|T.-|t", " ")
        :gsub("|[rhn]", " ")
        :lower()
        :gsub("[^%a%d]", " ")
        :gsub("%s+", " ")
    return " " .. text .. " "
end

Parser.Flatten = flatten

local function contains(text, term)
    return text:find(" " .. term .. " ", 1, true) ~= nil
        or text:find(" " .. term .. "s ", 1, true) ~= nil
        or text:find(" " .. term .. "es ", 1, true) ~= nil
end

Parser.Contains = contains

local function quantity(text)
    for number, word in text:gmatch("(%d+) (%a+)") do
        if word:find("box", 1, true) or word:find("chest", 1, true) then
            local count = tonumber(number)
            if count and count > 1 and count <= QUANTITY_CEILING then return count end
        end
    end
    return nil
end

local function signal(result, kind, detail, weight)
    result.signals[#result.signals + 1] = { kind = kind, detail = detail, weight = weight }
    result.score = result.score + weight
end

function Parser.Scan(message)
    if type(message) ~= "string" or message == "" then return nil end

    local text = flatten(message)
    local result = { score = 0, signals = {}, text = text }

    for _, id in ipairs(itemIDs(message)) do
        local box = Boxes.Find(id)
        if box and not result.box then
            result.box = box
            result.itemID = id
            signal(result, "link", box.name, LINK_WEIGHT)
        end
    end

    for _, entry in ipairs(Boxes.Terms()) do
        if contains(text, entry.term) then
            result.box = result.box or entry.box
            signal(result, "box", entry.term, BOX_WEIGHT)
            break
        end
    end

    for _, rule in ipairs(RULES) do
        local hits
        if rule.terms then
            for _, term in ipairs(rule.terms) do
                if contains(text, term) then
                    hits = hits and (hits .. ", " .. term) or term
                end
            end
        end
        if rule.patterns then
            for _, pattern in ipairs(rule.patterns) do
                local found = text:match(pattern)
                if found then
                    found = found:match("^%s*(.-)%s*$")
                    hits = hits and (hits .. ", " .. found) or found
                end
            end
        end
        if hits then
            signal(result, rule.kind, hits, rule.weight)
            if rule.veto then result.veto = true end
        end
    end

    result.quantity = quantity(text)
    return result
end

function Parser.Matches(result, threshold)
    if not result or result.veto then return false end
    return result.score >= (threshold or Parser.SENSITIVITY.NORMAL)
end

function Parser.Explain(result)
    if not result or #result.signals == 0 then return "" end
    local parts = {}
    for _, item in ipairs(result.signals) do
        if item.weight == 0 then
            parts[#parts + 1] = string.format("%s veto (%s)", item.kind, item.detail)
        else
            parts[#parts + 1] = string.format("%s %+d (%s)", item.kind, item.weight, item.detail)
        end
    end
    return table.concat(parts, "  ")
end
