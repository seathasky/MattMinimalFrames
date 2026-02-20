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
local UnitClassBase = UnitClassBase
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetDetailedHealPrediction = UnitGetDetailedHealPrediction
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local PowerBarColor = PowerBarColor

local IS_PLAYER_SHAMAN = (UnitClassBase("player") == "SHAMAN")
local SCALE_TO_100 = CurveConstants and CurveConstants.ScaleTo100

local function IsCheckedFlag(value)
    return value == true or value == 1
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

local function FormatPercentAndValue(current, showPercent, useShortValue, percentText)
    local absolute = SafeFormatValue(current, useShortValue)

    if not showPercent then
        return absolute
    end

    local displayPercent = percentText or "0%"

    return string.format("%s | %s", displayPercent, absolute)
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

local function ApplyNameTextFontSize(frame, size)
    if not frame or not frame.nameText then return end
    size = tonumber(size) or 12
    if size < 6 then size = 6 end
    local rounded = math.floor(size + 0.5)
    if frame.mmfAppliedNameFontSize == rounded then
        return
    end
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or cfg.FONT_PATH
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.nameText, fontPath, rounded, "OUTLINE")
    else
        frame.nameText:SetFont(fontPath, rounded, "OUTLINE")
    end
    frame.mmfAppliedNameFontSize = rounded
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
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.hpText, fontPath, rounded, "OUTLINE")
    else
        frame.hpText:SetFont(fontPath, rounded, "OUTLINE")
    end
    frame.mmfAppliedHPFontSize = rounded
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
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.powerText, fontPath, size, "OUTLINE")
    else
        frame.powerText:SetFont(fontPath, size, "OUTLINE")
    end
    frame.mmfAppliedPowerFontSize = size
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

    ApplyNameTextFontSize(frame, baseSize)

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

    local minSize = 6
    local size = math.floor(baseSize + 0.5)
    while size > minSize do
        local widthNow = GetNameTextWidthNoWrap(frame.nameText)
        if not SafeIsGreater(widthNow, maxWidth) then
            break
        end
        size = size - 1
        ApplyNameTextFontSize(frame, size)
    end

    local textWidth = GetNameTextWidthNoWrap(frame.nameText)
    if SafeIsLessOrEqual(textWidth, maxWidth) then
        return
    end

    -- Allow a little overflow before truncating in auto mode (about 5 chars worth).
    local totalChars = SafeStringLen(displayName)
    if totalChars and SafeIsGreater(totalChars, 0) then
        local avgCharWidth = SafeDivide(textWidth, totalChars, 0)
        if SafeIsGreater(avgCharWidth, 0) then
            local overflowBudgetPx = SafeMultiply(avgCharWidth, 5, 0)
            local allowedWidth = SafeAdd(maxWidth, overflowBudgetPx, maxWidth)
            if SafeIsLessOrEqual(textWidth, allowedWidth) then
                return
            end
        end
    end

    -- Prefer removing whole trailing words first.
    local okTrimmed, trimmed = pcall(string.gsub, displayName, "%s+$", "")
    if not okTrimmed or type(trimmed) ~= "string" then
        return
    end
    local guard = 0
    while guard < 64 do
        local okMatch, withoutLastWord = pcall(string.match, trimmed, "^(.*)%s+[^%s]+$")
        if not okMatch or type(withoutLastWord) ~= "string" then
            break
        end
        local okWordLen, wordLen = pcall(string.len, withoutLastWord)
        if not okWordLen or type(wordLen) ~= "number" or not SafeIsGreater(wordLen, 0) then
            break
        end
        local okStrip, stripped = pcall(string.gsub, withoutLastWord, "%s+$", "")
        if not okStrip or type(stripped) ~= "string" then
            break
        end
        trimmed = stripped
        frame.nameText:SetText(trimmed .. "...")
        if SafeIsLessOrEqual(GetNameTextWidthNoWrap(frame.nameText), maxWidth) then
            return
        end
        guard = guard + 1
    end

    -- Fallback for single long words: character trim to force fit.
    local charCount = SafeStringLen(displayName)
    if not charCount or not SafeIsGreater(charCount, 1) then
        return
    end
    local keepChars = SafeSubtract(charCount, 1, nil)
    if not keepChars then
        return
    end
    while SafeIsGreater(keepChars, 1) do
        local okSub, head = pcall(string.sub, displayName, 1, keepChars)
        if not okSub or type(head) ~= "string" then
            break
        end
        local okHeadLen, headLen = pcall(string.len, head)
        if not okHeadLen or type(headLen) ~= "number" or not SafeIsGreater(headLen, 0) then
            break
        end
        local okHeadTrim, headTrimmed = pcall(string.gsub, head, "%s+$", "")
        if not okHeadTrim or type(headTrimmed) ~= "string" then
            break
        end
        frame.nameText:SetText(headTrimmed .. "...")
        if SafeIsLessOrEqual(GetNameTextWidthNoWrap(frame.nameText), maxWidth) then
            return
        end
        keepChars = SafeSubtract(keepChars, 1, 0)
    end
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
    local db = MattMinimalFramesDB or {}
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

    if hideNameText then
        frame.nameText:SetText("")
        frame.nameText:Hide()
        ApplyNameTextFontSize(frame, MMF_GetNameTextSize and MMF_GetNameTextSize(unit) or tonumber(db.nameTextSize) or 12)
    elseif not UnitExists(unit) then
        frame.nameText:SetText("")
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

    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, maxHP)
        frame.healthBar:SetValue(hp)
    end

    if frame.hpText and (unit == "player" or unit == "target") then
        ApplyHPTextFontSize(frame, MMF_GetHPTextSize and MMF_GetHPTextSize(unit) or tonumber(db.hpTextSize) or 13)
        if hideHPText then
            frame.hpText:SetText("")
            frame.hpText:Hide()
        else
            local hpPercentText = GetHealthPercentText(unit, hp, maxHP)
            local showHPPercentText = (db.showHPPercentText ~= false)
            local useShortHPValue = (db.hpTextUseShortValue ~= false)
            frame.hpText:SetText(FormatPercentAndValue(hp, showHPPercentText, useShortHPValue, hpPercentText))
            frame.hpText:Show()
        end
    end

    UpdateHealPrediction(frame)
    UpdateAbsorbBar(frame)

    if unit ~= "player" and unit ~= "target" then
        if frame.hpText then frame.hpText:Hide() end
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

            if frame.powerText then
                local showPowerText = false
                if unit == "player" then
                    showPowerText = (db.showPlayerPowerBar ~= false) and IsCheckedFlag(db.showPlayerPowerText)
                else
                    showPowerText = (db.showTargetPowerBar ~= false) and IsCheckedFlag(db.showTargetPowerText)
                end

                if showPowerText then
                    local display = SafeFormatValue(power, false)
                    local textScale = db.powerTextScale or 1.0
                    if unit == "player" then
                        textScale = db.playerPowerTextScale or textScale
                    elseif unit == "target" then
                        textScale = db.targetPowerTextScale or textScale
                    end
                    ApplyPowerTextFontSize(frame, textScale)
                    frame.powerText:SetText(display)
                    frame.powerText:Show()
                else
                    frame.powerText:Hide()
                end
            end
        else
            if frame.powerBarBorder then frame.powerBarBorder:Hide() end
            frame.powerBarBG:Hide()
            frame.powerBar:Hide()
            if frame.powerText then frame.powerText:Hide() end
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
