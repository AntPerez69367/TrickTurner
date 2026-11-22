local addonName, ns = ...
local Button = ns.Minimap

local ICON = "Interface\\AddOns\\TrickTurner\\Media\\icon.tga"

local broker

local function onClick(_, button)
    if button == "RightButton" then
        ns.Monitor.SetRunning(not ns.Storage.account.running)
        Button.Sync()
    else
        ns.UI.Toggle()
    end
end

local function onTooltipShow(tip)
    tip:AddLine("Trick Turner")
    local running = ns.Storage.account.running
    tip:AddLine(running
        and string.format(ns.L.STATUS_RUNNING, ns.Monitor.ActiveChannels())
        or ns.L.STATUS_STOPPED, 1, 1, 1)
    tip:AddLine(string.format(ns.L.STATUS_JOBS, ns.Queue.Count()), 1, 1, 1)
    local rank, maximum, known = ns.Skill.Get()
    if known then
        tip:AddLine(string.format("Lockpicking %d/%d", rank, maximum), 0.7, 0.7, 0.7)
    end
    tip:AddLine(" ")
    tip:AddLine(ns.L.MINIMAP_LEFT_CLICK, 0.6, 0.6, 0.6)
    tip:AddLine(ns.L.MINIMAP_RIGHT_CLICK, 0.6, 0.6, 0.6)
end

function Button.Sync()
    if not broker then return end
    broker.iconR, broker.iconG, broker.iconB = 1, 1, 1
    if not ns.Storage.account.running then
        broker.iconR, broker.iconG, broker.iconB = 0.45, 0.45, 0.45
    end
end

function Button.Initialise()
    broker = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "launcher",
        icon = ICON,
        OnClick = onClick,
        OnTooltipShow = onTooltipShow,
    })
    LibStub("LibDBIcon-1.0"):Register(addonName, broker, ns.Storage.account.minimap)
    Button.Sync()
end

function Button.SetShown(shown)
    local icon = LibStub("LibDBIcon-1.0")
    if shown then icon:Show(addonName) else icon:Hide(addonName) end
end
