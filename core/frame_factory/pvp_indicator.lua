local cfg = MMF_Config or {}
local Compat = _G.MMF_Compat or {}

local function IsTBCPVPFlagEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.showTBCPVPFlagIndicator ~= false
end

local function IsRetailPVPFlagEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.showPVPFlagIndicator ~= false
end

local function CreatePVPFlagIndicator(frame, unit)
    if not frame or not frame.nameOverlay then return end
    if unit ~= "player" and unit ~= "target" then return end
    if frame.pvpFlagText then return end

    local text = frame.nameOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"
    if MMF_SetFontSafe then
        MMF_SetFontSafe(text, cfg.FONT_PATH, 10, fontFlags)
    else
        text:SetFont(cfg.FONT_PATH, 10, fontFlags)
    end
    text:SetText("PVP")
    text:SetTextColor(1, 0.2, 0.2, 1)
    if MMF_ApplyGlobalTextShadow then
        MMF_ApplyGlobalTextShadow(text)
    end

    text:ClearAllPoints()
    if unit == "player" then
        text:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
    else
        text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    end

    text:Hide()
    frame.pvpFlagText = text
end

local function UpdatePVPFlagIndicator(frame)
    if not frame or not frame.unit then return end
    if not frame.pvpFlagText then return end
    if Compat.IsTBC and not IsTBCPVPFlagEnabled() then
        frame.pvpFlagText:Hide()
        return
    end
    if not Compat.IsTBC and not IsRetailPVPFlagEnabled() then
        frame.pvpFlagText:Hide()
        return
    end

    local unit = frame.unit
    if (unit ~= "player" and unit ~= "target") or not UnitExists(unit) then
        frame.pvpFlagText:Hide()
        return
    end

    local function FormatPVPTimerText(milliseconds)
        local totalSeconds = math.floor(((tonumber(milliseconds) or 0) / 1000) + 0.5)
        if totalSeconds < 0 then totalSeconds = 0 end
        local minutes = math.floor(totalSeconds / 60)
        local seconds = totalSeconds % 60
        return string.format("%d:%02d", minutes, seconds)
    end

    local isFFA = UnitIsPVPFreeForAll(unit) == true
    local isFlagged = false
    local labelText = "PVP"
    local timerMode = false
    local textR, textG, textB = 1, 0.2, 0.2
    if unit == "player" then
        local desired = (GetPVPDesired and GetPVPDesired()) == true
        local timerRunning = (IsPVPTimerRunning and IsPVPTimerRunning()) == true
        if Compat.IsTBC then
            isFlagged = isFFA or (UnitIsPVP(unit) and (desired or timerRunning))
        else
            local warModeActive = C_PvP and C_PvP.IsWarModeActive and C_PvP.IsWarModeActive() == true
            local warModeDesired = C_PvP and C_PvP.IsWarModeDesired and C_PvP.IsWarModeDesired() == true
            isFlagged = isFFA or warModeActive or warModeDesired or UnitIsPVP(unit)
        end
        if timerRunning and not desired and GetPVPTimer then
            local timerText = FormatPVPTimerText(GetPVPTimer())
            local timerHex = "ffffd933"
            local _, playerClass = UnitClass("player")
            if playerClass == "ROGUE" then
                timerHex = "ffffffff"
            end
            labelText = "|cffff3333PVP|r |c" .. timerHex .. timerText .. "|r"
            timerMode = true
            textR, textG, textB = 1.0, 0.85, 0.2
        end
    else
        isFlagged = isFFA or (UnitIsPlayer(unit) and UnitIsPVP(unit))
    end

    if isFlagged then
        frame.pvpFlagText:SetText(labelText)
        if timerMode then
            frame.pvpFlagText:SetTextColor(1, 1, 1, 1)
        else
            frame.pvpFlagText:SetTextColor(textR, textG, textB, 1)
        end
        frame.pvpFlagText:Show()
    else
        frame.pvpFlagText:Hide()
    end
end

_G.MMF_FrameFactoryPVPIndicator = {
    CreatePVPFlagIndicator = CreatePVPFlagIndicator,
    UpdatePVPFlagIndicator = UpdatePVPFlagIndicator,
}

