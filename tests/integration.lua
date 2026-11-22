-- Loads every addon file in TOC order against a stand-in client, then drives
-- the chat and roster events to assert the queue, skill and service behaviour
-- the corpus cannot reach.
local root = (arg and arg[0] or ""):match("^(.*)tests[/\\]integration%.lua$") or ""

local stub = assert(loadfile(root .. "tests/wowstub.lua"))()
stub.install(_G)

local ADDON = "TrickTurner"
local ns = {}
local FILES = {
    "Core/Namespace.lua", "Core/Storage.lua", "Locales.lua", "Core/Boxes.lua",
    "Core/Parser.lua", "Core/Skill.lua", "Core/Queue.lua", "Core/Service.lua",
    "Core/Monitor.lua", "Core/Minimap.lua", "UI/Widgets.lua", "UI/JobList.lua",
    "UI/Window.lua", "UI/OptionsStub.lua", "Core/Commands.lua",
}
for _, file in ipairs(FILES) do
    local chunk, err = loadfile(root .. file)
    assert(chunk, "load " .. file .. ": " .. tostring(err))
    local ok, runErr = pcall(chunk, ADDON, ns)
    assert(ok, "run " .. file .. ": " .. tostring(runErr))
end

local failures, checks = 0, 0
local function check(label, got, want)
    checks = checks + 1
    if got ~= want then
        failures = failures + 1
        io.write(string.format("FAIL  %s\n      wanted %s, got %s\n",
            label, tostring(want), tostring(got)))
    end
end

-- Boot the addon the way ADDON_LOADED does.
stub.playerName = "Tester"
stub.skill = 150
stub.fireAll("ADDON_LOADED", ADDON)

check("storage seeded", type(TrickTurnerDB), "table")
check("threshold default", ns.Storage.Threshold(), 3)
check("locale loaded", ns.L.TAB_BOARD, "Board")
check("skill read", select(1, ns.Skill.Get()), 150)
check("skill known", select(3, ns.Skill.Get()), true)
check("can open sturdy (175)", ns.Skill.CanOpen(175), false)
check("can open worn (70)", ns.Skill.CanOpen(70), true)
check("unknown requirement", ns.Skill.CanOpen(nil), nil)

-- A customer posts in Trade.
local function trade(sender, message)
    stub.fireAll("CHAT_MSG_CHANNEL", message, sender, nil, "2. Trade", nil, nil, 2, 2, "Trade")
end

trade("Fizzle Lockpick", "need my thorium lockbox opened, will tip 5g")
check("card raised", ns.Queue.Count(), 1)
local job = ns.Queue.Get("Fizzle Lockpick")
check("job found", job ~= nil, true)
check("job name kept whole", job and job.name, "Fizzle Lockpick")
check("box identified", job and job.box and job.box.name, "Thorium Lockbox")
check("state new", job and job.state, "new")
check("channel tagged", job and job.channel, "TRADE")

-- A repeat post updates the card rather than adding one.
trade("Fizzle Lockpick", "still need that lockbox opened")
check("repeat does not stack", ns.Queue.Count(), 1)

-- A competing locksmith must not reach the board.
trade("Rival Rogue", "Junkboxes opened! 5g each, pst")
check("impersonal ad rejected", ns.Queue.Count(), 1)

-- The player's own message must not raise a card.
trade("Tester", "need a junkbox opened")
check("self ignored", ns.Queue.Count(), 1)

-- Hostile markup must be neutralised on the way into the card.
trade("Sneak Thief", "need a |cffff0000|Hitem:99999|h[fake]|h|r junkbox opened")
local hostile = ns.Queue.Get("Sneak Thief")
check("markup escaped", hostile and hostile.message:find("||cffff0000", 1, true) ~= nil, true)

-- Whisper drafts without sending, and advances the card.
stub.editBox = stub.object("editbox")
local drafted = ns.Service.WhisperDraft(job)
check("draft returned ok", drafted, true)
check("whisper targeted whole name", stub.lastTell, "Fizzle Lockpick")
check("greeting typed not sent", stub.editBox.text:find("Fizzle Lockpick", 1, true) ~= nil, true)
check("state contacted", ns.Queue.Get("Fizzle Lockpick").state, "contacted")

-- Invite is refused in combat, with a reason rather than a silent false.
stub.inCombat = true
local ok, reason = ns.Service.Invite("Fizzle Lockpick")
check("combat refuses", ok, false)
check("combat states a reason", reason, ns.L.REFUSE_COMBAT)
stub.inCombat = false

ok = ns.Service.Invite("Fizzle Lockpick")
check("invite dispatched", ok, true)
check("invite used whole name", stub.lastInvite, "Fizzle Lockpick")
check("state invited", ns.Queue.Get("Fizzle Lockpick").state, "invited")

-- Joining the group advances the card without a click.
stub.group = { "Fizzle Lockpick" }
stub.fireAll("GROUP_ROSTER_UPDATE")
check("roster advances card", ns.Queue.Get("Fizzle Lockpick").state, "grouped")

-- A group member's message raises nothing.
local before = ns.Queue.Count()
trade("Fizzle Lockpick", "another junkbox please")
check("group member ignored", ns.Queue.Count(), before)
stub.group = nil

-- Ignoring removes the card and bars the customer for the session.
ns.Queue.Ignore("Sneak Thief")
check("ignore removed card", ns.Queue.Get("Sneak Thief"), nil)
trade("Sneak Thief", "need a junkbox opened")
check("ignored stays off", ns.Queue.Get("Sneak Thief"), nil)

-- Eviction drops untouched cards before worked ones.
ns.Queue.ClearSession()
for index = 1, 55 do
    trade("Filler" .. index, "need a junkbox opened")
end
check("cap enforced", ns.Queue.Count() <= 50, true)
ns.Queue.SetState("Filler55", "invited")
for index = 56, 70 do
    trade("Filler" .. index, "need a junkbox opened")
end
check("worked card survives flood", ns.Queue.Get("Filler55") ~= nil, true)

-- A channel hidden from every chat window is not read.
ns.Queue.ClearSession()
stub.shownChannels = { "General", 0 }
trade("Quiet One", "need a junkbox opened")
check("hidden channel ignored", ns.Queue.Count(), 0)
stub.shownChannels = nil

-- The dev command scores without touching the board.
ns.Queue.ClearSession()
SlashCmdList.TRICKTURNER("dev need my junkbox opened")
check("dev printed", #stub.printed > 0, true)
check("dev did not queue", ns.Queue.Count(), 0)

io.write(string.format("%d assertions\n", checks))
if failures > 0 then
    io.write(string.format("%d failure(s)\n", failures))
    os.exit(1)
end
io.write("ok\n")
