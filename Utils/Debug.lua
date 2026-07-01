--------------------------------------------------------------------------------
--  Utils/Debug.lua  -  Debug logger (toggleable via the Debug Mode option)
--
--  All diagnostic output flows through here. When Debug Mode is off, calls are
--  near-zero cost (a single boolean check). A small ring buffer keeps the last
--  N messages so `/jdbar debug dump` can show recent activity even if the user
--  wasn't watching chat.
--------------------------------------------------------------------------------
local _, ns = ...
local D = ns.Debug

local BUFFER_SIZE = 200
local buffer = {}
local head = 0

-- Resolved lazily: depends on the active profile (advanced.debug). The Database
-- layer flips this via D.SetEnabled when the profile loads or the option changes.
local enabled = false

--- Enable/disable debug output. Called by Database/Config when the option changes.
function D.SetEnabled(state)
    enabled = state and true or false
end

function D.IsEnabled()
    return enabled
end

--- Log a message. Accepts a format string + args, or plain values.
-- @param fmt  format string (or first value)
-- @param ...  format arguments
function D.Log(fmt, ...)
    local msg
    if type(fmt) == "string" and select("#", ...) > 0 then
        -- Guard against malformed format strings.
        local ok, res = pcall(string.format, fmt, ...)
        msg = ok and res or fmt
    else
        local parts = { fmt, ... }
        for i = 1, #parts do parts[i] = tostring(parts[i]) end
        msg = table.concat(parts, " ")
    end

    -- Ring buffer (always recorded, even when output is off).
    head = (head % BUFFER_SIZE) + 1
    buffer[head] = ("[%s] %s"):format(date("%H:%M:%S"), msg)

    if enabled then
        ns.Print("|cff999999[debug]|r " .. msg)
    end
end

--- Dump the recent ring-buffer contents to chat (used by the slash command).
function D.Dump()
    ns.Print(("debug log (last %d entries):"):format(math.min(BUFFER_SIZE, ns.Util.Count(buffer))))
    -- Print in chronological order starting just after head.
    for i = 1, BUFFER_SIZE do
        local idx = ((head + i - 1) % BUFFER_SIZE) + 1
        local line = buffer[idx]
        if line and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
        end
    end
end
