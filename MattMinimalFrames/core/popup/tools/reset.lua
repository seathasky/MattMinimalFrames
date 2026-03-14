function MMF_ResetPopupScaleAndTextToDefaults()
        local d = MattMinimalFrames_Defaults
        -- Text/aura scales
        MattMinimalFramesDB.auraTextScale = d.auraTextScale
        MattMinimalFramesDB.timerTextScale = d.timerTextScale
        MattMinimalFramesDB.auraIconSize = d.auraIconSize
        MattMinimalFramesDB.nameTextSize = d.nameTextSize
        MattMinimalFramesDB.textSizeUnit = d.textSizeUnit
        MattMinimalFramesDB.playerNameTextSize = d.nameTextSize
        MattMinimalFramesDB.targetNameTextSize = d.nameTextSize
        MattMinimalFramesDB.totNameTextSize = d.nameTextSize
        MattMinimalFramesDB.petNameTextSize = d.nameTextSize
        MattMinimalFramesDB.focusNameTextSize = d.nameTextSize
        MattMinimalFramesDB.bossNameTextSize = d.bossNameTextSize or d.nameTextSize
        MattMinimalFramesDB.enableNameTruncation = d.enableNameTruncation
        MattMinimalFramesDB.autoResizeTextOnLongName = d.autoResizeTextOnLongName
        MattMinimalFramesDB.nameTruncationLength = d.nameTruncationLength
        MattMinimalFramesDB.nameTextXOffset = d.nameTextXOffset
        MattMinimalFramesDB.nameTextYOffset = d.nameTextYOffset
        MattMinimalFramesDB.nameTextScaleX = d.nameTextScaleX or 1.0
        MattMinimalFramesDB.nameTextScaleY = d.nameTextScaleY or 1.0
        MattMinimalFramesDB.playerNameTextXOffset = d.playerNameTextXOffset
        MattMinimalFramesDB.playerNameTextYOffset = d.playerNameTextYOffset
        MattMinimalFramesDB.targetNameTextXOffset = d.targetNameTextXOffset
        MattMinimalFramesDB.targetNameTextYOffset = d.targetNameTextYOffset
        MattMinimalFramesDB.totNameTextXOffset = d.totNameTextXOffset
        MattMinimalFramesDB.totNameTextYOffset = d.totNameTextYOffset
        MattMinimalFramesDB.petNameTextXOffset = d.petNameTextXOffset
        MattMinimalFramesDB.petNameTextYOffset = d.petNameTextYOffset
        MattMinimalFramesDB.focusNameTextXOffset = d.focusNameTextXOffset
        MattMinimalFramesDB.focusNameTextYOffset = d.focusNameTextYOffset
        MattMinimalFramesDB.bossNameTextXOffset = d.bossNameTextXOffset or 0
        MattMinimalFramesDB.bossNameTextYOffset = d.bossNameTextYOffset or 0
        MattMinimalFramesDB.hpTextSize = d.hpTextSize
        MattMinimalFramesDB.playerHPTextSize = d.hpTextSize
        MattMinimalFramesDB.targetHPTextSize = d.hpTextSize
        MattMinimalFramesDB.totHPTextSize = d.hpTextSize
        MattMinimalFramesDB.petHPTextSize = d.hpTextSize
        MattMinimalFramesDB.focusHPTextSize = d.hpTextSize
        MattMinimalFramesDB.bossHPTextSize = d.bossHPTextSize or d.hpTextSize
        MattMinimalFramesDB.hpTextXOffset = d.hpTextXOffset
        MattMinimalFramesDB.hpTextYOffset = d.hpTextYOffset
        MattMinimalFramesDB.hpTextScaleX = d.hpTextScaleX or 1.0
        MattMinimalFramesDB.hpTextScaleY = d.hpTextScaleY or 1.0
        MattMinimalFramesDB.playerHPTextXOffset = d.playerHPTextXOffset
        MattMinimalFramesDB.playerHPTextYOffset = d.playerHPTextYOffset
        MattMinimalFramesDB.targetHPTextXOffset = d.targetHPTextXOffset
        MattMinimalFramesDB.targetHPTextYOffset = d.targetHPTextYOffset
        MattMinimalFramesDB.totHPTextXOffset = d.totHPTextXOffset or 0
        MattMinimalFramesDB.totHPTextYOffset = d.totHPTextYOffset or 0
        MattMinimalFramesDB.petHPTextXOffset = d.petHPTextXOffset or 0
        MattMinimalFramesDB.petHPTextYOffset = d.petHPTextYOffset or 0
        MattMinimalFramesDB.focusHPTextXOffset = d.focusHPTextXOffset or 0
        MattMinimalFramesDB.focusHPTextYOffset = d.focusHPTextYOffset or 0
        MattMinimalFramesDB.bossHPTextXOffset = d.bossHPTextXOffset or 0
        MattMinimalFramesDB.bossHPTextYOffset = d.bossHPTextYOffset or 0
        MattMinimalFramesDB.showHPValueText = d.showHPValueText
        MattMinimalFramesDB.showHPPercentText = d.showHPPercentText
        MattMinimalFramesDB.hpTextUseShortValue = d.hpTextUseShortValue
        -- Power bar size
        MattMinimalFramesDB.showPlayerPowerBar = d.showPlayerPowerBar
        MattMinimalFramesDB.showTargetPowerBar = d.showTargetPowerBar
        MattMinimalFramesDB.showPlayerPowerText = d.showPlayerPowerText
        MattMinimalFramesDB.showTargetPowerText = d.showTargetPowerText
        MattMinimalFramesDB.showPlayerPowerPercentText = d.showPlayerPowerPercentText
        MattMinimalFramesDB.showTargetPowerPercentText = d.showTargetPowerPercentText
        MattMinimalFramesDB.showPowerPercentText = d.showPowerPercentText
        MattMinimalFramesDB.colorPlayerPowerTextByResource = d.colorPlayerPowerTextByResource
        MattMinimalFramesDB.colorTargetPowerTextByResource = d.colorTargetPowerTextByResource
        MattMinimalFramesDB.playerBarColorMode = d.playerBarColorMode or "class"
        MattMinimalFramesDB.targetBarColorMode = d.targetBarColorMode or "default"
        MattMinimalFramesDB.totBarColorMode = d.totBarColorMode or "default"
        MattMinimalFramesDB.focusBarColorMode = d.focusBarColorMode or "default"
        MattMinimalFramesDB.petBarColorMode = d.petBarColorMode or "default"
        MattMinimalFramesDB.playerBarCustomColorR = d.playerBarCustomColorR or 1.0
        MattMinimalFramesDB.playerBarCustomColorG = d.playerBarCustomColorG or 1.0
        MattMinimalFramesDB.playerBarCustomColorB = d.playerBarCustomColorB or 1.0
        MattMinimalFramesDB.targetBarCustomColorR = d.targetBarCustomColorR or 0.8
        MattMinimalFramesDB.targetBarCustomColorG = d.targetBarCustomColorG or 0.2
        MattMinimalFramesDB.targetBarCustomColorB = d.targetBarCustomColorB or 0.2
        MattMinimalFramesDB.totBarCustomColorR = d.totBarCustomColorR or 0.8
        MattMinimalFramesDB.totBarCustomColorG = d.totBarCustomColorG or 0.2
        MattMinimalFramesDB.totBarCustomColorB = d.totBarCustomColorB or 0.2
        MattMinimalFramesDB.focusBarCustomColorR = d.focusBarCustomColorR or 0.8
        MattMinimalFramesDB.focusBarCustomColorG = d.focusBarCustomColorG or 0.2
        MattMinimalFramesDB.focusBarCustomColorB = d.focusBarCustomColorB or 0.2
        MattMinimalFramesDB.petBarCustomColorR = d.petBarCustomColorR or 0.2
        MattMinimalFramesDB.petBarCustomColorG = d.petBarCustomColorG or 0.8
        MattMinimalFramesDB.petBarCustomColorB = d.petBarCustomColorB or 0.2
        MattMinimalFramesDB.frameColorAlpha = d.frameColorAlpha or 1.0
        MattMinimalFramesDB.powerBarWidth = d.powerBarWidth
        MattMinimalFramesDB.powerBarHeight = d.powerBarHeight
        MattMinimalFramesDB.powerTextScale = d.powerTextScale or 1.0
        MattMinimalFramesDB.playerPowerTextScale = d.playerPowerTextScale or d.powerTextScale or 1.0
        MattMinimalFramesDB.targetPowerTextScale = d.targetPowerTextScale or d.powerTextScale or 1.0
        MattMinimalFramesDB.playerPowerBarWidth = d.playerPowerBarWidth or d.powerBarWidth
        MattMinimalFramesDB.playerPowerBarHeight = d.playerPowerBarHeight or d.powerBarHeight
        MattMinimalFramesDB.targetPowerBarWidth = d.targetPowerBarWidth or d.powerBarWidth
        MattMinimalFramesDB.targetPowerBarHeight = d.targetPowerBarHeight or d.powerBarHeight
        MattMinimalFramesDB.powerBarVerticalOffset = d.powerBarVerticalOffset or -24
        MattMinimalFramesDB.powerBarHorizontalOffset = d.powerBarHorizontalOffset or 4
        MattMinimalFramesDB.powerBarPositions = nil
        MattMinimalFramesDB.powerTextPositions = nil
        MattMinimalFramesDB.castBarPositions = nil
        MattMinimalFramesDB.powerBarSizeUnit = "player"
        if MMF_UpdatePowerBarVisibility then
            MMF_UpdatePowerBarVisibility()
        end
        if MMF_RequestUnitUpdate then
            MMF_RequestUnitUpdate("player")
            MMF_RequestUnitUpdate("target")
        elseif MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local playerFrame = MMF_GetFrameForUnit("player")
            if playerFrame then MMF_UpdateUnitFrame(playerFrame) end
            local targetFrame = MMF_GetFrameForUnit("target")
            if targetFrame then MMF_UpdateUnitFrame(targetFrame) end
        end
        if MMF_RefreshPowerTextOptionStates then
            MMF_RefreshPowerTextOptionStates()
        end
        -- Class resource bars (legacy scales + new layout keys)
        MattMinimalFramesDB.runeBarScale = d.runeBarScale
        MattMinimalFramesDB.holyPowerBarScale = d.holyPowerBarScale
        MattMinimalFramesDB.comboPointBarScale = d.comboPointBarScale
        MattMinimalFramesDB.soulShardBarScale = d.soulShardBarScale
        MattMinimalFramesDB.chiBarScale = d.chiBarScale
        MattMinimalFramesDB.arcaneChargeBarScale = d.arcaneChargeBarScale
        MattMinimalFramesDB.essenceBarScale = d.essenceBarScale
        MattMinimalFramesDB.runeBarWidth = d.runeBarWidth
        MattMinimalFramesDB.runeBarHeight = d.runeBarHeight
        MattMinimalFramesDB.runeBarSpacing = d.runeBarSpacing
        MattMinimalFramesDB.runeBarX = d.runeBarX
        MattMinimalFramesDB.runeBarY = d.runeBarY
        MattMinimalFramesDB.holyPowerBarWidth = d.holyPowerBarWidth
        MattMinimalFramesDB.holyPowerBarHeight = d.holyPowerBarHeight
        MattMinimalFramesDB.holyPowerBarSpacing = d.holyPowerBarSpacing
        MattMinimalFramesDB.holyPowerBarX = d.holyPowerBarX
        MattMinimalFramesDB.holyPowerBarY = d.holyPowerBarY
        MattMinimalFramesDB.comboPointBarWidth = d.comboPointBarWidth
        MattMinimalFramesDB.comboPointBarHeight = d.comboPointBarHeight
        MattMinimalFramesDB.comboPointBarSpacing = d.comboPointBarSpacing
        MattMinimalFramesDB.comboPointBarX = d.comboPointBarX
        MattMinimalFramesDB.comboPointBarY = d.comboPointBarY
        MattMinimalFramesDB.soulShardBarWidth = d.soulShardBarWidth
        MattMinimalFramesDB.soulShardBarHeight = d.soulShardBarHeight
        MattMinimalFramesDB.soulShardBarSpacing = d.soulShardBarSpacing
        MattMinimalFramesDB.soulShardBarX = d.soulShardBarX
        MattMinimalFramesDB.soulShardBarY = d.soulShardBarY
        MattMinimalFramesDB.chiBarWidth = d.chiBarWidth
        MattMinimalFramesDB.chiBarHeight = d.chiBarHeight
        MattMinimalFramesDB.chiBarSpacing = d.chiBarSpacing
        MattMinimalFramesDB.chiBarX = d.chiBarX
        MattMinimalFramesDB.chiBarY = d.chiBarY
        MattMinimalFramesDB.arcaneChargeBarWidth = d.arcaneChargeBarWidth
        MattMinimalFramesDB.arcaneChargeBarHeight = d.arcaneChargeBarHeight
        MattMinimalFramesDB.arcaneChargeBarSpacing = d.arcaneChargeBarSpacing
        MattMinimalFramesDB.arcaneChargeBarX = d.arcaneChargeBarX
        MattMinimalFramesDB.arcaneChargeBarY = d.arcaneChargeBarY
        MattMinimalFramesDB.essenceBarWidth = d.essenceBarWidth
        MattMinimalFramesDB.essenceBarHeight = d.essenceBarHeight
        MattMinimalFramesDB.essenceBarSpacing = d.essenceBarSpacing
        MattMinimalFramesDB.essenceBarX = d.essenceBarX
        MattMinimalFramesDB.essenceBarY = d.essenceBarY
        -- Frame scales
        MattMinimalFramesDB.playerFrameScaleX = d.playerFrameScaleX
        MattMinimalFramesDB.playerFrameScaleY = d.playerFrameScaleY
        MattMinimalFramesDB.targetFrameScaleX = d.targetFrameScaleX
        MattMinimalFramesDB.targetFrameScaleY = d.targetFrameScaleY
        MattMinimalFramesDB.totFrameScaleX = d.totFrameScaleX
        MattMinimalFramesDB.totFrameScaleY = d.totFrameScaleY
        MattMinimalFramesDB.focusFrameScaleX = d.focusFrameScaleX
        MattMinimalFramesDB.focusFrameScaleY = d.focusFrameScaleY
        MattMinimalFramesDB.petFrameScaleX = d.petFrameScaleX
        MattMinimalFramesDB.petFrameScaleY = d.petFrameScaleY
        MattMinimalFramesDB.bossFrameScaleX = d.bossFrameScaleX or 1.0
        MattMinimalFramesDB.bossFrameScaleY = d.bossFrameScaleY or 1.0
        -- Cast bar scales (all supported cast bars)
        MattMinimalFramesDB.playerCastBarFrameScaleX = d.playerCastBarFrameScaleX or 1.0
        MattMinimalFramesDB.playerCastBarFrameScaleY = d.playerCastBarFrameScaleY or 1.0
        MattMinimalFramesDB.targetCastBarFrameScaleX = d.targetCastBarFrameScaleX or 1.0
        MattMinimalFramesDB.targetCastBarFrameScaleY = d.targetCastBarFrameScaleY or 1.0
        MattMinimalFramesDB.focusCastBarFrameScaleX = d.focusCastBarFrameScaleX or 1.0
        MattMinimalFramesDB.focusCastBarFrameScaleY = d.focusCastBarFrameScaleY or 1.0
        -- Cast bar text sizes (all supported cast bars)
        MattMinimalFramesDB.playerCastBarSpellNameTextSize = d.playerCastBarSpellNameTextSize or 12
        MattMinimalFramesDB.playerCastBarCastTimeTextSize = d.playerCastBarCastTimeTextSize or 9
        MattMinimalFramesDB.targetCastBarSpellNameTextSize = d.targetCastBarSpellNameTextSize or 12
        MattMinimalFramesDB.targetCastBarCastTimeTextSize = d.targetCastBarCastTimeTextSize or 9
        MattMinimalFramesDB.focusCastBarSpellNameTextSize = d.focusCastBarSpellNameTextSize or 12
        MattMinimalFramesDB.focusCastBarCastTimeTextSize = d.focusCastBarCastTimeTextSize or 9
        MattMinimalFramesDB.playerFrameIconScale = d.playerFrameIconScale or 1.0
        MattMinimalFramesDB.targetFrameIconScale = d.targetFrameIconScale or 1.0
        MattMinimalFramesDB.popupSize = {
            width = (MMF_GetPopupLayout and MMF_GetPopupLayout().width) or 920,
            height = (MMF_GetPopupLayout and MMF_GetPopupLayout().height) or 748,
        }
        StaticPopup_Show("MMF_RELOADUI")
end
