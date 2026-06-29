local cfg = MMF_Config
local Compat = _G.MMF_Compat
local noop = function() end

local function GetStatusBarTexturePath()
    if MMF_GetStatusBarTexturePath then
        return MMF_GetStatusBarTexturePath()
    end
    return cfg.TEXTURE_PATH
end

local IconUtils = _G.MMF_FrameFactoryIcons or {}
local GetPlayerFrameIconMode = IconUtils.GetPlayerFrameIconMode or function() return "off" end
local GetTargetFrameIconMode = IconUtils.GetTargetFrameIconMode or function() return "off" end
local ApplyFrameIconPlacement = IconUtils.ApplyFrameIconPlacement or noop

local TargetMarkerUtils = _G.MMF_FrameFactoryTargetMarkers or {}
local CreateTargetMarker = TargetMarkerUtils.CreateTargetMarker or noop

--------------------------------------------------
-- FRAME POSITIONING
--------------------------------------------------

local PositioningUtils = _G.MMF_FrameFactoryPositioningUtils or {}
local PositioningModule = _G.MMF_FrameFactoryPositioning or {}
local PositioningAPI = _G.MMF_FrameFactoryPositioningAPI or {}

if PositioningAPI.Install then
    PositioningAPI.Install(PositioningUtils, PositioningModule)
end

local function SaveFramePosition(frame, frameName)
    if PositioningModule.SaveFramePosition then
        return PositioningModule.SaveFramePosition(frame, frameName)
    end
end

local CastbarOffsetUtils = _G.MMF_FrameFactoryCastbarOffsets or {}
local CastbarOffsetAPI = _G.MMF_FrameFactoryCastbarOffsetsAPI or {}

if CastbarOffsetAPI.Install then
    CastbarOffsetAPI.Install(CastbarOffsetUtils)
end

local function RestoreFramePosition(frame, frameName, defaultPoint, defaultRelPoint, defaultX, defaultY)
    if PositioningModule.RestoreFramePosition then
        return PositioningModule.RestoreFramePosition(frame, frameName, defaultPoint, defaultRelPoint, defaultX, defaultY)
    end
    if PositioningModule.ApplyFramePosition then
        return PositioningModule.ApplyFramePosition(frame, frameName, frame and frame.unit, defaultPoint, defaultRelPoint, defaultX, defaultY)
    end
end

--------------------------------------------------
-- TOOLTIP HANDLERS
--------------------------------------------------

local DragHelpers = _G.MMF_FrameFactoryDragHelpers or {}
local DragSetupUtils = _G.MMF_FrameFactoryDragSetup or {}
local ResetPopupUtils = _G.MMF_FrameFactoryResetPopup or {}
local TextPositionUtils = _G.MMF_FrameFactoryTextPositions or {}
local PowerBarUtils = _G.MMF_FrameFactoryPowerBar or {}
local HealthPowerUtils = _G.MMF_FrameFactoryHealthPower or {}
local IndicatorsUtils = _G.MMF_FrameFactoryIndicators or {}
local CastbarUtils = _G.MMF_FrameFactoryCastbar or {}
local TextUtils = _G.MMF_FrameFactoryText or {}
local PVPUtils = _G.MMF_FrameFactoryPVPIndicator or {}
local UpdateAPI = _G.MMF_FrameFactoryUpdateAPI or {}
local CreateTooltipHandlers = DragHelpers.CreateTooltipHandlers or noop
local ShowFrameResetPopup = ResetPopupUtils.ShowFrameResetPopup or noop

--------------------------------------------------
-- DRAG HANDLERS
--------------------------------------------------

local IsEditModeDragEnabled = DragHelpers.IsEditModeDragEnabled or function() return false end
local CanStartFrameDrag = DragHelpers.CanStartFrameDrag or function() return false end
local GetDragHintText = DragHelpers.GetDragHintText or function() return "Shift+Drag to move" end
local TryBeginFrameMoving = DragHelpers.TryBeginFrameMoving
local TryStopFrameMoving = DragHelpers.TryStopFrameMoving or function() return false end

_G.MMF_FrameFactoryDragSetupDeps = {
    cfg = cfg,
    SetFontSafe = MMF_SetFontSafe,
    GetFrameDefinition = MMF_GetFrameDefinition,
    IsEditModeDragEnabled = IsEditModeDragEnabled,
    CanStartFrameDrag = CanStartFrameDrag,
    GetDragHintText = GetDragHintText,
    TryBeginFrameMoving = TryBeginFrameMoving,
    TryStopFrameMoving = TryStopFrameMoving,
    SaveFramePosition = SaveFramePosition,
    ShowFrameResetPopup = ShowFrameResetPopup,
}

local CreateDragHandlers = DragSetupUtils.CreateDragHandlers or noop

_G.MMF_FrameFactoryPowerBarDeps = {
    cfg = cfg,
    GetStatusBarTexturePath = GetStatusBarTexturePath,
    CanStartFrameDrag = CanStartFrameDrag,
    TryBeginFrameMoving = TryBeginFrameMoving,
    TryStopFrameMoving = TryStopFrameMoving,
    GetDragHintText = GetDragHintText,
}

--------------------------------------------------
-- HEALTH BAR CREATION
--------------------------------------------------

local CreateHealthBar = HealthPowerUtils.CreateHealthBar or noop

--------------------------------------------------
-- POWER BAR CREATION
--------------------------------------------------

local CreatePowerBarContainer = PowerBarUtils.CreatePowerBarContainer or noop
local SetupPowerBar = PowerBarUtils.SetupPowerBar or noop

local ApplyPowerTextPosition = TextPositionUtils.ApplyPowerTextPosition or noop

MMF_ApplyPowerTextPosition = ApplyPowerTextPosition

local ApplyHPTextPosition = TextPositionUtils.ApplyHPTextPosition or noop

MMF_ApplyHPTextPosition = ApplyHPTextPosition

--------------------------------------------------
-- ABSORB BAR CREATION
--------------------------------------------------

local CreateAbsorbBar = HealthPowerUtils.CreateAbsorbBar or noop

--------------------------------------------------
-- HEAL PREDICTION BAR CREATION
--------------------------------------------------

local CreateHealPredictionBar = HealthPowerUtils.CreateHealPredictionBar or noop

--------------------------------------------------
-- TEXT ELEMENTS
--------------------------------------------------

local CreateNameText = TextUtils.CreateNameText or noop
local CreateResourceText = TextUtils.CreateResourceText or noop

if UpdateAPI.Install then
    UpdateAPI.Install({
        ApplyPowerTextPosition = ApplyPowerTextPosition,
        ApplyHPTextPosition = ApplyHPTextPosition,
        TextPositionUtils = TextPositionUtils,
        HealthPowerUtils = HealthPowerUtils,
        IndicatorsUtils = IndicatorsUtils,
    })
end

local CreatePlayerIndicators = IndicatorsUtils.CreatePlayerIndicators or noop
local CreatePlayerClassIcon = IconUtils.CreatePlayerClassIcon or noop
local CreateTargetFrameIcon = IconUtils.CreateTargetFrameIcon or noop
local CreatePVPFlagIndicator = PVPUtils.CreatePVPFlagIndicator or noop
local UpdatePVPFlagIndicator = PVPUtils.UpdatePVPFlagIndicator or noop

-- CAST BAR (Player, Target, Focus)
--------------------------------------------------

local CreateCastBar = CastbarUtils.CreateCastBar or noop

--------------------------------------------------
-- MAIN FRAME CREATION
--------------------------------------------------

_G.MMF_FrameFactoryMainDeps = {
    Compat = Compat,
    ResetSecureAttributes = MMF_ResetSecureAttributes,
    CreateTooltipHandlers = CreateTooltipHandlers,
    RestoreFramePosition = RestoreFramePosition,
    CreateDragHandlers = CreateDragHandlers,
    CreateHealthBar = CreateHealthBar,
    CreatePowerBarContainer = CreatePowerBarContainer,
    CreateHealPredictionBar = CreateHealPredictionBar,
    CreateAbsorbBar = CreateAbsorbBar,
    CreateNameText = CreateNameText,
    CreateResourceText = CreateResourceText,
    CreatePVPFlagIndicator = CreatePVPFlagIndicator,
    CreateTargetMarker = CreateTargetMarker,
    SetupPowerBar = SetupPowerBar,
    CreatePlayerClassIcon = CreatePlayerClassIcon,
    CreatePlayerIndicators = CreatePlayerIndicators,
    CreateTargetFrameIcon = CreateTargetFrameIcon,
    CreateCastBar = CreateCastBar,
}

local PublicAPI = _G.MMF_FrameFactoryPublicAPI or {}
if PublicAPI.Install then
    PublicAPI.Install({
        GetPlayerFrameIconModeFallback = GetPlayerFrameIconMode,
        GetTargetFrameIconModeFallback = GetTargetFrameIconMode,
        ApplyFrameIconPlacementFallback = ApplyFrameIconPlacement,
        UpdatePVPFlagIndicatorFallback = UpdatePVPFlagIndicator,
    })
end
