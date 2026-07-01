--------------------------------------------------------------------------------
--  Modules/Slot.lua  -  Slot frame factory + per-bar pools
--
--  A slot is a Button with a `.text` FontString. Each bar owns its own pool
--  (bar.pool), so slots never leak between bars. Slots are created once and
--  reused (pooled) so changing the slot count never churns frames. Every slot
--  carries `_bar` so the engine can route auto-size relayouts to the owning bar.
--------------------------------------------------------------------------------
local _, ns = ...
local Slot = ns.Slot

--- Create a brand-new slot button parented to a bar frame.
local function CreateSlot(bar, index)
    local b = CreateFrame("Button", "JulsanityDataBarSlot_" .. bar.def.id .. "_" .. index, bar.frame)
    b:RegisterForClicks("AnyUp")
    b:EnableMouse(false)

    local fs = b:CreateFontString(nil, "OVERLAY")
    -- Set a default font immediately: on 12.0, SetText() on a font-less
    -- FontString errors ("Font not set"). The Renderer overrides this later.
    fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(false)
    b.text = fs

    b.index = index
    b._bar  = bar
    return b
end

--- Get (creating if needed) the pooled slot for `index` on `bar`.
function Slot.Acquire(bar, index)
    local pool = bar.pool
    local b = pool[index]
    if not b then
        b = CreateSlot(bar, index)
        pool[index] = b
    end
    b._bar = bar
    b:SetParent(bar.frame)
    b:Show()
    return b
end

--- The slot at `index` on `bar`, or nil.
function Slot.Get(bar, index)
    return bar.pool[index]
end

--- Unbind + hide every pooled slot on `bar` whose index is greater than `keep`.
function Slot.HideFrom(bar, keep)
    local pool = bar.pool
    local i = keep + 1
    while pool[i] do
        ns.Engine.Unbind(pool[i])
        pool[i]:Hide()
        i = i + 1
    end
end

--- Number of slots ever created for `bar` (pool high-water mark).
function Slot.PoolSize(bar)
    local n = 0
    while bar.pool[n + 1] do n = n + 1 end
    return n
end
