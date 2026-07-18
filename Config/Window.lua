--------------------------------------------------------------------------------
--  Config/Window.lua  -  Standalone configuration window
--
--  A self-owned options window so end users do NOT need to patch EllesmereUI.
--  It is still styled natively: it uses EllesmereUI's public widget toolkit
--  (EllesmereUI.Widgets) for every control, EllesmereUI's accent colour, font
--  and pixel-perfect border. Tabs reuse the shared page builders exposed by
--  Config/Options.lua (ns.Config.PAGES / ns.Config.BuildPage), so the window
--  and the (optional) EllesmereUI sidebar entry render identical pages.
--------------------------------------------------------------------------------
local _, ns = ...
local Window = ns.Window or {}
ns.Window = Window

local PANEL_W, PANEL_H = 720, 620
local TAB_TOP   = -52      -- y of the tab row
local CONTENT_TOP = -88    -- y where the scroll area starts

local function Accent()
    -- Window chrome (border, tab underline, buttons) inherits EllesmereUI's
    -- accent. Only the "JulsanityUI" wordmark uses the brand purple (#AD00FF),
    -- which is set directly on the title FontStrings.
    if EllesmereUI and EllesmereUI.GetAccentColor then return EllesmereUI.GetAccentColor() end
    return 0.6784, 0.0, 1.0
end
local function FontPath()
    return (EllesmereUI and EllesmereUI.GetFontPath and EllesmereUI.GetFontPath("options"))
        or "Fonts\\FRIZQT__.TTF"
end

local function ClearChildren(frame)
    for _, c in ipairs({ frame:GetChildren() }) do c:Hide(); c:SetParent(nil) end
    for _, r in ipairs({ frame:GetRegions() }) do r:Hide(); r:SetParent(nil) end
end

--------------------------------------------------------------------------------
--  Tab bar
--------------------------------------------------------------------------------
local function UpdateTabHighlight(self)
    local ar, ag, ab = Accent()
    for _, btn in ipairs(self.tabs) do
        if btn._page == self.activeTab then
            btn.label:SetTextColor(1, 1, 1, 1)
            btn.underline:Show()
        else
            btn.label:SetTextColor(0.7, 0.7, 0.7, 1)
            btn.underline:Hide()
        end
        btn.underline:SetColorTexture(ar, ag, ab, 1)
    end
end

local function BuildTabs(self)
    self.tabs = {}
    local x = 16
    for _, page in ipairs(ns.Config.PAGES) do
        local btn = CreateFrame("Button", nil, self.frame)
        btn:SetHeight(28)
        btn._page = page
        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(FontPath(), 14, "")
        label:SetText(ns.L[page])
        label:SetPoint("CENTER")
        btn.label = label
        local tw = label:GetStringWidth() or 60
        btn:SetWidth(tw + 24)
        btn:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, TAB_TOP)
        x = x + tw + 30

        local underline = btn:CreateTexture(nil, "ARTWORK")
        underline:SetHeight(2)
        underline:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 0)
        underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        underline:Hide()
        btn.underline = underline

        btn:SetScript("OnEnter", function() if btn._page ~= self.activeTab then label:SetTextColor(1, 1, 1, 0.9) end end)
        btn:SetScript("OnLeave", function() if btn._page ~= self.activeTab then label:SetTextColor(0.7, 0.7, 0.7, 1) end end)
        btn:SetScript("OnClick", function()
            self.activeTab = btn._page
            UpdateTabHighlight(self)
            self:BuildContent()
        end)
        self.tabs[#self.tabs + 1] = btn
    end
end

--------------------------------------------------------------------------------
--  Construction
--------------------------------------------------------------------------------
function Window:Build()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "JulsanityDataBarConfig", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:Hide()
    self.frame = f
    self:ApplyScale()

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.07, 0.09, 0.97)

    -- Pixel-perfect accent border (EllesmereUI), with a plain fallback.
    local ar, ag, ab = Accent()
    if EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.CreateBorder then
        EllesmereUI.PP.CreateBorder(f, ar, ag, ab, 0.6, 1, "OVERLAY", 7)
    end

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(FontPath(), 18, "")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
    title:SetText("|cffad00ffJulsanityUI|r DataBars")

    -- Close button
    local close = CreateFrame("Button", nil, f)
    close:SetSize(26, 26)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
    local x = close:CreateFontString(nil, "OVERLAY")
    x:SetFont(FontPath(), 18, "")
    x:SetText("x"); x:SetPoint("CENTER"); x:SetTextColor(0.7, 0.7, 0.7, 1)
    close:SetScript("OnEnter", function() x:SetTextColor(1, 1, 1, 1) end)
    close:SetScript("OnLeave", function() x:SetTextColor(0.7, 0.7, 0.7, 1) end)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Unlock-mode button (EllesmereUI-styled): closes this window and opens
    -- EllesmereUI Unlock/Edit mode so the user can drag the bars. Hidden if
    -- EllesmereUI exposes no unlock toggle.
    local uar, uag, uab = Accent()
    local unlock = CreateFrame("Button", nil, f)
    unlock:SetHeight(24)

    local ubg = unlock:CreateTexture(nil, "BACKGROUND")
    ubg:SetAllPoints()
    ubg:SetColorTexture(0.11, 0.13, 0.15, 0.9)

    if EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.CreateBorder then
        EllesmereUI.PP.CreateBorder(unlock, uar, uag, uab, 0.35, 1, "OVERLAY", 7)
    end

    local ul = unlock:CreateFontString(nil, "OVERLAY")
    ul:SetFont(FontPath(), 12, "")
    ul:SetText(ns.L["Unlock Mode"])
    ul:SetPoint("CENTER")
    ul:SetTextColor(0.85, 0.85, 0.85, 1)

    unlock:SetWidth((ul:GetStringWidth() or 90) + 22)
    unlock:SetPoint("RIGHT", close, "LEFT", -12, 0)

    unlock:SetScript("OnEnter", function()
        ubg:SetColorTexture(uar * 0.35, uag * 0.35, uab * 0.35, 0.9)
        ul:SetTextColor(1, 1, 1, 1)
    end)
    unlock:SetScript("OnLeave", function()
        ubg:SetColorTexture(0.11, 0.13, 0.15, 0.9)
        ul:SetTextColor(0.85, 0.85, 0.85, 1)
    end)
    unlock:SetScript("OnClick", function()
        f:Hide()
        ns.EUI:OpenUnlock()
    end)
    if not ns.EUI:IsUnlockAvailable() then unlock:Hide() end

    -- Divider under header
    local div = f:CreateTexture(nil, "ARTWORK")
    div:SetColorTexture(1, 1, 1, 0.08)
    div:SetHeight(1)
    div:SetPoint("TOPLEFT", f, "TOPLEFT", 8, TAB_TOP - 30)
    div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, TAB_TOP - 30)

    -- Scroll area
    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 8, CONTENT_TOP)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 12)
    scroll:EnableMouseWheel(true)
    scroll:SetClipsChildren(true)
    self.scroll = scroll

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(PANEL_W - 18, 10)
    scroll:SetScrollChild(child)
    self.child = child

    scroll:SetScript("OnMouseWheel", function(s, delta)
        local maxs = s:GetVerticalScrollRange() or 0
        local cur = s:GetVerticalScroll() or 0
        local nv = cur - delta * 45
        if nv < 0 then nv = 0 elseif nv > maxs then nv = maxs end
        s:SetVerticalScroll(nv)
    end)

    BuildTabs(self)
    self.activeTab = ns.Config.PAGES[1]

    -- Close with Escape.
    tinsert(UISpecialFrames, "JulsanityDataBarConfig")

    return f
end

--------------------------------------------------------------------------------
--  Scale (config window only)
--------------------------------------------------------------------------------
function Window:ApplyScale()
    if not self.frame then return end
    local g = ns.General and ns.General()
    self.frame:SetScale((g and g.windowScale) or 1.0)
end

--------------------------------------------------------------------------------
--  Content
--------------------------------------------------------------------------------
function Window:BuildContent(keepScroll)
    if not self.child then return end
    -- Remember the scroll offset for in-place rebuilds (e.g. after changing a
    -- datatext), so the page doesn't jump back to the top.
    local saved = keepScroll and (self.scroll:GetVerticalScroll() or 0) or 0
    ClearChildren(self.child)
    if EllesmereUI and EllesmereUI.ResetRowCounters then EllesmereUI.ResetRowCounters() end
    self.child:SetWidth(self.scroll:GetWidth())
    local totalH = ns.Config.BuildPage(self.activeTab, self.child, -6)
    self.child:SetHeight(totalH)

    local function apply()
        local maxs = self.scroll:GetVerticalScrollRange() or 0
        self.scroll:SetVerticalScroll(math.min(saved, maxs))
    end
    apply()
    -- The scroll range can lag one frame after the child resizes; re-clamp then.
    if keepScroll then C_Timer.After(0, apply) end
end

function Window:RebuildCurrent()
    if self.frame and self.frame:IsShown() then self:BuildContent(true) end
end

function Window:IsShown()
    return self.frame and self.frame:IsShown()
end

--------------------------------------------------------------------------------
--  Toggle
--------------------------------------------------------------------------------
function Window:Toggle()
    -- EllesmereUI's widget toolkit lives in a deferred file; make sure it loaded.
    if EllesmereUI and EllesmereUI.EnsureLoaded then EllesmereUI:EnsureLoaded() end
    if not (EllesmereUI and EllesmereUI.Widgets) then
        ns.Print("EllesmereUI widgets unavailable; cannot open options.")
        return
    end
    self:Build()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        -- Close the Blizzard Settings window (if open, e.g. opened from the
        -- Options > AddOns button) so our window isn't stacked behind it.
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        self:ApplyScale()
        UpdateTabHighlight(self)
        self:BuildContent()
        self.frame:Show()
    end
end

--------------------------------------------------------------------------------
--  Blizzard Options -> AddOns registration
--
--  Registers a canvas panel under the game's Settings > AddOns list with a
--  centered button that opens our standalone options window. This is purely an
--  additional entry point; the /jdbar slash command still works.
--------------------------------------------------------------------------------
function Window:RegisterCategory()
    if self._category then return end
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end

    local panel = CreateFrame("Frame", "JulsanityDataBarOptionsPanel")
    panel.name = "JulsanityUI DataBars"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -40)
    title:SetText("|cffad00ffJulsanityUI|r DataBars")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -8)
    sub:SetWidth(500)
    sub:SetText(ns.L["ElvUI-style configurable data texts, native to EllesmereUI."])

    -- Centered button that opens the standalone options window.
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(260, 32)
    btn:SetPoint("CENTER", panel, "CENTER", 0, 0)
    btn:SetText(ns.L["Open Configuration"])
    btn:SetScript("OnClick", function() ns.Window:Toggle() end)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOP", btn, "BOTTOM", 0, -12)
    hint:SetText("|cff808080/jdbar|r")

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    category.ID = panel.name
    Settings.RegisterAddOnCategory(category)

    self._category = category
    self._categoryPanel = panel
end
