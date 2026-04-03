function MMF_CreatePopupHeaderTitleControlFactories(config)
    config = config or {}

    local titleBar = config.titleBar
    local ACCENT_COLOR = config.accentColor or { 0.6, 0.4, 0.9 }
    local TITLE_CONTROL_FONT = config.fontPath or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"

    local function EnsureTitleControlFont(fontString, size)
        if not fontString then
            return
        end
        local targetSize = tonumber(size) or 10
        if MMF_SetFontSafe then
            MMF_SetFontSafe(fontString, TITLE_CONTROL_FONT, targetSize, "")
        else
            fontString:SetFont(TITLE_CONTROL_FONT, targetSize, "")
        end
        fontString:SetDrawLayer("OVERLAY", 7)
        fontString:SetAlpha(1)
    end

    local function CreateTitleCheckbox(anchor, xOffset, labelText, isChecked, onToggle)
        local container = CreateFrame("Frame", nil, titleBar)
        container:SetSize(120, 20)
        container:SetPoint("RIGHT", anchor, "LEFT", xOffset, 0)

        local checkbox = CreateFrame("CheckButton", nil, container)
        checkbox:SetSize(14, 14)
        checkbox:SetPoint("LEFT", 0, 0)

        local bg = checkbox:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.1, 1)

        local border = checkbox:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.25, 0.25, 0.3, 1)

        local check = checkbox:CreateTexture(nil, "ARTWORK")
        check:SetSize(8, 8)
        check:SetPoint("CENTER")
        check:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
        checkbox.check = check

        local label = container:CreateFontString(nil, "OVERLAY")
        EnsureTitleControlFont(label, 10)
        label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
        label:SetTextColor(0.9, 0.9, 0.9)
        label:SetText(labelText)
        label:SetShown(true)
        label.mmfSkipGlobalFont = true

        checkbox:SetChecked(isChecked == true)
        check:SetShown(isChecked == true)
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked() == true
            self.check:SetShown(checked)
            if onToggle then
                onToggle(checked)
            end
        end)

        checkbox.labelText = label
        container.labelText = label
        container.mmfLabelRaw = labelText
        container.MMFRefreshWidget = function()
            if container.labelText and container.labelText.SetText then
                container.labelText:SetText(labelText)
            end
        end

        return container, checkbox
    end

    local function CreateTitleButton(anchor, xOffset, labelText, onClick, width)
        local containerWidth = tonumber(width) or 88
        if containerWidth < 72 then
            containerWidth = 72
        end
        local container = CreateFrame("Frame", nil, titleBar)
        container:SetSize(containerWidth, 20)
        container:SetPoint("RIGHT", anchor, "LEFT", xOffset, 0)

        local button = CreateFrame("Button", nil, container, "BackdropTemplate")
        button:SetSize(containerWidth - 4, 18)
        button:SetPoint("LEFT", 0, 0)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.08, 0.08, 0.1, 1)
        button:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

        local textHost = CreateFrame("Frame", nil, button)
        textHost:SetAllPoints(button)
        textHost:SetFrameStrata(button:GetFrameStrata())
        textHost:SetFrameLevel((button:GetFrameLevel() or 1) + 8)
        textHost:EnableMouse(false)

        local label = textHost:CreateFontString(nil, "OVERLAY")
        EnsureTitleControlFont(label, 10)
        label:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -1)
        label:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 1)
        label:SetJustifyH("CENTER")
        label:SetJustifyV("MIDDLE")
        label:SetWordWrap(false)
        label:SetTextColor(0.9, 0.9, 0.9)
        label:SetText(labelText)
        label:SetShown(true)
        label.mmfSkipGlobalFont = true

        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
            label:SetTextColor(1, 1, 1)
        end)
        button:SetScript("OnLeave", function(self)
            if self.mmfActive then
                if self.mmfActiveBorderColor then
                    self:SetBackdropBorderColor(
                        self.mmfActiveBorderColor[1] or 0.25,
                        self.mmfActiveBorderColor[2] or 0.25,
                        self.mmfActiveBorderColor[3] or 0.3,
                        self.mmfActiveBorderColor[4] or 1
                    )
                else
                    self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
                end
                if self.mmfActiveTextColor then
                    label:SetTextColor(
                        self.mmfActiveTextColor[1] or 1,
                        self.mmfActiveTextColor[2] or 0.93,
                        self.mmfActiveTextColor[3] or 0.45
                    )
                else
                    label:SetTextColor(1, 0.93, 0.45)
                end
            else
                if self.mmfInactiveBorderColor then
                    self:SetBackdropBorderColor(
                        self.mmfInactiveBorderColor[1] or 0.25,
                        self.mmfInactiveBorderColor[2] or 0.25,
                        self.mmfInactiveBorderColor[3] or 0.3,
                        self.mmfInactiveBorderColor[4] or 1
                    )
                else
                    self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
                end
                if self.mmfInactiveTextColor then
                    label:SetTextColor(
                        self.mmfInactiveTextColor[1] or 0.9,
                        self.mmfInactiveTextColor[2] or 0.9,
                        self.mmfInactiveTextColor[3] or 0.9
                    )
                else
                    label:SetTextColor(0.9, 0.9, 0.9)
                end
            end
        end)
        button:SetScript("OnClick", function()
            if onClick then
                onClick()
            end
        end)

        button.labelText = label
        button.textHost = textHost
        container.button = button
        container.labelText = label
        container.mmfLabelRaw = labelText
        container.MMFRefreshWidget = function()
            if container.labelText and container.labelText.SetText then
                container.labelText:SetText(labelText)
            end
        end

        return container, button
    end

    return {
        EnsureTitleControlFont = EnsureTitleControlFont,
        CreateTitleCheckbox = CreateTitleCheckbox,
        CreateTitleButton = CreateTitleButton,
    }
end
