function MMF_CreateTBCPage(page, accentColor, createMinimalCheckbox, createMinimalSlider)
    local Compat = _G.MMF_Compat or {}
    if not Compat.IsTBC then
        return
    end

    local ACCENT_COLOR = accentColor or { 0.2, 0.9, 0.4 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateMinimalSlider = createMinimalSlider or MMF_CreateMinimalSlider

    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetTextColor(MMF_GetPopupSectionTitleColor())
    title:SetText("TBC FEATURES")

    local body = page:CreateFontString(nil, "OVERLAY")
    body:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    body:SetPoint("TOPLEFT", 12, -34)
    body:SetWidth(420)
    body:SetJustifyH("LEFT")
    body:SetTextColor(0.68, 0.74, 0.78)
    body:SetText("Toggle TBC-specific gameplay visuals. These default to enabled.")

    local divider = page:CreateTexture(nil, "ARTWORK")
    divider:SetSize(420, 1)
    divider:SetPoint("TOPLEFT", 12, -58)
    divider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local function RefreshFrames()
        if MMF_RequestUnitUpdate then
            MMF_RequestUnitUpdate("player")
            MMF_RequestUnitUpdate("target")
            return
        end
        if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local playerFrame = MMF_GetFrameForUnit("player")
            if playerFrame then MMF_UpdateUnitFrame(playerFrame) end
            local targetFrame = MMF_GetFrameForUnit("target")
            if targetFrame then MMF_UpdateUnitFrame(targetFrame) end
        end
    end

    CreateMinimalCheckbox(
        page,
        "PvP Flag Indicator",
        12,
        -78,
        "showTBCPVPFlagIndicator",
        true,
        function()
            RefreshFrames()
        end
    )

    CreateMinimalCheckbox(
        page,
        "Target Tap Gray Color",
        12,
        -102,
        "showTBCTargetTapColor",
        true,
        function()
            RefreshFrames()
        end
    )

    local note = page:CreateFontString(nil, "OVERLAY")
    note:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    note:SetPoint("TOPLEFT", 12, -130)
    note:SetWidth(500)
    note:SetJustifyH("LEFT")
    note:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)
    note:SetText("These two options control the TBC-only frame behaviors.")

    local classSectionTitle = page:CreateFontString(nil, "OVERLAY")
    classSectionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    classSectionTitle:SetPoint("TOPLEFT", 12, -164)
    classSectionTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    classSectionTitle:SetText("CLASS BAR VISIBILITY")

    local classSectionBody = page:CreateFontString(nil, "OVERLAY")
    classSectionBody:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    classSectionBody:SetPoint("TOPLEFT", 12, -182)
    classSectionBody:SetWidth(520)
    classSectionBody:SetJustifyH("LEFT")
    classSectionBody:SetTextColor(0.68, 0.74, 0.78)
    classSectionBody:SetText("Show or hide TBC-supported class bars from this tab.")

    local classDivider = page:CreateTexture(nil, "ARTWORK")
    classDivider:SetSize(420, 1)
    classDivider:SetPoint("TOPLEFT", 12, -202)
    classDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local function RefreshClassBar()
        if MMF_EnsureComboPointBarInitialized then
            MMF_EnsureComboPointBarInitialized()
        end
        if MMF_UpdateClassBarLayout then
            MMF_UpdateClassBarLayout("comboPointBar")
        end
        if MMF_UpdateClassBarLayoutForCurrentClass then
            MMF_UpdateClassBarLayoutForCurrentClass()
        end
        if MMF_RefreshClassResourceVisibility then
            MMF_RefreshClassResourceVisibility()
        end
        RefreshFrames()
    end

    local classBarToggles = {
        { label = "Rogue/Druid Combo Bar", key = "showComboPointBar", defaultValue = true },
    }

    local startX = 12
    local startY = -218
    local rowHeight = 22
    for index, toggle in ipairs(classBarToggles) do
        local row = index - 1
        local x = startX
        local y = startY - (row * rowHeight)
        CreateMinimalCheckbox(
            page,
            toggle.label,
            x,
            y,
            toggle.key,
            toggle.defaultValue,
            RefreshClassBar
        )
    end

    CreateMinimalSlider(
        page,
        "Combo Bar Scale",
        12,
        -244,
        280,
        "comboPointBarScale",
        0.5,
        3.0,
        0.05,
        1.0,
        function(value)
            if MMF_EnsureComboPointBarInitialized then
                MMF_EnsureComboPointBarInitialized()
            end
            if MMF_UpdateComboPointBarScale then
                MMF_UpdateComboPointBarScale(value)
            end
            RefreshClassBar()
        end
    )
end
