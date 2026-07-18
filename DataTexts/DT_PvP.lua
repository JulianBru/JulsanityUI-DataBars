--------------------------------------------------------------------------------
--  DataTexts/DT_PvP.lua  -  PvP category
--    PvP - Honor / Conquest / rated bracket rating (selectable), rich tooltip.
--------------------------------------------------------------------------------
local _, ns = ...
local U      = ns.Util
local Engine = ns.Engine
local Reg    = ns.RegisterDataText
local L      = ns.L
local format = string.format

local HONOR_CURRENCY    = 1792
local CONQUEST_CURRENCY = 1602

-- Rated brackets: { GetPersonalRatedInfo index, display name }.
local BRACKETS = {
    { 1, "2v2" }, { 2, "3v3" }, { 4, "RBG" }, { 7, "Solo Shuffle" }, { 9, "Blitz" },
}

local function Currency(id)
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if ok then return info end
end

local function BestRating()
    if not (C_PvP and C_PvP.GetPersonalRatedInfo) then return 0, nil end
    local best, bestName = 0, nil
    for _, b in ipairs(BRACKETS) do
        local ok, rating = pcall(C_PvP.GetPersonalRatedInfo, b[1])
        if ok and rating and rating > best then best, bestName = rating, b[2] end
    end
    return best, bestName
end

Reg({
    name = "PvP", label = "PvP", category = "PvP",
    events = {
        "HONOR_XP_UPDATE", "HONOR_LEVEL_UPDATE", "CURRENCY_DISPLAY_UPDATE",
        "PVP_RATED_STATS_UPDATE", "PLAYER_ENTERING_WORLD",
    },
    options = {
        { key = "show", type = "dropdown", label = "Show", default = "honor",
          values = { honor = "Honor", conquest = "Conquest", rating = "Rating" },
          order = { "honor", "conquest", "rating" } },
    },
    update = function(slot)
        local hex  = ns.ValueHex(slot)
        local show = ns.SlotOpt(slot, "show", "honor")
        local pre  = ns.WantPrefix(slot)
        if show == "conquest" then
            local info = Currency(CONQUEST_CURRENCY)
            local q = (info and info.quantity) or 0
            slot.text:SetFormattedText("%s|cff%s%s|r", pre and "|cffaaaaaaCQ|r " or "", hex, U.ShortValue(q))
        elseif show == "rating" then
            local best = BestRating()
            slot.text:SetFormattedText("%s|cff%s%d|r", pre and "|cffaaaaaaPvP|r " or "", hex, best)
        else -- honor
            local cur = (UnitHonor and UnitHonor("player")) or 0
            local max = (UnitHonorMax and UnitHonorMax("player")) or 0
            if max > 0 then
                slot.text:SetFormattedText("%s|cff%s%s|r|cffaaaaaa/%s|r",
                    pre and "|cffaaaaaaHonor|r " or "", hex, U.ShortValue(cur), U.ShortValue(max))
            else
                slot.text:SetFormattedText("%s|cff%s%s|r", pre and "|cffaaaaaaHonor|r " or "", hex, U.ShortValue(cur))
            end
        end
    end,
    enter = function(slot)
        local ar, ag, ab = ns.EUI:GetAccent()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["PvP"], 1, 1, 1)
        GameTooltip:AddLine(" ")

        local lvl = (UnitHonorLevel and UnitHonorLevel("player"))
        local cur = (UnitHonor and UnitHonor("player")) or 0
        local max = (UnitHonorMax and UnitHonorMax("player")) or 0
        if lvl then GameTooltip:AddDoubleLine(L["Honor Level"], tostring(lvl), 1, 1, 1, ar, ag, ab) end
        if max > 0 then
            GameTooltip:AddDoubleLine(L["Honor"], format("%s / %s", U.ShortValue(cur), U.ShortValue(max)), 1, 1, 1, 1, 1, 1)
        end

        local cq = Currency(CONQUEST_CURRENCY)
        if cq then
            local capTxt = (cq.maxQuantity and cq.maxQuantity > 0)
                and format("%s / %s", U.ShortValue(cq.quantity or 0), U.ShortValue(cq.maxQuantity))
                or U.ShortValue(cq.quantity or 0)
            GameTooltip:AddDoubleLine(L["Conquest"], capTxt, 1, 1, 1, 1, 1, 1)
        end

        if C_PvP and C_PvP.GetPersonalRatedInfo then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Rated"], ar, ag, ab)
            for _, b in ipairs(BRACKETS) do
                local ok, rating = pcall(C_PvP.GetPersonalRatedInfo, b[1])
                if ok and rating and rating > 0 then
                    GameTooltip:AddDoubleLine("  " .. b[2], tostring(rating), 1, 1, 1, 1, 1, 1)
                end
            end
        end
        GameTooltip:Show()
    end,
    click = function() if TogglePVPUI then TogglePVPUI() end end,
})
