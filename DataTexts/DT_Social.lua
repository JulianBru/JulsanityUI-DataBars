--------------------------------------------------------------------------------
--  DataTexts/DT_Social.lua  -  Social category
--    Friends - Guild - Mail
--------------------------------------------------------------------------------
local _, ns = ...
local U      = ns.Util
local Engine = ns.Engine
local Reg    = ns.RegisterDataText

local function AccentHex() return U.RGBToHex(ns.EUI:GetAccent()) end

--------------------------------------------------------------------------------
--  Friends  -  online WoW + Battle.net; click: friends list
--------------------------------------------------------------------------------
local function FriendCounts()
    local wowOnline = (C_FriendList and C_FriendList.GetNumOnlineFriends and C_FriendList.GetNumOnlineFriends()) or 0
    local wowTotal  = (C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetNumFriends()) or 0
    local bnTotal, bnOnline = 0, 0
    if BNGetNumFriends then bnTotal, bnOnline = BNGetNumFriends() end
    return wowOnline, wowTotal, bnOnline or 0, bnTotal or 0
end

Reg({
    name = "Friends", label = "Friends", category = "Social",
    events = {
        "FRIENDLIST_UPDATE", "PLAYER_ENTERING_WORLD",
        "BN_FRIEND_LIST_SIZE_CHANGED", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE",
    },
    update = function(slot)
        local wowOnline, _, bnOnline = FriendCounts()
        slot.text:SetFormattedText("|cff%s%d|r |cffaaaaaafriends|r", AccentHex(), wowOnline + bnOnline)
    end,
    enter = function(slot)
        local wowOnline, wowTotal, bnOnline, bnTotal = FriendCounts()
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Friends", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("WoW", wowOnline .. " / " .. wowTotal, 1, 1, 1, 1, 1, 1)
        if bnTotal > 0 then
            GameTooltip:AddDoubleLine("Battle.net", bnOnline .. " / " .. bnTotal, 1, 1, 1, 0.36, 0.65, 1)
        end
        GameTooltip:Show()
    end,
    click = function()
        if ToggleFriendsFrame then ToggleFriendsFrame(1) end
    end,
})

--------------------------------------------------------------------------------
--  Guild  -  online guild members; tooltip: a few names; click: guild frame
--------------------------------------------------------------------------------
Reg({
    name = "Guild", label = "Guild", category = "Social",
    events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        if not IsInGuild() then
            slot.text:SetText("|cffaaaaaaNo Guild|r")
            return
        end
        if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
        local _, online = GetNumGuildMembers()
        slot.text:SetFormattedText("|cff%s%d|r |cffaaaaaaguild|r", AccentHex(), online or 0)
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Guild", 1, 1, 1)
        if not IsInGuild() then
            GameTooltip:AddLine("You are not in a guild.", 0.7, 0.7, 0.7)
            GameTooltip:Show()
            return
        end
        local total, online = GetNumGuildMembers()
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Online", (online or 0) .. " / " .. (total or 0), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddLine(" ")
        local shown = 0
        for i = 1, (total or 0) do
            local name, _, _, _, _, zone, _, _, isOnline = GetGuildRosterInfo(i)
            if isOnline and name and shown < 10 then
                shown = shown + 1
                name = Ambiguate(name, "guild")
                GameTooltip:AddDoubleLine(name, zone or "", 0.9, 0.9, 0.9, 0.6, 0.6, 0.6)
            end
        end
        if (online or 0) > shown then
            GameTooltip:AddLine(("... and %d more"):format(online - shown), 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end,
    click = function()
        if ToggleGuildFrame then ToggleGuildFrame() end
    end,
})

--------------------------------------------------------------------------------
--  Mail  -  unread indicator; tooltip: latest senders
--------------------------------------------------------------------------------
Reg({
    name = "Mail", label = "Mail", category = "Social",
    events = { "MAIL_INBOX_UPDATE", "UPDATE_PENDING_MAIL", "MAIL_CLOSED", "MAIL_SHOW", "PLAYER_ENTERING_WORLD" },
    update = function(slot)
        if HasNewMail and HasNewMail() then
            slot.text:SetFormattedText("|cff%sNew Mail|r", AccentHex())
        else
            slot.text:SetText("|cffaaaaaaNo Mail|r")
        end
    end,
    enter = function(slot)
        Engine.OpenTooltip(slot)
        GameTooltip:AddLine("Mail", 1, 1, 1)
        local hasMail = HasNewMail and HasNewMail()
        if hasMail and GetLatestThreeSenders then
            local senders = { GetLatestThreeSenders() }
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("New mail from:", 1, 1, 1)
            if #senders == 0 then
                GameTooltip:AddLine("  (unknown sender)", 0.8, 0.8, 0.8)
            end
            for _, s in ipairs(senders) do
                GameTooltip:AddLine("  " .. s, 0.9, 0.9, 0.9)
            end
        else
            GameTooltip:AddLine("No new mail.", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end,
})
