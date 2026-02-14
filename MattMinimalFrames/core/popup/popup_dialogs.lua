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
