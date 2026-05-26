local cfg = MMF_Config
local Compat = _G.MMF_Compat
local lastUpdate = 0

local function ShouldSuspendForBlizzardEditMode()
    return _G.MMF_ShouldSuspendForBlizzardEditMode and _G.MMF_ShouldSuspendForBlizzardEditMode() == true
end

local function IsTBCTargetOfTargetTransitionFixEnabled()
    return Compat and Compat.IsTBC == true
end

local UnitExists = UnitExists
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitHealthPercent = UnitHealthPercent
local UnitName = UnitName
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitIsEnemy = UnitIsEnemy
local UnitPowerType = UnitPowerType
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitIsFriend = UnitIsFriend
local UnitPowerPercent = UnitPowerPercent
local UnitClassBase = UnitClassBase
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetDetailedHealPrediction = UnitGetDetailedHealPrediction
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local PowerBarColor = PowerBarColor
local UnitAura = UnitAura

local IS_PLAYER_SHAMAN = (UnitClassBase("player") == "SHAMAN")
local IS_PLAYER_DRUID = (UnitClassBase("player") == "DRUID")
local SCALE_TO_100 = CurveConstants and CurveConstants.ScaleTo100
local ClampColorChannel

local TBC_TRACKED_ABSORB_SPELLS = {
    -- Power Word: Shield
    [17] = 44, [592] = 88, [600] = 158, [3747] = 234, [6065] = 301, [6066] = 381,
    [10898] = 484, [10899] = 605, [10900] = 760, [10901] = 942, [25217] = 1104, [25218] = 1265,
    -- Ice Barrier
    [11426] = 438, [13031] = 549, [13032] = 678, [13033] = 818, [27134] = 925, [33405] = 1075,
    -- Voidwalker Sacrifice
    [30115] = 0,
}
local GetTBCTrackedAbsorbTotal
local TBCTrackedAbsorbStateByGUID = {}

local function IsCheckedFlag(value)
    return value == true or value == 1
end

local function ResolvePowerColor(unit, powerType, powerToken, db)
    local function GetOverrideColor(token)
        if not db or not token or (unit ~= "player" and unit ~= "target") then
            return nil
        end
        local keyBase = "powerColor_" .. unit .. "_" .. tostring(token)
        local r = db[keyBase .. "_R"]
        local g = db[keyBase .. "_G"]
        local b = db[keyBase .. "_B"]
        local a = db[keyBase .. "_A"]
        if type(r) == "number" and type(g) == "number" and type(b) == "number" then
            return ClampColorChannel(r, 1.0),
                ClampColorChannel(g, 1.0),
                ClampColorChannel(b, 1.0),
                ClampColorChannel(a, 1.0)
        end
        return nil
    end

    local powerColor = nil
    pcall(function()
        if powerType ~= nil and PowerBarColor then
            powerColor = PowerBarColor[powerType]
        end
        if (not powerColor) and powerToken and PowerBarColor then
            powerColor = PowerBarColor[powerToken]
        end
    end)

    local overrideR, overrideG, overrideB, overrideA = GetOverrideColor(powerToken)
    if overrideR then
        return overrideR, overrideG, overrideB, overrideA
    end

    if powerType == 0 or powerToken == "MANA" then
        local prefix = (unit == "target") and "target" or "player"
        return ClampColorChannel(db[prefix .. "ManaBarColorR"], 0.2),
            ClampColorChannel(db[prefix .. "ManaBarColorG"], 0.7),
            ClampColorChannel(db[prefix .. "ManaBarColorB"], 1.0),
            ClampColorChannel(db[prefix .. "ManaBarColorA"], 1.0)
    end
    if powerColor then
        return powerColor.r or 1, powerColor.g or 1, powerColor.b or 1, 1
    end
    return 1, 1, 1, 1
end

local function ResolvePowerBGColor(unit, powerType, powerToken, db)
    if db and powerToken and (unit == "player" or unit == "target") then
        local keyBase = "powerColor_" .. unit .. "_" .. tostring(powerToken) .. "_BG"
        local r = db[keyBase .. "_R"]
        local g = db[keyBase .. "_G"]
        local b = db[keyBase .. "_B"]
        local a = db[keyBase .. "_A"]
        if type(r) == "number" and type(g) == "number" and type(b) == "number" then
            return ClampColorChannel(r, 0.0),
                ClampColorChannel(g, 0.0),
                ClampColorChannel(b, 0.0),
                ClampColorChannel(a, 0.25)
        end
    end

    if powerType == 0 or powerToken == "MANA" then
        local prefix = (unit == "target") and "target" or "player"
        return ClampColorChannel(db[prefix .. "ManaBarBGColorR"], 0.0),
            ClampColorChannel(db[prefix .. "ManaBarBGColorG"], 0.0),
            ClampColorChannel(db[prefix .. "ManaBarBGColorB"], 0.0),
            ClampColorChannel(db[prefix .. "ManaBarBGColorA"], 0.25)
    end

    return 0, 0, 0, 0.25
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

local function SafeUnitIsUnit(unitA, unitB)
    if type(UnitIsUnit) ~= "function" then
        return false
    end
    local ok, result = pcall(UnitIsUnit, unitA, unitB)
    if not ok or not NotSecretValue(result) then
        return false
    end
    return result == true
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

ClampColorChannel = function(value, fallback)
    local n = SafeToNumber(value, fallback)
    if type(n) ~= "number" then
        n = fallback or 0
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function SafeAccessibleNumber(value, fallback)
    if canaccessvalue and not canaccessvalue(value) then
        return fallback
    end
    local ok, n = pcall(tonumber, value)
    if ok and type(n) == "number" then
        return n
    end
    return fallback
end

local function ClampUnitInterval(value, fallback)
    local n = SafeToNumber(value, fallback)
    if type(n) ~= "number" then
        n = fallback or 0
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function GetHealthGradientColor(percent)
    local normalized = SafeAccessibleNumber(percent, nil)
    if type(normalized) ~= "number" then
        return nil, nil, nil
    end

    if normalized < 0 then normalized = 0 end
    if normalized > 1 then normalized = 1 end
    percent = normalized
    if percent >= 0.5 then
        local t = ClampUnitInterval((percent - 0.5) * 2, 0)
        return 1 - t, 1, 0
    end

    local t = ClampUnitInterval(percent * 2, 0)
    return 1, t, 0
end

local healthGradientCurve = nil
local function EnsureHealthGradientCurve()
    if healthGradientCurve or not C_CurveUtil or not C_CurveUtil.CreateColorCurve then
        return healthGradientCurve
    end
    local curve = C_CurveUtil.CreateColorCurve()
    if not curve then
        return nil
    end
    curve:SetType(Enum.LuaCurveType.Linear)
    curve:ClearPoints()
    curve:AddPoint(0, CreateColor(1, 0, 0, 1))
    curve:AddPoint(0.5, CreateColor(1, 1, 0, 1))
    curve:AddPoint(1, CreateColor(0, 1, 0, 1))
    healthGradientCurve = curve
    return healthGradientCurve
end

local function GetHealthGradientColorForUnit(unit, fallbackPercent)
    local curve = EnsureHealthGradientCurve()
    if UnitHealthPercent and curve then
        local okCurveColor, curveColor = pcall(UnitHealthPercent, unit, true, curve)
        if okCurveColor and curveColor then
            if type(curveColor) == "table" then
                if curveColor.GetRGB then
                    local okRgb, r, g, b = pcall(curveColor.GetRGB, curveColor)
                    if okRgb and type(r) == "number" and type(g) == "number" and type(b) == "number" then
                        return r, g, b
                    end
                end
                local r = curveColor.r
                local g = curveColor.g
                local b = curveColor.b
                if type(r) == "number" and type(g) == "number" and type(b) == "number" then
                    return r, g, b
                end
            end
        end
    end
    return GetHealthGradientColor(fallbackPercent)
end

local function IsDispelHighlightEnabledForUnit(unit, db)
    if unit == "player" then
        return db.showPlayerDispelHighlight == true
    elseif unit == "target" then
        return db.showTargetDispelHighlight == true
    end
    return false
end

-- Blizzard ColorMixin objects for the color curve (same as oUF.colors.dispel)
local DISPEL_CURVE_COLORS = {
    [1]  = DEBUFF_TYPE_MAGIC_COLOR   or CreateColor(0.2, 0.6, 1.0, 1),
    [2]  = DEBUFF_TYPE_CURSE_COLOR   or CreateColor(0.6, 0.0, 1.0, 1),
    [3]  = DEBUFF_TYPE_DISEASE_COLOR or CreateColor(0.6, 0.4, 0.0, 1),
    [4]  = DEBUFF_TYPE_POISON_COLOR  or CreateColor(0.0, 0.6, 0.0, 1),
    [11] = DEBUFF_TYPE_BLEED_COLOR   or CreateColor(0.6, 0.0, 0.1, 1),
}

local function EnsureDispelColorCurve(frame)
    if not frame.mmfDispelColorCurve then
        frame.mmfDispelColorCurve = C_CurveUtil.CreateColorCurve()
        frame.mmfDispelColorCurve:SetType(Enum.LuaCurveType.Step)
    end
    frame.mmfDispelColorCurve:ClearPoints()
    for index, color in pairs(DISPEL_CURVE_COLORS) do
        frame.mmfDispelColorCurve:AddPoint(index, color)
    end
    return frame.mmfDispelColorCurve
end

local function GetColorRGB(colorObj, defaultR, defaultG, defaultB)
    if colorObj then
        if colorObj.GetRGB then
            local r, g, b = colorObj:GetRGB()
            return r or defaultR, g or defaultG, b or defaultB
        end
        return colorObj.r or defaultR, colorObj.g or defaultG, colorObj.b or defaultB
    end
    return defaultR, defaultG, defaultB
end

local function GetLegacyDispelTypeColor(dispelType)
    if dispelType == "Magic" then
        return GetColorRGB(DEBUFF_TYPE_MAGIC_COLOR, 0.2, 0.6, 1.0)
    elseif dispelType == "Curse" then
        return GetColorRGB(DEBUFF_TYPE_CURSE_COLOR, 0.6, 0.0, 1.0)
    elseif dispelType == "Disease" then
        return GetColorRGB(DEBUFF_TYPE_DISEASE_COLOR, 0.6, 0.4, 0.0)
    elseif dispelType == "Poison" then
        return GetColorRGB(DEBUFF_TYPE_POISON_COLOR, 0.0, 0.6, 0.0)
    elseif dispelType == "Bleed" then
        return GetColorRGB(DEBUFF_TYPE_BLEED_COLOR, 0.6, 0.0, 0.1)
    end
    return nil, nil, nil
end

local function FindLegacyDispellableDebuffType(unit, dispelList)
    for i = 1, 40 do
        local name, _, _, debuffType = UnitDebuff(unit, i)
        if not name then
            break
        end
        if debuffType and dispelList[debuffType] then
            return debuffType
        end
    end
    return nil
end

local function GetLibDispel()
    if not LibStub then return nil end
    local ok, lib = pcall(LibStub, "LibDispel-1.0", true)
    if ok then return lib end
    return nil
end

local function UpdateDispelHighlight(frame, db)
    if not frame or not frame.dispelHighlight or not frame.unit then
        return
    end

    local unit = frame.unit
    if (unit ~= "player" and unit ~= "target") or not IsDispelHighlightEnabledForUnit(unit, db) then
        frame.dispelHighlight:Hide()
        return
    end

    if not UnitExists(unit) then
        frame.dispelHighlight:Hide()
        return
    end

    if not SafeUnitIsUnit(unit, "player") and not UnitIsFriend("player", unit) then
        frame.dispelHighlight:Hide()
        return
    end

    local libDispel = GetLibDispel()
    if not libDispel then
        frame.dispelHighlight:Hide()
        return
    end

    local dispelList = libDispel:GetMyDispelTypes()
    if not dispelList or not (dispelList.Magic or dispelList.Curse or dispelList.Disease or dispelList.Poison or dispelList.Bleed) then
        frame.dispelHighlight:Hide()
        return
    end

    if Compat and Compat.IsRetail and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDispelTypeColor and C_CurveUtil and Enum and Enum.LuaCurveType then
        -- Retail path: use C_UnitAuras.GetAuraDispelTypeColor with a color curve.
        local bestAura = C_UnitAuras.GetAuraDataByIndex(unit, 1, "HARMFUL|RAID")
        local bestAuraInstanceID = bestAura and bestAura.auraInstanceID or nil

        if bestAuraInstanceID then
            local curve = EnsureDispelColorCurve(frame)
            local color = C_UnitAuras.GetAuraDispelTypeColor(unit, bestAuraInstanceID, curve)
            if color then
                local r, g, b = color:GetRGB()
                frame.dispelHighlight:SetVertexColor(r, g, b, 1)
                frame.dispelHighlight:Show()
            else
                frame.dispelHighlight:Hide()
            end
        else
            frame.dispelHighlight:Hide()
        end
    else
        local debuffType = FindLegacyDispellableDebuffType(unit, dispelList)
        if debuffType then
            local r, g, b = GetLegacyDispelTypeColor(debuffType)
            if r and g and b then
                frame.dispelHighlight:SetVertexColor(r, g, b, 1)
                frame.dispelHighlight:Show()
                return
            end
        end
        frame.dispelHighlight:Hide()
    end
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

local function GetPowerTextModeForUnit(db, unit)
    if unit == "player" then
        if db.playerPowerTextMode == "value" or db.playerPowerTextMode == "percent" or db.playerPowerTextMode == "both" or db.playerPowerTextMode == "both_white_percent" then
            return db.playerPowerTextMode
        end
    elseif unit == "target" then
        if db.targetPowerTextMode == "value" or db.targetPowerTextMode == "percent" or db.targetPowerTextMode == "both" or db.targetPowerTextMode == "both_white_percent" then
            return db.targetPowerTextMode
        end
    end

    -- Backward compatibility with the older percent checkbox behavior.
    if IsPowerPercentEnabledForUnit(db, unit) then
        return "both"
    end
    return "value"
end

local function ClampRgbByte(n)
    local value = math.floor(((tonumber(n) or 0) * 255) + 0.5)
    if value < 0 then value = 0 end
    if value > 255 then value = 255 end
    return value
end

local function ColorizeTextRGB(text, r, g, b)
    return string.format("|cff%02x%02x%02x%s|r", ClampRgbByte(r), ClampRgbByte(g), ClampRgbByte(b), tostring(text or ""))
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

local LEADER_ICON_TEXTURE = "Interface\\GroupFrame\\UI-Group-LeaderIcon"

local function ShouldShowLeaderIconForUnit(unit, db)
    if db.showLeaderIcons ~= true then
        return false
    end
    if unit ~= "player" and unit ~= "target" then
        return false
    end
    if not UnitExists(unit) then
        return false
    end
    if not IsInGroup or not IsInGroup() then
        return false
    end
    if not UnitIsGroupLeader then
        return false
    end
    local ok, isLeader = pcall(UnitIsGroupLeader, unit)
    return ok and isLeader == true
end

local function GetLevelSuffixForUnit(unit, db)
    local showNameLevel = (MMF_GetShowNameLevel and MMF_GetShowNameLevel(unit))
    if showNameLevel == nil then
        showNameLevel = not (db and db.showNameLevel == false)
    end
    if not showNameLevel then
        return ""
    end
    if unit ~= "player" and unit ~= "target" then
        return ""
    end
    if not UnitExists(unit) or not UnitLevel then
        return ""
    end
    local ok, level = pcall(UnitLevel, unit)
    if not ok or type(level) ~= "number" then
        return ""
    end
    if level < 0 then
        return " - ??"
    end
    return " - " .. tostring(level)
end

local function BuildNameTextWithLeaderIcon(unit, displayName, db)
    if displayName == nil then
        return ""
    end
    if type(displayName) ~= "string" then
        return ""
    end
    if issecretvalue and issecretvalue(displayName) then
        return displayName
    end
    local suffix = GetLevelSuffixForUnit(unit, db)
    if not ShouldShowLeaderIconForUnit(unit, db) then
        return displayName .. suffix
    end
    return string.format("|T%s:0|t %s%s", LEADER_ICON_TEXTURE, displayName, suffix)
end

local function GetReactionColorForNameText(unit)
    if UnitIsEnemy and UnitIsEnemy("player", unit) then
        return 0.8, 0.2, 0.2
    end
    if UnitIsFriend and UnitIsFriend("player", unit) then
        return 0.2, 0.8, 0.2
    end
    return 1, 1, 0
end

local function GetNameTextColor(unit, db)
    local usePlayerClassColor = nil
    if MMF_GetColorPlayerNameTextByClass then
        usePlayerClassColor = MMF_GetColorPlayerNameTextByClass(unit)
    end
    if usePlayerClassColor == nil then
        usePlayerClassColor = IsCheckedFlag(db and db.colorPlayerNameTextByClass)
    end

    local useNPCReactionColor = nil
    if MMF_GetColorNPCNameTextByReaction then
        useNPCReactionColor = MMF_GetColorNPCNameTextByReaction(unit)
    end
    if useNPCReactionColor == nil then
        useNPCReactionColor = IsCheckedFlag(db and db.colorNPCNameTextByReaction)
    end

    if not usePlayerClassColor and not useNPCReactionColor then
        return 1, 1, 1
    end

    local unitExists = UnitExists(unit)
    if not unitExists and unit ~= "player" then
        return 1, 1, 1
    end

    local isPlayerUnit = unitExists and UnitIsPlayer and UnitIsPlayer(unit)
    if usePlayerClassColor and isPlayerUnit and UnitClass and RAID_CLASS_COLORS then
        local _, classToken = UnitClass(unit)
        local classColor = classToken and RAID_CLASS_COLORS[classToken]
        if classColor then
            return classColor.r or 1, classColor.g or 1, classColor.b or 1
        end
    end

    if useNPCReactionColor and not isPlayerUnit then
        return GetReactionColorForNameText(unit)
    end

    return 1, 1, 1
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
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or cfg.FONT_PATH
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"
    if TryApplyFont(frame.nameText, fontPath, rounded, fontFlags) then
        frame.mmfAppliedNameFontSize = rounded
    else
        frame.mmfAppliedNameFontSize = nil
    end
    if MMF_ApplyGlobalTextShadow then
        MMF_ApplyGlobalTextShadow(frame.nameText)
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
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"
    if TryApplyFont(frame.hpText, fontPath, rounded, fontFlags) then
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
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"
    if TryApplyFont(frame.powerText, fontPath, size, fontFlags) then
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
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"
    if frame.castBarText and frame.mmfAppliedCastBarNameFontSize ~= roundedSpellName then
        if TryApplyFont(frame.castBarText, fontPath, roundedSpellName, fontFlags) then
            frame.mmfAppliedCastBarNameFontSize = roundedSpellName
        else
            frame.mmfAppliedCastBarNameFontSize = nil
        end
    end

    local castTimeSize = tonumber(MattMinimalFramesDB and MattMinimalFramesDB[castPrefix .. "CastTimeTextSize"]) or 9
    if castTimeSize < 6 then castTimeSize = 6 end
    castTimeSize = math.floor(castTimeSize + 0.5)
    if frame.castBarTime and frame.mmfAppliedCastBarHPFontSize ~= castTimeSize then
        if TryApplyFont(frame.castBarTime, fontPath, castTimeSize, fontFlags) then
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

local function EnsureTextOverlayAbovePredictions(frame, overlayTopLevel)
    if not frame or not frame.nameOverlay then
        return
    end

    local frameLevel = (frame.GetFrameLevel and frame:GetFrameLevel()) or 0
    local targetLevel = frameLevel + 30

    local numericOverlayLevel = tonumber(overlayTopLevel)
    if type(numericOverlayLevel) == "number" and (numericOverlayLevel + 6) > targetLevel then
        targetLevel = numericOverlayLevel + 6
    end

    if frame.GetFrameStrata and frame.nameOverlay.SetFrameStrata and frame.nameOverlay.GetFrameStrata then
        local desiredStrata = frame:GetFrameStrata()
        if desiredStrata and frame.nameOverlay:GetFrameStrata() ~= desiredStrata then
            frame.nameOverlay:SetFrameStrata(desiredStrata)
        end
    end
    if frame.nameOverlay.SetFrameLevel then
        if frame.mmfTextOverlayLevel ~= targetLevel then
            frame.nameOverlay:SetFrameLevel(targetLevel)
            frame.mmfTextOverlayLevel = targetLevel
        end
    end

    if frame.mmfTextOverlayDrawLayerApplied ~= true then
        if frame.nameText and frame.nameText.SetDrawLayer then
            frame.nameText:SetDrawLayer("OVERLAY", 7)
        end
        if frame.hpText and frame.hpText.SetDrawLayer then
            frame.hpText:SetDrawLayer("OVERLAY", 7)
        end
        if frame.powerText and frame.powerText.SetDrawLayer then
            frame.powerText:SetDrawLayer("OVERLAY", 7)
        end
        frame.mmfTextOverlayDrawLayerApplied = true
    end
end

local function UpdateHealPrediction(frame)
    if not frame or (not frame.myHealPrediction and not frame.healAbsorbBar) then return end

    -- Heal prediction colors/layers.
    ApplyHealPredictionBarColor(frame)
    EnsureTextOverlayAbovePredictions(frame, nil)

    local function HideAllPredictionBars()
        if frame.myHealPrediction then
            frame.myHealPrediction:Hide()
        end
        if frame.otherHealPrediction then
            frame.otherHealPrediction:Hide()
        end
        if frame.healAbsorbBar then
            frame.healAbsorbBar:Hide()
        end
    end

    local unit = frame.unit
    if not unit or not UnitExists(unit) then
        HideAllPredictionBars()
        return
    end

    local db = MattMinimalFramesDB or {}
    local showHealPrediction = db.showHealPrediction ~= false
    local showHealAbsorbBar = db.showHealAbsorbBar ~= false
    if not showHealPrediction and not showHealAbsorbBar then
        HideAllPredictionBars()
        return
    end

    local maxHealth = UnitHealthMax(unit)
    maxHealth = SafeToNumber(maxHealth, 1) or 1
    if maxHealth <= 0 then
        maxHealth = 1
    end
    local healthTexture = frame.healthBar:GetStatusBarTexture()
    local barWidth = frame.healthBar:GetWidth()
    local barHeight = frame.healthBar:GetHeight()
    local verticalHealthFill = db.healthFillTopToBottom == true
    local showOverhealPrediction = db.showOverhealPrediction == true
    local containOverhealWithinFrame = db.containOverhealWithinFrame == true

    local overlayTopLevel = nil
    if frame.healPredictionClip and frame.myHealPrediction and frame.otherHealPrediction and frame.healAbsorbBar then
        local baseLevel = (frame.healthBar and frame.healthBar.GetFrameLevel and frame.healthBar:GetFrameLevel() or frame:GetFrameLevel() or 0) + 1
        frame.healPredictionClip:SetFrameLevel(baseLevel)
        frame.myHealPrediction:SetFrameLevel(baseLevel + 1)
        frame.otherHealPrediction:SetFrameLevel(baseLevel + 2)
        frame.healAbsorbBar:SetFrameLevel(baseLevel + 4)
        overlayTopLevel = baseLevel + 3
    end
    EnsureTextOverlayAbovePredictions(frame, overlayTopLevel)

    local overflowPixels = 0
    if showOverhealPrediction then
        local sizeForOverflow = verticalHealthFill and barHeight or barWidth
        overflowPixels = math.floor(sizeForOverflow * 0.08 + 0.5)
        if overflowPixels < 4 then overflowPixels = 4 end
        if overflowPixels > 16 then overflowPixels = 16 end
    end

    if frame.healPredictionClip then
        frame.healPredictionClip:ClearAllPoints()
        if verticalHealthFill then
            frame.healPredictionClip:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", 0, 0)
            frame.healPredictionClip:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
            if containOverhealWithinFrame then
                frame.healPredictionClip:SetHeight(barHeight * 1.01)
            else
                frame.healPredictionClip:SetHeight(barHeight + overflowPixels)
            end
        else
            frame.healPredictionClip:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
            frame.healPredictionClip:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", 0, 0)
            if containOverhealWithinFrame then
                frame.healPredictionClip:SetWidth(barWidth * 1.01)
            else
                frame.healPredictionClip:SetWidth(barWidth + overflowPixels)
            end
        end
    end

    if showHealPrediction and frame.myHealPrediction and frame.otherHealPrediction then
        frame.myHealPrediction:ClearAllPoints()
        if frame.myHealPrediction.SetReverseFill then
            frame.myHealPrediction:SetReverseFill(false)
        end
        if verticalHealthFill then
            frame.myHealPrediction:SetPoint("BOTTOMLEFT", healthTexture, "TOPLEFT", 0, 0)
            frame.myHealPrediction:SetPoint("BOTTOMRIGHT", healthTexture, "TOPRIGHT", 0, 0)
            frame.myHealPrediction:SetHeight(barHeight + overflowPixels)
        else
            frame.myHealPrediction:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT", 0, 0)
            frame.myHealPrediction:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT", 0, 0)
            frame.myHealPrediction:SetWidth(barWidth + overflowPixels)
        end
        frame.myHealPrediction:SetMinMaxValues(0, maxHealth)

        local myHealTexture = frame.myHealPrediction:GetStatusBarTexture()
        frame.otherHealPrediction:ClearAllPoints()
        if frame.otherHealPrediction.SetReverseFill then
            frame.otherHealPrediction:SetReverseFill(false)
        end
        if verticalHealthFill then
            frame.otherHealPrediction:SetPoint("BOTTOMLEFT", myHealTexture, "TOPLEFT", 0, 0)
            frame.otherHealPrediction:SetPoint("BOTTOMRIGHT", myHealTexture, "TOPRIGHT", 0, 0)
            frame.otherHealPrediction:SetHeight(barHeight + overflowPixels)
        else
            frame.otherHealPrediction:SetPoint("TOPLEFT", myHealTexture, "TOPRIGHT", 0, 0)
            frame.otherHealPrediction:SetPoint("BOTTOMLEFT", myHealTexture, "BOTTOMRIGHT", 0, 0)
            frame.otherHealPrediction:SetWidth(barWidth + overflowPixels)
        end
        frame.otherHealPrediction:SetMinMaxValues(0, maxHealth)
    else
        if frame.myHealPrediction then frame.myHealPrediction:Hide() end
        if frame.otherHealPrediction then frame.otherHealPrediction:Hide() end
    end

    local myHeal = 0
    local otherHeal = 0
    local totalIncomingHeal = 0
    local allIncomingHeal = 0
    local calculatorHealAbsorb = nil

    if Compat.IsRetail and frame.healPredictionCalculator and UnitGetDetailedHealPrediction then
        pcall(function()
            UnitGetDetailedHealPrediction(unit, "player", frame.healPredictionCalculator)
            local incomingTotalHeal, playerHeal, incomingOtherHeal = frame.healPredictionCalculator:GetIncomingHeals()
            totalIncomingHeal = incomingTotalHeal or 0
            myHeal = playerHeal or 0
            otherHeal = incomingOtherHeal or 0
            if frame.healPredictionCalculator.GetTotalHealAbsorbs then
                calculatorHealAbsorb = frame.healPredictionCalculator:GetTotalHealAbsorbs() or 0
            elseif frame.healPredictionCalculator.GetHealAbsorbs then
                local healAbsorbAmount = frame.healPredictionCalculator:GetHealAbsorbs()
                calculatorHealAbsorb = healAbsorbAmount or 0
            end
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

    -- Heal prediction bars.
    if showHealPrediction and frame.myHealPrediction and frame.otherHealPrediction then
        frame.myHealPrediction:SetValue(myHeal)
        frame.otherHealPrediction:SetValue(otherHeal)
        frame.myHealPrediction:Show()
        frame.otherHealPrediction:Show()
    end

    if not frame.healAbsorbBar then
        return
    end

    -- Heal absorb bar (player only).
    local showForPlayerUnit = (unit == "player") or SafeUnitIsUnit(unit, "player")
    if not showForPlayerUnit then
        frame.healAbsorbBar:Hide()
        return
    end
    if not showHealAbsorbBar or not UnitGetTotalHealAbsorbs then
        frame.healAbsorbBar:Hide()
        return
    end

    local currentHealth = SafeToNumber(UnitHealth(unit), 0) or 0
    frame.healAbsorbBar:ClearAllPoints()
    if verticalHealthFill then
        frame.healAbsorbBar:SetHeight(barHeight)
    else
        frame.healAbsorbBar:SetWidth(barWidth)
    end
    frame.healAbsorbBar:SetMinMaxValues(0, maxHealth)

    -- Heal absorb source.
    local rawHealAbsorb = nil
    if calculatorHealAbsorb ~= nil then
        rawHealAbsorb = calculatorHealAbsorb
    elseif UnitGetTotalHealAbsorbs then
        pcall(function()
            rawHealAbsorb = UnitGetTotalHealAbsorbs(unit)
        end)
    end

    -- Heal absorb shown amount.
    local rawIncomingHeals = 0
    if UnitGetIncomingHeals then
        pcall(function()
            rawIncomingHeals = UnitGetIncomingHeals(unit) or 0
        end)
    end

    local healAbsorbValue = SafeAccessibleNumber(rawHealAbsorb, nil)
    local incomingHealsValue = SafeAccessibleNumber(rawIncomingHeals, 0) or 0
    local shownHealAbsorb = nil
    local hasOverHealAbsorb = false

    if type(healAbsorbValue) == "number" then
        shownHealAbsorb = SafeSubtract(healAbsorbValue, incomingHealsValue, 0) or 0
        if SafeIsLessOrEqual(shownHealAbsorb, 0) then
            frame.healAbsorbBar:Hide()
            return
        end
        hasOverHealAbsorb = SafeIsLess(currentHealth, shownHealAbsorb)
        frame.healAbsorbBar:SetValue(shownHealAbsorb)
    else
        local setOk = false
        pcall(function()
            frame.healAbsorbBar:SetValue(rawHealAbsorb or 0)
            setOk = true
        end)
        if not setOk then
            frame.healAbsorbBar:Hide()
            return
        end
    end

    -- Heal absorb anchoring.
    if verticalHealthFill then
        if hasOverHealAbsorb then
            if frame.healAbsorbBar.SetReverseFill then
                frame.healAbsorbBar:SetReverseFill(false)
            end
            frame.healAbsorbBar:SetPoint("BOTTOMLEFT", healthTexture, "TOPLEFT", 0, 0)
            frame.healAbsorbBar:SetPoint("BOTTOMRIGHT", healthTexture, "TOPRIGHT", 0, 0)
        else
            if frame.healAbsorbBar.SetReverseFill then
                frame.healAbsorbBar:SetReverseFill(true)
            end
            frame.healAbsorbBar:SetPoint("TOPLEFT", healthTexture, "TOPLEFT", 0, 0)
            frame.healAbsorbBar:SetPoint("TOPRIGHT", healthTexture, "TOPRIGHT", 0, 0)
        end
    else
        if hasOverHealAbsorb then
            if frame.healAbsorbBar.SetReverseFill then
                frame.healAbsorbBar:SetReverseFill(false)
            end
            frame.healAbsorbBar:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT", 0, 0)
            frame.healAbsorbBar:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT", 0, 0)
        else
            if frame.healAbsorbBar.SetReverseFill then
                frame.healAbsorbBar:SetReverseFill(true)
            end
            frame.healAbsorbBar:SetPoint("TOPRIGHT", healthTexture, "TOPRIGHT", 0, 0)
            frame.healAbsorbBar:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT", 0, 0)
        end
    end

    frame.healAbsorbBar:Show()
end

--------------------------------------------------
-- ABSORB BAR UPDATE
--------------------------------------------------

local function UpdateAbsorbBar(frame)
    if not frame or not frame.absorbBar then return end

    -- Damage absorb bar.
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

    local isTBC = Compat and Compat.IsTBC == true
    local unitGetTotalAbsorbs = UnitGetTotalAbsorbs or _G.UnitGetTotalAbsorbs
    local tbcTotalAbsorb = nil
    if isTBC then
        if unitGetTotalAbsorbs then
            local ok, totalAbsorb = pcall(unitGetTotalAbsorbs, unit)
            tbcTotalAbsorb = ok and SafeToNumber(totalAbsorb, 0) or 0
        else
            tbcTotalAbsorb = 0
        end
        if tbcTotalAbsorb <= 0 then
            tbcTotalAbsorb = GetTBCTrackedAbsorbTotal(unit)
        end
        if tbcTotalAbsorb <= 0 then
            frame.absorbBar:Hide()
            return
        end
    elseif not unitGetTotalAbsorbs then
        frame.absorbBar:Hide()
        return
    end

    local maxHealth = UnitHealthMax(unit)
    if isTBC and (SafeToNumber(maxHealth, 0) or 0) <= 0 then
        frame.absorbBar:Hide()
        return
    end
    local currentHealth = isTBC and (SafeToNumber(UnitHealth(unit), 0) or 0) or 0
    local barWidth = frame.healthBar:GetWidth()
    local barHeight = frame.healthBar:GetHeight()
    local verticalHealthFill = MattMinimalFramesDB and MattMinimalFramesDB.healthFillTopToBottom == true

    if isTBC then
        local healthTexture = frame.healthBar:GetStatusBarTexture()
        if not healthTexture then
            frame.absorbBar:Hide()
            return
        end

        local safeMaxHealth = SafeToNumber(maxHealth, 1) or 1
        if safeMaxHealth <= 0 then
            safeMaxHealth = 1
        end
        local safeCurrentHealth = SafeToNumber(currentHealth, 0) or 0
        if safeCurrentHealth < 0 then
            safeCurrentHealth = 0
        elseif safeCurrentHealth > safeMaxHealth then
            safeCurrentHealth = safeMaxHealth
        end

        local totalAbsorb = SafeToNumber(tbcTotalAbsorb, 0) or 0
        local missingHealth = safeMaxHealth - safeCurrentHealth
        if missingHealth < 0 then missingHealth = 0 end

        frame.absorbBar:ClearAllPoints()
        frame.absorbBar:SetMinMaxValues(0, safeMaxHealth)

        if missingHealth <= 0 and totalAbsorb > 0 then
            -- Full HP: keep a tiny overflow sliver so shield presence is still visible.
            if frame.absorbBar.SetReverseFill then
                frame.absorbBar:SetReverseFill(false)
            end
            if verticalHealthFill then
                frame.absorbBar:SetPoint("BOTTOMLEFT", frame.healthBar, "TOPLEFT", 0, 0)
                frame.absorbBar:SetPoint("BOTTOMRIGHT", frame.healthBar, "TOPRIGHT", 0, 0)
                frame.absorbBar:SetHeight(2)
            else
                frame.absorbBar:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", 0, 0)
                frame.absorbBar:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
                frame.absorbBar:SetWidth(2)
            end
            frame.absorbBar:SetMinMaxValues(0, 1)
            frame.absorbBar:SetValue(1)
            frame.absorbBar:Show()
            return
        end

        local shownAbsorb = totalAbsorb
        if shownAbsorb > missingHealth then
            shownAbsorb = missingHealth
        end
        if shownAbsorb <= 0 then
            frame.absorbBar:Hide()
            return
        end

        if frame.absorbBar.SetReverseFill then
            frame.absorbBar:SetReverseFill(false)
        end
        if verticalHealthFill then
            frame.absorbBar:SetPoint("BOTTOMLEFT", healthTexture, "TOPLEFT", 0, 0)
            frame.absorbBar:SetPoint("BOTTOMRIGHT", healthTexture, "TOPRIGHT", 0, 0)
            frame.absorbBar:SetHeight(barHeight)
        else
            frame.absorbBar:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT", 0, 0)
            frame.absorbBar:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT", 0, 0)
            frame.absorbBar:SetWidth(barWidth)
        end
        frame.absorbBar:SetValue(shownAbsorb)
        frame.absorbBar:Show()
        return
    end

    local anchorTexture
    if frame.otherHealPrediction and frame.otherHealPrediction:IsShown() then
        anchorTexture = frame.otherHealPrediction:GetStatusBarTexture()
    elseif frame.myHealPrediction and frame.myHealPrediction:IsShown() then
        anchorTexture = frame.myHealPrediction:GetStatusBarTexture()
    else
        anchorTexture = frame.healthBar:GetStatusBarTexture()
    end

    frame.absorbBar:ClearAllPoints()
    if verticalHealthFill then
        if frame.absorbBar.SetReverseFill then
            frame.absorbBar:SetReverseFill(false)
        end
        frame.absorbBar:SetPoint("BOTTOMLEFT", anchorTexture, "TOPLEFT", 0, 0)
        frame.absorbBar:SetPoint("BOTTOMRIGHT", anchorTexture, "TOPRIGHT", 0, 0)
        frame.absorbBar:SetHeight(barHeight)
    else
        if frame.absorbBar.SetReverseFill then
            frame.absorbBar:SetReverseFill(false)
        end
        frame.absorbBar:SetPoint("TOPLEFT", anchorTexture, "TOPRIGHT", 0, 0)
        frame.absorbBar:SetPoint("BOTTOMLEFT", anchorTexture, "BOTTOMRIGHT", 0, 0)
        frame.absorbBar:SetWidth(barWidth)
    end
    frame.absorbBar:SetMinMaxValues(0, maxHealth)
    if isTBC then
        frame.absorbBar:SetValue(tbcTotalAbsorb)
    else
        pcall(function()
            local totalAbsorb = unitGetTotalAbsorbs(unit) or 0
            frame.absorbBar:SetValue(totalAbsorb)
        end)
    end

    frame.absorbBar:Show()
end

local function BuildTrackedAbsorbAuraSignature(auras)
    if type(auras) ~= "table" then
        return ""
    end
    local parts = {}
    for _, aura in ipairs(auras) do
        local spellId = aura and aura.spellId
        if TBC_TRACKED_ABSORB_SPELLS[spellId] ~= nil then
            local expiration = SafeToNumber(aura.expirationTime, 0) or 0
            parts[#parts + 1] = tostring(spellId) .. ":" .. tostring(expiration)
        end
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

GetTBCTrackedAbsorbTotal = function(unit)
    if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
        return 0
    end

    local compat = _G.MMF_Compat
    if not compat or type(compat.GetUnitAuras) ~= "function" then
        return 0
    end

    local auras = compat.GetUnitAuras(unit, "HELPFUL")
    if type(auras) ~= "table" then
        return 0
    end

    local total = 0
    local usedLiveValue = false
    for _, aura in ipairs(auras) do
        local spellId = aura and aura.spellId
        if TBC_TRACKED_ABSORB_SPELLS[spellId] ~= nil then
            local auraValue = SafeToNumber(aura.value1, nil) or SafeToNumber(aura.value2, nil) or SafeToNumber(aura.value3, nil)
            if type(auraValue) == "number" and auraValue > 0 then
                total = total + auraValue
                usedLiveValue = true
            else
                total = total + (TBC_TRACKED_ABSORB_SPELLS[spellId] or 0)
            end
        end
    end

    local guid = UnitGUID(unit)
    if type(guid) ~= "string" or guid == "" then
        return total
    end

    local signature = BuildTrackedAbsorbAuraSignature(auras)
    if signature == "" then
        TBCTrackedAbsorbStateByGUID[guid] = nil
        return 0
    end

    local state = TBCTrackedAbsorbStateByGUID[guid]
    if not state then
        state = { current = total, signature = signature, base = total }
        TBCTrackedAbsorbStateByGUID[guid] = state
        return total
    end

    if usedLiveValue then
        state.current = total
        state.base = total
        state.signature = signature
        return total
    end

    if state.signature ~= signature or total > (state.base or 0) then
        state.current = total
        state.base = total
        state.signature = signature
        return total
    end

    local current = SafeToNumber(state.current, total) or total
    if current < 0 then current = 0 end
    if current > total then current = total end
    state.current = current
    state.base = total
    state.signature = signature
    return current
end

function MMF_TBCConsumeTrackedAbsorb(destGUID, absorbSpellId, amount)
    if not (Compat and Compat.IsTBC == true) then
        return
    end
    if type(destGUID) ~= "string" or destGUID == "" then
        return
    end
    if TBC_TRACKED_ABSORB_SPELLS[absorbSpellId] == nil then
        return
    end
    local absorbAmount = SafeToNumber(amount, 0) or 0
    if absorbAmount <= 0 then
        return
    end

    local state = TBCTrackedAbsorbStateByGUID[destGUID]
    if not state then
        return
    end

    local current = SafeToNumber(state.current, 0) or 0
    current = current - absorbAmount
    if current < 0 then current = 0 end
    state.current = current
end

function MMF_TBCConsumeTrackedAbsorbAmount(destGUID, amount)
    if not (Compat and Compat.IsTBC == true) then
        return
    end
    if type(destGUID) ~= "string" or destGUID == "" then
        return
    end
    local absorbAmount = SafeToNumber(amount, 0) or 0
    if absorbAmount <= 0 then
        return
    end

    local state = TBCTrackedAbsorbStateByGUID[destGUID]
    if not state then
        return
    end

    local current = SafeToNumber(state.current, 0) or 0
    current = current - absorbAmount
    if current < 0 then current = 0 end
    state.current = current
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
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
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
        local displayNameWithLeaderIcon = BuildNameTextWithLeaderIcon(unit, displayName, db)
        local nameTextWidth = SafeGetNameTextMaxWidth(frame)
        local useAnchorNamePosition = (MMF_IsNameTextAnchorEnabled and MMF_IsNameTextAnchorEnabled(unit)) or false
        if unit == "targettarget" then
            frame.nameText:SetText(displayNameWithLeaderIcon or "")
            if useAnchorNamePosition then
                frame.nameText:SetWidth(0)
            else
                frame.nameText:SetWidth(nameTextWidth)
            end
        else
            frame.nameText:SetText(displayNameWithLeaderIcon)
            if useAnchorNamePosition then
                frame.nameText:SetWidth(0)
            else
                frame.nameText:SetWidth(nameTextWidth)
            end
        end
        if not useAnchorNamePosition then
            ApplyAutoResizeNameText(frame, unit, displayNameWithLeaderIcon)
        else
            ApplyNameTextFontSize(frame, MMF_GetNameTextSize and MMF_GetNameTextSize(unit) or tonumber(db.nameTextSize) or 12)
        end
    end

    local nameR, nameG, nameB = GetNameTextColor(unit, db)
    frame.nameText:SetTextColor(nameR, nameG, nameB, 1)

    if MMF_UpdatePVPFlagIndicator then
        MMF_UpdatePVPFlagIndicator(frame)
    end

    local unitExistsNow = UnitExists(unit)
    local maxHP = UnitHealthMax(unit)
    local hp = UnitHealth(unit)
    if auraTestPreviewTarget then
        maxHP = 1000000
        hp = 1000000
    end

    local isPendingTargetOfTargetHealth = false
    if IsTBCTargetOfTargetTransitionFixEnabled()
        and unit == "targettarget"
        and not auraTestPreviewTarget
        and unitExistsNow then
        local safeMaxForReadyCheck = tonumber(maxHP) or 0
        local safeHPForReadyCheck = tonumber(hp) or 0
        local isDead = false
        if type(UnitIsDeadOrGhost) == "function" then
            local okDead, deadResult = pcall(UnitIsDeadOrGhost, unit)
            isDead = okDead and deadResult == true
        elseif type(UnitIsDead) == "function" then
            local okDead, deadResult = pcall(UnitIsDead, unit)
            isDead = okDead and deadResult == true
        end
        if not isDead and (safeMaxForReadyCheck <= 0 or safeHPForReadyCheck <= 0) then
            isPendingTargetOfTargetHealth = true
        end
    end

    if frame.healthBar and not isPendingTargetOfTargetHealth then
        frame.healthBar:Show()
        if frame.healthBarBG then frame.healthBarBG:Show() end
        if frame.healthBarBorder then frame.healthBarBorder:Show() end
        if not unitExistsNow and not previewMode and not auraTestPreviewTarget then
            frame.healthBar:SetMinMaxValues(0, 1)
            frame.healthBar:SetValue(1)
        else
            frame.healthBar:SetMinMaxValues(0, maxHP)
            frame.healthBar:SetValue(hp)
        end
    elseif frame.healthBar and isPendingTargetOfTargetHealth then
        frame.healthBar:Hide()
        if frame.healthBarBG then frame.healthBarBG:Hide() end
        if frame.healthBarBorder then frame.healthBarBorder:Hide() end
    end

    local healthPercentNormalized = nil
    local safeHP = SafeAccessibleNumber(hp, nil)
    local safeMaxHP = SafeAccessibleNumber(maxHP, nil)
    if type(safeHP) == "number" and type(safeMaxHP) == "number" and not SafeIsLessOrEqual(safeMaxHP, 0) then
        healthPercentNormalized = SafeDivide(safeHP, safeMaxHP, nil)
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
            if frame.hpTextDragFrame then frame.hpTextDragFrame:Hide() end
        elseif isPendingTargetOfTargetHealth then
            -- Keep HP text blank until the first valid value arrives.
            frame.hpText:SetText("")
            frame.hpText:Show()
            if frame.hpTextDragFrame then frame.hpTextDragFrame:Show() end
        elseif not unitExistsNow and not (previewMode or auraTestPreviewTarget) then
            frame.hpText:SetText("")
            frame.hpText:Hide()
            if frame.hpTextDragFrame then frame.hpTextDragFrame:Hide() end
            healthPercentNormalized = nil
        elseif (previewMode or auraTestPreviewTarget) and not unitExistsNow then
            local showHPValueText = MMF_GetShowHPValueText and MMF_GetShowHPValueText(unit)
            if showHPValueText == nil then
                showHPValueText = (db.showHPValueText ~= false)
            end
            local showHPPercentText = MMF_GetShowHPPercentText and MMF_GetShowHPPercentText(unit)
            if showHPPercentText == nil then
                showHPPercentText = (db.showHPPercentText == true)
            end
            local useShortHPValue = MMF_GetHPTextUseShortValue and MMF_GetHPTextUseShortValue(unit)
            if useShortHPValue == nil then
                useShortHPValue = (db.hpTextUseShortValue ~= false)
            end
            frame.hpText:SetText(FormatPercentAndValue(999000, showHPPercentText, showHPValueText, useShortHPValue, "100%"))
            frame.hpText:Show()
            if frame.hpTextDragFrame then frame.hpTextDragFrame:Show() end
            healthPercentNormalized = 1
        else
            local hpPercentText = GetHealthPercentText(unit, hp, maxHP)
            local showHPPercentText = MMF_GetShowHPPercentText and MMF_GetShowHPPercentText(unit)
            if showHPPercentText == nil then
                showHPPercentText = (db.showHPPercentText == true)
            end
            local showHPValueText = MMF_GetShowHPValueText and MMF_GetShowHPValueText(unit)
            if showHPValueText == nil then
                showHPValueText = (db.showHPValueText ~= false)
            end
            local useShortHPValue = MMF_GetHPTextUseShortValue and MMF_GetHPTextUseShortValue(unit)
            if useShortHPValue == nil then
                useShortHPValue = (db.hpTextUseShortValue ~= false)
            end
            frame.hpText:SetText(FormatPercentAndValue(hp, showHPPercentText, showHPValueText, useShortHPValue, hpPercentText))
            frame.hpText:Show()
            if frame.hpTextDragFrame then frame.hpTextDragFrame:Show() end
        end
    end

    if isPendingTargetOfTargetHealth then
        if frame.healthBar then frame.healthBar:Hide() end
        if frame.healthBarBG then frame.healthBarBG:Hide() end
        if frame.healthBarBorder then frame.healthBarBorder:Hide() end
        if frame.myHealPrediction then frame.myHealPrediction:Hide() end
        if frame.otherHealPrediction then frame.otherHealPrediction:Hide() end
        if frame.healAbsorbBar then frame.healAbsorbBar:Hide() end
        if frame.absorbBar then frame.absorbBar:Hide() end
        if not frame.mmfPendingTargetOfTargetHealthRetry then
            frame.mmfPendingTargetOfTargetHealthRetry = true
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function()
                    frame.mmfPendingTargetOfTargetHealthRetry = nil
                    if frame and frame.unit == "targettarget" and frame:IsShown() then
                        if MMF_RequestFrameUpdate then
                            MMF_RequestFrameUpdate(frame)
                        elseif MMF_UpdateUnitFrame then
                            MMF_UpdateUnitFrame(frame)
                        end
                    end
                end)
            else
                frame.mmfPendingTargetOfTargetHealthRetry = nil
            end
        end
        -- Stop here so stale zero-valued data cannot repaint later in this pass.
        return
    else
        frame.mmfPendingTargetOfTargetHealthRetry = nil
    end

    if not isPendingTargetOfTargetHealth then
        UpdateHealPrediction(frame)
        UpdateAbsorbBar(frame)
    end
    UpdateCastBarForEditMode(frame, unit, previewMode, db)

    if unit ~= "player" and unit ~= "target"
        and unit ~= "targettarget" and unit ~= "pet" and unit ~= "focus"
        and unit ~= "boss1" and unit ~= "boss2" and unit ~= "boss3" and unit ~= "boss4" and unit ~= "boss5" then
        if frame.hpText then frame.hpText:Hide() end
        if frame.hpTextDragFrame then frame.hpTextDragFrame:Hide() end
        if frame.powerText then frame.powerText:Hide() end
        if frame.powerTextDragFrame then frame.powerTextDragFrame:Hide() end
    end

    local r, g, b = MMF_GetUnitColor(unit)
    if db.useHealthGradientColor == true then
        local gr, gg, gb = GetHealthGradientColorForUnit(unit, healthPercentNormalized)
        if gr and gg and gb then
            r, g, b = gr, gg, gb
        end
    end
    if Compat and Compat.IsTBC
        and (not MattMinimalFramesDB or MattMinimalFramesDB.showTBCTargetTapColor ~= false)
        and unit == "target"
        and not UnitPlayerControlled(unit)
        and UnitIsTapDenied
        and UnitIsTapDenied(unit) then
        r, g, b = 0.5, 0.5, 0.5
    end
    local colorAlpha = (MMF_GetUnitColorAlpha and MMF_GetUnitColorAlpha(unit)) or 1
    if frame.healthBar then
        frame.healthBar:SetStatusBarColor(r, g, b, colorAlpha)
    end
    UpdateDispelHighlight(frame, db)

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
        local showPowerBar = false
        if unit == "player" then
            showPowerBar = (db.showPlayerPowerBar ~= false)
        else
            showPowerBar = (db.showTargetPowerBar ~= false)
        end
        local hasPower = false
        pcall(function()
            hasPower = (maxPower and maxPower > 0) and true or false
        end)

        if showPowerBar then
            local barMaxPower = maxPower or 1
            local barPower = power or 0
            if frame.powerBarFrame then frame.powerBarFrame:Show() end
            frame.powerBar:SetMinMaxValues(0, barMaxPower)
            frame.powerBar:SetValue(barPower)
            local pr, pg, pb, pa = ResolvePowerColor(unit, powerType, powerToken, db)
            frame.powerBar:SetStatusBarColor(pr, pg, pb, pa or 1)
            if frame.powerBarBG then
                local bgR, bgG, bgB, bgA = ResolvePowerBGColor(unit, powerType, powerToken, db)
                frame.powerBarBG:SetColorTexture(bgR, bgG, bgB, bgA)
            end
            if frame.powerBarBorder then frame.powerBarBorder:Show() end
            frame.powerBarBG:Show()
            frame.powerBar:Show()
        else
            if frame.powerBarFrame then frame.powerBarFrame:Hide() end
            if frame.powerBarBorder then frame.powerBarBorder:Hide() end
            frame.powerBarBG:Hide()
            frame.powerBar:Hide()
        end

        if frame.powerText then
            local showPowerText = false
            local colorPowerText = false
            local textPowerType = powerType
            local textPowerToken = powerToken
            local anchorPowerEnabled = (MMF_IsPowerTextAnchorEnabled and MMF_IsPowerTextAnchorEnabled(unit)) or false
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

            if anchorPowerEnabled then
                -- Anchor mode overrides normal power text visibility/position.
                showPowerText = true
            end

            if showPowerText then
                local textPower = power
                local textMaxPower = maxPower
                if textPowerType ~= powerType then
                    local okTextMaxPower
                    local okTextPower
                    okTextMaxPower, textMaxPower = pcall(UnitPowerMax, unit, textPowerType)
                    okTextPower, textPower = pcall(UnitPower, unit, textPowerType)
                    if not okTextMaxPower then textMaxPower = maxPower end
                    if not okTextPower then textPower = power end
                end

                local powerTextMode = GetPowerTextModeForUnit(db, unit)
                local powerPercentText = GetPowerPercentText(unit, textPower, textMaxPower, textPowerType)
                local showPowerPercent = (powerTextMode == "percent" or powerTextMode == "both" or powerTextMode == "both_white_percent")
                local showPowerValue = (powerTextMode == "value" or powerTextMode == "both" or powerTextMode == "both_white_percent")
                local display = FormatPercentAndValue(textPower, showPowerPercent, showPowerValue, false, powerPercentText)
                local tpr, tpg, tpb = ResolvePowerColor(unit, textPowerType, textPowerToken, db)
                if powerTextMode == "both_white_percent" then
                    local valueText = SafeFormatValue(textPower, false)
                    if colorPowerText then
                        valueText = ColorizeTextRGB(valueText, tpr, tpg, tpb)
                    end
                    display = string.format("%s | %s", valueText, ColorizeTextRGB(powerPercentText, 1, 1, 1))
                end
                local textScale = db.powerTextScale or 1.0
                if unit == "player" then
                    textScale = db.playerPowerTextScale or textScale
                elseif unit == "target" then
                    textScale = db.targetPowerTextScale or textScale
                end
                ApplyPowerTextFontSize(frame, textScale)
                frame.powerText:SetText(display)
                if colorPowerText and powerTextMode ~= "both_white_percent" then
                    frame.powerText:SetTextColor(tpr, tpg, tpb, 1)
                else
                    frame.powerText:SetTextColor(1, 1, 1, 1)
                end
                frame.powerText:Show()
                if frame.powerTextDragFrame then
                    frame.powerTextDragFrame:SetShown(not anchorPowerEnabled)
                end
                if MMF_ApplyPowerTextPosition then
                    MMF_ApplyPowerTextPosition(frame, unit)
                end
            else
                frame.powerText:Hide()
                if frame.powerTextDragFrame then frame.powerTextDragFrame:Hide() end
            end
        end
    end
end

MMF_UpdateUnitFrame = UpdateUnitFrame

function MMF_UpdateDispelHighlights()
    local db = MattMinimalFramesDB or {}
    if MMF_PlayerFrame then
        UpdateDispelHighlight(MMF_PlayerFrame, db)
    end
    if MMF_TargetFrame then
        UpdateDispelHighlight(MMF_TargetFrame, db)
    end
end

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
