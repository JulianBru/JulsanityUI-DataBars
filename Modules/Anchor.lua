--------------------------------------------------------------------------------
--  Modules/Anchor.lua  -  Per-bar position + EllesmereUI Unlock-Mode integration
--
--  Each bar is positioned by its own saved anchor (barCfg.position) - no ElvUI
--  mover. The minimap bar additionally supports an "attach" mode: while
--  barCfg.attach == "minimap" it anchors its TOP to the minimap's BOTTOM and
--  follows the minimap. Dragging it in EllesmereUI Unlock/Edit mode switches the
--  bar to free positioning (attach = "free"). One unlock element is registered
--  per bar, using the public EllesmereUI:RegisterUnlockElements API.
--------------------------------------------------------------------------------
local _, ns = ...
local Anchor = ns.Anchor
local D = ns.Debug

local ATTACH_GAP = 2   -- px gap between the minimap and the bar when attached

-- Unlock elements are keyed by bar INDEX (a fixed set of ns.MAX_BARS is
-- registered once), so add/remove of custom bars just lights slots up or down.
local function KeyForIndex(i) return ns.UNLOCK_KEY .. "_" .. i end
local function KeyFor(bar) return KeyForIndex(bar.index) end

--- Place a bar at its saved position (or attached under the minimap).
function Anchor:ApplyPosition(bar)
    local f = bar and bar.frame
    if not f then return end
    local c = ns.BarCfg(bar.index)
    f:ClearAllPoints()

    if bar.def.attachable and c.attach == "minimap" then
        local mm = _G[bar.def.attachFrameName or "Minimap"]
        if mm then
            f:SetPoint("TOP", mm, "BOTTOM", (c.position and c.position.x) or 0, -ATTACH_GAP)
            return
        end
    end

    local p = c.position or {}
    f:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or -200)
end

--- Apply positions for every active bar.
function Anchor:ApplyAll()
    for i = 1, (ns.NUM_BARS or #ns.Bars) do
        if ns.Bars[i] then self:ApplyPosition(ns.Bars[i]) end
    end
end

--- Reset one bar to its default position/attach and re-apply. Custom bars have
--- no fixed default, so they fall back to a sensible centred free position.
function Anchor:Reset(bar)
    if not bar then return end
    local c = ns.BarCfg(bar.index)
    if not c then return end
    local def = ns.DEFAULT_PROFILE.bars and ns.DEFAULT_PROFILE.bars[bar.index]
    if def then
        c.attach = def.attach
        c.position = { point = def.position.point, relPoint = def.position.relPoint, x = def.position.x, y = def.position.y }
    else
        c.attach = "free"
        c.position = { point = "CENTER", relPoint = "CENTER", x = 0, y = -240 }
    end
    self:ApplyPosition(bar)
    D.Log("anchor reset (%s)", bar.def.id)
end

--- Tell EllesmereUI a bar changed size so unlock-mode relations stay correct.
function Anchor:NotifyResized(bar)
    if bar and EllesmereUI and EllesmereUI.NotifyElementResized then
        pcall(EllesmereUI.NotifyElementResized, KeyFor(bar))
    end
end

--- Register every bar as an EllesmereUI unlock element (once).
function Anchor:Register()
    if self._registered then return end
    if not (EllesmereUI and EllesmereUI.RegisterUnlockElements) then
        D.Log("EllesmereUI unlock API unavailable; anchors not registered")
        return
    end
    self._registered = true

    -- Register a fixed set of MAX_BARS elements, each bound to a bar index and
    -- reading its live instance/config. Elements past the current bar count
    -- report themselves hidden until that bar is created.
    local elements = {}
    for i = 1, (ns.MAX_BARS or 10) do
        local idx = i
        elements[i] = {
            key   = KeyForIndex(idx),
            label = (idx == 1 and "Main Bar") or (idx == 2 and "Minimap Bar") or ("DataBar " .. idx),
            group = "JulsanityUI",
            order = 500 + idx,

            getFrame = function() local b = ns.Bars[idx]; return b and b.frame end,
            getSize  = function()
                local b = ns.Bars[idx]; local f = b and b.frame
                if f then return f:GetWidth(), f:GetHeight() end
                return 0, 0
            end,
            isHidden = function()
                if idx > (ns.NUM_BARS or 0) then return true end
                local c = ns.BarCfg(idx)
                local b = ns.Bars[idx]; local f = b and b.frame
                return (not c) or (c.enabled == false) or (not f) or (not f:IsShown())
            end,

            savePosition = function(_, point, relPoint, x, y)
                local c = ns.BarCfg(idx)
                if not c then return end
                c.attach = "free"
                c.position = c.position or {}
                c.position.point, c.position.relPoint, c.position.x, c.position.y = point, relPoint, x, y
                if not (EllesmereUI and EllesmereUI._unlockActive) then
                    Anchor:ApplyPosition(ns.Bars[idx])
                end
            end,
            loadPosition  = function()
                local c = ns.BarCfg(idx); local b = ns.Bars[idx]
                -- While attached under the minimap, let unlock mode read the live
                -- position instead of a saved one.
                if b and b.def and b.def.attachable and c and c.attach == "minimap" then return nil end
                return c and c.position
            end,
            clearPosition = function() if ns.Bars[idx] then Anchor:Reset(ns.Bars[idx]) end end,
            applyPosition = function() if ns.Bars[idx] then Anchor:ApplyPosition(ns.Bars[idx]) end end,
        }
    end

    EllesmereUI:RegisterUnlockElements(elements, ns.FOLDER)
    D.Log("registered %d EllesmereUI unlock elements", #elements)
end
