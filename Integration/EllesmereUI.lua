--------------------------------------------------------------------------------
--  Integration/EllesmereUI.lua  -  EllesmereUI adapter (the only external API)
--
--  Wraps every EllesmereUI touch-point behind a small, stable facade so that a
--  change in EllesmereUI affects exactly one file. All calls are defensive: a
--  missing API degrades gracefully instead of erroring. Bound against the
--  verified EllesmereUI source (Lite, accent/font helpers,
--  LibSharedMedia from EllesmereUI's bundled Libs).
--------------------------------------------------------------------------------
local _, ns = ...
local EUI = ns.EUI
local D = ns.Debug

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
EUI.LSM = LSM

--------------------------------------------------------------------------------
--  Accent colour
--------------------------------------------------------------------------------

--- The EllesmereUI accent colour (r,g,b in 0..1). Falls back to EllesmereUI's
--- signature green if the API is unavailable.
function EUI:GetAccent()
    if EllesmereUI and EllesmereUI.GetAccentColor then
        local r, g, b = EllesmereUI.GetAccentColor()
        if r then return r, g, b end
    end
    return 0.6784, 0.0, 1.0
end

--------------------------------------------------------------------------------
--  Fonts
--------------------------------------------------------------------------------

--- Resolve a font option value to a usable font path.
--  @param name  a LibSharedMedia font name, or nil to inherit EllesmereUI's
--               configured module font.
function EUI:ResolveFont(name)
    if name and name ~= "" and LSM then
        local ok = LSM:IsValid("font", name)
        if ok then return LSM:Fetch("font", name) end
    end
    if EllesmereUI and EllesmereUI.GetFontPath then
        local path = EllesmereUI.GetFontPath(ns.FOLDER)
        if path then return path end
    end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

--- Sorted list of available font names (for the appearance dropdown). The first
--- entry, "", represents "Inherit (EllesmereUI)".
function EUI:GetFontList()
    local values = { [""] = "Inherit (EllesmereUI)" }
    local order  = { "" }
    if LSM then
        local list = LSM:List("font")   -- array of names
        local names = {}
        for _, n in ipairs(list) do names[#names + 1] = n end
        table.sort(names)
        for _, n in ipairs(names) do
            values[n] = n
            order[#order + 1] = n
        end
    end
    return values, order
end

--------------------------------------------------------------------------------
--  Textures (statusbar / background)
--------------------------------------------------------------------------------

--- Resolve a background-texture option value to a usable texture path.
--  @param name  a LibSharedMedia "statusbar" texture name, or nil/"" for a
--               solid colour (returns nil so the Renderer uses SetColorTexture).
function EUI:ResolveStatusbar(name)
    if name and name ~= "" and LSM and LSM:IsValid("statusbar", name) then
        return LSM:Fetch("statusbar", name)
    end
    return nil
end

--- Sorted list of available statusbar textures (for the appearance dropdown).
--- The first entry, "", represents "Solid Color" (no texture).
function EUI:GetStatusbarList()
    local values = { [""] = "Solid Color" }
    local order  = { "" }
    if LSM then
        local names = {}
        for _, n in ipairs(LSM:List("statusbar")) do names[#names + 1] = n end
        table.sort(names)
        for _, n in ipairs(names) do
            values[n] = n
            order[#order + 1] = n
        end
    end
    return values, order
end

--------------------------------------------------------------------------------
--  Accent change hook (fixes the wrong/teal accent on first login)
--------------------------------------------------------------------------------
-- EllesmereUI applies the user's saved accent shortly AFTER login (with a fade),
-- so datatexts rendered at PLAYER_LOGIN can briefly use EUI's default colour.
-- Register a callback so we re-render whenever the accent updates. Coalesced via
-- a short timer so a colour fade triggers only one refresh.
function EUI:HookAccent()
    if self._accentHooked then return end
    if not (EllesmereUI and EllesmereUI.RegAccent) then return end
    self._accentHooked = true
    local pending = false
    EllesmereUI.RegAccent({ type = "callback", fn = function()
        if pending then return end
        pending = true
        C_Timer.After(0.05, function()
            pending = false
            if ns.Events and ns.MSG then ns.Events:Fire(ns.MSG.ACCENT_CHANGED) end
        end)
    end })
    D.Log("registered EllesmereUI accent callback")
end

--------------------------------------------------------------------------------
--  Unlock / Edit mode
--------------------------------------------------------------------------------

--- Is EllesmereUI's Unlock-mode toggle available?
function EUI:IsUnlockAvailable()
    return (EllesmereUI and type(EllesmereUI.ToggleUnlockMode) == "function") and true or false
end

--- Open EllesmereUI's Unlock/Edit mode (no-op if already active or unavailable).
function EUI:OpenUnlock()
    if not (EllesmereUI and EllesmereUI.ToggleUnlockMode) then return false end
    if EllesmereUI.IsUnlockModeActive and EllesmereUI.IsUnlockModeActive() then return true end
    EllesmereUI:ToggleUnlockMode()
    return true
end

--------------------------------------------------------------------------------
--  Lifecycle handle
--------------------------------------------------------------------------------

--- The EllesmereUI Lite addon object (created in Core/Init).
function EUI:Addon()
    return ns.addon
end
