local cfg = MMF_Config
local Compat = _G.MMF_Compat
local lastUpdate = 0

local UnitExists = UnitExists
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitName = UnitName
local UnitPowerType = UnitPowerType
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitClassBase = UnitClassBase
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetDetailedHealPrediction = UnitGetDetailedHealPrediction
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local PowerBarColor = PowerBarColor

local IS_PLAYER_SHAMAN = (UnitClassBase("player") == "SHAMAN")

local function SafeEq(a, b)
    local ok, result = pcall(function()
        return a == b
    end)
    return ok and result or false
end

--------------------------------------------------
-- HEAL PREDICTION UPDATE
--------------------------------------------------

local function UpdateHealPrediction(frame)
    if not frame or not frame.myHealPrediction then return end

    local unit = frame.unit
    if not unit or not UnitExists(unit) then
        frame.myHealPrediction:Hide()
        frame.otherHealPrediction:Hide()
        return
    end

    if MattMinimalFramesDB and MattMinimalFramesDB.showHealPrediction == false then
        frame.myHealPrediction:Hide()
        frame.otherHealPrediction:Hide()
        return
    end

    local maxHealth = UnitHealthMax(unit)
    local healthTexture = frame.healthBar:GetStatusBarTexture()
    local barWidth = frame.healthBar:GetWidth()

    frame.myHealPrediction:ClearAllPoints()
    frame.myHealPrediction:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT", 0, 0)
    frame.myHealPrediction:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT", 0, 0)
    frame.myHealPrediction:SetWidth(barWidth)
    frame.myHealPrediction:SetMinMaxValues(0, maxHealth)

    local myHealTexture = frame.myHealPrediction:GetStatusBarTexture()
    frame.otherHealPrediction:ClearAllPoints()
    frame.otherHealPrediction:SetPoint("TOPLEFT", myHealTexture, "TOPRIGHT", 0, 0)
    frame.otherHealPrediction:SetPoint("BOTTOMLEFT", myHealTexture, "BOTTOMRIGHT", 0, 0)
    frame.otherHealPrediction:SetWidth(barWidth)
    frame.otherHealPrediction:SetMinMaxValues(0, maxHealth)

    if Compat.IsRetail and frame.healPredictionCalculator and UnitGetDetailedHealPrediction then
        pcall(function()
            UnitGetDetailedHealPrediction(unit, "player", frame.healPredictionCalculator)
            local _, playerHeal, otherHeal = frame.healPredictionCalculator:GetIncomingHeals()
            frame.myHealPrediction:SetValue(playerHeal or 0)
            frame.otherHealPrediction:SetValue(otherHeal or 0)
        end)
    elseif UnitGetIncomingHeals then
        local myHeal = UnitGetIncomingHeals(unit, "player") or 0
        local allHeal = UnitGetIncomingHeals(unit) or 0
        frame.myHealPrediction:SetValue(myHeal)
        local otherHeal = 0
        pcall(function()
            otherHeal = allHeal - myHeal
        end)
        frame.otherHealPrediction:SetValue(otherHeal)
    end

    frame.myHealPrediction:Show()
    frame.otherHealPrediction:Show()
end

--------------------------------------------------
-- ABSORB BAR UPDATE
--------------------------------------------------

local function UpdateAbsorbBar(frame)
    if not frame or not frame.absorbBar then return end

    local unit = frame.unit
    if not unit or not UnitExists(unit) then
        frame.absorbBar:Hide()
        return
    end

    if MattMinimalFramesDB and MattMinimalFramesDB.showAbsorbBar == false then
        frame.absorbBar:Hide()
        return
    end

    if not UnitGetTotalAbsorbs then
        frame.absorbBar:Hide()
        return
    end

    local maxHealth = UnitHealthMax(unit)
    local barWidth = frame.healthBar:GetWidth()

    local anchorTexture
    if frame.otherHealPrediction and frame.otherHealPrediction:IsShown() then
        anchorTexture = frame.otherHealPrediction:GetStatusBarTexture()
    elseif frame.myHealPrediction and frame.myHealPrediction:IsShown() then
        anchorTexture = frame.myHealPrediction:GetStatusBarTexture()
    else
        anchorTexture = frame.healthBar:GetStatusBarTexture()
    end

    frame.absorbBar:ClearAllPoints()
    frame.absorbBar:SetPoint("TOPLEFT", anchorTexture, "TOPRIGHT", 0, 0)
    frame.absorbBar:SetPoint("BOTTOMLEFT", anchorTexture, "BOTTOMRIGHT", 0, 0)
    frame.absorbBar:SetWidth(barWidth)
    frame.absorbBar:SetMinMaxValues(0, maxHealth)

    pcall(function()
        local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0
        frame.absorbBar:SetValue(totalAbsorb)
    end)

    frame.absorbBar:Show()
end

--------------------------------------------------
-- UNIT FRAME UPDATE
--------------------------------------------------

local function UpdateUnitFrame(frame)
    if not frame or not frame.unit or not frame.nameText then return end
    local unit = frame.unit
    local hideNameText = MMF_IsNameTextHidden and MMF_IsNameTextHidden(unit)
    local hideHPText = MMF_IsHPTextHidden and MMF_IsHPTextHidden(unit)

    if hideNameText then
        frame.nameText:SetText("")
        frame.nameText:Hide()
    elseif not UnitExists(unit) then
        frame.nameText:SetText("")
        frame.nameText:Show()
    else
        frame.nameText:Show()
        local unitName = UnitName(unit)
        if unit == "targettarget" then
            -- Avoid string ops on unit names: in some restricted contexts (e.g. dungeons)
            -- Blizzard may provide a protected "secret string" that errors on Lua manipulation.
            frame.nameText:SetText(unitName or "")
            frame.nameText:SetWidth(frame.originalWidth - 4)
        else
            frame.nameText:SetText(unitName)
            frame.nameText:SetWidth(frame.originalWidth - 4)
        end
    end

    local maxHP = UnitHealthMax(unit)
    local hp = UnitHealth(unit)

    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, maxHP)
        frame.healthBar:SetValue(hp)
    end

    if frame.hpText and (unit == "player" or unit == "target") then
        if hideHPText then
            frame.hpText:SetText("")
            frame.hpText:Hide()
        else
            frame.hpText:SetText(hp)
            frame.hpText:Show()
        end
    end

    UpdateHealPrediction(frame)
    UpdateAbsorbBar(frame)

    if unit == "targettarget" or unit == "pet" then
        if frame.hpText then frame.hpText:Hide() end
        if frame.powerText then frame.powerText:Hide() end
    else
        if frame.powerText then frame.powerText:Hide() end
    end

    local r, g, b = MMF_GetUnitColor(unit)
    if frame.healthBar then
        frame.healthBar:SetStatusBarColor(r, g, b, 1)
    end

    if frame.powerBar and (unit == "player" or unit == "target") then
        local powerType = UnitPowerType(unit)

        local useManaPowerType = false
        if unit == "player" and IS_PLAYER_SHAMAN and Compat.HasSpecialization then
            local spec = Compat.GetSpecialization()
            if SafeEq(spec, 1) or SafeEq(spec, 2) then
                useManaPowerType = true
                powerType = 0
            end
        end

        local maxPower = useManaPowerType and UnitPowerMax(unit, 0) or UnitPowerMax(unit)
        local power = useManaPowerType and UnitPower(unit, 0) or UnitPower(unit)
        local hasPower = false
        pcall(function()
            hasPower = (maxPower and maxPower > 0) and true or false
        end)

        if hasPower then
            frame.powerBar:SetMinMaxValues(0, maxPower)
            frame.powerBar:SetValue(power)

            local powerColor
            pcall(function()
                powerColor = PowerBarColor[powerType]
            end)
            local pr, pg, pb = 1, 1, 1
            local isManaPowerType = false
            pcall(function()
                isManaPowerType = (powerType == 0)
            end)
            if isManaPowerType then
                pr, pg, pb = 0.2, 0.7, 1
            elseif powerColor then
                pr, pg, pb = powerColor.r, powerColor.g, powerColor.b
            end

            frame.powerBar:SetStatusBarColor(pr, pg, pb, 1)

            if frame.powerBarBorder then frame.powerBarBorder:Show() end
            frame.powerBarBG:Show()
            frame.powerBar:Show()
        else
            if frame.powerBarBorder then frame.powerBarBorder:Hide() end
            frame.powerBarBG:Hide()
            frame.powerBar:Hide()
        end
    end
end

MMF_UpdateUnitFrame = UpdateUnitFrame

function MMF_UpdateAll(elapsed)
    lastUpdate = lastUpdate + (elapsed or 0)
    if lastUpdate < cfg.UPDATE_INTERVAL then return end
    lastUpdate = 0

    local allFrames = MMF_GetAllFrames()
    for _, frame in ipairs(allFrames) do
        if frame and frame:IsShown() then
            UpdateUnitFrame(frame)
        end
    end
end

function MMF_SetPowerBarSize(width, height)
    if not width or not height then return end

    local frames = { MMF_PlayerFrame, MMF_TargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.powerBarFrame then
            frame.powerBarFrame:SetSize(width + 2, height + 2)
            frame.powerBarBG:SetWidth(width)
            frame.powerBarBG:SetHeight(height)
            frame.powerBar:SetWidth(width)
            frame.powerBar:SetHeight(height)
            frame.powerBarFG:SetHeight(height)
        end
    end

    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.powerBarWidth = width
    MattMinimalFramesDB.powerBarHeight = height
end

function MMF_SetPowerBarOffset(verticalOffset, horizontalOffset)
    if not verticalOffset then return end
    horizontalOffset = horizontalOffset or cfg.POWER_BAR_HORIZONTAL_OFFSET

    local frames = { MMF_PlayerFrame, MMF_TargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.powerBarBorder then
            frame.powerBarBorder:ClearAllPoints()
            if frame.unit == "player" then
                frame.powerBarBorder:SetPoint("BOTTOM", frame, "BOTTOM", 0, verticalOffset)
                frame.powerBarBorder:SetPoint("RIGHT", frame, "RIGHT", -horizontalOffset, 0)
            else
                frame.powerBarBorder:SetPoint("BOTTOM", frame, "BOTTOM", 0, verticalOffset)
                frame.powerBarBorder:SetPoint("LEFT", frame, "LEFT", horizontalOffset, 0)
            end
        end
    end

    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.powerBarVerticalOffset = verticalOffset
    MattMinimalFramesDB.powerBarHorizontalOffset = horizontalOffset
end

function MMF_UpdatePowerBarVisibility()
    if MMF_PlayerFrame and MMF_PlayerFrame.powerBarFrame then
        MMF_PlayerFrame.powerBarFrame:SetShown(MattMinimalFramesDB.showPlayerPowerBar ~= false)
        MMF_PlayerFrame.powerText:SetShown(MattMinimalFramesDB.showPlayerPowerBar ~= false)
    end

    if MMF_TargetFrame and MMF_TargetFrame.powerBarFrame then
        MMF_TargetFrame.powerBarFrame:SetShown(MattMinimalFramesDB.showTargetPowerBar ~= false)
        MMF_TargetFrame.powerText:SetShown(MattMinimalFramesDB.showTargetPowerBar ~= false)
    end
end
