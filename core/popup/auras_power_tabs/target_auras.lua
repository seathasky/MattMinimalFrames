function MMF_BuildAurasPowerTargetAurasSection(ctx)
    local root = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local CreateMinimalSlider = ctx.createMinimalSlider
    local AURA_COL_X = ctx.auraColX
    local AURA_COL_WIDTH = ctx.auraColWidth
    local isTBCComboClass = ctx.isTBCComboClass
    local dropdownLists = ctx.dropdownLists or {}

    local aurasTitle = root:CreateFontString(nil, "OVERLAY")
    aurasTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    aurasTitle:SetPoint("TOPLEFT", AURA_COL_X, -12)
    aurasTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    aurasTitle:SetText("TARGET AURA POSITION")

    local BUFF_TOGGLE_Y = -32
    local DEBUFF_TOGGLE_Y = -56
    local AURA_TYPE_Y = -84

    local function ApplyCompactCheckboxLayout(checkboxControl, textWidth)
        if not checkboxControl or not checkboxControl.resetButton or not checkboxControl.checkbox or not checkboxControl.labelText then
            return
        end
        local reset = checkboxControl.resetButton
        local cb = checkboxControl.checkbox
        local text = checkboxControl.labelText

        text:ClearAllPoints()
        text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        text:SetWidth(textWidth or 112)
        text:SetJustifyH("LEFT")

        reset:ClearAllPoints()
        reset:SetPoint("LEFT", text, "RIGHT", 8, 0)
    end

    local function RefreshAuraAnchoring()
        if MMF_UpdateAuraLayout then
            MMF_UpdateAuraLayout()
        else
            if MMF_UpdateTargetAuras then
                MMF_UpdateTargetAuras()
            end
            if MMF_UpdatePlayerAuras then
                MMF_UpdatePlayerAuras()
            end
        end
    end

    local function SetAnchorCheckboxEnabled(container, enabled)
        if not container then return end
        container:SetAlpha(enabled and 1 or 0.45)
        if container.labelText then
            container.labelText:SetAlpha(enabled and 1 or 0.7)
        end
        if container.checkbox then
            container.checkbox:SetEnabled(enabled)
            container.checkbox:EnableMouse(enabled)
            container.checkbox:SetAlpha(enabled and 1 or 0.55)
            if container.checkbox.check then
                container.checkbox.check:SetAlpha(enabled and 1 or 0.35)
            end
        end
        if container.resetButton then
            container.resetButton:SetEnabled(enabled)
            container.resetButton:EnableMouse(enabled)
            container.resetButton:SetAlpha(enabled and 1 or 0.45)
        end
    end

    local RefreshBlizzardAnchorState = function() end

    local buffsCheckbox = CreateMinimalCheckbox(root, "Buffs", AURA_COL_X, BUFF_TOGGLE_Y, "showBuffs", true, function()
        RefreshBlizzardAnchorState()
        if MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end
    end)

    local debuffsCheckbox = CreateMinimalCheckbox(root, "Debuffs", AURA_COL_X, DEBUFF_TOGGLE_Y, "showDebuffs", true, function()
        RefreshBlizzardAnchorState()
        if MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end
    end)

    local blizzardAnchorCheckbox = CreateMinimalCheckbox(root, "Blizzard Anchor", AURA_COL_X + 136, BUFF_TOGGLE_Y, "targetUseBlizzardAuraAnchoring", false, function()
        RefreshAuraAnchoring()
    end)

    ApplyCompactCheckboxLayout(buffsCheckbox, 36)
    ApplyCompactCheckboxLayout(debuffsCheckbox, 46)
    ApplyCompactCheckboxLayout(blizzardAnchorCheckbox, 92)

    local blizzardAnchorHint = root:CreateFontString(nil, "OVERLAY")
    blizzardAnchorHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    if blizzardAnchorCheckbox and blizzardAnchorCheckbox.labelText then
        blizzardAnchorHint:SetPoint("TOPLEFT", blizzardAnchorCheckbox.labelText, "BOTTOMLEFT", 0, -2)
    else
        blizzardAnchorHint:SetPoint("TOPLEFT", blizzardAnchorCheckbox, "BOTTOMLEFT", 20, -2)
    end
    blizzardAnchorHint:SetWidth(170)
    blizzardAnchorHint:SetJustifyH("LEFT")
    blizzardAnchorHint:SetTextColor(0.72, 0.72, 0.76)
    blizzardAnchorHint:SetText("Buff/Debuffs must be enabled")
    blizzardAnchorHint:Hide()

    RefreshBlizzardAnchorState = function()
        local buffsEnabled = buffsCheckbox and buffsCheckbox.checkbox and buffsCheckbox.checkbox:GetChecked() == true
        local debuffsEnabled = debuffsCheckbox and debuffsCheckbox.checkbox and debuffsCheckbox.checkbox:GetChecked() == true
        local allowAnchor = buffsEnabled and debuffsEnabled

        SetAnchorCheckboxEnabled(blizzardAnchorCheckbox, allowAnchor)
        if blizzardAnchorHint then
            blizzardAnchorHint:SetShown(not allowAnchor)
        end
        if not allowAnchor and blizzardAnchorCheckbox and blizzardAnchorCheckbox.checkbox and blizzardAnchorCheckbox.checkbox:GetChecked() then
            blizzardAnchorCheckbox.checkbox:SetChecked(false)
            if blizzardAnchorCheckbox.checkbox.check then
                blizzardAnchorCheckbox.checkbox.check:SetShown(false)
            end
            if type(MattMinimalFramesDB) ~= "table" then
                MattMinimalFramesDB = {}
            end
            MattMinimalFramesDB.targetUseBlizzardAuraAnchoring = false
            if blizzardAnchorCheckbox.RefreshResetVisibility then
                blizzardAnchorCheckbox:RefreshResetVisibility()
            end
            RefreshAuraAnchoring()
        end
    end

    RefreshBlizzardAnchorState()

    local auraTypeOptions = {
        { value = "buff", label = "Target Buffs" },
        { value = "debuff", label = "Target Debuffs" },
    }
    MattMinimalFramesDB.auraOffsetType = MattMinimalFramesDB.auraOffsetType or "buff"
    if MattMinimalFramesDB.auraOffsetType ~= "buff" and MattMinimalFramesDB.auraOffsetType ~= "debuff" then
        MattMinimalFramesDB.auraOffsetType = "buff"
    end

    local SyncAuraOffsetSliders = function() end

    local auraTypeDropdown = MMF_CreateMinimalDropdown(root, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "auraOffsetType",
        x = AURA_COL_X,
        y = AURA_TYPE_Y,
        width = AURA_COL_WIDTH,
        labelWidth = 74,
        buttonOffset = 78,
        buttonWidth = AURA_COL_WIDTH - 78,
        visibleRows = #auraTypeOptions,
        label = "Aura Type",
        options = auraTypeOptions,
        getValue = function()
            return MattMinimalFramesDB.auraOffsetType
        end,
        onSelect = function(value)
            MattMinimalFramesDB.auraOffsetType = value
            SyncAuraOffsetSliders()
        end,
    })
    dropdownLists.auraTypeList = auraTypeDropdown.list

    local auraDirectionOptions = {
        { value = "left_down", label = "Left + Down" },
        { value = "left_up", label = "Left + Up" },
        { value = "right_down", label = "Right + Down" },
        { value = "right_up", label = "Right + Up" },
        { value = "down_left", label = "Down + Left" },
        { value = "down_right", label = "Down + Right" },
        { value = "up_left", label = "Up + Left" },
        { value = "up_right", label = "Up + Right" },
    }

    local function NormalizeAuraDirection(value, fallback)
        if type(value) ~= "string" then
            return fallback
        end
        local normalized = value:match("^%s*(.-)%s*$")
        if not normalized or normalized == "" then
            return fallback
        end
        for _, option in ipairs(auraDirectionOptions) do
            if option.value == normalized then
                return normalized
            end
        end
        return fallback
    end

    MattMinimalFramesDB.buffAuraDirection = NormalizeAuraDirection(MattMinimalFramesDB.buffAuraDirection, "left_down")
    MattMinimalFramesDB.debuffAuraDirection = NormalizeAuraDirection(MattMinimalFramesDB.debuffAuraDirection, "right_up")

    local function RefreshAuraDirection()
        if MMF_UpdateAuraLayout then
            MMF_UpdateAuraLayout()
        elseif MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end
    end

    local RefreshPositionResetButtons = function() end

    local buffDirectionDropdown = MMF_CreateMinimalDropdown(root, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "buffAuraDirection",
        x = AURA_COL_X,
        y = -164,
        width = AURA_COL_WIDTH,
        labelWidth = 90,
        buttonOffset = 94,
        buttonWidth = AURA_COL_WIDTH - 94,
        visibleRows = #auraDirectionOptions,
        label = "Buff Direction",
        options = auraDirectionOptions,
        getValue = function()
            return NormalizeAuraDirection(MattMinimalFramesDB.buffAuraDirection, "left_down")
        end,
        onSelect = function(value)
            MattMinimalFramesDB.buffAuraDirection = NormalizeAuraDirection(value, "left_down")
            RefreshAuraDirection()
            RefreshPositionResetButtons()
        end,
    })
    dropdownLists.buffAuraDirectionList = buffDirectionDropdown.list

    local debuffDirectionDropdown = MMF_CreateMinimalDropdown(root, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "debuffAuraDirection",
        x = AURA_COL_X,
        y = -192,
        width = AURA_COL_WIDTH,
        labelWidth = 90,
        buttonOffset = 94,
        buttonWidth = AURA_COL_WIDTH - 94,
        visibleRows = #auraDirectionOptions,
        label = "Debuff Direction",
        options = auraDirectionOptions,
        getValue = function()
            return NormalizeAuraDirection(MattMinimalFramesDB.debuffAuraDirection, "right_up")
        end,
        onSelect = function(value)
            MattMinimalFramesDB.debuffAuraDirection = NormalizeAuraDirection(value, "right_up")
            RefreshAuraDirection()
            RefreshPositionResetButtons()
        end,
    })
    dropdownLists.debuffAuraDirectionList = debuffDirectionDropdown.list

    local directionHelpText = root:CreateFontString(nil, "OVERLAY")
    directionHelpText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    directionHelpText:SetPoint("TOPLEFT", AURA_COL_X, -222)
    directionHelpText:SetWidth(AURA_COL_WIDTH)
    directionHelpText:SetJustifyH("LEFT")
    directionHelpText:SetWordWrap(true)
    directionHelpText:SetTextColor(0.6, 0.66, 0.7)
    directionHelpText:SetText("Growth order: first word is horizontal, second is vertical.")

    local function GetAuraOffsetKeys()
        if MattMinimalFramesDB.auraOffsetType == "debuff" then
            return "debuffXOffset", "debuffYOffset", 3, 27
        end
        return "buffXOffset", "buffYOffset", -2, -6
    end

    local auraXSlider = CreateMinimalSlider(root, "X Offset", AURA_COL_X, -108, AURA_COL_WIDTH, "__tempAuraOffsetX", -200, 200, 1, -2, function(value)
        local xKey, yKey = GetAuraOffsetKeys()
        MattMinimalFramesDB[xKey] = value
        if xKey == "debuffXOffset" then
            if MMF_UpdateDebuffPosition then
                MMF_UpdateDebuffPosition(value, MattMinimalFramesDB[yKey] or 27)
            end
        else
            if MMF_UpdateBuffPosition then
                MMF_UpdateBuffPosition(value, MattMinimalFramesDB[yKey] or -6)
            end
        end
        RefreshPositionResetButtons()
    end, true)

    local auraYSlider = CreateMinimalSlider(root, "Y Offset", AURA_COL_X, -132, AURA_COL_WIDTH, "__tempAuraOffsetY", -200, 200, 1, -6, function(value)
        local xKey, yKey = GetAuraOffsetKeys()
        MattMinimalFramesDB[yKey] = value
        if yKey == "debuffYOffset" then
            if MMF_UpdateDebuffPosition then
                MMF_UpdateDebuffPosition(MattMinimalFramesDB[xKey] or 3, value)
            end
        else
            if MMF_UpdateBuffPosition then
                MMF_UpdateBuffPosition(MattMinimalFramesDB[xKey] or -2, value)
            end
        end
        RefreshPositionResetButtons()
    end, true)

    SyncAuraOffsetSliders = function()
        local xKey, yKey, defaultX, defaultY = GetAuraOffsetKeys()
        auraXSlider.slider:SetValue(MattMinimalFramesDB[xKey] or defaultX)
        auraYSlider.slider:SetValue(MattMinimalFramesDB[yKey] or defaultY)
    end
    SyncAuraOffsetSliders()

    local LEGACY_BUFF_X = -2
    local LEGACY_BUFF_Y = -6
    local LEGACY_BUFF_DIRECTION = "left_down"
    local LEGACY_DEBUFF_X = 3
    local LEGACY_DEBUFF_Y = 27
    local LEGACY_DEBUFF_DIRECTION = "right_up"

    local buffPositionResetButton
    local debuffPositionResetButton

    local function IsPositionDefault(kind)
        local db = MattMinimalFramesDB or {}
        if kind == "debuff" then
            local x = tonumber(db.debuffXOffset) or LEGACY_DEBUFF_X
            local y = tonumber(db.debuffYOffset) or LEGACY_DEBUFF_Y
            local dir = NormalizeAuraDirection(db.debuffAuraDirection, "right_up")
            return x == LEGACY_DEBUFF_X
                and y == LEGACY_DEBUFF_Y
                and dir == NormalizeAuraDirection(LEGACY_DEBUFF_DIRECTION, "right_up")
        end
        local x = tonumber(db.buffXOffset) or LEGACY_BUFF_X
        local y = tonumber(db.buffYOffset) or LEGACY_BUFF_Y
        local dir = NormalizeAuraDirection(db.buffAuraDirection, "left_down")
        return x == LEGACY_BUFF_X
            and y == LEGACY_BUFF_Y
            and dir == NormalizeAuraDirection(LEGACY_BUFF_DIRECTION, "left_down")
    end

    RefreshPositionResetButtons = function()
        if buffPositionResetButton then
            buffPositionResetButton:SetShown(true)
        end
        if debuffPositionResetButton then
            debuffPositionResetButton:SetShown(true)
        end
    end

    local function ResetAuraPosition(kind)
        if kind == "debuff" then
            local x = LEGACY_DEBUFF_X
            local y = LEGACY_DEBUFF_Y
            local direction = LEGACY_DEBUFF_DIRECTION
            MattMinimalFramesDB.debuffXOffset = x
            MattMinimalFramesDB.debuffYOffset = y
            MattMinimalFramesDB.debuffAuraDirection = NormalizeAuraDirection(direction, "right_up")
            if MMF_UpdateDebuffPosition then
                MMF_UpdateDebuffPosition(x, y)
            end
            if debuffDirectionDropdown and debuffDirectionDropdown.SetSelectedValue then
                debuffDirectionDropdown.SetSelectedValue(MattMinimalFramesDB.debuffAuraDirection)
            end
            if MattMinimalFramesDB.auraOffsetType == "debuff" then
                SyncAuraOffsetSliders()
            end
        else
            local x = LEGACY_BUFF_X
            local y = LEGACY_BUFF_Y
            local direction = LEGACY_BUFF_DIRECTION
            MattMinimalFramesDB.buffXOffset = x
            MattMinimalFramesDB.buffYOffset = y
            MattMinimalFramesDB.buffAuraDirection = NormalizeAuraDirection(direction, "left_down")
            if MMF_UpdateBuffPosition then
                MMF_UpdateBuffPosition(x, y)
            end
            if buffDirectionDropdown and buffDirectionDropdown.SetSelectedValue then
                buffDirectionDropdown.SetSelectedValue(MattMinimalFramesDB.buffAuraDirection)
            end
            if MattMinimalFramesDB.auraOffsetType ~= "debuff" then
                SyncAuraOffsetSliders()
            end
        end
        if MMF_UpdateAuraLayout then
            MMF_UpdateAuraLayout()
        elseif MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end
        RefreshPositionResetButtons()
    end

    local resetGap = 8
    local resetButtonWidth = math.floor((AURA_COL_WIDTH - resetGap) / 2)
    local resetButtonHeight = 22
    local function CreateAuraResetButton(x, y, label, onClick)
        local button = CreateFrame("Button", nil, root, "BackdropTemplate")
        button:SetSize(resetButtonWidth, resetButtonHeight)
        button:SetPoint("TOPLEFT", x, y)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.08, 0.08, 0.1, 1)
        button:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)

        local text = button:CreateFontString(nil, "OVERLAY")
        text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        text:SetPoint("CENTER")
        text:SetTextColor(0.82, 0.82, 0.86)
        text:SetText(label)

        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.11, 0.11, 0.14, 1)
            self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
            text:SetTextColor(1, 1, 1)
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.08, 0.08, 0.1, 1)
            self:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
            text:SetTextColor(0.82, 0.82, 0.86)
        end)
        button:SetScript("OnClick", function()
            if type(onClick) == "function" then
                onClick()
            end
        end)

        return button
    end

    buffPositionResetButton = CreateAuraResetButton(AURA_COL_X, -250, "Reset Buff Position", function()
        ResetAuraPosition("buff")
    end)
    debuffPositionResetButton = CreateAuraResetButton(AURA_COL_X + resetButtonWidth + resetGap, -250, "Reset Debuff Position", function()
        ResetAuraPosition("debuff")
    end)
    RefreshPositionResetButtons()

    local divider1 = root:CreateTexture(nil, "ARTWORK")
    divider1:SetSize(AURA_COL_WIDTH, 1)
    divider1:SetPoint("TOPLEFT", AURA_COL_X, -286)
    divider1:SetColorTexture(0.12, 0.12, 0.15, 1)

    local auraTitle = root:CreateFontString(nil, "OVERLAY")
    auraTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    auraTitle:SetPoint("TOPLEFT", AURA_COL_X, -298)
    auraTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    auraTitle:SetText("TARGET AURA APPEARANCE")

    local appearanceTypeOptions = {
        { value = "buff", label = "Target Buffs" },
        { value = "debuff", label = "Target Debuffs" },
    }
    MattMinimalFramesDB.auraAppearanceType = MattMinimalFramesDB.auraAppearanceType or "buff"
    if MattMinimalFramesDB.auraAppearanceType ~= "buff" and MattMinimalFramesDB.auraAppearanceType ~= "debuff" then
        MattMinimalFramesDB.auraAppearanceType = "buff"
    end

    local SyncAuraAppearanceSliders = function() end
    local appearanceTypeDropdown = MMF_CreateMinimalDropdown(root, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "auraAppearanceType",
        x = AURA_COL_X,
        y = -322,
        width = AURA_COL_WIDTH,
        labelWidth = 112,
        buttonOffset = 116,
        buttonWidth = AURA_COL_WIDTH - 116,
        visibleRows = #appearanceTypeOptions,
        label = "Appearance Type",
        options = appearanceTypeOptions,
        getValue = function()
            return MattMinimalFramesDB.auraAppearanceType
        end,
        onSelect = function(value)
            MattMinimalFramesDB.auraAppearanceType = value
            SyncAuraAppearanceSliders()
        end,
    })
    dropdownLists.auraAppearanceTypeList = appearanceTypeDropdown.list

    local function GetAuraAppearanceKeys()
        if MattMinimalFramesDB.auraAppearanceType == "debuff" then
            return "debuffAuraIconSize", "debuffAuraIconsPerRow", "debuffAuraRows", 18, 4, 3
        end
        return "buffAuraIconSize", "buffAuraIconsPerRow", "buffAuraRows", 18, 4, 3
    end

    local function GetAppearanceDefaultValues()
        local defaults = MattMinimalFrames_Defaults or {}
        local sizeKey, perRowKey, rowsKey, defaultSize, defaultPerRow, defaultRows = GetAuraAppearanceKeys()
        return sizeKey, perRowKey, rowsKey,
            tonumber(defaults[sizeKey]) or defaultSize,
            tonumber(defaults[perRowKey]) or defaultPerRow,
            tonumber(defaults[rowsKey]) or defaultRows
    end

    local auraIconSizeSlider
    local auraIconsPerRowSlider
    local auraRowsSlider

    auraIconSizeSlider = CreateMinimalSlider(root, "Icon Size", AURA_COL_X, -346, AURA_COL_WIDTH, "__tempAuraAppearanceIconSize", 12, 40, 1, 18, function(value)
        local sizeKey = GetAuraAppearanceKeys()
        MattMinimalFramesDB[sizeKey] = math.floor((tonumber(value) or 18) + 0.5)
        if MMF_UpdateAuraLayout then
            MMF_UpdateAuraLayout()
        end
    end, true, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local sizeKey, _, _, defaultSize = GetAppearanceDefaultValues()
            local current = tonumber(db[sizeKey]) or defaultSize
            return current == defaultSize
        end,
        onReset = function()
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            local sizeKey, _, _, defaultSize = GetAppearanceDefaultValues()
            MattMinimalFramesDB[sizeKey] = defaultSize
            if auraIconSizeSlider and auraIconSizeSlider.slider then
                auraIconSizeSlider.slider:SetValue(defaultSize)
            end
            if MMF_UpdateAuraLayout then
                MMF_UpdateAuraLayout()
            end
        end,
    })

    auraIconsPerRowSlider = CreateMinimalSlider(root, "Icons Per Row", AURA_COL_X, -370, AURA_COL_WIDTH, "__tempAuraAppearancePerRow", 1, 16, 1, 4, function(value)
        local _, perRowKey = GetAuraAppearanceKeys()
        MattMinimalFramesDB[perRowKey] = math.floor((tonumber(value) or 4) + 0.5)
        if MMF_UpdateAuraLayout then
            MMF_UpdateAuraLayout()
        end
    end, true, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local _, perRowKey, _, _, defaultPerRow = GetAppearanceDefaultValues()
            local current = tonumber(db[perRowKey]) or defaultPerRow
            return current == defaultPerRow
        end,
        onReset = function()
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            local _, perRowKey, _, _, defaultPerRow = GetAppearanceDefaultValues()
            MattMinimalFramesDB[perRowKey] = defaultPerRow
            if auraIconsPerRowSlider and auraIconsPerRowSlider.slider then
                auraIconsPerRowSlider.slider:SetValue(defaultPerRow)
            end
            if MMF_UpdateAuraLayout then
                MMF_UpdateAuraLayout()
            end
        end,
    })

    auraRowsSlider = CreateMinimalSlider(root, "Rows", AURA_COL_X, -394, AURA_COL_WIDTH, "__tempAuraAppearanceRows", 1, 16, 1, 3, function(value)
        local _, _, rowsKey = GetAuraAppearanceKeys()
        MattMinimalFramesDB[rowsKey] = math.floor((tonumber(value) or 3) + 0.5)
        if MMF_UpdateAuraLayout then
            MMF_UpdateAuraLayout()
        end
    end, true, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local _, _, rowsKey, _, _, defaultRows = GetAppearanceDefaultValues()
            local current = tonumber(db[rowsKey]) or defaultRows
            return current == defaultRows
        end,
        onReset = function()
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            local _, _, rowsKey, _, _, defaultRows = GetAppearanceDefaultValues()
            MattMinimalFramesDB[rowsKey] = defaultRows
            if auraRowsSlider and auraRowsSlider.slider then
                auraRowsSlider.slider:SetValue(defaultRows)
            end
            if MMF_UpdateAuraLayout then
                MMF_UpdateAuraLayout()
            end
        end,
    })

    SyncAuraAppearanceSliders = function()
        local sizeKey, perRowKey, rowsKey, defaultSize, defaultPerRow, defaultRows = GetAuraAppearanceKeys()
        auraIconSizeSlider.slider:SetValue(MattMinimalFramesDB[sizeKey] or MattMinimalFramesDB.auraIconSize or defaultSize)
        auraIconsPerRowSlider.slider:SetValue(MattMinimalFramesDB[perRowKey] or MattMinimalFramesDB.auraIconsPerRow or defaultPerRow)
        auraRowsSlider.slider:SetValue(MattMinimalFramesDB[rowsKey] or MattMinimalFramesDB.auraRows or defaultRows)
        if auraIconSizeSlider.RefreshResetVisibility then
            auraIconSizeSlider:RefreshResetVisibility()
        end
        if auraIconsPerRowSlider.RefreshResetVisibility then
            auraIconsPerRowSlider:RefreshResetVisibility()
        end
        if auraRowsSlider.RefreshResetVisibility then
            auraRowsSlider:RefreshResetVisibility()
        end
    end
    SyncAuraAppearanceSliders()

    CreateMinimalSlider(root, "Stack Text", AURA_COL_X, -418, AURA_COL_WIDTH, "auraTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateAuraTextScale then
            MMF_UpdateAuraTextScale(value)
        end
    end, false)

    CreateMinimalSlider(root, "Timer Text", AURA_COL_X, -438, AURA_COL_WIDTH, "timerTextScale", 0.5, 2.0, 0.1, 1.0, function(value)
        if MMF_UpdateTimerTextScale then
            MMF_UpdateTimerTextScale(value)
        end
    end, false)

    local divider4 = root:CreateTexture(nil, "ARTWORK")
    divider4:SetSize(AURA_COL_WIDTH, 1)
    divider4:SetPoint("TOPLEFT", AURA_COL_X, -470)
    divider4:SetColorTexture(0.12, 0.12, 0.15, 1)

    if isTBCComboClass then
        local comboDivider = root:CreateTexture(nil, "ARTWORK")
        comboDivider:SetSize(AURA_COL_WIDTH, 1)
        comboDivider:SetPoint("TOPLEFT", AURA_COL_X, -576)
        comboDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

        local comboTitle = root:CreateFontString(nil, "OVERLAY")
        comboTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        comboTitle:SetPoint("TOPLEFT", AURA_COL_X, -588)
        comboTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
        comboTitle:SetText("COMBO POINTS")

        CreateMinimalCheckbox(root, "Enable Combo Point Bar", AURA_COL_X, -608, "showComboPointBar", true, function(checked)
            if checked then
                if MMF_InitializeClassResources then
                    MMF_InitializeClassResources()
                end
            else
                if _G.MMF_ComboPointBar then
                    _G.MMF_ComboPointBar:Hide()
                end
            end
        end)

        CreateMinimalSlider(root, "Point Width", AURA_COL_X, -632, AURA_COL_WIDTH, "comboPointBarWidth", 6, 80, 1, 30, function()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout("comboPointBar")
            end
        end, true)

        CreateMinimalSlider(root, "Point Height", AURA_COL_X, -656, AURA_COL_WIDTH, "comboPointBarHeight", 4, 30, 1, 10, function()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout("comboPointBar")
            end
        end, true)
    end

    MattMinimalFramesDB.__tempAuraOffsetX = nil
    MattMinimalFramesDB.__tempAuraOffsetY = nil
    MattMinimalFramesDB.__tempAuraAppearanceIconSize = nil
    MattMinimalFramesDB.__tempAuraAppearancePerRow = nil
    MattMinimalFramesDB.__tempAuraAppearanceRows = nil
end
