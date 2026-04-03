function MMF_GetPopupFooterClassDisplay(accentColor)
    local name = UnitName("player") or "Player"
    local _, classToken = UnitClass("player")
    local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]

    local iconTexture = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
    local texCoord = { 0, 1, 0, 1 }
    if classToken then
        iconTexture = "Interface\\ICONS\\ClassIcon_" .. classToken
        texCoord = { 0.08, 0.92, 0.08, 0.92 }
    end

    local textColor
    if classColor then
        textColor = { classColor.r, classColor.g, classColor.b }
    else
        local fallback = accentColor or { 0.6, 0.4, 0.9 }
        textColor = { fallback[1], fallback[2], fallback[3] }
    end

    return {
        name = name,
        iconTexture = iconTexture,
        iconTexCoord = texCoord,
        textColor = textColor,
    }
end
