function MMF_CreateUnitFramesSection(unitFramesCol, popup, accentColor, createMinimalCheckbox, createMinimalSlider, getCurrentPlayerIconModeValue, getCurrentTargetIconModeValue)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider
    local GetCurrentPlayerIconModeValue = getCurrentPlayerIconModeValue or function() return "off" end
    local GetCurrentTargetIconModeValue = getCurrentTargetIconModeValue or function() return "off" end
    local castBarColorList
    local unitTextureList
    local unitFontList
    local playerIconModeList
    local targetIconModeList
    local scaleUnitList
    local nameTextUnitList
    local hpTextUnitList
    local hideNameTextUnitList
    local hideHPTextUnitList
    local UpdatePlayerIconModeButtonText = function() end

    local function NormalizeSelectionValue(value, fallback)
        if type(value) ~= "string" then
            return fallback
        end
        local trimmed = value:match("^%s*(.-)%s*$")
        if not trimmed or trimmed == "" then
            return fallback
        end
        return trimmed
    end

    -- UNIT FRAMES COLUMN (2nd Column)
    ---------------------------------------------------
    local unitFramesTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    unitFramesTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    unitFramesTitle:SetPoint("TOPLEFT", 12, -12)
    unitFramesTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    unitFramesTitle:SetText("UNIT FRAMES")

    -- Right-side style column for unit frame texture selection
    local unitFramesSplit = unitFramesCol:CreateTexture(nil, "ARTWORK")
    unitFramesSplit:SetPoint("TOPLEFT", 264, -36)
    unitFramesSplit:SetPoint("BOTTOMLEFT", 264, 12)
    unitFramesSplit:SetWidth(1)
    unitFramesSplit:SetColorTexture(0.12, 0.12, 0.15, 1)

    local textOffsetsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    textOffsetsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    textOffsetsTitle:SetPoint("TOPLEFT", 12, -410)
    textOffsetsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    textOffsetsTitle:SetText("TEXT OFFSETS")

    local nameUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
    }
    local hpUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
    }
    MattMinimalFramesDB.textOffsetNameUnit = MattMinimalFramesDB.textOffsetNameUnit or "player"
    MattMinimalFramesDB.textOffsetHPUnit = MattMinimalFramesDB.textOffsetHPUnit or "player"

    local function EnsureTextOffsetDropdownSelections()
        local nameValid, hpValid = false, false
        for _, opt in ipairs(nameUnitOptions) do
            if opt.value == MattMinimalFramesDB.textOffsetNameUnit then nameValid = true break end
        end
        for _, opt in ipairs(hpUnitOptions) do
            if opt.value == MattMinimalFramesDB.textOffsetHPUnit then hpValid = true break end
        end
        if not nameValid then MattMinimalFramesDB.textOffsetNameUnit = "player" end
        if not hpValid then MattMinimalFramesDB.textOffsetHPUnit = "player" end
    end
    EnsureTextOffsetDropdownSelections()

    local UpdateVisibleNameOffsetSliders = function() end
    local UpdateVisibleHPOffsetSliders = function() end

    local nameUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -434,
        width = 220,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = 142,
        visibleRows = #nameUnitOptions,
        label = "Name Unit",
        options = nameUnitOptions,
        getValue = function()
            return MattMinimalFramesDB.textOffsetNameUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textOffsetNameUnit = value
            UpdateVisibleNameOffsetSliders()
        end,
    })

    local nameXSliders = {}
    local nameYSliders = {}
    for _, opt in ipairs(nameUnitOptions) do
        local prefix = opt.value == "targettarget" and "tot" or opt.value
        nameXSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Name X Offset", 12, -458, 220, prefix .. "NameTextXOffset", -60, 60, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        nameYSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Name Y Offset", 12, -482, 220, prefix .. "NameTextYOffset", -60, 60, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        nameXSliders[opt.value]:Hide()
        nameYSliders[opt.value]:Hide()
    end

    local function UpdateNameUnitButtonText()
        nameUnitDropdown.SetSelectedValue(MattMinimalFramesDB.textOffsetNameUnit)
    end

    UpdateVisibleNameOffsetSliders = function()
        local current = MattMinimalFramesDB.textOffsetNameUnit
        for _, opt in ipairs(nameUnitOptions) do
            local show = (opt.value == current)
            nameXSliders[opt.value]:SetShown(show)
            nameYSliders[opt.value]:SetShown(show)
        end
    end

    nameTextUnitList = nameUnitDropdown.list

    local hpUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -514,
        width = 220,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = 142,
        visibleRows = #hpUnitOptions,
        label = "HP Unit",
        options = hpUnitOptions,
        getValue = function()
            return MattMinimalFramesDB.textOffsetHPUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textOffsetHPUnit = value
            UpdateVisibleHPOffsetSliders()
        end,
    })

    local hpXSliders = {}
    local hpYSliders = {}
    for _, opt in ipairs(hpUnitOptions) do
        local prefix = opt.value == "targettarget" and "tot" or opt.value
        hpXSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "HP X Offset", 12, -538, 220, prefix .. "HPTextXOffset", -60, 60, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        hpYSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "HP Y Offset", 12, -562, 220, prefix .. "HPTextYOffset", -60, 60, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        hpXSliders[opt.value]:Hide()
        hpYSliders[opt.value]:Hide()
    end

    local function UpdateHPUnitButtonText()
        hpUnitDropdown.SetSelectedValue(MattMinimalFramesDB.textOffsetHPUnit)
    end

    UpdateVisibleHPOffsetSliders = function()
        local current = MattMinimalFramesDB.textOffsetHPUnit
        for _, opt in ipairs(hpUnitOptions) do
            local show = (opt.value == current)
            hpXSliders[opt.value]:SetShown(show)
            hpYSliders[opt.value]:SetShown(show)
        end
    end

    hpTextUnitList = hpUnitDropdown.list

    UpdateNameUnitButtonText()
    UpdateVisibleNameOffsetSliders()
    UpdateHPUnitButtonText()
    UpdateVisibleHPOffsetSliders()

    local offsetsDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    offsetsDivider:SetSize(220, 1)
    offsetsDivider:SetPoint("TOPLEFT", 12, -398)
    offsetsDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local castBarsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    castBarsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    castBarsTitle:SetPoint("TOPLEFT", 280, -36)
    castBarsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    castBarsTitle:SetText("CAST BARS")

    local playerCastBarCheck = CreateMinimalCheckbox(unitFramesCol, "Player Cast Bar", 280, -60, "showPlayerCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local targetCastBarCheck = CreateMinimalCheckbox(unitFramesCol, "Target Cast Bar", 280, -84, "showTargetCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local castBarColorDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 280,
        y = -108,
        width = 252,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 148,
        visibleRows = #MMF_Config.CAST_BAR_COLORS,
        label = "Cast Bar Color",
        options = MMF_Config.CAST_BAR_COLORS,
        getValue = function()
            return (MattMinimalFramesDB and MattMinimalFramesDB.castBarColor) or "yellow"
        end,
        onSelect = function(value)
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.castBarColor = value
            StaticPopup_Show("MMF_RELOADUI")
        end,
    })
    castBarColorList = castBarColorDropdown.list

    local castStyleDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    castStyleDivider:SetSize(252, 1)
    castStyleDivider:SetPoint("TOPLEFT", 280, -148)
    castStyleDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local styleTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    styleTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    styleTitle:SetPoint("TOPLEFT", 280, -160)
    styleTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    styleTitle:SetText("STYLE")

    local styleSubtext = unitFramesCol:CreateFontString(nil, "OVERLAY")
    styleSubtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    styleSubtext:SetPoint("TOPLEFT", 280, -180)
    styleSubtext:SetTextColor(0.65, 0.65, 0.7)
    styleSubtext:SetText("SharedMedia unit frame textures and fonts")

    local unitTextureDropdown

    local texturePreviewBG = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
    texturePreviewBG:SetSize(194, 16)
    texturePreviewBG:SetPoint("TOPLEFT", 338, -238)
    texturePreviewBG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    texturePreviewBG:SetBackdropColor(0.03, 0.03, 0.04, 1)
    texturePreviewBG:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    local texturePreview = CreateFrame("StatusBar", nil, texturePreviewBG)
    texturePreview:SetPoint("TOPLEFT", texturePreviewBG, "TOPLEFT", 1, -1)
    texturePreview:SetPoint("BOTTOMRIGHT", texturePreviewBG, "BOTTOMRIGHT", -1, 1)
    texturePreview:SetMinMaxValues(0, 1)
    texturePreview:SetValue(1)
    texturePreview:SetStatusBarColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)

    local textureOptions = MMF_GetStatusBarTextureOptions and MMF_GetStatusBarTextureOptions() or { "MMF Melli" }

    local function GetSelectedTexture()
        return NormalizeSelectionValue(MattMinimalFramesDB and MattMinimalFramesDB.statusBarTexture, "MMF Melli")
    end

    local function EnsureValidSelectedTexture()
        textureOptions = MMF_GetStatusBarTextureOptions and MMF_GetStatusBarTextureOptions() or { "MMF Melli" }
    end
    EnsureValidSelectedTexture()

    local function UpdateUnitTexturePreview()
        local texturePath = MMF_GetStatusBarTexturePath and MMF_GetStatusBarTexturePath()
        if texturePath then
            texturePreview:SetStatusBarTexture(texturePath)
        end
    end
    UpdateUnitTexturePreview()

    local function BuildTextureDropdownOptions()
        local out = {}
        for _, optionName in ipairs(textureOptions) do
            out[#out + 1] = { value = optionName, label = optionName }
        end
        return out
    end

    local function ApplySelectedTexture(name)
        if MMF_SetStatusBarTexture then
            MMF_SetStatusBarTexture(name)
        else
            MattMinimalFramesDB.statusBarTexture = name
        end
        EnsureValidSelectedTexture()
        UpdateUnitTexturePreview()
        if unitTextureDropdown then
            unitTextureDropdown.SetSelectedValue(GetSelectedTexture())
        end
    end

    unitTextureDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 280,
        y = -204,
        width = 252,
        labelWidth = 56,
        buttonOffset = 58,
        buttonWidth = 194,
        visibleRows = 9,
        label = "Texture",
        options = BuildTextureDropdownOptions(),
        getValue = function()
            return GetSelectedTexture()
        end,
        optionsProvider = function()
            EnsureValidSelectedTexture()
            return BuildTextureDropdownOptions()
        end,
        onOpen = function()
            EnsureValidSelectedTexture()
            UpdateUnitTexturePreview()
            if unitTextureDropdown then
                unitTextureDropdown.SetSelectedValue(GetSelectedTexture())
            end
        end,
        onSelect = function(value)
            ApplySelectedTexture(value)
        end,
    })
    unitTextureList = unitTextureDropdown.list

    local fontOptions = MMF_GetFontOptions and MMF_GetFontOptions() or { "MMF Naowh" }

    local function GetSelectedFont()
        return NormalizeSelectionValue(MattMinimalFramesDB and MattMinimalFramesDB.globalFont, "MMF Naowh")
    end

    local function EnsureValidSelectedFont()
        fontOptions = MMF_GetFontOptions and MMF_GetFontOptions() or { "MMF Naowh" }
    end
    EnsureValidSelectedFont()

    local function BuildFontDropdownOptions()
        local out = {}
        for _, optionName in ipairs(fontOptions) do
            out[#out + 1] = { value = optionName, label = optionName }
        end
        return out
    end

    local unitFontDropdown
    unitFontDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 280,
        y = -274,
        width = 252,
        labelWidth = 56,
        buttonOffset = 58,
        buttonWidth = 194,
        visibleRows = 9,
        label = "Font",
        options = BuildFontDropdownOptions(),
        getValue = function()
            return GetSelectedFont()
        end,
        optionsProvider = function()
            EnsureValidSelectedFont()
            return BuildFontDropdownOptions()
        end,
        onOpen = function()
            EnsureValidSelectedFont()
            if unitFontDropdown then
                unitFontDropdown.SetSelectedValue(GetSelectedFont())
            end
        end,
        onSelect = function(value)
            if MMF_SetGlobalFont then
                MMF_SetGlobalFont(value)
            else
                MattMinimalFramesDB.globalFont = value
            end
            EnsureValidSelectedFont()
            unitFontDropdown.SetSelectedValue(GetSelectedFont())
        end,
    })
    unitFontList = unitFontDropdown.list

    local styleDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    styleDivider:SetSize(252, 1)
    styleDivider:SetPoint("TOPLEFT", 280, -302)
    styleDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local frameOptionsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    frameOptionsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    frameOptionsTitle:SetPoint("TOPLEFT", 280, -314)
    frameOptionsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    frameOptionsTitle:SetText("FRAME OPTIONS")

    local iconModeOptions = {
        { value = "off", label = "Off" },
        { value = "class", label = "Class Icon" },
        { value = "portrait", label = "Portrait" },
    }
    local playerIconModeDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 280,
        y = -338,
        width = 252,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 148,
        visibleRows = #iconModeOptions,
        label = "Player Frame Icon",
        options = iconModeOptions,
        getValue = function()
            return GetCurrentPlayerIconModeValue()
        end,
        onSelect = function(value)
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.playerFrameIconMode = value
            MattMinimalFramesDB.showPlayerClassIcon = (value == "class")
            if MMF_UpdatePlayerClassIconVisibility then
                MMF_UpdatePlayerClassIconVisibility(value)
            end
            UpdatePlayerIconModeButtonText()
        end,
    })
    playerIconModeList = playerIconModeDropdown.list

    UpdatePlayerIconModeButtonText = function()
        playerIconModeDropdown.SetSelectedValue(GetCurrentPlayerIconModeValue())
    end
    UpdatePlayerIconModeButtonText()

    local targetIconModeDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 280,
        y = -362,
        width = 252,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 148,
        visibleRows = #iconModeOptions,
        label = "Target Frame Icon",
        options = iconModeOptions,
        getValue = function()
            return GetCurrentTargetIconModeValue()
        end,
        onSelect = function(value)
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.targetFrameIconMode = value
            MattMinimalFramesDB.showTargetFrameIcon = (value == "class")
            if MMF_UpdateTargetFrameIconVisibility then
                MMF_UpdateTargetFrameIconVisibility(value)
            end
        end,
    })
    targetIconModeList = targetIconModeDropdown.list

    local targetMarkersCheck = CreateMinimalCheckbox(unitFramesCol, "Target Markers", 280, -394, "showTargetMarkers", false, function(checked)
        if MMF_UpdateTargetMarkerVisibility then
            MMF_UpdateTargetMarkerVisibility(checked)
        end
    end)

    -- Tiny raid-marker preview so users immediately recognize the toggle.
    local markerPreviewText = unitFramesCol:CreateFontString(nil, "OVERLAY")
    markerPreviewText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    markerPreviewText:SetPoint("LEFT", targetMarkersCheck, "LEFT", 116, 0)
    markerPreviewText:SetText(
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:14:14:0:0:256:256:0:64:0:64|t" ..
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:14:14:0:0:256:256:64:128:0:64|t" ..
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:14:14:0:0:256:256:128:192:0:64|t"
    )

    local function RefreshPredictionVisuals()
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
            return
        end
        if MMF_GetAllFrames and MMF_UpdateUnitFrame then
            for _, frame in ipairs(MMF_GetAllFrames()) do
                if frame then
                    MMF_UpdateUnitFrame(frame)
                end
            end
        end
    end

    local frameOptionsDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    frameOptionsDivider:SetSize(252, 1)
    frameOptionsDivider:SetPoint("TOPLEFT", 280, -418)
    frameOptionsDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local healOverlaysTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    healOverlaysTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    healOverlaysTitle:SetPoint("TOPLEFT", 280, -430)
    healOverlaysTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    healOverlaysTitle:SetText("HEAL OVERLAYS")

    local healPredictionCheck = CreateMinimalCheckbox(unitFramesCol, "Heal Prediction", 280, -454, "showHealPrediction", true, function()
        RefreshPredictionVisuals()
    end)

    local overlayHintTooltip = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    overlayHintTooltip:SetSize(208, 108)
    overlayHintTooltip:SetFrameStrata("TOOLTIP")
    overlayHintTooltip:SetFrameLevel(400)
    overlayHintTooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    overlayHintTooltip:SetBackdropColor(0.03, 0.03, 0.05, 0.98)
    overlayHintTooltip:SetBackdropBorderColor(0.28, 0.28, 0.34, 1)
    overlayHintTooltip:Hide()

    overlayHintTooltip.title = overlayHintTooltip:CreateFontString(nil, "OVERLAY")
    overlayHintTooltip.title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    overlayHintTooltip.title:SetPoint("TOPLEFT", 8, -8)
    overlayHintTooltip.title:SetTextColor(0.95, 0.95, 0.95)

    overlayHintTooltip.preview = overlayHintTooltip:CreateTexture(nil, "ARTWORK")
    overlayHintTooltip.preview:SetPoint("TOPLEFT", 8, -30)
    overlayHintTooltip.preview:SetSize(192, 70)
    overlayHintTooltip.preview:SetTexCoord(0, 1, 0, 1)

    local function ResizeOverlayHintTooltipForImage(sourceW, sourceH)
        local maxPreviewW, maxPreviewH = 220, 120
        local texW = tonumber(sourceW) or 0
        local texH = tonumber(sourceH) or 0

        local previewW, previewH = 192, 70
        if texW > 0 and texH > 0 then
            local scale = math.min(maxPreviewW / texW, maxPreviewH / texH, 1)
            previewW = math.max(24, math.floor(texW * scale + 0.5))
            previewH = math.max(12, math.floor(texH * scale + 0.5))
        end

        overlayHintTooltip.preview:ClearAllPoints()
        overlayHintTooltip.preview:SetPoint("TOPLEFT", 8, -30)
        overlayHintTooltip.preview:SetSize(previewW, previewH)
        overlayHintTooltip:SetSize(previewW + 16, previewH + 40)
    end

    local function ShowOverlayHintTooltip(anchor, title, imagePath, sourceW, sourceH)
        if not anchor or not imagePath then return end
        overlayHintTooltip.title:SetText(title or "Hint")
        overlayHintTooltip.preview:SetTexture(imagePath)
        ResizeOverlayHintTooltipForImage(sourceW, sourceH)
        overlayHintTooltip:ClearAllPoints()
        overlayHintTooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 10, 6)
        overlayHintTooltip:Show()
    end

    local function HideOverlayHintTooltip()
        overlayHintTooltip:Hide()
    end

    local function CreateHintIcon(anchorContainer, xOffset, title, imagePath, sourceW, sourceH)
        local hint = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
        hint:SetSize(12, 12)
        hint:SetPoint("LEFT", anchorContainer, "LEFT", xOffset or 146, 0)
        hint:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        hint:SetBackdropColor(0.08, 0.08, 0.1, 1)
        hint:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        hint:EnableMouse(true)

        local hintText = hint:CreateFontString(nil, "OVERLAY")
        hintText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
        hintText:SetPoint("CENTER", 0, 0)
        hintText:SetText("?")
        hintText:SetTextColor(0.85, 0.85, 0.9)

        hint:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
            hintText:SetTextColor(1, 1, 1)
            ShowOverlayHintTooltip(self, title, imagePath, sourceW, sourceH)
        end)
        hint:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            hintText:SetTextColor(0.85, 0.85, 0.9)
            HideOverlayHintTooltip()
        end)

        return hint
    end

    CreateHintIcon(
        healPredictionCheck,
        128,
        "Heal Prediction",
        "Interface\\AddOns\\MattMinimalFrames\\Images\\healpredict.png",
        200,
        52
    )

    local absorbBarCheck = CreateMinimalCheckbox(unitFramesCol, "Absorb Bar", 280, -478, "showAbsorbBar", true, function()
        RefreshPredictionVisuals()
    end)
    CreateHintIcon(
        absorbBarCheck,
        106,
        "Absorb Bar",
        "Interface\\AddOns\\MattMinimalFrames\\Images\\absorb.png",
        357,
        86
    )

    local scaleUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
    }
    MattMinimalFramesDB.frameScaleUnit = MattMinimalFramesDB.frameScaleUnit or "player"

    local function EnsureScaleUnitSelection()
        local valid = false
        for _, opt in ipairs(scaleUnitOptions) do
            if opt.value == MattMinimalFramesDB.frameScaleUnit then
                valid = true
                break
            end
        end
        if not valid then
            MattMinimalFramesDB.frameScaleUnit = "player"
        end
    end
    EnsureScaleUnitSelection()

    local scaleXSliders = {}
    local scaleYSliders = {}
    for _, opt in ipairs(scaleUnitOptions) do
        local prefix = (opt.value == "targettarget") and "tot" or opt.value
        scaleXSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -62, 220, prefix .. "FrameScaleX", 0.5, 3.0, 0.05, 1.0, function()
            if MMF_UpdateFrameScale then
                MMF_UpdateFrameScale(opt.value)
            end
        end, false)
        scaleYSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -86, 220, prefix .. "FrameScaleY", 0.5, 5.0, 0.05, 1.0, function()
            if MMF_UpdateFrameScale then
                MMF_UpdateFrameScale(opt.value)
            end
        end, false)
        scaleXSliders[opt.value]:Hide()
        scaleYSliders[opt.value]:Hide()
    end

    local function UpdateVisibleScaleSliders()
        local current = MattMinimalFramesDB.frameScaleUnit
        for _, opt in ipairs(scaleUnitOptions) do
            local show = (opt.value == current)
            scaleXSliders[opt.value]:SetShown(show)
            scaleYSliders[opt.value]:SetShown(show)
        end
    end

    local scaleUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -36,
        width = 220,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = 142,
        visibleRows = #scaleUnitOptions,
        label = "Scale Unit",
        options = scaleUnitOptions,
        getValue = function()
            return MattMinimalFramesDB.frameScaleUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.frameScaleUnit = value
            UpdateVisibleScaleSliders()
        end,
    })
    scaleUnitList = scaleUnitDropdown.list
    UpdateVisibleScaleSliders()

    -- Divider before Frame Text
    local unitFramesDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    unitFramesDivider:SetSize(220, 1)
    unitFramesDivider:SetPoint("TOPLEFT", 12, -108)
    unitFramesDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    -- Frame Text section (moved here)
    local frameTextTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    frameTextTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    frameTextTitle:SetPoint("TOPLEFT", 12, -120)
    frameTextTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    frameTextTitle:SetText("FRAME TEXT")

    local nameTextSlider = CreateMinimalSlider(unitFramesCol, "Name Size", 12, -144, 220, "nameTextSize", 8, 20, 1, 12, function(value)
        if MMF_UpdateNameTextSize then
            MMF_UpdateNameTextSize(value)
        end
    end, true)

    local hpTextSlider = CreateMinimalSlider(unitFramesCol, "HP Size", 12, -168, 220, "hpTextSize", 8, 20, 1, 13, function(value)
        if MMF_UpdateHPTextSize then
            MMF_UpdateHPTextSize(value)
        end
    end, true)

    local function RequestNameTextRefresh()
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
            return
        end
        if MMF_GetAllFrames and MMF_UpdateUnitFrame then
            for _, frame in ipairs(MMF_GetAllFrames()) do
                if frame then
                    MMF_UpdateUnitFrame(frame)
                end
            end
        end
    end

    if MattMinimalFramesDB.enableNameTruncation == nil then
        MattMinimalFramesDB.enableNameTruncation = false
    end
    MattMinimalFramesDB.enableNameTruncation = (MattMinimalFramesDB.enableNameTruncation == true or MattMinimalFramesDB.enableNameTruncation == 1)
    local truncLength = tonumber(MattMinimalFramesDB.nameTruncationLength) or 14
    if truncLength < 5 then truncLength = 5 end
    if truncLength > 30 then truncLength = 30 end
    MattMinimalFramesDB.nameTruncationLength = truncLength

    if MattMinimalFramesDB.autoResizeTextOnLongName == nil then
        MattMinimalFramesDB.autoResizeTextOnLongName = false
    end
    MattMinimalFramesDB.autoResizeTextOnLongName = (MattMinimalFramesDB.autoResizeTextOnLongName == true or MattMinimalFramesDB.autoResizeTextOnLongName == 1)
    if MattMinimalFramesDB.enableNameTruncation and MattMinimalFramesDB.autoResizeTextOnLongName then
        MattMinimalFramesDB.autoResizeTextOnLongName = false
    end

    local truncateNameCheck
    local autoResizeNameCheck
    local truncateNameSlider

    local function SetCheckboxEnabled(container, enabled)
        if not container then return end
        container:SetAlpha(enabled and 1 or 0.45)
        if container.checkbox then
            container.checkbox:EnableMouse(enabled)
        end
    end

    local function UpdateNameFeatureState()
        local truncEnabled = (MattMinimalFramesDB.enableNameTruncation == true or MattMinimalFramesDB.enableNameTruncation == 1)
        local autoEnabled = (MattMinimalFramesDB.autoResizeTextOnLongName == true or MattMinimalFramesDB.autoResizeTextOnLongName == 1)

        truncateNameSlider:SetAlpha(truncEnabled and 1 or 0.45)
        if truncateNameSlider.slider then
            truncateNameSlider.slider:SetEnabled(truncEnabled)
            truncateNameSlider.slider:EnableMouse(truncEnabled)
        end
        if truncateNameSlider.valueText then
            truncateNameSlider.valueText:SetEnabled(truncEnabled)
            truncateNameSlider.valueText:EnableMouse(truncEnabled)
        end

        SetCheckboxEnabled(truncateNameCheck, not autoEnabled)
        SetCheckboxEnabled(autoResizeNameCheck, not truncEnabled)
    end

    truncateNameCheck = CreateMinimalCheckbox(unitFramesCol, "Manual Name Truncate", 12, -192, "enableNameTruncation", false, function(checked)
        MattMinimalFramesDB.enableNameTruncation = checked and true or false
        if checked and MattMinimalFramesDB.autoResizeTextOnLongName then
            MattMinimalFramesDB.autoResizeTextOnLongName = false
            if autoResizeNameCheck and autoResizeNameCheck.checkbox then
                autoResizeNameCheck.checkbox:SetChecked(false)
                autoResizeNameCheck.checkbox.check:SetShown(false)
            end
        end
        UpdateNameFeatureState()
        RequestNameTextRefresh()
    end)

    truncateNameSlider = CreateMinimalSlider(unitFramesCol, "Truncate Length", 12, -216, 220, "nameTruncationLength", 5, 30, 1, 14, function()
        RequestNameTextRefresh()
    end, true)

    autoResizeNameCheck = CreateMinimalCheckbox(unitFramesCol, "Auto Resize Text On Long Name", 12, -240, "autoResizeTextOnLongName", false, function(checked)
        MattMinimalFramesDB.autoResizeTextOnLongName = checked and true or false
        if checked and MattMinimalFramesDB.enableNameTruncation then
            MattMinimalFramesDB.enableNameTruncation = false
            if truncateNameCheck and truncateNameCheck.checkbox then
                truncateNameCheck.checkbox:SetChecked(false)
                truncateNameCheck.checkbox.check:SetShown(false)
            end
        end
        UpdateNameFeatureState()
        RequestNameTextRefresh()
    end)
    UpdateNameFeatureState()

    local textVisibilityDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    textVisibilityDivider:SetSize(220, 1)
    textVisibilityDivider:SetPoint("TOPLEFT", 12, -264)
    textVisibilityDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local textVisibilityTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    textVisibilityTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    textVisibilityTitle:SetPoint("TOPLEFT", 12, -276)
    textVisibilityTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    textVisibilityTitle:SetText("TEXT VISIBILITY")

    local textHideUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
    }

    MattMinimalFramesDB.textHideNameUnit = MattMinimalFramesDB.textHideNameUnit or "player"
    MattMinimalFramesDB.textHideHPUnit = MattMinimalFramesDB.textHideHPUnit or "player"

    local function GetUnitPrefix(unit)
        if unit == "targettarget" then return "tot" end
        return unit
    end

    local function IsValidTextHideUnit(value)
        for _, opt in ipairs(textHideUnitOptions) do
            if opt.value == value then
                return true
            end
        end
        return false
    end

    local function EnsureValidTextHideUnits()
        if not IsValidTextHideUnit(MattMinimalFramesDB.textHideNameUnit) then
            MattMinimalFramesDB.textHideNameUnit = "player"
        end
        if not IsValidTextHideUnit(MattMinimalFramesDB.textHideHPUnit) then
            MattMinimalFramesDB.textHideHPUnit = "player"
        end
    end

    local function ApplyTextVisibilityForUnit(unit)
        if not unit then return end
        if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local frame = MMF_GetFrameForUnit(unit)
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end

    local function BuildTextHideUnitOptions()
        local out = {}
        for _, option in ipairs(textHideUnitOptions) do
            out[#out + 1] = { value = option.value, label = option.label }
        end
        return out
    end

    local hideNameTextCheckbox
    local hideHPTextCheckbox

    local function SetHideNameCheckboxFromDB()
        if not hideNameTextCheckbox then return end
        local prefix = GetUnitPrefix(MattMinimalFramesDB.textHideNameUnit)
        local key = prefix .. "HideNameText"
        hideNameTextCheckbox.checkbox:SetChecked(MattMinimalFramesDB[key] == true)
        hideNameTextCheckbox.checkbox.check:SetShown(hideNameTextCheckbox.checkbox:GetChecked())
    end

    local function SetHideHPCheckboxFromDB()
        if not hideHPTextCheckbox then return end
        local prefix = GetUnitPrefix(MattMinimalFramesDB.textHideHPUnit)
        local key = prefix .. "HideHPText"
        hideHPTextCheckbox.checkbox:SetChecked(MattMinimalFramesDB[key] == true)
        hideHPTextCheckbox.checkbox.check:SetShown(hideHPTextCheckbox.checkbox:GetChecked())
    end

    EnsureValidTextHideUnits()

    local hideNameUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -298,
        width = 220,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = 142,
        visibleRows = #textHideUnitOptions,
        label = "Name Unit",
        options = BuildTextHideUnitOptions(),
        getValue = function()
            return MattMinimalFramesDB.textHideNameUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textHideNameUnit = value
            SetHideNameCheckboxFromDB()
        end,
    })
    hideNameTextUnitList = hideNameUnitDropdown.list

    hideNameTextCheckbox = CreateMinimalCheckbox(unitFramesCol, "Hide Name Text", 12, -322, "__tempHideNameText", false, function(checked)
        local unit = MattMinimalFramesDB.textHideNameUnit
        local prefix = GetUnitPrefix(unit)
        MattMinimalFramesDB[prefix .. "HideNameText"] = checked and true or false
        MattMinimalFramesDB.__tempHideNameText = nil
        ApplyTextVisibilityForUnit(unit)
    end)
    MattMinimalFramesDB.__tempHideNameText = nil
    SetHideNameCheckboxFromDB()

    local hideHPUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 12,
        y = -352,
        width = 220,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = 142,
        visibleRows = #textHideUnitOptions,
        label = "HP Unit",
        options = BuildTextHideUnitOptions(),
        getValue = function()
            return MattMinimalFramesDB.textHideHPUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textHideHPUnit = value
            SetHideHPCheckboxFromDB()
        end,
    })
    hideHPTextUnitList = hideHPUnitDropdown.list

    hideHPTextCheckbox = CreateMinimalCheckbox(unitFramesCol, "Hide HP Text", 12, -376, "__tempHideHPText", false, function(checked)
        local unit = MattMinimalFramesDB.textHideHPUnit
        local prefix = GetUnitPrefix(unit)
        MattMinimalFramesDB[prefix .. "HideHPText"] = checked and true or false
        MattMinimalFramesDB.__tempHideHPText = nil
        ApplyTextVisibilityForUnit(unit)
    end)
    MattMinimalFramesDB.__tempHideHPText = nil
    SetHideHPCheckboxFromDB()

    ---------------------------------------------------

    return {
        castBarColorList = castBarColorList,
        unitTextureList = unitTextureList,
        unitFontList = unitFontList,
        playerIconModeList = playerIconModeList,
        targetIconModeList = targetIconModeList,
        scaleUnitList = scaleUnitList,
        nameTextUnitList = nameTextUnitList,
        hpTextUnitList = hpTextUnitList,
        hideNameTextUnitList = hideNameTextUnitList,
        hideHPTextUnitList = hideHPTextUnitList,
        UpdatePlayerIconModeButtonText = UpdatePlayerIconModeButtonText,
    }
end
