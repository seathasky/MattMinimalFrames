local Compat = _G.MMF_Compat or {}

local function GetAccentColor()
    if MMF_GetPopupAccentColor then
        local accent = MMF_GetPopupAccentColor()
        if accent and accent[1] and accent[2] and accent[3] then
            return accent
        end
    end
    if Compat.IsTBC then
        return { 0.2, 0.9, 0.4 }
    end
    return { 0.6, 0.4, 0.9 }
end

function MMF_CreateMinimalDropdown(parent, popup, config)
    local accent = (config and config.accentColor) or GetAccentColor()
    local fontPath = (config and config.fontPath) or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local width = (config and config.width) or 300
    local labelWidth = (config and config.labelWidth) or 95
    local buttonWidth = (config and config.buttonWidth) or (width - labelWidth - 9)
    local buttonOffset = (config and config.buttonOffset) or (labelWidth + 9)
    local visibleRows = math.max(1, (config and config.visibleRows) or 8)
    local placeholderText = (config and config.placeholderText) or "Select..."
    local rowHeight = 20
    local listPadding = 2
    local listFrameLevel = (config and config.listFrameLevel) or 1000
    local previewOptionFonts = (config and config.previewOptionFonts) == true
    local preserveWidgetFont = (config and config.preserveWidgetFont) == true

    local function TrySetFont(region, requestedPath, size, flags)
        if not region or not region.SetFont then
            return false
        end

        local targetSize = tonumber(size) or 10
        if targetSize <= 0 then
            targetSize = 10
        end

        local targetFlags = flags or ""
        local fallbackPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

        if type(requestedPath) == "string" and requestedPath ~= "" then
            local ok, applied = pcall(region.SetFont, region, requestedPath, targetSize, targetFlags)
            if ok and applied ~= false then
                return true
            end
            ok, applied = pcall(region.SetFont, region, requestedPath, targetSize, "")
            if ok and applied ~= false then
                return true
            end
        end

        if type(fontPath) == "string" and fontPath ~= "" and requestedPath ~= fontPath then
            local ok, applied = pcall(region.SetFont, region, fontPath, targetSize, targetFlags)
            if ok and applied ~= false then
                return true
            end
            ok, applied = pcall(region.SetFont, region, fontPath, targetSize, "")
            if ok and applied ~= false then
                return true
            end
        end

        local ok, applied = pcall(region.SetFont, region, fallbackPath, targetSize, targetFlags)
        if ok and applied ~= false then
            return true
        end
        ok, applied = pcall(region.SetFont, region, fallbackPath, targetSize, "")
        return ok and applied ~= false
    end

    local function NormalizeOptions(raw)
        local out = {}
        local function NormalizeString(value)
            if type(value) ~= "string" then
                return nil
            end
            local trimmed = value:match("^%s*(.-)%s*$")
            if not trimmed or trimmed == "" then
                return nil
            end
            return trimmed
        end
        for _, opt in ipairs(raw or {}) do
            if type(opt) == "table" then
                if opt.divider == true then
                    out[#out + 1] = { divider = true, label = tostring(opt.label or "") }
                else
                    local value = opt.value
                    local label = opt.label
                    local normalizedLabel = NormalizeString(label)
                    if value ~= nil and normalizedLabel then
                        local optionFontPath = nil
                        if type(opt.fontPath) == "string" then
                            local trimmedFontPath = opt.fontPath:match("^%s*(.-)%s*$")
                            if trimmedFontPath and trimmedFontPath ~= "" then
                                optionFontPath = trimmedFontPath
                            end
                        end
                        if type(value) == "string" then
                            local normalizedValue = NormalizeString(value)
                            if normalizedValue then
                                out[#out + 1] = { value = normalizedValue, label = normalizedLabel, fontPath = optionFontPath }
                            end
                        else
                            out[#out + 1] = { value = value, label = normalizedLabel, fontPath = optionFontPath }
                        end
                    end
                end
            elseif type(opt) == "string" then
                local normalized = NormalizeString(opt)
                if normalized then
                    out[#out + 1] = { value = normalized, label = normalized }
                end
            end
        end
        return out
    end

    local options = NormalizeOptions(config and config.options)
    local dropdownLabel = tostring((config and config.label) or "")
    local offset = 0
    local updatingScroll = false
    local rows = {}
    local selectedValue = nil

    local preserveTextFormatting = (config and config.preserveTextFormatting) == true
    local function EscapeDisplayText(text)
        local value = tostring(text or "")
        if preserveTextFormatting then
            return value
        end
        return value:gsub("|", "||")
    end

    local function HasVisibleCharacters(text)
        return type(text) == "string" and text:match("%S") ~= nil
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 24)
    container:SetPoint((config and config.anchor) or "TOPLEFT", (config and config.x) or 0, (config and config.y) or 0)

    local label = container:CreateFontString(nil, "OVERLAY")
    TrySetFont(label, fontPath, 10, "")
    label:SetPoint("LEFT", 0, 0)
    label:SetTextColor(0.8, 0.8, 0.8)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetText(dropdownLabel)

    local button = CreateFrame("Button", nil, container, "BackdropTemplate")
    button:SetSize(buttonWidth, 20)
    button:SetPoint("LEFT", buttonOffset, 0)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0.06, 0.06, 0.08, 1)
    button:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    TrySetFont(buttonText, fontPath, 10, "")
    buttonText:SetPoint("LEFT", 6, 0)
    buttonText:SetJustifyH("LEFT")
    buttonText:SetWidth(buttonWidth - 24)

    local arrowText = button:CreateFontString(nil, "OVERLAY")
    TrySetFont(arrowText, fontPath, 9, "")
    arrowText:SetPoint("RIGHT", -6, 0)
    arrowText:SetTextColor(0.92, 0.92, 0.92)
    arrowText:SetText("v")

    if preserveWidgetFont then
        label.mmfSkipGlobalFont = true
        buttonText.mmfSkipGlobalFont = true
        arrowText.mmfSkipGlobalFont = true
    end

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
        arrowText:SetTextColor(1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        arrowText:SetTextColor(0.92, 0.92, 0.92)
    end)

    local listParent = popup or parent
    local list = CreateFrame("Frame", nil, listParent, "BackdropTemplate")
    list:SetSize(buttonWidth, (visibleRows * rowHeight) + listPadding)
    list:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    list:SetBackdropColor(0.06, 0.06, 0.08, 1)
    list:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    list:SetFrameStrata("DIALOG")
    list:SetFrameLevel(listFrameLevel)
    list:EnableMouseWheel(true)
    list:Hide()

    local scrollBar = CreateFrame("Slider", nil, list, "BackdropTemplate")
    scrollBar:SetPoint("TOPRIGHT", -2, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollBar:SetWidth(10)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    scrollBar:SetBackdropColor(0.03, 0.03, 0.04, 1)
    scrollBar:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 18)
    thumb:SetColorTexture(accent[1], accent[2], accent[3], 1)
    scrollBar:SetThumbTexture(thumb)

    local function GetOptionByValue(value)
        for _, opt in ipairs(options) do
            if opt.divider ~= true and opt.value == value then
                return opt
            end
        end
        return nil
    end

    local function UpdateButtonTextFromSelection()
        TrySetFont(buttonText, fontPath, 10, "")
        local selectedOpt = GetOptionByValue(selectedValue)
        if selectedOpt then
            local selectedLabel = tostring(selectedOpt.label or "")
            buttonText:SetTextColor(0.92, 0.92, 0.92)
            if HasVisibleCharacters(selectedLabel) then
                buttonText:SetText(EscapeDisplayText(selectedLabel))
            else
                buttonText:SetText("Selected")
            end
            local okWidth, measuredWidth = pcall(buttonText.GetStringWidth, buttonText)
            if okWidth and type(measuredWidth) == "number" and measuredWidth <= 0 then
                buttonText:SetText("Selected")
            end
            return
        end
        if selectedValue ~= nil then
            local fallbackText = tostring(selectedValue)
            if HasVisibleCharacters(fallbackText) then
                buttonText:SetTextColor(0.75, 0.75, 0.75)
                buttonText:SetText(EscapeDisplayText(fallbackText))
                local okWidth, measuredWidth = pcall(buttonText.GetStringWidth, buttonText)
                if okWidth and type(measuredWidth) == "number" and measuredWidth <= 0 then
                    buttonText:SetText("Selected")
                end
                return
            end
        end
        buttonText:SetTextColor(0.6, 0.6, 0.6)
        buttonText:SetText(EscapeDisplayText(placeholderText))
    end

    local function ClampOffset()
        local maxOffset = math.max(0, #options - visibleRows)
        if offset < 0 then offset = 0 end
        if offset > maxOffset then offset = maxOffset end
    end

    local function RefreshRows()
        local maxOffset = math.max(0, #options - visibleRows)
        ClampOffset()
        scrollBar:SetShown(maxOffset > 0)
        scrollBar:SetMinMaxValues(0, maxOffset)
        updatingScroll = true
        scrollBar:SetValue(offset)
        updatingScroll = false

        for rowIndex = 1, visibleRows do
            local option = options[offset + rowIndex]
            local row = rows[rowIndex]
            if option then
                row.option = option
                local rowFontPath = fontPath
                if option.divider then
                    rowFontPath = fontPath
                elseif previewOptionFonts and type(option.fontPath) == "string" and option.fontPath ~= "" then
                    rowFontPath = option.fontPath
                end
                TrySetFont(row.text, rowFontPath, 10, "")
                row.text:SetText(EscapeDisplayText(option.label))
                if option.divider then
                    row.text:SetTextColor(0.35, 0.35, 0.4)
                    row.bg:SetColorTexture(0, 0, 0, 0)
                else
                    row.text:SetTextColor(0.9, 0.9, 0.9)
                    row.bg:SetColorTexture(0, 0, 0, 0)
                end
                row:Show()
            else
                row.option = nil
                row:Hide()
            end
        end
    end

    local dropdown = {}

    function dropdown.Close()
        list:Hide()
        if list.clickCatcher then
            list.clickCatcher:Hide()
        end
    end

    function dropdown.SetSelectedValue(value)
        selectedValue = value
        UpdateButtonTextFromSelection()
    end

    function dropdown.SetOptions(newOptions)
        options = NormalizeOptions(newOptions)
        if selectedValue == nil and #options > 0 then
            selectedValue = options[1].value
        end
        UpdateButtonTextFromSelection()
        RefreshRows()
    end

    function dropdown.GetOptions()
        return options
    end

    function dropdown.GetSelectedValue()
        return selectedValue
    end

    local function SelectOption(option)
        if not option then return end
        if option.divider then return end
        selectedValue = option.value
        UpdateButtonTextFromSelection()
        if config and config.onSelect then
            config.onSelect(option.value, option, dropdown)
        end
        dropdown.Close()
    end

    for rowIndex = 1, visibleRows do
        local row = CreateFrame("Button", nil, list, "BackdropTemplate")
        row:SetSize(buttonWidth - 14, rowHeight)
        row:SetPoint("TOPLEFT", 1, -1 - (rowIndex - 1) * rowHeight)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        row:SetBackdropColor(0, 0, 0, 0)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0)
        row.text = row:CreateFontString(nil, "OVERLAY")
        TrySetFont(row.text, fontPath, 10, "")
        row.text:SetPoint("LEFT", 6, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetTextColor(0.9, 0.9, 0.9)
        if preserveWidgetFont then
            row.text.mmfSkipGlobalFont = true
        end
        row:SetScript("OnEnter", function(self)
            if self.option and self.option.divider then
                return
            end
            self.bg:SetColorTexture(accent[1] * 0.2, accent[2] * 0.2, accent[3] * 0.2, 0.6)
            self.text:SetTextColor(accent[1], accent[2], accent[3])
        end)
        row:SetScript("OnLeave", function(self)
            if self.option and self.option.divider then
                self.bg:SetColorTexture(0, 0, 0, 0)
                self.text:SetTextColor(0.35, 0.35, 0.4)
                return
            end
            self.bg:SetColorTexture(0, 0, 0, 0)
            self.text:SetTextColor(0.9, 0.9, 0.9)
        end)
        row:SetScript("OnClick", function(self)
            SelectOption(self.option)
        end)
        rows[rowIndex] = row
    end

    scrollBar:SetScript("OnValueChanged", function(_, value)
        if updatingScroll then return end
        offset = math.floor((value or 0) + 0.5)
        RefreshRows()
    end)

    list:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            offset = offset - 1
        elseif delta < 0 then
            offset = offset + 1
        end
        RefreshRows()
    end)

    local function OpenDropdown()
        if config and config.onOpen then
            config.onOpen(dropdown)
        end

        if config and config.optionsProvider then
            dropdown.SetOptions(config.optionsProvider() or {})
        end

        if config and config.getValue then
            selectedValue = config.getValue()
            UpdateButtonTextFromSelection()
        end

        if #options == 0 then
            dropdown.Close()
            return
        end

        RefreshRows()
        list:Show()
        if not list.clickCatcher then
            local anchor = listParent
            local catcher = CreateFrame("Button", nil, anchor)
            catcher:SetAllPoints(anchor)
            catcher:SetScript("OnClick", function()
                dropdown.Close()
            end)
            list.clickCatcher = catcher
        end
        local levelAnchor = listParent
        list.clickCatcher:SetFrameLevel(levelAnchor:GetFrameLevel() + 100)
        list.clickCatcher:Show()
    end

    button:SetScript("OnClick", function()
        if list:IsShown() then
            dropdown.Close()
            return
        end
        OpenDropdown()
    end)

    if config and config.getValue then
        selectedValue = config.getValue()
    elseif config and config.selectedValue ~= nil then
        selectedValue = config.selectedValue
    end

    UpdateButtonTextFromSelection()
    RefreshRows()

    local function RefreshDropdownVisual()
        TrySetFont(label, fontPath, 10, "")
        label:SetText(dropdownLabel)
        if config and config.optionsProvider then
            options = NormalizeOptions(config.optionsProvider() or {})
        end
        if config and config.getValue then
            selectedValue = config.getValue()
        end
        UpdateButtonTextFromSelection()
        RefreshRows()
    end

    container:SetScript("OnShow", RefreshDropdownVisual)

    dropdown.container = container
    dropdown.label = label
    dropdown.button = button
    dropdown.buttonText = buttonText
    dropdown.arrowText = arrowText
    dropdown.list = list
    dropdown.scrollBar = scrollBar
    dropdown.RefreshRows = RefreshRows

    container.labelText = label
    container.mmfLabelRaw = dropdownLabel
    container.MMFRefreshWidget = RefreshDropdownVisual

    return dropdown
end

