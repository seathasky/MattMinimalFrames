function MMF_EnsurePopupEditModePopup(config)
    config = config or {}

    local existingPopup = config.existingPopup
    local popup = config.popup
    local ACCENT_COLOR = config.accentColor or { 0.6, 0.4, 0.9 }
    local OnExitEditMode = config.onExitEditMode or function() end

    if existingPopup then
        return existingPopup
    end

    local editModePopup = CreateFrame("Frame", "MMF_EditModePopup", UIParent, "BackdropTemplate")
    editModePopup:SetSize(380, 170)
    editModePopup:SetPoint("TOP", UIParent, "TOP", 0, -120)
    editModePopup:SetFrameStrata("DIALOG")
    editModePopup:SetToplevel(true)
    editModePopup:SetMovable(true)
    editModePopup:EnableMouse(true)
    editModePopup:RegisterForDrag("LeftButton")
    editModePopup:SetScript("OnDragStart", editModePopup.StartMoving)
    editModePopup:SetScript("OnDragStop", editModePopup.StopMovingOrSizing)
    editModePopup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editModePopup:SetBackdropColor(0.04, 0.04, 0.05, 0.98)
    editModePopup:SetBackdropBorderColor(0.1, 0.1, 0.12, 1)

    local modeTitleBar = CreateFrame("Frame", nil, editModePopup)
    modeTitleBar:SetPoint("TOPLEFT", 0, 0)
    modeTitleBar:SetPoint("TOPRIGHT", 0, 0)
    modeTitleBar:SetHeight(28)

    local modeTitleBg = modeTitleBar:CreateTexture(nil, "BACKGROUND")
    modeTitleBg:SetAllPoints()
    modeTitleBg:SetColorTexture(0.07, 0.09, 0.11, 1)

    local modeTitleGlow = modeTitleBar:CreateTexture(nil, "ARTWORK")
    modeTitleGlow:SetPoint("BOTTOMLEFT", 0, 0)
    modeTitleGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    modeTitleGlow:SetHeight(2)
    modeTitleGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

    local modeTitle = modeTitleBar:CreateFontString(nil, "OVERLAY")
    modeTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    modeTitle:SetPoint("LEFT", 12, 1)
    modeTitle:SetTextColor(1, 1, 1)
    modeTitle:SetText("Matt's Minimal Frames Edit Mode")

    local modeHelp = editModePopup:CreateFontString(nil, "OVERLAY")
    modeHelp:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    modeHelp:SetPoint("TOP", editModePopup, "TOP", 0, -54)
    modeHelp:SetTextColor(0.85, 0.85, 0.85)
    modeHelp:SetText("Drag frames normally. Click below to exit Edit Mode.")

    local openGuiContainer = CreateFrame("Frame", nil, editModePopup)
    openGuiContainer:SetSize(220, 20)
    openGuiContainer:SetPoint("TOP", modeHelp, "BOTTOM", 0, -10)

    local openGuiCheckbox = CreateFrame("CheckButton", nil, openGuiContainer)
    openGuiCheckbox:SetSize(14, 14)
    openGuiCheckbox:SetPoint("LEFT", 0, 0)

    local openGuiBg = openGuiCheckbox:CreateTexture(nil, "BACKGROUND")
    openGuiBg:SetAllPoints()
    openGuiBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local openGuiBorder = openGuiCheckbox:CreateTexture(nil, "BORDER")
    openGuiBorder:SetPoint("TOPLEFT", -1, 1)
    openGuiBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    openGuiBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local openGuiCheck = openGuiCheckbox:CreateTexture(nil, "ARTWORK")
    openGuiCheck:SetSize(8, 8)
    openGuiCheck:SetPoint("CENTER")
    openGuiCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    openGuiCheckbox.check = openGuiCheck

    local openGuiLabel = openGuiContainer:CreateFontString(nil, "OVERLAY")
    openGuiLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    openGuiLabel:SetPoint("LEFT", openGuiCheckbox, "RIGHT", 6, 0)
    openGuiLabel:SetTextColor(0.9, 0.9, 0.9)
    openGuiLabel:SetText("Open Settings GUI")

    local gridContainer = CreateFrame("Frame", nil, editModePopup)
    gridContainer:SetSize(180, 20)
    gridContainer:SetPoint("TOP", openGuiContainer, "BOTTOM", 0, -8)

    local gridCheckbox = CreateFrame("CheckButton", nil, gridContainer)
    gridCheckbox:SetSize(14, 14)
    gridCheckbox:SetPoint("LEFT", 0, 0)

    local gridBg = gridCheckbox:CreateTexture(nil, "BACKGROUND")
    gridBg:SetAllPoints()
    gridBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local gridBorder = gridCheckbox:CreateTexture(nil, "BORDER")
    gridBorder:SetPoint("TOPLEFT", -1, 1)
    gridBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    gridBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local gridCheck = gridCheckbox:CreateTexture(nil, "ARTWORK")
    gridCheck:SetSize(8, 8)
    gridCheck:SetPoint("CENTER")
    gridCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    gridCheckbox.check = gridCheck

    local gridLabel = gridContainer:CreateFontString(nil, "OVERLAY")
    gridLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    gridLabel:SetPoint("LEFT", gridCheckbox, "RIGHT", 6, 0)
    gridLabel:SetTextColor(0.9, 0.9, 0.9)
    gridLabel:SetText("Alignment Grid")

    local function SetGridChecked(checked)
        gridCheckbox:SetChecked(checked == true)
        if gridCheckbox.check then
            gridCheckbox.check:SetShown(checked == true)
        end
    end

    local function SetOpenGuiChecked(checked)
        openGuiCheckbox:SetChecked(checked == true)
        if openGuiCheckbox.check then
            openGuiCheckbox.check:SetShown(checked == true)
        end
    end

    openGuiCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == true
        SetOpenGuiChecked(checked)
        if checked then
            popup:Show()
        else
            popup:Hide()
        end
    end)

    gridCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == true
        SetGridChecked(checked)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        MattMinimalFramesDB.showAlignmentGrid = checked
        if MMF_ToggleAlignmentGrid then
            MMF_ToggleAlignmentGrid(checked)
        end
    end)

    local exitButton = CreateFrame("Button", nil, editModePopup, "BackdropTemplate")
    exitButton:SetSize(150, 24)
    exitButton:SetPoint("BOTTOM", editModePopup, "BOTTOM", 0, 16)
    exitButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    exitButton:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
    exitButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)

    local exitText = exitButton:CreateFontString(nil, "OVERLAY")
    exitText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    exitText:SetPoint("CENTER")
    exitText:SetTextColor(0.9, 0.9, 0.9)
    exitText:SetText("Exit Edit Mode")

    exitButton:SetScript("OnEnter", function()
        exitButton:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
    end)
    exitButton:SetScript("OnLeave", function()
        exitButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
    end)
    exitButton:SetScript("OnClick", function()
        if MMF_SetEditMode then
            MMF_SetEditMode(false)
        else
            MattMinimalFramesDB.unlockFramesEditMode = false
            if MMF_RefreshFrameLockState then
                MMF_RefreshFrameLockState()
            end
        end
        OnExitEditMode()
        editModePopup:Hide()
        popup:Show()
    end)

    editModePopup:SetScript("OnShow", function(self)
        local scale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB and MattMinimalFramesDB.guiScale)) or 1.0
        self:SetScale(scale)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        if MattMinimalFramesDB.showAlignmentGrid ~= true then
            MattMinimalFramesDB.showAlignmentGrid = true
            if MMF_ToggleAlignmentGrid then
                MMF_ToggleAlignmentGrid(true)
            end
        end
        SetOpenGuiChecked(false)
        popup:Hide()
        SetGridChecked(MattMinimalFramesDB.showAlignmentGrid == true)
    end)

    editModePopup:Hide()
    return editModePopup
end
