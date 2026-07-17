local function HideBlizzardFrames()
    local framesToHide = {
        PlayerFrame,
        TargetFrame,
        FocusFrame,
        PetFrame,
        _G.Boss1TargetFrame,
        _G.Boss2TargetFrame,
        _G.Boss3TargetFrame,
        _G.Boss4TargetFrame,
        _G.Boss5TargetFrame,
        _G.BossTargetFrameContainer,
    }
    for _, frame in pairs(framesToHide) do
        if frame then
            frame:UnregisterAllEvents()
            frame:SetScript("OnShow", function(self) self:Hide() end)
            MMF_HideFrame(frame)
        end
    end
    if TargetFrameToT then
        TargetFrameToT:UnregisterAllEvents()
        TargetFrameToT:SetScript("OnShow", function(self) self:Hide() end)
        MMF_HideFrame(TargetFrameToT)
    end

    local compat = _G.MMF_Compat
    if compat and compat.IsClassicEra then
        local comboFrames = {
            _G.ComboFrame,
            _G.ComboPointPlayerFrame,
            _G.PlayerFrameComboPoints,
        }
        for _, frame in ipairs(comboFrames) do
            if frame then
                if frame.UnregisterAllEvents then
                    frame:UnregisterAllEvents()
                end
                frame:SetScript("OnShow", function(self) self:Hide() end)
                MMF_HideFrame(frame)
            end
        end
    end
end

local function UpdateBlizzardPlayerCastBarVisibility()
    local shouldHide = MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true
    local candidates = {
        _G.PlayerCastingBarFrame,
        _G.CastingBarFrame,
        _G.PlayerFrame and _G.PlayerFrame.castBar or nil,
    }

    for _, frame in pairs(candidates) do
        if frame then
            if not frame.mmfHideBlizzardCastBarHooked then
                frame:HookScript("OnShow", function(self)
                    if MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true then
                        self:Hide()
                    end
                end)
                frame.mmfHideBlizzardCastBarHooked = true
            end

            if shouldHide then
                frame:Hide()
            end
        end
    end
end

_G.MMF_HideBlizzardFrames = HideBlizzardFrames
_G.MMF_UpdateBlizzardPlayerCastBarVisibility = UpdateBlizzardPlayerCastBarVisibility
