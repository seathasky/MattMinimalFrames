function MMF_CreatePopupPageFrame(parent, contentHeight)
    local theme = (MMF_GetPopupTheme and MMF_GetPopupTheme()) or {}
    local surface = theme.surface or { 0.045, 0.055, 0.068, 0.98 }
    local border = theme.border or { 0.145, 0.175, 0.205, 1 }
    local page = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetWidth(10)
    page:SetHeight(contentHeight or 760)
    page:SetClipsChildren(true)
    page:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    page:SetBackdropColor(surface[1], surface[2], surface[3], surface[4] or 0.98)
    page:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    return page
end
