local Compat = _G.MMF_Compat or {}

MMF_POPUP_LAYOUT = {
    TITLE_HEIGHT = 28,
    FOOTER_HEIGHT = 32,
    TAB_HEIGHT = 24,
    TAB_SPACING = 4,
    CONTENT_SIDE_PADDING = 10,
    CONTENT_TOP_OFFSET = -4,
    PAGE_GAP = 4,
    DEFAULT_CENTER_Y = 50,
    WIDTH_TBC = 600,
    WIDTH_RETAIL = 620,
    HEIGHT_TBC = 696,
    HEIGHT_RETAIL = 700,
}

function MMF_GetPopupLayout()
    local layout = MMF_POPUP_LAYOUT or {}
    local isTBC = Compat and Compat.IsTBC
    return {
        titleHeight = layout.TITLE_HEIGHT or 28,
        footerHeight = layout.FOOTER_HEIGHT or 32,
        tabHeight = layout.TAB_HEIGHT or 24,
        tabSpacing = layout.TAB_SPACING or 4,
        contentSidePadding = layout.CONTENT_SIDE_PADDING or 10,
        contentTopOffset = layout.CONTENT_TOP_OFFSET or -4,
        pageGap = layout.PAGE_GAP or 4,
        centerY = layout.DEFAULT_CENTER_Y or 50,
        width = isTBC and (layout.WIDTH_TBC or 600) or (layout.WIDTH_RETAIL or 620),
        height = isTBC and (layout.HEIGHT_TBC or 696) or (layout.HEIGHT_RETAIL or 700),
    }
end

local function GetPlayerClassAccent()
    if MattMinimalFramesDB and MattMinimalFramesDB.classColorGUI == false then
        return 0.72, 0.74, 0.78
    end
    local _, classToken = UnitClass("player")
    local classColors = RAID_CLASS_COLORS
    local classColor = classToken and classColors and classColors[classToken]
    if classColor then
        return classColor.r, classColor.g, classColor.b
    end
    if Compat.IsTBC then
        return 0.2, 0.9, 0.4
    end
    return 0.6, 0.4, 0.9
end

function MMF_GetPopupAccentColor()
    local r, g, b = GetPlayerClassAccent()
    return { r, g, b }
end

function MMF_IsClassColorGUIEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.classColorGUI ~= false
end

function MMF_RGBToHexPrefix(r, g, b)
    local function ChannelToInt(v)
        v = tonumber(v) or 1
        if v < 0 then v = 0 end
        if v > 1 then v = 1 end
        return math.floor((v * 255) + 0.5)
    end
    return string.format("|cff%02x%02x%02x", ChannelToInt(r), ChannelToInt(g), ChannelToInt(b))
end

function MMF_IsPopupUISoundsEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.uiSoundsEnabled ~= false
end
