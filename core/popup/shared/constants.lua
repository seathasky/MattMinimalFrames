local Compat = _G.MMF_Compat or {}

MMF_POPUP_LAYOUT = {
    TITLE_HEIGHT = 28,
    FOOTER_HEIGHT = 32,
    TAB_HEIGHT = 42,
    TAB_SPACING = 6,
    CONTENT_SIDE_PADDING = 12,
    CONTENT_TOP_OFFSET = -8,
    PAGE_GAP = 8,
    DEFAULT_CENTER_Y = 50,
    WIDTH_TBC = 840,
    WIDTH_RETAIL = 840,
    HEIGHT_TBC = 580,
    HEIGHT_RETAIL = 580,
    PAGE_CONTENT_HEIGHT_UNIT_FRAMES = 460,
    PAGE_CONTENT_HEIGHT_AURAS_POWER = 680,
    PAGE_CONTENT_HEIGHT_PARTY_RAID = 680,
    PAGE_CONTENT_HEIGHT_CURRENT_CLASS = 680,
    PAGE_CONTENT_HEIGHT_PROFILES = 680,
    PAGE_CONTENT_HEIGHT_TOOLS = 680,
}

-- One visual language for every popup module and every supported client.  Keep
-- these values data-only so Classic clients do not depend on newer APIs.
MMF_POPUP_THEME = {
    font = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf",
    window = { 0.025, 0.030, 0.038, 0.99 },
    surface = { 0.045, 0.055, 0.068, 0.98 },
    surfaceRaised = { 0.060, 0.075, 0.090, 0.98 },
    surfaceHover = { 0.080, 0.100, 0.118, 1.00 },
    input = { 0.025, 0.032, 0.042, 1.00 },
    border = { 0.145, 0.175, 0.205, 1.00 },
    borderStrong = { 0.220, 0.260, 0.300, 1.00 },
    text = { 0.92, 0.94, 0.96, 1.00 },
    textMuted = { 0.62, 0.67, 0.72, 1.00 },
    textDisabled = { 0.40, 0.43, 0.47, 1.00 },
    section = { 0.62, 0.92, 0.88, 1.00 },
    danger = { 1.00, 0.38, 0.38, 1.00 },
    controlHeight = 22,
    rowHeight = 26,
    resetWidth = 52,
}

function MMF_GetPopupTheme()
    return MMF_POPUP_THEME or {}
end

MMF_POPUP_INACTIVE_FADE = {
    FOCUS_ALPHA = 1.0,
    DEFAULT_ALPHA = 0.60,
    MIN_ALPHA = 0.05,
    MAX_ALPHA = 0.95,
    FADE_TIME = 0.30,
    HOVER_POLL_INTERVAL = 0.03,
    CURSOR_PAD = 4,
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
        height = isTBC and (layout.HEIGHT_TBC or 820) or (layout.HEIGHT_RETAIL or 824),
        unitFramesContentHeight = layout.PAGE_CONTENT_HEIGHT_UNIT_FRAMES or 980,
        aurasPowerContentHeight = layout.PAGE_CONTENT_HEIGHT_AURAS_POWER or 980,
        partyRaidContentHeight = layout.PAGE_CONTENT_HEIGHT_PARTY_RAID or 760,
        currentClassContentHeight = layout.PAGE_CONTENT_HEIGHT_CURRENT_CLASS or 760,
        profilesContentHeight = layout.PAGE_CONTENT_HEIGHT_PROFILES or 760,
        toolsContentHeight = layout.PAGE_CONTENT_HEIGHT_TOOLS or 760,
    }
end

function MMF_GetPopupInactiveFadeConfig()
    local cfg = MMF_POPUP_INACTIVE_FADE or {}
    return {
        focusAlpha = cfg.FOCUS_ALPHA or 1.0,
        defaultAlpha = cfg.DEFAULT_ALPHA or 0.60,
        minAlpha = cfg.MIN_ALPHA or 0.05,
        maxAlpha = cfg.MAX_ALPHA or 0.95,
        fadeTime = cfg.FADE_TIME or 0.30,
        hoverPollInterval = cfg.HOVER_POLL_INTERVAL or 0.03,
        cursorPad = cfg.CURSOR_PAD or 4,
    }
end

local function GetPlayerClassAccent()
    -- Monochrome popup accent (gray/white/dark-gray theme).
    return 0.72, 0.74, 0.78
end

function MMF_GetPopupAccentColor()
    local r, g, b = GetPlayerClassAccent()
    return { r, g, b }
end

function MMF_GetPopupSectionTitleColor()
    local theme = MMF_GetPopupTheme()
    local color = theme.section or { 0.62, 0.92, 0.88 }
    return color[1], color[2], color[3]
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
