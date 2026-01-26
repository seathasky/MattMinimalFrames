-- core/popup.lua
-- Contains the MMF_ShowWelcomePopup function for MattMinimalFrames

-- Helper to create a minimal styled checkbox
local function CreateMinimalCheckbox(parent, label, x, y, settingKey, defaultVal, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 20)
    container:SetPoint("TOPLEFT", x, y)
    
    local cb = CreateFrame("CheckButton", nil, container)
    cb:SetSize(14, 14)
    cb:SetPoint("LEFT", 0, 0)
    
    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.1, 1)
    
    local border = cb:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.25, 0.25, 0.3, 1)
    
    local check = cb:CreateTexture(nil, "ARTWORK")
    check:SetSize(8, 8)
    check:SetPoint("CENTER")
    check:SetColorTexture(0.2, 0.75, 1, 1)
    cb.check = check
    
    cb:SetChecked(MattMinimalFramesDB[settingKey] ~= false and (defaultVal ~= false))
    check:SetShown(cb:GetChecked())
    
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.check:SetShown(checked)
        MattMinimalFramesDB[settingKey] = checked
        if onChange then onChange(checked) end
    end)
    
    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    text:SetTextColor(0.9, 0.9, 0.9)
    text:SetText(label)
    
    container.checkbox = cb
    return container
end

-- Helper to create a minimal slider with label on left
local function CreateMinimalSlider(parent, label, x, y, width, settingKey, minVal, maxVal, step, defaultVal, onChange, isInteger)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 20)
    container:SetPoint("TOPLEFT", x, y)
    
    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    text:SetPoint("LEFT", 0, 0)
    text:SetTextColor(0.8, 0.8, 0.8)
    text:SetText(label)
    
    local valueText = container:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    valueText:SetPoint("RIGHT", 0, 0)
    valueText:SetTextColor(0.2, 0.75, 1)
    valueText:SetWidth(35)
    valueText:SetJustifyH("RIGHT")
    
    local sliderWidth = width - 100
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetSize(sliderWidth, 8)
    slider:SetPoint("RIGHT", valueText, "LEFT", -8, 0)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    slider:SetBackdropColor(0.06, 0.06, 0.08, 1)
    
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 14)
    thumb:SetColorTexture(0.2, 0.75, 1, 1)
    slider:SetThumbTexture(thumb)
    
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(8)
    fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    fill:SetColorTexture(0.1, 0.3, 0.4, 0.8)
    slider.fill = fill
    
    local currentVal = MattMinimalFramesDB[settingKey] or defaultVal
    slider:SetValue(currentVal)
    if isInteger then
        valueText:SetText(tostring(math.floor(currentVal)))
    else
        valueText:SetText(string.format("%.1f", currentVal))
    end
    
    local function UpdateFill()
        local min, max = slider:GetMinMaxValues()
        local val = slider:GetValue()
        local pct = (val - min) / (max - min)
        fill:SetWidth(math.max(1, slider:GetWidth() * pct))
    end
    UpdateFill()
    
    slider:SetScript("OnValueChanged", function(self, value)
        if isInteger then
            value = math.floor(value + 0.5)
            valueText:SetText(tostring(value))
        else
            value = math.floor(value * 10 + 0.5) / 10
            valueText:SetText(string.format("%.1f", value))
        end
        MattMinimalFramesDB[settingKey] = value
        UpdateFill()
        if onChange then onChange(value) end
    end)
    
    container.slider = slider
    container.valueText = valueText
    return container
end

function MMF_ShowWelcomePopup(forceShow)
    if not forceShow and MattMinimalFramesDB.hideWelcomeMessage then return end

    if MMF_WelcomePopup then MMF_WelcomePopup:Hide() end

    -- Main frame - wider ElvUI style
    local popup = CreateFrame("Frame", "MMF_WelcomePopup", UIParent, "BackdropTemplate")
    popup:SetSize(500, 380)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.04, 0.04, 0.05, 0.98)
    popup:SetBackdropBorderColor(0.1, 0.1, 0.12, 1)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup:SetFrameStrata("DIALOG")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, popup)
    titleBar:SetSize(500, 28)
    titleBar:SetPoint("TOP", 0, 0)
    
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.06, 0.06, 0.08, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("MattMinimalFrames")
    title:SetTextColor(0.2, 0.75, 1)

    local closeX = CreateFrame("Button", nil, titleBar)
    closeX:SetSize(28, 28)
    closeX:SetPoint("RIGHT", 0, 0)
    local closeText = closeX:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 14, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    closeText:SetTextColor(0.5, 0.5, 0.5)
    closeX:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.3, 0.3) end)
    closeX:SetScript("OnLeave", function() closeText:SetTextColor(0.5, 0.5, 0.5) end)
    closeX:SetScript("OnClick", function() popup:Hide() end)

    -- Content area
    local content = CreateFrame("Frame", nil, popup)
    content:SetPoint("TOPLEFT", 0, -28)
    content:SetPoint("BOTTOMRIGHT", 0, 40)

    -- Left column background
    local leftCol = CreateFrame("Frame", nil, content, "BackdropTemplate")
    leftCol:SetSize(230, 312)
    leftCol:SetPoint("TOPLEFT", 10, -10)
    leftCol:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    leftCol:SetBackdropColor(0.03, 0.03, 0.04, 1)
    leftCol:SetBackdropBorderColor(0.08, 0.08, 0.1, 1)

    -- Right column background  
    local rightCol = CreateFrame("Frame", nil, content, "BackdropTemplate")
    rightCol:SetSize(230, 312)
    rightCol:SetPoint("TOPRIGHT", -10, -10)
    rightCol:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    rightCol:SetBackdropColor(0.03, 0.03, 0.04, 1)
    rightCol:SetBackdropBorderColor(0.08, 0.08, 0.1, 1)

    ---------------------------------------------------
    -- LEFT COLUMN: Buffs & Debuffs
    ---------------------------------------------------
    local buffsTitle = leftCol:CreateFontString(nil, "OVERLAY")
    buffsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    buffsTitle:SetPoint("TOPLEFT", 12, -12)
    buffsTitle:SetTextColor(0.2, 0.75, 1)
    buffsTitle:SetText("BUFFS")

    local buffsCheck = CreateMinimalCheckbox(leftCol, "Enable", 12, -32, "showBuffs", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local buffXSlider = CreateMinimalSlider(leftCol, "X Offset", 12, -56, 206, "buffXOffset", -200, 200, 1, -2, function(value)
        if MMF_UpdateBuffPosition then
            MMF_UpdateBuffPosition(value, MattMinimalFramesDB.buffYOffset or -64)
        end
    end, true)

    local buffYSlider = CreateMinimalSlider(leftCol, "Y Offset", 12, -80, 206, "buffYOffset", -200, 200, 1, -64, function(value)
        if MMF_UpdateBuffPosition then
            MMF_UpdateBuffPosition(MattMinimalFramesDB.buffXOffset or -2, value)
        end
    end, true)

    -- Divider
    local divider1 = leftCol:CreateTexture(nil, "ARTWORK")
    divider1:SetSize(206, 1)
    divider1:SetPoint("TOPLEFT", 12, -108)
    divider1:SetColorTexture(0.12, 0.12, 0.15, 1)

    local debuffsTitle = leftCol:CreateFontString(nil, "OVERLAY")
    debuffsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    debuffsTitle:SetPoint("TOPLEFT", 12, -120)
    debuffsTitle:SetTextColor(0.2, 0.75, 1)
    debuffsTitle:SetText("DEBUFFS")

    local debuffsCheck = CreateMinimalCheckbox(leftCol, "Enable", 12, -140, "showDebuffs", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local debuffXSlider = CreateMinimalSlider(leftCol, "X Offset", 12, -164, 206, "debuffXOffset", -200, 200, 1, 3, function(value)
        if MMF_UpdateDebuffPosition then
            MMF_UpdateDebuffPosition(value, MattMinimalFramesDB.debuffYOffset or 27)
        end
    end, true)

    local debuffYSlider = CreateMinimalSlider(leftCol, "Y Offset", 12, -188, 206, "debuffYOffset", -200, 200, 1, 27, function(value)
        if MMF_UpdateDebuffPosition then
            MMF_UpdateDebuffPosition(MattMinimalFramesDB.debuffXOffset or 3, value)
        end
    end, true)

    -- Divider 2
    local divider2 = leftCol:CreateTexture(nil, "ARTWORK")
    divider2:SetSize(206, 1)
    divider2:SetPoint("TOPLEFT", 12, -216)
    divider2:SetColorTexture(0.12, 0.12, 0.15, 1)

    local generalTitle = leftCol:CreateFontString(nil, "OVERLAY")
    generalTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    generalTitle:SetPoint("TOPLEFT", 12, -228)
    generalTitle:SetTextColor(0.2, 0.75, 1)
    generalTitle:SetText("GENERAL")

    local resourceCheck = CreateMinimalCheckbox(leftCol, "Show Resource Bars", 12, -248, "showPowerBars", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    ---------------------------------------------------
    -- RIGHT COLUMN: Aura Appearance
    ---------------------------------------------------
    local auraTitle = rightCol:CreateFontString(nil, "OVERLAY")
    auraTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    auraTitle:SetPoint("TOPLEFT", 12, -12)
    auraTitle:SetTextColor(0.2, 0.75, 1)
    auraTitle:SetText("AURA APPEARANCE")

    local auraIconSlider = CreateMinimalSlider(rightCol, "Icon Size", 12, -36, 206, "auraIconSize", 12, 40, 1, 18, function(value)
        if MMF_UpdateAuraIconSize then
            MMF_UpdateAuraIconSize(value)
        end
    end, true)

    local auraTextSlider = CreateMinimalSlider(rightCol, "Stack Text", 12, -60, 206, "auraTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateAuraTextScale then
            MMF_UpdateAuraTextScale(value)
        end
    end, false)

    local timerTextSlider = CreateMinimalSlider(rightCol, "Timer Text", 12, -84, 206, "timerTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateTimerTextScale then
            MMF_UpdateTimerTextScale(value)
        end
    end, false)

    -- Divider
    local divider3 = rightCol:CreateTexture(nil, "ARTWORK")
    divider3:SetSize(206, 1)
    divider3:SetPoint("TOPLEFT", 12, -112)
    divider3:SetColorTexture(0.12, 0.12, 0.15, 1)

    local infoTitle = rightCol:CreateFontString(nil, "OVERLAY")
    infoTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    infoTitle:SetPoint("TOPLEFT", 12, -124)
    infoTitle:SetTextColor(0.2, 0.75, 1)
    infoTitle:SetText("INFO")

    local infoText = rightCol:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    infoText:SetPoint("TOPLEFT", 12, -144)
    infoText:SetWidth(206)
    infoText:SetJustifyH("LEFT")
    infoText:SetSpacing(3)
    infoText:SetTextColor(0.6, 0.6, 0.6)
    infoText:SetText("Hold |cff33ccffSHIFT|r + drag frames to reposition.\n\nType |cff33ccff/mmf|r to open this panel.\n\nChanges to checkboxes require a UI reload.")

    -- Footer
    local footer = CreateFrame("Frame", nil, popup)
    footer:SetSize(500, 40)
    footer:SetPoint("BOTTOM", 0, 0)
    
    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(0.03, 0.03, 0.04, 1)

    local dontShowCheck = CreateFrame("CheckButton", nil, footer)
    dontShowCheck:SetSize(12, 12)
    dontShowCheck:SetPoint("LEFT", 14, 0)
    
    local dsBg = dontShowCheck:CreateTexture(nil, "BACKGROUND")
    dsBg:SetAllPoints()
    dsBg:SetColorTexture(0.08, 0.08, 0.1, 1)
    
    local dsBorder = dontShowCheck:CreateTexture(nil, "BORDER")
    dsBorder:SetPoint("TOPLEFT", -1, 1)
    dsBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    dsBorder:SetColorTexture(0.2, 0.2, 0.25, 1)
    
    local dsCheck = dontShowCheck:CreateTexture(nil, "ARTWORK")
    dsCheck:SetSize(6, 6)
    dsCheck:SetPoint("CENTER")
    dsCheck:SetColorTexture(0.2, 0.75, 1, 1)
    dontShowCheck.check = dsCheck
    
    dontShowCheck:SetChecked(MattMinimalFramesDB.hideWelcomeMessage)
    dsCheck:SetShown(dontShowCheck:GetChecked())
    
    dontShowCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.check:SetShown(checked)
        MattMinimalFramesDB.hideWelcomeMessage = checked
    end)
    
    local dontShowText = footer:CreateFontString(nil, "OVERLAY")
    dontShowText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    dontShowText:SetPoint("LEFT", dontShowCheck, "RIGHT", 5, 0)
    dontShowText:SetTextColor(0.5, 0.5, 0.5)
    dontShowText:SetText("Don't show on login")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    closeBtn:SetSize(70, 24)
    closeBtn:SetPoint("RIGHT", -14, 0)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    closeBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    closeBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    
    local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    closeBtnText:SetPoint("CENTER")
    closeBtnText:SetText("Close")
    closeBtnText:SetTextColor(0.8, 0.8, 0.8)
    
    closeBtn:SetScript("OnEnter", function(self) 
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        closeBtnText:SetTextColor(1, 1, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self) 
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        closeBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)
    closeBtn:SetScript("OnClick", function() popup:Hide() end)

    popup:Show()

    StaticPopupDialogs["MMF_RELOADUI"] = {
        text = "Reload UI to apply changes?",
        button1 = "Reload",
        button2 = "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end
