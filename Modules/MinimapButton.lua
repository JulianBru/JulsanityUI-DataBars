--------------------------------------------------------------------------------
--  Modules/MinimapButton.lua  -  Minimap button via LibDBIcon + LDB launcher
--
--  Registers a LibDataBroker "launcher" object and hands it to LibDBIcon-1.0,
--  which manages the minimap icon (creation, dragging, radial positioning,
--  addon-compartment entry, minimap-shape handling). Clicking the icon opens
--  the standalone config window.
--
--  The button's state lives account-wide in ns.General().minimap
--  (LibDBIcon reads db.hide / db.minimapPos / db.lock directly), so the icon
--  keeps the same position on every character. The General-tab toggle flips
--  db.hide and calls MB:ApplyShown().
--------------------------------------------------------------------------------
local _, ns = ...
local MB = ns.MinimapButton or {}
ns.MinimapButton = MB

local L        = ns.L
local LDB_NAME = "JulsanityUI DataBars"

local function LDB()  return LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true) end
local function Icon() return LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true) end

local function OpenConfig()
    if ns.Window and ns.Window.Toggle then ns.Window:Toggle() end
end

--------------------------------------------------------------------------------
--  LibDataBroker launcher object (also usable by Titan Panel / ChocolateBar).
--  Created lazily so it exists exactly once.
--------------------------------------------------------------------------------
local function EnsureDataObject()
    local ldb = LDB()
    if not ldb then return nil end
    local obj = ldb:GetDataObjectByName(LDB_NAME)
    if obj then return obj end
    return ldb:NewDataObject(LDB_NAME, {
        type  = "launcher",
        icon  = "Interface\\AddOns\\JulsanityUI_DataBars\\Media\\JulsanityUI.tga",
        label = "JulsanityUI DataBars",
        OnClick = function(_, _) OpenConfig() end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffad00ffJulsanityUI|r DataBars")
            tt:AddLine(L["Left-click: open configuration"], 1, 1, 1)
            tt:AddLine(L["Drag to reposition."], 0.6, 0.6, 0.6)
        end,
    })
end

--------------------------------------------------------------------------------
--  Registration (called at PLAYER_LOGIN, after the database is ready)
--------------------------------------------------------------------------------
function MB:Create()
    local icon = Icon()
    if not icon then return end               -- LibDBIcon missing (should not happen)
    local obj = EnsureDataObject()
    if not obj then return end                -- LibDataBroker missing

    local g = ns.General and ns.General()
    local db = g and g.minimap
    if not db then return end

    if not icon:IsRegistered(LDB_NAME) then
        icon:Register(LDB_NAME, obj, db)
    else
        icon:Refresh(LDB_NAME, db)
    end
    self.registered = true
end

-- Show/hide per the account-wide setting (General-tab toggle wrote db.hide).
function MB:ApplyShown()
    local icon = Icon()
    if not icon or not icon:IsRegistered(LDB_NAME) then return end
    local g = ns.General and ns.General()
    local hidden = g and g.minimap and g.minimap.hide
    if hidden then icon:Hide(LDB_NAME) else icon:Show(LDB_NAME) end
end
