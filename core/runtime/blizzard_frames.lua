local hiddenBlizzardFrames = setmetatable({}, { __mode = "k" })
local castBarHooks = setmetatable({}, { __mode = "k" })
local castBarVisibilityDrivers = setmetatable({}, { __mode = "k" })
local castBarAlphaStates = setmetatable({}, { __mode = "k" })

local function SetCastBarWidgetAlphaHidden(widget, shouldHide)
    local state = castBarAlphaStates[widget]
    if not state then
        if not shouldHide then
            return
        end
        state = { hidden = false, alpha = widget:GetAlpha() }
        castBarAlphaStates[widget] = state

        local function KeepHiddenAlpha(self)
            if not state.hidden or state.applying then
                return
            end
            
            
            state.alpha = self:GetAlpha()
            state.applying = true
            self:SetAlpha(0)
            state.applying = false
        end
        hooksecurefunc(widget, "SetAlpha", KeepHiddenAlpha)
        if type(widget.SetAlphaFromBoolean) == "function" then
            hooksecurefunc(widget, "SetAlphaFromBoolean", KeepHiddenAlpha)
        end
    end

    if shouldHide then
        if not state.hidden then
            state.alpha = widget:GetAlpha()
        end
        state.hidden = true
        state.applying = true
        widget:SetAlpha(0)
        state.applying = false
    elseif state.hidden then
        state.hidden = false
        widget:SetAlpha(state.alpha)
    end
    return state
end

local function SetForeverCastBarAlphaHidden(frame, shouldHide)
    local state = SetCastBarWidgetAlphaHidden(frame, shouldHide)
    if not state then
        return
    end
    if not state.fadeWidgets then
        state.fadeWidgets = setmetatable({}, { __mode = "k" })
        if type(frame.AddWidgetForFade) == "function" then
            hooksecurefunc(frame, "AddWidgetForFade", function(_, widget)
                state.fadeWidgets[widget] = true
                SetCastBarWidgetAlphaHidden(widget, state.hidden)
            end)
        end
    end
    
    
    if frame.additionalFadeWidgets then
        for widget in pairs(frame.additionalFadeWidgets) do
            state.fadeWidgets[widget] = true
        end
    end
    for widget in pairs(state.fadeWidgets) do
        SetCastBarWidgetAlphaHidden(widget, shouldHide)
    end
end

local function HideBlizzardFrame(frame)
    if not frame or hiddenBlizzardFrames[frame] then
        return
    end

    
    
    
    
    
    if type(RegisterStateDriver) == "function" then
        local ok = pcall(RegisterStateDriver, frame, "visibility", "hide")
        if ok then
            hiddenBlizzardFrames[frame] = true
            return
        end
    end

    
    
    frame:Hide()
    if type(hooksecurefunc) == "function" then
        local ok = pcall(hooksecurefunc, frame, "Show", function(self)
            if hiddenBlizzardFrames[self]
                and (type(InCombatLockdown) ~= "function" or not InCombatLockdown()) then
                self:Hide()
            end
        end)
        if ok then
            hiddenBlizzardFrames[frame] = true
        end
    end
end

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
        HideBlizzardFrame(frame)
    end
    if TargetFrameToT then
        HideBlizzardFrame(TargetFrameToT)
    end

    local compat = _G.MMF_Compat
    if compat and compat.IsClassicEra then
        local comboFrames = {
            _G.ComboFrame,
            _G.ComboPointPlayerFrame,
            _G.PlayerFrameComboPoints,
        }
        for _, frame in ipairs(comboFrames) do
            HideBlizzardFrame(frame)
        end
    end
end

local function UpdateBlizzardPlayerCastBarVisibility()
    local shouldHide = MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true
    local compat = _G.MMF_Compat
    local isForever = compat and compat.IsForever == true
    local candidates = {
        _G.PlayerCastingBarFrame,
        _G.CastingBarFrame,
        _G.PlayerFrame and _G.PlayerFrame.castBar or nil,
    }

    if isForever then
        
        
        
        for _, frame in pairs(candidates) do
            SetForeverCastBarAlphaHidden(frame, shouldHide)
        end

        
        if type(InCombatLockdown) == "function" and InCombatLockdown() then
            if MMF_RunAfterCombat then
                MMF_RunAfterCombat("blizzard_castbar_visibility", UpdateBlizzardPlayerCastBarVisibility)
            end
            return
        end
    end

    for _, frame in pairs(candidates) do
        if frame then
            if isForever then
                if shouldHide then
                    if not castBarVisibilityDrivers[frame] and type(RegisterStateDriver) == "function" then
                        local ok = pcall(RegisterStateDriver, frame, "visibility", "hide")
                        if ok then
                            castBarVisibilityDrivers[frame] = true
                        end
                    end
                elseif castBarVisibilityDrivers[frame] then
                    if type(UnregisterStateDriver) == "function" then
                        pcall(UnregisterStateDriver, frame, "visibility")
                    end
                    castBarVisibilityDrivers[frame] = nil
                    if type(frame.UpdateShownState) == "function" then
                        pcall(frame.UpdateShownState, frame)
                    end
                end
            else
                
                
                
                if shouldHide and not castBarHooks[frame] then
                    frame:HookScript("OnShow", function(self)
                        if MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true then
                            self:Hide()
                        end
                    end)
                    castBarHooks[frame] = true
                end

                if shouldHide then
                    frame:Hide()
                end
            end
        end
    end
end

_G.MMF_HideBlizzardFrames = HideBlizzardFrames
_G.MMF_UpdateBlizzardPlayerCastBarVisibility = UpdateBlizzardPlayerCastBarVisibility
