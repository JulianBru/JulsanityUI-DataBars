--------------------------------------------------------------------------------
--  DataTexts/DT_Character.lua  -  Character category
--    Gold - Item Level - Experience - Movement Speed - Bags - Reputation
--------------------------------------------------------------------------------
local _, ns = ...
local U      = ns.Util
local Engine = ns.Engine
local Reg    = ns.RegisterDataText

local L       = ns.L
local floor   = math.floor
local format  = string.format
local sort    = table.sort
local tinsert = table.insert

local function AccentHex() return U.RGBToHex(ns.EUI:GetAccent()) end

-- Format a copper amount as a coin string (uses Blizzard's icon string when
-- available, otherwise a plain "Ng Ms" fallback).
local function Money(copper)
    copper = copper or 0
    if GetMoneyString then
        local ok, str = pcall(GetMoneyString, copper, true)
        if ok and str and str ~= "" then return str end
    end
    local g = floor(copper / 10000)
    local sv = floor((copper % 10000) / 100)
    return format("|cffffd700%s|r|cffc0c0c0g %ds|r", BreakUpLargeNumbers(g), sv)
end

--------------------------------------------------------------------------------
--  Gold  -  money; tooltip: breakdown; click: character (currency tab)
--------------------------------------------------------------------------------
-- Faction header colours.
local FACTION_COLOR = {
    Alliance = { 0.2, 0.45, 1.0 },
    Horde    = { 0.85, 0.15, 0.15 },
    Neutral  = { 0.8, 0.8, 0.8 },
}

-- Pull every tracked character's gold from Syndicator, grouped by faction.
-- Returns: groups = {Alliance={...}, Horde={...}, Neutral={...}},
--          totals = {Alliance=copper, ...}, grand = copper, ok = boolean.
local function CollectSyndicatorGold()
    if not (Syndicator and Syndicator.API and Syndicator.API.GetAllCharacters) then
        return nil
    end
    local groups = { Alliance = {}, Horde = {}, Neutral = {} }
    local totals = { Alliance = 0, Horde = 0, Neutral = 0 }
    local grand  = 0
    local current = Syndicator.API.GetCurrentCharacter and Syndicator.API.GetCurrentCharacter()

    for _, full in ipairs(Syndicator.API.GetAllCharacters() or {}) do
        local d = Syndicator.API.GetByCharacterFullName(full)
        local det = d and d.details
        -- Respect Syndicator's per-character "show gold" toggle.
        if det and (not det.show or det.show.gold ~= false) then
            local fac = det.faction
            if fac ~= "Alliance" and fac ~= "Horde" then fac = "Neutral" end
            local money = d.money or 0
            tinsert(groups[fac], {
                name    = det.character or full,
                realm   = det.realm,
                class   = det.className,   -- class TOKEN, e.g. "MAGE"
                money   = money,
                current = (full == current),
            })
            totals[fac] = totals[fac] + money
            grand = grand + money
        end
    end
    return groups, totals, grand
end

-- Fallback source: EllesmereUI Bags' own gold tracker. It stores per-character
-- gold in EllesmereUIDB.characterGold["Name-Realm"] = { gold, class, classColor }
-- (no faction), plus EllesmereUIDB.warbandGold. Used when Syndicator is absent.
local function CollectBagsGold()
    local db = EllesmereUIDB
    if type(db) ~= "table" or type(db.characterGold) ~= "table" then return nil end
    local list, grand = {}, 0
    for charID, d in pairs(db.characterGold) do
        if type(d) == "table" and d.gold then
            list[#list + 1] = { id = charID, money = d.gold, classColor = d.classColor }
            grand = grand + d.gold
        end
    end
    if #list == 0 then return nil end
    local warband = db.warbandGold and db.warbandGold.gold
    return list, grand, warband
end

-- Best-available Warband (account) bank gold, in copper. Prefers the LIVE game
-- value (accurate even when an addon's saved cache is stale, and works even if
-- Syndicator lacks a warband API); falls back to the cached value the caller
-- supplies (Syndicator / EllesmereUI Bags).
local function WarbandGold(cachedCopper)
    if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account then
        local ok, live = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
        if ok and type(live) == "number" and live > 0 then return live end
    end
    return cachedCopper or 0
end

Reg({
    name = "Gold", label = "Gold", category = "Character",
    events = { "PLAYER_MONEY", "PLAYER_ENTERING_WORLD", "SEND_MAIL_MONEY_CHANGED", "TRADE_MONEY_CHANGED" },
    update = function(slot)
        local copper = GetMoney() or 0
        local g = floor(copper / 10000)
        local s = floor((copper % 10000) / 100)
        if g > 0 then
            slot.text:SetFormattedText("|cffffd700%s|r|cffc0c0c0g %ds|r", BreakUpLargeNumbers(g), s)
        elseif s > 0 then
            slot.text:SetFormattedText("|cffc0c0c0%ds %dc|r", s, copper % 100)
        else
            slot.text:SetFormattedText("|cffeda55f%dc|r", copper % 100)
        end
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Gold"], 1, 1, 1)

        local groups, totals, grand = CollectSyndicatorGold()
        if not groups then
            -- Syndicator unavailable: try EllesmereUI Bags' gold tracker
            -- (flat list; it stores no faction, so no Horde/Alliance split).
            local list, grand, warband = CollectBagsGold()
            if list then
                sort(list, function(a, b) return a.money > b.money end)
                local ar, ag, ab = ns.EUI:GetAccent()
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Characters"], ar, ag, ab)
                for _, c in ipairs(list) do
                    local cc = c.classColor
                    local r, g, b = 1, 1, 1
                    if type(cc) == "table" then r, g, b = cc.r or 1, cc.g or 1, cc.b or 1 end
                    local name = (Ambiguate and Ambiguate(c.id, "short")) or c.id
                    GameTooltip:AddDoubleLine("  " .. name, Money(c.money), r, g, b, 1, 1, 1)
                end
                local wbMoney = WarbandGold(warband)
                if wbMoney > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine(L["Warband Bank"], Money(wbMoney), 0.6, 0.8, 1, 1, 1, 1)
                    grand = grand + wbMoney
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(L["Total"], Money(grand), 1, 1, 1, 1, 0.82, 0)
                GameTooltip:Show()
                return
            end

            -- Last resort: this character only.
            local copper = GetMoney() or 0
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(L["Gold"],   BreakUpLargeNumbers(floor(copper / 10000)) .. " g", 1, 1, 1, 1, 0.82, 0)
            GameTooltip:AddDoubleLine(L["Silver"], floor((copper % 10000) / 100) .. " s", 1, 1, 1, 0.75, 0.75, 0.75)
            GameTooltip:AddDoubleLine(L["Copper"], (copper % 100) .. " c", 1, 1, 1, 0.86, 0.55, 0.24)
            GameTooltip:Show()
            return
        end

        local function RenderFaction(fac, header)
            local list = groups[fac]
            if #list == 0 then return end
            sort(list, function(a, b) return a.money > b.money end)
            local fc = FACTION_COLOR[fac]
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(header, Money(totals[fac]), fc[1], fc[2], fc[3], 1, 0.82, 0)
            for _, c in ipairs(list) do
                local cc = c.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[c.class]
                local r, g, b = 1, 1, 1
                if cc then r, g, b = cc.r, cc.g, cc.b end
                local name = c.name or "?"
                if c.current then name = "> " .. name else name = "  " .. name end
                GameTooltip:AddDoubleLine(name, Money(c.money), r, g, b, 1, 1, 1)
            end
        end

        RenderFaction("Alliance", L["Alliance"])
        RenderFaction("Horde",    L["Horde"])
        RenderFaction("Neutral",  L["Neutral"])

        -- Account-wide (Warband) bank gold. Use the live game value (falls back
        -- to Syndicator's cache), so it is correct even if Syndicator hasn't
        -- refreshed its warband snapshot or lacks a warband API.
        do
            local wb = Syndicator.API.GetWarband and Syndicator.API.GetWarband(1)
            local wbMoney = WarbandGold(wb and wb.money)
            if wbMoney > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(L["Warband Bank"], Money(wbMoney), 0.6, 0.8, 1, 1, 1, 1)
                grand = grand + wbMoney
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Total"], Money(grand), 1, 1, 1, 1, 0.82, 0)
        GameTooltip:Show()
    end,
    click = function() ToggleCharacter("TokenFrame") end,
})

--------------------------------------------------------------------------------
--  Item Level  -  equipped average; tooltip: per-slot ilvl
--------------------------------------------------------------------------------
local ILVL_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
local ILVL_NAMES = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulder", [5] = "Chest", [6] = "Waist",
    [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands", [11] = "Ring 1",
    [12] = "Ring 2", [13] = "Trinket 1", [14] = "Trinket 2", [15] = "Back",
    [16] = "Main Hand", [17] = "Off Hand",
}

Reg({
    name = "Item Level", label = "Item Level", category = "Character",
    events = { "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP" },
    update = function(slot)
        if not GetAverageItemLevel then slot.text:SetText("N/A"); return end
        local _, equipped = GetAverageItemLevel()
        if not equipped then slot.text:SetText("N/A"); return end
        slot.text:SetFormattedText("|cff%s%.0f ilvl|r", AccentHex(), equipped)
    end,
    enter = function(slot)
        if not GetAverageItemLevel then return end
        local avg, equipped = GetAverageItemLevel()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Item Level", 1, 1, 1)
        GameTooltip:AddLine(" ")
        if avg and equipped then
            GameTooltip:AddDoubleLine("Equipped", format("%.1f", equipped), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Overall",  format("%.1f", avg), 1, 1, 1, 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ")
        end
        for _, s in ipairs(ILVL_SLOTS) do
            local link = GetInventoryItemLink("player", s)
            if link then
                local ilvl = (C_Item and C_Item.GetDetailedItemLevelInfo)
                    and C_Item.GetDetailedItemLevelInfo(link) or nil
                if ilvl and ilvl > 0 then
                    GameTooltip:AddDoubleLine(ILVL_NAMES[s] or ("Slot " .. s), tostring(ilvl), 1, 1, 1, 1, 1, 1)
                end
            end
        end
        GameTooltip:Show()
    end,
    click = function() ToggleCharacter("PaperDollFrame") end,
})

--------------------------------------------------------------------------------
--  Experience  -  % to next level or "Max"; tooltip: rested
--------------------------------------------------------------------------------
Reg({
    name = "Experience", label = "Experience", category = "Character",
    events = { "PLAYER_XP_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "DISABLE_XP_GAIN", "ENABLE_XP_GAIN" },
    update = function(slot)
        local maxXP = UnitXPMax("player")
        if not maxXP or maxXP == 0 or IsXPUserDisabled() then
            slot.text:SetFormattedText("|cff%sMax Level|r", AccentHex())
            return
        end
        local cur = UnitXP("player") or 0
        slot.text:SetFormattedText("XP |cff%s%.1f%%|r", AccentHex(), cur / maxXP * 100)
    end,
    enter = function(slot)
        local maxXP = UnitXPMax("player")
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Experience", 1, 1, 1)
        if not maxXP or maxXP == 0 then
            GameTooltip:AddLine("Max Level", 0.8, 0.8, 0.8)
        else
            local cur  = UnitXP("player") or 0
            local rest = GetXPExhaustion() or 0
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Current",   U.ShortValue(cur), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Remaining", U.ShortValue(maxXP - cur), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Progress",  format("%.1f%%", cur / maxXP * 100), 1, 1, 1, 1, 1, 1)
            if rest > 0 then
                GameTooltip:AddDoubleLine("Rested",
                    U.ShortValue(rest) .. format(" (%.0f%%)", rest / maxXP * 100), 1, 1, 1, 0, 0.6, 1)
            end
        end
        GameTooltip:Show()
    end,
})

--------------------------------------------------------------------------------
--  Movement Speed  -  current run speed %; tooltip: rating bonus
--------------------------------------------------------------------------------
Reg({
    name = "Speed", label = "Movement Speed", category = "Character", interval = 0.5,
    update = function(slot)
        local current = GetUnitSpeed("player") or 0
        local pct = current / BASE_MOVEMENT_SPEED * 100   -- BASE_MOVEMENT_SPEED = 7
        slot.text:SetFormattedText("Speed |cff%s%.0f%%|r", AccentHex(), pct)
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Movement Speed", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local pct = (GetUnitSpeed("player") or 0) / BASE_MOVEMENT_SPEED * 100
        GameTooltip:AddDoubleLine("Current", format("%.0f%%", pct), 1, 1, 1, 1, 1, 1)
        if GetCombatRatingBonus and CR_SPEED then
            local bonus = GetCombatRatingBonus(CR_SPEED)
            if bonus and bonus ~= 0 then
                GameTooltip:AddDoubleLine("Speed Rating", format("+%.2f%%", bonus), 1, 1, 1, 0.8, 0.8, 0.8)
            end
        end
        GameTooltip:Show()
    end,
})

--------------------------------------------------------------------------------
--  Bags  -  free / total slots; tooltip: per-bag; click: open bags
--------------------------------------------------------------------------------
local function CountBags()
    local free, total = 0, 0
    for i = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4 do
        local f, ftype = C_Container.GetContainerNumFreeSlots(i)
        if not ftype or ftype == 0 then
            total = total + (C_Container.GetContainerNumSlots(i) or 0)
            free  = free + (f or 0)
        end
    end
    return free, total
end

Reg({
    name = "Bags", label = "Bag Space", category = "Character",
    events = { "BAG_UPDATE", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED" },
    update = function(slot)
        local free, total = CountBags()
        slot.text:SetFormattedText("|cff%s%d|r |cffaaaaaa/ %d|r", AccentHex(), free, total)
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Bag Space", 1, 1, 1)
        GameTooltip:AddLine(" ")
        for i = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4 do
            local f, ftype = C_Container.GetContainerNumFreeSlots(i)
            if not ftype or ftype == 0 then
                local total = C_Container.GetContainerNumSlots(i) or 0
                if total > 0 then
                    local name = (i == 0) and "Backpack" or ("Bag " .. i)
                    GameTooltip:AddDoubleLine(name, (f or 0) .. " / " .. total, 1, 1, 1, 1, 1, 1)
                end
            end
        end
        GameTooltip:Show()
    end,
    click = function() if ToggleAllBags then ToggleAllBags() end end,
})

--------------------------------------------------------------------------------
--  Reputation  -  watched faction %; tooltip: standing; click: rep tab
--------------------------------------------------------------------------------
local REP_COLORS = {
    [1] = { 0.8, 0.13, 0.13 }, [2] = { 0.8, 0.13, 0.13 }, [3] = { 0.75, 0.27, 0 },
    [4] = { 0.9, 0.7, 0 }, [5] = { 0, 0.6, 0.1 }, [6] = { 0, 0.6, 0.1 },
    [7] = { 0, 0.6, 0.1 }, [8] = { 0, 0.6, 0.1 },
}

local function WatchedFaction()
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        return C_Reputation.GetWatchedFactionData()
    end
end

Reg({
    name = "Reputation", label = "Reputation", category = "Character",
    events = { "UPDATE_FACTION", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        local d = WatchedFaction()
        if not d or not d.name or d.name == "" then
            slot.text:SetText("|cffaaaaaa-- Rep|r")
            return
        end
        local lo, hi, cur = d.currentReactionThreshold or 0, d.nextReactionThreshold or 1, d.currentStanding or 0
        local span = hi - lo
        local pct = span > 0 and (cur - lo) / span * 100 or 100
        local col = REP_COLORS[d.reaction] or { 1, 1, 1 }
        slot.text:SetFormattedText("|cff%s%.0f%%|r", U.RGBToHex(col[1], col[2], col[3]), pct)
    end,
    enter = function(slot)
        local d = WatchedFaction()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Reputation", 1, 1, 1)
        if not d or not d.name or d.name == "" then
            GameTooltip:AddLine("No faction watched.", 0.7, 0.7, 0.7)
        else
            local lo, hi, cur = d.currentReactionThreshold or 0, d.nextReactionThreshold or 1, d.currentStanding or 0
            local span = hi - lo
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(d.name, format("%.1f%%", span > 0 and (cur - lo) / span * 100 or 100), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Standing",
                BreakUpLargeNumbers(cur - lo) .. " / " .. BreakUpLargeNumbers(span), 1, 1, 1, 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end,
    click = function() ToggleCharacter("PaperDollFrame") if ReputationFrame and CharacterFrameTab3 then CharacterFrameTab3:Click() end end,
})
