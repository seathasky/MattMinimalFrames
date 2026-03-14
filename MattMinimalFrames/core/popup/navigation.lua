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
        local buttonHeight = 42
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
            tabButton:SetBackdropColor(0.06, 0.10, 0.12, 0.78)
            tabButton:SetBackdropBorderColor(0.16, 0.22, 0.24, 1)
            tabButton.text:SetTextColor(1, 1, 1)
            tabButton.activeLine:SetAlpha(1)
            tabButton.glow:SetAlpha(0.16)
            tabButton.activeRail:SetAlpha(1)
        else
            tabButton:SetBackdropColor(0.03, 0.04, 0.05, 0.70)
            tabButton:SetBackdropBorderColor(0.12, 0.14, 0.16, 1)
            tabButton.text:SetTextColor(0.68, 0.72, 0.76)
            tabButton.activeLine:SetAlpha(0)
            tabButton.glow:SetAlpha(0)
            tabButton.activeRail:SetAlpha(0)
        end
    end

    local function SetActiveTab(tabIndex)
        local subtitleByLabel = {
            ["Unit Frames"] = "Frame sizing, text, visibility, style, and cast bar controls.",
            ["Auras / Power"] = "Aura behavior, power options, and related display settings.",
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
        tabButton:SetBackdropColor(0.04, 0.05, 0.06, 0.96)
        tabButton:SetBackdropBorderColor(0.12, 0.14, 0.16, 1)

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
        tabButtonText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        tabButtonText:SetPoint("LEFT", 16, 1)
        tabButtonText:SetJustifyH("LEFT")
        tabButtonText:SetText(def.label)
        tabButton.text = tabButtonText

        tabButton:SetScript("OnEnter", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(accentColor[1], accentColor[2], accentColor[3], 0.4)
                self.text:SetTextColor(0.9, 0.93, 0.95)
                self.activeLine:SetAlpha(0.45)
            end
        end)
        tabButton:SetScript("OnLeave", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(0.12, 0.14, 0.16, 1)
                self.text:SetTextColor(0.68, 0.72, 0.76)
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
