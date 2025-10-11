--========================================================
-- MattMinimalFrames_UI.lua
-- Settings GUI
--========================================================

-- Track settings frame
local settingsFrame = nil

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

-- Show settings GUI
function MMF_ShowSettings()
    -- If already open, just bring it to front
    if settingsFrame and settingsFrame:IsShown() then 
        settingsFrame:Raise()
        return 
    end
    
    -- Create settings frame
    settingsFrame = CreateFrame("Frame", "MMF_SettingsFrame", UIParent, "BackdropTemplate")
    settingsFrame:SetSize(400, 340)
    settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    settingsFrame:SetBackdropColor(0.07, 0.07, 0.10, 0.97)
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame:SetFrameStrata("DIALOG")

    -- Title
    local title = settingsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 18, "OUTLINE")
    title:SetPoint("TOP", 0, -20)
    title:SetJustifyH("CENTER")
    title:SetText("MattMinimalFrames Settings")
    title:SetTextColor(0.15, 0.85, 1)

    -- Instructions
    local instructions = settingsFrame:CreateFontString(nil, "OVERLAY")
    instructions:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 12, "OUTLINE")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -15)
    instructions:SetWidth(360)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Hold |cffff0000SHIFT|r and drag frames with left mouse button to move them while out of combat.")
    instructions:SetTextColor(0.8, 0.8, 0.8)

    -- Buffs checkbox
    local buffsCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    buffsCheckbox:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -25)
    buffsCheckbox:SetChecked(MattMinimalFramesDB.showBuffs ~= false)
    local buffsLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
    buffsLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 13, "OUTLINE")
    buffsLabel:SetPoint("LEFT", buffsCheckbox, "RIGHT", 8, 0)
    buffsLabel:SetJustifyH("LEFT")
    buffsLabel:SetText("Show Buffs")
    buffsCheckbox:SetScript("OnClick", function(self)
        MattMinimalFramesDB.showBuffs = self:GetChecked()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Debuffs checkbox
    local debuffsCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    debuffsCheckbox:SetPoint("TOPLEFT", buffsCheckbox, "BOTTOMLEFT", 0, -15)
    debuffsCheckbox:SetChecked(MattMinimalFramesDB.showDebuffs ~= false)
    local debuffsLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
    debuffsLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 13, "OUTLINE")
    debuffsLabel:SetPoint("LEFT", debuffsCheckbox, "RIGHT", 8, 0)
    debuffsLabel:SetJustifyH("LEFT")
    debuffsLabel:SetText("Show Debuffs")
    debuffsCheckbox:SetScript("OnClick", function(self)
        MattMinimalFramesDB.showDebuffs = self:GetChecked()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Resource bar checkbox
    local resourceCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    resourceCheckbox:SetPoint("TOPLEFT", debuffsCheckbox, "BOTTOMLEFT", 0, -15)
    resourceCheckbox:SetChecked(MattMinimalFramesDB.showPowerBars ~= false)
    local resourceLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
    resourceLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 13, "OUTLINE")
    resourceLabel:SetPoint("LEFT", resourceCheckbox, "RIGHT", 8, 0)
    resourceLabel:SetJustifyH("LEFT")
    resourceLabel:SetText("Show Resource Bar (mana/rage/energy)")
    resourceCheckbox:SetScript("OnClick", function(self)
        MattMinimalFramesDB.showPowerBars = self:GetChecked()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    -- Minimap button checkbox
    local minimapCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    minimapCheckbox:SetPoint("TOPLEFT", resourceCheckbox, "BOTTOMLEFT", 0, -15)
    minimapCheckbox:SetChecked(not (MattMinimalFramesDB.minimapButton and MattMinimalFramesDB.minimapButton.hide))
    local minimapLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
    minimapLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 13, "OUTLINE")
    minimapLabel:SetPoint("LEFT", minimapCheckbox, "RIGHT", 8, 0)
    minimapLabel:SetJustifyH("LEFT")
    minimapLabel:SetText("Show Minimap Button")
    minimapCheckbox:SetScript("OnClick", function(self)
        MMF_ToggleMinimapButton()
    end)
    
    -- Minimap button hint
    local minimapHint = settingsFrame:CreateFontString(nil, "OVERLAY")
    minimapHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 11, "OUTLINE")
    minimapHint:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 25, -5)
    minimapHint:SetJustifyH("LEFT")
    minimapHint:SetText("Use |cff33ccff/mmf|r command when button is hidden")
    minimapHint:SetTextColor(0.6, 0.6, 0.6)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 26)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() settingsFrame:Hide() end)
    closeBtn:GetFontString():SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 12, "OUTLINE")

    settingsFrame:Show()
end
