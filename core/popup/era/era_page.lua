function MMF_CreateERAPage(page, accentColor, createMinimalCheckbox, createMinimalSlider)
    local Compat = _G.MMF_Compat or {}
    if not Compat.IsClassic then
        return
    end

    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetTextColor(MMF_GetPopupSectionTitleColor())
    title:SetText("ERA FEATURES")

    local body = page:CreateFontString(nil, "OVERLAY")
    body:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    body:SetPoint("TOPLEFT", 12, -34)
    body:SetWidth(420)
    body:SetJustifyH("LEFT")
    body:SetTextColor(0.68, 0.74, 0.78)
    body:SetText("Toggle Classic Era-specific gameplay visuals.")

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

    CreateMinimalCheckbox(page, "Target Tap Gray Color", 12, -78, "showTBCTargetTapColor", true, function()
        RefreshFrames()
    end)

    local classSectionTitle = page:CreateFontString(nil, "OVERLAY")
    classSectionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    classSectionTitle:SetPoint("TOPLEFT", 12, -112)
    classSectionTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    classSectionTitle:SetText("CLASS BAR VISIBILITY")

    local classSectionBody = page:CreateFontString(nil, "OVERLAY")
    classSectionBody:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    classSectionBody:SetPoint("TOPLEFT", 12, -130)
    classSectionBody:SetWidth(520)
    classSectionBody:SetJustifyH("LEFT")
    classSectionBody:SetTextColor(0.68, 0.74, 0.78)
    classSectionBody:SetText("Show or hide Era-supported class bars from this tab.")

    local classDivider = page:CreateTexture(nil, "ARTWORK")
    classDivider:SetSize(420, 1)
    classDivider:SetPoint("TOPLEFT", 12, -150)
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
    local startY = -166
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
            function()
                RefreshClassBar()
            end
        )
    end
end
