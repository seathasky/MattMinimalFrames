-- Helper function to get a spell's name from its ID.
local function GetSpellName(spellID)
    -- Try the legacy global function first.
    if _G.GetSpellInfo then
        local name = _G.GetSpellInfo(spellID)
        if name then
            return name
        end
    end
    -- Fallback to the new API documented at Townlong-Yak.
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name
        end
    end
    error("GetSpellInfo API not available or failed for spellID: " .. tostring(spellID))
end

-- Cache WoW API functions
local UnitIsVisible         = UnitIsVisible
local UnitInRange           = UnitInRange
local UnitCanAssist         = UnitCanAssist
local UnitCanAttack         = UnitCanAttack
local IsSpellInRange        = (C_Spell and C_Spell.IsSpellInRange) and C_Spell.IsSpellInRange or IsSpellInRange
local UnitIsDead            = UnitIsDead

local playerClass = UnitClassBase("player")

-- **Class-Specific Spells for Range Checking**
local friendSpells = {
    DEATHKNIGHT = 47541,  -- Death Coil (Adding DK to friendly spells)
    DRUID      = 8936,    -- Regrowth
    EVOKER     = 355913,  -- Emerald Blossom
    MAGE       = 1459,    -- Arcane Intellect
    MONK       = 116670,  -- Vivify
    PALADIN    = 19750,   -- Flash of Light
    PRIEST     = 2061,    -- Flash Heal
    SHAMAN     = 8004,    -- Healing Surge
    WARLOCK    = 5697,    -- Unending Breath
}

local harmSpells = {
    DEATHKNIGHT = 49998,   -- Death Strike (changed from Death Coil)
    DEMONHUNTER = 185123,  -- Throw Glaive
    DRUID       = 5176,    -- Wrath
    EVOKER      = 362969,  -- Azure Strike
    HUNTER      = 75,      -- Auto Shot
    MAGE        = 116,     -- Frostbolt
    MONK        = 117952,  -- Crackling Jade Lightning
    PALADIN     = 20271,   -- Judgment
    PRIEST      = 589,     -- Shadow Word: Pain
    ROGUE       = 1752,    -- Sinister Strike
    SHAMAN      = 188196,  -- Lightning Bolt
    WARLOCK     = 234153,  -- Drain Life
    WARRIOR     = 355,     -- Taunt
}

-- **Function to Check if a Unit is in Range**
local function IsUnitInRange(unit)
    if not UnitExists(unit) then
        return false
    end

    -- Always return true for player unit
    if unit == "player" then
        return true
    end

    local isFriendly = UnitCanAssist("player", unit)
    local isHostile  = UnitCanAttack("player", unit)

    -- Pick the appropriate spell for range checking
    local spell = isFriendly and friendSpells[playerClass] or isHostile and harmSpells[playerClass]

    if spell then
        local spellName = GetSpellName(spell)
        if spellName then
            local inRange = IsSpellInRange(spellName, unit)
            -- Convert to boolean
            return (inRange == 1 or inRange == true)
        end
    end

    -- If no spell-based checks work, assume in range
    -- Note: UnitInRange returns secret values that addon code cannot use
    return true
end

-- Add Lerp function before UpdateFrameRange
local function Lerp(start, end_, pct)
    return start + (end_ - start) * pct
end

-- **Update Frame Alpha Based on Range**
local function UpdateFrameRange(frame, unit)
    if not frame then return end
    
    if not UnitExists(unit) then
        frame:SetAlpha(1)
        return
    end

    -- Use our custom spell-based range check instead of UnitInRange
    -- UnitInRange returns secret values that addon code cannot use
    local inRange = IsUnitInRange(unit)
    local targetAlpha = inRange and 1 or 0.5
    local currentAlpha = frame:GetAlpha()

    if currentAlpha ~= targetAlpha then
        -- Always create or update fade info
        frame.fadeInfo = frame.fadeInfo or {}
        frame.fadeInfo.startAlpha = currentAlpha
        frame.fadeInfo.targetAlpha = targetAlpha
        frame.fadeInfo.startTime = GetTime()
        frame.fadeInfo.duration = 0.2

        -- Create the fade timer if it doesn't exist
        if not frame.fadeTimer then
            frame.fadeTimer = CreateFrame("Frame")
            frame.fadeTimer:SetScript("OnUpdate", function(self, elapsed)
                local parent = self:GetParent()
                if not parent.fadeInfo then return end

                local progress = (GetTime() - parent.fadeInfo.startTime) / parent.fadeInfo.duration
                if progress >= 1 then
                    parent:SetAlpha(parent.fadeInfo.targetAlpha)
                    parent.fadeInfo = nil
                else
                    local newAlpha = Lerp(parent.fadeInfo.startAlpha, parent.fadeInfo.targetAlpha, progress)
                    parent:SetAlpha(newAlpha)
                end
            end)
            frame.fadeTimer:SetParent(frame)
        end
    end
end

-- **Update All Frames**
local function UpdateAllFrames()
    UpdateFrameRange(MMF_TargetFrame, "target")
    
    -- Only update targettarget if target exists
    if UnitExists("target") then
        if UnitExists("targettarget") then
            UpdateFrameRange(MMF_TargetOfTargetFrame, "targettarget")
        else
            if MMF_TargetOfTargetFrame then
                MMF_TargetOfTargetFrame:SetAlpha(1)
            end
        end
    end
    
    -- Update focus
    UpdateFrameRange(MMF_FocusFrame, "focus")
end

-- **Register Events**
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("SPELLS_CHANGED")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_FOCUS_CHANGED")
f:RegisterEvent("UNIT_TARGET")

f:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" or 
       event == "PLAYER_FOCUS_CHANGED" or 
       event == "UNIT_TARGET" or
       unit == "target" or 
       unit == "focus" or 
       unit == "targettarget" then
        UpdateAllFrames() -- Immediate update
        C_Timer.After(0.1, UpdateAllFrames) -- Delayed update for stability
    end
end)

-- **Ensure Range is Updated Periodically**
local updateThrottle = 0
local rangeUpdater = CreateFrame("Frame")
rangeUpdater:SetScript("OnUpdate", function(self, elapsed)
    updateThrottle = updateThrottle + elapsed
    if updateThrottle >= 0.2 then -- Check every 0.2 seconds instead of every frame
        updateThrottle = 0
        UpdateAllFrames()
    end
end)