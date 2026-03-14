function MMF_CreatePopupHeaderTitleBarShell(config)
    config = config or {}

    local popup = config.popup
    local popupWidth = config.popupWidth
    local popupLayout = config.popupLayout or {}
    local accentColor = config.accentColor or { 0.6, 0.4, 0.9 }
    local titleWallpaperAlpha = config.titleWallpaperAlpha or 0.03
    local setAspectCropTexCoords = config.setAspectCropTexCoords or MMF_SetAspectCropTexCoords
    local headerBranding = config.headerBranding or {}

    local titleBar = CreateFrame("Frame", nil, popup)
    titleBar:SetSize(popupWidth, popupLayout.titleHeight)
    titleBar:SetPoint("TOP", 0, 0)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.07, 0.09, 0.11, 1)

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
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("LEFT", 16, 1)
    title:SetText(headerBranding.titleText or "")

    local versionSuffix = titleBar:CreateFontString(nil, "OVERLAY")
    versionSuffix:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 8, "")
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
    closeX:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
    closeX:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
    local closeText = closeX:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    closeText:SetTextColor(0.5, 0.5, 0.5)
    closeX:SetScript("OnEnter", function()
        closeX:SetBackdropBorderColor(accentColor[1], accentColor[2], accentColor[3], 0.8)
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    closeX:SetScript("OnLeave", function()
        closeX:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        closeText:SetTextColor(0.5, 0.5, 0.5)
    end)
    closeX:SetScript("OnClick", function() popup:Hide() end)

    return {
        titleBar = titleBar,
        closeX = closeX,
        UpdateTitleWallpaperCrop = UpdateTitleWallpaperCrop,
    }
end
