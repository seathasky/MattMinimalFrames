local Compat = _G.MMF_Compat
local ACCENT_COLOR = Compat.IsTBC and {0.2, 0.9, 0.4} or {0.6, 0.4, 0.9}  -- Green for TBC, Purple for Retail
local ADDON_TITLE = Compat.IsTBC and "|cffffffffMatt's Minimal Frames |cff66FF66TBC|r" or "|cffffffffMatt's Minimal Frames |cff9966FFMIDNIGHT|r"

-- Define static popup dialogs at file load time (not inside functions)
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

StaticPopupDialogs["MMF_RESET_ALL_WARNING"] = {
    text = "|cffFF4444WARNING:|r This will reset ALL settings and frame positions to defaults.\n\n|cffFFFF00Are you absolutely sure?|r",
    button1 = "Reset Everything",
    button2 = "Cancel",
    OnAccept = function()
        -- Wipe the ACTUAL SavedVariables table (don't create new reference)
        for k in pairs(MattMinimalFramesDB) do
            MattMinimalFramesDB[k] = nil
        end
        
        -- Copy defaults
        for key, value in pairs(MattMinimalFrames_Defaults) do
            MattMinimalFramesDB[key] = value
        end
        
        -- Physically move frames to default positions before reload
        for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
            local frame = _G[def.name]
            if frame then
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", def.x, def.y)
            end
        end
        
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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
    check:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    cb.check = check
    
    local isChecked = MattMinimalFramesDB[settingKey]
    if isChecked == nil then
        isChecked = (defaultVal ~= false)
    end
    cb:SetChecked(isChecked)
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
    container:SetSize(width, 24)
    container:SetPoint("TOPLEFT", x, y)
    
    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    text:SetPoint("LEFT", 0, 0)
    text:SetTextColor(0.8, 0.8, 0.8)
    text:SetText(label)
    text:SetWidth(95)
    text:SetJustifyH("LEFT")
    
    local valueText = container:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    valueText:SetPoint("RIGHT", 0, 0)
    valueText:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    valueText:SetWidth(35)
    valueText:SetJustifyH("RIGHT")
    
    local sliderWidth = width - 155
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetSize(sliderWidth, 8)
    slider:SetPoint("LEFT", 105, 0)
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
    thumb:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    slider:SetThumbTexture(thumb)
    
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(8)
    fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    -- Light purple for Retail, white for TBC
    if Compat.IsTBC then
        fill:SetColorTexture(0.8, 0.8, 0.8, 0.8)
    else
        fill:SetColorTexture(ACCENT_COLOR[1] * 0.5, ACCENT_COLOR[2] * 0.5, ACCENT_COLOR[3] * 0.6, 0.8)
    end
    slider.fill = fill
    
    local currentVal = MattMinimalFramesDB[settingKey] or defaultVal
    slider:SetValue(currentVal)
    if isInteger then
        valueText:SetText(tostring(math.floor(currentVal)))
    else
        -- Support higher precision for small steps
        if step and step < 0.1 then
            valueText:SetText(string.format("%.2f", currentVal))
        else
            valueText:SetText(string.format("%.1f", currentVal))
        end
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
            -- Support higher precision for small steps
            if step and step < 0.1 then
                value = math.floor(value * 100 + 0.5) / 100
                valueText:SetText(string.format("%.2f", value))
            else
                value = math.floor(value * 10 + 0.5) / 10
                valueText:SetText(string.format("%.1f", value))
            end
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

    -- If popup already exists, just show it and return
    if MMF_WelcomePopup then
        MMF_WelcomePopup:Show()
        return
    end

    -- Main frame 
    local popup = CreateFrame("Frame", "MMF_WelcomePopup", UIParent, "BackdropTemplate")
    local popupHeight = Compat.IsTBC and 680 or 705
    local popupWidth = Compat.IsTBC and 685 or 920
    popup:SetSize(popupWidth, popupHeight)
    
    -- Apply saved GUI scale
    local guiScale = MattMinimalFramesDB.guiScale or 1.0
    popup:SetScale(guiScale)
    
    -- Restore saved position or use default
    if MattMinimalFramesDB and MattMinimalFramesDB.popupPosition then
        local pos = MattMinimalFramesDB.popupPosition
        popup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    else
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    end
    
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
    popup:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left = self:GetLeft()
        local top = self:GetTop()
        if left and top then
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.popupPosition = { left = left, top = top }
        end
    end)
    popup:SetFrameStrata("DIALOG")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, popup)
    titleBar:SetSize(popupWidth, 28)
    titleBar:SetPoint("TOP", 0, 0)
    
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.12, 0.12, 0.15, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 18, "")
    title:SetPoint("LEFT", 12, 0)
    if Compat.IsTBC then
        title:SetText("|cffffffffMatt's Minimal Frames |cff66FF66TBC")
    else
        title:SetText("|cffffffffMatt's Minimal Frames ")
    end
    
    -- Add version suffix with smaller font
    local versionSuffix = titleBar:CreateFontString(nil, "OVERLAY")
    versionSuffix:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    versionSuffix:SetPoint("LEFT", title, "RIGHT", 2, 2)
    if Compat.IsTBC then
        versionSuffix:SetText("")
    else
        versionSuffix:SetText("|cff9966FFMIDNIGHT")
    end

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
    
    local scaleValue = guiScaleContainer:CreateFontString(nil, "OVERLAY")
    scaleValue:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    scaleValue:SetPoint("RIGHT", 0, 0)
    scaleValue:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    scaleValue:SetWidth(30)
    scaleValue:SetJustifyH("RIGHT")
    
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
    
    local currentScale = MattMinimalFramesDB.guiScale or 1.0
    guiScaleSlider:SetValue(currentScale)
    scaleValue:SetText(string.format("%.1f", currentScale))
    
    guiScaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10
        scaleValue:SetText(string.format("%.1f", value))
        MattMinimalFramesDB.guiScale = value
    end)
    
    guiScaleSlider:SetScript("OnMouseUp", function(self)
        local value = MattMinimalFramesDB.guiScale or 1.0
        if popup and popup:IsShown() then
            popup:SetScale(value)
        end
    end)

    -- Content area (between title bar and footer)
    local content = CreateFrame("Frame", nil, popup)
    content:SetPoint("TOPLEFT", 0, -28)
    content:SetPoint("BOTTOMRIGHT", 0, 40)

    -- Column height matches content (popup - title - footer - top/bottom padding)
    local colHeight = popupHeight - 28 - 40 - 10  -- 10 = 5 top + 5 bottom padding

    -- Left column background
    local leftCol = CreateFrame("Frame", nil, content, "BackdropTemplate")
    leftCol:SetSize(230, colHeight)
    leftCol:SetPoint("TOPLEFT", 10, -10)
    leftCol:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    leftCol:SetBackdropColor(0.08, 0.08, 0.1, 1)
    leftCol:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)

    -- Right column background (INFO column - position depends on TBC vs Retail)
    local rightCol = CreateFrame("Frame", nil, content, "BackdropTemplate")
    rightCol:SetSize(180, colHeight)
    local rightColOffset = Compat.IsTBC and 460 or 695
    rightCol:SetPoint("TOP", leftCol, "TOP", rightColOffset, 0)
    rightCol:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    rightCol:SetBackdropColor(0.08, 0.08, 0.1, 1)
    rightCol:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)

    -- Unit Frames column (2nd column - for frame scaling and text)
    local unitFramesCol = CreateFrame("Frame", nil, content, "BackdropTemplate")
    unitFramesCol:SetSize(230, colHeight)
    unitFramesCol:SetPoint("TOP", leftCol, "TOP", 240, 0)
    unitFramesCol:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    unitFramesCol:SetBackdropColor(0.08, 0.08, 0.1, 1)
    unitFramesCol:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)
    
    -- Unit frames column is shown in both Retail and TBC

    ---------------------------------------------------
    -- UNIT FRAMES COLUMN (2nd Column)
    ---------------------------------------------------
    local unitFramesTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    unitFramesTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    unitFramesTitle:SetPoint("TOPLEFT", 12, -12)
    unitFramesTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    unitFramesTitle:SetText("UNIT FRAMES")

    -- Player Frame Scale
    local playerLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    playerLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    playerLabel:SetPoint("TOPLEFT", 12, -36)
    playerLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    playerLabel:SetText("Player")

    local playerScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -56, 200, "playerFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("player")
        end
    end, false)

    local playerScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -80, 200, "playerFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("player")
        end
    end, false)

    -- Target Frame Scale
    local targetLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    targetLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    targetLabel:SetPoint("TOPLEFT", 12, -108)
    targetLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    targetLabel:SetText("Target")

    local targetScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -128, 200, "targetFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("target")
        end
    end, false)

    local targetScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -152, 200, "targetFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("target")
        end
    end, false)

    -- Target of Target Frame Scale
    local totLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    totLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    totLabel:SetPoint("TOPLEFT", 12, -180)
    totLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    totLabel:SetText("Target of Target")

    local totScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -200, 200, "totFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("targettarget")
        end
    end, false)

    local totScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -224, 200, "totFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("targettarget")
        end
    end, false)

    -- Focus Frame Scale
    local focusLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    focusLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    focusLabel:SetPoint("TOPLEFT", 12, -252)
    focusLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    focusLabel:SetText("Focus")

    local focusScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -272, 200, "focusFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("focus")
        end
    end, false)

    local focusScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -296, 200, "focusFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("focus")
        end
    end, false)

    -- Pet Frame Scale
    local petLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    petLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    petLabel:SetPoint("TOPLEFT", 12, -324)
    petLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    petLabel:SetText("Pet")

    local petScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -344, 200, "petFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("pet")
        end
    end, false)

    local petScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -368, 200, "petFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("pet")
        end
    end, false)

    -- Divider before Frame Text
    local unitFramesDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    unitFramesDivider:SetSize(200, 1)
    unitFramesDivider:SetPoint("TOPLEFT", 12, -400)
    unitFramesDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    -- Frame Text section (moved here)
    local frameTextTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    frameTextTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    frameTextTitle:SetPoint("TOPLEFT", 12, -412)
    frameTextTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    frameTextTitle:SetText("FRAME TEXT")

    local nameTextSlider = CreateMinimalSlider(unitFramesCol, "Name Size", 12, -436, 200, "nameTextSize", 8, 20, 1, 12, function(value)
        if MMF_UpdateNameTextSize then
            MMF_UpdateNameTextSize(value)
        end
    end, true)

    local hpTextSlider = CreateMinimalSlider(unitFramesCol, "HP Size", 12, -460, 200, "hpTextSize", 8, 20, 1, 13, function(value)
        if MMF_UpdateHPTextSize then
            MMF_UpdateHPTextSize(value)
        end
    end, true)

    -- Divider before Cast Bars
    local castBarsDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    castBarsDivider:SetSize(200, 1)
    castBarsDivider:SetPoint("TOPLEFT", 12, -488)
    castBarsDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    -- Cast Bars section
    local castBarsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    castBarsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    castBarsTitle:SetPoint("TOPLEFT", 12, -500)
    castBarsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    castBarsTitle:SetText("CAST BARS")

    local playerCastBarCheck = CreateMinimalCheckbox(unitFramesCol, "Player Cast Bar", 12, -524, "showPlayerCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local targetCastBarCheck = CreateMinimalCheckbox(unitFramesCol, "Target Cast Bar", 12, -548, "showTargetCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Cast bar color dropdown (minimal style: same row layout as sliders)
    local castBarColorContainer = CreateFrame("Frame", "MMF_CastBarColorDropdown", unitFramesCol)
    castBarColorContainer:SetSize(200, 24)
    castBarColorContainer:SetPoint("TOPLEFT", 12, -572)

    local castBarColorLabel = castBarColorContainer:CreateFontString(nil, "OVERLAY")
    castBarColorLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    castBarColorLabel:SetPoint("LEFT", 0, 0)
    castBarColorLabel:SetTextColor(0.8, 0.8, 0.8)
    castBarColorLabel:SetText("Cast Bar Color")
    castBarColorLabel:SetWidth(95)
    castBarColorLabel:SetJustifyH("LEFT")

    local castBarColorButton = CreateFrame("Button", nil, castBarColorContainer, "BackdropTemplate")
    castBarColorButton:SetSize(105, 20)
    castBarColorButton:SetPoint("LEFT", 105, 0)
    castBarColorButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    castBarColorButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
    castBarColorButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    castBarColorButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.6)
    end)
    castBarColorButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    local castBarColorButtonText = castBarColorButton:CreateFontString(nil, "OVERLAY")
    castBarColorButtonText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    castBarColorButtonText:SetPoint("LEFT", 4, 0)
    castBarColorButtonText:SetJustifyH("LEFT")
    castBarColorButtonText:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])

    local function UpdateCastBarColorButtonText()
        local key = MattMinimalFramesDB and MattMinimalFramesDB.castBarColor or "yellow"
        for _, opt in ipairs(MMF_Config.CAST_BAR_COLORS) do
            if opt.value == key then
                castBarColorButtonText:SetText(opt.label)
                return
            end
        end
        castBarColorButtonText:SetText("Yellow")
    end
    UpdateCastBarColorButtonText()

    -- Minimal-style dropdown list (no Blizzard UIDropDownMenu)
    local castBarColorList = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
    castBarColorList:SetSize(105, 22 * #MMF_Config.CAST_BAR_COLORS)
    castBarColorList:SetPoint("TOPLEFT", castBarColorButton, "BOTTOMLEFT", 0, -2)
    castBarColorList:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    castBarColorList:SetBackdropColor(0.06, 0.06, 0.08, 1)
    castBarColorList:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    castBarColorList:SetFrameStrata("DIALOG")
    castBarColorList:SetFrameLevel(1000)
    castBarColorList:Hide()

    for i, opt in ipairs(MMF_Config.CAST_BAR_COLORS) do
        local row = CreateFrame("Button", nil, castBarColorList, "BackdropTemplate")
        row:SetSize(105, 20)
        row:SetPoint("TOPLEFT", 1, -1 - (i - 1) * 22)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
        })
        row:SetBackdropColor(0, 0, 0, 0)
        row:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(ACCENT_COLOR[1] * 0.2, ACCENT_COLOR[2] * 0.2, ACCENT_COLOR[3] * 0.2, 0.6)
            self.text:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
        end)
        row:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0)
            self.text:SetTextColor(0.9, 0.9, 0.9)
        end)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0)
        local text = row:CreateFontString(nil, "OVERLAY")
        text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        text:SetPoint("LEFT", 4, 0)
        text:SetJustifyH("LEFT")
        text:SetTextColor(0.9, 0.9, 0.9)
        text:SetText(opt.label)
        row.text = text
        row:SetScript("OnClick", function()
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.castBarColor = opt.value
            UpdateCastBarColorButtonText()
            castBarColorList:Hide()
            if castBarColorList.clickCatcher then
                castBarColorList.clickCatcher:Hide()
            end
            StaticPopup_Show("MMF_RELOADUI")
        end)
    end

    castBarColorButton:SetScript("OnClick", function(self)
        if castBarColorList:IsShown() then
            castBarColorList:Hide()
            if castBarColorList.clickCatcher then castBarColorList.clickCatcher:Hide() end
            return
        end
        castBarColorList:Show()
        -- Click-outside to close: transparent overlay on popup (list has higher frame level so list clicks work)
        if not castBarColorList.clickCatcher then
            local catcher = CreateFrame("Button", nil, popup)
            catcher:SetAllPoints(popup)
            catcher:SetFrameLevel(popup:GetFrameLevel() + 100)
            catcher:SetScript("OnClick", function()
                catcher:Hide()
                castBarColorList:Hide()
            end)
            castBarColorList.clickCatcher = catcher
        end
        castBarColorList.clickCatcher:SetFrameLevel(popup:GetFrameLevel() + 100)
        castBarColorList.clickCatcher:Show()
    end)

    -- Middle column for CLASS BARS (Retail only)
    local middleCol = CreateFrame("Frame", nil, content, "BackdropTemplate")
    middleCol:SetSize(230, colHeight)
    middleCol:SetPoint("TOP", leftCol, "TOP", 480, 0)
    middleCol:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    middleCol:SetBackdropColor(0.08, 0.08, 0.1, 1)
    middleCol:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)
    
    -- Hide middle column in TBC
    if Compat.IsTBC then
        middleCol:Hide()
    end

    ---------------------------------------------------
    -- LEFT COLUMN: Buffs & Debuffs
    ---------------------------------------------------
    local buffsTitle = leftCol:CreateFontString(nil, "OVERLAY")
    buffsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    buffsTitle:SetPoint("TOPLEFT", 12, -12)
    buffsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    buffsTitle:SetText("BUFFS")

    local buffsCheck = CreateMinimalCheckbox(leftCol, "Enable", 12, -32, "showBuffs", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local buffXSlider = CreateMinimalSlider(leftCol, "X Offset", 12, -56, 200, "buffXOffset", -200, 200, 1, -2, function(value)
        if MMF_UpdateBuffPosition then
            MMF_UpdateBuffPosition(value, MattMinimalFramesDB.buffYOffset or -64)
        end
    end, true)

    local buffYSlider = CreateMinimalSlider(leftCol, "Y Offset", 12, -80, 200, "buffYOffset", -200, 200, 1, -64, function(value)
        if MMF_UpdateBuffPosition then
            MMF_UpdateBuffPosition(MattMinimalFramesDB.buffXOffset or -2, value)
        end
    end, true)

    -- Divider
    local divider1 = leftCol:CreateTexture(nil, "ARTWORK")
    divider1:SetSize(200, 1)
    divider1:SetPoint("TOPLEFT", 12, -108)
    divider1:SetColorTexture(0.12, 0.12, 0.15, 1)

    local debuffsTitle = leftCol:CreateFontString(nil, "OVERLAY")
    debuffsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    debuffsTitle:SetPoint("TOPLEFT", 12, -120)
    debuffsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    debuffsTitle:SetText("DEBUFFS")

    local debuffsCheck = CreateMinimalCheckbox(leftCol, "Enable", 12, -140, "showDebuffs", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local debuffXSlider = CreateMinimalSlider(leftCol, "X Offset", 12, -164, 200, "debuffXOffset", -200, 200, 1, 3, function(value)
        if MMF_UpdateDebuffPosition then
            MMF_UpdateDebuffPosition(value, MattMinimalFramesDB.debuffYOffset or 27)
        end
    end, true)

    local debuffYSlider = CreateMinimalSlider(leftCol, "Y Offset", 12, -188, 200, "debuffYOffset", -200, 200, 1, 27, function(value)
        if MMF_UpdateDebuffPosition then
            MMF_UpdateDebuffPosition(MattMinimalFramesDB.debuffXOffset or 3, value)
        end
    end, true)

    -- Divider 2
    local divider2 = leftCol:CreateTexture(nil, "ARTWORK")
    divider2:SetSize(200, 1)
    divider2:SetPoint("TOPLEFT", 12, -216)
    divider2:SetColorTexture(0.12, 0.12, 0.15, 1)

    ---------------------------------------------------
    -- AURA APPEARANCE (Left Column)
    ---------------------------------------------------
    local auraTitle = leftCol:CreateFontString(nil, "OVERLAY")
    auraTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    auraTitle:SetPoint("TOPLEFT", 12, -228)
    auraTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    auraTitle:SetText("AURA APPEARANCE")

    local auraIconSlider = CreateMinimalSlider(leftCol, "Icon Size", 12, -252, 200, "auraIconSize", 12, 40, 1, 18, function(value)
        if MMF_UpdateAuraIconSize then
            MMF_UpdateAuraIconSize(value)
        end
    end, true)

    local auraTextSlider = CreateMinimalSlider(leftCol, "Stack Text", 12, -276, 200, "auraTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateAuraTextScale then
            MMF_UpdateAuraTextScale(value)
        end
    end, false)

    local timerTextSlider = CreateMinimalSlider(leftCol, "Timer Text", 12, -300, 200, "timerTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateTimerTextScale then
            MMF_UpdateTimerTextScale(value)
        end
    end, false)

    -- Divider
    local divider4 = leftCol:CreateTexture(nil, "ARTWORK")
    divider4:SetSize(200, 1)
    divider4:SetPoint("TOPLEFT", 12, -328)
    divider4:SetColorTexture(0.12, 0.12, 0.15, 1)

    local generalTitle = leftCol:CreateFontString(nil, "OVERLAY")
    generalTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    generalTitle:SetPoint("TOPLEFT", 12, -340)
    generalTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    generalTitle:SetText("RESOURCES")

    local playerPowerCheck = CreateMinimalCheckbox(leftCol, "Player Power Bar", 12, -360, "showPlayerPowerBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local targetPowerCheck = CreateMinimalCheckbox(leftCol, "Target Power Bar", 12, -384, "showTargetPowerBar", false, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local powerBarWidthSlider = CreateMinimalSlider(leftCol, "Width", 12, -408, 200, "powerBarWidth", 30, 250, 1, 73, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.powerBarHeight or 5)
        end
    end, true)

    local powerBarHeightSlider = CreateMinimalSlider(leftCol, "Height", 12, -432, 200, "powerBarHeight", 3, 15, 1, 5, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.powerBarWidth or 73, value)
        end
    end, true)

    local healPredictionCheck = CreateMinimalCheckbox(leftCol, "Heal Prediction", 12, -460, "showHealPrediction", true, nil)

    local absorbBarCheck = CreateMinimalCheckbox(leftCol, "Absorb Bar", 12, -484, "showAbsorbBar", true, nil)

    ---------------------------------------------------
    -- MIDDLE COLUMN: Class Bars
    ---------------------------------------------------
    local classBarTitle = middleCol:CreateFontString(nil, "OVERLAY")
    classBarTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    classBarTitle:SetPoint("TOPLEFT", 12, -12)
    classBarTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    classBarTitle:SetText("CLASS BARS")

    -- DK Rune bar only shown in retail (DK doesn't exist in TBC)
    local Compat = _G.MMF_Compat
    local runeBarCheck, runeBarSlider
    if Compat.HasDeathKnight then
        -- Death Knight (Red)
        local dkTitle = middleCol:CreateFontString(nil, "OVERLAY")
        dkTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        dkTitle:SetPoint("TOPLEFT", 12, -32)
        dkTitle:SetTextColor(0.77, 0.12, 0.23)
        dkTitle:SetText("Death Knight")

        runeBarCheck = CreateMinimalCheckbox(middleCol, "Show Rune Bar", 12, -52, "showRuneBar", true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        runeBarSlider = CreateMinimalSlider(middleCol, "Rune Bar", 12, -76, 200, "runeBarScale", 0.5, 2.0, 0.01, 1.0, function(value)
            if MMF_UpdateRuneBarScale then
                MMF_UpdateRuneBarScale(value)
            end
        end, false)
        
        -- Paladin (Pink)
        local paladinTitle = middleCol:CreateFontString(nil, "OVERLAY")
        paladinTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        paladinTitle:SetPoint("TOPLEFT", 12, -104)
        paladinTitle:SetTextColor(1.0, 0.6, 0.8)
        paladinTitle:SetText("Paladin")
        
        -- Paladin Holy Power Bar
        local holyPowerBarCheck = CreateMinimalCheckbox(middleCol, "Show Holy Power Bar", 12, -124, "showHolyPowerBar", true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        local holyPowerBarSlider = CreateMinimalSlider(middleCol, "Holy Power", 12, -148, 200, "holyPowerBarScale", 0.5, 2.0, 0.01, 1.0, function(value)
            if MMF_UpdateHolyPowerBarScale then
                MMF_UpdateHolyPowerBarScale(value)
            end
        end, false)

        -- Rogue (Yellow) / Druid (Orange)
        local rogueTitle = middleCol:CreateFontString(nil, "OVERLAY")
        rogueTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        rogueTitle:SetPoint("TOPLEFT", 12, -176)
        rogueTitle:SetTextColor(1.0, 0.96, 0.41)
        rogueTitle:SetText("Rogue")

        local druidSlash = middleCol:CreateFontString(nil, "OVERLAY")
        druidSlash:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        druidSlash:SetPoint("LEFT", rogueTitle, "RIGHT", 8, 0)
        druidSlash:SetTextColor(0.9, 0.9, 0.9)
        druidSlash:SetText("/  ")

        local druidTitle = middleCol:CreateFontString(nil, "OVERLAY")
        druidTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        druidTitle:SetPoint("LEFT", druidSlash, "RIGHT", 0, 0)
        druidTitle:SetTextColor(1.0, 0.49, 0.04)
        druidTitle:SetText("Druid")

        -- Combo Point Bar (Rogue/Feral Druid)
        local comboPointBarCheck = CreateMinimalCheckbox(middleCol, "Show Combo Point Bar", 12, -196, "showComboPointBar", true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        local comboPointBarSlider = CreateMinimalSlider(middleCol, "Combo Points", 12, -220, 200, "comboPointBarScale", 0.5, 2.0, 0.01, 1.0, function(value)
            if MMF_UpdateComboPointBarScale then
                MMF_UpdateComboPointBarScale(value)
            end
        end, false)

        -- Warlock (Purple)
        local warlockTitle = middleCol:CreateFontString(nil, "OVERLAY")
        warlockTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        warlockTitle:SetPoint("TOPLEFT", 12, -248)
        warlockTitle:SetTextColor(0.58, 0.51, 0.79)
        warlockTitle:SetText("Warlock")

        -- Soul Shard Bar (Warlock)
        local soulShardBarCheck = CreateMinimalCheckbox(middleCol, "Show Soul Shard Bar", 12, -268, "showSoulShardBar", true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        local soulShardBarSlider = CreateMinimalSlider(middleCol, "Soul Shards", 12, -292, 200, "soulShardBarScale", 0.5, 2.0, 0.01, 1.0, function(value)
            if MMF_UpdateSoulShardBarScale then
                MMF_UpdateSoulShardBarScale(value)
            end
        end, false)

        -- Monk (Green)
        local monkTitle = middleCol:CreateFontString(nil, "OVERLAY")
        monkTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        monkTitle:SetPoint("TOPLEFT", 12, -320)
        monkTitle:SetTextColor(0.0, 1.0, 0.6)
        monkTitle:SetText("Monk")

        -- Chi Bar (Windwalker Monk)
        local chiBarCheck = CreateMinimalCheckbox(middleCol, "Show Chi Bar", 12, -340, "showChiBar", true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        local chiBarSlider = CreateMinimalSlider(middleCol, "Chi", 12, -364, 200, "chiBarScale", 0.5, 2.0, 0.01, 1.0, function(value)
            if MMF_UpdateChiBarScale then
                MMF_UpdateChiBarScale(value)
            end
        end, false)

        -- Mage (Blue)
        local mageTitle = middleCol:CreateFontString(nil, "OVERLAY")
        mageTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        mageTitle:SetPoint("TOPLEFT", 12, -392)
        mageTitle:SetTextColor(0.4, 0.8, 1.0)
        mageTitle:SetText("Mage")

        -- Arcane Charge Bar (Arcane Mage)
        local arcaneChargeBarCheck = CreateMinimalCheckbox(middleCol, "Show Arcane Charge Bar", 12, -412, "showArcaneChargeBar", true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        local arcaneChargeBarSlider = CreateMinimalSlider(middleCol, "Arcane Charges", 12, -436, 200, "arcaneChargeBarScale", 0.5, 2.0, 0.01, 1.0, function(value)
            if MMF_UpdateArcaneChargeBarScale then
                MMF_UpdateArcaneChargeBarScale(value)
            end
        end, false)

        -- Evoker (Pink)
        local evokerTitle = middleCol:CreateFontString(nil, "OVERLAY")
        evokerTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        evokerTitle:SetPoint("TOPLEFT", 12, -464)
        evokerTitle:SetTextColor(0.94, 0.3, 0.8)
        evokerTitle:SetText("Evoker")

        -- Essence Bar (Evoker)
        local essenceBarCheck = CreateMinimalCheckbox(middleCol, "Show Essence Bar", 12, -484, "showEssenceBar", true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        local essenceBarSlider = CreateMinimalSlider(middleCol, "Essence", 12, -508, 200, "essenceBarScale", 0.5, 2.0, 0.01, 1.0, function(value)
            if MMF_UpdateEssenceBarScale then
                MMF_UpdateEssenceBarScale(value)
            end
        end, false)
    else

    end

    ---------------------------------------------------
    -- RIGHT COLUMN: Info
    ---------------------------------------------------
    local infoTitle = rightCol:CreateFontString(nil, "OVERLAY")
    infoTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    infoTitle:SetPoint("TOPLEFT", 12, -12)
    infoTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    infoTitle:SetText("INFO")

    local showHintsCheck = CreateMinimalCheckbox(rightCol, "Show Move Hints", 12, -32, "showMoveHints", false, nil)

    -- Minimap icon checkbox (uses LibDBIcon's minimap.hide structure)
    local showMinimapContainer = CreateFrame("Frame", nil, rightCol)
    showMinimapContainer:SetSize(200, 20)
    showMinimapContainer:SetPoint("TOPLEFT", 12, -56)
    
    local showMinimapCB = CreateFrame("CheckButton", nil, showMinimapContainer)
    showMinimapCB:SetSize(14, 14)
    showMinimapCB:SetPoint("LEFT", 0, 0)
    
    local mmBg = showMinimapCB:CreateTexture(nil, "BACKGROUND")
    mmBg:SetAllPoints()
    mmBg:SetColorTexture(0.08, 0.08, 0.1, 1)
    
    local mmBorder = showMinimapCB:CreateTexture(nil, "BORDER")
    mmBorder:SetPoint("TOPLEFT", -1, 1)
    mmBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    mmBorder:SetColorTexture(0.25, 0.25, 0.3, 1)
    
    local mmCheck = showMinimapCB:CreateTexture(nil, "ARTWORK")
    mmCheck:SetSize(8, 8)
    mmCheck:SetPoint("CENTER")
    mmCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    showMinimapCB.check = mmCheck
    
    -- Initialize: LibDBIcon uses minimap.hide (true = hidden)
    local isHidden = MattMinimalFramesDB.minimap and MattMinimalFramesDB.minimap.hide
    showMinimapCB:SetChecked(not isHidden)
    mmCheck:SetShown(not isHidden)
    
    showMinimapCB:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.check:SetShown(checked)
        if MMF_ToggleMinimapButton then
            MMF_ToggleMinimapButton(checked)
        end
    end)
    
    local mmText = showMinimapContainer:CreateFontString(nil, "OVERLAY")
    mmText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    mmText:SetPoint("LEFT", showMinimapCB, "RIGHT", 6, 0)
    mmText:SetTextColor(0.85, 0.85, 0.85)
    mmText:SetText("Show Minimap Icon")

    -- Alignment grid (session-only, resets each time popup is created)
    if MattMinimalFramesDB then MattMinimalFramesDB.showAlignmentGrid = false end
    local alignGridCheck = CreateMinimalCheckbox(rightCol, "Alignment Grid", 12, -80, "showAlignmentGrid", false, function(checked)
        if MMF_ToggleAlignmentGrid then
            MMF_ToggleAlignmentGrid(checked)
        end
    end)

    local infoText = rightCol:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    infoText:SetPoint("TOPLEFT", 12, -152)
    infoText:SetWidth(156)
    infoText:SetJustifyH("LEFT")
    infoText:SetSpacing(3)
    infoText:SetTextColor(0.6, 0.6, 0.6)
    -- Purple highlights for Retail, cyan for TBC
    local highlightColor = Compat.IsTBC and "|cff33ccff" or "|cff9966FF"
    infoText:SetText("Hold " .. highlightColor .. "SHIFT|r + drag frames to reposition.\n\nType " .. highlightColor .. "/mmf|r to open this panel.\n\nChanges to some checkboxes may require a UI reload.")

    -- Footer
    local footer = CreateFrame("Frame", nil, popup)
    footer:SetSize(popupWidth, 40)
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
    dsCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
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

    -- Reset Scale/Text button
    local resetScaleBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    resetScaleBtn:SetSize(95, 24)
    resetScaleBtn:SetPoint("RIGHT", -178, 0)
    resetScaleBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    resetScaleBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    resetScaleBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    
    local resetScaleBtnText = resetScaleBtn:CreateFontString(nil, "OVERLAY")
    resetScaleBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    resetScaleBtnText:SetPoint("CENTER")
    resetScaleBtnText:SetText("Reset Scale/Text")
    resetScaleBtnText:SetTextColor(0.8, 0.8, 0.8)
    
    resetScaleBtn:SetScript("OnEnter", function(self) 
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        resetScaleBtnText:SetTextColor(1, 1, 1)
    end)
    resetScaleBtn:SetScript("OnLeave", function(self) 
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        resetScaleBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)
    resetScaleBtn:SetScript("OnClick", function()
        local d = MattMinimalFrames_Defaults
        -- Text/aura scales
        MattMinimalFramesDB.auraTextScale = d.auraTextScale
        MattMinimalFramesDB.timerTextScale = d.timerTextScale
        MattMinimalFramesDB.auraIconSize = d.auraIconSize
        MattMinimalFramesDB.nameTextSize = d.nameTextSize
        MattMinimalFramesDB.hpTextSize = d.hpTextSize
        -- Power bar size
        MattMinimalFramesDB.powerBarWidth = d.powerBarWidth
        MattMinimalFramesDB.powerBarHeight = d.powerBarHeight
        -- Class resource bar scales
        MattMinimalFramesDB.runeBarScale = d.runeBarScale
        MattMinimalFramesDB.holyPowerBarScale = d.holyPowerBarScale
        MattMinimalFramesDB.comboPointBarScale = d.comboPointBarScale
        MattMinimalFramesDB.soulShardBarScale = d.soulShardBarScale
        MattMinimalFramesDB.chiBarScale = d.chiBarScale
        MattMinimalFramesDB.arcaneChargeBarScale = d.arcaneChargeBarScale
        MattMinimalFramesDB.essenceBarScale = d.essenceBarScale
        -- Frame scales
        MattMinimalFramesDB.playerFrameScaleX = d.playerFrameScaleX
        MattMinimalFramesDB.playerFrameScaleY = d.playerFrameScaleY
        MattMinimalFramesDB.targetFrameScaleX = d.targetFrameScaleX
        MattMinimalFramesDB.targetFrameScaleY = d.targetFrameScaleY
        MattMinimalFramesDB.totFrameScaleX = d.totFrameScaleX
        MattMinimalFramesDB.totFrameScaleY = d.totFrameScaleY
        MattMinimalFramesDB.focusFrameScaleX = d.focusFrameScaleX
        MattMinimalFramesDB.focusFrameScaleY = d.focusFrameScaleY
        MattMinimalFramesDB.petFrameScaleX = d.petFrameScaleX
        MattMinimalFramesDB.petFrameScaleY = d.petFrameScaleY
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Reset All button
    local resetAllBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    resetAllBtn:SetSize(70, 24)
    resetAllBtn:SetPoint("RIGHT", -100, 0)
    resetAllBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    resetAllBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    resetAllBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    
    local resetAllBtnText = resetAllBtn:CreateFontString(nil, "OVERLAY")
    resetAllBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    resetAllBtnText:SetPoint("CENTER")
    resetAllBtnText:SetText("Reset All")
    resetAllBtnText:SetTextColor(0.8, 0.8, 0.8)
    
    resetAllBtn:SetScript("OnEnter", function(self) 
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        resetAllBtnText:SetTextColor(1, 0.3, 0.3)
    end)
    resetAllBtn:SetScript("OnLeave", function(self) 
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        resetAllBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)
    resetAllBtn:SetScript("OnClick", function()
        StaticPopup_Show("MMF_RESET_ALL_WARNING")
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    closeBtn:SetSize(70, 24)
    closeBtn:SetPoint("RIGHT", -22, 0)
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
end
