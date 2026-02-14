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

function MMF_CreateMinimalCheckbox(parent, label, x, y, settingKey, defaultVal, onChange)
    local accent = GetAccentColor()

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 20)
    container:SetPoint("TOPLEFT", x, y)

    local cb = CreateFrame("CheckButton", nil, container)
    cb:SetSize(14, 14)
    cb:SetPoint("LEFT", 0, 0)

    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local border = cb:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.25, 0.25, 0.3, 1)

    local check = cb:CreateTexture(nil, "ARTWORK")
    check:SetSize(8, 8)
    check:SetPoint("CENTER")
    check:SetColorTexture(accent[1], accent[2], accent[3], 1)
    cb.check = check

    local isChecked = MattMinimalFramesDB[settingKey]
    if isChecked == nil then
        isChecked = (defaultVal ~= false)
    end
    cb:SetChecked(isChecked)
    check:SetShown(cb:GetChecked())

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.check:SetShown(checked)
        MattMinimalFramesDB[settingKey] = checked
        if onChange then onChange(checked) end
    end)

    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    text:SetTextColor(0.9, 0.9, 0.9)
    text:SetText(label)

    container.checkbox = cb
    return container
end

function MMF_CreateMinimalSlider(parent, label, x, y, width, settingKey, minVal, maxVal, step, defaultVal, onChange, isInteger)
    local accent = GetAccentColor()
    local isTBC = Compat.IsTBC

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 24)
    container:SetPoint("TOPLEFT", x, y)

    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    text:SetPoint("LEFT", 0, 0)
    text:SetTextColor(0.8, 0.8, 0.8)
    text:SetText(label)
    text:SetWidth(95)
    text:SetJustifyH("LEFT")

    local valueBg = CreateFrame("Frame", nil, container, "BackdropTemplate")
    valueBg:SetSize(40, 18)
    valueBg:SetPoint("RIGHT", 0, 0)
    valueBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    valueBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
    valueBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local valueText = CreateFrame("EditBox", nil, valueBg)
    valueText:SetAllPoints(valueBg)
    valueText:SetAutoFocus(false)
    valueText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    valueText:SetJustifyH("CENTER")
    valueText:SetJustifyV("MIDDLE")
    valueText:SetTextColor(accent[1], accent[2], accent[3])
    valueText:SetHitRectInsets(0, 0, 0, 0)

    local sliderWidth = width - 155
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetSize(sliderWidth, 8)
    slider:SetPoint("LEFT", 105, 0)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    slider:SetBackdropColor(0.06, 0.06, 0.08, 1)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 14)
    thumb:SetColorTexture(accent[1], accent[2], accent[3], 1)
    slider:SetThumbTexture(thumb)

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(8)
    fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    if isTBC then
        fill:SetColorTexture(0.8, 0.8, 0.8, 0.8)
    else
        fill:SetColorTexture(accent[1] * 0.5, accent[2] * 0.5, accent[3] * 0.6, 0.8)
    end
    slider.fill = fill

    local currentVal = MattMinimalFramesDB[settingKey] or defaultVal
    slider:SetValue(currentVal)
    if isInteger then
        valueText:SetText(tostring(math.floor(currentVal)))
    else
        if step and step < 0.1 then
            valueText:SetText(string.format("%.2f", currentVal))
        else
            valueText:SetText(string.format("%.1f", currentVal))
        end
    end

    local function UpdateFill()
        local min, max = slider:GetMinMaxValues()
        local val = slider:GetValue()
        local pct = (val - min) / (max - min)
        fill:SetWidth(math.max(1, slider:GetWidth() * pct))
    end
    UpdateFill()

    local function formatForDisplay(v)
        if isInteger then
            return tostring(math.floor(v + 0.5))
        else
            if step and step < 0.1 then
                return string.format("%.2f", math.floor(v * 100 + 0.5) / 100)
            else
                return string.format("%.1f", math.floor(v * 10 + 0.5) / 10)
            end
        end
    end

    valueText:SetText(formatForDisplay(currentVal))
    valueText:Show()

    valueBg:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
    end)
    valueBg:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    local function commitText(input)
        local num = tonumber(input)
        if not num then
            valueText:SetText(formatForDisplay(slider:GetValue()))
            return
        end
        local minV, maxV = slider:GetMinMaxValues()
        if num < minV then num = minV end
        if num > maxV then num = maxV end
        if isInteger then
            num = math.floor(num + 0.5)
        else
            if step and step < 0.1 then
                num = math.floor(num * 100 + 0.5) / 100
            else
                num = math.floor(num * 10 + 0.5) / 10
            end
        end
        slider:SetValue(num)
        MattMinimalFramesDB[settingKey] = num
        if onChange then pcall(onChange, num) end
        UpdateFill()
        valueText:SetText(formatForDisplay(num))
    end

    valueText:SetScript("OnEnterPressed", function(self)
        commitText(self:GetText())
        self:ClearFocus()
    end)
    valueText:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        valueText:SetText(formatForDisplay(slider:GetValue()))
    end)
    valueText:SetScript("OnEditFocusLost", function()
        valueText:SetText(formatForDisplay(slider:GetValue()))
    end)

    slider:SetScript("OnValueChanged", function(self, value)
        if isInteger then
            value = math.floor(value + 0.5)
            valueText:SetText(tostring(value))
        else
            if step and step < 0.1 then
                value = math.floor(value * 100 + 0.5) / 100
                valueText:SetText(string.format("%.2f", value))
            else
                value = math.floor(value * 10 + 0.5) / 10
                valueText:SetText(string.format("%.1f", value))
            end
        end
        MattMinimalFramesDB[settingKey] = value
        UpdateFill()
        if onChange then onChange(value) end
    end)

    container.slider = slider
    container.valueText = valueText
    return container
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
                local value = opt.value
                local label = opt.label
                local normalizedLabel = NormalizeString(label)
                if value ~= nil and normalizedLabel then
                    if type(value) == "string" then
                        local normalizedValue = NormalizeString(value)
                        if normalizedValue then
                            out[#out + 1] = { value = normalizedValue, label = normalizedLabel }
                        end
                    else
                        out[#out + 1] = { value = value, label = normalizedLabel }
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
    local offset = 0
    local updatingScroll = false
    local rows = {}
    local selectedValue = nil

    local function EscapeDisplayText(text)
        local value = tostring(text or "")
        return value:gsub("|", "||")
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 24)
    container:SetPoint((config and config.anchor) or "TOPLEFT", (config and config.x) or 0, (config and config.y) or 0)

    local label = container:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 10, "")
    label:SetPoint("LEFT", 0, 0)
    label:SetTextColor(0.8, 0.8, 0.8)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetText((config and config.label) or "")

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
    buttonText:SetFont(fontPath, 10, "")
    buttonText:SetPoint("LEFT", 6, 0)
    buttonText:SetJustifyH("LEFT")
    buttonText:SetWidth(buttonWidth - 24)

    local arrowText = button:CreateFontString(nil, "OVERLAY")
    arrowText:SetFont(fontPath, 9, "")
    arrowText:SetPoint("RIGHT", -6, 0)
    arrowText:SetTextColor(0.92, 0.92, 0.92)
    arrowText:SetText("v")

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
            if opt.value == value then
                return opt
            end
        end
        return nil
    end

    local function UpdateButtonTextFromSelection()
        local selectedOpt = GetOptionByValue(selectedValue)
        if selectedOpt then
            buttonText:SetTextColor(0.92, 0.92, 0.92)
            buttonText:SetText(EscapeDisplayText(selectedOpt.label))
            return
        end
        if selectedValue ~= nil then
            local fallbackText = tostring(selectedValue)
            if fallbackText ~= "" then
                buttonText:SetTextColor(0.75, 0.75, 0.75)
                buttonText:SetText(EscapeDisplayText(fallbackText))
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
                row.text:SetText(EscapeDisplayText(option.label))
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
        row.text:SetFont(fontPath, 10, "")
        row.text:SetPoint("LEFT", 6, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetTextColor(0.9, 0.9, 0.9)
        row:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(accent[1] * 0.2, accent[2] * 0.2, accent[3] * 0.2, 0.6)
            self.text:SetTextColor(accent[1], accent[2], accent[3])
        end)
        row:SetScript("OnLeave", function(self)
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

    dropdown.container = container
    dropdown.label = label
    dropdown.button = button
    dropdown.buttonText = buttonText
    dropdown.arrowText = arrowText
    dropdown.list = list
    dropdown.scrollBar = scrollBar
    dropdown.RefreshRows = RefreshRows

    return dropdown
end
