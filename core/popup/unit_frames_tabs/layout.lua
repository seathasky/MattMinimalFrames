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
        scaleXSliders[opt.value] = CreateMinimalSlider(
            unitFramesCol,
            "Scale X",
            LEFT_COL_X,
            -64,
            LEFT_COL_WIDTH,
            prefix .. "FrameScaleX",
            FRAME_SCALE_X_MIN,
            FRAME_SCALE_X_MAX,
            0.05,
            1.0,
            function()
                if MMF_UpdateFrameScale then
                    MMF_UpdateFrameScale(opt.value)
                end
            end,
            false
        )
        scaleYSliders[opt.value] = CreateMinimalSlider(
            unitFramesCol,
            "Scale Y",
            LEFT_COL_X,
            -88,
            LEFT_COL_WIDTH,
            prefix .. "FrameScaleY",
            FRAME_SCALE_Y_MIN,
            FRAME_SCALE_Y_MAX,
            0.05,
            1.0,
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
            scaleYSliders[opt.value]:SetShown(show)
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
        -156,
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
    positionDivider:SetPoint("TOPLEFT", LEFT_COL_X, -192)
    positionDivider:SetColorTexture(0.42, 0.42, 0.46, 1)

    local framePositionTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    framePositionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    framePositionTitle:SetPoint("TOPLEFT", LEFT_COL_X, -208)
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
        local defaultX = GetFrameCenterDefault(opt.value, "x")
        local defaultY = GetFrameCenterDefault(opt.value, "y")

        positionXSliders[opt.value] = CreateMinimalSlider(
            unitFramesCol,
            "Center X",
            LEFT_COL_X,
            -260,
            LEFT_COL_WIDTH,
            xKey,
            -1200,
            1200,
            1,
            defaultX,
            function()
                if MMF_ApplyFrameCenterPositionForUnit then
                    MMF_ApplyFrameCenterPositionForUnit(opt.value, "x")
                end
            end,
            true,
            {
                onReset = function()
                    MattMinimalFramesDB[xKey] = defaultX
                    if MMF_ApplyFrameCenterPositionForUnit then
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
            -284,
            LEFT_COL_WIDTH,
            yKey,
            -1200,
            1200,
            1,
            defaultY,
            function()
                if MMF_ApplyFrameCenterPositionForUnit then
                    MMF_ApplyFrameCenterPositionForUnit(opt.value, "y")
                end
            end,
            true,
            {
                onReset = function()
                    MattMinimalFramesDB[yKey] = defaultY
                    if MMF_ApplyFrameCenterPositionForUnit then
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
        y = -236,
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

    local positionHelp = unitFramesCol:CreateFontString(nil, "OVERLAY")
    positionHelp:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    positionHelp:SetPoint("TOPLEFT", LEFT_COL_X, -310)
    positionHelp:SetTextColor(0.68, 0.74, 0.8)
    positionHelp:SetText("Dragging frames in Edit Mode updates these values live.")

    if MMF_SyncFramePositionControlsForUnit then
        MMF_SyncFramePositionControlsForUnit("player")
        MMF_SyncFramePositionControlsForUnit("target")
        MMF_SyncFramePositionControlsForUnit("targettarget")
        MMF_SyncFramePositionControlsForUnit("pet")
        MMF_SyncFramePositionControlsForUnit("focus")
        MMF_SyncFramePositionControlsForUnit("boss")
    end
end
