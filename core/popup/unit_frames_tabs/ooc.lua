function MMF_BuildUnitFramesOOCSection(ctx)
    local unitFramesCol = ctx.parent
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local CreateMinimalSlider = ctx.createMinimalSlider

    local MIDDLE_COL_X = ctx.middleColX
    local MIDDLE_COL_WIDTH = ctx.middleColWidth
    local RIGHT_COL_Y_OFFSET = ctx.rightColYOffset
    local RIGHT_COL_X = ctx.rightColX or MIDDLE_COL_X
    local RIGHT_COL_WIDTH = ctx.rightColWidth or MIDDLE_COL_WIDTH
    local standardLayout = ctx.standardLayout == true

    local function IsCheckedFlag(value)
        return value == true or value == 1
    end

    if MattMinimalFramesDB.enableCombatFrameVisibility == nil then
        MattMinimalFramesDB.enableCombatFrameVisibility = false
    end
    if MattMinimalFramesDB.showPlayerOnTargetSelected == nil then
        MattMinimalFramesDB.showPlayerOnTargetSelected = false
    end
    if MattMinimalFramesDB.outOfCombatPlayerOpacity == nil then
        MattMinimalFramesDB.outOfCombatPlayerOpacity = 0.0
    end
    if MattMinimalFramesDB.outOfCombatTargetOpacity == nil then
        MattMinimalFramesDB.outOfCombatTargetOpacity = 0.35
    end
    if MattMinimalFramesDB.combatVisibilityFadeTime == nil then
        MattMinimalFramesDB.combatVisibilityFadeTime = 0.4
    end
    if MattMinimalFramesDB.hideCurrentClassBarOOCNoTarget == nil then
        MattMinimalFramesDB.hideCurrentClassBarOOCNoTarget = false
    end
    if MattMinimalFramesDB.outOfCombatClassBarOpacity == nil then
        MattMinimalFramesDB.outOfCombatClassBarOpacity = 1.0
    end
    if MMF_GetOutOfCombatTargetOpacity then
        MattMinimalFramesDB.outOfCombatTargetOpacity = MMF_GetOutOfCombatTargetOpacity()
    end
    if MMF_GetOutOfCombatPlayerOpacity then
        MattMinimalFramesDB.outOfCombatPlayerOpacity = MMF_GetOutOfCombatPlayerOpacity()
    end
    if MMF_GetCombatVisibilityFadeTime then
        MattMinimalFramesDB.combatVisibilityFadeTime = MMF_GetCombatVisibilityFadeTime()
    end

    local combatVisibilityTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    combatVisibilityTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
    combatVisibilityTitle:SetPoint("TOPLEFT", MIDDLE_COL_X, standardLayout and -12 or (-288 + RIGHT_COL_Y_OFFSET))
    MMF_ApplyUnitFramesHeadingColor(combatVisibilityTitle, "visibility")
    combatVisibilityTitle:SetText("OUT OF COMBAT VISIBILITY")

    local combatVisibilitySubtext = unitFramesCol:CreateFontString(nil, "OVERLAY")
    combatVisibilitySubtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    combatVisibilitySubtext:SetPoint("TOPLEFT", MIDDLE_COL_X, standardLayout and -34 or (-308 + RIGHT_COL_Y_OFFSET))
    combatVisibilitySubtext:SetTextColor(0.65, 0.65, 0.7)
    combatVisibilitySubtext:SetText("OOC visibility options")

    local combatVisibilityWarning = unitFramesCol:CreateFontString(nil, "OVERLAY")
    combatVisibilityWarning:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    combatVisibilityWarning:SetPoint("TOPLEFT", standardLayout and RIGHT_COL_X or MIDDLE_COL_X, standardLayout and -126 or (-320 + RIGHT_COL_Y_OFFSET))
    combatVisibilityWarning:SetTextColor(0.95, 0.25, 0.25)
    combatVisibilityWarning:SetText("Range Check Disabled")
    combatVisibilityWarning:SetShown(IsCheckedFlag(MattMinimalFramesDB.enableCombatFrameVisibility))

    local hidePlayerOOCCheck
    local playerOpacitySlider
    local targetOpacitySlider
    local fadeTimeSlider
    local showPlayerOnTargetCheck
    local hideCurrentClassBarOOCCheck
    local classBarOpacitySlider

    local function SetSliderEnabled(container, enabled)
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

    local function SetCheckboxEnabled(container, enabled)
        if not container then return end
        container:SetAlpha(enabled and 1 or 0.45)
        if container.checkbox then
            container.checkbox:SetEnabled(enabled)
            container.checkbox:EnableMouse(enabled)
        end
    end

    local function RefreshCombatVisibilityControlStates()
        local combatVisibilityEnabled = IsCheckedFlag(MattMinimalFramesDB.enableCombatFrameVisibility)
        local classBarOOCEnabled = IsCheckedFlag(MattMinimalFramesDB.hideCurrentClassBarOOCNoTarget)
        if playerOpacitySlider then
            SetSliderEnabled(playerOpacitySlider, combatVisibilityEnabled)
        end
        if targetOpacitySlider then
            SetSliderEnabled(targetOpacitySlider, combatVisibilityEnabled)
        end
        if fadeTimeSlider then
            SetSliderEnabled(fadeTimeSlider, combatVisibilityEnabled)
        end
        if showPlayerOnTargetCheck then
            SetCheckboxEnabled(showPlayerOnTargetCheck, combatVisibilityEnabled)
        end
        if classBarOpacitySlider then
            SetSliderEnabled(classBarOpacitySlider, classBarOOCEnabled)
        end
        if combatVisibilityWarning then
            combatVisibilityWarning:SetShown(combatVisibilityEnabled)
        end
    end

    if standardLayout then
        local opacityTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
        opacityTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
        opacityTitle:SetPoint("TOPLEFT", RIGHT_COL_X, -12)
        MMF_ApplyUnitFramesHeadingColor(opacityTitle, "visibility")
        opacityTitle:SetText("OUT OF COMBAT OPACITY")
    end

    hidePlayerOOCCheck = CreateMinimalCheckbox(unitFramesCol, "Hide Player OOC", MIDDLE_COL_X, standardLayout and -62 or (-330 + RIGHT_COL_Y_OFFSET), "enableCombatFrameVisibility", false, function()
        RefreshCombatVisibilityControlStates()
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
    end)

    showPlayerOnTargetCheck = CreateMinimalCheckbox(unitFramesCol, "Show Player on Target Select", MIDDLE_COL_X, standardLayout and -90 or (-358 + RIGHT_COL_Y_OFFSET), "showPlayerOnTargetSelected", false, function()
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
    end)

    hideCurrentClassBarOOCCheck = CreateMinimalCheckbox(unitFramesCol, "Hide Current Class Bar OOC (No Target)", MIDDLE_COL_X, standardLayout and -118 or (-386 + RIGHT_COL_Y_OFFSET), "hideCurrentClassBarOOCNoTarget", false, function()
        RefreshCombatVisibilityControlStates()
        if MMF_RefreshClassResourceVisibility then
            MMF_RefreshClassResourceVisibility()
        end
    end)

    classBarOpacitySlider = CreateMinimalSlider(unitFramesCol, "Class Bar OOC Opacity", MIDDLE_COL_X, standardLayout and -146 or (-430 + RIGHT_COL_Y_OFFSET), MIDDLE_COL_WIDTH, "outOfCombatClassBarOpacity", 0.0, 1.0, 0.05, 1.0, function(value)
        MattMinimalFramesDB.outOfCombatClassBarOpacity = value
        if MMF_RefreshClassResourceVisibility then
            MMF_RefreshClassResourceVisibility()
        end
    end, false)

    playerOpacitySlider = CreateMinimalSlider(unitFramesCol, "Player OOC Opacity", standardLayout and RIGHT_COL_X or MIDDLE_COL_X, standardLayout and -42 or (-456 + RIGHT_COL_Y_OFFSET), standardLayout and RIGHT_COL_WIDTH or MIDDLE_COL_WIDTH, "outOfCombatPlayerOpacity", 0.0, 1.0, 0.05, 0.0, function(value)
        MattMinimalFramesDB.outOfCombatPlayerOpacity = value
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
    end, false)

    targetOpacitySlider = CreateMinimalSlider(unitFramesCol, "Target/TOT OOC Opacity", standardLayout and RIGHT_COL_X or MIDDLE_COL_X, standardLayout and -70 or (-482 + RIGHT_COL_Y_OFFSET), standardLayout and RIGHT_COL_WIDTH or MIDDLE_COL_WIDTH, "outOfCombatTargetOpacity", 0.0, 1.0, 0.05, 0.35, function(value)
        MattMinimalFramesDB.outOfCombatTargetOpacity = value
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
    end, false)

    fadeTimeSlider = CreateMinimalSlider(unitFramesCol, "OOC Fade Time", standardLayout and RIGHT_COL_X or MIDDLE_COL_X, standardLayout and -98 or (-508 + RIGHT_COL_Y_OFFSET), standardLayout and RIGHT_COL_WIDTH or MIDDLE_COL_WIDTH, "combatVisibilityFadeTime", 0.0, 2.0, 0.05, 0.4, function(value)
        MattMinimalFramesDB.combatVisibilityFadeTime = value
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
    end, false)

    RefreshCombatVisibilityControlStates()
end

