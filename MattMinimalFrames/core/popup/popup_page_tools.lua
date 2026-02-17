function MMF_CreateToolsPage(rightCol, accentColor, accentHexPrefix, createMinimalCheckbox, isUISoundsEnabled)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local ACCENT_HEX_PREFIX = accentHexPrefix or "|cff9966e6"
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local IsUISoundsEnabled = isUISoundsEnabled or MMF_IsPopupUISoundsEnabled or function()
        return true
    end

    -- RIGHT COLUMN: Tools
    ---------------------------------------------------
    local infoTitle = rightCol:CreateFontString(nil, "OVERLAY")
    infoTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    infoTitle:SetPoint("TOPLEFT", 12, -12)
    infoTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    infoTitle:SetText("TOOLS")

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

    local toolsDivider = rightCol:CreateTexture(nil, "ARTWORK")
    toolsDivider:SetSize(176, 1)
    toolsDivider:SetPoint("TOPLEFT", 12, -112)
    toolsDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local toolsActionsTitle = rightCol:CreateFontString(nil, "OVERLAY")
    toolsActionsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    toolsActionsTitle:SetPoint("TOPLEFT", 12, -124)
    toolsActionsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    toolsActionsTitle:SetText("ACTIONS")

    CreateMinimalCheckbox(rightCol, "UI Sounds", 12, -148, "uiSoundsEnabled", true, nil)
    local rainbowClassColorGUILabel =
        "|cffff3b3bC|cffff7a2el|cffffb326a|cffffe01bs|cfff4ff10s " ..
        "|cff8dff24C|cff36ff61o|cff22ffc6l|cff2bc9ffo|cff3e7dffr " ..
        "|cff8f4effG|cffa548ffU|cfff14bffI"
    CreateMinimalCheckbox(rightCol, rainbowClassColorGUILabel, 12, -172, "classColorGUI", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local function ResetScaleAndTextToDefaults()
        local d = MattMinimalFrames_Defaults
        -- Text/aura scales
        MattMinimalFramesDB.auraTextScale = d.auraTextScale
        MattMinimalFramesDB.timerTextScale = d.timerTextScale
        MattMinimalFramesDB.auraIconSize = d.auraIconSize
        MattMinimalFramesDB.nameTextSize = d.nameTextSize
        MattMinimalFramesDB.enableNameTruncation = d.enableNameTruncation
        MattMinimalFramesDB.autoResizeTextOnLongName = d.autoResizeTextOnLongName
        MattMinimalFramesDB.nameTruncationLength = d.nameTruncationLength
        MattMinimalFramesDB.nameTextXOffset = d.nameTextXOffset
        MattMinimalFramesDB.nameTextYOffset = d.nameTextYOffset
        MattMinimalFramesDB.playerNameTextXOffset = d.playerNameTextXOffset
        MattMinimalFramesDB.playerNameTextYOffset = d.playerNameTextYOffset
        MattMinimalFramesDB.targetNameTextXOffset = d.targetNameTextXOffset
        MattMinimalFramesDB.targetNameTextYOffset = d.targetNameTextYOffset
        MattMinimalFramesDB.totNameTextXOffset = d.totNameTextXOffset
        MattMinimalFramesDB.totNameTextYOffset = d.totNameTextYOffset
        MattMinimalFramesDB.petNameTextXOffset = d.petNameTextXOffset
        MattMinimalFramesDB.petNameTextYOffset = d.petNameTextYOffset
        MattMinimalFramesDB.focusNameTextXOffset = d.focusNameTextXOffset
        MattMinimalFramesDB.focusNameTextYOffset = d.focusNameTextYOffset
        MattMinimalFramesDB.hpTextSize = d.hpTextSize
        MattMinimalFramesDB.hpTextXOffset = d.hpTextXOffset
        MattMinimalFramesDB.hpTextYOffset = d.hpTextYOffset
        MattMinimalFramesDB.playerHPTextXOffset = d.playerHPTextXOffset
        MattMinimalFramesDB.playerHPTextYOffset = d.playerHPTextYOffset
        MattMinimalFramesDB.targetHPTextXOffset = d.targetHPTextXOffset
        MattMinimalFramesDB.targetHPTextYOffset = d.targetHPTextYOffset
        -- Power bar size
        MattMinimalFramesDB.powerBarWidth = d.powerBarWidth
        MattMinimalFramesDB.powerBarHeight = d.powerBarHeight
        -- Class resource bars (legacy scales + new layout keys)
        MattMinimalFramesDB.runeBarScale = d.runeBarScale
        MattMinimalFramesDB.holyPowerBarScale = d.holyPowerBarScale
        MattMinimalFramesDB.comboPointBarScale = d.comboPointBarScale
        MattMinimalFramesDB.soulShardBarScale = d.soulShardBarScale
        MattMinimalFramesDB.chiBarScale = d.chiBarScale
        MattMinimalFramesDB.arcaneChargeBarScale = d.arcaneChargeBarScale
        MattMinimalFramesDB.essenceBarScale = d.essenceBarScale
        MattMinimalFramesDB.runeBarWidth = d.runeBarWidth
        MattMinimalFramesDB.runeBarHeight = d.runeBarHeight
        MattMinimalFramesDB.runeBarSpacing = d.runeBarSpacing
        MattMinimalFramesDB.runeBarX = d.runeBarX
        MattMinimalFramesDB.runeBarY = d.runeBarY
        MattMinimalFramesDB.holyPowerBarWidth = d.holyPowerBarWidth
        MattMinimalFramesDB.holyPowerBarHeight = d.holyPowerBarHeight
        MattMinimalFramesDB.holyPowerBarSpacing = d.holyPowerBarSpacing
        MattMinimalFramesDB.holyPowerBarX = d.holyPowerBarX
        MattMinimalFramesDB.holyPowerBarY = d.holyPowerBarY
        MattMinimalFramesDB.comboPointBarWidth = d.comboPointBarWidth
        MattMinimalFramesDB.comboPointBarHeight = d.comboPointBarHeight
        MattMinimalFramesDB.comboPointBarSpacing = d.comboPointBarSpacing
        MattMinimalFramesDB.comboPointBarX = d.comboPointBarX
        MattMinimalFramesDB.comboPointBarY = d.comboPointBarY
        MattMinimalFramesDB.soulShardBarWidth = d.soulShardBarWidth
        MattMinimalFramesDB.soulShardBarHeight = d.soulShardBarHeight
        MattMinimalFramesDB.soulShardBarSpacing = d.soulShardBarSpacing
        MattMinimalFramesDB.soulShardBarX = d.soulShardBarX
        MattMinimalFramesDB.soulShardBarY = d.soulShardBarY
        MattMinimalFramesDB.chiBarWidth = d.chiBarWidth
        MattMinimalFramesDB.chiBarHeight = d.chiBarHeight
        MattMinimalFramesDB.chiBarSpacing = d.chiBarSpacing
        MattMinimalFramesDB.chiBarX = d.chiBarX
        MattMinimalFramesDB.chiBarY = d.chiBarY
        MattMinimalFramesDB.arcaneChargeBarWidth = d.arcaneChargeBarWidth
        MattMinimalFramesDB.arcaneChargeBarHeight = d.arcaneChargeBarHeight
        MattMinimalFramesDB.arcaneChargeBarSpacing = d.arcaneChargeBarSpacing
        MattMinimalFramesDB.arcaneChargeBarX = d.arcaneChargeBarX
        MattMinimalFramesDB.arcaneChargeBarY = d.arcaneChargeBarY
        MattMinimalFramesDB.essenceBarWidth = d.essenceBarWidth
        MattMinimalFramesDB.essenceBarHeight = d.essenceBarHeight
        MattMinimalFramesDB.essenceBarSpacing = d.essenceBarSpacing
        MattMinimalFramesDB.essenceBarX = d.essenceBarX
        MattMinimalFramesDB.essenceBarY = d.essenceBarY
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
    end

    local toolsResetScaleBtn = CreateFrame("Button", nil, rightCol, "BackdropTemplate")
    toolsResetScaleBtn:SetSize(176, 24)
    toolsResetScaleBtn:SetPoint("TOPLEFT", 12, -196)
    toolsResetScaleBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    toolsResetScaleBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    toolsResetScaleBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local toolsResetScaleBtnText = toolsResetScaleBtn:CreateFontString(nil, "OVERLAY")
    toolsResetScaleBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    toolsResetScaleBtnText:SetPoint("CENTER")
    toolsResetScaleBtnText:SetText("Reset Scale/Text")
    toolsResetScaleBtnText:SetTextColor(0.8, 0.8, 0.8)
    toolsResetScaleBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        toolsResetScaleBtnText:SetTextColor(1, 1, 1)
    end)
    toolsResetScaleBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        toolsResetScaleBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)
    toolsResetScaleBtn:SetScript("OnClick", function()
        ResetScaleAndTextToDefaults()
    end)

    local toolsResetAllBtn = CreateFrame("Button", nil, rightCol, "BackdropTemplate")
    toolsResetAllBtn:SetSize(176, 24)
    toolsResetAllBtn:SetPoint("TOPLEFT", 12, -224)
    toolsResetAllBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    toolsResetAllBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    toolsResetAllBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local toolsResetAllBtnText = toolsResetAllBtn:CreateFontString(nil, "OVERLAY")
    toolsResetAllBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    toolsResetAllBtnText:SetPoint("CENTER")
    toolsResetAllBtnText:SetText("Reset All")
    toolsResetAllBtnText:SetTextColor(0.8, 0.8, 0.8)
    toolsResetAllBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        toolsResetAllBtnText:SetTextColor(1, 0.3, 0.3)
    end)
    toolsResetAllBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        toolsResetAllBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)
    toolsResetAllBtn:SetScript("OnClick", function()
        if PlaySoundFile and IsUISoundsEnabled() then
            PlaySoundFile("Interface\\AddOns\\MattMinimalFrames\\Sounds\\are-you-sure-about-that.mp3", "Master")
        end
        StaticPopup_Show("MMF_RESET_ALL_WARNING")
    end)

    local infoDivider = rightCol:CreateTexture(nil, "ARTWORK")
    infoDivider:SetSize(176, 1)
    infoDivider:SetPoint("TOPLEFT", 12, -256)
    infoDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local toolsInfoTitle = rightCol:CreateFontString(nil, "OVERLAY")
    toolsInfoTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    toolsInfoTitle:SetPoint("TOPLEFT", 12, -268)
    toolsInfoTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    toolsInfoTitle:SetText("INFO")

    local infoText = rightCol:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    infoText:SetPoint("TOPLEFT", 12, -292)
    infoText:SetWidth(176)
    infoText:SetJustifyH("LEFT")
    infoText:SetSpacing(3)
    infoText:SetTextColor(0.6, 0.6, 0.6)
    local highlightColor = ACCENT_HEX_PREFIX
    infoText:SetText("Hold " .. highlightColor .. "SHIFT|r + drag frames to reposition.\n\nType " .. highlightColor .. "/mmf|r to open this panel.\n\nChanges to some checkboxes may require a UI reload.")

end
