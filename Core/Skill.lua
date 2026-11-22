local addonName, ns = ...
local Skill = ns.Skill

local LOCKPICKING_SKILL_LINE = 633
local PICK_LOCK_SPELL = 1804

local rank, maximum, known = 0, 0, false

local function spellName(spellID)
    local getter = ns.Namespaced("C_Spell", "GetSpellName", "GetSpellInfo")
    if not getter then return nil end
    local ok, name = pcall(getter, spellID)
    if not ok then return nil end
    return ns.PlainString(name)
end

local function isLockpicking(name)
    local plain = ns.PlainString(name)
    if not plain then return false end
    plain = plain:lower()
    if plain == "lockpicking" then return true end
    local localised = spellName(PICK_LOCK_SPELL)
    return localised ~= nil and plain == localised:lower()
end

function Skill.Refresh()
    local byID = ns.Namespaced("C_SkillInfo", "GetSkillLineInfoByID")
    if byID then
        local ok, data = pcall(byID, LOCKPICKING_SKILL_LINE)
        if ok and type(data) == "table" then
            local current, ceiling = ns.Plain(data.rank), ns.Plain(data.maxRank)
            if type(current) == "number" and type(ceiling) == "number" then
                rank, maximum, known = current, ceiling, true
                return rank, maximum, known
            end
        end
    end

    if type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
        local ok, count = pcall(GetNumSkillLines)
        if ok and type(count) == "number" then
            for index = 1, count do
                local fine, name, isHeader, _, skillRank, _, _, skillMax =
                    pcall(GetSkillLineInfo, index)
                if fine and not ns.Plain(isHeader) and isLockpicking(name) then
                    local current, ceiling = ns.Plain(skillRank), ns.Plain(skillMax)
                    if type(current) == "number" then
                        rank = current
                        maximum = type(ceiling) == "number" and ceiling or 0
                        known = true
                        return rank, maximum, known
                    end
                end
            end
        end
    end

    rank, maximum, known = 0, 0, false
    return rank, maximum, known
end

function Skill.Get()
    return rank, maximum, known
end

function Skill.CanOpen(required)
    if not known or type(required) ~= "number" then return nil end
    return rank >= required
end

function Skill.Initialise()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("SKILL_LINES_CHANGED")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:RegisterEvent("PLAYER_LEVEL_UP")
    frame:SetScript("OnEvent", Skill.Refresh)
    Skill.Refresh()
end
