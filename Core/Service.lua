local addonName, ns = ...
local Service = ns.Service

local function restricted()
    local lockdown = ns.Namespaced("C_ChatInfo", "InChatMessagingLockdown")
    if lockdown then
        local ok, blocked = pcall(lockdown)
        if ok and blocked then return true end
    end
    local outgoing = ns.Namespaced("C_ChatInfo", "AreOutgoingAddonChatMessagesRestricted")
    if outgoing then
        local ok, blocked = pcall(outgoing)
        if ok and blocked then return true end
    end
    return false
end

Service.Restricted = restricted

function Service.CanInvite(name)
    if not name then return false, ns.L.REFUSE_NO_TARGET end
    if InCombatLockdown and InCombatLockdown() then return false, ns.L.REFUSE_COMBAT end
    if ns.IsGroupMember(name) then
        return false, string.format(ns.L.REFUSE_GROUPED, name)
    end
    if restricted() then return false, ns.L.REFUSE_RESTRICTED end
    local canInvite = ns.Namespaced("C_PartyInfo", "CanInvite")
    if canInvite then
        local ok, allowed = pcall(canInvite)
        if ok and not allowed then return false, ns.L.REFUSE_GROUP_FULL end
    end
    if IsInGroup and IsInGroup() then
        local leader = UnitIsGroupLeader and UnitIsGroupLeader("player")
        local assistant = UnitIsGroupAssistant and UnitIsGroupAssistant("player")
        if not (leader or assistant) then return false, ns.L.REFUSE_NOT_LEADER end
    end
    return true
end

function Service.Invite(name)
    local allowed, reason = Service.CanInvite(name)
    if not allowed then return false, reason end
    local invite = ns.Namespaced("C_PartyInfo", "InviteUnit", "InviteUnit")
        or ns.Namespaced(nil, nil, "InviteByName")
    if not invite then return false, ns.L.REFUSE_NO_API end
    local ok = pcall(invite, name)
    if not ok then return false, ns.L.REFUSE_NO_API end
    ns.Queue.SetState(name, "invited")
    return true
end

function Service.Greeting(job)
    local template = ns.Storage.account.greeting or ""
    local rank, _, known = ns.Skill.Get()
    local box = job and job.box and job.box.name or "box"
    local skill = known and tostring(rank) or "?"
    local text = template:gsub("%%NAME%%", job and job.name or "")
    text = text:gsub("%%BOX%%", box)
    text = text:gsub("%%SKILL%%", skill)
    return text
end

function Service.WhisperDraft(job)
    if not job or not job.name then return false, ns.L.REFUSE_NO_TARGET end
    local sendTell = ns.Namespaced("ChatFrameUtil", "SendTell", "ChatFrame_SendTell")
    if not sendTell then return false, ns.L.REFUSE_NO_API end
    local ok = pcall(sendTell, job.name)
    if not ok then return false, ns.L.REFUSE_NO_API end

    local box = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if box then
        local greeting = Service.Greeting(job)
        if greeting ~= "" then
            box:SetText(box:GetText() .. greeting)
            if box.SetCursorPosition then box:SetCursorPosition(#box:GetText()) end
        end
    end
    ns.Queue.SetState(job.name, "contacted")
    return true
end
