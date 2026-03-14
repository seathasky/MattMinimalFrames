function MMF_BuildAurasPowerPowerSection(ctx)
    local root = ctx.parent
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local CreateMinimalSlider = ctx.createMinimalSlider
    local RESOURCE_COL_X = ctx.resourceColX
    local isPlayerDruid = ctx.isPlayerDruid
    local RefreshPowerFrames = ctx.refreshPowerFrames or function() end

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
    local playerPercentPowerTextCheck = nil
    local playerDruidManaPowerTextCheck = nil
    local targetPercentPowerTextCheck = nil

    if MattMinimalFramesDB.showPlayerPowerPercentText == nil then
        MattMinimalFramesDB.showPlayerPowerPercentText = (MattMinimalFramesDB.showPowerPercentText == true)
    end
    if MattMinimalFramesDB.showTargetPowerPercentText == nil then
        MattMinimalFramesDB.showTargetPowerPercentText = (MattMinimalFramesDB.showPowerPercentText == true)
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

    local function UpdatePowerTextDependencies()
        local playerTextEnabled = (MattMinimalFramesDB.showPlayerPowerText == true or MattMinimalFramesDB.showPlayerPowerText == 1)
        local targetTextEnabled = (MattMinimalFramesDB.showTargetPowerText == true or MattMinimalFramesDB.showTargetPowerText == 1)
        SetDependentCheckboxState(playerColorPowerTextCheck, playerTextEnabled)
        SetDependentCheckboxState(playerPercentPowerTextCheck, playerTextEnabled)
        SetDependentCheckboxState(playerDruidManaPowerTextCheck, playerTextEnabled and isPlayerDruid)
        SetDependentCheckboxState(targetColorPowerTextCheck, targetTextEnabled)
        SetDependentCheckboxState(targetPercentPowerTextCheck, targetTextEnabled)
    end
    MMF_RefreshPowerTextOptionStates = UpdatePowerTextDependencies

    CreateMinimalCheckbox(root, "Power Bar", RESOURCE_COL_X, -72, "showPlayerPowerBar", true, function()
        RefreshPowerFrames()
    end)

    CreateMinimalCheckbox(root, "Power Text", RESOURCE_COL_X, -96, "showPlayerPowerText", false, function()
        RefreshPowerFrames()
        UpdatePowerTextDependencies()
    end)

    playerColorPowerTextCheck = CreateMinimalCheckbox(root, "Color Text by Resource", RESOURCE_COL_X, -120, "colorPlayerPowerTextByResource", false, function()
        RefreshPowerFrames()
    end)

    playerPercentPowerTextCheck = CreateMinimalCheckbox(root, "Power Text: Percent", RESOURCE_COL_X, -144, "showPlayerPowerPercentText", false, function()
        RefreshPowerFrames()
    end)

    local playerTextScaleY = -168
    local playerWidthY = -192
    local playerHeightY = -216
    local targetDividerY = -244
    local targetTitleY = -256
    local targetPowerBarY = -276
    local targetPowerTextY = -300
    local targetColorTextY = -324
    local targetPercentTextY = -348
    local targetTextScaleY = -372
    local targetWidthY = -396
    local targetHeightY = -420

    if isPlayerDruid then
        playerDruidManaPowerTextCheck = CreateMinimalCheckbox(root, "Mana Resource Only", RESOURCE_COL_X, -168, "showDruidManaPowerText", false, function()
            RefreshPowerFrames()
        end)
        playerTextScaleY = -192
        playerWidthY = -216
        playerHeightY = -240
        targetDividerY = -268
        targetTitleY = -280
        targetPowerBarY = -300
        targetPowerTextY = -324
        targetColorTextY = -348
        targetPercentTextY = -372
        targetTextScaleY = -396
        targetWidthY = -420
        targetHeightY = -444
    end

    CreateMinimalSlider(root, "Text Scale", RESOURCE_COL_X, playerTextScaleY, 200, "playerPowerTextScale", 0.5, 2.0, 0.05, 1.0, function()
        RefreshPowerFrames()
    end, false)

    CreateMinimalSlider(root, "Width", RESOURCE_COL_X, playerWidthY, 200, "playerPowerBarWidth", 30, 250, 1, 73, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.playerPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5, "player")
        end
    end, true)

    CreateMinimalSlider(root, "Height", RESOURCE_COL_X, playerHeightY, 200, "playerPowerBarHeight", 3, 15, 1, 5, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.playerPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73, value, "player")
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

    CreateMinimalCheckbox(root, "Power Bar", RESOURCE_COL_X, targetPowerBarY, "showTargetPowerBar", false, function()
        RefreshPowerFrames()
    end)

    CreateMinimalCheckbox(root, "Power Text", RESOURCE_COL_X, targetPowerTextY, "showTargetPowerText", false, function()
        RefreshPowerFrames()
        UpdatePowerTextDependencies()
    end)

    targetColorPowerTextCheck = CreateMinimalCheckbox(root, "Color Text by Resource", RESOURCE_COL_X, targetColorTextY, "colorTargetPowerTextByResource", false, function()
        RefreshPowerFrames()
    end)
    targetPercentPowerTextCheck = CreateMinimalCheckbox(root, "Power Text: Percent", RESOURCE_COL_X, targetPercentTextY, "showTargetPowerPercentText", false, function()
        RefreshPowerFrames()
    end)

    UpdatePowerTextDependencies()

    CreateMinimalSlider(root, "Text Scale", RESOURCE_COL_X, targetTextScaleY, 200, "targetPowerTextScale", 0.5, 2.0, 0.05, 1.0, function()
        RefreshPowerFrames()
    end, false)

    CreateMinimalSlider(root, "Width", RESOURCE_COL_X, targetWidthY, 200, "targetPowerBarWidth", 30, 250, 1, 73, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(value, MattMinimalFramesDB.targetPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5, "target")
        end
    end, true)

    CreateMinimalSlider(root, "Height", RESOURCE_COL_X, targetHeightY, 200, "targetPowerBarHeight", 3, 15, 1, 5, function(value)
        if MMF_SetPowerBarSize then
            MMF_SetPowerBarSize(MattMinimalFramesDB.targetPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73, value, "target")
        end
    end, true)
end
