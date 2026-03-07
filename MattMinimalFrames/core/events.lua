local LibCustomGlow = LibStub("LibCustomGlow-1.0")

local function IsEditModeActive()
    return MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
end

local function GetEffectiveLockedState()
    if IsEditModeActive() then
        return false
    end
    return MattMinimalFramesDB and MattMinimalFramesDB.locked == true
end

local function ApplyEditModeAlignmentGrid(isEnabled)
    if not MMF_ToggleAlignmentGrid then
        return
    end

    if isEnabled then
        if MattMinimalFramesDB.mmfGridBeforeEditMode == nil then
            MattMinimalFramesDB.mmfGridBeforeEditMode = MattMinimalFramesDB.showAlignmentGrid == true
        end
        MattMinimalFramesDB.showAlignmentGrid = true
        MMF_ToggleAlignmentGrid(true)
        return
    end

    local restoreGrid = MattMinimalFramesDB.mmfGridBeforeEditMode == true
    MattMinimalFramesDB.showAlignmentGrid = restoreGrid
    MMF_ToggleAlignmentGrid(restoreGrid)
    MattMinimalFramesDB.mmfGridBeforeEditMode = nil
end

local function GetPetActionBarFrame()
    return _G.PetActionBarFrame or _G.PetActionBar
end

local function SavePetActionBarPosition(frame)
    if not frame then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    local left = frame:GetLeft()
    local top = frame:GetTop()
    if left and top then
        MattMinimalFramesDB.petActionBarPosition = { left = left, top = top }
    end
end

local function ApplyPetActionBarSavedPosition()
    local frame = GetPetActionBarFrame()
    if not frame or not MattMinimalFramesDB then
        return
    end
    local pos = MattMinimalFramesDB.petActionBarPosition
    if type(pos) ~= "table" or pos.left == nil or pos.top == nil then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
end

local function EnsurePetActionBarEditBackdrop(frame)
    if not frame or frame.mmfEditDragBackdrop then
        return
    end

    local backdrop = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    backdrop:SetFrameStrata("DIALOG")
    backdrop:SetFrameLevel(frame:GetFrameLevel() + 20)
    backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    backdrop:SetBackdropColor(0.02, 0.02, 0.03, 0.35)
    backdrop:SetBackdropBorderColor(0.2, 0.2, 0.24, 0.9)
    backdrop:EnableMouse(true)
    backdrop:RegisterForDrag("LeftButton")

    local title = backdrop:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    title:SetPoint("BOTTOM", backdrop, "TOP", 0, 2)
    title:SetTextColor(1, 1, 1)
    title:SetText("Pet Ability Bar")

    backdrop:SetScript("OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        if not MattMinimalFramesDB or MattMinimalFramesDB.unlockFramesEditMode ~= true then
            return
        end
        frame:StartMoving()
        self.mmfDragInProgress = true
    end)

    backdrop:SetScript("OnDragStop", function(self)
        frame:StopMovingOrSizing()
        SavePetActionBarPosition(frame)
        self.mmfDragInProgress = nil
    end)

    frame.mmfEditDragBackdrop = backdrop
    frame.mmfEditDragBackdropTitle = title
    backdrop:Hide()
end

local function EnsurePetActionBarMover()
    local frame = GetPetActionBarFrame()
    if not frame or frame.mmfMoverHooked then
        return
    end

    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:HookScript("OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        if not MattMinimalFramesDB or MattMinimalFramesDB.unlockFramesEditMode ~= true then
            return
        end
        self:StartMoving()
    end)

    frame:HookScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePetActionBarPosition(self)
    end)

    EnsurePetActionBarEditBackdrop(frame)
    frame.mmfMoverHooked = true
end

function MMF_UpdatePetActionBarEditMode()
    local frame = GetPetActionBarFrame()
    if not frame then
        return
    end
    EnsurePetActionBarMover()
    ApplyPetActionBarSavedPosition()
    frame:SetMovable(true)
    local backdrop = frame.mmfEditDragBackdrop
    local editMode = MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
    if editMode then
        if not (InCombatLockdown and InCombatLockdown()) then
            pcall(frame.Show, frame)
        end
        if backdrop then
            backdrop:ClearAllPoints()
            backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -12, 10)
            backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 12, -10)
            if not (InCombatLockdown and InCombatLockdown()) then
                backdrop:Show()
            else
                backdrop:Hide()
            end
        end
    elseif backdrop then
        backdrop:Hide()
    end
end

function MMF_ApplyPetActionBarPosition()
    EnsurePetActionBarMover()
    ApplyPetActionBarSavedPosition()
end

--------------------------------------------------
-- FRAME LOCKING
--------------------------------------------------

local function SetUnitWatchState(frame, enabled)
    if not frame then
        return
    end
    if enabled then
        if type(RegisterUnitWatch) == "function" then
            pcall(RegisterUnitWatch, frame)
        end
        frame.mmfUnitWatchSuspended = nil
    else
        if type(UnregisterUnitWatch) == "function" then
            local ok = pcall(UnregisterUnitWatch, frame)
            if ok then
                frame.mmfUnitWatchSuspended = true
            end
        end
    end
end

local function ApplyFrameLockState(locked)
    local revealHiddenFrames = MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
    for _, frm in ipairs(MMF_GetAllFrames()) do
        if frm then
            frm:SetMovable(true)
            frm:SetClampedToScreen(locked)
            frm:EnableMouse(true)
            frm:RegisterForDrag("LeftButton")
            frm:RegisterForClicks("AnyUp")
            if frm.titleText then
                frm.titleText:SetShown(not locked)
            end
            MMF_ResetSecureAttributes(frm)
            if LibCustomGlow then
                LibCustomGlow.PixelGlow_Stop(frm)
            end
            if revealHiddenFrames then
                SetUnitWatchState(frm, false)
                frm:Show()
            else
                SetUnitWatchState(frm, true)
            end
        end
    end

    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
    elseif MMF_UpdateUnitFrame then
        for _, frm in ipairs(MMF_GetAllFrames()) do
            if frm then
                MMF_UpdateUnitFrame(frm)
            end
        end
    end
end

function MMF_RefreshFrameLockState()
    if IsEditModeActive() and MattMinimalFramesDB then
        MattMinimalFramesDB.locked = false
    end
    local locked = GetEffectiveLockedState()
    if InCombatLockdown and InCombatLockdown() then
        if MMF_RunAfterCombat then
            MMF_RunAfterCombat("frame_lock_state_refresh", function()
                MMF_RefreshFrameLockState()
            end)
        end
        return
    end
    ApplyFrameLockState(locked)
end

function MMF_SetEditMode(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local isEnabled = enabled == true
    local wasEnabled = MattMinimalFramesDB.unlockFramesEditMode == true

    if isEnabled and not wasEnabled then
        MattMinimalFramesDB.mmfLockedBeforeEditMode = MattMinimalFramesDB.locked == true
        MattMinimalFramesDB.locked = false
    elseif (not isEnabled) and wasEnabled then
        if MattMinimalFramesDB.mmfLockedBeforeEditMode ~= nil then
            MattMinimalFramesDB.locked = MattMinimalFramesDB.mmfLockedBeforeEditMode == true
        end
        MattMinimalFramesDB.mmfLockedBeforeEditMode = nil
    end

    MattMinimalFramesDB.unlockFramesEditMode = isEnabled
    ApplyEditModeAlignmentGrid(isEnabled)
    MMF_UpdatePetActionBarEditMode()
    MMF_RefreshFrameLockState()
end

function MMF_LockFrames()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end

    if IsEditModeActive() then
        MattMinimalFramesDB.mmfLockedBeforeEditMode = true
        MattMinimalFramesDB.locked = false
        if MMF_RefreshFrameLockState then
            MMF_RefreshFrameLockState()
        end
        return
    end

    MattMinimalFramesDB.locked = true

    local queuedMessage = "|cff00ff00Matt's Minimal Frames|r: Locking frames after combat."
    if MMF_RunAfterCombat then
        MMF_RunAfterCombat("frame_lock_state", function()
            ApplyFrameLockState(true)
        end, queuedMessage)
        return
    end

    if InCombatLockdown() then
        print(queuedMessage)
        return
    end

    ApplyFrameLockState(true)
end

function MMF_UnlockFrames()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end

    if IsEditModeActive() then
        MattMinimalFramesDB.mmfLockedBeforeEditMode = false
        MattMinimalFramesDB.locked = false
        if MMF_RefreshFrameLockState then
            MMF_RefreshFrameLockState()
        end
        return
    end

    MattMinimalFramesDB.locked = false

    local queuedMessage = "|cff00ff00Matt's Minimal Frames|r: Unlocking frames after combat."
    if MMF_RunAfterCombat then
        MMF_RunAfterCombat("frame_lock_state", function()
            ApplyFrameLockState(false)
        end, queuedMessage)
        return
    end

    if InCombatLockdown() then
        print(queuedMessage)
        return
    end

    ApplyFrameLockState(false)
end

--------------------------------------------------
-- CORE EVENT HANDLER
--------------------------------------------------

local function RequestUnitUpdate(unit)
    if MMF_RequestUnitUpdate then
        MMF_RequestUnitUpdate(unit)
        return
    end
    if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
        local frame = MMF_GetFrameForUnit(unit)
        if frame then
            MMF_UpdateUnitFrame(frame)
        end
    end
end

local function RequestFrameUpdate(frame)
    if not frame then return end
    if MMF_RequestFrameUpdate then
        MMF_RequestFrameUpdate(frame)
        return
    end
    if MMF_UpdateUnitFrame then
        MMF_UpdateUnitFrame(frame)
    end
end

local function RequestAllUpdates()
    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
        return
    end
    if MMF_GetAllFrames and MMF_UpdateUnitFrame then
        for _, frame in ipairs(MMF_GetAllFrames()) do
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end
end

local function RefreshPVPIndicators()
    if MMF_UpdatePVPFlagIndicator then
        if MMF_PlayerFrame then
            MMF_UpdatePVPFlagIndicator(MMF_PlayerFrame)
        end
        if MMF_TargetFrame then
            MMF_UpdatePVPFlagIndicator(MMF_TargetFrame)
        end
    end
end

local coreEventFrame = CreateFrame("Frame")
local function SafeRegisterEvent(frame, eventName)
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end
coreEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
coreEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
coreEventFrame:RegisterEvent("UNIT_HEALTH")
coreEventFrame:RegisterEvent("UNIT_POWER_UPDATE")
coreEventFrame:RegisterEvent("PLAYER_ALIVE")
coreEventFrame:RegisterEvent("PLAYER_DEAD")
coreEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coreEventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
coreEventFrame:RegisterEvent("UNIT_NAME_UPDATE")
coreEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
coreEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
coreEventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
coreEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
coreEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
coreEventFrame:RegisterEvent("UNIT_PET")
coreEventFrame:RegisterEvent("UNIT_TARGET")
coreEventFrame:RegisterEvent("UNIT_HEAL_PREDICTION")
coreEventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
coreEventFrame:RegisterEvent("UNIT_FACTION")
coreEventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
SafeRegisterEvent(coreEventFrame, "PLAYER_PVP_UPDATE")

coreEventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        if MMF_FlushCombatQueue then
            MMF_FlushCombatQueue()
        end
        if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
            MMF_PlayerFrame.combatTexture:Hide()
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
            MMF_PlayerFrame.combatTexture:Show()
        end

    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_UPDATE_RESTING" then
        if MMF_PlayerFrame and MMF_PlayerFrame.restingTexture then
            MMF_PlayerFrame.restingTexture:SetShown(IsResting())
        end
        if event == "PLAYER_ENTERING_WORLD" then
            RequestAllUpdates()
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        if MMF_UpdateUnitFrame then
            if MMF_TargetFrame then
                MMF_UpdateUnitFrame(MMF_TargetFrame)
            else
                RequestFrameUpdate(MMF_TargetFrame)
            end
            if MMF_TargetOfTargetFrame then
                MMF_UpdateUnitFrame(MMF_TargetOfTargetFrame)
            else
                RequestFrameUpdate(MMF_TargetOfTargetFrame)
            end
        else
            RequestFrameUpdate(MMF_TargetFrame)
            RequestFrameUpdate(MMF_TargetOfTargetFrame)
        end

    elseif event == "PLAYER_FOCUS_CHANGED" then
        RequestFrameUpdate(MMF_FocusFrame)

    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        RequestUnitUpdate("player")

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if unit == nil or unit == "player" then
            RequestUnitUpdate("player")
        end

    elseif event == "UNIT_PET" then
        RequestFrameUpdate(MMF_PetFrame)

    elseif event == "UNIT_TARGET" then
        if unit == "target" then
            RequestFrameUpdate(MMF_TargetOfTargetFrame)
        end

    elseif event == "PLAYER_FLAGS_CHANGED" then
        if unit == nil or unit == "player" or unit == "target" then
            RequestUnitUpdate("player")
            RequestUnitUpdate("target")
            RefreshPVPIndicators()
        end

    elseif event == "PLAYER_PVP_UPDATE" then
        RequestUnitUpdate("player")
        RequestUnitUpdate("target")
        RefreshPVPIndicators()

    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_DISPLAYPOWER" or event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        RequestUnitUpdate(unit)

    elseif event == "UNIT_FACTION" then
        if unit == nil or unit == "player" or unit == "target" then
            RequestUnitUpdate("player")
            RequestUnitUpdate("target")
            RefreshPVPIndicators()
        end

    elseif event == "PLAYER_ALIVE" or event == "PLAYER_DEAD" then
        RequestUnitUpdate("player")
    end

    if MMF_FlushRequestedUpdates then
        if (event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_DISPLAYPOWER")
            and (unit == nil or unit == "player") then
            MMF_FlushRequestedUpdates()
        end
    end

    if MMF_UpdateCombatFrameVisibility then
        MMF_UpdateCombatFrameVisibility()
    end
end)

local pvpRefreshElapsed = 0
coreEventFrame:SetScript("OnUpdate", function(_, elapsed)
    pvpRefreshElapsed = pvpRefreshElapsed + (elapsed or 0)
    if pvpRefreshElapsed < 1.0 then
        return
    end
    pvpRefreshElapsed = 0
    RefreshPVPIndicators()
end)
