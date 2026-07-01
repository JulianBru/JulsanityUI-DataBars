--------------------------------------------------------------------------------
--  Locales/enUS.lua  -  Default locale + lookup table
--
--  ns.L is a string table with a metatable that returns the key itself when a
--  translation is missing. English is therefore the source language: keys are
--  the English strings, and other locale files override entries as needed.
--------------------------------------------------------------------------------
local _, ns = ...

local L = setmetatable({}, {
    __index = function(_, k) return k end,
})
ns.L = L

-- enUS needs no explicit entries (keys are the English text). Listed here as
-- the canonical set of translatable strings for translators to mirror.
--
--  Sections:        "Layout", "Appearance", "Behavior", "Advanced"
--  Layout:          "Width", "Height", "Padding", "Margin", "Spacing",
--                   "Orientation", "Growth Direction", "Auto Size",
--                   "Horizontal", "Vertical", "Left", "Right", "Up", "Down"
--  Appearance:      "Font", "Font Size", "Font Outline", "Text Color",
--                   "Background Color", "Border", "Border Size", "Border Color",
--                   "Shadow", "Transparency", "Mouseover Fade", "Faded Alpha",
--                   "Auto Hide"
--  Behavior:        "Number of DataTexts", "DataText {n}", "Lock Position", "Snap"
--  Advanced:        "Debug Mode", "Reload UI", "Reset Position", "Reset Profile",
--                   "Export Profile", "Import Profile", "Profiles",
--                   "New Profile", "Copy Profile", "Delete Profile",
--                   "Active Profile"
