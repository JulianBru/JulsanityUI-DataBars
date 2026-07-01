--------------------------------------------------------------------------------
--  Modules/Bar.lua  -  Bar instances + layout engine
--
--  Manages the fixed set of bars defined in ns.BARS (main + minimap). Each bar
--  is an instance table {index, def, frame, pool} stored in ns.Bars. The main
--  bar's Auto Size follows the chat frame width; the minimap bar's follows the
--  minimap width. Slots always fill their bar equally.
--------------------------------------------------------------------------------
local _, ns = ...
local Bar = ns.Bar
local U   = ns.Util
local D   = ns.Debug

local MIN_SLOT_W = 12
local TEXT_PAD   = 6
local max = math.max

--------------------------------------------------------------------------------
--  Helpers
--------------------------------------------------------------------------------

-- Iterate every built bar instance.
function Bar:ForEach(fn)
    for i = 1, #ns.Bars do fn(ns.Bars[i], i) end
end

-- Resolve the auto-size reference width for a bar (chat vs minimap).
local function AutoWidth(bar)
    if bar.def.widthSource == "minimap" then
        local mm = _G[bar.def.attachFrameName or "Minimap"]
        return (mm and mm:GetWidth()) or 200
    end
    return (ChatFrame1 and ChatFrame1:GetWidth()) or 400
end

--------------------------------------------------------------------------------
--  Construction
--------------------------------------------------------------------------------
local function BuildFrame(bar)
    if bar.frame then return bar.frame end

    local f = CreateFrame("Frame", "JulsanityDataBar_" .. bar.def.id, UIParent)
    f:SetFrameStrata("LOW")
    f:SetFrameLevel(10)
    f:SetClampedToScreen(true)
    f:SetSize(200, 22)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)

    f.border = {
        top    = f:CreateTexture(nil, "BORDER"),
        bottom = f:CreateTexture(nil, "BORDER"),
        left   = f:CreateTexture(nil, "BORDER"),
        right  = f:CreateTexture(nil, "BORDER"),
    }
    f.shadow = {
        top    = f:CreateTexture(nil, "BACKGROUND", nil, -1),
        bottom = f:CreateTexture(nil, "BACKGROUND", nil, -1),
        left   = f:CreateTexture(nil, "BACKGROUND", nil, -1),
        right  = f:CreateTexture(nil, "BACKGROUND", nil, -1),
    }

    bar.frame = f
    f._bar = bar

    -- Follow the reference frame's width while Auto Size is on (horizontal).
    local refName = (bar.def.widthSource == "minimap") and (bar.def.attachFrameName or "Minimap") or "ChatFrame1"
    local ref = _G[refName]
    if ref and not bar._sizeHooked then
        bar._sizeHooked = true
        ref:HookScript("OnSizeChanged", function()
            local c = ns.BarCfg(bar.index)
            if c and c.layout.autoSize and c.layout.orientation ~= "VERTICAL" then
                Bar.Layout(bar)
            end
        end)
    end

    return f
end

--- Create every bar instance + frame (idempotent).
function Bar:BuildAll()
    for i, def in ipairs(ns.BARS) do
        local bar = ns.Bars[i]
        if not bar then
            bar = { index = i, def = def, pool = {} }
            ns.Bars[i] = bar
        end
        BuildFrame(bar)
    end
    return ns.Bars
end

-- Back-compat: ns.Bar:Build() builds all bars and returns the main frame.
function Bar:Build()
    self:BuildAll()
    return ns.Bars[1] and ns.Bars[1].frame
end

--------------------------------------------------------------------------------
--  Slot management (per bar)
--------------------------------------------------------------------------------
function Bar.UpdateSlots(bar)
    if not bar or not bar.frame then return end
    local c = ns.BarCfg(bar.index)
    local n = max(1, c.behavior.numSlots or 1)
    local slots = c.behavior.slots or {}

    for i = 1, n do
        local slot = ns.Slot.Acquire(bar, i)
        local want = slots[i] or "None"
        if slot._dtName ~= want then
            ns.Engine.Bind(slot, want)
        end
        ns.Renderer:ApplyText(bar, slot)
    end
    ns.Slot.HideFrom(bar, n)
    D.Log("slots updated (%s n=%d)", bar.def.id, n)
end

--------------------------------------------------------------------------------
--  Layout (per bar)
--------------------------------------------------------------------------------
local function ContentWidth(slot)
    local w = (slot and slot.text and slot.text:GetStringWidth() or 0) + TEXT_PAD * 2
    return max(w, MIN_SLOT_W)
end

function Bar.Layout(bar)
    local f = bar and bar.frame
    if not f then return end

    local c   = ns.BarCfg(bar.index)
    local L    = c.layout
    local n    = max(1, c.behavior.numSlots or 1)
    local pad, sp = L.padding or 0, L.spacing or 0
    local horizontal = (L.orientation ~= "VERTICAL")

    local slots = {}
    for i = 1, n do slots[i] = ns.Slot.Get(bar, i) end

    if horizontal then
        local barH  = max(L.height or 22, 4)
        local slotH = max(barH - 2 * pad, 1)

        local barW
        if L.autoSize then
            barW = AutoWidth(bar) + (L.widthOffset or 0)
        else
            barW = L.width or 400
        end
        local widths = {}
        local usable = max(barW - 2 * pad - sp * (n - 1), MIN_SLOT_W * n)
        local w = usable / n
        for i = 1, n do widths[i] = w end
        f:SetSize(max(barW, MIN_SLOT_W), barH)

        local reversed = (L.growth == "LEFT")
        local cursor = pad
        for p = 1, n do
            local idx = reversed and (n - p + 1) or p
            local slot = slots[idx]
            if slot then
                slot:ClearAllPoints()
                slot:SetPoint("TOPLEFT", f, "TOPLEFT", cursor, -pad)
                slot:SetSize(widths[idx], slotH)
            end
            cursor = cursor + widths[idx] + sp
        end
    else
        local slotH = max(L.height or 22, 4)
        local barW
        local widths = {}
        if L.autoSize then
            local maxW = MIN_SLOT_W
            for i = 1, n do maxW = max(maxW, ContentWidth(slots[i])) end
            barW = maxW + 2 * pad
            for i = 1, n do widths[i] = maxW end
        else
            barW = L.width or 200
            local w = max(barW - 2 * pad, MIN_SLOT_W)
            for i = 1, n do widths[i] = w end
        end

        local content = n * slotH + sp * (n - 1)
        f:SetSize(max(barW, MIN_SLOT_W), content + 2 * pad)

        local reversed = (L.growth == "UP")
        local cursor = pad
        for p = 1, n do
            local idx = reversed and (n - p + 1) or p
            local slot = slots[idx]
            if slot then
                slot:ClearAllPoints()
                slot:SetPoint("TOPLEFT", f, "TOPLEFT", pad, -cursor)
                slot:SetSize(widths[idx], slotH)
            end
            cursor = cursor + slotH + sp
        end
    end

    ns.Renderer:ApplyAppearance(bar)
    if ns.Anchor.NotifyResized then ns.Anchor:NotifyResized(bar) end
end

--------------------------------------------------------------------------------
--  Auto-size: debounced re-layout when slot text changes (vertical auto-size)
--------------------------------------------------------------------------------
function Bar.OnSlotUpdated(slot)
    local bar = slot and slot._bar
    if not bar then return end
    local c = ns.BarCfg(bar.index)
    if not (c and c.layout.autoSize) then return end
    if bar._resizePending then return end
    bar._resizePending = true
    C_Timer.After(0.1, function()
        bar._resizePending = false
        Bar.Layout(bar)
    end)
end

--------------------------------------------------------------------------------
--  Full rebuild of a single bar
--------------------------------------------------------------------------------
function Bar.RebuildOne(bar)
    BuildFrame(bar)
    Bar.UpdateSlots(bar)
    Bar.Layout(bar)
    ns.Renderer:ApplyAppearance(bar)
    ns.Visibility:ApplyOne(bar)
end
