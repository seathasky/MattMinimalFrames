function MMF_CreatePartyRaidPage(page, accentColor, createMinimalCheckbox, createMinimalSlider)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider

    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetTextColor(MMF_GetPopupSectionTitleColor())
    title:SetText("BLIZZARD PARTY / RAID FRAME APPEARANCE")

    local subtextLead = page:CreateFontString(nil, "OVERLAY")
    subtextLead:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
    subtextLead:SetPoint("TOPLEFT", 12, -32)
    subtextLead:SetWidth(420)
    subtextLead:SetJustifyH("LEFT")
    subtextLead:SetWordWrap(true)
    subtextLead:SetTextColor(0.86, 0.90, 0.96)
    subtextLead:SetText("Enhances Blizzard party/raid frame fonts ONLY!")

    local subtext = page:CreateFontString(nil, "OVERLAY")
    subtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    subtext:SetPoint("TOPLEFT", subtextLead, "BOTTOMLEFT", 0, -10)
    subtext:SetWidth(420)
    subtext:SetJustifyH("LEFT")
    subtext:SetWordWrap(true)
    subtext:SetTextColor(0.78, 0.82, 0.88)
    subtext:SetText("|cffff9a9aFor full standalone party/raid frames,|r\n|cffff9a9ause something like |r|cffc9a0ffDander's Frames|r|cffff9a9a instead.|r")

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetSize(240, 1)
    divider:SetPoint("TOPLEFT", subtext, "BOTTOMLEFT", 0, -8)
    divider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local quickGuide = CreateFrame("Frame", nil, page, "BackdropTemplate")
    quickGuide:SetPoint("TOPRIGHT", -16, -12)
    quickGuide:SetSize(236, 148)
    quickGuide:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    quickGuide:SetBackdropColor(0.05, 0.08, 0.11, 0.82)
    quickGuide:SetBackdropBorderColor(0.14, 0.18, 0.2, 1)

    local quickGuideTitle = quickGuide:CreateFontString(nil, "OVERLAY")
    quickGuideTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    quickGuideTitle:SetPoint("TOPLEFT", 12, -10)
    quickGuideTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    quickGuideTitle:SetText("Blizzard Party/Raid Name Styling")

    local quickGuideBody = quickGuide:CreateFontString(nil, "OVERLAY")
    quickGuideBody:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    quickGuideBody:SetPoint("TOPLEFT", quickGuideTitle, "BOTTOMLEFT", 0, -8)
    quickGuideBody:SetPoint("TOPRIGHT", -12, -30)
    quickGuideBody:SetPoint("BOTTOMLEFT", quickGuide, "BOTTOMLEFT", 12, 34)
    quickGuideBody:SetPoint("BOTTOMRIGHT", quickGuide, "BOTTOMRIGHT", -12, 34)
    quickGuideBody:SetJustifyH("LEFT")
    quickGuideBody:SetJustifyV("TOP")
    quickGuideBody:SetTextColor(0.78, 0.90, 0.96)
    quickGuideBody:SetText(
        "This is a skin/font enhancement for\n" ..
        "Blizzard Party and Raid frames.\n\n" ..
        "Customize Blizzard Party and Raid\n" ..
        "name text styling.\n" ..
        "Adjust font size, outline, centering,\n" ..
        "truncation, and label visibility."
    )

    local function SetCheckboxEnabled(container, enabled)
        if not container then return end
        container:SetAlpha(enabled and 1 or 0.45)
        if container.checkbox then
            container.checkbox:EnableMouse(enabled)
            container.checkbox:SetAlpha(enabled and 1 or 0.55)
            if container.checkbox.check then
                container.checkbox.check:SetAlpha(enabled and 1 or 0.35)
            end
        end
        if container.labelText then
            if enabled then
                container.labelText:SetTextColor(0.9, 0.9, 0.9)
            else
                container.labelText:SetTextColor(0.5, 0.5, 0.55)
            end
        end
    end

    local function SetSliderEnabled(container, enabled)
        if not container then return end
        container:SetAlpha(enabled and 1 or 0.45)
        if container.slider then
            container.slider:EnableMouse(enabled)
        end
        if container.valueText then
            container.valueText:EnableMouse(enabled)
            if enabled then
                local accent = ACCENT_COLOR
                container.valueText:SetTextColor(accent[1], accent[2], accent[3])
            else
                container.valueText:SetTextColor(0.6, 0.6, 0.6)
            end
        end
        if container.labelText then
            if enabled then
                container.labelText:SetTextColor(0.8, 0.8, 0.8)
            else
                container.labelText:SetTextColor(0.5, 0.5, 0.55)
            end
        end
    end

    local function IsNonRaidPartyFramesDetected()
        local partyFrame = _G.PartyFrame
        local editMode = _G.EditModeManagerFrame
        if not partyFrame or not editMode then
            return false
        end
        if type(partyFrame.ShouldShow) ~= "function" or type(editMode.UseRaidStylePartyFrames) ~= "function" then
            return false
        end

        local showParty = false
        local okShow, showValue = pcall(partyFrame.ShouldShow, partyFrame)
        if okShow then
            showParty = (showValue == true)
        end

        local useRaidStyle = false
        local okRaid, raidStyleValue = pcall(editMode.UseRaidStylePartyFrames, editMode)
        if okRaid then
            useRaidStyle = (raidStyleValue == true)
        end

        return showParty and (not useRaidStyle)
    end

    local centerNameCheck
    local centerNameNote
    local hideRemainingHealthCheck
    local useFontHintTooltip
    local outlineCheck
    local partyFontSizeSlider
    local raidFontSizeSlider
    local partyNameTruncateSlider
    local raidNameTruncateSlider
    local UpdateNameControlsEnabledState
    local SyncHideRemainingHealthWithCenter

    UpdateNameControlsEnabledState = function()
        local enabled = MattMinimalFramesDB and MattMinimalFramesDB.useSharedPartyRaidNameFont == true
        local nonRaidDetected = IsNonRaidPartyFramesDetected()
        local centerEnabled = enabled and not nonRaidDetected
        local centerChecked = MattMinimalFramesDB and MattMinimalFramesDB.centerPartyRaidNames == true
        SetCheckboxEnabled(centerNameCheck, centerEnabled)
        SetCheckboxEnabled(hideRemainingHealthCheck, enabled and (not centerChecked))
        SetCheckboxEnabled(outlineCheck, enabled)
        SetSliderEnabled(partyFontSizeSlider, enabled)
        SetSliderEnabled(raidFontSizeSlider, enabled)
        SetSliderEnabled(partyNameTruncateSlider, enabled)
        SetSliderEnabled(raidNameTruncateSlider, enabled)
        if centerNameNote then
            if nonRaidDetected then
                centerNameNote:SetText("* enable Raid-Style Party in Blizzard Edit Mode")
                centerNameNote:SetTextColor(1, 0.25, 0.25)
            else
                centerNameNote:SetText("* Raid Style party frames enabled")
                centerNameNote:SetTextColor(0.2, 1, 0.2)
            end
            centerNameNote:SetShown(true)
        end
    end

    local function SetCheckboxVisualState(container, checked)
        if not container or not container.checkbox then return end
        local isChecked = (checked == true)
        container.checkbox:SetChecked(isChecked)
        if container.checkbox.check then
            container.checkbox.check:SetShown(isChecked)
        end
        if container.RefreshResetVisibility then
            container:RefreshResetVisibility()
        end
    end

    SyncHideRemainingHealthWithCenter = function(applyNow)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        local db = MattMinimalFramesDB
        local centerChecked = (db.centerPartyRaidNames == true)
        local changed = false

        if centerChecked then
            if db._mmfHideRemainingHealthBeforeCenter == nil then
                db._mmfHideRemainingHealthBeforeCenter = (db.hidePartyRaidRemainingHealth == true)
            end
            if db.hidePartyRaidRemainingHealth ~= true then
                db.hidePartyRaidRemainingHealth = true
                changed = true
            end
            SetCheckboxVisualState(hideRemainingHealthCheck, true)
        else
            if db._mmfHideRemainingHealthBeforeCenter ~= nil then
                local restoreValue = (db._mmfHideRemainingHealthBeforeCenter == true)
                if db.hidePartyRaidRemainingHealth ~= restoreValue then
                    db.hidePartyRaidRemainingHealth = restoreValue
                    changed = true
                end
                db._mmfHideRemainingHealthBeforeCenter = nil
            end
            SetCheckboxVisualState(hideRemainingHealthCheck, db.hidePartyRaidRemainingHealth == true)
        end

        if changed and applyNow and MMF_UpdateBlizzardPartyRaidHealthText then
            MMF_UpdateBlizzardPartyRaidHealthText()
        end
    end

    local useAppearanceFontCheck = CreateMinimalCheckbox(page, "Use Appearance Font for Names", 12, -84, "useSharedPartyRaidNameFont", false, function()
        UpdateNameControlsEnabledState()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
        if StaticPopup_Show then
            StaticPopup_Show("MMF_RELOADUI")
        end
    end)
    if useAppearanceFontCheck then
        useAppearanceFontCheck:ClearAllPoints()
        useAppearanceFontCheck:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -10)
    end

    useFontHintTooltip = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    useFontHintTooltip:SetSize(220, 120)
    useFontHintTooltip:SetFrameStrata("TOOLTIP")
    useFontHintTooltip:SetFrameLevel(400)
    useFontHintTooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    useFontHintTooltip:SetBackdropColor(0.03, 0.03, 0.05, 0.98)
    useFontHintTooltip:SetBackdropBorderColor(0.28, 0.28, 0.34, 1)
    useFontHintTooltip:Hide()

    useFontHintTooltip.title = useFontHintTooltip:CreateFontString(nil, "OVERLAY")
    useFontHintTooltip.title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    useFontHintTooltip.title:SetPoint("TOPLEFT", 8, -8)
    useFontHintTooltip.title:SetTextColor(0.95, 0.95, 0.95)
    useFontHintTooltip.title:SetText("Blizzard Party / Raid Names")

    useFontHintTooltip.preview = useFontHintTooltip:CreateTexture(nil, "ARTWORK")
    useFontHintTooltip.preview:SetPoint("TOPLEFT", 8, -30)
    useFontHintTooltip.preview:SetSize(194, 120)
    useFontHintTooltip.preview:SetTexCoord(0, 1, 0, 1)
    useFontHintTooltip.preview:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\raid.png")
    
    local function ResizeUseFontHintTooltipForImage(sourceW, sourceH)
        local maxPreviewW, maxPreviewH = 220, 120
        local texW = tonumber(sourceW) or 0
        local texH = tonumber(sourceH) or 0

        local previewW, previewH = 194, 120
        if texW > 0 and texH > 0 then
            local scale = math.min(maxPreviewW / texW, maxPreviewH / texH, 1)
            previewW = math.max(24, math.floor(texW * scale + 0.5))
            previewH = math.max(12, math.floor(texH * scale + 0.5))
        end

        useFontHintTooltip.preview:ClearAllPoints()
        useFontHintTooltip.preview:SetPoint("TOPLEFT", 8, -30)
        useFontHintTooltip.preview:SetSize(previewW, previewH)
        useFontHintTooltip:SetSize(previewW + 16, previewH + 40)
    end
    ResizeUseFontHintTooltipForImage(276, 170)

    local useFontHint = CreateFrame("Frame", nil, page, "BackdropTemplate")
    useFontHint:SetSize(12, 12)
    useFontHint:SetPoint("LEFT", useAppearanceFontCheck, "LEFT", 238, 0)
    useFontHint:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    useFontHint:SetBackdropColor(0.08, 0.08, 0.1, 1)
    useFontHint:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    useFontHint:EnableMouse(true)

    local useFontHintText = useFontHint:CreateFontString(nil, "OVERLAY")
    useFontHintText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    useFontHintText:SetPoint("CENTER", 0, 0)
    useFontHintText:SetText("?")
    useFontHintText:SetTextColor(0.85, 0.85, 0.9)

    useFontHint:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
        useFontHintText:SetTextColor(1, 1, 1)
        useFontHintTooltip:ClearAllPoints()
        useFontHintTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 10, 6)
        useFontHintTooltip:Show()
    end)
    useFontHint:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        useFontHintText:SetTextColor(0.85, 0.85, 0.9)
        useFontHintTooltip:Hide()
    end)

    centerNameCheck = CreateMinimalCheckbox(page, "Center Names in Middle", 12, -96, "centerPartyRaidNames", false, function()
        SyncHideRemainingHealthWithCenter(true)
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
        UpdateNameControlsEnabledState()
    end)
    if centerNameCheck and useAppearanceFontCheck then
        centerNameCheck:ClearAllPoints()
        centerNameCheck:SetPoint("TOPLEFT", useAppearanceFontCheck, "BOTTOMLEFT", 0, -10)
    end

    centerNameNote = page:CreateFontString(nil, "OVERLAY")
    centerNameNote:SetFontObject(GameFontHighlightSmall)
    centerNameNote:SetPoint("TOPLEFT", centerNameCheck, "BOTTOMLEFT", 20, -2)
    centerNameNote:SetTextColor(1, 1, 1)
    centerNameNote:SetText("(enable Raid-Style Party in Blizzard Edit Mode)")

    hideRemainingHealthCheck = CreateMinimalCheckbox(page, "Hide Remaining Health", 32, -120, "hidePartyRaidRemainingHealth", true, function()
        if MattMinimalFramesDB then
            MattMinimalFramesDB._mmfHideRemainingHealthBeforeCenter = nil
        end
        if MMF_UpdateBlizzardPartyRaidHealthText then
            MMF_UpdateBlizzardPartyRaidHealthText()
        end
    end)
    if hideRemainingHealthCheck then
        hideRemainingHealthCheck:ClearAllPoints()
        hideRemainingHealthCheck:SetPoint("TOPLEFT", centerNameNote, "BOTTOMLEFT", 12, -8)
    end
    if hideRemainingHealthCheck and hideRemainingHealthCheck.labelText then
        hideRemainingHealthCheck.labelText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    end

    outlineCheck = CreateMinimalCheckbox(page, "Font Outline", 12, -184, "partyRaidNameOutline", false, function()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end)

    partyFontSizeSlider = CreateMinimalSlider(page, "Party Font Size", 12, -210, 240, "partyNameFontSize", 8, 20, 1, 16, function()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end, true)

    raidFontSizeSlider = CreateMinimalSlider(page, "Raid Font Size", 12, -236, 240, "raidNameFontSize", 8, 20, 1, 14, function()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end, true)

    partyNameTruncateSlider = CreateMinimalSlider(page, "Party Name Truncate (0 = Off)", 12, -262, 240, "partyNameTruncateLength", 0, 24, 1, 0, function()
        if MMF_ApplyPartyRaidNameTruncationPreview then
            MMF_ApplyPartyRaidNameTruncationPreview()
        end
    end, true)

    raidNameTruncateSlider = CreateMinimalSlider(page, "Raid Name Truncate (0 = Off)", 12, -288, 240, "raidNameTruncateLength", 0, 24, 1, 0, function()
        if MMF_ApplyRaidNameTruncationPreview then
            MMF_ApplyRaidNameTruncationPreview()
        end
    end, true)

    local function ApplyPartyRaidTruncateNow()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end

    if partyNameTruncateSlider and partyNameTruncateSlider.slider and partyNameTruncateSlider.slider.HookScript then
        partyNameTruncateSlider.slider:HookScript("OnMouseUp", function()
            ApplyPartyRaidTruncateNow()
        end)
    end
    if partyNameTruncateSlider and partyNameTruncateSlider.valueText and partyNameTruncateSlider.valueText.HookScript then
        partyNameTruncateSlider.valueText:HookScript("OnEnterPressed", function()
            ApplyPartyRaidTruncateNow()
        end)
    end

    if raidNameTruncateSlider and raidNameTruncateSlider.slider and raidNameTruncateSlider.slider.HookScript then
        raidNameTruncateSlider.slider:HookScript("OnMouseUp", function()
            ApplyPartyRaidTruncateNow()
        end)
    end
    if raidNameTruncateSlider and raidNameTruncateSlider.valueText and raidNameTruncateSlider.valueText.HookScript then
        raidNameTruncateSlider.valueText:HookScript("OnEnterPressed", function()
            ApplyPartyRaidTruncateNow()
        end)
    end

    local hint = page:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    hint:SetPoint("TOPLEFT", 12, -318)
    hint:SetWidth(420)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(0.58, 0.63, 0.67)
    hint:SetText("Uses your Appearance font selection for Blizzard Compact Party/Raid name text.")

    local openAppearanceButton = CreateFrame("Button", nil, quickGuide, "BackdropTemplate")
    openAppearanceButton:SetSize(132, 20)
    openAppearanceButton:SetPoint("BOTTOMLEFT", quickGuide, "BOTTOMLEFT", 12, 10)
    openAppearanceButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    openAppearanceButton:SetBackdropColor(0.08, 0.08, 0.1, 1)
    openAppearanceButton:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)

    local openAppearanceButtonText = openAppearanceButton:CreateFontString(nil, "OVERLAY")
    openAppearanceButtonText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    openAppearanceButtonText:SetPoint("CENTER")
    openAppearanceButtonText:SetText("Change Font Here")
    openAppearanceButtonText:SetTextColor(0.8, 0.8, 0.8)

    openAppearanceButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.7)
        openAppearanceButtonText:SetTextColor(1, 1, 1)
    end)
    openAppearanceButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        self:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
        openAppearanceButtonText:SetTextColor(0.8, 0.8, 0.8)
    end)
    openAppearanceButton:SetScript("OnClick", function()
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        -- Jump to Unit Frames -> Appearance sub-tab (index 7).
        MattMinimalFramesDB.popupActiveTab = 1
        MattMinimalFramesDB.unitFramesSubTab = 7

        local popup = _G.MMF_WelcomePopup
        if popup and type(popup.MMFSetActiveTab) == "function" then
            popup:MMFSetActiveTab(1)
            return
        end

        if MMF_ShowWelcomePopup then
            MMF_ShowWelcomePopup(true)
            popup = _G.MMF_WelcomePopup
            if popup and type(popup.MMFSetActiveTab) == "function" then
                popup:MMFSetActiveTab(1)
            end
        end
    end)

    local labelDivider = page:CreateTexture(nil, "ARTWORK")
    labelDivider:SetSize(240, 1)
    labelDivider:SetPoint("TOPLEFT", 12, -338)
    labelDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local labelsTitle = page:CreateFontString(nil, "OVERLAY")
    labelsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    labelsTitle:SetPoint("TOPLEFT", 12, -350)
    labelsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    labelsTitle:SetText("LABELS / STATE")

    CreateMinimalCheckbox(page, "Hide Party Label", 12, -370, "hidePartyFrameLabel", false, function()
        if MMF_UpdateBlizzardPartyRaidLabels then
            MMF_UpdateBlizzardPartyRaidLabels()
        end
    end)

    CreateMinimalCheckbox(page, "Hide Raid Group Labels", 12, -394, "hideRaidGroupLabels", false, function()
        if MMF_UpdateBlizzardPartyRaidLabels then
            MMF_UpdateBlizzardPartyRaidLabels()
        end
    end)

    CreateMinimalCheckbox(page, "Show Solo Party Frame", 12, -418, "showSoloPartyFrame", false, function()
        if MMF_UpdateBlizzardSoloPartyFrameVisibility then
            MMF_UpdateBlizzardSoloPartyFrameVisibility()
        end
        if StaticPopup_Show then
            StaticPopup_Show("MMF_RELOADUI")
        end
    end)

    CreateMinimalCheckbox(page, "Hide Self In Party", 12, -442, "hidePlayerInPartyFrame", false, function()
        if MMF_UpdateBlizzardPartySelfVisibility then
            MMF_UpdateBlizzardPartySelfVisibility()
        end
    end)

    local modeWatcher = CreateFrame("Frame", nil, page)
    modeWatcher:RegisterEvent("GROUP_ROSTER_UPDATE")
    modeWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    modeWatcher:RegisterEvent("CVAR_UPDATE")
    modeWatcher:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    modeWatcher:SetScript("OnEvent", function()
        UpdateNameControlsEnabledState()
    end)

    local lastNonRaidDetected = nil
    local pollElapsed = 0
    local function PollNameControlMode(_, elapsed)
        pollElapsed = pollElapsed + (elapsed or 0)
        if pollElapsed < 0.2 then
            return
        end
        pollElapsed = 0

        local nonRaidDetected = IsNonRaidPartyFramesDetected()
        if nonRaidDetected ~= lastNonRaidDetected then
            lastNonRaidDetected = nonRaidDetected
            UpdateNameControlsEnabledState()
        end
    end

    page:HookScript("OnShow", function()
        SyncHideRemainingHealthWithCenter(true)
        lastNonRaidDetected = IsNonRaidPartyFramesDetected()
        pollElapsed = 0
        UpdateNameControlsEnabledState()
        modeWatcher:SetScript("OnUpdate", PollNameControlMode)
    end)
    page:HookScript("OnHide", function()
        modeWatcher:SetScript("OnUpdate", nil)
        if useFontHintTooltip then
            useFontHintTooltip:Hide()
        end
    end)

    UpdateNameControlsEnabledState()
end
