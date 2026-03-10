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
        local currentScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB and MattMinimalFramesDB.guiScale)) or 1.0
        if MMF_WelcomePopup.ApplyGUIScale then
            MMF_WelcomePopup:ApplyGUIScale(currentScale, false)
        else
            MMF_WelcomePopup:SetScale(currentScale)
        end
        if MMF_WelcomePopup.ClampToScreen then
            MMF_WelcomePopup:ClampToScreen()
        end
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
    local function GetParentBounds()
        local parentLeft = UIParent and (UIParent:GetLeft() or 0) or 0
        local parentRight = UIParent and UIParent:GetRight()
        if not parentRight and UIParent and UIParent.GetWidth then
            parentRight = parentLeft + (UIParent:GetWidth() or 0)
        end
        local parentBottom = UIParent and (UIParent:GetBottom() or 0) or 0
        local parentTop = UIParent and UIParent:GetTop()
        if not parentTop and UIParent and UIParent.GetHeight then
            parentTop = parentBottom + (UIParent:GetHeight() or 0)
        end
        return parentLeft, parentRight or parentLeft, parentBottom, parentTop or parentBottom
    end
    local function NormalizePopupAnchorToCenter(self)
        if not self or not UIParent then return nil, nil end
        local left = self:GetLeft()
        local right = self:GetRight()
        local top = self:GetTop()
        local bottom = self:GetBottom()
        if not left or not right or not top or not bottom then return nil, nil end
        local parentLeft, parentRight, parentBottom, parentTop = GetParentBounds()
        local x = ((left + right) * 0.5) - ((parentLeft + parentRight) * 0.5)
        local y = ((top + bottom) * 0.5) - ((parentTop + parentBottom) * 0.5)
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", x, y)
        return x, y
    end
    local function GetPopupCenterOffsets(self)
        if not self or not UIParent then return nil, nil end
        local point, relTo, relPoint, x, y = self:GetPoint(1)
        if point == "CENTER" and (relTo == UIParent or relTo == nil) and (relPoint == "CENTER" or relPoint == nil) then
            return x or 0, y or 0
        end
        return NormalizePopupAnchorToCenter(self)
    end
    local function PersistPopupPosition()
        local x, y = GetPopupCenterOffsets(popup)
        if x and y then
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.popupPosition = { x = x, y = y, anchor = "CENTER" }
        end
    end
    local function ClampPopupHorizontal(self)
        if not self or not UIParent then return end
        local x, y = GetPopupCenterOffsets(self)
        if not x or not y then return end
        local parentLeft, parentRight, parentBottom, parentTop = GetParentBounds()
        local parentWidth = math.max(1, parentRight - parentLeft)
        local parentHeight = math.max(1, parentTop - parentBottom)
        local frameScale = self:GetScale() or 1
        local halfW = ((self:GetWidth() or 0) * frameScale) * 0.5
        local halfH = ((self:GetHeight() or 0) * frameScale) * 0.5

        local minX = (-parentWidth * 0.5) + halfW
        local maxX = (parentWidth * 0.5) - halfW
        local minY = (-parentHeight * 0.5) + halfH
        local maxY = (parentHeight * 0.5) - halfH
        if minX > maxX then
            minX, maxX = 0, 0
        end
        if minY > maxY then
            minY, maxY = 0, 0
        end

        local clampedX = math.max(minX, math.min(maxX, x))
        local clampedY = math.max(minY, math.min(maxY, y))
        if math.abs(clampedX - x) > 0.5 or math.abs(clampedY - y) > 0.5 then
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", clampedX, clampedY)
        end
    end
    local function ApplyPopupScale(scale, preservePosition)
        local targetScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(scale)) or scale or 1.0
        local x, y

        if preservePosition and popup and popup.IsVisible and popup:IsVisible() then
            x, y = GetPopupCenterOffsets(popup)
        end

        popup:SetScale(targetScale)

        if x and y then
            popup:ClearAllPoints()
            popup:SetPoint("CENTER", UIParent, "CENTER", x, y)
        end
        ClampPopupHorizontal(popup)
        PersistPopupPosition()
    end
    
    -- Apply saved GUI scale
    local guiScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
    MattMinimalFramesDB.guiScale = guiScale
    ApplyPopupScale(guiScale, false)
    
    -- Restore saved position or use default
    if MattMinimalFramesDB and MattMinimalFramesDB.popupPosition then
        local pos = MattMinimalFramesDB.popupPosition
        if pos.x and pos.y then
            popup:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
        elseif pos.left and pos.top then
            popup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
            NormalizePopupAnchorToCenter(popup)
            PersistPopupPosition()
        else
            popup:SetPoint("CENTER", UIParent, "CENTER", 0, POPUP_LAYOUT.centerY)
        end
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
    popup.ApplyGUIScale = function(self, scale, preservePosition)
        ApplyPopupScale(scale, preservePosition)
    end
    popup.ClampToScreen = function(self)
        ClampPopupHorizontal(self)
        PersistPopupPosition()
    end
    popup:HookScript("OnShow", function(self)
        ClampPopupHorizontal(self)
        PersistPopupPosition()
    end)

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

    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local function CreateTitleCheckbox(anchor, xOffset, labelText, isChecked, onToggle)
        local container = CreateFrame("Frame", nil, titleBar)
        container:SetSize(120, 20)
        container:SetPoint("RIGHT", anchor, "LEFT", xOffset, 0)

        local checkbox = CreateFrame("CheckButton", nil, container)
        checkbox:SetSize(14, 14)
        checkbox:SetPoint("LEFT", 0, 0)

        local bg = checkbox:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.1, 1)

        local border = checkbox:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.25, 0.25, 0.3, 1)

        local check = checkbox:CreateTexture(nil, "ARTWORK")
        check:SetSize(8, 8)
        check:SetPoint("CENTER")
        check:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
        checkbox.check = check

        local label = container:CreateFontString(nil, "OVERLAY")
        label:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
        label:SetTextColor(0.9, 0.9, 0.9)
        label:SetText(labelText)

        checkbox:SetChecked(isChecked == true)
        check:SetShown(isChecked == true)
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked() == true
            self.check:SetShown(checked)
            if onToggle then
                onToggle(checked)
            end
        end)

        return container, checkbox
    end

    local lockFramesContainer = nil
    local editModeContainer = nil
    local lockFramesCheckbox = nil
    local editModeCheckbox = nil
    local editModePopup = nil

    local function SetTitleCheckboxVisual(checkbox, checked)
        if not checkbox then return end
        checkbox:SetChecked(checked == true)
        if checkbox.check then
            checkbox.check:SetShown(checked == true)
        end
    end

    local function SyncTitleLockCheckboxState()
        local editModeEnabled = MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
        local effectiveLocked = MattMinimalFramesDB and MattMinimalFramesDB.locked == true

        if editModeEnabled then
            SetTitleCheckboxVisual(lockFramesCheckbox, false)
            if lockFramesCheckbox and lockFramesCheckbox.Disable then
                lockFramesCheckbox:Disable()
            end
            if lockFramesContainer then
                lockFramesContainer:SetAlpha(0.45)
            end
            return
        end

        SetTitleCheckboxVisual(lockFramesCheckbox, effectiveLocked)
        if lockFramesCheckbox and lockFramesCheckbox.Enable then
            lockFramesCheckbox:Enable()
        end
        if lockFramesContainer then
            lockFramesContainer:SetAlpha(1)
        end
    end

    local function SetEditModeCheckboxState(checked)
        SetTitleCheckboxVisual(editModeCheckbox, checked)
    end

    local function EnsureEditModePopup()
        if editModePopup then
            return editModePopup
        end

        editModePopup = CreateFrame("Frame", "MMF_EditModePopup", UIParent, "BackdropTemplate")
        editModePopup:SetSize(380, 170)
        editModePopup:SetPoint("TOP", UIParent, "TOP", 0, -120)
        editModePopup:SetFrameStrata("DIALOG")
        editModePopup:SetToplevel(true)
        editModePopup:SetMovable(true)
        editModePopup:EnableMouse(true)
        editModePopup:RegisterForDrag("LeftButton")
        editModePopup:SetScript("OnDragStart", editModePopup.StartMoving)
        editModePopup:SetScript("OnDragStop", editModePopup.StopMovingOrSizing)
        editModePopup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        editModePopup:SetBackdropColor(0.04, 0.04, 0.05, 0.98)
        editModePopup:SetBackdropBorderColor(0.1, 0.1, 0.12, 1)

        local modeTitleBar = CreateFrame("Frame", nil, editModePopup)
        modeTitleBar:SetPoint("TOPLEFT", 0, 0)
        modeTitleBar:SetPoint("TOPRIGHT", 0, 0)
        modeTitleBar:SetHeight(28)

        local modeTitleBg = modeTitleBar:CreateTexture(nil, "BACKGROUND")
        modeTitleBg:SetAllPoints()
        modeTitleBg:SetColorTexture(0.07, 0.09, 0.11, 1)

        local modeTitleGlow = modeTitleBar:CreateTexture(nil, "ARTWORK")
        modeTitleGlow:SetPoint("BOTTOMLEFT", 0, 0)
        modeTitleGlow:SetPoint("BOTTOMRIGHT", 0, 0)
        modeTitleGlow:SetHeight(2)
        modeTitleGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

        local modeTitle = modeTitleBar:CreateFontString(nil, "OVERLAY")
        modeTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        modeTitle:SetPoint("LEFT", 12, 1)
        modeTitle:SetTextColor(1, 1, 1)
        modeTitle:SetText("Matt's Minimal Frames Edit Mode")

        local modeHelp = editModePopup:CreateFontString(nil, "OVERLAY")
        modeHelp:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        modeHelp:SetPoint("TOP", editModePopup, "TOP", 0, -54)
        modeHelp:SetTextColor(0.85, 0.85, 0.85)
        modeHelp:SetText("Drag frames normally. Click below to exit Edit Mode.")

        local openGuiContainer = CreateFrame("Frame", nil, editModePopup)
        openGuiContainer:SetSize(220, 20)
        openGuiContainer:SetPoint("TOP", modeHelp, "BOTTOM", 0, -10)

        local openGuiCheckbox = CreateFrame("CheckButton", nil, openGuiContainer)
        openGuiCheckbox:SetSize(14, 14)
        openGuiCheckbox:SetPoint("LEFT", 0, 0)

        local openGuiBg = openGuiCheckbox:CreateTexture(nil, "BACKGROUND")
        openGuiBg:SetAllPoints()
        openGuiBg:SetColorTexture(0.08, 0.08, 0.1, 1)

        local openGuiBorder = openGuiCheckbox:CreateTexture(nil, "BORDER")
        openGuiBorder:SetPoint("TOPLEFT", -1, 1)
        openGuiBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        openGuiBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

        local openGuiCheck = openGuiCheckbox:CreateTexture(nil, "ARTWORK")
        openGuiCheck:SetSize(8, 8)
        openGuiCheck:SetPoint("CENTER")
        openGuiCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
        openGuiCheckbox.check = openGuiCheck

        local openGuiLabel = openGuiContainer:CreateFontString(nil, "OVERLAY")
        openGuiLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        openGuiLabel:SetPoint("LEFT", openGuiCheckbox, "RIGHT", 6, 0)
        openGuiLabel:SetTextColor(0.9, 0.9, 0.9)
        openGuiLabel:SetText("Open Settings GUI")

        local gridContainer = CreateFrame("Frame", nil, editModePopup)
        gridContainer:SetSize(180, 20)
        gridContainer:SetPoint("TOP", openGuiContainer, "BOTTOM", 0, -8)

        local gridCheckbox = CreateFrame("CheckButton", nil, gridContainer)
        gridCheckbox:SetSize(14, 14)
        gridCheckbox:SetPoint("LEFT", 0, 0)

        local gridBg = gridCheckbox:CreateTexture(nil, "BACKGROUND")
        gridBg:SetAllPoints()
        gridBg:SetColorTexture(0.08, 0.08, 0.1, 1)

        local gridBorder = gridCheckbox:CreateTexture(nil, "BORDER")
        gridBorder:SetPoint("TOPLEFT", -1, 1)
        gridBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        gridBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

        local gridCheck = gridCheckbox:CreateTexture(nil, "ARTWORK")
        gridCheck:SetSize(8, 8)
        gridCheck:SetPoint("CENTER")
        gridCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
        gridCheckbox.check = gridCheck

        local gridLabel = gridContainer:CreateFontString(nil, "OVERLAY")
        gridLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        gridLabel:SetPoint("LEFT", gridCheckbox, "RIGHT", 6, 0)
        gridLabel:SetTextColor(0.9, 0.9, 0.9)
        gridLabel:SetText("Alignment Grid")

        local function SetGridChecked(checked)
            gridCheckbox:SetChecked(checked == true)
            if gridCheckbox.check then
                gridCheckbox.check:SetShown(checked == true)
            end
        end

        local function SetOpenGuiChecked(checked)
            openGuiCheckbox:SetChecked(checked == true)
            if openGuiCheckbox.check then
                openGuiCheckbox.check:SetShown(checked == true)
            end
        end

        openGuiCheckbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked() == true
            SetOpenGuiChecked(checked)
            if checked then
                popup:Show()
            else
                popup:Hide()
            end
        end)

        gridCheckbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked() == true
            SetGridChecked(checked)
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            MattMinimalFramesDB.showAlignmentGrid = checked
            if MMF_ToggleAlignmentGrid then
                MMF_ToggleAlignmentGrid(checked)
            end
        end)

        local exitButton = CreateFrame("Button", nil, editModePopup, "BackdropTemplate")
        exitButton:SetSize(150, 24)
        exitButton:SetPoint("BOTTOM", editModePopup, "BOTTOM", 0, 16)
        exitButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        exitButton:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
        exitButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)

        local exitText = exitButton:CreateFontString(nil, "OVERLAY")
        exitText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        exitText:SetPoint("CENTER")
        exitText:SetTextColor(0.9, 0.9, 0.9)
        exitText:SetText("Exit Edit Mode")

        exitButton:SetScript("OnEnter", function()
            exitButton:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
        end)
        exitButton:SetScript("OnLeave", function()
            exitButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        end)
        exitButton:SetScript("OnClick", function()
            if MMF_SetEditMode then
                MMF_SetEditMode(false)
            else
                MattMinimalFramesDB.unlockFramesEditMode = false
                if MMF_RefreshFrameLockState then
                    MMF_RefreshFrameLockState()
                end
            end
            SetEditModeCheckboxState(false)
            SyncTitleLockCheckboxState()
            editModePopup:Hide()
            popup:Show()
        end)

        editModePopup:SetScript("OnShow", function(self)
            local scale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB and MattMinimalFramesDB.guiScale)) or 1.0
            self:SetScale(scale)
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            if MattMinimalFramesDB.showAlignmentGrid ~= true then
                MattMinimalFramesDB.showAlignmentGrid = true
                if MMF_ToggleAlignmentGrid then
                    MMF_ToggleAlignmentGrid(true)
                end
            end
            SetOpenGuiChecked(false)
            popup:Hide()
            SetGridChecked(MattMinimalFramesDB.showAlignmentGrid == true)
        end)

        editModePopup:Hide()
        return editModePopup
    end

    editModeContainer, editModeCheckbox = CreateTitleCheckbox(closeX, -248, "Edit Mode", MattMinimalFramesDB.unlockFramesEditMode == true, function(checked)
        if MMF_SetEditMode then
            MMF_SetEditMode(checked)
        else
            MattMinimalFramesDB.unlockFramesEditMode = checked and true or false
            if MMF_RefreshFrameLockState then
                MMF_RefreshFrameLockState()
            end
        end
        SyncTitleLockCheckboxState()
        if checked then
            local modePopup = EnsureEditModePopup()
            popup:Hide()
            modePopup:Show()
        else
            if editModePopup then
                editModePopup:Hide()
            end
        end
    end)

    lockFramesContainer, lockFramesCheckbox = CreateTitleCheckbox(closeX, -136, "Lock Frames", MattMinimalFramesDB.locked == true, function(checked)
        if MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true then
            SetTitleCheckboxVisual(lockFramesCheckbox, false)
            return
        end

        MattMinimalFramesDB.locked = checked and true or false
        if checked then
            if MMF_LockFrames then
                MMF_LockFrames()
            end
        else
            if MMF_UnlockFrames then
                MMF_UnlockFrames()
            end
        end
        SyncTitleLockCheckboxState()
    end)

    SyncTitleLockCheckboxState()

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
        if popup and popup.IsVisible and popup:IsVisible() then
            ApplyPopupScale(num, true)
        end
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
            ApplyPopupScale(value, true)
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

    local aurasState = MMF_CreateAurasPowerSection(leftCol, popup, ACCENT_COLOR, CreateMinimalCheckbox, CreateMinimalSlider, UpdateSharedScrollBounds)
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
