function MMF_BuildUnitFramesOffsetsSection(ctx)
    local unitFramesCol = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = ctx.createMinimalSlider
    local dropdownLists = ctx.dropdownLists

    local LEFT_COL_X = ctx.leftColX
    local LEFT_COL_WIDTH = ctx.leftColWidth
    local LEFT_LABEL_WIDTH = ctx.leftLabelWidth
    local LEFT_BUTTON_OFFSET = ctx.leftButtonOffset
    local LEFT_BUTTON_WIDTH = ctx.leftButtonWidth
    local LEFT_LOWER_Y_OFFSET = ctx.leftLowerYOffset

    local textOffsetsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    textOffsetsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    textOffsetsTitle:SetPoint("TOPLEFT", LEFT_COL_X, -416 + LEFT_LOWER_Y_OFFSET)
    textOffsetsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    textOffsetsTitle:SetText("TEXT OFFSETS")

    local nameUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
        { value = "boss", label = "Boss" },
    }
    local hpUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
        { value = "boss", label = "Boss" },
    }

    local anchorOptions = {
        { value = "TOPLEFT", label = "Top Left" },
        { value = "TOP", label = "Top" },
        { value = "TOPRIGHT", label = "Top Right" },
        { value = "LEFT", label = "Left" },
        { value = "CENTER", label = "Center" },
        { value = "RIGHT", label = "Right" },
        { value = "BOTTOMLEFT", label = "Bottom Left" },
        { value = "BOTTOM", label = "Bottom" },
        { value = "BOTTOMRIGHT", label = "Bottom Right" },
    }

    local function IsValidAnchorPoint(value)
        if type(value) ~= "string" then
            return false
        end
        local upper = string.upper(value)
        for _, opt in ipairs(anchorOptions) do
            if opt.value == upper then
                return true
            end
        end
        return false
    end

    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
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
    local UpdateHPResetButtonLabel = function() end

    local function GetPopupUnitPrefix(unit)
        if unit == "targettarget" then return "tot" end
        if unit == "boss" then return "boss" end
        if unit == "playerCastBar" then return "playerCastBar" end
        if unit == "targetCastBar" then return "targetCastBar" end
        if unit == "focusCastBar" then return "focusCastBar" end
        return unit
    end

    local function SetSliderEnabled(sliderContainer, enabled)
        if not sliderContainer then return end
        sliderContainer:SetAlpha(enabled and 1 or 0.45)
        if sliderContainer.slider then
            sliderContainer.slider:EnableMouse(enabled)
        end
        if sliderContainer.valueText then
            sliderContainer.valueText:EnableMouse(enabled)
        end
        if sliderContainer.resetButton then
            sliderContainer.resetButton:EnableMouse(enabled)
        end
    end

    local function RefreshTextOffsetVisuals()
        if MMF_UpdateFrameTextOffsets then
            MMF_UpdateFrameTextOffsets()
        end
        if MMF_ApplyHPTextPositions then
            MMF_ApplyHPTextPositions()
        end
        if MMF_ApplyPowerTextPositions then
            MMF_ApplyPowerTextPositions()
        end

        if MMF_GetFrameForUnit and MMF_IsNameTextAnchorEnabled and MMF_GetNameTextAnchorPoint and MMF_GetTextAnchorPreset then
            local function ApplyNameAnchorNow(unit)
                local frame = MMF_GetFrameForUnit(unit)
                if not frame or not frame.nameText then
                    return
                end
                if not MMF_IsNameTextAnchorEnabled(unit) then
                    return
                end
                local preset = MMF_GetTextAnchorPreset(MMF_GetNameTextAnchorPoint(unit))
                preset = preset or { point = "TOP", relPoint = "TOP", x = 0, y = -2, justify = "CENTER" }
                frame.nameText:ClearAllPoints()
                frame.nameText:SetPoint(preset.point, frame, preset.relPoint, preset.x, preset.y)
                if frame.nameText.SetJustifyH then
                    frame.nameText:SetJustifyH(preset.justify or "CENTER")
                end
            end

            ApplyNameAnchorNow("player")
            ApplyNameAnchorNow("target")
            ApplyNameAnchorNow("targettarget")
            ApplyNameAnchorNow("pet")
            ApplyNameAnchorNow("focus")
            ApplyNameAnchorNow("boss1")
            ApplyNameAnchorNow("boss2")
            ApplyNameAnchorNow("boss3")
            ApplyNameAnchorNow("boss4")
            ApplyNameAnchorNow("boss5")
        end

        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        end
    end

    local function ApplyNameAnchorDirectForUnit(unit)
        if not MMF_GetFrameForUnit or not MMF_GetTextAnchorPreset then
            return
        end

        local function ApplyToFrame(frameUnit)
            local frame = MMF_GetFrameForUnit(frameUnit)
            if not frame or not frame.nameText then
                return
            end
            if not ((MMF_IsNameTextAnchorEnabled and MMF_IsNameTextAnchorEnabled(unit)) or false) then
                return
            end
            local selectedAnchor = (MMF_GetNameTextAnchorPoint and MMF_GetNameTextAnchorPoint(unit)) or "TOP"
            local preset = MMF_GetTextAnchorPreset(selectedAnchor)
            preset = preset or { point = "TOP", relPoint = "TOP", x = 0, y = -2, justify = "CENTER" }
            frame.nameText:ClearAllPoints()
            frame.nameText:SetPoint(preset.point, frame, preset.relPoint, preset.x, preset.y)
            if frame.nameText.SetJustifyH then
                frame.nameText:SetJustifyH(preset.justify or "CENTER")
            end
        end

        if unit == "boss" then
            for i = 1, 5 do
                ApplyToFrame("boss" .. i)
            end
            return
        end
        ApplyToFrame(unit)
    end

    local function GetNameAnchorEnabled(unit)
        local prefix = GetPopupUnitPrefix(unit)
        return MattMinimalFramesDB[prefix .. "NameTextAnchorEnabled"] == true
    end

    local function SetNameAnchorEnabled(unit, enabled)
        local prefix = GetPopupUnitPrefix(unit)
        MattMinimalFramesDB[prefix .. "NameTextAnchorEnabled"] = enabled == true
    end

    local function GetNameAnchorPoint(unit)
        local prefix = GetPopupUnitPrefix(unit)
        local key = prefix .. "NameTextAnchorPoint"
        local value = MattMinimalFramesDB[key]
        if not IsValidAnchorPoint(value) then
            value = "TOP"
            MattMinimalFramesDB[key] = value
        end
        return value
    end

    local function SetNameAnchorPoint(unit, point)
        local prefix = GetPopupUnitPrefix(unit)
        local key = prefix .. "NameTextAnchorPoint"
        if not IsValidAnchorPoint(point) then
            point = "TOP"
        end
        MattMinimalFramesDB[key] = point
    end

    local function GetHPAnchorEnabled(unit)
        local prefix = GetPopupUnitPrefix(unit)
        return MattMinimalFramesDB[prefix .. "HPTextAnchorEnabled"] == true
    end

    local function SetHPAnchorEnabled(unit, enabled)
        local prefix = GetPopupUnitPrefix(unit)
        MattMinimalFramesDB[prefix .. "HPTextAnchorEnabled"] = enabled == true
    end

    local function GetHPAnchorPoint(unit)
        local prefix = GetPopupUnitPrefix(unit)
        local key = prefix .. "HPTextAnchorPoint"
        local value = MattMinimalFramesDB[key]
        if not IsValidAnchorPoint(value) then
            value = "BOTTOM"
            MattMinimalFramesDB[key] = value
        end
        return value
    end

    local function SetHPAnchorPoint(unit, point)
        local prefix = GetPopupUnitPrefix(unit)
        local key = prefix .. "HPTextAnchorPoint"
        if not IsValidAnchorPoint(point) then
            point = "BOTTOM"
        end
        MattMinimalFramesDB[key] = point
    end

    local nameUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "textOffsetNameUnit",
        x = LEFT_COL_X,
        y = -434 + LEFT_LOWER_Y_OFFSET,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
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

    local nameAnchorToggle
    local nameAnchorDropdown

    nameAnchorToggle = CreateMinimalCheckbox(
        unitFramesCol,
        "Anchor Name Text Inside",
        LEFT_COL_X,
        -458 + LEFT_LOWER_Y_OFFSET,
        "__tempNameTextAnchorEnabled",
        false,
        function(checked)
            local unit = MattMinimalFramesDB.textOffsetNameUnit or "player"
            SetNameAnchorEnabled(unit, checked)
            MattMinimalFramesDB.__tempNameTextAnchorEnabled = nil
            UpdateVisibleNameOffsetSliders()
            ApplyNameAnchorDirectForUnit(unit)
            RefreshTextOffsetVisuals()
        end
    )

    nameAnchorDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "__tempNameTextAnchorPoint",
        x = LEFT_COL_X,
        y = -482 + LEFT_LOWER_Y_OFFSET,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #anchorOptions,
        label = "Name Anchor",
        options = anchorOptions,
        getValue = function()
            local unit = MattMinimalFramesDB.textOffsetNameUnit or "player"
            return GetNameAnchorPoint(unit)
        end,
        onSelect = function(value)
            local unit = MattMinimalFramesDB.textOffsetNameUnit or "player"
            SetNameAnchorEnabled(unit, true)
            SetNameAnchorPoint(unit, value)
            UpdateVisibleNameOffsetSliders()
            ApplyNameAnchorDirectForUnit(unit)
            RefreshTextOffsetVisuals()
        end,
    })

    local nameXSliders = {}
    local nameYSliders = {}
    for _, opt in ipairs(nameUnitOptions) do
        local prefix = GetPopupUnitPrefix(opt.value)
        nameXSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Name X Offset", LEFT_COL_X, -506 + LEFT_LOWER_Y_OFFSET, LEFT_COL_WIDTH, prefix .. "NameTextXOffset", -60, 60, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        nameYSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "Name Y Offset", LEFT_COL_X, -530 + LEFT_LOWER_Y_OFFSET, LEFT_COL_WIDTH, prefix .. "NameTextYOffset", -60, 60, 1, 0, function()
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
        local anchorEnabled = GetNameAnchorEnabled(current)

        if nameAnchorToggle and nameAnchorToggle.checkbox then
            nameAnchorToggle.checkbox:SetChecked(anchorEnabled)
            if nameAnchorToggle.checkbox.check then
                nameAnchorToggle.checkbox.check:SetShown(anchorEnabled)
            end
        end
        if nameAnchorDropdown and nameAnchorDropdown.SetSelectedValue then
            nameAnchorDropdown.SetSelectedValue(GetNameAnchorPoint(current))
        end
        if nameAnchorDropdown and nameAnchorDropdown.container then
            nameAnchorDropdown.container:SetAlpha(anchorEnabled and 1 or 0.45)
            if nameAnchorDropdown.button then
                nameAnchorDropdown.button:EnableMouse(anchorEnabled)
            end
        end

        for _, opt in ipairs(nameUnitOptions) do
            local isCurrent = (opt.value == current)
            local show = isCurrent
            nameXSliders[opt.value]:SetShown(show)
            nameYSliders[opt.value]:SetShown(show)
            if show then
                SetSliderEnabled(nameXSliders[opt.value], not anchorEnabled)
                SetSliderEnabled(nameYSliders[opt.value], not anchorEnabled)
            end
        end
    end

    dropdownLists.nameTextUnitList = nameUnitDropdown.list
    dropdownLists.nameTextAnchorList = nameAnchorDropdown.list

    local hpUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "textOffsetHPUnit",
        x = LEFT_COL_X,
        y = -562 + LEFT_LOWER_Y_OFFSET,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #hpUnitOptions,
        label = "HP Unit",
        options = hpUnitOptions,
        getValue = function()
            return MattMinimalFramesDB.textOffsetHPUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textOffsetHPUnit = value
            UpdateVisibleHPOffsetSliders()
            UpdateHPResetButtonLabel()
        end,
    })

    local hpAnchorToggle
    local hpAnchorDropdown

    hpAnchorToggle = CreateMinimalCheckbox(
        unitFramesCol,
        "Anchor HP Text Inside",
        LEFT_COL_X,
        -586 + LEFT_LOWER_Y_OFFSET,
        "__tempHPTextAnchorEnabled",
        false,
        function(checked)
            local unit = MattMinimalFramesDB.textOffsetHPUnit or "player"
            SetHPAnchorEnabled(unit, checked)
            MattMinimalFramesDB.__tempHPTextAnchorEnabled = nil
            UpdateVisibleHPOffsetSliders()
            RefreshTextOffsetVisuals()
        end
    )

    hpAnchorDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "__tempHPTextAnchorPoint",
        x = LEFT_COL_X,
        y = -610 + LEFT_LOWER_Y_OFFSET,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #anchorOptions,
        label = "HP Anchor",
        options = anchorOptions,
        getValue = function()
            local unit = MattMinimalFramesDB.textOffsetHPUnit or "player"
            return GetHPAnchorPoint(unit)
        end,
        onSelect = function(value)
            local unit = MattMinimalFramesDB.textOffsetHPUnit or "player"
            SetHPAnchorEnabled(unit, true)
            SetHPAnchorPoint(unit, value)
            UpdateVisibleHPOffsetSliders()
            RefreshTextOffsetVisuals()
        end,
    })

    local function ResetSelectedHPPosition()
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end

        local selectedUnit = MattMinimalFramesDB.textOffsetHPUnit or "player"
        local prefix = GetPopupUnitPrefix(selectedUnit)
        local defaults = MattMinimalFrames_Defaults or {}

        MattMinimalFramesDB[prefix .. "HPTextXOffset"] = defaults[prefix .. "HPTextXOffset"] or defaults.hpTextXOffset or 0
        MattMinimalFramesDB[prefix .. "HPTextYOffset"] = defaults[prefix .. "HPTextYOffset"] or defaults.hpTextYOffset or 0

        if MattMinimalFramesDB.hpTextPositions then
            if selectedUnit == "boss" then
                for i = 1, 5 do
                    MattMinimalFramesDB.hpTextPositions["boss" .. i] = nil
                end
            else
                MattMinimalFramesDB.hpTextPositions[selectedUnit] = nil
            end
        end
    end

    local hpResetPositionButton = CreateFrame("Button", nil, unitFramesCol, "BackdropTemplate")
    hpResetPositionButton:SetSize(LEFT_COL_WIDTH, 20)
    hpResetPositionButton:SetPoint("TOPLEFT", LEFT_COL_X, -662 + LEFT_LOWER_Y_OFFSET)
    hpResetPositionButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    hpResetPositionButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
    hpResetPositionButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local hpResetPositionButtonText = hpResetPositionButton:CreateFontString(nil, "OVERLAY")
    hpResetPositionButtonText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    hpResetPositionButtonText:SetPoint("CENTER")
    hpResetPositionButtonText:SetTextColor(0.85, 0.85, 0.85)
    hpResetPositionButtonText:SetText("Reset HP Position")

    local function GetUnitLabel(options, value)
        for _, opt in ipairs(options) do
            if opt.value == value then
                return opt.label
            end
        end
        return "Selected"
    end

    UpdateHPResetButtonLabel = function()
        local selectedUnit = MattMinimalFramesDB.textOffsetHPUnit or "player"
        local label = GetUnitLabel(hpUnitOptions, selectedUnit)
        hpResetPositionButtonText:SetText("Reset " .. label .. " HP Position")
    end

    hpResetPositionButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.6)
        hpResetPositionButtonText:SetTextColor(1, 1, 1)
    end)
    hpResetPositionButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        hpResetPositionButtonText:SetTextColor(0.85, 0.85, 0.85)
    end)

    local hpXSliders = {}
    local hpYSliders = {}
    for _, opt in ipairs(hpUnitOptions) do
        local prefix = GetPopupUnitPrefix(opt.value)
        hpXSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "HP X Offset", LEFT_COL_X, -692 + LEFT_LOWER_Y_OFFSET, LEFT_COL_WIDTH, prefix .. "HPTextXOffset", -500, 500, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        hpYSliders[opt.value] = CreateMinimalSlider(unitFramesCol, "HP Y Offset", LEFT_COL_X, -718 + LEFT_LOWER_Y_OFFSET, LEFT_COL_WIDTH, prefix .. "HPTextYOffset", -500, 500, 1, 0, function()
            if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end
        end, true)
        hpXSliders[opt.value]:Hide()
        hpYSliders[opt.value]:Hide()
    end

    hpResetPositionButton:SetScript("OnClick", function()
        ResetSelectedHPPosition()

        local selectedUnit = MattMinimalFramesDB.textOffsetHPUnit or "player"
        local prefix = GetPopupUnitPrefix(selectedUnit)
        local xVal = tonumber(MattMinimalFramesDB[prefix .. "HPTextXOffset"]) or 0
        local yVal = tonumber(MattMinimalFramesDB[prefix .. "HPTextYOffset"]) or 0

        if hpXSliders[selectedUnit] and hpXSliders[selectedUnit].slider then
            hpXSliders[selectedUnit].slider:SetValue(xVal)
        end
        if hpYSliders[selectedUnit] and hpYSliders[selectedUnit].slider then
            hpYSliders[selectedUnit].slider:SetValue(yVal)
        end

        RefreshTextOffsetVisuals()
    end)

    local function UpdateHPUnitButtonText()
        hpUnitDropdown.SetSelectedValue(MattMinimalFramesDB.textOffsetHPUnit)
    end

    UpdateVisibleHPOffsetSliders = function()
        local current = MattMinimalFramesDB.textOffsetHPUnit
        local anchorEnabled = GetHPAnchorEnabled(current)

        if hpAnchorToggle and hpAnchorToggle.checkbox then
            hpAnchorToggle.checkbox:SetChecked(anchorEnabled)
            if hpAnchorToggle.checkbox.check then
                hpAnchorToggle.checkbox.check:SetShown(anchorEnabled)
            end
        end
        if hpAnchorDropdown and hpAnchorDropdown.SetSelectedValue then
            hpAnchorDropdown.SetSelectedValue(GetHPAnchorPoint(current))
        end
        if hpAnchorDropdown and hpAnchorDropdown.container then
            hpAnchorDropdown.container:SetAlpha(anchorEnabled and 1 or 0.45)
            if hpAnchorDropdown.button then
                hpAnchorDropdown.button:EnableMouse(anchorEnabled)
            end
        end

        hpResetPositionButton:SetAlpha(anchorEnabled and 0.45 or 1)
        hpResetPositionButton:EnableMouse(not anchorEnabled)

        for _, opt in ipairs(hpUnitOptions) do
            local isCurrent = (opt.value == current)
            local show = isCurrent
            hpXSliders[opt.value]:SetShown(show)
            hpYSliders[opt.value]:SetShown(show)
            if show then
                SetSliderEnabled(hpXSliders[opt.value], not anchorEnabled)
                SetSliderEnabled(hpYSliders[opt.value], not anchorEnabled)
            end
        end
    end

    dropdownLists.hpTextUnitList = hpUnitDropdown.list
    dropdownLists.hpTextAnchorList = hpAnchorDropdown.list

    UpdateNameUnitButtonText()
    UpdateVisibleNameOffsetSliders()
    UpdateHPUnitButtonText()
    UpdateHPResetButtonLabel()
    UpdateVisibleHPOffsetSliders()

    local offsetsDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    offsetsDivider:SetSize(LEFT_COL_WIDTH, 1)
    offsetsDivider:SetPoint("TOPLEFT", LEFT_COL_X, -404 + LEFT_LOWER_Y_OFFSET)
    offsetsDivider:SetColorTexture(0.42, 0.42, 0.46, 1)
end
