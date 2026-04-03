function MMF_BuildUnitFramesCastBarsSection(ctx)
    local unitFramesCol = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local CreateMinimalSlider = ctx.createMinimalSlider or MMF_CreateMinimalSlider
    local CreateMinimalColorPicker = ctx.createMinimalColorPicker or MMF_CreateMinimalColorPicker
    local dropdownLists = ctx.dropdownLists

    local MIDDLE_COL_X = ctx.middleColX
    local MIDDLE_COL_WIDTH = ctx.middleColWidth
    local MIDDLE_LABEL_WIDTH = ctx.middleLabelWidth
    local MIDDLE_BUTTON_OFFSET = ctx.middleButtonOffset
    local MIDDLE_BUTTON_WIDTH = ctx.middleButtonWidth
    local RIGHT_COL_Y_OFFSET = ctx.rightColYOffset

    local function RefreshCastBars()
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
            return
        end
        if MMF_GetAllFrames and MMF_UpdateUnitFrame then
            for _, frame in ipairs(MMF_GetAllFrames()) do
                if frame and (frame.unit == "player" or frame.unit == "target" or frame.unit == "focus") then
                    MMF_UpdateUnitFrame(frame)
                end
            end
        end
    end

    local castBarsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    castBarsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    castBarsTitle:SetPoint("TOPLEFT", MIDDLE_COL_X, -140 + RIGHT_COL_Y_OFFSET)
    castBarsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    castBarsTitle:SetText("CAST BARS")

    CreateMinimalCheckbox(unitFramesCol, "Player Cast Bar", MIDDLE_COL_X, -164 + RIGHT_COL_Y_OFFSET, "showPlayerCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    CreateMinimalCheckbox(unitFramesCol, "Target Cast Bar", MIDDLE_COL_X, -188 + RIGHT_COL_Y_OFFSET, "showTargetCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    CreateMinimalCheckbox(unitFramesCol, "Focus Cast Bar", MIDDLE_COL_X, -212 + RIGHT_COL_Y_OFFSET, "showFocusCastBar", true, function()
        StaticPopup_Show("MMF_RELOADUI")
    end)

    CreateMinimalCheckbox(unitFramesCol, "Hide Blizzard Cast Bar", MIDDLE_COL_X, -236 + RIGHT_COL_Y_OFFSET, "hideBlizzardPlayerCastBar", false, function()
        if MMF_UpdateBlizzardPlayerCastBarVisibility then
            MMF_UpdateBlizzardPlayerCastBarVisibility()
        end
        StaticPopup_Show("MMF_RELOADUI")
    end)

    if CreateMinimalColorPicker then
        CreateMinimalColorPicker(unitFramesCol, {
            accentColor = ACCENT_COLOR,
            x = MIDDLE_COL_X,
            y = -260 + RIGHT_COL_Y_OFFSET,
            width = MIDDLE_COL_WIDTH,
            height = 24,
            labelWidth = MIDDLE_LABEL_WIDTH,
            buttonOffset = MIDDLE_BUTTON_OFFSET,
            buttonWidth = MIDDLE_BUTTON_WIDTH,
            label = "Cast Bar Color",
            resetLabel = "RESET",
            getColor = function()
                local key = (MattMinimalFramesDB and MattMinimalFramesDB.castBarColor)
                    or (MattMinimalFrames_Defaults and MattMinimalFrames_Defaults.castBarColor)
                    or "yellow"
                local r, g, b = MMF_Config.GetCastBarColor(key)
                return r, g, b
            end,
            onColorChanged = function(r, g, b)
                if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
                MattMinimalFramesDB.castBarColor = "custom"
                MattMinimalFramesDB.castBarCustomColorR = r
                MattMinimalFramesDB.castBarCustomColorG = g
                MattMinimalFramesDB.castBarCustomColorB = b
                RefreshCastBars()
            end,
            onReset = function()
                if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
                local d = MattMinimalFrames_Defaults or {}
                MattMinimalFramesDB.castBarColor = d.castBarColor or "yellow"
                MattMinimalFramesDB.castBarCustomColorR = d.castBarCustomColorR or 1.0
                MattMinimalFramesDB.castBarCustomColorG = d.castBarCustomColorG or 1.0
                MattMinimalFramesDB.castBarCustomColorB = d.castBarCustomColorB or 0.0
                RefreshCastBars()
            end,
            isDefault = function()
                local db = MattMinimalFramesDB or {}
                local d = MattMinimalFrames_Defaults or {}
                local function NearlyEqual(a, b)
                    return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) < 0.0001
                end
                return (db.castBarColor or d.castBarColor or "yellow") == (d.castBarColor or "yellow")
                    and NearlyEqual(db.castBarCustomColorR or d.castBarCustomColorR or 1.0, d.castBarCustomColorR or 1.0)
                    and NearlyEqual(db.castBarCustomColorG or d.castBarCustomColorG or 1.0, d.castBarCustomColorG or 1.0)
                    and NearlyEqual(db.castBarCustomColorB or d.castBarCustomColorB or 0.0, d.castBarCustomColorB or 0.0)
            end,
        })
    end

    local offsetsDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    offsetsDivider:SetSize(MIDDLE_COL_WIDTH, 1)
    offsetsDivider:SetPoint("TOPLEFT", MIDDLE_COL_X, -292 + RIGHT_COL_Y_OFFSET)
    offsetsDivider:SetColorTexture(0.42, 0.42, 0.46, 1)

    local castBarOffsetsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    castBarOffsetsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    castBarOffsetsTitle:SetPoint("TOPLEFT", MIDDLE_COL_X, -308 + RIGHT_COL_Y_OFFSET)
    castBarOffsetsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    castBarOffsetsTitle:SetText("CAST BAR OFFSETS")

    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local castBarOffsetUnitOptions = {
        { value = "player", label = "Player Cast Bar" },
        { value = "target", label = "Target Cast Bar" },
        { value = "focus", label = "Focus Cast Bar" },
    }

    local function IsValidCastBarOffsetUnit(unit)
        return unit == "player" or unit == "target" or unit == "focus"
    end

    if not IsValidCastBarOffsetUnit(MattMinimalFramesDB.castBarOffsetUnit) then
        MattMinimalFramesDB.castBarOffsetUnit = "player"
    end

    local function GetSelectedCastBarOffsetUnit()
        if not IsValidCastBarOffsetUnit(MattMinimalFramesDB.castBarOffsetUnit) then
            MattMinimalFramesDB.castBarOffsetUnit = "player"
        end
        return MattMinimalFramesDB.castBarOffsetUnit
    end

    local function GetFallbackDefaultOffset(unit)
        if unit == "focus" then
            return 0, -19
        end
        return 0, -9
    end

    local function GetCastBarOffset(unit)
        if MMF_GetCastBarOffsetForUnit then
            local x, y = MMF_GetCastBarOffsetForUnit(unit)
            if x ~= nil and y ~= nil then
                return tonumber(x) or 0, tonumber(y) or 0
            end
        end

        local dbPos = MattMinimalFramesDB and MattMinimalFramesDB.castBarPositions and MattMinimalFramesDB.castBarPositions[unit]
        local x = dbPos and tonumber(dbPos.x) or nil
        local y = dbPos and tonumber(dbPos.y) or nil
        if x ~= nil and y ~= nil then
            return x, y
        end

        if MMF_GetCastBarDefaultOffsetForUnit then
            local xDefault, yDefault = MMF_GetCastBarDefaultOffsetForUnit(unit)
            return tonumber(xDefault) or 0, tonumber(yDefault) or 0
        end

        return GetFallbackDefaultOffset(unit)
    end

    local function SetCastBarOffset(unit, x, y)
        if MMF_SetCastBarOffsetForUnit then
            MMF_SetCastBarOffsetForUnit(unit, x, y)
            return
        end

        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        if not MattMinimalFramesDB.castBarPositions then
            MattMinimalFramesDB.castBarPositions = {}
        end
        MattMinimalFramesDB.castBarPositions[unit] = { x = tonumber(x) or 0, y = tonumber(y) or 0 }

        local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit)
        if frame and frame.castBarFrame and MMF_ApplyCastBarPosition then
            MMF_ApplyCastBarPosition(frame, unit)
        end
    end

    local function ResetCastBarOffset(unit)
        if MMF_ResetCastBarOffsetForUnit then
            MMF_ResetCastBarOffsetForUnit(unit)
            return
        end

        if MattMinimalFramesDB and MattMinimalFramesDB.castBarPositions then
            MattMinimalFramesDB.castBarPositions[unit] = nil
        end

        local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit)
        if frame and frame.castBarFrame and MMF_ApplyCastBarPosition then
            MMF_ApplyCastBarPosition(frame, unit)
        end
    end

    local syncingCastBarOffsets = false
    local castBarOffsetXSlider
    local castBarOffsetYSlider
    local castBarResetPositionButtonText
    local SyncCastBarOffsetSliders = function() end

    local function GetSelectedCastBarOffsetLabel()
        local selectedUnit = GetSelectedCastBarOffsetUnit()
        for _, option in ipairs(castBarOffsetUnitOptions) do
            if option.value == selectedUnit then
                return option.label
            end
        end
        return "Selected Cast Bar"
    end

    local function UpdateCastBarResetButtonLabel()
        if castBarResetPositionButtonText then
            castBarResetPositionButtonText:SetText("Reset " .. GetSelectedCastBarOffsetLabel() .. " Position")
        end
    end

    local castBarOffsetUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        settingKey = "castBarOffsetUnit",
        x = MIDDLE_COL_X,
        y = -332 + RIGHT_COL_Y_OFFSET,
        width = MIDDLE_COL_WIDTH,
        labelWidth = MIDDLE_LABEL_WIDTH,
        buttonOffset = MIDDLE_BUTTON_OFFSET,
        buttonWidth = MIDDLE_BUTTON_WIDTH,
        visibleRows = #castBarOffsetUnitOptions,
        label = "Offset Unit",
        options = castBarOffsetUnitOptions,
        getValue = function()
            return GetSelectedCastBarOffsetUnit()
        end,
        onSelect = function(value)
            MattMinimalFramesDB.castBarOffsetUnit = value
            UpdateCastBarResetButtonLabel()
            SyncCastBarOffsetSliders()
        end,
    })

    if dropdownLists then
        dropdownLists.castBarOffsetUnitList = castBarOffsetUnitDropdown.list
    end

    castBarOffsetXSlider = CreateMinimalSlider(
        unitFramesCol,
        "X Offset",
        MIDDLE_COL_X,
        -356 + RIGHT_COL_Y_OFFSET,
        MIDDLE_COL_WIDTH,
        "__tempCastBarOffsetX",
        -300,
        300,
        1,
        0,
        function(value)
            if syncingCastBarOffsets then
                return
            end
            local unit = GetSelectedCastBarOffsetUnit()
            local currentX, currentY = GetCastBarOffset(unit)
            if math.abs((tonumber(value) or 0) - (tonumber(currentX) or 0)) < 0.0001 then
                return
            end
            SetCastBarOffset(unit, value, currentY)
        end,
        true
    )

    castBarOffsetYSlider = CreateMinimalSlider(
        unitFramesCol,
        "Y Offset",
        MIDDLE_COL_X,
        -380 + RIGHT_COL_Y_OFFSET,
        MIDDLE_COL_WIDTH,
        "__tempCastBarOffsetY",
        -300,
        300,
        1,
        -9,
        function(value)
            if syncingCastBarOffsets then
                return
            end
            local unit = GetSelectedCastBarOffsetUnit()
            local currentX, currentY = GetCastBarOffset(unit)
            if math.abs((tonumber(value) or 0) - (tonumber(currentY) or 0)) < 0.0001 then
                return
            end
            SetCastBarOffset(unit, currentX, value)
        end,
        true
    )

    local castBarResetPositionButton = CreateFrame("Button", nil, unitFramesCol, "BackdropTemplate")
    castBarResetPositionButton:SetSize(MIDDLE_COL_WIDTH, 20)
    castBarResetPositionButton:SetPoint("TOPLEFT", MIDDLE_COL_X, -408 + RIGHT_COL_Y_OFFSET)
    castBarResetPositionButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    castBarResetPositionButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
    castBarResetPositionButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    castBarResetPositionButtonText = castBarResetPositionButton:CreateFontString(nil, "OVERLAY")
    castBarResetPositionButtonText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    castBarResetPositionButtonText:SetPoint("CENTER")
    castBarResetPositionButtonText:SetTextColor(0.85, 0.85, 0.85)

    castBarResetPositionButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.6)
        castBarResetPositionButtonText:SetTextColor(1, 1, 1)
    end)
    castBarResetPositionButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        castBarResetPositionButtonText:SetTextColor(0.85, 0.85, 0.85)
    end)
    castBarResetPositionButton:SetScript("OnClick", function()
        local selectedUnit = GetSelectedCastBarOffsetUnit()
        ResetCastBarOffset(selectedUnit)
        SyncCastBarOffsetSliders()
    end)

    SyncCastBarOffsetSliders = function()
        local selectedUnit = GetSelectedCastBarOffsetUnit()
        local xValue, yValue = GetCastBarOffset(selectedUnit)
        syncingCastBarOffsets = true
        if castBarOffsetXSlider and castBarOffsetXSlider.slider then
            castBarOffsetXSlider.slider:SetValue(xValue)
        end
        if castBarOffsetYSlider and castBarOffsetYSlider.slider then
            castBarOffsetYSlider.slider:SetValue(yValue)
        end
        syncingCastBarOffsets = false
        if castBarOffsetXSlider.RefreshResetVisibility then
            castBarOffsetXSlider:RefreshResetVisibility()
        end
        if castBarOffsetYSlider.RefreshResetVisibility then
            castBarOffsetYSlider:RefreshResetVisibility()
        end
        UpdateCastBarResetButtonLabel()
    end

    _G.MMF_CastBarOffsetSliderRegistry = {
        x = castBarOffsetXSlider,
        y = castBarOffsetYSlider,
        getSelectedUnit = function()
            return GetSelectedCastBarOffsetUnit()
        end,
    }

    SyncCastBarOffsetSliders()
    if MMF_SyncCastBarOffsetControlsForUnit then
        MMF_SyncCastBarOffsetControlsForUnit(GetSelectedCastBarOffsetUnit())
    end

    MattMinimalFramesDB.__tempCastBarOffsetX = nil
    MattMinimalFramesDB.__tempCastBarOffsetY = nil
end
