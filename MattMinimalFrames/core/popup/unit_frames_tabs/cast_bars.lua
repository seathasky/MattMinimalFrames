function MMF_BuildUnitFramesCastBarsSection(ctx)
    local unitFramesCol = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local dropdownLists = ctx.dropdownLists

    local MIDDLE_COL_X = ctx.middleColX
    local MIDDLE_COL_WIDTH = ctx.middleColWidth
    local MIDDLE_LABEL_WIDTH = ctx.middleLabelWidth
    local MIDDLE_BUTTON_OFFSET = ctx.middleButtonOffset
    local MIDDLE_BUTTON_WIDTH = ctx.middleButtonWidth
    local RIGHT_COL_Y_OFFSET = ctx.rightColYOffset

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

    local castBarColorDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = MIDDLE_COL_X,
        y = -260 + RIGHT_COL_Y_OFFSET,
        width = MIDDLE_COL_WIDTH,
        labelWidth = MIDDLE_LABEL_WIDTH,
        buttonOffset = MIDDLE_BUTTON_OFFSET,
        buttonWidth = MIDDLE_BUTTON_WIDTH,
        visibleRows = #MMF_Config.CAST_BAR_COLORS,
        label = "Cast Bar Color",
        options = MMF_Config.CAST_BAR_COLORS,
        getValue = function()
            return (MattMinimalFramesDB and MattMinimalFramesDB.castBarColor) or "yellow"
        end,
        onSelect = function(value)
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.castBarColor = value
            StaticPopup_Show("MMF_RELOADUI")
        end,
    })
    dropdownLists.castBarColorList = castBarColorDropdown.list
end

