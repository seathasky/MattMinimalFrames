local cfg = MMF_Config

function MMF_CreateAllMinimalFrames()
    for _, def in ipairs(cfg.FRAME_DEFINITIONS) do
        local frame = MMF_CreateSecureUnitFrame(
            def.unit,
            def.name,
            def.width,
            def.height,
            "CENTER",
            "CENTER",
            def.x,
            def.y
        )
        RegisterUnitWatch(frame)
        _G[def.name] = frame
    end

    C_Timer.After(0, function()
        if MMF_TargetFrame and MMF_TargetFrame.BuffContainer then
            MMF_TargetFrame.BuffContainer:SetShown(MattMinimalFramesDB.showBuffs ~= false)
        end

        if MMF_TargetFrame and MMF_TargetFrame.DebuffContainer then
            MMF_TargetFrame.DebuffContainer:SetShown(MattMinimalFramesDB.showDebuffs ~= false)
        end

        if MMF_PlayerFrame and MMF_PlayerFrame.powerBarFrame then
            MMF_PlayerFrame.powerBarFrame:SetShown(MattMinimalFramesDB.showPlayerPowerBar ~= false)
        end

        if MMF_TargetFrame and MMF_TargetFrame.powerBarFrame then
            MMF_TargetFrame.powerBarFrame:SetShown(MattMinimalFramesDB.showTargetPowerBar ~= false)
        end
    end)
end
