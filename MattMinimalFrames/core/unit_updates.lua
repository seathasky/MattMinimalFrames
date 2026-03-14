local cfg = MMF_Config
local Compat = _G.MMF_Compat
local lastUpdate = 0

local UnitExists = UnitExists
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitHealthPercent = UnitHealthPercent
local UnitName = UnitName
local UnitPowerType = UnitPowerType
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitPowerPercent = UnitPowerPercent
local UnitClassBase = UnitClassBase
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetDetailedHealPrediction = UnitGetDetailedHealPrediction
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local PowerBarColor = PowerBarColor

local IS_PLAYER_SHAMAN = (UnitClassBase("player") == "SHAMAN")
local IS_PLAYER_DRUID = (UnitClassBase("player") == "DRUID")
local SCALE_TO_100 = CurveConstants and CurveConstants.ScaleTo100

local function IsCheckedFlag(value)
    return value == true or value == 1
end

local function ResolvePowerColor(powerType, powerToken)
    local powerColor = nil
    pcall(function()
        if powerType ~= nil and PowerBarColor then
            powerColor = PowerBarColor[powerType]
        end
        if (not powerColor) and powerToken and PowerBarColor then
            powerColor = PowerBarColor[powerToken]
        end
    end)

    if powerType == 0 or powerToken == "MANA" then
        return 0.2, 0.7, 1
    end
    if powerColor then
        return powerColor.r or 1, powerColor.g or 1, powerColor.b or 1
    end
    return 1, 1, 1
end

local function SafeEq(a, b)
    local ok, result = pcall(function()
        return a == b
    end)
    return ok and result or false
end

local function NotSecretValue(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return true
end

local function SafeIsGreater(a, b)
    local ok, result = pcall(function()
        return a > b
    end)
    return ok and result or false
end

local function SafeIsLessOrEqual(a, b)
    local ok, result = pcall(function()
        return a <= b
    end)
    return ok and result or false
end

local function SafeIsLess(a, b)
    local ok, result = pcall(function()
        return a < b
    end)
    return ok and result or false
end

local function SafeToNumber(value, fallback)
    if not NotSecretValue(value) then
        return fallback
    end
    local ok, numberValue = pcall(tonumber, value)
    if ok and type(numberValue) == "number" and NotSecretValue(numberValue) then
        return numberValue
    end
    return fallback
end

local function SafeAdd(a, b, fallback)
    local ok, result = pcall(function()
        return a + b
    end)
    if ok and type(result) == "number" then
        return result
    end
    return fallback
end

local function SafeSubtract(a, b, fallback)
    local ok, result = pcall(function()
        return a - b
    end)
    if ok and type(result) == "number" then
        return result
    end
    return fallback
end

local function SafeMultiply(a, b, fallback)
    local ok, result = pcall(function()
        return a * b
    end)
    if ok and type(result) == "number" then
        return result
    end
    return fallback
end

local function SafeDivide(a, b, fallback)
    local ok, result = pcall(function()
        return a / b
    end)
    if ok and type(result) == "number" then
        return result
    end
    return fallback
end

local function SafeStringLen(value)
    local ok, length = pcall(string.len, value)
    if ok and type(length) == "number" then
        return length
    end
    return nil
end

local function ClampColorChannel(value, fallback)
    local n = SafeToNumber(value, fallback)
    if type(n) ~= "number" then
        n = fallback or 0
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function ApplyHealPredictionBarColor(frame)
    if not frame then return end

    local db = MattMinimalFramesDB or {}
    local r = ClampColorChannel(db.healPredictionColorR, 0.0)
    local g = ClampColorChannel(db.healPredictionColorG, 0.827)
    local b = ClampColorChannel(db.healPredictionColorB, 0.765)
    local a = ClampColorChannel(db.healPredictionColorA, 0.7)

    if frame.myHealPrediction then
        frame.myHealPrediction:SetStatusBarColor(r, g, b, a)
        local myTex = frame.myHealPrediction:GetStatusBarTexture()
        if myTex then
            myTex:SetVertexColor(r, g, b, a)
        end
    end

    if frame.otherHealPrediction then
        frame.otherHealPrediction:SetStatusBarColor(r, g, b, a)
        local otherTex = frame.otherHealPrediction:GetStatusBarTexture()
        if otherTex then
            otherTex:SetVertexColor(r, g, b, a)
        end
    end
end

local function ApplyAbsorbBarColor(frame)
    if not frame or not frame.absorbBar then return end

    local db = MattMinimalFramesDB or {}
    local r = ClampColorChannel(db.absorbBarColorR, 0.62)
    local g = ClampColorChannel(db.absorbBarColorG, 0.84)
    local b = ClampColorChannel(db.absorbBarColorB, 1.0)
    local a = ClampColorChannel(db.absorbBarColorA, 0.7)
    local useSolid = (db.useSolidAbsorbBar == true)

    local desiredTexture = nil
    if useSolid and MMF_GetStatusBarTexturePath then
        desiredTexture = MMF_GetStatusBarTexturePath()
    else
        desiredTexture = "Interface\\AddOns\\MattMinimalFrames\\Textures\\shield.tga"
    end
    if desiredTexture then
        frame.absorbBar:SetStatusBarTexture(desiredTexture)
    end

    frame.absorbBar:SetStatusBarColor(r, g, b, a)
    local absorbTex = frame.absorbBar:GetStatusBarTexture()
    if absorbTex then
        absorbTex:SetHorizTile(not useSolid)
        absorbTex:SetVertTile(not useSolid)
        if useSolid then
            absorbTex:SetTexCoord(0, 1, 0, 1)
        else
            absorbTex:SetTexCoord(0, 8, 0, 1)
        end
        absorbTex:SetVertexColor(r, g, b, a)
    end
end

local function SafeGetRegionWidth(region, fallback)
    if not region then
        return fallback
    end
    local ok, width = pcall(region.GetWidth, region)
    if not ok then
        return fallback
    end
    return SafeToNumber(width, fallback)
end

local function SafeGetNameTextBaseWidth(frame)
    local baseWidth = SafeToNumber(frame and frame.originalWidth, nil)
    if type(baseWidth) ~= "number" then
        baseWidth = SafeGetRegionWidth(frame, 0)
    end
    return baseWidth or 0
end

local function SafeGetNameTextMaxWidth(frame)
    local maxWidth = SafeSubtract(SafeGetNameTextBaseWidth(frame), 4, 0)
    if SafeIsGreater(maxWidth, 0) then
        return maxWidth
    end
    return 0
end

local function SafeFormatValue(value, useShortValue)
    if value == nil then
        return "0"
    end

    if useShortValue then
        if type(AbbreviateLargeNumbers) == "function" then
            local ok, text = pcall(AbbreviateLargeNumbers, value)
            if ok and text then
                return text
            end
        end
    end

    if type(BreakUpLargeNumbers) == "function" then
        local ok, text = pcall(BreakUpLargeNumbers, value)
        if ok and text then
            return text
        end
    end

    local ok, text = pcall(function()
        return tostring(value)
    end)
    if ok and text then
        return text
    end

    return "0"
end

local function GetHealthPercentText(unit, current, maximum)
    if not unit then
        return "0%"
    end

    if UnitHealthPercent then
        if SCALE_TO_100 then
            local okCurve, percentText = pcall(function()
                return string.format("%d%%", UnitHealthPercent(unit, true, SCALE_TO_100))
            end)
            if okCurve and percentText then
                return percentText
            end
        else
            local okScaled, percentText = pcall(function()
                local pct = UnitHealthPercent(unit, true)
                if pct == nil then
                    pct = UnitHealthPercent(unit)
                end
                return string.format("%.0f%%", pct * 100)
            end)
            if okScaled and percentText then
                return percentText
            end
        end
    end

    local okFallback, fallbackText = pcall(function()
        local pct = math.floor(((current / maximum) * 100) + 0.5)
        return string.format("%d%%", pct)
    end)
    if okFallback and fallbackText then
        return fallbackText
    end

    return "0%"
end

local function GetPowerPercentText(unit, current, maximum, powerType)
    if unit and UnitPowerPercent then
        if SCALE_TO_100 then
            local okCurve, percentText = pcall(function()
                return string.format("%d%%", UnitPowerPercent(unit, powerType, true, SCALE_TO_100))
            end)
            if okCurve and percentText then
                return percentText
            end
        else
            local okScaled, percentText = pcall(function()
                local pct = UnitPowerPercent(unit, powerType, true)
                if pct == nil then
                    pct = UnitPowerPercent(unit, powerType)
                end
                return string.format("%.0f%%", pct * 100)
            end)
            if okScaled and percentText then
                return percentText
            end
        end
    end

    local currentNumber = SafeToNumber(current, nil)
    local maximumNumber = SafeToNumber(maximum, nil)
    if not currentNumber or not maximumNumber or maximumNumber <= 0 then
        return "0%"
    end

    local ok, text = pcall(function()
        local pct = math.floor(((currentNumber / maximumNumber) * 100) + 0.5)
        if pct < 0 then pct = 0 end
        if pct > 100 then pct = 100 end
        return string.format("%d%%", pct)
    end)
    if ok and text then
        return text
    end
    return "0%"
end

local function IsPowerPercentEnabledForUnit(db, unit)
    if unit == "player" then
        if db.showPlayerPowerPercentText ~= nil then
            return IsCheckedFlag(db.showPlayerPowerPercentText)
        end
    elseif unit == "target" then
        if db.showTargetPowerPercentText ~= nil then
            return IsCheckedFlag(db.showTargetPowerPercentText)
        end
    end
    -- Backward compatibility with older single-toggle setting.
    return db.showPowerPercentText == true
end

local function FormatPercentAndValue(current, showPercent, showValue, useShortValue, percentText)
    local displayPercent = percentText or "0%"
    local absolute = SafeFormatValue(current, useShortValue)

    if showPercent and showValue then
        return string.format("%s | %s", displayPercent, absolute)
    end
    if showPercent then
        return displayPercent
    end
    if showValue then
        return absolute
    end

    return ""
end

local function GetNameTruncationSettings()
    local manualEnabled = MattMinimalFramesDB and IsCheckedFlag(MattMinimalFramesDB.enableNameTruncation)
    local autoResizeEnabled = MattMinimalFramesDB and IsCheckedFlag(MattMinimalFramesDB.autoResizeTextOnLongName)
    local enabled = manualEnabled and not autoResizeEnabled
    local length = tonumber(MattMinimalFramesDB and MattMinimalFramesDB.nameTruncationLength) or 14
    if length < 5 then
        length = 5
    elseif length > 30 then
        length = 30
    end
    return enabled, length
end

local function IsAutoResizeNameTextEnabled()
    if not MattMinimalFramesDB then
        return false
    end

    return IsCheckedFlag(MattMinimalFramesDB.autoResizeTextOnLongName)
end

local function GetDisplayUnitName(unit, unitName)
    if not unitName then
        return ""
    end

    local truncEnabled, truncLength = GetNameTruncationSettings()
    if not truncEnabled then
        return unitName
    end

    if unit == "targettarget" then
        return unitName
    end

    local unitNameLength = SafeStringLen(unitName)
    if not unitNameLength or not SafeIsGreater(unitNameLength, truncLength) then
        return unitName
    end

    local ok, truncated = pcall(string.sub, unitName, 1, truncLength)
    if not ok then
        return unitName
    end
    return truncated
end

local function TryApplyFont(region, fontPath, size, flags)
    if not region then
        return false
    end
    if MMF_SetFontSafe then
        return MMF_SetFontSafe(region, fontPath, size, flags)
    end
    if not region.SetFont then
        return false
    end

    local requestedFlags = flags or ""
    local ok, applied = pcall(region.SetFont, region, fontPath, size, requestedFlags)
    if ok and applied ~= false then
        return true
    end
    if requestedFlags ~= "" then
        ok, applied = pcall(region.SetFont, region, fontPath, size, "")
        if ok and applied ~= false then
            return true
        end
    end
    return false
end

local function ApplyNameTextFontSize(frame, size, minSize)
    if not frame or not frame.nameText then return end
    size = tonumber(size) or 12
    minSize = tonumber(minSize) or 6
    if minSize < 1 then minSize = 1 end
    if size < minSize then size = minSize end
    local rounded = math.floor(size + 0.5)
    if frame.mmfAppliedNameFontSize == rounded then
        return
    end
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or cfg.FONT_PATH
    if TryApplyFont(frame.nameText, fontPath, rounded, "OUTLINE") then
        frame.mmfAppliedNameFontSize = rounded
    else
        frame.mmfAppliedNameFontSize = nil
    end
end

local function ApplyHPTextFontSize(frame, size)
    if not frame or not frame.hpText then return end
    size = tonumber(size) or 13
    if size < 6 then size = 6 end
    local rounded = math.floor(size + 0.5)
    if frame.mmfAppliedHPFontSize == rounded then
        return
    end
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or cfg.FONT_PATH
    if TryApplyFont(frame.hpText, fontPath, rounded, "OUTLINE") then
        frame.mmfAppliedHPFontSize = rounded
    else
        frame.mmfAppliedHPFontSize = nil
    end
end

local function ApplyPowerTextFontSize(frame, scale)
    if not frame or not frame.powerText then return end
    local normalizedScale = tonumber(scale) or 1
    if normalizedScale < 0.5 then normalizedScale = 0.5 end
    if normalizedScale > 2.0 then normalizedScale = 2.0 end

    local baseSize = 13
    local size = math.floor((baseSize * normalizedScale) + 0.5)
    if size < 6 then size = 6 end
    if frame.mmfAppliedPowerFontSize == size then
        return
    end

    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or cfg.FONT_PATH
    if TryApplyFont(frame.powerText, fontPath, size, "OUTLINE") then
        frame.mmfAppliedPowerFontSize = size
    else
        frame.mmfAppliedPowerFontSize = nil
    end
end

local function ApplyCastBarFontSizes(frame, unit)
    if not frame or not unit then return end
    if unit ~= "player" and unit ~= "target" and unit ~= "focus" then return end

    local castPrefix = (unit == "player" and "playerCastBar")
        or (unit == "target" and "targetCastBar")
        or (unit == "focus" and "focusCastBar")
        or "targetCastBar"
    local spellNameSize = tonumber(MattMinimalFramesDB and MattMinimalFramesDB[castPrefix .. "SpellNameTextSize"])
    if not spellNameSize then
        spellNameSize = tonumber(MMF_GetNameTextSize and MMF_GetNameTextSize(unit)) or 12
    end
    if spellNameSize < 6 then spellNameSize = 6 end
    local roundedSpellName = math.floor(spellNameSize + 0.5)

    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or cfg.FONT_PATH
    if frame.castBarText and frame.mmfAppliedCastBarNameFontSize ~= roundedSpellName then
        if TryApplyFont(frame.castBarText, fontPath, roundedSpellName, "OUTLINE") then
            frame.mmfAppliedCastBarNameFontSize = roundedSpellName
        else
            frame.mmfAppliedCastBarNameFontSize = nil
        end
    end

    local castTimeSize = tonumber(MattMinimalFramesDB and MattMinimalFramesDB[castPrefix .. "CastTimeTextSize"]) or 9
    if castTimeSize < 6 then castTimeSize = 6 end
    castTimeSize = math.floor(castTimeSize + 0.5)
    if frame.castBarTime and frame.mmfAppliedCastBarHPFontSize ~= castTimeSize then
        if TryApplyFont(frame.castBarTime, fontPath, castTimeSize, "OUTLINE") then
            frame.mmfAppliedCastBarHPFontSize = castTimeSize
        else
            frame.mmfAppliedCastBarHPFontSize = nil
        end
    end
end

local function GetNameTextWidthNoWrap(nameText)
    if not nameText then return 0 end
    local okUnbounded, unboundedWidth = pcall(nameText.GetUnboundedStringWidth, nameText)
    if okUnbounded and type(unboundedWidth) == "number" then
        return unboundedWidth
    end

    local restoreWidth = 1
    local okCurrent, currentWidth = pcall(nameText.GetWidth, nameText)
    if okCurrent and type(currentWidth) == "number" then
        local okPositive, isPositive = pcall(function()
            return currentWidth > 0
        end)
        if okPositive and isPositive then
            restoreWidth = currentWidth
        end
    end

    pcall(nameText.SetWidth, nameText, 4096)
    local okWidth, measuredWidth = pcall(nameText.GetStringWidth, nameText)
    pcall(nameText.SetWidth, nameText, restoreWidth)
    if okWidth and type(measuredWidth) == "number" then
        return measuredWidth
    end
    return 0
end

local function ApplyAutoResizeNameText(frame, unit, displayName)
    if not frame or not frame.nameText then return end
    local baseSize = tonumber(MMF_GetNameTextSize and MMF_GetNameTextSize(unit) or (MattMinimalFramesDB and MattMinimalFramesDB.nameTextSize)) or 12
    local autoEnabled = IsAutoResizeNameTextEnabled()
    local maxWidth = SafeGetNameTextMaxWidth(frame)

    ApplyNameTextFontSize(frame, baseSize, 1)

    local hasDisplayName = false
    if displayName then
        local displayNameLen = SafeStringLen(displayName)
        hasDisplayName = displayNameLen and SafeIsGreater(displayNameLen, 0) or false
    end

    if not autoEnabled or unit == "targettarget" or not hasDisplayName then
        return
    end
    if not SafeIsGreater(maxWidth, 0) then
        return
    end

    local minSize = 1
    local size = math.floor(baseSize + 0.5)
    while size > minSize do
        local widthNow = GetNameTextWidthNoWrap(frame.nameText)
        if not SafeIsGreater(widthNow, maxWidth) then
            break
        end
        size = size - 1
        ApplyNameTextFontSize(frame, size, minSize)
    end

    local textWidth = GetNameTextWidthNoWrap(frame.nameText)
    if SafeIsLessOrEqual(textWidth, maxWidth) then
        return
    end

    -- Auto mode should preserve the full name and only scale the font down.
    local scale = SafeDivide(maxWidth, textWidth, 0)
    if SafeIsGreater(scale, 0) and SafeIsGreater(1, scale) then
        local target = math.floor((baseSize * scale) + 0.5)
        if target < minSize then
            target = minSize
        end
        if target < size then
            size = target
            ApplyNameTextFontSize(frame, size, minSize)
            textWidth = GetNameTextWidthNoWrap(frame.nameText)
        end
    end

    while size > minSize and SafeIsGreater(textWidth, maxWidth) do
        size = size - 1
        ApplyNameTextFontSize(frame, size, minSize)
        textWidth = GetNameTextWidthNoWrap(frame.nameText)
    end
end

--------------------------------------------------
-- HEAL PREDICTION UPDATE
--------------------------------------------------

local function UpdateHealPrediction(frame)
    if not frame or not frame.myHealPrediction then return end

    ApplyHealPredictionBarColor(frame)

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
    local showOverhealPrediction = MattMinimalFramesDB and MattMinimalFramesDB.showOverhealPrediction == true
    local containOverhealWithinFrame = MattMinimalFramesDB and MattMinimalFramesDB.containOverhealWithinFrame == true

    if frame.healPredictionClip and frame.myHealPrediction and frame.otherHealPrediction then
        if containOverhealWithinFrame then
            local topLevel = (frame.GetFrameLevel and frame:GetFrameLevel() or 0) + 20
            if frame.GetFrameStrata and frame.healPredictionClip.SetFrameStrata then
                frame.healPredictionClip:SetFrameStrata(frame:GetFrameStrata())
            end
            frame.healPredictionClip:SetFrameLevel(topLevel)
            frame.myHealPrediction:SetFrameLevel(topLevel + 1)
            frame.otherHealPrediction:SetFrameLevel(topLevel + 2)
        else
            local baseLevel = (frame.healthBar and frame.healthBar.GetFrameLevel and frame.healthBar:GetFrameLevel() or frame:GetFrameLevel() or 0) + 1
            frame.healPredictionClip:SetFrameLevel(baseLevel)
            frame.myHealPrediction:SetFrameLevel(baseLevel)
            frame.otherHealPrediction:SetFrameLevel(baseLevel)
        end
    end

    local overflowPixels = 0
    if showOverhealPrediction then
        overflowPixels = math.floor(barWidth * 0.08 + 0.5)
        if overflowPixels < 4 then overflowPixels = 4 end
        if overflowPixels > 16 then overflowPixels = 16 end
    end

    if frame.healPredictionClip then
        frame.healPredictionClip:ClearAllPoints()
        frame.healPredictionClip:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
        frame.healPredictionClip:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", 0, 0)
        if containOverhealWithinFrame then

            frame.healPredictionClip:SetWidth(barWidth * 1.01)
        else
            frame.healPredictionClip:SetWidth(barWidth + overflowPixels)
        end
    end

    frame.myHealPrediction:ClearAllPoints()
    if frame.myHealPrediction.SetReverseFill then
        frame.myHealPrediction:SetReverseFill(false)
    end
    frame.myHealPrediction:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT", 0, 0)
    frame.myHealPrediction:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT", 0, 0)
    frame.myHealPrediction:SetWidth(barWidth + overflowPixels)
    frame.myHealPrediction:SetMinMaxValues(0, maxHealth)

    local myHealTexture = frame.myHealPrediction:GetStatusBarTexture()
    frame.otherHealPrediction:ClearAllPoints()
    if frame.otherHealPrediction.SetReverseFill then
        frame.otherHealPrediction:SetReverseFill(false)
    end
    frame.otherHealPrediction:SetPoint("TOPLEFT", myHealTexture, "TOPRIGHT", 0, 0)
    frame.otherHealPrediction:SetPoint("BOTTOMLEFT", myHealTexture, "BOTTOMRIGHT", 0, 0)
    frame.otherHealPrediction:SetWidth(barWidth + overflowPixels)
    frame.otherHealPrediction:SetMinMaxValues(0, maxHealth)

    local myHeal = 0
    local otherHeal = 0
    local totalIncomingHeal = 0
    local allIncomingHeal = 0

    if Compat.IsRetail and frame.healPredictionCalculator and UnitGetDetailedHealPrediction then
        pcall(function()
            UnitGetDetailedHealPrediction(unit, "player", frame.healPredictionCalculator)
            local incomingTotalHeal, playerHeal, incomingOtherHeal = frame.healPredictionCalculator:GetIncomingHeals()
            totalIncomingHeal = incomingTotalHeal or 0
            myHeal = playerHeal or 0
            otherHeal = incomingOtherHeal or 0
        end)
    elseif UnitGetIncomingHeals then
        myHeal = UnitGetIncomingHeals(unit, "player") or 0
        local allHeal = UnitGetIncomingHeals(unit) or 0
        totalIncomingHeal = allHeal
        allIncomingHeal = allHeal
        otherHeal = 0
        pcall(function()
            otherHeal = allHeal - myHeal
        end)
    end

    if UnitGetIncomingHeals then
        pcall(function()
            allIncomingHeal = UnitGetIncomingHeals(unit) or allIncomingHeal or 0
        end)
    end

    if SafeIsLess(otherHeal, 0) then
        otherHeal = 0
    end

    if not SafeIsGreater(totalIncomingHeal, 0) then
        if SafeIsGreater(allIncomingHeal, 0) then
            totalIncomingHeal = allIncomingHeal
        end
    end

    if not SafeIsGreater(totalIncomingHeal, 0) then
        local summed = SafeAdd(myHeal, otherHeal, nil)
        if type(summed) == "number" and SafeIsGreater(summed, 0) then
            totalIncomingHeal = summed
        end
    end

    frame.myHealPrediction:SetValue(myHeal)
    frame.otherHealPrediction:SetValue(otherHeal)

    frame.myHealPrediction:Show()
    frame.otherHealPrediction:Show()
end

--------------------------------------------------
-- ABSORB BAR UPDATE
--------------------------------------------------

local function UpdateAbsorbBar(frame)
    if not frame or not frame.absorbBar then return end

    ApplyAbsorbBarColor(frame)

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

local function UpdateCastBarForEditMode(frame, unit, unlockedEditMode, db)
    if not frame or not frame.castBarFrame then
        return
    end
    if unit ~= "player" and unit ~= "target" and unit ~= "focus" then
        return
    end

    local enabledKey = (unit == "player" and "showPlayerCastBar")
        or (unit == "target" and "showTargetCastBar")
        or (unit == "focus" and "showFocusCastBar")
        or "showTargetCastBar"
    if db and db[enabledKey] == false and unlockedEditMode ~= true then
        frame.castBarFrame:Hide()
        return
    end

    local castInfo = frame.castInfo
    local activelyCasting = castInfo and (castInfo.casting == true or castInfo.channeling == true)

    if unlockedEditMode then
        if not activelyCasting then
            local colorKey = (db and db.castBarColor) or "yellow"
            local r, g, b = MMF_Config.GetCastBarColor(colorKey)
            if frame.castBar then
                frame.castBar:SetStatusBarColor(r, g, b, 1)
                frame.castBar:SetMinMaxValues(0, 1)
                frame.castBar:SetValue(0.55)
            end
            if frame.castBarText then
                if unit == "player" then
                    frame.castBarText:SetText("Player Cast Bar")
                elseif unit == "focus" then
                    frame.castBarText:SetText("Focus Cast Bar")
                else
                    frame.castBarText:SetText("Target Cast Bar")
                end
            end
            if frame.castBarTime then
                frame.castBarTime:SetText("1.8")
            end
            frame.castBarFrame:Show()
        end
        return
    end

    if not activelyCasting then
        frame.castBarFrame:Hide()
    end
end

--------------------------------------------------
-- UNIT FRAME UPDATE
--------------------------------------------------

local function UpdateUnitFrame(frame)
    if not frame or not frame.unit or not frame.nameText then return end
    local unit = frame.unit
    local db = MattMinimalFramesDB or {}
    ApplyCastBarFontSizes(frame, unit)
    local manualTruncateEnabled = IsCheckedFlag(db.enableNameTruncation)
    local autoResizeEnabled = IsCheckedFlag(db.autoResizeTextOnLongName)
    local forceSingleLine = manualTruncateEnabled or autoResizeEnabled
    pcall(function()
        frame.nameText:SetWordWrap(not forceSingleLine)
    end)
    pcall(function()
        frame.nameText:SetNonSpaceWrap(not forceSingleLine)
    end)
    pcall(function()
        frame.nameText:SetMaxLines(forceSingleLine and 1 or 0)
    end)
    local hideNameText = MMF_IsNameTextHidden and MMF_IsNameTextHidden(unit)
    local hideHPText = MMF_IsHPTextHidden and MMF_IsHPTextHidden(unit)

    local unlockedEditMode = (db.unlockFramesEditMode == true)
    local layoutTestMode = (db.layoutTestMode == true)
    local previewMode = (unlockedEditMode or layoutTestMode)
    local auraTestPreviewTarget = (unit == "target" and db.auraTestMode == true and not UnitExists(unit))

    if hideNameText then
        frame.nameText:SetText("")
        frame.nameText:Hide()
        ApplyNameTextFontSize(frame, MMF_GetNameTextSize and MMF_GetNameTextSize(unit) or tonumber(db.nameTextSize) or 12)
    elseif not UnitExists(unit) then
        if previewMode then
            frame.nameText:SetText((frame.frameLabel and (frame.frameLabel .. " (Edit)")) or (unit .. " (Edit)"))
        elseif auraTestPreviewTarget then
            frame.nameText:SetText("Target (Preview)")
        else
            frame.nameText:SetText("")
        end
        frame.nameText:Show()
        ApplyNameTextFontSize(frame, MMF_GetNameTextSize and MMF_GetNameTextSize(unit) or tonumber(db.nameTextSize) or 12)
    else
        frame.nameText:Show()
        local unitName = UnitName(unit)
        local displayName = GetDisplayUnitName(unit, unitName)
        local nameTextWidth = SafeGetNameTextMaxWidth(frame)
        if unit == "targettarget" then
            frame.nameText:SetText(displayName or "")
            frame.nameText:SetWidth(nameTextWidth)
        else
            frame.nameText:SetText(displayName)
            frame.nameText:SetWidth(nameTextWidth)
        end
        ApplyAutoResizeNameText(frame, unit, displayName)
    end

    if MMF_UpdatePVPFlagIndicator then
        MMF_UpdatePVPFlagIndicator(frame)
    end

    local maxHP = UnitHealthMax(unit)
    local hp = UnitHealth(unit)
    if auraTestPreviewTarget then
        maxHP = 1000000
        hp = 1000000
    end

    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, maxHP)
        frame.healthBar:SetValue(hp)
    end

    local supportsHPText = (
        unit == "player"
        or unit == "target"
        or unit == "targettarget"
        or unit == "pet"
        or unit == "focus"
        or unit == "boss1"
        or unit == "boss2"
        or unit == "boss3"
        or unit == "boss4"
        or unit == "boss5"
    )

    if frame.hpText and supportsHPText then
        ApplyHPTextFontSize(frame, MMF_GetHPTextSize and MMF_GetHPTextSize(unit) or tonumber(db.hpTextSize) or 13)
        if hideHPText then
            frame.hpText:SetText("")
            frame.hpText:Hide()
        elseif (previewMode or auraTestPreviewTarget) and not UnitExists(unit) then
            local showHPValueText = (db.showHPValueText ~= false)
            local showHPPercentText = (db.showHPPercentText == true)
            local useShortHPValue = (db.hpTextUseShortValue ~= false)
            frame.hpText:SetText(FormatPercentAndValue(999000, showHPPercentText, showHPValueText, useShortHPValue, "100%"))
            frame.hpText:Show()
        else
            local hpPercentText = GetHealthPercentText(unit, hp, maxHP)
            local showHPPercentText = (db.showHPPercentText == true)
            local showHPValueText = (db.showHPValueText ~= false)
            local useShortHPValue = (db.hpTextUseShortValue ~= false)
            frame.hpText:SetText(FormatPercentAndValue(hp, showHPPercentText, showHPValueText, useShortHPValue, hpPercentText))
            frame.hpText:Show()
        end
    end

    UpdateHealPrediction(frame)
    UpdateAbsorbBar(frame)
    UpdateCastBarForEditMode(frame, unit, previewMode, db)

    if unit ~= "player" and unit ~= "target"
        and unit ~= "targettarget" and unit ~= "pet" and unit ~= "focus"
        and unit ~= "boss1" and unit ~= "boss2" and unit ~= "boss3" and unit ~= "boss4" and unit ~= "boss5" then
        if frame.hpText then frame.hpText:Hide() end
        if frame.powerText then frame.powerText:Hide() end
    end

    local r, g, b = MMF_GetUnitColor(unit)
    local colorAlpha = (MMF_GetUnitColorAlpha and MMF_GetUnitColorAlpha(unit)) or 1
    if frame.healthBar then
        frame.healthBar:SetStatusBarColor(r, g, b, colorAlpha)
    end

    if frame.powerBar and (unit == "player" or unit == "target") then
        local powerType, powerToken = UnitPowerType(unit)

        local useManaPowerType = false
        if unit == "player" then
            if IS_PLAYER_DRUID and IsCheckedFlag(db.showDruidManaPowerText) then
                useManaPowerType = true
                powerType = 0
                powerToken = "MANA"
            elseif IS_PLAYER_SHAMAN and Compat.HasSpecialization then
                local spec = Compat.GetSpecialization()
                if SafeEq(spec, 1) or SafeEq(spec, 2) then
                    useManaPowerType = true
                    powerType = 0
                    powerToken = "MANA"
                end
            end
        end

        local maxPower, power
        if useManaPowerType then
            maxPower = UnitPowerMax(unit, 0)
            power = UnitPower(unit, 0)
        else
            if powerType ~= nil then
                maxPower = UnitPowerMax(unit, powerType)
                power = UnitPower(unit, powerType)
            else
                maxPower = UnitPowerMax(unit)
                power = UnitPower(unit)
            end
        end
        if previewMode and not UnitExists(unit) then
            maxPower = 100
            power = 72
        end
        local hasPower = false
        pcall(function()
            hasPower = (maxPower and maxPower > 0) and true or false
        end)

        if hasPower then
            frame.powerBar:SetMinMaxValues(0, maxPower)
            frame.powerBar:SetValue(power)

            local pr, pg, pb = ResolvePowerColor(powerType, powerToken)
            local showPowerBar = false
            if unit == "player" then
                showPowerBar = (db.showPlayerPowerBar ~= false)
            else
                showPowerBar = (db.showTargetPowerBar ~= false)
            end

            frame.powerBar:SetStatusBarColor(pr, pg, pb, 1)
            if showPowerBar then
                if frame.powerBarBorder then frame.powerBarBorder:Show() end
                frame.powerBarBG:Show()
                frame.powerBar:Show()
            else
                if frame.powerBarBorder then frame.powerBarBorder:Hide() end
                frame.powerBarBG:Hide()
                frame.powerBar:Hide()
            end

            if frame.powerText then
                local showPowerText = false
                local colorPowerText = false
                local textPowerType = powerType
                local textPowerToken = powerToken
                if unit == "player" then
                    showPowerText = IsCheckedFlag(db.showPlayerPowerText)
                    colorPowerText = IsCheckedFlag(db.colorPlayerPowerTextByResource)
                    if IS_PLAYER_DRUID and IsCheckedFlag(db.showDruidManaPowerText) then
                        textPowerType = 0
                        textPowerToken = "MANA"
                    end
                else
                    showPowerText = IsCheckedFlag(db.showTargetPowerText)
                    colorPowerText = IsCheckedFlag(db.colorTargetPowerTextByResource)
                end

                if showPowerText then
                    local textPower = power
                    local textMaxPower = maxPower
                    if textPowerType ~= powerType then
                        textMaxPower = UnitPowerMax(unit, textPowerType)
                        textPower = UnitPower(unit, textPowerType)
                    end

                    local display = SafeFormatValue(textPower, false)
                    if IsPowerPercentEnabledForUnit(db, unit) then
                        display = GetPowerPercentText(unit, textPower, textMaxPower, textPowerType)
                    end
                    local tpr, tpg, tpb = ResolvePowerColor(textPowerType, textPowerToken)
                    local textScale = db.powerTextScale or 1.0
                    if unit == "player" then
                        textScale = db.playerPowerTextScale or textScale
                    elseif unit == "target" then
                        textScale = db.targetPowerTextScale or textScale
                    end
                    ApplyPowerTextFontSize(frame, textScale)
                    frame.powerText:SetText(display)
                    if colorPowerText then
                        frame.powerText:SetTextColor(tpr, tpg, tpb, 1)
                    else
                        frame.powerText:SetTextColor(1, 1, 1, 1)
                    end
                    frame.powerText:Show()
                    if frame.powerTextDragFrame then frame.powerTextDragFrame:Show() end
                else
                    frame.powerText:Hide()
                    if frame.powerTextDragFrame then frame.powerTextDragFrame:Hide() end
                end
            end
        else
            if frame.powerBarBorder then frame.powerBarBorder:Hide() end
            frame.powerBarBG:Hide()
            frame.powerBar:Hide()
            if frame.powerText then frame.powerText:Hide() end
            if frame.powerTextDragFrame then frame.powerTextDragFrame:Hide() end
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

function MMF_SetPowerBarSize(width, height, unit)
    if not width or not height then return end

    local function ApplySize(frame)
        if frame and frame.powerBarFrame then
            frame.powerBarFrame:SetSize(width + 2, height + 2)
            frame.powerBarBG:SetWidth(width)
            frame.powerBarBG:SetHeight(height)
            frame.powerBar:SetWidth(width)
            frame.powerBar:SetHeight(height)
            frame.powerBarFG:SetHeight(height)
        end
    end

    if unit == "player" then
        ApplySize(MMF_PlayerFrame)
    elseif unit == "target" then
        ApplySize(MMF_TargetFrame)
    else
        ApplySize(MMF_PlayerFrame)
        ApplySize(MMF_TargetFrame)
    end

    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    if unit == "player" then
        MattMinimalFramesDB.playerPowerBarWidth = width
        MattMinimalFramesDB.playerPowerBarHeight = height
    elseif unit == "target" then
        MattMinimalFramesDB.targetPowerBarWidth = width
        MattMinimalFramesDB.targetPowerBarHeight = height
    else
        MattMinimalFramesDB.playerPowerBarWidth = width
        MattMinimalFramesDB.playerPowerBarHeight = height
        MattMinimalFramesDB.targetPowerBarWidth = width
        MattMinimalFramesDB.targetPowerBarHeight = height
        -- Keep legacy keys in sync for backward compatibility.
        MattMinimalFramesDB.powerBarWidth = width
        MattMinimalFramesDB.powerBarHeight = height
    end
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
    end

    if MMF_TargetFrame and MMF_TargetFrame.powerBarFrame then
        MMF_TargetFrame.powerBarFrame:SetShown(MattMinimalFramesDB.showTargetPowerBar ~= false)
    end
end
