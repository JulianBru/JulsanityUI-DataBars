--------------------------------------------------------------------------------
--  DataTexts/DT_System.lua  -  System / world category
--    Time - Coordinates - System (FPS+Latency) - Durability
--------------------------------------------------------------------------------
local _, ns = ...
local U      = ns.Util
local Engine = ns.Engine
local Reg    = ns.RegisterDataText

local floor, max = math.floor, math.max
local format = string.format

local function AccentHex() return U.RGBToHex(ns.EUI:GetAccent()) end

-- Threshold colour: good (accent) / warn (amber) / bad (red), returned as hex.
local function StatusHex(slot, value, goodAt, warnAt, invert)
    local warn, bad = "ffc800", "ff4719"
    -- The "good" tier uses the datatext value colour (custom text colour when the
    -- bar enables it, otherwise the EllesmereUI accent). Warn/bad stay as the
    -- yellow/red warning colours so low FPS / low durability still stand out.
    local good = ns.ValueHex(slot)
    local ok
    if invert then ok = value <= goodAt else ok = value >= goodAt end
    if ok then return good end
    local mid
    if invert then mid = value <= warnAt else mid = value >= warnAt end
    if mid then return warn end
    return bad
end

--------------------------------------------------------------------------------
--  Time  -  server clock; tooltip: local time + daily/weekly resets
--------------------------------------------------------------------------------
Reg({
    name = "Time", label = "Time", category = "System", interval = 2,
    update = function(slot)
        local h, m = GetGameTime()
        slot.text:SetFormattedText("|cff%s%d:%02d|r", ns.ValueHex(slot), h, m)
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Time", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local sh, sm = GetGameTime()
        GameTooltip:AddDoubleLine("Server", format("%d:%02d", sh, sm), 1, 1, 1, 1, 1, 1)
        local lt = date("*t")
        GameTooltip:AddDoubleLine("Local", format("%d:%02d", lt.hour, lt.min), 1, 1, 1, 0.8, 0.8, 0.8)
        if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Daily Reset",
                U.FormatDuration(C_DateAndTime.GetSecondsUntilDailyReset()), 1, 1, 1, 0.6, 0.6, 0.6)
        end
        if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
            GameTooltip:AddDoubleLine("Weekly Reset",
                U.FormatDuration(C_DateAndTime.GetSecondsUntilWeeklyReset()), 1, 1, 1, 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end,
    click = function() if ToggleCalendar then ToggleCalendar() end end,
})

--------------------------------------------------------------------------------
--  Coordinates  -  zone + x,y; click: world map
--------------------------------------------------------------------------------
Reg({
    name = "Coordinates", label = "Coordinates", category = "System", interval = 0.3,
    update = function(slot)
        local mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then slot.text:SetText("|cffaaaaaa--|r"); return end
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        local zone = (GetMinimapZoneText and GetMinimapZoneText()) or GetZoneText() or "?"
        if #zone > 14 then zone = zone:sub(1, 13) .. "." end
        if pos then
            local x, y = pos:GetXY()
            slot.text:SetFormattedText("%s |cffaaaaaa%.1f, %.1f|r", zone, x * 100, y * 100)
        else
            slot.text:SetText(zone)
        end
    end,
    click = function()
        if WorldMapFrame:IsShown() then HideUIPanel(WorldMapFrame) else ShowUIPanel(WorldMapFrame) end
    end,
})

--------------------------------------------------------------------------------
--  System  -  FPS + latency; tooltip: network breakdown
--------------------------------------------------------------------------------
Reg({
    name = "System", label = "System (FPS/MS)", category = "System", interval = 1.5,
    update = function(slot)
        local fps = floor(GetFramerate())
        local _, _, lh, lw = GetNetStats()
        local lat = max(lh or 0, lw or 0)
        slot.text:SetFormattedText("|cff%s%d fps|r  |cff%s%d ms|r",
            StatusHex(slot, fps, 50, 25, false), fps,
            StatusHex(slot, lat, 100, 250, true), lat)
    end,
    enter = function(slot)
        local _, bwIn, latHome, latWorld = GetNetStats()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("System", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("FPS", tostring(floor(GetFramerate())), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Home Latency", (latHome or 0) .. " ms", 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("World Latency", (latWorld or 0) .. " ms", 1, 1, 1, 1, 1, 1)
        if bwIn and bwIn > 0 then
            GameTooltip:AddDoubleLine("Bandwidth In", format("%.2f Mbps", bwIn), 1, 1, 1, 1, 1, 1)
        end
        GameTooltip:Show()
    end,
    click = function() collectgarbage("collect") ns.Print("memory collected.") end,
})

--------------------------------------------------------------------------------
--  Durability  -  lowest slot %; tooltip: per-slot; click: character sheet
--------------------------------------------------------------------------------
local DURA_SLOTS = {
    [1] = "Head", [3] = "Shoulders", [5] = "Chest", [6] = "Waist", [7] = "Legs",
    [8] = "Feet", [9] = "Wrists", [10] = "Hands", [15] = "Back",
    [16] = "Main Hand", [17] = "Off Hand",
}

Reg({
    name = "Durability", label = "Durability", category = "System",
    events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_ENTERING_WORLD", "MERCHANT_SHOW", "MERCHANT_CLOSED" },
    update = function(slot)
        local lowest = 101
        for s in pairs(DURA_SLOTS) do
            local c, m = GetInventoryItemDurability(s)
            if c and m and m > 0 then
                local pct = floor(c / m * 100)
                if pct < lowest then lowest = pct end
            end
        end
        if lowest > 100 then
            slot.text:SetText("|cff4d4d4dDur --|r")
            -- Right after login, equipped-item durability is often not populated
            -- yet (GetInventoryItemDurability returns nil for every slot) and the
            -- UPDATE_INVENTORY_DURABILITY event may fire before this slot is bound.
            -- Retry a few times so we don't stay stuck on "Dur --".
            slot._duraTries = (slot._duraTries or 0) + 1
            if slot._duraTries <= 10 then
                C_Timer.After(1.5, function()
                    if slot._dtName == "Durability" then ns.Engine.Refresh(slot) end
                end)
            end
            return
        end
        slot._duraTries = 0
        local pre = ns.WantPrefix(slot) and "Dur " or ""
        slot.text:SetFormattedText("|cff%s%s%d%%|r", StatusHex(slot, lowest, 60, 30, false), pre, lowest)
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Durability", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local any = false
        for s, name in pairs(DURA_SLOTS) do
            local c, m = GetInventoryItemDurability(s)
            if c and m and m > 0 then
                any = true
                local pct = floor(c / m * 100)
                local hex = StatusHex(slot, pct, 60, 30, false)
                GameTooltip:AddDoubleLine(name, ("|cff%s%d%%|r"):format(hex, pct), 1, 1, 1)
            end
        end
        if not any then GameTooltip:AddLine("All equipment at full durability.", 0.7, 0.7, 0.7) end
        GameTooltip:Show()
    end,
    click = function() ToggleCharacter("PaperDollFrame") end,
})
