--------------------------------------------------------------------------------
--  Utils/Utils.lua  -  Pure helper functions (no side effects, no frames)
--
--  Small, reusable, side-effect-free helpers. Kept free of any EllesmereUI or
--  WoW UI dependency so they are trivially testable and reusable.
--------------------------------------------------------------------------------
local _, ns = ...
local U = ns.Util

local floor, min, max = math.floor, math.min, math.max
local format = string.format

--------------------------------------------------------------------------------
--  Numbers
--------------------------------------------------------------------------------

--- Clamp `v` into the inclusive range [lo, hi].
function U.Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

--- Round to the nearest integer (half away from zero).
function U.Round(v)
    if v >= 0 then return floor(v + 0.5) end
    return -floor(-v + 0.5)
end

--- Round to `decimals` places.
function U.RoundTo(v, decimals)
    local m = 10 ^ (decimals or 0)
    return U.Round(v * m) / m
end

--- Abbreviate large numbers: 1500 -> "1.5k", 2_000_000 -> "2.0m".
function U.ShortValue(v)
    v = v or 0
    if v >= 1e9 then return format("%.1fb", v / 1e9) end
    if v >= 1e6 then return format("%.1fm", v / 1e6) end
    if v >= 1e3 then return format("%.1fk", v / 1e3) end
    return tostring(v)
end

--- Seconds -> compact duration string ("3d 4h", "2h 15m", "45m", "30s").
function U.FormatDuration(s)
    if not s or s <= 0 then return "--" end
    s = floor(s)
    local d = floor(s / 86400); s = s % 86400
    local h = floor(s / 3600);  s = s % 3600
    local m = floor(s / 60);    local sec = s % 60
    if d > 0 then return format("%dd %dh", d, h) end
    if h > 0 then return format("%dh %dm", h, m) end
    if m > 0 then return format("%dm", m) end
    return format("%ds", sec)
end

--------------------------------------------------------------------------------
--  Colour
--------------------------------------------------------------------------------

--- r,g,b in 0..1 -> "rrggbb" hex (for |cffRRGGBB escape codes).
function U.RGBToHex(r, g, b)
    return format("%02x%02x%02x",
        U.Clamp(floor((r or 1) * 255), 0, 255),
        U.Clamp(floor((g or 1) * 255), 0, 255),
        U.Clamp(floor((b or 1) * 255), 0, 255))
end

--- Wrap `text` in a colour escape. Accepts r,g,b (0..1).
function U.Colorize(text, r, g, b)
    return "|cff" .. U.RGBToHex(r, g, b) .. tostring(text) .. "|r"
end

--- Linear interpolation between two colours by t in [0,1].
function U.LerpColor(t, r1, g1, b1, r2, g2, b2)
    t = U.Clamp(t, 0, 1)
    return r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t
end

--------------------------------------------------------------------------------
--  Tables
--------------------------------------------------------------------------------

--- Deep copy a table (recursively). Non-tables returned as-is.
function U.DeepCopy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do
        out[k] = (type(v) == "table") and U.DeepCopy(v) or v
    end
    return out
end

--- Recursively fill missing keys of `dest` from `defaults` (defaults win only
--- where dest is nil). Returns dest.
function U.MergeDefaults(dest, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then dest[k] = {} end
            U.MergeDefaults(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
    return dest
end

--- Shallow count of a table's keys.
function U.Count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--- Return a sorted array of the table's string keys.
function U.SortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

--- True if `value` exists in array `list`.
function U.Contains(list, value)
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end
