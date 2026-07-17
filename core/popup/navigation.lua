function MMF_CreatePopupNavigationController(config)
    config = config or {}

    local tabBar = config.tabBar
    local navButtonHost = config.navButtonHost
    local tabDefs = config.tabDefs or {}
    local tabPages = config.tabPages or {}
    local allPages = config.allPages or {}
    local pageHeaderTitle = config.pageHeaderTitle
    local pageHeaderSubtitle = config.pageHeaderSubtitle
    local pageScrollFrame = config.pageScrollFrame
    local sharedScrollBar = config.sharedScrollBar
    local accentColor = config.accentColor or { 0.6, 0.4, 0.9 }
    local theme = (MMF_GetPopupTheme and MMF_GetPopupTheme()) or {}
    local fontPath = theme.font or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local surface = theme.surface or { 0.045, 0.055, 0.068, 0.98 }
    local surfaceRaised = theme.surfaceRaised or { 0.060, 0.075, 0.090, 0.98 }
    local surfaceHover = theme.surfaceHover or { 0.080, 0.100, 0.118, 1 }
    local border = theme.border or { 0.145, 0.175, 0.205, 1 }
    local text = theme.text or { 0.92, 0.94, 0.96, 1 }
    local textMuted = theme.textMuted or { 0.62, 0.67, 0.72, 1 }
    local popupLayout = config.popupLayout or {}
    local sidebarWidth = config.sidebarWidth or 180
    local closableLists = config.closableLists or {}
    local closeListFrame = config.closeListFrame or function() end
    local updateSharedScrollBounds = config.updateSharedScrollBounds or function() end
    local isUISoundsEnabledFn = config.isUISoundsEnabledFn or function() return true end
    local setActivePage = config.setActivePage or function() end
    local onUnitFramesTabActivated = config.onUnitFramesTabActivated or function() end

    local tabButtons = {}

    local function LayoutTabButtons()
        local tabSpacing = popupLayout.tabSpacing
        local buttonHeight = popupLayout.tabHeight or 42
        local tabY = 0

        for _, tabButton in ipairs(tabButtons) do
            tabButton:SetSize(sidebarWidth - 16, buttonHeight)
            tabButton:ClearAllPoints()
            tabButton:SetPoint("TOPLEFT", navButtonHost, "TOPLEFT", 8, -tabY)
            tabY = tabY + buttonHeight + tabSpacing
        end
    end

    local function SetTabButtonState(tabButton, isActive)
        tabButton.isActive = isActive
        if isActive then
            tabButton:SetBackdropColor(surfaceRaised[1], surfaceRaised[2], surfaceRaised[3], 1)
            tabButton:SetBackdropBorderColor(accentColor[1], accentColor[2], accentColor[3], 0.55)
            tabButton.text:SetTextColor(text[1], text[2], text[3])
            tabButton.activeLine:SetAlpha(0)
            tabButton.glow:SetAlpha(0.10)
            tabButton.activeRail:SetAlpha(1)
        else
            tabButton:SetBackdropColor(surface[1], surface[2], surface[3], 0.78)
            tabButton:SetBackdropBorderColor(border[1], border[2], border[3], 0.72)
            tabButton.text:SetTextColor(textMuted[1], textMuted[2], textMuted[3])
            tabButton.activeLine:SetAlpha(0)
            tabButton.glow:SetAlpha(0)
            tabButton.activeRail:SetAlpha(0)
        end
    end

    local function SetActiveTab(tabIndex)
        local subtitleByLabel = {
            ["Unit Frames"] = "Frame sizing, text, visibility, style, and cast bar controls.",
            ["Auras / Power"] = "Aura behavior, power options, and related display settings.",
            ["Party / Raid"] = "Blizzard party and raid frame options.",
            ["TBC Features"] = "TBC-specific gameplay feature toggles.",
            ["ERA Features"] = "Classic Era-specific gameplay feature toggles.",
            ["Current Class"] = "Class-specific resources and active spec customization.",
            ["Profiles"] = "Manage, copy, and delete settings profiles.",
            ["Tools"] = "Utility settings and addon-wide helper tools.",
        }
        for _, page in ipairs(allPages) do
            page:Hide()
        end

        local activePage = tabPages[tabIndex]
        setActivePage(activePage)
        if activePage then
            activePage:Show()
            pageScrollFrame:SetScrollChild(activePage)
            sharedScrollBar:SetValue(0)
            pageScrollFrame:SetVerticalScroll(0)
            updateSharedScrollBounds()
        end

        for i, tabButton in ipairs(tabButtons) do
            SetTabButtonState(tabButton, i == tabIndex)
        end

        local activeDef = tabDefs[tabIndex]
        local activeLabel = activeDef and activeDef.label or "Settings"
        pageHeaderTitle:SetText(activeLabel)
        pageHeaderSubtitle:SetText(subtitleByLabel[activeLabel] or "")

        for _, listFrame in ipairs(closableLists) do
            closeListFrame(listFrame)
        end

        if tabIndex == 1 then
            onUnitFramesTabActivated()
        end

        MattMinimalFramesDB.popupActiveTab = tabIndex
    end

    for i, def in ipairs(tabDefs) do
        local tabButton = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        tabButton:SetSize(1, popupLayout.tabHeight or 24)
        tabButton:SetPoint("TOPLEFT", 0, 0)
        tabButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        tabButton:SetBackdropColor(surface[1], surface[2], surface[3], 0.96)
        tabButton:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)

        local tabGlow = tabButton:CreateTexture(nil, "BACKGROUND")
        tabGlow:SetPoint("TOPLEFT", -2, -2)
        tabGlow:SetPoint("BOTTOMRIGHT", 2, 2)
        tabGlow:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 1)
        tabGlow:SetAlpha(0)
        tabButton.glow = tabGlow

        local tabActiveRail = tabButton:CreateTexture(nil, "ARTWORK")
        tabActiveRail:SetPoint("TOPLEFT", 0, 0)
        tabActiveRail:SetPoint("BOTTOMLEFT", 0, 0)
        tabActiveRail:SetWidth(3)
        tabActiveRail:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 1)
        tabActiveRail:SetAlpha(0)
        tabButton.activeRail = tabActiveRail

        local tabActiveLine = tabButton:CreateTexture(nil, "ARTWORK")
        tabActiveLine:SetPoint("BOTTOMLEFT", 0, 0)
        tabActiveLine:SetPoint("BOTTOMRIGHT", 0, 0)
        tabActiveLine:SetHeight(2)
        tabActiveLine:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 1)
        tabActiveLine:SetAlpha(0)
        tabButton.activeLine = tabActiveLine

        local tabButtonText = tabButton:CreateFontString(nil, "OVERLAY")
        tabButtonText:SetFont(fontPath, 11, "")
        tabButtonText:SetPoint("LEFT", 16, 1)
        tabButtonText:SetPoint("RIGHT", -12, 1)
        tabButtonText:SetJustifyH("LEFT")
        tabButtonText:SetText(def.label)
        tabButton.text = tabButtonText

        tabButton:SetScript("OnEnter", function(self)
            if not self.isActive then
                self:SetBackdropColor(surfaceHover[1], surfaceHover[2], surfaceHover[3], surfaceHover[4] or 1)
                self:SetBackdropBorderColor(accentColor[1], accentColor[2], accentColor[3], 0.4)
                self.text:SetTextColor(text[1], text[2], text[3])
                self.activeLine:SetAlpha(0.35)
            end
        end)
        tabButton:SetScript("OnLeave", function(self)
            if not self.isActive then
                self:SetBackdropColor(surface[1], surface[2], surface[3], 0.78)
                self:SetBackdropBorderColor(border[1], border[2], border[3], 0.72)
                self.text:SetTextColor(textMuted[1], textMuted[2], textMuted[3])
                self.activeLine:SetAlpha(0)
            end
        end)
        tabButton:SetScript("OnClick", function()
            if PlaySoundFile and isUISoundsEnabledFn() then
                PlaySoundFile("Interface\\AddOns\\MattMinimalFrames\\Sounds\\click.mp3", "Master")
            end
            SetActiveTab(i)
        end)

        tabButtons[i] = tabButton
    end

    return {
        LayoutTabButtons = LayoutTabButtons,
        SetActiveTab = SetActiveTab,
        tabButtons = tabButtons,
    }
end
