local function GetDefaultPowerTextAnchor(frame, unit)
    if unit == "player" then
        return "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 8
    elseif unit == "target" then
        return "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 8
    elseif unit == "targettarget" or unit == "pet" then
        return "BOTTOM", frame, "BOTTOM", 0, 0
    end
    return "BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3
end

local appliedTextAnchors = setmetatable({}, { __mode = "k" })
local appliedTextJustifications = setmetatable({}, { __mode = "k" })

local function IsAppliedAnchor(region, point, relativeTo, relativePoint, x, y)
    local applied = appliedTextAnchors[region]
    return applied
        and applied[1] == point
        and applied[2] == relativeTo
        and applied[3] == relativePoint
        and applied[4] == x
        and applied[5] == y
end

local function RememberAppliedAnchor(region, point, relativeTo, relativePoint, x, y)
    appliedTextAnchors[region] = { point, relativeTo, relativePoint, x, y }
end

local function SetPointIfChanged(region, point, relativeTo, relativePoint, x, y)
    if not region then
        return
    end
    if region.GetNumPoints and region.GetPoint and region:GetNumPoints() == 1 then
        local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = region:GetPoint(1)
        
        
        local hasSecretAnchor = issecretvalue and (
            issecretvalue(currentPoint)
            or issecretvalue(currentRelativeTo)
            or issecretvalue(currentRelativePoint)
            or issecretvalue(currentX)
            or issecretvalue(currentY)
        )
        if hasSecretAnchor then
            if IsAppliedAnchor(region, point, relativeTo, relativePoint, x, y) then
                return
            end
        else
            if currentPoint == point
                and currentRelativeTo == relativeTo
                and currentRelativePoint == relativePoint
                and currentX == x
                and currentY == y
            then
                RememberAppliedAnchor(region, point, relativeTo, relativePoint, x, y)
                return
            end
        end
    end

    region:ClearAllPoints()
    region:SetPoint(point, relativeTo, relativePoint, x, y)
    RememberAppliedAnchor(region, point, relativeTo, relativePoint, x, y)
end

local function SetJustifyIfChanged(region, justify)
    if not region or not region.SetJustifyH then
        return
    end
    local currentJustify = region.GetJustifyH and region:GetJustifyH()
    if region.GetJustifyH then
        if issecretvalue and issecretvalue(currentJustify) then
            if appliedTextJustifications[region] == justify then
                return
            end
        elseif currentJustify == justify then
            appliedTextJustifications[region] = justify
            return
        end
    end
    region:SetJustifyH(justify)
    appliedTextJustifications[region] = justify
end

local function ApplyPowerTextPosition(frame, unit)
    if not frame or not frame.powerText then return end

    local powerAnchorPoint = (MMF_GetPowerTextAnchorPoint and MMF_GetPowerTextAnchorPoint(unit)) or "OFF"
    if powerAnchorPoint ~= "OFF" and MMF_GetTextAnchorPreset then
        local preset = MMF_GetTextAnchorPreset(powerAnchorPoint)
        preset = preset or { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 2, justify = "CENTER" }
        if frame.powerTextDragFrame then
            frame.powerTextDragFrame:Hide()
        end
        SetPointIfChanged(frame.powerText, preset.point, frame, preset.relPoint, preset.x, preset.y)
        SetJustifyIfChanged(frame.powerText, preset.justify or "CENTER")
        return
    end

    if frame.powerTextDragFrame then
        if frame.powerTextDragFrame.mmfDragInProgress then
            return
        end
        local pos = MattMinimalFramesDB and MattMinimalFramesDB.powerTextPositions and MattMinimalFramesDB.powerTextPositions[unit]
        local hasCustomPosition = type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number"
        if hasCustomPosition then
            SetPointIfChanged(frame.powerTextDragFrame, "CENTER", frame, "CENTER", pos.x, pos.y)
        else
            local point, relFrame, relPoint, x, y = GetDefaultPowerTextAnchor(frame, unit)
            SetPointIfChanged(frame.powerTextDragFrame, point, relFrame, relPoint, x, y)
        end

        if unit == "player" then
            SetPointIfChanged(frame.powerText, "BOTTOMLEFT", frame.powerTextDragFrame, "BOTTOMLEFT", 0, 0)
            SetJustifyIfChanged(frame.powerText, "LEFT")
        elseif unit == "target" then
            SetPointIfChanged(frame.powerText, "BOTTOMRIGHT", frame.powerTextDragFrame, "BOTTOMRIGHT", 0, 0)
            SetJustifyIfChanged(frame.powerText, "RIGHT")
        elseif hasCustomPosition then
            SetPointIfChanged(frame.powerText, "CENTER", frame.powerTextDragFrame, "CENTER", 0, 0)
            SetJustifyIfChanged(frame.powerText, "CENTER")
        else
            local point, relFrame, relPoint, x, y = GetDefaultPowerTextAnchor(frame, unit)
            SetPointIfChanged(frame.powerText, point, relFrame, relPoint, x, y)
            SetJustifyIfChanged(frame.powerText, "CENTER")
        end
        return
    end

    local point, relFrame, relPoint, x, y = GetDefaultPowerTextAnchor(frame, unit)
    SetPointIfChanged(frame.powerText, point, relFrame, relPoint, x, y)
    SetJustifyIfChanged(frame.powerText, "CENTER")
end

local function GetDefaultHPTextAnchor(frame, unit)
    local hpX = MMF_GetHPTextXOffset and MMF_GetHPTextXOffset(unit) or 0
    local hpY = MMF_GetHPTextYOffset and MMF_GetHPTextYOffset(unit) or 0

    if unit == "player" then
        return "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0 + hpX, 8 + hpY
    elseif unit == "target" then
        return "BOTTOMLEFT", frame, "BOTTOMLEFT", 2 + hpX, 8 + hpY
    elseif unit == "targettarget" then
        return "BOTTOMLEFT", frame, "BOTTOMLEFT", 2 + hpX, 8 + hpY
    elseif unit == "pet"
        or unit == "focus"
        or unit == "boss1"
        or unit == "boss2"
        or unit == "boss3"
        or unit == "boss4"
        or unit == "boss5"
    then
        return "BOTTOM", frame, "BOTTOM", 0 + hpX, 0 + hpY
    end
    return "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3 + hpX, 3 + hpY
end

local function GetHPTextAttachPoint(unit)
    if unit == "player" then
        return "BOTTOMRIGHT"
    elseif unit == "target" then
        return "BOTTOMLEFT"
    elseif unit == "targettarget" then
        return "BOTTOMLEFT"
    elseif unit == "pet"
        or unit == "focus"
        or unit == "boss1"
        or unit == "boss2"
        or unit == "boss3"
        or unit == "boss4"
        or unit == "boss5"
    then
        return "BOTTOM"
    end
    return "BOTTOMRIGHT"
end

local function ConvertLegacyHPTextPositionToEdge(frame, unit, centerX, centerY)
    local frameWidth = frame:GetWidth() or frame.originalWidth or 0
    local frameHeight = frame:GetHeight() or frame.originalHeight or 0
    local edgeX = centerX
    if unit == "player" then
        edgeX = centerX - (frameWidth * 0.5)
    else
        edgeX = centerX + (frameWidth * 0.5)
    end
    local edgeY = centerY + (frameHeight * 0.5)
    return edgeX, edgeY
end

local function GetStoredHPTextEdgePosition(frame, unit)
    local store = MattMinimalFramesDB and MattMinimalFramesDB.hpTextPositions
    local pos = store and store[unit]
    if type(pos) ~= "table" then
        return nil, nil
    end

    local x = tonumber(pos.x)
    local y = tonumber(pos.y)
    if type(x) ~= "number" or type(y) ~= "number" then
        return nil, nil
    end

    if pos.mode == "edge" then
        return x, y
    end

    local edgeX, edgeY = ConvertLegacyHPTextPositionToEdge(frame, unit, x, y)
    pos.mode = "edge"
    pos.x = edgeX
    pos.y = edgeY
    return edgeX, edgeY
end

local function ApplyHPTextPosition(frame, unit)
    if not frame or not frame.hpText then return end

    local useCustomAnchor = (MMF_IsHPTextAnchorEnabled and MMF_IsHPTextAnchorEnabled(unit)) or false
    if useCustomAnchor then
        local preset = nil
        if MMF_GetTextAnchorPreset and MMF_GetHPTextAnchorPoint then
            preset = MMF_GetTextAnchorPreset(MMF_GetHPTextAnchorPoint(unit))
        end
        preset = preset or { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 2, justify = "CENTER" }

        if frame.hpTextDragFrame then
            frame.hpTextDragFrame:Hide()
        end

        frame.hpText:ClearAllPoints()
        frame.hpText:SetPoint(preset.point, frame, preset.relPoint, preset.x, preset.y)
        if frame.hpText.SetJustifyH then
            frame.hpText:SetJustifyH(preset.justify or "CENTER")
        end
        return
    end

    if frame.hpTextDragFrame then
        if frame.hpTextDragFrame.mmfDragInProgress then
            return
        end
        frame.hpTextDragFrame:ClearAllPoints()
        local attach = GetHPTextAttachPoint(unit)
        local edgeX, edgeY = GetStoredHPTextEdgePosition(frame, unit)
        if type(edgeX) == "number" and type(edgeY) == "number" then
            frame.hpTextDragFrame:SetPoint(attach, frame, attach, edgeX, edgeY)
        else
            local point, relFrame, relPoint, x, y = GetDefaultHPTextAnchor(frame, unit)
            frame.hpTextDragFrame:SetPoint(point, relFrame, relPoint, x, y)
        end

        frame.hpText:ClearAllPoints()
        frame.hpText:SetPoint(attach, frame.hpTextDragFrame, attach, 0, 0)
        return
    end

    local point, relFrame, relPoint, x, y = GetDefaultHPTextAnchor(frame, unit)
    frame.hpText:ClearAllPoints()
    frame.hpText:SetPoint(point, relFrame, relPoint, x, y)
end

local function ApplyPowerTextPositions()
    local function ApplyFor(frame, unit)
        if not frame or not frame.powerText then return end
        ApplyPowerTextPosition(frame, unit)
    end

    ApplyFor(_G.MMF_PlayerFrame, "player")
    ApplyFor(_G.MMF_TargetFrame, "target")
    ApplyFor(_G.MMF_TargetOfTargetFrame, "targettarget")
    ApplyFor(_G.MMF_PetFrame, "pet")
    ApplyFor(_G.MMF_FocusFrame, "focus")
    ApplyFor(_G.MMF_Boss1Frame, "boss1")
    ApplyFor(_G.MMF_Boss2Frame, "boss2")
    ApplyFor(_G.MMF_Boss3Frame, "boss3")
    ApplyFor(_G.MMF_Boss4Frame, "boss4")
    ApplyFor(_G.MMF_Boss5Frame, "boss5")
end

local function ApplyHPTextPositions()
    local function ApplyFor(frame, unit)
        if not frame or not frame.hpText then return end
        ApplyHPTextPosition(frame, unit)
    end

    ApplyFor(_G.MMF_PlayerFrame, "player")
    ApplyFor(_G.MMF_TargetFrame, "target")
    ApplyFor(_G.MMF_TargetOfTargetFrame, "targettarget")
    ApplyFor(_G.MMF_PetFrame, "pet")
    ApplyFor(_G.MMF_FocusFrame, "focus")
    ApplyFor(_G.MMF_Boss1Frame, "boss1")
    ApplyFor(_G.MMF_Boss2Frame, "boss2")
    ApplyFor(_G.MMF_Boss3Frame, "boss3")
    ApplyFor(_G.MMF_Boss4Frame, "boss4")
    ApplyFor(_G.MMF_Boss5Frame, "boss5")
end

_G.MMF_FrameFactoryTextPositions = {
    GetDefaultPowerTextAnchor = GetDefaultPowerTextAnchor,
    ApplyPowerTextPosition = ApplyPowerTextPosition,
    GetDefaultHPTextAnchor = GetDefaultHPTextAnchor,
    GetHPTextAttachPoint = GetHPTextAttachPoint,
    ConvertLegacyHPTextPositionToEdge = ConvertLegacyHPTextPositionToEdge,
    GetStoredHPTextEdgePosition = GetStoredHPTextEdgePosition,
    ApplyHPTextPosition = ApplyHPTextPosition,
    ApplyPowerTextPositions = ApplyPowerTextPositions,
    ApplyHPTextPositions = ApplyHPTextPositions,
}
