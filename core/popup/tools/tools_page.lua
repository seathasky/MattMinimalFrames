local function MMF_ToolsNoteClamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function MMF_ToolsNoteClampChannel(value, fallback)
    local n = tonumber(value)
    if n == nil then
        n = tonumber(fallback) or 1
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function MMF_GetToolsNoteDefault(settingKey, fallback)
    local defaults = type(MattMinimalFrames_Defaults) == "table" and MattMinimalFrames_Defaults or nil
    if defaults and defaults[settingKey] ~= nil then
        return defaults[settingKey]
    end
    return fallback
end

local function MMF_EnsureToolsNoteDB()
    if type(MattMinimalFramesDB) ~= "table" then
        MattMinimalFramesDB = {}
    end
    if MattMinimalFramesDB.toolsNoteText == nil then
        MattMinimalFramesDB.toolsNoteText = MMF_GetToolsNoteDefault("toolsNoteText", "")
    end
    if MattMinimalFramesDB.toolsNoteAlpha == nil then
        MattMinimalFramesDB.toolsNoteAlpha = MMF_GetToolsNoteDefault("toolsNoteAlpha", 0.9)
    end
    if MattMinimalFramesDB.toolsNoteWidth == nil then
        MattMinimalFramesDB.toolsNoteWidth = MMF_GetToolsNoteDefault("toolsNoteWidth", 320)
    end
    if MattMinimalFramesDB.toolsNoteHeight == nil then
        MattMinimalFramesDB.toolsNoteHeight = MMF_GetToolsNoteDefault("toolsNoteHeight", 180)
    end
    if MattMinimalFramesDB.toolsNoteTextColorR == nil then
        MattMinimalFramesDB.toolsNoteTextColorR = MMF_GetToolsNoteDefault("toolsNoteTextColorR", 1.0)
    end
    if MattMinimalFramesDB.toolsNoteTextColorG == nil then
        MattMinimalFramesDB.toolsNoteTextColorG = MMF_GetToolsNoteDefault("toolsNoteTextColorG", 1.0)
    end
    if MattMinimalFramesDB.toolsNoteTextColorB == nil then
        MattMinimalFramesDB.toolsNoteTextColorB = MMF_GetToolsNoteDefault("toolsNoteTextColorB", 1.0)
    end
    if MattMinimalFramesDB.toolsNoteFontSize == nil then
        MattMinimalFramesDB.toolsNoteFontSize = MMF_GetToolsNoteDefault("toolsNoteFontSize", 11)
    end
    if MattMinimalFramesDB.toolsNoteMouseoverOpaque == nil then
        MattMinimalFramesDB.toolsNoteMouseoverOpaque = MMF_GetToolsNoteDefault("toolsNoteMouseoverOpaque", false)
    end
    if MattMinimalFramesDB.toolsNoteLocked == nil then
        MattMinimalFramesDB.toolsNoteLocked = MMF_GetToolsNoteDefault("toolsNoteLocked", false)
    end
    if type(MattMinimalFramesDB.toolsNotePosition) ~= "table" then
        MattMinimalFramesDB.toolsNotePosition = nil
    end
end

function MMF_EnsureToolsNoteFrame()
    if _G.MMF_ToolsNoteFrame then
        return _G.MMF_ToolsNoteFrame
    end

    MMF_EnsureToolsNoteDB()

    local noteFrame = CreateFrame("Frame", "MMF_ToolsNoteFrame", UIParent, "BackdropTemplate")
    noteFrame:SetFrameStrata("DIALOG")
    noteFrame:SetClampedToScreen(true)
    noteFrame:EnableMouse(true)
    noteFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    noteFrame:SetBackdropColor(0, 0, 0, 1)
    noteFrame:SetBackdropBorderColor(1, 1, 1, 0.35)
    noteFrame:Hide()

    local width = MMF_ToolsNoteClamp(tonumber(MattMinimalFramesDB.toolsNoteWidth) or 260, 320, 800)
    local height = MMF_ToolsNoteClamp(tonumber(MattMinimalFramesDB.toolsNoteHeight) or 180, 120, 600)
    noteFrame:SetSize(width, height)
    if MattMinimalFramesDB.toolsNotePosition and MattMinimalFramesDB.toolsNotePosition.left and MattMinimalFramesDB.toolsNotePosition.top then
        noteFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", MattMinimalFramesDB.toolsNotePosition.left, MattMinimalFramesDB.toolsNotePosition.top)
    else
        noteFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    noteFrame:SetMovable(true)
    noteFrame:RegisterForDrag("LeftButton")

    local alphaLabel = noteFrame:CreateFontString(nil, "OVERLAY")
    alphaLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    alphaLabel:SetPoint("TOPLEFT", noteFrame, "TOPLEFT", 8, -8)
    alphaLabel:SetTextColor(1, 1, 1, 1)

    local function SaveNoteSize()
        MMF_EnsureToolsNoteDB()
        MattMinimalFramesDB.toolsNoteWidth = math.floor((noteFrame:GetWidth() or 260) + 0.5)
        MattMinimalFramesDB.toolsNoteHeight = math.floor((noteFrame:GetHeight() or 180) + 0.5)
    end

    local function SaveNotePosition()
        MMF_EnsureToolsNoteDB()
        local left = noteFrame:GetLeft()
        local top = noteFrame:GetTop()
        if left and top then
            MattMinimalFramesDB.toolsNotePosition = {
                left = math.floor(left + 0.5),
                top = math.floor(top + 0.5),
            }
        end
    end

    local editBackground

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

        local initial = {
            r = MMF_ToolsNoteClampChannel(r, 1),
            g = MMF_ToolsNoteClampChannel(g, 1),
            b = MMF_ToolsNoteClampChannel(b, 1),
        }

        local function ApplyCurrentColor()
            local cr, cg, cb = GetColorPickerRGB()
            if cr and cg and cb and onChanged then
                onChanged(
                    MMF_ToolsNoteClampChannel(cr, initial.r),
                    MMF_ToolsNoteClampChannel(cg, initial.g),
                    MMF_ToolsNoteClampChannel(cb, initial.b)
                )
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
                    local rr = MMF_ToolsNoteClampChannel(restore.r, initial.r)
                    local rg = MMF_ToolsNoteClampChannel(restore.g, initial.g)
                    local rb = MMF_ToolsNoteClampChannel(restore.b, initial.b)
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
            local rr = MMF_ToolsNoteClampChannel(restore.r, initial.r)
            local rg = MMF_ToolsNoteClampChannel(restore.g, initial.g)
            local rb = MMF_ToolsNoteClampChannel(restore.b, initial.b)
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

    local noteEditBox
    local textColorButtonSwatch
    local fontSizeSlider
    local hoverModeCB
    local lockButton
    local resizeGrip
    local visualBackgroundAlpha = 1
    local alphaFadeDriver = CreateFrame("Frame", nil, noteFrame)
    alphaFadeDriver:Show()
    local hoverWatchDriver = CreateFrame("Frame", nil, noteFrame)
    hoverWatchDriver:Show()
    local hoverWatchElapsed = 0
    local lastHoverState = false
    local titleBarWidgets = {}
    local titleBarVisible = true
    titleBarWidgets[#titleBarWidgets + 1] = alphaLabel

    local function ApplyTextColor(r, g, b)
        MMF_EnsureToolsNoteDB()
        local cr = MMF_ToolsNoteClampChannel(r, 1)
        local cg = MMF_ToolsNoteClampChannel(g, 1)
        local cb = MMF_ToolsNoteClampChannel(b, 1)
        MattMinimalFramesDB.toolsNoteTextColorR = cr
        MattMinimalFramesDB.toolsNoteTextColorG = cg
        MattMinimalFramesDB.toolsNoteTextColorB = cb
        if noteEditBox then
            noteEditBox:SetTextColor(cr, cg, cb, 1)
        end
        if textColorButtonSwatch then
            textColorButtonSwatch:SetColorTexture(cr, cg, cb, 1)
        end
    end

    local function ApplyTextFontSize(size)
        MMF_EnsureToolsNoteDB()
        local n = math.floor((tonumber(size) or 11) + 0.5)
        if n < 8 then n = 8 end
        if n > 24 then n = 24 end
        MattMinimalFramesDB.toolsNoteFontSize = n
        if noteEditBox then
            noteEditBox:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", n, "")
        end
        if fontSizeSlider then
            fontSizeSlider:SetValue(n)
        end
    end

    local function SetBackgroundAlphaVisual(alpha)
        local clamped = MMF_ToolsNoteClamp(tonumber(alpha) or 1, 0.0, 1.0)
        visualBackgroundAlpha = clamped
        noteFrame:SetBackdropColor(0, 0, 0, clamped)
        noteFrame:SetBackdropBorderColor(1, 1, 1, 0.35 * clamped)
        if editBackground then
            editBackground:SetBackdropColor(0, 0, 0, clamped)
            editBackground:SetBackdropBorderColor(1, 1, 1, 0.12 * clamped)
        end
    end

    local function IsCursorInsideNote()
        if MMF_IsCursorInsideFrame then
            return MMF_IsCursorInsideFrame(noteFrame, 4)
        end
        return false
    end

    local function SetTitleBarVisible(visible)
        local show = (visible == true)
        if titleBarVisible == show then
            return
        end
        titleBarVisible = show
        for _, widget in ipairs(titleBarWidgets) do
            if widget and widget.SetShown then
                widget:SetShown(show)
            end
        end
        if editBackground then
            editBackground:ClearAllPoints()
            if show then
                editBackground:SetPoint("TOPLEFT", noteFrame, "TOPLEFT", 6, -28)
            else
                editBackground:SetPoint("TOPLEFT", noteFrame, "TOPLEFT", 6, -6)
            end
            editBackground:SetPoint("BOTTOMRIGHT", noteFrame, "BOTTOMRIGHT", -6, 6)
        end
    end

    local function GetTargetBackgroundAlpha()
        local baseAlpha = MMF_ToolsNoteClamp(tonumber(MattMinimalFramesDB.toolsNoteAlpha) or 0.9, 0.0, 1.0)
        if MattMinimalFramesDB.toolsNoteMouseoverOpaque == true and IsCursorInsideNote() then
            return 1.0
        end
        return baseAlpha
    end

    local function EaseBackgroundFadeProgress(t)
        if t <= 0 then
            return 0
        end
        if t >= 1 then
            return 1
        end
        return t * t * (3 - (2 * t))
    end

    local function GetBackgroundFadeDuration()
        local cfg = (MMF_GetPopupInactiveFadeConfig and MMF_GetPopupInactiveFadeConfig()) or nil
        local duration = cfg and tonumber(cfg.fadeTime) or nil
        if duration == nil or duration <= 0 then
            duration = 0.30
        end
        return duration
    end

    local function RefreshBackgroundAlpha(animate)
        local target = GetTargetBackgroundAlpha()
        if not animate then
            alphaFadeDriver:SetScript("OnUpdate", nil)
            SetBackgroundAlphaVisual(target)
            return
        end
        local startAlpha = visualBackgroundAlpha
        if math.abs(startAlpha - target) < 0.001 then
            SetBackgroundAlphaVisual(target)
            return
        end
        local elapsed = 0
        local duration = GetBackgroundFadeDuration()
        alphaFadeDriver:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + (dt or 0)
            local t = elapsed / duration
            if t >= 1 then
                alphaFadeDriver:SetScript("OnUpdate", nil)
                SetBackgroundAlphaVisual(target)
                return
            end
            local easedT = EaseBackgroundFadeProgress(t)
            SetBackgroundAlphaVisual(startAlpha + (target - startAlpha) * easedT)
        end)
    end

    local function ApplyMouseoverOpaqueState(enabled)
        MMF_EnsureToolsNoteDB()
        local isEnabled = (enabled == true)
        MattMinimalFramesDB.toolsNoteMouseoverOpaque = isEnabled
        if hoverModeCB then
            hoverModeCB:SetChecked(isEnabled)
            if hoverModeCB.check then
                hoverModeCB.check:SetShown(isEnabled)
            end
        end
        hoverWatchDriver:SetScript("OnUpdate", nil)
        if noteFrame:IsShown() then
            lastHoverState = IsCursorInsideNote()
            hoverWatchElapsed = 0
            hoverWatchDriver:SetScript("OnUpdate", function(_, dt)
                hoverWatchElapsed = hoverWatchElapsed + (dt or 0)
                if hoverWatchElapsed < 0.02 then
                    return
                end
                hoverWatchElapsed = 0
                local nowHover = IsCursorInsideNote()
                if nowHover ~= lastHoverState then
                    lastHoverState = nowHover
                    RefreshBackgroundAlpha(true)
                    SetTitleBarVisible(nowHover)
                end
            end)
        end
        RefreshBackgroundAlpha(true)
        SetTitleBarVisible(lastHoverState)
    end

    local function ApplyLockState(locked)
        MMF_EnsureToolsNoteDB()
        local isLocked = (locked == true)
        MattMinimalFramesDB.toolsNoteLocked = isLocked
        local stateR = isLocked and 0.2 or 0.95
        local stateG = isLocked and 0.9 or 0.25
        local stateB = isLocked and 0.25 or 0.25
        if lockButton then
            if lockButton.icon then
                if isLocked then
                    lockButton.icon:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
                else
                    lockButton.icon:SetTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
                end
                lockButton.icon:SetTexCoord(0.2, 0.8, 0.2, 0.8)
                lockButton.icon:SetVertexColor(stateR, stateG, stateB, 1)
            end
            lockButton:SetBackdropBorderColor(stateR, stateG, stateB, 0.85)
        end
        if resizeGrip then
            resizeGrip:SetShown(not isLocked)
        end
        if noteEditBox then
            if isLocked and noteEditBox.ClearFocus then
                noteEditBox:ClearFocus()
            end
            if noteEditBox.EnableMouse then
                noteEditBox:EnableMouse(not isLocked)
            end
            if noteEditBox.SetEnabled then
                noteEditBox:SetEnabled(not isLocked)
            end
        end
        if isLocked and noteFrame.mmfNoteResizing then
            noteFrame.mmfNoteResizing = false
            noteFrame:SetScript("OnUpdate", nil)
            SaveNoteSize()
        end
    end

    local function ApplyAlpha(alphaValue)
        MMF_EnsureToolsNoteDB()
        local clamped = MMF_ToolsNoteClamp(tonumber(alphaValue) or 0.9, 0.0, 1.0)
        MattMinimalFramesDB.toolsNoteAlpha = clamped
        alphaLabel:SetText("Alpha " .. math.floor(clamped * 100 + 0.5) .. "%")
        RefreshBackgroundAlpha(false)
    end

    local alphaDown = CreateFrame("Button", nil, noteFrame, "BackdropTemplate")
    alphaDown:SetSize(16, 14)
    alphaDown:SetPoint("LEFT", alphaLabel, "RIGHT", 6, 0)
    alphaDown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    alphaDown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    alphaDown:SetBackdropBorderColor(1, 1, 1, 0.25)
    local alphaDownText = alphaDown:CreateFontString(nil, "OVERLAY")
    alphaDownText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    alphaDownText:SetPoint("CENTER")
    alphaDownText:SetTextColor(1, 1, 1, 1)
    alphaDownText:SetText("-")
    alphaDown:SetScript("OnClick", function()
        ApplyAlpha((tonumber(MattMinimalFramesDB.toolsNoteAlpha) or 0.9) - 0.05)
    end)
    titleBarWidgets[#titleBarWidgets + 1] = alphaDown

    local alphaUp = CreateFrame("Button", nil, noteFrame, "BackdropTemplate")
    alphaUp:SetSize(16, 14)
    alphaUp:SetPoint("LEFT", alphaDown, "RIGHT", 3, 0)
    alphaUp:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    alphaUp:SetBackdropColor(0.08, 0.08, 0.08, 1)
    alphaUp:SetBackdropBorderColor(1, 1, 1, 0.25)
    local alphaUpText = alphaUp:CreateFontString(nil, "OVERLAY")
    alphaUpText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    alphaUpText:SetPoint("CENTER")
    alphaUpText:SetTextColor(1, 1, 1, 1)
    alphaUpText:SetText("+")
    alphaUp:SetScript("OnClick", function()
        ApplyAlpha((tonumber(MattMinimalFramesDB.toolsNoteAlpha) or 0.9) + 0.05)
    end)
    titleBarWidgets[#titleBarWidgets + 1] = alphaUp

    local textColorButton = CreateFrame("Button", nil, noteFrame, "BackdropTemplate")
    textColorButton:SetSize(18, 14)
    textColorButton:SetPoint("LEFT", alphaUp, "RIGHT", 6, 0)
    textColorButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    textColorButton:SetBackdropColor(0.08, 0.08, 0.08, 1)
    textColorButton:SetBackdropBorderColor(1, 1, 1, 0.25)
    textColorButtonSwatch = textColorButton:CreateTexture(nil, "OVERLAY")
    textColorButtonSwatch:SetPoint("TOPLEFT", textColorButton, "TOPLEFT", 3, -3)
    textColorButtonSwatch:SetPoint("BOTTOMRIGHT", textColorButton, "BOTTOMRIGHT", -3, 3)
    textColorButton:SetScript("OnClick", function()
        MMF_EnsureToolsNoteDB()
        local sr = MMF_ToolsNoteClampChannel(MattMinimalFramesDB.toolsNoteTextColorR, 1)
        local sg = MMF_ToolsNoteClampChannel(MattMinimalFramesDB.toolsNoteTextColorG, 1)
        local sb = MMF_ToolsNoteClampChannel(MattMinimalFramesDB.toolsNoteTextColorB, 1)
        OpenColorPicker(sr, sg, sb, function(nr, ng, nb)
            ApplyTextColor(nr, ng, nb)
        end, function(cr, cg, cb)
            ApplyTextColor(cr, cg, cb)
        end)
    end)
    titleBarWidgets[#titleBarWidgets + 1] = textColorButton

    local fontSizeLabel = noteFrame:CreateFontString(nil, "OVERLAY")
    fontSizeLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    fontSizeLabel:SetPoint("LEFT", textColorButton, "RIGHT", 6, 0)
    fontSizeLabel:SetTextColor(1, 1, 1, 1)
    fontSizeLabel:SetText("Font")
    titleBarWidgets[#titleBarWidgets + 1] = fontSizeLabel

    fontSizeSlider = CreateFrame("Slider", nil, noteFrame, "BackdropTemplate")
    fontSizeSlider:SetSize(42, 8)
    fontSizeSlider:SetPoint("LEFT", fontSizeLabel, "RIGHT", 3, 0)
    fontSizeSlider:SetOrientation("HORIZONTAL")
    fontSizeSlider:SetMinMaxValues(8, 24)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    fontSizeSlider:SetBackdropColor(0.06, 0.06, 0.08, 1)
    local fontThumb = fontSizeSlider:CreateTexture(nil, "OVERLAY")
    fontThumb:SetSize(6, 12)
    fontThumb:SetColorTexture(1, 1, 1, 1)
    fontSizeSlider:SetThumbTexture(fontThumb)
    fontSizeSlider:SetScript("OnValueChanged", function(_, value)
        local n = math.floor(value + 0.5)
        if MattMinimalFramesDB and MattMinimalFramesDB.toolsNoteFontSize ~= n then
            ApplyTextFontSize(n)
        end
    end)
    titleBarWidgets[#titleBarWidgets + 1] = fontSizeSlider

    hoverModeCB = CreateFrame("CheckButton", nil, noteFrame)
    hoverModeCB:SetSize(12, 12)
    hoverModeCB:SetPoint("LEFT", fontSizeSlider, "RIGHT", 8, 0)
    local hoverBg = hoverModeCB:CreateTexture(nil, "BACKGROUND")
    hoverBg:SetAllPoints()
    hoverBg:SetColorTexture(0.08, 0.08, 0.1, 1)
    local hoverBorder = hoverModeCB:CreateTexture(nil, "BORDER")
    hoverBorder:SetPoint("TOPLEFT", -1, 1)
    hoverBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    hoverBorder:SetColorTexture(1, 1, 1, 0.25)
    local hoverCheck = hoverModeCB:CreateTexture(nil, "ARTWORK")
    hoverCheck:SetPoint("TOPLEFT", 2, -2)
    hoverCheck:SetPoint("BOTTOMRIGHT", -2, 2)
    hoverCheck:SetColorTexture(1, 1, 1, 1)
    hoverModeCB.check = hoverCheck
    local hoverLabel = noteFrame:CreateFontString(nil, "OVERLAY")
    hoverLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    hoverLabel:SetPoint("LEFT", hoverModeCB, "RIGHT", 3, 0)
    hoverLabel:SetTextColor(1, 1, 1, 1)
    hoverLabel:SetText("MouseOver")
    hoverModeCB:SetScript("OnClick", function(self)
        ApplyMouseoverOpaqueState(self:GetChecked())
    end)
    titleBarWidgets[#titleBarWidgets + 1] = hoverModeCB
    titleBarWidgets[#titleBarWidgets + 1] = hoverLabel

    local closeButton = CreateFrame("Button", nil, noteFrame, "BackdropTemplate")
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("TOPRIGHT", noteFrame, "TOPRIGHT", -6, -6)
    closeButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    closeButton:SetBackdropColor(0.08, 0.08, 0.08, 1)
    closeButton:SetBackdropBorderColor(1, 1, 1, 0.25)
    local closeText = closeButton:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    closeText:SetPoint("CENTER")
    closeText:SetTextColor(1, 1, 1, 1)
    closeText:SetText("X")

    lockButton = CreateFrame("Button", nil, noteFrame, "BackdropTemplate")
    lockButton:SetSize(16, 16)
    lockButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0)
    lockButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    lockButton:SetBackdropColor(0.08, 0.08, 0.08, 1)
    lockButton:SetBackdropBorderColor(1, 1, 1, 0.25)
    local lockIcon = lockButton:CreateTexture(nil, "ARTWORK")
    lockIcon:SetPoint("TOPLEFT", 3, -3)
    lockIcon:SetPoint("BOTTOMRIGHT", -3, 3)
    lockButton.icon = lockIcon
    lockButton:SetScript("OnClick", function()
        ApplyLockState(not (MattMinimalFramesDB and MattMinimalFramesDB.toolsNoteLocked == true))
    end)
    titleBarWidgets[#titleBarWidgets + 1] = closeButton
    titleBarWidgets[#titleBarWidgets + 1] = lockButton

    closeButton:SetScript("OnClick", function()
        MMF_EnsureToolsNoteDB()
        MattMinimalFramesDB.showToolsNote = false
        noteFrame:Hide()
        local checkbox = noteFrame.mmfToolsNoteCheckbox
        if checkbox then
            checkbox:SetChecked(false)
            if checkbox.check then
                checkbox.check:SetShown(false)
            end
        end
    end)

    editBackground = CreateFrame("Frame", nil, noteFrame, "BackdropTemplate")
    editBackground:SetPoint("TOPLEFT", noteFrame, "TOPLEFT", 6, -28)
    editBackground:SetPoint("BOTTOMRIGHT", noteFrame, "BOTTOMRIGHT", -6, 6)
    editBackground:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBackground:SetBackdropColor(0, 0, 0, 0.8)
    editBackground:SetBackdropBorderColor(1, 1, 1, 0.12)

    noteEditBox = CreateFrame("EditBox", nil, editBackground)
    noteEditBox:SetPoint("TOPLEFT", editBackground, "TOPLEFT", 6, -6)
    noteEditBox:SetPoint("BOTTOMRIGHT", editBackground, "BOTTOMRIGHT", -6, 6)
    noteEditBox:SetAutoFocus(false)
    noteEditBox:SetMultiLine(true)
    noteEditBox:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", tonumber(MattMinimalFramesDB.toolsNoteFontSize) or 11, "")
    noteEditBox:SetTextColor(1, 1, 1, 1)
    noteEditBox:SetTextInsets(2, 2, 2, 2)
    noteEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    noteEditBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then
            return
        end
        MMF_EnsureToolsNoteDB()
        MattMinimalFramesDB.toolsNoteText = self:GetText() or ""
    end)

    resizeGrip = CreateFrame("Button", nil, noteFrame)
    resizeGrip:SetSize(18, 18)
    resizeGrip:SetPoint("BOTTOMRIGHT", noteFrame, "BOTTOMRIGHT", -1, 1)
    local resizeTexture = resizeGrip:CreateTexture(nil, "OVERLAY")
    resizeTexture:SetAllPoints()
    resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeTexture:SetVertexColor(1, 1, 1, 0.8)

    local function StopNoteResize()
        if not noteFrame.mmfNoteResizing then
            return
        end
        noteFrame.mmfNoteResizing = false
        noteFrame:SetScript("OnUpdate", nil)
        SaveNoteSize()
    end

    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then
            return
        end
        if MattMinimalFramesDB and MattMinimalFramesDB.toolsNoteLocked == true then
            return
        end
        local startX, startY = GetCursorPosition()
        noteFrame.mmfNoteResizing = true
        noteFrame.mmfResizeStartX = startX
        noteFrame.mmfResizeStartY = startY
        noteFrame.mmfResizeStartW = noteFrame:GetWidth() or 260
        noteFrame.mmfResizeStartH = noteFrame:GetHeight() or 180
        noteFrame:SetScript("OnUpdate", function(self)
            if not self.mmfNoteResizing then
                self:SetScript("OnUpdate", nil)
                return
            end
            local cx, cy = GetCursorPosition()
            local scale = self:GetEffectiveScale() or 1
            local deltaX = (cx - (self.mmfResizeStartX or cx)) / scale
            local deltaY = ((self.mmfResizeStartY or cy) - cy) / scale
            local newW = MMF_ToolsNoteClamp((self.mmfResizeStartW or 260) + deltaX, 320, 800)
            local newH = MMF_ToolsNoteClamp((self.mmfResizeStartH or 180) + deltaY, 120, 600)
            self:SetSize(newW, newH)
        end)
    end)
    resizeGrip:SetScript("OnMouseUp", StopNoteResize)
    resizeGrip:SetScript("OnHide", StopNoteResize)

    noteFrame.noteEditBox = noteEditBox
    noteFrame.ApplyAlpha = ApplyAlpha
    noteFrame.ApplyTextColor = ApplyTextColor
    noteFrame.ApplyTextFontSize = ApplyTextFontSize
    noteFrame.ApplyMouseoverOpaqueState = ApplyMouseoverOpaqueState
    noteFrame.ApplyLockState = ApplyLockState
    noteFrame.SaveNoteSize = SaveNoteSize
    noteFrame.SaveNotePosition = SaveNotePosition
    noteFrame:SetScript("OnDragStart", function(self)
        if MattMinimalFramesDB and MattMinimalFramesDB.toolsNoteLocked == true then
            return
        end
        self:StartMoving()
    end)
    noteFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveNotePosition()
    end)
    noteFrame:SetScript("OnHide", function()
        StopNoteResize()
        alphaFadeDriver:SetScript("OnUpdate", nil)
        hoverWatchDriver:SetScript("OnUpdate", nil)
    end)
    noteFrame:HookScript("OnShow", function()
        ApplyMouseoverOpaqueState(MattMinimalFramesDB and MattMinimalFramesDB.toolsNoteMouseoverOpaque == true)
        local hovering = IsCursorInsideNote()
        lastHoverState = hovering
        SetTitleBarVisible(hovering)
        RefreshBackgroundAlpha(false)
    end)
    noteFrame:HookScript("OnEnter", function()
        RefreshBackgroundAlpha(true)
    end)
    noteFrame:HookScript("OnLeave", function()
        RefreshBackgroundAlpha(true)
    end)

    MMF_EnsureToolsNoteDB()
    noteEditBox:SetText(MattMinimalFramesDB.toolsNoteText or "")
    ApplyTextColor(
        MattMinimalFramesDB.toolsNoteTextColorR,
        MattMinimalFramesDB.toolsNoteTextColorG,
        MattMinimalFramesDB.toolsNoteTextColorB
    )
    ApplyTextFontSize(MattMinimalFramesDB.toolsNoteFontSize or 11)
    ApplyMouseoverOpaqueState(MattMinimalFramesDB.toolsNoteMouseoverOpaque == true)
    ApplyLockState(MattMinimalFramesDB.toolsNoteLocked == true)
    ApplyAlpha(MattMinimalFramesDB.toolsNoteAlpha or 0.9)
    SetTitleBarVisible(IsCursorInsideNote())

    return noteFrame
end

function MMF_BindToolsNoteCheckbox(checkbox)
    local noteFrame = MMF_EnsureToolsNoteFrame()
    noteFrame.mmfToolsNoteCheckbox = checkbox
end

function MMF_SetToolsNoteEnabled(enabled, checkbox)
    MMF_EnsureToolsNoteDB()
    MattMinimalFramesDB.showToolsNote = (enabled == true)
    local noteFrame = MMF_EnsureToolsNoteFrame()
    if checkbox then
        noteFrame.mmfToolsNoteCheckbox = checkbox
    end

    if enabled then
        local width = MMF_ToolsNoteClamp(tonumber(MattMinimalFramesDB.toolsNoteWidth) or 260, 320, 800)
        local height = MMF_ToolsNoteClamp(tonumber(MattMinimalFramesDB.toolsNoteHeight) or 180, 120, 600)
        noteFrame:SetSize(width, height)
        if noteFrame.noteEditBox then
            noteFrame.noteEditBox:SetText(MattMinimalFramesDB.toolsNoteText or "")
        end
        if noteFrame.ApplyTextColor then
            noteFrame.ApplyTextColor(
                MattMinimalFramesDB.toolsNoteTextColorR,
                MattMinimalFramesDB.toolsNoteTextColorG,
                MattMinimalFramesDB.toolsNoteTextColorB
            )
        end
        if noteFrame.ApplyAlpha then
            noteFrame.ApplyAlpha(MattMinimalFramesDB.toolsNoteAlpha or 0.9)
        end
        if noteFrame.ApplyTextFontSize then
            noteFrame.ApplyTextFontSize(MattMinimalFramesDB.toolsNoteFontSize or 11)
        end
        if noteFrame.ApplyMouseoverOpaqueState then
            noteFrame.ApplyMouseoverOpaqueState(MattMinimalFramesDB.toolsNoteMouseoverOpaque == true)
        end
        if noteFrame.ApplyLockState then
            noteFrame.ApplyLockState(MattMinimalFramesDB.toolsNoteLocked == true)
        end
        noteFrame:Show()
        return
    end

    noteFrame:Hide()
end

function MMF_ApplyToolsNoteState()
    if type(MattMinimalFramesDB) ~= "table" then
        return
    end
    MMF_SetToolsNoteEnabled(MattMinimalFramesDB.showToolsNote == true)
end

function MMF_CreateToolsPage(rightCol, accentColor, accentHexPrefix, createMinimalCheckbox, isUISoundsEnabled)
    local ACCENT_COLOR = accentColor or { 0.6, 0.4, 0.9 }
    local ACCENT_HEX_PREFIX = accentHexPrefix or "|cff9966e6"
    local CreateMinimalCheckbox = createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local IsUISoundsEnabled = isUISoundsEnabled or MMF_IsPopupUISoundsEnabled or function()
        return true
    end

    -- RIGHT COLUMN: Tools
    ---------------------------------------------------
    local infoTitle = rightCol:CreateFontString(nil, "OVERLAY")
    infoTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    infoTitle:SetPoint("TOPLEFT", 12, -12)
    infoTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    infoTitle:SetText("TOOLS")

    CreateMinimalCheckbox(rightCol, "Show Move Hints", 12, -32, "showMoveHints", false, nil)

    -- Minimap icon checkbox (uses LibDBIcon's minimap.hide structure)
    local showMinimapContainer = CreateFrame("Frame", nil, rightCol)
    showMinimapContainer:SetSize(200, 20)
    showMinimapContainer:SetPoint("TOPLEFT", 12, -56)
    
    local showMinimapCB = CreateFrame("CheckButton", nil, showMinimapContainer)
    showMinimapCB:SetSize(14, 14)
    showMinimapCB:SetPoint("LEFT", 0, 0)
    
    local mmBg = showMinimapCB:CreateTexture(nil, "BACKGROUND")
    mmBg:SetAllPoints()
    mmBg:SetColorTexture(0.08, 0.08, 0.1, 1)
    
    local mmBorder = showMinimapCB:CreateTexture(nil, "BORDER")
    mmBorder:SetPoint("TOPLEFT", -1, 1)
    mmBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    mmBorder:SetColorTexture(0.25, 0.25, 0.3, 1)
    
    local mmCheck = showMinimapCB:CreateTexture(nil, "ARTWORK")
    mmCheck:SetSize(8, 8)
    mmCheck:SetPoint("CENTER")
    mmCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    showMinimapCB.check = mmCheck
    
    -- Initialize: LibDBIcon uses minimap.hide (true = hidden)
    local isHidden = MattMinimalFramesDB.minimap and MattMinimalFramesDB.minimap.hide
    showMinimapCB:SetChecked(not isHidden)
    mmCheck:SetShown(not isHidden)
    
    showMinimapCB:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.check:SetShown(checked)
        if MMF_ToggleMinimapButton then
            MMF_ToggleMinimapButton(checked)
        end
    end)
    
    local mmText = showMinimapContainer:CreateFontString(nil, "OVERLAY")
    mmText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    mmText:SetPoint("LEFT", showMinimapCB, "RIGHT", 6, 0)
    mmText:SetTextColor(0.85, 0.85, 0.85)
    mmText:SetText("Show Minimap Icon")

    -- Alignment grid (session-only, resets each time popup is created)
    if MattMinimalFramesDB then MattMinimalFramesDB.showAlignmentGrid = false end
    CreateMinimalCheckbox(rightCol, "Alignment Grid", 12, -80, "showAlignmentGrid", false, function(checked)
        if MMF_ToggleAlignmentGrid then
            MMF_ToggleAlignmentGrid(checked)
        end
    end)

    local function ClampPopupFadeAlpha(value)
        if MMF_ClampPopupInactiveFadeAlpha then
            return MMF_ClampPopupInactiveFadeAlpha(value, 0.60)
        end
        local n = tonumber(value) or 0.60
        if n < 0.05 then n = 0.05 end
        if n > 0.95 then n = 0.95 end
        return n
    end

    local popupFadeContainer = CreateFrame("Frame", nil, rightCol)
    popupFadeContainer:SetSize(256, 20)
    popupFadeContainer:SetPoint("TOPLEFT", 12, -104)

    local popupFadeCB = CreateFrame("CheckButton", nil, popupFadeContainer)
    popupFadeCB:SetSize(14, 14)
    popupFadeCB:SetPoint("LEFT", 0, 0)

    local popupFadeBg = popupFadeCB:CreateTexture(nil, "BACKGROUND")
    popupFadeBg:SetAllPoints()
    popupFadeBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local popupFadeBorder = popupFadeCB:CreateTexture(nil, "BORDER")
    popupFadeBorder:SetPoint("TOPLEFT", -1, 1)
    popupFadeBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    popupFadeBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local popupFadeCheck = popupFadeCB:CreateTexture(nil, "ARTWORK")
    popupFadeCheck:SetSize(8, 8)
    popupFadeCheck:SetPoint("CENTER")
    popupFadeCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    popupFadeCB.check = popupFadeCheck

    local popupFadeText = popupFadeContainer:CreateFontString(nil, "OVERLAY")
    popupFadeText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    popupFadeText:SetPoint("LEFT", popupFadeCB, "RIGHT", 6, 0)
    popupFadeText:SetTextColor(0.9, 0.9, 0.9)
    popupFadeText:SetText("Popup Inactive Fade")

    local popupFadeAlphaHost = CreateFrame("Frame", nil, popupFadeContainer)
    popupFadeAlphaHost:SetSize(98, 18)
    popupFadeAlphaHost:SetPoint("RIGHT", 0, 0)

    local popupFadeAlphaSlider = CreateFrame("Slider", nil, popupFadeAlphaHost, "BackdropTemplate")
    popupFadeAlphaSlider:SetSize(64, 8)
    popupFadeAlphaSlider:SetPoint("LEFT", 0, 0)
    popupFadeAlphaSlider:SetOrientation("HORIZONTAL")
    popupFadeAlphaSlider:SetMinMaxValues(0.05, 0.95)
    popupFadeAlphaSlider:SetValueStep(0.05)
    popupFadeAlphaSlider:SetObeyStepOnDrag(true)
    popupFadeAlphaSlider:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    popupFadeAlphaSlider:SetBackdropColor(0.06, 0.06, 0.08, 1)

    local popupFadeAlphaThumb = popupFadeAlphaSlider:CreateTexture(nil, "OVERLAY")
    popupFadeAlphaThumb:SetSize(6, 12)
    popupFadeAlphaThumb:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    popupFadeAlphaSlider:SetThumbTexture(popupFadeAlphaThumb)

    local popupFadeAlphaValueBg = CreateFrame("Frame", nil, popupFadeAlphaHost, "BackdropTemplate")
    popupFadeAlphaValueBg:SetSize(30, 18)
    popupFadeAlphaValueBg:SetPoint("RIGHT", 0, 0)
    popupFadeAlphaValueBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popupFadeAlphaValueBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
    popupFadeAlphaValueBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local popupFadeAlphaValue = popupFadeAlphaValueBg:CreateFontString(nil, "OVERLAY")
    popupFadeAlphaValue:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    popupFadeAlphaValue:SetPoint("CENTER")
    popupFadeAlphaValue:SetTextColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)

    popupFadeAlphaValueBg:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.6)
    end)
    popupFadeAlphaValueBg:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    local initialFadeEnabled = MattMinimalFramesDB.popupInactiveFade
    if initialFadeEnabled == nil then
        initialFadeEnabled = true
        MattMinimalFramesDB.popupInactiveFade = true
    end
    popupFadeCB:SetChecked(initialFadeEnabled)
    popupFadeCheck:SetShown(initialFadeEnabled)

    local initialFadeAlpha = ClampPopupFadeAlpha(MattMinimalFramesDB.popupInactiveFadeAlpha)
    MattMinimalFramesDB.popupInactiveFadeAlpha = initialFadeAlpha
    popupFadeAlphaSlider:SetValue(initialFadeAlpha)
    popupFadeAlphaValue:SetText(string.format("%.2f", initialFadeAlpha))
    popupFadeAlphaHost:SetShown(initialFadeEnabled)

    popupFadeCB:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        self.check:SetShown(checked)
        MattMinimalFramesDB.popupInactiveFade = checked
        popupFadeAlphaHost:SetShown(checked)
        if MMF_SetPopupInactiveFadeEnabled then
            MMF_SetPopupInactiveFadeEnabled(checked)
        elseif MMF_WelcomePopup and MMF_WelcomePopup.MMFApplyInactiveFade then
            MMF_WelcomePopup:MMFApplyInactiveFade(checked, true)
        end
    end)

    popupFadeAlphaSlider:SetScript("OnValueChanged", function(_, value)
        local alpha = ClampPopupFadeAlpha(value)
        popupFadeAlphaValue:SetText(string.format("%.2f", alpha))
        MattMinimalFramesDB.popupInactiveFadeAlpha = alpha
        if MMF_SetPopupInactiveFadeAlpha then
            MMF_SetPopupInactiveFadeAlpha(alpha)
        elseif MMF_WelcomePopup and MMF_WelcomePopup.MMFApplyInactiveFade then
            MMF_WelcomePopup:MMFApplyInactiveFade(MattMinimalFramesDB.popupInactiveFade ~= false, true)
        end
    end)

    local noteCheckboxContainer
    noteCheckboxContainer = CreateMinimalCheckbox(rightCol, "Simple Note", 12, -128, "showToolsNote", false, function(checked)
        if MMF_SetToolsNoteEnabled then
            MMF_SetToolsNoteEnabled(checked, noteCheckboxContainer and noteCheckboxContainer.checkbox)
        end
    end)
    if MMF_BindToolsNoteCheckbox and noteCheckboxContainer and noteCheckboxContainer.checkbox then
        MMF_BindToolsNoteCheckbox(noteCheckboxContainer.checkbox)
    end

    local toolsDivider = rightCol:CreateTexture(nil, "ARTWORK")
    toolsDivider:SetSize(176, 1)
    toolsDivider:SetPoint("TOPLEFT", 12, -160)
    toolsDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local toolsActionsTitle = rightCol:CreateFontString(nil, "OVERLAY")
    toolsActionsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    toolsActionsTitle:SetPoint("TOPLEFT", 12, -172)
    toolsActionsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    toolsActionsTitle:SetText("ACTIONS")

    CreateMinimalCheckbox(rightCol, "UI Sounds", 12, -196, "uiSoundsEnabled", true, nil)

    if MattMinimalFramesDB then
        MattMinimalFramesDB.hideChangelogPopup = (MattMinimalFramesDB.changelogSeenVersion == "7.7.2")
    end
    CreateMinimalCheckbox(rightCol, "Hide Changelog Popup", 12, -220, "hideChangelogPopup", false,
        function(checked)
            if MattMinimalFramesDB then
                MattMinimalFramesDB.hideChangelogPopup = checked
                MattMinimalFramesDB.changelogSeenVersion = checked and "7.7.2" or nil
            end
        end
    )

    local toolsResetScaleBtn = CreateFrame("Button", nil, rightCol, "BackdropTemplate")
    toolsResetScaleBtn:SetSize(176, 24)
    toolsResetScaleBtn:SetPoint("TOPLEFT", 12, -248)
    toolsResetScaleBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    toolsResetScaleBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    toolsResetScaleBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local toolsResetScaleBtnText = toolsResetScaleBtn:CreateFontString(nil, "OVERLAY")
    toolsResetScaleBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    toolsResetScaleBtnText:SetPoint("CENTER")
    toolsResetScaleBtnText:SetText("Reset Scale/Text")
    toolsResetScaleBtnText:SetTextColor(0.8, 0.8, 0.8)
    toolsResetScaleBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        toolsResetScaleBtnText:SetTextColor(1, 1, 1)
    end)
    toolsResetScaleBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        toolsResetScaleBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)
    toolsResetScaleBtn:SetScript("OnClick", function()
        MMF_ResetPopupScaleAndTextToDefaults()
    end)

    local toolsResetAllBtn = CreateFrame("Button", nil, rightCol, "BackdropTemplate")
    toolsResetAllBtn:SetSize(176, 24)
    toolsResetAllBtn:SetPoint("TOPLEFT", 12, -276)
    toolsResetAllBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    toolsResetAllBtn:SetBackdropColor(0.08, 0.08, 0.1, 1)
    toolsResetAllBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local toolsResetAllBtnText = toolsResetAllBtn:CreateFontString(nil, "OVERLAY")
    toolsResetAllBtnText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    toolsResetAllBtnText:SetPoint("CENTER")
    toolsResetAllBtnText:SetText("Reset All")
    toolsResetAllBtnText:SetTextColor(0.8, 0.8, 0.8)
    toolsResetAllBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.15, 1)
        toolsResetAllBtnText:SetTextColor(1, 0.3, 0.3)
    end)
    toolsResetAllBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
        toolsResetAllBtnText:SetTextColor(0.8, 0.8, 0.8)
    end)
    toolsResetAllBtn:SetScript("OnClick", function()
        if PlaySoundFile and IsUISoundsEnabled() then
            PlaySoundFile("Interface\\AddOns\\MattMinimalFrames\\Sounds\\are-you-sure-about-that.mp3", "Master")
        end
        StaticPopup_Show("MMF_RESET_ALL_WARNING")
    end)

    local infoDivider = rightCol:CreateTexture(nil, "ARTWORK")
    infoDivider:SetSize(176, 1)
    infoDivider:SetPoint("TOPLEFT", toolsResetAllBtn, "BOTTOMLEFT", 0, -8)
    infoDivider:SetColorTexture(0.12, 0.12, 0.15, 1)

    local toolsInfoTitle = rightCol:CreateFontString(nil, "OVERLAY")
    toolsInfoTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    toolsInfoTitle:SetPoint("TOPLEFT", infoDivider, "BOTTOMLEFT", 0, -10)
    toolsInfoTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    toolsInfoTitle:SetText("INFO")

    local infoText = rightCol:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    infoText:SetPoint("TOPLEFT", toolsInfoTitle, "BOTTOMLEFT", 0, -8)
    infoText:SetWidth(176)
    infoText:SetJustifyH("LEFT")
    infoText:SetSpacing(2)
    infoText:SetTextColor(0.6, 0.6, 0.6)
    local highlightColor = ACCENT_HEX_PREFIX
    infoText:SetText("Hold " .. highlightColor .. "SHIFT|r + mouse drag to reposition frames outside of Edit Mode.\nType " .. highlightColor .. "/mmf|r to open this panel.\nChanges to some checkboxes may require a UI reload.")

end

