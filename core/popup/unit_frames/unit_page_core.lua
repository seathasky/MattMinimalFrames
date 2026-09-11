local function MMF_GetUnitPagePrefix(unit)
    if unit == "targettarget" then
        return "tot"
    end
    return unit
end

MMF_UNIT_FRAMES_SECTION_TITLE_SIZE = 16

MMF_UNIT_FRAMES_TITLE_TONES = {
    frame = { 0.48, 0.88, 0.88 },
    power = { 0.40, 0.75, 0.95 },
    aura = { 0.73, 0.62, 0.95 },
    cast = { 0.95, 0.66, 0.42 },
    icon = { 0.90, 0.78, 0.38 },
    appearance = { 0.45, 0.88, 0.66 },
    visibility = { 0.95, 0.72, 0.38 },
    overlay = { 0.94, 0.58, 0.75 },
    shared = { 0.64, 0.80, 0.92 },
}

local function MMF_GetUnitFramesHeadingRGB(tone)
    local moduleColor = MMF_UNIT_FRAMES_TITLE_TONES[tone]
    if moduleColor then
        return moduleColor[1], moduleColor[2], moduleColor[3]
    end
    if MMF_GetPopupSectionTitleColor then
        local r, g, b = MMF_GetPopupSectionTitleColor()
        if type(r) == "table" then
            return r[1] or 0.55, r[2] or 0.94, r[3] or 0.90
        end
        if type(r) == "number" and type(g) == "number" and type(b) == "number" then
            return r, g, b
        end
    end
    return 0.55, 0.94, 0.90
end

function MMF_ApplyUnitFramesHeadingColor(region, tone)
    if not region or not region.SetTextColor then return end
    local r, g, b = MMF_GetUnitFramesHeadingRGB(tone)
    region:SetTextColor(r, g, b)
end

function MMF_CreateUnitFramesSectionHeader(parent, text, x, y, tone)
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE, "")
    title:SetPoint("TOPLEFT", x, y)
    MMF_ApplyUnitFramesHeadingColor(title, tone)
    title:SetText(string.upper(tostring(text or "")))
    return title
end

function MMF_CreateUnitFramesSectionCard(parent, x, y, width, height, tone)
    local background = parent:CreateTexture(nil, "BACKGROUND", nil, -8)
    background:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    background:SetSize(width, height)
    background:SetColorTexture(0.035, 0.048, 0.062, 0.44)

    return { background = background }
end

MMF_UNIT_PAGE_LAYOUT = MMF_UNIT_PAGE_LAYOUT or {
    leftX = 12,
    rightX = 382,
    columnWidth = 346,
    headingY = -12,
    firstRowY = -42,
    rowStep = 28,
    sectionGap = 36,
    cardGap = 8,
    cardBottomPadding = 16,
}

local function MMF_CreateUnitPageSectionTitle(parent, text, x, y, tone)
    return MMF_CreateUnitFramesSectionHeader(parent, text, x, y, tone)
end

local function MMF_RefreshUnitPageText(unit)
    if unit == "boss" and MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
        for index = 1, 5 do
            local frame = MMF_GetFrameForUnit("boss" .. index)
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
        return
    end

    if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
        local frame = MMF_GetFrameForUnit(unit)
        if frame then
            MMF_UpdateUnitFrame(frame)
            return
        end
    end

    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
    end
end

local function MMF_RefreshUnitPageTextPositions()
    if MMF_UpdateFrameTextOffsets then
        MMF_UpdateFrameTextOffsets()
    end
    if MMF_ApplyHPTextPositions then
        MMF_ApplyHPTextPositions()
    end
    if MMF_ApplyPowerTextPositions then
        MMF_ApplyPowerTextPositions()
    end
    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
    end
end

local function MMF_ApplyUnitPageNameAnchor(unit)
    if not (MMF_GetFrameForUnit and MMF_GetTextAnchorPreset and MMF_IsNameTextAnchorEnabled and MMF_IsNameTextAnchorEnabled(unit)) then
        return
    end

    local selected = MMF_GetNameTextAnchorPoint and MMF_GetNameTextAnchorPoint(unit) or "TOP"
    local preset = MMF_GetTextAnchorPreset(selected)
    preset = preset or { point = "TOP", relPoint = "TOP", x = 0, y = -2, justify = "CENTER" }

    local function ApplyToFrame(frameUnit)
        local frame = MMF_GetFrameForUnit(frameUnit)
        if not frame or not frame.nameText then
            return
        end
        frame.nameText:ClearAllPoints()
        frame.nameText:SetPoint(preset.point, frame, preset.relPoint, preset.x, preset.y)
        if frame.nameText.SetJustifyH then
            frame.nameText:SetJustifyH(preset.justify or "CENTER")
        end
    end

    if unit == "boss" then
        for index = 1, 5 do
            ApplyToFrame("boss" .. index)
        end
        return
    end

    ApplyToFrame(unit)
end

function MMF_BuildUnitFramesUnitPageCore(ctx)
    local parent = ctx.parent
    local popup = ctx.popup
    local unit = ctx.unit
    local prefix = MMF_GetUnitPagePrefix(unit)
    local CreateCheckbox = ctx.createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateSlider = ctx.createMinimalSlider or MMF_CreateMinimalSlider
    local accentColor = ctx.accentColor or { 0.6, 0.4, 0.9 }
    local dropdownLists = ctx.dropdownLists or {}
    local defaults = MattMinimalFrames_Defaults or {}
    local db = MattMinimalFramesDB or {}

    -- Match the unit page viewport: two generous columns make sliders and
    -- dropdown values legible instead of compressing the page vertically.
    local layout = MMF_UNIT_PAGE_LAYOUT
    local leftX, rightX = layout.leftX, layout.rightX
    local columnWidth = layout.columnWidth
    local frameTitleY = layout.headingY
    local textTitleY = layout.headingY
    local cardGap = layout.cardGap or 8
    local cardBottomPadding = layout.cardBottomPadding or 16
    local hideFrameKeys = {
        targettarget = "hideTargetOfTargetFrame",
        pet = "hidePetFrame",
        focus = "hideFocusFrame",
        boss = "hideBossFrames",
    }
    local hideFrameKey = hideFrameKeys[unit]
    local hasFrameExtraRow = unit == "player" or unit == "boss"
    local frameLastBottom = hasFrameExtraRow and 180 or 152
    local frameCardHeight = frameLastBottom + cardBottomPadding
    local textSizeCardHeight = 96 + cardBottomPadding
    local textFormatStart = textSizeCardHeight + cardGap
    local textFormatCardHeight = 180 + cardBottomPadding
    local visibilityStart = frameCardHeight + cardGap
    local visibilityLastBottom = hideFrameKey and 124 or 96
    local visibilityCardHeight = visibilityLastBottom + cardBottomPadding
    local upperGridEnd = math.max(visibilityStart + visibilityCardHeight, textFormatStart + textFormatCardHeight)
    local positionStart = upperGridEnd + cardGap
    local positionCardHeight = 152 + cardBottomPadding
    local embeddedStart = positionStart + positionCardHeight + cardGap

    -- Every card is sized from its final row, then receives the same bottom
    -- padding and inter-card gap. Sparse sections no longer reserve arbitrary
    -- vertical space and dense sections cannot touch their card boundary.
    MMF_CreateUnitFramesSectionCard(parent, 4, 0, 360, frameCardHeight, "frame")
    MMF_CreateUnitFramesSectionCard(parent, 376, 0, 360, textSizeCardHeight, "frame")
    MMF_CreateUnitFramesSectionCard(parent, 376, -textFormatStart, 360, textFormatCardHeight, "frame")
    MMF_CreateUnitFramesSectionCard(parent, 4, -visibilityStart, 360, visibilityCardHeight, "frame")
    MMF_CreateUnitFramesSectionCard(parent, 4, -positionStart, 360, positionCardHeight, "frame")
    MMF_CreateUnitFramesSectionCard(parent, 376, -positionStart, 360, positionCardHeight, "frame")

    local function DefaultValue(key, fallback)
        local value = defaults[key]
        if value == nil then
            value = fallback
        end
        return value
    end

    local function UpdateFrameVisibility()
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
        if MMF_ApplyAllFramePositions then
            MMF_ApplyAllFramePositions()
        end
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        end
    end

    -- Frame
    MMF_CreateUnitPageSectionTitle(parent, "FRAME SIZE", leftX, frameTitleY, "frame")
    CreateSlider(parent, "Scale X", leftX, -42, columnWidth, prefix .. "FrameScaleX", 0.1, 6.0, 0.05,
        DefaultValue(prefix .. "FrameScaleX", 1.0), function()
            if MMF_UpdateFrameScale then
                MMF_UpdateFrameScale(unit)
            end
        end, false)
    CreateSlider(parent, "Scale Y", leftX, -70, columnWidth, prefix .. "FrameScaleY", 0.1, 10.0, 0.05,
        DefaultValue(prefix .. "FrameScaleY", 1.0), function()
            if MMF_UpdateFrameScale then
                MMF_UpdateFrameScale(unit)
            end
        end, false)

    local definitionUnit = unit == "boss" and "boss1" or unit
    local definition = MMF_GetFrameDefinition and MMF_GetFrameDefinition(definitionUnit) or {}
    CreateSlider(parent, "Center X", leftX, -98, columnWidth, prefix .. "FrameCenterX", -1200, 1200, 1,
        DefaultValue(prefix .. "FrameCenterX", tonumber(definition.x) or 0), function()
            if MMF_ApplyFrameCenterPositionForUnit then
                MMF_ApplyFrameCenterPositionForUnit(unit, "x")
            end
        end, true)
    CreateSlider(parent, "Center Y", leftX, -126, columnWidth, prefix .. "FrameCenterY", -1200, 1200, 1,
        DefaultValue(prefix .. "FrameCenterY", tonumber(definition.y) or 0), function()
            if MMF_ApplyFrameCenterPositionForUnit then
                MMF_ApplyFrameCenterPositionForUnit(unit, "y")
            end
        end, true)

    if unit == "player" then
        CreateCheckbox(parent, "Health Fill Top to Bottom", leftX, -154, "healthFillTopToBottom", false, function()
            if MMF_ApplyHealthFillDirections then
                MMF_ApplyHealthFillDirections()
            end
            if MMF_RequestAllFramesUpdate then
                MMF_RequestAllFramesUpdate()
            end
        end)
    elseif unit == "boss" then
        CreateSlider(parent, "Bottom Padding", leftX, -154, columnWidth, "bossFrameBottomPadding", 0, 64, 1,
            DefaultValue("bossFrameBottomPadding", 0), function()
                UpdateFrameVisibility()
            end, true)
    end

    -- Text size
    MMF_CreateUnitPageSectionTitle(parent, "FRAME TEXT SIZE", rightX, textTitleY, "frame")
    local nameTextDefault = defaults[prefix .. "NameTextSize"]
        or db.nameTextSize
        or defaults.nameTextSize
        or 12
    CreateSlider(parent, "Name Size", rightX, -42, columnWidth, prefix .. "NameTextSize", 8, 20, 1,
        nameTextDefault, function(value)
            if MMF_UpdateNameTextSize then
                MMF_UpdateNameTextSize(value, unit)
            end
            MMF_RefreshUnitPageText(unit)
        end, true)
    local hpTextDefault = defaults[prefix .. "HPTextSize"]
        or db.hpTextSize
        or defaults.hpTextSize
        or 13
    CreateSlider(parent, "HP Size", rightX, -70, columnWidth, prefix .. "HPTextSize", 8, 20, 1,
        hpTextDefault, function(value)
            if MMF_UpdateHPTextSize then
                MMF_UpdateHPTextSize(value, unit)
            end
            MMF_RefreshUnitPageText(unit)
        end, true)

    MMF_CreateUnitPageSectionTitle(parent, "FRAME TEXT FORMAT", rightX, -(textFormatStart + 12), "frame")
    local formatControls = {
        { label = "HP Value", suffix = "ShowHPValueText", legacy = "showHPValueText", default = true, y = -(textFormatStart + 42) },
        { label = "HP Short Value", suffix = "HPTextUseShortValue", legacy = "hpTextUseShortValue", default = true, y = -(textFormatStart + 70) },
        { label = "HP Percent", suffix = "ShowHPPercentText", legacy = "showHPPercentText", default = false, y = -(textFormatStart + 98) },
        { label = "Player Name Class", suffix = "ColorPlayerNameTextByClass", legacy = "colorPlayerNameTextByClass", default = false, y = -(textFormatStart + 126) },
        { label = "NPC Name Reaction", suffix = "ColorNPCNameTextByReaction", legacy = "colorNPCNameTextByReaction", default = false, y = -(textFormatStart + 154) },
    }
    for _, control in ipairs(formatControls) do
        local key = prefix .. control.suffix
        local initialValue = db[key]
        if initialValue == nil then
            initialValue = db[control.legacy]
        end
        if initialValue == nil then
            initialValue = DefaultValue(key, control.default)
        end
        local checkbox = CreateCheckbox(parent, control.label, rightX, control.y, key, initialValue == true, function()
            MMF_RefreshUnitPageText(unit)
        end)
        if checkbox and checkbox.checkbox then
            checkbox.checkbox:SetChecked(initialValue == true)
            if checkbox.checkbox.check then
                checkbox.checkbox.check:SetShown(initialValue == true)
            end
        end
    end

    -- Visibility
    MMF_CreateUnitPageSectionTitle(parent, "FRAME VISIBILITY", leftX, -(visibilityStart + 12), "frame")
    CreateCheckbox(parent, "Hide Name Text", leftX, -(visibilityStart + 42), prefix .. "HideNameText", false, function()
        MMF_RefreshUnitPageText(unit)
    end)
    CreateCheckbox(parent, "Hide HP Text", leftX, -(visibilityStart + 70), prefix .. "HideHPText", false, function()
        MMF_RefreshUnitPageText(unit)
    end)
    if hideFrameKey then
        CreateCheckbox(parent, "Hide Frame", leftX, -(visibilityStart + 98), hideFrameKey, false, UpdateFrameVisibility)
    end

    -- Text Position.  Name and HP anchoring are independent, so keep them in
    -- parallel columns instead of leaving the right half of the editor empty.
    MMF_CreateUnitPageSectionTitle(parent, "NAME TEXT POSITION", leftX, -(positionStart + 12), "frame")
    MMF_CreateUnitPageSectionTitle(parent, "HP TEXT POSITION", rightX, -(positionStart + 12), "frame")
    local anchorOptions = {
        { value = "TOPLEFT", label = "Top Left" }, { value = "TOP", label = "Top" }, { value = "TOPRIGHT", label = "Top Right" },
        { value = "LEFT", label = "Left" }, { value = "CENTER", label = "Center" }, { value = "RIGHT", label = "Right" },
        { value = "BOTTOMLEFT", label = "Bottom Left" }, { value = "BOTTOM", label = "Bottom" }, { value = "BOTTOMRIGHT", label = "Bottom Right" },
    }
    local nameAnchorEnabledKey = prefix .. "NameTextAnchorEnabled"
    local nameAnchorPointKey = prefix .. "NameTextAnchorPoint"
    local nameAnchorCheckbox = CreateCheckbox(parent, "Anchor Name Inside", leftX, -(positionStart + 42), nameAnchorEnabledKey, false, function()
        MMF_ApplyUnitPageNameAnchor(unit)
        MMF_RefreshUnitPageTextPositions()
    end)
    local nameAnchorDropdown = MMF_CreateMinimalDropdown(parent, popup, {
        accentColor = accentColor, settingKey = nameAnchorPointKey, x = leftX, y = -(positionStart + 70), width = columnWidth,
        labelWidth = 74, buttonOffset = 78, buttonWidth = columnWidth - 78, visibleRows = #anchorOptions,
        label = "Name Anchor", options = anchorOptions,
        getValue = function()
            return MMF_GetNameTextAnchorPoint and MMF_GetNameTextAnchorPoint(unit) or "TOP"
        end,
        onSelect = function(value)
            MattMinimalFramesDB[nameAnchorEnabledKey] = true
            MattMinimalFramesDB[nameAnchorPointKey] = value
            if nameAnchorCheckbox and nameAnchorCheckbox.checkbox then
                nameAnchorCheckbox.checkbox:SetChecked(true)
                if nameAnchorCheckbox.checkbox.check then
                    nameAnchorCheckbox.checkbox.check:Show()
                end
            end
            MMF_ApplyUnitPageNameAnchor(unit)
            MMF_RefreshUnitPageTextPositions()
        end,
    })
    dropdownLists[unit .. "NameAnchorList"] = nameAnchorDropdown.list
    CreateSlider(parent, "Name X Offset", leftX, -(positionStart + 98), columnWidth, prefix .. "NameTextXOffset", -60, 60, 1,
        DefaultValue(prefix .. "NameTextXOffset", 0), MMF_RefreshUnitPageTextPositions, true)
    CreateSlider(parent, "Name Y Offset", leftX, -(positionStart + 126), columnWidth, prefix .. "NameTextYOffset", -60, 60, 1,
        DefaultValue(prefix .. "NameTextYOffset", 0), MMF_RefreshUnitPageTextPositions, true)

    local hpAnchorEnabledKey = prefix .. "HPTextAnchorEnabled"
    local hpAnchorPointKey = prefix .. "HPTextAnchorPoint"
    local hpAnchorCheckbox = CreateCheckbox(parent, "Anchor HP Inside", rightX, -(positionStart + 42), hpAnchorEnabledKey, false, MMF_RefreshUnitPageTextPositions)
    local hpAnchorDropdown = MMF_CreateMinimalDropdown(parent, popup, {
        accentColor = accentColor, settingKey = hpAnchorPointKey, x = rightX, y = -(positionStart + 70), width = columnWidth,
        labelWidth = 74, buttonOffset = 78, buttonWidth = columnWidth - 78, visibleRows = #anchorOptions,
        label = "HP Anchor", options = anchorOptions,
        getValue = function()
            return MMF_GetHPTextAnchorPoint and MMF_GetHPTextAnchorPoint(unit) or "BOTTOM"
        end,
        onSelect = function(value)
            MattMinimalFramesDB[hpAnchorEnabledKey] = true
            MattMinimalFramesDB[hpAnchorPointKey] = value
            if hpAnchorCheckbox and hpAnchorCheckbox.checkbox then
                hpAnchorCheckbox.checkbox:SetChecked(true)
                if hpAnchorCheckbox.checkbox.check then
                    hpAnchorCheckbox.checkbox.check:Show()
                end
            end
            MMF_RefreshUnitPageTextPositions()
        end,
    })
    dropdownLists[unit .. "HPAnchorList"] = hpAnchorDropdown.list
    CreateSlider(parent, "HP X Offset", rightX, -(positionStart + 98), columnWidth, prefix .. "HPTextXOffset", -500, 500, 1,
        DefaultValue(prefix .. "HPTextXOffset", 0), MMF_RefreshUnitPageTextPositions, true)
    CreateSlider(parent, "HP Y Offset", rightX, -(positionStart + 126), columnWidth, prefix .. "HPTextYOffset", -500, 500, 1,
        DefaultValue(prefix .. "HPTextYOffset", 0), MMF_RefreshUnitPageTextPositions, true)

    local function BuildEmbeddedSection(yOffset, height, builder, config)
        if type(builder) ~= "function" then
            return
        end
        local section = CreateFrame("Frame", nil, parent)
        section:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
        section:SetSize(740, height)
        config = config or {}
        if config.cardTone then
            MMF_CreateUnitFramesSectionCard(section, 4, 0, 732, height, config.cardTone)
        end
        config.parent = section
        config.popup = popup
        config.accentColor = accentColor
        config.createMinimalCheckbox = CreateCheckbox
        config.createMinimalSlider = CreateSlider
        config.dropdownLists = dropdownLists
        builder(config)
    end

    local compat = _G.MMF_Compat or {}
    local _, playerClass = UnitClass("player")
    local playerHasTBCComboPoints = compat.IsTBC and (playerClass == "ROGUE" or playerClass == "DRUID")
    local playerIsDruid = playerClass == "DRUID"
    local sectionCursor = embeddedStart

    local function AddSection(height, builder, config)
        BuildEmbeddedSection(-sectionCursor, height, builder, config)
        sectionCursor = sectionCursor + height + cardGap
    end

    if unit == "player" or unit == "target" then
        local powerHeight = unit == "target" and 240
            or playerHasTBCComboPoints and 408
            or playerIsDruid and 280
            or 252
        AddSection(powerHeight, MMF_BuildUnitFramesPowerSection, {
            unit = unit,
            createMinimalColorPicker = MMF_CreateMinimalColorPicker,
            cardTone = "power",
        })
    end

    if unit == "player" then
        AddSection(422, MMF_BuildAurasPowerPlayerAurasSection, {
            auraColX = 12,
            auraColWidth = 346,
            auraRightColX = 382,
            auraRightColWidth = 346,
            cardTone = "aura",
        })
    elseif unit == "target" then
        AddSection(354, MMF_BuildAurasPowerTargetAurasSection, {
            auraColX = 12,
            auraColWidth = 346,
            auraRightColX = 382,
            auraRightColWidth = 346,
            isTBCComboClass = false,
            showComboPointBar = false,
            showSharedTextScale = false,
            cardTone = "aura",
        })
        AddSection(82, MMF_BuildAurasPowerFiltersSection, { auraColX = 12, cardTone = "aura" })
    elseif unit == "focus" then
        AddSection(354, MMF_BuildAurasPowerFocusAurasSection, {
            auraColX = 12,
            auraColWidth = 346,
            auraRightColX = 382,
            auraRightColWidth = 346,
            showSharedTextScale = false,
            cardTone = "aura",
        })
    end

    if unit == "player" then
        AddSection(164, MMF_BuildUnitFramesCastBarSection, { unit = unit, cardTone = "cast" })
        AddSection(140, MMF_BuildUnitFramesIconsSection, {
            fixedUnit = "player", rightSection = {}, normalizeSelectionValue = function(value, fallback) return type(value) == "string" and value or fallback end,
            getCurrentPlayerIconModeValue = ctx.getCurrentPlayerIconModeValue or function() return "off" end,
            getCurrentTargetIconModeValue = ctx.getCurrentTargetIconModeValue or function() return "off" end,
            setUpdatePlayerIconModeButtonText = function() end,
            rightColX = 12, rightColWidth = 346, rightLabelWidth = 92, rightButtonOffset = 98, rightButtonWidth = 248,
            rightStackYOffset = 442, rightFrameOptionsYShift = 0, iconResetButtonWidth = 346, iconResetButtonGap = 0,
            cardTone = "icon",
        })
        AddSection(168, MMF_BuildUnitFramesAppearanceSection, { unit = unit, cardTone = "appearance" })
    elseif unit == "target" then
        AddSection(164, MMF_BuildUnitFramesCastBarSection, { unit = unit, cardTone = "cast" })
        AddSection(140, MMF_BuildUnitFramesIconsSection, {
            fixedUnit = "target", rightSection = {}, normalizeSelectionValue = function(value, fallback) return type(value) == "string" and value or fallback end,
            getCurrentPlayerIconModeValue = ctx.getCurrentPlayerIconModeValue or function() return "off" end,
            getCurrentTargetIconModeValue = ctx.getCurrentTargetIconModeValue or function() return "off" end,
            rightColX = 12, rightColWidth = 346, rightLabelWidth = 92, rightButtonOffset = 98, rightButtonWidth = 248,
            rightStackYOffset = 442, rightFrameOptionsYShift = 0, iconResetButtonWidth = 346, iconResetButtonGap = 0,
            cardTone = "icon",
        })
        AddSection(168, MMF_BuildUnitFramesAppearanceSection, { unit = unit, cardTone = "appearance" })
    elseif unit == "focus" then
        AddSection(164, MMF_BuildUnitFramesCastBarSection, { unit = unit, cardTone = "cast" })
        AddSection(168, MMF_BuildUnitFramesAppearanceSection, { unit = unit, cardTone = "appearance" })
    elseif unit == "boss" then
        AddSection(140, MMF_BuildUnitFramesCastBarSection, { unit = unit, cardTone = "cast" })
        AddSection(168, MMF_BuildUnitFramesAppearanceSection, { unit = unit, cardTone = "appearance" })
    else
        AddSection(168, MMF_BuildUnitFramesAppearanceSection, { unit = unit, cardTone = "appearance" })
    end
end
