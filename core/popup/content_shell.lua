function MMF_CreatePopupContentShell(popup, config)
    if not popup then
        return nil
    end

    config = config or {}
    local popupLayout = config.popupLayout or {}
    local accentColor = config.accentColor or { 0.6, 0.4, 0.9 }
    local sidebarWallpaperAlpha = tonumber(config.sidebarWallpaperAlpha) or 0.10
    local setAspectCropTexCoords = config.setAspectCropTexCoords or MMF_SetAspectCropTexCoords

    local sidebarWidth = tonumber(config.sidebarWidth) or 180
    local headerHeight = tonumber(config.headerHeight) or 68
    local scrollbarWidth = tonumber(config.scrollbarWidth) or 12
    local scrollbarGap = tonumber(config.scrollbarGap) or 4

    local content = CreateFrame("Frame", nil, popup)
    content:SetPoint("TOPLEFT", 0, -(popupLayout.titleHeight or 28))
    content:SetPoint("BOTTOMRIGHT", 0, popupLayout.footerHeight or 32)
    content:SetClipsChildren(true)

    local tabContainer = CreateFrame("Frame", nil, content)
    tabContainer:SetPoint("TOPLEFT", popupLayout.contentSidePadding or 10, popupLayout.contentTopOffset or -4)
    tabContainer:SetPoint("BOTTOMRIGHT", -(popupLayout.contentSidePadding or 10), 0)
    tabContainer:SetClipsChildren(true)

    local tabBar = CreateFrame("Frame", nil, tabContainer)
    tabBar:SetPoint("TOPLEFT", 0, 0)
    tabBar:SetPoint("BOTTOMLEFT", 0, 0)
    tabBar:SetWidth(sidebarWidth)

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
    sidebarWallpaper:SetAlpha(sidebarWallpaperAlpha)
    if setAspectCropTexCoords then
        setAspectCropTexCoords(sidebarWallpaper, sidebarBg, 16 / 9)
    end

    local sidebarWallpaperTint = sidebarBg:CreateTexture(nil, "ARTWORK", nil, 1)
    sidebarWallpaperTint:SetPoint("TOPLEFT", 1, -1)
    sidebarWallpaperTint:SetPoint("BOTTOMRIGHT", -1, 1)
    sidebarWallpaperTint:SetColorTexture(0.02, 0.03, 0.04, 0.02)

    sidebarBg:SetScript("OnSizeChanged", function()
        if setAspectCropTexCoords then
            setAspectCropTexCoords(sidebarWallpaper, sidebarBg, 16 / 9)
        end
    end)

    local sidebarBrand = CreateFrame("Frame", nil, tabBar)
    sidebarBrand:SetPoint("TOPLEFT", 0, 0)
    sidebarBrand:SetPoint("TOPRIGHT", 0, 0)
    sidebarBrand:SetHeight(64)

    local sidebarBrandGlow = sidebarBrand:CreateTexture(nil, "ARTWORK")
    sidebarBrandGlow:SetPoint("BOTTOMLEFT", 0, 0)
    sidebarBrandGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarBrandGlow:SetHeight(2)
    sidebarBrandGlow:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.95)

    local sidebarBrandTitle = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 20, "")
    sidebarBrandTitle:SetPoint("TOPLEFT", 16, -16)
    sidebarBrandTitle:SetTextColor(0.96, 0.97, 0.98)
    sidebarBrandTitle:SetText("SETTINGS")

    local sidebarBrandSub = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandSub:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    sidebarBrandSub:SetPoint("TOPLEFT", sidebarBrandTitle, "BOTTOMLEFT", 0, -4)
    sidebarBrandSub:SetTextColor(accentColor[1], accentColor[2], accentColor[3])
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
    pageHeader:SetPoint("TOPRIGHT", -(scrollbarWidth + scrollbarGap), 0)
    pageHeader:SetHeight(headerHeight)
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
    if setAspectCropTexCoords then
        setAspectCropTexCoords(pageHeaderWallpaper, pageHeader, 16 / 9)
    end
    pageHeader:SetScript("OnSizeChanged", function()
        if setAspectCropTexCoords then
            setAspectCropTexCoords(pageHeaderWallpaper, pageHeader, 16 / 9)
        end
    end)

    local pageHeaderGlow = pageHeader:CreateTexture(nil, "ARTWORK")
    pageHeaderGlow:SetPoint("BOTTOMLEFT", 0, 0)
    pageHeaderGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    pageHeaderGlow:SetHeight(2)
    pageHeaderGlow:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.95)

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

    local pageScrollFrame = CreateFrame("ScrollFrame", nil, pageContainer)
    pageScrollFrame:SetPoint("TOPLEFT", pageHeader, "BOTTOMLEFT", 0, -8)
    pageScrollFrame:SetPoint("BOTTOMRIGHT", -(scrollbarWidth + scrollbarGap), 0)
    pageScrollFrame:EnableMouseWheel(true)
    pageScrollFrame:SetClipsChildren(true)

    local sharedScrollBar = CreateFrame("Slider", nil, pageContainer, "BackdropTemplate")
    sharedScrollBar:SetPoint("TOPRIGHT", 0, -2)
    sharedScrollBar:SetPoint("BOTTOMRIGHT", 0, 2)
    sharedScrollBar:SetWidth(scrollbarWidth)
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
    sharedThumb:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 1)
    sharedScrollBar:SetThumbTexture(sharedThumb)

    return {
        content = content,
        tabContainer = tabContainer,
        tabBar = tabBar,
        navButtonHost = navButtonHost,
        pageContainer = pageContainer,
        pageHeader = pageHeader,
        pageHeaderTitle = pageHeaderTitle,
        pageHeaderSubtitle = pageHeaderSubtitle,
        pageScrollFrame = pageScrollFrame,
        sharedScrollBar = sharedScrollBar,
        sidebarWidth = sidebarWidth,
    }
end
