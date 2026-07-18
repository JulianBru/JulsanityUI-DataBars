--------------------------------------------------------------------------------
--  DataTexts/DT_Extra.lua  -  Character category (v1.8 additions)
--    Talent Loadout - Secondary Stats - Currency - Equipment Set
--    Warband Bank - Guild Bank
--------------------------------------------------------------------------------
local _, ns = ...
local U      = ns.Util
local Engine = ns.Engine
local Reg    = ns.RegisterDataText
local L      = ns.L
local format = string.format
local floor  = math.floor

--------------------------------------------------------------------------------
--  Shared money helpers
--------------------------------------------------------------------------------
local function GoldShort(g)
    if g >= 1e6 then return format("%.1fM", g / 1e6) end
    if g >= 1e3 then return format("%.0fK", g / 1e3) end
    return tostring(g)
end

local function MoneyStr(copper)
    copper = copper or 0
    if GetMoneyString then
        local ok, s = pcall(GetMoneyString, copper, true)
        if ok and s and s ~= "" then return s end
    end
    return format("%dg", floor(copper / 10000))
end

-- Bar text for a copper amount: gold only, honouring the slot's Short Numbers.
local function GoldBar(slot, copper)
    local g = floor((copper or 0) / 10000)
    local gv = ns.SlotOpt(slot, "shortNumber", false) and GoldShort(g) or BreakUpLargeNumbers(g)
    return format("|cffffd700%s|r|cffc0c0c0g|r", gv)
end

--------------------------------------------------------------------------------
--  Talent Loadout  -  active build name; tooltip: saved loadouts for this spec
--------------------------------------------------------------------------------
local function ActiveLoadoutName()
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return nil end
    local cid = C_ClassTalents.GetActiveConfigID()
    if not cid then return nil end
    local info = C_Traits and C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(cid)
    return info and info.name, cid
end

local function CurrentSpecID()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return nil end
    return (GetSpecializationInfo and GetSpecializationInfo(idx)) or nil
end

Reg({
    name = "Talent Loadout", label = "Talent Loadout", category = "Character",
    events = { "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "PLAYER_TALENT_UPDATE", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        local name = ActiveLoadoutName()
        local pre  = ns.WantPrefix(slot) and "|cffaaaaaaBuild|r " or ""
        if name then
            slot.text:SetFormattedText("%s|cff%s%s|r", pre, ns.ValueHex(slot), name)
        else
            slot.text:SetText(pre .. "|cffaaaaaa--|r")
        end
    end,
    enter = function(slot)
        local ar, ag, ab = ns.EUI:GetAccent()
        local active, activeID = ActiveLoadoutName()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Talent Loadout"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Active"], active or "--", 1, 1, 1, ar, ag, ab)

        local specID = CurrentSpecID()
        if specID and C_ClassTalents and C_ClassTalents.GetConfigIDsBySpecID then
            local ids = C_ClassTalents.GetConfigIDsBySpecID(specID)
            if type(ids) == "table" and #ids > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Loadouts"], ar, ag, ab)
                for _, id in ipairs(ids) do
                    local info = C_Traits and C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(id)
                    if info and info.name then
                        local mark = (id == activeID) and "> " or "  "
                        GameTooltip:AddLine(mark .. info.name, 1, 1, 1)
                    end
                end
            end
        end
        GameTooltip:Show()
    end,
    click = function()
        if PlayerSpellsUtil and PlayerSpellsUtil.OpenToClassTalentsTab then
            PlayerSpellsUtil.OpenToClassTalentsTab()
        elseif ToggleTalentFrame then
            ToggleTalentFrame()
        end
    end,
})

--------------------------------------------------------------------------------
--  Secondary Stats  -  crit / haste / mastery / versatility
--------------------------------------------------------------------------------
local function StatValue(kind)
    if kind == "crit" then
        return (GetCritChance and GetCritChance()) or 0
    elseif kind == "haste" then
        return (GetHaste and GetHaste()) or 0
    elseif kind == "mastery" then
        return (GetMasteryEffect and GetMasteryEffect()) or (GetMastery and GetMastery()) or 0
    elseif kind == "vers" then
        local cr = CR_VERSATILITY_DAMAGE_DONE
        local a = (GetCombatRatingBonus and cr and GetCombatRatingBonus(cr)) or 0
        local b = (GetVersatilityBonus and cr and GetVersatilityBonus(cr)) or 0
        return a + b
    end
    return 0
end

Reg({
    name = "Secondary Stats", label = "Secondary Stats", category = "Character",
    events = { "COMBAT_RATING_UPDATE", "MASTERY_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD" },
    options = {
        { key = "show", type = "dropdown", label = "Show", default = "all",
          values = { all = "All", crit = "Critical Strike", haste = "Haste", mastery = "Mastery", vers = "Versatility" },
          order = { "all", "crit", "haste", "mastery", "vers" } },
    },
    update = function(slot)
        local hex  = ns.ValueHex(slot)
        local show = ns.SlotOpt(slot, "show", "all")
        if show == "all" then
            slot.text:SetFormattedText(
                "|cffaaaaaaC|r|cff%s%.0f|r |cffaaaaaaH|r|cff%s%.0f|r |cffaaaaaaM|r|cff%s%.0f|r |cffaaaaaaV|r|cff%s%.0f|r",
                hex, StatValue("crit"), hex, StatValue("haste"), hex, StatValue("mastery"), hex, StatValue("vers"))
        else
            local labels = { crit = "Crit", haste = "Haste", mastery = "Mastery", vers = "Vers" }
            local pre = ns.WantPrefix(slot) and ("|cffaaaaaa" .. (labels[show] or "") .. "|r ") or ""
            slot.text:SetFormattedText("%s|cff%s%.1f%%|r", pre, hex, StatValue(show))
        end
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Secondary Stats"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Critical Strike"], format("%.2f%%", StatValue("crit")), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["Haste"],           format("%.2f%%", StatValue("haste")), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["Mastery"],         format("%.2f%%", StatValue("mastery")), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["Versatility"],     format("%.2f%%", StatValue("vers")), 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end,
})

--------------------------------------------------------------------------------
--  Currency  -  tracked backpack currencies; tooltip: all tracked
--------------------------------------------------------------------------------
local function TrackedCurrencies()
    local out = {}
    if not (C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo) then return out end
    local i = 1
    while i <= 20 do
        local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
        if not info then break end
        out[#out + 1] = info
        i = i + 1
    end
    return out
end

Reg({
    name = "Currency", label = "Currency", category = "Character",
    events = { "CURRENCY_DISPLAY_UPDATE", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        local list = TrackedCurrencies()
        if #list == 0 then
            slot.text:SetText("|cffaaaaaa" .. L["Currency"] .. "|r")
            return
        end
        local c = list[1]
        local icon = c.iconFileID and ("|T" .. c.iconFileID .. ":14:14:0:0|t ") or ""
        slot.text:SetFormattedText("%s|cff%s%s|r", icon, ns.ValueHex(slot), BreakUpLargeNumbers(c.quantity or 0))
    end,
    enter = function(slot)
        local list = TrackedCurrencies()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Currency"], 1, 1, 1)
        if #list == 0 then
            GameTooltip:AddLine(L["No currency tracked."], 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(" ")
            for _, c in ipairs(list) do
                local icon = c.iconFileID and ("|T" .. c.iconFileID .. ":14:14:0:0|t ") or ""
                GameTooltip:AddDoubleLine(icon .. (c.name or "?"), BreakUpLargeNumbers(c.quantity or 0), 1, 1, 1, 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end,
    click = function() if ToggleCharacter then ToggleCharacter("TokenFrame") end end,
})

--------------------------------------------------------------------------------
--  Equipment Set  -  equipped set name; click: switch set (context menu)
--------------------------------------------------------------------------------
local function AllSets()
    if not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs) then return {} end
    return C_EquipmentSet.GetEquipmentSetIDs() or {}
end

local function EquippedSet()
    for _, id in ipairs(AllSets()) do
        local name, icon, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(id)
        if isEquipped then return name, icon, id, true end
    end
    local ids = AllSets()
    if ids[1] then
        local name, icon = C_EquipmentSet.GetEquipmentSetInfo(ids[1])
        return name, icon, ids[1], false
    end
    return nil
end

Reg({
    name = "Equipment Set", label = "Equipment Set", category = "Character",
    events = { "EQUIPMENT_SETS_CHANGED", "EQUIPMENT_SWAP_FINISHED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        local name = EquippedSet()
        local pre  = ns.WantPrefix(slot) and "|cffaaaaaaSet|r " or ""
        if name then
            slot.text:SetFormattedText("%s|cff%s%s|r", pre, ns.ValueHex(slot), name)
        else
            slot.text:SetText(pre .. "|cffaaaaaa--|r")
        end
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Equipment Set"], 1, 1, 1)
        local ids = AllSets()
        if #ids == 0 then
            GameTooltip:AddLine(L["No equipment sets."], 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(" ")
            for _, id in ipairs(ids) do
                local name, _, _, isEquipped, numItems, numEquipped = C_EquipmentSet.GetEquipmentSetInfo(id)
                local mark = isEquipped and "> " or "  "
                local r, g, b = (isEquipped and 0.2 or 1), 1, (isEquipped and 0.2 or 1)
                GameTooltip:AddDoubleLine(mark .. (name or "?"),
                    format("%d/%d", numEquipped or 0, numItems or 0), r, g, b, 0.8, 0.8, 0.8)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Click to switch set."], 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end,
    click = function(slot)
        if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
        local ids = AllSets()
        if #ids == 0 then return end
        MenuUtil.CreateContextMenu(slot, function(_, root)
            root:CreateTitle(L["Equipment Set"])
            for _, id in ipairs(ids) do
                local name, _, setID, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(id)
                root:CreateRadio(name or "?",
                    function() return isEquipped end,
                    function() if C_EquipmentSet.UseEquipmentSet then C_EquipmentSet.UseEquipmentSet(id) end end)
            end
        end)
    end,
})

--------------------------------------------------------------------------------
--  Warband Bank  -  account bank gold (live via C_Bank)
--------------------------------------------------------------------------------
local function WarbandMoney()
    if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account then
        local ok, v = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
        if ok and type(v) == "number" then return v end
    end
    return 0
end

Reg({
    name = "Warband Bank", label = "Warband Bank", category = "Character",
    events = { "PLAYER_ENTERING_WORLD", "PLAYER_MONEY", "ACCOUNT_MONEY", "BANKFRAME_OPENED", "BANKFRAME_CLOSED" },
    options = {
        { key = "shortNumber", type = "toggle", label = "Short Numbers", default = false },
    },
    update = function(slot)
        local pre = ns.WantPrefix(slot) and "|cffaaaaaaBank|r " or ""
        slot.text:SetText(pre .. GoldBar(slot, WarbandMoney()))
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Warband Bank"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Deposited"], MoneyStr(WarbandMoney()), 1, 1, 1, 1, 0.82, 0)
        GameTooltip:Show()
    end,
})

--------------------------------------------------------------------------------
--  Guild Bank  -  guild bank gold. Only readable while the guild bank has been
--  viewed this session, so we cache the last seen value.
--------------------------------------------------------------------------------
local guildBankCache = nil

Reg({
    name = "Guild Bank", label = "Guild Bank", category = "Character",
    events = { "GUILDBANKFRAME_OPENED", "GUILDBANK_UPDATE_MONEY", "PLAYER_GUILD_UPDATE", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        local pre = ns.WantPrefix(slot) and "|cffaaaaaaGBank|r " or ""
        if not (IsInGuild and IsInGuild()) then
            slot.text:SetText(pre .. "|cffaaaaaa--|r")
            return
        end
        local live = GetGuildBankMoney and GetGuildBankMoney() or 0
        if live and live > 0 then guildBankCache = live end
        if guildBankCache then
            slot.text:SetText(pre .. GoldBar(slot, guildBankCache))
        else
            slot.text:SetText(pre .. "|cffaaaaaa?|r")
        end
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Guild Bank"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        if not (IsInGuild and IsInGuild()) then
            GameTooltip:AddLine(L["Not in a guild."], 0.7, 0.7, 0.7)
        elseif guildBankCache then
            GameTooltip:AddDoubleLine(L["Deposited"], MoneyStr(guildBankCache), 1, 1, 1, 1, 0.82, 0)
        else
            GameTooltip:AddLine(L["Open the guild bank to read its gold."], 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end,
    click = function() if ToggleGuildFrame then ToggleGuildFrame() end end,
    options = {
        { key = "shortNumber", type = "toggle", label = "Short Numbers", default = false },
    },
})
