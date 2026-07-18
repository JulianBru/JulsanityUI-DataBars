--------------------------------------------------------------------------------
--  Core/Database.lua  -  Standalone SavedVariables + modular profile system
--
--  Independent of ElvUI *and* of EllesmereUI's profile store. All data lives in
--  the addon's own SavedVariables table `JulsanityDataBarsDB`, declared in the
--  .toc.
--
--  A profile now holds an array of bar configs: profile.bars[1] = main bar,
--  profile.bars[2] = minimap bar. Each bar config is fully independent
--  (layout / appearance / behavior / position / enabled / attach). `advanced`
--  stays profile-global. Schema v1 (single top-level bar) is migrated into
--  bars[1] automatically.
--------------------------------------------------------------------------------
local _, ns = ...
local DB = ns.DB or {}
ns.DB = DB

local U  = ns.Util
local D  = ns.Debug

DB.SCHEMA_VERSION = 3

--------------------------------------------------------------------------------
--  Defaults
--------------------------------------------------------------------------------
-- A single bar's default config. Shared shape for every bar; per-bar tweaks are
-- applied in DefaultProfile() below.
local function BaseBar()
    return {
        enabled = true,
        attach  = "free",        -- "free" (UIParent coords) | "minimap" (under minimap)
        layout = {
            autoSize    = true,
            width       = 400,
            widthOffset = 0,
            height      = 22,
            padding     = 4,
            margin      = 0,
            spacing     = 8,
            orientation = "HORIZONTAL",
            growth      = "RIGHT",
        },
        appearance = {
            font        = nil,
            fontSize    = 12,
            fontOutline = "NONE",
            textColor   = { 1, 1, 1, 0.9 },
            useCustomTextColor = false,   -- true = colour datatext values with textColor
            bgColor     = { 0.03, 0.045, 0.05, 0.9 },
            bgTexture   = nil,       -- nil = solid colour; else a LibSharedMedia statusbar name
            border      = true,
            borderSize  = 1,
            borderColor = { 0, 0, 0, 1 },
            shadow      = true,
            showSeparators = false,   -- thin line between slots
            separatorUseAccent = true,   -- true = EllesmereUI accent; false = custom
            separatorColor = { 0.5, 0.5, 0.5, 0.6 },
            hidePrefix  = false,     -- hide datatext labels/prefixes (Dur, ilvl, ...)
            alpha       = 1.0,
            mouseoverFade = false,
            fadeAlpha   = 0.0,
            autoHide    = false,
        },
        behavior = {
            numSlots     = 5,
            slots        = { "Friends", "Difficulty", "Loot Spec", "Gold", "Durability" },
            lockPosition = false,
            snap         = true,
            slotOptions  = {},       -- per-slot datatext options (by slot index)
        },
        position = { point = "CENTER", relPoint = "CENTER", x = 0, y = -200 },
    }
end

-- Build a fresh default profile (two bars).
local function DefaultProfile()
    local main = BaseBar()
    main.kind = "main"
    main.id   = "Main"

    local mm = BaseBar()
    mm.kind              = "minimap"
    mm.id                = "Minimap"
    mm.attach            = "minimap"          -- sit under the minimap by default
    mm.layout.width      = 200
    mm.behavior.numSlots = 2
    mm.behavior.slots    = { "System", "Guild" }
    -- Fallback position (used only if the player detaches it from the minimap).
    mm.position          = { point = "TOP", relPoint = "CENTER", x = 0, y = 0 }

    return {
        bars     = { main, mm },
        barSeq   = 0,             -- monotonic counter for stable custom-bar ids
        advanced = { debug = false },
    }
end

-- Build a fresh free-floating custom bar config (index 3+).
local function NewCustomBar(uid, ordinal)
    local b = BaseBar()
    b.kind               = "custom"
    b.id                 = "Custom" .. uid
    b.name               = "Bar " .. ordinal
    b.attach             = "free"
    b.layout.autoSize    = false
    b.layout.width       = 250
    b.behavior.numSlots  = 2
    b.behavior.slots     = { "None", "None" }
    b.position           = { point = "CENTER", relPoint = "CENTER", x = 0, y = -240 - (ordinal - 3) * 26 }
    return b
end

local DEFAULT_PROFILE = DefaultProfile()
ns.DEFAULT_PROFILE = DEFAULT_PROFILE

-- Account-wide settings, independent of the profile (General tab).
local DEFAULT_GENERAL = {
    windowScale = 1.0,   -- scale of the standalone config window only
    minimap = {          -- minimap button (LibDBIcon-style), account-wide
        hide       = false,
        minimapPos = 225,   -- angle in degrees around the minimap
    },
}

--------------------------------------------------------------------------------
--  Internal state
--------------------------------------------------------------------------------
local sv          -- the global SavedVariables table
local activeName  -- name of the active profile
local profile     -- the active profile table (live reference)

--------------------------------------------------------------------------------
--  Migration
--------------------------------------------------------------------------------
local migrations = {
    -- v1 -> v2: move the old single top-level bar into profile.bars[1].
    [1] = function(svTable)
        for _, prof in pairs(svTable.profiles or {}) do
            if type(prof) == "table" and prof.layout and not prof.bars then
                prof.bars = {
                    {
                        enabled    = true,
                        attach     = "free",
                        layout     = prof.layout,
                        appearance = prof.appearance,
                        behavior   = prof.behavior,
                        position   = prof.position,
                    },
                }
                prof.layout, prof.appearance, prof.behavior, prof.position = nil, nil, nil, nil
            end
        end
    end,
    -- v2 -> v3: tag bars with kind/id/name and add the custom-bar id counter.
    [2] = function(svTable)
        for _, prof in pairs(svTable.profiles or {}) do
            if type(prof) == "table" and type(prof.bars) == "table" then
                if prof.bars[1] then
                    prof.bars[1].kind = prof.bars[1].kind or "main"
                    prof.bars[1].id   = prof.bars[1].id or "Main"
                end
                if prof.bars[2] then
                    prof.bars[2].kind = prof.bars[2].kind or "minimap"
                    prof.bars[2].id   = prof.bars[2].id or "Minimap"
                end
                for i = 3, #prof.bars do
                    local b = prof.bars[i]
                    if type(b) == "table" then
                        b.kind = b.kind or "custom"
                        b.id   = b.id or ("Custom" .. i)
                        b.name = b.name or ("Bar " .. i)
                    end
                end
                prof.barSeq = prof.barSeq or math.max(0, #prof.bars - 2)
            end
        end
    end,
}

local function RunMigrations()
    sv.dbVersion = sv.dbVersion or DB.SCHEMA_VERSION
    while sv.dbVersion < DB.SCHEMA_VERSION do
        local step = migrations[sv.dbVersion]
        if step then
            local ok, err = pcall(step, sv)
            if not ok then D.Log("migration %d failed: %s", sv.dbVersion, tostring(err)) end
        end
        sv.dbVersion = sv.dbVersion + 1
    end
end

--------------------------------------------------------------------------------
--  Profile resolution
--------------------------------------------------------------------------------
local function EnsureProfile(name)
    sv.profiles[name] = sv.profiles[name] or {}
    U.MergeDefaults(sv.profiles[name], DEFAULT_PROFILE)
    return sv.profiles[name]
end

local function BindActiveProfile()
    profile = EnsureProfile(activeName)
    if ns.RebuildBarDefs then ns.RebuildBarDefs() end   -- keep ns.BARS in sync
    D.SetEnabled(profile.advanced and profile.advanced.debug)
end

--------------------------------------------------------------------------------
--  Public API
--------------------------------------------------------------------------------
function DB:Initialize()
    if JulsanityDataBarsDB == nil then JulsanityDataBarsDB = {} end
    sv = JulsanityDataBarsDB

    sv.profiles      = sv.profiles or {}
    sv.activeProfile = sv.activeProfile or "Default"
    sv.profileKeys   = sv.profileKeys or {}

    -- Account-wide settings (General tab): scale + minimap button.
    sv.general = sv.general or {}
    U.MergeDefaults(sv.general, DEFAULT_GENERAL)

    RunMigrations()

    activeName = sv.activeProfile
    if type(activeName) ~= "string" or activeName == "" then activeName = "Default" end
    BindActiveProfile()

    D.Log("database initialized (profile '%s', schema v%d)", activeName, sv.dbVersion)
end

function DB:GetProfile()        return profile end
function DB:GetActiveName()     return activeName end
function DB:GetProfileNames()   return U.SortedKeys(sv.profiles) end
function DB:Exists(name)        return sv.profiles[name] ~= nil end

function DB:CreateProfile(name)
    if not name or name == "" or sv.profiles[name] then return false end
    EnsureProfile(name)
    D.Log("created profile '%s'", name)
    return true
end

function DB:CopyProfile(fromName, toName)
    if not sv.profiles[fromName] or not toName or toName == "" then return false end
    sv.profiles[toName] = U.DeepCopy(sv.profiles[fromName])
    if toName == activeName then BindActiveProfile() end
    D.Log("copied profile '%s' -> '%s'", fromName, toName)
    return true
end

function DB:DeleteProfile(name)
    if name == activeName or name == "Default" or not sv.profiles[name] then return false end
    sv.profiles[name] = nil
    D.Log("deleted profile '%s'", name)
    return true
end

function DB:SetActive(name)
    if not sv.profiles[name] or name == activeName then return false end
    activeName       = name
    sv.activeProfile = name
    BindActiveProfile()
    D.Log("active profile -> '%s'", name)
    ns.Events:Fire(ns.MSG.PROFILE_CHANGED)
    return true
end

function DB:ResetActive()
    wipe(sv.profiles[activeName])
    U.MergeDefaults(sv.profiles[activeName], DEFAULT_PROFILE)
    BindActiveProfile()
    D.Log("reset profile '%s' to defaults", activeName)
    ns.Events:Fire(ns.MSG.PROFILE_CHANGED)
    return true
end

function DB:ApplyImported(data)
    if type(data) ~= "table" then return false end
    wipe(sv.profiles[activeName])
    for k, v in pairs(data) do
        sv.profiles[activeName][k] = U.DeepCopy(v)
    end
    U.MergeDefaults(sv.profiles[activeName], DEFAULT_PROFILE)
    BindActiveProfile()
    D.Log("imported data into profile '%s'", activeName)
    ns.Events:Fire(ns.MSG.PROFILE_CHANGED)
    return true
end

function DB:Snapshot()
    return U.DeepCopy(profile)
end

--------------------------------------------------------------------------------
--  Dynamic bars (main + minimap are fixed; indices 3+ are custom)
--------------------------------------------------------------------------------
function DB:BarCount()
    return (profile and profile.bars and #profile.bars) or 0
end

function DB:CanAddBar()
    return self:BarCount() < (ns.MAX_BARS or 10)
end

-- Append a new custom bar. Returns its index, or false if at the cap.
function DB:AddBar()
    if not (profile and profile.bars) then return false end
    if #profile.bars >= (ns.MAX_BARS or 10) then return false end
    profile.barSeq = (profile.barSeq or 0) + 1
    local ordinal = #profile.bars + 1
    profile.bars[ordinal] = NewCustomBar(profile.barSeq, ordinal)
    if ns.RebuildBarDefs then ns.RebuildBarDefs() end
    D.Log("added bar #%d (id Custom%d)", ordinal, profile.barSeq)
    ns.Events:Fire(ns.MSG.PROFILE_CHANGED)
    return ordinal
end

-- Remove a custom bar (index >= 3). Main/minimap are protected.
function DB:RemoveBar(index)
    if not (profile and profile.bars) then return false end
    if type(index) ~= "number" or index <= 2 then return false end
    if not profile.bars[index] then return false end
    table.remove(profile.bars, index)
    if ns.RebuildBarDefs then ns.RebuildBarDefs() end
    D.Log("removed bar #%d (%d left)", index, #profile.bars)
    ns.Events:Fire(ns.MSG.PROFILE_CHANGED)
    return true
end

-- Rename a custom bar (index >= 3).
function DB:RenameBar(index, name)
    if not (profile and profile.bars and profile.bars[index]) then return false end
    if index <= 2 then return false end
    if type(name) == "string" then name = name:gsub("^%s+", ""):gsub("%s+$", "") end
    if not name or name == "" then return false end
    profile.bars[index].name = name
    if ns.RebuildBarDefs then ns.RebuildBarDefs() end
    ns.Events:Fire(ns.MSG.PROFILE_CHANGED)
    return true
end

--------------------------------------------------------------------------------
--  Convenience accessors
--------------------------------------------------------------------------------
-- ns.Cfg() returns the active profile table (has .bars and .advanced).
function ns.Cfg()
    return profile
end

-- ns.BarCfg(index) returns a single bar's config block.
function ns.BarCfg(index)
    return profile and profile.bars and profile.bars[index]
end

-- ns.General() returns the account-wide settings table (General tab).
function ns.General()
    return sv and sv.general
end
