local function Install(deps)
    deps = deps or {}

    local function getIconAPI()
        return _G.MMF_FrameFactoryIconAPI or {}
    end

    local function getMainFactory()
        return _G.MMF_FrameFactoryMain or {}
    end

    local function getPVPUtils()
        return _G.MMF_FrameFactoryPVPIndicator or {}
    end

    _G.MMF_CreateSecureUnitFrame = function(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
        local mainFactory = getMainFactory()
        if mainFactory.CreateSecureUnitFrame then
            return mainFactory.CreateSecureUnitFrame(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
        end
        error("MMF_FrameFactoryMain.CreateSecureUnitFrame is unavailable; check TOC load order.", 2)
    end

    local originalCreate = _G.MMF_CreateSecureUnitFrame
    _G.MMF_CreateSecureUnitFrame = function(...)
        local frame = originalCreate(...)

        if frame.powerBarFrame then
            local showPowerBar = true
            if frame.unit == "player" then
                showPowerBar = not (MattMinimalFramesDB and MattMinimalFramesDB.showPlayerPowerBar == false)
            elseif frame.unit == "target" then
                showPowerBar = (MattMinimalFramesDB and MattMinimalFramesDB.showTargetPowerBar ~= false)
            end
            frame.powerBarFrame:SetShown(showPowerBar)
            if frame.powerText then
                frame.powerText:Hide()
            end
            if frame.powerTextDragFrame then
                frame.powerTextDragFrame:Hide()
            end
            if frame.hpTextDragFrame then
                frame.hpTextDragFrame:Hide()
            end
        end

        return frame
    end

    _G.MMF_SetGUIScale = function(scale)
        local normalized = (MMF_ClampGUIScale and MMF_ClampGUIScale(scale)) or scale
        if MattMinimalFramesDB then
            MattMinimalFramesDB.guiScale = normalized
        end
        if MMF_WelcomePopup then
            if MMF_WelcomePopup.ApplyGUIScale then
                MMF_WelcomePopup:ApplyGUIScale(normalized, true)
            else
                MMF_WelcomePopup:SetScale(normalized)
            end
        end
    end

    _G.MMF_UpdatePlayerClassIconVisibility = function(enabled)
        local api = getIconAPI()
        if api.UpdatePlayerClassIconVisibility then
            return api.UpdatePlayerClassIconVisibility(enabled)
        end
    end

    _G.MMF_GetPlayerFrameIconMode = function()
        local api = getIconAPI()
        if api.GetPlayerFrameIconMode then
            return api.GetPlayerFrameIconMode()
        end
        if deps.GetPlayerFrameIconModeFallback then
            return deps.GetPlayerFrameIconModeFallback()
        end
        return "off"
    end

    _G.MMF_UpdateTargetFrameIconVisibility = function(enabled)
        local api = getIconAPI()
        if api.UpdateTargetFrameIconVisibility then
            return api.UpdateTargetFrameIconVisibility(enabled)
        end
    end

    _G.MMF_GetTargetFrameIconMode = function()
        local api = getIconAPI()
        if api.GetTargetFrameIconMode then
            return api.GetTargetFrameIconMode()
        end
        if deps.GetTargetFrameIconModeFallback then
            return deps.GetTargetFrameIconModeFallback()
        end
        return "off"
    end

    _G.MMF_UpdateTargetMarkers = function()
        local api = getIconAPI()
        if api.UpdateTargetMarkers then
            return api.UpdateTargetMarkers()
        end
    end

    _G.MMF_UpdateTargetMarkerVisibility = function(enabled)
        local api = getIconAPI()
        if api.UpdateTargetMarkerVisibility then
            return api.UpdateTargetMarkerVisibility(enabled)
        end
    end

    _G.MMF_UpdatePVPFlagIndicator = function(frame)
        local pvp = getPVPUtils()
        if pvp.UpdatePVPFlagIndicator then
            return pvp.UpdatePVPFlagIndicator(frame)
        end
        if deps.UpdatePVPFlagIndicatorFallback then
            return deps.UpdatePVPFlagIndicatorFallback(frame)
        end
    end

    _G.MMF_ApplyFrameIconPlacement = function(frame)
        local api = getIconAPI()
        if api.ApplyFrameIconPlacement then
            return api.ApplyFrameIconPlacement(frame)
        end
        if deps.ApplyFrameIconPlacementFallback then
            return deps.ApplyFrameIconPlacementFallback(frame)
        end
    end

    _G.MMF_UpdateFrameIconPlacement = function(unit)
        local api = getIconAPI()
        if api.UpdateFrameIconPlacement then
            return api.UpdateFrameIconPlacement(unit)
        end

        if deps.ApplyFrameIconPlacementFallback then
            deps.ApplyFrameIconPlacementFallback(MMF_PlayerFrame)
            deps.ApplyFrameIconPlacementFallback(MMF_TargetFrame)
        end
        if _G.MMF_UpdatePlayerClassIconVisibility then
            _G.MMF_UpdatePlayerClassIconVisibility(_G.MMF_GetPlayerFrameIconMode and _G.MMF_GetPlayerFrameIconMode())
        end
        if _G.MMF_UpdateTargetFrameIconVisibility then
            _G.MMF_UpdateTargetFrameIconVisibility(_G.MMF_GetTargetFrameIconMode and _G.MMF_GetTargetFrameIconMode())
        end
    end

    local api = getIconAPI()
    if api.InitializeEvents then
        api.InitializeEvents()
    end
end

_G.MMF_FrameFactoryPublicAPI = {
    Install = Install,
}
