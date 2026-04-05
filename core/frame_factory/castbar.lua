local cfg = MMF_Config or {}
local Compat = _G.MMF_Compat
local DragHelpers = _G.MMF_FrameFactoryDragHelpers or {}
local CastbarOffsetUtils = _G.MMF_FrameFactoryCastbarOffsets or {}

local function NotSecretValue(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return true
end

local function GetStatusBarTexturePath()
    if MMF_GetStatusBarTexturePath then
        return MMF_GetStatusBarTexturePath()
    end
    return cfg.TEXTURE_PATH
end

local function CanStartFrameDrag(frame)
    if DragHelpers.CanStartFrameDrag then
        return DragHelpers.CanStartFrameDrag(frame)
    end
    return false
end

local function GetDragHintText()
    if DragHelpers.GetDragHintText then
        return DragHelpers.GetDragHintText()
    end
    return "Shift+Drag to move"
end

local function TryStopFrameMoving(frame)
    if DragHelpers.TryStopFrameMoving then
        return DragHelpers.TryStopFrameMoving(frame)
    end
    return false
end

local function SaveCastBarPosition(frame, unit)
    if CastbarOffsetUtils.SaveCastBarPosition then
        return CastbarOffsetUtils.SaveCastBarPosition(frame, unit)
    end
end

local function ApplyCastBarPosition(frame, unit)
    if CastbarOffsetUtils.ApplyCastBarPosition then
        return CastbarOffsetUtils.ApplyCastBarPosition(frame, unit)
    end
end

local function CreateCastBar(frame, unit)
    local settingKey = (unit == "player" and "showPlayerCastBar")
        or (unit == "target" and "showTargetCastBar")
        or (unit == "focus" and "showFocusCastBar")
        or "showTargetCastBar"
    local showCastBar = MattMinimalFramesDB and MattMinimalFramesDB[settingKey]
    if showCastBar == nil then
        showCastBar = true
    end
    if not showCastBar then return end

    frame.castBarFrame = CreateFrame("Frame", nil, frame)
    frame.castBarFrame:SetFrameLevel(frame.healthBar:GetFrameLevel() + 5)
    frame.castBarFrame:SetMovable(true)
    frame.castBarFrame:EnableMouse(true)
    frame.castBarFrame:RegisterForDrag("LeftButton")
    frame.castBarFrame:SetHeight(8)

    frame.castBarBG = frame.castBarFrame:CreateTexture(nil, "BACKGROUND")
    frame.castBarBG:SetAllPoints(frame.castBarFrame)
    frame.castBarBG:SetColorTexture(0, 0, 0, 0.5)

    frame.castBarBorder = frame.castBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.castBarBorder:SetPoint("TOPLEFT", frame.castBarFrame, "TOPLEFT", -1, 1)
    frame.castBarBorder:SetPoint("BOTTOMRIGHT", frame.castBarFrame, "BOTTOMRIGHT", 1, -1)
    frame.castBarBorder:SetColorTexture(0, 0, 0, 1)

    frame.castBar = CreateFrame("StatusBar", nil, frame.castBarFrame)
    frame.castBar:SetAllPoints(frame.castBarFrame)
    frame.castBar:SetMinMaxValues(0, 1)
    frame.castBar:SetValue(0)
    frame.castBar:SetStatusBarTexture(GetStatusBarTexturePath())
    frame.castBar:SetStatusBarColor(1, 1, 1, 1)
    frame.castBar:SetAlpha(1)

    frame.castBarTextOverlay = CreateFrame("Frame", nil, frame.castBarFrame)
    frame.castBarTextOverlay:SetFrameLevel(frame.castBar:GetFrameLevel() + 2)
    frame.castBarTextOverlay:SetAllPoints(frame.castBarFrame)
    frame.castBarTextOverlay:EnableMouse(false)

    frame.castBarText = frame.castBarTextOverlay:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.castBarText, cfg.FONT_PATH, 9, "OUTLINE")
    else
        frame.castBarText:SetFont(cfg.FONT_PATH, 9, "OUTLINE")
    end
    frame.castBarText:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.castBarText:SetWordWrap(false)

    frame.castBarTime = frame.castBarTextOverlay:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.castBarTime, cfg.FONT_PATH, 9, "OUTLINE")
    else
        frame.castBarTime:SetFont(cfg.FONT_PATH, 9, "OUTLINE")
    end
    frame.castBarTime:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.castBarTime:SetWordWrap(false)
    frame.castBarTime:SetPoint("RIGHT", frame.castBarTextOverlay, "RIGHT", -3, 0)
    frame.castBarTime:SetJustifyH("RIGHT")
    frame.castBarTime:SetWidth(36)

    frame.castBarText:SetPoint("LEFT", frame.castBarTextOverlay, "LEFT", 3, 0)
    frame.castBarText:SetPoint("RIGHT", frame.castBarTime, "LEFT", -4, 0)
    frame.castBarText:SetJustifyH("LEFT")

    ApplyCastBarPosition(frame, unit)

    frame.castBarFrame:SetScript("OnDragStart", function(self)
        if CanStartFrameDrag(self) then
            self:StartMoving()
        end
    end)

    frame.castBarFrame:SetScript("OnDragStop", function(self)
        if not TryStopFrameMoving(self) then
            return
        end
        SaveCastBarPosition(frame, unit)
    end)

    frame.castBarFrame:SetScript("OnEnter", function(self)
        if CanStartFrameDrag(self) then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Cast Bar", 1, 1, 1)
            GameTooltip:AddLine(GetDragHintText(), 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end
    end)
    frame.castBarFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.castBarFrame:Hide()

    frame.castInfo = {
        casting = false,
        channeling = false,
        castID = nil,
        startTimeMs = nil,
        endTimeMs = nil,
    }

    local function SetCastTimeText(seconds)
        if frame.castBarTime then
            if NotSecretValue(seconds) and type(seconds) == "number" and seconds > 0 then
                frame.castBarTime:SetFormattedText("%.1f", seconds)
                return true
            else
                frame.castBarTime:SetText("")
                return false
            end
        end
        return false
    end

    local function GetSafeRemainingSeconds(endTimeMs)
        if not NotSecretValue(endTimeMs) or type(endTimeMs) ~= "number" then
            return nil
        end
        return (endTimeMs / 1000) - GetTime()
    end

    local function ShowCastBar(spellName, notInterruptible, startTimeMs, endTimeMs)
        local r, g, b = MMF_Config.GetCastBarColor(MattMinimalFramesDB and MattMinimalFramesDB.castBarColor or "yellow")
        if unit == "target" then
            frame.castBar:SetStatusBarColor(r, g, b, 1)
        else
            local isUninterruptible = (NotSecretValue(notInterruptible) and notInterruptible == true)
            if isUninterruptible then
                frame.castBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
            else
                frame.castBar:SetStatusBarColor(r, g, b, 1)
            end
        end
        if spellName then
            local ok = pcall(function() frame.castBarText:SetText(spellName) end)
            if not ok then frame.castBarText:SetText("") end
        else
            frame.castBarText:SetText("")
        end
        if Compat.IsTBC then
            SetCastTimeText(GetSafeRemainingSeconds(endTimeMs))
        else
            SetCastTimeText(nil)
        end
        if Compat.IsTBC and startTimeMs and endTimeMs then
            frame.castInfo.startTimeMs = startTimeMs
            frame.castInfo.endTimeMs = endTimeMs
            local maxVal = (endTimeMs - startTimeMs) / 1000
            frame.castBar:SetMinMaxValues(0, maxVal)
            if frame.castInfo.casting then
                frame.castBar:SetValue(GetTime() - startTimeMs / 1000)
            else
                frame.castBar:SetValue(endTimeMs / 1000 - GetTime())
            end
        end
        frame.castBarFrame:Show()
    end

    local function HideCastBar()
        frame.castInfo.casting = false
        frame.castInfo.channeling = false
        frame.castInfo.startTimeMs = nil
        frame.castInfo.endTimeMs = nil
        SetCastTimeText(nil)
        frame.castBarFrame:Hide()
    end

    local function SyncCastBarFromUnitState()
        local name, _, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
        if name then
            frame.castInfo.casting = true
            frame.castInfo.channeling = false
            frame.castInfo.castID = (unit == "player" and NotSecretValue(castID) and castID) or nil
            ShowCastBar(name, notInterruptible, startTime, endTime)
            return true
        end

        name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        if name then
            frame.castInfo.casting = false
            frame.castInfo.channeling = true
            frame.castInfo.castID = nil
            ShowCastBar(name, notInterruptible, startTime, endTime)
            return true
        end

        HideCastBar()
        return false
    end

    if Compat.IsTBC then
        frame.castBarFrame:SetScript("OnUpdate", function(self, elapsed)
            local info = frame.castInfo
            if info.casting and info.startTimeMs and info.endTimeMs then
                local now = GetTime()
                local startSec = info.startTimeMs / 1000
                local endSec = info.endTimeMs / 1000
                local maxVal = endSec - startSec
                local val = now - startSec
                if val >= maxVal then
                    frame.castBar:SetMinMaxValues(0, maxVal)
                    frame.castBar:SetValue(maxVal)
                    HideCastBar()
                    return
                end
                frame.castBar:SetMinMaxValues(0, maxVal)
                frame.castBar:SetValue(val)
                SetCastTimeText(maxVal - val)
            elseif info.channeling and info.startTimeMs and info.endTimeMs then
                local now = GetTime()
                local endSec = info.endTimeMs / 1000
                local startSec = info.startTimeMs / 1000
                local maxVal = endSec - startSec
                local val = endSec - now
                if val <= 0 then
                    HideCastBar()
                    return
                end
                frame.castBar:SetMinMaxValues(0, maxVal)
                frame.castBar:SetValue(val)
                SetCastTimeText(val)
            end
        end)
    else
        local StatusBarTimerDirection = Enum.StatusBarTimerDirection
        local StatusBarInterpolation = Enum.StatusBarInterpolation
        local function GetRemainingFromDurationObject(durationObject)
            if durationObject and durationObject.GetRemainingDuration then
                local ok, remaining = pcall(durationObject.GetRemainingDuration, durationObject)
                if ok and type(remaining) == "number" and NotSecretValue(remaining) then
                    return remaining
                end
            end
        end
        frame.castBarFrame:SetScript("OnUpdate", function(self, elapsed)
            local info = frame.castInfo
            if info.casting then
                local name = UnitCastingInfo(unit)
                if not name then
                    HideCastBar()
                    return
                end
                local duration = UnitCastingDuration(unit)
                if duration then
                    frame.castBar:SetTimerDuration(duration, StatusBarInterpolation.Immediate, StatusBarTimerDirection.ElapsedTime)
                    SetCastTimeText(GetRemainingFromDurationObject(duration))
                else
                    SetCastTimeText(nil)
                end
            elseif info.channeling then
                local name = UnitChannelInfo(unit)
                if not name then
                    HideCastBar()
                    return
                end
                local duration = UnitChannelDuration(unit)
                if duration then
                    frame.castBar:SetTimerDuration(duration, StatusBarInterpolation.Immediate, StatusBarTimerDirection.RemainingTime)
                    SetCastTimeText(GetRemainingFromDurationObject(duration))
                else
                    SetCastTimeText(nil)
                end
            end
        end)
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    if unit == "target" then
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif unit == "focus" then
        eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end
    if Compat.IsTBC then
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", unit)
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)
    end

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
            SyncCastBarFromUnitState()

        elseif event == "UNIT_SPELLCAST_START" then
            local name, _, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
            if name then
                frame.castInfo.casting = true
                frame.castInfo.channeling = false
                frame.castInfo.castID = (unit == "player" and NotSecretValue(castID) and castID) or nil
                ShowCastBar(name, notInterruptible, startTime, endTime)
            end

        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            local name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
            if name then
                frame.castInfo.casting = false
                frame.castInfo.channeling = true
                frame.castInfo.castID = nil
                ShowCastBar(name, notInterruptible, startTime, endTime)
            end

        elseif Compat.IsTBC and event == "UNIT_SPELLCAST_DELAYED" then
            if frame.castInfo.casting then
                local name, _, _, startTime, endTime = UnitCastingInfo(unit)
                if name and startTime and endTime then
                    frame.castInfo.startTimeMs = startTime
                    frame.castInfo.endTimeMs = endTime
                end
            end

        elseif Compat.IsTBC and event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
            if frame.castInfo.channeling then
                local name, _, _, startTime, endTime = UnitChannelInfo(unit)
                if name and startTime and endTime then
                    frame.castInfo.startTimeMs = startTime
                    frame.castInfo.endTimeMs = endTime
                end
            end

        elseif event == "UNIT_SPELLCAST_STOP" then
            if not frame.castInfo.casting then return end
            if unit == "target" then
                if not UnitCastingInfo(unit) then
                    SyncCastBarFromUnitState()
                end
            else
                local _, eventCastID = ...
                if NotSecretValue(eventCastID) and NotSecretValue(frame.castInfo.castID) and eventCastID == frame.castInfo.castID then
                    SyncCastBarFromUnitState()
                end
            end

        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            if frame.castInfo.channeling then
                SyncCastBarFromUnitState()
            end

        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            if not frame.castInfo.casting then return end
            if unit == "target" then
                if not UnitCastingInfo(unit) then
                    SyncCastBarFromUnitState()
                end
            else
                local _, eventCastID = ...
                if NotSecretValue(eventCastID) and NotSecretValue(frame.castInfo.castID) and eventCastID == frame.castInfo.castID then
                    SyncCastBarFromUnitState()
                end
            end
        end
    end)
end

_G.MMF_FrameFactoryCastbar = {
    CreateCastBar = CreateCastBar,
}

