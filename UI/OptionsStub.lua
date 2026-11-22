local addonName, ns = ...
local UI = ns.UI

function UI.RegisterOptions()
    local panel = CreateFrame("Frame")
    panel.name = "Trick Turner"

    local title = UI.Text(panel, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText("Trick Turner")

    local open = UI.Button(panel, ns.L.OPEN_WINDOW, 200, function() UI.Open("board") end)
    open:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        category.ID = addonName
        Settings.RegisterAddOnCategory(category)
        return
    end
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end
