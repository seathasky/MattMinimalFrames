local Compat = _G.MMF_Compat

local POPUP_LAYOUT = (MMF_GetPopupLayout and MMF_GetPopupLayout()) or {
    width = 820,
    height = Compat.IsTBC and 750 or 750,
    titleHeight = 28,
    footerHeight = 32,
    tabHeight = 24,
    tabSpacing = 4,
    contentSidePadding = 10,
    contentTopOffset = -4,
    pageGap = 4,
    centerY = 50,
    unitFramesContentHeight = 680,
    aurasPowerContentHeight = 680,
    currentClassContentHeight = 680,
    profilesContentHeight = 680,
    toolsContentHeight = 680,
}

local CreateMinimalCheckbox = MMF_CreateMinimalCheckbox
local CreateMinimalSlider = MMF_CreateMinimalSlider
local CreateSubTabBar = MMF_CreateSubTabBar
local TITLE_WALLPAPER_ALPHA = 0.03
local SIDEBAR_WALLPAPER_ALPHA = 0.10

local function SetAspectCropTexCoords(texture, holder, imageAspect)
    if not texture or not holder then return end
    local w = math.max(1, holder:GetWidth() or 1)
    local h = math.max(1, holder:GetHeight() or 1)
    local frameAspect = w / h
    local sourceAspect = imageAspect or (16 / 9)
    if frameAspect > sourceAspect then
        local visibleV = sourceAspect / frameAspect
        local padV = (1 - visibleV) * 0.5
        texture:SetTexCoord(0, 1, padV, 1 - padV)
    else
        local visibleU = frameAspect / sourceAspect
        local padU = (1 - visibleU) * 0.5
        texture:SetTexCoord(padU, 1 - padU, 0, 1)
    end
end

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
    titleBg:SetColorTexture(0.07, 0.09, 0.11, 1)

    local titleWallpaper = titleBar:CreateTexture(nil, "ARTWORK")
    titleWallpaper:SetPoint("TOPLEFT", 1, -1)
    titleWallpaper:SetPoint("BOTTOMRIGHT", -1, 1)
    titleWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw.png")
    titleWallpaper:SetAlpha(TITLE_WALLPAPER_ALPHA)

    local function UpdateTitleWallpaperCrop()
        local barW = math.max(1, titleBar:GetWidth() or popupWidth or 1)
        local barH = math.max(1, titleBar:GetHeight() or (POPUP_LAYOUT.titleHeight or 28))
        local imageAspect = 16 / 9
        local barAspect = barW / barH

        if barAspect > imageAspect then
            local visibleV = imageAspect / barAspect
            local padV = (1 - visibleV) * 0.5
            titleWallpaper:SetTexCoord(0, 1, padV, 1 - padV)
        else
            local visibleU = barAspect / imageAspect
            local padU = (1 - visibleU) * 0.5
            titleWallpaper:SetTexCoord(padU, 1 - padU, 0, 1)
        end
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
    titleGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("LEFT", 16, 1)
    title:SetText("|cffffffffMatt's Minimal Frames ")
    
    -- Add version suffix with smaller font
    local versionSuffix = titleBar:CreateFontString(nil, "OVERLAY")
    versionSuffix:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 8, "")
    versionSuffix:SetPoint("LEFT", title, "RIGHT", 4, 2)
    if Compat.IsTBC then
        versionSuffix:SetText("TBC EDITION")
        versionSuffix:SetTextColor(0.2, 0.9, 0.4)
    else
        versionSuffix:SetText("MIDNIGHT EDITION")
        versionSuffix:SetTextColor(0.6, 0.4, 0.9)
    end

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
        closeX:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    closeX:SetScript("OnLeave", function()
        closeX:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        closeText:SetTextColor(0.5, 0.5, 0.5)
    end)
    closeX:SetScript("OnClick", function() popup:Hide() end)

    -- Lock Frames checkbox on title bar
    local lockFramesContainer = CreateFrame("Frame", nil, titleBar)
    lockFramesContainer:SetSize(120, 20)
    lockFramesContainer:SetPoint("RIGHT", closeX, "LEFT", -136, 0)

    local lockFramesCheckbox = CreateFrame("CheckButton", nil, lockFramesContainer)
    lockFramesCheckbox:SetSize(14, 14)
    lockFramesCheckbox:SetPoint("LEFT", 0, 0)

    local lockFramesBg = lockFramesCheckbox:CreateTexture(nil, "BACKGROUND")
    lockFramesBg:SetAllPoints()
    lockFramesBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local lockFramesBorder = lockFramesCheckbox:CreateTexture(nil, "BORDER")
    lockFramesBorder:SetPoint("TOPLEFT", -1, 1)
    lockFramesBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    lockFramesBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local lockFramesCheck = lockFramesCheckbox:CreateTexture(nil, "ARTWORK")
    lockFramesCheck:SetSize(8, 8)
    lockFramesCheck:SetPoint("CENTER")
    lockFramesCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    lockFramesCheckbox.check = lockFramesCheck

    local lockFramesLabel = lockFramesContainer:CreateFontString(nil, "OVERLAY")
    lockFramesLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    lockFramesLabel:SetPoint("LEFT", lockFramesCheckbox, "RIGHT", 6, 0)
    lockFramesLabel:SetTextColor(0.9, 0.9, 0.9)
    lockFramesLabel:SetText("Lock Frames")

    local isLocked = MattMinimalFramesDB and MattMinimalFramesDB.locked == true
    lockFramesCheckbox:SetChecked(isLocked)
    lockFramesCheck:SetShown(isLocked)
    lockFramesCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == true
        self.check:SetShown(checked)
        MattMinimalFramesDB.locked = checked
        if checked then
            if MMF_LockFrames then
                MMF_LockFrames()
            end
        else
            if MMF_UnlockFrames then
                MMF_UnlockFrames()
            end
        end
    end)

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

    local SIDEBAR_WIDTH = 180
    local HEADER_HEIGHT = 68
    local tabBar = CreateFrame("Frame", nil, tabContainer)
    tabBar:SetPoint("TOPLEFT", 0, 0)
    tabBar:SetPoint("BOTTOMLEFT", 0, 0)
    tabBar:SetWidth(SIDEBAR_WIDTH)

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
    sidebarWallpaper:SetAlpha(SIDEBAR_WALLPAPER_ALPHA)
    SetAspectCropTexCoords(sidebarWallpaper, sidebarBg, 16 / 9)

    local sidebarWallpaperTint = sidebarBg:CreateTexture(nil, "ARTWORK", nil, 1)
    sidebarWallpaperTint:SetPoint("TOPLEFT", 1, -1)
    sidebarWallpaperTint:SetPoint("BOTTOMRIGHT", -1, 1)
    sidebarWallpaperTint:SetColorTexture(0.02, 0.03, 0.04, 0.02)

    sidebarBg:SetScript("OnSizeChanged", function()
        SetAspectCropTexCoords(sidebarWallpaper, sidebarBg, 16 / 9)
    end)

    local sidebarBrand = CreateFrame("Frame", nil, tabBar)
    sidebarBrand:SetPoint("TOPLEFT", 0, 0)
    sidebarBrand:SetPoint("TOPRIGHT", 0, 0)
    sidebarBrand:SetHeight(64)

    local sidebarBrandGlow = sidebarBrand:CreateTexture(nil, "ARTWORK")
    sidebarBrandGlow:SetPoint("BOTTOMLEFT", 0, 0)
    sidebarBrandGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarBrandGlow:SetHeight(2)
    sidebarBrandGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

    local sidebarBrandTitle = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 20, "")
    sidebarBrandTitle:SetPoint("TOPLEFT", 16, -16)
    sidebarBrandTitle:SetTextColor(0.96, 0.97, 0.98)
    sidebarBrandTitle:SetText("SETTINGS")

    local sidebarBrandSub = sidebarBrand:CreateFontString(nil, "OVERLAY")
    sidebarBrandSub:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    sidebarBrandSub:SetPoint("TOPLEFT", sidebarBrandTitle, "BOTTOMLEFT", 0, -4)
    sidebarBrandSub:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
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
    pageHeader:SetPoint("TOPRIGHT", -(12 + 4), 0)
    pageHeader:SetHeight(HEADER_HEIGHT)
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
    SetAspectCropTexCoords(pageHeaderWallpaper, pageHeader, 16 / 9)
    pageHeader:SetScript("OnSizeChanged", function()
        SetAspectCropTexCoords(pageHeaderWallpaper, pageHeader, 16 / 9)
    end)

    local pageHeaderGlow = pageHeader:CreateTexture(nil, "ARTWORK")
    pageHeaderGlow:SetPoint("BOTTOMLEFT", 0, 0)
    pageHeaderGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    pageHeaderGlow:SetHeight(2)
    pageHeaderGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

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

    local SCROLLBAR_WIDTH = 12
    local SCROLLBAR_GAP = 4

    local pageScrollFrame = CreateFrame("ScrollFrame", nil, pageContainer)
    pageScrollFrame:SetPoint("TOPLEFT", pageHeader, "BOTTOMLEFT", 0, -8)
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
        page:SetBackdropColor(0.08, 0.10, 0.13, 0.96)
        page:SetBackdropBorderColor(0.12, 0.16, 0.18, 1)

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
    local playerBarColorList
    local targetBarColorList
    local totBarColorList
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
    local unitFramesState
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

    local function GetActivePageScrollRange()
        local page = activePage
        if not page then
            return 0, 0
        end

        if type(page.MMFGetSectionRange) == "function" then
            local startY, endY = page:MMFGetSectionRange()
            startY = math.max(0, tonumber(startY) or 0)
            endY = math.max(startY, tonumber(endY) or (page:GetHeight() or 0))
            return startY, endY
        end

        return 0, page:GetHeight() or 0
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
        local sectionStart, sectionEnd = GetActivePageScrollRange()
        local contentHeight = math.max(0, sectionEnd - sectionStart)
        local maxScroll = math.max(0, contentHeight - viewHeight)
        local current = sharedScrollBar:GetValue() or 0
        if current > maxScroll then
            current = maxScroll
        end

        sharedScrollBar:SetMinMaxValues(0, maxScroll)
        sharedScrollBar:SetValue(current)
        sharedScrollBar:SetEnabled(maxScroll > 0)
        sharedScrollBar:SetAlpha(maxScroll > 0 and 1 or 0.45)
        pageScrollFrame:SetVerticalScroll(sectionStart + current)
    end

    sharedScrollBar:SetScript("OnValueChanged", function(self, value)
        local sectionStart = 0
        if activePage and type(activePage.MMFGetSectionRange) == "function" then
            local startY = activePage:MMFGetSectionRange()
            sectionStart = math.max(0, tonumber(startY) or 0)
        end
        pageScrollFrame:SetVerticalScroll(sectionStart + (value or 0))
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
        local buttonHeight = 42
        local tabY = 0

        for i, tabButton in ipairs(tabButtons) do
            tabButton:SetSize(SIDEBAR_WIDTH - 16, buttonHeight)
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

        local activeDef = tabDefs[tabIndex]
        local activeLabel = activeDef and activeDef.label or "Settings"
        pageHeaderTitle:SetText(activeLabel)
        pageHeaderSubtitle:SetText(subtitleByLabel[activeLabel] or "")

        for _, listFrame in ipairs(closableLists) do
            CloseListFrame(listFrame)
        end

        if tabIndex == 1 and unitFramesState and unitFramesState.ApplyInitialSection then
            unitFramesState.ApplyInitialSection()
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
        tabButton:SetBackdropColor(0.04, 0.05, 0.06, 0.96)
        tabButton:SetBackdropBorderColor(0.12, 0.14, 0.16, 1)

        local tabGlow = tabButton:CreateTexture(nil, "BACKGROUND")
        tabGlow:SetPoint("TOPLEFT", -2, -2)
        tabGlow:SetPoint("BOTTOMRIGHT", 2, 2)
        tabGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
        tabGlow:SetAlpha(0)
        tabButton.glow = tabGlow

        local tabActiveRail = tabButton:CreateTexture(nil, "ARTWORK")
        tabActiveRail:SetPoint("TOPLEFT", 0, 0)
        tabActiveRail:SetPoint("BOTTOMLEFT", 0, 0)
        tabActiveRail:SetWidth(3)
        tabActiveRail:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
        tabActiveRail:SetAlpha(0)
        tabButton.activeRail = tabActiveRail

        local tabActiveLine = tabButton:CreateTexture(nil, "ARTWORK")
        tabActiveLine:SetPoint("BOTTOMLEFT", 0, 0)
        tabActiveLine:SetPoint("BOTTOMRIGHT", 0, 0)
        tabActiveLine:SetHeight(2)
        tabActiveLine:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
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
                self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.4)
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
            if PlaySoundFile and IsUISoundsEnabled() then
                PlaySoundFile("Interface\\AddOns\\MattMinimalFrames\\Sounds\\click.mp3", "Master")
            end
            SetActiveTab(i)
        end)

        tabButtons[i] = tabButton
    end
    LayoutTabButtons()

    local function ScrollActivePageTo(offset)
        sharedScrollBar:SetValue(math.max(0, tonumber(offset) or 0))
    end

    ---------------------------------------------------
    unitFramesState = MMF_CreateUnitFramesSection(unitFramesCol, popup, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider, GetCurrentPlayerIconModeValue, GetCurrentTargetIconModeValue, CreateSubTabBar, ScrollActivePageTo, UpdateSharedScrollBounds)
    castBarColorList = unitFramesState.castBarColorList
    unitTextureList = unitFramesState.unitTextureList
    unitFontList = unitFramesState.unitFontList
    playerBarColorList = unitFramesState.playerBarColorList
    targetBarColorList = unitFramesState.targetBarColorList
    totBarColorList = unitFramesState.totBarColorList
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
    RegisterClosableList(playerBarColorList)
    RegisterClosableList(targetBarColorList)
    RegisterClosableList(totBarColorList)
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
            UpdateTitleWallpaperCrop()
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

