local Compat = _G.MMF_Compat

local POPUP_LAYOUT = (MMF_GetPopupLayout and MMF_GetPopupLayout()) or {
    width = Compat.IsTBC and 914 or 934,
    height = Compat.IsTBC and 750 or 750,
    titleHeight = 28,
    footerHeight = 32,
    tabHeight = 24,
    tabSpacing = 4,
    contentSidePadding = 10,
    contentTopOffset = -4,
    pageGap = 4,
    centerY = 50,
    unitFramesContentHeight = 880,
    aurasPowerContentHeight = 760,
    currentClassContentHeight = 640,
    profilesContentHeight = 640,
    toolsContentHeight = 640,
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
    local MIN_POPUP_WIDTH = POPUP_LAYOUT.width
    local chromeHeight = (POPUP_LAYOUT.titleHeight or 28)
        + (POPUP_LAYOUT.footerHeight or 32)
        - (POPUP_LAYOUT.contentTopOffset or -4)
        + (POPUP_LAYOUT.tabHeight or 24)
        + (POPUP_LAYOUT.pageGap or 4)
    local MIN_POPUP_HEIGHT = chromeHeight + 8
    local MAX_POPUP_HEIGHT = (POPUP_LAYOUT.unitFramesContentHeight or 980) + chromeHeight
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

    local function PersistPopupSize()
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB.popupSize = {
            width = math.floor((popup:GetWidth() or POPUP_LAYOUT.width) + 0.5),
            height = math.floor((popup:GetHeight() or POPUP_LAYOUT.height) + 0.5),
        }
    end
    local function PersistPopupPosition()
        local left = popup:GetLeft()
        local top = popup:GetTop()
        if left and top then
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.popupPosition = { left = left, top = top }
        end
    end
    local function ClampPopupHorizontal(self)
        if not self or not UIParent then return end
        local left = self:GetLeft()
        local right = self:GetRight()
        local top = self:GetTop()
        if not left or not right or not top then return end

        local parentLeft = UIParent:GetLeft() or 0
        local parentRight = UIParent:GetRight()
        if not parentRight then
            local parentWidth = UIParent.GetWidth and UIParent:GetWidth() or 0
            parentRight = parentLeft + parentWidth
        end

        local width = right - left
        local clampedLeft = left
        if width >= (parentRight - parentLeft) then
            clampedLeft = parentLeft
        else
            if left < parentLeft then
                clampedLeft = parentLeft
            end
            if right > parentRight then
                clampedLeft = parentRight - width
            end
        end

        if math.abs(clampedLeft - left) > 0.5 then
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", clampedLeft, top)
        end
    end
    
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
    ClampPopupHorizontal(popup)
    
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
        ClampPopupHorizontal(self)
        PersistPopupPosition()
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

    local SCROLLBAR_WIDTH = 12
    local SCROLLBAR_GAP = 4

    local pageScrollFrame = CreateFrame("ScrollFrame", nil, pageContainer)
    pageScrollFrame:SetPoint("TOPLEFT", 0, 0)
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
        page:SetBackdropColor(0.08, 0.08, 0.1, 1)
        page:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.5)
        return page
    end

    local leftCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.aurasPowerContentHeight)
    local unitFramesCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.unitFramesContentHeight)
    local middleCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.currentClassContentHeight)
    local rightCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.toolsContentHeight)
    local profilesCol = CreatePageFrame(pageScrollFrame, POPUP_LAYOUT.profilesContentHeight)

    local castBarColorList
    local unitTextureList
    local unitFontList
    local playerIconModeList
    local targetIconModeList
    local scaleUnitList
    local frameTextUnitList
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
    local tabButtons = {}
    local allPages = {
        unitFramesCol,
        leftCol,
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

    local function UpdateSharedScrollBounds()
        local page = activePage
        if not page then
            sharedScrollBar:SetMinMaxValues(0, 0)
            sharedScrollBar:SetValue(0)
            pageScrollFrame:SetVerticalScroll(0)
            return
        end

        local viewHeight = pageScrollFrame:GetHeight() or 0
        local contentHeight = page:GetHeight() or 0
        local maxScroll = math.max(0, contentHeight - viewHeight)
        local current = sharedScrollBar:GetValue() or 0
        if current > maxScroll then
            current = maxScroll
        end

        sharedScrollBar:SetMinMaxValues(0, maxScroll)
        sharedScrollBar:SetValue(current)
        sharedScrollBar:SetEnabled(maxScroll > 0)
        sharedScrollBar:SetAlpha(maxScroll > 0 and 1 or 0.45)
        pageScrollFrame:SetVerticalScroll(current)
    end

    sharedScrollBar:SetScript("OnValueChanged", function(self, value)
        pageScrollFrame:SetVerticalScroll(value or 0)
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

    local function LayoutTabButtons()
        local tabCount = #tabDefs
        local tabSpacing = POPUP_LAYOUT.tabSpacing
        local tabContentWidth = popup:GetWidth() - (POPUP_LAYOUT.contentSidePadding * 2) - (SCROLLBAR_WIDTH + SCROLLBAR_GAP)
        local totalGapWidth = (tabCount - 1) * tabSpacing
        local usableTabWidth = tabContentWidth - totalGapWidth
        local baseTabWidth = math.floor(usableTabWidth / tabCount)
        local extraPixels = usableTabWidth - (baseTabWidth * tabCount)
        local tabX = 0

        for i, tabButton in ipairs(tabButtons) do
            local thisTabWidth = baseTabWidth
            if extraPixels > 0 then
                thisTabWidth = thisTabWidth + 1
                extraPixels = extraPixels - 1
            end
            tabButton:SetSize(thisTabWidth, POPUP_LAYOUT.tabHeight)
            tabButton:ClearAllPoints()
            tabButton:SetPoint("TOPLEFT", tabX, 0)
            tabX = tabX + thisTabWidth + tabSpacing
        end
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

        activePage = tabPages[tabIndex]
        if activePage then
            activePage:Show()
            pageScrollFrame:SetScrollChild(activePage)
            sharedScrollBar:SetValue(0)
            pageScrollFrame:SetVerticalScroll(0)
            UpdateSharedScrollBounds()
        end

        for i, tabButton in ipairs(tabButtons) do
            SetTabButtonState(tabButton, i == tabIndex)
        end

        for _, listFrame in ipairs(closableLists) do
            CloseListFrame(listFrame)
        end

        MattMinimalFramesDB.popupActiveTab = tabIndex
    end

    for i, def in ipairs(tabDefs) do
        local tabButton = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        tabButton:SetSize(1, POPUP_LAYOUT.tabHeight)
        tabButton:SetPoint("TOPLEFT", 0, 0)
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
    LayoutTabButtons()

    ---------------------------------------------------
    local unitFramesState = MMF_CreateUnitFramesSection(unitFramesCol, popup, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider, GetCurrentPlayerIconModeValue, GetCurrentTargetIconModeValue)
    castBarColorList = unitFramesState.castBarColorList
    unitTextureList = unitFramesState.unitTextureList
    unitFontList = unitFramesState.unitFontList
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
    RegisterClosableList(playerIconModeList)
    RegisterClosableList(targetIconModeList)
    RegisterClosableList(scaleUnitList)
    RegisterClosableList(frameTextUnitList)
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
            local newH = math.max(MIN_POPUP_HEIGHT, math.min(MAX_POPUP_HEIGHT, (self.mmfResizeStartH or POPUP_LAYOUT.height) + dy))
            self:SetSize(MIN_POPUP_WIDTH, newH)
        end)
    end)

    resizeGrip:SetScript("OnMouseUp", function()
        popup.mmfResizing = false
        popup:SetScript("OnUpdate", nil)
        ClampPopupHorizontal(popup)
        PersistPopupPosition()
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB.popupSize = {
            width = math.floor((popup:GetWidth() or POPUP_LAYOUT.width) + 0.5),
            height = math.floor((popup:GetHeight() or POPUP_LAYOUT.height) + 0.5),
        }
        LayoutTabButtons()
        UpdateSharedScrollBounds()
    end)

    popup:SetScript("OnSizeChanged", function(self, width, height)
        if math.abs((self:GetWidth() or 0) - MIN_POPUP_WIDTH) > 0.5 then
            self:SetWidth(MIN_POPUP_WIDTH)
            width = MIN_POPUP_WIDTH
        end
        local currentHeight = self:GetHeight() or height or POPUP_LAYOUT.height
        if currentHeight < MIN_POPUP_HEIGHT then
            self:SetHeight(MIN_POPUP_HEIGHT)
            currentHeight = MIN_POPUP_HEIGHT
        elseif currentHeight > MAX_POPUP_HEIGHT then
            self:SetHeight(MAX_POPUP_HEIGHT)
            currentHeight = MAX_POPUP_HEIGHT
        end
        height = currentHeight
        ClampPopupHorizontal(self)
        if titleBar then
            titleBar:SetWidth(width or self:GetWidth())
        end
        if footer then
            footer:SetWidth(width or self:GetWidth())
        end
        LayoutTabButtons()
        UpdateSharedScrollBounds()
        PersistPopupSize()
    end)

    popup:Show()
    C_Timer.After(0, function()
        if not popup or not popup:IsShown() then return end
        ApplyPageWidths()
        LayoutTabButtons()
        UpdateSharedScrollBounds()
    end)
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
end
