-- core/defaults.lua
-- Contains default settings for MattMinimalFrames

local mmfDefaults = {
    locked = false,
    showPlayerPowerBar = true,
    showTargetPowerBar = false,
    showBuffs = true,
    showDebuffs = true,
    showRuneBar = false,
    runeBarScale = 1.0,
    powerBarWidth = 73,
    powerBarHeight = 5,
    powerBarVerticalOffset = -24,
    powerBarHorizontalOffset = 4,
    hideWelcomeMessage = false,
    auraTextScale = 1.0,
    timerTextScale = 1.0,
    auraIconSize = 18,
    nameTextSize = 12,
    hpTextSize = 13,
    -- Buff position (relative to BOTTOMRIGHT of target frame)
    buffXOffset = -2,
    buffYOffset = -64,
    -- Debuff position (relative to TOPLEFT of target frame)
    debuffXOffset = 3,
    debuffYOffset = 27,
    -- Popup position (nil = default center)
    popupPosition = nil,
    -- Move hints
    showMoveHints = false,
    -- Minimap button (LibDBIcon format)
    minimap = { hide = false },
}

-- Power bar configuration constants (for convenience)
mmfDefaults.DEFAULT_POWER_BAR_VERTICAL_OFFSET = -24  -- Distance from bottom of frame
mmfDefaults.DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = 4   -- Distance from edge of frame

MattMinimalFrames_Defaults = mmfDefaults
