function MMF_BuildAurasPowerFiltersSection(ctx)
    local root = ctx.parent
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local AURA_COL_X = ctx.auraColX

    local filtersTitle = root:CreateFontString(nil, "OVERLAY")
    filtersTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    filtersTitle:SetPoint("TOPLEFT", AURA_COL_X, -12)
    filtersTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    filtersTitle:SetText("AURA FILTERS")

    CreateMinimalCheckbox(root, "Only Show My Debuffs on Target", AURA_COL_X, -40, "onlyShowPlayerDebuffsOnTarget", false, function()
        if MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end
    end)
end
