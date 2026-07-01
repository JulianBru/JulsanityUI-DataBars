--------------------------------------------------------------------------------
--  DataTexts/Registry.lua  -  Index of registered DataTexts
--
--  Maintains a sorted, categorised view over the catalog for the config UI
--  (dropdowns) and for validation. Built incrementally as DT_*.lua files call
--  Engine.Register. Results are cached and invalidated only when a new spec is
--  added, so the config dropdown build is cheap.
--------------------------------------------------------------------------------
local _, ns = ...
local Registry = ns.Registry

local specs       = {}    -- array of spec tables in registration order
local nameCache   = nil   -- cached sorted array of { name, label, category }
local optionCache = nil   -- cached { values = {name->label}, order = {names} }

--- Add a spec to the index (called by the engine on registration).
function Registry:Add(spec)
    specs[#specs + 1] = spec
    nameCache, optionCache = nil, nil   -- invalidate caches
end

--- Number of registered datatexts.
function Registry:Count()
    return #specs
end

--- True if a datatext with this name is registered.
function Registry:Has(name)
    return ns.DataTexts[name] ~= nil
end

--- Sorted list (by category, then label) of { name, label, category }.
function Registry:List()
    if nameCache then return nameCache end
    local list = {}
    for i = 1, #specs do
        local s = specs[i]
        list[#list + 1] = { name = s.name, label = s.label, category = s.category }
    end
    table.sort(list, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        return a.label < b.label
    end)
    nameCache = list
    return list
end

--- Dropdown-friendly data for the slot assignment control.
--- Returns:  values = { [name] = "Category: Label" },  order = { name, ... }
--- The first entry is always "None" so a slot can be cleared.
function Registry:GetDropdownData()
    if optionCache then return optionCache.values, optionCache.order end
    local values = { None = NONE or "None" }
    local order  = { "None" }
    for _, e in ipairs(self:List()) do
        values[e.name] = e.category .. ": " .. e.label
        order[#order + 1] = e.name
    end
    optionCache = { values = values, order = order }
    return values, order
end

--- All registered category names, sorted and unique.
function Registry:Categories()
    local seen, cats = {}, {}
    for _, e in ipairs(self:List()) do
        if not seen[e.category] then
            seen[e.category] = true
            cats[#cats + 1] = e.category
        end
    end
    return cats
end
