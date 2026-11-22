local addonName, ns = ...

local columns = { enUS = 1 }
local aliases = { enGB = "enUS" }

local catalog = {
    TAB_BOARD = { "Board" },
    TAB_OPTIONS = { "Options" },

    STATE_NEW = { "New" },
    STATE_CONTACTED = { "Contacted" },
    STATE_INVITED = { "Invited" },
    STATE_GROUPED = { "Grouped" },

    CHANNEL_TRADE = { "Trade" },
    CHANNEL_GENERAL = { "General" },
    CHANNEL_LFG = { "LFG" },
    CHANNEL_OTHER = { "Chan" },
    CHANNEL_SAY = { "Say" },
    CHANNEL_YELL = { "Yell" },
    CHANNEL_WHISPER = { "Whisper" },

    ACTION_INVITE = { "Invite" },
    ACTION_WHISPER = { "Whisper" },
    ACTION_DONE = { "Done" },
    ACTION_IGNORE = { "Ignore" },

    SKILL_UNKNOWN = { "\226\128\148" },
    SKILL_REQUIRED = { "Needs %d" },
    SKILL_TOO_LOW = { "Needs %d, you have %d" },

    EMPTY_QUIET = { "Watching chat. Nothing yet." },
    EMPTY_STOPPED = { "Monitoring is off." },
    EMPTY_NO_CHANNELS = { "No channels are enabled. Turn one on in Options." },
    EMPTY_HIDDEN = { "%d requests are hidden because they are above your skill." },
    EMPTY_ENABLE = { "Start monitoring" },

    STATUS_RUNNING = { "Watching %d channels" },
    STATUS_STOPPED = { "Stopped" },
    STATUS_SCRUBBED = { "%d messages unreadable" },
    STATUS_JOBS = { "%d on the board" },

    REFUSE_COMBAT = { "Not while in combat." },
    REFUSE_GROUPED = { "%s is already in your group." },
    REFUSE_NOT_LEADER = { "You are not the group leader." },
    REFUSE_GROUP_FULL = { "Your group cannot take anyone else." },
    REFUSE_RESTRICTED = { "The client is blocking outgoing messages right now." },
    REFUSE_NO_TARGET = { "No customer selected." },
    REFUSE_NO_API = { "This client does not expose that action." },

    ALERT_NEW = { "Lockpicking wanted: %s" },
    ANNOUNCE_MATCH = { "%s (%s) \226\128\148 %s" },

    SECTION_MONITORING = { "Monitoring" },
    SECTION_MATCHING = { "Matching" },
    SECTION_ALERTS = { "Alerts" },
    SECTION_GREETING = { "Greeting" },
    SECTION_WINDOW = { "Window" },

    SETTING_RUNNING = { "Watch chat for lockpicking requests" },
    SETTING_TRADE = { "Trade" },
    SETTING_GENERAL = { "General" },
    SETTING_LFG = { "LookingForGroup" },
    SETTING_OTHER = { "Other channels" },
    SETTING_OTHER_HELP = { "Custom and server channels. On this client the trade traffic may not be on Blizzard's Trade channel." },
    SETTING_SAY = { "Say" },
    SETTING_YELL = { "Yell" },
    SETTING_WHISPER = { "Whispers" },
    SETTING_SENSITIVITY = { "Sensitivity" },
    SETTING_SENSITIVITY_HELP = { "How much evidence a message needs before it reaches the board." },
    SENSITIVITY_LOOSE = { "Loose" },
    SENSITIVITY_NORMAL = { "Normal" },
    SENSITIVITY_STRICT = { "Strict" },
    SETTING_HIDE_ABOVE_SKILL = { "Hide boxes above my skill" },
    SETTING_HIDE_HELP = { "Only hides a card when the box and your skill are both known." },
    SETTING_SOUND = { "Play a sound for a new request" },
    SETTING_ALERT_CHAT = { "Print new requests to chat" },
    SETTING_ANNOUNCE = { "Show messages in" },
    ANNOUNCE_CHAT = { "Chat" },
    ANNOUNCE_ERROR = { "Top of screen" },
    ANNOUNCE_NONE = { "Off" },
    SETTING_GREETING = { "Whisper draft" },
    SETTING_GREETING_HELP = { "Typed into the chat box for you. It is never sent. %NAME%, %BOX% and %SKILL% are replaced." },
    SETTING_SCALE = { "Window scale" },
    SETTING_MINIMAP = { "Show a minimap button" },

    MINIMAP_LEFT_CLICK = { "Left-click to open the board" },
    MINIMAP_RIGHT_CLICK = { "Right-click to start or stop watching" },

    OPEN_WINDOW = { "Open the board" },
    CLEAR_BOARD = { "Clear the board" },
    CLEAR_BOARD_CONFIRM = { "Clear every job from the board?" },
}

function ns.LoadLocale()
    local locale = GetLocale and GetLocale() or "enUS"
    locale = aliases[locale] or locale
    local column = columns[locale] or columns.enUS
    for key, row in pairs(catalog) do
        ns.L[key] = row[column] or row[columns.enUS]
    end
end
