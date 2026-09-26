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
    f:SetSize(width, height)
    f.originalWidth = width
    f.originalHeight = height
    f.unit = unit

    deps.ResetSecureAttributes(f)
    deps.CreateTooltipHandlers(f)
    deps.RestoreFramePosition(f, frameName, point, relPoint, xOfs, yOfs)
    MMF_Visuals.Create(f, {mode="live", unitKey=MMF_Designer.Key(unit), unitToken=unit})

    return f
end

_G.MMF_FrameFactoryMain = {
    CreateSecureUnitFrame = CreateSecureUnitFrame,
}
