function MMF_BuildAurasPowerFiltersSection(ctx)
    local root = ctx.parent
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local AURA_COL_X = ctx.auraColX

    local filtersTitle = root:CreateFontString(nil, "OVERLAY")
    filtersTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
    filtersTitle:SetPoint("TOPLEFT", AURA_COL_X, -12)
    MMF_ApplyUnitFramesHeadingColor(filtersTitle, "aura")
    filtersTitle:SetText("TARGET AURA FILTERS")

    CreateMinimalCheckbox(root, "Only Show My Debuffs on Target", AURA_COL_X, -40, "onlyShowPlayerDebuffsOnTarget", false, function()
        if MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end
    end)
end
