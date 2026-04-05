local function Install(positioningUtils, positioningModule)
    positioningUtils = positioningUtils or _G.MMF_FrameFactoryPositioningUtils or {}
    positioningModule = positioningModule or _G.MMF_FrameFactoryPositioning or {}

    _G.MMF_ClearLegacyFramePosition = positioningUtils.ClearLegacyFramePositionForUnit or function() end
    _G.MMF_SyncFramePositionControlsForUnit = positioningUtils.UpdateFramePositionControlsForUnit or function() end

    _G.MMF_ApplyFramePositionByUnit = function(unit)
        if positioningModule.ApplyFramePositionByUnit then
            return positioningModule.ApplyFramePositionByUnit(unit)
        end
    end

    _G.MMF_ApplyAllFramePositions = function()
        if positioningModule.ApplyAllFramePositions then
            return positioningModule.ApplyAllFramePositions()
        end
    end

    _G.MMF_ApplyFrameCenterPositionForUnit = function(unit, changedAxis)
        if positioningModule.ApplyFrameCenterPositionForUnit then
            return positioningModule.ApplyFrameCenterPositionForUnit(unit, changedAxis)
        end
    end

    _G.MMF_ResetFrameCenterPositionForUnit = function(unit)
        if positioningModule.ResetFrameCenterPositionForUnit then
            return positioningModule.ResetFrameCenterPositionForUnit(unit)
        end
    end

    _G.MMF_InitializeFrameCenterPositionsFromFrames = function()
        if positioningModule.InitializeFrameCenterPositionsFromFrames then
            return positioningModule.InitializeFrameCenterPositionsFromFrames()
        end
    end
end

_G.MMF_FrameFactoryPositioningAPI = {
    Install = Install,
}
