function MMF_CreatePopupFooter(popup, popupWidth, accentColor, footerHeight)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local height = footerHeight or 40
    -- Footer
    local footer = CreateFrame("Frame", nil, popup)
    footer:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", 0, 0)
    footer:SetHeight(height)
    
    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(0.03, 0.03, 0.04, 1)

    local footerWallpaper = footer:CreateTexture(nil, "ARTWORK")
    footerWallpaper:SetPoint("TOPLEFT", 1, -1)
    footerWallpaper:SetPoint("BOTTOMRIGHT", -1, 1)
    footerWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw.png")
    footerWallpaper:SetAlpha(0.10)

    local function UpdateFooterWallpaperCrop()
        local w = math.max(1, footer:GetWidth() or 1)
        local h = math.max(1, footer:GetHeight() or 1)
        local imageAspect = 16 / 9
        local frameAspect = w / h
        if frameAspect > imageAspect then
            local visibleV = imageAspect / frameAspect
            local padV = (1 - visibleV) * 0.5
            footerWallpaper:SetTexCoord(0, 1, padV, 1 - padV)
        else
            local visibleU = frameAspect / imageAspect
            local padU = (1 - visibleU) * 0.5
            footerWallpaper:SetTexCoord(padU, 1 - padU, 0, 1)
        end
    end
    UpdateFooterWallpaperCrop()
    footer:SetScript("OnSizeChanged", function()
        UpdateFooterWallpaperCrop()
    end)

    local footerWallpaperTint = footer:CreateTexture(nil, "ARTWORK")
    footerWallpaperTint:SetPoint("TOPLEFT", 1, -1)
    footerWallpaperTint:SetPoint("BOTTOMRIGHT", -1, 1)
    footerWallpaperTint:SetColorTexture(0.02, 0.03, 0.04, 0.22)

    -- Version text (bottom-left)
    local versionText = footer:CreateFontString(nil, "OVERLAY")
    versionText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    versionText:SetPoint("LEFT", footer, "LEFT", 12, 0)
    versionText:SetJustifyH("LEFT")
    versionText:SetTextColor(1.0, 0.86, 0.2)
    versionText:SetText("v.6.1.6")

    -- Current class display (bottom-right)
    local classInfo = CreateFrame("Frame", nil, footer)
    classInfo:SetSize(138, 24)
    classInfo:SetPoint("RIGHT", -34, 0)

    local classIcon = classInfo:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(24, 24)
    classIcon:SetPoint("RIGHT", 0, 0)
    classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")

    local playerName = UnitName("player")
    local _, classToken = UnitClass("player")
    local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if classToken then
        classIcon:SetTexture("Interface\\ICONS\\ClassIcon_" .. classToken)
        classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        classIcon:SetTexCoord(0, 1, 0, 1)
    end

    local classNameText = classInfo:CreateFontString(nil, "OVERLAY")
    classNameText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    classNameText:SetPoint("RIGHT", classIcon, "LEFT", -6, 0)
    classNameText:SetWidth(96)
    classNameText:SetJustifyH("RIGHT")
    classNameText:SetText(playerName or "Player")
    if classColor then
        classNameText:SetTextColor(classColor.r, classColor.g, classColor.b)
    else
        classNameText:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    end

    return footer

end
