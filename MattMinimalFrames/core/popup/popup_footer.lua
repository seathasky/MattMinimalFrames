function MMF_CreatePopupFooter(popup, popupWidth, accentColor, footerHeight)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local height = footerHeight or 40
    -- Footer
    local footer = CreateFrame("Frame", nil, popup)
    footer:SetSize(popupWidth, height)
    footer:SetPoint("BOTTOM", 0, 0)
    
    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(0.03, 0.03, 0.04, 1)

    local dontShowCheck = CreateFrame("CheckButton", nil, footer)
    dontShowCheck:SetSize(12, 12)
    dontShowCheck:SetPoint("LEFT", 14, 0)
    
    local dsBg = dontShowCheck:CreateTexture(nil, "BACKGROUND")
    dsBg:SetAllPoints()
    dsBg:SetColorTexture(0.08, 0.08, 0.1, 1)
    
    local dsBorder = dontShowCheck:CreateTexture(nil, "BORDER")
    dsBorder:SetPoint("TOPLEFT", -1, 1)
    dsBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    dsBorder:SetColorTexture(0.2, 0.2, 0.25, 1)
    
    local dsCheck = dontShowCheck:CreateTexture(nil, "ARTWORK")
    dsCheck:SetSize(6, 6)
    dsCheck:SetPoint("CENTER")
    dsCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    dontShowCheck.check = dsCheck
    
    dontShowCheck:SetChecked(MattMinimalFramesDB.hideWelcomeMessage)
    dsCheck:SetShown(dontShowCheck:GetChecked())
    
    dontShowCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.check:SetShown(checked)
        MattMinimalFramesDB.hideWelcomeMessage = checked
    end)
    
    local dontShowText = footer:CreateFontString(nil, "OVERLAY")
    dontShowText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    dontShowText:SetPoint("LEFT", dontShowCheck, "RIGHT", 5, 0)
    dontShowText:SetTextColor(0.5, 0.5, 0.5)
    dontShowText:SetText("Don't show on login")

    -- Current class display (bottom-right)
    local classInfo = CreateFrame("Frame", nil, footer)
    classInfo:SetSize(138, 24)
    classInfo:SetPoint("RIGHT", -12, 0)

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

end
