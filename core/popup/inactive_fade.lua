local function IsPopupInactiveFadeEnabledFromDB()
    if type(MattMinimalFramesDB) ~= "table" then
        return true
    end
    return MattMinimalFramesDB.popupInactiveFade ~= false
end

function MMF_EnsurePopupInactiveFadeDB()
    if type(MattMinimalFramesDB) ~= "table" then
        return
    end
    if MattMinimalFramesDB.popupInactiveFade == nil then
        MattMinimalFramesDB.popupInactiveFade = true
    end
    if MattMinimalFramesDB.popupInactiveFadeAlpha == nil then
        MattMinimalFramesDB.popupInactiveFadeAlpha = (MMF_GetPopupInactiveFadeAlpha and MMF_GetPopupInactiveFadeAlpha()) or 0.60
    end
end

function MMF_SetPopupInactiveFadeEnabled(enabled)
    if type(MattMinimalFramesDB) ~= "table" then
        MattMinimalFramesDB = {}
    end
    local isEnabled = (enabled == true)
    MattMinimalFramesDB.popupInactiveFade = isEnabled
    if MMF_WelcomePopup and MMF_WelcomePopup.MMFApplyInactiveFade then
        if isEnabled and MMF_WelcomePopup.MMFResetInactiveFadePriming then
            MMF_WelcomePopup:MMFResetInactiveFadePriming()
        end
        MMF_WelcomePopup:MMFApplyInactiveFade(isEnabled, true)
    end
end

function MMF_SetPopupInactiveFadeAlpha(alpha)
    if type(MattMinimalFramesDB) ~= "table" then
        MattMinimalFramesDB = {}
    end
    if MMF_ClampPopupInactiveFadeAlpha then
        MattMinimalFramesDB.popupInactiveFadeAlpha = MMF_ClampPopupInactiveFadeAlpha(alpha)
    else
        MattMinimalFramesDB.popupInactiveFadeAlpha = tonumber(alpha) or 0.60
    end

    if MMF_WelcomePopup and MMF_WelcomePopup.MMFRefreshInactiveFade then
        MMF_WelcomePopup:MMFRefreshInactiveFade(true)
    elseif MMF_WelcomePopup and MMF_WelcomePopup.MMFApplyInactiveFade then
        MMF_WelcomePopup:MMFApplyInactiveFade(IsPopupInactiveFadeEnabledFromDB(), true)
    end
end

function MMF_CreatePopupInactiveFadeController(popup, config)
    if not popup then
        return nil
    end

    config = config or {}
    local fadeConfig = (MMF_GetPopupInactiveFadeConfig and MMF_GetPopupInactiveFadeConfig()) or {}
    local focusAlpha = tonumber(config.focusAlpha) or tonumber(fadeConfig.focusAlpha) or 1.0
    local fadeTime = tonumber(config.fadeTime) or tonumber(fadeConfig.fadeTime) or 0.30
    local hoverPollInterval = tonumber(config.hoverPollInterval) or tonumber(fadeConfig.hoverPollInterval) or 0.03
    local cursorPad = tonumber(config.cursorPad) or tonumber(fadeConfig.cursorPad) or 4

    local popupFadeDriver = CreateFrame("Frame", nil, popup)
    popupFadeDriver:Show()
    local popupHoverDriver = CreateFrame("Frame", nil, popup)
    popupHoverDriver:Show()

    local popupVisualAlpha = focusAlpha
    local popupLastHover = false
    local popupHoverElapsed = 0
    local popupFadePrimed = false
    local popupFadeSawMouseInside = false
    local popupInactiveFadeEnabled = IsPopupInactiveFadeEnabledFromDB()

    local function EasePopupFadeProgress(t)
        if t <= 0 then
            return 0
        end
        if t >= 1 then
            return 1
        end
        return t * t * (3 - (2 * t))
    end

    local function SetPopupVisualAlpha(alpha)
        local clamped = tonumber(alpha) or focusAlpha
        if clamped < 0 then
            clamped = 0
        elseif clamped > 1 then
            clamped = 1
        end
        popupVisualAlpha = clamped
        popup:SetAlpha(clamped)
    end

    local function IsCursorInsidePopup()
        if MMF_IsCursorInsideFrame then
            return MMF_IsCursorInsideFrame(popup, cursorPad)
        end
        return false
    end

    local function ResetPopupFadePriming()
        local hovering = IsCursorInsidePopup()
        popupFadePrimed = false
        popupFadeSawMouseInside = hovering
        popupLastHover = hovering
    end

    local function GetPopupTargetAlpha()
        if not popupInactiveFadeEnabled then
            return focusAlpha
        end
        if not popupFadePrimed then
            return focusAlpha
        end
        if IsCursorInsidePopup() then
            return focusAlpha
        end
        if MMF_GetPopupInactiveFadeAlpha then
            return MMF_GetPopupInactiveFadeAlpha()
        end
        return 0.60
    end

    local function RefreshPopupAlpha(animate)
        local target = GetPopupTargetAlpha()
        if not animate then
            popupFadeDriver:SetScript("OnUpdate", nil)
            SetPopupVisualAlpha(target)
            return
        end
        local startAlpha = popupVisualAlpha
        if math.abs(startAlpha - target) < 0.001 then
            SetPopupVisualAlpha(target)
            return
        end
        local elapsed = 0
        popupFadeDriver:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + (dt or 0)
            local t = elapsed / fadeTime
            if t >= 1 then
                popupFadeDriver:SetScript("OnUpdate", nil)
                SetPopupVisualAlpha(target)
                return
            end
            local easedT = EasePopupFadeProgress(t)
            SetPopupVisualAlpha(startAlpha + (target - startAlpha) * easedT)
        end)
    end

    local function StopPopupHoverWatcher()
        popupHoverDriver:SetScript("OnUpdate", nil)
        popupFadeDriver:SetScript("OnUpdate", nil)
    end

    local function StartPopupHoverWatcher()
        popupLastHover = IsCursorInsidePopup()
        popupHoverElapsed = 0
        popupHoverDriver:SetScript("OnUpdate", function(_, dt)
            popupHoverElapsed = popupHoverElapsed + (dt or 0)
            if popupHoverElapsed < hoverPollInterval then
                return
            end
            popupHoverElapsed = 0
            local nowHover = IsCursorInsidePopup()
            if not popupFadePrimed then
                if nowHover then
                    popupFadeSawMouseInside = true
                end
                if popupFadeSawMouseInside and not nowHover then
                    popupFadePrimed = true
                    popupLastHover = nowHover
                    RefreshPopupAlpha(true)
                    return
                end
                popupLastHover = nowHover
                if math.abs((popupVisualAlpha or 1) - focusAlpha) > 0.001 then
                    SetPopupVisualAlpha(focusAlpha)
                end
                return
            end
            if nowHover ~= popupLastHover then
                popupLastHover = nowHover
                RefreshPopupAlpha(true)
            end
        end)
    end

    popup.MMFApplyInactiveFade = function(self, enabled, animate)
        popupInactiveFadeEnabled = (enabled == true)
        if not self:IsShown() then
            popupFadePrimed = false
            popupFadeSawMouseInside = false
            SetPopupVisualAlpha(focusAlpha)
            StopPopupHoverWatcher()
            return
        end
        if popupInactiveFadeEnabled then
            StartPopupHoverWatcher()
        else
            popupFadePrimed = false
            popupFadeSawMouseInside = false
            StopPopupHoverWatcher()
        end
        if popupInactiveFadeEnabled and popupFadePrimed then
            RefreshPopupAlpha(animate ~= false)
        else
            SetPopupVisualAlpha(focusAlpha)
        end
    end

    popup.MMFResetInactiveFadePriming = function(self)
        if not self or not self:IsShown() then
            popupFadePrimed = false
            popupFadeSawMouseInside = false
            popupLastHover = false
            SetPopupVisualAlpha(focusAlpha)
            return
        end
        ResetPopupFadePriming()
        SetPopupVisualAlpha(focusAlpha)
    end

    popup.MMFRefreshInactiveFade = function(_, animate)
        if popupInactiveFadeEnabled and popupFadePrimed then
            RefreshPopupAlpha(animate ~= false)
        else
            SetPopupVisualAlpha(focusAlpha)
        end
    end

    popup:HookScript("OnShow", function(self)
        local fadeEnabled = IsPopupInactiveFadeEnabledFromDB()
        if self.MMFResetInactiveFadePriming then
            self:MMFResetInactiveFadePriming()
        end
        if self.MMFApplyInactiveFade then
            self:MMFApplyInactiveFade(fadeEnabled, false)
        end
    end)

    popup:HookScript("OnHide", function()
        popupFadePrimed = false
        popupFadeSawMouseInside = false
        popupLastHover = false
        StopPopupHoverWatcher()
        SetPopupVisualAlpha(focusAlpha)
    end)

    return {
        Apply = popup.MMFApplyInactiveFade,
        Refresh = popup.MMFRefreshInactiveFade,
    }
end
