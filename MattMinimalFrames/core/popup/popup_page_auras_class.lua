local Compat = _G.MMF_Compat or {}

function MMF_CreateAurasPowerSection(leftCol, popup, accentColor, createMinimalCheckbox, createMinimalSlider)
    local _, playerClass = UnitClass("player")
    local isComboClass = (playerClass == "ROGUE" or playerClass == "DRUID")
    local isTBCComboClass = Compat.IsTBC and isComboClass
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider

    -- LEFT COLUMN: Buffs & Debuffs
    ---------------------------------------------------
    local aurasTitle = leftCol:CreateFontString(nil, "OVERLAY")
    aurasTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    aurasTitle:SetPoint("TOPLEFT", 12, -12)
    aurasTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    aurasTitle:SetText("TARGET AURA POSITION")

    local buffsCheck = CreateMinimalCheckbox(leftCol, "Buffs", 12, -32, "showBuffs", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local debuffsCheck = CreateMinimalCheckbox(leftCol, "Debuffs", 112, -32, "showDebuffs", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local auraTypeOptions = {
        { value = "buff", label = "Target Buffs" },
        { value = "debuff", label = "Target Debuffs" },
    }
    MattMinimalFramesDB.auraOffsetType = MattMinimalFramesDB.auraOffsetType or "buff"
    if MattMinimalFramesDB.auraOffsetType ~= "buff" and MattMinimalFramesDB.auraOffsetType ~= "debuff" then
        MattMinimalFramesDB.auraOffsetType = "buff"
    end

    local SyncAuraOffsetSliders = function() end

    local auraTypeDropdown = MMF_CreateMinimalDropdown(leftCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -56,
        width = 200,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = 122,
        visibleRows = #auraTypeOptions,
        label = "Aura Type",
        options = auraTypeOptions,
        getValue = function()
            return MattMinimalFramesDB.auraOffsetType
        end,
        onSelect = function(value)
            MattMinimalFramesDB.auraOffsetType = value
            SyncAuraOffsetSliders()
        end,
    })

    local function GetAuraOffsetKeys()
        if MattMinimalFramesDB.auraOffsetType == "debuff" then
            return "debuffXOffset", "debuffYOffset", 3, 27
        end
        return "buffXOffset", "buffYOffset", -2, -64
    end

    local auraXSlider = CreateMinimalSlider(leftCol, "X Offset", 12, -80, 200, "__tempAuraOffsetX", -200, 200, 1, -2, function(value)
        local xKey, yKey = GetAuraOffsetKeys()
        MattMinimalFramesDB[xKey] = value
        if xKey == "debuffXOffset" then
            if MMF_UpdateDebuffPosition then
                MMF_UpdateDebuffPosition(value, MattMinimalFramesDB[yKey] or 27)
            end
        else
            if MMF_UpdateBuffPosition then
                MMF_UpdateBuffPosition(value, MattMinimalFramesDB[yKey] or -64)
            end
        end
    end, true)

    local auraYSlider = CreateMinimalSlider(leftCol, "Y Offset", 12, -104, 200, "__tempAuraOffsetY", -200, 200, 1, -64, function(value)
        local xKey, yKey = GetAuraOffsetKeys()
        MattMinimalFramesDB[yKey] = value
        if yKey == "debuffYOffset" then
            if MMF_UpdateDebuffPosition then
                MMF_UpdateDebuffPosition(MattMinimalFramesDB[xKey] or 3, value)
            end
        else
            if MMF_UpdateBuffPosition then
                MMF_UpdateBuffPosition(MattMinimalFramesDB[xKey] or -2, value)
            end
        end
    end, true)

    SyncAuraOffsetSliders = function()
        local xKey, yKey, defaultX, defaultY = GetAuraOffsetKeys()
        auraXSlider.slider:SetValue(MattMinimalFramesDB[xKey] or defaultX)
        auraYSlider.slider:SetValue(MattMinimalFramesDB[yKey] or defaultY)
    end
    SyncAuraOffsetSliders()

    -- Divider
    local divider1 = leftCol:CreateTexture(nil, "ARTWORK")
    divider1:SetSize(200, 1)
    divider1:SetPoint("TOPLEFT", 12, -132)
    divider1:SetColorTexture(0.12, 0.12, 0.15, 1)

    ---------------------------------------------------
    -- AURA APPEARANCE (Left Column)
    ---------------------------------------------------
    local auraTitle = leftCol:CreateFontString(nil, "OVERLAY")
    auraTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    auraTitle:SetPoint("TOPLEFT", 12, -144)
    auraTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    auraTitle:SetText("TARGET AURA APPEARANCE")

    local auraIconSlider = CreateMinimalSlider(leftCol, "Icon Size", 12, -168, 200, "auraIconSize", 12, 40, 1, 18, function(value)
        if MMF_UpdateAuraIconSize then
            MMF_UpdateAuraIconSize(value)
        end
    end, true)

    local auraTextSlider = CreateMinimalSlider(leftCol, "Stack Text", 12, -192, 200, "auraTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateAuraTextScale then
            MMF_UpdateAuraTextScale(value)
        end
    end, false)

    local timerTextSlider = CreateMinimalSlider(leftCol, "Timer Text", 12, -216, 200, "timerTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateTimerTextScale then
            MMF_UpdateTimerTextScale(value)
        end
    end, false)

    -- Divider
    local divider4 = leftCol:CreateTexture(nil, "ARTWORK")
    divider4:SetSize(200, 1)
    divider4:SetPoint("TOPLEFT", 12, -244)
    divider4:SetColorTexture(0.12, 0.12, 0.15, 1)

    local generalTitle = leftCol:CreateFontString(nil, "OVERLAY")
    generalTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    generalTitle:SetPoint("TOPLEFT", 12, -256)
    generalTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    generalTitle:SetText("RESOURCES")

    local playerPowerCheck = CreateMinimalCheckbox(leftCol, "Player Power Bar", 12, -276, "showPlayerPowerBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local targetPowerCheck = CreateMinimalCheckbox(leftCol, "Target Power Bar", 12, -300, "showTargetPowerBar", false, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local widthSliderY = -324
    local heightSliderY = -348

    if isTBCComboClass then
        local comboDivider = leftCol:CreateTexture(nil, "ARTWORK")
        comboDivider:SetSize(200, 1)
        comboDivider:SetPoint("TOPLEFT", 12, -376)
        comboDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

        local comboTitle = leftCol:CreateFontString(nil, "OVERLAY")
        comboTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        comboTitle:SetPoint("TOPLEFT", 12, -388)
        comboTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
        comboTitle:SetText("COMBO POINTS")

        CreateMinimalCheckbox(leftCol, "Enable Combo Point Bar", 12, -408, "showComboPointBar", true, function(checked)
            if checked then
                if MMF_InitializeClassResources then
                    MMF_InitializeClassResources()
                end
            else
                if _G.MMF_ComboPointBar then
                    _G.MMF_ComboPointBar:Hide()
                end
            end
        end)

        CreateMinimalSlider(leftCol, "Point Width", 12, -432, 200, "comboPointBarWidth", 6, 80, 1, 30, function()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout("comboPointBar")
            end
        end, true)

        CreateMinimalSlider(leftCol, "Point Height", 12, -456, 200, "comboPointBarHeight", 4, 30, 1, 10, function()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout("comboPointBar")
            end
        end, true)
    end

    local powerBarWidthSlider = CreateMinimalSlider(leftCol, "Width", 12, widthSliderY, 200, "powerBarWidth", 30, 250, 1, 73, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.powerBarHeight or 5)
        end
    end, true)

    local powerBarHeightSlider = CreateMinimalSlider(leftCol, "Height", 12, heightSliderY, 200, "powerBarHeight", 3, 15, 1, 5, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.powerBarWidth or 73, value)
        end
    end, true)

    MattMinimalFramesDB.__tempAuraOffsetX = nil
    MattMinimalFramesDB.__tempAuraOffsetY = nil

    ---------------------------------------------------
    return {
        auraTypeList = auraTypeDropdown.list,
    }
end

function MMF_CreateCurrentClassSection(middleCol, accentColor, createMinimalCheckbox, createMinimalSlider, updatePlayerIconModeButtonText, getCurrentPlayerIconModeValue)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider
    local UpdatePlayerIconModeButtonText = updatePlayerIconModeButtonText or function() end
    local GetCurrentPlayerIconModeValue = getCurrentPlayerIconModeValue or function() return "off" end

    -- MIDDLE COLUMN: Current Class
    ---------------------------------------------------
    local classBarTitle = middleCol:CreateFontString(nil, "OVERLAY")
    classBarTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    classBarTitle:SetPoint("TOPLEFT", 12, -12)
    classBarTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    classBarTitle:SetText("CURRENT CLASS")

    local classCfg = MMF_GetCurrentClassBarConfig and MMF_GetCurrentClassBarConfig() or nil
    if classCfg then
        local classColor = classCfg.classColor or {0.9, 0.9, 0.9}
        local currentClassTitle = middleCol:CreateFontString(nil, "OVERLAY")
        currentClassTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 14, "OUTLINE")
        currentClassTitle:SetPoint("TOPLEFT", 12, -36)
        currentClassTitle:SetTextColor(classColor[1], classColor[2], classColor[3])
        currentClassTitle:SetText(classCfg.classLabel or "Unknown")

        local classHelp = middleCol:CreateFontString(nil, "OVERLAY")
        classHelp:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        classHelp:SetPoint("TOPLEFT", 12, -56)
        classHelp:SetTextColor(0.65, 0.65, 0.7)
        classHelp:SetText("Configure your active class resource bar.")

        local classDivider = middleCol:CreateTexture(nil, "ARTWORK")
        classDivider:SetSize(200, 1)
        classDivider:SetPoint("TOPLEFT", 12, -72)
        classDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

        local classShowCheck = CreateMinimalCheckbox(middleCol, classCfg.showLabel or "Show Class Resource Bar", 12, -92, classCfg.showKey, true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)

        local layoutTitle = middleCol:CreateFontString(nil, "OVERLAY")
        layoutTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        layoutTitle:SetPoint("TOPLEFT", 12, -148)
        layoutTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
        layoutTitle:SetText("RESOURCE LAYOUT")

        local prefix = classCfg.prefix
        local d = MattMinimalFrames_Defaults or {}
        local widthKey = prefix .. "Width"
        local heightKey = prefix .. "Height"
        local spacingKey = prefix .. "Spacing"
        local xKey = prefix .. "X"
        local yKey = prefix .. "Y"

        local function ApplyCurrentClassLayout()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout(prefix)
            end
        end

        local resourceWidthSlider = CreateMinimalSlider(middleCol, "Point Width", 12, -172, 200, widthKey, 6, 80, 1, d[widthKey] or 30, function()
            ApplyCurrentClassLayout()
        end, true)

        local resourceHeightSlider = CreateMinimalSlider(middleCol, "Point Height", 12, -196, 200, heightKey, 4, 30, 1, d[heightKey] or 10, function()
            ApplyCurrentClassLayout()
        end, true)

        local resourceSpacingSlider = CreateMinimalSlider(middleCol, "Spacing", 12, -220, 200, spacingKey, 0, 20, 1, d[spacingKey] or 4, function()
            ApplyCurrentClassLayout()
        end, true)

        local layoutDivider = middleCol:CreateTexture(nil, "ARTWORK")
        layoutDivider:SetSize(200, 1)
        layoutDivider:SetPoint("TOPLEFT", 12, -248)
        layoutDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

        local positionTitle = middleCol:CreateFontString(nil, "OVERLAY")
        positionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        positionTitle:SetPoint("TOPLEFT", 12, -260)
        positionTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
        positionTitle:SetText("POSITION")

        local resourceXSlider = CreateMinimalSlider(middleCol, "X Offset", 12, -284, 200, xKey, -800, 800, 1, d[xKey] or 0, function()
            ApplyCurrentClassLayout()
        end, true)

        local resourceYSlider = CreateMinimalSlider(middleCol, "Y Offset", 12, -308, 200, yKey, -800, 800, 1, d[yKey] or -50, function()
            ApplyCurrentClassLayout()
        end, true)

        local hintText = middleCol:CreateFontString(nil, "OVERLAY")
        hintText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        hintText:SetPoint("TOPLEFT", 12, -336)
        hintText:SetTextColor(0.6, 0.6, 0.6)
        hintText:SetText("Tip: Hold SHIFT and drag the bar to move it too.")

        if classCfg.note and classCfg.note ~= "" then
            local classNote = middleCol:CreateFontString(nil, "OVERLAY")
            classNote:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
            classNote:SetPoint("TOPLEFT", 12, -352)
            classNote:SetWidth(200)
            classNote:SetJustifyH("LEFT")
            classNote:SetTextColor(0.6, 0.6, 0.6)
            classNote:SetText(classCfg.note)
        end

        local resetY = (classCfg.note and classCfg.note ~= "") and -384 or -368
        local resetClassBtn = CreateFrame("Button", nil, middleCol, "BackdropTemplate")
        resetClassBtn:SetSize(200, 22)
        resetClassBtn:SetPoint("TOPLEFT", 12, resetY)
        resetClassBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        resetClassBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
        resetClassBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)

        local resetClassBtnText = resetClassBtn:CreateFontString(nil, "OVERLAY")
        resetClassBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        resetClassBtnText:SetPoint("CENTER")
        resetClassBtnText:SetText("Reset Current Class")
        resetClassBtnText:SetTextColor(0.8, 0.8, 0.8)

        resetClassBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.15, 1)
            resetClassBtnText:SetTextColor(1, 1, 1)
        end)
        resetClassBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.08, 0.08, 0.1, 1)
            resetClassBtnText:SetTextColor(0.8, 0.8, 0.8)
        end)
        resetClassBtn:SetScript("OnClick", function()
            _G.MMF_OnConfirmResetCurrentClass = function()
                local needsReload = false
                if MMF_ResetCurrentClassBarSettings then
                    needsReload = MMF_ResetCurrentClassBarSettings()
                end

                if classShowCheck and classShowCheck.checkbox then
                    local checked = MattMinimalFramesDB[classCfg.showKey]
                    classShowCheck.checkbox:SetChecked(checked)
                    classShowCheck.checkbox.check:SetShown(checked)
                end
                UpdatePlayerIconModeButtonText()

                resourceWidthSlider.slider:SetValue(MattMinimalFramesDB[widthKey] or d[widthKey] or 30)
                resourceHeightSlider.slider:SetValue(MattMinimalFramesDB[heightKey] or d[heightKey] or 10)
                resourceSpacingSlider.slider:SetValue(MattMinimalFramesDB[spacingKey] or d[spacingKey] or 4)
                resourceXSlider.slider:SetValue(MattMinimalFramesDB[xKey] or d[xKey] or 0)
                resourceYSlider.slider:SetValue(MattMinimalFramesDB[yKey] or d[yKey] or -50)
                if MMF_UpdatePlayerClassIconVisibility then
                    MMF_UpdatePlayerClassIconVisibility(GetCurrentPlayerIconModeValue())
                end

                if needsReload then
                    StaticPopup_Show("MMF_RELOADUI")
                end
            end
            StaticPopup_Show("MMF_RESET_CURRENT_CLASS_WARNING")
        end)
    else
        local unsupported = middleCol:CreateFontString(nil, "OVERLAY")
        unsupported:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        unsupported:SetPoint("TOPLEFT", 12, -92)
        unsupported:SetTextColor(0.7, 0.7, 0.7)
        unsupported:SetText("No class resource options for this class.")
    end

    ---------------------------------------------------
end
