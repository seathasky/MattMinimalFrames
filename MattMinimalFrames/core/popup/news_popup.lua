local NEWS_ID = "2026-03-edit-mode"

local function BuildNewsPopup()
    if _G.MMF_NewsPopup then
        return _G.MMF_NewsPopup
    end

    local popup = CreateFrame("Frame", "MMF_NewsPopup", UIParent, "BackdropTemplate")
    popup:SetSize(620, 380)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    popup:SetFrameStrata("DIALOG")
    popup:SetToplevel(true)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.04, 0.04, 0.05, 0.98)
    popup:SetBackdropBorderColor(0.1, 0.1, 0.12, 1)

    local accent = (MMF_GetPopupAccentColor and MMF_GetPopupAccentColor()) or { 0.2, 0.8, 1.0 }

    local header = popup:CreateTexture(nil, "BACKGROUND")
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(28)
    header:SetColorTexture(0.07, 0.09, 0.11, 1)

    local headerWallpaper = popup:CreateTexture(nil, "ARTWORK")
    headerWallpaper:SetPoint("TOPLEFT", 1, -1)
    headerWallpaper:SetPoint("TOPRIGHT", -1, -1)
    headerWallpaper:SetHeight(28)
    headerWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw.png")
    headerWallpaper:SetTexCoord(0, 1, 0.43, 0.57)
    headerWallpaper:SetAlpha(0.03)

    local headerTint = popup:CreateTexture(nil, "ARTWORK")
    headerTint:SetPoint("TOPLEFT", 1, -1)
    headerTint:SetPoint("TOPRIGHT", -1, -1)
    headerTint:SetHeight(28)
    headerTint:SetColorTexture(0.02, 0.03, 0.04, 0.22)

    local headerLine = popup:CreateTexture(nil, "OVERLAY")
    headerLine:SetPoint("TOPLEFT", 1, -29)
    headerLine:SetPoint("TOPRIGHT", -1, -29)
    headerLine:SetHeight(1)
    headerLine:SetColorTexture(accent[1], accent[2], accent[3], 0.95)

    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("LEFT", popup, "TOPLEFT", 12, -15)
    title:SetTextColor(1, 1, 1)
    title:SetText("Matt's Minimal Frames  |cff9fd6ffNews|r")

    local bodyHeadline = popup:CreateFontString(nil, "OVERLAY")
    bodyHeadline:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 16, "")
    bodyHeadline:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -44)
    bodyHeadline:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -14, -44)
    bodyHeadline:SetJustifyH("LEFT")
    bodyHeadline:SetTextColor(1.0, 0.86, 0.2)
    bodyHeadline:SetText("Matt's Minimal Frames update (v6.1.0):")

    local body = popup:CreateFontString(nil, "OVERLAY")
    body:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    body:SetPoint("TOPLEFT", bodyHeadline, "BOTTOMLEFT", 0, -10)
    body:SetPoint("TOPRIGHT", bodyHeadline, "BOTTOMRIGHT", 0, -10)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetTextColor(0.9, 0.9, 0.9)
    body:SetText(
        "|cff40ff40NEW|r: |cff9fd6ffEdit Mode|r is now available.\n\n" ..
        "You can find Edit Mode in Settings GUI at top:"
    )

    local previewHolder = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    previewHolder:SetSize(596, 82)
    previewHolder:SetPoint("TOP", popup, "TOP", 0, -118)
    previewHolder:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    previewHolder:SetBackdropColor(0.02, 0.02, 0.03, 0.92)
    previewHolder:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)

    local previewImage = previewHolder:CreateTexture(nil, "ARTWORK")
    previewImage:SetSize(590, 76)
    previewImage:SetPoint("CENTER", previewHolder, "CENTER", 0, 0)
    previewImage:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\News\\editmode.png")
    previewImage:SetTexCoord(0, 1, 0, 1)

    local details = popup:CreateFontString(nil, "OVERLAY")
    details:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    details:SetPoint("TOPLEFT", previewHolder, "BOTTOMLEFT", 0, -12)
    details:SetPoint("TOPRIGHT", previewHolder, "BOTTOMRIGHT", 0, -12)
    details:SetJustifyH("LEFT")
    details:SetTextColor(0.88, 0.88, 0.88)
    details:SetText(
        "• Use Edit Mode to reveal/move frames out of combat.\n" ..
        "• Dedicated Edit Mode popup with quick Exit + Alignment Grid toggle.\n" ..
        "• Clicking a frame in Edit Mode opens per-frame reset options.\n" ..
        "• Player cast bar is movable in Edit Mode and scalable in Frame Scale.\n" ..
        "• Pet / Focus / ToT now have HP text options..\n" ..
        "• Pet Action Bar is now moveable in Edit mode."
    )

    local dismissContainer = CreateFrame("Frame", nil, popup)
    dismissContainer:SetSize(520, 20)

    local dismissCheckbox = CreateFrame("CheckButton", nil, dismissContainer)
    dismissCheckbox:SetSize(14, 14)
    dismissCheckbox:SetPoint("LEFT", 0, 0)

    local cbBg = dismissCheckbox:CreateTexture(nil, "BACKGROUND")
    cbBg:SetAllPoints()
    cbBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local cbBorder = dismissCheckbox:CreateTexture(nil, "BORDER")
    cbBorder:SetPoint("TOPLEFT", -1, 1)
    cbBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    cbBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local cbCheck = dismissCheckbox:CreateTexture(nil, "ARTWORK")
    cbCheck:SetSize(8, 8)
    cbCheck:SetPoint("CENTER")
    cbCheck:SetColorTexture(accent[1], accent[2], accent[3], 1)
    cbCheck:Hide()
    dismissCheckbox.check = cbCheck

    local dismissLabel = dismissContainer:CreateFontString(nil, "OVERLAY")
    dismissLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    dismissLabel:SetPoint("LEFT", dismissCheckbox, "RIGHT", 6, 0)
    dismissLabel:SetTextColor(0.9, 0.9, 0.9)
    dismissLabel:SetText("Don't show again until next major patch!")

    local warning = popup:CreateFontString(nil, "OVERLAY")
    warning:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 14, "")
    warning:SetPoint("TOPLEFT", details, "BOTTOMLEFT", 0, -18)
    warning:SetPoint("TOPRIGHT", details, "BOTTOMRIGHT", 0, -18)
    warning:SetJustifyH("LEFT")
    warning:SetJustifyV("TOP")
    warning:SetTextColor(1.0, 0.2, 0.2)
    warning:SetText("Warning: some of your changed settings may have reverted due to the Edit Mode change update. Sorry for the inconvenience.")

    local warningDivider = popup:CreateTexture(nil, "ARTWORK")
    warningDivider:SetHeight(1)
    warningDivider:SetPoint("LEFT", warning, "TOPLEFT", 0, 10)
    warningDivider:SetPoint("RIGHT", warning, "TOPRIGHT", 0, 10)
    warningDivider:SetColorTexture(1.0, 0.2, 0.2, 0.55)

    dismissContainer:SetPoint("TOPLEFT", warning, "BOTTOMLEFT", 0, -16)

    local function ApplyDismiss(checked)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        dismissCheckbox:SetChecked(checked == true)
        dismissCheckbox.check:SetShown(checked == true)
        if checked then
            MattMinimalFramesDB.newsDismissedId = NEWS_ID
            popup:Hide()
        end
    end

    dismissCheckbox:SetScript("OnClick", function(self)
        ApplyDismiss(self:GetChecked() == true)
    end)

    local closeButton = CreateFrame("Button", nil, popup, "BackdropTemplate")
    closeButton:SetSize(18, 18)
    closeButton:SetPoint("TOPRIGHT", -8, -6)
    closeButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    closeButton:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
    closeButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)

    local closeText = closeButton:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    closeText:SetPoint("CENTER")
    closeText:SetTextColor(0.5, 0.5, 0.5)
    closeText:SetText("×")

    closeButton:SetScript("OnEnter", function()
        closeButton:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.8)
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    closeButton:SetScript("OnLeave", function()
        closeButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        closeText:SetTextColor(0.5, 0.5, 0.5)
    end)
    closeButton:SetScript("OnClick", function()
        popup:Hide()
    end)

    popup:SetScript("OnShow", function()
        dismissCheckbox:SetChecked(false)
        dismissCheckbox.check:SetShown(false)
        local guiScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB and MattMinimalFramesDB.guiScale)) or 1.0
        popup:SetScale(guiScale)
        if previewImage and previewImage.SetScale then
            previewImage:SetScale(1 / guiScale)
        end
    end)

    popup:Hide()
    _G.MMF_NewsPopup = popup
    return popup
end

function MMF_ShowNewsPopup(forceShow)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local dismissed = (MattMinimalFramesDB.newsDismissedId == NEWS_ID)
    if dismissed and not forceShow then
        return
    end

    local popup = BuildNewsPopup()
    popup:Show()
end
