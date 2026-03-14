local Compat = _G.MMF_Compat

local POPUP_LAYOUT = (MMF_GetPopupLayout and MMF_GetPopupLayout()) or {
    width = 840,
    height = Compat.IsTBC and 750 or 750,
    titleHeight = 28,
    footerHeight = 32,
    tabHeight = 24,
    tabSpacing = 4,
    contentSidePadding = 10,
    contentTopOffset = -4,
    pageGap = 4,
    centerY = 50,
    unitFramesContentHeight = 680,
    aurasPowerContentHeight = 680,
    partyRaidContentHeight = 680,
    currentClassContentHeight = 680,
    profilesContentHeight = 680,
    toolsContentHeight = 680,
}

local CreateMinimalCheckbox = MMF_CreateMinimalCheckbox
local CreateMinimalSlider = MMF_CreateMinimalSlider
local CreateSubTabBar = MMF_CreateSubTabBar
local TITLE_WALLPAPER_ALPHA = 0.03
local SIDEBAR_WALLPAPER_ALPHA = 0.10
local SetAspectCropTexCoords = MMF_SetAspectCropTexCoords

local function IsUISoundsEnabled()
    if MMF_IsPopupUISoundsEnabled then
        return MMF_IsPopupUISoundsEnabled()
    end
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.uiSoundsEnabled ~= false
end

local CreateProfilesPage = MMF_CreateProfilesPage

function MMF_ShowWelcomePopup(forceShow)
    local ACCENT_COLOR = (MMF_GetPopupAccentColor and MMF_GetPopupAccentColor()) or { 0.6, 0.4, 0.9 }
    local ACCENT_HEX_PREFIX = (MMF_RGBToHexPrefix and MMF_RGBToHexPrefix(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])) or "|cff9966e6"

    -- If popup already exists, just show it and return
    if MMF_WelcomePopup then
        local currentScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB and MattMinimalFramesDB.guiScale)) or 1.0
        if MMF_WelcomePopup.ApplyGUIScale then
            MMF_WelcomePopup:ApplyGUIScale(currentScale, false)
        else
            MMF_WelcomePopup:SetScale(currentScale)
        end
        if MMF_WelcomePopup.ClampToScreen then
            MMF_WelcomePopup:ClampToScreen()
        end
        if MMF_WelcomePopup.MMFRefreshTitleBarControls then
            MMF_WelcomePopup:MMFRefreshTitleBarControls()
        end
        MMF_WelcomePopup:Show()
        if MMF_ApplyGlobalFont then
            MMF_ApplyGlobalFont()
        end
        return
    end

    -- Main frame 
    local popup = CreateFrame("Frame", "MMF_WelcomePopup", UIParent, "BackdropTemplate")
    local popupHeight = POPUP_LAYOUT.height
    local popupWidth = POPUP_LAYOUT.width
    local MIN_POPUP_WIDTH = POPUP_LAYOUT.width
    local chromeHeight = (POPUP_LAYOUT.titleHeight or 28)
        + (POPUP_LAYOUT.footerHeight or 32)
        - (POPUP_LAYOUT.contentTopOffset or -4)
        + (POPUP_LAYOUT.tabHeight or 24)
        + (POPUP_LAYOUT.pageGap or 4)
    local MIN_POPUP_HEIGHT = chromeHeight + 8
    -- Keep a large hard cap, then enforce an actual dynamic cap from screen bounds.
    local MAX_POPUP_HEIGHT = math.max((POPUP_LAYOUT.unitFramesContentHeight or 980) + chromeHeight, 5000)
    if MattMinimalFramesDB and type(MattMinimalFramesDB.popupSize) == "table" then
        local h = tonumber(MattMinimalFramesDB.popupSize.height)
        if h and h > (MIN_POPUP_HEIGHT - 40) then popupHeight = h end
    end
    popupWidth = MIN_POPUP_WIDTH
    if popupHeight < MIN_POPUP_HEIGHT then
        popupHeight = MIN_POPUP_HEIGHT
    end
    if popupHeight > MAX_POPUP_HEIGHT then
        popupHeight = MAX_POPUP_HEIGHT
    end
    popup:SetSize(popupWidth, popupHeight)
    local windowController = MMF_CreatePopupWindowController({
        popup = popup,
        popupLayout = POPUP_LAYOUT,
        minPopupWidth = MIN_POPUP_WIDTH,
        minPopupHeight = MIN_POPUP_HEIGHT,
        maxPopupHeight = MAX_POPUP_HEIGHT,
    })
    
    -- Apply saved GUI scale
    local guiScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
    MattMinimalFramesDB.guiScale = guiScale
    windowController.ApplyPopupScale(guiScale, false)
    
    -- Restore saved position or use default
    windowController.RestoreOrInitializePopupPosition(POPUP_LAYOUT.centerY)
    
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.04, 0.04, 0.05, 0.98)
    popup:SetBackdropBorderColor(0.1, 0.1, 0.12, 1)
    popup:SetMovable(true)
    local canSystemResize = (type(popup.SetResizable) == "function")
        and (type(popup.StartSizing) == "function")
        and (type(popup.StopMovingOrSizing) == "function")
    if canSystemResize then
        popup:SetResizable(true)
        if type(popup.SetMinResize) == "function" then
            popup:SetMinResize(MIN_POPUP_WIDTH, MIN_POPUP_HEIGHT)
        end
        if type(popup.SetMaxResize) == "function" then
            popup:SetMaxResize(MIN_POPUP_WIDTH, MAX_POPUP_HEIGHT)
        end
    end
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        windowController.ClampPopupHorizontal(self)
        windowController.PersistPopupPosition()
    end)
    popup:SetFrameStrata("DIALOG")
    popup.ApplyGUIScale = function(self, scale, preservePosition)
        windowController.ApplyPopupScale(scale, preservePosition)
    end
    popup.ClampToScreen = function(self)
        windowController.ClampPopupHorizontal(self)
        windowController.PersistPopupPosition()
    end
    popup:HookScript("OnShow", function(self)
        windowController.ClampPopupHorizontal(self)
        windowController.PersistPopupPosition()
    end)


    local headerState = MMF_CreatePopupHeader(popup, {
        popupWidth = popupWidth,
        popupLayout = POPUP_LAYOUT,
        accentColor = ACCENT_COLOR,
        titleWallpaperAlpha = TITLE_WALLPAPER_ALPHA,
        compat = Compat,
        setAspectCropTexCoords = SetAspectCropTexCoords,
        applyPopupScale = windowController.ApplyPopupScale,
        isUISoundsEnabled = IsUISoundsEnabled,
    }) or {}

    local titleBar = headerState.titleBar
    local UpdateTitleWallpaperCrop = headerState.UpdateTitleWallpaperCrop or function() end
    local ApplyInitialTitleBarState = headerState.ApplyInitialTitleBarState or function() end

    -- Content area (between title bar and footer)
    local content = CreateFrame("Frame", nil, popup)
    content:SetPoint("TOPLEFT", 0, -POPUP_LAYOUT.titleHeight)
    content:SetPoint("BOTTOMRIGHT", 0, POPUP_LAYOUT.footerHeight)
    content:SetClipsChildren(true)

    local tabContainer = CreateFrame("Frame", nil, content)
    tabContainer:SetPoint("TOPLEFT", POPUP_LAYOUT.contentSidePadding, POPUP_LAYOUT.contentTopOffset)
    tabContainer:SetPoint("BOTTOMRIGHT", -POPUP_LAYOUT.contentSidePadding, 0)
    tabContainer:SetClipsChildren(true)

    local SIDEBAR_WIDTH = 180
    local HEADER_HEIGHT = 68
    local tabBar = CreateFrame("Frame", nil, tabContainer)
    tabBar:SetPoint("TOPLEFT", 0, 0)
    tabBar:SetPoint("BOTTOMLEFT", 0, 0)
    tabBar:SetWidth(SIDEBAR_WIDTH)

    local sidebarBg = CreateFrame("Frame", nil, tabBar, "BackdropTemplate")
    sidebarBg:SetAllPoints()
    sidebarBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    sidebarBg:SetBackdropColor(0.05, 0.07, 0.09, 0.72)
    sidebarBg:SetBackdropBorderColor(0.12, 0.16, 0.18, 1)

    local sidebarWallpaper = sidebarBg:CreateTexture(nil, "ARTWORK")
    sidebarWallpaper:SetPoint("TOPLEFT", 1, -1)
    sidebarWallpaper:SetPoint("BOTTOMRIGHT", -1, 1)
    sidebarWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw2.png")
    sidebarWallpaper:SetAlpha(SIDEBAR_WALLPAPER_ALPHA)
    SetAspectCropTexCoords(sidebarWallpaper, sidebarBg, 16 / 9)

    local sidebarWallpaperTint = sidebarBg:CreateTexture(nil, "ARTWORK", nil, 1)
    sidebarWallpaperTint:SetPoint("TOPLEFT", 1, -1)
    sidebarWallpaperTint:SetPoint("BOTTOMRIGHT", -1, 1)
    sidebarWallpaperTint:SetColorTexture(0.02, 0.03, 0.04, 0.02)

    sidebarBg:SetScript("OnSizeChanged", function()
        SetAspectCropTexCoords(sidebarWallpaper, sidebarBg, 16 / 9)
    end)

    local sidebarBrand = CreateFrame("Frame", nil, tabBar)
    sidebarBrand:SetPoint("TOPLEFT", 0, 0)
    sidebarBrand:SetPoint("TOPRIGHT", 0, 0)
    sidebarBrand:SetHeight(64)

    local sidebarBrandGlow = sidebarBrand:CreateTexture(nil, "ARTWORK")
    sidebarBrandGlow:SetPoint("BOTTOMLEFT", 0, 0)
    sidebarBrandGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarBrandGlow:SetHeight(2)
    sidebarBrandGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

    local sidebarBrandTitle = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 20, "")
    sidebarBrandTitle:SetPoint("TOPLEFT", 16, -16)
    sidebarBrandTitle:SetTextColor(0.96, 0.97, 0.98)
    sidebarBrandTitle:SetText("SETTINGS")

    local sidebarBrandSub = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandSub:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    sidebarBrandSub:SetPoint("TOPLEFT", sidebarBrandTitle, "BOTTOMLEFT", 0, -4)
    sidebarBrandSub:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    sidebarBrandSub:SetText("")

    local navButtonHost = CreateFrame("Frame", nil, tabBar)
    navButtonHost:SetPoint("TOPLEFT", sidebarBrand, "BOTTOMLEFT", 0, -14)
    navButtonHost:SetPoint("TOPRIGHT", sidebarBrand, "BOTTOMRIGHT", 0, -14)
    navButtonHost:SetPoint("BOTTOMLEFT", 0, 12)
    navButtonHost:SetPoint("BOTTOMRIGHT", 0, 12)

    local pageContainer = CreateFrame("Frame", nil, tabContainer)
    pageContainer:SetPoint("TOPLEFT", tabBar, "TOPRIGHT", 12, 0)
    pageContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    pageContainer:SetClipsChildren(true)

    local pageHeader = CreateFrame("Frame", nil, pageContainer, "BackdropTemplate")
    pageHeader:SetPoint("TOPLEFT", 0, 0)
    pageHeader:SetPoint("TOPRIGHT", -(12 + 4), 0)
    pageHeader:SetHeight(HEADER_HEIGHT)
    pageHeader:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    pageHeader:SetBackdropColor(0.05, 0.07, 0.09, 0.96)
    pageHeader:SetBackdropBorderColor(0.12, 0.16, 0.18, 1)

    local pageHeaderWallpaper = pageHeader:CreateTexture(nil, "ARTWORK")
    pageHeaderWallpaper:SetPoint("TOPLEFT", 1, -1)
    pageHeaderWallpaper:SetPoint("BOTTOMRIGHT", -1, 1)
    pageHeaderWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw.png")
    pageHeaderWallpaper:SetAlpha(0.12)
    SetAspectCropTexCoords(pageHeaderWallpaper, pageHeader, 16 / 9)
    pageHeader:SetScript("OnSizeChanged", function()
        SetAspectCropTexCoords(pageHeaderWallpaper, pageHeader, 16 / 9)
    end)

    local pageHeaderGlow = pageHeader:CreateTexture(nil, "ARTWORK")
    pageHeaderGlow:SetPoint("BOTTOMLEFT", 0, 0)
    pageHeaderGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    pageHeaderGlow:SetHeight(2)
    pageHeaderGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

    local pageHeaderShade = pageHeader:CreateTexture(nil, "BACKGROUND")
    pageHeaderShade:SetPoint("TOPLEFT", 0, 0)
    pageHeaderShade:SetPoint("TOPRIGHT", 0, 0)
    pageHeaderShade:SetHeight(22)
    pageHeaderShade:SetColorTexture(0.02, 0.03, 0.04, 0.10)

    local pageHeaderTitle = pageHeader:CreateFontString(nil, "OVERLAY")
    pageHeaderTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 18, "")
    pageHeaderTitle:SetPoint("TOPLEFT", 16, -14)
    pageHeaderTitle:SetTextColor(0.98, 0.98, 0.98)

    local pageHeaderSubtitle = pageHeader:CreateFontString(nil, "OVERLAY")
    pageHeaderSubtitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    pageHeaderSubtitle:SetPoint("TOPLEFT", pageHeaderTitle, "BOTTOMLEFT", 0, -6)
    pageHeaderSubtitle:SetTextColor(0.62, 0.67, 0.71)

    local SCROLLBAR_WIDTH = 12
    local SCROLLBAR_GAP = 4

    local pageScrollFrame = CreateFrame("ScrollFrame", nil, pageContainer)
    pageScrollFrame:SetPoint("TOPLEFT", pageHeader, "BOTTOMLEFT", 0, -8)
    pageScrollFrame:SetPoint("BOTTOMRIGHT", -(SCROLLBAR_WIDTH + SCROLLBAR_GAP), 0)
    pageScrollFrame:EnableMouseWheel(true)
    pageScrollFrame:SetClipsChildren(true)

    local sharedScrollBar = CreateFrame("Slider", nil, pageContainer, "BackdropTemplate")
    sharedScrollBar:SetPoint("TOPRIGHT", 0, -2)
    sharedScrollBar:SetPoint("BOTTOMRIGHT", 0, 2)
    sharedScrollBar:SetWidth(SCROLLBAR_WIDTH)
    sharedScrollBar:SetOrientation("VERTICAL")
    sharedScrollBar:SetMinMaxValues(0, 0)
    sharedScrollBar:SetValueStep(1)
    sharedScrollBar:SetObeyStepOnDrag(true)
    sharedScrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    sharedScrollBar:SetBackdropColor(0.03, 0.03, 0.04, 1)
    sharedScrollBar:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local sharedThumb = sharedScrollBar:CreateTexture(nil, "OVERLAY")
    sharedThumb:SetSize(8, 24)
    sharedThumb:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    sharedScrollBar:SetThumbTexture(sharedThumb)

    local function CreatePageFrame(parent, contentHeight)
        local page = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        page:SetPoint("TOPLEFT", 0, 0)
        page:SetWidth(10)
        page:SetHeight(contentHeight or 760)
        page:SetClipsChildren(true)
        page:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        page:SetBackdropColor(0.08, 0.10, 0.13, 0.96)
        page:SetBackdropBorderColor(0.12, 0.16, 0.18, 1)

        return page
    end

    local leftCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.aurasPowerContentHeight)
    local partyRaidCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.partyRaidContentHeight)
    local unitFramesCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.unitFramesContentHeight)
    local middleCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.currentClassContentHeight)
    local rightCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.toolsContentHeight)
    local profilesCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.profilesContentHeight)

    local castBarColorList
    local unitTextureList
    local unitFontList
    local playerBarColorList
    local targetBarColorList
    local totBarColorList
    local playerIconModeList
    local targetIconModeList
    local scaleUnitList
    local frameTextUnitList
    local nameTextUnitList
    local hpTextUnitList
    local hideNameTextUnitList
    local hideHPTextUnitList
    local auraTypeList
    local buffAuraDirectionList
    local debuffAuraDirectionList
    local auraAppearanceTypeList
    local playerAuraTypeList
    local playerBuffAuraDirectionList
    local playerDebuffAuraDirectionList
    local playerAuraAppearanceTypeList
    local profileSelectList
    local deleteProfileSelectList
    local closableLists = {}
    local function RegisterClosableList(listFrame)
        if listFrame then
            closableLists[#closableLists + 1] = listFrame
        end
    end
    local function CloseListFrame(listFrame)
        if listFrame and listFrame:IsShown() then
            listFrame:Hide()
            if listFrame.clickCatcher then
                listFrame.clickCatcher:Hide()
            end
        end
    end
    local GetCurrentPlayerIconModeValue = function()
        local mode = MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMode or nil
        if mode ~= "off" and mode ~= "class" and mode ~= "portrait" and mode ~= "sharedmedia" and mode ~= "jiberish" then
            mode = "off"
        end
        return mode
    end
    local GetCurrentTargetIconModeValue = function()
        local mode = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMode or nil
        if mode ~= "off" and mode ~= "class" and mode ~= "portrait" and mode ~= "sharedmedia" and mode ~= "jiberish" then
            mode = "off"
        end
        return mode
    end
    local UpdatePlayerIconModeButtonText = function() end
    local unitFramesState
    local tabButtons = {}
    local allPages = {
        unitFramesCol,
        leftCol,
        partyRaidCol,
        middleCol,
        rightCol,
        profilesCol,
    }
    local activePage
    local function ApplyPageWidths(explicitWidth)
        local w = explicitWidth or pageScrollFrame:GetWidth() or 1
        w = math.max(1, w)
        for _, page in ipairs(allPages) do
            page:SetWidth(w)
        end
    end

    local function GetActivePageScrollRange()
        local page = activePage
        if not page then
            return 0, 0
        end

        if type(page.MMFGetSectionRange) == "function" then
            local startY, endY = page:MMFGetSectionRange()
            startY = math.max(0, tonumber(startY) or 0)
            endY = math.max(startY, tonumber(endY) or (page:GetHeight() or 0))
            return startY, endY
        end

        return 0, page:GetHeight() or 0
    end

    local function UpdateSharedScrollBounds()
        local page = activePage
        if not page then
            sharedScrollBar:SetMinMaxValues(0, 0)
            sharedScrollBar:SetValue(0)
            pageScrollFrame:SetVerticalScroll(0)
            return
        end

        local viewHeight = pageScrollFrame:GetHeight() or 0
        local sectionStart, sectionEnd = GetActivePageScrollRange()
        local contentHeight = math.max(0, sectionEnd - sectionStart)
        local maxScroll = math.max(0, contentHeight - viewHeight)
        local current = sharedScrollBar:GetValue() or 0
        if current > maxScroll then
            current = maxScroll
        end

        sharedScrollBar:SetMinMaxValues(0, maxScroll)
        sharedScrollBar:SetValue(current)
        sharedScrollBar:SetEnabled(maxScroll > 0)
        sharedScrollBar:SetAlpha(maxScroll > 0 and 1 or 0.45)
        pageScrollFrame:SetVerticalScroll(sectionStart + current)
    end

    sharedScrollBar:SetScript("OnValueChanged", function(self, value)
        local sectionStart = 0
        if activePage and type(activePage.MMFGetSectionRange) == "function" then
            local startY = activePage:MMFGetSectionRange()
            sectionStart = math.max(0, tonumber(startY) or 0)
        end
        pageScrollFrame:SetVerticalScroll(sectionStart + (value or 0))
    end)

    pageScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local minScroll, maxScroll = sharedScrollBar:GetMinMaxValues()
        local current = sharedScrollBar:GetValue() or 0
        local step = 32
        if delta > 0 then
            current = math.max(minScroll, current - step)
        else
            current = math.min(maxScroll, current + step)
        end
        sharedScrollBar:SetValue(current)
    end)

    pageScrollFrame:SetScript("OnSizeChanged", function(_, width)
        ApplyPageWidths(width)
        UpdateSharedScrollBounds()
    end)
    ApplyPageWidths()
    local tabPages
    local tabDefs
    if Compat.IsTBC then
        tabPages = {
            unitFramesCol,
            leftCol,
            partyRaidCol,
            profilesCol,
            rightCol,
        }
        tabDefs = {
            { label = "Unit Frames" },
            { label = "Auras / Power" },
            { label = "Party / Raid" },
            { label = "Profiles" },
            { label = "Tools" },
        }
    else
        tabPages = {
            unitFramesCol,
            leftCol,
            partyRaidCol,
            middleCol,
            profilesCol,
            rightCol,
        }
        tabDefs = {
            { label = "Unit Frames" },
            { label = "Auras / Power" },
            { label = "Party / Raid" },
            { label = "Current Class" },
            { label = "Profiles" },
            { label = "Tools" },
        }
    end

    local navigationController = MMF_CreatePopupNavigationController({
        tabBar = tabBar,
        navButtonHost = navButtonHost,
        tabDefs = tabDefs,
        tabPages = tabPages,
        allPages = allPages,
        pageHeaderTitle = pageHeaderTitle,
        pageHeaderSubtitle = pageHeaderSubtitle,
        pageScrollFrame = pageScrollFrame,
        sharedScrollBar = sharedScrollBar,
        accentColor = ACCENT_COLOR,
        popupLayout = POPUP_LAYOUT,
        sidebarWidth = SIDEBAR_WIDTH,
        closableLists = closableLists,
        closeListFrame = CloseListFrame,
        updateSharedScrollBounds = UpdateSharedScrollBounds,
        isUISoundsEnabledFn = IsUISoundsEnabled,
        setActivePage = function(page)
            activePage = page
        end,
        onUnitFramesTabActivated = function()
            if unitFramesState and unitFramesState.ApplyInitialSection then
                unitFramesState.ApplyInitialSection()
            end
        end,
    })
    local LayoutTabButtons = navigationController.LayoutTabButtons
    local SetActiveTab = navigationController.SetActiveTab
    tabButtons = navigationController.tabButtons
    LayoutTabButtons()

    ---------------------------------------------------
    unitFramesState = MMF_CreateUnitFramesSection(unitFramesCol, popup, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider, GetCurrentPlayerIconModeValue, GetCurrentTargetIconModeValue, CreateSubTabBar, UpdateSharedScrollBounds)
    castBarColorList = unitFramesState.castBarColorList
    unitTextureList = unitFramesState.unitTextureList
    unitFontList = unitFramesState.unitFontList
    playerBarColorList = unitFramesState.playerBarColorList
    targetBarColorList = unitFramesState.targetBarColorList
    totBarColorList = unitFramesState.totBarColorList
    playerIconModeList = unitFramesState.playerIconModeList
    targetIconModeList = unitFramesState.targetIconModeList
    scaleUnitList = unitFramesState.scaleUnitList
    frameTextUnitList = unitFramesState.frameTextUnitList
    nameTextUnitList = unitFramesState.nameTextUnitList
    hpTextUnitList = unitFramesState.hpTextUnitList
    hideNameTextUnitList = unitFramesState.hideNameTextUnitList
    hideHPTextUnitList = unitFramesState.hideHPTextUnitList
    if unitFramesState.UpdatePlayerIconModeButtonText then
        UpdatePlayerIconModeButtonText = unitFramesState.UpdatePlayerIconModeButtonText
    end
    RegisterClosableList(castBarColorList)
    RegisterClosableList(unitTextureList)
    RegisterClosableList(unitFontList)
    RegisterClosableList(playerBarColorList)
    RegisterClosableList(targetBarColorList)
    RegisterClosableList(totBarColorList)
    RegisterClosableList(playerIconModeList)
    RegisterClosableList(targetIconModeList)
    RegisterClosableList(scaleUnitList)
    RegisterClosableList(frameTextUnitList)
    RegisterClosableList(nameTextUnitList)
    RegisterClosableList(hpTextUnitList)
    RegisterClosableList(hideNameTextUnitList)
    RegisterClosableList(hideHPTextUnitList)

    local aurasState = MMF_CreateAurasPowerSection(leftCol, popup, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider, UpdateSharedScrollBounds)
    if type(aurasState) == "table" then
        auraTypeList = aurasState.auraTypeList
        buffAuraDirectionList = aurasState.buffAuraDirectionList
        debuffAuraDirectionList = aurasState.debuffAuraDirectionList
        auraAppearanceTypeList = aurasState.auraAppearanceTypeList
        playerAuraTypeList = aurasState.playerAuraTypeList
        playerBuffAuraDirectionList = aurasState.playerBuffAuraDirectionList
        playerDebuffAuraDirectionList = aurasState.playerDebuffAuraDirectionList
        playerAuraAppearanceTypeList = aurasState.playerAuraAppearanceTypeList
    end
    RegisterClosableList(auraTypeList)
    RegisterClosableList(buffAuraDirectionList)
    RegisterClosableList(debuffAuraDirectionList)
    RegisterClosableList(auraAppearanceTypeList)
    RegisterClosableList(playerAuraTypeList)
    RegisterClosableList(playerBuffAuraDirectionList)
    RegisterClosableList(playerDebuffAuraDirectionList)
    RegisterClosableList(playerAuraAppearanceTypeList)

    MMF_CreatePartyRaidPage(partyRaidCol, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider)

    MMF_CreateCurrentClassSection(middleCol, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider, UpdatePlayerIconModeButtonText, GetCurrentPlayerIconModeValue)

    MMF_CreateToolsPage(rightCol, ACCENT_COLOR, ACCENT_HEX_PREFIX, CreateMinimalCheckbox, IsUISoundsEnabled)

    local profilesState = CreateProfilesPage(popup, profilesCol, ACCENT_COLOR)
    if type(profilesState) == "table" then
        profileSelectList = profilesState.profileSelectList
        deleteProfileSelectList = profilesState.deleteProfileSelectList
    else
        profileSelectList = profilesState
    end
    RegisterClosableList(profileSelectList)
    RegisterClosableList(deleteProfileSelectList)

    local defaultTab = tonumber(MattMinimalFramesDB.popupActiveTab) or 1
    if defaultTab < 1 or defaultTab > #tabPages then
        defaultTab = 1
    end

    local footer = MMF_CreatePopupFooter(popup, popupWidth, ACCENT_COLOR, POPUP_LAYOUT.footerHeight)

    local resizeGrip = CreateFrame("Button", nil, popup)
    resizeGrip:SetSize(18, 18)
    resizeGrip:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetFrameStrata("DIALOG")
    local gripTex = resizeGrip:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    gripTex:SetVertexColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.9)
    resizeGrip:SetNormalTexture(gripTex)
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeGrip:SetScript("OnMouseDown", function()
        if type(GetCursorPosition) ~= "function" then
            return
        end
        popup.mmfResizing = true
        popup.mmfResizeStartH = popup:GetHeight() or POPUP_LAYOUT.height
        local _, startY = GetCursorPosition()
        popup.mmfResizeStartY = startY
        popup:SetScript("OnUpdate", function(self)
            if not self.mmfResizing or type(GetCursorPosition) ~= "function" then
                return
            end
            local _, cy = GetCursorPosition()
            local scale = self:GetEffectiveScale() or 1
            local dy = ((self.mmfResizeStartY or cy) - cy) / scale
            -- Ignore tiny cursor jitter so click without drag does nothing.
            if math.abs(dy) < 1 then
                return
            end
            local maxAllowed = windowController.GetDynamicMaxPopupHeight(self)
            local newH = math.max(MIN_POPUP_HEIGHT, math.min(maxAllowed, (self.mmfResizeStartH or POPUP_LAYOUT.height) + dy))
            self:SetSize(MIN_POPUP_WIDTH, newH)
        end)
    end)

    resizeGrip:SetScript("OnMouseUp", function()
        popup.mmfResizing = false
        popup:SetScript("OnUpdate", nil)
        windowController.ClampPopupHorizontal(popup)
        windowController.PersistPopupPosition()
        windowController.PersistPopupSize()
        LayoutTabButtons()
        UpdateSharedScrollBounds()
    end)

    popup:SetScript("OnSizeChanged", function(self, width, height)
        if math.abs((self:GetWidth() or 0) - MIN_POPUP_WIDTH) > 0.5 then
            self:SetWidth(MIN_POPUP_WIDTH)
            width = MIN_POPUP_WIDTH
        end
        local currentHeight = self:GetHeight() or height or POPUP_LAYOUT.height
        local dynamicMaxHeight = windowController.GetDynamicMaxPopupHeight(self)
        if currentHeight < MIN_POPUP_HEIGHT then
            self:SetHeight(MIN_POPUP_HEIGHT)
            currentHeight = MIN_POPUP_HEIGHT
        elseif currentHeight > dynamicMaxHeight then
            self:SetHeight(dynamicMaxHeight)
            currentHeight = dynamicMaxHeight
        end
        height = currentHeight
        windowController.ClampPopupHorizontal(self)
        if titleBar then
            titleBar:SetWidth(width or self:GetWidth())
            UpdateTitleWallpaperCrop()
        end
        if footer then
            footer:SetWidth(width or self:GetWidth())
        end
        LayoutTabButtons()
        UpdateSharedScrollBounds()
        windowController.PersistPopupSize()
    end)

    popup:Show()
    local function ApplyInitialPopupLayout()
        if not popup or not popup:IsShown() then return end
        ApplyPageWidths()
        LayoutTabButtons()
        SetActiveTab(defaultTab)
        ApplyInitialTitleBarState()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ApplyInitialPopupLayout)
    else
        ApplyInitialPopupLayout()
    end
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
    ApplyInitialTitleBarState()
end
