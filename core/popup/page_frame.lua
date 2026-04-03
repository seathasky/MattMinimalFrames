function MMF_CreatePopupPageFrame(parent, contentHeight)
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
    page:SetBackdropColor(0.08, 0.10, 0.13, 0.96)
    page:SetBackdropBorderColor(0.12, 0.16, 0.18, 1)
    return page
end
