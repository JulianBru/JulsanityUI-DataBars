--------------------------------------------------------------------------------
--  DataTexts/DT_PvE.lua  -  PvE / endgame category (Retail)
--    Mythic+ Score - Mythic+ Keystone - Great Vault - Specialization
--------------------------------------------------------------------------------
local _, ns = ...
local U      = ns.Util
local Engine = ns.Engine
local Reg    = ns.RegisterDataText
local L      = ns.L

local format = string.format
local function AccentHex() return U.RGBToHex(ns.EUI:GetAccent()) end

--------------------------------------------------------------------------------
--  Mythic+ Score  -  overall rating; tooltip: per-dungeon best
--------------------------------------------------------------------------------
Reg({
    name = "Mythic+ Score", label = "Mythic+ Score", category = "PvE",
    events = { "CHALLENGE_MODE_COMPLETED", "PLAYER_ENTERING_WORLD", "MYTHIC_PLUS_NEW_WEEKLY_RECORD" },
    update = function(slot)
        if not (C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore) then
            slot.text:SetText("|cffaaaaaa-- Score|r"); return
        end
        local score = C_ChallengeMode.GetOverallDungeonScore() or 0
        local color = C_ChallengeMode.GetDungeonScoreRarityColor and C_ChallengeMode.GetDungeonScoreRarityColor(score)
        if color then
            slot.text:SetFormattedText("|cff%sM+ %d|r", U.RGBToHex(color.r, color.g, color.b), score)
        else
            slot.text:SetFormattedText("|cff%sM+ %d|r", AccentHex(), score)
        end
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Mythic+ Score", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local score = (C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore and C_ChallengeMode.GetOverallDungeonScore()) or 0
        GameTooltip:AddDoubleLine("Overall", tostring(score), 1, 1, 1, 1, 1, 1)
        local summary = C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary
            and C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if summary and summary.runs and #summary.runs > 0 then
            GameTooltip:AddLine(" ")
            for _, run in ipairs(summary.runs) do
                local mapName = C_ChallengeMode.GetMapUIInfo and (C_ChallengeMode.GetMapUIInfo(run.challengeModeID)) or "?"
                local col = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
                    and C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(run.mapScore)
                local r, g, b = 1, 1, 1
                if col then r, g, b = col.r, col.g, col.b end
                GameTooltip:AddDoubleLine(mapName,
                    format("%d (%s%d)", run.mapScore or 0, run.finishedSuccess and "+" or "", run.bestRunLevel or 0),
                    0.9, 0.9, 0.9, r, g, b)
            end
        end
        GameTooltip:Show()
    end,
})

--------------------------------------------------------------------------------
--  Mythic+ Keystone  -  owned keystone level + dungeon
--------------------------------------------------------------------------------
Reg({
    name = "Mythic+ Keystone", label = "Mythic+ Keystone", category = "PvE",
    events = { "BAG_UPDATE", "PLAYER_ENTERING_WORLD", "CHALLENGE_MODE_COMPLETED" },
    update = function(slot)
        if not (C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel) then
            slot.text:SetText("|cffaaaaaaNo Key|r"); return
        end
        local level = C_MythicPlus.GetOwnedKeystoneLevel()
        local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        if not level or not mapID then
            slot.text:SetText("|cffaaaaaaNo Key|r"); return
        end
        local name = C_ChallengeMode.GetMapUIInfo and (C_ChallengeMode.GetMapUIInfo(mapID)) or "Key"
        if #name > 10 then name = name:sub(1, 9) .. "." end
        slot.text:SetFormattedText("|cff%s+%d|r %s", AccentHex(), level, name)
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Mythic+ Keystone", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local level = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()
        local mapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        if level and mapID then
            local name = C_ChallengeMode.GetMapUIInfo and (C_ChallengeMode.GetMapUIInfo(mapID)) or "?"
            local ar, ag, ab = ns.EUI:GetAccent()
            GameTooltip:AddDoubleLine(name, "+" .. level, 1, 1, 1, ar, ag, ab)
        else
            GameTooltip:AddLine("No keystone in bags.", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end,
})

--------------------------------------------------------------------------------
--  Great Vault  -  available weekly rewards
--------------------------------------------------------------------------------
Reg({
    name = "Great Vault", label = "Great Vault", category = "PvE",
    events = { "WEEKLY_REWARDS_UPDATE", "PLAYER_ENTERING_WORLD", "CHALLENGE_MODE_COMPLETED" },
    update = function(slot)
        if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then
            slot.text:SetText("|cffaaaaaaVault --|r"); return
        end
        local activities = C_WeeklyRewards.GetActivities() or {}
        local unlocked = 0
        for _, a in ipairs(activities) do
            if a.progress and a.threshold and a.progress >= a.threshold then
                unlocked = unlocked + 1
            end
        end
        if C_WeeklyRewards.HasAvailableRewards and C_WeeklyRewards.HasAvailableRewards() then
            slot.text:SetFormattedText("|cff%sVault Ready|r", AccentHex())
        else
            slot.text:SetFormattedText("Vault |cff%s%d|r|cffaaaaaa/%d|r", AccentHex(), unlocked, #activities)
        end
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Great Vault", 1, 1, 1)
        GameTooltip:AddLine(" ")
        if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
            local TYPE_NAMES = { [1] = "Raid", [3] = "Mythic+", [6] = "World", [7] = "PvP" }
            for _, a in ipairs(C_WeeklyRewards.GetActivities() or {}) do
                local label = TYPE_NAMES[a.type] or ("Slot " .. (a.index or "?"))
                local progress = format("%d / %d", a.progress or 0, a.threshold or 0)
                local done = a.progress and a.threshold and a.progress >= a.threshold
                local r, g, b = 0.7, 0.7, 0.7
                if done then r, g, b = ns.EUI:GetAccent() end
                GameTooltip:AddDoubleLine(label, progress, 1, 1, 1, r, g, b)
            end
        end
        GameTooltip:Show()
    end,
})

--------------------------------------------------------------------------------
--  Specialization  -  active spec + loot spec
--    Left-click  : open the talent/spec UI
--    Right-click : choose the loot specialization
--------------------------------------------------------------------------------
local function ToggleSpec()
    if PlayerSpellsUtil and PlayerSpellsUtil.ToggleClassTalentOrSpecFrame then
        PlayerSpellsUtil.ToggleClassTalentOrSpecFrame()
    elseif ToggleTalentFrame then
        pcall(ToggleTalentFrame)
    end
end

local function OpenLootMenu(slot)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        ns.Print("loot spec menu requires a newer client.")
        return
    end
    MenuUtil.CreateContextMenu(slot, function(_, root)
        root:CreateTitle(L["Loot Specialization"])
        -- "Current Specialization" (id 0 = follow active spec)
        local curIdx = GetSpecialization and GetSpecialization()
        local curName = curIdx and select(2, GetSpecializationInfo(curIdx)) or nil
        local label = L["Current Specialization"]
        if curName and curName ~= "" then label = label .. " (" .. curName .. ")" end
        root:CreateRadio(label,
            function() return (GetLootSpecialization and GetLootSpecialization() or 0) == 0 end,
            function() if SetLootSpecialization then SetLootSpecialization(0) end end)
        -- Each of the player's specs
        local num = GetNumSpecializations and GetNumSpecializations() or 0
        for i = 1, num do
            local specID, name = GetSpecializationInfo(i)
            if specID then
                root:CreateRadio(name,
                    function() return (GetLootSpecialization and GetLootSpecialization()) == specID end,
                    function() if SetLootSpecialization then SetLootSpecialization(specID) end end)
            end
        end
    end)
end

Reg({
    name = "Specialization", label = "Specialization", category = "PvE",
    events = { "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_LOOT_SPEC_UPDATED" },
    update = function(slot)
        local idx = GetSpecialization and GetSpecialization()
        if not idx then slot.text:SetText("|cffaaaaaaNo Spec|r"); return end
        local _, name = GetSpecializationInfo(idx)
        slot.text:SetFormattedText("|cff%s%s|r", AccentHex(), name or "Spec")
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Specialization", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local idx = GetSpecialization and GetSpecialization()
        if idx then
            local _, name = GetSpecializationInfo(idx)
            GameTooltip:AddDoubleLine("Active", name or "?", 1, 1, 1, 1, 1, 1)
        end
        if GetLootSpecialization then
            local lootID = GetLootSpecialization()
            local lootName
            if lootID and lootID > 0 and GetSpecializationInfoByID then
                lootName = select(2, GetSpecializationInfoByID(lootID))
            else
                lootName = L["Current Specialization"]
            end
            GameTooltip:AddDoubleLine("Loot", lootName or "?", 1, 1, 1, 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Left-click: open specialization"], 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["Right-click: set loot spec"], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end,
    click = function(slot, button)
        if button == "RightButton" then
            OpenLootMenu(slot)
        else
            ToggleSpec()
        end
    end,
})

--------------------------------------------------------------------------------
--  Loot Spec  -  primarily shows the configured loot specialization
--    Left-click  : choose the loot specialization
--    Right-click : open the talent/spec UI
--------------------------------------------------------------------------------
Reg({
    name = "Loot Spec", label = "Loot Spec", category = "PvE",
    events = { "PLAYER_LOOT_SPEC_UPDATED", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        if not GetLootSpecialization then
            slot.text:SetText("|cffaaaaaaNo Loot Spec|r"); return
        end
        local lootID = GetLootSpecialization() or 0
        local name
        if lootID == 0 then
            -- 0 = follow the active spec; show that spec's name (the effective loot).
            local idx = GetSpecialization and GetSpecialization()
            if idx then name = select(2, GetSpecializationInfo(idx)) end
        elseif GetSpecializationInfoByID then
            name = select(2, GetSpecializationInfoByID(lootID))
        end
        slot.text:SetFormattedText("|cff%sLoot: %s|r", AccentHex(), name or "?")
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine(L["Loot Specialization"], 1, 1, 1)
        GameTooltip:AddLine(" ")
        if GetLootSpecialization then
            local lootID = GetLootSpecialization() or 0
            local lootName
            if lootID == 0 then
                lootName = L["Current Specialization"]
            elseif GetSpecializationInfoByID then
                lootName = select(2, GetSpecializationInfoByID(lootID))
            end
            GameTooltip:AddDoubleLine("Loot", lootName or "?", 1, 1, 1, ns.EUI:GetAccent())
        end
        local idx = GetSpecialization and GetSpecialization()
        if idx then
            local _, name = GetSpecializationInfo(idx)
            GameTooltip:AddDoubleLine("Active", name or "?", 1, 1, 1, 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Left-click: set loot spec"], 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["Right-click: open specialization"], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end,
    click = function(slot, button)
        if button == "RightButton" then
            ToggleSpec()
        else
            OpenLootMenu(slot)
        end
    end,
})
