local function IsBossUnit(unit)
    return unit == "boss1" or unit == "boss2" or unit == "boss3" or unit == "boss4" or unit == "boss5" or unit == "boss"
end

local function GetPositionPrefixForUnit(unit)
    if unit == "targettarget" then
        return "tot"
    end
    if IsBossUnit(unit) then
        return "boss"
    end
    return unit
end

local function RoundCoordinate(value)
    local n = tonumber(value)
    if not n then
        return nil
    end
    if n >= 0 then
        return math.floor(n + 0.5)
    end
    return math.ceil(n - 0.5)
end

local function GetRelativeCenter(frame)
    if not frame or not UIParent then
        return nil, nil
    end
    local centerX, centerY = frame:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()
    if not centerX or not centerY or not parentCenterX or not parentCenterY then
        return nil, nil
    end
    return centerX - parentCenterX, centerY - parentCenterY
end

local function GetRelativeCenterFromTopLeft(frame, left, top)
    local leftCoord = tonumber(left)
    local topCoord = tonumber(top)
    if leftCoord == nil or topCoord == nil or not UIParent then
        return nil, nil
    end

    local parentCenterX, parentCenterY = UIParent:GetCenter()
    if not parentCenterX or not parentCenterY then
        return nil, nil
    end

    local width = frame and frame.GetWidth and frame:GetWidth()
    local height = frame and frame.GetHeight and frame:GetHeight()
    width = tonumber(width)
    height = tonumber(height)
    if width == nil or height == nil then
        return nil, nil
    end

    local frameScale = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1
    local parentScale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    frameScale = tonumber(frameScale) or 1
    parentScale = tonumber(parentScale) or 1
    if parentScale == 0 then
        parentScale = 1
    end
    local scaleRatio = frameScale / parentScale

    local centerX = leftCoord + (width * scaleRatio * 0.5) - parentCenterX
    local centerY = topCoord - (height * scaleRatio * 0.5) - parentCenterY
    return centerX, centerY
end

local function GetCenterKeysForUnit(unit)
    local prefix = GetPositionPrefixForUnit(unit)
    if type(prefix) ~= "string" or prefix == "" then
        return nil, nil
    end
    return prefix .. "FrameCenterX", prefix .. "FrameCenterY"
end

local function GetDefaultCenterForUnit(unit)
    local normalizedUnit = IsBossUnit(unit) and "boss" or unit
    local lookupUnit = (normalizedUnit == "boss") and "boss1" or normalizedUnit
    local def = MMF_GetFrameDefinition and MMF_GetFrameDefinition(lookupUnit)
    if not def then
        return 0, 0
    end
    return tonumber(def.x) or 0, tonumber(def.y) or 0
end

local function SetStoredFrameCenter(unit, centerX, centerY)
    local xKey, yKey = GetCenterKeysForUnit(unit)
    if not xKey or not yKey then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    local roundedX = RoundCoordinate(centerX)
    local roundedY = RoundCoordinate(centerY)
    if roundedX ~= nil then
        MattMinimalFramesDB[xKey] = roundedX
    end
    if roundedY ~= nil then
        MattMinimalFramesDB[yKey] = roundedY
    end
end

local function ClearStoredFrameCenter(unit)
    local xKey, yKey = GetCenterKeysForUnit(unit)
    if not xKey or not yKey or not MattMinimalFramesDB then
        return
    end
    MattMinimalFramesDB[xKey] = nil
    MattMinimalFramesDB[yKey] = nil
end

local function ClearLegacyFramePositionForUnit(unit)
    if not MattMinimalFramesDB then
        return
    end
    local prefix = GetPositionPrefixForUnit(unit)
    if prefix == "boss" then
        for i = 1, 5 do
            MattMinimalFramesDB["MMF_Boss" .. i .. "Frame"] = nil
        end
        return
    end
    if MMF_GetFrameDefinition then
        local def = MMF_GetFrameDefinition(unit)
        if def and def.name then
            MattMinimalFramesDB[def.name] = nil
        end
    end
end

local function GetLegacyFramePositionForUnit(unit)
    if not MattMinimalFramesDB then
        return nil
    end

    local normalizedUnit = IsBossUnit(unit) and "boss" or unit
    local prefix = GetPositionPrefixForUnit(normalizedUnit)
    if prefix == "boss" then
        for i = 1, 5 do
            local pos = MattMinimalFramesDB["MMF_Boss" .. i .. "Frame"]
            if type(pos) == "table" and pos.left ~= nil and pos.top ~= nil then
                return pos
            end
        end
        return nil
    end

    if MMF_GetFrameDefinition then
        local def = MMF_GetFrameDefinition(normalizedUnit)
        if def and def.name then
            local pos = MattMinimalFramesDB[def.name]
            if type(pos) == "table" and pos.left ~= nil and pos.top ~= nil then
                return pos
            end
        end
    end

    return nil
end

local function HasLegacyFramePositionForUnit(unit)
    return GetLegacyFramePositionForUnit(unit) ~= nil
end

local function GetPositionAnchorFrameForUnit(unit)
    local normalizedUnit = IsBossUnit(unit) and "boss" or unit
    local anchorUnit = (normalizedUnit == "boss") and "boss1" or normalizedUnit
    local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(anchorUnit) or nil
    if not frame and MMF_GetFrameDefinition then
        local def = MMF_GetFrameDefinition(anchorUnit)
        if def and def.name then
            frame = _G[def.name]
        end
    end
    return frame
end

local function GetLiveCenterForUnit(unit)
    local normalizedUnit = IsBossUnit(unit) and "boss" or unit
    local frame = GetPositionAnchorFrameForUnit(unit)
    local centerX, centerY = GetRelativeCenter(frame)
    if centerX ~= nil and centerY ~= nil then
        return centerX, centerY
    end

    if normalizedUnit == "boss" then
        return nil, nil
    end

    local legacyPos = GetLegacyFramePositionForUnit(unit)
    if frame and legacyPos then
        centerX, centerY = GetRelativeCenterFromTopLeft(frame, legacyPos.left, legacyPos.top)
        if centerX ~= nil and centerY ~= nil then
            return centerX, centerY
        end
    end

    return nil, nil
end

local function UpdateSingleFramePositionControl(control, value)
    if not control or not control.slider then
        return
    end
    if control.valueText and control.valueText.HasFocus and control.valueText:HasFocus() then
        return
    end
    local slider = control.slider
    local current = slider:GetValue()
    local target = tonumber(value) or 0
    if current == nil or math.abs(current - target) > 0.0001 then
        if control.MMFSetValueSilently then
            control.MMFSetValueSilently(target)
        else
            slider:SetValue(target)
        end
    elseif control.MMFRefreshWidget then
        control.MMFRefreshWidget()
    end
    if control.RefreshResetVisibility then
        control.RefreshResetVisibility()
    end
end

local function UpdateFramePositionControlsForUnit(unit)
    local registry = _G.MMF_FramePositionSliderRegistry
    if type(registry) ~= "table" then
        return
    end

    local normalizedUnit = IsBossUnit(unit) and "boss" or unit
    local controls = registry[normalizedUnit]
    if type(controls) ~= "table" then
        return
    end

    local xKey, yKey = GetCenterKeysForUnit(normalizedUnit)
    if not xKey or not yKey then
        return
    end

    local defaultX, defaultY = GetDefaultCenterForUnit(normalizedUnit)
    local valueX = tonumber(MattMinimalFramesDB and MattMinimalFramesDB[xKey])
    local valueY = tonumber(MattMinimalFramesDB and MattMinimalFramesDB[yKey])

    if HasLegacyFramePositionForUnit(normalizedUnit) then
        local liveX, liveY = GetLiveCenterForUnit(normalizedUnit)
        if liveX ~= nil and liveY ~= nil then
            valueX = liveX
            valueY = liveY
        end
    end

    if valueX == nil then
        valueX = defaultX
    end
    if valueY == nil then
        valueY = defaultY
    end

    UpdateSingleFramePositionControl(controls.x, valueX)
    UpdateSingleFramePositionControl(controls.y, valueY)
end

_G.MMF_FrameFactoryPositioningUtils = {
    IsBossUnit = IsBossUnit,
    GetPositionPrefixForUnit = GetPositionPrefixForUnit,
    RoundCoordinate = RoundCoordinate,
    GetRelativeCenter = GetRelativeCenter,
    GetRelativeCenterFromTopLeft = GetRelativeCenterFromTopLeft,
    GetCenterKeysForUnit = GetCenterKeysForUnit,
    GetDefaultCenterForUnit = GetDefaultCenterForUnit,
    SetStoredFrameCenter = SetStoredFrameCenter,
    ClearStoredFrameCenter = ClearStoredFrameCenter,
    ClearLegacyFramePositionForUnit = ClearLegacyFramePositionForUnit,
    GetLegacyFramePositionForUnit = GetLegacyFramePositionForUnit,
    HasLegacyFramePositionForUnit = HasLegacyFramePositionForUnit,
    GetPositionAnchorFrameForUnit = GetPositionAnchorFrameForUnit,
    GetLiveCenterForUnit = GetLiveCenterForUnit,
    UpdateSingleFramePositionControl = UpdateSingleFramePositionControl,
    UpdateFramePositionControlsForUnit = UpdateFramePositionControlsForUnit,
}
