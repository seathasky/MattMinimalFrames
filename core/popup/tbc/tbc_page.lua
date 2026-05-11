function MMF_CreateTBCPage(page, accentColor, createMinimalCheckbox)
    local Compat = _G.MMF_Compat or {}
    if not Compat.IsTBC then
        return
    end

    local ACCENT_COLOR = accentColor or { 0.2, 0.9, 0.4 }
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox

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
end
