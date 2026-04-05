local PositioningUtils = _G.MMF_FrameFactoryPositioningUtils or {}

local IsBossUnit = PositioningUtils.IsBossUnit
local GetCenterKeysForUnit = PositioningUtils.GetCenterKeysForUnit
local GetDefaultCenterForUnit = PositioningUtils.GetDefaultCenterForUnit
local SetStoredFrameCenter = PositioningUtils.SetStoredFrameCenter
local ClearLegacyFramePositionForUnit = PositioningUtils.ClearLegacyFramePositionForUnit
local HasLegacyFramePositionForUnit = PositioningUtils.HasLegacyFramePositionForUnit
local GetLiveCenterForUnit = PositioningUtils.GetLiveCenterForUnit
local UpdateFramePositionControlsForUnit = PositioningUtils.UpdateFramePositionControlsForUnit
local GetRelativeCenter = PositioningUtils.GetRelativeCenter

local function ApplyFramePosition(frame, frameName, unit, defaultPoint, defaultRelPoint, defaultX, defaultY)
    if not frame then
        return
    end

    local db = MattMinimalFramesDB
    local xKey, yKey = GetCenterKeysForUnit(unit)
    local pos = db and frameName and db[frameName] or nil
    local hasLegacyPosition = pos and pos.left ~= nil and pos.top ~= nil
    local hasCenterX = db and xKey and db[xKey] ~= nil
    local hasCenterY = db and yKey and db[yKey] ~= nil
    local hasCenterPosition = hasCenterX or hasCenterY

    frame:ClearAllPoints()

    -- Migration safety: preserve existing legacy saved positions until they are
    -- explicitly replaced (drag/reset/center-slider flows clear legacy keys).
    if hasLegacyPosition then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
        return
    end

    if hasCenterPosition then
        local centerX = tonumber(db[xKey])
        local centerY = tonumber(db[yKey])
        if IsBossUnit(unit) then
            local boss1Def = MMF_GetFrameDefinition and MMF_GetFrameDefinition("boss1")
            local unitDef = MMF_GetFrameDefinition and MMF_GetFrameDefinition(unit)
            local boss1DefaultX = (boss1Def and boss1Def.x) or 0
            local boss1DefaultY = (boss1Def and boss1Def.y) or 0
            local unitDefaultY = (unitDef and unitDef.y) or defaultY or boss1DefaultY
            if centerX == nil then
                centerX = boss1DefaultX
            end
            if centerY == nil then
                centerY = boss1DefaultY
            end
            frame:SetPoint("CENTER", UIParent, "CENTER", centerX, centerY + (unitDefaultY - boss1DefaultY))
            return
        end

        if centerX == nil then
            centerX = defaultX or 0
        end
        if centerY == nil then
            centerY = defaultY or 0
        end
        frame:SetPoint("CENTER", UIParent, "CENTER", centerX, centerY)
        return
    end

    frame:SetPoint(defaultPoint or "CENTER", UIParent, defaultRelPoint or "CENTER", defaultX or 0, defaultY or 0)
end

local function ApplyFramePositionByUnit(unit)
    if unit == "boss" then
        for i = 1, 5 do
            ApplyFramePositionByUnit("boss" .. i)
        end
        return
    end

    local def = MMF_GetFrameDefinition and MMF_GetFrameDefinition(unit)
    if not def or not def.name then
        return
    end
    local frame = _G[def.name]
    if not frame then
        return
    end
    ApplyFramePosition(frame, def.name, def.unit, def.point or "CENTER", def.relPoint or "CENTER", def.x or 0, def.y or 0)
end

local function ApplyAllFramePositions()
    if not MMF_Config or not MMF_Config.FRAME_DEFINITIONS then
        return
    end
    for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
        local frame = _G[def.name]
        if frame then
            ApplyFramePosition(frame, def.name, def.unit, def.point or "CENTER", def.relPoint or "CENTER", def.x or 0, def.y or 0)
        end
    end
end

local function ApplyFrameCenterPositionForUnit(unit, changedAxis)
    if type(unit) ~= "string" or unit == "" then
        return
    end
    local normalizedUnit = IsBossUnit(unit) and "boss" or unit

    if HasLegacyFramePositionForUnit(normalizedUnit) then
        local liveX, liveY = GetLiveCenterForUnit(normalizedUnit)
        if liveX ~= nil and liveY ~= nil then
            local xKey, yKey = GetCenterKeysForUnit(normalizedUnit)
            local storedX = tonumber(MattMinimalFramesDB and xKey and MattMinimalFramesDB[xKey])
            local storedY = tonumber(MattMinimalFramesDB and yKey and MattMinimalFramesDB[yKey])

            local nextX = liveX
            local nextY = liveY
            if changedAxis == "x" then
                if storedX ~= nil then
                    nextX = storedX
                end
            elseif changedAxis == "y" then
                if storedY ~= nil then
                    nextY = storedY
                end
            else
                if storedX ~= nil then
                    nextX = storedX
                end
                if storedY ~= nil then
                    nextY = storedY
                end
            end

            local didMove = math.abs((tonumber(nextX) or 0) - (tonumber(liveX) or 0)) > 0.0001
                or math.abs((tonumber(nextY) or 0) - (tonumber(liveY) or 0)) > 0.0001
            if not didMove then
                UpdateFramePositionControlsForUnit(normalizedUnit)
                return
            end

            SetStoredFrameCenter(normalizedUnit, nextX, nextY)
        end
    end

    ClearLegacyFramePositionForUnit(normalizedUnit)
    ApplyFramePositionByUnit(normalizedUnit)
    UpdateFramePositionControlsForUnit(normalizedUnit)
end

local function ResetFrameCenterPositionForUnit(unit)
    if type(unit) ~= "string" or unit == "" then
        return
    end
    local normalizedUnit = IsBossUnit(unit) and "boss" or unit
    local defaultX, defaultY = GetDefaultCenterForUnit(normalizedUnit)
    SetStoredFrameCenter(normalizedUnit, defaultX, defaultY)
    ClearLegacyFramePositionForUnit(normalizedUnit)
    ApplyFramePositionByUnit(normalizedUnit)
    UpdateFramePositionControlsForUnit(normalizedUnit)
end

local function SaveFramePosition(frame, frameName)
    if not frame then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local unit = frame.unit
    local centerX, centerY = GetRelativeCenter(frame)
    if centerX ~= nil and centerY ~= nil and type(unit) == "string" and unit ~= "" then
        if IsBossUnit(unit) then
            local boss1Def = MMF_GetFrameDefinition and MMF_GetFrameDefinition("boss1")
            local unitDef = MMF_GetFrameDefinition and MMF_GetFrameDefinition(unit)
            local boss1DefaultY = (boss1Def and boss1Def.y) or 0
            local unitDefaultY = (unitDef and unitDef.y) or boss1DefaultY
            SetStoredFrameCenter("boss", centerX, centerY + (boss1DefaultY - unitDefaultY))
            ClearLegacyFramePositionForUnit("boss")
            for i = 1, 5 do
                ApplyFramePositionByUnit("boss" .. i)
            end
            UpdateFramePositionControlsForUnit("boss")
            return
        end

        SetStoredFrameCenter(unit, centerX, centerY)
        ClearLegacyFramePositionForUnit(unit)
        UpdateFramePositionControlsForUnit(unit)
        return
    end

    local left = frame:GetLeft()
    local top = frame:GetTop()
    if left and top and frameName then
        MattMinimalFramesDB[frameName] = { left = left, top = top }
    end
end

local function InitializeFrameCenterPositionsFromFrames()
    if not MMF_Config or not MMF_Config.FRAME_DEFINITIONS then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local seen = {}
    for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
        local frame = def and def.name and _G[def.name]
        if frame then
            local normalizedUnit = IsBossUnit(def.unit) and "boss" or def.unit
            if normalizedUnit ~= "boss" or def.unit == "boss1" then
                local centerX, centerY = GetRelativeCenter(frame)
                if centerX ~= nil and centerY ~= nil then
                    SetStoredFrameCenter(normalizedUnit, centerX, centerY)
                    if not seen[normalizedUnit] then
                        ClearLegacyFramePositionForUnit(normalizedUnit)
                        seen[normalizedUnit] = true
                    end
                end
            end
        end
    end

    UpdateFramePositionControlsForUnit("player")
    UpdateFramePositionControlsForUnit("target")
    UpdateFramePositionControlsForUnit("targettarget")
    UpdateFramePositionControlsForUnit("pet")
    UpdateFramePositionControlsForUnit("focus")
    UpdateFramePositionControlsForUnit("boss")
end

local function RestoreFramePosition(frame, frameName, defaultPoint, defaultRelPoint, defaultX, defaultY)
    ApplyFramePosition(frame, frameName, frame and frame.unit, defaultPoint, defaultRelPoint, defaultX, defaultY)
end

_G.MMF_FrameFactoryPositioning = {
    ApplyFramePosition = ApplyFramePosition,
    ApplyFramePositionByUnit = ApplyFramePositionByUnit,
    ApplyAllFramePositions = ApplyAllFramePositions,
    ApplyFrameCenterPositionForUnit = ApplyFrameCenterPositionForUnit,
    ResetFrameCenterPositionForUnit = ResetFrameCenterPositionForUnit,
    InitializeFrameCenterPositionsFromFrames = InitializeFrameCenterPositionsFromFrames,
    SaveFramePosition = SaveFramePosition,
    RestoreFramePosition = RestoreFramePosition,
}
