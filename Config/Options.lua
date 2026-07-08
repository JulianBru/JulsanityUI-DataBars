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
--------------------------------------------------------------------------------
local _, ns = ...
local Config = ns.Config
local L   = ns.L
local MSG = ns.MSG

local PAGE_LAYOUT     = "Layout"
local PAGE_APPEARANCE = "Appearance"
local PAGE_BEHAVIOR   = "Behavior"
local PAGE_ADVANCED   = "Advanced"
local PAGE_ABOUT      = "About"

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
    -- Cap the Width slider at the current screen width (UI units), so a bar can
    -- span the whole screen on any resolution / UI scale. Never below 1200.
    local WIDTH_MAX = math.max(1200, math.floor((UIParent and UIParent:GetWidth()) or 1200))
    _, h = W:SectionHeader(parent, L["Layout"], y); y = y - h
    _, h = W:Toggle(parent, L["Auto Size"], y,
        function() return c.layout.autoSize end,
        function(v) c.layout.autoSize = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Width"], y, 60, WIDTH_MAX, 1,
        function() return c.layout.width end,
        function(v) c.layout.width = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Width Offset"], y, -100, 300, 1,
        function() return c.layout.widthOffset or 0 end,
        function(v) c.layout.widthOffset = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end,
        "Added to the auto-size width (chat or minimap) to match a skin border."); y = y - h
    _, h = W:Slider(parent, L["Height"], y, 8, 80, 1,
        function() return c.layout.height end,
        function(v) c.layout.height = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Slider(parent, L["Padding"], y, 0, 15, 1,
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
    _, h = W:Toggle(parent, L["Use Custom Text Color"], y,
        function() return c.appearance.useCustomTextColor end,
        function(v)
            c.appearance.useCustomTextColor = v
            ns.Events:Fire(MSG.FONT_CHANGED); ns.Events:Fire(MSG.VALUES_CHANGED)
        end); y = y - h
    _, h = W:ColorPicker(parent, L["Text Color"], y,
        function() local t = c.appearance.textColor; return t[1], t[2], t[3], t[4] end,
        function(r, g, b, a)
            c.appearance.textColor = { r, g, b, a }
            c.appearance.useCustomTextColor = true
            ns.Events:Fire(MSG.FONT_CHANGED); ns.Events:Fire(MSG.VALUES_CHANGED)
        end, true); y = y - h

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

    _, h = W:SectionHeader(parent, L["Separators"], y); y = y - h
    _, h = W:Toggle(parent, L["Section Separators"], y,
        function() return c.appearance.showSeparators end,
        function(v) c.appearance.showSeparators = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:Toggle(parent, L["Separator Uses Accent"], y,
        function() return c.appearance.separatorUseAccent ~= false end,
        function(v) c.appearance.separatorUseAccent = v; ns.Events:Fire(MSG.LAYOUT_CHANGED) end); y = y - h
    _, h = W:ColorPicker(parent, L["Separator Color"], y,
        function() local t = c.appearance.separatorColor or { 0.5, 0.5, 0.5, 0.6 }; return t[1], t[2], t[3], t[4] end,
        function(r, g, b, a)
            c.appearance.separatorColor = { r, g, b, a }
            c.appearance.separatorUseAccent = false
            ns.Events:Fire(MSG.LAYOUT_CHANGED)
        end, true); y = y - h

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

-- Render one per-slot datatext option (toggle/dropdown/slider); returns height.
local function RenderSlotOption(c, idx, opt, parent, y)
    local W = EllesmereUI.Widgets
    local label = "   " .. (L[opt.label] or opt.label)
    local function getv()
        local so = c.behavior.slotOptions[idx]
        local v = so and so[opt.key]
        if v == nil then return opt.default end
        return v
    end
    local function setv(v)
        c.behavior.slotOptions[idx] = c.behavior.slotOptions[idx] or {}
        c.behavior.slotOptions[idx][opt.key] = v
        ns.Events:Fire(MSG.VALUES_CHANGED)
    end
    local _, hh = nil, 0
    if opt.type == "toggle" then
        _, hh = W:Toggle(parent, label, y, getv, setv)
    elseif opt.type == "dropdown" then
        local vals = {}
        for k, disp in pairs(opt.values) do vals[k] = L[disp] or disp end
        _, hh = W:Dropdown(parent, label, y, vals, getv, setv, opt.order)
    elseif opt.type == "slider" then
        _, hh = W:Slider(parent, label, y, opt.min or 0, opt.max or 100, opt.step or 1, getv, setv)
    end
    return hh or 0
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
    c.behavior.slotOptions = c.behavior.slotOptions or {}
    for i = 1, n do
        local idx = i
        _, h = W:Dropdown(parent, L["DataText"] .. " " .. idx, y, values,
            function() return c.behavior.slots[idx] or "None" end,
            function(v) c.behavior.slots[idx] = v; ns.Events:Fire(MSG.SLOTS_CHANGED); ScheduleRebuild() end,
            order); y = y - h

        -- Per-datatext options for the selected datatext, shown under its dropdown.
        local spec = ns.DataTexts[c.behavior.slots[idx]]
        if spec and spec.options then
            for _, opt in ipairs(spec.options) do
                y = y - RenderSlotOption(c, idx, opt, parent, y)
            end
        end
    end

    _, h = W:Toggle(parent, L["Lock Position"], y,
        function() return c.behavior.lockPosition end,
        function(v) c.behavior.lockPosition = v end); y = y - h
    _, h = W:Toggle(parent, L["Snap"], y,
        function() return c.behavior.snap end,
        function(v) c.behavior.snap = v end); y = y - h
    _, h = W:Toggle(parent, L["Hide Prefixes"], y,
        function() return c.appearance.hidePrefix end,
        function(v) c.appearance.hidePrefix = v; ns.Events:Fire(MSG.VALUES_CHANGED) end); y = y - h
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
--  About page (plugin disclaimer)
--------------------------------------------------------------------------------
local GITHUB_URL     = "https://github.com/JulianBru/JulsanityUI-DataBars/issues"
local CURSEFORGE_URL = "https://www.curseforge.com/wow/addons/julsanityui-databars/comments"

-- Chrome borders/hovers inherit EllesmereUI's accent (purple only as fallback),
-- matching the rest of the window. Only the "JulsanityUI" wordmark stays purple.
local function AccentRGB()
    if EllesmereUI and EllesmereUI.GetAccentColor then return EllesmereUI.GetAccentColor() end
    return 0.6784, 0.0, 1.0
end
local LINK_BTN_W, LINK_BTN_H = 170, 40

local function IconPath(name, sub)
    local base = "Interface\\AddOns\\" .. ns.FOLDER .. "\\Media\\Icons\\"
    if sub and sub ~= "" then base = base .. sub .. "\\" end
    return base .. name .. ".tga"
end

-- Changelog shown by the Changelog button (keep in sync with CHANGELOG.md).
local CHANGELOG_TEXT = table.concat({
    "|cffad00ffVersion 1.7|r",
    "- Customizable datatexts: each has its own options in the Behavior tab",
    "  (e.g. local/server clock, gold as 485K, FPS/MS only, and much more).",
    "- New 'Addons' datatext, plus addon memory in the System tooltip.",
    "- Live-updating tooltips for System and Addons (paused in combat).",
    "- Added French, Spanish, Italian and Portuguese (BR) translations.",
    "- The options window keeps its scroll position when changing a datatext.",
    "",
    "|cffad00ffVersion 1.6.1|r",
    "- Text Color now recolours the datatext values, incl. the good state of FPS,",
    "  durability and reputation (warning colours are kept).",
    "- Difficulty menu now also offers legacy raid difficulties (10/25-player).",
    "- Fixed Padding squeezing fields until they disappeared; now always readable.",
    "- Section separators stay visible at any Padding value.",
    "- Long values (like long spec names) now truncate instead of overlapping.",
    "",
    "|cffad00ffVersion 1.6|r",
    "- New About tab: makes clear this is an independent plugin for EllesmereUI,",
    "  with CurseForge, GitHub and this Changelog.",
    "- Optional separator lines between datatexts (accent or custom colour).",
    "- New 'Hide Prefixes' option to show just the value (no 'Dur', 'ilvl', ...).",
    "- Unlock Mode button in the options header.",
    "- The main bar width can now span the whole screen.",
    "- New default layout and clearer Friends / Guild labels.",
    "- Own icon and branding colour so it no longer looks like part of the suite.",
    "- Fixed the accent colour being wrong right after login.",
    "",
    "|cffad00ffVersion 1.5|r",
    "- Added an entry under Options > AddOns with a button that opens the config.",
    "- The Blizzard Settings window now closes automatically when the config opens.",
    "- Added a bundled license file.",
    "",
    "|cffad00ffVersion 1.4|r",
    "- New option to use a background texture instead of a plain colour.",
    "",
    "|cffad00ffVersion 1.3|r",
    "- Added a second, fully independent bar that docks beneath the minimap.",
    "- Every bar now has its own layout, appearance, slots and position.",
    "",
    "|cffad00ffVersion 1.2|r",
    "- The Gold tooltip now lists every character's gold, grouped by faction.",
    "- Reads from Syndicator when installed, with EllesmereUI Bags as a fallback.",
    "- Fixed the Warband bank balance showing a wrong or missing value.",
    "",
    "|cffad00ffVersion 1.1|r",
    "- Added the Difficulty and Loot Spec datatexts.",
    "- Right-click the Specialization datatext to set your loot specialization.",
    "- Fixed tooltips overlapping menus and the durability value not loading on login.",
    "",
    "|cffad00ffVersion 1.0|r",
    "- First release: configurable, ElvUI-style datatexts, native to EllesmereUI.",
}, "\n")

-- Wrapped paragraph (the widget factory has no plain-text widget). Places a
-- FontString at the current y-cursor and returns the height consumed.
local function AboutText(parent, y, text, r, g, b, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ns.EUI:ResolveFont(nil), size or 13, "")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetTextColor(r or 0.82, g or 0.82, b or 0.82, 1)
    local w = (parent:GetWidth() or 680) - 48
    if w < 60 then w = 400 end
    fs:SetWidth(w)
    fs:SetText(text)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
    return (fs:GetStringHeight() or 16) + 14
end

-- A clean, self-contained "copy this link" popup (an EditBox the user can
-- Ctrl+C). Deliberately NOT the profile export popup, to avoid confusion.
local linkPopup
local function ShowLinkPopup(url)
    if not linkPopup then
        local ar, ag, ab = AccentRGB()
        local f = CreateFrame("Frame", "JulsanityDataBarLinkPopup", UIParent)
        f:SetSize(460, 130)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function() f:StartMoving() end)
        f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0.05, 0.07, 0.09, 0.98)
        if EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.CreateBorder then
            EllesmereUI.PP.CreateBorder(f, ar, ag, ab, 0.7, 1, "OVERLAY", 7)
        end

        local title = f:CreateFontString(nil, "OVERLAY")
        title:SetFont(ns.EUI:ResolveFont(nil), 14, "")
        title:SetPoint("TOP", f, "TOP", 0, -16)
        title:SetText(ns.L["Copy the link (Ctrl+C), then close."])
        title:SetTextColor(0.9, 0.9, 0.9, 1)

        local ebbg = f:CreateTexture(nil, "BACKGROUND")
        ebbg:SetColorTexture(0, 0, 0, 0.5)
        ebbg:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -48)
        ebbg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -48)
        ebbg:SetHeight(28)

        local eb = CreateFrame("EditBox", nil, f)
        eb:SetFontObject(ChatFontNormal)
        eb:SetPoint("TOPLEFT", ebbg, "TOPLEFT", 6, -5)
        eb:SetPoint("BOTTOMRIGHT", ebbg, "BOTTOMRIGHT", -6, 5)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed", function() f:Hide() end)
        eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        f.eb = eb

        local close = CreateFrame("Button", nil, f)
        close:SetSize(120, 26)
        close:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
        local cbg = close:CreateTexture(nil, "BACKGROUND")
        cbg:SetAllPoints(); cbg:SetColorTexture(0.11, 0.13, 0.15, 0.95)
        if EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.CreateBorder then
            EllesmereUI.PP.CreateBorder(close, ar, ag, ab, 0.35, 1, "OVERLAY", 7)
        end
        local clbl = close:CreateFontString(nil, "OVERLAY")
        clbl:SetFont(ns.EUI:ResolveFont(nil), 13, "")
        clbl:SetPoint("CENTER")
        clbl:SetText(CLOSE or "Close")
        clbl:SetTextColor(0.85, 0.85, 0.85, 1)
        close:SetScript("OnEnter", function()
            cbg:SetColorTexture(ar * 0.35, ag * 0.35, ab * 0.35, 0.95)
            clbl:SetTextColor(1, 1, 1, 1)
        end)
        close:SetScript("OnLeave", function()
            cbg:SetColorTexture(0.11, 0.13, 0.15, 0.95)
            clbl:SetTextColor(0.85, 0.85, 0.85, 1)
        end)
        close:SetScript("OnClick", function() f:Hide() end)

        if UISpecialFrames then tinsert(UISpecialFrames, "JulsanityDataBarLinkPopup") end
        linkPopup = f
    end
    linkPopup.eb:SetText(url)
    linkPopup.eb:SetCursorPosition(0)
    linkPopup:Show()
    linkPopup.eb:SetFocus()
    linkPopup.eb:HighlightText()
end

-- Scrollable in-game changelog viewer (EllesmereUI-styled).
local changelogPopup
local function ShowChangelogPopup()
    if not changelogPopup then
        local ar, ag, ab = AccentRGB()
        local f = CreateFrame("Frame", "JulsanityDataBarChangelog", UIParent)
        f:SetSize(540, 460)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function() f:StartMoving() end)
        f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0.05, 0.07, 0.09, 0.98)
        if EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.CreateBorder then
            EllesmereUI.PP.CreateBorder(f, ar, ag, ab, 0.7, 1, "OVERLAY", 7)
        end

        local title = f:CreateFontString(nil, "OVERLAY")
        title:SetFont(ns.EUI:ResolveFont(nil), 16, "")
        title:SetPoint("TOP", f, "TOP", 0, -16)
        title:SetText(ns.L["Changelog"])
        title:SetTextColor(1, 1, 1, 1)

        local scroll = CreateFrame("ScrollFrame", nil, f)
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -48)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 54)
        scroll:EnableMouseWheel(true)
        scroll:SetClipsChildren(true)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(504, 10)
        scroll:SetScrollChild(child)

        local fs = child:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ns.EUI:ResolveFont(nil), 13, "")
        fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
        fs:SetSpacing(4)
        fs:SetWidth(496)
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", 4, -4)
        fs:SetText(CHANGELOG_TEXT)
        fs:SetTextColor(0.82, 0.82, 0.82, 1)
        child:SetHeight((fs:GetStringHeight() or 100) + 16)

        scroll:SetScript("OnMouseWheel", function(sf, delta)
            local maxs = sf:GetVerticalScrollRange() or 0
            local cur = sf:GetVerticalScroll() or 0
            local nv = cur - delta * 40
            if nv < 0 then nv = 0 elseif nv > maxs then nv = maxs end
            sf:SetVerticalScroll(nv)
        end)

        local close = CreateFrame("Button", nil, f)
        close:SetSize(120, 26)
        close:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
        local cbg = close:CreateTexture(nil, "BACKGROUND")
        cbg:SetAllPoints(); cbg:SetColorTexture(0.11, 0.13, 0.15, 0.95)
        if EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.CreateBorder then
            EllesmereUI.PP.CreateBorder(close, ar, ag, ab, 0.35, 1, "OVERLAY", 7)
        end
        local clbl = close:CreateFontString(nil, "OVERLAY")
        clbl:SetFont(ns.EUI:ResolveFont(nil), 13, "")
        clbl:SetPoint("CENTER"); clbl:SetText(CLOSE or "Close")
        clbl:SetTextColor(0.85, 0.85, 0.85, 1)
        close:SetScript("OnEnter", function() cbg:SetColorTexture(ar * 0.35, ag * 0.35, ab * 0.35, 0.95); clbl:SetTextColor(1, 1, 1, 1) end)
        close:SetScript("OnLeave", function() cbg:SetColorTexture(0.11, 0.13, 0.15, 0.95); clbl:SetTextColor(0.85, 0.85, 0.85, 1) end)
        close:SetScript("OnClick", function() f:Hide() end)

        if UISpecialFrames then tinsert(UISpecialFrames, "JulsanityDataBarChangelog") end
        changelogPopup = f
    end
    changelogPopup:Show()
end

-- A styled icon + label button. `onClick` runs when pressed.
local function LinkButton(parent, x, y, iconPath, label, onClick)
    local ar, ag, ab = AccentRGB()
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(LINK_BTN_W, LINK_BTN_H)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local bbg = btn:CreateTexture(nil, "BACKGROUND")
    bbg:SetAllPoints(); bbg:SetColorTexture(0.11, 0.13, 0.15, 0.9)
    if EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.CreateBorder then
        EllesmereUI.PP.CreateBorder(btn, ar, ag, ab, 0.35, 1, "OVERLAY", 7)
    end

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", btn, "LEFT", 12, 0)
    icon:SetTexture(iconPath)

    local txt = btn:CreateFontString(nil, "OVERLAY")
    txt:SetFont(ns.EUI:ResolveFont(nil), 13, "")
    txt:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    txt:SetText(label)
    txt:SetTextColor(0.85, 0.85, 0.85, 1)

    btn:SetScript("OnEnter", function()
        bbg:SetColorTexture(ar * 0.35, ag * 0.35, ab * 0.35, 0.9)
        txt:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        bbg:SetColorTexture(0.11, 0.13, 0.15, 0.9)
        txt:SetTextColor(0.85, 0.85, 0.85, 1)
    end)
    btn:SetScript("OnClick", function() if onClick then onClick() end end)
    return btn
end

local function BuildAbout(parent, y)
    -- Prominent page title (bigger than a section header).
    y = y - AboutText(parent, y, L["About"], 1, 1, 1, 22)
    y = y - 2

    y = y - AboutText(parent, y, L["JulsanityUI DataBars is an independent, third-party plugin for EllesmereUI."], 1, 1, 1)
    y = y - AboutText(parent, y, L["It is not part of EllesmereUI and is not created, maintained, or endorsed by the EllesmereUI team."])
    y = y - AboutText(parent, y, L["Please do not request support for this addon in the EllesmereUI Discord."], 1, 0.5, 0.5)
    y = y - AboutText(parent, y, L["For bugs or feature requests, use this addon's own GitHub or CurseForge page."])

    -- Two support buttons side by side (icon + label -> copy-link popup).
    y = y - 6
    local gap = 14
    LinkButton(parent, 24, y, IconPath("curseforge", "Links"), "CurseForge",
        function() ShowLinkPopup(CURSEFORGE_URL) end)
    LinkButton(parent, 24 + (LINK_BTN_W + gap), y, IconPath("github", "Links"), "GitHub",
        function() ShowLinkPopup(GITHUB_URL) end)
    LinkButton(parent, 24 + 2 * (LINK_BTN_W + gap), y, IconPath("info"), "Changelog",
        ShowChangelogPopup)
    y = y - (LINK_BTN_H + 16)

    y = y - AboutText(parent, y, ("Version %s   -   Author: Julsanity"):format(ns.VERSION or "?"), 0.55, 0.55, 0.55, 12)
    return y
end

--------------------------------------------------------------------------------
--  Shared page dispatch (used by the standalone options window)
--------------------------------------------------------------------------------
Config.PAGES = { PAGE_LAYOUT, PAGE_APPEARANCE, PAGE_BEHAVIOR, PAGE_ADVANCED, PAGE_ABOUT }

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
    elseif pageName == PAGE_ABOUT then
        y = BuildAbout(parent, y)
    end
    return abs(y) + 20
end
