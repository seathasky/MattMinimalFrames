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

function MMF_CreateMinimalColorPicker(parent, config)
    local accent = (config and config.accentColor) or GetAccentColor()
    local fontPath = (config and config.fontPath) or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local width = (config and config.width) or 276
    local rowHeight = math.max(18, (config and tonumber(config.height)) or 24)
    local labelWidth = (config and config.labelWidth) or 120
    local buttonOffset = (config and config.buttonOffset) or (labelWidth + 4)
    local buttonWidth = (config and config.buttonWidth) or (width - buttonOffset)

    local function ClampChannel(value, fallback)
        local n = tonumber(value)
        if not n then
            n = tonumber(fallback) or 1
        end
        if n < 0 then n = 0 end
        if n > 1 then n = 1 end
        return n
    end

    local function GetColorPickerRGB()
        if not ColorPickerFrame then
            return nil, nil, nil
        end
        if ColorPickerFrame.GetColorRGB then
            local ok, r, g, b = pcall(ColorPickerFrame.GetColorRGB, ColorPickerFrame)
            if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
                return r, g, b
            end
        end
        local content = ColorPickerFrame.Content
        local picker = content and content.ColorPicker
        if picker and picker.GetColorRGB then
            local ok, r, g, b = pcall(picker.GetColorRGB, picker)
            if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
                return r, g, b
            end
        end
        return nil, nil, nil
    end

    local function OpenColorPicker(r, g, b, onChanged, onCancelled)
        if not ColorPickerFrame then
            return
        end

        local initial = { r = ClampChannel(r, 1), g = ClampChannel(g, 1), b = ClampChannel(b, 1) }
        local function ApplyCurrentColor()
            local cr, cg, cb = GetColorPickerRGB()
            if cr and cg and cb and onChanged then
                onChanged(ClampChannel(cr, initial.r), ClampChannel(cg, initial.g), ClampChannel(cb, initial.b))
            end
        end

        if ColorPickerFrame.SetupColorPickerAndShow then
            local colorInfo = {
                r = initial.r,
                g = initial.g,
                b = initial.b,
                hasOpacity = false,
                swatchFunc = function()
                    ApplyCurrentColor()
                end,
                opacityFunc = nil,
                cancelFunc = function(previousValues)
                    local restore = previousValues or initial
                    local rr = ClampChannel(restore.r, initial.r)
                    local rg = ClampChannel(restore.g, initial.g)
                    local rb = ClampChannel(restore.b, initial.b)
                    if onCancelled then
                        onCancelled(rr, rg, rb)
                    elseif onChanged then
                        onChanged(rr, rg, rb)
                    end
                end,
            }
            ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
            return
        end

        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.opacity = 1
        ColorPickerFrame.previousValues = initial
        ColorPickerFrame.func = function()
            ApplyCurrentColor()
        end
        ColorPickerFrame.opacityFunc = nil
        ColorPickerFrame.cancelFunc = function(previousValues)
            local restore = previousValues or initial
            local rr = ClampChannel(restore.r, initial.r)
            local rg = ClampChannel(restore.g, initial.g)
            local rb = ClampChannel(restore.b, initial.b)
            if onCancelled then
                onCancelled(rr, rg, rb)
            elseif onChanged then
                onChanged(rr, rg, rb)
            end
        end
        if ColorPickerFrame.SetColorRGB then
            ColorPickerFrame:SetColorRGB(initial.r, initial.g, initial.b)
        end
        if ColorPickerFrame.Hide and ColorPickerFrame.Show then
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, rowHeight)
    container:SetPoint((config and config.anchor) or "TOPLEFT", (config and config.x) or 0, (config and config.y) or 0)

    local label = container:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 10, "")
    label:SetPoint("LEFT", 0, 0)
    label:SetTextColor(0.8, 0.8, 0.8)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetText((config and config.label) or "")

    local hasReset = (config and type(config.onReset) == "function") and true or false
    local resetWidth = hasReset and 52 or 0
    local swatchWidth = hasReset and math.max(70, buttonWidth - resetWidth - 4) or buttonWidth
    local buttonHeight = math.max(16, rowHeight - 4)

    local swatchButton = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatchButton:SetSize(swatchWidth, buttonHeight)
    swatchButton:SetPoint("LEFT", buttonOffset, 0)
    swatchButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatchButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
    swatchButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local swatch = swatchButton:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(12, 12)
    swatch:SetPoint("LEFT", 6, 0)
    swatch:SetColorTexture(1, 1, 1, 1)

    local swatchBorder = swatchButton:CreateTexture(nil, "OVERLAY")
    swatchBorder:SetPoint("TOPLEFT", swatch, "TOPLEFT", -1, 1)
    swatchBorder:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 1, -1)
    swatchBorder:SetColorTexture(0, 0, 0, 1)

    local swatchText = swatchButton:CreateFontString(nil, "OVERLAY")
    swatchText:SetFont(fontPath, 10, "")
    swatchText:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    swatchText:SetPoint("RIGHT", swatchButton, "RIGHT", -6, 0)
    swatchText:SetTextColor(0.92, 0.92, 0.92)
    swatchText:SetJustifyH("LEFT")
    swatchText:SetText("Pick")

    local resetButton
    if hasReset then
        resetButton = CreateFrame("Button", nil, container, "BackdropTemplate")
        resetButton:SetSize(resetWidth, buttonHeight)
        resetButton:SetPoint("LEFT", swatchButton, "RIGHT", 4, 0)
        resetButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        resetButton:SetBackdropColor(0.06, 0.06, 0.08, 1)
        resetButton:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

        local resetText = resetButton:CreateFontString(nil, "OVERLAY")
        resetText:SetFont(fontPath, 9, "")
        resetText:SetPoint("CENTER")
        resetText:SetTextColor(0.85, 0.85, 0.85)
        resetText:SetText((config and config.resetLabel) or "Default")
        resetButton.text = resetText
    end

    local function ApplySwatchColor(r, g, b)
        local cr = ClampChannel(r, 1)
        local cg = ClampChannel(g, 1)
        local cb = ClampChannel(b, 1)
        swatch:SetColorTexture(cr, cg, cb, 1)
        local hex = string.format("#%02X%02X%02X", math.floor(cr * 255 + 0.5), math.floor(cg * 255 + 0.5), math.floor(cb * 255 + 0.5))
        swatchText:SetText(hex)
    end

    local function RefreshFromProvider()
        local getColor = config and config.getColor
        if type(getColor) ~= "function" then
            ApplySwatchColor(1, 1, 1)
            return
        end
        local ok, r, g, b = pcall(getColor)
        if ok then
            ApplySwatchColor(r, g, b)
        else
            ApplySwatchColor(1, 1, 1)
        end
    end

    swatchButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
    end)
    swatchButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)
    swatchButton:SetScript("OnClick", function()
        local r, g, b = 1, 1, 1
        if config and type(config.getColor) == "function" then
            local ok, pr, pg, pb = pcall(config.getColor)
            if ok then
                r, g, b = ClampChannel(pr, 1), ClampChannel(pg, 1), ClampChannel(pb, 1)
            end
        end
        OpenColorPicker(r, g, b, function(nr, ng, nb)
            if config and config.onColorChanged then
                config.onColorChanged(ClampChannel(nr, r), ClampChannel(ng, g), ClampChannel(nb, b))
            end
            ApplySwatchColor(nr, ng, nb)
        end, function(cr, cg, cb)
            if config and config.onColorChanged then
                config.onColorChanged(ClampChannel(cr, r), ClampChannel(cg, g), ClampChannel(cb, b))
            end
            ApplySwatchColor(cr, cg, cb)
        end)
    end)

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
            if config and config.onReset then
                config.onReset()
            end
            RefreshFromProvider()
        end)
    end

    RefreshFromProvider()

    container.RefreshColor = RefreshFromProvider
    container.SetColor = ApplySwatchColor
    container.swatchButton = swatchButton
    container.resetButton = resetButton
    return container
end

