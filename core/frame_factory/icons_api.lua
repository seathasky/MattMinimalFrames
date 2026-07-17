local Icons = _G.MMF_FrameFactoryIcons or {}
local TargetMarkers = _G.MMF_FrameFactoryTargetMarkers or {}

local iconEventsInitialized = false
local markerEventsInitialized = false

local function GetPlayerFrameIconMode()
    if Icons.GetPlayerFrameIconMode then
        return Icons.GetPlayerFrameIconMode()
    end
    return "off"
end

local function GetTargetFrameIconMode()
    if Icons.GetTargetFrameIconMode then
        return Icons.GetTargetFrameIconMode()
    end
    return "off"
end

local function ApplyFrameIconPlacement(frame)
    if Icons.ApplyFrameIconPlacement then
        return Icons.ApplyFrameIconPlacement(frame)
    end
end

local function ApplyPlayerFrameIconMode(frame, mode)
    if Icons.ApplyPlayerFrameIconMode then
        return Icons.ApplyPlayerFrameIconMode(frame, mode)
    end
end

local function ApplyTargetFrameIconMode(frame, mode)
    if Icons.ApplyTargetFrameIconMode then
        return Icons.ApplyTargetFrameIconMode(frame, mode)
    end
end

local function UpdateFrameTargetMarker(frame)
    if TargetMarkers.UpdateFrameTargetMarker then
        return TargetMarkers.UpdateFrameTargetMarker(frame)
    end
end

local function UpdatePlayerClassIconVisibility(enabled)
    if not MMF_PlayerFrame then
        return
    end
    if not MMF_PlayerFrame.classIcon and Icons.CreatePlayerClassIcon then
        Icons.CreatePlayerClassIcon(MMF_PlayerFrame)
    end
    if not MMF_PlayerFrame.classIcon then
        return
    end

    local mode = enabled
    if type(mode) == "boolean" then
        mode = mode and "class" or "off"
    end
    if mode == nil then
        mode = GetPlayerFrameIconMode()
    end
    if mode ~= "off" and mode ~= "class" and mode ~= "portrait" and mode ~= "portrait_zoomed" and mode ~= "portrait_more_zoomed" and mode ~= "portrait_animated" and mode ~= "sharedmedia" and mode ~= "jiberish" then
        mode = "off"
    end
    if MattMinimalFramesDB then
        MattMinimalFramesDB.playerFrameIconMode = mode
        MattMinimalFramesDB.showPlayerClassIcon = (mode == "class")
    end

    ApplyPlayerFrameIconMode(MMF_PlayerFrame, mode)

    if (mode == "portrait" or mode == "portrait_zoomed" or mode == "portrait_more_zoomed" or mode == "portrait_animated") and C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if MMF_PlayerFrame and MMF_PlayerFrame.classIcon then
                ApplyPlayerFrameIconMode(MMF_PlayerFrame, mode)
            end
        end)
    end
end

local function UpdateTargetFrameIconVisibility(enabled)
    if not MMF_TargetFrame or not MMF_TargetFrame.targetIcon then
        return
    end

    local mode = enabled
    if type(mode) == "boolean" then
        mode = mode and "class" or "off"
    end
    if mode == nil then
        mode = GetTargetFrameIconMode()
    end
    if mode ~= "off" and mode ~= "class" and mode ~= "portrait" and mode ~= "portrait_zoomed" and mode ~= "portrait_more_zoomed" and mode ~= "portrait_animated" and mode ~= "sharedmedia" and mode ~= "jiberish" then
        mode = "off"
    end
    if MattMinimalFramesDB then
        MattMinimalFramesDB.targetFrameIconMode = mode
        MattMinimalFramesDB.showTargetFrameIcon = (mode == "class")
    end

    ApplyTargetFrameIconMode(MMF_TargetFrame, mode)
end

local function UpdateTargetMarkers()
    local frames = MMF_GetAllFrames and MMF_GetAllFrames() or {}
    for _, frame in ipairs(frames) do
        UpdateFrameTargetMarker(frame)
    end
end

local function UpdateTargetMarkerVisibility(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled == nil then
        enabled = MattMinimalFramesDB.showTargetMarkers == true
    end
    MattMinimalFramesDB.showTargetMarkers = enabled and true or false
    UpdateTargetMarkers()
end

local function UpdateFrameIconPlacement(unit)
    if unit == "player" then
        ApplyFrameIconPlacement(MMF_PlayerFrame)
        UpdatePlayerClassIconVisibility(GetPlayerFrameIconMode())
        return
    end

    if unit == "target" then
        ApplyFrameIconPlacement(MMF_TargetFrame)
        UpdateTargetFrameIconVisibility(GetTargetFrameIconMode())
        return
    end

    ApplyFrameIconPlacement(MMF_PlayerFrame)
    ApplyFrameIconPlacement(MMF_TargetFrame)
    UpdatePlayerClassIconVisibility(GetPlayerFrameIconMode())
    UpdateTargetFrameIconVisibility(GetTargetFrameIconMode())
end

local function InitializeIconEvents()
    if iconEventsInitialized then
        return
    end
    iconEventsInitialized = true

    local iconEventFrame = CreateFrame("Frame")
    iconEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    iconEventFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
    iconEventFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "target")
    iconEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    iconEventFrame:SetScript("OnEvent", function(_, _, unit)
        if Compat and Compat.GetAccessibleUnitToken then
            unit = Compat.GetAccessibleUnitToken(unit)
        end
        if (not unit or unit == "player") and GetPlayerFrameIconMode() ~= "off" then
            UpdatePlayerClassIconVisibility(GetPlayerFrameIconMode())
        end
        if (not unit or unit == "target") and GetTargetFrameIconMode() ~= "off" then
            UpdateTargetFrameIconVisibility(GetTargetFrameIconMode())
        end
    end)
end

local function InitializeMarkerEvents()
    if markerEventsInitialized then
        return
    end
    markerEventsInitialized = true

    local markerEventFrame = CreateFrame("Frame")
    markerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    markerEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    markerEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    markerEventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    markerEventFrame:RegisterEvent("UNIT_TARGET")
    markerEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    markerEventFrame:SetScript("OnEvent", function()
        UpdateTargetMarkers()
    end)
end

local function InitializeEvents()
    InitializeIconEvents()
    InitializeMarkerEvents()
end

_G.MMF_FrameFactoryIconAPI = {
    GetPlayerFrameIconMode = GetPlayerFrameIconMode,
    GetTargetFrameIconMode = GetTargetFrameIconMode,
    UpdatePlayerClassIconVisibility = UpdatePlayerClassIconVisibility,
    UpdateTargetFrameIconVisibility = UpdateTargetFrameIconVisibility,
    UpdateTargetMarkers = UpdateTargetMarkers,
    UpdateTargetMarkerVisibility = UpdateTargetMarkerVisibility,
    ApplyFrameIconPlacement = ApplyFrameIconPlacement,
    UpdateFrameIconPlacement = UpdateFrameIconPlacement,
    InitializeEvents = InitializeEvents,
}
