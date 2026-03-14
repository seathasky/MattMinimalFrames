function MMF_CreatePopupHeaderGUIScaleControl(titleBar, closeX, popup, accentColor, applyPopupScale)
    if not titleBar or not closeX then
        return
    end

    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local ApplyPopupScale = applyPopupScale or function() end

    -- GUI Scale slider on title bar
    local guiScaleContainer = CreateFrame("Frame", nil, titleBar)
    guiScaleContainer:SetSize(120, 24)
    guiScaleContainer:SetPoint("RIGHT", closeX, "LEFT", -8, 0)

    local scaleLabel = guiScaleContainer:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    scaleLabel:SetPoint("LEFT", 0, 0)
    scaleLabel:SetTextColor(0.8, 0.8, 0.8)
    scaleLabel:SetText("Scale")
    scaleLabel:SetWidth(35)
    scaleLabel:SetJustifyH("LEFT")

    -- Persistent themed value box for GUI scale (matches slider inputs)
    local scaleValueBg = CreateFrame("Frame", nil, guiScaleContainer, "BackdropTemplate")
    scaleValueBg:SetSize(36, 18)
    scaleValueBg:SetPoint("RIGHT", 0, 0)
    scaleValueBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    scaleValueBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
    scaleValueBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local scaleValue = CreateFrame("EditBox", nil, scaleValueBg)
    scaleValue:SetAllPoints(scaleValueBg)
    scaleValue:SetAutoFocus(false)
    scaleValue:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    scaleValue:SetJustifyH("CENTER")
    scaleValue:SetJustifyV("MIDDLE")
    scaleValue:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])

    local guiScaleSlider = CreateFrame("Slider", nil, guiScaleContainer, "BackdropTemplate")
    guiScaleSlider:SetSize(40, 8)
    guiScaleSlider:SetPoint("LEFT", 40, 0)
    guiScaleSlider:SetOrientation("HORIZONTAL")
    guiScaleSlider:SetMinMaxValues(0.5, 1.5)
    guiScaleSlider:SetValueStep(0.1)
    guiScaleSlider:SetObeyStepOnDrag(true)
    guiScaleSlider:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    guiScaleSlider:SetBackdropColor(0.06, 0.06, 0.08, 1)

    local guiScaleThumb = guiScaleSlider:CreateTexture(nil, "OVERLAY")
    guiScaleThumb:SetSize(6, 12)
    guiScaleThumb:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    guiScaleSlider:SetThumbTexture(guiScaleThumb)

    local currentScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
    guiScaleSlider:SetValue(currentScale)
    scaleValue:SetText(string.format("%.1f", currentScale))

    -- Visual feedback on hover / focus
    scaleValueBg:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.6)
    end)
    scaleValueBg:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    scaleValue:SetScript("OnEnterPressed", function(self)
        local num = tonumber(self:GetText())
        if not num then
            self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
            return
        end
        num = (MMF_ClampGUIScale and MMF_ClampGUIScale(num)) or num
        guiScaleSlider:SetValue(num)
        MattMinimalFramesDB.guiScale = num
        if popup and popup.IsVisible and popup:IsVisible() then
            ApplyPopupScale(num, true)
        end
    end)
    scaleValue:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
        self:ClearFocus()
    end)
    scaleValue:SetScript("OnEditFocusLost", function(self)
        self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
    end)

    guiScaleSlider:SetScript("OnValueChanged", function(self, value)
        value = (MMF_ClampGUIScale and MMF_ClampGUIScale(value)) or value
        scaleValue:SetText(string.format("%.1f", value))
        MattMinimalFramesDB.guiScale = value
    end)

    guiScaleSlider:SetScript("OnMouseUp", function(self)
        local value = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
        MattMinimalFramesDB.guiScale = value
        if popup and popup:IsShown() then
            ApplyPopupScale(value, true)
        end
    end)
end
