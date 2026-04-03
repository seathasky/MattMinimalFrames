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
    local defaults = type(MattMinimalFrames_Defaults) == "table" and MattMinimalFrames_Defaults or nil
    local customReset = type(resetConfig) == "table" and resetConfig or nil
    local hasDefault = (type(settingKey) == "string" and defaults and defaults[settingKey] ~= nil)
        or (customReset and (type(customReset.onReset) == "function" or type(customReset.isDefault) == "function"))
    local resetWidth = hasDefault and 52 or 0

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(hasDefault and 256 or 200, 20)
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
    if hasDefault then
        text:SetWidth(container:GetWidth() - (cb:GetWidth() + 6 + resetWidth + 8))
        text:SetJustifyH("LEFT")
    end

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

    if resetButton then
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
