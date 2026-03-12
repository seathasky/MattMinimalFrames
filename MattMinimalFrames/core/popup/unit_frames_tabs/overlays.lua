function MMF_BuildUnitFramesOverlaysSection(ctx)
    local unitFramesCol = ctx.parent
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local rightSection = ctx.rightSection
    local OnPredictionChanged = ctx.onPredictionChanged or function() end

    local RIGHT_COL_X = ctx.rightColX
    local RIGHT_COL_WIDTH = ctx.rightColWidth
    local RIGHT_STACK_Y_OFFSET = ctx.rightStackYOffset
    local RIGHT_FRAME_OPTIONS_Y_SHIFT = ctx.rightFrameOptionsYShift

    rightSection.frameOptionsDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    rightSection.frameOptionsDivider:SetSize(RIGHT_COL_WIDTH, 1)
    rightSection.frameOptionsDivider:SetPoint("TOPLEFT", RIGHT_COL_X, (-706 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET)
    rightSection.frameOptionsDivider:SetColorTexture(0.42, 0.42, 0.46, 1)

    rightSection.healOverlaysTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    rightSection.healOverlaysTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    rightSection.healOverlaysTitle:SetPoint("TOPLEFT", RIGHT_COL_X, (-718 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET)
    rightSection.healOverlaysTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    rightSection.healOverlaysTitle:SetText("HEAL OVERLAYS")

    rightSection.healPredictionCheck = CreateMinimalCheckbox(unitFramesCol, "Heal Prediction", RIGHT_COL_X, (-742 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, "showHealPrediction", true, function()
        OnPredictionChanged()
    end)

    local overlayHintTooltip = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    overlayHintTooltip:SetSize(208, 108)
    overlayHintTooltip:SetFrameStrata("TOOLTIP")
    overlayHintTooltip:SetFrameLevel(400)
    overlayHintTooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    overlayHintTooltip:SetBackdropColor(0.03, 0.03, 0.05, 0.98)
    overlayHintTooltip:SetBackdropBorderColor(0.28, 0.28, 0.34, 1)
    overlayHintTooltip:Hide()
    rightSection.overlayHintTooltip = overlayHintTooltip

    overlayHintTooltip.title = overlayHintTooltip:CreateFontString(nil, "OVERLAY")
    overlayHintTooltip.title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    overlayHintTooltip.title:SetPoint("TOPLEFT", 8, -8)
    overlayHintTooltip.title:SetTextColor(0.95, 0.95, 0.95)

    overlayHintTooltip.preview = overlayHintTooltip:CreateTexture(nil, "ARTWORK")
    overlayHintTooltip.preview:SetPoint("TOPLEFT", 8, -30)
    overlayHintTooltip.preview:SetSize(192, 70)
    overlayHintTooltip.preview:SetTexCoord(0, 1, 0, 1)

    local function ResizeOverlayHintTooltipForImage(sourceW, sourceH)
        local maxPreviewW, maxPreviewH = 220, 120
        local texW = tonumber(sourceW) or 0
        local texH = tonumber(sourceH) or 0

        local previewW, previewH = 192, 70
        if texW > 0 and texH > 0 then
            local scale = math.min(maxPreviewW / texW, maxPreviewH / texH, 1)
            previewW = math.max(24, math.floor(texW * scale + 0.5))
            previewH = math.max(12, math.floor(texH * scale + 0.5))
        end

        overlayHintTooltip.preview:ClearAllPoints()
        overlayHintTooltip.preview:SetPoint("TOPLEFT", 8, -30)
        overlayHintTooltip.preview:SetSize(previewW, previewH)
        overlayHintTooltip:SetSize(previewW + 16, previewH + 40)
    end

    local function ShowOverlayHintTooltip(anchor, title, imagePath, sourceW, sourceH)
        if not anchor or not imagePath then return end
        overlayHintTooltip.title:SetText(title or "Hint")
        overlayHintTooltip.preview:SetTexture(imagePath)
        ResizeOverlayHintTooltipForImage(sourceW, sourceH)
        overlayHintTooltip:ClearAllPoints()
        overlayHintTooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 10, 6)
        overlayHintTooltip:Show()
    end

    local function HideOverlayHintTooltip()
        overlayHintTooltip:Hide()
    end

    local function CreateHintIcon(anchorContainer, xOffset, title, imagePath, sourceW, sourceH)
        local hint = CreateFrame("Frame", nil, unitFramesCol, "BackdropTemplate")
        hint:SetSize(12, 12)
        hint:SetPoint("LEFT", anchorContainer, "LEFT", xOffset or 146, 0)
        hint:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        hint:SetBackdropColor(0.08, 0.08, 0.1, 1)
        hint:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        hint:EnableMouse(true)

        local hintText = hint:CreateFontString(nil, "OVERLAY")
        hintText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
        hintText:SetPoint("CENTER", 0, 0)
        hintText:SetText("?")
        hintText:SetTextColor(0.85, 0.85, 0.9)

        hint:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
            hintText:SetTextColor(1, 1, 1)
            ShowOverlayHintTooltip(self, title, imagePath, sourceW, sourceH)
        end)
        hint:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            hintText:SetTextColor(0.85, 0.85, 0.9)
            HideOverlayHintTooltip()
        end)

        return hint
    end

    CreateHintIcon(
        rightSection.healPredictionCheck,
        128,
        "Heal Prediction",
        "Interface\\AddOns\\MattMinimalFrames\\Images\\healpredict.png",
        200,
        52
    )

    rightSection.overhealPredictionCheck = CreateMinimalCheckbox(unitFramesCol, "Overheal", RIGHT_COL_X, (-766 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, "showOverhealPrediction", false, function()
        OnPredictionChanged()
    end)

    rightSection.absorbBarCheck = CreateMinimalCheckbox(unitFramesCol, "Absorb Bar", RIGHT_COL_X, (-790 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, "showAbsorbBar", true, function()
        OnPredictionChanged()
    end)

    CreateHintIcon(
        rightSection.absorbBarCheck,
        106,
        "Absorb Bar",
        "Interface\\AddOns\\MattMinimalFrames\\Images\\absorb.png",
        357,
        86
    )
end

