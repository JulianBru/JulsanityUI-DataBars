--------------------------------------------------------------------------------
--  DataTexts/DT_Difficulty.lua  -  Instance difficulty (PvE)
--
--  Shows the currently selected 5-man dungeon + raid difficulty. Clicking opens
--  a native context menu (MenuUtil) to switch either one. Setting only works
--  out of an instance and, in a group, as the leader -- Blizzard enforces this
--  and prints its own error otherwise, so we just call the setters.
--------------------------------------------------------------------------------
local _, ns = ...
local U      = ns.Util
local Engine = ns.Engine
local Reg    = ns.RegisterDataText
local L      = ns.L
local format = string.format

local function AccentHex() return U.RGBToHex(ns.EUI:GetAccent()) end

-- Selectable difficulties (M+ is keystone-driven, not a manual choice here).
local DUNGEON_IDS = { 1, 2, 23 }              -- Normal, Heroic, Mythic
local RAID_IDS    = { 17, 14, 15, 16 }        -- LFR, Normal, Heroic, Mythic
local LEGACY_RAID_IDS = { 3, 4, 5, 6 }        -- 10/25 Player (Normal/Heroic), legacy raids

-- Compact abbreviations for the bar text.
local ABBR = { [1] = "N", [2] = "HC", [23] = "M", [17] = "LFR", [14] = "N", [15] = "HC", [16] = "M" }

local function DiffName(id)
    local name = id and GetDifficultyInfo and GetDifficultyInfo(id)
    return name or "?"
end
local function CurDungeon() return (GetDungeonDifficultyID and GetDungeonDifficultyID()) or 1 end
local function CurRaid()    return (GetRaidDifficultyID and GetRaidDifficultyID()) or 14 end
local function CurLegacyRaid() return (GetLegacyRaidDifficultyID and GetLegacyRaidDifficultyID()) or 3 end

local function OpenMenu(slot)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        ns.Print("difficulty menu requires a newer client.")
        return
    end
    MenuUtil.CreateContextMenu(slot, function(_, root)
        root:CreateTitle(L["Dungeon Difficulty"])
        for _, id in ipairs(DUNGEON_IDS) do
            root:CreateRadio(DiffName(id),
                function() return CurDungeon() == id end,
                function() if SetDungeonDifficultyID then SetDungeonDifficultyID(id) end end)
        end
        root:CreateDivider()
        root:CreateTitle(L["Raid Difficulty"])
        for _, id in ipairs(RAID_IDS) do
            root:CreateRadio(DiffName(id),
                function() return CurRaid() == id end,
                function() if SetRaidDifficultyID then SetRaidDifficultyID(id) end end)
        end
        if SetLegacyRaidDifficultyID then
            root:CreateDivider()
            root:CreateTitle(L["Legacy Raid Difficulty"])
            for _, id in ipairs(LEGACY_RAID_IDS) do
                root:CreateRadio(DiffName(id),
                    function() return CurLegacyRaid() == id end,
                    function() SetLegacyRaidDifficultyID(id) end)
            end
        end
    end)
end

Reg({
    name = "Difficulty", label = "Difficulty", category = "PvE",
    events = { "PLAYER_DIFFICULTY_CHANGED", "UPDATE_INSTANCE_INFO", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE" },
    options = {
        { key = "show", type = "dropdown", label = "Show", default = "both",
          values = { both = "Both", dungeon = "Dungeon", raid = "Raid" }, order = { "both", "dungeon", "raid" } },
        { key = "names", type = "dropdown", label = "Names", default = "abbr",
          values = { abbr = "Abbreviated", full = "Full" }, order = { "abbr", "full" } },
    },
    update = function(slot)
        local hex = ns.ValueHex(slot)
        local full = ns.SlotOpt(slot, "names", "abbr") == "full"
        local function part(id, abbr)
            local txt = full and DiffName(id) or (abbr or "?")
            return format("|cff%s%s|r", hex, txt)
        end
        local show = ns.SlotOpt(slot, "show", "both")
        local body
        if show == "dungeon" then
            body = part(CurDungeon(), ABBR[CurDungeon()])
        elseif show == "raid" then
            body = part(CurRaid(), ABBR[CurRaid()])
        else
            body = part(CurDungeon(), ABBR[CurDungeon()]) .. "|cffaaaaaa/|r" .. part(CurRaid(), ABBR[CurRaid()])
        end
        if ns.WantPrefix(slot) then
            slot.text:SetText("|cffaaaaaaDiff|r " .. body)
        else
            slot.text:SetText(body)
        end
    end,
    enter = function(slot)
        local ar, ag, ab = ns.EUI:GetAccent()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Difficulty"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["Dungeon"], DiffName(CurDungeon()), 1, 1, 1, ar, ag, ab)
        GameTooltip:AddDoubleLine(L["Raid"],    DiffName(CurRaid()),    1, 1, 1, ar, ag, ab)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Click to change difficulty."], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end,
    click = function(slot) OpenMenu(slot) end,
})
