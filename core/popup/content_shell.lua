function MMF_CreatePopupContentShell(popup, config)
    if not popup then
        return nil
    end

    config = config or {}
    local popupLayout = config.popupLayout or {}
    local accentColor = config.accentColor or { 0.6, 0.4, 0.9 }
    local theme = (MMF_GetPopupTheme and MMF_GetPopupTheme()) or {}
    local fontPath = theme.font or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local surface = theme.surface or { 0.045, 0.055, 0.068, 0.98 }
    local surfaceRaised = theme.surfaceRaised or { 0.060, 0.075, 0.090, 0.98 }
    local border = theme.border or { 0.145, 0.175, 0.205, 1 }
    local text = theme.text or { 0.92, 0.94, 0.96, 1 }
    local textMuted = theme.textMuted or { 0.62, 0.67, 0.72, 1 }
    local sidebarWallpaperAlpha = tonumber(config.sidebarWallpaperAlpha) or 0.10
    local setAspectCropTexCoords = config.setAspectCropTexCoords or MMF_SetAspectCropTexCoords

    local sidebarWidth = tonumber(config.sidebarWidth) or 180
    local headerHeight = tonumber(config.headerHeight) or 72
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
    sidebarBg:SetBackdropColor(surface[1], surface[2], surface[3], 0.92)
    sidebarBg:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)

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
    sidebarBrand:SetHeight(68)

    local sidebarBrandGlow = sidebarBrand:CreateTexture(nil, "ARTWORK")
    sidebarBrandGlow:SetPoint("BOTTOMLEFT", 0, 0)
    sidebarBrandGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarBrandGlow:SetHeight(2)
    sidebarBrandGlow:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.95)

    local sidebarBrandTitle = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandTitle:SetFont(fontPath, 18, "")
    sidebarBrandTitle:SetPoint("TOPLEFT", 16, -14)
    sidebarBrandTitle:SetTextColor(text[1], text[2], text[3])
    sidebarBrandTitle:SetText("SETTINGS")

    local sidebarBrandSub = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandSub:SetFont(fontPath, 8, "")
    sidebarBrandSub:SetPoint("TOPLEFT", sidebarBrandTitle, "BOTTOMLEFT", 0, -5)
    sidebarBrandSub:SetTextColor(textMuted[1], textMuted[2], textMuted[3])
    sidebarBrandSub:SetText("MATT'S MINIMAL FRAMES")

    local navButtonHost = CreateFrame("Frame", nil, tabBar)
    navButtonHost:SetPoint("TOPLEFT", sidebarBrand, "BOTTOMLEFT", 0, -12)
    navButtonHost:SetPoint("TOPRIGHT", sidebarBrand, "BOTTOMRIGHT", 0, -12)
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
    pageHeader:SetBackdropColor(surfaceRaised[1], surfaceRaised[2], surfaceRaised[3], surfaceRaised[4] or 0.98)
    pageHeader:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)

    local pageHeaderWallpaper = pageHeader:CreateTexture(nil, "ARTWORK")
    pageHeaderWallpaper:SetPoint("TOPLEFT", 1, -1)
    pageHeaderWallpaper:SetPoint("BOTTOMRIGHT", -1, 1)
    pageHeaderWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw.png")
    pageHeaderWallpaper:SetAlpha(0.08)
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

    local pageHeaderKicker = pageHeader:CreateFontString(nil, "OVERLAY")
    pageHeaderKicker:SetFont(fontPath, 8, "")
    pageHeaderKicker:SetPoint("TOPLEFT", 16, -10)
    pageHeaderKicker:SetTextColor(accentColor[1], accentColor[2], accentColor[3])
    pageHeaderKicker:SetText("CONFIGURATION")

    local pageHeaderTitle = pageHeader:CreateFontString(nil, "OVERLAY")
    pageHeaderTitle:SetFont(fontPath, 17, "")
    pageHeaderTitle:SetPoint("TOPLEFT", 16, -24)
    pageHeaderTitle:SetTextColor(text[1], text[2], text[3])

    local pageHeaderSubtitle = pageHeader:CreateFontString(nil, "OVERLAY")
    pageHeaderSubtitle:SetFont(fontPath, 9, "")
    pageHeaderSubtitle:SetPoint("TOPLEFT", pageHeaderTitle, "BOTTOMLEFT", 0, -5)
    pageHeaderSubtitle:SetPoint("TOPRIGHT", pageHeader, "TOPRIGHT", -14, -46)
    pageHeaderSubtitle:SetJustifyH("LEFT")
    pageHeaderSubtitle:SetTextColor(textMuted[1], textMuted[2], textMuted[3])

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
    sharedScrollBar:SetBackdropColor(theme.input and theme.input[1] or 0.025, theme.input and theme.input[2] or 0.032, theme.input and theme.input[3] or 0.042, 1)
    sharedScrollBar:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    local sharedThumb = sharedScrollBar:CreateTexture(nil, "OVERLAY")
    sharedThumb:SetSize(8, 28)
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
