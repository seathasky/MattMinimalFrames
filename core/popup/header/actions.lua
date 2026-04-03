function MMF_CreatePopupHeaderActions(config)
    config = config or {}

    local popup = config.popup
    local accentColor = config.accentColor or { 0.6, 0.4, 0.9 }
    local modeController = config.modeController or {}

    local editModePopup = nil

    local function EnsureEditModePopup()
        editModePopup = MMF_EnsurePopupEditModePopup({
            existingPopup = editModePopup,
            popup = popup,
            accentColor = accentColor,
            onExitEditMode = function()
                if modeController.SetEditModeButtonState then
                    modeController.SetEditModeButtonState(false)
                end
                if modeController.SyncTitleLockCheckboxState then
                    modeController.SyncTitleLockCheckboxState()
                end
            end,
        })
        return editModePopup
    end

    local function OnEditModeClick()
        local currentlyEnabled = MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
        if not currentlyEnabled then
            if MMF_SetEditMode then
                MMF_SetEditMode(true)
            else
                MattMinimalFramesDB.unlockFramesEditMode = true
                if MMF_RefreshFrameLockState then
                    MMF_RefreshFrameLockState()
                end
            end
        end
        if modeController.SetEditModeButtonState then
            modeController.SetEditModeButtonState(true)
        end
        if modeController.SyncTitleLockCheckboxState then
            modeController.SyncTitleLockCheckboxState()
        end
        local modePopup = EnsureEditModePopup()
        popup:Hide()
        modePopup:Show()
    end

    local function OnTestModeToggle(checked)
        if modeController.SetGlobalTestMode then
            modeController.SetGlobalTestMode(checked)
        end
        if modeController.SetTestModeCheckboxState then
            modeController.SetTestModeCheckboxState(checked)
        end
    end

    local function OnLockFramesClick()
        if MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true then
            return
        end
        local currentlyLocked = MattMinimalFramesDB and MattMinimalFramesDB.locked == true
        local newLocked = not currentlyLocked
        MattMinimalFramesDB.locked = newLocked
        if newLocked then
            if MMF_LockFrames then
                MMF_LockFrames()
            end
        else
            if MMF_UnlockFrames then
                MMF_UnlockFrames()
            end
        end
        if modeController.SyncTitleLockCheckboxState then
            modeController.SyncTitleLockCheckboxState()
        end
    end

    return {
        OnEditModeClick = OnEditModeClick,
        OnTestModeToggle = OnTestModeToggle,
        OnLockFramesClick = OnLockFramesClick,
    }
end
