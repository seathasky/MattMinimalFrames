local Compat = _G.MMF_Compat

local COMBAT_ICON_BASE_SCALE = 1.00
local COMBAT_ICON_BREATH_DELTA = 0.06
local COMBAT_ICON_BREATH_PERIOD = 0.6
local COMBAT_BORDER_IDLE_ALPHA = 0.32
local COMBAT_BORDER_PULSE_MIN_ALPHA = 0.24
local COMBAT_BORDER_PULSE_MAX_ALPHA = 0.58
local COMBAT_BORDER_RED_GB = 0.62
local COMBAT_FRAME_OUTLINE_IDLE_ALPHA = 0.50
local COMBAT_FRAME_OUTLINE_PULSE_MIN_ALPHA = 0.40
local COMBAT_FRAME_OUTLINE_PULSE_MAX_ALPHA = 0.95
local COMBAT_FRAME_OUTLINE_RED_GB = 0.35

local function IsPlayerInCombat()
    if UnitAffectingCombat then
        return UnitAffectingCombat("player") == true
    end
    return InCombatLockdown and InCombatLockdown() or false
end

local function SetCombatOutlineColor(frame, r, g, b, a)
    if not frame or not frame.combatIconOutlineTextures then
        return
    end
    for _, tex in ipairs(frame.combatIconOutlineTextures) do
        tex:SetVertexColor(r, g, b, a)
    end
end

local function SetCombatFrameOutlineColor(frame, r, g, b, a)
    if not frame or not frame.combatFrameOutlineEdges then
        return
    end
    for _, edge in pairs(frame.combatFrameOutlineEdges) do
        edge:SetColorTexture(r, g, b, a)
    end
end

local function IsCombatFrameOutlineEnabled()
    if not MattMinimalFramesDB then
        return false
    end
    return MattMinimalFramesDB.combatFrameOutline == true
end

local function IsCombatIconHidden()
    return MattMinimalFramesDB and MattMinimalFramesDB.hideCombatIcon == true
end

local function SetPlayerCombatVisual(frame, isInCombat)
    if not frame or not frame.combatTexture then
        return
    end

    local frameOutlineEnabled = IsCombatFrameOutlineEnabled()
    local hideCombatIcon = IsCombatIconHidden()

    frame.combatTexture:SetShown(isInCombat == true and not hideCombatIcon)
    if frame.combatIconOutlineTextures then
        for _, tex in ipairs(frame.combatIconOutlineTextures) do
            tex:SetShown(isInCombat == true and not hideCombatIcon)
        end
    end
    if frame.combatFrameOutlineEdges then
        for _, edge in pairs(frame.combatFrameOutlineEdges) do
            edge:SetShown(isInCombat == true and frameOutlineEnabled)
        end
    end

    if not frame.combatUsesAnimation then
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Hide()
        end
        frame.combatTexture:SetScale(1)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
        return
    end

    if isInCombat then
        frame.combatTexture:SetScale(COMBAT_ICON_BASE_SCALE)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        frame.combatPulseStart = GetTime and GetTime() or 0
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Show()
        end
    else
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Hide()
        end
        frame.combatTexture:SetScale(1)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
    end
end

local function CreateCombatIconOutline(frame)
    if not frame or not frame.nameOverlay or not frame.combatTexture or frame.combatIconOutlineTextures then
        return
    end

    local offsets = {
        { -0.5, 0 }, { 0.5, 0 }, { 0, -0.5 }, { 0, 0.5 },
    }

    frame.combatIconOutlineTextures = {}
    for _, offset in ipairs(offsets) do
        local dx, dy = offset[1], offset[2]
        local tex = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 6)
        tex:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        tex:SetTexCoord(0.5, 1, 0, 0.49)
        tex:SetVertexColor(1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        tex:SetPoint("TOPLEFT", frame.combatTexture, "TOPLEFT", dx, dy)
        tex:SetPoint("BOTTOMRIGHT", frame.combatTexture, "BOTTOMRIGHT", dx, dy)
        tex:Hide()
        frame.combatIconOutlineTextures[#frame.combatIconOutlineTextures + 1] = tex
    end
end

local function IsAnimatedCombatIconEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    if IsCombatIconHidden() then
        return false
    end
    return MattMinimalFramesDB.animatedCombatIcon ~= false
end

local function CreateCombatFrameOutline(frame)
    if not frame or frame.combatFrameOutlineEdges then
        return
    end

    local edges = {
        top = frame:CreateTexture(nil, "OVERLAY", nil, 7),
        right = frame:CreateTexture(nil, "OVERLAY", nil, 7),
        bottom = frame:CreateTexture(nil, "OVERLAY", nil, 7),
        left = frame:CreateTexture(nil, "OVERLAY", nil, 7),
    }
    local edgeSize = 1

    edges.top:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    edges.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    edges.top:SetHeight(edgeSize)

    edges.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
    edges.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    edges.bottom:SetHeight(edgeSize)

    edges.left:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    edges.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
    edges.left:SetWidth(edgeSize)

    edges.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    edges.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    edges.right:SetWidth(edgeSize)

    frame.combatFrameOutlineEdges = edges
    SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
    for _, edge in pairs(edges) do
        edge:Hide()
    end
end

local function ConfigurePlayerCombatTexture(frame)
    if not frame or not frame.combatTexture then
        return
    end

    local canUsePulse = IsAnimatedCombatIconEnabled() or IsCombatFrameOutlineEnabled()
    if canUsePulse then
        frame.combatUsesAnimation = true
        frame.combatTexture:SetScale(COMBAT_ICON_BASE_SCALE)
        if not frame.combatPulseDriver then
            local pulseDriver = CreateFrame("Frame", nil, frame)
            pulseDriver:Hide()
            pulseDriver:SetScript("OnUpdate", function()
                if not frame.combatTexture or not frame.combatTexture:IsShown() then
                    return
                end
                local now = GetTime and GetTime() or 0
                local startTime = frame.combatPulseStart or now
                local period = COMBAT_ICON_BREATH_PERIOD
                if period <= 0 then
                    period = 2.0
                end
                local phase = ((now - startTime) / period) * (2 * math.pi)
                local normalized = (math.sin(phase - (math.pi * 0.5)) + 1) * 0.5
                local scale = COMBAT_ICON_BASE_SCALE + (COMBAT_ICON_BREATH_DELTA * normalized)
                local alpha = COMBAT_BORDER_PULSE_MIN_ALPHA + ((COMBAT_BORDER_PULSE_MAX_ALPHA - COMBAT_BORDER_PULSE_MIN_ALPHA) * normalized)
                local frameAlpha = COMBAT_FRAME_OUTLINE_PULSE_MIN_ALPHA + ((COMBAT_FRAME_OUTLINE_PULSE_MAX_ALPHA - COMBAT_FRAME_OUTLINE_PULSE_MIN_ALPHA) * normalized)

                if IsAnimatedCombatIconEnabled() then
                    frame.combatTexture:SetScale(scale)
                else
                    frame.combatTexture:SetScale(1)
                end
                frame.combatTexture:SetVertexColor(1, 1, 1, 1)
                SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, alpha)
                if IsCombatFrameOutlineEnabled() then
                    SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, frameAlpha)
                else
                    SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
                end
            end)
            frame.combatPulseDriver = pulseDriver
        end
    else
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Hide()
        end
        frame.combatUsesAnimation = false
        frame.combatTexture:SetScale(1)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
    end
end

local function SetPlayerRestingVisual(frame, isResting)
    if not frame or not frame.restingTexture then
        return
    end

    local hideRestingIcon = MattMinimalFramesDB and MattMinimalFramesDB.hideRestingIcon == true
    if hideRestingIcon then
        frame.restingTexture:Hide()
        if frame.restingAnim and frame.restingUsesAnimation then
            frame.restingAnim:Stop()
        end
        return
    end

    frame.restingTexture:SetShown(isResting == true)
    if not frame.restingAnim or not frame.restingUsesAnimation then
        return
    end

    if isResting then
        if not frame.restingAnim:IsPlaying() then
            frame.restingAnim:Play()
        end
    else
        frame.restingAnim:Stop()
    end
end

local function IsAnimatedRestingIconEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.animatedRestingIcon ~= false
end

local function ConfigurePlayerRestingTexture(frame)
    if not frame or not frame.restingTexture then
        return
    end

    local canUseFlipbook = (Compat and Compat.IsRetail)
        and frame.restingTexture.SetAtlas
        and frame.restingTexture.CreateAnimationGroup
        and IsAnimatedRestingIconEnabled()

    if canUseFlipbook then
        frame.restingTexture:SetAtlas("UI-HUD-UnitFrame-Player-Rest-Flipbook")
        frame.restingTexture:SetTexCoord(0, 1, 0, 1)
        frame.restingTexture:SetSize(24, 24)
        frame.restingUsesAnimation = true

        if not frame.restingAnim then
            local animGroup = frame.restingTexture:CreateAnimationGroup()
            animGroup:SetLooping("REPEAT")
            animGroup:SetToFinalAlpha(true)

            local flipBook = animGroup:CreateAnimation("FlipBook")
            if flipBook then
                flipBook:SetOrder(1)
                flipBook:SetDuration(1.5)
                if flipBook.SetSmoothing then flipBook:SetSmoothing("NONE") end
                if flipBook.SetFlipBookRows then flipBook:SetFlipBookRows(7) end
                if flipBook.SetFlipBookColumns then flipBook:SetFlipBookColumns(6) end
                if flipBook.SetFlipBookFrames then flipBook:SetFlipBookFrames(42) end
                if flipBook.SetFlipBookFrameWidth then flipBook:SetFlipBookFrameWidth(0) end
                if flipBook.SetFlipBookFrameHeight then flipBook:SetFlipBookFrameHeight(0) end
            end
            frame.restingAnim = animGroup
        end
    else
        if frame.restingAnim then
            frame.restingAnim:Stop()
        end
        frame.restingTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        frame.restingTexture:SetTexCoord(0, 0.5, 0, 0.421875)
        frame.restingTexture:SetSize(20, 20)
        frame.restingUsesAnimation = false
    end

    frame.restingTexture:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 10)
    frame.restingTexture:SetDrawLayer("OVERLAY", 7)
end

local function UpdatePlayerRestingIndicator()
    if not _G.MMF_PlayerFrame then
        return
    end
    SetPlayerRestingVisual(_G.MMF_PlayerFrame, IsResting())
end

local function UpdatePlayerCombatIndicator()
    if not _G.MMF_PlayerFrame then
        return
    end
    SetPlayerCombatVisual(_G.MMF_PlayerFrame, IsPlayerInCombat())
end

local function UpdateAnimatedRestingIconSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.animatedRestingIcon = (enabled == true)
    elseif MattMinimalFramesDB.animatedRestingIcon == nil then
        MattMinimalFramesDB.animatedRestingIcon = true
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.restingTexture then
        ConfigurePlayerRestingTexture(_G.MMF_PlayerFrame)
        SetPlayerRestingVisual(_G.MMF_PlayerFrame, IsResting())
    end
end

local function UpdateHideRestingIconSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.hideRestingIcon = (enabled == true)
    elseif MattMinimalFramesDB.hideRestingIcon == nil then
        MattMinimalFramesDB.hideRestingIcon = false
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.restingTexture then
        ConfigurePlayerRestingTexture(_G.MMF_PlayerFrame)
        SetPlayerRestingVisual(_G.MMF_PlayerFrame, IsResting())
    end
end

local function UpdateAnimatedCombatIconSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.animatedCombatIcon = (enabled == true)
    elseif MattMinimalFramesDB.animatedCombatIcon == nil then
        MattMinimalFramesDB.animatedCombatIcon = true
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.combatTexture then
        ConfigurePlayerCombatTexture(_G.MMF_PlayerFrame)
        SetPlayerCombatVisual(_G.MMF_PlayerFrame, IsPlayerInCombat())
    end
end

local function UpdateHideCombatIconSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.hideCombatIcon = (enabled == true)
    elseif MattMinimalFramesDB.hideCombatIcon == nil then
        MattMinimalFramesDB.hideCombatIcon = false
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.combatTexture then
        ConfigurePlayerCombatTexture(_G.MMF_PlayerFrame)
        SetPlayerCombatVisual(_G.MMF_PlayerFrame, IsPlayerInCombat())
    end
end

local function UpdateCombatFrameOutlineSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.combatFrameOutline = (enabled == true)
    elseif MattMinimalFramesDB.combatFrameOutline == nil then
        MattMinimalFramesDB.combatFrameOutline = false
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.combatTexture then
        ConfigurePlayerCombatTexture(_G.MMF_PlayerFrame)
        SetPlayerCombatVisual(_G.MMF_PlayerFrame, IsPlayerInCombat())
    end
end

local function CreatePlayerIndicators(frame)
    frame.combatTexture = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.combatTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.combatTexture:SetTexCoord(0.5, 1, 0, 0.49)
    frame.combatTexture:SetSize(22, 22)
    frame.combatTexture:SetPoint("CENTER", frame, "CENTER", 0, 12)
    frame.combatTexture:SetDrawLayer("OVERLAY", 7)
    CreateCombatIconOutline(frame)
    CreateCombatFrameOutline(frame)
    ConfigurePlayerCombatTexture(frame)
    SetPlayerCombatVisual(frame, IsPlayerInCombat())

    frame.restingTexture = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    ConfigurePlayerRestingTexture(frame)
    SetPlayerRestingVisual(frame, IsResting())
end

_G.MMF_FrameFactoryIndicators = {
    CreatePlayerIndicators = CreatePlayerIndicators,
    UpdatePlayerRestingIndicator = UpdatePlayerRestingIndicator,
    UpdatePlayerCombatIndicator = UpdatePlayerCombatIndicator,
    UpdateAnimatedRestingIconSetting = UpdateAnimatedRestingIconSetting,
    UpdateHideRestingIconSetting = UpdateHideRestingIconSetting,
    UpdateAnimatedCombatIconSetting = UpdateAnimatedCombatIconSetting,
    UpdateHideCombatIconSetting = UpdateHideCombatIconSetting,
    UpdateCombatFrameOutlineSetting = UpdateCombatFrameOutlineSetting,
}

