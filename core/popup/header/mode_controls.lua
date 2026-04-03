function MMF_CreatePopupHeaderModeController(config)
    config = config or {}

    local refs = config.refs or {}
    local titleBar = config.titleBar
    local ACCENT_COLOR = config.accentColor or { 0.6, 0.4, 0.9 }
    local EnsureTitleControlFont = config.ensureTitleControlFont or function() end
    local RefreshPopupWidgetTree = config.refreshPopupWidgetTree or MMF_RefreshPopupWidgetTree

    local titleStateGeneration = 0
    local testModeTextPulseFrame = nil

    local function SetTitleCheckboxVisual(checkbox, checked)
        if not checkbox then return end
        checkbox:SetChecked(checked == true)
        if checkbox.check then
            checkbox.check:SetShown(checked == true)
        end
    end

    local function HSVToRGB(h, s, v)
        h = (tonumber(h) or 0) % 1
        s = math.max(0, math.min(1, tonumber(s) or 1))
        v = math.max(0, math.min(1, tonumber(v) or 1))
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)
        i = i % 6
        if i == 0 then return v, t, p end
        if i == 1 then return q, v, p end
        if i == 2 then return p, v, t end
        if i == 3 then return p, q, v end
        if i == 4 then return t, p, v end
        return v, p, q
    end

    local function EnsureTestModeRainbowText()
        if testModeTextPulseFrame or not refs.testModeContainer then
            return
        end
        local pulse = CreateFrame("Frame", nil, titleBar)
        pulse:SetAllPoints(titleBar)
        pulse:Hide()
        testModeTextPulseFrame = pulse

        pulse:SetScript("OnUpdate", function(self, elapsed)
            local speed = 0.22
            self._mmfHue = ((self._mmfHue or 0) + (elapsed or 0) * speed) % 1
            local r, g, b = HSVToRGB(self._mmfHue, 1, 1)
            if refs.testModeContainer and refs.testModeContainer.labelText then
                refs.testModeContainer.labelText:SetTextColor(r, g, b)
            end
        end)
    end

    local function SetTestModeCheckboxState(checked)
        SetTitleCheckboxVisual(refs.testModeCheckbox, checked)
        EnsureTestModeRainbowText()
        if refs.testModeContainer and refs.testModeContainer.labelText then
            EnsureTitleControlFont(refs.testModeContainer.labelText, 10)
            refs.testModeContainer.labelText:SetShown(true)
        end
        if testModeTextPulseFrame then
            if checked then
                testModeTextPulseFrame:Show()
            else
                testModeTextPulseFrame:Hide()
            end
        end
        if refs.testModeContainer and refs.testModeContainer.labelText and not checked then
            refs.testModeContainer.labelText:SetTextColor(0.9, 0.9, 0.9)
        end
    end

    local function IsGlobalTestModeEnabled()
        return MattMinimalFramesDB and (MattMinimalFramesDB.layoutTestMode == true or MattMinimalFramesDB.auraTestMode == true)
    end

    local function SetEditModeButtonState(checked)
        if not refs.editModeButton then
            return
        end
        if refs.editModeButton.labelText then
            EnsureTitleControlFont(refs.editModeButton.labelText, 10)
            refs.editModeButton.labelText:SetShown(true)
        end
        refs.editModeButton.mmfActive = checked == true
        if checked then
            refs.editModeButton:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)
            if refs.editModeButton.labelText then
                refs.editModeButton.labelText:SetTextColor(1, 0.93, 0.45)
            end
        else
            refs.editModeButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            if refs.editModeButton.labelText then
                refs.editModeButton.labelText:SetTextColor(0.9, 0.9, 0.9)
            end
        end
    end

    local function SyncTitleLockCheckboxState()
        local editModeEnabled = MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
        local effectiveLocked = MattMinimalFramesDB and MattMinimalFramesDB.locked == true

        local function ApplyLockButtonState(isLocked, disabled)
            if not refs.lockFramesButton then
                return
            end
            if refs.lockFramesButton.labelText then
                EnsureTitleControlFont(refs.lockFramesButton.labelText, 10)
                refs.lockFramesButton.labelText:SetShown(true)
            end
            refs.lockFramesButton.mmfActive = isLocked == true
            refs.lockFramesButton.mmfActiveTextColor = { 0.45, 1.0, 0.45 }
            refs.lockFramesButton.mmfInactiveTextColor = { 1.0, 0.35, 0.35 }
            refs.lockFramesButton.mmfActiveBorderColor = { 0.25, 0.55, 0.25, 1 }
            refs.lockFramesButton.mmfInactiveBorderColor = { 0.55, 0.25, 0.25, 1 }
            if isLocked then
                if refs.lockFramesButton.labelText then
                    refs.lockFramesButton.labelText:SetText("Frames Locked")
                    refs.lockFramesButton.labelText:SetTextColor(0.45, 1.0, 0.45)
                end
                refs.lockFramesButton:SetBackdropBorderColor(0.25, 0.55, 0.25, 1)
            else
                if refs.lockFramesButton.labelText then
                    refs.lockFramesButton.labelText:SetText("Frames Unlocked")
                    refs.lockFramesButton.labelText:SetTextColor(1.0, 0.35, 0.35)
                end
                refs.lockFramesButton:SetBackdropBorderColor(0.55, 0.25, 0.25, 1)
            end
            if disabled then
                if refs.lockFramesButton.Disable then
                    refs.lockFramesButton:Disable()
                end
            else
                if refs.lockFramesButton.Enable then
                    refs.lockFramesButton:Enable()
                end
            end
        end

        if editModeEnabled then
            if refs.lockFramesContainer then
                refs.lockFramesContainer:SetAlpha(0.45)
            end
            ApplyLockButtonState(false, true)
            return
        end

        if refs.lockFramesContainer then
            refs.lockFramesContainer:SetAlpha(1)
        end
        ApplyLockButtonState(effectiveLocked, false)
    end

    local function RefreshTitleBarControls()
        if RefreshPopupWidgetTree then
            RefreshPopupWidgetTree(titleBar)
        end
        if refs.lockFramesButton and refs.lockFramesButton.labelText then
            EnsureTitleControlFont(refs.lockFramesButton.labelText, 10)
            refs.lockFramesButton.labelText:SetShown(true)
        end
        if refs.editModeButton and refs.editModeButton.labelText and refs.editModeButton.labelText.SetText then
            EnsureTitleControlFont(refs.editModeButton.labelText, 10)
            refs.editModeButton.labelText:SetText("Edit Mode")
            refs.editModeButton.labelText:SetShown(true)
        end
        if refs.testModeContainer and refs.testModeContainer.labelText and refs.testModeContainer.labelText.SetText then
            EnsureTitleControlFont(refs.testModeContainer.labelText, 10)
            refs.testModeContainer.labelText:SetText("Test Mode")
            refs.testModeContainer.labelText:SetShown(true)
        end

        SetEditModeButtonState(MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true)
        SetTestModeCheckboxState(IsGlobalTestModeEnabled())
        SyncTitleLockCheckboxState()
    end

    local function ApplyInitialTitleBarState()
        titleStateGeneration = titleStateGeneration + 1
        local currentGeneration = titleStateGeneration
        local function RefreshIfCurrent()
            if currentGeneration ~= titleStateGeneration then
                return
            end
            RefreshTitleBarControls()
        end
        RefreshIfCurrent()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                RefreshIfCurrent()
            end)
            C_Timer.After(0.05, function()
                RefreshIfCurrent()
            end)
            C_Timer.After(0.2, function()
                RefreshIfCurrent()
            end)
        end
    end

    local function SetGlobalTestMode(enabled)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        local active = enabled == true
        MattMinimalFramesDB.layoutTestMode = active
        MattMinimalFramesDB.auraTestMode = active
        if MMF_RefreshFrameLockState then
            MMF_RefreshFrameLockState()
        end
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
        if MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end
        if MMF_UpdatePlayerAuras then
            MMF_UpdatePlayerAuras()
        end
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        elseif MMF_GetAllFrames and MMF_UpdateUnitFrame then
            for _, frame in ipairs(MMF_GetAllFrames()) do
                if frame then
                    MMF_UpdateUnitFrame(frame)
                end
            end
        end
    end

    return {
        IsGlobalTestModeEnabled = IsGlobalTestModeEnabled,
        SetGlobalTestMode = SetGlobalTestMode,
        SetEditModeButtonState = SetEditModeButtonState,
        SetTestModeCheckboxState = SetTestModeCheckboxState,
        SyncTitleLockCheckboxState = SyncTitleLockCheckboxState,
        ApplyInitialTitleBarState = ApplyInitialTitleBarState,
    }
end
