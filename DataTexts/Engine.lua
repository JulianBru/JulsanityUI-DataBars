--------------------------------------------------------------------------------
--  DataTexts/Engine.lua  -  Native DataText engine
--
--  Owns the DataText specification format, registration, and the binding of a
--  spec to a bar slot. Fully self-contained: no ElvUI, no external framework.
--
--  Spec fields (see docs/API.md):
--    name      string                       required, unique key
--    label     string                       display name (config dropdown)
--    category  string                       grouping (e.g. "System")
--    events    table  (optional)            Blizzard events that trigger update
--    interval  number (optional)            periodic refresh seconds (use sparingly)
--    update    function(slot, event, ...)   required: sets slot.text
--    click     function(slot, button)       optional
--    enter     function(slot)               optional: build tooltip
--    leave     function(slot)               optional: default hides GameTooltip
--
--  A "slot" is a Button frame created by Modules/Slot.lua with a `.text`
--  FontString. The engine attaches per-slot bookkeeping (_dtName, _eventFrame,
--  _ticker) and routes events/ticks/mouse scripts to the bound spec.
--------------------------------------------------------------------------------
local _, ns = ...
local Engine = ns.Engine
local D = ns.Debug

local REFRESH_EVENT = "JDB_REFRESH"   -- synthetic event for initial/forced draw
Engine.REFRESH_EVENT = REFRESH_EVENT

--------------------------------------------------------------------------------
--  Registration
--------------------------------------------------------------------------------

--- Register a DataText spec. Validates required fields, stores it in the global
--- catalog (ns.DataTexts) and indexes it in the Registry.
function Engine.Register(spec)
    assert(type(spec) == "table", "RegisterDataText: spec table required")
    assert(type(spec.name) == "string" and spec.name ~= "", "RegisterDataText: spec.name required")
    assert(type(spec.update) == "function", "RegisterDataText: spec.update required for '" .. spec.name .. "'")

    spec.label    = spec.label or spec.name
    spec.category = spec.category or "Misc"

    ns.DataTexts[spec.name] = spec
    ns.Registry:Add(spec)
    D.Log("registered datatext '%s' (%s)", spec.name, spec.category)
end

-- Public alias used throughout the catalog files.
ns.RegisterDataText = Engine.Register

--------------------------------------------------------------------------------
--  Tooltip helper (shared by specs)
--------------------------------------------------------------------------------

--- Open GameTooltip anchored above the slot and clear it, ready for lines.
function Engine.OpenTooltip(slot)
    GameTooltip:SetOwner(slot, "ANCHOR_TOP")
    GameTooltip:ClearLines()
end

--------------------------------------------------------------------------------
--  Binding
--------------------------------------------------------------------------------

-- Run a spec callback safely; a faulty datatext must never break the bar.
local function SafeCall(fn, slot, ...)
    if not fn then return end
    local ok, err = xpcall(fn, geterrorhandler(), slot, ...)
    if not ok then D.Log("datatext '%s' callback error: %s", slot._dtName or "?", tostring(err)) end
end

-- Run a spec's update, then notify the bar so auto-size can re-layout if the
-- rendered text width changed. Centralised so every update path behaves alike.
local function DoUpdate(slot, event, ...)
    SafeCall(slot._spec and slot._spec.update, slot, event, ...)
    if ns.Bar and ns.Bar.OnSlotUpdated then ns.Bar.OnSlotUpdated(slot) end
end

--------------------------------------------------------------------------------
--  Live tooltip refresh (opt-in via spec.tooltipRefresh = interval seconds)
--
--  While the cursor stays on a slot whose spec sets `tooltipRefresh`, the spec's
--  `enter` is re-run on an interval so the tooltip shows live values (e.g. addon
--  memory). Paused while in combat, and stopped when the cursor leaves.
--------------------------------------------------------------------------------
local ttDriver = CreateFrame("Frame")
ttDriver:Hide()
local ttSlot, ttInterval, ttAcc = nil, 1, 0
ttDriver:SetScript("OnUpdate", function(_, elapsed)
    ttAcc = ttAcc + elapsed
    if ttAcc < ttInterval then return end
    ttAcc = 0
    local sl = ttSlot
    if not (sl and sl._spec and type(sl._spec.enter) == "function" and sl:IsMouseOver()) then
        ttDriver:Hide(); ttSlot = nil; return
    end
    if InCombatLockdown() then return end   -- pause live refresh in combat
    SafeCall(sl._spec.enter, sl)
end)

local function StartTooltipRefresh(slot, spec)
    local iv = spec.tooltipRefresh
    if not iv then return end
    ttSlot = slot
    ttInterval = (type(iv) == "number" and iv > 0) and iv or 1
    ttAcc = 0
    ttDriver:Show()
end
local function StopTooltipRefresh(slot)
    if ttSlot == slot then ttDriver:Hide(); ttSlot = nil end
end

--- Detach any spec currently bound to the slot: stop events, cancel the ticker,
--- clear scripts and text. Leaves the slot reusable (pooled).
function Engine.Unbind(slot)
    StopTooltipRefresh(slot)
    if slot._eventFrame then
        slot._eventFrame:UnregisterAllEvents()
        slot._eventFrame:SetScript("OnEvent", nil)
    end
    if slot._ticker then
        slot._ticker:Cancel()
        slot._ticker = nil
    end
    slot._dtName = nil
    slot._spec   = nil
    slot.text:SetText("")
    slot:SetScript("OnClick", nil)
    slot:SetScript("OnEnter", nil)
    slot:SetScript("OnLeave", nil)
    slot:EnableMouse(false)
end

--- Bind the named DataText to the slot. Safe to call repeatedly; it unbinds the
--- previous spec first. `dtName` of nil/"None"/unknown leaves the slot empty.
function Engine.Bind(slot, dtName)
    Engine.Unbind(slot)
    if not dtName or dtName == "None" then return end

    local spec = ns.DataTexts[dtName]
    if not spec then
        D.Log("bind skipped: unknown datatext '%s'", tostring(dtName))
        return
    end

    slot._dtName = dtName
    slot._spec   = spec

    -- Event-driven updates ---------------------------------------------------
    if spec.events and #spec.events > 0 then
        local ef = slot._eventFrame
        if not ef then
            ef = CreateFrame("Frame")
            slot._eventFrame = ef
        end
        ef:SetScript("OnEvent", function(_, event, ...)
            DoUpdate(slot, event, ...)
        end)
        for i = 1, #spec.events do
            -- Unit events would need RegisterUnitEvent; the catalog uses broad
            -- events only, so RegisterEvent is correct and pcall-guarded.
            pcall(ef.RegisterEvent, ef, spec.events[i])
        end
    end

    -- Periodic updates -------------------------------------------------------
    if spec.interval and spec.interval > 0 then
        slot._ticker = C_Timer.NewTicker(spec.interval, function()
            DoUpdate(slot)
        end)
    end

    -- Mouse interaction ------------------------------------------------------
    local hasClick = type(spec.click) == "function"
    local hasEnter = type(spec.enter) == "function"
    slot:EnableMouse(hasClick or hasEnter)

    if hasClick then
        slot:RegisterForClicks("AnyUp")
        slot:SetScript("OnClick", function(_, button)
            -- Hide our hover tooltip before running the click handler so it can
            -- never overlap a context menu the click opens. Only hide it if we
            -- own it, so we don't stomp on another addon's tooltip.
            if GameTooltip:IsOwned(slot) then GameTooltip:Hide() end
            SafeCall(spec.click, slot, button)
        end)
    end

    -- Hover accent + tooltip. Even datatexts without an enter/leave get the
    -- accent-colour hover so the bar feels uniform.
    slot:SetScript("OnEnter", function()
        local r, g, b = ns.EUI:GetAccent()
        slot.text:SetTextColor(r, g, b, 1)
        if hasEnter then
            SafeCall(spec.enter, slot)
            StartTooltipRefresh(slot, spec)
        end
    end)
    slot:SetScript("OnLeave", function()
        StopTooltipRefresh(slot)
        local c = slot._baseColor
        if c then slot.text:SetTextColor(c[1], c[2], c[3], c[4] or 1) end
        if type(spec.leave) == "function" then
            SafeCall(spec.leave, slot)
        else
            GameTooltip:Hide()
        end
    end)

    -- Initial draw -----------------------------------------------------------
    DoUpdate(slot, REFRESH_EVENT)
end

--- Force an immediate re-draw of the slot's bound spec (used after font/colour
--- changes so values reflect the new styling without waiting for an event).
function Engine.Refresh(slot)
    if slot._spec then DoUpdate(slot, REFRESH_EVENT) end
end
