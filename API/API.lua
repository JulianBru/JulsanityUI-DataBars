--------------------------------------------------------------------------------
--  API/API.lua  -  Public internal API + event wiring
--
--  The documented surface other modules (and the config panel) call. Update
--  entry points iterate every bar instance, so a config change is reflected on
--  all bars (each reads its own config block). The wiring at the bottom connects
--  fine-grained config messages to the minimal update needed.
--
--  See docs/API.md for the full reference.
--------------------------------------------------------------------------------
local _, ns = ...
local API = ns.API
local Events = ns.Events
local MSG = ns.MSG

--------------------------------------------------------------------------------
--  Construction / registration
--------------------------------------------------------------------------------

--- Build all bar frames (idempotent). Returns the main bar frame.
function API.CreateBar()
    return ns.Bar:Build()
end

--- Acquire (creating if needed) the pooled slot at `index` on a bar
--- (defaults to the main bar).
function API.CreateSlot(index, barIndex)
    local bar = ns.Bars[barIndex or 1]
    if not bar then return nil end
    return ns.Slot.Acquire(bar, index)
end

--- Register a DataText specification (see DataTexts/Engine.lua).
function API.RegisterDataText(spec)
    return ns.Engine.Register(spec)
end

--------------------------------------------------------------------------------
--  Update entry points (granular; applied to every bar)
--------------------------------------------------------------------------------

function API.UpdateSlots()
    ns.Bar:ForEach(function(bar)
        ns.Bar.UpdateSlots(bar)
        ns.Bar.Layout(bar)
    end)
end

function API.UpdateLayout()
    ns.Bar:ForEach(function(bar) ns.Bar.Layout(bar) end)
end

function API.UpdateFonts()
    ns.Bar:ForEach(function(bar) ns.Renderer:UpdateFonts(bar) end)
end

function API.UpdateAppearance()
    ns.Bar:ForEach(function(bar) ns.Renderer:ApplyAppearance(bar) end)
end

function API.UpdateVisibility()
    ns.Visibility:ApplyAll()
end

function API.UpdateMover()
    ns.Bar:ForEach(function(bar)
        ns.Anchor:ApplyPosition(bar)
        ns.Anchor:NotifyResized(bar)
    end)
end

--- Full refresh of every bar (used on profile switches/imports).
function API.Refresh()
    ns.Bar:BuildAll()
    ns.Bar:ForEach(function(bar)
        ns.Bar.UpdateSlots(bar)
        ns.Renderer:UpdateAll(bar)
        ns.Bar.Layout(bar)
        ns.Anchor:ApplyPosition(bar)
        ns.Visibility:ApplyOne(bar)
    end)
end

ns.Refresh = API.Refresh

--------------------------------------------------------------------------------
--  Event wiring: message -> minimal update
--------------------------------------------------------------------------------
Events:Register(MSG.LAYOUT_CHANGED,     function() API.UpdateLayout() end)
Events:Register(MSG.APPEARANCE_CHANGED, function() API.UpdateAppearance() end)
Events:Register(MSG.FONT_CHANGED,       function() API.UpdateFonts() end)
Events:Register(MSG.SLOTS_CHANGED,      function() API.UpdateSlots() end)
Events:Register(MSG.VISIBILITY_CHANGED, function() API.UpdateVisibility() end)
Events:Register(MSG.PROFILE_CHANGED,    function() API.Refresh() end)
Events:Register(MSG.VALUES_CHANGED,      function()
    ns.Bar:ForEach(function(bar)
        local n = ns.BarCfg(bar.index).behavior.numSlots or 1
        for i = 1, n do
            local slot = ns.Slot.Get(bar, i)
            if slot then ns.Engine.Refresh(slot) end
        end
    end)
end)
Events:Register(MSG.ACCENT_CHANGED,     function()
    -- Accent affects styling, the colour datatexts paint inline, and separators.
    API.UpdateAppearance()
    ns.Bar:ForEach(function(bar)
        local n = ns.BarCfg(bar.index).behavior.numSlots or 1
        for i = 1, n do
            local slot = ns.Slot.Get(bar, i)
            if slot then ns.Engine.Refresh(slot) end
        end
        ns.Bar.Layout(bar)   -- redraw separators with the new accent colour
    end)
end)
