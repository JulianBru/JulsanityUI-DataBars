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
    options = {
        { key = "localTime", type = "toggle", label = "Local Time",     default = false },
        { key = "format24",  type = "toggle", label = "24-Hour Format", default = true  },
    },
    update = function(slot)
        local h, m
        if ns.SlotOpt(slot, "localTime", false) then
            local lt = date("*t"); h, m = lt.hour, lt.min
        else
            h, m = GetGameTime()
        end
        local hex = ns.ValueHex(slot)
        if ns.SlotOpt(slot, "format24", true) then
            slot.text:SetFormattedText("|cff%s%d:%02d|r", hex, h, m)
        else
            local ampm = (h >= 12) and "PM" or "AM"
            local hh = h % 12; if hh == 0 then hh = 12 end
            slot.text:SetFormattedText("|cff%s%d:%02d %s|r", hex, hh, m, ampm)
        end
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
    options = {
        { key = "showZone", type = "toggle", label = "Show Zone", default = true },
        { key = "decimals", type = "dropdown", label = "Decimals", default = "1",
          values = { ["0"] = "0", ["1"] = "1", ["2"] = "2" }, order = { "0", "1", "2" } },
    },
    update = function(slot)
        local mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then slot.text:SetText("|cffaaaaaa--|r"); return end
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        local dec = tonumber(ns.SlotOpt(slot, "decimals", "1")) or 1
        local zone = ""
        if ns.SlotOpt(slot, "showZone", true) then
            zone = (GetMinimapZoneText and GetMinimapZoneText()) or GetZoneText() or "?"
            if #zone > 14 then zone = zone:sub(1, 13) .. "." end
        end
        if pos then
            local x, y = pos:GetXY()
            local coords = format("%%.%df, %%.%df", dec, dec):format(x * 100, y * 100)
            if zone ~= "" then
                slot.text:SetFormattedText("%s |cffaaaaaa%s|r", zone, coords)
            else
                slot.text:SetFormattedText("|cffaaaaaa%s|r", coords)
            end
        else
            slot.text:SetText(zone ~= "" and zone or "|cffaaaaaa--|r")
        end
    end,
    click = function()
        if WorldMapFrame:IsShown() then HideUIPanel(WorldMapFrame) else ShowUIPanel(WorldMapFrame) end
    end,
})

--------------------------------------------------------------------------------
--  System  -  FPS + latency; tooltip: network breakdown + addon memory
--------------------------------------------------------------------------------
local function FormatMem(kb)
    if kb >= 1024 then return format("%.1f MB", kb / 1024) end
    return format("%.0f KB", kb)
end

-- UpdateAddOnMemoryUsage() scans every addon and is expensive; throttle the real
-- scan to at most once every 2s even if a tooltip re-renders faster.
local lastMemScan = 0
local function RefreshAddonMemory()
    local now = GetTime()
    if now - lastMemScan >= 2 then
        UpdateAddOnMemoryUsage()
        lastMemScan = now
    end
end
Reg({
    name = "System", label = "System (FPS/MS)", category = "System", interval = 1.5,
    tooltipRefresh = 1,
    options = {
        { key = "display", type = "dropdown", label = "Display", default = "both",
          values = { both = "FPS + MS", fps = "FPS", ms = "MS" }, order = { "both", "fps", "ms" } },
        { key = "latency", type = "dropdown", label = "Latency", default = "world",
          values = { world = "World", home = "Home" }, order = { "world", "home" } },
        { key = "memCount", type = "dropdown", label = "Addon Memory", default = "5",
          values = { off = "None", ["3"] = "3", ["5"] = "5", ["10"] = "10", all = "All" }, order = { "off", "3", "5", "10", "all" } },
    },
    update = function(slot)
        local fps = floor(GetFramerate())
        local _, _, lh, lw = GetNetStats()
        local lat = (ns.SlotOpt(slot, "latency", "world") == "home") and (lh or 0) or (lw or 0)
        local disp = ns.SlotOpt(slot, "display", "both")
        local fpsStr = format("|cff%s%d fps|r", StatusHex(slot, fps, 50, 25, false), fps)
        local msStr  = format("|cff%s%d ms|r",  StatusHex(slot, lat, 100, 250, true), lat)
        if disp == "fps" then
            slot.text:SetText(fpsStr)
        elseif disp == "ms" then
            slot.text:SetText(msStr)
        else
            slot.text:SetText(fpsStr .. "  " .. msStr)
        end
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

        local memCount = ns.SlotOpt(slot, "memCount", "5")
        if memCount ~= "off" then
            RefreshAddonMemory()
            local numAddons = (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns())
                or (GetNumAddOns and GetNumAddOns()) or 0
            local list, total = {}, 0
            for i = 1, numAddons do
                local mem = GetAddOnMemoryUsage(i) or 0
                if mem > 0 then
                    local name = (C_AddOns and C_AddOns.GetAddOnInfo and (C_AddOns.GetAddOnInfo(i)))
                        or (GetAddOnInfo and (GetAddOnInfo(i))) or ("AddOn " .. i)
                    list[#list + 1] = { name = name, mem = mem }
                    total = total + mem
                end
            end
            table.sort(list, function(a, b) return a.mem > b.mem end)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Addon Memory", 1, 1, 1)
            local topN = (memCount == "all") and #list or (tonumber(memCount) or 5)
            for i = 1, math.min(topN, #list) do
                GameTooltip:AddDoubleLine(list[i].name, FormatMem(list[i].mem), 0.9, 0.9, 0.9, 1, 1, 1)
            end
            local ar, ag, ab = ns.EUI:GetAccent()
            GameTooltip:AddDoubleLine("Total", FormatMem(total), 1, 1, 1, ar, ag, ab)
        end

        GameTooltip:Show()
    end,
    click = function() collectgarbage("collect") ns.Print("memory collected.") end,
})

--------------------------------------------------------------------------------
--  Addons  -  number of loaded addons; tooltip: memory of every loaded addon
--------------------------------------------------------------------------------
local function IsLoaded(i)
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(i) end
    return IsAddOnLoaded and IsAddOnLoaded(i)
end
local function NumAddons()
    return (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns())
        or (GetNumAddOns and GetNumAddOns()) or 0
end
local function AddonName(i)
    return (C_AddOns and C_AddOns.GetAddOnInfo and (C_AddOns.GetAddOnInfo(i)))
        or (GetAddOnInfo and (GetAddOnInfo(i))) or ("AddOn " .. i)
end

Reg({
    name = "Addons", label = "Addons", category = "System",
    events = { "PLAYER_ENTERING_WORLD", "ADDON_LOADED" },
    tooltipRefresh = 2,
    update = function(slot)
        local loaded = 0
        for i = 1, NumAddons() do
            if IsLoaded(i) then loaded = loaded + 1 end
        end
        local hex = ns.ValueHex(slot)
        if ns.WantPrefix(slot) then
            slot.text:SetFormattedText("|cff%s%d|r |cffaaaaaaaddons|r", hex, loaded)
        else
            slot.text:SetFormattedText("|cff%s%d|r", hex, loaded)
        end
    end,
    enter = function(slot)
        RefreshAddonMemory()
        local list, total = {}, 0
        for i = 1, NumAddons() do
            if IsLoaded(i) then
                local mem = GetAddOnMemoryUsage(i) or 0
                list[#list + 1] = { name = AddonName(i), mem = mem }
                total = total + mem
            end
        end
        table.sort(list, function(a, b) return a.mem > b.mem end)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(format("Addons (%d)", #list), 1, 1, 1)
        GameTooltip:AddLine(" ")
        for i = 1, #list do
            GameTooltip:AddDoubleLine(list[i].name, FormatMem(list[i].mem), 0.9, 0.9, 0.9, 1, 1, 1)
        end
        GameTooltip:AddLine(" ")
        local ar, ag, ab = ns.EUI:GetAccent()
        GameTooltip:AddDoubleLine("Total", FormatMem(total), 1, 1, 1, ar, ag, ab)
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
    options = {
        { key = "mode", type = "dropdown", label = "Value", default = "lowest",
          values = { lowest = "Lowest", average = "Average" }, order = { "lowest", "average" } },
    },
    update = function(slot)
        local lowest, sum, count = 101, 0, 0
        for s in pairs(DURA_SLOTS) do
            local c, m = GetInventoryItemDurability(s)
            if c and m and m > 0 then
                local pct = floor(c / m * 100)
                if pct < lowest then lowest = pct end
                sum = sum + pct; count = count + 1
            end
        end
        local value = lowest
        if ns.SlotOpt(slot, "mode", "lowest") == "average" and count > 0 then
            value = floor(sum / count)
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
        slot.text:SetFormattedText("|cff%s%s%d%%|r", StatusHex(slot, value, 60, 30, false), pre, value)
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
