local Compat = _G.MMF_Compat or {}

local function MMF_SetupAurasPowerHeader(leftCol, accentColor, requestScrollRefresh)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local RequestScrollRefresh = requestScrollRefresh or function() end

    local sectionCard = CreateFrame("Frame", nil, leftCol, "BackdropTemplate")
    sectionCard:SetPoint("TOPLEFT", 12, -60)
    sectionCard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    sectionCard:SetBackdropColor(0.03, 0.05, 0.07, 0.98)
    sectionCard:SetBackdropBorderColor(0.12, 0.16, 0.18, 1)

    local sectionTitle = sectionCard:CreateFontString(nil, "OVERLAY")
    sectionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 14, "")
    sectionTitle:SetPoint("TOPLEFT", 18, -16)
    sectionTitle:SetTextColor(MMF_GetPopupSectionTitleColor())

    local sectionSubtitle = sectionCard:CreateFontString(nil, "OVERLAY")
    sectionSubtitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    sectionSubtitle:SetPoint("TOPLEFT", sectionTitle, "BOTTOMLEFT", 0, -6)
    sectionSubtitle:SetTextColor(0.62, 0.67, 0.71)

    local sectionDivider = sectionCard:CreateTexture(nil, "ARTWORK")
    sectionDivider:SetPoint("TOPLEFT", 18, -52)
    sectionDivider:SetPoint("TOPRIGHT", -18, -52)
    sectionDivider:SetHeight(1)
    sectionDivider:SetColorTexture(0.14, 0.18, 0.2, 1)

    local quickGuide = CreateFrame("Frame", nil, sectionCard, "BackdropTemplate")
    quickGuide:SetPoint("TOPRIGHT", -18, -62)
    quickGuide:SetSize(184, 128)
    quickGuide:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    quickGuide:SetBackdropColor(0.05, 0.08, 0.11, 0.82)
    quickGuide:SetBackdropBorderColor(0.14, 0.18, 0.2, 1)

    local quickGuideTitle = quickGuide:CreateFontString(nil, "OVERLAY")
    quickGuideTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    quickGuideTitle:SetPoint("TOPLEFT", 12, -10)
    quickGuideTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    quickGuideTitle:SetText("Quick Guide")

    local quickGuideBody = quickGuide:CreateFontString(nil, "OVERLAY")
    quickGuideBody:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    quickGuideBody:SetPoint("TOPLEFT", quickGuideTitle, "BOTTOMLEFT", 0, -8)
    quickGuideBody:SetPoint("TOPRIGHT", -12, -30)
    quickGuideBody:SetJustifyH("LEFT")
    quickGuideBody:SetJustifyV("TOP")
    quickGuideBody:SetTextColor(0.78, 0.90, 0.96)

    local sectionViewport = CreateFrame("Frame", nil, sectionCard)
    sectionViewport:SetPoint("TOPLEFT", 18, -62)
    sectionViewport:SetClipsChildren(true)

    local sectionRoots = {}

    local sectionDefs = {
        { label = "Power", subtitle = "Player and target power bars and text.", x = 304, y = 12, width = 228, height = 460, guide = "Use this page to control power bars and power text.\nYou can choose what is shown and how large it appears." },
        { label = "Player Auras", subtitle = "Player aura position and appearance.", x = 0, y = 12, width = 352, height = 500, guide = "Use this page to control your own buffs and debuffs.\nMove them, resize them, and set how they grow." },
        { label = "Target Auras", subtitle = "Target aura position and appearance.", x = 0, y = 12, width = 352, height = 500, guide = "Use this page to control target buffs and debuffs.\nAdjust layout so important effects are easy to read." },
        { label = "Filters", subtitle = "Filter which target debuffs are displayed.", x = 0, y = 12, width = 300, height = 180, guide = "Use this page to hide less important debuffs.\nKeep only the debuffs you actually care about." },
    }

    -- Match Unit Frames visual footprint so both pages feel consistent.
    local FIXED_VIEWPORT_W = 560
    local FIXED_VIEWPORT_H = 500
    local FIXED_CARD_W = 596
    local FIXED_CARD_H = 562
    local FIXED_PAGE_H = 662

    sectionCard:SetSize(FIXED_CARD_W, FIXED_CARD_H)
    leftCol:SetHeight(FIXED_PAGE_H)

    local activeSectionIndex = tonumber(MattMinimalFramesDB.aurasPowerSubTab) or 1
    if activeSectionIndex < 1 or activeSectionIndex > #sectionDefs then
        activeSectionIndex = 1
    end

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
        MattMinimalFramesDB.aurasPowerSubTab = index
        local section = sectionDefs[index]
        if not section then return end

        sectionTitle:SetText(section.label or "")
        sectionSubtitle:SetText(section.subtitle or "")
        quickGuideBody:SetText(section.guide or "")
        sectionViewport:SetSize(FIXED_VIEWPORT_W, FIXED_VIEWPORT_H)
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
        if sectionChangeHandler then
            sectionChangeHandler(index, section)
        end
        RequestScrollRefresh()
    end

    local subTabs = MMF_CreateSubTabBar and MMF_CreateSubTabBar(leftCol, {
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
            if subTabs and subTabs.SetActive then
                subTabs.SetActive(activeSectionIndex, true)
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

function MMF_CreateAurasPowerSection(leftCol, popup, accentColor, createMinimalCheckbox, createMinimalSlider, requestScrollRefresh)
    local _, playerClass = UnitClass("player")
    local isPlayerDruid = (playerClass == "DRUID")
    local isTBCComboClass = Compat.IsTBC and (playerClass == "ROGUE" or playerClass == "DRUID")
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider
    local headerState = MMF_SetupAurasPowerHeader(leftCol, ACCENT_COLOR, requestScrollRefresh)
    local sectionRoots = (headerState and headerState.sectionRoots) or {}
    local fallbackRoot = (headerState and headerState.contentRoot) or leftCol
    local AURA_COL_X = 12
    local AURA_COL_WIDTH = 300
    local RESOURCE_COL_X = AURA_COL_X + AURA_COL_WIDTH + 24
    local dropdownLists = {}

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
            builder = MMF_BuildAurasPowerPowerSection,
            config = {
                createMinimalCheckbox = CreateMinimalCheckbox,
                createMinimalSlider = CreateMinimalSlider,
                resourceColX = RESOURCE_COL_X,
                isPlayerDruid = isPlayerDruid,
                refreshPowerFrames = RefreshPowerFrames,
            },
        },
        [2] = {
            builder = MMF_BuildAurasPowerPlayerAurasSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                createMinimalSlider = CreateMinimalSlider,
                auraColX = AURA_COL_X,
                auraColWidth = AURA_COL_WIDTH,
                dropdownLists = dropdownLists,
            },
        },
        [3] = {
            builder = MMF_BuildAurasPowerTargetAurasSection,
            config = {
                popup = popup,
                accentColor = ACCENT_COLOR,
                createMinimalCheckbox = CreateMinimalCheckbox,
                createMinimalSlider = CreateMinimalSlider,
                auraColX = AURA_COL_X,
                auraColWidth = AURA_COL_WIDTH,
                isTBCComboClass = isTBCComboClass,
                dropdownLists = dropdownLists,
            },
        },
        [4] = {
            builder = MMF_BuildAurasPowerFiltersSection,
            config = {
                createMinimalCheckbox = CreateMinimalCheckbox,
                auraColX = AURA_COL_X,
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

    if headerState and headerState.SetSectionChangeHandler then
        headerState.SetSectionChangeHandler(function(index)
            EnsureSectionBuilt(index)
            local activeRoot = sectionRoots[index]
            if activeRoot and MMF_RefreshPopupWidgetTree then
                MMF_RefreshPopupWidgetTree(activeRoot)
            end
        end)
    end

    if headerState and headerState.ApplyInitialSection then
        headerState.ApplyInitialSection()
    else
        EnsureSectionBuilt(1)
    end

    return {
        auraTypeList = dropdownLists.auraTypeList,
        buffAuraDirectionList = dropdownLists.buffAuraDirectionList,
        debuffAuraDirectionList = dropdownLists.debuffAuraDirectionList,
        auraAppearanceTypeList = dropdownLists.auraAppearanceTypeList,
        playerAuraTypeList = dropdownLists.playerAuraTypeList,
        playerBuffAuraDirectionList = dropdownLists.playerBuffAuraDirectionList,
        playerDebuffAuraDirectionList = dropdownLists.playerDebuffAuraDirectionList,
        playerAuraAppearanceTypeList = dropdownLists.playerAuraAppearanceTypeList,
    }
end
