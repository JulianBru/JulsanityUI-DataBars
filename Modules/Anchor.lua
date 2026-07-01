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

local function KeyFor(bar) return ns.UNLOCK_KEY .. "_" .. bar.def.id end

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

--- Apply positions for every bar.
function Anchor:ApplyAll()
    for i = 1, #ns.Bars do self:ApplyPosition(ns.Bars[i]) end
end

--- Reset one bar to its default position/attach and re-apply.
function Anchor:Reset(bar)
    if not bar then return end
    local def = ns.DEFAULT_PROFILE.bars[bar.index]
    local c = ns.BarCfg(bar.index)
    c.attach = def.attach
    c.position = { point = def.position.point, relPoint = def.position.relPoint, x = def.position.x, y = def.position.y }
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

    local elements = {}
    for i = 1, #ns.Bars do
        local bar = ns.Bars[i]
        elements[i] = {
            key   = KeyFor(bar),
            label = bar.def.label,
            group = "JulsanityUI",
            order = 500 + i,

            getFrame = function() return bar.frame end,
            getSize  = function()
                local f = bar.frame
                if f then return f:GetWidth(), f:GetHeight() end
                return 0, 0
            end,
            isHidden = function()
                local c = ns.BarCfg(bar.index)
                local f = bar.frame
                return (c.enabled == false) or (not f) or (not f:IsShown())
            end,

            savePosition = function(_, point, relPoint, x, y)
                local c = ns.BarCfg(bar.index)
                c.attach = "free"
                c.position = c.position or {}
                c.position.point, c.position.relPoint, c.position.x, c.position.y = point, relPoint, x, y
                if not (EllesmereUI and EllesmereUI._unlockActive) then
                    Anchor:ApplyPosition(bar)
                end
            end,
            loadPosition  = function()
                local c = ns.BarCfg(bar.index)
                -- While attached under the minimap, let unlock mode read the live
                -- position instead of a saved one.
                if bar.def.attachable and c.attach == "minimap" then return nil end
                return c.position
            end,
            clearPosition = function() Anchor:Reset(bar) end,
            applyPosition = function() Anchor:ApplyPosition(bar) end,
        }
    end

    EllesmereUI:RegisterUnlockElements(elements, ns.FOLDER)
    D.Log("registered %d EllesmereUI unlock elements", #elements)
end
