-- Labelled chat lines. Each entry gives the expected verdict at every shipped
-- sensitivity, so a change that only moves one threshold cannot pass unnoticed.
--   message, loose (2), normal (3), strict (4), box name or false, quantity or false
local LINK = "|cffffffff|Hitem:16882:0:0:0:0:0:0:0|h[Battered Junkbox]|h|r"
local STURDY = "|cffffffff|Hitem:16884:0:0:0:0:0:0:0|h[Sturdy Junkbox]|h|r"

return {
    -- Customers, stated plainly enough to clear every threshold.
    { "anyone have a lockpick? need a junkbox opened, will tip", true, true, true, "Junkbox" },
    { "LF rogue to open lockbox, tips available", true, true, true, "Lockbox" },
    { "need lockpicking, anybody about?", true, true, true, false },
    { "rogue needed for lockbox pls", true, true, true, "Lockbox" },
    { "got 5 junkboxes, who can open?", true, true, true, "Junkbox", 5 },
    { "can a rogue unlock this for me", true, true, true, false },
    { "need a rouge to open my box", true, true, true, "Unnamed box" },
    { "lockpick plz", true, true, true, false },
    { "paying 10g for lockbox opening", true, true, true, "Lockbox" },
    { "any rogues around? got 3 junkboxes", true, true, true, "Junkbox", 3 },
    { "can someone open this? " .. STURDY, true, true, true, "Sturdy Junkbox" },
    { "anyone offer lockpicking service?", true, true, true, false },
    { "need my thorium lockbox opened, will tip 5g", true, true, true, "Thorium Lockbox" },

    -- Customers the weight-based design used to discard. Regression guards.
    { "LF rogue to open lockbox, tips appreciated", true, true, true, "Lockbox" },
    { "need a junkbox opened, tips welcome", true, true, true, "Junkbox" },
    { "need someone to open my junkbox, my lockpicking is too low", true, true, true, "Junkbox" },
    { "im a rogue but low lockpicking, need my junkbox opened", true, true, true, "Junkbox" },

    -- Terse requests. These are what the sensitivity control is for: common in
    -- Trade, and the only lines whose verdict moves between settings.
    { "lockbox", true, true, false, "Lockbox" },
    { "junkbox", true, true, false, "Junkbox" },
    { "rogue pls", true, true, false, false },
    { "got a lockbox", true, true, false, "Lockbox" },
    { "pst rogue", true, true, false, false },
    { "rogue, will pay", true, false, false, false },
    { "rogue tips", true, false, false, false },

    -- Loose admits this, which is the cost of Loose rather than a defect.
    { "anyone around?", true, false, false, false },

    -- Competing locksmiths. None of these may reach the board at any setting.
    { "Lockpicking available! Let me open your Junkboxes - tips appreciated!", false, false, false },
    { "im a rogue, i can open your lockboxes, pst me for lockpicking", false, false, false },
    { "Junkboxes opened! 5g each, pst", false, false, false },
    { "Lockpicking available, let me open your " .. LINK .. " - tips appreciated", false, false, false },
    { "opening junkboxes, 2g per box, whisper for an invite", false, false, false },

    -- Known gap. Its only seller markers are phrases customers also write, so
    -- no term list separates it. Asserted as-is so the set cannot grow silently.
    { "{skull} Master Locksmith - All boxes - Fast service - Tips welcome! {skull}", true, true, true },

    -- Traffic that must never match.
    { "WTS Thorium Lockbox", false, false, false },
    { "LFG SM, need rogue", false, false, false },
    { "LFM UBRS need tank and heals", false, false, false },
    { "WTB enchant weapon crusader, paying well", false, false, false },
    { "anyone selling junkboxes?", false, false, false },
    { "LF warlock for summon to BRD", false, false, false },
    { "guild recruiting, pst for invite", false, false, false },
    { "need 2 dps for wsg premade", false, false, false },

    -- Known gap. A dungeon name costs 7, more than box and intent together.
    { "need my junkbox opened, im outside SM", false, false, false, "Junkbox" },
}
