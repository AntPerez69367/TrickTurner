local addonName, ns = ...
local UI, Storage, Queue, Monitor = ns.UI, ns.Storage, ns.Queue, ns.Monitor
local Skill, Parser = ns.Skill, ns.Parser
local Tuning = UI.Tuning

local TABS = { "board", "options", "tuning" }

local M = {
    width = 560,
    height = 452,
    pad = 14,
    headerH = 30,
    closeSize = 22,
    tabTop = -34,
    tabH = 26,
    tabGap = 8,
    listTop = -74,
    listWidth = 532,
    footerTop = -390,
    statusTop = -422,
    optionsTop = -72,
    optionsHeight = 340,
    rowH = 20,
    rowGap = 8,
    sectionGap = 14,
    indent = 12,
}

local frame, boardPage, optionsPage, tuningPage, tabStrip, status, statusTimer
local footerDone, footerIgnore
local tabs = {}
local currentTab = "board"
local sections, layoutRows = {}, {}
local channelSection, channelRows = nil, {}
local trackButton
local canvas, scroll

local function tabLabel(name)
    if name == "options" then return ns.L.TAB_OPTIONS end
    if name == "tuning" then
        return string.format("%s (%d)", ns.L.TAB_TUNING, ns.Log.Count())
    end
    return string.format("%s (%d)", ns.L.TAB_BOARD, Queue.Count())
end

local function reflowTabs()
    local anchor
    for _, name in ipairs(TABS) do
        local tab = tabs[name]
        tab:ClearAllPoints()
        if anchor then
            tab:SetPoint("BOTTOMLEFT", anchor, "BOTTOMRIGHT", M.tabGap, 0)
        else
            tab:SetPoint("BOTTOMLEFT", tabStrip, "BOTTOMLEFT", 0, 0)
        end
        anchor = tab
    end
end

function UI.SetStatus(text, bad)
    if not status then return end
    status:SetText(text or "")
    UI.Ink(status, bad and UI.C.bad or UI.C.dim)
    if statusTimer then statusTimer:Cancel() end
    if bad then
        statusTimer = C_Timer.NewTimer(5, function()
            statusTimer = nil
            UI.Refresh()
        end)
    end
end

local function refreshTrack()
    if not trackButton then return end
    trackButton:SetText(Storage.account.running and ns.L.ACTION_STOP or ns.L.ACTION_START)
end

local function defaultStatus()
    if not Storage.account.running then return ns.L.STATUS_STOPPED end
    local parts = string.format(ns.L.STATUS_RUNNING, Monitor.ActiveChannels())
    parts = parts .. "  \226\128\162  " .. string.format(ns.L.STATUS_JOBS, Queue.Count())
    if Queue.scrubbed > 0 then
        parts = parts .. "  \226\128\162  " .. string.format(ns.L.STATUS_SCRUBBED, Queue.scrubbed)
    end
    return parts
end

local function layoutOptions()
    local y = 0
    for _, section in ipairs(sections) do
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -y)
        section.header:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", 0, -y)
        y = y + 22 + 6
        for _, row in ipairs(section.rows) do
            row:SetShown(section.header.expanded)
            if section.header.expanded then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", canvas, "TOPLEFT", M.indent, -y)
                row:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", -M.indent, -y)
                y = y + row:GetHeight() + M.rowGap
            end
        end
        y = y + M.sectionGap
    end
    canvas:SetHeight(math.max(y, M.optionsHeight))
end

local function syncChannelRows()
    if not channelSection then return false end
    local added = false
    for _, entry in ipairs(ns.Channels.Live()) do
        local key = ns.Channels.Key(entry.name)
        if key and not channelRows[key] then
            local name = entry.name
            local row = UI.Switch(canvas, name,
                function() return ns.Channels.Enabled(name) end,
                function(value)
                    ns.Channels.SetEnabled(name, value)
                    UI.Refresh()
                end)
            channelRows[key] = row
            channelSection.rows[#channelSection.rows + 1] = row
            layoutRows[#layoutRows + 1] = row
            added = true
        end
    end
    return added
end

function UI.Refresh()
    refreshTrack()
    if not frame then return end
    boardPage:SetShown(currentTab == "board")
    optionsPage:SetShown(currentTab == "options")
    tuningPage:SetShown(currentTab == "tuning")
    for _, name in ipairs(TABS) do
        tabs[name].SetLabel(tabLabel(name), name == currentTab)
    end
    reflowTabs()

    if currentTab == "board" then
        UI.List.Build()
        UI.List.Render()
        local job = UI.List.Selected()
        footerDone:SetEnabled(job ~= nil)
        footerIgnore:SetEnabled(job ~= nil)
        if not statusTimer then UI.SetStatus(defaultStatus()) end
    elseif currentTab == "tuning" then
        if Tuning.weight and Tuning.weight.Apply then Tuning.weight.Apply() end
        if Tuning.level and Tuning.level.Apply then Tuning.level.Apply() end
        Tuning.Render()
        if not statusTimer then UI.SetStatus(defaultStatus()) end
    else
        syncChannelRows()
        for _, row in ipairs(layoutRows) do
            if row.Apply then row.Apply() end
        end
        layoutOptions()
        if not statusTimer then UI.SetStatus(defaultStatus()) end
    end
end

local function switchTab(name)
    currentTab = name
    UI.List.ClearSelection()
    UI.Refresh()
end

local function buildHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -1)
    header:SetHeight(M.headerH)
    UI.Fill(header, UI.C.header)
    UI.Rule(header, "BOTTOM", UI.C.borderDim)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() parent:StartMoving() end)
    header:SetScript("OnDragStop", function() parent:StopMovingOrSizing() end)

    local title = UI.Text(header, "GameFontNormal")
    title:SetPoint("CENTER", header, "CENTER", 0, 0)
    title:SetText("Trick Turner")
    UI.Ink(title, UI.C.gold)

    local skill = UI.Text(header, "GameFontNormalSmall")
    skill:SetPoint("LEFT", header, "LEFT", 10, 0)
    skill:SetWordWrap(false)
    UI.Ink(skill, UI.C.dim)
    header.skill = skill

    trackButton = UI.Button(header, "", 56, function()
        Monitor.SetRunning(not Storage.account.running)
    end)

    local close = CreateFrame("Button", nil, header)
    close:SetSize(M.closeSize, M.closeSize)
    close:SetPoint("RIGHT", header, "RIGHT", -4, 0)
    local wash = UI.Fill(close, UI.C.buttonHover, 0)
    close.label = UI.Text(close, "GameFontNormal")
    close.label:SetPoint("CENTER")
    close.label:SetText("X")
    close.Apply = function()
        wash:SetColorTexture(UI.C.buttonHover[1], UI.C.buttonHover[2], UI.C.buttonHover[3],
            close.hover and 1 or 0)
        UI.Ink(close.label, close.hover and UI.C.white or UI.C.muted)
    end
    close:SetScript("OnEnter", function(self) self.hover = true; self.Apply() end)
    close:SetScript("OnLeave", function(self) self.hover = false; self.Apply() end)
    close:SetScript("OnClick", function() parent:Hide() end)
    close.Apply()

    trackButton:SetPoint("RIGHT", close, "LEFT", -6, 0)
    refreshTrack()
    return header
end

local function buildFooter(parent)
    footerDone = UI.Button(parent, ns.L.ACTION_DONE, 110, function()
        local job = UI.List.Selected()
        if not job then return end
        Queue.Complete(job.name)
        UI.List.ClearSelection()
        UI.Refresh()
    end)
    footerDone:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.footerTop)

    footerIgnore = UI.Button(parent, ns.L.ACTION_IGNORE, 110, function()
        local job = UI.List.Selected()
        if not job then return end
        Queue.Ignore(job.name)
        UI.List.ClearSelection()
        UI.Refresh()
    end)
    footerIgnore:SetPoint("LEFT", footerDone, "RIGHT", 8, 0)

    status = UI.Text(parent, "GameFontNormalSmall")
    status:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.statusTop)
    status:SetWidth(M.listWidth)
    status:SetJustifyH("LEFT")
    status:SetWordWrap(false)
    UI.Ink(status, UI.C.dim)
end

local function addSection(title, rows)
    local header = UI.Section(canvas, title, function() layoutOptions() end)
    local section = { header = header, rows = rows }
    sections[#sections + 1] = section
    for _, row in ipairs(rows) do layoutRows[#layoutRows + 1] = row end
    return section
end

local function switchRow(label, key)
    return UI.Switch(canvas, label,
        function() return Storage.account[key] end,
        function(value)
            Storage.account[key] = value
            if key == "running" then Monitor.SetRunning(value) end
            UI.Refresh()
        end)
end

local function buildOptions(parent)
    scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pad, M.optionsTop)
    scroll:SetSize(M.listWidth - 8, M.optionsHeight)
    scroll:EnableMouseWheel(true)
    canvas = CreateFrame("Frame", nil, scroll)
    canvas:SetSize(M.listWidth - 8, M.optionsHeight)
    scroll:SetScrollChild(canvas)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, canvas:GetHeight() - M.optionsHeight)
        local target = math.max(0, math.min(range, self:GetVerticalScroll() - delta * 28))
        self:SetVerticalScroll(target)
    end)

    addSection(ns.L.SECTION_MONITORING, {
        switchRow(ns.L.SETTING_RUNNING, "running"),
        switchRow(ns.L.SETTING_SAY, "monitorSay"),
        switchRow(ns.L.SETTING_YELL, "monitorYell"),
        switchRow(ns.L.SETTING_WHISPER, "monitorWhisper"),
    })

    channelSection = addSection(ns.L.SECTION_CHANNELS, {})
    syncChannelRows()

    local sensitivity = UI.Segmented(canvas, {
        { value = Parser.SENSITIVITY.LOOSE, label = ns.L.SENSITIVITY_LOOSE },
        { value = Parser.SENSITIVITY.NORMAL, label = ns.L.SENSITIVITY_NORMAL },
        { value = Parser.SENSITIVITY.STRICT, label = ns.L.SENSITIVITY_STRICT },
    }, 72,
        function() return Storage.Threshold() end,
        function(value) Storage.account.threshold = value; UI.Refresh() end,
        ns.L.SETTING_SENSITIVITY_HELP)
    addSection(ns.L.SECTION_MATCHING, {
        sensitivity,
        switchRow(ns.L.SETTING_HIDE_ABOVE_SKILL, "hideAboveSkill"),
    })

    local announce = UI.Segmented(canvas, {
        { value = "CHAT", label = ns.L.ANNOUNCE_CHAT },
        { value = "ERROR", label = ns.L.ANNOUNCE_ERROR },
        { value = "NONE", label = ns.L.ANNOUNCE_NONE },
    }, 96,
        function() return Storage.account.announce end,
        function(value) Storage.account.announce = value end,
        ns.L.SETTING_ANNOUNCE)
    addSection(ns.L.SECTION_ALERTS, {
        switchRow(ns.L.SETTING_SOUND, "alertSound"),
        switchRow(ns.L.SETTING_ALERT_CHAT, "alertChat"),
        announce,
    })

    addSection(ns.L.SECTION_GREETING, {
        UI.Field(canvas, ns.L.SETTING_GREETING, M.listWidth - 40,
            ns.L.SETTING_GREETING_HELP,
            function() return Storage.account.greeting end,
            function(value) Storage.account.greeting = value end),
    })

    addSection(ns.L.SECTION_WINDOW, {
        UI.Slider(canvas, ns.L.SETTING_SCALE, 0.8, 1.5, 0.05,
            function() return Storage.account.windowScale end,
            function(value)
                Storage.account.windowScale = value
                frame:SetScale(value)
            end),
        UI.Switch(canvas, ns.L.SETTING_MINIMAP,
            function() return not Storage.account.minimap.hide end,
            function(value)
                Storage.account.minimap.hide = not value
                ns.Minimap.SetShown(value)
            end),
    })
    layoutOptions()
end

local function build()
    frame = CreateFrame("Frame", "TrickTurnerWindow", UIParent)
    frame:SetSize(M.width, M.height)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:Hide()
    UI.Fill(frame, UI.C.frame)
    UI.Edge(frame, UI.C.border)
    frame:SetScale(Storage.account.windowScale or 1)
    tinsert(UISpecialFrames, "TrickTurnerWindow")

    frame.header = buildHeader(frame)

    tabStrip = CreateFrame("Frame", nil, frame)
    tabStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", M.pad, M.tabTop)
    tabStrip:SetSize(M.listWidth, M.tabH)
    UI.Rule(tabStrip, "BOTTOM", UI.C.borderDim)
    for _, name in ipairs(TABS) do
        tabs[name] = UI.Tab(tabStrip, M.tabH, function() switchTab(name) end)
        tabs[name].SetLabel(tabLabel(name), name == currentTab)
    end
    reflowTabs()

    boardPage = CreateFrame("Frame", nil, frame)
    boardPage:SetAllPoints(frame)
    optionsPage = CreateFrame("Frame", nil, frame)
    optionsPage:SetAllPoints(frame)
    optionsPage:Hide()
    tuningPage = CreateFrame("Frame", nil, frame)
    tuningPage:SetAllPoints(frame)
    tuningPage:Hide()

    UI.List.Attach(boardPage, M)
    buildFooter(boardPage)
    buildOptions(optionsPage)
    Tuning.Attach(tuningPage, M)

    frame:SetScript("OnShow", function()
        Skill.Refresh()
        local rank, maximum, known = Skill.Get()
        frame.header.skill:SetText(known
            and string.format("Lockpicking %d/%d", rank, maximum)
            or "Lockpicking \226\128\148")
        UI.Refresh()
    end)
end

function UI.Toggle()
    if not frame then build() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function UI.Open(tab)
    if not frame then build() end
    if tab then currentTab = tab end
    frame:Show()
    UI.Refresh()
end
