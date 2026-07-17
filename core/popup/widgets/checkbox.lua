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

function MMF_CreateMinimalCheckbox(parent, label, x, y, settingKey, defaultVal, onChange, resetConfig)
    local accent = GetAccentColor()
    local theme = (MMF_GetPopupTheme and MMF_GetPopupTheme()) or {}
    local fontPath = theme.font or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local rowHeight = theme.rowHeight or 26
    local controlHeight = theme.controlHeight or 22
    local input = theme.input or { 0.025, 0.032, 0.042, 1 }
    local borderColor = theme.border or { 0.145, 0.175, 0.205, 1 }
    local textColor = theme.text or { 0.92, 0.94, 0.96, 1 }
    local defaults = type(MattMinimalFrames_Defaults) == "table" and MattMinimalFrames_Defaults or nil
    local customReset = type(resetConfig) == "table" and resetConfig or nil
    local hasDefault = (type(settingKey) == "string" and defaults and defaults[settingKey] ~= nil)
        or (customReset and (type(customReset.onReset) == "function" or type(customReset.isDefault) == "function"))
    local resetWidth = hasDefault and (theme.resetWidth or 52) or 0

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(hasDefault and 256 or 200, rowHeight)
    container:SetPoint("TOPLEFT", x, y)

    local rowHighlight = container:CreateTexture(nil, "BACKGROUND")
    rowHighlight:SetAllPoints()
    rowHighlight:SetColorTexture(accent[1], accent[2], accent[3], 0.055)
    rowHighlight:SetAlpha(0)

    local cb = CreateFrame("CheckButton", nil, container)
    cb:SetSize(16, 16)
    cb:SetPoint("LEFT", 0, 0)

    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(input[1], input[2], input[3], input[4] or 1)

    local border = cb:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)

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
    text:SetFont(fontPath, 11, "")
    text:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    text:SetTextColor(textColor[1], textColor[2], textColor[3])
    text:SetText(label)
    if hasDefault then
        text:SetWidth(container:GetWidth() - (cb:GetWidth() + 8 + resetWidth + 8))
        text:SetJustifyH("LEFT")
    end

    local resetButton
    if hasDefault then
        resetButton = CreateFrame("Button", nil, container, "BackdropTemplate")
        resetButton:SetSize(resetWidth, controlHeight)
        resetButton:SetPoint("RIGHT", 0, 0)
        resetButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        resetButton:SetBackdropColor(input[1], input[2], input[3], input[4] or 1)
        resetButton:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)

        local resetText = resetButton:CreateFontString(nil, "OVERLAY")
        resetText:SetFont(fontPath, 9, "")
        resetText:SetPoint("CENTER")
        resetText:SetTextColor(0.85, 0.85, 0.85)
        resetText:SetText("RESET")
        resetButton.text = resetText
    end

    local function IsValueDefault()
        if not hasDefault then
            return true
        end
        if customReset and type(customReset.isDefault) == "function" then
            local ok, isDefaultValue = pcall(customReset.isDefault, cb)
            if ok then
                return isDefaultValue == true
            end
        end
        local defaultValue = defaults[settingKey]
        local currentValue = MattMinimalFramesDB and MattMinimalFramesDB[settingKey]
        if currentValue == nil then
            currentValue = defaultValue
        end
        return currentValue == defaultValue
    end

    local function RefreshResetVisibility()
        if not resetButton then
            return
        end
        resetButton:SetShown(not IsValueDefault())
    end

    container.checkbox = cb
    container.labelText = text
    container.resetButton = resetButton
    container.RefreshResetVisibility = RefreshResetVisibility

    -- Make the whole label row an obvious, forgiving click target while
    -- leaving the reset action independent.
    local labelButton = CreateFrame("Button", nil, container)
    labelButton:SetPoint("TOPLEFT", 0, 0)
    labelButton:SetPoint("BOTTOMRIGHT", hasDefault and -(resetWidth + 6) or 0, 0)
    labelButton:SetScript("OnEnter", function()
        rowHighlight:SetAlpha(1)
        border:SetColorTexture(accent[1], accent[2], accent[3], 0.75)
    end)
    labelButton:SetScript("OnLeave", function()
        rowHighlight:SetAlpha(0)
        border:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    end)
    labelButton:SetScript("OnClick", function()
        cb:Click()
    end)
    container.labelButton = labelButton

    if resetButton then
        resetButton:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
            if self.text then
                self.text:SetTextColor(1, 1, 1)
            end
        end)
        resetButton:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
            if self.text then
                self.text:SetTextColor(0.85, 0.85, 0.85)
            end
        end)
        resetButton:SetScript("OnClick", function()
            if customReset and type(customReset.onReset) == "function" then
                customReset.onReset()
            else
                local defaultValue = defaults and defaults[settingKey]
                if not MattMinimalFramesDB then
                    MattMinimalFramesDB = {}
                end
                MattMinimalFramesDB[settingKey] = defaultValue
                cb:SetChecked(defaultValue == true)
                check:SetShown(cb:GetChecked())
                if onChange then onChange(defaultValue == true) end
            end
            RefreshResetVisibility()
        end)
    end

    cb:HookScript("OnClick", RefreshResetVisibility)
    container:SetScript("OnShow", RefreshResetVisibility)
    RefreshResetVisibility()
    return container
end
