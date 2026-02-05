local cfg = MMF_Config
local Compat = _G.MMF_Compat

local function NotSecretValue(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return true
end

--------------------------------------------------
-- FRAME POSITIONING
--------------------------------------------------

local function SaveFramePosition(frame, frameName)
    local left = frame:GetLeft()
    local top = frame:GetTop()
    if left and top then
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB[frameName] = { left = left, top = top }
    end
end

local function RestoreFramePosition(frame, frameName, defaultPoint, defaultRelPoint, defaultX, defaultY)
    if MattMinimalFramesDB and MattMinimalFramesDB[frameName] then
        local pos = MattMinimalFramesDB[frameName]
        frame:ClearAllPoints()
        if pos.left ~= nil and pos.top ~= nil then
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
        else
            frame:SetPoint(defaultPoint, UIParent, defaultRelPoint, defaultX, defaultY)
        end
    else
        frame:ClearAllPoints()
        frame:SetPoint(defaultPoint, UIParent, defaultRelPoint, defaultX, defaultY)
    end
end

--------------------------------------------------
-- TOOLTIP HANDLERS
--------------------------------------------------

local function CreateTooltipHandlers(frame)
    frame:SetScript("OnEnter", function(self)
        if self.unit and UnitExists(self.unit) and 
           (self.unit == "target" or self.unit == "targettarget" or 
            self.unit == "player" or self.unit == "focus") then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
            self.highlightTexture:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        if self.unit == "target" or self.unit == "targettarget" or 
           self.unit == "player" or self.unit == "focus" then
            GameTooltip:Hide()
            self.highlightTexture:Hide()
        end
    end)
end

--------------------------------------------------
-- DRAG HANDLERS
--------------------------------------------------

local function CreateDragHandlers(frame, frameName)
    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() and IsShiftKeyDown() and self:IsMovable() then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        if self:IsMovable() then
            self:StopMovingOrSizing()
            SaveFramePosition(self, frameName)
        end
    end)

    frame.moveOverlay = frame:CreateTexture(nil, "OVERLAY")
    frame.moveOverlay:SetAllPoints()
    frame.moveOverlay:SetColorTexture(1, 1, 1, 0.3)
    frame.moveOverlay:Hide()

    frame:HookScript("OnEnter", function(self)
        if not InCombatLockdown() and IsShiftKeyDown() then
            self.moveOverlay:Show()
        end
    end)

    frame:HookScript("OnLeave", function(self)
        self.moveOverlay:Hide()
    end)

    local frameDef = MMF_GetFrameDefinition(frame.unit)
    local frameLabel = frameDef and frameDef.label or frame.unit
    
    frame.moveHint = frame:CreateFontString(nil, "OVERLAY")
    frame.moveHint:SetFont(cfg.FONT_PATH, 10, "OUTLINE")
    frame.moveHint:SetText(frameLabel)
    frame.moveHint:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.moveHint:Hide()
    
    frame.moveSubtext = frame:CreateFontString(nil, "OVERLAY")
    frame.moveSubtext:SetFont(cfg.FONT_PATH, 9, "OUTLINE")
    frame.moveSubtext:SetText("Shift+Drag to move")
    frame.moveSubtext:SetPoint("TOP", frame.moveHint, "BOTTOM", 0, -2)
    frame.moveSubtext:SetTextColor(0.7, 0.7, 0.7)
    frame.moveSubtext:Hide()

    frame:HookScript("OnEnter", function(self)
        if not InCombatLockdown() and MattMinimalFramesDB.showMoveHints then
            self.moveHint:Show()
            self.moveSubtext:Show()
        end
    end)
    
    frame:HookScript("OnLeave", function(self)
        self.moveHint:Hide()
        self.moveSubtext:Hide()
    end)
end

--------------------------------------------------
-- HEALTH BAR CREATION
--------------------------------------------------

local function CreateHealthBar(frame)
    frame.healthBarBG = frame:CreateTexture(nil, "BACKGROUND")
    frame.healthBarBG:SetAllPoints(frame)
    frame.healthBarBG:SetColorTexture(0, 0, 0, 0.5)

    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.healthBar:SetStatusBarTexture(cfg.TEXTURE_PATH)
    frame.healthBar:SetMinMaxValues(0, 1)
    frame.healthBar:SetValue(1)
    frame.healthBarFG = frame.healthBar:GetStatusBarTexture()
end

--------------------------------------------------
-- POWER BAR CREATION
--------------------------------------------------

local function CreatePowerBarContainer(frame, unit)
    frame.powerBarFrame = CreateFrame("Frame", nil, frame)
    frame.powerBarFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    frame.powerBarBG = frame.powerBarFrame:CreateTexture(nil, "BACKGROUND")
    frame.powerBarBG:SetColorTexture(0, 0, 0, 0.25)
    
    frame.powerBar = CreateFrame("StatusBar", nil, frame.powerBarFrame)
    frame.powerBar:SetStatusBarTexture(cfg.TEXTURE_PATH)
    frame.powerBar:SetMinMaxValues(0, 1)
    frame.powerBar:SetValue(1)
    frame.powerBarFG = frame.powerBar:GetStatusBarTexture()
end

local function SetupPowerBar(frame, unit)
    local DEFAULT_WIDTH = MattMinimalFramesDB.powerBarWidth or cfg.POWER_BAR_WIDTH
    local DEFAULT_HEIGHT = MattMinimalFramesDB.powerBarHeight or cfg.POWER_BAR_HEIGHT
    local DEFAULT_V_OFFSET = cfg.POWER_BAR_VERTICAL_OFFSET
    local DEFAULT_H_OFFSET = cfg.POWER_BAR_HORIZONTAL_OFFSET

    frame.powerBarFrame:SetSize(DEFAULT_WIDTH + 2, DEFAULT_HEIGHT + 2)
    frame.powerBarFrame:SetMovable(true)
    frame.powerBarFrame:EnableMouse(true)
    frame.powerBarFrame:RegisterForDrag("LeftButton")
    
    if unit == "player" then
        frame.powerBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -DEFAULT_H_OFFSET, DEFAULT_V_OFFSET)
    else
        frame.powerBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", DEFAULT_H_OFFSET, DEFAULT_V_OFFSET)
    end

    frame.powerBarFrame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() and IsShiftKeyDown() then
            self:StartMoving()
        end
    end)

    frame.powerBarFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local px, py = frame:GetCenter()
        if not MattMinimalFramesDB.powerBarPositions then
            MattMinimalFramesDB.powerBarPositions = {}
        end
        MattMinimalFramesDB.powerBarPositions[unit] = { x = x - px, y = y - py }
    end)

    frame.powerBarFrame:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        if unit == "player" then
            GameTooltip:SetText("Player Power Bar", 1, 1, 1)
        else
            GameTooltip:SetText("Target Power Bar", 1, 1, 1)
        end
        GameTooltip:AddLine("Shift+Drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    frame.powerBarFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    frame.powerBarBorder = frame.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.powerBarBorder:SetColorTexture(0, 0, 0, 0.5)
    frame.powerBarBorder:SetAllPoints()

    frame.powerBarBG:SetHeight(DEFAULT_HEIGHT)
    frame.powerBarBG:SetWidth(DEFAULT_WIDTH)
    frame.powerBarBG:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)

    frame.powerBar:SetHeight(DEFAULT_HEIGHT)
    frame.powerBar:SetWidth(DEFAULT_WIDTH)
    frame.powerBar:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)
    frame.powerBar:SetAlpha(0.5)

    if MattMinimalFramesDB and MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit] then
        local pos = MattMinimalFramesDB.powerBarPositions[unit]
        frame.powerBarFrame:ClearAllPoints()
        frame.powerBarFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
    end
end

--------------------------------------------------
-- ABSORB BAR CREATION
--------------------------------------------------

local function CreateAbsorbBar(frame)
    frame.absorbBar = CreateFrame("StatusBar", nil, frame)
    frame.absorbBar:SetStatusBarTexture(cfg.SHIELD_TEXTURE_PATH)
    frame.absorbBar:SetMinMaxValues(0, 1)
    frame.absorbBar:SetValue(0)
    frame.absorbBar:SetStatusBarColor(0, 1, 1, 1.0)
    frame.absorbBar:SetReverseFill(true)
    
    local texture = frame.absorbBar:GetStatusBarTexture()
    if texture then
        texture:SetHorizTile(true)
        texture:SetVertTile(true)
    end
    
    frame.absorbBar:Hide()
    frame.absorbBar:SetWidth(46)
    frame.absorbBar:SetPoint("RIGHT", frame.healthBar, "RIGHT", 0, 0)
    frame.absorbBar:SetHeight(frame.healthBar:GetHeight() or 20)
    frame.absorbBar:SetFrameLevel(frame.healthBar:GetFrameLevel() + 2)
end

--------------------------------------------------
-- TEXT ELEMENTS
--------------------------------------------------

local function CreateNameText(frame, unit)
    local fontPath = cfg.FONT_PATH
    
    frame.nameOverlay = CreateFrame("Frame", nil, frame)
    frame.nameOverlay:SetAllPoints(frame)
    frame.nameOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    
    frame.nameText = frame.nameOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
    
    local fontSize = MMF_GetNameTextSize()
    frame.nameText:SetFont(fontPath, fontSize, "OUTLINE")
    frame.nameText:SetTextColor(1, 1, 1, 1)
    frame.nameText:SetShadowOffset(1, -1)
    frame.nameText:SetShadowColor(0, 0, 0, 0.9)
    
    local positions = {
        player = { point = "LEFT", relPoint = "TOPLEFT", x = 2, y = 0, justify = "LEFT" },
        target = { point = "RIGHT", relPoint = "TOPRIGHT", x = -2, y = 0, justify = "RIGHT" },
        targettarget = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        pet = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        focus = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
    }
    
    local pos = positions[unit] or positions.focus
    frame.nameText:SetPoint(pos.point, frame, pos.relPoint, pos.x, pos.y)
    frame.nameText:SetJustifyH(pos.justify)
    frame.nameText:SetWidth(frame.originalWidth - 4)
end

local function CreateResourceText(frame, unit)
    local fontPath = cfg.FONT_PATH
    local hpSize = MMF_GetHPTextSize and MMF_GetHPTextSize() or 13
    
    frame.hpText = frame.nameOverlay:CreateFontString(nil, "OVERLAY")
    frame.hpText:SetFont(fontPath, hpSize, "OUTLINE")
    frame.hpText:SetTextColor(1, 1, 1)
    
    frame.powerText = frame.nameOverlay:CreateFontString(nil, "OVERLAY")
    frame.powerText:SetFont(fontPath, 13, "OUTLINE")
    frame.powerText:SetTextColor(1, 1, 1)
    
    if unit == "player" then
        frame.hpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -14.5)
        frame.powerText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    elseif unit == "target" then
        frame.hpText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, -14.5)
        frame.powerText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    elseif unit == "targettarget" or unit == "pet" then
        frame.hpText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
        frame.powerText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    elseif unit == "focus" then
        frame.hpText:Hide()
        frame.powerText:Hide()
    else
        frame.hpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
        frame.powerText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)
    end
end

--------------------------------------------------
-- COMBAT/RESTING INDICATORS
--------------------------------------------------

local function CreatePlayerIndicators(frame)
    frame.combatTexture = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.combatTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.combatTexture:SetTexCoord(0.5, 1, 0, 0.49)
    frame.combatTexture:SetSize(22, 22)
    frame.combatTexture:SetPoint("CENTER", frame, "CENTER", 0, 12)
    frame.combatTexture:SetDrawLayer("OVERLAY", 7)
    frame.combatTexture:Hide()

    frame.restingTexture = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.restingTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.restingTexture:SetTexCoord(0, 0.5, 0, 0.421875)
    frame.restingTexture:SetSize(20, 20)
    frame.restingTexture:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 10)
    frame.restingTexture:SetDrawLayer("OVERLAY", 7)
    frame.restingTexture:SetShown(IsResting())
end

--------------------------------------------------
-- CAST BAR (Player and Target)
--------------------------------------------------

local function CreateCastBar(frame, unit)
    local settingKey = (unit == "player") and "showPlayerCastBar" or "showTargetCastBar"
    local showCastBar = MattMinimalFramesDB and MattMinimalFramesDB[settingKey]
    if showCastBar == nil then
        showCastBar = true
    end
    if not showCastBar then return end
    
    frame.castBarFrame = CreateFrame("Frame", nil, frame)
    frame.castBarFrame:SetFrameLevel(frame.healthBar:GetFrameLevel() + 5)
    frame.castBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    frame.castBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.castBarFrame:SetHeight(8)
    
    frame.castBarBG = frame.castBarFrame:CreateTexture(nil, "BACKGROUND")
    frame.castBarBG:SetAllPoints(frame.castBarFrame)
    frame.castBarBG:SetColorTexture(0, 0, 0, 0.5)

    frame.castBar = CreateFrame("StatusBar", nil, frame.castBarFrame)
    frame.castBar:SetAllPoints(frame.castBarFrame)
    frame.castBar:SetMinMaxValues(0, 1)
    frame.castBar:SetValue(0)
    frame.castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.castBar:SetStatusBarColor(1, 1, 1, 1)
    
    frame.castBarTextOverlay = CreateFrame("Frame", nil, frame.castBarFrame)
    frame.castBarTextOverlay:SetFrameLevel(frame.castBar:GetFrameLevel() + 2)
    frame.castBarTextOverlay:SetAllPoints(frame.castBarFrame)
    frame.castBarTextOverlay:EnableMouse(false)
    
    frame.castBarText = frame.castBarTextOverlay:CreateFontString(nil, "OVERLAY")
    frame.castBarText:SetFont(cfg.FONT_PATH, 9, "OUTLINE")
    frame.castBarText:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.castBarText:SetWordWrap(false)
    
    frame.castBarText:SetPoint("CENTER", frame.castBarTextOverlay, "CENTER", 0, 0)
    frame.castBarText:SetJustifyH("CENTER")
    frame.castBarText:SetWidth(frame.originalWidth - 8)
    frame.castBarFrame:Hide()
    
    frame.castInfo = {
        casting = false,
        channeling = false,
        castID = nil,  
        startTimeMs = nil,  -- TBC only: from UnitCastingInfo/UnitChannelInfo (ms)
        endTimeMs = nil,    -- TBC only
    }
    
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
        frame.castBarFrame:Hide()
    end
    
    -- OnUpdate: TBC uses manual timing (no SetTimerDuration/UnitCastingDuration); Retail uses SetTimerDuration
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
            end
        end)
    else
        local StatusBarTimerDirection = Enum.StatusBarTimerDirection
        local StatusBarInterpolation = Enum.StatusBarInterpolation
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
                end
            end
        end)
    end

    -- Create a separate event frame to avoid conflicts
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    if unit == "target" then
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
    if Compat.IsTBC then
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", unit)
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)
    end
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            local name, _, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
            if name then
                frame.castInfo.casting = true
                frame.castInfo.channeling = false
                frame.castInfo.castID = (unit == "player" and NotSecretValue(castID) and castID) or nil
                ShowCastBar(name, notInterruptible, Compat.IsTBC and startTime or nil, Compat.IsTBC and endTime or nil)
                return
            end
            name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
            if name then
                frame.castInfo.casting = false
                frame.castInfo.channeling = true
                frame.castInfo.castID = nil
                ShowCastBar(name, notInterruptible, Compat.IsTBC and startTime or nil, Compat.IsTBC and endTime or nil)
                return
            end
            HideCastBar()
            
        elseif event == "UNIT_SPELLCAST_START" then
            local name, _, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
            if name then
                frame.castInfo.casting = true
                frame.castInfo.channeling = false
                frame.castInfo.castID = (unit == "player" and NotSecretValue(castID) and castID) or nil
                ShowCastBar(name, notInterruptible, Compat.IsTBC and startTime or nil, Compat.IsTBC and endTime or nil)
            end
            
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            -- TBC: name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID
            local name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
            if name then
                frame.castInfo.casting = false
                frame.castInfo.channeling = true
                frame.castInfo.castID = nil
                ShowCastBar(name, notInterruptible, Compat.IsTBC and startTime or nil, Compat.IsTBC and endTime or nil)
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
            -- For target, castID is secret - use API instead of comparing
            if unit == "target" then
                if not UnitCastingInfo(unit) then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            else
                local _, eventCastID = ...
                if NotSecretValue(eventCastID) and NotSecretValue(frame.castInfo.castID) and eventCastID == frame.castInfo.castID then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            end
            
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            if frame.castInfo.channeling then
                frame.castInfo.channeling = false
                HideCastBar()
            end
            
        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            if not frame.castInfo.casting then return end
            if unit == "target" then
                if not UnitCastingInfo(unit) then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            else
                local _, eventCastID = ...
                if NotSecretValue(eventCastID) and NotSecretValue(frame.castInfo.castID) and eventCastID == frame.castInfo.castID then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            end
            
        end
    end)
end

--------------------------------------------------
-- MAIN FRAME CREATION
--------------------------------------------------

function MMF_CreateSecureUnitFrame(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
    local f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForClicks("AnyUp")
    f:RegisterForDrag("LeftButton")
    f:SetSize(width, height)
    f.originalWidth = width
    f.originalHeight = height
    f.unit = unit

    MMF_ResetSecureAttributes(f)
    CreateTooltipHandlers(f)
    RestoreFramePosition(f, frameName, point, relPoint, xOfs, yOfs)
    CreateDragHandlers(f, frameName)
    CreateHealthBar(f)

    if unit == "player" or unit == "target" then
        CreatePowerBarContainer(f, unit)
        CreateAbsorbBar(f)
    end

    f.highlightTexture = f:CreateTexture(nil, "OVERLAY")
    f.highlightTexture:SetAllPoints(f)
    f.highlightTexture:SetColorTexture(1, 1, 1, 0.15)
    f.highlightTexture:Hide()

    CreateNameText(f, unit)
    CreateResourceText(f, unit)

    if unit == "player" or unit == "target" then
        SetupPowerBar(f, unit)
    end

    if unit == "player" then
        CreatePlayerIndicators(f)
    end

    if unit == "player" or unit == "target" then
        CreateCastBar(f, unit)
    end

    return f
end

local originalCreate = MMF_CreateSecureUnitFrame
MMF_CreateSecureUnitFrame = function(...)
    local frame = originalCreate(...)
    
    if frame.powerBarFrame then
        frame.powerBarFrame:SetShown(MattMinimalFramesDB and MattMinimalFramesDB.showPowerBars)
        frame.powerText:SetShown(MattMinimalFramesDB and MattMinimalFramesDB.showPowerBars)
    end
    
    return frame
end

function MMF_SetGUIScale(scale)
    if MMF_WelcomePopup then
        MMF_WelcomePopup:SetScale(scale)
    end
end
