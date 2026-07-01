--------------------------------------------------------------------------------
--  API/Events.lua  -  Internal message bus (pub/sub)
--
--  Lightweight in-addon messaging used to decouple config changes from the UI.
--  Config writes the DB and fires a fine-grained message (e.g. FONT_CHANGED);
--  the relevant module listens and runs exactly the update it needs - no full
--  rebuild, no /reload. This is NOT a Blizzard-event wrapper (the EllesmereUI
--  Lite addon object already provides RegisterEvent for game events).
--------------------------------------------------------------------------------
local _, ns = ...
local Events = ns.Events
local D = ns.Debug

local listeners = {}   -- message -> array of callbacks

--- Subscribe `callback(...)` to `message`. Returns the callback (for symmetry).
function Events:Register(message, callback)
    assert(type(message) == "string", "Events:Register requires a message string")
    assert(type(callback) == "function", "Events:Register requires a callback")
    local list = listeners[message]
    if not list then list = {}; listeners[message] = list end
    list[#list + 1] = callback
    return callback
end

--- Remove a previously registered callback from `message`.
function Events:Unregister(message, callback)
    local list = listeners[message]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == callback then table.remove(list, i) end
    end
end

--- Fire `message`, invoking every subscriber with the supplied arguments.
--- Each callback runs in a protected call so one bad listener cannot break the
--- dispatch chain; failures are logged when Debug Mode is on.
function Events:Fire(message, ...)
    local list = listeners[message]
    if not list then return end
    for i = 1, #list do
        local ok, err = xpcall(list[i], geterrorhandler(), ...)
        if not ok then D.Log("listener for %s errored: %s", message, tostring(err)) end
    end
end
