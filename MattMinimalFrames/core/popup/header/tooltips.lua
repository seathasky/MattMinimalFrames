function MMF_AttachPopupSideTooltip(frame, title, lines)
    if not frame then
        return
    end

    local tooltipLines = lines or {}
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("LEFT", self, "RIGHT", 14, 0)
        GameTooltip:SetText(title or "", 1, 1, 1)
        for _, line in ipairs(tooltipLines) do
            if type(line) == "string" and line ~= "" then
                GameTooltip:AddLine(line, 0.75, 0.75, 0.75, true)
            end
        end
        GameTooltip:Show()
    end)

    frame:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
