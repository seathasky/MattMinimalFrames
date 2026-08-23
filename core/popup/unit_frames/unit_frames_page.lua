local function MMF_SetupUnitFramesHeader(unitFramesCol, accentColor, createSubTabBar, requestScrollRefresh)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateSubTabBar = createSubTabBar or MMF_CreateSubTabBar
    local RequestScrollRefresh = requestScrollRefresh or function() end
    local theme = (MMF_GetPopupTheme and MMF_GetPopupTheme()) or {}
    local pageBorder = theme.borderStrong or { 0.22, 0.26, 0.30, 1 }
    local pageSurface = theme.surface or { 0.045, 0.055, 0.068, 1 }
    local subtleBorder = theme.border or { 0.145, 0.175, 0.205, 1 }

    local sectionCard = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
    sectionCard:SetPoint("TOPLEFT", 12, -60)
    sectionCard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    sectionCard:SetBackdropColor(0.03, 0.05, 0.07, 0.98)
    sectionCard:SetBackdropBorderColor(pageBorder[1], pageBorder[2], pageBorder[3], pageBorder[4] or 1)

    -- Draw the page perimeter one pixel inside the frame. Backdrop edges that
    -- sit directly on a clipped boundary can lose the rightmost pixel at some
    -- UI scales, making an otherwise complete border look one-sided.
    local function CreatePageBorderEdge(pointA, relativePointA, xA, yA, pointB, relativePointB, xB, yB)
        local edge = sectionCard:CreateTexture(nil, "BORDER", nil, 7)
        edge:SetPoint(pointA, sectionCard, relativePointA, xA, yA)
        edge:SetPoint(pointB, sectionCard, relativePointB, xB, yB)
        edge:SetColorTexture(pageBorder[1], pageBorder[2], pageBorder[3], pageBorder[4] or 1)
        return edge
    end
    local pageBorderTop = CreatePageBorderEdge("TOPLEFT", "TOPLEFT", 1, -1, "TOPRIGHT", "TOPRIGHT", -1, -1)
    pageBorderTop:SetHeight(1)
    local pageBorderBottom = CreatePageBorderEdge("BOTTOMLEFT", "BOTTOMLEFT", 1, 1, "BOTTOMRIGHT", "BOTTOMRIGHT", -1, 1)
    pageBorderBottom:SetHeight(1)
    local pageBorderLeft = CreatePageBorderEdge("TOPLEFT", "TOPLEFT", 1, -1, "BOTTOMLEFT", "BOTTOMLEFT", 1, 1)
    pageBorderLeft:SetWidth(1)
    local pageBorderRight = CreatePageBorderEdge("TOPRIGHT", "TOPRIGHT", -1, -1, "BOTTOMRIGHT", "BOTTOMRIGHT", -1, 1)
    pageBorderRight:SetWidth(1)

    local sectionCardTitle = sectionCard:CreateFontString(nil, "OVERLAY")
    sectionCardTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
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

    local UNIT_PAGE_WIDTH = 740
    local compat = _G.MMF_Compat or {}
    local _, playerClass = UnitClass("player")
    local needsTBCComboSpace = compat.IsTBC and (playerClass == "ROGUE" or playerClass == "DRUID")
    local playerPageHeight = needsTBCComboSpace and 1834
        or (playerClass == "DRUID" and 1706)
        or 1678

    local sectionDefs = {
        { unit = "player", label = "Player", subtitle = "Configure every setting that belongs to your player frame.", x = 0, y = 0, width = UNIT_PAGE_WIDTH, height = playerPageHeight },
        { unit = "target", label = "Target", subtitle = "Configure every setting that belongs to your target frame.", x = 0, y = 0, width = UNIT_PAGE_WIDTH, height = 1688 },
        { unit = "targettarget", label = "Target of Target", subtitle = "Configure every setting that belongs to the target-of-target frame.", x = 0, y = 0, width = UNIT_PAGE_WIDTH, height = 668 },
        { unit = "pet", label = "Pet", subtitle = "Configure every setting that belongs to your pet frame.", x = 0, y = 0, width = UNIT_PAGE_WIDTH, height = 668 },
        { unit = "focus", label = "Focus", subtitle = "Configure every setting that belongs to your focus frame.", x = 0, y = 0, width = UNIT_PAGE_WIDTH, height = 1202 },
        { unit = "boss", label = "Boss", subtitle = "Configure every setting that belongs to the boss-frame group.", x = 0, y = 0, width = UNIT_PAGE_WIDTH, height = 696 },
        { unit = "more", label = "More Settings", subtitle = "Shared presentation, indicators, overlays, and compatibility controls.", x = 0, y = 0, width = UNIT_PAGE_WIDTH, height = 1108 },
    }

    local activeSectionIndex = tonumber(MattMinimalFramesDB.unitFramesSubTab) or 1
    if activeSectionIndex < 1 or activeSectionIndex > #sectionDefs then
        activeSectionIndex = 1
    end

    sectionCard:SetSize(UNIT_PAGE_WIDTH + 36, 642)
    unitFramesCol:SetHeight(742)

    for index, def in ipairs(sectionDefs) do
        local sectionRoot = CreateFrame("Frame", nil, sectionViewport)
        sectionRoot:SetPoint("TOPLEFT", sectionViewport, "TOPLEFT", -def.x, def.y)
        sectionRoot:SetSize(def.width or UNIT_PAGE_WIDTH, math.max(760, def.height or 0))
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
        sectionCard:SetSize(math.max(360, (section.width or 0) + 36), (section.height or 0) + 82)
        unitFramesCol:SetHeight((section.height or 0) + 182)
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

    -- Keep unit navigation attached to the viewport instead of the scroll
    -- child. The opaque host prevents settings content from showing through
    -- while it scrolls underneath the pinned navigation.
    local stickyParent = unitFramesCol:GetParent() or unitFramesCol
    local stickyTabHost = CreateFrame("Frame", nil, stickyParent)
    stickyTabHost:SetPoint("TOPLEFT", stickyParent, "TOPLEFT", 0, 0)
    stickyTabHost:SetPoint("TOPRIGHT", stickyParent, "TOPRIGHT", 0, 0)
    stickyTabHost:SetHeight(52)
    stickyTabHost:SetFrameLevel(math.max((stickyParent:GetFrameLevel() or 0) + 40, (unitFramesCol:GetFrameLevel() or 0) + 40))

    local stickyBackground = stickyTabHost:CreateTexture(nil, "BACKGROUND")
    stickyBackground:SetAllPoints()
    stickyBackground:SetColorTexture(pageSurface[1], pageSurface[2], pageSurface[3], 1)

    local stickyTopBorder = stickyTabHost:CreateTexture(nil, "ARTWORK")
    stickyTopBorder:SetPoint("TOPLEFT", 0, 0)
    stickyTopBorder:SetPoint("TOPRIGHT", 0, 0)
    stickyTopBorder:SetHeight(1)
    stickyTopBorder:SetColorTexture(subtleBorder[1], subtleBorder[2], subtleBorder[3], subtleBorder[4] or 1)

    local stickyBottomBorder = stickyTabHost:CreateTexture(nil, "ARTWORK")
    stickyBottomBorder:SetPoint("BOTTOMLEFT", 0, 0)
    stickyBottomBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    stickyBottomBorder:SetHeight(1)
    stickyBottomBorder:SetColorTexture(subtleBorder[1], subtleBorder[2], subtleBorder[3], subtleBorder[4] or 1)

    local unitFramesSubTabs = CreateSubTabBar and CreateSubTabBar(stickyTabHost, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -22,
        width = UNIT_PAGE_WIDTH,
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

    local function RefreshStickyTabVisibility()
        stickyTabHost:SetShown(unitFramesCol:IsShown())
    end
    unitFramesCol:HookScript("OnShow", RefreshStickyTabVisibility)
    unitFramesCol:HookScript("OnHide", RefreshStickyTabVisibility)
    RefreshStickyTabVisibility()

    return {
        contentRoot = sectionRoots[1],
        sectionRoots = sectionRoots,
        stickyTabHost = stickyTabHost,
        SetSectionChangeHandler = function(handler)
            sectionChangeHandler = handler
        end,
        ApplyInitialSection = function()
            local requestedSection = tonumber(MattMinimalFramesDB and MattMinimalFramesDB.unitFramesSubTab) or activeSectionIndex
            if requestedSection >= 1 and requestedSection <= #sectionDefs then
                activeSectionIndex = requestedSection
            end
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

    local dropdownLists = {}
    local headerState = MMF_SetupUnitFramesHeader(unitFramesCol, ACCENT_COLOR, createSubTabBar, requestScrollRefresh)
    local sectionRoots = (headerState and headerState.sectionRoots) or {}
    local fallbackRoot = (headerState and headerState.contentRoot) or unitFramesCol

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

    local function NormalizeSelectionValue(value, fallback)
        if type(value) ~= "string" then return fallback end
        local trimmed = value:match("^%s*(.-)%s*$")
        return trimmed ~= "" and trimmed or fallback
    end

    local function RefreshPredictionVisuals()
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        end
    end

    -- One safety-net page for controls that have not been moved yet.  It has
    -- no nested navigation and uses the original controls, keys, and callbacks.
    local function BuildLegacyFallback(ctx)
        local parent = ctx.parent
        local X, WIDTH, LABEL, OFFSET = 12, 346, 92, 98
        local function CreateGroup(y, height, tone)
            local group = CreateFrame("Frame", nil, parent)
            group:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
            group:SetSize(740, height)
            if MMF_CreateUnitFramesSectionCard then
                MMF_CreateUnitFramesSectionCard(group, 4, 0, 732, height, tone or "shared")
            end
            return group
        end
        local function Common(group)
            return {
                parent = group, popup = popup, accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                createMinimalSlider = CreateMinimalSlider,
                createMinimalColorPicker = MMF_CreateMinimalColorPicker,
                dropdownLists = dropdownLists,
            }
        end

        local castBars = Common(CreateGroup(0, 84, "cast"))
        MMF_BuildUnitFramesSharedCastBarSection(castBars)

        local ooc = Common(CreateGroup(-92, 188, "visibility"))
        ooc.middleColX, ooc.middleColWidth, ooc.rightColYOffset = X, WIDTH, 288
        ooc.rightColX, ooc.rightColWidth, ooc.standardLayout = 382, WIDTH, true
        MMF_BuildUnitFramesOOCSection(ooc)

        -- Only shared texture/font presentation belongs here.  Unit-specific
        -- colors and borders now live on their owner pages.
        local appearance = Common(CreateGroup(-288, 156, "shared"))
        appearance.rightSection, appearance.normalizeSelectionValue = {}, NormalizeSelectionValue
        appearance.rightColX, appearance.rightColWidth, appearance.rightStackYOffset = X, WIDTH, 288
        appearance.rightStyleLabelWidth, appearance.rightStyleButtonOffset, appearance.rightStyleButtonWidth = 56, 58, WIDTH - 58
        appearance.playerBarLabelWidth, appearance.playerBarButtonOffset, appearance.playerBarButtonWidth = 120, 124, WIDTH - 124
        appearance.sharedRightColX = 382
        appearance.sharedLabelWidth, appearance.sharedButtonOffset, appearance.sharedButtonWidth = 92, 98, WIDTH - 98
        appearance.sharedOnly = true
        MMF_BuildUnitFramesMediaSection(appearance)

        local icons = Common(CreateGroup(-452, 252, "icon"))
        icons.rightSection, icons.normalizeSelectionValue = {}, NormalizeSelectionValue
        icons.getCurrentPlayerIconModeValue = getCurrentPlayerIconModeValue or function() return "off" end
        icons.getCurrentTargetIconModeValue = getCurrentTargetIconModeValue or function() return "off" end
        icons.setUpdatePlayerIconModeButtonText = function() end
        icons.rightColX, icons.rightColWidth, icons.rightStackYOffset = X, WIDTH, 518
        icons.rightLabelWidth, icons.rightButtonOffset, icons.rightButtonWidth = LABEL, OFFSET, WIDTH - OFFSET
        icons.rightFrameOptionsYShift, icons.iconResetButtonGap = 76, 8
        icons.iconResetButtonWidth = math.floor((WIDTH - icons.iconResetButtonGap) / 2)
        icons.fixedUnit = "shared"
        MMF_BuildUnitFramesIconsSection(icons)

        local overlays = Common(CreateGroup(-712, 396, "overlay"))
        overlays.rightSection = {}
        overlays.rightColX, overlays.rightColWidth, overlays.rightStackYOffset = X, WIDTH, 794
        overlays.rightFrameOptionsYShift = 76
        overlays.onPredictionChanged = RefreshPredictionVisuals
        overlays.standardLayout = true
        MMF_BuildUnitFramesOverlaysSection(overlays)
    end

    -- The unit tab itself is the sole selector.  Legacy category builders
    -- remain available as modules for Phase 6, but are never instantiated here.
    local unitPageUnits = { "player", "target", "targettarget", "pet", "focus", "boss" }
    local sectionBuilders = {}
    for index, unit in ipairs(unitPageUnits) do
        sectionBuilders[index] = {
            builder = MMF_BuildUnitFramesUnitPageCore,
            config = {
                popup = popup,
                unit = unit,
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                createMinimalSlider = CreateMinimalSlider,
                dropdownLists = dropdownLists,
                getCurrentPlayerIconModeValue = getCurrentPlayerIconModeValue,
                getCurrentTargetIconModeValue = getCurrentTargetIconModeValue,
            },
        }
    end
    sectionBuilders[7] = { builder = BuildLegacyFallback, config = {} }

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
        end)
    end

    return {
        ApplyInitialSection = headerState and headerState.ApplyInitialSection,
    }
end
