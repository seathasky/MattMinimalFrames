function MMF_SetAspectCropTexCoords(texture, holder, imageAspect)
    if not texture or not holder then
        return
    end

    local w = math.max(1, holder:GetWidth() or 1)
    local h = math.max(1, holder:GetHeight() or 1)
    local frameAspect = w / h
    local sourceAspect = imageAspect or (16 / 9)

    if frameAspect > sourceAspect then
        local visibleV = sourceAspect / frameAspect
        local padV = (1 - visibleV) * 0.5
        texture:SetTexCoord(0, 1, padV, 1 - padV)
    else
        local visibleU = frameAspect / sourceAspect
        local padU = (1 - visibleU) * 0.5
        texture:SetTexCoord(padU, 1 - padU, 0, 1)
    end
end

function MMF_IsCursorInsideFrame(frame, pad)
    if not frame or not frame.IsShown or not frame:IsShown() then
        return false
    end

    local left = frame:GetLeft()
    local right = frame:GetRight()
    local top = frame:GetTop()
    local bottom = frame:GetBottom()
    if not left or not right or not top or not bottom then
        return false
    end

    local rawX, rawY = GetCursorPosition()
    local padding = tonumber(pad) or 4
    local function IsInsideWithScale(scale)
        if not scale or scale == 0 then
            return false
        end
        local cx = rawX / scale
        local cy = rawY / scale
        return (cx >= (left - padding) and cx <= (right + padding) and cy >= (bottom - padding) and cy <= (top + padding))
    end

    if IsInsideWithScale(frame:GetEffectiveScale() or 1) then
        return true
    end
    if UIParent and IsInsideWithScale(UIParent:GetEffectiveScale() or 1) then
        return true
    end
    if type(MouseIsOver) == "function" then
        local ok, isOver = pcall(MouseIsOver, frame)
        if ok and isOver == true then
            return true
        end
    end
    return false
end

function MMF_ClampPopupInactiveFadeAlpha(value, fallback)
    local cfg = (MMF_GetPopupInactiveFadeConfig and MMF_GetPopupInactiveFadeConfig()) or {}
    local minAlpha = tonumber(cfg.minAlpha) or 0.05
    local maxAlpha = tonumber(cfg.maxAlpha) or 0.95
    local defaultAlpha = tonumber(cfg.defaultAlpha) or 0.60

    local alpha = tonumber(value)
    if alpha == nil then
        alpha = tonumber(fallback) or defaultAlpha
    end
    if alpha < minAlpha then
        alpha = minAlpha
    elseif alpha > maxAlpha then
        alpha = maxAlpha
    end
    return alpha
end

function MMF_GetPopupInactiveFadeAlpha()
    local alpha
    if type(MattMinimalFramesDB) == "table" then
        alpha = MattMinimalFramesDB.popupInactiveFadeAlpha
    end
    if alpha == nil and type(MattMinimalFrames_Defaults) == "table" then
        alpha = MattMinimalFrames_Defaults.popupInactiveFadeAlpha
    end
    return MMF_ClampPopupInactiveFadeAlpha(alpha)
end
