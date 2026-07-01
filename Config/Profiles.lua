--------------------------------------------------------------------------------
--  Config/Profiles.lua  -  Profile management actions
--
--  Thin action layer between the config buttons and the database. Uses
--  EllesmereUI's native popups (ShowInputPopup / ShowConfirmPopup /
--  ShowExportPopup / ShowImportPopup) so the dialogs match the rest of the UI.
--------------------------------------------------------------------------------
local _, ns = ...
local Profiles = ns.Profiles
local DB = ns.DB
local L = ns.L

-- Re-draw whichever config UI is open (standalone window or EUI sidebar).
local function RefreshPanel()
    if ns.Config and ns.Config.RefreshOpen then ns.Config:RefreshOpen() end
end

--- Prompt for a name and create a new profile (then switch to it).
function Profiles:New()
    if not (EllesmereUI and EllesmereUI.ShowInputPopup) then return end
    EllesmereUI:ShowInputPopup({
        title       = L["New Profile"],
        message     = "Enter a name for the new profile:",
        confirmText = L["New Profile"],
        onConfirm   = function(name)
            name = name and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
            if name == "" then ns.Print("profile name cannot be empty."); return end
            if DB:Exists(name) then ns.Print("a profile named '" .. name .. "' already exists."); return end
            DB:CreateProfile(name)
            DB:SetActive(name)
            RefreshPanel()
            ns.Print("created and switched to profile '" .. name .. "'.")
        end,
    })
end

--- Prompt for a name and copy the active profile into it (then switch).
function Profiles:Copy()
    if not (EllesmereUI and EllesmereUI.ShowInputPopup) then return end
    local from = DB:GetActiveName()
    EllesmereUI:ShowInputPopup({
        title       = L["Copy Profile"],
        message     = "Copy '" .. from .. "' to a new profile named:",
        confirmText = L["Copy Profile"],
        onConfirm   = function(name)
            name = name and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
            if name == "" then ns.Print("profile name cannot be empty."); return end
            DB:CopyProfile(from, name)
            DB:SetActive(name)
            RefreshPanel()
            ns.Print("copied '" .. from .. "' to '" .. name .. "'.")
        end,
    })
end

--- Confirm + delete the active profile (switches to Default first).
function Profiles:Delete()
    local name = DB:GetActiveName()
    if name == "Default" then
        ns.Print("the Default profile cannot be deleted.")
        return
    end
    if not (EllesmereUI and EllesmereUI.ShowConfirmPopup) then return end
    EllesmereUI:ShowConfirmPopup({
        title       = L["Delete Profile"],
        message     = "Delete profile '" .. name .. "'? This cannot be undone.",
        confirmText = L["Delete Profile"],
        onConfirm   = function()
            DB:SetActive("Default")
            DB:DeleteProfile(name)
            RefreshPanel()
            ns.Print("deleted profile '" .. name .. "'.")
        end,
    })
end

--- Confirm + reset the active profile to defaults.
function Profiles:ResetActive()
    if not (EllesmereUI and EllesmereUI.ShowConfirmPopup) then return end
    EllesmereUI:ShowConfirmPopup({
        title       = L["Reset Profile"],
        message     = "Reset the active profile to default settings?",
        confirmText = L["Reset Profile"],
        onConfirm   = function()
            DB:ResetActive()
            RefreshPanel()
            ns.Print("profile reset to defaults.")
        end,
    })
end

--- Switch to an existing profile by name.
function Profiles:Switch(name)
    if DB:SetActive(name) then RefreshPanel() end
end

--- Show the export string for the active profile.
function Profiles:Export()
    local str = ns.Serial:Export()
    if EllesmereUI and EllesmereUI.ShowExportPopup then
        EllesmereUI:ShowExportPopup(str)
    else
        ns.Print("export string:")
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(str) end
    end
end

--- Prompt for an import string and apply it to the active profile.
function Profiles:Import()
    if not (EllesmereUI and EllesmereUI.ShowImportPopup) then return end
    EllesmereUI:ShowImportPopup(function(str)
        local data, err = ns.Serial:Import(str)
        if not data then
            ns.Print("import failed: " .. tostring(err))
            return
        end
        ns.DB:ApplyImported(data)
        RefreshPanel()
        ns.Print("profile imported.")
    end, L["Import Profile"], "Paste a JulsanityUI DataBars profile string below")
end
