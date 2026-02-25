local Compat = _G.MMF_Compat or {}

function MMF_CreateAurasPowerSection(leftCol, popup, accentColor, createMinimalCheckbox, createMinimalSlider)
    local _, playerClass = UnitClass("player")
    local isPlayerDruid = (playerClass == "DRUID")
    local isComboClass = (playerClass == "ROGUE" or playerClass == "DRUID")
    local isTBCComboClass = Compat.IsTBC and isComboClass
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider
    local AURA_COL_X = 12
    local AURA_COL_WIDTH = 280
    local RESOURCE_COL_X = AURA_COL_X + AURA_COL_WIDTH + 24

    local function RefreshPowerFrames()
        if MMF_UpdatePowerBarVisibility then
            MMF_UpdatePowerBarVisibility()
        end
        if MMF_RequestUnitUpdate then
            MMF_RequestUnitUpdate("player")
            MMF_RequestUnitUpdate("target")
            return
        end
        if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local p = MMF_GetFrameForUnit("player")
            if p then MMF_UpdateUnitFrame(p) end
            local t = MMF_GetFrameForUnit("target")
            if t then MMF_UpdateUnitFrame(t) end
        end
    end

    -- LEFT COLUMN: Buffs & Debuffs
    ---------------------------------------------------
    local aurasTitle = leftCol:CreateFontString(nil, "OVERLAY")
    aurasTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    aurasTitle:SetPoint("TOPLEFT", AURA_COL_X, -12)
    aurasTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    aurasTitle:SetText("TARGET AURA POSITION")

    local buffsCheck = CreateMinimalCheckbox(leftCol, "Buffs", AURA_COL_X, -32, "showBuffs", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local debuffsCheck = CreateMinimalCheckbox(leftCol, "Debuffs", AURA_COL_X + 120, -32, "showDebuffs", true, function()
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
        x = AURA_COL_X,
        y = -56,
        width = AURA_COL_WIDTH,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = AURA_COL_WIDTH - 78,
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

    local auraXSlider = CreateMinimalSlider(leftCol, "X Offset", AURA_COL_X, -80, AURA_COL_WIDTH, "__tempAuraOffsetX", -200, 200, 1, -2, function(value)
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

    local auraYSlider = CreateMinimalSlider(leftCol, "Y Offset", AURA_COL_X, -104, AURA_COL_WIDTH, "__tempAuraOffsetY", -200, 200, 1, -64, function(value)
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
    divider1:SetSize(AURA_COL_WIDTH, 1)
    divider1:SetPoint("TOPLEFT", AURA_COL_X, -132)
    divider1:SetColorTexture(0.12, 0.12, 0.15, 1)

    ---------------------------------------------------
    -- AURA APPEARANCE (Left Column)
    ---------------------------------------------------
    local auraTitle = leftCol:CreateFontString(nil, "OVERLAY")
    auraTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    auraTitle:SetPoint("TOPLEFT", AURA_COL_X, -144)
    auraTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    auraTitle:SetText("TARGET AURA APPEARANCE")

    local auraIconSlider = CreateMinimalSlider(leftCol, "Icon Size", AURA_COL_X, -168, AURA_COL_WIDTH, "auraIconSize", 12, 40, 1, 18, function(value)
        if MMF_UpdateAuraIconSize then
            MMF_UpdateAuraIconSize(value)
        end
    end, true)

    local auraTextSlider = CreateMinimalSlider(leftCol, "Stack Text", AURA_COL_X, -192, AURA_COL_WIDTH, "auraTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateAuraTextScale then
            MMF_UpdateAuraTextScale(value)
        end
    end, false)

    local timerTextSlider = CreateMinimalSlider(leftCol, "Timer Text", AURA_COL_X, -216, AURA_COL_WIDTH, "timerTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateTimerTextScale then
            MMF_UpdateTimerTextScale(value)
        end
    end, false)

    -- Divider
    local divider4 = leftCol:CreateTexture(nil, "ARTWORK")
    divider4:SetSize(AURA_COL_WIDTH, 1)
    divider4:SetPoint("TOPLEFT", AURA_COL_X, -244)
    divider4:SetColorTexture(0.12, 0.12, 0.15, 1)

    local generalTitle = leftCol:CreateFontString(nil, "OVERLAY")
    generalTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    local columnDivider = leftCol:CreateTexture(nil, "ARTWORK")
    columnDivider:SetPoint("TOPLEFT", RESOURCE_COL_X - 16, -12)
    columnDivider:SetPoint("BOTTOMLEFT", RESOURCE_COL_X - 16, 12)
    columnDivider:SetWidth(1)
    columnDivider:SetColorTexture(0.35, 0.35, 0.4, 1)

    generalTitle:SetPoint("TOPLEFT", RESOURCE_COL_X, -12)
    generalTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    generalTitle:SetText("RESOURCES")

    local resourceHint = leftCol:CreateFontString(nil, "OVERLAY")
    resourceHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    resourceHint:SetPoint("TOPLEFT", RESOURCE_COL_X, -28)
    resourceHint:SetTextColor(0.6, 0.6, 0.6)
    resourceHint:SetText("Tip: Hold Shift and Click+Drag power bar or power text to move it.")

    local playerTitle = leftCol:CreateFontString(nil, "OVERLAY")
    playerTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    playerTitle:SetPoint("TOPLEFT", RESOURCE_COL_X, -52)
    playerTitle:SetTextColor(0.85, 0.85, 0.9)
    playerTitle:SetText("PLAYER")

    local playerColorPowerTextCheck = nil
    local targetColorPowerTextCheck = nil
    local playerPercentPowerTextCheck = nil
    local playerDruidManaPowerTextCheck = nil
    local targetPercentPowerTextCheck = nil
    if MattMinimalFramesDB.showPlayerPowerPercentText == nil then
        MattMinimalFramesDB.showPlayerPowerPercentText = (MattMinimalFramesDB.showPowerPercentText == true)
    end
    if MattMinimalFramesDB.showTargetPowerPercentText == nil then
        MattMinimalFramesDB.showTargetPowerPercentText = (MattMinimalFramesDB.showPowerPercentText == true)
    end
    local function SetDependentCheckboxState(container, enabled)
        if not container then return end
        local checkbox = container.checkbox
        if checkbox then
            checkbox:EnableMouse(enabled)
            checkbox:SetAlpha(enabled and 1 or 0.45)
            if checkbox.check then
                checkbox.check:SetAlpha(enabled and 1 or 0.35)
            end
        end
        container:SetAlpha(enabled and 1 or 0.55)
    end
    local function UpdatePowerTextDependencies()
        local playerTextEnabled = (MattMinimalFramesDB.showPlayerPowerText == true or MattMinimalFramesDB.showPlayerPowerText == 1)
        local targetTextEnabled = (MattMinimalFramesDB.showTargetPowerText == true or MattMinimalFramesDB.showTargetPowerText == 1)
        SetDependentCheckboxState(playerColorPowerTextCheck, playerTextEnabled)
        SetDependentCheckboxState(playerPercentPowerTextCheck, playerTextEnabled)
        SetDependentCheckboxState(playerDruidManaPowerTextCheck, playerTextEnabled and isPlayerDruid)
        SetDependentCheckboxState(targetColorPowerTextCheck, targetTextEnabled)
        SetDependentCheckboxState(targetPercentPowerTextCheck, targetTextEnabled)
    end
    MMF_RefreshPowerTextOptionStates = UpdatePowerTextDependencies

    CreateMinimalCheckbox(leftCol, "Power Bar", RESOURCE_COL_X, -72, "showPlayerPowerBar", true, function()
        RefreshPowerFrames()
    end)

    CreateMinimalCheckbox(leftCol, "Power Text", RESOURCE_COL_X, -96, "showPlayerPowerText", false, function()
        RefreshPowerFrames()
        UpdatePowerTextDependencies()
    end)

    playerColorPowerTextCheck = CreateMinimalCheckbox(leftCol, "Color Text by Resource", RESOURCE_COL_X, -120, "colorPlayerPowerTextByResource", false, function()
        RefreshPowerFrames()
    end)

    playerPercentPowerTextCheck = CreateMinimalCheckbox(leftCol, "Power Text: Percent", RESOURCE_COL_X, -144, "showPlayerPowerPercentText", false, function()
        RefreshPowerFrames()
    end)

    local playerTextScaleY = -168
    local playerWidthY = -192
    local playerHeightY = -216
    local targetDividerY = -244
    local targetTitleY = -256
    local targetPowerBarY = -276
    local targetPowerTextY = -300
    local targetColorTextY = -324
    local targetPercentTextY = -348
    local targetTextScaleY = -372
    local targetWidthY = -396
    local targetHeightY = -420

    if isPlayerDruid then
        playerDruidManaPowerTextCheck = CreateMinimalCheckbox(leftCol, "Mana Resource Only", RESOURCE_COL_X, -168, "showDruidManaPowerText", false, function()
            RefreshPowerFrames()
        end)
        playerTextScaleY = -192
        playerWidthY = -216
        playerHeightY = -240
        targetDividerY = -268
        targetTitleY = -280
        targetPowerBarY = -300
        targetPowerTextY = -324
        targetColorTextY = -348
        targetPercentTextY = -372
        targetTextScaleY = -396
        targetWidthY = -420
        targetHeightY = -444
    end

    CreateMinimalSlider(leftCol, "Text Scale", RESOURCE_COL_X, playerTextScaleY, 200, "playerPowerTextScale", 0.5, 2.0, 0.05, 1.0, function()
        RefreshPowerFrames()
    end, false)

    CreateMinimalSlider(leftCol, "Width", RESOURCE_COL_X, playerWidthY, 200, "playerPowerBarWidth", 30, 250, 1, 73, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.playerPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5, "player")
        end
    end, true)

    CreateMinimalSlider(leftCol, "Height", RESOURCE_COL_X, playerHeightY, 200, "playerPowerBarHeight", 3, 15, 1, 5, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.playerPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73, value, "player")
        end
    end, true)

    local targetDivider = leftCol:CreateTexture(nil, "ARTWORK")
    targetDivider:SetSize(200, 1)
    targetDivider:SetPoint("TOPLEFT", RESOURCE_COL_X, targetDividerY)
    targetDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local targetTitle = leftCol:CreateFontString(nil, "OVERLAY")
    targetTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    targetTitle:SetPoint("TOPLEFT", RESOURCE_COL_X, targetTitleY)
    targetTitle:SetTextColor(0.85, 0.85, 0.9)
    targetTitle:SetText("TARGET")

    CreateMinimalCheckbox(leftCol, "Power Bar", RESOURCE_COL_X, targetPowerBarY, "showTargetPowerBar", false, function()
        RefreshPowerFrames()
    end)

    CreateMinimalCheckbox(leftCol, "Power Text", RESOURCE_COL_X, targetPowerTextY, "showTargetPowerText", false, function()
        RefreshPowerFrames()
        UpdatePowerTextDependencies()
    end)

    targetColorPowerTextCheck = CreateMinimalCheckbox(leftCol, "Color Text by Resource", RESOURCE_COL_X, targetColorTextY, "colorTargetPowerTextByResource", false, function()
        RefreshPowerFrames()
    end)
    targetPercentPowerTextCheck = CreateMinimalCheckbox(leftCol, "Power Text: Percent", RESOURCE_COL_X, targetPercentTextY, "showTargetPowerPercentText", false, function()
        RefreshPowerFrames()
    end)

    UpdatePowerTextDependencies()

    CreateMinimalSlider(leftCol, "Text Scale", RESOURCE_COL_X, targetTextScaleY, 200, "targetPowerTextScale", 0.5, 2.0, 0.05, 1.0, function()
        RefreshPowerFrames()
    end, false)

    CreateMinimalSlider(leftCol, "Width", RESOURCE_COL_X, targetWidthY, 200, "targetPowerBarWidth", 30, 250, 1, 73, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.targetPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5, "target")
        end
    end, true)

    CreateMinimalSlider(leftCol, "Height", RESOURCE_COL_X, targetHeightY, 200, "targetPowerBarHeight", 3, 15, 1, 5, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.targetPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73, value, "target")
        end
    end, true)

    if isTBCComboClass then
        local comboDivider = leftCol:CreateTexture(nil, "ARTWORK")
        comboDivider:SetSize(AURA_COL_WIDTH, 1)
        comboDivider:SetPoint("TOPLEFT", AURA_COL_X, -576)
        comboDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

        local comboTitle = leftCol:CreateFontString(nil, "OVERLAY")
        comboTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        comboTitle:SetPoint("TOPLEFT", AURA_COL_X, -588)
        comboTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
        comboTitle:SetText("COMBO POINTS")

        CreateMinimalCheckbox(leftCol, "Enable Combo Point Bar", AURA_COL_X, -608, "showComboPointBar", true, function(checked)
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

        CreateMinimalSlider(leftCol, "Point Width", AURA_COL_X, -632, AURA_COL_WIDTH, "comboPointBarWidth", 6, 80, 1, 30, function()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout("comboPointBar")
            end
        end, true)

        CreateMinimalSlider(leftCol, "Point Height", AURA_COL_X, -656, AURA_COL_WIDTH, "comboPointBarHeight", 4, 30, 1, 10, function()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout("comboPointBar")
            end
        end, true)
    end

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
        local classSoundsCheck = nil
        local classSoundsEnabled = (classCfg.classSoundsKey and classCfg.classSoundsLabel) and true or false
        local classSoundsLabel = classSoundsEnabled and classCfg.classSoundsLabel or "Class Sounds (Coming Soon)"
        local classSoundsKey = classSoundsEnabled and classCfg.classSoundsKey or "__mmfClassSoundsComingSoon"
        classSoundsCheck = CreateMinimalCheckbox(middleCol, classSoundsLabel, 12, -116, classSoundsKey, false, nil)
        if not classSoundsEnabled and classSoundsCheck and classSoundsCheck.checkbox then
            classSoundsCheck:SetAlpha(0.55)
            classSoundsCheck.checkbox:EnableMouse(false)
            classSoundsCheck.checkbox:SetChecked(false)
            if classSoundsCheck.checkbox.check then
                classSoundsCheck.checkbox.check:SetShown(false)
                classSoundsCheck.checkbox.check:SetAlpha(0.35)
            end
        end

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
                if classSoundsEnabled and classSoundsCheck and classSoundsCheck.checkbox and classCfg.classSoundsKey then
                    local checked = MattMinimalFramesDB[classCfg.classSoundsKey]
                    classSoundsCheck.checkbox:SetChecked(checked)
                    classSoundsCheck.checkbox.check:SetShown(checked)
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
