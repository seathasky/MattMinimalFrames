local function SaveCastBarPosition(frame, unit)
    if not frame or not frame.castBarFrame or not unit then
        return
    end
    if unit ~= "player" and unit ~= "target" and unit ~= "focus" then
        return
    end
    local x, y = frame.castBarFrame:GetCenter()
    local px, py = frame:GetCenter()
    if not x or not y or not px or not py then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if not MattMinimalFramesDB.castBarPositions then
        MattMinimalFramesDB.castBarPositions = {}
    end
    MattMinimalFramesDB.castBarPositions[unit] = {
        x = MMF_FrameFactoryPositioningUtils and MMF_FrameFactoryPositioningUtils.RoundCoordinate(x - px) or x - px,
        y = MMF_FrameFactoryPositioningUtils and MMF_FrameFactoryPositioningUtils.RoundCoordinate(y - py) or y - py,
    }
    if MMF_SyncCastBarOffsetControlsForUnit then
        MMF_SyncCastBarOffsetControlsForUnit(unit)
    end
end

local function RoundCoordinate(value)
    if MMF_FrameFactoryPositioningUtils and MMF_FrameFactoryPositioningUtils.RoundCoordinate then
        return MMF_FrameFactoryPositioningUtils.RoundCoordinate(value)
    end
    return value
end

local function GetFontStringHeight(fontString, fallback)
    if not fontString then
        return fallback or 0
    end
    local _, size = fontString:GetFont()
    return tonumber(size) or tonumber(fallback) or 0
end

local function GetCastBarHeight(frame, scaleY)
    local baseHeight = 8 * (tonumber(scaleY) or 1.0)
    return math.max(
        4,
        baseHeight,
        GetFontStringHeight(frame and frame.castBarText, 9) + 4,
        GetFontStringHeight(frame and frame.castBarTime, 9) + 4
    )
end

local function GetFrameHeight(frame)
    return tonumber(frame and (frame.originalHeight or frame:GetHeight())) or 28
end

local function GetEmbeddedLegacyDefaultOffset(frame, castBarHeight)
    local frameHeight = GetFrameHeight(frame)
    return 0, RoundCoordinate((-frameHeight * 0.5) + 1 + (castBarHeight * 0.5))
end

local function IsLegacyEmbeddedDefault(frame, x, y, castBarHeight)
    if x == nil or y == nil then
        return false
    end
    local legacyX, legacyY = GetEmbeddedLegacyDefaultOffset(frame, castBarHeight)
    return math.abs((tonumber(x) or 0) - (tonumber(legacyX) or 0)) < 0.5
        and math.abs((tonumber(y) or 0) - (tonumber(legacyY) or 0)) < 0.5
end

local function ApplyCastBarPosition(frame, unit)
    if not frame or not frame.castBarFrame or not unit then
        return
    end

    local castBarPrefix = (unit == "player" and "playerCastBar")
        or (unit == "target" and "targetCastBar")
        or (unit == "focus" and "focusCastBar")
        or nil
    local scaleX = 1.0
    local scaleY = 1.0
    if castBarPrefix and MattMinimalFramesDB then
        scaleX = tonumber(MattMinimalFramesDB[castBarPrefix .. "FrameScaleX"]) or 1.0
        scaleY = tonumber(MattMinimalFramesDB[castBarPrefix .. "FrameScaleY"]) or 1.0
    elseif unit == "focus" then
        scaleX = tonumber(MMF_GetFrameScaleX and MMF_GetFrameScaleX("focus")) or 1.0
        scaleY = tonumber(MMF_GetFrameScaleY and MMF_GetFrameScaleY("focus")) or 1.0
    end
    if scaleX < 0.1 then scaleX = 0.1 end
    if scaleX > 6.0 then scaleX = 6.0 end
    if scaleY < 0.1 then scaleY = 0.1 end
    if scaleY > 10.0 then scaleY = 10.0 end

    local baseWidth = math.max(8, (frame.originalWidth or frame:GetWidth() or 0) - 2)
    local width = math.max(8, baseWidth * scaleX)
    local legacyHeight = math.max(4, 8 * scaleY)
    local height = GetCastBarHeight(frame, scaleY)
    frame.castBarFrame:SetSize(width, height)
    frame.castBarFrame:ClearAllPoints()

    local dbPos = MattMinimalFramesDB and MattMinimalFramesDB.castBarPositions and MattMinimalFramesDB.castBarPositions[unit]
    local dbX = dbPos and tonumber(dbPos.x) or nil
    local dbY = dbPos and tonumber(dbPos.y) or nil
    if IsLegacyEmbeddedDefault(frame, dbX, dbY, legacyHeight) then
        MattMinimalFramesDB.castBarPositions[unit] = nil
        dbX = nil
        dbY = nil
    end
    if dbX ~= nil and dbY ~= nil then
        frame.castBarFrame:SetPoint("CENTER", frame, "CENTER", dbX, dbY)
    else
        frame.castBarFrame:SetPoint("TOP", frame, "BOTTOM", 0, -1)
    end

    local timeWidth = 36
    if frame.castBarTime then
        frame.castBarTime:SetWidth(timeWidth)
    end
    if frame.castBarText then
        frame.castBarText:SetWidth(math.max(8, width - timeWidth - 8))
    end
    if MMF_RefreshCastBarTextLayer then
        MMF_RefreshCastBarTextLayer(frame)
    end
    if MMF_SyncCastBarOffsetControlsForUnit then
        MMF_SyncCastBarOffsetControlsForUnit(unit)
    end
end

local function IsSupportedCastBarUnit(unit)
    return unit == "player" or unit == "target" or unit == "focus"
end

local function GetCastBarDefaultOffsetForUnit(unit)
    if not IsSupportedCastBarUnit(unit) then
        return 0, 0
    end

    local ownerFrame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit)
    local frameHeight = GetFrameHeight(ownerFrame)
    local castBarHeight = (ownerFrame and ownerFrame.castBarFrame and ownerFrame.castBarFrame:GetHeight())
        or GetCastBarHeight(ownerFrame, 1.0)
    local y = (-frameHeight * 0.5) - 1 - (castBarHeight * 0.5)
    return 0, RoundCoordinate(y or 0)
end

local function GetStoredCastBarOffsetForUnit(unit)
    if not IsSupportedCastBarUnit(unit) then
        return nil, nil
    end
    local dbPos = MattMinimalFramesDB and MattMinimalFramesDB.castBarPositions and MattMinimalFramesDB.castBarPositions[unit]
    local x = dbPos and tonumber(dbPos.x) or nil
    local y = dbPos and tonumber(dbPos.y) or nil
    if x == nil or y == nil then
        return nil, nil
    end
    return RoundCoordinate(x or 0), RoundCoordinate(y or 0)
end

local function GetCastBarOffsetForUnit(unit)
    local x, y = GetStoredCastBarOffsetForUnit(unit)
    if x ~= nil and y ~= nil then
        return x, y
    end
    return GetCastBarDefaultOffsetForUnit(unit)
end

local function UpdateCastBarOffsetControlsForUnit(unit)
    if not IsSupportedCastBarUnit(unit) then
        return
    end
    local registry = _G.MMF_CastBarOffsetSliderRegistry
    if type(registry) ~= "table" then
        return
    end

    local selectedUnit = unit
    if type(registry.getSelectedUnit) == "function" then
        local ok, selected = pcall(registry.getSelectedUnit)
        if ok and type(selected) == "string" and selected ~= "" then
            selectedUnit = selected
        end
    end
    if selectedUnit ~= unit then
        return
    end

    local x, y = GetCastBarOffsetForUnit(unit)
    local updateControl = MMF_FrameFactoryPositioningUtils and MMF_FrameFactoryPositioningUtils.UpdateSingleFramePositionControl
    if updateControl then
        updateControl(registry.x, x)
        updateControl(registry.y, y)
    end
end

local function SetCastBarOffsetForUnit(unit, offsetX, offsetY)
    if not IsSupportedCastBarUnit(unit) then
        return
    end
    local x = RoundCoordinate(tonumber(offsetX))
    local y = RoundCoordinate(tonumber(offsetY))
    if x == nil or y == nil then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if not MattMinimalFramesDB.castBarPositions then
        MattMinimalFramesDB.castBarPositions = {}
    end
    MattMinimalFramesDB.castBarPositions[unit] = { x = x, y = y }

    local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit)
    if frame and frame.castBarFrame then
        ApplyCastBarPosition(frame, unit)
    end
    UpdateCastBarOffsetControlsForUnit(unit)
end

local function ResetCastBarOffsetForUnit(unit)
    if not IsSupportedCastBarUnit(unit) then
        return
    end
    if MattMinimalFramesDB and MattMinimalFramesDB.castBarPositions then
        MattMinimalFramesDB.castBarPositions[unit] = nil
    end

    local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit)
    if frame and frame.castBarFrame then
        ApplyCastBarPosition(frame, unit)
    end
    UpdateCastBarOffsetControlsForUnit(unit)
end

local function IsCastBarOffsetDefaultForUnit(unit)
    if not IsSupportedCastBarUnit(unit) then
        return true
    end
    local valueX, valueY = GetCastBarOffsetForUnit(unit)
    local defaultX, defaultY = GetCastBarDefaultOffsetForUnit(unit)
    return math.abs((tonumber(valueX) or 0) - (tonumber(defaultX) or 0)) < 0.0001
        and math.abs((tonumber(valueY) or 0) - (tonumber(defaultY) or 0)) < 0.0001
end

_G.MMF_FrameFactoryCastbarOffsets = {
    SaveCastBarPosition = SaveCastBarPosition,
    ApplyCastBarPosition = ApplyCastBarPosition,
    IsSupportedCastBarUnit = IsSupportedCastBarUnit,
    GetCastBarDefaultOffsetForUnit = GetCastBarDefaultOffsetForUnit,
    GetStoredCastBarOffsetForUnit = GetStoredCastBarOffsetForUnit,
    GetCastBarOffsetForUnit = GetCastBarOffsetForUnit,
    UpdateCastBarOffsetControlsForUnit = UpdateCastBarOffsetControlsForUnit,
    SetCastBarOffsetForUnit = SetCastBarOffsetForUnit,
    ResetCastBarOffsetForUnit = ResetCastBarOffsetForUnit,
    IsCastBarOffsetDefaultForUnit = IsCastBarOffsetDefaultForUnit,
}
