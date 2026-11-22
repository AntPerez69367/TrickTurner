local addonName, ns = ...
local UI = ns.UI

local EDGES = {
    { "TOPLEFT", "TOPRIGHT", false },
    { "BOTTOMLEFT", "BOTTOMRIGHT", false },
    { "TOPLEFT", "BOTTOMLEFT", true },
    { "TOPRIGHT", "BOTTOMRIGHT", true },
}

UI.C = {
    accent = { 0.38, 0.68, 1.00 },
    frame = { 0.064, 0.070, 0.084 },
    header = { 0.040, 0.045, 0.056 },
    content = { 0.110, 0.119, 0.140 },
    field = { 0.048, 0.054, 0.068 },
    fieldHover = { 0.076, 0.086, 0.106 },
    button = { 0.148, 0.162, 0.192 },
    buttonHover = { 0.202, 0.222, 0.262 },
    border = { 0.230, 0.248, 0.286 },
    borderDim = { 0.158, 0.170, 0.198 },
    gold = { 1.00, 0.82, 0.32 },
    white = { 1, 1, 1 },
    text = { 0.86, 0.89, 0.94 },
    muted = { 0.63, 0.67, 0.74 },
    dim = { 0.44, 0.47, 0.54 },
    bad = { 0.95, 0.40, 0.40 },
}

function UI.Text(parent, template)
    return parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
end

function UI.Ink(fontString, color, alpha)
    fontString:SetTextColor(color[1], color[2], color[3], alpha or 1)
end

function UI.Fill(frame, color, alpha)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(frame)
    texture:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    return texture
end

function UI.Edge(frame, color, alpha)
    local textures = {}
    for index, spec in ipairs(EDGES) do
        local texture = frame:CreateTexture(nil, "BORDER")
        texture:SetPoint(spec[1])
        texture:SetPoint(spec[2])
        if spec[3] then texture:SetWidth(1) else texture:SetHeight(1) end
        textures[index] = texture
    end
    local edge = { textures = textures }
    edge.Set = function(newColor, newAlpha)
        for _, texture in ipairs(textures) do
            texture:SetColorTexture(newColor[1], newColor[2], newColor[3], newAlpha or 1)
        end
    end
    edge.Set(color, alpha)
    return edge
end

function UI.Rule(frame, side, color, alpha, inset)
    local texture = frame:CreateTexture(nil, "BORDER")
    inset = inset or 0
    texture:SetPoint(side .. "LEFT", inset, 0)
    texture:SetPoint(side .. "RIGHT", -inset, 0)
    texture:SetHeight(1)
    texture:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    return texture
end

function UI.Button(parent, label, width, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 22)
    local surface = UI.Fill(button, UI.C.button)
    local edge = UI.Edge(button, UI.C.border)
    button.label = UI.Text(button, "GameFontNormalSmall")
    button.label:SetPoint("CENTER")
    button.label:SetWordWrap(false)
    button.label:SetText(label)
    button.enabled = true
    button.Apply = function()
        if not button.enabled then
            surface:SetColorTexture(UI.C.button[1], UI.C.button[2], UI.C.button[3], 0.40)
            edge.Set(UI.C.borderDim, 0.45)
            UI.Ink(button.label, UI.C.muted, 0.40)
            return
        end
        local tint = button.hover and UI.C.buttonHover or UI.C.button
        surface:SetColorTexture(tint[1], tint[2], tint[3], 1)
        edge.Set(button.hover and UI.C.accent or UI.C.border, 1)
        UI.Ink(button.label, button.hover and UI.C.white or UI.C.text)
    end
    button.SetText = function(self, value)
        self.label:SetText(value)
    end
    button.SetEnabled = function(self, value)
        self.enabled = value and true or false
        if self.enabled then self:Enable() else self:Disable() end
        self.Apply()
    end
    button:SetScript("OnEnter", function(self) self.hover = true; self.Apply() end)
    button:SetScript("OnLeave", function(self) self.hover = false; self.Apply() end)
    button:SetScript("OnClick", onClick)
    button.Apply()
    return button
end

function UI.Search(parent, width, placeholder, onChange)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(width, 22)
    box:EnableMouse(true)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetTextInsets(8, 20, 2, 2)
    box:SetMaxLetters(48)
    local surface = UI.Fill(box, UI.C.field)
    local edge = UI.Edge(box, UI.C.borderDim)

    local hint = UI.Text(box, "GameFontNormalSmall")
    hint:SetPoint("LEFT", box, "LEFT", 8, 0)
    hint:SetPoint("RIGHT", box, "RIGHT", -22, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(false)
    hint:SetText(placeholder)
    UI.Ink(hint, UI.C.dim)

    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(16, 16)
    clear:SetPoint("RIGHT", box, "RIGHT", -3, 0)
    clear.label = UI.Text(clear, "GameFontNormalSmall")
    clear.label:SetPoint("CENTER")
    clear.label:SetText("x")
    UI.Ink(clear.label, UI.C.muted)
    clear:SetScript("OnEnter", function(self) UI.Ink(self.label, UI.C.white) end)
    clear:SetScript("OnLeave", function(self) UI.Ink(self.label, UI.C.muted) end)

    box.Apply = function()
        local typed = box:GetText() ~= ""
        hint:SetShown(not typed)
        clear:SetShown(typed)
        if box.focused then
            surface:SetColorTexture(UI.C.fieldHover[1], UI.C.fieldHover[2], UI.C.fieldHover[3], 1)
            edge.Set(UI.C.accent)
        else
            surface:SetColorTexture(UI.C.field[1], UI.C.field[2], UI.C.field[3], 1)
            edge.Set(UI.C.borderDim)
        end
    end
    clear:SetScript("OnClick", function()
        box:SetText("")
        box:ClearFocus()
        onChange()
    end)
    box:SetScript("OnEditFocusGained", function(self) self.focused = true; self.Apply() end)
    box:SetScript("OnEditFocusLost", function(self) self.focused = false; self.Apply() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        onChange()
    end)
    box:SetScript("OnTextChanged", function(self, userInput)
        self.Apply()
        if userInput then onChange() end
    end)
    box.Apply()
    return box
end

function UI.Segmented(parent, choices, segmentWidth, getter, setter, tooltip)
    local group = CreateFrame("Frame", nil, parent)
    group:SetHeight(20)
    UI.Fill(group, UI.C.field)
    UI.Edge(group, UI.C.borderDim)
    local segments = {}
    local function paint()
        for _, segment in ipairs(segments) do
            local on = getter() == segment.value
            segment.wash:SetShown(on)
            if on then
                UI.Ink(segment.label, UI.C.white)
            else
                UI.Ink(segment.label, segment.hover and UI.C.text or UI.C.dim)
            end
        end
    end
    local x = 0
    for index, choice in ipairs(choices) do
        local segment = CreateFrame("Button", nil, group)
        segment.value = choice.value
        segment.label = UI.Text(segment, "GameFontNormalSmall")
        segment.label:SetText(choice.label)
        segment.label:SetWordWrap(false)
        local width = segmentWidth or math.ceil(segment.label:GetStringWidth() + 18)
        segment:SetSize(width, 18)
        segment:SetPoint("TOPLEFT", group, "TOPLEFT", x, -1)
        segment.label:SetPoint("CENTER")
        x = x + width
        segment.wash = segment:CreateTexture(nil, "ARTWORK")
        segment.wash:SetAllPoints(segment)
        segment.wash:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.30)
        segment:SetScript("OnClick", function(self)
            setter(self.value)
            paint()
        end)
        segment:SetScript("OnEnter", function(self)
            self.hover = true
            paint()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end)
        segment:SetScript("OnLeave", function(self)
            self.hover = false
            paint()
            if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        end)
        segments[index] = segment
    end
    group:SetWidth(x)
    paint()
    return group
end

function UI.Tab(parent, height, onClick)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetHeight(height)
    tab.label = UI.Text(tab, "GameFontNormalSmall")
    tab.label:SetPoint("CENTER", tab, "CENTER", 0, 1)
    tab.label:SetWordWrap(false)
    tab.underline = tab:CreateTexture(nil, "ARTWORK")
    tab.underline:SetHeight(2)
    tab.underline:SetPoint("BOTTOMLEFT")
    tab.underline:SetPoint("BOTTOMRIGHT")
    tab.underline:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 1)
    tab.Apply = function()
        tab.underline:SetShown(tab.active and true or false)
        if tab.active then
            UI.Ink(tab.label, UI.C.white)
        else
            UI.Ink(tab.label, tab.hover and UI.C.text or UI.C.dim)
        end
    end
    tab.SetLabel = function(text, active)
        tab.active = active
        tab.label:SetText(text)
        tab:SetWidth(math.ceil(tab.label:GetStringWidth() + 26))
        tab.Apply()
    end
    tab:SetScript("OnEnter", function(self) self.hover = true; self.Apply() end)
    tab:SetScript("OnLeave", function(self) self.hover = false; self.Apply() end)
    tab:SetScript("OnClick", onClick)
    return tab
end

function UI.Section(parent, title, onToggle)
    local header = CreateFrame("Button", nil, parent)
    header:SetHeight(22)
    local wash = header:CreateTexture(nil, "BACKGROUND")
    wash:SetAllPoints(header)
    local bar = header:CreateTexture(nil, "ARTWORK")
    bar:SetSize(9, 1)
    bar:SetPoint("LEFT", header, "LEFT", 4, 0)
    local stem = header:CreateTexture(nil, "ARTWORK")
    stem:SetSize(1, 9)
    stem:SetPoint("CENTER", bar, "CENTER", 0, 0)
    header.label = UI.Text(header, "GameFontNormal")
    header.label:SetPoint("LEFT", header, "LEFT", 21, 0)
    header.label:SetWordWrap(false)
    header.label:SetText(title)
    header.expanded = true
    UI.Rule(header, "BOTTOM", UI.C.borderDim)
    header.Apply = function()
        stem:SetShown(not header.expanded)
        local ink = header.hover and UI.C.white or UI.C.gold
        UI.Ink(header.label, ink)
        bar:SetColorTexture(ink[1], ink[2], ink[3], 1)
        stem:SetColorTexture(ink[1], ink[2], ink[3], 1)
        wash:SetColorTexture(UI.C.buttonHover[1], UI.C.buttonHover[2], UI.C.buttonHover[3],
            header.hover and 1 or 0)
    end
    header:SetScript("OnEnter", function(self) self.hover = true; self.Apply() end)
    header:SetScript("OnLeave", function(self) self.hover = false; self.Apply() end)
    header:SetScript("OnClick", function(self)
        self.expanded = not self.expanded
        self.Apply()
        onToggle()
    end)
    header.Apply()
    return header
end

function UI.Switch(parent, label, getter, setter)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(20)
    local track = row:CreateTexture(nil, "ARTWORK")
    track:SetSize(24, 11)
    track:SetPoint("LEFT", row, "LEFT", 0, 0)
    local knob = row:CreateTexture(nil, "OVERLAY")
    knob:SetSize(7, 7)
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 30, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.label:SetText(label)
    row.Apply = function()
        local on = getter() and true or false
        knob:ClearAllPoints()
        if on then
            track:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 0.85)
            knob:SetPoint("RIGHT", track, "RIGHT", -2, 0)
            knob:SetColorTexture(1, 1, 1, 1)
        else
            track:SetColorTexture(UI.C.field[1], UI.C.field[2], UI.C.field[3], 1)
            knob:SetPoint("LEFT", track, "LEFT", 2, 0)
            knob:SetColorTexture(UI.C.dim[1], UI.C.dim[2], UI.C.dim[3], 1)
        end
        UI.Ink(row.label, row.hover and UI.C.text or UI.C.muted)
    end
    row:SetScript("OnClick", function()
        setter(not getter())
        row.Apply()
    end)
    row:SetScript("OnEnter", function(self) self.hover = true; self.Apply() end)
    row:SetScript("OnLeave", function(self) self.hover = false; self.Apply() end)
    row.Apply()
    return row
end

function UI.Slider(parent, label, min, max, step, getter, setter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(20)
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetWordWrap(false)
    row.label:SetText(label)
    UI.Ink(row.label, UI.C.muted)
    row.value = UI.Text(row, "GameFontNormalSmall")
    row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.value:SetWidth(42)
    row.value:SetJustifyH("RIGHT")
    row.value:SetWordWrap(false)
    UI.Ink(row.value, UI.C.text)

    local slider = CreateFrame("Slider", nil, row)
    slider:SetHeight(10)
    slider:SetPoint("LEFT", row.label, "RIGHT", 12, 0)
    slider:SetPoint("RIGHT", row.value, "LEFT", -12, 0)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    UI.Fill(slider, UI.C.field)
    UI.Edge(slider, UI.C.borderDim)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 18)
    thumb:SetColorTexture(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3], 1)
    slider:SetThumbTexture(thumb)

    local percent = math.floor(step * 100 + 0.5)
    row.Apply = function(value)
        row.value:SetText(string.format("%d%%", math.floor(value * 100 + 0.5)))
    end
    local function quantise(raw)
        local steps = math.floor(raw * 100 / percent + 0.5)
        return steps * percent / 100
    end
    slider:SetScript("OnValueChanged", function(_, raw)
        row.Apply(quantise(raw))
    end)
    slider:SetScript("OnMouseUp", function(self)
        setter(quantise(self:GetValue()))
    end)
    slider:SetValue(getter())
    row.Apply(getter())
    return row
end

function UI.Field(parent, label, width, help, getter, setter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(help and 56 or 42)
    row.label = UI.Text(row, "GameFontNormalSmall")
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.label:SetText(label)
    row.label:SetWordWrap(false)
    UI.Ink(row.label, UI.C.muted)

    local box = CreateFrame("EditBox", nil, row)
    box:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -17)
    box:SetSize(width, 22)
    box:EnableMouse(true)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetTextInsets(8, 8, 2, 2)
    box:SetMaxLetters(240)
    local surface = UI.Fill(box, UI.C.field)
    local edge = UI.Edge(box, UI.C.borderDim)

    if help then
        row.help = UI.Text(row, "GameFontNormalSmall")
        row.help:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -3)
        row.help:SetWidth(width)
        row.help:SetJustifyH("LEFT")
        row.help:SetText(help)
        UI.Ink(row.help, UI.C.dim)
    end

    box.Apply = function()
        if box.focused then
            surface:SetColorTexture(UI.C.fieldHover[1], UI.C.fieldHover[2], UI.C.fieldHover[3], 1)
            edge.Set(UI.C.accent)
        else
            surface:SetColorTexture(UI.C.field[1], UI.C.field[2], UI.C.field[3], 1)
            edge.Set(UI.C.borderDim)
        end
    end
    box:SetScript("OnEditFocusGained", function(self) self.focused = true; self.Apply() end)
    box:SetScript("OnEditFocusLost", function(self)
        self.focused = false
        self.Apply()
        setter(self:GetText())
    end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(getter())
        self:ClearFocus()
    end)
    box:SetText(getter() or "")
    box.Apply()
    row.box = box
    return row
end

function UI.Chip(parent, height)
    local chip = CreateFrame("Frame", nil, parent)
    chip:SetHeight(height)
    local wash = UI.Fill(chip, UI.C.button)
    chip.label = UI.Text(chip, "GameFontNormalSmall")
    chip.label:SetPoint("CENTER")
    chip.label:SetWordWrap(false)
    chip.Set = function(text, colour)
        chip.label:SetText(text)
        UI.Ink(chip.label, colour or UI.C.muted)
        chip:SetWidth(math.ceil(chip.label:GetStringWidth() + 12))
        wash:SetColorTexture(UI.C.button[1], UI.C.button[2], UI.C.button[3], 0.9)
    end
    return chip
end
