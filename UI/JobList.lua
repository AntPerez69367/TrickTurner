local addonName, ns = ...
local UI, Queue, Skill, Service = ns.UI, ns.Queue, ns.Skill, ns.Service
local Storage = ns.Storage

local ROW_HEIGHT = 38
local VISIBLE_ROWS = 8
local GUTTER = 4
local GUTTER_SPAN = 8
local THUMB_MIN = 18
local CHIP_HEIGHT = 14
local ACTION_WIDTH = 54

local STATE_INK = {
    new = "accent",
    contacted = "gold",
    invited = "muted",
    grouped = "dim",
}

local List = {}
UI.List = List

local pool = {}
local entries = {}
local selected
local offset = 0
local hovering = false
local panel, empty, track, thumb, rowWidth, enableButton
local hiddenCount = 0

local function skillBadge(box)
    if not box or type(box.skill) ~= "number" then return ns.L.SKILL_UNKNOWN, UI.C.dim end
    local rank, _, known = Skill.Get()
    if not known then return string.format(ns.L.SKILL_REQUIRED, box.skill), UI.C.dim end
    if rank >= box.skill then return string.format(ns.L.SKILL_REQUIRED, box.skill), UI.C.muted end
    return string.format(ns.L.SKILL_TOO_LOW, box.skill, rank), UI.C.bad
end

local function hiddenBySkill(job)
    if not Storage.account.hideAboveSkill then return false end
    return Skill.CanOpen(job.box and job.box.skill) == false
end

local function act(job, action)
    if action == "invite" then
        local ok, reason = Service.Invite(job.name)
        if not ok then UI.SetStatus(reason, true) end
    elseif action == "whisper" then
        local ok, reason = Service.WhisperDraft(job)
        if not ok then UI.SetStatus(reason, true) end
    end
    UI.Refresh()
end

local function createRow(slot)
    local row = CreateFrame("Button", nil, panel)
    row:SetSize(rowWidth, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1 - (slot - 1) * ROW_HEIGHT)

    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row)
    row.stripe:SetColorTexture(1, 1, 1, slot % 2 == 0 and 0.035 or 0)
    row.hover = row:CreateTexture(nil, "BORDER")
    row.hover:SetAllPoints(row)
    row.hover:SetColorTexture(1, 1, 1, 0.07)
    row.hover:Hide()
    row.fill = row:CreateTexture(nil, "BORDER")
    row.fill:SetAllPoints(row)
    row.fill:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.22)
    row.fill:Hide()
    row.state = row:CreateTexture(nil, "ARTWORK")
    row.state:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.state:SetSize(3, ROW_HEIGHT)

    row.name = UI.Text(row, "GameFontNormalSmall")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -5)
    row.name:SetWidth(140)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.badge = UI.Text(row, "GameFontNormalSmall")
    row.badge:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -5)
    row.badge:SetJustifyH("RIGHT")
    row.badge:SetWordWrap(false)

    row.chip = UI.Chip(row, CHIP_HEIGHT)
    row.chip:SetPoint("TOPLEFT", row.name, "TOPRIGHT", 6, -1)

    row.box = UI.Text(row, "GameFontNormalSmall")
    row.box:SetPoint("LEFT", row.chip, "RIGHT", 6, 0)
    row.box:SetPoint("RIGHT", row.badge, "LEFT", -6, 0)
    row.box:SetJustifyH("LEFT")
    row.box:SetWordWrap(false)

    row.message = UI.Text(row, "GameFontNormalSmall")
    row.message:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 6)
    row.message:SetJustifyH("LEFT")
    row.message:SetWordWrap(false)

    row.actions = CreateFrame("Frame", nil, row)
    row.actions:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 4)
    row.actions:SetSize(ACTION_WIDTH * 2 + 4, 18)
    row.actions:Hide()
    row.invite = UI.Button(row.actions, ns.L.ACTION_INVITE, ACTION_WIDTH,
        function() if row.job then act(row.job, "invite") end end)
    row.invite:SetHeight(18)
    row.invite:SetPoint("LEFT", row.actions, "LEFT", 0, 0)
    row.whisper = UI.Button(row.actions, ns.L.ACTION_WHISPER, ACTION_WIDTH,
        function() if row.job then act(row.job, "whisper") end end)
    row.whisper:SetHeight(18)
    row.whisper:SetPoint("LEFT", row.invite, "RIGHT", 4, 0)

    row:SetScript("OnEnter", function(self)
        self.hover:Show()
        self.actions:Show()
        self.message:SetPoint("RIGHT", self.actions, "LEFT", -8, 0)
        if not self.job then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.job.name, 1, 1, 1)
        GameTooltip:AddLine(self.job.message, 0.8, 0.8, 0.8, true)
        if self.job.explain ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(self.job.explain, 0.55, 0.6, 0.7, true)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        self.actions:Hide()
        self.message:SetPoint("RIGHT", self, "RIGHT", -10, 0)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick", function(self)
        selected = (selected ~= self.key) and self.key or nil
        UI.Refresh()
    end)
    return row
end

local function updateRow(row, job)
    row.key, row.job = job.key, job
    row.name:SetText(job.name)
    UI.Ink(row.name, UI.C.text)
    row.chip.Set(ns.L["CHANNEL_" .. job.channel] or job.channelName or job.channel, UI.C.muted)

    local label = job.box and ns.Boxes.Label(job.box, job.quantity) or ""
    row.box:SetText(label)
    UI.Ink(row.box, UI.C.muted)

    local badge, colour = skillBadge(job.box)
    row.badge:SetText(badge)
    UI.Ink(row.badge, colour)

    row.message:SetText(job.message)
    UI.Ink(row.message, UI.C.dim)

    local ink = UI.C[STATE_INK[job.state] or "accent"]
    row.state:SetColorTexture(ink[1], ink[2], ink[3], 1)
    row.state:SetShown(job.state ~= "new")

    row.fill:SetShown(selected == job.key)
end

local function paintGutter(total, maxOffset)
    if maxOffset == 0 then
        track:Hide(); thumb:Hide(); return
    end
    local span = VISIBLE_ROWS * ROW_HEIGHT - 4
    local height = math.max(THUMB_MIN, math.floor(span * VISIBLE_ROWS / total))
    thumb:SetHeight(height)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3,
        -3 - math.floor((span - height) * offset / maxOffset))
    track:Show(); thumb:Show()
end

function List.Build()
    if hovering and #entries > 0 then return end
    entries = {}
    hiddenCount = 0
    for _, job in ipairs(Queue.List()) do
        if hiddenBySkill(job) then
            hiddenCount = hiddenCount + 1
        else
            entries[#entries + 1] = job
        end
    end
    if selected then
        local found
        for _, job in ipairs(entries) do
            if job.key == selected then found = true break end
        end
        if not found then selected = nil end
    end
end

function List.Selected()
    if not selected then return nil end
    return Queue.Get(selected)
end

function List.ClearSelection()
    selected = nil
end

function List.Hidden()
    return hiddenCount
end

local function emptyMessage()
    if not Storage.account.running then return ns.L.EMPTY_STOPPED end
    if ns.Monitor.ActiveChannels() == 0 then return ns.L.EMPTY_NO_CHANNELS end
    if hiddenCount > 0 then return string.format(ns.L.EMPTY_HIDDEN, hiddenCount) end
    return ns.L.EMPTY_QUIET
end

function List.Render()
    local total = #entries
    local maxOffset = math.max(0, total - VISIBLE_ROWS)
    offset = math.max(0, math.min(offset, maxOffset))
    for slot = 1, VISIBLE_ROWS do
        local job = entries[slot + offset]
        if job then
            updateRow(pool[slot], job)
            pool[slot]:Show()
        else
            pool[slot].job = nil
            pool[slot]:Hide()
        end
    end
    paintGutter(total, maxOffset)
    if total == 0 then
        empty:SetText(emptyMessage())
        empty:Show()
        enableButton:SetShown(not Storage.account.running)
    else
        empty:Hide()
        enableButton:Hide()
    end
end

function List.Attach(parent, metrics)
    rowWidth = metrics.listWidth - GUTTER_SPAN - 2
    panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", metrics.pad, metrics.listTop)
    panel:SetSize(metrics.listWidth, VISIBLE_ROWS * ROW_HEIGHT + 2)
    UI.Fill(panel, UI.C.content, 0.45)
    UI.Edge(panel, UI.C.borderDim)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        offset = offset - delta
        List.Render()
    end)
    panel:SetScript("OnEnter", function() hovering = true end)
    panel:SetScript("OnLeave", function()
        hovering = false
        UI.Refresh()
    end)

    track = panel:CreateTexture(nil, "ARTWORK")
    track:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
    track:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3, 3)
    track:SetWidth(GUTTER)
    track:SetColorTexture(1, 1, 1, 0.05)
    track:Hide()
    thumb = panel:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(GUTTER)
    thumb:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.6)
    thumb:Hide()

    for slot = 1, VISIBLE_ROWS do pool[slot] = createRow(slot) end

    empty = UI.Text(panel, "GameFontDisableLarge")
    empty:SetPoint("CENTER", panel, "CENTER", 0, 12)
    empty:SetWidth(metrics.listWidth - 60)
    empty:SetJustifyH("CENTER")
    empty:Hide()

    enableButton = UI.Button(panel, ns.L.EMPTY_ENABLE, 150, function()
        ns.Monitor.SetRunning(true)
    end)
    enableButton:SetPoint("CENTER", empty, "CENTER", 0, -34)
    enableButton:Hide()
end
