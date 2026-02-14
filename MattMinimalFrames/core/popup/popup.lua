local Compat = _G.MMF_Compat

local POPUP_LAYOUT = (MMF_GetPopupLayout and MMF_GetPopupLayout()) or {
    width = Compat.IsTBC and 600 or 620,
    height = Compat.IsTBC and 616 or 620,
    titleHeight = 28,
    footerHeight = 32,
    tabHeight = 24,
    tabSpacing = 4,
    contentSidePadding = 10,
    contentTopOffset = -4,
    pageGap = 4,
    centerY = 50,
}

local CreateMinimalCheckbox = MMF_CreateMinimalCheckbox
local CreateMinimalSlider = MMF_CreateMinimalSlider

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

    if not forceShow and MattMinimalFramesDB.hideWelcomeMessage then return end

    -- If popup already exists, just show it and return
    if MMF_WelcomePopup then
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
    popup:SetSize(popupWidth, popupHeight)
    
    -- Apply saved GUI scale
    local guiScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
    MattMinimalFramesDB.guiScale = guiScale
    popup:SetScale(guiScale)
    
    -- Restore saved position or use default
    if MattMinimalFramesDB and MattMinimalFramesDB.popupPosition then
        local pos = MattMinimalFramesDB.popupPosition
        popup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    else
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, POPUP_LAYOUT.centerY)
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
    titleBar:SetSize(popupWidth, POPUP_LAYOUT.titleHeight)
    titleBar:SetPoint("TOP", 0, 0)
    
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.12, 0.12, 0.15, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cffffffffMatt's Minimal Frames ")
    
    -- Add version suffix with smaller font
    local versionSuffix = titleBar:CreateFontString(nil, "OVERLAY")
    versionSuffix:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 8, "")
    versionSuffix:SetPoint("LEFT", title, "RIGHT", 2, 2)
    if Compat.IsTBC then
        versionSuffix:SetText("TBC EDITION")
        versionSuffix:SetTextColor(0.2, 0.9, 0.4)
    else
        versionSuffix:SetText("MIDNIGHT EDITION")
        versionSuffix:SetTextColor(0.6, 0.4, 0.9)
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
    
    -- Persistent themed value box for GUI scale (matches slider inputs)
    local scaleValueBg = CreateFrame("Frame", nil, guiScaleContainer, "BackdropTemplate")
    scaleValueBg:SetSize(36, 18)
    scaleValueBg:SetPoint("RIGHT", 0, 0)
    scaleValueBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    scaleValueBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
    scaleValueBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local scaleValue = CreateFrame("EditBox", nil, scaleValueBg)
    scaleValue:SetAllPoints(scaleValueBg)
    scaleValue:SetAutoFocus(false)
    scaleValue:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    scaleValue:SetJustifyH("CENTER")
    scaleValue:SetJustifyV("MIDDLE")
    scaleValue:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])

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
    
    local currentScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
    guiScaleSlider:SetValue(currentScale)
    scaleValue:SetText(string.format("%.1f", currentScale))

    -- Visual feedback on hover / focus
    scaleValueBg:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.6)
    end)
    scaleValueBg:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    scaleValue:SetScript("OnEnterPressed", function(self)
        local num = tonumber(self:GetText())
        if not num then
            self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
            return
        end
        num = (MMF_ClampGUIScale and MMF_ClampGUIScale(num)) or num
        guiScaleSlider:SetValue(num)
        MattMinimalFramesDB.guiScale = num
        if popup and popup:IsShown() then popup:SetScale(num) end
    end)
    scaleValue:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
        self:ClearFocus()
    end)
    scaleValue:SetScript("OnEditFocusLost", function(self)
        self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
    end)

    guiScaleSlider:SetScript("OnValueChanged", function(self, value)
        value = (MMF_ClampGUIScale and MMF_ClampGUIScale(value)) or value
        scaleValue:SetText(string.format("%.1f", value))
        MattMinimalFramesDB.guiScale = value
    end)
    
    guiScaleSlider:SetScript("OnMouseUp", function(self)
        local value = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
        MattMinimalFramesDB.guiScale = value
        if popup and popup:IsShown() then
            popup:SetScale(value)
        end
    end)

    -- Content area (between title bar and footer)
    local content = CreateFrame("Frame", nil, popup)
    content:SetPoint("TOPLEFT", 0, -POPUP_LAYOUT.titleHeight)
    content:SetPoint("BOTTOMRIGHT", 0, POPUP_LAYOUT.footerHeight)
    content:SetClipsChildren(true)

    local tabContainer = CreateFrame("Frame", nil, content)
    tabContainer:SetPoint("TOPLEFT", POPUP_LAYOUT.contentSidePadding, POPUP_LAYOUT.contentTopOffset)
    tabContainer:SetPoint("BOTTOMRIGHT", -POPUP_LAYOUT.contentSidePadding, 0)
    tabContainer:SetClipsChildren(true)

    local tabBar = CreateFrame("Frame", nil, tabContainer)
    tabBar:SetPoint("TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", 0, 0)
    tabBar:SetHeight(POPUP_LAYOUT.tabHeight)

    local pageContainer = CreateFrame("Frame", nil, tabContainer)
    pageContainer:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -POPUP_LAYOUT.pageGap)
    pageContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    pageContainer:SetClipsChildren(true)

    local function CreatePageFrame(parent)
        local page = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        page:SetPoint("TOPLEFT", 0, 0)
        page:SetPoint("BOTTOMRIGHT", 0, 0)
        page:SetClipsChildren(true)
        page:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        page:SetBackdropColor(0.08, 0.08, 0.1, 1)
        page:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)
        return page
    end

    local leftCol = CreatePageFrame(pageContainer)
    local unitFramesCol = CreatePageFrame(pageContainer)
    local middleCol = CreatePageFrame(pageContainer)
    local rightCol = CreatePageFrame(pageContainer)
    local profilesCol = CreatePageFrame(pageContainer)

    local castBarColorList
    local unitTextureList
    local unitFontList
    local playerIconModeList
    local targetIconModeList
    local scaleUnitList
    local nameTextUnitList
    local hpTextUnitList
    local hideNameTextUnitList
    local hideHPTextUnitList
    local auraTypeList
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
        if mode ~= "off" and mode ~= "class" and mode ~= "portrait" then
            mode = "off"
        end
        return mode
    end
    local GetCurrentTargetIconModeValue = function()
        local mode = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMode or nil
        if mode ~= "off" and mode ~= "class" and mode ~= "portrait" then
            mode = "off"
        end
        return mode
    end
    local UpdatePlayerIconModeButtonText = function() end
    local tabButtons = {}
    local allPages = {
        unitFramesCol,
        leftCol,
        middleCol,
        rightCol,
        profilesCol,
    }
    local tabPages
    local tabDefs
    if Compat.IsTBC then
        tabPages = {
            unitFramesCol,
            leftCol,
            profilesCol,
            rightCol,
        }
        tabDefs = {
            { label = "Unit Frames" },
            { label = "Auras / Power" },
            { label = "Profiles" },
            { label = "Tools" },
        }
    else
        tabPages = {
            unitFramesCol,
            leftCol,
            middleCol,
            profilesCol,
            rightCol,
        }
        tabDefs = {
            { label = "Unit Frames" },
            { label = "Auras / Power" },
            { label = "Current Class" },
            { label = "Profiles" },
            { label = "Tools" },
        }
    end

    local function SetTabButtonState(tabButton, isActive)
        tabButton.isActive = isActive
        if isActive then
            tabButton:SetBackdropColor(0.12, 0.12, 0.15, 1)
            tabButton:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.85)
            tabButton.text:SetTextColor(1, 1, 1)
        else
            tabButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
            tabButton:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
            tabButton.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end

    local function SetActiveTab(tabIndex)
        for _, page in ipairs(allPages) do
            page:Hide()
        end

        local activePage = tabPages[tabIndex]
        if activePage then
            activePage:Show()
        end

        for i, tabButton in ipairs(tabButtons) do
            SetTabButtonState(tabButton, i == tabIndex)
        end

        for _, listFrame in ipairs(closableLists) do
            CloseListFrame(listFrame)
        end

        MattMinimalFramesDB.popupActiveTab = tabIndex
    end

    local tabCount = #tabDefs
    local tabSpacing = POPUP_LAYOUT.tabSpacing
    local tabContentWidth = popupWidth - (POPUP_LAYOUT.contentSidePadding * 2)
    local totalGapWidth = (tabCount - 1) * tabSpacing
    local usableTabWidth = tabContentWidth - totalGapWidth
    local baseTabWidth = math.floor(usableTabWidth / tabCount)
    local extraPixels = usableTabWidth - (baseTabWidth * tabCount)
    local tabX = 0

    for i, def in ipairs(tabDefs) do
        local tabButton = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        local thisTabWidth = baseTabWidth
        if extraPixels > 0 then
            thisTabWidth = thisTabWidth + 1
            extraPixels = extraPixels - 1
        end
        tabButton:SetSize(thisTabWidth, POPUP_LAYOUT.tabHeight)
        tabButton:SetPoint("TOPLEFT", tabX, 0)
        tabX = tabX + thisTabWidth + tabSpacing
        tabButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })

        local tabButtonText = tabButton:CreateFontString(nil, "OVERLAY")
        tabButtonText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        tabButtonText:SetPoint("CENTER")
        tabButtonText:SetText(def.label)
        tabButton.text = tabButtonText

        tabButton:SetScript("OnEnter", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)
                self.text:SetTextColor(0.9, 0.9, 0.9)
            end
        end)
        tabButton:SetScript("OnLeave", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
                self.text:SetTextColor(0.7, 0.7, 0.7)
            end
        end)
        tabButton:SetScript("OnClick", function()
            if PlaySoundFile and IsUISoundsEnabled() then
                PlaySoundFile("Interface\\AddOns\\MattMinimalFrames\\Sounds\\click.mp3", "Master")
            end
            SetActiveTab(i)
        end)

        tabButtons[i] = tabButton
    end

    ---------------------------------------------------
    local unitFramesState = MMF_CreateUnitFramesSection(unitFramesCol, popup, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider, GetCurrentPlayerIconModeValue, GetCurrentTargetIconModeValue)
    castBarColorList = unitFramesState.castBarColorList
    unitTextureList = unitFramesState.unitTextureList
    unitFontList = unitFramesState.unitFontList
    playerIconModeList = unitFramesState.playerIconModeList
    targetIconModeList = unitFramesState.targetIconModeList
    scaleUnitList = unitFramesState.scaleUnitList
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
    RegisterClosableList(playerIconModeList)
    RegisterClosableList(targetIconModeList)
    RegisterClosableList(scaleUnitList)
    RegisterClosableList(nameTextUnitList)
    RegisterClosableList(hpTextUnitList)
    RegisterClosableList(hideNameTextUnitList)
    RegisterClosableList(hideHPTextUnitList)

    local aurasState = MMF_CreateAurasPowerSection(leftCol, popup, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider)
    if type(aurasState) == "table" then
        auraTypeList = aurasState.auraTypeList
    end
    RegisterClosableList(auraTypeList)

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
    SetActiveTab(defaultTab)

    MMF_CreatePopupFooter(popup, popupWidth, ACCENT_COLOR, POPUP_LAYOUT.footerHeight)

    popup:Show()
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
end
