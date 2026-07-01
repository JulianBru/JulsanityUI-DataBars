--------------------------------------------------------------------------------
--  Config/Options.lua  -  Config pages (Layout/Appearance/Behavior/Advanced)
--
--  Builds the option pages with EllesmereUI's NATIVE widget toolkit
--  (EllesmereUI.Widgets / WidgetFactory). The per-bar pages (Layout/Appearance/
--  Behavior) start with a Bar selector + Enabled toggle, so the SAME pages
--  configure either bar (main or minimap); Config.currentBar selects which.
--  Advanced is profile-global (profiles, import/export, debug). Pages are
--  exposed via ns.Config.BuildPage / ns.Config.PAGES so both hosts can use them:
--    * the standalone window (Config/Window.lua),
--    * the EllesmereUI sidebar entry (RegisterModule, when whitelisted).
--------------------------------------------------------------------------------
local _, ns = ...
local Config = ns.Config
local L   = ns.L
local MSG = ns.MSG

local PAGE_LAYOUT     = "Layout"
local PAGE_APPEARANCE = "Appearance"
local PAGE_BEHAVIOR   = "Behavior"
local PAGE_ADVANCED   = "Advanced"

local UI_SLOT_CAP = 20

local min, abs = math.min, math.abs

-- Which bar the per-bar pages currently edit (1 = main, 2 = minimap).
Config.currentBar = Config.currentBar or 1

-- Active bar's config block.
local function cfg() return ns.BarCfg(Config.currentBar) end

--- Refresh whichever config UI is currently open (our window or the EUI panel).
function Config:RefreshOpen()
    if ns.Window and ns.Window.IsShown and ns.Window:IsShown() then
        ns.Window:RebuildCurrent()
    elseif EllesmereUI and EllesmereUI.RefreshPage then
        EllesmereUI:RefreshPage(true)
    end
end

-- Debounced rebuild (when the number of visible rows changes).
local rebuildPending = false
local function ScheduleRebuild()
    if rebuildPending then return end
    rebuildPending = true
    C_Timer.After(0.35, function()
        rebuildPending = false
        Config:RefreshOpen()
    end)
end

--------------------------------------------------------------------------------
--  Bar selector (top of every per-bar page)
--------------------------------------------------------------------------------
local function BuildBarSelector(parent, y)
    local W = EllesmereUI.Widgets
    local _, h

    local values, order = {}, {}
    for i, def in ipairs(ns.BARS) do
        local key = tostring(i)
        values[key] = L[def.label] or def.label
        order[i] = key
    end
    _, h = W:Dropdown(parent, L["Bar"], y, values,
        function() return tostring(Config.currentBar) end,
        function(v) Config.currentBar = tonumber(v) or 1; Config:RefreshOpen() end,
        order); y = y - h

    local c = cfg()
    _, h = W:Toggle(parent, L["Enabled"], y,
        function() return c.enabled ~= false end,
        function(v) c.enabled = v; ns.Events:Fire(MSG.VISIBILITY_CHANGED) end); y = y - h

    return y
end

--------------------------------------------------------------------------------
--  Pages
--------------------------------------------------------------------------------
local function BuildLayout(parent, y)
    y = BuildBarSelector(parent, y)
    local c, W = cfg(), EllesmereUI.Widgets
    local _, h
    _, h = W:SectionHeader(parent, L["Layout"], y); y = y - h
    _, h = W:Toggle(parent, L["Auto Size"], y,
        function() return c.layout.autoSize end,
        function(v) c.layout.autoSize = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Width"], y, 60, 1200, 1,
        function() return c.layout.width end,
        function(v) c.layout.width = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Width Offset"], y, -100, 300, 1,
        function() return c.layout.widthOffset or 0 end,
        function(v) c.layout.widthOffset = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end,
        "Added to the auto-size width (chat or minimap) to match a skin border."); y = y - h
    _, h = W:Slider(parent, L["Height"], y, 8, 80, 1,
        function() return c.layout.height end,
        function(v) c.layout.height = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Padding"], y, 0, 30, 1,
        function() return c.layout.padding end,
        function(v) c.layout.padding = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Spacing"], y, 0, 40, 1,
        function() return c.layout.spacing end,
        function(v) c.layout.spacing = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Dropdown(parent, L["Orientation"], y,
        { HORIZONTAL = L["Horizontal"], VERTICAL = L["Vertical"] },
        function() return c.layout.orientation end,
        function(v) c.layout.orientation = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end,
        { "HORIZONTAL", "VERTICAL" }); y = y - h
    _, h = W:Dropdown(parent, L["Growth Direction"], y,
        { RIGHT = L["Right"], LEFT = L["Left"], UP = L["Up"], DOWN = L["Down"] },
        function() return c.layout.growth end,
        function(v) c.layout.growth = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end,
        { "RIGHT", "LEFT", "UP", "DOWN" }); y = y - h

    _, h = W:Button(parent, L["Reset Position"], y, function()
        ns.Anchor:Reset(ns.Bars[Config.currentBar]); ns.Print("position reset.")
    end); y = y - h
    return y
end

local function BuildAppearance(parent, y)
    y = BuildBarSelector(parent, y)
    local c, W = cfg(), EllesmereUI.Widgets
    local _, h
    _, h = W:SectionHeader(parent, L["Appearance"], y); y = y - h

    local fontValues, fontOrder = ns.EUI:GetFontList()
    _, h = W:Dropdown(parent, L["Font"], y, fontValues,
        function() return c.appearance.font or "" end,
        function(v) c.appearance.font = (v ~= "" and v) or nil; ns.Events:Fire(MSG.FONT_CHANGED) end,
        fontOrder); y = y - h
    _, h = W:Slider(parent, L["Font Size"], y, 6, 30, 1,
        function() return c.appearance.fontSize end,
        function(v) c.appearance.fontSize = v; ns.Events:Fire(MSG.FONT_CHANGED) end); y = y - h
    _, h = W:Dropdown(parent, L["Font Outline"], y,
        { NONE = L["None"], OUTLINE = L["Outline"], THICKOUTLINE = L["Thick Outline"] },
        function() return c.appearance.fontOutline end,
        function(v) c.appearance.fontOutline = v; ns.Events:Fire(MSG.FONT_CHANGED) end,
        { "NONE", "OUTLINE", "THICKOUTLINE" }); y = y - h
    _, h = W:ColorPicker(parent, L["Text Color"], y,
        function() local t = c.appearance.textColor; return t[1], t[2], t[3], t[4] end,
        function(r, g, b, a) c.appearance.textColor = { r, g, b, a }; ns.Events:Fire(MSG.FONT_CHANGED) end,
        true); y = y - h

    _, h = W:SectionHeader(parent, L["Background Color"], y); y = y - h
    local texValues, texOrder = ns.EUI:GetStatusbarList()
    _, h = W:Dropdown(parent, L["Background Texture"], y, texValues,
        function() return c.appearance.bgTexture or "" end,
        function(v) c.appearance.bgTexture = (v ~= "" and v) or nil; ns.Events:Fire(MSG.APPEARANCE_CHANGED) end,
        texOrder); y = y - h
    _, h = W:ColorPicker(parent, L["Background Color"], y,
        function() local t = c.appearance.bgColor; return t[1], t[2], t[3], t[4] end,
        function(r, g, b, a) c.appearance.bgColor = { r, g, b, a }; ns.Events:Fire(MSG.APPEARANCE_CHANGED) end,
        true); y = y - h
    _, h = W:Toggle(parent, L["Border"], y,
        function() return c.appearance.border end,
        function(v) c.appearance.border = v; ns.Events:Fire(MSG.APPEARANCE_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Border Size"], y, 1, 6, 1,
        function() return c.appearance.borderSize end,
        function(v) c.appearance.borderSize = v; ns.Events:Fire(MSG.APPEARANCE_CHANGED) end); y = y - h
    _, h = W:ColorPicker(parent, L["Border Color"], y,
        function() local t = c.appearance.borderColor; return t[1], t[2], t[3], t[4] end,
        function(r, g, b, a) c.appearance.borderColor = { r, g, b, a }; ns.Events:Fire(MSG.APPEARANCE_CHANGED) end,
        true); y = y - h
    _, h = W:Toggle(parent, L["Shadow"], y,
        function() return c.appearance.shadow end,
        function(v) c.appearance.shadow = v; ns.Events:Fire(MSG.APPEARANCE_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Transparency"], y, 0, 1, 0.05,
        function() return c.appearance.alpha end,
        function(v) c.appearance.alpha = v; ns.Events:Fire(MSG.APPEARANCE_CHANGED); ns.Events:Fire(MSG.VISIBILITY_CHANGED) end); y = y - h

    _, h = W:SectionHeader(parent, L["Auto Hide"], y); y = y - h
    _, h = W:Toggle(parent, L["Mouseover Fade"], y,
        function() return c.appearance.mouseoverFade end,
        function(v) c.appearance.mouseoverFade = v; ns.Events:Fire(MSG.VISIBILITY_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Faded Alpha"], y, 0, 1, 0.05,
        function() return c.appearance.fadeAlpha end,
        function(v) c.appearance.fadeAlpha = v; ns.Events:Fire(MSG.VISIBILITY_CHANGED) end); y = y - h
    _, h = W:Toggle(parent, L["Auto Hide"], y,
        function() return c.appearance.autoHide end,
        function(v) c.appearance.autoHide = v; ns.Events:Fire(MSG.VISIBILITY_CHANGED) end); y = y - h
    return y
end

local function BuildBehavior(parent, y)
    y = BuildBarSelector(parent, y)
    local c, W = cfg(), EllesmereUI.Widgets
    local _, h
    _, h = W:SectionHeader(parent, L["Behavior"], y); y = y - h

    _, h = W:Slider(parent, L["Number of DataTexts"], y, 1, UI_SLOT_CAP, 1,
        function() return min(c.behavior.numSlots, UI_SLOT_CAP) end,
        function(v)
            c.behavior.numSlots = v
            for i = 1, v do c.behavior.slots[i] = c.behavior.slots[i] or "None" end
            ns.Events:Fire(MSG.SLOTS_CHANGED)
            ScheduleRebuild()
        end); y = y - h

    local values, order = ns.Registry:GetDropdownData()
    local n = min(c.behavior.numSlots or 1, UI_SLOT_CAP)
    for i = 1, n do
        local idx = i
        _, h = W:Dropdown(parent, L["DataText"] .. " " .. idx, y, values,
            function() return c.behavior.slots[idx] or "None" end,
            function(v) c.behavior.slots[idx] = v; ns.Events:Fire(MSG.SLOTS_CHANGED) end,
            order); y = y - h
    end

    _, h = W:Toggle(parent, L["Lock Position"], y,
        function() return c.behavior.lockPosition end,
        function(v) c.behavior.lockPosition = v end); y = y - h
    _, h = W:Toggle(parent, L["Snap"], y,
        function() return c.behavior.snap end,
        function(v) c.behavior.snap = v end); y = y - h
    return y
end

local function BuildAdvanced(parent, y)
    local W = EllesmereUI.Widgets
    local adv = ns.Cfg().advanced
    local _, h

    _, h = W:SectionHeader(parent, L["Profiles"], y); y = y - h
    local names = ns.DB:GetProfileNames()
    local pvals = {}
    for _, nm in ipairs(names) do pvals[nm] = nm end
    _, h = W:Dropdown(parent, L["Active Profile"], y, pvals,
        function() return ns.DB:GetActiveName() end,
        function(v) ns.Profiles:Switch(v) end,
        names); y = y - h
    _, h = W:Button(parent, L["New Profile"],    y, function() ns.Profiles:New() end);    y = y - h
    _, h = W:Button(parent, L["Copy Profile"],   y, function() ns.Profiles:Copy() end);   y = y - h
    _, h = W:Button(parent, L["Delete Profile"], y, function() ns.Profiles:Delete() end); y = y - h
    _, h = W:Button(parent, L["Reset Profile"],  y, function() ns.Profiles:ResetActive() end); y = y - h

    _, h = W:SectionHeader(parent, L["Import Profile"] .. " / " .. L["Export Profile"], y); y = y - h
    _, h = W:Button(parent, L["Export Profile"], y, function() ns.Profiles:Export() end); y = y - h
    _, h = W:Button(parent, L["Import Profile"], y, function() ns.Profiles:Import() end); y = y - h

    _, h = W:SectionHeader(parent, L["Advanced"], y); y = y - h
    _, h = W:Toggle(parent, L["Debug Mode"], y,
        function() return adv.debug end,
        function(v) adv.debug = v; ns.Debug.SetEnabled(v) end); y = y - h
    _, h = W:Button(parent, L["Reload UI"], y, function() ReloadUI() end); y = y - h
    return y
end

--------------------------------------------------------------------------------
--  Shared page dispatch (used by both the window and the EUI sidebar)
--------------------------------------------------------------------------------
Config.PAGES = { PAGE_LAYOUT, PAGE_APPEARANCE, PAGE_BEHAVIOR, PAGE_ADVANCED }

function Config.BuildPage(pageName, parent, yOffset)
    local y = yOffset or -6
    if pageName == PAGE_LAYOUT then
        y = BuildLayout(parent, y)
    elseif pageName == PAGE_APPEARANCE then
        y = BuildAppearance(parent, y)
    elseif pageName == PAGE_BEHAVIOR then
        y = BuildBehavior(parent, y)
    elseif pageName == PAGE_ADVANCED then
        y = BuildAdvanced(parent, y)
    end
    return abs(y) + 20
end

--------------------------------------------------------------------------------
--  EllesmereUI sidebar registration (bonus path; no-op unless whitelisted)
--------------------------------------------------------------------------------
function Config:Register()
    ns.EUI:RegisterConfigModule({
        title       = "DataBars",
        description = "ElvUI-style data texts, native to EllesmereUI.",
        pages       = Config.PAGES,
        buildPage   = function(pageName, parent, yOffset)
            return Config.BuildPage(pageName, parent, yOffset)
        end,
        onReset = function()
            ns.DB:ResetActive()
            if EllesmereUI.RefreshPage then EllesmereUI:RefreshPage(true) end
        end,
    })
end
