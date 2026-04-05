local function CreateSecureUnitFrame(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
    local deps = _G.MMF_FrameFactoryMainDeps or {}
    local Compat = deps.Compat

    local unitButtonTemplate = "SecureUnitButtonTemplate"
    if Compat and Compat.IsRetail then
        unitButtonTemplate = "SecureUnitButtonTemplate, PingableUnitFrameTemplate"
    end

    local ok, f = pcall(CreateFrame, "Button", frameName, UIParent, unitButtonTemplate)
    if not ok or not f then
        f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")
    end
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForClicks("AnyUp")
    f:RegisterForDrag("LeftButton")
    f:SetSize(width, height)
    f.originalWidth = width
    f.originalHeight = height
    f.unit = unit

    deps.ResetSecureAttributes(f)
    deps.CreateTooltipHandlers(f)
    deps.RestoreFramePosition(f, frameName, point, relPoint, xOfs, yOfs)
    deps.CreateDragHandlers(f, frameName)
    deps.CreateHealthBar(f)

    if unit == "player" or unit == "target" then
        deps.CreatePowerBarContainer(f, unit)
    end

    if unit == "player" or unit == "target" or unit == "targettarget" then
        deps.CreateHealPredictionBar(f)
        deps.CreateAbsorbBar(f)
    end

    f.highlightOverlay = CreateFrame("Frame", nil, f)
    f.highlightOverlay:SetAllPoints(f)
    f.highlightOverlay:SetFrameLevel((f:GetFrameLevel() or 1) + 30)
    f.highlightOverlay:EnableMouse(false)

    f.highlightTexture = f.highlightOverlay:CreateTexture(nil, "OVERLAY")
    f.highlightTexture:SetAllPoints(f.highlightOverlay)
    f.highlightTexture:SetColorTexture(1, 1, 1, 0.2)
    f.highlightTexture:Hide()

    deps.CreateNameText(f, unit)
    deps.CreateResourceText(f, unit)
    deps.CreatePVPFlagIndicator(f, unit)
    deps.CreateTargetMarker(f)

    if unit == "player" or unit == "target" then
        deps.SetupPowerBar(f, unit)
    end

    if unit == "player" then
        deps.CreatePlayerClassIcon(f)
        deps.CreatePlayerIndicators(f)
    elseif unit == "target" then
        deps.CreateTargetFrameIcon(f)
    end

    if unit == "player" or unit == "target" or unit == "focus" then
        deps.CreateCastBar(f, unit)
    end

    return f
end

_G.MMF_FrameFactoryMain = {
    CreateSecureUnitFrame = CreateSecureUnitFrame,
}

