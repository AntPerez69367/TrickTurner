-- Loads Boxes and Parser standalone and asserts the corpus at every
-- sensitivity. No WoW API is touched: the matching stage is pure by design.
local root = (arg and arg[0] or ""):match("^(.*)tests[/\\]parser%.lua$") or "./"

local ns = { Boxes = {}, Parser = {} }
assert(loadfile(root .. "Core/Boxes.lua"))("TrickTurner", ns)
assert(loadfile(root .. "Core/Parser.lua"))("TrickTurner", ns)

local corpus = assert(loadfile(root .. "tests/corpus.lua"))()
local LEVELS = { { "loose", 2, 2 }, { "normal", 3, 3 }, { "strict", 4, 4 } }

local failures, checks, separating = 0, 0, 0

local function fail(message, detail)
    failures = failures + 1
    io.write(string.format("FAIL  %s\n      %s\n", message, detail))
end

for index, entry in ipairs(corpus) do
    local message = entry[1]
    local result = ns.Parser.Scan(message)
    if not result then
        fail(message, "parser returned nil")
    else
        local verdicts = {}
        for slot, level in ipairs(LEVELS) do
            local name, threshold = level[1], level[2]
            local want = entry[1 + slot] and true or false
            local got = ns.Parser.Matches(result, threshold)
            verdicts[slot] = got
            checks = checks + 1
            if got ~= want then
                fail(message, string.format("%s (%d): wanted %s, got %s  [score %d%s]  %s",
                    name, threshold, tostring(want), tostring(got),
                    result.score, result.veto and ", vetoed" or "",
                    ns.Parser.Explain(result)))
            end
        end
        if not (verdicts[1] == verdicts[2] and verdicts[2] == verdicts[3]) then
            separating = separating + 1
        end

        local wantBox = entry[5]
        if wantBox ~= nil then
            checks = checks + 1
            local gotBox = result.box and result.box.name or false
            if wantBox == false then
                if gotBox ~= false then
                    fail(message, "expected no box, identified " .. tostring(gotBox))
                end
            elseif gotBox ~= wantBox then
                fail(message, string.format("box: wanted %s, got %s", wantBox, tostring(gotBox)))
            end
        end

        local wantQuantity = entry[6]
        if wantQuantity then
            checks = checks + 1
            if result.quantity ~= wantQuantity then
                fail(message, string.format("quantity: wanted %d, got %s",
                    wantQuantity, tostring(result.quantity)))
            end
        end
    end
end

if separating < 3 then
    fail("corpus coverage",
        string.format("only %d line(s) change verdict between Loose, Normal and Strict; "
            .. "at least 3 are required or the sensitivity control is untested", separating))
end

io.write(string.format("%d corpus lines, %d assertions, %d separating the thresholds\n",
    #corpus, checks, separating))
if failures > 0 then
    io.write(string.format("%d failure(s)\n", failures))
    os.exit(1)
end
io.write("ok\n")
