local addonName, ns = ...
local UI = ns.UI
local Tuning = {}
UI.Tuning = Tuning

local ROW_HEIGHT = 34
local VISIBLE_ROWS = 7
local GUTTER = 4
local GUTTER_SPAN = 10

local panel, pool, empty, offset, rowWidth = nil, {}, nil, 0, 500
local track, thumb

local VERDICT_INK = { match = "accent", veto = "bad", below = "gold" }

local function createRow(slot)
    local row = CreateFrame("Frame", nil, panel)
    row:SetSize(rowWidth, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -(slot - 1) * ROW_HEIGHT - 4)

    row.head = UI.Text(row, "GameFontNormalSmall")
    row.head:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
    row.head:SetWordWrap(false)

    row.score = UI.Text(row, "GameFontNormalSmall")
    row.score:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -2)
    row.score:SetWordWrap(false)

    row.text = UI.Text(row, "GameFontNormalSmall")
    row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -17)
    row.text:SetWidth(rowWidth - 64)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    row.up = UI.Button(row, "", 24, function()
        if row.entry then
            ns.Log.Vote(row.entry, "up")
            Tuning.Render()
        end
    end)
    row.up:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -30, 2)
    row.down = UI.Button(row, "", 24, function()
        if row.entry then
            ns.Log.Vote(row.entry, "down")
            Tuning.Render()
        end
    end)
    row.down:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 2)

    row:Hide()
    return row
end

local function paintVotes(row, vote)
    row.up:SetText(vote == "up" and "|cff66ff66+|r" or "|cff666666+|r")
    row.down:SetText(vote == "down" and "|cffff6666-|r" or "|cff666666-|r")
end

local function entriesNewestFirst()
    local source = ns.Log.Entries()
    local out = {}
    for index = #source, 1, -1 do out[#out + 1] = source[index] end
    return out
end

function Tuning.Render()
    if not panel then return end
    local entries = entriesNewestFirst()
    local total = #entries

    if total == 0 then
        for _, row in ipairs(pool) do row:Hide() end
        track:Hide()
        thumb:Hide()
        empty:SetText(ns.L.TUNING_EMPTY)
        empty:Show()
        return
    end
    empty:Hide()

    local maxOffset = math.max(0, total - VISIBLE_ROWS)
    if offset > maxOffset then offset = maxOffset end
    if offset < 0 then offset = 0 end

    for slot = 1, VISIBLE_ROWS do
        local row = pool[slot]
        local entry = entries[slot + offset]
        if not entry then
            row.entry = nil
            row:Hide()
        else
            local verdict = ns.Log.Verdict(entry)
            row.head:SetText(string.format("%s  \226\128\162  %s",
                entry.name or "?", entry.channel or "?"))
            UI.Ink(row.head, UI.C.muted)
            row.score:SetText(string.format("%s %d", ns.L["VERDICT_" .. verdict:upper()],
                entry.score or 0))
            UI.Ink(row.score, UI.C[VERDICT_INK[verdict]] or UI.C.text)
            row.text:SetText(entry.text or "")
            UI.Ink(row.text, UI.C.text)
            row.entry = entry
            paintVotes(row, entry.vote)
            row:Show()
        end
    end

    if total > VISIBLE_ROWS then
        track:Show()
        local span = select(2, panel:GetSize()) - 6
        local height = math.max(12, span * VISIBLE_ROWS / total)
        thumb:SetHeight(height)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3,
            -3 - (span - height) * (maxOffset > 0 and offset / maxOffset or 0))
        thumb:Show()
    else
        track:Hide()
        thumb:Hide()
    end
end

function Tuning.Attach(parent, metrics)
    rowWidth = metrics.listWidth - GUTTER_SPAN - 2

    local weight = UI.Slider(parent, ns.L.SETTING_WEIGHT, 1, 12, 1,
        function() return ns.Storage.Threshold() end,
        function(value)
            ns.Storage.account.threshold = math.floor(value + 0.5)
            UI.Refresh()
        end,
        function(value) return tostring(math.floor(value + 0.5)) end)
    weight:SetPoint("TOPLEFT", parent, "TOPLEFT", metrics.pad, metrics.optionsTop)
    weight:SetWidth(metrics.listWidth - 110)
    Tuning.weight = weight

    local clear = UI.Button(parent, ns.L.ACTION_CLEAR_LOG, 96, function()
        ns.Log.Clear()
        offset = 0
        UI.Refresh()
    end)
    clear:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -metrics.pad, metrics.optionsTop - 1)

    local level = UI.Slider(parent, ns.L.SETTING_LOG_LEVEL, 0, 12, 1,
        function() return ns.Storage.LogLevel() end,
        function(value)
            ns.Storage.account.logLevel = math.floor(value + 0.5)
            UI.Refresh()
        end,
        function(value) return tostring(math.floor(value + 0.5)) end)
    level:SetPoint("TOPLEFT", parent, "TOPLEFT", metrics.pad, metrics.optionsTop - 26)
    level:SetWidth(metrics.listWidth - 110)
    Tuning.level = level

    panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", metrics.pad, metrics.optionsTop - 58)
    panel:SetSize(metrics.listWidth, VISIBLE_ROWS * ROW_HEIGHT + 8)
    UI.Fill(panel, UI.C.content, 0.45)
    UI.Edge(panel, UI.C.borderDim)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        offset = offset - delta
        Tuning.Render()
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
    empty:SetPoint("CENTER", panel, "CENTER", 0, 0)
    empty:SetWidth(metrics.listWidth - 60)
    empty:SetJustifyH("CENTER")
    empty:Hide()
end
