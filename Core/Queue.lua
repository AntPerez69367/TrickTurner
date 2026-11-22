local addonName, ns = ...
local Queue = ns.Queue

local MAX_JOBS = 50
local STALE_SECONDS = 30 * 60
local ALERT_THROTTLE = 60
local MESSAGE_LIMIT = 255

local ORDER = { new = 1, contacted = 2, invited = 3, grouped = 4 }

local jobs = {}
local ignored = {}
local alerted = {}

Queue.completed = 0
Queue.scrubbed = 0

local function displayCopy(message)
    local escaped = message:gsub("|", "||")
    if #escaped > MESSAGE_LIMIT then
        escaped = escaped:sub(1, MESSAGE_LIMIT)
    end
    return escaped
end

Queue.DisplayCopy = displayCopy

local function count()
    local total = 0
    for _ in pairs(jobs) do total = total + 1 end
    return total
end

local function evict()
    local victimKey, victimRank, victimAge
    for key, job in pairs(jobs) do
        local rank = ORDER[job.state] or 1
        if not victimKey or rank < victimRank
            or (rank == victimRank and job.updated < victimAge) then
            victimKey, victimRank, victimAge = key, rank, job.updated
        end
    end
    if victimKey then jobs[victimKey] = nil end
end

local function prune()
    local cutoff = time() - STALE_SECONDS
    for key, job in pairs(jobs) do
        if job.updated < cutoff then jobs[key] = nil end
    end
    while count() > MAX_JOBS do evict() end
end

function Queue.Ignore(name)
    local key = ns.NameKey(name)
    if not key then return false end
    ignored[key] = true
    jobs[key] = nil
    return true
end

function Queue.IsIgnored(name)
    local key = ns.NameKey(name)
    return key ~= nil and ignored[key] == true
end

function Queue.Add(name, message, channel, channelName, result)
    local key = ns.NameKey(name)
    if not key or ignored[key] then return nil, false end

    local now = time()
    local existing = jobs[key]
    local job = existing or { key = key, state = "new", seen = now }

    job.name = name
    job.message = displayCopy(message)
    job.channel = channel
    job.channelName = channelName
    job.box = result.box
    job.quantity = result.quantity
    job.score = result.score
    job.explain = ns.Parser.Explain(result)
    job.updated = now

    jobs[key] = job
    if not existing then prune() end

    local fresh = existing == nil
    local chime = false
    if job.state == "new" and (not alerted[key] or now - alerted[key] >= ALERT_THROTTLE) then
        alerted[key] = now
        chime = true
    end
    return job, fresh, chime
end

function Queue.Get(name)
    local key = ns.NameKey(name)
    return key and jobs[key] or nil
end

function Queue.SetState(name, state)
    local job = Queue.Get(name)
    if not job or not ORDER[state] then return false end
    job.state = state
    job.updated = time()
    return true
end

function Queue.Complete(name)
    local key = ns.NameKey(name)
    if not key or not jobs[key] then return false end
    jobs[key] = nil
    Queue.completed = Queue.completed + 1
    return true
end

function Queue.Drop(name)
    local key = ns.NameKey(name)
    if not key or not jobs[key] then return false end
    jobs[key] = nil
    return true
end

function Queue.List()
    prune()
    local list = {}
    for _, job in pairs(jobs) do list[#list + 1] = job end
    table.sort(list, function(a, b)
        if a.updated ~= b.updated then return a.updated > b.updated end
        return a.key < b.key
    end)
    return list
end

function Queue.Count()
    return count()
end

function Queue.Clear()
    jobs = {}
    alerted = {}
end

function Queue.ClearSession()
    Queue.Clear()
    ignored = {}
    Queue.completed = 0
    Queue.scrubbed = 0
end
