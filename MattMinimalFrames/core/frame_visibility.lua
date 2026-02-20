local function ClampOpacity(value)
    local n = tonumber(value)
    if not n then
        return 0.35
    end
    if n < 0 then
        return 0
    end
    if n > 1 then
        return 1
    end
    return math.floor((n * 100) + 0.5) / 100
end

local function ClampFadeTime(value)
    local n = tonumber(value)
    if not n then
        return 0.4
    end
    if n < 0 then
        return 0
    end
    if n > 2 then
        return 2
    end
    return math.floor((n * 100) + 0.5) / 100
end

local function StopAlphaDriver(frame)
    if not frame or not frame.mmfAlphaDriver then
        return
    end
    frame.mmfAlphaDriver:SetScript("OnUpdate", nil)
    frame.mmfAlphaFade = nil
end

local function IsTargetLikeUnit(unit)
    return unit == "target" or unit == "targettarget"
end

local function SuspendUnitWatch(frame)
    if not frame or frame.mmfUnitWatchSuspended then
        return
    end
    if type(UnregisterUnitWatch) ~= "function" then
        return
    end
    local ok = pcall(UnregisterUnitWatch, frame)
    if ok then
        frame.mmfUnitWatchSuspended = true
    end
end

local function ResumeUnitWatch(frame)
    if not frame or not frame.mmfUnitWatchSuspended then
        return
    end
    if (type(InCombatLockdown) == "function") and InCombatLockdown() then
        if MMF_RunAfterCombat then
            local key = "mmf_resume_unitwatch_" .. (frame:GetName() or tostring(frame))
            MMF_RunAfterCombat(key, function()
                ResumeUnitWatch(frame)
            end)
        end
        return
    end
    if type(RegisterUnitWatch) ~= "function" then
        frame.mmfUnitWatchSuspended = nil
        return
    end
    pcall(RegisterUnitWatch, frame)
    frame.mmfUnitWatchSuspended = nil
end

local function EnsureVisibilityHooks(frame, unit)
    if not frame or frame.mmfCombatVisibilityHooksSet then
        return
    end

    frame:HookScript("OnShow", function(self)
        if self.mmfSuppressCombatVisibilityOnShow then
            self.mmfSuppressCombatVisibilityOnShow = nil
            return
        end

        if not MMF_IsCombatFrameVisibilityEnabled or MMF_IsCombatFrameVisibilityEnabled() ~= true then
            return
        end

        local inCombat = (type(InCombatLockdown) == "function") and InCombatLockdown() or false
        local alpha = MMF_GetCombatVisibilityBaseAlphaForUnit and MMF_GetCombatVisibilityBaseAlphaForUnit(unit) or 1

        -- Target/TOT should be instant in combat, but fade outside combat.
        if inCombat and IsTargetLikeUnit(unit) and alpha >= 1 then
            StopAlphaDriver(self)
            self:SetAlpha(alpha)
            return
        end

        if MMF_GetCombatVisibilityFadeTime then
            local fade = MMF_GetCombatVisibilityFadeTime()
            -- Out of combat, prime from hidden alpha so target reveal fades in.
            self:SetAlpha(0)
            MMF_SetAlphaSmooth(self, alpha, fade)
        else
            self:SetAlpha(alpha)
        end
    end)

    frame:HookScript("OnHide", function(self)
        if self.mmfSkipCombatVisibilityHide then
            self.mmfSkipCombatVisibilityHide = nil
            return
        end
        if self.mmfOOCFadeOutActive then
            return
        end
        if not IsTargetLikeUnit(unit) then
            return
        end
        if not MMF_IsCombatFrameVisibilityEnabled or MMF_IsCombatFrameVisibilityEnabled() ~= true then
            return
        end

        local inCombat = (type(InCombatLockdown) == "function") and InCombatLockdown() or false
        if inCombat then
            return
        end
        if type(UnitExists) ~= "function" or UnitExists(unit) then
            return
        end
        if not C_Timer or type(C_Timer.After) ~= "function" then
            return
        end

        local fade = MMF_GetCombatVisibilityFadeTime and MMF_GetCombatVisibilityFadeTime() or 0.4
        if fade < 0 then
            fade = 0
        end

        -- RegisterUnitWatch hides target/TOT instantly when the unit disappears.
        -- Suspend it briefly so we can complete the out-of-combat fade-out.
        SuspendUnitWatch(self)
        self.mmfOOCFadeOutActive = true

        self.mmfSuppressCombatVisibilityOnShow = true
        self:Show()

        local startAlpha = self:GetAlpha()
        if type(startAlpha) ~= "number" then
            startAlpha = MMF_GetOutOfCombatTargetOpacity and MMF_GetOutOfCombatTargetOpacity() or 1
        end
        self:SetAlpha(startAlpha)

        if MMF_SetAlphaSmooth then
            MMF_SetAlphaSmooth(self, 0, fade)
        else
            self:SetAlpha(0)
        end

        C_Timer.After(fade, function()
            if not self then
                return
            end

            local function FinalizeFadeOut()
                if not self then
                    return
                end

                self.mmfOOCFadeOutActive = nil

                if type(UnitExists) == "function" and UnitExists(unit) then
                    ResumeUnitWatch(self)
                    if MMF_UpdateCombatFrameVisibility then
                        MMF_UpdateCombatFrameVisibility()
                    end
                    return
                end

                StopAlphaDriver(self)
                self.mmfSkipCombatVisibilityHide = true
                self:Hide()
                ResumeUnitWatch(self)
            end

            if (type(InCombatLockdown) == "function") and InCombatLockdown() then
                if MMF_RunAfterCombat then
                    local key = "mmf_finalize_ooc_fade_" .. (self:GetName() or tostring(self))
                    MMF_RunAfterCombat(key, FinalizeFadeOut)
                    return
                end
                return
            end

            FinalizeFadeOut()
        end)
    end)

    frame.mmfCombatVisibilityHooksSet = true
end

local function SetAlphaSmooth(frame, targetAlpha, duration)
    if not frame then
        return
    end

    duration = tonumber(duration) or 0.35
    if duration <= 0 then
        StopAlphaDriver(frame)
        frame:SetAlpha(targetAlpha)
        return
    end

    local existingFade = frame.mmfAlphaFade
    if existingFade
        and math.abs((existingFade.targetAlpha or 0) - targetAlpha) < 0.001
        and math.abs((existingFade.duration or 0) - duration) < 0.001 then
        return
    end

    local currentAlpha = frame:GetAlpha() or 1
    if math.abs(currentAlpha - targetAlpha) < 0.001 then
        StopAlphaDriver(frame)
        frame:SetAlpha(targetAlpha)
        return
    end

    frame.mmfAlphaDriver = frame.mmfAlphaDriver or CreateFrame("Frame")
    frame.mmfAlphaDriver:SetParent(frame)
    frame.mmfAlphaFade = {
        startAlpha = currentAlpha,
        targetAlpha = targetAlpha,
        elapsed = 0,
        duration = duration,
    }

    frame.mmfAlphaDriver:SetScript("OnUpdate", function(self, elapsed)
        local parent = self:GetParent()
        if not parent or not parent.mmfAlphaFade then
            self:SetScript("OnUpdate", nil)
            return
        end

        local fade = parent.mmfAlphaFade
        fade.elapsed = fade.elapsed + (elapsed or 0)
        local progress = fade.elapsed / fade.duration
        if progress >= 1 then
            parent:SetAlpha(fade.targetAlpha)
            parent.mmfAlphaFade = nil
            self:SetScript("OnUpdate", nil)
            return
        end

        local newAlpha = fade.startAlpha + ((fade.targetAlpha - fade.startAlpha) * progress)
        parent:SetAlpha(newAlpha)
    end)
end

MMF_SetAlphaSmooth = SetAlphaSmooth
MMF_StopAlphaDriver = StopAlphaDriver

function MMF_GetCombatVisibilityBaseAlphaForUnit(unit)
    local enabled = MattMinimalFramesDB and MattMinimalFramesDB.enableCombatFrameVisibility == true
    if not enabled then
        return 1
    end

    local inCombat = (type(InCombatLockdown) == "function") and InCombatLockdown() or false
    if unit == "player" then
        local showOnTarget = MattMinimalFramesDB and MattMinimalFramesDB.showPlayerOnTargetSelected == true
        local hasTarget = (type(UnitExists) == "function") and UnitExists("target") or false
        if (not inCombat) and showOnTarget and hasTarget then
            return 1
        end
        return inCombat and 1 or 0
    end

    if unit == "target" or unit == "targettarget" then
        return inCombat and 1 or MMF_GetOutOfCombatTargetOpacity()
    end

    return 1
end

function MMF_IsCombatFrameVisibilityEnabled()
    if not MattMinimalFramesDB then
        return false
    end
    return MattMinimalFramesDB.enableCombatFrameVisibility == true
end

function MMF_GetOutOfCombatTargetOpacity()
    if not MattMinimalFramesDB then
        return 0.35
    end
    MattMinimalFramesDB.outOfCombatTargetOpacity = ClampOpacity(MattMinimalFramesDB.outOfCombatTargetOpacity)
    return MattMinimalFramesDB.outOfCombatTargetOpacity
end

function MMF_GetCombatVisibilityFadeTime()
    if not MattMinimalFramesDB then
        return 0.4
    end
    MattMinimalFramesDB.combatVisibilityFadeTime = ClampFadeTime(MattMinimalFramesDB.combatVisibilityFadeTime)
    return MattMinimalFramesDB.combatVisibilityFadeTime
end

function MMF_UpdateCombatFrameVisibility()
    local playerFrame = MMF_GetFrameForUnit and MMF_GetFrameForUnit("player") or _G.MMF_PlayerFrame
    local targetFrame = MMF_GetFrameForUnit and MMF_GetFrameForUnit("target") or _G.MMF_TargetFrame
    local totFrame = MMF_GetFrameForUnit and MMF_GetFrameForUnit("targettarget") or _G.MMF_TargetOfTargetFrame

    if not playerFrame and not targetFrame and not totFrame then
        return
    end

    EnsureVisibilityHooks(targetFrame, "target")
    EnsureVisibilityHooks(totFrame, "targettarget")

    local combatEnabled = MMF_IsCombatFrameVisibilityEnabled()
    local inCombat = (type(InCombatLockdown) == "function") and InCombatLockdown() or false
    local fadeTime = MMF_GetCombatVisibilityFadeTime()

    local function ApplyUnitAlpha(frame, unit)
        if not frame then
            return
        end
        if frame.mmfOOCFadeOutActive then
            return
        end

        if IsTargetLikeUnit(unit) and frame.mmfUnitWatchSuspended and type(UnitExists) == "function" and UnitExists(unit) then
            ResumeUnitWatch(frame)
        end

        local alpha = MMF_GetCombatVisibilityBaseAlphaForUnit(unit)
        if not combatEnabled then
            StopAlphaDriver(frame)
            frame:SetAlpha(alpha)
            return
        end

        -- Entering combat should immediately reveal target/TOT only.
        if inCombat and (unit == "target" or unit == "targettarget") and alpha >= 1 then
            StopAlphaDriver(frame)
            frame:SetAlpha(alpha)
            return
        end

        SetAlphaSmooth(frame, alpha, fadeTime)
    end

    ApplyUnitAlpha(playerFrame, "player")
    ApplyUnitAlpha(targetFrame, "target")
    ApplyUnitAlpha(totFrame, "targettarget")
end
