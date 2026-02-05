MMF_UIHider = CreateFrame("Frame")
MMF_UIHider:Hide()

function MMF_AddEditModeHighlight(frame, name)
    if frame and name then
        frame.editModeHighlight = frame:CreateTexture(nil, "OVERLAY")
        frame.editModeHighlight:SetAllPoints()
        frame.editModeHighlight:SetColorTexture(1, 1, 1, 0.3)
        frame.editModeHighlight:Hide()
        frame.editModeName = name
    end
end

function MMF_HideFrame(frame)
    if frame then
        frame:Hide()
        frame:SetParent(MMF_UIHider)
    end
end

function MMF_ShowFrame(frame, parent)
    if frame then
        frame:SetParent(parent or UIParent)
        frame:Show()
    end
end
