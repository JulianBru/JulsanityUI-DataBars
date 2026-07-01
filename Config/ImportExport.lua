--------------------------------------------------------------------------------
--  Config/ImportExport.lua  -  Profile serialization (export / import strings)
--
--  Serializes the active profile to a portable, printable string and back.
--  Uses LibDeflate (bundled with EllesmereUI) for compression + print-safe
--  encoding when available; otherwise falls back to a plain Lua literal so the
--  feature still works. Deserialization runs the literal in an EMPTY
--  environment, so an imported string cannot call game/Lua globals.
--------------------------------------------------------------------------------
local _, ns = ...
local Serial = ns.Serial
local D = ns.Debug

local LibDeflate = LibStub and LibStub("LibDeflate", true)

local PREFIX_COMPRESSED = "JDB1:"
local PREFIX_PLAIN      = "JDB0:"

--------------------------------------------------------------------------------
--  Lua-literal serializer (scalars + nested tables only)
--------------------------------------------------------------------------------
local SerializeValue

local function SerializeKey(k)
    if type(k) == "number" then
        return "[" .. k .. "]"
    end
    return "[" .. string.format("%q", tostring(k)) .. "]"
end

SerializeValue = function(v)
    local t = type(v)
    if t == "number" then
        -- %.14g preserves enough precision without locale issues.
        return string.format("%.14g", v)
    elseif t == "boolean" then
        return v and "true" or "false"
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" then
        local parts = { "{" }
        -- Array part first for compactness, then hash part.
        local arrayN = #v
        for i = 1, arrayN do
            parts[#parts + 1] = SerializeValue(v[i]) .. ","
        end
        for k, val in pairs(v) do
            local isArrayIndex = (type(k) == "number" and k >= 1 and k <= arrayN and k == math.floor(k))
            if not isArrayIndex then
                parts[#parts + 1] = SerializeKey(k) .. "=" .. SerializeValue(val) .. ","
            end
        end
        parts[#parts + 1] = "}"
        return table.concat(parts)
    end
    -- Unsupported types (functions, userdata) are dropped as nil.
    return "nil"
end

--------------------------------------------------------------------------------
--  Export
--------------------------------------------------------------------------------

--- Serialize the active profile to a portable string.
function Serial:Export()
    local snapshot = ns.DB:Snapshot()
    local literal = "return " .. SerializeValue(snapshot)

    if LibDeflate then
        local compressed = LibDeflate:CompressDeflate(literal, { level = 9 })
        local encoded = LibDeflate:EncodeForPrint(compressed)
        return PREFIX_COMPRESSED .. encoded
    end
    return PREFIX_PLAIN .. literal
end

--------------------------------------------------------------------------------
--  Import
--------------------------------------------------------------------------------

--- Parse an export string back into a profile table.
--  @return table on success; or nil, errorMessage on failure.
function Serial:Import(str)
    if type(str) ~= "string" or str == "" then
        return nil, "empty string"
    end
    str = str:gsub("^%s+", ""):gsub("%s+$", "")

    local literal
    if str:sub(1, #PREFIX_COMPRESSED) == PREFIX_COMPRESSED then
        if not LibDeflate then return nil, "LibDeflate required to decode this string" end
        local encoded = str:sub(#PREFIX_COMPRESSED + 1)
        local compressed = LibDeflate:DecodeForPrint(encoded)
        if not compressed then return nil, "could not decode string" end
        literal = LibDeflate:DecompressDeflate(compressed)
        if not literal then return nil, "could not decompress string" end
    elseif str:sub(1, #PREFIX_PLAIN) == PREFIX_PLAIN then
        literal = str:sub(#PREFIX_PLAIN + 1)
    else
        return nil, "unrecognized format"
    end

    -- Run in an empty environment so the literal cannot touch globals.
    local chunk, err = loadstring and loadstring(literal) or load(literal, "JDB-import", "t", {})
    if not chunk then return nil, "parse error: " .. tostring(err) end
    if setfenv then setfenv(chunk, {}) end   -- belt-and-braces on 5.1 hosts

    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
        return nil, "invalid data"
    end
    D.Log("imported profile string (%d bytes)", #str)
    return data
end
