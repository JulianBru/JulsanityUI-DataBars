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

DB.SCHEMA_VERSION = 2

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
        },
        position = { point = "CENTER", relPoint = "CENTER", x = 0, y = -200 },
    }
end

-- Build a fresh default profile (two bars).
local function DefaultProfile()
    local main = BaseBar()

    local mm = BaseBar()
    mm.attach            = "minimap"          -- sit under the minimap by default
    mm.layout.width      = 200
    mm.behavior.numSlots = 2
    mm.behavior.slots    = { "System", "Guild" }
    -- Fallback position (used only if the player detaches it from the minimap).
    mm.position          = { point = "TOP", relPoint = "CENTER", x = 0, y = 0 }

    return {
        bars     = { main, mm },
        advanced = { debug = false },
    }
end

local DEFAULT_PROFILE = DefaultProfile()
ns.DEFAULT_PROFILE = DEFAULT_PROFILE

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
