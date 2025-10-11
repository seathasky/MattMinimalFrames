--========================================================
-- MattMinimalFrames_UnitFrames.lua
-- Unit frame creation and visual setup
--========================================================

-- Constants
local DEFAULT_POWER_BAR_WIDTH = 73
local DEFAULT_POWER_BAR_HEIGHT = 5
local DEFAULT_POWER_BAR_VERTICAL_OFFSET = -24
local DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = 4

----------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------

local function MMF_ResetSecureAttributes(frame)
    if not frame or not frame.unit then return end
    frame:SetAttribute("unit", frame.unit)
    frame:SetAttribute("type1", "target")         -- Left-click => target
    frame:SetAttribute("target", frame.unit)
    frame:SetAttribute("type2", "togglemenu")       -- Right-click => Blizzard menu
    frame:SetAttribute("alt-type2", "focus")        -- Alt+Right-click => Focus
    frame:SetAttribute("focus", frame.unit)
    frame:SetAttribute("shift-alt-type2", "macro")   -- Shift+Alt+Right-click => /clearfocus
    frame:SetAttribute("shift-alt-macrotext2", "/clearfocus")
end

function MMF_GetUnitColor(unit)
    if not unit then return 1, 1, 1 end
    
    -- For enemy players
    if UnitIsPlayer(unit) and UnitIsEnemy("player", unit) then
        local _, class = UnitClass(unit)
        if class then
            local colors = RAID_CLASS_COLORS[class]
            if colors then
                return colors.r, colors.g, colors.b
            end
        end
    -- For friendly players (including self)
    elseif UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local colors = RAID_CLASS_COLORS[class]
            if colors then
                return colors.r, colors.g, colors.b
            end
        end
    -- For NPCs
    else
        -- Red for hostile NPCs
        if UnitIsEnemy("player", unit) then
            return 0.8, 0.2, 0.2
        -- Yellow for neutral NPCs
        elseif not UnitIsFriend("player", unit) then
            return 1, 1, 0
        -- Green for friendly NPCs
        else
            return 0.2, 0.8, 0.2
        end
    end
    
    return 1, 1, 1
end

----------------------------------------------------------
-- FRAME CREATION
----------------------------------------------------------

function MMF_CreateSecureMinimalUnitFrame(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
    -- Create a secure clickable unit button
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

    -- Tooltip on hover
    f:SetScript("OnEnter", function(self)
        if self.unit and UnitExists(self.unit) and 
           (self.unit == "target" or self.unit == "targettarget" or 
            self.unit == "player" or self.unit == "focus") then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
            self.highlightTexture:Show()
        end
    end)

    f:SetScript("OnLeave", function(self)
        if self.unit == "target" or self.unit == "targettarget" or 
           self.unit == "player" or self.unit == "focus" then
            GameTooltip:Hide()
            self.highlightTexture:Hide()
        end
    end)

    -- Positioning from DB or default
    if MattMinimalFramesDB and MattMinimalFramesDB[frameName] then
        local pos = MattMinimalFramesDB[frameName]
        f:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOffset, pos.yOffset)
    else
        f:SetPoint(point, UIParent, relPoint, xOfs, yOfs)
    end

    -- Drag handling
    f:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() and IsShiftKeyDown() then
            self:StartMoving()
        end
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        if p then
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB[frameName] = {
                point = p,
                relativePoint = rp,
                xOffset = x,
                yOffset = y,
            }
        end
    end)

    -- Add visual feedback for movement
    f.moveOverlay = f:CreateTexture(nil, "OVERLAY")
    f.moveOverlay:SetAllPoints()
    f.moveOverlay:SetColorTexture(1, 1, 1, 0.3)
    f.moveOverlay:Hide()

    f:HookScript("OnEnter", function(self)
        if not InCombatLockdown() and IsShiftKeyDown() then
            self.moveOverlay:Show()
        end
    end)

    f:HookScript("OnLeave", function(self)
        self.moveOverlay:Hide()
    end)

    -- Add shift-click movement hint
    f.moveHint = f:CreateFontString(nil, "OVERLAY")
    f.moveHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf", 10, "OUTLINE")
    f.moveHint:SetText("Hold Shift to move")
    f.moveHint:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.moveHint:Hide()

    f:HookScript("OnEnter", function(self)
        if MattMinimalFramesDB.locked and not InCombatLockdown() then
            self.moveHint:Show()
        end
    end)
    
    f:HookScript("OnLeave", function(self)
        self.moveHint:Hide()
    end)

    ------------------------------------------------------
    -- Health Bar Visuals
    ------------------------------------------------------
    f.healthBarBG = f:CreateTexture(nil, "BACKGROUND")
    f.healthBarBG:SetAllPoints(f)
    f.healthBarBG:SetColorTexture(0, 0, 0, 0.5)

    f.healthBarFG = f:CreateTexture(nil, "ARTWORK")
    f.healthBarFG:ClearAllPoints()
    f.healthBarFG:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.healthBarFG:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    f.healthBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
    f.healthBarFG:SetTexCoord(0, 1, 0, 1)

    -- Shield textures for player and target
    if unit == "player" or unit == "target" then
        f.shieldBarFG = f:CreateTexture(nil, "BACKGROUND")
        f.shieldBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\shield.tga")
        f.shieldBarFG:SetHorizTile(true)
        f.shieldBarFG:SetVertTile(true)
        f.shieldBarFG:SetPoint("TOPLEFT", f.healthBarFG, "TOPRIGHT", 0, 0)
        f.shieldBarFG:SetPoint("BOTTOMLEFT", f.healthBarFG, "BOTTOMRIGHT", 0, 0)
        f.shieldBarFG:SetTexCoord(0, 1, 0, 1)
        f.shieldBarFG:SetDrawLayer("BACKGROUND", 0)
        f.shieldBarFG:SetAlpha(0.5)
        f.shieldBarFG:Hide()

        f.shieldBarFG2 = f:CreateTexture(nil, "OVERLAY")
        f.shieldBarFG2:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\white.tga")
        f.shieldBarFG2:SetWidth(2)
        f.shieldBarFG2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -1)
        f.shieldBarFG2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 1)
        f.shieldBarFG2:SetTexCoord(0, 1, 0, 1)
        f.shieldBarFG2:SetDrawLayer("OVERLAY", 7)
        f.shieldBarFG2:Hide()

        f:SetScript("OnSizeChanged", function(self)
            f.shieldBarFG2:SetHeight(self:GetHeight() - 2)
        end)
    end

    -- Highlight texture
    f.highlightTexture = f:CreateTexture(nil, "OVERLAY")
    f.highlightTexture:SetAllPoints(f)
    f.highlightTexture:SetColorTexture(1, 1, 1, 0.15)
    f.highlightTexture:Hide()

    ------------------------------------------------------
    -- Name Text
    ------------------------------------------------------
    local fontPath = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Matt.ttf"
    f.nameText = f:CreateFontString(nil, "OVERLAY")
    if unit == "focus" or unit == "targettarget" then
        f.nameText:SetFont(fontPath, 10, "OUTLINE")
    else
        f.nameText:SetFont(fontPath, 14, "OUTLINE")
    end
    f.nameText:SetTextColor(1, 1, 1, 1)
    f.nameText:SetShadowOffset(1, -1)
    f.nameText:SetShadowColor(0, 0, 0, 0.9)
    
    if unit == "player" then
        f.nameText:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 8)
        f.nameText:SetJustifyH("LEFT")
    elseif unit == "target" then
        f.nameText:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 8)
        f.nameText:SetJustifyH("RIGHT")
    elseif unit == "targettarget" then
        f.nameText:SetPoint("TOP", f, "TOP", 0, 4)
        f.nameText:SetJustifyH("CENTER")
    elseif unit == "pet" then
        f.nameText:SetPoint("BOTTOM", f, "BOTTOM", 0, -5)
        f.nameText:SetJustifyH("CENTER")
    elseif unit == "focus" then
        f.nameText:SetPoint("TOP", f, "TOP", 0, 4)
        f.nameText:SetJustifyH("CENTER")
    else
        f.nameText:SetPoint("TOP", f, "TOP", 0, 1)
        f.nameText:SetJustifyH("CENTER")
    end
    f.nameText:SetWidth(f.originalWidth - 4)

    ------------------------------------------------------
    -- HP & Power Text
    ------------------------------------------------------
    f.hpText = f:CreateFontString(nil, "OVERLAY")
    f.hpText:SetFont(fontPath, 13, "OUTLINE")
    f.hpText:SetTextColor(1, 1, 1)
    f.powerText = f:CreateFontString(nil, "OVERLAY")
    f.powerText:SetFont(fontPath, 13, "OUTLINE")
    f.powerText:SetTextColor(1, 1, 1)
    
    if unit == "player" then
        f.hpText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -14.5)
        f.powerText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        MMF_CreatePowerBar(f, unit, "RIGHT", -DEFAULT_POWER_BAR_HORIZONTAL_OFFSET)
    elseif unit == "target" then
        f.hpText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, -14.5)
        f.powerText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        MMF_CreatePowerBar(f, unit, "LEFT", DEFAULT_POWER_BAR_HORIZONTAL_OFFSET)
    elseif unit == "targettarget" or unit == "pet" then
        f.hpText:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
        f.powerText:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    elseif unit == "focus" then
        f.hpText:Hide()
        f.powerText:Hide()
    else
        f.hpText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
        f.powerText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 3, 3)
    end

    ------------------------------------------------------
    -- Combat & Resting Indicators (player only)
    ------------------------------------------------------
    if unit == "player" then
        f.combatTexture = f:CreateTexture(nil, "OVERLAY")
        f.combatTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        f.combatTexture:SetTexCoord(0.5, 1, 0, 0.49)
        f.combatTexture:SetSize(22, 22)
        f.combatTexture:SetPoint("CENTER", f, "CENTER", 0, 0)
        f.combatTexture:Hide()

        f.restingTexture = f:CreateTexture(nil, "OVERLAY")
        f.restingTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        f.restingTexture:SetTexCoord(0, 0.5, 0, 0.421875)
        f.restingTexture:SetSize(20, 20)
        f.restingTexture:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, 10)
        f.restingTexture:SetDrawLayer("OVERLAY", 7)
        if IsResting() then
            f.restingTexture:Show()
        else
            f.restingTexture:Hide()
        end
    end

    ------------------------------------------------------
    -- Cast Bar (target only)
    ------------------------------------------------------
    if unit == "target" then
        MMF_CreateCastBar(f)
    end

    return f
end

----------------------------------------------------------
-- POWER BAR CREATION
----------------------------------------------------------

function MMF_CreatePowerBar(frame, unit, anchorSide, horizontalOffset)
    frame.powerBarFrame = CreateFrame("Frame", nil, frame)
    frame.powerBarFrame:SetSize(DEFAULT_POWER_BAR_WIDTH + 2, DEFAULT_POWER_BAR_HEIGHT + 2)
    frame.powerBarFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, DEFAULT_POWER_BAR_VERTICAL_OFFSET)
    frame.powerBarFrame:SetPoint(anchorSide, frame, anchorSide, horizontalOffset, 0)
    frame.powerBarFrame:SetMovable(true)
    frame.powerBarFrame:EnableMouse(true)
    frame.powerBarFrame:RegisterForDrag("LeftButton")
    
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
        MattMinimalFramesDB.powerBarPositions[unit] = {x = x - px, y = y - py}
    end)

    frame.powerBarBorder = frame.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.powerBarBorder:SetColorTexture(0, 0, 0, 0.5)
    frame.powerBarBorder:SetAllPoints()

    frame.powerBarBG = frame.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.powerBarBG:SetColorTexture(0, 0, 0, 0.25)
    frame.powerBarBG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
    frame.powerBarBG:SetWidth(DEFAULT_POWER_BAR_WIDTH)
    frame.powerBarBG:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)

    frame.powerBarFG = frame.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 2)
    frame.powerBarFG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
    frame.powerBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
    frame.powerBarFG:SetAlpha(0.5)
    frame.powerBarFG:SetPoint("BOTTOMLEFT", frame.powerBarBG, "BOTTOMLEFT", 0, 0)

    -- Restore saved position if it exists
    if MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit] then
        local pos = MattMinimalFramesDB.powerBarPositions[unit]
        frame.powerBarFrame:ClearAllPoints()
        frame.powerBarFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
    end
end

----------------------------------------------------------
-- CAST BAR CREATION
----------------------------------------------------------

function MMF_CreateCastBar(frame)
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
                self.casting = true
                self.castStart = GetTime()
                self.castDuration = (endTime - startTime) / 1000
                
                if notInterruptible then
                    self.castBarFG:SetColorTexture(0.7, 0.7, 0.7, 1)
                else
                    self.castBarFG:SetColorTexture(1, 1, 1, 1)
                end
                
                self.castBarBG:Show()
                self.castBarFG:Show()
                self:SetScript("OnUpdate", self.UpdateCastBar)
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

----------------------------------------------------------
-- POWER BAR SETTINGS
----------------------------------------------------------

function MMF_SetPowerBarSize(width, height)
    DEFAULT_POWER_BAR_WIDTH = width
    DEFAULT_POWER_BAR_HEIGHT = height
    
    for _, frameName in ipairs({"MMF_PlayerFrame", "MMF_TargetFrame"}) do
        local frame = _G[frameName]
        if frame and frame.powerBarFrame then
            frame.powerBarFrame:SetSize(width + 2, height + 2)
            frame.powerBarBG:SetSize(width, height)
            frame.powerBarFG:SetHeight(height)
        end
    end
    
    MattMinimalFramesDB.powerBarWidth = width
    MattMinimalFramesDB.powerBarHeight = height
end

function MMF_SetPowerBarOffset(verticalOffset, horizontalOffset)
    DEFAULT_POWER_BAR_VERTICAL_OFFSET = verticalOffset
    DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = horizontalOffset
    
    for _, frameName in ipairs({"MMF_PlayerFrame", "MMF_TargetFrame"}) do
        local frame = _G[frameName]
        if frame and frame.powerBarFrame then
            frame.powerBarFrame:ClearAllPoints()
            frame.powerBarFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, verticalOffset)
            if frameName == "MMF_PlayerFrame" then
                frame.powerBarFrame:SetPoint("RIGHT", frame, "RIGHT", -horizontalOffset, 0)
            else
                frame.powerBarFrame:SetPoint("LEFT", frame, "LEFT", horizontalOffset, 0)
            end
        end
    end
    
    MattMinimalFramesDB.powerBarVerticalOffset = verticalOffset
    MattMinimalFramesDB.powerBarHorizontalOffset = horizontalOffset
end

function MMF_UpdatePowerBarVisibility()
    local shouldShow = MattMinimalFramesDB and MattMinimalFramesDB.showPowerBars
    
    for _, frameName in ipairs({"MMF_PlayerFrame", "MMF_TargetFrame"}) do
        local frame = _G[frameName]
        if frame then
            if frame.powerBarFrame then
                frame.powerBarFrame:SetShown(shouldShow)
            end
            if frame.powerText then
                frame.powerText:SetShown(shouldShow)
            end
        end
    end
end
