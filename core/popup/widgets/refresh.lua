function MMF_RefreshPopupWidgetTree(root)
    local function Visit(frame)
        if not frame then return end
        if type(frame.MMFRefreshWidget) == "function" then
            frame.MMFRefreshWidget()
        elseif frame.labelText and frame.mmfLabelRaw and frame.labelText.SetText then
            frame.labelText:SetText(frame.mmfLabelRaw)
        end
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do
            Visit(child)
        end
    end
    Visit(root)
end
