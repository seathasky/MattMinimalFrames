function MMF_BuildUnitFramesMediaSection(ctx)
    local unitFramesCol = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local dropdownLists = ctx.dropdownLists
    local rightSection = ctx.rightSection
    local NormalizeSelectionValue = ctx.normalizeSelectionValue
    local CreateMinimalSlider = ctx.createMinimalSlider or MMF_CreateMinimalSlider

    local RIGHT_COL_X = ctx.rightColX
    local RIGHT_COL_WIDTH = ctx.rightColWidth
    local RIGHT_STACK_Y_OFFSET = ctx.rightStackYOffset
    local RIGHT_STYLE_LABEL_WIDTH = ctx.rightStyleLabelWidth
    local RIGHT_STYLE_BUTTON_OFFSET = ctx.rightStyleButtonOffset
    local RIGHT_STYLE_BUTTON_WIDTH = ctx.rightStyleButtonWidth
    local PLAYER_BAR_LABEL_WIDTH = ctx.playerBarLabelWidth
    local PLAYER_BAR_BUTTON_OFFSET = ctx.playerBarButtonOffset
    local PLAYER_BAR_BUTTON_WIDTH = ctx.playerBarButtonWidth

    rightSection.styleTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    rightSection.styleTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    rightSection.styleTitle:SetPoint("TOPLEFT", RIGHT_COL_X, -288 + RIGHT_STACK_Y_OFFSET)
    rightSection.styleTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    rightSection.styleTitle:SetText("STYLE")

    rightSection.styleSubtext = unitFramesCol:CreateFontString(nil, "OVERLAY")
    rightSection.styleSubtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    rightSection.styleSubtext:SetPoint("TOPLEFT", RIGHT_COL_X, -308 + RIGHT_STACK_Y_OFFSET)
    rightSection.styleSubtext:SetTextColor(0.65, 0.65, 0.7)
    rightSection.styleSubtext:SetText("Textures, fonts, and frame colors")

    rightSection.texturePreviewBG = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
    rightSection.texturePreviewBG:SetSize(RIGHT_STYLE_BUTTON_WIDTH, 16)
    rightSection.texturePreviewBG:SetPoint("TOPLEFT", RIGHT_COL_X + RIGHT_STYLE_BUTTON_OFFSET, -366 + RIGHT_STACK_Y_OFFSET)
    rightSection.texturePreviewBG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    rightSection.texturePreviewBG:SetBackdropColor(0.03, 0.03, 0.04, 1)
    rightSection.texturePreviewBG:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    local texturePreview = CreateFrame("StatusBar", nil, rightSection.texturePreviewBG)
    texturePreview:SetPoint("TOPLEFT", rightSection.texturePreviewBG, "TOPLEFT", 1, -1)
    texturePreview:SetPoint("BOTTOMRIGHT", rightSection.texturePreviewBG, "BOTTOMRIGHT", -1, 1)
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
        if rightSection.unitTextureDropdown then
            rightSection.unitTextureDropdown.SetSelectedValue(GetSelectedTexture())
        end
    end

    rightSection.unitTextureDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = -332 + RIGHT_STACK_Y_OFFSET,
        width = RIGHT_COL_WIDTH,
        labelWidth = RIGHT_STYLE_LABEL_WIDTH,
        buttonOffset = RIGHT_STYLE_BUTTON_OFFSET,
        buttonWidth = RIGHT_STYLE_BUTTON_WIDTH,
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
            if rightSection.unitTextureDropdown then
                rightSection.unitTextureDropdown.SetSelectedValue(GetSelectedTexture())
            end
        end,
        onSelect = function(value)
            ApplySelectedTexture(value)
        end,
    })
    dropdownLists.unitTextureList = rightSection.unitTextureDropdown.list

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
            local previewPath = nil
            if MMF_GetGlobalFontPathByName then
                local resolvedPath = MMF_GetGlobalFontPathByName(optionName)
                if type(resolvedPath) == "string" and resolvedPath ~= "" then
                    previewPath = resolvedPath
                end
            end
            out[#out + 1] = { value = optionName, label = optionName, fontPath = previewPath }
        end
        return out
    end

    local function ApplySelectedFont(name)
        local selected = NormalizeSelectionValue(name, "MMF Naowh")
        local previous = GetSelectedFont()
        if selected == previous then
            return
        end

        if MMF_SetGlobalFont then
            MMF_SetGlobalFont(selected)
        else
            MattMinimalFramesDB.globalFont = selected
            if MMF_ApplyGlobalFont then
                MMF_ApplyGlobalFont()
            end
        end

        EnsureValidSelectedFont()
        if rightSection.unitFontDropdown then
            rightSection.unitFontDropdown.SetSelectedValue(GetSelectedFont())
        end

        if StaticPopup_Show then
            StaticPopup_Show("MMF_RELOADUI")
        end
    end

    rightSection.unitFontDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        fontPath = STANDARD_TEXT_FONT or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf",
        preserveWidgetFont = true,
        previewOptionFonts = true,
        x = RIGHT_COL_X,
        y = -402 + RIGHT_STACK_Y_OFFSET,
        width = RIGHT_COL_WIDTH,
        labelWidth = RIGHT_STYLE_LABEL_WIDTH,
        buttonOffset = RIGHT_STYLE_BUTTON_OFFSET,
        buttonWidth = RIGHT_STYLE_BUTTON_WIDTH,
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
            if rightSection.unitFontDropdown then
                rightSection.unitFontDropdown.SetSelectedValue(GetSelectedFont())
            end
        end,
        onSelect = function(value)
            ApplySelectedFont(value)
        end,
    })
    dropdownLists.unitFontList = rightSection.unitFontDropdown.list

    local function ClampColorChannel(value, fallback)
        local n = tonumber(value)
        if not n then
            n = tonumber(fallback) or 1
        end
        if n < 0 then n = 0 end
        if n > 1 then n = 1 end
        return n
    end

    rightSection.frameColorsDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    rightSection.frameColorsDivider:SetSize(RIGHT_COL_WIDTH, 1)
    rightSection.frameColorsDivider:SetPoint("TOPLEFT", RIGHT_COL_X, -438 + RIGHT_STACK_Y_OFFSET)
    rightSection.frameColorsDivider:SetColorTexture(0.42, 0.42, 0.46, 1)

    rightSection.frameColorsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    rightSection.frameColorsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    rightSection.frameColorsTitle:SetPoint("TOPLEFT", RIGHT_COL_X, -450 + RIGHT_STACK_Y_OFFSET)
    rightSection.frameColorsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    rightSection.frameColorsTitle:SetText("FRAME COLORS")

    local frameColorRowsStartY = -466 + RIGHT_STACK_Y_OFFSET
    local frameColorRowSpacing = 22
    local frameColorPetY = frameColorRowsStartY - (frameColorRowSpacing * 4)

    -- Three visual groups:
    -- 1) Unit frame colors
    -- 2) Frame alpha + health BG controls
    -- 3) Health border controls
    local frameColorAlphaY = frameColorPetY - 28
    local frameColorDividerUnderPetY = frameColorAlphaY - 24
    local frameColorsStartY = frameColorDividerUnderPetY - 18
    local frameColorsRowSpacing = 30
    local healthBGAlphaY = frameColorsStartY - frameColorsRowSpacing
    local frameColorsDividerUnderHealthBGAlphaY = healthBGAlphaY - 26
    local healthBorderY = frameColorsDividerUnderHealthBGAlphaY - 8
    local borderSectionRowSpacing = 20
    local borderWidthY = healthBorderY - borderSectionRowSpacing
    local borderAlphaY = borderWidthY - borderSectionRowSpacing

    rightSection.frameColorDividerBottom = unitFramesCol:CreateTexture(nil, "ARTWORK")
    rightSection.frameColorDividerBottom:SetSize(RIGHT_COL_WIDTH, 1)
    rightSection.frameColorDividerBottom:SetPoint("TOPLEFT", RIGHT_COL_X, frameColorDividerUnderPetY)
    rightSection.frameColorDividerBottom:SetColorTexture(0.42, 0.42, 0.46, 1)

    CreateMinimalSlider(unitFramesCol, "Frame Alpha", RIGHT_COL_X, frameColorAlphaY, RIGHT_COL_WIDTH, "frameColorAlpha", 0.0, 1.0, 0.05, 1.0, function(value)
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB.frameColorAlpha = value
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        elseif MMF_GetAllFrames and MMF_UpdateUnitFrame then
            for _, frame in ipairs(MMF_GetAllFrames()) do
                if frame then
                    MMF_UpdateUnitFrame(frame)
                end
            end
        end
    end, false)

    rightSection.healthBarBGColorPicker = MMF_CreateMinimalColorPicker(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = frameColorsStartY,
        width = RIGHT_COL_WIDTH,
        height = 16,
        labelWidth = PLAYER_BAR_LABEL_WIDTH,
        buttonOffset = PLAYER_BAR_BUTTON_OFFSET,
        buttonWidth = PLAYER_BAR_BUTTON_WIDTH,
        label = "Health Bar BG",
        resetLabel = "Reset",
        getColor = function()
            return ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBGColorR, 0),
                ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBGColorG, 0),
                ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBGColorB, 0)
        end,
        onColorChanged = function(r, g, b)
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.healthBarBGColorR = ClampColorChannel(r, 0)
            MattMinimalFramesDB.healthBarBGColorG = ClampColorChannel(g, 0)
            MattMinimalFramesDB.healthBarBGColorB = ClampColorChannel(b, 0)
            if MMF_ApplyHealthBarBackgroundColor then
                MMF_ApplyHealthBarBackgroundColor()
            end
        end,
        onReset = function()
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.healthBarBGColorR = 0
            MattMinimalFramesDB.healthBarBGColorG = 0
            MattMinimalFramesDB.healthBarBGColorB = 0
            if MMF_ApplyHealthBarBackgroundColor then
                MMF_ApplyHealthBarBackgroundColor()
            end
        end,
    })

    CreateMinimalSlider(unitFramesCol, "Health BG Alpha", RIGHT_COL_X, healthBGAlphaY, RIGHT_COL_WIDTH, "healthBarBGAlpha", 0.0, 1.0, 0.05, 0.65, function(value)
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB.healthBarBGAlpha = value
        if MMF_ApplyHealthBarBackgroundColor then
            MMF_ApplyHealthBarBackgroundColor()
        end
    end, false)

    rightSection.healthBGDividerBottom = unitFramesCol:CreateTexture(nil, "ARTWORK")
    rightSection.healthBGDividerBottom:SetSize(RIGHT_COL_WIDTH, 1)
    rightSection.healthBGDividerBottom:SetPoint("TOPLEFT", RIGHT_COL_X, frameColorsDividerUnderHealthBGAlphaY)
    rightSection.healthBGDividerBottom:SetColorTexture(0.42, 0.42, 0.46, 1)

    rightSection.healthBarBorderColorPicker = MMF_CreateMinimalColorPicker(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = healthBorderY,
        width = RIGHT_COL_WIDTH,
        height = 16,
        labelWidth = PLAYER_BAR_LABEL_WIDTH,
        buttonOffset = PLAYER_BAR_BUTTON_OFFSET,
        buttonWidth = PLAYER_BAR_BUTTON_WIDTH,
        label = "Frame Border",
        resetLabel = "Reset",
        getColor = function()
            return ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBorderColorR, 0),
                ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBorderColorG, 0),
                ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBorderColorB, 0)
        end,
        onColorChanged = function(r, g, b)
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.healthBarBorderColorR = ClampColorChannel(r, 0)
            MattMinimalFramesDB.healthBarBorderColorG = ClampColorChannel(g, 0)
            MattMinimalFramesDB.healthBarBorderColorB = ClampColorChannel(b, 0)
            if MMF_ApplyHealthBarBorderStyle then
                MMF_ApplyHealthBarBorderStyle()
            end
        end,
        onReset = function()
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.healthBarBorderColorR = 0
            MattMinimalFramesDB.healthBarBorderColorG = 0
            MattMinimalFramesDB.healthBarBorderColorB = 0
            if MMF_ApplyHealthBarBorderStyle then
                MMF_ApplyHealthBarBorderStyle()
            end
        end,
    })

    CreateMinimalSlider(unitFramesCol, "Border Width", RIGHT_COL_X, borderWidthY, RIGHT_COL_WIDTH, "healthBarBorderSize", 0, 3, 1, 1, function(value)
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB.healthBarBorderSize = math.floor((tonumber(value) or 1) + 0.5)
        if MMF_ApplyHealthBarBorderStyle then
            MMF_ApplyHealthBarBorderStyle()
        end
    end, true)

    CreateMinimalSlider(unitFramesCol, "Border Alpha", RIGHT_COL_X, borderAlphaY, RIGHT_COL_WIDTH, "healthBarBorderAlpha", 0.0, 1.0, 0.05, 1.0, function(value)
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB.healthBarBorderAlpha = value
        if MMF_ApplyHealthBarBorderStyle then
            MMF_ApplyHealthBarBorderStyle()
        end
    end, false)

    local playerBarColorOptions = (MMF_Config and MMF_Config.PLAYER_BAR_COLORS) or {
        { value = "class", label = "Class (Default)" },
        { value = "green", label = "Green", r = 0.20, g = 0.80, b = 0.20 },
        { value = "white", label = "White", r = 1.00, g = 1.00, b = 1.00 },
        { value = "gray",  label = "Gray",  r = 0.60, g = 0.60, b = 0.60 },
        { value = "red",   label = "Red",   r = 0.90, g = 0.20, b = 0.20 },
        { value = "blue",  label = "Blue",  r = 0.20, g = 0.45, b = 0.95 },
    }

    local targetBarColorOptions = (MMF_Config and MMF_Config.TARGET_BAR_COLORS) or {
        { value = "default", label = "Default" },
        { value = "green", label = "Green", r = 0.20, g = 0.80, b = 0.20 },
        { value = "white", label = "White", r = 1.00, g = 1.00, b = 1.00 },
        { value = "gray", label = "Gray", r = 0.60, g = 0.60, b = 0.60 },
        { value = "red", label = "Red", r = 0.90, g = 0.20, b = 0.20 },
        { value = "blue", label = "Blue", r = 0.20, g = 0.45, b = 0.95 },
    }

    local function GetOptionColor(options, mode)
        if type(options) ~= "table" then return nil end
        for _, option in ipairs(options) do
            if option and option.value == mode and option.r and option.g and option.b then
                return ClampColorChannel(option.r, 1), ClampColorChannel(option.g, 1), ClampColorChannel(option.b, 1)
            end
        end
        return nil
    end

    local function RequestFrameColorRefresh(unit)
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
            return
        end
        if not MMF_UpdateUnitFrame then
            return
        end
        if unit == "player" and MMF_PlayerFrame then
            MMF_UpdateUnitFrame(MMF_PlayerFrame)
        elseif unit == "target" and MMF_TargetFrame then
            MMF_UpdateUnitFrame(MMF_TargetFrame)
        elseif unit == "targettarget" and MMF_TargetOfTargetFrame then
            MMF_UpdateUnitFrame(MMF_TargetOfTargetFrame)
        elseif unit == "focus" and MMF_FocusFrame then
            MMF_UpdateUnitFrame(MMF_FocusFrame)
        elseif unit == "pet" and MMF_PetFrame then
            MMF_UpdateUnitFrame(MMF_PetFrame)
        end
    end

    local function GetPlayerClassColor()
        local _, classToken = UnitClass("player")
        if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
            local c = RAID_CLASS_COLORS[classToken]
            return ClampColorChannel(c.r, 1), ClampColorChannel(c.g, 1), ClampColorChannel(c.b, 1)
        end
        return 1, 1, 1
    end

    local function GetCustomColor(baseKey, fallbackR, fallbackG, fallbackB)
        return ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB[baseKey .. "R"], fallbackR),
            ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB[baseKey .. "G"], fallbackG),
            ClampColorChannel(MattMinimalFramesDB and MattMinimalFramesDB[baseKey .. "B"], fallbackB)
    end

    local function SetCustomColor(baseKey, r, g, b)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        MattMinimalFramesDB[baseKey .. "R"] = ClampColorChannel(r, 1)
        MattMinimalFramesDB[baseKey .. "G"] = ClampColorChannel(g, 1)
        MattMinimalFramesDB[baseKey .. "B"] = ClampColorChannel(b, 1)
    end

    local FRAME_COLOR_PICKER_HEIGHT = 16

    rightSection.playerFrameColorPicker = MMF_CreateMinimalColorPicker(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = frameColorRowsStartY,
        width = RIGHT_COL_WIDTH,
        height = FRAME_COLOR_PICKER_HEIGHT,
        labelWidth = PLAYER_BAR_LABEL_WIDTH,
        buttonOffset = PLAYER_BAR_BUTTON_OFFSET,
        buttonWidth = PLAYER_BAR_BUTTON_WIDTH,
        label = "Player Frame Color",
        resetLabel = "Class",
        getColor = function()
            local mode = NormalizeSelectionValue(MattMinimalFramesDB and MattMinimalFramesDB.playerBarColorMode, "class"):lower()
            if mode == "custom" then
                return GetCustomColor("playerBarCustomColor", 1, 1, 1)
            end
            local or_, og, ob = GetOptionColor(playerBarColorOptions, mode)
            if or_ and og and ob then
                return or_, og, ob
            end
            return GetPlayerClassColor()
        end,
        onColorChanged = function(r, g, b)
            SetCustomColor("playerBarCustomColor", r, g, b)
            MattMinimalFramesDB.playerBarColorMode = "custom"
            RequestFrameColorRefresh("player")
        end,
        onReset = function()
            MattMinimalFramesDB.playerBarColorMode = "class"
            RequestFrameColorRefresh("player")
        end,
    })

    rightSection.targetFrameColorPicker = MMF_CreateMinimalColorPicker(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = frameColorRowsStartY - frameColorRowSpacing,
        width = RIGHT_COL_WIDTH,
        height = FRAME_COLOR_PICKER_HEIGHT,
        labelWidth = PLAYER_BAR_LABEL_WIDTH,
        buttonOffset = PLAYER_BAR_BUTTON_OFFSET,
        buttonWidth = PLAYER_BAR_BUTTON_WIDTH,
        label = "Target Frame Color",
        resetLabel = "Default",
        getColor = function()
            local mode = NormalizeSelectionValue(MattMinimalFramesDB and MattMinimalFramesDB.targetBarColorMode, "default"):lower()
            if mode == "custom" then
                return GetCustomColor("targetBarCustomColor", 0.8, 0.2, 0.2)
            end
            local or_, og, ob = GetOptionColor(targetBarColorOptions, mode)
            if or_ and og and ob then
                return or_, og, ob
            end
            if MMF_GetUnitColor then
                local r, g, b = MMF_GetUnitColor("target")
                return ClampColorChannel(r, 0.8), ClampColorChannel(g, 0.2), ClampColorChannel(b, 0.2)
            end
            return 0.8, 0.2, 0.2
        end,
        onColorChanged = function(r, g, b)
            SetCustomColor("targetBarCustomColor", r, g, b)
            MattMinimalFramesDB.targetBarColorMode = "custom"
            RequestFrameColorRefresh("target")
        end,
        onReset = function()
            MattMinimalFramesDB.targetBarColorMode = "default"
            RequestFrameColorRefresh("target")
        end,
    })

    rightSection.totFrameColorPicker = MMF_CreateMinimalColorPicker(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = frameColorRowsStartY - (frameColorRowSpacing * 2),
        width = RIGHT_COL_WIDTH,
        height = FRAME_COLOR_PICKER_HEIGHT,
        labelWidth = PLAYER_BAR_LABEL_WIDTH,
        buttonOffset = PLAYER_BAR_BUTTON_OFFSET,
        buttonWidth = PLAYER_BAR_BUTTON_WIDTH,
        label = "ToT Frame Color",
        resetLabel = "Default",
        getColor = function()
            local mode = NormalizeSelectionValue(MattMinimalFramesDB and MattMinimalFramesDB.totBarColorMode, "default"):lower()
            if mode == "custom" then
                return GetCustomColor("totBarCustomColor", 0.8, 0.2, 0.2)
            end
            local or_, og, ob = GetOptionColor(targetBarColorOptions, mode)
            if or_ and og and ob then
                return or_, og, ob
            end
            if MMF_GetUnitColor then
                local r, g, b = MMF_GetUnitColor("targettarget")
                return ClampColorChannel(r, 0.8), ClampColorChannel(g, 0.2), ClampColorChannel(b, 0.2)
            end
            return 0.8, 0.2, 0.2
        end,
        onColorChanged = function(r, g, b)
            SetCustomColor("totBarCustomColor", r, g, b)
            MattMinimalFramesDB.totBarColorMode = "custom"
            RequestFrameColorRefresh("targettarget")
        end,
        onReset = function()
            MattMinimalFramesDB.totBarColorMode = "default"
            RequestFrameColorRefresh("targettarget")
        end,
    })

    rightSection.focusFrameColorPicker = MMF_CreateMinimalColorPicker(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = frameColorRowsStartY - (frameColorRowSpacing * 3),
        width = RIGHT_COL_WIDTH,
        height = FRAME_COLOR_PICKER_HEIGHT,
        labelWidth = PLAYER_BAR_LABEL_WIDTH,
        buttonOffset = PLAYER_BAR_BUTTON_OFFSET,
        buttonWidth = PLAYER_BAR_BUTTON_WIDTH,
        label = "Focus Frame Color",
        resetLabel = "Default",
        getColor = function()
            local mode = NormalizeSelectionValue(MattMinimalFramesDB and MattMinimalFramesDB.focusBarColorMode, "default"):lower()
            if mode == "custom" then
                return GetCustomColor("focusBarCustomColor", 0.8, 0.2, 0.2)
            end
            local or_, og, ob = GetOptionColor(targetBarColorOptions, mode)
            if or_ and og and ob then
                return or_, og, ob
            end
            if MMF_GetUnitColor then
                local r, g, b = MMF_GetUnitColor("focus")
                return ClampColorChannel(r, 0.8), ClampColorChannel(g, 0.2), ClampColorChannel(b, 0.2)
            end
            return 0.8, 0.2, 0.2
        end,
        onColorChanged = function(r, g, b)
            SetCustomColor("focusBarCustomColor", r, g, b)
            MattMinimalFramesDB.focusBarColorMode = "custom"
            RequestFrameColorRefresh("focus")
        end,
        onReset = function()
            MattMinimalFramesDB.focusBarColorMode = "default"
            RequestFrameColorRefresh("focus")
        end,
    })

    rightSection.petFrameColorPicker = MMF_CreateMinimalColorPicker(unitFramesCol, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = frameColorRowsStartY - (frameColorRowSpacing * 4),
        width = RIGHT_COL_WIDTH,
        height = FRAME_COLOR_PICKER_HEIGHT,
        labelWidth = PLAYER_BAR_LABEL_WIDTH,
        buttonOffset = PLAYER_BAR_BUTTON_OFFSET,
        buttonWidth = PLAYER_BAR_BUTTON_WIDTH,
        label = "Pet Frame Color",
        resetLabel = "Default",
        getColor = function()
            local mode = NormalizeSelectionValue(MattMinimalFramesDB and MattMinimalFramesDB.petBarColorMode, "default"):lower()
            if mode == "custom" then
                return GetCustomColor("petBarCustomColor", 0.2, 0.8, 0.2)
            end
            local or_, og, ob = GetOptionColor(targetBarColorOptions, mode)
            if or_ and og and ob then
                return or_, og, ob
            end
            if MMF_GetUnitColor then
                local r, g, b = MMF_GetUnitColor("pet")
                return ClampColorChannel(r, 0.2), ClampColorChannel(g, 0.8), ClampColorChannel(b, 0.2)
            end
            return 0.2, 0.8, 0.2
        end,
        onColorChanged = function(r, g, b)
            SetCustomColor("petBarCustomColor", r, g, b)
            MattMinimalFramesDB.petBarColorMode = "custom"
            RequestFrameColorRefresh("pet")
        end,
        onReset = function()
            MattMinimalFramesDB.petBarColorMode = "default"
            RequestFrameColorRefresh("pet")
        end,
    })
end

