local function Install(deps)
    deps = deps or {}

    _G.MMF_ApplyPowerTextPosition = deps.ApplyPowerTextPosition or _G.MMF_ApplyPowerTextPosition
    _G.MMF_ApplyHPTextPosition = deps.ApplyHPTextPosition or _G.MMF_ApplyHPTextPosition

    _G.MMF_ApplyHealthFillDirections = function()
        if deps.HealthPowerUtils and deps.HealthPowerUtils.ApplyHealthFillDirections then
            return deps.HealthPowerUtils.ApplyHealthFillDirections(MMF_GetAllFrames)
        end
    end

    _G.MMF_ApplyPowerTextPositions = function()
        if deps.TextPositionUtils and deps.TextPositionUtils.ApplyPowerTextPositions then
            return deps.TextPositionUtils.ApplyPowerTextPositions()
        end
    end

    _G.MMF_ApplyHPTextPositions = function()
        if deps.TextPositionUtils and deps.TextPositionUtils.ApplyHPTextPositions then
            return deps.TextPositionUtils.ApplyHPTextPositions()
        end
    end

    _G.MMF_UpdatePlayerRestingIndicator = function()
        if deps.IndicatorsUtils and deps.IndicatorsUtils.UpdatePlayerRestingIndicator then
            return deps.IndicatorsUtils.UpdatePlayerRestingIndicator()
        end
    end

    _G.MMF_UpdatePlayerCombatIndicator = function()
        if deps.IndicatorsUtils and deps.IndicatorsUtils.UpdatePlayerCombatIndicator then
            return deps.IndicatorsUtils.UpdatePlayerCombatIndicator()
        end
    end

    _G.MMF_UpdateAnimatedRestingIconSetting = function(enabled)
        if deps.IndicatorsUtils and deps.IndicatorsUtils.UpdateAnimatedRestingIconSetting then
            return deps.IndicatorsUtils.UpdateAnimatedRestingIconSetting(enabled)
        end
    end

    _G.MMF_UpdateHideRestingIconSetting = function(enabled)
        if deps.IndicatorsUtils and deps.IndicatorsUtils.UpdateHideRestingIconSetting then
            return deps.IndicatorsUtils.UpdateHideRestingIconSetting(enabled)
        end
    end

    _G.MMF_UpdateAnimatedCombatIconSetting = function(enabled)
        if deps.IndicatorsUtils and deps.IndicatorsUtils.UpdateAnimatedCombatIconSetting then
            return deps.IndicatorsUtils.UpdateAnimatedCombatIconSetting(enabled)
        end
    end

    _G.MMF_UpdateHideCombatIconSetting = function(enabled)
        if deps.IndicatorsUtils and deps.IndicatorsUtils.UpdateHideCombatIconSetting then
            return deps.IndicatorsUtils.UpdateHideCombatIconSetting(enabled)
        end
    end

    _G.MMF_UpdateCombatFrameOutlineSetting = function(enabled)
        if deps.IndicatorsUtils and deps.IndicatorsUtils.UpdateCombatFrameOutlineSetting then
            return deps.IndicatorsUtils.UpdateCombatFrameOutlineSetting(enabled)
        end
    end
end

_G.MMF_FrameFactoryUpdateAPI = {
    Install = Install,
}
