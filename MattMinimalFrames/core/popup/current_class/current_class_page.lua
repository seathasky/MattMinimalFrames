function MMF_CreateCurrentClassSection(middleCol, accentColor, createMinimalCheckbox, createMinimalSlider, updatePlayerIconModeButtonText, getCurrentPlayerIconModeValue)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider
    local UpdatePlayerIconModeButtonText = updatePlayerIconModeButtonText or function() end
    local GetCurrentPlayerIconModeValue = getCurrentPlayerIconModeValue or function() return "off" end

    -- MIDDLE COLUMN: Current Class
    ---------------------------------------------------
    local classBarTitle = middleCol:CreateFontString(nil, "OVERLAY")
    classBarTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    classBarTitle:SetPoint("TOPLEFT", 12, -12)
    classBarTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    classBarTitle:SetText("CURRENT CLASS")

    local classCfg = MMF_GetCurrentClassBarConfig and MMF_GetCurrentClassBarConfig() or nil
    if classCfg then
        local classColor = classCfg.classColor or {0.9, 0.9, 0.9}
        local currentClassTitle = middleCol:CreateFontString(nil, "OVERLAY")
        currentClassTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 14, "OUTLINE")
        currentClassTitle:SetPoint("TOPLEFT", 12, -36)
        currentClassTitle:SetTextColor(classColor[1], classColor[2], classColor[3])
        currentClassTitle:SetText(classCfg.classLabel or "Unknown")

        local classHelp = middleCol:CreateFontString(nil, "OVERLAY")
        classHelp:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        classHelp:SetPoint("TOPLEFT", 12, -56)
        classHelp:SetTextColor(0.65, 0.65, 0.7)
        classHelp:SetText("Configure your active class resource bar.")

        local classDivider = middleCol:CreateTexture(nil, "ARTWORK")
        classDivider:SetSize(200, 1)
        classDivider:SetPoint("TOPLEFT", 12, -72)
        classDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

        local classShowCheck = CreateMinimalCheckbox(middleCol, classCfg.showLabel or "Show Class Resource Bar", 12, -92, classCfg.showKey, true, function()
            StaticPopup_Show("MMF_RELOADUI")
        end)
        local classSoundsCheck = nil
        local classSoundsEnabled = (classCfg.classSoundsKey and classCfg.classSoundsLabel) and true or false
        local classSoundsLabel = classSoundsEnabled and classCfg.classSoundsLabel or "Class Sounds (Coming Soon)"
        local classSoundsKey = classSoundsEnabled and classCfg.classSoundsKey or "__mmfClassSoundsComingSoon"
        classSoundsCheck = CreateMinimalCheckbox(middleCol, classSoundsLabel, 12, -116, classSoundsKey, false, nil)
        if not classSoundsEnabled and classSoundsCheck and classSoundsCheck.checkbox then
            classSoundsCheck:SetAlpha(0.55)
            classSoundsCheck.checkbox:EnableMouse(false)
            classSoundsCheck.checkbox:SetChecked(false)
            if classSoundsCheck.checkbox.check then
                classSoundsCheck.checkbox.check:SetShown(false)
                classSoundsCheck.checkbox.check:SetAlpha(0.35)
            end
        end

        local layoutTitle = middleCol:CreateFontString(nil, "OVERLAY")
        layoutTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        layoutTitle:SetPoint("TOPLEFT", 12, -148)
        layoutTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
        layoutTitle:SetText("RESOURCE LAYOUT")

        local prefix = classCfg.prefix
        local d = MattMinimalFrames_Defaults or {}
        local widthKey = prefix .. "Width"
        local heightKey = prefix .. "Height"
        local spacingKey = prefix .. "Spacing"
        local xKey = prefix .. "X"
        local yKey = prefix .. "Y"

        local function ApplyCurrentClassLayout()
            if MMF_UpdateClassBarLayout then
                MMF_UpdateClassBarLayout(prefix)
            end
        end

        local resourceWidthSlider = CreateMinimalSlider(middleCol, "Point Width", 12, -172, 200, widthKey, 6, 80, 1, d[widthKey] or 30, function()
            ApplyCurrentClassLayout()
        end, true)

        local resourceHeightSlider = CreateMinimalSlider(middleCol, "Point Height", 12, -196, 200, heightKey, 4, 30, 1, d[heightKey] or 10, function()
            ApplyCurrentClassLayout()
        end, true)

        local resourceSpacingSlider = CreateMinimalSlider(middleCol, "Spacing", 12, -220, 200, spacingKey, 0, 20, 1, d[spacingKey] or 4, function()
            ApplyCurrentClassLayout()
        end, true)

        local layoutDivider = middleCol:CreateTexture(nil, "ARTWORK")
        layoutDivider:SetSize(200, 1)
        layoutDivider:SetPoint("TOPLEFT", 12, -248)
        layoutDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

        local positionTitle = middleCol:CreateFontString(nil, "OVERLAY")
        positionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
        positionTitle:SetPoint("TOPLEFT", 12, -260)
        positionTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
        positionTitle:SetText("POSITION")

        local resourceXSlider = CreateMinimalSlider(middleCol, "X Offset", 12, -284, 200, xKey, -800, 800, 1, d[xKey] or 0, function()
            ApplyCurrentClassLayout()
        end, true)

        local resourceYSlider = CreateMinimalSlider(middleCol, "Y Offset", 12, -308, 200, yKey, -800, 800, 1, d[yKey] or -50, function()
            ApplyCurrentClassLayout()
        end, true)

        local hintText = middleCol:CreateFontString(nil, "OVERLAY")
        hintText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        hintText:SetPoint("TOPLEFT", 12, -336)
        hintText:SetTextColor(0.6, 0.6, 0.6)
        hintText:SetText("Tip: Hold SHIFT and drag the bar to move it too.")

        if classCfg.note and classCfg.note ~= "" then
            local classNote = middleCol:CreateFontString(nil, "OVERLAY")
            classNote:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
            classNote:SetPoint("TOPLEFT", 12, -352)
            classNote:SetWidth(200)
            classNote:SetJustifyH("LEFT")
            classNote:SetTextColor(0.6, 0.6, 0.6)
            classNote:SetText(classCfg.note)
        end

        local resetY = (classCfg.note and classCfg.note ~= "") and -384 or -368
        local resetClassBtn = CreateFrame("Button", nil, middleCol, "BackdropTemplate")
        resetClassBtn:SetSize(200, 22)
        resetClassBtn:SetPoint("TOPLEFT", 12, resetY)
        resetClassBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        resetClassBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
        resetClassBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)

        local resetClassBtnText = resetClassBtn:CreateFontString(nil, "OVERLAY")
        resetClassBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        resetClassBtnText:SetPoint("CENTER")
        resetClassBtnText:SetText("Reset Current Class")
        resetClassBtnText:SetTextColor(0.8, 0.8, 0.8)

        resetClassBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.15, 1)
            resetClassBtnText:SetTextColor(1, 1, 1)
        end)
        resetClassBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.08, 0.08, 0.1, 1)
            resetClassBtnText:SetTextColor(0.8, 0.8, 0.8)
        end)
        resetClassBtn:SetScript("OnClick", function()
            _G.MMF_OnConfirmResetCurrentClass = function()
                local needsReload = false
                if MMF_ResetCurrentClassBarSettings then
                    needsReload = MMF_ResetCurrentClassBarSettings()
                end

                if classShowCheck and classShowCheck.checkbox then
                    local checked = MattMinimalFramesDB[classCfg.showKey]
                    classShowCheck.checkbox:SetChecked(checked)
                    classShowCheck.checkbox.check:SetShown(checked)
                end
                if classSoundsEnabled and classSoundsCheck and classSoundsCheck.checkbox and classCfg.classSoundsKey then
                    local checked = MattMinimalFramesDB[classCfg.classSoundsKey]
                    classSoundsCheck.checkbox:SetChecked(checked)
                    classSoundsCheck.checkbox.check:SetShown(checked)
                end
                UpdatePlayerIconModeButtonText()

                resourceWidthSlider.slider:SetValue(MattMinimalFramesDB[widthKey] or d[widthKey] or 30)
                resourceHeightSlider.slider:SetValue(MattMinimalFramesDB[heightKey] or d[heightKey] or 10)
                resourceSpacingSlider.slider:SetValue(MattMinimalFramesDB[spacingKey] or d[spacingKey] or 4)
                resourceXSlider.slider:SetValue(MattMinimalFramesDB[xKey] or d[xKey] or 0)
                resourceYSlider.slider:SetValue(MattMinimalFramesDB[yKey] or d[yKey] or -50)
                if MMF_UpdatePlayerClassIconVisibility then
                    MMF_UpdatePlayerClassIconVisibility(GetCurrentPlayerIconModeValue())
                end

                if needsReload then
                    StaticPopup_Show("MMF_RELOADUI")
                end
            end
            StaticPopup_Show("MMF_RESET_CURRENT_CLASS_WARNING")
        end)
    else
        local unsupported = middleCol:CreateFontString(nil, "OVERLAY")
        unsupported:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
        unsupported:SetPoint("TOPLEFT", 12, -92)
        unsupported:SetTextColor(0.7, 0.7, 0.7)
        unsupported:SetText("No class resource options for this class.")
    end

    ---------------------------------------------------
end

