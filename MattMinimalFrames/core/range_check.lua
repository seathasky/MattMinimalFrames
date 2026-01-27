-- core/range_check.lua
-- Range check module for MattMinimalFrames
-- Uses compat.lua for version-specific spell tables and APIs

local Compat = _G.MMF_Compat

-- Cache from compat layer
local GetSpellName = Compat.GetSpellName
local IsSpellInRange = Compat.IsSpellInRange
local friendSpells = Compat.FriendSpells
local harmSpells = Compat.HarmSpells

-- Cache WoW API functions
local UnitExists = UnitExists
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local GetTime = GetTime

local playerClass = UnitClassBase("player")

--------------------------------------------------
-- RANGE CHECK LOGIC
--------------------------------------------------

local function IsUnitInRange(unit)
    if not UnitExists(unit) then
        return false
    end

    -- Always return true for player unit
    if unit == "player" then
        return true
    end

    local isFriendly = UnitCanAssist("player", unit)
    local isHostile = UnitCanAttack("player", unit)

    -- Pick the appropriate spell for range checking
    local spell = isFriendly and friendSpells[playerClass] or isHostile and harmSpells[playerClass]

    if spell then
        local spellName = GetSpellName(spell)
        if spellName then
            local inRange = IsSpellInRange(spellName, unit)
            -- Convert to boolean (TBC returns 1/0, retail may return true/false)
            return (inRange == 1 or inRange == true)
        end
    end

    -- If no spell-based checks work, assume in range
    return true
end

--------------------------------------------------
-- ALPHA FADE ANIMATION
--------------------------------------------------

local function Lerp(startVal, endVal, pct)
    return startVal + (endVal - startVal) * pct
end

local function UpdateFrameRange(frame, unit)
    if not frame then return end
    
    if not UnitExists(unit) then
        frame:SetAlpha(1)
        return
    end

    local inRange = IsUnitInRange(unit)
    local targetAlpha = inRange and 1 or 0.5
    local currentAlpha = frame:GetAlpha()

    if currentAlpha ~= targetAlpha then
        frame.fadeInfo = frame.fadeInfo or {}
        frame.fadeInfo.startAlpha = currentAlpha
        frame.fadeInfo.targetAlpha = targetAlpha
        frame.fadeInfo.startTime = GetTime()
        frame.fadeInfo.duration = 0.2

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

--------------------------------------------------
-- UPDATE ALL FRAMES
--------------------------------------------------

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

--------------------------------------------------
-- EVENT HANDLING
--------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_TARGET")

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" or 
       event == "PLAYER_FOCUS_CHANGED" or 
       event == "UNIT_TARGET" or
       unit == "target" or 
       unit == "focus" or 
       unit == "targettarget" then
        UpdateAllFrames()
        C_Timer.After(0.1, UpdateAllFrames)
    end
end)

--------------------------------------------------
-- PERIODIC UPDATE
--------------------------------------------------

local updateThrottle = 0
local rangeUpdater = CreateFrame("Frame")
rangeUpdater:SetScript("OnUpdate", function(self, elapsed)
    updateThrottle = updateThrottle + elapsed
    if updateThrottle >= 0.2 then
        updateThrottle = 0
        UpdateAllFrames()
    end
end)
