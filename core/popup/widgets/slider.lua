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

function MMF_CreateMinimalSlider(parent, label, x, y, width, settingKey, minVal, maxVal, step, defaultVal, onChange, isInteger, resetConfig)
    local accent = GetAccentColor()
    local isTBC = Compat.IsTBC
    local sliderLabel = tostring(label or "")
    local defaults = type(MattMinimalFrames_Defaults) == "table" and MattMinimalFrames_Defaults or nil
    local customReset = type(resetConfig) == "table" and resetConfig or nil
    local hasDefault = (type(settingKey) == "string" and defaults and defaults[settingKey] ~= nil)
        or (customReset and (type(customReset.onReset) == "function" or type(customReset.isDefault) == "function"))
    local resetWidth = hasDefault and 52 or 0
    local valueBoxWidth = 40

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 24)
    container:SetPoint("TOPLEFT", x, y)

    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    text:SetPoint("LEFT", 0, 0)
    text:SetTextColor(0.8, 0.8, 0.8)
    text:SetText(sliderLabel)
    text:SetWidth(95)
    text:SetJustifyH("LEFT")

    local valueBg = CreateFrame("Frame", nil, container, "BackdropTemplate")
    valueBg:SetSize(valueBoxWidth, 18)
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

    local sliderWidth = math.max(30, width - 155)
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

    local function ApplyLayout()
        local resetPad = hasDefault and (resetWidth + 4) or 0
        local labelWidth = 95
        local sliderLeft = labelWidth + 10
        local sliderRight = valueBoxWidth + resetPad + 6
        local available = width - sliderLeft - sliderRight

        if available < 30 then
            labelWidth = math.max(56, labelWidth - (30 - available))
            sliderLeft = labelWidth + 10
            available = math.max(30, width - sliderLeft - sliderRight)
        end

        text:SetWidth(labelWidth)
        valueBg:ClearAllPoints()
        valueBg:SetPoint("RIGHT", -resetPad, 0)
        slider:ClearAllPoints()
        slider:SetPoint("LEFT", sliderLeft, 0)
        slider:SetWidth(math.max(30, available))
        UpdateFill()
    end

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
        if container.mmfSuppressOnValueChanged then
            UpdateFill()
            if container.RefreshResetVisibility then
                container.RefreshResetVisibility()
            end
            return
        end
        MattMinimalFramesDB[settingKey] = value
        UpdateFill()
        if onChange then onChange(value) end
        if container.RefreshResetVisibility then
            container.RefreshResetVisibility()
        end
    end)

    local resetButton
    if hasDefault then
        resetButton = CreateFrame("Button", nil, container, "BackdropTemplate")
        resetButton:SetSize(resetWidth, 18)
        resetButton:SetPoint("RIGHT", 0, 0)
        resetButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        resetButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
        resetButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

        local resetText = resetButton:CreateFontString(nil, "OVERLAY")
        resetText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        resetText:SetPoint("CENTER")
        resetText:SetTextColor(0.85, 0.85, 0.85)
        resetText:SetText("RESET")
        resetButton.text = resetText

        resetButton:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
            if self.text then
                self.text:SetTextColor(1, 1, 1)
            end
        end)
        resetButton:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            if self.text then
                self.text:SetTextColor(0.85, 0.85, 0.85)
            end
        end)
        resetButton:SetScript("OnClick", function()
            if customReset and type(customReset.onReset) == "function" then
                customReset.onReset()
            else
                local defaultValue = defaults and defaults[settingKey]
                slider:SetValue(tonumber(defaultValue) or defaultValue)
            end
            if container.RefreshResetVisibility then
                container.RefreshResetVisibility()
            end
        end)
    end

    local function ValuesEqual(a, b)
        if type(a) == "number" and type(b) == "number" then
            return math.abs(a - b) < 0.0001
        end
        return a == b
    end

    local function IsValueDefault()
        if not hasDefault then
            return true
        end
        if customReset and type(customReset.isDefault) == "function" then
            local ok, isDefaultValue = pcall(customReset.isDefault, slider)
            if ok then
                return isDefaultValue == true
            end
        end
        local defaultValue = defaults[settingKey]
        local currentValue = MattMinimalFramesDB and MattMinimalFramesDB[settingKey]
        if currentValue == nil then
            currentValue = defaultValue
        end
        return ValuesEqual(currentValue, defaultValue)
    end

    local function RefreshResetVisibility()
        if not resetButton then
            return
        end
        resetButton:SetShown(not IsValueDefault())
    end

    local function RefreshSliderVisual()
        text:SetText(sliderLabel)
        valueText:SetText(formatForDisplay(slider:GetValue()))
        UpdateFill()
        RefreshResetVisibility()
    end

    container:SetScript("OnShow", RefreshSliderVisual)

    container.slider = slider
    container.labelText = text
    container.mmfLabelRaw = sliderLabel
    container.MMFRefreshWidget = RefreshSliderVisual
    container.valueText = valueText
    container.resetButton = resetButton
    container.RefreshResetVisibility = RefreshResetVisibility
    container.MMFSetValueSilently = function(v)
        if v == nil then
            return
        end
        container.mmfSuppressOnValueChanged = true
        slider:SetValue(v)
        container.mmfSuppressOnValueChanged = nil
    end
    ApplyLayout()
    RefreshResetVisibility()
    return container
end
