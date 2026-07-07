--------------------------------------------------------------------------------
--  Core/Init.lua  -  Namespace bootstrap, version, constants
--
--  Loaded first. Establishes the private namespace table `ns` that every other
--  file shares (second return value of `...`). No globals are created except the
--  SavedVariables table declared in the .toc (JulsanityDataBarsDB).
--
--  EllesmereUI is a hard dependency (see .toc) and therefore guaranteed loaded
--  before this file. We still guard defensively so a broken EllesmereUI install
--  fails loudly but cleanly instead of throwing raw Lua errors.
--------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

-- Hard guard: without EllesmereUI's Lite layer there is nothing to integrate
-- with. Bail out early; the .toc dependency normally prevents this.
if not EllesmereUI or not EllesmereUI.Lite then
    local msg = "|cffad00ffJulsanityUI DataBars|r: EllesmereUI not found - addon disabled."
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
    return
end

--------------------------------------------------------------------------------
--  Namespace skeleton
--------------------------------------------------------------------------------
ns.ADDON      = ADDON_NAME            -- "JulsanityUI_DataBars"
ns.FOLDER     = ADDON_NAME            -- folder name (used by EUI integrations)
ns.UNLOCK_KEY = "JDB_DataBar"         -- base key for EllesmereUI unlock elements (per-bar suffix added)

-- Bar definitions. Exactly two fixed bars: the main bar (follows the chat
-- width when Auto Size is on) and the minimap bar (follows the minimap width
-- and anchors beneath it by default). Each bar has its own config block
-- (profile.bars[index]) and its own anchor / unlock element.
ns.BARS = {
    { id = "Main",    label = "Main Bar",    widthSource = "chat",    attachable = false },
    { id = "Minimap", label = "Minimap Bar", widthSource = "minimap", attachable = true, attachFrameName = "Minimap" },
}
ns.NUM_BARS = #ns.BARS

-- Resolve version from TOC metadata (single source of truth).
do
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata)
        and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    ns.VERSION = meta or "0.0.0"
end

-- Sub-module containers. Populated by their respective files; referenced here so
-- editors and later files have a stable, documented surface to attach to.
ns.Util     = ns.Util     or {}   -- Utils/Utils.lua
ns.Debug    = ns.Debug    or {}   -- Utils/Debug.lua
ns.Events   = ns.Events   or {}   -- API/Events.lua
ns.API      = ns.API      or {}   -- API/API.lua
ns.EUI      = ns.EUI      or {}   -- Integration/EllesmereUI.lua
ns.Engine   = ns.Engine   or {}   -- DataTexts/Engine.lua
ns.Registry = ns.Registry or {}   -- DataTexts/Registry.lua
ns.Slot     = ns.Slot     or {}   -- Modules/Slot.lua
ns.Bar      = ns.Bar      or {}   -- Modules/Bar.lua (manager)
ns.Bars     = ns.Bars     or {}   -- runtime bar instances (array, 1..NUM_BARS)
ns.Renderer = ns.Renderer or {}   -- Modules/Renderer.lua
ns.Anchor   = ns.Anchor   or {}   -- Modules/Anchor.lua
ns.Visibility = ns.Visibility or {} -- Modules/Visibility.lua
ns.Config   = ns.Config   or {}   -- Config/Options.lua
ns.Profiles = ns.Profiles or {}   -- Config/Profiles.lua
ns.Serial   = ns.Serial   or {}   -- Config/ImportExport.lua

-- DataText catalog: name -> spec. Filled by DataTexts/DT_*.lua via the engine.
ns.DataTexts = ns.DataTexts or {}

--------------------------------------------------------------------------------
--  Internal message names (used by the Events bus, see API/Events.lua)
--------------------------------------------------------------------------------
ns.MSG = {
    LAYOUT_CHANGED     = "LAYOUT_CHANGED",       -- size/padding/spacing/orientation/growth
    APPEARANCE_CHANGED = "APPEARANCE_CHANGED",   -- bg/border/shadow/alpha/text color
    FONT_CHANGED       = "FONT_CHANGED",         -- font/size/outline
    SLOTS_CHANGED      = "SLOTS_CHANGED",        -- count or assignment of datatexts
    VISIBILITY_CHANGED = "VISIBILITY_CHANGED",   -- fade/auto-hide/lock
    PROFILE_CHANGED    = "PROFILE_CHANGED",      -- active profile switched/reset/imported
    ACCENT_CHANGED     = "ACCENT_CHANGED",       -- EllesmereUI accent color changed
    VALUES_CHANGED     = "VALUES_CHANGED",       -- re-render datatext values (e.g. hide prefixes)
}

--------------------------------------------------------------------------------
--  Lifecycle addon object (EllesmereUI Lite). OnInitialize fires at
--  ADDON_LOADED (our SavedVariables are available), OnEnable at PLAYER_LOGIN.
--  The actual handlers are assigned in Core/Core.lua.
--------------------------------------------------------------------------------
ns.addon = EllesmereUI.Lite.NewAddon(ADDON_NAME)

--------------------------------------------------------------------------------
--  Print helper (accent-coloured prefix)
--------------------------------------------------------------------------------
function ns.Print(...)
    -- Fixed JulsanityUI brand colour (#AD00FF) for the chat tag - not the
    -- EllesmereUI accent, so the addon reads as its own plugin.
    local prefix = "|cffad00ffJulsanityUI DataBars|r"
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. ": " .. table.concat(parts, " "))
    end
end

--------------------------------------------------------------------------------
--  DataText prefix visibility
--------------------------------------------------------------------------------
-- True unless the slot's bar is configured to hide datatext prefixes/labels
-- (e.g. "Dur", "ilvl"). DataTexts call this to decide whether to draw a label.
function ns.WantPrefix(slot)
    local bar = slot and slot._bar
    local c = bar and ns.BarCfg and ns.BarCfg(bar.index)
    return not (c and c.appearance and c.appearance.hidePrefix)
end

-- Hex colour a datatext should use for its main VALUE: the bar's custom text
-- colour when enabled, otherwise the EllesmereUI accent. Semantic colours
-- (gold, durability, reputation, ...) are set explicitly and ignore this.
function ns.ValueHex(slot)
    local bar = slot and slot._bar
    local c = bar and ns.BarCfg and ns.BarCfg(bar.index)
    local a = c and c.appearance
    if a and a.useCustomTextColor and type(a.textColor) == "table" then
        return ns.Util.RGBToHex(a.textColor[1] or 1, a.textColor[2] or 1, a.textColor[3] or 1)
    end
    return ns.Util.RGBToHex(ns.EUI:GetAccent())
end

-- Returns the bar's custom text colour hex when enabled, otherwise the supplied
-- fallback hex. Used to override a datatext's "good" tier (e.g. friendly+ rep)
-- with the custom text colour while keeping its warning colours.
function ns.ColorOr(slot, fallbackHex)
    local bar = slot and slot._bar
    local c = bar and ns.BarCfg and ns.BarCfg(bar.index)
    local a = c and c.appearance
    if a and a.useCustomTextColor and type(a.textColor) == "table" then
        return ns.Util.RGBToHex(a.textColor[1] or 1, a.textColor[2] or 1, a.textColor[3] or 1)
    end
    return fallbackHex
end
