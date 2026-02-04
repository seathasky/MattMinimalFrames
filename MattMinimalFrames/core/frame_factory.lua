-- core/frame_factory.lua
-- Factory module for creating unit frames

local cfg = MMF_Config

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

    -- Visual feedback for movement
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

    -- Frame label from config
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
    -- Background
    frame.healthBarBG = frame:CreateTexture(nil, "BACKGROUND")
    frame.healthBarBG:SetAllPoints(frame)
    frame.healthBarBG:SetColorTexture(0, 0, 0, 0.5)

    -- Health bar as StatusBar
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

    -- Tooltip on mouse over
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

    -- Border
    frame.powerBarBorder = frame.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.powerBarBorder:SetColorTexture(0, 0, 0, 0.5)
    frame.powerBarBorder:SetAllPoints()

    -- Background
    frame.powerBarBG:SetHeight(DEFAULT_HEIGHT)
    frame.powerBarBG:SetWidth(DEFAULT_WIDTH)
    frame.powerBarBG:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)

    -- Power bar
    frame.powerBar:SetHeight(DEFAULT_HEIGHT)
    frame.powerBar:SetWidth(DEFAULT_WIDTH)
    frame.powerBar:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)
    frame.powerBar:SetAlpha(0.5)

    -- Restore saved position
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
    
    -- Position based on unit
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
    frame.combatTexture:SetPoint("CENTER", frame, "CENTER", 0, 0)
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
-- CAST BAR (Target only)
--------------------------------------------------

local function CreateCastBar(frame)
    frame.castBarBG = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.castBarBG:SetColorTexture(0, 0, 0, 0.5)
    frame.castBarBG:SetHeight(3)
    frame.castBarBG:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    frame.castBarBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.castBarBG:Hide()

    frame.castBarFG = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    frame.castBarFG:SetHeight(3)
    frame.castBarFG:SetPoint("BOTTOMLEFT", frame.castBarBG, "BOTTOMLEFT", 0, 0)
    frame.castBarFG:Hide()
    
    frame.UpdateCastBar = function(self, elapsed)
        if not self.casting then return end
        
        local duration = GetTime() - self.castStart
        if duration > self.castDuration then
            self.casting = false
            self.castBarBG:Hide()
            self.castBarFG:Hide()
            self:SetScript("OnUpdate", nil)
            return
        end
        
        local width = self.originalWidth - 2
        local progress = duration / self.castDuration
        self.castBarFG:SetWidth(width * progress)
    end

    -- Register cast events
    frame:RegisterEvent("UNIT_SPELLCAST_START")
    frame:RegisterEvent("UNIT_SPELLCAST_STOP")
    frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    
    frame:HookScript("OnEvent", function(self, event, ...)
        local eventUnit = ...
        if eventUnit ~= self.unit then return end
        
        if event == "UNIT_SPELLCAST_START" then
            local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(self.unit)
            if name then
                local success, duration = pcall(function()
                    return (endTime - startTime) / 1000
                end)
                
                if success and duration then
                    self.casting = true
                    self.castStart = GetTime()
                    self.castDuration = duration
                    
                    if notInterruptible then
                        self.castBarFG:SetColorTexture(0.7, 0.7, 0.7, 1)
                    else
                        self.castBarFG:SetColorTexture(1, 1, 1, 1)
                    end
                    
                    self.castBarBG:Show()
                    self.castBarFG:Show()
                    self:SetScript("OnUpdate", self.UpdateCastBar)
                else
                    self.casting = false
                    self.castBarBG:Hide()
                    self.castBarFG:Hide()
                    self:SetScript("OnUpdate", nil)
                end
            end
        elseif event == "UNIT_SPELLCAST_STOP" or 
               event == "UNIT_SPELLCAST_FAILED" or 
               event == "UNIT_SPELLCAST_INTERRUPTED" then
            self.casting = false
            self.castBarBG:Hide()
            self.castBarFG:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end

--------------------------------------------------
-- MAIN FRAME CREATION
--------------------------------------------------

function MMF_CreateSecureUnitFrame(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
    -- Create secure button
    local f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForClicks("AnyUp")
    f:RegisterForDrag("LeftButton")
    f:SetSize(width, height)
    f.originalWidth = width
    f.originalHeight = height
    f.unit = unit

    -- Secure attributes
    MMF_ResetSecureAttributes(f)

    -- Tooltip handlers
    CreateTooltipHandlers(f)
    
    -- Position
    RestoreFramePosition(f, frameName, point, relPoint, xOfs, yOfs)

    -- Drag handlers
    CreateDragHandlers(f, frameName)

    -- Health bar
    CreateHealthBar(f)

    -- Power bar (player and target only)
    if unit == "player" or unit == "target" then
        CreatePowerBarContainer(f, unit)
        CreateAbsorbBar(f)
    end

    -- Highlight texture
    f.highlightTexture = f:CreateTexture(nil, "OVERLAY")
    f.highlightTexture:SetAllPoints(f)
    f.highlightTexture:SetColorTexture(1, 1, 1, 0.15)
    f.highlightTexture:Hide()

    -- Text elements
    CreateNameText(f, unit)
    CreateResourceText(f, unit)

    -- Setup power bar layout (player/target)
    if unit == "player" or unit == "target" then
        SetupPowerBar(f, unit)
    end

    -- Player-specific indicators
    if unit == "player" then
        CreatePlayerIndicators(f)
    end

    -- Target-specific cast bar
    if unit == "target" then
        CreateCastBar(f)
    end

    return f
end

-- Wrapper with initial visibility setup
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
    -- Scale only the popup GUI
    if MMF_WelcomePopup then
        MMF_WelcomePopup:SetScale(scale)
    end
end
