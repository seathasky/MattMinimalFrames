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
    container.labelText = text
    return container
end

