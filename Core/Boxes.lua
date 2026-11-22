local addonName, ns = ...
local Boxes = ns.Boxes

local KNOWN = {
    { id = 16882, name = "Battered Junkbox", skill = 1, kind = "junkbox",
      terms = { "battered junkbox", "battered" } },
    { id = 16883, name = "Worn Junkbox", skill = 70, kind = "junkbox",
      terms = { "worn junkbox", "worn" } },
    { id = 16884, name = "Sturdy Junkbox", skill = 175, kind = "junkbox",
      terms = { "sturdy junkbox", "sturdy" } },
    { id = 16885, name = "Heavy Junkbox", skill = 250, kind = "junkbox",
      terms = { "heavy junkbox" } },
    { id = 4632, name = "Ornate Bronze Lockbox", skill = 1, kind = "lockbox",
      terms = { "ornate bronze lockbox", "ornate bronze", "ornate" } },
    { id = 4633, name = "Heavy Bronze Lockbox", skill = 25, kind = "lockbox",
      terms = { "heavy bronze lockbox", "heavy bronze" } },
    { id = 4634, name = "Iron Lockbox", skill = 70, kind = "lockbox",
      terms = { "iron lockbox" } },
    { id = 4636, name = "Strong Iron Lockbox", skill = 125, kind = "lockbox",
      terms = { "strong iron lockbox", "strong iron" } },
    { id = 4637, name = "Steel Lockbox", skill = 175, kind = "lockbox",
      terms = { "steel lockbox" } },
    { id = 4638, name = "Reinforced Steel Lockbox", skill = 225, kind = "lockbox",
      terms = { "reinforced steel lockbox", "reinforced steel" } },
    { id = 5758, name = "Mithril Lockbox", skill = 225, kind = "lockbox",
      terms = { "mithril lockbox", "mithril" } },
    { id = 5759, name = "Thorium Lockbox", skill = 225, kind = "lockbox",
      terms = { "thorium lockbox", "thorium" } },
    { id = 5760, name = "Eternium Lockbox", skill = 225, kind = "lockbox",
      terms = { "eternium lockbox", "eternium" } },
    { id = 13875, name = "Ironbound Locked Chest", skill = 175, kind = "chest",
      terms = { "ironbound locked chest", "ironbound chest", "ironbound" } },
    { id = 13918, name = "Reinforced Locked Chest", skill = 250, kind = "chest",
      terms = { "reinforced locked chest" } },
}

local GENERIC = {
    { name = "Junkbox", kind = "junkbox", terms = { "junkbox", "junk box", "jb" } },
    { name = "Lockbox", kind = "lockbox", terms = { "lockbox", "lock box", "strongbox", "strong box" } },
    { name = "Locked chest", kind = "chest", terms = { "locked chest" } },
    { name = "Unnamed box", kind = "box", terms = { "box", "chest" } },
}

Boxes.ById = {}
Boxes.All = {}

local terms = {}

local function register(box, generic)
    box.generic = generic or nil
    Boxes.All[#Boxes.All + 1] = box
    if box.id then Boxes.ById[box.id] = box end
    for _, term in ipairs(box.terms) do
        local clean = ns.NormaliseTerm(term)
        if clean then terms[#terms + 1] = { term = clean, box = box } end
    end
end

for _, box in ipairs(KNOWN) do register(box) end
for _, box in ipairs(GENERIC) do register(box, true) end

table.sort(terms, function(a, b)
    if #a.term ~= #b.term then return #a.term > #b.term end
    return a.term < b.term
end)

function Boxes.Terms()
    return terms
end

function Boxes.Find(itemID)
    return Boxes.ById[itemID]
end

function Boxes.Label(box, quantity)
    if not box then return nil end
    if quantity and quantity > 1 then
        return string.format("%s x%d", box.name, quantity)
    end
    return box.name
end
