local mmfDefaults = {
    locked = false,
    showPlayerPowerBar = true,
    showTargetPowerBar = false,
    showBuffs = true,
    showDebuffs = true,
    showRuneBar = true,
    runeBarScale = 1.0,
    showHolyPowerBar = true,
    holyPowerBarScale = 1.0,
    showComboPointBar = true,
    comboPointBarScale = 1.0,
    showSoulShardBar = true,
    soulShardBarScale = 1.0,
    showChiBar = true,
    chiBarScale = 1.0,
    showArcaneChargeBar = true,
    arcaneChargeBarScale = 1.0,
    showEssenceBar = true,
    essenceBarScale = 1.0,
    powerBarWidth = 73,
    powerBarHeight = 5,
    powerBarVerticalOffset = -24,
    powerBarHorizontalOffset = 4,
    hideWelcomeMessage = false,
    auraTextScale = 1.0,
    timerTextScale = 0.8,
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
    -- Frame scale settings
    playerFrameScaleX = 1.0,
    playerFrameScaleY = 1.0,
    targetFrameScaleX = 1.0,
    targetFrameScaleY = 1.0,
    totFrameScaleX = 1.0,
    totFrameScaleY = 1.0,
    focusFrameScaleX = 1.0,
    focusFrameScaleY = 1.0,
    petFrameScaleX = 1.0,
    petFrameScaleY = 1.0,
    -- Heal prediction / absorb
    showHealPrediction = true,
    showAbsorbBar = true,
    -- Cast bar settings
    showPlayerCastBar = true,
    showTargetCastBar = true,
    castBarColor = "yellow",  -- key for MMF_Config.CAST_BAR_COLORS
}

-- Power bar configuration constants (for convenience)
mmfDefaults.DEFAULT_POWER_BAR_VERTICAL_OFFSET = -24  -- Distance from bottom of frame
mmfDefaults.DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = 4   -- Distance from edge of frame

MattMinimalFrames_Defaults = mmfDefaults
