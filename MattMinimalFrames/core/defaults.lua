-- core/defaults.lua
-- Contains default settings for MattMinimalFrames

local mmfDefaults = {
    locked = false,
    showPowerBars = true,
    powerBarWidth = 73,
    powerBarHeight = 5,
    powerBarVerticalOffset = -24,
    powerBarHorizontalOffset = 4,
    hideWelcomeMessage = false,
}

-- Power bar configuration constants (for convenience)
mmfDefaults.DEFAULT_POWER_BAR_VERTICAL_OFFSET = -24  -- Distance from bottom of frame
mmfDefaults.DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = 4   -- Distance from edge of frame

MattMinimalFrames_Defaults = mmfDefaults
