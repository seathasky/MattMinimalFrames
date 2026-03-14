function MMF_CreatePartyRaidPage(page, accentColor, createMinimalCheckbox, createMinimalSlider)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider

    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetTextColor(MMF_GetPopupSectionTitleColor())
    title:SetText("BLIZZARD PARTY / RAID FRAME APPEARANCE")

    local subtext = page:CreateFontString(nil, "OVERLAY")
    subtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    subtext:SetPoint("TOPLEFT", 12, -32)
    subtext:SetTextColor(0.62, 0.67, 0.71)
    subtext:SetText("These are not standalone party / raid frames.")

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetSize(240, 1)
    divider:SetPoint("TOPLEFT", 12, -52)
    divider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local quickGuide = CreateFrame("Frame", nil, page, "BackdropTemplate")
    quickGuide:SetPoint("TOPRIGHT", -16, -12)
    quickGuide:SetSize(236, 122)
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
    quickGuideTitle:SetText("Quick Guide")

    local quickGuideBody = quickGuide:CreateFontString(nil, "OVERLAY")
    quickGuideBody:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    quickGuideBody:SetPoint("TOPLEFT", quickGuideTitle, "BOTTOMLEFT", 0, -8)
    quickGuideBody:SetPoint("TOPRIGHT", -12, -30)
    quickGuideBody:SetJustifyH("LEFT")
    quickGuideBody:SetJustifyV("TOP")
    quickGuideBody:SetTextColor(0.78, 0.90, 0.96)
    quickGuideBody:SetText(
        "Enable Use Appearance Font for Names.\n" ..
        "Adjust Font Size and Outline.\n" ..
        "If Center is disabled, switch Party\n" ..
        "Frames to Raid-Style in Edit Mode.\n" ..
        "Labels can be hidden separately."
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
    local useFontHintTooltip
    local outlineCheck
    local partyFontSizeSlider
    local raidFontSizeSlider
    local raidNameTruncateSlider
    local UpdateNameControlsEnabledState

    UpdateNameControlsEnabledState = function()
        local enabled = MattMinimalFramesDB and MattMinimalFramesDB.useSharedPartyRaidNameFont == true
        local nonRaidDetected = IsNonRaidPartyFramesDetected()
        local centerEnabled = enabled and not nonRaidDetected
        SetCheckboxEnabled(centerNameCheck, centerEnabled)
        SetCheckboxEnabled(outlineCheck, enabled)
        SetSliderEnabled(partyFontSizeSlider, enabled)
        SetSliderEnabled(raidFontSizeSlider, enabled)
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

    local useAppearanceFontCheck = CreateMinimalCheckbox(page, "Use Appearance Font for Names", 12, -72, "useSharedPartyRaidNameFont", false, function()
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
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end)

    centerNameNote = page:CreateFontString(nil, "OVERLAY")
    centerNameNote:SetFontObject(GameFontHighlightSmall)
    centerNameNote:SetPoint("TOPLEFT", centerNameCheck, "BOTTOMLEFT", 20, -2)
    centerNameNote:SetTextColor(1, 1, 1)
    centerNameNote:SetText("(enable Raid-Style Party in Blizzard Edit Mode)")

    outlineCheck = CreateMinimalCheckbox(page, "Font Outline", 12, -136, "partyRaidNameOutline", false, function()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end)

    partyFontSizeSlider = CreateMinimalSlider(page, "Party Font Size", 12, -162, 240, "partyNameFontSize", 8, 20, 1, 16, function()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end, true)

    raidFontSizeSlider = CreateMinimalSlider(page, "Raid Font Size", 12, -188, 240, "raidNameFontSize", 8, 20, 1, 14, function()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end, true)

    raidNameTruncateSlider = CreateMinimalSlider(page, "Raid Name Truncate (0 = Off)", 12, -214, 240, "raidNameTruncateLength", 0, 24, 1, 0, function()
        if MMF_ApplyRaidNameTruncationPreview then
            MMF_ApplyRaidNameTruncationPreview()
        end
    end, true)

    local function ApplyRaidTruncateNow()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_RefreshBlizzardPartyRaidNameFonts then
            MMF_RefreshBlizzardPartyRaidNameFonts()
        end
    end

    if raidNameTruncateSlider and raidNameTruncateSlider.slider and raidNameTruncateSlider.slider.HookScript then
        raidNameTruncateSlider.slider:HookScript("OnMouseUp", function()
            ApplyRaidTruncateNow()
        end)
    end
    if raidNameTruncateSlider and raidNameTruncateSlider.valueText and raidNameTruncateSlider.valueText.HookScript then
        raidNameTruncateSlider.valueText:HookScript("OnEnterPressed", function()
            ApplyRaidTruncateNow()
        end)
    end

    local hint = page:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    hint:SetPoint("TOPLEFT", 12, -244)
    hint:SetWidth(420)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(0.58, 0.63, 0.67)
    hint:SetText("Uses your Appearance font selection for Blizzard Compact Party/Raid name text.")

    local labelDivider = page:CreateTexture(nil, "ARTWORK")
    labelDivider:SetSize(240, 1)
    labelDivider:SetPoint("TOPLEFT", 12, -274)
    labelDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local labelsTitle = page:CreateFontString(nil, "OVERLAY")
    labelsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    labelsTitle:SetPoint("TOPLEFT", 12, -286)
    labelsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    labelsTitle:SetText("LABELS / STATE")

    CreateMinimalCheckbox(page, "Hide Party Label", 12, -306, "hidePartyFrameLabel", false, function()
        if MMF_UpdateBlizzardPartyRaidLabels then
            MMF_UpdateBlizzardPartyRaidLabels()
        end
    end)

    CreateMinimalCheckbox(page, "Hide Raid Group Labels", 12, -330, "hideRaidGroupLabels", false, function()
        if MMF_UpdateBlizzardPartyRaidLabels then
            MMF_UpdateBlizzardPartyRaidLabels()
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
    modeWatcher:SetScript("OnUpdate", function(_, elapsed)
        if not page or not page:IsShown() then
            return
        end
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
    end)

    page:HookScript("OnShow", function()
        lastNonRaidDetected = IsNonRaidPartyFramesDetected()
        pollElapsed = 0
        UpdateNameControlsEnabledState()
    end)
    page:HookScript("OnHide", function()
        if useFontHintTooltip then
            useFontHintTooltip:Hide()
        end
    end)

    UpdateNameControlsEnabledState()
end
