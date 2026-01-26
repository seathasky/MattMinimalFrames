-- core/defaults.lua
-- Contains default settings for MattMinimalFrames

local mmfDefaults = {
    locked = false,
    showPowerBars = true,
    showBuffs = true,
    showDebuffs = true,
    powerBarWidth = 73,
    powerBarHeight = 5,
    powerBarVerticalOffset = -24,
    powerBarHorizontalOffset = 4,
    hideWelcomeMessage = false,
    auraTextScale = 1.0,
    timerTextScale = 1.0,
    auraIconSize = 18,
    -- Buff position (relative to BOTTOMRIGHT of target frame)
    buffXOffset = -2,
    buffYOffset = -64,
    -- Debuff position (relative to TOPLEFT of target frame)
    debuffXOffset = 3,
    debuffYOffset = 27,
}

-- Power bar configuration constants (for convenience)
mmfDefaults.DEFAULT_POWER_BAR_VERTICAL_OFFSET = -24  -- Distance from bottom of frame
mmfDefaults.DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = 4   -- Distance from edge of frame

MattMinimalFrames_Defaults = mmfDefaults
