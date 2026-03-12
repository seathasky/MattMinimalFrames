local function MMF_SetupUnitFramesHeader(unitFramesCol, accentColor, createSubTabBar, requestScrollRefresh)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateSubTabBar = createSubTabBar or MMF_CreateSubTabBar
    local RequestScrollRefresh = requestScrollRefresh or function() end

    local sectionCard = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
    sectionCard:SetPoint("TOPLEFT", 12, -60)
    sectionCard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    sectionCard:SetBackdropColor(0.03, 0.05, 0.07, 0.98)
    sectionCard:SetBackdropBorderColor(0.12, 0.16, 0.18, 1)

    local sectionCardTitle = sectionCard:CreateFontString(nil, "OVERLAY")
    sectionCardTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 14, "")
    sectionCardTitle:SetPoint("TOPLEFT", 18, -16)
    sectionCardTitle:SetTextColor(MMF_GetPopupSectionTitleColor())

    local sectionCardSubtitle = sectionCard:CreateFontString(nil, "OVERLAY")
    sectionCardSubtitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    sectionCardSubtitle:SetPoint("TOPLEFT", sectionCardTitle, "BOTTOMLEFT", 0, -6)
    sectionCardSubtitle:SetTextColor(0.62, 0.67, 0.71)

    local sectionDivider = sectionCard:CreateTexture(nil, "ARTWORK")
    sectionDivider:SetPoint("TOPLEFT", 18, -52)
    sectionDivider:SetPoint("TOPRIGHT", -18, -52)
    sectionDivider:SetHeight(1)
    sectionDivider:SetColorTexture(0.14, 0.18, 0.2, 1)

    local sectionViewport = CreateFrame("Frame", nil, sectionCard)
    sectionViewport:SetPoint("TOPLEFT", 18, -62)
    sectionViewport:SetClipsChildren(true)

    local sectionViewportMaskTop = sectionViewport:CreateTexture(nil, "OVERLAY")
    sectionViewportMaskTop:SetPoint("TOPLEFT", 0, 0)
    sectionViewportMaskTop:SetPoint("TOPRIGHT", 0, 0)
    sectionViewportMaskTop:SetColorTexture(0.03, 0.05, 0.07, 1)
    sectionViewportMaskTop:Hide()

    local sectionViewportMaskBottom = sectionViewport:CreateTexture(nil, "OVERLAY")
    sectionViewportMaskBottom:SetPoint("BOTTOMLEFT", 0, 0)
    sectionViewportMaskBottom:SetPoint("BOTTOMRIGHT", 0, 0)
    sectionViewportMaskBottom:SetColorTexture(0.03, 0.05, 0.07, 1)
    sectionViewportMaskBottom:Hide()

    local sectionRoots = {}

    local sectionDefs = {
        { label = "Layout", subtitle = "Scale and frame sizing controls.", x = 0, y = 8, width = 288, height = 122 },
        { label = "Text", subtitle = "Font sizes, truncation, HP text format, and name behavior.", x = 0, y = 98, width = 288, height = 300, maskTop = 12 },
        { label = "Visibility", subtitle = "Choose when name, HP text, and boss frames are shown.", x = 0, y = 410, width = 288, height = 124 },
        { label = "Offsets", subtitle = "Adjust text positions for each supported unit.", x = 0, y = 544, width = 288, height = 174 },
        { label = "Cast Bars", subtitle = "Cast bar settings.", x = 300, y = 112, width = 288, height = 170 },
        { label = "OOC", subtitle = "Out-of-combat visibility and fade rules.", x = 300, y = 258, width = 288, height = 184 },
        { label = "Appearance", subtitle = "Textures, fonts, and frame colors.", x = 588, y = 6, width = 300, height = 480 },
        { label = "Icons", subtitle = "Icon positions, sizes, and target markers.", x = 588, y = 236, width = 300, height = 266 },
        { label = "Overlays", subtitle = "Heal prediction and absorb overlay settings.", x = 588, y = 512, width = 300, height = 102 },
    }

    local activeSectionIndex = tonumber(MattMinimalFramesDB.unitFramesSubTab) or 1
    if activeSectionIndex < 1 or activeSectionIndex > #sectionDefs then
        activeSectionIndex = 1
    end

    -- Compute a fixed card size from the largest section so every sub-tab
    -- renders inside the same box - no resize flash when switching tabs.
    local fixedCardW, fixedCardH = 360, 0
    for _, def in ipairs(sectionDefs) do
        local w = math.max(360, (def.width or 0) + 36)
        local h = (def.height or 0) + 82
        if w > fixedCardW then fixedCardW = w end
        if h > fixedCardH then fixedCardH = h end
    end
    local fixedPageH = fixedCardH + 100   -- card height + header / padding

    sectionCard:SetSize(fixedCardW, fixedCardH)
    unitFramesCol:SetHeight(fixedPageH)

    for index, def in ipairs(sectionDefs) do
        local sectionRoot = CreateFrame("Frame", nil, sectionViewport)
        sectionRoot:SetPoint("TOPLEFT", sectionViewport, "TOPLEFT", -def.x, def.y)
        sectionRoot:SetSize(840, 760)
        sectionRoot:Hide()
        sectionRoots[index] = sectionRoot
    end

    local sectionChangeHandler = nil
    local applyGeneration = 0

    local function ApplySection(index)
        activeSectionIndex = index
        MattMinimalFramesDB.unitFramesSubTab = index
        local section = sectionDefs[index]
        if not section then
            return
        end
        sectionCardTitle:SetText(section.label or "")
        sectionCardSubtitle:SetText(section.subtitle or "")
        sectionViewport:SetSize(section.width, section.height)
        for sectionIndex = 1, #sectionDefs do
            local root = sectionRoots[sectionIndex]
            if root then
                root:SetShown(sectionIndex == index)
            end
        end
        local activeRoot = sectionRoots[index]
        if activeRoot and MMF_RefreshPopupWidgetTree then
            MMF_RefreshPopupWidgetTree(activeRoot)
        end
        if section.maskTop and section.maskTop > 0 then
            sectionViewportMaskTop:SetHeight(section.maskTop)
            sectionViewportMaskTop:Show()
        else
            sectionViewportMaskTop:Hide()
        end
        if section.maskBottom and section.maskBottom > 0 then
            sectionViewportMaskBottom:SetHeight(section.maskBottom)
            sectionViewportMaskBottom:Show()
        else
            sectionViewportMaskBottom:Hide()
        end
        if sectionChangeHandler then
            sectionChangeHandler(index, section)
        end
        RequestScrollRefresh()
    end

    local unitFramesSubTabs = CreateSubTabBar and CreateSubTabBar(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -22,
        width = 640,
        height = 28,
        spacing = 6,
        minButtonWidth = 58,
        horizontalPadding = 12,
        fontSize = 10,
        tabs = sectionDefs,
        defaultIndex = activeSectionIndex,
        onSelect = function(index)
            ApplySection(index)
        end,
    }) or nil

    return {
        contentRoot = sectionRoots[1],
        sectionRoots = sectionRoots,
        SetSectionChangeHandler = function(handler)
            sectionChangeHandler = handler
        end,
        ApplyInitialSection = function()
            applyGeneration = applyGeneration + 1
            local currentGeneration = applyGeneration
            if unitFramesSubTabs and unitFramesSubTabs.SetActive then
                unitFramesSubTabs.SetActive(activeSectionIndex, true)
            end
            ApplySection(activeSectionIndex)
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if currentGeneration ~= applyGeneration then
                        return
                    end
                    ApplySection(activeSectionIndex)
                end)
            end
        end,
    }
end

function MMF_CreateUnitFramesSection(unitFramesCol, popup, accentColor, createMinimalCheckbox, createMinimalSlider, getCurrentPlayerIconModeValue, getCurrentTargetIconModeValue, createSubTabBar, requestScrollRefresh)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider
    local GetCurrentPlayerIconModeValue = getCurrentPlayerIconModeValue or function() return "off" end
    local GetCurrentTargetIconModeValue = getCurrentTargetIconModeValue or function() return "off" end

    local dropdownLists = {}
    local UpdatePlayerIconModeButtonTextImpl = function() end
    local function UpdatePlayerIconModeButtonText()
        UpdatePlayerIconModeButtonTextImpl()
    end
    local rightSection = {}

    local headerState = MMF_SetupUnitFramesHeader(unitFramesCol, ACCENT_COLOR, createSubTabBar, requestScrollRefresh)
    local sectionRoots = (headerState and headerState.sectionRoots) or {}
    local fallbackRoot = (headerState and headerState.contentRoot) or unitFramesCol

    local LEFT_COL_X = 12
    local LEFT_COL_WIDTH = 276
    local LEFT_LABEL_WIDTH = 74
    local LEFT_BUTTON_OFFSET = 78
    local LEFT_BUTTON_WIDTH = LEFT_COL_WIDTH - LEFT_BUTTON_OFFSET

    local MIDDLE_COL_X = 312
    local MIDDLE_COL_WIDTH = 276
    local MIDDLE_LABEL_WIDTH = 95
    local MIDDLE_BUTTON_OFFSET = 104
    local MIDDLE_BUTTON_WIDTH = MIDDLE_COL_WIDTH - MIDDLE_BUTTON_OFFSET

    local RIGHT_COL_X = 612
    local RIGHT_COL_WIDTH = 276
    local RIGHT_LABEL_WIDTH = 95
    local RIGHT_BUTTON_OFFSET = 104
    local RIGHT_BUTTON_WIDTH = RIGHT_COL_WIDTH - RIGHT_BUTTON_OFFSET
    local RIGHT_STYLE_LABEL_WIDTH = 56
    local RIGHT_STYLE_BUTTON_OFFSET = 58
    local RIGHT_STYLE_BUTTON_WIDTH = RIGHT_COL_WIDTH - RIGHT_STYLE_BUTTON_OFFSET
    local PLAYER_BAR_LABEL_WIDTH = 120
    local PLAYER_BAR_BUTTON_OFFSET = 124
    local PLAYER_BAR_BUTTON_WIDTH = RIGHT_COL_WIDTH - PLAYER_BAR_BUTTON_OFFSET
    local ICON_RESET_BUTTON_GAP = 8
    local ICON_RESET_BUTTON_WIDTH = math.floor((RIGHT_COL_WIDTH - ICON_RESET_BUTTON_GAP) / 2)
    local RIGHT_COL_Y_OFFSET = 24
    local RIGHT_STACK_Y_OFFSET = RIGHT_COL_Y_OFFSET + 252
    local RIGHT_FRAME_OPTIONS_Y_SHIFT = 76
    local LEFT_LOWER_Y_OFFSET = -134

    local function NormalizeSelectionValue(value, fallback)
        if type(value) ~= "string" then
            return fallback
        end
        local trimmed = value:match("^%s*(.-)%s*$")
        if not trimmed or trimmed == "" then
            return fallback
        end
        return trimmed
    end

    local function RefreshPredictionVisuals()
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
            return
        end
        if MMF_GetAllFrames and MMF_UpdateUnitFrame then
            for _, frame in ipairs(MMF_GetAllFrames()) do
                if frame then
                    MMF_UpdateUnitFrame(frame)
                end
            end
        end
    end

    local function BuildSection(index, builder, config)
        if type(builder) ~= "function" then
            return
        end
        local root = sectionRoots[index] or fallbackRoot
        local wasShown = root and root.IsShown and root:IsShown() or false
        if root and root.Show then
            root:Show()
        end
        config = config or {}
        config.parent = root
        builder(config)
        if root and root.Hide and not wasShown then
            root:Hide()
        end
    end

    local sectionBuilders = {
        [1] = {
            builder = MMF_BuildUnitFramesLayoutSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                createMinimalSlider = CreateMinimalSlider,
                dropdownLists = dropdownLists,
                leftColX = LEFT_COL_X,
                leftColWidth = LEFT_COL_WIDTH,
                leftLabelWidth = LEFT_LABEL_WIDTH,
                leftButtonOffset = LEFT_BUTTON_OFFSET,
                leftButtonWidth = LEFT_BUTTON_WIDTH,
            },
        },
        [2] = {
            builder = MMF_BuildUnitFramesTextSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                createMinimalSlider = CreateMinimalSlider,
                dropdownLists = dropdownLists,
                refreshPredictionVisuals = RefreshPredictionVisuals,
                leftColX = LEFT_COL_X,
                leftColWidth = LEFT_COL_WIDTH,
                leftLabelWidth = LEFT_LABEL_WIDTH,
                leftButtonOffset = LEFT_BUTTON_OFFSET,
                leftButtonWidth = LEFT_BUTTON_WIDTH,
            },
        },
        [3] = {
            builder = MMF_BuildUnitFramesVisibilitySection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                dropdownLists = dropdownLists,
                leftColX = LEFT_COL_X,
                leftColWidth = LEFT_COL_WIDTH,
                leftLabelWidth = LEFT_LABEL_WIDTH,
                leftButtonOffset = LEFT_BUTTON_OFFSET,
                leftButtonWidth = LEFT_BUTTON_WIDTH,
            },
        },
        [4] = {
            builder = MMF_BuildUnitFramesOffsetsSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                createMinimalSlider = CreateMinimalSlider,
                dropdownLists = dropdownLists,
                leftColX = LEFT_COL_X,
                leftColWidth = LEFT_COL_WIDTH,
                leftLabelWidth = LEFT_LABEL_WIDTH,
                leftButtonOffset = LEFT_BUTTON_OFFSET,
                leftButtonWidth = LEFT_BUTTON_WIDTH,
                leftLowerYOffset = LEFT_LOWER_Y_OFFSET,
            },
        },
        [5] = {
            builder = MMF_BuildUnitFramesCastBarsSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                dropdownLists = dropdownLists,
                middleColX = MIDDLE_COL_X,
                middleColWidth = MIDDLE_COL_WIDTH,
                middleLabelWidth = MIDDLE_LABEL_WIDTH,
                middleButtonOffset = MIDDLE_BUTTON_OFFSET,
                middleButtonWidth = MIDDLE_BUTTON_WIDTH,
                rightColYOffset = RIGHT_COL_Y_OFFSET,
            },
        },
        [6] = {
            builder = MMF_BuildUnitFramesOOCSection,
            config = {
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                createMinimalSlider = CreateMinimalSlider,
                middleColX = MIDDLE_COL_X,
                middleColWidth = MIDDLE_COL_WIDTH,
                rightColYOffset = RIGHT_COL_Y_OFFSET,
            },
        },
        [7] = {
            builder = MMF_BuildUnitFramesMediaSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                dropdownLists = dropdownLists,
                rightSection = rightSection,
                normalizeSelectionValue = NormalizeSelectionValue,
                rightColX = RIGHT_COL_X,
                rightColWidth = RIGHT_COL_WIDTH,
                rightStackYOffset = RIGHT_STACK_Y_OFFSET,
                rightStyleLabelWidth = RIGHT_STYLE_LABEL_WIDTH,
                rightStyleButtonOffset = RIGHT_STYLE_BUTTON_OFFSET,
                rightStyleButtonWidth = RIGHT_STYLE_BUTTON_WIDTH,
                playerBarLabelWidth = PLAYER_BAR_LABEL_WIDTH,
                playerBarButtonOffset = PLAYER_BAR_BUTTON_OFFSET,
                playerBarButtonWidth = PLAYER_BAR_BUTTON_WIDTH,
            },
        },
        [8] = {
            builder = MMF_BuildUnitFramesIconsSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                dropdownLists = dropdownLists,
                rightSection = rightSection,
                normalizeSelectionValue = NormalizeSelectionValue,
                getCurrentPlayerIconModeValue = GetCurrentPlayerIconModeValue,
                getCurrentTargetIconModeValue = GetCurrentTargetIconModeValue,
                createMinimalSlider = CreateMinimalSlider,
                createMinimalCheckbox = CreateMinimalCheckbox,
                setUpdatePlayerIconModeButtonText = function(callback)
                    if type(callback) == "function" then
                        UpdatePlayerIconModeButtonTextImpl = callback
                    end
                end,
                rightColX = RIGHT_COL_X,
                rightColWidth = RIGHT_COL_WIDTH,
                rightLabelWidth = RIGHT_LABEL_WIDTH,
                rightButtonOffset = RIGHT_BUTTON_OFFSET,
                rightButtonWidth = RIGHT_BUTTON_WIDTH,
                rightStackYOffset = RIGHT_STACK_Y_OFFSET,
                rightFrameOptionsYShift = RIGHT_FRAME_OPTIONS_Y_SHIFT,
                iconResetButtonWidth = ICON_RESET_BUTTON_WIDTH,
                iconResetButtonGap = ICON_RESET_BUTTON_GAP,
            },
        },
        [9] = {
            builder = MMF_BuildUnitFramesOverlaysSection,
            config = {
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                rightSection = rightSection,
                rightColX = RIGHT_COL_X,
                rightColWidth = RIGHT_COL_WIDTH,
                rightStackYOffset = RIGHT_STACK_Y_OFFSET,
                rightFrameOptionsYShift = RIGHT_FRAME_OPTIONS_Y_SHIFT,
                onPredictionChanged = function()
                    RefreshPredictionVisuals()
                end,
            },
        },
    }

    local builtSections = {}
    local function EnsureSectionBuilt(index)
        if builtSections[index] then
            return
        end
        local entry = sectionBuilders[index]
        if not entry then
            return
        end
        BuildSection(index, entry.builder, entry.config)
        builtSections[index] = true
    end

    local function HideDropdownList(listFrame)
        if listFrame and listFrame.Hide then
            listFrame:Hide()
        end
    end

    if headerState and headerState.SetSectionChangeHandler then
        headerState.SetSectionChangeHandler(function(index)
            EnsureSectionBuilt(index)
            local activeRoot = sectionRoots[index]
            if activeRoot and MMF_RefreshPopupWidgetTree then
                MMF_RefreshPopupWidgetTree(activeRoot)
            end
            for _, listFrame in pairs(dropdownLists) do
                HideDropdownList(listFrame)
            end
            if rightSection.overlayHintTooltip then
                rightSection.overlayHintTooltip:Hide()
            end
        end)
    end

    return {
        castBarColorList = dropdownLists.castBarColorList,
        unitTextureList = dropdownLists.unitTextureList,
        unitFontList = dropdownLists.unitFontList,
        playerBarColorList = dropdownLists.playerBarColorList,
        targetBarColorList = dropdownLists.targetBarColorList,
        totBarColorList = dropdownLists.totBarColorList,
        playerIconModeList = dropdownLists.playerIconModeList,
        targetIconModeList = dropdownLists.targetIconModeList,
        scaleUnitList = dropdownLists.scaleUnitList,
        frameTextUnitList = dropdownLists.frameTextUnitList,
        nameTextUnitList = dropdownLists.nameTextUnitList,
        hpTextUnitList = dropdownLists.hpTextUnitList,
        hideNameTextUnitList = dropdownLists.hideNameTextUnitList,
        hideHPTextUnitList = dropdownLists.hideHPTextUnitList,
        UpdatePlayerIconModeButtonText = UpdatePlayerIconModeButtonText,
        ApplyInitialSection = headerState and headerState.ApplyInitialSection,
    }
end

