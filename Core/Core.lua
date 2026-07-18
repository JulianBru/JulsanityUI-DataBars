--------------------------------------------------------------------------------
--  Core/Core.lua  -  Lifecycle boot + slash commands
--
--  Loaded last. OnInitialize (ADDON_LOADED) inits the database; OnEnable
--  (PLAYER_LOGIN) builds every bar, registers anchors and draws everything.
--  /jdbar opens the standalone options window (no EllesmereUI patch required).
--------------------------------------------------------------------------------
local _, ns = ...
local addon = ns.addon
local D = ns.Debug

function addon:OnInitialize()
    ns.DB:Initialize()
end

function addon:OnEnable()
    ns.Bar:BuildAll()
    ns.Anchor:Register()
    ns.Bar:ForEach(function(bar)
        ns.Anchor:ApplyPosition(bar)
        ns.Bar.UpdateSlots(bar)
        ns.Renderer:UpdateAll(bar)
        ns.Bar.Layout(bar)
        ns.Visibility:ApplyOne(bar)
    end)
    if ns.Window and ns.Window.RegisterCategory then ns.Window:RegisterCategory() end  -- Blizzard Options > AddOns
    if ns.MinimapButton and ns.MinimapButton.Create then ns.MinimapButton:Create() end  -- minimap icon + LDB launcher
    if ns.EUI.HookAccent then ns.EUI:HookAccent() end   -- re-render when EllesmereUI applies its accent

    -- Safety net: EllesmereUI often applies the saved accent a moment after
    -- login; force one re-render shortly after so colours are correct even if
    -- the accent callback did not fire.
    C_Timer.After(1, function()
        if ns.Events and ns.MSG then ns.Events:Fire(ns.MSG.ACCENT_CHANGED) end
    end)

    D.Log("enabled - %d bars, %d datatexts available", ns.NUM_BARS or #ns.Bars, ns.Registry:Count())
end

local function ShowHelp()
    ns.Print("commands:")
    ns.Print("  |cffffffff/jdbar config|r - open the options window")
    ns.Print("  |cffffffff/jdbar reset|r - reset all bar positions to default")
    ns.Print("  |cffffffff/jdbar debug|r - toggle debug mode")
    ns.Print("  |cffffffff/jdbar debug dump|r - print the recent debug log")
end

local function Handler(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")

    if cmd == "" or cmd == "config" or cmd == "options" then
        if ns.Window then ns.Window:Toggle() end
    elseif cmd == "help" then
        ShowHelp()
    elseif cmd == "reset" then
        ns.Bar:ForEach(function(bar) ns.Anchor:Reset(bar) end)
        ns.Print("all bar positions reset to default.")
    elseif cmd == "debug" then
        if rest == "dump" then
            D.Dump()
        else
            local cfg = ns.Cfg()
            cfg.advanced.debug = not cfg.advanced.debug
            D.SetEnabled(cfg.advanced.debug)
            ns.Print("debug mode " .. (cfg.advanced.debug and "|cff00ff00on|r" or "|cffff0000off|r"))
        end
    else
        ShowHelp()
    end
end

SLASH_JDBAR1 = "/jdbar"
SLASH_JDBAR2 = "/julsanitydatabars"
SlashCmdList["JDBAR"] = Handler
