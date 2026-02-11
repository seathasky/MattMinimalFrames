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

--------------------------------------------------
-- ALIGNMENT GRID
--------------------------------------------------

local alignmentGrid = nil

function MMF_ToggleAlignmentGrid(show)
    if not show then
        if alignmentGrid then alignmentGrid:Hide() end
        return
    end

    if not alignmentGrid then
        alignmentGrid = CreateFrame("Frame", "MMF_AlignmentGrid", UIParent)
        alignmentGrid:SetAllPoints(UIParent)
        alignmentGrid:SetFrameStrata("LOW")
        alignmentGrid:EnableMouse(false)

        local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
        local sp = 25

        -- Center crosshair
        local cv = alignmentGrid:CreateTexture(nil, "OVERLAY")
        cv:SetColorTexture(0.784, 0.271, 0.980, 0.5)
        cv:SetSize(2, sh)
        cv:SetPoint("CENTER", alignmentGrid, "CENTER", 0, 0)

        local ch = alignmentGrid:CreateTexture(nil, "OVERLAY")
        ch:SetColorTexture(0.784, 0.271, 0.980, 0.5)
        ch:SetSize(sw, 2)
        ch:SetPoint("CENTER", alignmentGrid, "CENTER", 0, 0)

        -- Grid lines radiating from center 
        for i = 1, math.floor(sw / sp / 2) do
            local off = i * sp
            local r = alignmentGrid:CreateTexture(nil, "ARTWORK")
            r:SetColorTexture(1, 1, 1, 0.25)
            r:SetSize(1, sh)
            r:SetPoint("CENTER", alignmentGrid, "CENTER", off, 0)
            local l = alignmentGrid:CreateTexture(nil, "ARTWORK")
            l:SetColorTexture(1, 1, 1, 0.25)
            l:SetSize(1, sh)
            l:SetPoint("CENTER", alignmentGrid, "CENTER", -off, 0)
        end

        for i = 1, math.floor(sh / sp / 2) do
            local off = i * sp
            local u = alignmentGrid:CreateTexture(nil, "ARTWORK")
            u:SetColorTexture(1, 1, 1, 0.25)
            u:SetSize(sw, 1)
            u:SetPoint("CENTER", alignmentGrid, "CENTER", 0, off)
            local d = alignmentGrid:CreateTexture(nil, "ARTWORK")
            d:SetColorTexture(1, 1, 1, 0.25)
            d:SetSize(sw, 1)
            d:SetPoint("CENTER", alignmentGrid, "CENTER", 0, -off)
        end
    end

    alignmentGrid:Show()
end
