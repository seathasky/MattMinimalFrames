local Compat = _G.MMF_Compat

local GetSpellName = Compat.GetSpellName
local IsSpellInRange = Compat.IsSpellInRange
local friendSpells = Compat.FriendSpells
local harmSpells = Compat.HarmSpells

local UnitExists = UnitExists
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local GetTime = GetTime

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

local function IsUnitInRange(unit)
    if not UnitExists(unit) then
        return false
    end

    if unit == "player" then
        return true
    end

    local isFriendly = UnitCanAssist("player", unit)
    local isHostile = UnitCanAttack("player", unit)

    local spellName = isFriendly and friendSpellName or isHostile and harmSpellName

    if spellName then
        local inRange = IsSpellInRange(spellName, unit)
        return (inRange == 1 or inRange == true)
    end

    return true
end

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

    if UnitExists("targettarget") then
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
    if event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" then
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
