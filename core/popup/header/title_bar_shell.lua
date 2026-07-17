function MMF_CreatePopupHeaderTitleBarShell(config)
    config = config or {}

    local popup = config.popup
    local popupWidth = config.popupWidth
    local popupLayout = config.popupLayout or {}
    local accentColor = config.accentColor or { 0.6, 0.4, 0.9 }
    local theme = (MMF_GetPopupTheme and MMF_GetPopupTheme()) or {}
    local fontPath = theme.font or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local surfaceRaised = theme.surfaceRaised or { 0.060, 0.075, 0.090, 0.98 }
    local input = theme.input or { 0.025, 0.032, 0.042, 1 }
    local border = theme.border or { 0.145, 0.175, 0.205, 1 }
    local textMuted = theme.textMuted or { 0.62, 0.67, 0.72, 1 }
    local titleWallpaperAlpha = config.titleWallpaperAlpha or 0.03
    local setAspectCropTexCoords = config.setAspectCropTexCoords or MMF_SetAspectCropTexCoords
    local headerBranding = config.headerBranding or {}

    local titleBar = CreateFrame("Frame", nil, popup)
    titleBar:SetSize(popupWidth, popupLayout.titleHeight)
    titleBar:SetPoint("TOP", 0, 0)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(surfaceRaised[1], surfaceRaised[2], surfaceRaised[3], 1)

    local titleWallpaper = titleBar:CreateTexture(nil, "ARTWORK")
    titleWallpaper:SetPoint("TOPLEFT", 1, -1)
    titleWallpaper:SetPoint("BOTTOMRIGHT", -1, 1)
    titleWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw.png")
    titleWallpaper:SetAlpha(titleWallpaperAlpha)

    local function UpdateTitleWallpaperCrop()
        setAspectCropTexCoords(titleWallpaper, titleBar, 16 / 9)
    end
    UpdateTitleWallpaperCrop()

    local titleWallpaperTint = titleBar:CreateTexture(nil, "ARTWORK")
    titleWallpaperTint:SetPoint("TOPLEFT", 1, -1)
    titleWallpaperTint:SetPoint("BOTTOMRIGHT", -1, 1)
    titleWallpaperTint:SetColorTexture(0.02, 0.03, 0.04, 0.22)

    local titleGlow = titleBar:CreateTexture(nil, "ARTWORK")
    titleGlow:SetPoint("BOTTOMLEFT", 0, 0)
    titleGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    titleGlow:SetHeight(2)
    titleGlow:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.95)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 12, "")
    title:SetPoint("LEFT", 16, 1)
    title:SetText(headerBranding.titleText or "")

    local versionSuffix = titleBar:CreateFontString(nil, "OVERLAY")
    versionSuffix:SetFont(fontPath, 8, "")
    versionSuffix:SetPoint("LEFT", title, "RIGHT", 4, 2)
    versionSuffix:SetText(headerBranding.suffixText or "")
    local suffixColor = headerBranding.suffixColor or { 0.6, 0.4, 0.9 }
    versionSuffix:SetTextColor(
        suffixColor[1] or 0.6,
        suffixColor[2] or 0.4,
        suffixColor[3] or 0.9
    )

    local closeX = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeX:SetSize(18, 18)
    closeX:SetPoint("RIGHT", -9, 0)
    closeX:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    closeX:SetBackdropColor(input[1], input[2], input[3], input[4] or 1)
    closeX:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    local closeText = closeX:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(fontPath, 9, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeText:SetTextColor(textMuted[1], textMuted[2], textMuted[3])
    closeX:SetScript("OnEnter", function()
        closeX:SetBackdropBorderColor(accentColor[1], accentColor[2], accentColor[3], 0.8)
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    closeX:SetScript("OnLeave", function()
        closeX:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        closeText:SetTextColor(textMuted[1], textMuted[2], textMuted[3])
    end)
    closeX:SetScript("OnClick", function() popup:Hide() end)

    return {
        titleBar = titleBar,
        closeX = closeX,
        UpdateTitleWallpaperCrop = UpdateTitleWallpaperCrop,
    }
end
