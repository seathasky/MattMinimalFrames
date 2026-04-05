local cfg = MMF_Config or {}

local function ResetFrameToDefaultPosition(frame, frameName)
    if not frame or not frameName then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local bossIndex = tostring(frameName):match("^MMF_Boss([1-5])Frame$")
    if bossIndex then
        MMF_ResetFrameCenterPositionForUnit("boss")
        return
    end

    MMF_ResetFrameCenterPositionForUnit(frame.unit)
end

local function EnsureFrameResetPopup()
    if _G.MMF_FrameResetPopup then
        return _G.MMF_FrameResetPopup
    end

    local popup = CreateFrame("Frame", "MMF_FrameResetPopup", UIParent, "BackdropTemplate")
    popup:SetSize(230, 112)
    popup:SetFrameStrata("DIALOG")
    popup:SetToplevel(true)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.04, 0.04, 0.05, 0.72)
    popup:SetBackdropBorderColor(0.1, 0.1, 0.12, 0.9)
    popup:Hide()

    local title = popup:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(title, cfg.FONT_PATH, 10, "")
    else
        title:SetFont(cfg.FONT_PATH, 10, "")
    end
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetTextColor(1, 1, 1)
    title:SetText("Frame Options")
    popup.title = title

    local close = CreateFrame("Button", nil, popup)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -6, -6)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(closeText, cfg.FONT_PATH, 10, "")
    else
        closeText:SetFont(cfg.FONT_PATH, 10, "")
    end
    closeText:SetPoint("CENTER")
    closeText:SetTextColor(0.8, 0.8, 0.8)
    closeText:SetText("x")
    close:SetScript("OnClick", function() popup:Hide() end)

    local function CreatePopupButton(yOffset, label)
        local btn = CreateFrame("Button", nil, popup, "BackdropTemplate")
        btn:SetSize(206, 24)
        btn:SetPoint("TOP", popup, "TOP", 0, yOffset)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
        btn:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        local txt = btn:CreateFontString(nil, "OVERLAY")
        if MMF_SetFontSafe then
            MMF_SetFontSafe(txt, cfg.FONT_PATH, 10, "")
        else
            txt:SetFont(cfg.FONT_PATH, 10, "")
        end
        txt:SetPoint("CENTER")
        txt:SetTextColor(0.9, 0.9, 0.9)
        txt:SetText(label)
        return btn
    end

    popup.resetPositionBtn = CreatePopupButton(-28, "Reset Frame Position")
    popup.resetCastBarBtn = CreatePopupButton(-58, "Reset Cast Bar")
    _G.MMF_FrameResetPopup = popup
    return popup
end

local function ShowFrameResetPopup(frame, frameName)
    if not frame or not frameName then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local popup = EnsureFrameResetPopup()
    popup.currentFrame = frame
    popup.currentFrameName = frameName
    popup.title:SetText((frame.frameLabel or frame.unit or "Frame") .. " Options")

    local function ResetUnitCastBarToDefaults(unitToReset)
        if unitToReset ~= "player" and unitToReset ~= "target" and unitToReset ~= "focus" then
            return
        end
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        if unitToReset == "player" or unitToReset == "target" or unitToReset == "focus" then
            local defaults = MattMinimalFrames_Defaults or {}
            local prefix = (unitToReset == "player" and "playerCastBar")
                or (unitToReset == "target" and "targetCastBar")
                or "focusCastBar"
            MattMinimalFramesDB[prefix .. "FrameScaleX"] = tonumber(defaults[prefix .. "FrameScaleX"]) or 1.0
            MattMinimalFramesDB[prefix .. "FrameScaleY"] = tonumber(defaults[prefix .. "FrameScaleY"]) or 1.0
        end
        if MMF_ResetCastBarOffsetForUnit then
            MMF_ResetCastBarOffsetForUnit(unitToReset)
        elseif MattMinimalFramesDB.castBarPositions then
            MattMinimalFramesDB.castBarPositions[unitToReset] = nil
        end
    end

    popup.resetPositionBtn:SetScript("OnClick", function()
        ResetFrameToDefaultPosition(frame, frameName)
        if frame.unit == "player" or frame.unit == "target" or frame.unit == "focus" then
            ResetUnitCastBarToDefaults(frame.unit)
            if MMF_ApplyCastBarPosition then
                MMF_ApplyCastBarPosition(frame, frame.unit)
            end
        end
        if MMF_RequestFrameUpdate then
            MMF_RequestFrameUpdate(frame)
        elseif MMF_UpdateUnitFrame then
            MMF_UpdateUnitFrame(frame)
        end
        popup:Hide()
    end)

    local hasCastBar = (frame.castBarFrame ~= nil and (frame.unit == "player" or frame.unit == "target" or frame.unit == "focus"))
    popup.resetCastBarBtn:SetShown(hasCastBar)
    popup:SetHeight(hasCastBar and 112 or 82)
    if hasCastBar then
        popup.resetCastBarBtn:ClearAllPoints()
        popup.resetCastBarBtn:SetPoint("TOP", popup, "TOP", 0, -58)
    end

    if hasCastBar then
        popup.resetCastBarBtn:SetScript("OnClick", function()
            ResetUnitCastBarToDefaults(frame.unit)
            if MMF_ApplyCastBarPosition then
                MMF_ApplyCastBarPosition(frame, frame.unit)
            end
            popup:Hide()
        end)
    end

    popup:ClearAllPoints()
    popup:SetPoint("TOP", frame, "BOTTOM", 0, -8)
    popup:Show()
end

_G.MMF_FrameFactoryResetPopup = {
    ResetFrameToDefaultPosition = ResetFrameToDefaultPosition,
    EnsureFrameResetPopup = EnsureFrameResetPopup,
    ShowFrameResetPopup = ShowFrameResetPopup,
}
