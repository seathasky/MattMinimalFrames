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
