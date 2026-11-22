-- Minimal WoW client stand-in: enough frame, event and chat surface to load the
-- addon end to end and drive its event handlers. Not a simulator.
local stub = {}

local methods = {}
local function noop() end

local function object(name)
    return setmetatable({ name = name, scripts = {}, events = {}, shown = false, text = "" },
        { __index = function(_, key)
            if methods[key] then return methods[key] end
            if type(key) == "string" and key:match("^%u") then return noop end
            return nil
        end })
end
stub.object = object

function methods:SetScript(key, fn) self.scripts[key] = fn end
function methods:GetScript(key) return self.scripts[key] end
function methods:HookScript(key, fn) self.scripts[key] = fn end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:IsEventRegistered(event) return self.events[event] == true end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown end
function methods:SetShown(value) self.shown = value and true or false end
function methods:SetText(value) self.text = value or "" end
function methods:GetText() return self.text or "" end
function methods:GetStringWidth() return 80 end
function methods:GetHeight() return self.height or 20 end
function methods:SetHeight(value) self.height = value end
function methods:GetWidth() return self.width or 100 end
function methods:SetWidth(value) self.width = value end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetVerticalScroll() return 0 end
function methods:CreateTexture() return object("texture") end
function methods:CreateFontString() return object("fontstring") end
function methods:SetEnabled(value) self.enabled = value end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:SetScrollChild(child) self.child = child end

function stub.install(G)
    local frames = {}
    G.CreateFrame = function(_, name)
        local frame = object(name or "frame")
        frames[#frames + 1] = frame
        return frame
    end
    stub.frames = frames

    G.UIParent = object("UIParent")
    G.UIErrorsFrame = object("UIErrorsFrame")
    G.GameTooltip = object("GameTooltip")
    G.UISpecialFrames = {}
    G.SlashCmdList = {}
    G.NUM_CHAT_WINDOWS = 1
    G.SOUNDKIT = { TELL_MESSAGE = 1 }
    G.ITEM_QUALITY_COLORS = {}

    G.tinsert = table.insert
    G.time = function() return stub.now or 1000 end
    G.GetTime = function() return stub.now or 1000 end
    G.GetLocale = function() return "enUS" end
    G.PlaySound = noop
    G.InCombatLockdown = function() return stub.inCombat == true end
    G.IsInGroup = function() return stub.group ~= nil and #stub.group > 0 end
    G.IsInRaid = function() return false end
    G.GetNumGroupMembers = function() return stub.group and #stub.group or 0 end
    G.UnitIsGroupLeader = function() return true end
    G.UnitIsGroupAssistant = function() return true end
    G.UnitName = function(unit)
        if unit == "player" then return stub.playerName or "Tester" end
        local index = tonumber((unit or ""):match("%d+"))
        local member = index and stub.group and stub.group[index]
        if member then return member end
        return nil
    end
    G.UnitNameUnmodified = G.UnitName
    G.GetNumSkillLines = function() return stub.skill and 1 or 0 end
    G.GetSkillLineInfo = function()
        if not stub.skill then return nil end
        return "Lockpicking", false, true, stub.skill, 0, 0, 300
    end
    G.GetChatWindowChannels = function()
        if stub.shownChannels then return unpack(stub.shownChannels) end
        return nil
    end
    G.ChatEdit_GetActiveWindow = function() return stub.editBox end
    G.ChatFrame_SendTell = function(target) stub.lastTell = target end
    G.InviteUnit = function(target) stub.lastInvite = target end
    G.C_Timer = { NewTimer = function() return { Cancel = noop } end,
                  After = noop, NewTicker = function() return { Cancel = noop } end }
    G.LibStub = function()
        return { NewDataObject = function(_, _, obj) return obj end,
                 Register = noop, Show = noop, Hide = noop }
    end
    G.print = function(...) stub.printed[#stub.printed + 1] = table.concat({ ... }, " ") end
    stub.printed = {}
end

function stub.fire(frame, event, ...)
    local handler = frame.scripts.OnEvent
    if handler then handler(frame, event, ...) end
end

function stub.fireAll(event, ...)
    for _, frame in ipairs(stub.frames) do
        if frame.events[event] then stub.fire(frame, event, ...) end
    end
end

return stub
