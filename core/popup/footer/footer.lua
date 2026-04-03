function MMF_CreatePopupFooter(popup, _popupWidth, accentColor, footerHeight)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local DISCORD_URL = "https://discord.gg/9w6ZdaksDX"
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
        MMF_SetAspectCropTexCoords(footerWallpaper, footer, 16 / 9)
    end
    UpdateFooterWallpaperCrop()

    local footerWallpaperTint = footer:CreateTexture(nil, "ARTWORK")
    footerWallpaperTint:SetPoint("TOPLEFT", 1, -1)
    footerWallpaperTint:SetPoint("BOTTOMRIGHT", -1, 1)
    footerWallpaperTint:SetColorTexture(0.02, 0.03, 0.04, 0.22)

    -- Version text (bottom-left)
    local versionText = footer:CreateFontString(nil, "OVERLAY")
    versionText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    versionText:SetPoint("LEFT", footer, "LEFT", 12, 0)
    versionText:SetJustifyH("LEFT")
    versionText:SetWordWrap(false)
    versionText:SetTextColor(1.0, 0.86, 0.2)
    versionText:SetText((MMF_GetPopupFooterVersionText and MMF_GetPopupFooterVersionText()) or "")

    local discordButton = CreateFrame("Button", nil, footer)
    discordButton:SetSize(24, 24)

    local discordIcon = discordButton:CreateTexture(nil, "ARTWORK")
    discordIcon:SetAllPoints(discordButton)
    discordIcon:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\discord.png")
    discordIcon:SetTexCoord(0, 1, 0, 1)
    discordIcon:SetAlpha(0.74)

    discordButton:SetScript("OnEnter", function(self)
        discordIcon:SetAlpha(1)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetText("Matt's Addons Discord", 1, 1, 1)
        GameTooltip:AddLine("Click to copy invite link", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    discordButton:SetScript("OnLeave", function(self)
        discordIcon:SetAlpha(0.95)
        GameTooltip:Hide()
    end)
    discordButton:SetScript("OnClick", function()
        if MMF_ShowDiscordLinkPopup then
            MMF_ShowDiscordLinkPopup(DISCORD_URL)
        elseif MMF_ShowCopyLinkPopup then
            MMF_ShowCopyLinkPopup(DISCORD_URL)
        end
    end)

    -- Current class display (bottom-right)
    local classInfo = CreateFrame("Frame", nil, footer)
    classInfo:SetSize(138, 24)
    classInfo:SetPoint("RIGHT", -34, 0)

    local classIcon = classInfo:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(24, 24)
    classIcon:SetPoint("RIGHT", 0, 0)
    local classDisplay = (MMF_GetPopupFooterClassDisplay and MMF_GetPopupFooterClassDisplay(ACCENT_COLOR)) or {}
    classIcon:SetTexture(classDisplay.iconTexture or "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    local iconTexCoord = classDisplay.iconTexCoord or { 0, 1, 0, 1 }
    classIcon:SetTexCoord(
        iconTexCoord[1] or 0,
        iconTexCoord[2] or 1,
        iconTexCoord[3] or 0,
        iconTexCoord[4] or 1
    )

    local classNameText = classInfo:CreateFontString(nil, "OVERLAY")
    classNameText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    classNameText:SetPoint("RIGHT", classIcon, "LEFT", -6, 0)
    classNameText:SetWidth(96)
    classNameText:SetJustifyH("RIGHT")
    classNameText:SetText(classDisplay.name or "Player")
    local textColor = classDisplay.textColor or ACCENT_COLOR
    classNameText:SetTextColor(
        textColor[1] or ACCENT_COLOR[1],
        textColor[2] or ACCENT_COLOR[2],
        textColor[3] or ACCENT_COLOR[3]
    )

    local function UpdateFooterLayout()
        UpdateFooterWallpaperCrop()

        local leftPadding = 12
        local iconGap = 8
        local iconWidth = 24
        local classReserved = 188
        local footerWidth = footer:GetWidth() or 0
        local maxTextWidth = math.max(80, footerWidth - leftPadding - classReserved - iconGap - iconWidth)
        versionText:SetWidth(maxTextWidth)

        local textWidth = versionText:GetStringWidth() or 0
        if textWidth > maxTextWidth then
            textWidth = maxTextWidth
        end

        discordButton:ClearAllPoints()
        discordButton:SetPoint("LEFT", footer, "LEFT", leftPadding + textWidth + iconGap, 0)
    end

    footer:SetScript("OnSizeChanged", function()
        UpdateFooterLayout()
    end)
    UpdateFooterLayout()

    return footer

end
