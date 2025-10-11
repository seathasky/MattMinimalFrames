--========================================================
-- MattMinimalFrames_Utils.lua
-- General utility and helper functions
--========================================================

-- A hidden frame to store unwanted frames
MMF_UIHider = CreateFrame("Frame")
MMF_UIHider:Hide()

-- Hide a frame by moving it to the hidden frame
function MMF_HideFrame(frame)
    if frame then
        frame:Hide()
        frame:SetParent(MMF_UIHider)
    end
end

-- Show a frame by reparenting it
function MMF_ShowFrame(frame, parent)
    if frame then
        frame:SetParent(parent or UIParent)
        frame:Show()
    end
end

-- Format numbers with K/M suffixes
function MMF_FormatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

-- Add edit mode highlight to a frame
function MMF_AddEditModeHighlight(frame, name)
    if frame and name then
        frame.editModeHighlight = frame:CreateTexture(nil, "OVERLAY")
        frame.editModeHighlight:SetAllPoints()
        frame.editModeHighlight:SetColorTexture(1, 1, 1, 0.3)
        frame.editModeHighlight:Hide()
        
        frame.editModeName = name
    end
end
