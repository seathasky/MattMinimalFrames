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
    local nameTextUnitList
    local hpTextUnitList
    local UpdatePlayerIconModeButtonText = function() end

    -- UNIT FRAMES COLUMN (2nd Column)
    ---------------------------------------------------
    local unitFramesTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    unitFramesTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    unitFramesTitle:SetPoint("TOPLEFT", 12, -12)
    unitFramesTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    unitFramesTitle:SetText("UNIT FRAMES")

    -- Right-side style column for unit frame texture selection
    local unitFramesSplit = unitFramesCol:CreateTexture(nil, "ARTWORK")
    unitFramesSplit:SetPoint("TOPLEFT", 228, -36)
    unitFramesSplit:SetPoint("BOTTOMLEFT", 228, 12)
    unitFramesSplit:SetWidth(1)
    unitFramesSplit:SetColorTexture(0.12, 0.12, 0.15, 1)

    local textOffsetsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    textOffsetsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    textOffsetsTitle:SetPoint("TOPLEFT", 244, -36)
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
        x = 244,
        y = -60,
        width = 300,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 180,
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
        nameXSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Name X Offset", 244, -86, 300, prefix .. "NameTextXOffset", -60, 60, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        nameYSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Name Y Offset", 244, -110, 300, prefix .. "NameTextYOffset", -60, 60, 1, 0, function()
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
        x = 244,
        y = -142,
        width = 300,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 180,
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
        hpXSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "HP X Offset", 244, -168, 300, prefix .. "HPTextXOffset", -60, 60, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        hpYSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "HP Y Offset", 244, -192, 300, prefix .. "HPTextYOffset", -60, 60, 1, 0, function()
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
    offsetsDivider:SetSize(300, 1)
    offsetsDivider:SetPoint("TOPLEFT", 244, -220)
    offsetsDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local castBarsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    castBarsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    castBarsTitle:SetPoint("TOPLEFT", 244, -232)
    castBarsTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    castBarsTitle:SetText("CAST BARS")

    local playerCastBarCheck = CreateMinimalCheckbox(unitFramesCol, "Player Cast Bar", 244, -256, "showPlayerCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local targetCastBarCheck = CreateMinimalCheckbox(unitFramesCol, "Target Cast Bar", 244, -280, "showTargetCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    local castBarColorDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 244,
        y = -304,
        width = 300,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 180,
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

    local styleTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    styleTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    styleTitle:SetPoint("TOPLEFT", 244, -356)
    styleTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    styleTitle:SetText("STYLE")

    local styleSubtext = unitFramesCol:CreateFontString(nil, "OVERLAY")
    styleSubtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    styleSubtext:SetPoint("TOPLEFT", 244, -376)
    styleSubtext:SetTextColor(0.65, 0.65, 0.7)
    styleSubtext:SetText("SharedMedia unit frame textures and fonts")

    local unitTextureDropdown

    local texturePreviewBG = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
    texturePreviewBG:SetSize(222, 16)
    texturePreviewBG:SetPoint("TOPLEFT", 308, -434)
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
    local selectedTexture = MattMinimalFramesDB.statusBarTexture or "MMF Melli"

    local function HasTextureOption(name)
        for _, optName in ipairs(textureOptions) do
            if optName == name then
                return true
            end
        end
        return false
    end

    local function EnsureValidSelectedTexture()
        textureOptions = MMF_GetStatusBarTextureOptions and MMF_GetStatusBarTextureOptions() or { "MMF Melli" }
        for _, name in ipairs(textureOptions) do
            if name == selectedTexture then
                return
            end
        end
        if HasTextureOption("MMF Melli") then
            selectedTexture = "MMF Melli"
        else
            selectedTexture = textureOptions[1] or "MMF Melli"
        end
    end
    EnsureValidSelectedTexture()
    MattMinimalFramesDB.statusBarTexture = selectedTexture

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
        selectedTexture = name
        if MMF_SetStatusBarTexture then
            MMF_SetStatusBarTexture(name)
        else
            MattMinimalFramesDB.statusBarTexture = name
        end
        UpdateUnitTexturePreview()
        if unitTextureDropdown then
            unitTextureDropdown.SetSelectedValue(selectedTexture)
        end
    end

    unitTextureDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 244,
        y = -400,
        width = 300,
        labelWidth = 62,
        buttonOffset = 64,
        buttonWidth = 220,
        visibleRows = 9,
        label = "Texture",
        options = BuildTextureDropdownOptions(),
        getValue = function()
            return selectedTexture
        end,
        optionsProvider = function()
            EnsureValidSelectedTexture()
            return BuildTextureDropdownOptions()
        end,
        onOpen = function()
            EnsureValidSelectedTexture()
            UpdateUnitTexturePreview()
        end,
        onSelect = function(value)
            ApplySelectedTexture(value)
        end,
    })
    unitTextureList = unitTextureDropdown.list

    local fontOptions = MMF_GetFontOptions and MMF_GetFontOptions() or { "MMF Naowh" }
    local selectedFont = MattMinimalFramesDB.globalFont or "MMF Naowh"

    local function EnsureValidSelectedFont()
        fontOptions = MMF_GetFontOptions and MMF_GetFontOptions() or { "MMF Naowh" }
        for _, name in ipairs(fontOptions) do
            if name == selectedFont then
                return
            end
        end
        selectedFont = fontOptions[1] or "MMF Naowh"
    end
    EnsureValidSelectedFont()
    MattMinimalFramesDB.globalFont = selectedFont

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
        x = 244,
        y = -470,
        width = 300,
        labelWidth = 62,
        buttonOffset = 64,
        buttonWidth = 220,
        visibleRows = 9,
        label = "Font",
        options = BuildFontDropdownOptions(),
        getValue = function()
            return selectedFont
        end,
        optionsProvider = function()
            EnsureValidSelectedFont()
            return BuildFontDropdownOptions()
        end,
        onSelect = function(value)
            selectedFont = value
            if MMF_SetGlobalFont then
                MMF_SetGlobalFont(value)
            else
                MattMinimalFramesDB.globalFont = value
            end
            unitFontDropdown.SetSelectedValue(selectedFont)
        end,
    })
    unitFontList = unitFontDropdown.list

    local styleDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    styleDivider:SetSize(300, 1)
    styleDivider:SetPoint("TOPLEFT", 244, -494)
    styleDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local iconModeOptions = {
        { value = "off", label = "Off" },
        { value = "class", label = "Class Icon" },
        { value = "portrait", label = "Portrait" },
    }
    local playerIconModeDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = 244,
        y = -506,
        width = 300,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 180,
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
        x = 244,
        y = -530,
        width = 300,
        labelWidth = 95,
        buttonOffset = 104,
        buttonWidth = 180,
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

    local targetMarkersCheck = CreateMinimalCheckbox(unitFramesCol, "Target Markers", 244, -554, "showTargetMarkers", false, function(checked)
        if MMF_UpdateTargetMarkerVisibility then
            MMF_UpdateTargetMarkerVisibility(checked)
        end
    end)

    -- Player Frame Scale
    local playerLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    playerLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    playerLabel:SetPoint("TOPLEFT", 12, -36)
    playerLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    playerLabel:SetText("Player")

    local playerScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -56, 200, "playerFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("player")
        end
    end, false)

    local playerScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -80, 200, "playerFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("player")
        end
    end, false)

    -- Target Frame Scale
    local targetLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    targetLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    targetLabel:SetPoint("TOPLEFT", 12, -108)
    targetLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    targetLabel:SetText("Target")

    local targetScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -128, 200, "targetFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("target")
        end
    end, false)

    local targetScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -152, 200, "targetFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("target")
        end
    end, false)

    -- Target of Target Frame Scale
    local totLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    totLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    totLabel:SetPoint("TOPLEFT", 12, -180)
    totLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    totLabel:SetText("Target of Target")

    local totScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -200, 200, "totFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("targettarget")
        end
    end, false)

    local totScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -224, 200, "totFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("targettarget")
        end
    end, false)

    -- Focus Frame Scale
    local focusLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    focusLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    focusLabel:SetPoint("TOPLEFT", 12, -252)
    focusLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    focusLabel:SetText("Focus")

    local focusScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -272, 200, "focusFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("focus")
        end
    end, false)

    local focusScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -296, 200, "focusFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("focus")
        end
    end, false)

    -- Pet Frame Scale
    local petLabel = unitFramesCol:CreateFontString(nil, "OVERLAY")
    petLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "OUTLINE")
    petLabel:SetPoint("TOPLEFT", 12, -324)
    petLabel:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    petLabel:SetText("Pet")

    local petScaleXSlider = CreateMinimalSlider(unitFramesCol, "Scale X", 12, -344, 200, "petFrameScaleX", 0.5, 3.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("pet")
        end
    end, false)

    local petScaleYSlider = CreateMinimalSlider(unitFramesCol, "Scale Y", 12, -368, 200, "petFrameScaleY", 0.5, 5.0, 0.05, 1.0, function(value)
        if MMF_UpdateFrameScale then
            MMF_UpdateFrameScale("pet")
        end
    end, false)

    -- Divider before Frame Text
    local unitFramesDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    unitFramesDivider:SetSize(200, 1)
    unitFramesDivider:SetPoint("TOPLEFT", 12, -400)
    unitFramesDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    -- Frame Text section (moved here)
    local frameTextTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    frameTextTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    frameTextTitle:SetPoint("TOPLEFT", 12, -412)
    frameTextTitle:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
    frameTextTitle:SetText("FRAME TEXT")

    local nameTextSlider = CreateMinimalSlider(unitFramesCol, "Name Size", 12, -436, 200, "nameTextSize", 8, 20, 1, 12, function(value)
        if MMF_UpdateNameTextSize then
            MMF_UpdateNameTextSize(value)
        end
    end, true)

    local hpTextSlider = CreateMinimalSlider(unitFramesCol, "HP Size", 12, -460, 200, "hpTextSize", 8, 20, 1, 13, function(value)
        if MMF_UpdateHPTextSize then
            MMF_UpdateHPTextSize(value)
        end
    end, true)

    ---------------------------------------------------

    return {
        castBarColorList = castBarColorList,
        unitTextureList = unitTextureList,
        unitFontList = unitFontList,
        playerIconModeList = playerIconModeList,
        targetIconModeList = targetIconModeList,
        nameTextUnitList = nameTextUnitList,
        hpTextUnitList = hpTextUnitList,
        UpdatePlayerIconModeButtonText = UpdatePlayerIconModeButtonText,
    }
end
