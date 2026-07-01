--------------------------------------------------------------------------------
--  Modules/Renderer.lua  -  Applies appearance + text styling to a bar/slots
--
--  Pure presentation. Reads a bar's `appearance` block and pushes it onto the
--  structural frame/textures created by Bar.lua. Borders use EllesmereUI's
--  pixel-perfect multiplier (PP.mult) so 1px stays 1px at any UI scale. Every
--  function takes the bar instance it operates on.
--------------------------------------------------------------------------------
local _, ns = ...
local Renderer = ns.Renderer
local max = math.max

local function PixelMult()
    local PP = EllesmereUI and (EllesmereUI.PanelPP or EllesmereUI.PP)
    return (PP and PP.mult) or 1
end

local function unpackColor(c, dr, dg, db, da)
    if type(c) == "table" then
        return c[1] or dr, c[2] or dg, c[3] or db, c[4] or da or 1
    end
    return dr, dg, db, da or 1
end

--------------------------------------------------------------------------------
--  Background / border / shadow
--------------------------------------------------------------------------------
function Renderer:ApplyAppearance(bar)
    local f = bar and bar.frame
    if not f then return end
    local A = ns.BarCfg(bar.index).appearance
    local mult = PixelMult()

    -- Background: a LibSharedMedia statusbar texture tinted by bgColor, or a
    -- solid colour when no texture is selected.
    local br, bgc, bb, ba = unpackColor(A.bgColor, 0.03, 0.045, 0.05, 0.9)
    local texPath = ns.EUI:ResolveStatusbar(A.bgTexture)
    if texPath then
        f.bg:SetTexture(texPath)
        f.bg:SetVertexColor(br, bgc, bb, ba)
    else
        f.bg:SetColorTexture(br, bgc, bb, ba)
    end
    f:SetAlpha(A.alpha or 1)

    local b = f.border
    if A.border then
        local size = max(A.borderSize or 1, 1) * mult
        local br, bg, bb, ba = unpackColor(A.borderColor, 0, 0, 0, 1)
        for _, tex in pairs(b) do tex:SetColorTexture(br, bg, bb, ba); tex:Show() end

        b.top:ClearAllPoints()
        b.top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        b.top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        b.top:SetHeight(size)

        b.bottom:ClearAllPoints()
        b.bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        b.bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        b.bottom:SetHeight(size)

        b.left:ClearAllPoints()
        b.left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        b.left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        b.left:SetWidth(size)

        b.right:ClearAllPoints()
        b.right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        b.right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        b.right:SetWidth(size)
    else
        for _, tex in pairs(b) do tex:Hide() end
    end

    local s = f.shadow
    if A.shadow then
        local sw = 1 * mult
        for _, tex in pairs(s) do tex:SetColorTexture(0, 0, 0, 0.5); tex:Show() end

        s.top:ClearAllPoints()
        s.top:SetPoint("BOTTOMLEFT", f, "TOPLEFT", -sw, 0)
        s.top:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", sw, 0)
        s.top:SetHeight(sw)

        s.bottom:ClearAllPoints()
        s.bottom:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -sw, 0)
        s.bottom:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", sw, 0)
        s.bottom:SetHeight(sw)

        s.left:ClearAllPoints()
        s.left:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, 0)
        s.left:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", 0, 0)
        s.left:SetWidth(sw)

        s.right:ClearAllPoints()
        s.right:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, 0)
        s.right:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 0, 0)
        s.right:SetWidth(sw)
    else
        for _, tex in pairs(s) do tex:Hide() end
    end
end

--------------------------------------------------------------------------------
--  Text styling
--------------------------------------------------------------------------------
function Renderer:ApplyText(bar, slot)
    if not slot or not slot.text then return end
    local A = ns.BarCfg(bar.index).appearance
    local fontPath = ns.EUI:ResolveFont(A.font)
    local outline  = (A.fontOutline and A.fontOutline ~= "NONE") and A.fontOutline or ""
    slot.text:SetFont(fontPath, A.fontSize or 12, outline)

    local r, g, b, a = unpackColor(A.textColor, 1, 1, 1, 0.9)
    slot.text:SetTextColor(r, g, b, a)
    slot._baseColor = { r, g, b, a }
end

function Renderer:UpdateFonts(bar)
    local c = ns.BarCfg(bar.index)
    local n = c.behavior.numSlots or 1
    for i = 1, n do
        local slot = ns.Slot.Get(bar, i)
        if slot then self:ApplyText(bar, slot) end
    end
    ns.Bar.Layout(bar)
end

function Renderer:UpdateAll(bar)
    self:ApplyAppearance(bar)
    self:UpdateFonts(bar)
end
