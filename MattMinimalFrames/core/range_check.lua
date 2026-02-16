local Compat = _G.MMF_Compat

local GetSpellName = Compat.GetSpellName
local IsSpellInRange = Compat.IsSpellInRange
local friendSpells = Compat.FriendSpells
local harmSpells = Compat.HarmSpells

local UnitExists = UnitExists
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local UnitIsUnit = UnitIsUnit
local UnitInRange = UnitInRange
local CheckInteractDistance = CheckInteractDistance
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime
local Scrub = scrub

local playerClass = UnitClassBase("player")
local friendSpellID = friendSpells[playerClass]
local harmSpellID = harmSpells[playerClass]
local friendSpellName
local harmSpellName

local function RefreshRangeSpellNames()
    friendSpellName = friendSpellID and GetSpellName(friendSpellID) or nil
    harmSpellName = harmSpellID and GetSpellName(harmSpellID) or nil
end

RefreshRangeSpellNames()

local function ScrubValue(value)
    if not Scrub then
        return value
    end

    local ok, scrubbed = pcall(Scrub, value)
    if ok then
        return scrubbed
    end

    return nil
end

local function SafeCall(func, ...)
    if not func then
        return nil, nil
    end

    local ok, value1, value2 = pcall(func, ...)
    if not ok then
        return nil, nil
    end

    return ScrubValue(value1), ScrubValue(value2)
end

local function NormalizeBooleanResult(value)
    local scrubbed = ScrubValue(value)
    if type(scrubbed) == "boolean" then
        return scrubbed
    end
    return nil
end

local function NormalizeRangeResult(value)
    local boolValue = NormalizeBooleanResult(value)
    if boolValue ~= nil then
        return boolValue
    end

    local scrubbed = ScrubValue(value)
    local valueType = type(scrubbed)

    if valueType == "number" then
        local ok, normalized = pcall(function()
            if scrubbed > 0 then
                return true
            end
            if scrubbed == 0 then
                return false
            end
            return nil
        end)

        if ok then
            return normalized
        end
    end

    return nil
end

local function IsUnitInRange(unit)
    if NormalizeBooleanResult(SafeCall(UnitExists, unit)) ~= true then
        return false
    end

    -- Self-target can be represented as "target"; never treat self as out of range.
    if unit == "player" or (UnitIsUnit and NormalizeBooleanResult(SafeCall(UnitIsUnit, unit, "player")) == true) then
        return true
    end

    local isFriendly = NormalizeBooleanResult(SafeCall(UnitCanAssist, "player", unit)) == true
    local isHostile = NormalizeBooleanResult(SafeCall(UnitCanAttack, "player", unit)) == true

    local spellName = isFriendly and friendSpellName or isHostile and harmSpellName

    if spellName and IsSpellInRange then
        local rawRange = SafeCall(IsSpellInRange, spellName, unit)
        local inRange = NormalizeRangeResult(rawRange)
        if inRange ~= nil then
            return inRange
        end
    end

    if isFriendly and UnitInRange then
        local rawPartyRange, checkedPartyRange = SafeCall(UnitInRange, unit)
        if NormalizeBooleanResult(checkedPartyRange) == true then
            local partyRange = NormalizeRangeResult(rawPartyRange)
            if partyRange ~= nil then
                return partyRange
            end
        end
    end

    -- Avoid protected-function taint in combat; this fallback is optional.
    local inCombat = InCombatLockdown and NormalizeBooleanResult(SafeCall(InCombatLockdown)) == true
    if CheckInteractDistance and not inCombat then
        local interact = SafeCall(CheckInteractDistance, unit, 4)
        local interactRange = NormalizeRangeResult(interact)
        if interactRange ~= nil then
            return interactRange
        end
    end

    -- If no API can determine range for this unit type, avoid false dimming.
    return true
end

local function Lerp(startVal, endVal, pct)
    return startVal + (endVal - startVal) * pct
end

local function UpdateFrameRange(frame, unit)
    if not frame then return end

    if NormalizeBooleanResult(SafeCall(UnitExists, unit)) ~= true then
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
            frame.fadeTimer:SetParent(frame)
        end

        frame.fadeTimer:SetScript("OnUpdate", function(self)
            local parent = self:GetParent()
            if not parent or not parent.fadeInfo then
                self:SetScript("OnUpdate", nil)
                return
            end

            local progress = (GetTime() - parent.fadeInfo.startTime) / parent.fadeInfo.duration
            if progress >= 1 then
                parent:SetAlpha(parent.fadeInfo.targetAlpha)
                parent.fadeInfo = nil
                self:SetScript("OnUpdate", nil)
            else
                local newAlpha = Lerp(parent.fadeInfo.startAlpha, parent.fadeInfo.targetAlpha, progress)
                parent:SetAlpha(newAlpha)
            end
        end)
    end
end

local function ResetFrameAlpha(frame)
    if frame then
        frame:SetAlpha(1)
        frame.fadeInfo = nil
        if frame.fadeTimer then
            frame.fadeTimer:SetScript("OnUpdate", nil)
        end
    end
end

local function UpdateAllFrames()
    UpdateFrameRange(MMF_TargetFrame, "target")

    if NormalizeBooleanResult(SafeCall(UnitExists, "targettarget")) == true then
        UpdateFrameRange(MMF_TargetOfTargetFrame, "targettarget")
    else
        ResetFrameAlpha(MMF_TargetOfTargetFrame)
    end

    UpdateFrameRange(MMF_FocusFrame, "focus")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_TARGET")

eventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" or
       event == "SPELLS_CHANGED" then
        RefreshRangeSpellNames()
    end

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

local updateThrottle = 0
local rangeUpdater = CreateFrame("Frame")
rangeUpdater:SetScript("OnUpdate", function(_, elapsed)
    updateThrottle = updateThrottle + elapsed
    if updateThrottle >= 0.2 then
        updateThrottle = 0
        UpdateAllFrames()
    end
end)
