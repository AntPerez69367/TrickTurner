local addonName, ns = ...

ns.name = addonName
ns.Storage = {}
ns.Boxes = {}
ns.Parser = {}
ns.Skill = {}
ns.Queue = {}
ns.Service = {}
ns.Channels = {}
ns.Log = {}
ns.Monitor = {}
ns.Commands = {}
ns.Minimap = {}
ns.UI = {}
ns.L = {}

function ns.Plain(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then return nil end
    if type(canaccessvalue) == "function" and not canaccessvalue(value) then return nil end
    return value
end

function ns.PlainString(value)
    local plain = ns.Plain(value)
    if type(plain) ~= "string" or plain == "" then return nil end
    return plain
end

function ns.Print(message)
    print("|cff66ccffTrick Turner|r " .. tostring(message))
end

function ns.Announce(message)
    local destination = ns.Storage.account.announce
    if destination == "NONE" then return end
    if destination == "ERROR" then
        UIErrorsFrame:AddMessage(message, 0.40, 0.80, 1.00)
        return
    end
    ns.Print(message)
end

function ns.NormaliseTerm(term)
    if type(term) ~= "string" then return nil end
    local text = term:lower():gsub("[^%a%d]", " "):gsub("%s+", " ")
    text = text:match("^%s*(.-)%s*$")
    if text == "" then return nil end
    return text
end

function ns.Namespaced(container, method, fallback)
    local holder = container and _G[container]
    local candidate = holder and holder[method]
    if type(candidate) == "function" then return candidate end
    candidate = fallback and _G[fallback]
    if type(candidate) == "function" then return candidate end
    return nil
end

function ns.UnitAddress(unit)
    local full = ns.Namespaced("NameUtil", "GetUnmodifiedUnitFullName")
    if full then
        local ok, address = pcall(full, unit)
        if ok then
            local plain = ns.PlainString(address)
            if plain then return plain end
        end
    end
    local getName = UnitNameUnmodified or UnitName
    if type(getName) ~= "function" then return nil end
    local first, surname = getName(unit)
    first = ns.PlainString(first)
    if not first then return nil end
    surname = ns.PlainString(surname)
    if not surname then return first end
    local separators = Constants and Constants.CharacterNameSeparatorConsts
    return first .. (separators and separators.CHARACTERNAME_SURNAME_SEPARATOR or " ") .. surname
end

function ns.NameKey(name)
    local plain = ns.PlainString(name)
    if not plain then return nil end
    return plain:lower()
end

function ns.IsGroupMember(name)
    local key = ns.NameKey(name)
    if not key then return false end
    if key == ns.NameKey(ns.UnitAddress("player")) then return true end
    local raid = IsInRaid and IsInRaid()
    local count = (GetNumGroupMembers and GetNumGroupMembers()) or 0
    for index = 1, count do
        local unit = (raid and "raid" or "party") .. index
        if key == ns.NameKey(ns.UnitAddress(unit)) then return true end
    end
    return false
end
