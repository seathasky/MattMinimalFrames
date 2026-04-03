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

function MMF_CreateSubTabBar(parent, config)
    local accent = (config and config.accentColor) or GetAccentColor()
    local tabs = (config and config.tabs) or {}
    local width = (config and config.width) or 560
    local height = (config and config.height) or 30
    local spacing = (config and config.spacing) or 10
    local minButtonWidth = (config and config.minButtonWidth) or 76
    local horizontalPadding = (config and config.horizontalPadding) or 18
    local fontPath = (config and config.fontPath) or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local fontSize = (config and config.fontSize) or 11
    local onSelect = config and config.onSelect

    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(width, height)
    bar:SetPoint((config and config.anchor) or "TOPLEFT", (config and config.x) or 0, (config and config.y) or 0)

    local barWallpaper = bar:CreateTexture(nil, "BACKGROUND")
    barWallpaper:SetPoint("TOPLEFT", 1, -1)
    barWallpaper:SetPoint("BOTTOMRIGHT", -1, 1)
    barWallpaper:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\mw.png")
    barWallpaper:SetAlpha(0.30)

    local function UpdateBarWallpaperCrop()
        MMF_SetAspectCropTexCoords(barWallpaper, bar, 16 / 9)
    end
    UpdateBarWallpaperCrop()
    bar:SetScript("OnSizeChanged", function()
        UpdateBarWallpaperCrop()
    end)

    local barWallpaperTint = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
    barWallpaperTint:SetPoint("TOPLEFT", 1, -1)
    barWallpaperTint:SetPoint("BOTTOMRIGHT", -1, 1)
    barWallpaperTint:SetColorTexture(0.02, 0.03, 0.04, 0.24)

    local baseline = bar:CreateTexture(nil, "ARTWORK")
    baseline:SetPoint("BOTTOMLEFT", 0, 0)
    baseline:SetPoint("BOTTOMRIGHT", 0, 0)
    baseline:SetHeight(1)
    baseline:SetColorTexture(0.18, 0.22, 0.24, 1)

    local buttons = {}
    local activeIndex = 1

    local function ApplyButtonState(button, isActive)
        button.isActive = isActive
        if isActive then
            button.text:SetTextColor(1, 1, 1)
            button.plate:SetAlpha(0.45)
            button.glow:SetAlpha(0.08)
            button.underline:SetAlpha(1)
            button.underline:SetColorTexture(accent[1], accent[2], accent[3], 1)
        else
            button.text:SetTextColor(0.62, 0.66, 0.7)
            button.plate:SetAlpha(0.12)
            button.glow:SetAlpha(0)
            button.underline:SetAlpha(0)
        end
    end

    local function SetActive(index, suppressCallback)
        if index < 1 or index > #buttons then
            return
        end
        activeIndex = index
        for i, button in ipairs(buttons) do
            ApplyButtonState(button, i == index)
        end
        if not suppressCallback and onSelect then
            onSelect(index, tabs[index], bar)
        end
    end

    local cursorX = 0
    for index, tab in ipairs(tabs) do
        local label = tostring((type(tab) == "table" and tab.label) or tab or ("Tab " .. index))
        local button = CreateFrame("Button", nil, bar)
        button:SetHeight(height)
        button:SetPoint("TOPLEFT", cursorX, 0)

        button.base = button:CreateTexture(nil, "BACKGROUND")
        button.base:SetPoint("TOPLEFT", 0, -1)
        button.base:SetPoint("BOTTOMRIGHT", 0, 1)
        button.base:SetColorTexture(0.02, 0.03, 0.04, 0.45)

        button.plate = button:CreateTexture(nil, "BORDER")
        button.plate:SetPoint("TOPLEFT", 0, -1)
        button.plate:SetPoint("BOTTOMRIGHT", 0, 1)
        button.plate:SetColorTexture(0.08, 0.12, 0.14, 0.75)
        button.plate:SetAlpha(0.12)

        button.glow = button:CreateTexture(nil, "BACKGROUND")
        button.glow:SetPoint("TOPLEFT", -4, -2)
        button.glow:SetPoint("BOTTOMRIGHT", 4, 2)
        button.glow:SetColorTexture(accent[1], accent[2], accent[3], 1)
        button.glow:SetAlpha(0)

        button.text = button:CreateFontString(nil, "OVERLAY")
        button.text:SetFont(fontPath, fontSize, "")
        button.text:SetPoint("CENTER", 0, 1)
        button.text:SetText(label)

        button.underline = button:CreateTexture(nil, "OVERLAY")
        button.underline:SetPoint("BOTTOMLEFT", 0, 0)
        button.underline:SetPoint("BOTTOMRIGHT", 0, 0)
        button.underline:SetHeight(2)
        button.underline:SetAlpha(0)

        local textWidth = math.max(minButtonWidth, math.floor(button.text:GetStringWidth() + horizontalPadding))
        button:SetWidth(textWidth)
        cursorX = cursorX + textWidth + spacing

        button:SetScript("OnEnter", function(self)
            if self.isActive then
                return
            end
            self.plate:SetAlpha(0.22)
            self.text:SetTextColor(0.9, 0.94, 0.96)
            self.underline:SetAlpha(0.35)
            self.underline:SetColorTexture(accent[1], accent[2], accent[3], 0.8)
        end)
        button:SetScript("OnLeave", function(self)
            if self.isActive then
                return
            end
            self.plate:SetAlpha(0.12)
            self.text:SetTextColor(0.62, 0.66, 0.7)
            self.underline:SetAlpha(0)
        end)
        button:SetScript("OnClick", function()
            if PlaySoundFile and MMF_IsPopupUISoundsEnabled and MMF_IsPopupUISoundsEnabled() then
                PlaySoundFile("Interface\\AddOns\\MattMinimalFrames\\Sounds\\click.mp3", "Master")
            end
            SetActive(index)
        end)

        buttons[index] = button
    end

    bar.buttons = buttons
    bar.SetActive = SetActive
    bar.GetActive = function()
        return activeIndex
    end

    if #buttons > 0 then
        SetActive((config and config.defaultIndex) or 1, true)
    end

    return bar
end
