local function MMF_UnitPagePowerRefresh()
    if MMF_UpdatePowerBarVisibility then
        MMF_UpdatePowerBarVisibility()
    end
    if MMF_RequestUnitUpdate then
        MMF_RequestUnitUpdate("player")
        MMF_RequestUnitUpdate("target")
        return
    end
    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
    end
end

local function MMF_UnitPagePowerTitle(parent, text, x, y)
    local tone = "power"
    if MMF_CreateUnitFramesSectionHeader then
        return MMF_CreateUnitFramesSectionHeader(parent, text, x, y, tone)
    end
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
    title:SetPoint("TOPLEFT", x, y)
    if MMF_ApplyUnitFramesHeadingColor then
        MMF_ApplyUnitFramesHeadingColor(title, tone)
    else
        title:SetTextColor(MMF_GetPopupSectionTitleColor())
    end
    title:SetText(text)
end

function MMF_BuildUnitFramesPowerSection(ctx)
    local parent = ctx.parent
    local popup = ctx.popup
    local unit = ctx.unit
    if unit ~= "player" and unit ~= "target" then
        return
    end

    local db = MattMinimalFramesDB or {}
    local defaults = MattMinimalFrames_Defaults or {}
    local CreateCheckbox = ctx.createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateSlider = ctx.createMinimalSlider or MMF_CreateMinimalSlider
    local CreateColorPicker = ctx.createMinimalColorPicker or MMF_CreateMinimalColorPicker
    local accent = ctx.accentColor or { 0.6, 0.4, 0.9 }
    local dropdownLists = ctx.dropdownLists or {}
    local leftX, rightX, width = 12, 382, 346
    local isPlayer = unit == "player"
    local keyPrefix = isPlayer and "Player" or "Target"
    local lowerUnit = unit

    local function IsDruid()
        local _, class = UnitClass("player")
        return isPlayer and class == "DRUID"
    end

    local function IsEnabled(key)
        return db[key] == true or db[key] == 1
    end

    local function SetEnabled(control, enabled)
        if not control then return end
        control:SetAlpha(enabled and 1 or 0.45)
        if control.checkbox then control.checkbox:EnableMouse(enabled) end
        if control.slider then
            control.slider:SetEnabled(enabled)
            control.slider:EnableMouse(enabled)
        end
        if control.valueText then control.valueText:EnableMouse(enabled) end
    end

    MMF_UnitPagePowerTitle(parent, "POWER BAR", leftX, -12)
    local powerBarKey = "show" .. keyPrefix .. "PowerBar"
    local powerTextKey = "show" .. keyPrefix .. "PowerText"
    local colorTextKey = "color" .. keyPrefix .. "PowerTextByResource"
    local textScaleKey = lowerUnit .. "PowerTextScale"
    local widthKey = lowerUnit .. "PowerBarWidth"
    local heightKey = lowerUnit .. "PowerBarHeight"
    local modeKey = lowerUnit .. "PowerTextMode"
    local anchorKey = lowerUnit .. "PowerTextAnchorPoint"

    local percentKey = "show" .. keyPrefix .. "PowerPercentText"
    if MattMinimalFramesDB[percentKey] == nil then
        MattMinimalFramesDB[percentKey] = MattMinimalFramesDB.showPowerPercentText == true
    end
    if MattMinimalFramesDB[modeKey] == nil then
        MattMinimalFramesDB[modeKey] = MattMinimalFramesDB[percentKey] and "both" or "value"
    end

    local barCheckbox
    local textCheckbox
    local colorTextCheckbox
    local druidManaCheckbox
    local textScaleSlider
    local widthSlider
    local heightSlider

    local function RefreshDependencies()
        local textEnabled = IsEnabled(powerTextKey)
        local barEnabled = IsEnabled(powerBarKey)
        SetEnabled(colorTextCheckbox, textEnabled)
        SetEnabled(druidManaCheckbox, textEnabled and IsDruid())
        SetEnabled(widthSlider, barEnabled)
        SetEnabled(heightSlider, barEnabled)
    end

    barCheckbox = CreateCheckbox(parent, "Power Bar", leftX, -42, powerBarKey, true, function()
        MMF_UnitPagePowerRefresh()
        RefreshDependencies()
    end)
    textCheckbox = CreateCheckbox(parent, "Power Text", leftX, -70, powerTextKey, true, function()
        MMF_UnitPagePowerRefresh()
        RefreshDependencies()
    end)
    colorTextCheckbox = CreateCheckbox(parent, "Color Text by Resource", leftX, -98, colorTextKey, true, MMF_UnitPagePowerRefresh)

    local modeOptions = {
        { value = "value", label = "Value" }, { value = "percent", label = "Percent" },
        { value = "both", label = "Value + Percent" }, { value = "both_white_percent", label = "Value + % (White %)" },
    }
    local modeDropdown = MMF_CreateMinimalDropdown(parent, popup, {
        accentColor = accent, settingKey = modeKey, x = leftX, y = -126, width = width,
        labelWidth = 76, buttonOffset = 80, buttonWidth = width - 80, visibleRows = #modeOptions,
        label = "Text Format", options = modeOptions,
        getValue = function() return db[modeKey] or "value" end,
        onSelect = function(value)
            MattMinimalFramesDB[modeKey] = value
            MMF_UnitPagePowerRefresh()
        end,
    })
    dropdownLists[unit .. "PowerTextModeList"] = modeDropdown.list

    local anchorOptions = {
        { value = "OFF", label = "Off" }, { value = "TOPLEFT", label = "Top Left" }, { value = "TOP", label = "Top" },
        { value = "TOPRIGHT", label = "Top Right" }, { value = "LEFT", label = "Left" }, { value = "CENTER", label = "Center" },
        { value = "RIGHT", label = "Right" }, { value = "BOTTOMLEFT", label = "Bottom Left" }, { value = "BOTTOM", label = "Bottom" },
        { value = "BOTTOMRIGHT", label = "Bottom Right" },
    }
    local anchorDropdown = MMF_CreateMinimalDropdown(parent, popup, {
        accentColor = accent, settingKey = anchorKey, x = leftX, y = -154, width = width,
        labelWidth = 76, buttonOffset = 80, buttonWidth = width - 80, visibleRows = #anchorOptions,
        label = "Power Anchor", options = anchorOptions,
        getValue = function()
            return (MMF_GetPowerTextAnchorPoint and MMF_GetPowerTextAnchorPoint(unit)) or "OFF"
        end,
        onSelect = function(value)
            MattMinimalFramesDB[anchorKey] = value
            if MMF_ApplyPowerTextPositions then MMF_ApplyPowerTextPositions() end
            MMF_UnitPagePowerRefresh()
        end,
    })
    dropdownLists[unit .. "PowerAnchorList"] = anchorDropdown.list

    local resetButton = CreateFrame("Button", nil, parent, "BackdropTemplate")
    resetButton:SetSize(width, 20)
    resetButton:SetPoint("TOPLEFT", leftX, -182)
    resetButton:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    resetButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
    resetButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    local resetText = resetButton:CreateFontString(nil, "OVERLAY")
    resetText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    resetText:SetPoint("CENTER")
    resetText:SetText("RESET POWER POSITION")
    resetText:SetTextColor(0.85, 0.85, 0.85)
    resetButton:SetScript("OnClick", function()
        if MattMinimalFramesDB.powerTextPositions then MattMinimalFramesDB.powerTextPositions[unit] = nil end
        if MattMinimalFramesDB.powerBarPositions then MattMinimalFramesDB.powerBarPositions[unit] = nil end
        if MMF_ApplyPowerTextPositions then MMF_ApplyPowerTextPositions() end
        if MMF_ApplyPowerBarPositions then MMF_ApplyPowerBarPositions() end
        MMF_UnitPagePowerRefresh()
    end)

    textScaleSlider = CreateSlider(parent, "Text Scale", leftX, -210, width, textScaleKey, 0.5, 2.0, 0.05,
        db[textScaleKey] or db.powerTextScale or defaults[textScaleKey] or 0.77, MMF_UnitPagePowerRefresh, false)

    MMF_UnitPagePowerTitle(parent, "POWER BAR SIZE", rightX, -12)
    widthSlider = CreateSlider(parent, "Power Bar Width", rightX, -42, width, widthKey, 30, 250, 1,
        db[widthKey] or db.powerBarWidth or defaults[widthKey] or 218, function(value)
            if MMF_SetPowerBarSize then
                MMF_SetPowerBarSize(value, MattMinimalFramesDB[heightKey] or defaults[heightKey] or 3, unit)
            end
        end, true)
    heightSlider = CreateSlider(parent, "Power Bar Height", rightX, -70, width, heightKey, 3, 15, 1,
        db[heightKey] or db.powerBarHeight or defaults[heightKey] or 3, function(value)
            if MMF_SetPowerBarSize then
                MMF_SetPowerBarSize(MattMinimalFramesDB[widthKey] or defaults[widthKey] or 218, value, unit)
            end
        end, true)

    if isPlayer and IsDruid() then
        druidManaCheckbox = CreateCheckbox(parent, "Mana Resource Only", leftX, -238, "showDruidManaPowerText", false, MMF_UnitPagePowerRefresh)
    end

    local compat = _G.MMF_Compat or {}
    local _, playerClass = UnitClass("player")
    if isPlayer and compat.IsTBC and (playerClass == "ROGUE" or playerClass == "DRUID") then
        MMF_UnitPagePowerTitle(parent, "COMBO POINT BAR", leftX, -280)
        CreateCheckbox(parent, "Enable Combo Point Bar", leftX, -310, "showComboPointBar", true, function(checked)
            if checked then
                if MMF_InitializeClassResources then MMF_InitializeClassResources() end
            elseif _G.MMF_ComboPointBar then
                _G.MMF_ComboPointBar:Hide()
            end
        end)
        CreateSlider(parent, "Point Width", leftX, -338, width, "comboPointBarWidth", 6, 80, 1, defaults.comboPointBarWidth or 30, function()
            if MMF_UpdateClassBarLayout then MMF_UpdateClassBarLayout("comboPointBar") end
        end, true)
        CreateSlider(parent, "Point Height", leftX, -366, width, "comboPointBarHeight", 4, 30, 1, defaults.comboPointBarHeight or 10, function()
            if MMF_UpdateClassBarLayout then MMF_UpdateClassBarLayout("comboPointBar") end
        end, true)
    end

    MMF_UnitPagePowerTitle(parent, "POWER BAR COLORS", rightX, -112)
    local resourceOptionsRaw = {
        { value = "MANA", label = "Mana", tbcValid = true }, { value = "RAGE", label = "Rage", tbcValid = true },
        { value = "ENERGY", label = "Energy", tbcValid = true }, { value = "FOCUS", label = "Focus", tbcValid = false },
        { value = "RUNIC_POWER", label = "Runic Power", tbcValid = false }, { value = "LUNAR_POWER", label = "Lunar Power", tbcValid = false },
        { value = "INSANITY", label = "Insanity", tbcValid = false }, { value = "MAELSTROM", label = "Maelstrom", tbcValid = false },
        { value = "FURY", label = "Fury", tbcValid = false }, { value = "PAIN", label = "Pain", tbcValid = false },
    }
    local resourceOptions, validTokens = {}, {}
    for _, option in ipairs(resourceOptionsRaw) do
        if compat.IsClassicEra and not option.tbcValid then
            resourceOptions[#resourceOptions + 1] = { divider = true, label = option.label .. " (N/A)" }
        else
            resourceOptions[#resourceOptions + 1] = { value = option.value, label = option.label }
            validTokens[option.value] = true
        end
    end
    local function SelectedToken()
        local token = string.upper(tostring(MattMinimalFramesDB.powerColorEditorResource or "MANA"))
        if not validTokens[token] then token = "MANA" end
        MattMinimalFramesDB.powerColorEditorResource = token
        return token
    end
    local function DefaultColor(token)
        local colors = {
            MANA = { 0.2, 0.7, 1.0 }, RAGE = { 1.0, 0.2, 0.2 }, ENERGY = { 1.0, 0.85, 0.1 }, FOCUS = { 1.0, 0.5, 0.25 },
            RUNIC_POWER = { 0.0, 0.82, 1.0 }, LUNAR_POWER = { 0.3, 0.52, 0.9 }, INSANITY = { 1.0, 0.0, 0.72 },
            MAELSTROM = { 0.0, 0.5, 1.0 }, FURY = { 0.76, 0.36, 1.0 }, PAIN = { 1.0, 0.61, 0.0 },
        }
        local color = colors[token] or { 1, 1, 1 }
        return color[1], color[2], color[3]
    end
    local function ColorBase(background)
        local token = SelectedToken()
        return "powerColor_" .. unit .. "_" .. token .. (background and "_BG" or ""), token
    end
    local function LegacyPrefix(background)
        if unit == "target" then return background and "targetManaBarBGColor" or "targetManaBarColor" end
        return background and "playerManaBarBGColor" or "playerManaBarColor"
    end
    local function GetColor(background)
        local base, token = ColorBase(background)
        if token == "MANA" then
            local legacy = LegacyPrefix(background)
            if type(MattMinimalFramesDB[legacy .. "R"]) == "number" then
                return MattMinimalFramesDB[legacy .. "R"], MattMinimalFramesDB[legacy .. "G"], MattMinimalFramesDB[legacy .. "B"]
            end
        end
        local r, g, b
        if background then
            r, g, b = 0, 0, 0
        else
            r, g, b = DefaultColor(token)
        end
        return MattMinimalFramesDB[base .. "_R"] or r, MattMinimalFramesDB[base .. "_G"] or g, MattMinimalFramesDB[base .. "_B"] or b
    end
    local function SetColor(background, r, g, b)
        local base, token = ColorBase(background)
        MattMinimalFramesDB[base .. "_R"], MattMinimalFramesDB[base .. "_G"], MattMinimalFramesDB[base .. "_B"] = r, g, b
        if token == "MANA" then
            local legacy = LegacyPrefix(background)
            MattMinimalFramesDB[legacy .. "R"], MattMinimalFramesDB[legacy .. "G"], MattMinimalFramesDB[legacy .. "B"] = r, g, b
        end
        MMF_UnitPagePowerRefresh()
    end
    local function ResetColor(background)
        local base, token = ColorBase(background)
        MattMinimalFramesDB[base .. "_R"], MattMinimalFramesDB[base .. "_G"], MattMinimalFramesDB[base .. "_B"], MattMinimalFramesDB[base .. "_A"] = nil, nil, nil, nil
        if token == "MANA" then
            local legacy = LegacyPrefix(background)
            MattMinimalFramesDB[legacy .. "R"], MattMinimalFramesDB[legacy .. "G"], MattMinimalFramesDB[legacy .. "B"], MattMinimalFramesDB[legacy .. "A"] = nil, nil, nil, nil
        end
        MMF_UnitPagePowerRefresh()
    end
    local colorPicker, backgroundPicker
    local resourceDropdown = MMF_CreateMinimalDropdown(parent, popup, {
        accentColor = accent, settingKey = "powerColorEditorResource", x = rightX, y = -142, width = width,
        labelWidth = 52, buttonOffset = 56, buttonWidth = width - 56, visibleRows = #resourceOptions,
        label = "Type", options = resourceOptions, getValue = SelectedToken,
        onSelect = function(value)
            MattMinimalFramesDB.powerColorEditorResource = value
            if colorPicker and colorPicker.RefreshColor then colorPicker:RefreshColor() end
            if backgroundPicker and backgroundPicker.RefreshColor then backgroundPicker:RefreshColor() end
        end,
    })
    dropdownLists[unit .. "PowerColorTypeList"] = resourceDropdown.list
    if CreateColorPicker then
        colorPicker = CreateColorPicker(parent, {
            accentColor = accent, x = rightX, y = -170, width = width, height = 22, labelWidth = 92, buttonOffset = 96, buttonWidth = width - 96,
            label = "Power Color", getColor = function() return GetColor(false) end,
            onColorChanged = function(r, g, b) SetColor(false, r, g, b) end,
            isDefault = function() local base = ColorBase(false); return MattMinimalFramesDB[base .. "_R"] == nil and MattMinimalFramesDB[base .. "_G"] == nil and MattMinimalFramesDB[base .. "_B"] == nil end,
            onReset = function() ResetColor(false) end,
        })
        backgroundPicker = CreateColorPicker(parent, {
            accentColor = accent, x = rightX, y = -198, width = width, height = 22, labelWidth = 92, buttonOffset = 96, buttonWidth = width - 96,
            label = "Background", getColor = function() return GetColor(true) end,
            onColorChanged = function(r, g, b) SetColor(true, r, g, b) end,
            isDefault = function() local base = ColorBase(true); return MattMinimalFramesDB[base .. "_R"] == nil and MattMinimalFramesDB[base .. "_G"] == nil and MattMinimalFramesDB[base .. "_B"] == nil end,
            onReset = function() ResetColor(true) end,
        })
    end

    RefreshDependencies()
end
