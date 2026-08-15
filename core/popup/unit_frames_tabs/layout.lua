function MMF_BuildUnitFramesLayoutSection(ctx)
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

    local function GetPopupUnitPrefix(unit)
        if unit == "targettarget" then return "tot" end
        if unit == "boss" then return "boss" end
        if unit == "playerCastBar" then return "playerCastBar" end
        if unit == "targetCastBar" then return "targetCastBar" end
        if unit == "focusCastBar" then return "focusCastBar" end
        if unit == "petHappinessIcon" then return "petFrameHappiness" end
        return unit
    end

    local scaleUnitOptions = {
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
    local compat = _G.MMF_Compat
    if compat and compat.IsClassicEra then
        table.insert(scaleUnitOptions, 5, { value = "petHappinessIcon", label = "Pet Happiness" })
    end
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

    local frameScaleTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    frameScaleTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    frameScaleTitle:SetPoint("TOPLEFT", LEFT_COL_X, -12)
    frameScaleTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    frameScaleTitle:SetText("FRAME SCALE")

    local FRAME_SCALE_X_MIN = 0.1
    local FRAME_SCALE_X_MAX = 6.0
    local FRAME_SCALE_Y_MIN = 0.1
    local FRAME_SCALE_Y_MAX = 10.0

    local scaleXSliders = {}
    local scaleYSliders = {}
    for _, opt in ipairs(scaleUnitOptions) do
        local prefix = GetPopupUnitPrefix(opt.value)
        local scaleXKey = prefix .. "FrameScaleX"
        local scaleYKey = prefix .. "FrameScaleY"
        local scaleXDefault = 1.0
        local scaleYDefault = 1.0
        local scaleXLabel = "Scale X"
        local scaleYLabel = "Scale Y"
        local scaleXMax = FRAME_SCALE_X_MAX
        local scaleYMax = FRAME_SCALE_Y_MAX
        if opt.value == "petHappinessIcon" then
            scaleXKey = "petFrameHappinessScale"
            scaleYKey = "petFrameHappinessScale"
            scaleXDefault = tonumber(MattMinimalFrames_Defaults and MattMinimalFrames_Defaults.petFrameHappinessScale) or 1.0
            scaleYDefault = scaleXDefault
            scaleXLabel = "Scale"
            scaleXMax = 10.0
            scaleYMax = 10.0
        end
        scaleXSliders[opt.value] = CreateMinimalSlider(
            unitFramesCol,
            scaleXLabel,
            LEFT_COL_X,
            -64,
            LEFT_COL_WIDTH,
            scaleXKey,
            FRAME_SCALE_X_MIN,
            scaleXMax,
            0.05,
            scaleXDefault,
            function()
                if MMF_UpdateFrameScale then
                    MMF_UpdateFrameScale(opt.value)
                end
            end,
            false
        )
        scaleYSliders[opt.value] = CreateMinimalSlider(
            unitFramesCol,
            scaleYLabel,
            LEFT_COL_X,
            -88,
            LEFT_COL_WIDTH,
            scaleYKey,
            FRAME_SCALE_Y_MIN,
            scaleYMax,
            0.05,
            scaleYDefault,
            function()
                if MMF_UpdateFrameScale then
                    MMF_UpdateFrameScale(opt.value)
                end
            end,
            false
        )
        scaleXSliders[opt.value]:Hide()
        scaleYSliders[opt.value]:Hide()
    end

    local bossBottomPaddingSlider = CreateMinimalSlider(
        unitFramesCol,
        "Boss Bottom Padding",
        LEFT_COL_X,
        -112,
        LEFT_COL_WIDTH,
        "bossFrameBottomPadding",
        0,
        64,
        1,
        0,
        function()
            if MMF_UpdateCombatFrameVisibility then
                MMF_UpdateCombatFrameVisibility()
            end
            if MMF_ApplyAllFramePositions then
                MMF_ApplyAllFramePositions()
            end
            if MMF_RequestAllFramesUpdate then
                MMF_RequestAllFramesUpdate()
            end
        end,
        true
    )
    bossBottomPaddingSlider:Hide()

    local function UpdateVisibleScaleSliders()
        local current = MattMinimalFramesDB.frameScaleUnit
        for _, opt in ipairs(scaleUnitOptions) do
            local show = (opt.value == current)
            scaleXSliders[opt.value]:SetShown(show)
            scaleYSliders[opt.value]:SetShown(show and opt.value ~= "petHappinessIcon")
        end
        bossBottomPaddingSlider:SetShown(current == "boss")
    end

    local scaleUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "frameScaleUnit",
        x = LEFT_COL_X,
        y = -40,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
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
    dropdownLists.scaleUnitList = scaleUnitDropdown.list
    UpdateVisibleScaleSliders()

    CreateMinimalCheckbox(
        unitFramesCol,
        "Health Fill Top to Bottom",
        LEFT_COL_X,
        -120,
        "healthFillTopToBottom",
        false,
        function()
            if MMF_ApplyHealthFillDirections then
                MMF_ApplyHealthFillDirections()
            end
            if MMF_RequestAllFramesUpdate then
                MMF_RequestAllFramesUpdate()
            end
        end
    )

    local positionDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    positionDivider:SetSize(LEFT_COL_WIDTH, 1)
    positionDivider:SetPoint("TOPLEFT", LEFT_COL_X, -150)
    positionDivider:SetColorTexture(0.42, 0.42, 0.46, 1)

    local framePositionTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    framePositionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    framePositionTitle:SetPoint("TOPLEFT", LEFT_COL_X, -166)
    framePositionTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    framePositionTitle:SetText("FRAME POSITION (CENTER)")

    local positionUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
        { value = "boss", label = "Boss Group" },
    }
    if compat and compat.IsClassicEra then
        table.insert(positionUnitOptions, 5, { value = "petHappiness", label = "Pet Happiness" })
    end

    MattMinimalFramesDB.framePositionUnit = MattMinimalFramesDB.framePositionUnit or "player"
    local function EnsurePositionUnitSelection()
        local valid = false
        for _, opt in ipairs(positionUnitOptions) do
            if opt.value == MattMinimalFramesDB.framePositionUnit then
                valid = true
                break
            end
        end
        if not valid then
            MattMinimalFramesDB.framePositionUnit = "player"
        end
    end
    EnsurePositionUnitSelection()

    local function GetFrameCenterDefault(unit, axis)
        if unit == "petHappiness" then
            local defaultX, defaultY = 0, 0
            if MMF_GetPetFrameHappinessDefaultCenterOffset then
                defaultX, defaultY = MMF_GetPetFrameHappinessDefaultCenterOffset()
            end
            if axis == "x" then
                return tonumber(defaultX) or 0
            end
            return tonumber(defaultY) or 0
        end
        local lookupUnit = (unit == "boss") and "boss1" or unit
        local def = MMF_GetFrameDefinition and MMF_GetFrameDefinition(lookupUnit)
        if not def then
            return 0
        end
        if axis == "x" then
            return tonumber(def.x) or 0
        end
        return tonumber(def.y) or 0
    end

    local positionXSliders = {}
    local positionYSliders = {}
    _G.MMF_FramePositionSliderRegistry = _G.MMF_FramePositionSliderRegistry or {}

    local function UpdateVisiblePositionSliders()
        local current = MattMinimalFramesDB.framePositionUnit
        for _, opt in ipairs(positionUnitOptions) do
            local show = (opt.value == current)
            positionXSliders[opt.value]:SetShown(show)
            positionYSliders[opt.value]:SetShown(show)
        end
    end

    for _, opt in ipairs(positionUnitOptions) do
        local prefix = GetPopupUnitPrefix(opt.value)
        local xKey = prefix .. "FrameCenterX"
        local yKey = prefix .. "FrameCenterY"
        if opt.value == "petHappiness" then
            xKey = "petHappinessFrameCenterX"
            yKey = "petHappinessFrameCenterY"
            local saved = MattMinimalFramesDB and MattMinimalFramesDB.petFrameHappinessPosition
            if type(saved) == "table" then
                if MattMinimalFramesDB[xKey] == nil and tonumber(saved.x) ~= nil then
                    defaultX = tonumber(saved.x)
                end
                if MattMinimalFramesDB[yKey] == nil and tonumber(saved.y) ~= nil then
                    defaultY = tonumber(saved.y)
                end
            end
        end
        local defaultX = GetFrameCenterDefault(opt.value, "x")
        local defaultY = GetFrameCenterDefault(opt.value, "y")

        positionXSliders[opt.value] = CreateMinimalSlider(
            unitFramesCol,
            "Center X",
            LEFT_COL_X,
            -218,
            LEFT_COL_WIDTH,
            xKey,
            -1200,
            1200,
            1,
            defaultX,
            function()
                if opt.value == "petHappiness" then
                    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
                    MattMinimalFramesDB.petFrameHappinessPosition = {
                        x = tonumber(MattMinimalFramesDB.petHappinessFrameCenterX) or defaultX,
                        y = tonumber(MattMinimalFramesDB.petHappinessFrameCenterY) or defaultY,
                    }
                    if MMF_ApplyPetFrameHappinessPosition then
                        MMF_ApplyPetFrameHappinessPosition()
                    end
                elseif MMF_ApplyFrameCenterPositionForUnit then
                    MMF_ApplyFrameCenterPositionForUnit(opt.value, "x")
                end
            end,
            true,
            {
                onReset = function()
                    MattMinimalFramesDB[xKey] = defaultX
                    if opt.value == "petHappiness" then
                        MattMinimalFramesDB.petFrameHappinessPosition = {
                            x = defaultX,
                            y = tonumber(MattMinimalFramesDB[yKey]) or defaultY,
                        }
                        if MMF_ApplyPetFrameHappinessPosition then
                            MMF_ApplyPetFrameHappinessPosition()
                        end
                    elseif MMF_ApplyFrameCenterPositionForUnit then
                        MMF_ApplyFrameCenterPositionForUnit(opt.value, "x")
                    end
                end,
                isDefault = function()
                    local current = tonumber(MattMinimalFramesDB[xKey])
                    if current == nil then
                        return true
                    end
                    return math.abs(current - defaultX) < 0.0001
                end,
            }
        )

        positionYSliders[opt.value] = CreateMinimalSlider(
            unitFramesCol,
            "Center Y",
            LEFT_COL_X,
            -244,
            LEFT_COL_WIDTH,
            yKey,
            -1200,
            1200,
            1,
            defaultY,
            function()
                if opt.value == "petHappiness" then
                    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
                    MattMinimalFramesDB.petFrameHappinessPosition = {
                        x = tonumber(MattMinimalFramesDB.petHappinessFrameCenterX) or defaultX,
                        y = tonumber(MattMinimalFramesDB.petHappinessFrameCenterY) or defaultY,
                    }
                    if MMF_ApplyPetFrameHappinessPosition then
                        MMF_ApplyPetFrameHappinessPosition()
                    end
                elseif MMF_ApplyFrameCenterPositionForUnit then
                    MMF_ApplyFrameCenterPositionForUnit(opt.value, "y")
                end
            end,
            true,
            {
                onReset = function()
                    MattMinimalFramesDB[yKey] = defaultY
                    if opt.value == "petHappiness" then
                        MattMinimalFramesDB.petFrameHappinessPosition = {
                            x = tonumber(MattMinimalFramesDB[xKey]) or defaultX,
                            y = defaultY,
                        }
                        if MMF_ApplyPetFrameHappinessPosition then
                            MMF_ApplyPetFrameHappinessPosition()
                        end
                    elseif MMF_ApplyFrameCenterPositionForUnit then
                        MMF_ApplyFrameCenterPositionForUnit(opt.value, "y")
                    end
                end,
                isDefault = function()
                    local current = tonumber(MattMinimalFramesDB[yKey])
                    if current == nil then
                        return true
                    end
                    return math.abs(current - defaultY) < 0.0001
                end,
            }
        )

        _G.MMF_FramePositionSliderRegistry[opt.value] = {
            x = positionXSliders[opt.value],
            y = positionYSliders[opt.value],
        }

        positionXSliders[opt.value]:Hide()
        positionYSliders[opt.value]:Hide()
    end

    local positionUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "framePositionUnit",
        x = LEFT_COL_X,
        y = -192,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #positionUnitOptions,
        label = "Position Unit",
        options = positionUnitOptions,
        getValue = function()
            return MattMinimalFramesDB.framePositionUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.framePositionUnit = value
            UpdateVisiblePositionSliders()
        end,
    })
    dropdownLists.framePositionUnitList = positionUnitDropdown.list
    UpdateVisiblePositionSliders()

    if MMF_SyncFramePositionControlsForUnit then
        MMF_SyncFramePositionControlsForUnit("player")
        MMF_SyncFramePositionControlsForUnit("target")
        MMF_SyncFramePositionControlsForUnit("targettarget")
        MMF_SyncFramePositionControlsForUnit("pet")
        MMF_SyncFramePositionControlsForUnit("focus")
        MMF_SyncFramePositionControlsForUnit("boss")
    end
end
