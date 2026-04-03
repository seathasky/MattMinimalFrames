function MMF_CreatePopupScrollController(config)
    config = config or {}

    local pageScrollFrame = config.pageScrollFrame
    local sharedScrollBar = config.sharedScrollBar
    local pages = config.pages or {}
    local mouseWheelStep = tonumber(config.mouseWheelStep) or 32
    local disabledAlpha = tonumber(config.disabledAlpha) or 0.45

    local activePage = config.activePage

    local function SetPages(newPages)
        pages = newPages or {}
    end

    local function SetActivePage(page)
        activePage = page
    end

    local function ApplyPageWidths(explicitWidth)
        local w = explicitWidth or pageScrollFrame:GetWidth() or 1
        w = math.max(1, w)
        for _, page in ipairs(pages) do
            page:SetWidth(w)
        end
    end

    local function GetActivePageScrollRange()
        local page = activePage
        if not page then
            return 0, 0
        end

        if type(page.MMFGetSectionRange) == "function" then
            local startY, endY = page:MMFGetSectionRange()
            startY = math.max(0, tonumber(startY) or 0)
            endY = math.max(startY, tonumber(endY) or (page:GetHeight() or 0))
            return startY, endY
        end

        return 0, page:GetHeight() or 0
    end

    local function UpdateSharedScrollBounds()
        local page = activePage
        if not page then
            sharedScrollBar:SetMinMaxValues(0, 0)
            sharedScrollBar:SetValue(0)
            pageScrollFrame:SetVerticalScroll(0)
            return
        end

        local viewHeight = pageScrollFrame:GetHeight() or 0
        local sectionStart, sectionEnd = GetActivePageScrollRange()
        local contentHeight = math.max(0, sectionEnd - sectionStart)
        local maxScroll = math.max(0, contentHeight - viewHeight)
        local current = sharedScrollBar:GetValue() or 0
        if current > maxScroll then
            current = maxScroll
        end

        sharedScrollBar:SetMinMaxValues(0, maxScroll)
        sharedScrollBar:SetValue(current)
        sharedScrollBar:SetEnabled(maxScroll > 0)
        sharedScrollBar:SetAlpha(maxScroll > 0 and 1 or disabledAlpha)
        pageScrollFrame:SetVerticalScroll(sectionStart + current)
    end

    sharedScrollBar:SetScript("OnValueChanged", function(_, value)
        local sectionStart = 0
        if activePage and type(activePage.MMFGetSectionRange) == "function" then
            local startY = activePage:MMFGetSectionRange()
            sectionStart = math.max(0, tonumber(startY) or 0)
        end
        pageScrollFrame:SetVerticalScroll(sectionStart + (value or 0))
    end)

    pageScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local minScroll, maxScroll = sharedScrollBar:GetMinMaxValues()
        local current = sharedScrollBar:GetValue() or 0
        if delta > 0 then
            current = math.max(minScroll, current - mouseWheelStep)
        else
            current = math.min(maxScroll, current + mouseWheelStep)
        end
        sharedScrollBar:SetValue(current)
    end)

    pageScrollFrame:SetScript("OnSizeChanged", function(_, width)
        ApplyPageWidths(width)
        UpdateSharedScrollBounds()
    end)

    return {
        SetPages = SetPages,
        SetActivePage = SetActivePage,
        ApplyPageWidths = ApplyPageWidths,
        GetActivePageScrollRange = GetActivePageScrollRange,
        UpdateSharedScrollBounds = UpdateSharedScrollBounds,
    }
end
