function MMF_ApplyActiveProfileLive()
    if not MattMinimalFramesDB then return end

    if InCombatLockdown() and MMF_RunAfterCombat then
        MMF_RunAfterCombat(
            "apply_active_profile_live",
            function()
                MMF_ApplyActiveProfileLive()
            end,
            "|cff00ff00Matt's Minimal Frames|r: Applying profile changes after combat."
        )
        return
    end

    local function ApplyFramePositions()
        if MMF_ApplyAllFramePositions then
            MMF_ApplyAllFramePositions()
            return
        end
        if not MMF_Config or not MMF_Config.FRAME_DEFINITIONS then return end
        for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
            local frame = _G[def.name]
            if frame then
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", def.x, def.y)
            end
        end
    end

    local function ApplyPowerBarPositions()
        if not MMF_Config then return end
        local vOff = MMF_Config.POWER_BAR_VERTICAL_OFFSET or -24
        local hOff = MMF_Config.POWER_BAR_HORIZONTAL_OFFSET or 1

        local function ApplyFor(frame, unit)
            if not frame or not frame.powerBarFrame then return end
            frame.powerBarFrame:ClearAllPoints()
            local pos = MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit]
            if pos and pos.x and pos.y then
                frame.powerBarFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
            else
                if unit == "player" then
                    frame.powerBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -hOff, vOff)
                else
                    frame.powerBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", hOff, vOff)
                end
            end
        end

        ApplyFor(_G.MMF_PlayerFrame, "player")
        ApplyFor(_G.MMF_TargetFrame, "target")
    end

    ApplyFramePositions()
    if MMF_ApplyAllFrameScales then MMF_ApplyAllFrameScales() end
    ApplyPowerBarPositions()
    if MMF_ApplyPowerTextPositions then MMF_ApplyPowerTextPositions() end
    if MMF_ApplyHPTextPositions then MMF_ApplyHPTextPositions() end
    if MMF_ApplyHealthFillDirections then MMF_ApplyHealthFillDirections() end

    if MMF_SetPowerBarSize then
        local playerPowerW = MattMinimalFramesDB.playerPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73
        local playerPowerH = MattMinimalFramesDB.playerPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5
        local targetPowerW = MattMinimalFramesDB.targetPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73
        local targetPowerH = MattMinimalFramesDB.targetPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5
        MMF_SetPowerBarSize(playerPowerW, playerPowerH, "player")
        MMF_SetPowerBarSize(targetPowerW, targetPowerH, "target")
    end
    if MMF_UpdatePowerBarVisibility then MMF_UpdatePowerBarVisibility() end

    if MMF_UpdateNameTextSize then MMF_UpdateNameTextSize(MattMinimalFramesDB.nameTextSize or 12) end
    if MMF_UpdateHPTextSize then MMF_UpdateHPTextSize(MattMinimalFramesDB.hpTextSize or 13) end
    if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end

    if MMF_UpdateBuffPosition then
        MMF_UpdateBuffPosition(MattMinimalFramesDB.buffXOffset or -2, MattMinimalFramesDB.buffYOffset or -64)
    end
    if MMF_UpdateDebuffPosition then
        MMF_UpdateDebuffPosition(MattMinimalFramesDB.debuffXOffset or 3, MattMinimalFramesDB.debuffYOffset or 27)
    end
    if MMF_UpdateAuraLayout then MMF_UpdateAuraLayout() end
    if MMF_UpdateAuraTextScale then MMF_UpdateAuraTextScale(MattMinimalFramesDB.auraTextScale or 1.0) end
    if MMF_UpdateTimerTextScale then MMF_UpdateTimerTextScale(MattMinimalFramesDB.timerTextScale or 0.8) end
    if MMF_UpdateTargetAuras then MMF_UpdateTargetAuras() end
    if MMF_UpdatePlayerAuras then MMF_UpdatePlayerAuras() end
    if MMF_UpdateFocusAuras then MMF_UpdateFocusAuras() end

    if MMF_ApplyStatusBarTexture then MMF_ApplyStatusBarTexture() end

    if MMF_UpdatePlayerClassIconVisibility then
        MMF_UpdatePlayerClassIconVisibility(MattMinimalFramesDB.playerFrameIconMode or "off")
    end
    if MMF_UpdateTargetFrameIconVisibility then
        MMF_UpdateTargetFrameIconVisibility(MattMinimalFramesDB.targetFrameIconMode or "off")
    end
    if MMF_UpdateTargetMarkerVisibility then
        MMF_UpdateTargetMarkerVisibility(MattMinimalFramesDB.showTargetMarkers == true)
    end
    if MMF_UpdateHideRestingIconSetting then
        MMF_UpdateHideRestingIconSetting(MattMinimalFramesDB.hideRestingIcon == true)
    end
    if MMF_UpdateAnimatedRestingIconSetting then
        MMF_UpdateAnimatedRestingIconSetting(MattMinimalFramesDB.animatedRestingIcon ~= false)
    end
    if MMF_UpdateHideCombatIconSetting then
        MMF_UpdateHideCombatIconSetting(MattMinimalFramesDB.hideCombatIcon == true)
    end
    if MMF_UpdateAnimatedCombatIconSetting then
        MMF_UpdateAnimatedCombatIconSetting(MattMinimalFramesDB.animatedCombatIcon ~= false)
    end
    if MMF_UpdateCombatFrameOutlineSetting then
        MMF_UpdateCombatFrameOutlineSetting(MattMinimalFramesDB.combatFrameOutline == true)
    end
    if MMF_UpdateCombatFrameVisibility then
        MMF_UpdateCombatFrameVisibility()
    end
    if MMF_UpdateBlizzardPlayerCastBarVisibility then
        MMF_UpdateBlizzardPlayerCastBarVisibility()
    end
    if MMF_UpdateBlizzardPartyRaidNameFonts then
        MMF_UpdateBlizzardPartyRaidNameFonts()
    end
    if MMF_UpdateBlizzardSoloPartyFrameVisibility then
        MMF_UpdateBlizzardSoloPartyFrameVisibility()
    end

    if MMF_InitializeClassResources then MMF_InitializeClassResources() end
    if MMF_UpdateClassBarLayoutForCurrentClass then MMF_UpdateClassBarLayoutForCurrentClass() end
    if MMF_RefreshClassResourceVisibility then MMF_RefreshClassResourceVisibility() end
    if MMF_ApplyGlobalFont then MMF_ApplyGlobalFont() end
    if MMF_ApplyPetActionBarPosition then MMF_ApplyPetActionBarPosition() end

    if MMF_ToggleMinimapButton then
        local hidden = MattMinimalFramesDB.minimap and MattMinimalFramesDB.minimap.hide
        MMF_ToggleMinimapButton(not hidden)
    end
    if MMF_ApplyToolsNoteState then
        MMF_ApplyToolsNoteState()
    end

    if MattMinimalFramesDB.locked then
        if MMF_LockFrames then MMF_LockFrames() end
    else
        if MMF_UnlockFrames then MMF_UnlockFrames() end
    end

    if MMF_GetAllFrames and MMF_UpdateUnitFrame then
        for _, frame in ipairs(MMF_GetAllFrames()) do
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end

    if MMF_WelcomePopup then
        local guiScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
        if MMF_WelcomePopup.ApplyGUIScale then
            MMF_WelcomePopup:ApplyGUIScale(guiScale, true)
        else
            MMF_WelcomePopup:SetScale(guiScale)
        end
    end
end
