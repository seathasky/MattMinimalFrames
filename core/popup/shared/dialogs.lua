local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = DeepCopy(v)
    end
    return out
end

StaticPopupDialogs["MMF_RELOADUI"] = {
    text = "Reload UI to apply changes?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MMF_RESET_ALL_WARNING"] = {
    text = "|cffFF4444WARNING:|r This will reset ALL settings and frame positions to defaults.\n\n|cffFFFF00Are you absolutely sure?|r",
    button1 = "Reset Everything",
    button2 = "Cancel",
    OnAccept = function()
        for k in pairs(MattMinimalFramesDB) do
            MattMinimalFramesDB[k] = nil
        end

        for key, value in pairs(MattMinimalFrames_Defaults) do
            MattMinimalFramesDB[key] = DeepCopy(value)
        end

        for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
            local frame = _G[def.name]
            if frame then
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", def.x, def.y)
            end
        end

        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MMF_RESET_CURRENT_CLASS_WARNING"] = {
    text = "|cffFFCC00Reset current class bar settings?|r\n\nThis will reset only the active class resource bar settings to defaults.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        if _G.MMF_OnConfirmResetCurrentClass then
            _G.MMF_OnConfirmResetCurrentClass()
            _G.MMF_OnConfirmResetCurrentClass = nil
        end
    end,
    OnCancel = function()
        _G.MMF_OnConfirmResetCurrentClass = nil
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MMF_DELETE_PROFILE_WARNING"] = {
    text = "Delete profile \"%s\"?",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function()
        if _G.MMF_OnConfirmProfileDelete then
            _G.MMF_OnConfirmProfileDelete()
            _G.MMF_OnConfirmProfileDelete = nil
        end
    end,
    OnCancel = function()
        _G.MMF_OnConfirmProfileDelete = nil
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MMF_RESET_PROFILE_WARNING"] = {
    text = "Reset profile \"%s\" to defaults?",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        if _G.MMF_OnConfirmProfileReset then
            _G.MMF_OnConfirmProfileReset()
            _G.MMF_OnConfirmProfileReset = nil
        end
    end,
    OnCancel = function()
        _G.MMF_OnConfirmProfileReset = nil
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MMF_COPY_LINK"] = {
    text = "|cffFF4444Jiberish Icons not found.|r\nCopy this URL:",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 320,
    OnShow = function(self, data)
        local url = tostring(data or self.data or "")
        if self.editBox then
            self.editBox:SetText(url)
            self.editBox:SetTextColor(1, 1, 1, 1)
            self.editBox:HighlightText(0, 0)
            self.editBox:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(self)
        self:ClearFocus()
        local parent = self:GetParent()
        if parent then
            parent:Hide()
        end
    end,
    OnHide = function(self)
        if self.editBox then
            self.editBox:SetText("")
            self.editBox:ClearFocus()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function MMF_ShowCopyLinkPopup(url)
    if StaticPopup_Show then
        local value = tostring(url or "")
        local dialog = StaticPopup_Show("MMF_COPY_LINK", nil, nil, value)
        if dialog and dialog.editBox then
            dialog.editBox:SetText(value)
            dialog.editBox:SetTextColor(1, 1, 1, 1)
            dialog.editBox:HighlightText(0, 0)
            dialog.editBox:SetFocus()
        end
    end
end

StaticPopupDialogs["MMF_DISCORD_LINK"] = {
    text = "Join Matt's Addons Discord\nCopy this URL:",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 320,
    OnShow = function(self, data)
        local url = tostring(data or self.data or "")
        if self.editBox then
            self.editBox:SetText(url)
            self.editBox:SetTextColor(1, 1, 1, 1)
            self.editBox:HighlightText(0, 0)
            self.editBox:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(self)
        self:ClearFocus()
        local parent = self:GetParent()
        if parent then
            parent:Hide()
        end
    end,
    OnHide = function(self)
        if self.editBox then
            self.editBox:SetText("")
            self.editBox:ClearFocus()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function EnsureDiscordCopyPopup()
    if _G.MMF_DiscordCopyPopup then
        return _G.MMF_DiscordCopyPopup
    end

    local popup = CreateFrame("Frame", "MMF_DiscordCopyPopup", UIParent, "BackdropTemplate")
    popup:SetSize(560, 160)
    popup:SetFrameStrata("DIALOG")
    popup:SetToplevel(true)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.04, 0.04, 0.05, 0.92)
    popup:SetBackdropBorderColor(0.1, 0.1, 0.12, 0.95)
    popup:Hide()

    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 16, "")
    title:SetPoint("TOP", 0, -18)
    title:SetTextColor(1, 1, 1)
    title:SetText("Join Matt's Addon Discord")

    local subtitle = popup:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 15, "")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetTextColor(1, 1, 1)
    subtitle:SetText("Copy this URL:")

    local editBg = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    editBg:SetSize(520, 32)
    editBg:SetPoint("TOP", subtitle, "BOTTOM", 0, -10)
    editBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBg:SetBackdropColor(0.02, 0.03, 0.08, 0.95)
    editBg:SetBackdropBorderColor(0.75, 0.75, 0.78, 1)

    local editBox = CreateFrame("EditBox", nil, editBg)
    editBox:SetAllPoints(editBg)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "")
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetJustifyH("LEFT")
    editBox:SetTextInsets(8, 8, 0, 0)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        popup:Hide()
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    popup.editBox = editBox

    local close = CreateFrame("Button", nil, popup, "BackdropTemplate")
    close:SetSize(180, 28)
    close:SetPoint("BOTTOM", 0, 12)
    close:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    close:SetBackdropColor(0.45, 0.04, 0.04, 0.95)
    close:SetBackdropBorderColor(0.65, 0.12, 0.12, 1)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 15, "")
    closeText:SetPoint("CENTER")
    closeText:SetTextColor(1, 0.9, 0.2)
    closeText:SetText("Close")
    close:SetScript("OnClick", function()
        popup:Hide()
    end)

    _G.MMF_DiscordCopyPopup = popup
    return popup
end

function MMF_ShowDiscordLinkPopup(url)
    local popup = EnsureDiscordCopyPopup()
    local value = tostring(url or "")
    popup.editBox:SetText(value)
    popup:ClearAllPoints()
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:Show()
    popup.editBox:SetFocus()
    popup.editBox:HighlightText()
end
