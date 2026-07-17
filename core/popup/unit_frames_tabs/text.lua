function MMF_BuildUnitFramesTextSection(ctx)
    local unitFramesCol = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local CreateMinimalSlider = ctx.createMinimalSlider
    local dropdownLists = ctx.dropdownLists
    local RefreshPredictionVisuals = ctx.refreshPredictionVisuals or function() end

    local LEFT_COL_X = ctx.leftColX
    local LEFT_COL_WIDTH = ctx.leftColWidth
    local LEFT_LABEL_WIDTH = ctx.leftLabelWidth
    local LEFT_BUTTON_OFFSET = ctx.leftButtonOffset
    local LEFT_BUTTON_WIDTH = ctx.leftButtonWidth

    local textFormatDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    textFormatDivider:SetSize(LEFT_COL_WIDTH, 1)
    textFormatDivider:SetPoint("TOPLEFT", LEFT_COL_X, -286)
    textFormatDivider:SetColorTexture(0.42, 0.42, 0.46, 1)

    local textFormatTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    textFormatTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    textFormatTitle:SetPoint("TOPLEFT", LEFT_COL_X, -298)
    textFormatTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    textFormatTitle:SetText("TEXT FORMAT")

    local textFormatSubtext = unitFramesCol:CreateFontString(nil, "OVERLAY")
    textFormatSubtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    textFormatSubtext:SetPoint("TOPLEFT", LEFT_COL_X, -318)
    textFormatSubtext:SetTextColor(0.65, 0.65, 0.7)
    textFormatSubtext:SetText("HP and name text format options")

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

    if MattMinimalFramesDB.showHPValueText == nil then
        MattMinimalFramesDB.showHPValueText = true
    end
    if MattMinimalFramesDB.showHPPercentText == nil then
        MattMinimalFramesDB.showHPPercentText = false
    end
    if MattMinimalFramesDB.hpTextUseShortValue == nil then
        MattMinimalFramesDB.hpTextUseShortValue = true
    end
    if MattMinimalFramesDB.colorPlayerNameTextByClass == nil then
        MattMinimalFramesDB.colorPlayerNameTextByClass = false
    end
    if MattMinimalFramesDB.colorNPCNameTextByReaction == nil then
        MattMinimalFramesDB.colorNPCNameTextByReaction = false
    end
    if MattMinimalFramesDB.showNameLevel == nil then
        MattMinimalFramesDB.showNameLevel = false
    end
    MattMinimalFramesDB.textFormatUnit = MattMinimalFramesDB.textFormatUnit or "player"

    local textFormatUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
        { value = "boss", label = "Boss" },
    }

    local function IsValidTextFormatUnit(value)
        for _, option in ipairs(textFormatUnitOptions) do
            if option.value == value then
                return true
            end
        end
        return false
    end

    if not IsValidTextFormatUnit(MattMinimalFramesDB.textFormatUnit) then
        MattMinimalFramesDB.textFormatUnit = "player"
    end

    local function GetTextFormatPrefix(unit)
        if MMF_GetTextFormatUnitPrefix then
            return MMF_GetTextFormatUnitPrefix(unit)
        end
        if unit == "targettarget" then return "tot" end
        if unit == "boss" then return "boss" end
        return unit or "player"
    end

    local function GetTextFormatKey(unit, suffix)
        return GetTextFormatPrefix(unit) .. suffix
    end

    local function GetTextFormatToggle(unit, suffix, legacyKey, defaultValue)
        local db = MattMinimalFramesDB or {}
        local perUnitValue = db[GetTextFormatKey(unit, suffix)]
        if perUnitValue ~= nil then
            return perUnitValue == true
        end
        local legacyValue = db[legacyKey]
        if legacyValue ~= nil then
            return legacyValue == true
        end
        return defaultValue == true
    end

    local function GetSharedNameLevelToggle(defaultValue)
        return GetTextFormatToggle("player", "ShowNameLevel", "showNameLevel", defaultValue)
            or GetTextFormatToggle("target", "ShowNameLevel", "showNameLevel", defaultValue)
    end

    local function ApplyTextFormatForUnit(unit)
        if unit == "boss" and MMF_UpdateUnitFrame and MMF_GetFrameForUnit then
            for i = 1, 5 do
                local frame = MMF_GetFrameForUnit("boss" .. i)
                if frame then
                    MMF_UpdateUnitFrame(frame)
                end
            end
            return
        end
        if MMF_UpdateUnitFrame and MMF_GetFrameForUnit then
            local frame = MMF_GetFrameForUnit(unit)
            if frame then
                MMF_UpdateUnitFrame(frame)
                return
            end
        end
        RequestNameTextRefresh()
    end

    local hpValueCheckbox
    local hpShortValueCheckbox
    local hpPercentCheckbox
    local nameClassCheckbox
    local nameReactionCheckbox
    local nameLevelCheckbox

    local function SetFormatCheckboxEnabled(checkboxContainer, enabled)
        if not checkboxContainer then return end
        checkboxContainer:SetAlpha(enabled and 1 or 0.45)
        if checkboxContainer.checkbox then
            checkboxContainer.checkbox:EnableMouse(enabled)
        end
        if checkboxContainer.labelText then
            if enabled then
                checkboxContainer.labelText:SetTextColor(0.9, 0.9, 0.9)
            else
                checkboxContainer.labelText:SetTextColor(0.5, 0.5, 0.55)
            end
        end
    end

    local function SetCheckboxVisualState(container, checked)
        if not container or not container.checkbox then return end
        container.checkbox:SetChecked(checked == true)
        if container.checkbox.check then
            container.checkbox.check:SetShown(container.checkbox:GetChecked())
        end
        if container.RefreshResetVisibility then
            container:RefreshResetVisibility()
        end
    end

    local function RefreshTextFormatCheckboxesFromDB()
        local unit = MattMinimalFramesDB.textFormatUnit or "player"
        SetCheckboxVisualState(hpValueCheckbox, GetTextFormatToggle(unit, "ShowHPValueText", "showHPValueText", true))
        SetCheckboxVisualState(hpShortValueCheckbox, GetTextFormatToggle(unit, "HPTextUseShortValue", "hpTextUseShortValue", true))
        SetCheckboxVisualState(hpPercentCheckbox, GetTextFormatToggle(unit, "ShowHPPercentText", "showHPPercentText", false))
        SetCheckboxVisualState(nameClassCheckbox, GetTextFormatToggle(unit, "ColorPlayerNameTextByClass", "colorPlayerNameTextByClass", false))
        SetCheckboxVisualState(nameReactionCheckbox, GetTextFormatToggle(unit, "ColorNPCNameTextByReaction", "colorNPCNameTextByReaction", false))
        SetCheckboxVisualState(nameLevelCheckbox, GetSharedNameLevelToggle(false))
    end

    local function RefreshHPTextFormatCheckboxStates()
        local unit = MattMinimalFramesDB.textFormatUnit or "player"
        local showValue = GetTextFormatToggle(unit, "ShowHPValueText", "showHPValueText", true)
        SetFormatCheckboxEnabled(hpShortValueCheckbox, showValue)
    end

    local function BuildTextFormatUnitOptions()
        local out = {}
        for _, option in ipairs(textFormatUnitOptions) do
            out[#out + 1] = { value = option.value, label = option.label }
        end
        return out
    end

    local textFormatUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "textFormatUnit",
        x = LEFT_COL_X,
        y = -330,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #textFormatUnitOptions,
        label = "Format Unit",
        options = BuildTextFormatUnitOptions(),
        getValue = function()
            return MattMinimalFramesDB.textFormatUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textFormatUnit = value
            RefreshTextFormatCheckboxesFromDB()
            RefreshHPTextFormatCheckboxStates()
        end,
    })
    dropdownLists.textFormatUnitList = textFormatUnitDropdown.list

    hpValueCheckbox = CreateMinimalCheckbox(unitFramesCol, "HP Text: Value", LEFT_COL_X, -366, "__tempShowHPValueText", true, function(checked)
        local unit = MattMinimalFramesDB.textFormatUnit or "player"
        MattMinimalFramesDB[GetTextFormatKey(unit, "ShowHPValueText")] = checked and true or false
        MattMinimalFramesDB.__tempShowHPValueText = nil
        RefreshHPTextFormatCheckboxStates()
        RefreshPredictionVisuals()
        ApplyTextFormatForUnit(unit)
    end, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ShowHPValueText")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.showHPValueText
            end
            return GetTextFormatToggle(unit, "ShowHPValueText", "showHPValueText", defaultValue ~= false) == (defaultValue == true)
        end,
        onReset = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ShowHPValueText")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.showHPValueText
            end
            db[key] = defaultValue == true
            db.__tempShowHPValueText = nil
            RefreshTextFormatCheckboxesFromDB()
            RefreshHPTextFormatCheckboxStates()
            RefreshPredictionVisuals()
            ApplyTextFormatForUnit(unit)
        end,
    })

    hpShortValueCheckbox = CreateMinimalCheckbox(unitFramesCol, "HP Text: Short Value (K/M)", LEFT_COL_X, -390, "__tempHPTextUseShortValue", true, function(checked)
        local unit = MattMinimalFramesDB.textFormatUnit or "player"
        MattMinimalFramesDB[GetTextFormatKey(unit, "HPTextUseShortValue")] = checked and true or false
        MattMinimalFramesDB.__tempHPTextUseShortValue = nil
        RefreshPredictionVisuals()
        ApplyTextFormatForUnit(unit)
    end, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "HPTextUseShortValue")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.hpTextUseShortValue
            end
            return GetTextFormatToggle(unit, "HPTextUseShortValue", "hpTextUseShortValue", defaultValue ~= false) == (defaultValue == true)
        end,
        onReset = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "HPTextUseShortValue")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.hpTextUseShortValue
            end
            db[key] = defaultValue == true
            db.__tempHPTextUseShortValue = nil
            RefreshTextFormatCheckboxesFromDB()
            RefreshPredictionVisuals()
            ApplyTextFormatForUnit(unit)
        end,
    })

    hpPercentCheckbox = CreateMinimalCheckbox(unitFramesCol, "HP Text: %", LEFT_COL_X, -414, "__tempShowHPPercentText", false, function(checked)
        local unit = MattMinimalFramesDB.textFormatUnit or "player"
        MattMinimalFramesDB[GetTextFormatKey(unit, "ShowHPPercentText")] = checked and true or false
        MattMinimalFramesDB.__tempShowHPPercentText = nil
        RefreshPredictionVisuals()
        ApplyTextFormatForUnit(unit)
    end, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ShowHPPercentText")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.showHPPercentText
            end
            return GetTextFormatToggle(unit, "ShowHPPercentText", "showHPPercentText", defaultValue == true) == (defaultValue == true)
        end,
        onReset = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ShowHPPercentText")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.showHPPercentText
            end
            db[key] = defaultValue == true
            db.__tempShowHPPercentText = nil
            RefreshTextFormatCheckboxesFromDB()
            RefreshPredictionVisuals()
            ApplyTextFormatForUnit(unit)
        end,
    })

    nameClassCheckbox = CreateMinimalCheckbox(unitFramesCol, "Name Text: Player Class", LEFT_COL_X, -438, "__tempColorPlayerNameTextByClass", false, function(checked)
        local unit = MattMinimalFramesDB.textFormatUnit or "player"
        MattMinimalFramesDB[GetTextFormatKey(unit, "ColorPlayerNameTextByClass")] = checked and true or false
        MattMinimalFramesDB.__tempColorPlayerNameTextByClass = nil
        ApplyTextFormatForUnit(unit)
    end, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ColorPlayerNameTextByClass")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.colorPlayerNameTextByClass
            end
            return GetTextFormatToggle(unit, "ColorPlayerNameTextByClass", "colorPlayerNameTextByClass", defaultValue == true) == (defaultValue == true)
        end,
        onReset = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ColorPlayerNameTextByClass")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.colorPlayerNameTextByClass
            end
            db[key] = defaultValue == true
            db.__tempColorPlayerNameTextByClass = nil
            RefreshTextFormatCheckboxesFromDB()
            ApplyTextFormatForUnit(unit)
        end,
    })

    nameReactionCheckbox = CreateMinimalCheckbox(unitFramesCol, "Name Text: NPC Reaction", LEFT_COL_X, -462, "__tempColorNPCNameTextByReaction", false, function(checked)
        local unit = MattMinimalFramesDB.textFormatUnit or "player"
        MattMinimalFramesDB[GetTextFormatKey(unit, "ColorNPCNameTextByReaction")] = checked and true or false
        MattMinimalFramesDB.__tempColorNPCNameTextByReaction = nil
        ApplyTextFormatForUnit(unit)
    end, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ColorNPCNameTextByReaction")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.colorNPCNameTextByReaction
            end
            return GetTextFormatToggle(unit, "ColorNPCNameTextByReaction", "colorNPCNameTextByReaction", defaultValue == true) == (defaultValue == true)
        end,
        onReset = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local unit = db.textFormatUnit or "player"
            local key = GetTextFormatKey(unit, "ColorNPCNameTextByReaction")
            local defaultValue = defaults[key]
            if defaultValue == nil then
                defaultValue = defaults.colorNPCNameTextByReaction
            end
            db[key] = defaultValue == true
            db.__tempColorNPCNameTextByReaction = nil
            RefreshTextFormatCheckboxesFromDB()
            ApplyTextFormatForUnit(unit)
        end,
    })

    nameLevelCheckbox = CreateMinimalCheckbox(unitFramesCol, "Name Text: Level (P/T)", LEFT_COL_X, -486, "__tempShowNameLevel", false, function(checked)
        MattMinimalFramesDB.playerShowNameLevel = checked and true or false
        MattMinimalFramesDB.targetShowNameLevel = checked and true or false
        MattMinimalFramesDB.__tempShowNameLevel = nil
        ApplyTextFormatForUnit("player")
        ApplyTextFormatForUnit("target")
    end, {
        isDefault = function()
            local defaults = MattMinimalFrames_Defaults or {}
            local playerDefault = defaults.playerShowNameLevel
            local targetDefault = defaults.targetShowNameLevel
            if playerDefault == nil then playerDefault = defaults.showNameLevel end
            if targetDefault == nil then targetDefault = defaults.showNameLevel end
            local defaultValue = playerDefault == true or targetDefault == true
            return GetSharedNameLevelToggle(defaultValue) == defaultValue
        end,
        onReset = function()
            local db = MattMinimalFramesDB or {}
            local defaults = MattMinimalFrames_Defaults or {}
            local playerDefault = defaults.playerShowNameLevel
            local targetDefault = defaults.targetShowNameLevel
            if playerDefault == nil then playerDefault = defaults.showNameLevel end
            if targetDefault == nil then targetDefault = defaults.showNameLevel end
            db.playerShowNameLevel = playerDefault == true
            db.targetShowNameLevel = targetDefault == true
            db.__tempShowNameLevel = nil
            RefreshTextFormatCheckboxesFromDB()
            ApplyTextFormatForUnit("player")
            ApplyTextFormatForUnit("target")
        end,
    })

    MattMinimalFramesDB.__tempShowHPValueText = nil
    MattMinimalFramesDB.__tempHPTextUseShortValue = nil
    MattMinimalFramesDB.__tempShowHPPercentText = nil
    MattMinimalFramesDB.__tempColorPlayerNameTextByClass = nil
    MattMinimalFramesDB.__tempColorNPCNameTextByReaction = nil
    MattMinimalFramesDB.__tempShowNameLevel = nil
    RefreshTextFormatCheckboxesFromDB()
    RefreshHPTextFormatCheckboxStates()

    local frameTextTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    frameTextTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    frameTextTitle:SetPoint("TOPLEFT", LEFT_COL_X, -104)
    frameTextTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    frameTextTitle:SetText("FRAME TEXT")

    local function GetTextSizePrefix(unit)
        if unit == nil then return "player" end
        if unit == "targettarget" then return "tot" end
        if unit == "boss" then return "boss" end
        return unit
    end

    local function IsCastBarTextUnit(unit)
        return unit == "playerCastBar" or unit == "targetCastBar" or unit == "focusCastBar"
    end

    local function GetCastBarOwnerUnit(unit)
        if unit == "playerCastBar" then
            return "player"
        end
        if unit == "focusCastBar" then
            return "focus"
        end
        return "target"
    end

    local function GetNameTextSizeForUnit(unit)
        local prefix = GetTextSizePrefix(unit)
        local key = prefix .. "NameTextSize"
        local fallback = tonumber(MattMinimalFramesDB.nameTextSize) or 12
        local value = tonumber(MattMinimalFramesDB[key])
        if not value then
            value = fallback
        end
        if value < 8 then value = 8 end
        if value > 20 then value = 20 end
        return value
    end

    local function GetNameTextSizeKeyForUnit(unit)
        return GetTextSizePrefix(unit) .. "NameTextSize"
    end

    local function GetHPTextSizeForUnit(unit)
        local prefix = GetTextSizePrefix(unit)
        local key = prefix .. "HPTextSize"
        local fallback = tonumber(MattMinimalFramesDB.hpTextSize) or 13
        local value = tonumber(MattMinimalFramesDB[key])
        if not value then
            value = fallback
        end
        if value < 8 then value = 8 end
        if value > 20 then value = 20 end
        return value
    end

    local function GetHPTextSizeKeyForUnit(unit)
        return GetTextSizePrefix(unit) .. "HPTextSize"
    end

    local function GetSpellNameTextSizeForUnit(unit)
        if not IsCastBarTextUnit(unit) then
            return 12
        end
        local key = unit .. "SpellNameTextSize"
        local ownerUnit = GetCastBarOwnerUnit(unit)
        local fallback = tonumber(MMF_GetNameTextSize and MMF_GetNameTextSize(ownerUnit)) or 12
        local value = tonumber(MattMinimalFramesDB[key])
        if not value then
            value = fallback
        end
        if value < 8 then value = 8 end
        if value > 20 then value = 20 end
        return value
    end

    local function GetSpellNameTextSizeKeyForUnit(unit)
        return unit .. "SpellNameTextSize"
    end

    local function GetCastTimeTextSizeForUnit(unit)
        if not IsCastBarTextUnit(unit) then
            return 9
        end
        local key = unit .. "CastTimeTextSize"
        local value = tonumber(MattMinimalFramesDB[key]) or 9
        if value < 8 then value = 8 end
        if value > 20 then value = 20 end
        return value
    end

    local function GetCastTimeTextSizeKeyForUnit(unit)
        return unit .. "CastTimeTextSize"
    end

    local textUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
        { value = "boss", label = "Boss" },
        { value = "playerCastBar", label = "Player Cast Bar" },
        { value = "targetCastBar", label = "Target Cast Bar" },
        { value = "focusCastBar", label = "Focus Cast Bar" },
    }

    MattMinimalFramesDB.textSizeUnit = MattMinimalFramesDB.textSizeUnit or "player"
    local frameTextUnitValid = false
    for _, option in ipairs(textUnitOptions) do
        if option.value == MattMinimalFramesDB.textSizeUnit then
            frameTextUnitValid = true
            break
        end
    end
    if not frameTextUnitValid then
        MattMinimalFramesDB.textSizeUnit = "player"
    end

    local nameTextSlider
    local hpTextSlider
    local spellNameTextSlider
    local castTimeTextSlider
    local truncateNameCheck
    local autoResizeNameCheck
    local truncateNameSlider
    local syncingFrameTextSize = false

    local function SetSliderEnabled(sliderFrame, enabled)
        if not sliderFrame then return end
        sliderFrame:SetAlpha(enabled and 1 or 0.45)
        if sliderFrame.slider then
            sliderFrame.slider:SetEnabled(enabled)
            sliderFrame.slider:EnableMouse(enabled)
        end
        if sliderFrame.valueText then
            sliderFrame.valueText:SetEnabled(enabled)
            sliderFrame.valueText:EnableMouse(enabled)
        end
    end

    local function UpdateFrameTextModeVisibility()
        local unit = MattMinimalFramesDB.textSizeUnit or "player"
        local isCastBarMode = IsCastBarTextUnit(unit)
        SetSliderEnabled(nameTextSlider, not isCastBarMode)
        SetSliderEnabled(hpTextSlider, not isCastBarMode)
        if spellNameTextSlider then
            spellNameTextSlider:SetShown(isCastBarMode)
        end
        if castTimeTextSlider then
            castTimeTextSlider:SetShown(isCastBarMode)
        end
        if truncateNameCheck then
            truncateNameCheck:SetShown(not isCastBarMode)
        end
        if truncateNameSlider then
            truncateNameSlider:SetShown(not isCastBarMode)
        end
        if autoResizeNameCheck then
            autoResizeNameCheck:SetShown(not isCastBarMode)
        end
    end

    local function SyncFrameTextSizeSliders()
        if not nameTextSlider or not hpTextSlider then return end
        local unit = MattMinimalFramesDB.textSizeUnit or "player"
        syncingFrameTextSize = true
        nameTextSlider.slider:SetValue(GetNameTextSizeForUnit(unit))
        hpTextSlider.slider:SetValue(GetHPTextSizeForUnit(unit))
        if spellNameTextSlider then
            spellNameTextSlider.slider:SetValue(GetSpellNameTextSizeForUnit(unit))
        end
        if castTimeTextSlider then
            castTimeTextSlider.slider:SetValue(GetCastTimeTextSizeForUnit(unit))
        end
        syncingFrameTextSize = false
        UpdateFrameTextModeVisibility()
    end

    local frameTextUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "textSizeUnit",
        x = LEFT_COL_X,
        y = -128,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #textUnitOptions,
        label = "Text Unit",
        options = textUnitOptions,
        getValue = function()
            return MattMinimalFramesDB.textSizeUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textSizeUnit = value
            SyncFrameTextSizeSliders()
            UpdateFrameTextModeVisibility()
        end,
    })
    dropdownLists.frameTextUnitList = frameTextUnitDropdown.list

    nameTextSlider = CreateMinimalSlider(unitFramesCol, "Name Size", LEFT_COL_X, -152, LEFT_COL_WIDTH, "__tempNameTextSize", 8, 20, 1, 12, function(value)
        if syncingFrameTextSize then return end
        local unit = MattMinimalFramesDB.textSizeUnit or "player"
        local key = GetNameTextSizeKeyForUnit(unit)
        MattMinimalFramesDB[key] = value
        if MMF_UpdateNameTextSize then
            MMF_UpdateNameTextSize(value, unit)
        end
        if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local frame = MMF_GetFrameForUnit(unit)
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        else
            RequestNameTextRefresh()
        end
    end, true, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            local key = GetNameTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 12
            local currentValue = GetNameTextSizeForUnit(unit)
            return currentValue == defaultValue
        end,
        onReset = function()
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            local db = MattMinimalFramesDB
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            local key = GetNameTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 12
            db[key] = defaultValue
            if nameTextSlider and nameTextSlider.slider then
                nameTextSlider.slider:SetValue(defaultValue)
            end
        end,
    })

    hpTextSlider = CreateMinimalSlider(unitFramesCol, "HP Size", LEFT_COL_X, -176, LEFT_COL_WIDTH, "__tempHPTextSize", 8, 20, 1, 13, function(value)
        if syncingFrameTextSize then return end
        local unit = MattMinimalFramesDB.textSizeUnit or "player"
        local key = GetHPTextSizeKeyForUnit(unit)
        MattMinimalFramesDB[key] = value
        if MMF_UpdateHPTextSize then
            MMF_UpdateHPTextSize(value, unit)
        end
    end, true, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            local key = GetHPTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 13
            local currentValue = GetHPTextSizeForUnit(unit)
            return currentValue == defaultValue
        end,
        onReset = function()
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            local db = MattMinimalFramesDB
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            local key = GetHPTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 13
            db[key] = defaultValue
            if hpTextSlider and hpTextSlider.slider then
                hpTextSlider.slider:SetValue(defaultValue)
            end
        end,
    })

    spellNameTextSlider = CreateMinimalSlider(unitFramesCol, "Spell Name", LEFT_COL_X, -200, LEFT_COL_WIDTH, "__tempSpellNameTextSize", 8, 20, 1, 12, function(value)
        if syncingFrameTextSize then return end
        local unit = MattMinimalFramesDB.textSizeUnit or "player"
        if not IsCastBarTextUnit(unit) then return end
        MattMinimalFramesDB[GetSpellNameTextSizeKeyForUnit(unit)] = value
        if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local ownerUnit = GetCastBarOwnerUnit(unit)
            local frame = MMF_GetFrameForUnit(ownerUnit)
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        elseif MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        end
    end, true, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            if not IsCastBarTextUnit(unit) then
                return true
            end
            local key = GetSpellNameTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 12
            local currentValue = tonumber(db[key]) or defaultValue
            return currentValue == defaultValue
        end,
        onReset = function()
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            local db = MattMinimalFramesDB
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            if not IsCastBarTextUnit(unit) then
                return
            end
            local key = GetSpellNameTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 12
            db[key] = defaultValue
            if spellNameTextSlider and spellNameTextSlider.slider then
                spellNameTextSlider.slider:SetValue(defaultValue)
            end
        end,
    })
    spellNameTextSlider:Hide()

    castTimeTextSlider = CreateMinimalSlider(unitFramesCol, "Cast Time", LEFT_COL_X, -224, LEFT_COL_WIDTH, "__tempCastTimeTextSize", 8, 20, 1, 9, function(value)
        if syncingFrameTextSize then return end
        local unit = MattMinimalFramesDB.textSizeUnit or "player"
        if not IsCastBarTextUnit(unit) then return end
        MattMinimalFramesDB[GetCastTimeTextSizeKeyForUnit(unit)] = value
        if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local ownerUnit = GetCastBarOwnerUnit(unit)
            local frame = MMF_GetFrameForUnit(ownerUnit)
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        elseif MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        end
    end, true, {
        isDefault = function()
            local db = MattMinimalFramesDB or {}
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            if not IsCastBarTextUnit(unit) then
                return true
            end
            local key = GetCastTimeTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 9
            local currentValue = tonumber(db[key]) or defaultValue
            return currentValue == defaultValue
        end,
        onReset = function()
            if not MattMinimalFramesDB then
                MattMinimalFramesDB = {}
            end
            local db = MattMinimalFramesDB
            local d = MattMinimalFrames_Defaults or {}
            local unit = db.textSizeUnit or "player"
            if not IsCastBarTextUnit(unit) then
                return
            end
            local key = GetCastTimeTextSizeKeyForUnit(unit)
            local defaultValue = tonumber(d[key]) or 9
            db[key] = defaultValue
            if castTimeTextSlider and castTimeTextSlider.slider then
                castTimeTextSlider.slider:SetValue(defaultValue)
            end
        end,
    })
    castTimeTextSlider:Hide()

    MattMinimalFramesDB.__tempNameTextSize = nil
    MattMinimalFramesDB.__tempHPTextSize = nil
    MattMinimalFramesDB.__tempSpellNameTextSize = nil
    MattMinimalFramesDB.__tempCastTimeTextSize = nil
    SyncFrameTextSizeSliders()

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

    truncateNameCheck = CreateMinimalCheckbox(unitFramesCol, "Manual Name Truncate", LEFT_COL_X, -200, "enableNameTruncation", false, function(checked)
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

    truncateNameSlider = CreateMinimalSlider(unitFramesCol, "Truncate Length", LEFT_COL_X, -224, LEFT_COL_WIDTH, "nameTruncationLength", 5, 30, 1, 14, function()
        RequestNameTextRefresh()
    end, true)

    autoResizeNameCheck = CreateMinimalCheckbox(unitFramesCol, "Auto Resize Text On Long Name", LEFT_COL_X, -248, "autoResizeTextOnLongName", false, function(checked)
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
    UpdateFrameTextModeVisibility()
end
