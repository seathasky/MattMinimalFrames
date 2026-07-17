function MMF_BuildAurasPowerPowerSection(ctx)
    local root = ctx.parent
    local popup = ctx.popup
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local CreateMinimalSlider = ctx.createMinimalSlider
    local CreateMinimalDropdown = MMF_CreateMinimalDropdown
    local CreateMinimalColorPicker = MMF_CreateMinimalColorPicker
    local RESOURCE_COL_X = ctx.resourceColX
    local isPlayerDruid = ctx.isPlayerDruid
    local RefreshPowerFrames = ctx.refreshPowerFrames or function() end
    local accent = (MMF_GetPopupAccentColor and MMF_GetPopupAccentColor()) or { 0.6, 0.4, 0.9 }
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local generalTitle = root:CreateFontString(nil, "OVERLAY")
    generalTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    generalTitle:SetPoint("TOPLEFT", RESOURCE_COL_X, -12)
    generalTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    generalTitle:SetText("RESOURCES")

    local playerTitle = root:CreateFontString(nil, "OVERLAY")
    playerTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    playerTitle:SetPoint("TOPLEFT", RESOURCE_COL_X, -52)
    playerTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    playerTitle:SetText("PLAYER")

    local playerColorPowerTextCheck = nil
    local targetColorPowerTextCheck = nil
    local playerDruidManaPowerTextCheck = nil
    local playerPowerBarCheck = nil
    local targetPowerBarCheck = nil
    local playerPowerWidthSlider = nil
    local playerPowerHeightSlider = nil
    local targetPowerWidthSlider = nil
    local targetPowerHeightSlider = nil

    local powerAnchorOptions = {
        { value = "OFF", label = "Off" },
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

    local function GetPowerAnchorPoint(unit)
        local key = unit .. "PowerTextAnchorPoint"
        local value = MattMinimalFramesDB[key]
        if type(value) ~= "string" then
            return "OFF"
        end
        value = string.upper(value)
        if value == "OFF" then
            return "OFF"
        end
        local resolved = nil
        if MMF_GetTextAnchorPreset then
            local _, keyResolved = MMF_GetTextAnchorPreset(value)
            resolved = keyResolved
        end
        if resolved then
            return resolved
        end
        return "OFF"
    end

    local function SetPowerAnchorPoint(unit, value)
        local normalized = type(value) == "string" and string.upper(value) or "OFF"
        if normalized ~= "OFF" then
            local resolved = nil
            if MMF_GetTextAnchorPreset then
                local _, keyResolved = MMF_GetTextAnchorPreset(normalized)
                resolved = keyResolved
            end
            normalized = resolved or "OFF"
        end
        MattMinimalFramesDB[unit .. "PowerTextAnchorPoint"] = normalized
        if MMF_ApplyPowerTextPositions then
            MMF_ApplyPowerTextPositions()
        end
        RefreshPowerFrames()
    end

    local function ResetPowerTextPosition(unit)
        if unit ~= "player" and unit ~= "target" then
            return
        end
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        if MattMinimalFramesDB.powerTextPositions then
            MattMinimalFramesDB.powerTextPositions[unit] = nil
        end
        if MattMinimalFramesDB.powerBarPositions then
            MattMinimalFramesDB.powerBarPositions[unit] = nil
        end
        if MMF_ApplyPowerTextPositions then
            MMF_ApplyPowerTextPositions()
        end
        if MMF_ApplyPowerBarPositions then
            MMF_ApplyPowerBarPositions()
        end
        RefreshPowerFrames()
    end

    local function CreatePowerTextResetButton(x, y, onClick)
        local button = CreateFrame("Button", nil, root, "BackdropTemplate")
        button:SetSize(200, 22)
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
        text:SetText("RESET POWER POSITION")

        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.11, 0.11, 0.14, 1)
            self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.8)
            text:SetTextColor(1, 1, 1)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetText("Reset Power Text Position", 1, 1, 1)
            GameTooltip:AddLine("Resets dragged power text to default for this unit.", 0.75, 0.75, 0.75)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.08, 0.08, 0.1, 1)
            self:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
            text:SetTextColor(0.82, 0.82, 0.86)
            GameTooltip:Hide()
        end)
        button:SetScript("OnClick", function()
            if type(onClick) == "function" then
                onClick()
            end
        end)

        return button
    end

    if MattMinimalFramesDB.showPlayerPowerPercentText == nil then
        MattMinimalFramesDB.showPlayerPowerPercentText = (MattMinimalFramesDB.showPowerPercentText == true)
    end
    if MattMinimalFramesDB.showTargetPowerPercentText == nil then
        MattMinimalFramesDB.showTargetPowerPercentText = (MattMinimalFramesDB.showPowerPercentText == true)
    end
    if MattMinimalFramesDB.playerPowerTextMode == nil then
        MattMinimalFramesDB.playerPowerTextMode = MattMinimalFramesDB.showPlayerPowerPercentText and "both" or "value"
    end
    if MattMinimalFramesDB.targetPowerTextMode == nil then
        MattMinimalFramesDB.targetPowerTextMode = MattMinimalFramesDB.showTargetPowerPercentText and "both" or "value"
    end

    local function SetDependentCheckboxState(container, enabled)
        if not container then return end
        local checkbox = container.checkbox
        if checkbox then
            checkbox:EnableMouse(enabled)
            checkbox:SetAlpha(enabled and 1 or 0.45)
            if checkbox.check then
                checkbox.check:SetAlpha(enabled and 1 or 0.35)
            end
        end
        container:SetAlpha(enabled and 1 or 0.55)
    end

    local function SetDependentSliderState(container, enabled)
        if not container then return end
        container:SetAlpha(enabled and 1 or 0.45)
        if container.slider then
            container.slider:SetEnabled(enabled)
            container.slider:EnableMouse(enabled)
        end
        if container.valueText then
            container.valueText:SetEnabled(enabled)
            container.valueText:EnableMouse(enabled)
        end
    end

    local function ShiftResetButtonLeft(container, offset)
        if not container or not container.resetButton then
            return
        end
        local reset = container.resetButton
        local anchor, relativeTo, relativePoint, xOfs, yOfs = reset:GetPoint(1)
        if anchor and relativeTo then
            reset:ClearAllPoints()
            reset:SetPoint(anchor, relativeTo, relativePoint, (xOfs or 0) - (offset or 28), yOfs or 0)
        end
    end

    local function UpdatePowerTextDependencies()
        local playerTextEnabled = (MattMinimalFramesDB.showPlayerPowerText == true or MattMinimalFramesDB.showPlayerPowerText == 1)
        local targetTextEnabled = (MattMinimalFramesDB.showTargetPowerText == true or MattMinimalFramesDB.showTargetPowerText == 1)
        SetDependentCheckboxState(playerColorPowerTextCheck, playerTextEnabled)
        SetDependentCheckboxState(playerDruidManaPowerTextCheck, playerTextEnabled and isPlayerDruid)
        SetDependentCheckboxState(targetColorPowerTextCheck, targetTextEnabled)
    end
    MMF_RefreshPowerTextOptionStates = UpdatePowerTextDependencies

    local function UpdatePowerBarSizeDependencies()
        local playerBarEnabled = (MattMinimalFramesDB.showPlayerPowerBar == true or MattMinimalFramesDB.showPlayerPowerBar == 1)
        local targetBarEnabled = (MattMinimalFramesDB.showTargetPowerBar == true or MattMinimalFramesDB.showTargetPowerBar == 1)
        SetDependentSliderState(playerPowerWidthSlider, playerBarEnabled)
        SetDependentSliderState(playerPowerHeightSlider, playerBarEnabled)
        SetDependentSliderState(targetPowerWidthSlider, targetBarEnabled)
        SetDependentSliderState(targetPowerHeightSlider, targetBarEnabled)
    end

    playerPowerBarCheck = CreateMinimalCheckbox(root, "Power Bar", RESOURCE_COL_X, -72, "showPlayerPowerBar", true, function()
        RefreshPowerFrames()
        UpdatePowerBarSizeDependencies()
    end)
    ShiftResetButtonLeft(playerPowerBarCheck, 56)

    local playerPowerTextCheck = CreateMinimalCheckbox(root, "Power Text", RESOURCE_COL_X, -96, "showPlayerPowerText", true, function()
        RefreshPowerFrames()
        UpdatePowerTextDependencies()
    end)
    ShiftResetButtonLeft(playerPowerTextCheck, 56)

    playerColorPowerTextCheck = CreateMinimalCheckbox(root, "Color Text by Resource", RESOURCE_COL_X, -120, "colorPlayerPowerTextByResource", true, function()
        RefreshPowerFrames()
    end)
    ShiftResetButtonLeft(playerColorPowerTextCheck, 36)

    local powerTextModeOptions = {
        { value = "value", label = "Value" },
        { value = "percent", label = "Percent" },
        { value = "both", label = "Value + Percent" },
        { value = "both_white_percent", label = "Value + % (White %)" },
    }
    if CreateMinimalDropdown then
        CreateMinimalDropdown(root, popup, {
            accentColor = accent,
            settingKey = "__tempPlayerPowerTextMode",
            x = RESOURCE_COL_X,
            y = -144,
            width = 200,
            labelWidth = 92,
            buttonOffset = 96,
            buttonWidth = 104,
            visibleRows = #powerTextModeOptions,
            label = "Text Format",
            options = powerTextModeOptions,
            getValue = function()
                return MattMinimalFramesDB.playerPowerTextMode or "value"
            end,
            onSelect = function(value)
                MattMinimalFramesDB.playerPowerTextMode = value
                RefreshPowerFrames()
            end,
        })
    end

    local playerPowerAnchorY = -168
    local playerResetY = -196
    local playerTextScaleY = -224
    local playerWidthY = -248
    local playerHeightY = -272
    local targetDividerY = -300
    local targetTitleY = -312
    local targetPowerBarY = -332
    local targetPowerTextY = -356
    local targetColorTextY = -380
    local targetPercentTextY = -404
    local targetPowerAnchorY = -428
    local targetResetY = -456
    local targetTextScaleY = -484
    local targetWidthY = -508
    local targetHeightY = -532

    if isPlayerDruid then
        playerDruidManaPowerTextCheck = CreateMinimalCheckbox(root, "Mana Resource Only", RESOURCE_COL_X, -168, "showDruidManaPowerText", false, function()
            RefreshPowerFrames()
        end)
        playerPowerAnchorY = -192
        playerResetY = -220
        playerTextScaleY = -248
        playerWidthY = -272
        playerHeightY = -296
        targetDividerY = -324
        targetTitleY = -336
        targetPowerBarY = -356
        targetPowerTextY = -380
        targetColorTextY = -404
        targetPercentTextY = -428
        targetPowerAnchorY = -452
        targetResetY = -480
        targetTextScaleY = -508
        targetWidthY = -532
        targetHeightY = -556
    end

    if CreateMinimalDropdown then
        CreateMinimalDropdown(root, popup, {
            accentColor = accent,
            settingKey = "__tempPlayerPowerAnchorPoint",
            x = RESOURCE_COL_X,
            y = playerPowerAnchorY,
            width = 200,
            labelWidth = 92,
            buttonOffset = 96,
            buttonWidth = 104,
            visibleRows = #powerAnchorOptions,
            label = "Power Anchor",
            options = powerAnchorOptions,
            getValue = function()
                return GetPowerAnchorPoint("player")
            end,
            onSelect = function(value)
                SetPowerAnchorPoint("player", value)
            end,
        })
    end

    CreatePowerTextResetButton(RESOURCE_COL_X, playerResetY, function()
        ResetPowerTextPosition("player")
    end)

    CreatePowerTextResetButton(RESOURCE_COL_X, targetResetY, function()
        ResetPowerTextPosition("target")
    end)

    CreateMinimalSlider(root, "Text Scale", RESOURCE_COL_X, playerTextScaleY, 200, "playerPowerTextScale", 0.5, 2.0, 0.05, 0.77, function()
        RefreshPowerFrames()
    end, false)

    playerPowerWidthSlider = CreateMinimalSlider(root, "Power Bar Width", RESOURCE_COL_X, playerWidthY, 200, "playerPowerBarWidth", 30, 250, 1, 218, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.playerPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 3, "player")
        end
    end, true)

    playerPowerHeightSlider = CreateMinimalSlider(root, "Power Bar Height", RESOURCE_COL_X, playerHeightY, 200, "playerPowerBarHeight", 3, 15, 1, 3, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.playerPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 218, value, "player")
        end
    end, true)

    local targetDivider = root:CreateTexture(nil, "ARTWORK")
    targetDivider:SetSize(200, 1)
    targetDivider:SetPoint("TOPLEFT", RESOURCE_COL_X, targetDividerY)
    targetDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local targetTitle = root:CreateFontString(nil, "OVERLAY")
    targetTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    targetTitle:SetPoint("TOPLEFT", RESOURCE_COL_X, targetTitleY)
    targetTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    targetTitle:SetText("TARGET")

    targetPowerBarCheck = CreateMinimalCheckbox(root, "Power Bar", RESOURCE_COL_X, targetPowerBarY, "showTargetPowerBar", true, function()
        RefreshPowerFrames()
        UpdatePowerBarSizeDependencies()
    end)
    ShiftResetButtonLeft(targetPowerBarCheck, 56)

    local targetPowerTextCheck = CreateMinimalCheckbox(root, "Power Text", RESOURCE_COL_X, targetPowerTextY, "showTargetPowerText", true, function()
        RefreshPowerFrames()
        UpdatePowerTextDependencies()
    end)
    ShiftResetButtonLeft(targetPowerTextCheck, 56)

    targetColorPowerTextCheck = CreateMinimalCheckbox(root, "Color Text by Resource", RESOURCE_COL_X, targetColorTextY, "colorTargetPowerTextByResource", true, function()
        RefreshPowerFrames()
    end)
    ShiftResetButtonLeft(targetColorPowerTextCheck, 36)
    if CreateMinimalDropdown then
        CreateMinimalDropdown(root, popup, {
            accentColor = accent,
            settingKey = "__tempTargetPowerTextMode",
            x = RESOURCE_COL_X,
            y = targetPercentTextY,
            width = 200,
            labelWidth = 92,
            buttonOffset = 96,
            buttonWidth = 104,
            visibleRows = #powerTextModeOptions,
            label = "Text Format",
            options = powerTextModeOptions,
            getValue = function()
                return MattMinimalFramesDB.targetPowerTextMode or "value"
            end,
            onSelect = function(value)
                MattMinimalFramesDB.targetPowerTextMode = value
                RefreshPowerFrames()
            end,
        })
    end

    if CreateMinimalDropdown then
        CreateMinimalDropdown(root, popup, {
            accentColor = accent,
            settingKey = "__tempTargetPowerAnchorPoint",
            x = RESOURCE_COL_X,
            y = targetPowerAnchorY,
            width = 200,
            labelWidth = 92,
            buttonOffset = 96,
            buttonWidth = 104,
            visibleRows = #powerAnchorOptions,
            label = "Power Anchor",
            options = powerAnchorOptions,
            getValue = function()
                return GetPowerAnchorPoint("target")
            end,
            onSelect = function(value)
                SetPowerAnchorPoint("target", value)
            end,
        })
    end

    UpdatePowerTextDependencies()

    CreateMinimalSlider(root, "Text Scale", RESOURCE_COL_X, targetTextScaleY, 200, "targetPowerTextScale", 0.5, 2.0, 0.05, 0.77, function()
        RefreshPowerFrames()
    end, false)

    targetPowerWidthSlider = CreateMinimalSlider(root, "Power Bar Width", RESOURCE_COL_X, targetWidthY, 200, "targetPowerBarWidth", 30, 250, 1, 218, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.targetPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 3, "target")
        end
    end, true)

    targetPowerHeightSlider = CreateMinimalSlider(root, "Power Bar Height", RESOURCE_COL_X, targetHeightY, 200, "targetPowerBarHeight", 3, 15, 1, 3, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.targetPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 218, value, "target")
        end
    end, true)

    if CreateMinimalColorPicker and CreateMinimalDropdown then
        local editorX = RESOURCE_COL_X + 260
        local editorTitleY = -52
        local resourceDropdownY = -76
        local playerColorY = -104
        local playerBGColorY = -130
        local targetColorY = -156
        local targetBGColorY = -182

        local resourceTitle = root:CreateFontString(nil, "OVERLAY")
        resourceTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        resourceTitle:SetPoint("TOPLEFT", editorX, editorTitleY)
        resourceTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
        resourceTitle:SetText("RESOURCE COLORS")

        local Compat = _G.MMF_Compat or {}
        local resourceOptionsRaw = {
            { value = "MANA", label = "Mana", tbcValid = true },
            { value = "RAGE", label = "Rage", tbcValid = true },
            { value = "ENERGY", label = "Energy", tbcValid = true },
            { value = "FOCUS", label = "Focus", tbcValid = false },
            { value = "RUNIC_POWER", label = "Runic Power", tbcValid = false },
            { value = "LUNAR_POWER", label = "Lunar Power", tbcValid = false },
            { value = "INSANITY", label = "Insanity", tbcValid = false },
            { value = "MAELSTROM", label = "Maelstrom", tbcValid = false },
            { value = "FURY", label = "Fury", tbcValid = false },
            { value = "PAIN", label = "Pain", tbcValid = false },
        }
        local resourceOptions = {}
        local validTokens = {}
        for _, option in ipairs(resourceOptionsRaw) do
            if Compat.IsClassicEra and not option.tbcValid then
                resourceOptions[#resourceOptions + 1] = {
                    value = option.value,
                    label = option.label .. " (N/A)",
                    divider = true,
                }
            else
                resourceOptions[#resourceOptions + 1] = {
                    value = option.value,
                    label = option.label,
                }
                validTokens[option.value] = true
            end
        end
        local function IsValidResourceToken(token)
            return validTokens[token] == true
        end

        local function GetSelectedResourceToken()
            local token = MattMinimalFramesDB.powerColorEditorResource
            if type(token) ~= "string" then
                token = "MANA"
            end
            token = string.upper(token)
            if not IsValidResourceToken(token) then
                token = "MANA"
            end
            MattMinimalFramesDB.powerColorEditorResource = token
            return token
        end

        local function GetDefaultResourceColor(token)
            local defaults = {
                MANA = { 0.2, 0.7, 1.0 },
                RAGE = { 1.0, 0.2, 0.2 },
                ENERGY = { 1.0, 0.85, 0.1 },
                FOCUS = { 1.0, 0.5, 0.25 },
                RUNIC_POWER = { 0.0, 0.82, 1.0 },
                LUNAR_POWER = { 0.3, 0.52, 0.9 },
                INSANITY = { 1.0, 0.0, 0.72 },
                MAELSTROM = { 0.0, 0.5, 1.0 },
                FURY = { 0.76, 0.36, 1.0 },
                PAIN = { 1.0, 0.61, 0.0 },
            }
            local d = defaults[token]
            if d then
                return d[1], d[2], d[3]
            end
            return 1, 1, 1
        end

        local function BuildPowerColorKey(unit, token, isBackground)
            if isBackground then
                return "powerColor_" .. unit .. "_" .. token .. "_BG"
            end
            return "powerColor_" .. unit .. "_" .. token
        end

        local function GetResourceColor(unit, isBackground)
            local token = GetSelectedResourceToken()
            local keyBase = BuildPowerColorKey(unit, token, isBackground)
            local defaultR, defaultG, defaultB = 0, 0, 0
            if not isBackground then
                defaultR, defaultG, defaultB = GetDefaultResourceColor(token)
            end
            -- Backward compatibility: legacy mana keys should be reflected by the new editor.
            if token == "MANA" then
                if isBackground then
                    local legacyPrefix = (unit == "target") and "targetManaBarBGColor" or "playerManaBarBGColor"
                    local lr = MattMinimalFramesDB[legacyPrefix .. "R"]
                    local lg = MattMinimalFramesDB[legacyPrefix .. "G"]
                    local lb = MattMinimalFramesDB[legacyPrefix .. "B"]
                    if type(lr) == "number" and type(lg) == "number" and type(lb) == "number" then
                        return lr, lg, lb
                    end
                else
                    local legacyPrefix = (unit == "target") and "targetManaBarColor" or "playerManaBarColor"
                    local lr = MattMinimalFramesDB[legacyPrefix .. "R"]
                    local lg = MattMinimalFramesDB[legacyPrefix .. "G"]
                    local lb = MattMinimalFramesDB[legacyPrefix .. "B"]
                    if type(lr) == "number" and type(lg) == "number" and type(lb) == "number" then
                        return lr, lg, lb
                    end
                end
            end
            return MattMinimalFramesDB[keyBase .. "_R"] or defaultR,
                MattMinimalFramesDB[keyBase .. "_G"] or defaultG,
                MattMinimalFramesDB[keyBase .. "_B"] or defaultB
        end

        local function SetResourceColor(unit, isBackground, r, g, b)
            local token = GetSelectedResourceToken()
            local keyBase = BuildPowerColorKey(unit, token, isBackground)
            MattMinimalFramesDB[keyBase .. "_R"] = r
            MattMinimalFramesDB[keyBase .. "_G"] = g
            MattMinimalFramesDB[keyBase .. "_B"] = b
            if token == "MANA" then
                if isBackground then
                    local legacyPrefix = (unit == "target") and "targetManaBarBGColor" or "playerManaBarBGColor"
                    MattMinimalFramesDB[legacyPrefix .. "R"] = r
                    MattMinimalFramesDB[legacyPrefix .. "G"] = g
                    MattMinimalFramesDB[legacyPrefix .. "B"] = b
                else
                    local legacyPrefix = (unit == "target") and "targetManaBarColor" or "playerManaBarColor"
                    MattMinimalFramesDB[legacyPrefix .. "R"] = r
                    MattMinimalFramesDB[legacyPrefix .. "G"] = g
                    MattMinimalFramesDB[legacyPrefix .. "B"] = b
                end
            end
            RefreshPowerFrames()
        end


        local function IsResourceColorDefault(unit, isBackground)
            local token = GetSelectedResourceToken()
            local keyBase = BuildPowerColorKey(unit, token, isBackground)
            return MattMinimalFramesDB[keyBase .. "_R"] == nil
                and MattMinimalFramesDB[keyBase .. "_G"] == nil
                and MattMinimalFramesDB[keyBase .. "_B"] == nil
        end


        local function ResetResourceColor(unit, isBackground)
            local token = GetSelectedResourceToken()
            local keyBase = BuildPowerColorKey(unit, token, isBackground)
            MattMinimalFramesDB[keyBase .. "_R"] = nil
            MattMinimalFramesDB[keyBase .. "_G"] = nil
            MattMinimalFramesDB[keyBase .. "_B"] = nil
            MattMinimalFramesDB[keyBase .. "_A"] = nil
            if token == "MANA" then
                if isBackground then
                    local legacyPrefix = (unit == "target") and "targetManaBarBGColor" or "playerManaBarBGColor"
                    MattMinimalFramesDB[legacyPrefix .. "R"] = nil
                    MattMinimalFramesDB[legacyPrefix .. "G"] = nil
                    MattMinimalFramesDB[legacyPrefix .. "B"] = nil
                    MattMinimalFramesDB[legacyPrefix .. "A"] = nil
                else
                    local legacyPrefix = (unit == "target") and "targetManaBarColor" or "playerManaBarColor"
                    MattMinimalFramesDB[legacyPrefix .. "R"] = nil
                    MattMinimalFramesDB[legacyPrefix .. "G"] = nil
                    MattMinimalFramesDB[legacyPrefix .. "B"] = nil
                    MattMinimalFramesDB[legacyPrefix .. "A"] = nil
                end
            end
            RefreshPowerFrames()
        end


        local playerColorPicker
        local playerBGColorPicker
        local targetColorPicker
        local targetBGColorPicker

        CreateMinimalDropdown(root, popup, {
            accentColor = accent,
            settingKey = "__tempPowerColorEditorResource",
            x = editorX,
            y = resourceDropdownY,
            width = 220,
            labelWidth = 66,
            buttonOffset = 70,
            buttonWidth = 150,
            visibleRows = #resourceOptions,
            label = "Type",
            options = resourceOptions,
            getValue = function()
                return GetSelectedResourceToken()
            end,
            onSelect = function(value)
                MattMinimalFramesDB.powerColorEditorResource = value
                if playerColorPicker and playerColorPicker.RefreshColor then playerColorPicker:RefreshColor() end
                if playerBGColorPicker and playerBGColorPicker.RefreshColor then playerBGColorPicker:RefreshColor() end
                if targetColorPicker and targetColorPicker.RefreshColor then targetColorPicker:RefreshColor() end
                if targetBGColorPicker and targetBGColorPicker.RefreshColor then targetBGColorPicker:RefreshColor() end
            end,
        })

        playerColorPicker = CreateMinimalColorPicker(root, {
            accentColor = accent,
            label = "Player",
            x = editorX,
            y = playerColorY,
            width = 220,
            labelWidth = 66,
            buttonOffset = 70,
            buttonWidth = 150,
            getColor = function() return GetResourceColor("player", false) end,
            onColorChanged = function(r, g, b) SetResourceColor("player", false, r, g, b) end,
            isDefault = function() return IsResourceColorDefault("player", false) end,
            onReset = function() ResetResourceColor("player", false) end,
        })

        playerBGColorPicker = CreateMinimalColorPicker(root, {
            accentColor = accent,
            label = "Player BG",
            x = editorX,
            y = playerBGColorY,
            width = 220,
            labelWidth = 66,
            buttonOffset = 70,
            buttonWidth = 150,
            getColor = function() return GetResourceColor("player", true) end,
            onColorChanged = function(r, g, b) SetResourceColor("player", true, r, g, b) end,
            isDefault = function() return IsResourceColorDefault("player", true) end,
            onReset = function() ResetResourceColor("player", true) end,
        })

        targetColorPicker = CreateMinimalColorPicker(root, {
            accentColor = accent,
            label = "Target",
            x = editorX,
            y = targetColorY,
            width = 220,
            labelWidth = 66,
            buttonOffset = 70,
            buttonWidth = 150,
            getColor = function() return GetResourceColor("target", false) end,
            onColorChanged = function(r, g, b) SetResourceColor("target", false, r, g, b) end,
            isDefault = function() return IsResourceColorDefault("target", false) end,
            onReset = function() ResetResourceColor("target", false) end,
        })

        targetBGColorPicker = CreateMinimalColorPicker(root, {
            accentColor = accent,
            label = "Target BG",
            x = editorX,
            y = targetBGColorY,
            width = 220,
            labelWidth = 66,
            buttonOffset = 70,
            buttonWidth = 150,
            getColor = function() return GetResourceColor("target", true) end,
            onColorChanged = function(r, g, b) SetResourceColor("target", true, r, g, b) end,
            isDefault = function() return IsResourceColorDefault("target", true) end,
            onReset = function() ResetResourceColor("target", true) end,
        })
    end

    UpdatePowerBarSizeDependencies()
end
