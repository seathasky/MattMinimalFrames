-- core/popup.lua
-- Contains the MMF_ShowWelcomePopup function for MattMinimalFrames

function MMF_ShowWelcomePopup(forceShow)
    if not forceShow and MattMinimalFramesDB.hideWelcomeMessage then return end

    local popup = CreateFrame("Frame", "MMF_WelcomePopup", UIParent, "BackdropTemplate")
    popup:SetSize(560, 570)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    popup:SetBackdropColor(0.07, 0.07, 0.10, 0.97)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    -- Title
    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 20, "OUTLINE")
    title:SetPoint("TOPLEFT", 28, -28)
    title:SetJustifyH("LEFT")
    title:SetText("MattMinimalFrames")
    title:SetTextColor(0.15, 0.85, 1)

    -- Only the move-frames guide
    local msg = popup:CreateFontString(nil, "OVERLAY")
    msg:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 14, "OUTLINE")
    msg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    msg:SetJustifyH("LEFT")
    msg:SetWidth(500)
    msg:SetSpacing(8)
    msg:SetText(
        "|cff33ccffHow do I move the frames?|r\n" ..
        "Hold |cffff0000SHIFT|r and drag with |cffffffffleft mouse button|r to move any frame while out of combat.\n\n" ..
        "|cFFFFFF00Moveable Frames:|r\n" ..
        "|cFFFFFF00Player, Target, Target-of-Target, Focus, and Pet|r"
    )

    -- Divider line
    local divider = popup:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.2, 0.8, 1, 0.18)
    divider:SetSize(500, 2)
    divider:SetPoint("TOPLEFT", msg, "BOTTOMLEFT", 0, -16)

    -- Settings section header
    local settingsTitle = popup:CreateFontString(nil, "OVERLAY")
    settingsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 16, "OUTLINE")
    settingsTitle:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -20)
    settingsTitle:SetJustifyH("LEFT")
    settingsTitle:SetText("Settings")
    settingsTitle:SetTextColor(0.15, 0.85, 1)

    -- Buffs checkbox
    local buffsCheckbox = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
    buffsCheckbox:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 16, -20)
    buffsCheckbox:SetChecked(MattMinimalFramesDB.showBuffs ~= false)
    local buffsLabel = popup:CreateFontString(nil, "OVERLAY")
    buffsLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "OUTLINE")
    buffsLabel:SetPoint("LEFT", buffsCheckbox, "RIGHT", 8, 0)
    buffsLabel:SetJustifyH("LEFT")
    buffsLabel:SetText("Show Buffs")
    buffsCheckbox:SetScript("OnClick", function(self)
        MattMinimalFramesDB.showBuffs = self:GetChecked()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Debuffs checkbox
    local debuffsCheckbox = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
    debuffsCheckbox:SetPoint("TOPLEFT", buffsCheckbox, "BOTTOMLEFT", 0, -22)
    debuffsCheckbox:SetChecked(MattMinimalFramesDB.showDebuffs ~= false)
    local debuffsLabel = popup:CreateFontString(nil, "OVERLAY")
    debuffsLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "OUTLINE")
    debuffsLabel:SetPoint("LEFT", debuffsCheckbox, "RIGHT", 8, 0)
    debuffsLabel:SetJustifyH("LEFT")
    debuffsLabel:SetText("Show Debuffs")
    debuffsCheckbox:SetScript("OnClick", function(self)
        MattMinimalFramesDB.showDebuffs = self:GetChecked()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Resource bar checkbox
    local resourceCheckbox = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
    resourceCheckbox:SetPoint("TOPLEFT", debuffsCheckbox, "BOTTOMLEFT", 0, -22)
    resourceCheckbox:SetChecked(MattMinimalFramesDB.showPowerBars ~= false)
    local resourceLabel = popup:CreateFontString(nil, "OVERLAY")
    resourceLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "OUTLINE")
    resourceLabel:SetPoint("LEFT", resourceCheckbox, "RIGHT", 8, 0)
    resourceLabel:SetJustifyH("LEFT")
    resourceLabel:SetText("Show Resource Bar (mana/rage/energy)")
    resourceCheckbox:SetScript("OnClick", function(self)
        MattMinimalFramesDB.showPowerBars = self:GetChecked()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Tip at the bottom
    local tip = popup:CreateFontString(nil, "OVERLAY")
    tip:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "OUTLINE")
    tip:SetTextColor(0.15, 0.85, 1)
    tip:SetPoint("TOPLEFT", resourceCheckbox, "BOTTOMLEFT", 0, -32)
    tip:SetJustifyH("LEFT")
    tip:SetText("Tip: Type |cff33ccff/mmf|r to open this window at any time.")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    closeBtn:SetSize(90, 26)
    closeBtn:SetPoint("TOPLEFT", tip, "BOTTOMLEFT", 0, -24)
    closeBtn:SetText("Got it!")
    closeBtn:SetScript("OnClick", function() popup:Hide() end)
    closeBtn:GetFontString():SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "OUTLINE")
    closeBtn:GetFontString():SetTextColor(0.15, 0.85, 1)

    -- Hide welcome message checkbox
    local checkbox = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
    checkbox:SetPoint("BOTTOMLEFT", 16, 16)
    checkbox:SetChecked(MattMinimalFramesDB.hideWelcomeMessage)
    checkbox:SetScript("OnClick", function(self)
        MattMinimalFramesDB.hideWelcomeMessage = self:GetChecked()
    end)
    local checkboxText = popup:CreateFontString(nil, "OVERLAY")
    checkboxText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    checkboxText:SetJustifyH("LEFT")
    checkboxText:SetText("Don't show this again")

    popup:Show()

    -- StaticPopup for reload prompt
    StaticPopupDialogs["MMF_RELOADUI"] = {
        text = "You must reload your UI for this change to take effect.",
        button1 = "Reload UI",
        button2 = "Cancel",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end
