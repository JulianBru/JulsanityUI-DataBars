--------------------------------------------------------------------------------
--  Modules/Visibility.lua  -  Mouseover fade + auto-hide + enabled state
--
--  Per-bar behaviour, all event/condition driven:
--    * enabled       - a disabled bar is hidden entirely.
--    * mouseoverFade - the bar fades to `fadeAlpha` unless hovered. Each bar
--      gets its own OnUpdate driver, attached ONLY while fade is on.
--    * autoHide      - the bar hides while the player is in combat.
--------------------------------------------------------------------------------
local _, ns = ...
local Vis = ns.Visibility
local abs = math.abs

local THROTTLE = 0.05

-- Create (once) the per-bar fade driver.
local function EnsureDriver(bar)
    if bar._fadeDriver then return bar._fadeDriver end
    local d = CreateFrame("Frame")
    local acc = 0
    d:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < THROTTLE then return end
        acc = 0
        local f = bar.frame
        local s = bar._fade
        if not (f and s) then return end
        local target = f:IsMouseOver() and s.fullAlpha or s.fadeAlpha
        local cur = f:GetAlpha()
        local na = cur + (target - cur) * 0.25
        if abs(na - target) < 0.01 then na = target end
        f:SetAlpha(na)
    end)
    d:Hide()
    bar._fadeDriver = d
    return d
end

-- Combat watcher for auto-hide (one global frame; re-applies all bars).
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function() Vis:ApplyAll() end)

--- Apply the current visibility configuration for a single bar.
function Vis:ApplyOne(bar)
    local f = bar and bar.frame
    if not f then return end
    local c = ns.BarCfg(bar.index)
    local A = c.appearance

    -- Disabled bars are fully hidden.
    if c.enabled == false then
        if bar._fadeDriver then bar._fadeDriver:Hide() end
        f:Hide()
        return
    end

    -- Auto-hide in combat
    if A.autoHide and InCombatLockdown() then
        f:Hide()
    else
        f:Show()
    end

    -- Mouseover fade
    if A.mouseoverFade then
        bar._fade = { fadeAlpha = A.fadeAlpha or 0, fullAlpha = A.alpha or 1 }
        EnsureDriver(bar):Show()
    else
        if bar._fadeDriver then bar._fadeDriver:Hide() end
        f:SetAlpha(A.alpha or 1)
    end
end

--- Apply to every bar.
function Vis:ApplyAll()
    for i = 1, #ns.Bars do self:ApplyOne(ns.Bars[i]) end
end

--- Convenience: Apply(bar) for one, Apply() for all.
function Vis:Apply(bar)
    if bar then self:ApplyOne(bar) else self:ApplyAll() end
end
