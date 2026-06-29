local function CreateTooltipHandlers(frame)
    local function ShouldShowUnitTooltip(unit)
        return unit == "target"
            or unit == "targettarget"
            or unit == "player"
            or unit == "pet"
            or unit == "focus"
            or unit == "boss1"
            or unit == "boss2"
            or unit == "boss3"
            or unit == "boss4"
            or unit == "boss5"
    end

    frame:SetScript("OnEnter", function(self)
        -- Highlight is strictly a hover affordance; keep it independent of tooltip eligibility.
        if self.highlightTexture then
            self.highlightTexture:Show()
        end

        if self.unit and UnitExists(self.unit) and ShouldShowUnitTooltip(self.unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        if self.highlightTexture then
            self.highlightTexture:Hide()
        end
        if self.unit and ShouldShowUnitTooltip(self.unit) then
            GameTooltip:Hide()
        end
    end)
end

local function IsEditModeDragEnabled()
    return MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
end

local function IsTestModeShiftDragEnabled()
    return MattMinimalFramesDB and (MattMinimalFramesDB.layoutTestMode == true or MattMinimalFramesDB.auraTestMode == true)
end

local activeDragOwner = nil

local function DebugEditModeDrag(message, frame)
    local db = MattMinimalFramesDB or {}
    if db.debugEditModeDrag ~= true and db.mmfDebugEditModeDrag ~= true then
        return
    end

    local name = frame and frame.GetName and frame:GetName()
    if not name or name == "" then
        name = frame and frame.mmfDragOwnerName
    end
    if not name or name == "" then
        name = "unnamed frame"
    end
    print("|cff00ff00Matt's Minimal Frames|r Edit Drag: " .. message .. " (" .. name .. ")")
end

local function TryClaimDragOwner(frame, ownerName)
    if not frame then
        return false
    end
    if activeDragOwner and activeDragOwner ~= frame then
        DebugEditModeDrag("blocked while another owner is active", frame)
        return false
    end

    activeDragOwner = frame
    frame.mmfDragOwnerName = ownerName or frame.mmfDragOwnerName
    frame.mmfExclusiveDragActive = true
    DebugEditModeDrag("start", frame)
    return true
end

local function ReleaseDragOwner(frame)
    if activeDragOwner == frame then
        DebugEditModeDrag("stop", frame)
        activeDragOwner = nil
    end
    if frame then
        frame.mmfExclusiveDragActive = nil
    end
end

local function CanStartFrameDrag(frame)
    if InCombatLockdown() then
        return false
    end
    if activeDragOwner and activeDragOwner ~= frame then
        return false
    end
    if IsEditModeDragEnabled() then
        return frame and frame:IsMovable()
    end
    if IsTestModeShiftDragEnabled() then
        return IsShiftKeyDown() and frame and frame:IsMovable()
    end
    local isLocked = MattMinimalFramesDB and MattMinimalFramesDB.locked
    return (not isLocked) and IsShiftKeyDown() and frame and frame:IsMovable()
end

local function GetDragHintText()
    if IsEditModeDragEnabled() then
        return "Drag to move"
    end
    return "Shift+Drag to move"
end

local function TryStopFrameMoving(frame)
    if not frame or not frame.IsMovable or not frame:IsMovable() then
        return false
    end
    if activeDragOwner and activeDragOwner ~= frame then
        return false
    end
    if activeDragOwner ~= frame and frame.mmfExclusiveDragActive ~= true then
        return false
    end
    if InCombatLockdown and InCombatLockdown() then
        print("|cff00ff00Matt's Minimal Frames|r: Frame movement blocked during combat.")
        ReleaseDragOwner(frame)
        return false
    end
    frame:StopMovingOrSizing()
    ReleaseDragOwner(frame)
    return true
end

local function TryBeginFrameMoving(frame, ownerName)
    if not CanStartFrameDrag(frame) then
        return false
    end
    if not TryClaimDragOwner(frame, ownerName) then
        return false
    end
    frame:StartMoving()
    return true
end

_G.MMF_FrameFactoryDragHelpers = {
    CreateTooltipHandlers = CreateTooltipHandlers,
    IsEditModeDragEnabled = IsEditModeDragEnabled,
    IsTestModeShiftDragEnabled = IsTestModeShiftDragEnabled,
    CanStartFrameDrag = CanStartFrameDrag,
    GetDragHintText = GetDragHintText,
    TryClaimDragOwner = TryClaimDragOwner,
    ReleaseDragOwner = ReleaseDragOwner,
    TryBeginFrameMoving = TryBeginFrameMoving,
    TryStopFrameMoving = TryStopFrameMoving,
}
