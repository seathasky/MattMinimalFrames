--========================================================
-- MattMinimalFrames_Frames.lua
--========================================================


-------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------

function MMF_FormatNumber(num)
    if type(num) ~= "number" then return "0" end
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

-- No caching needed - StatusBars handle secret values directly

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

local function MMF_GetUnitColor(unit)
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

-------------------------------------------------
-- CREATE MINIMAL UNIT FRAMES (NO BACKDROP)
-------------------------------------------------

local DEFAULT_POWER_BAR_WIDTH = 73
local DEFAULT_POWER_BAR_HEIGHT = 5
local DEFAULT_POWER_BAR_VERTICAL_OFFSET = -24  -- Distance from bottom of frame
local DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = 1  -- Distance from edge of frame

local function CreateSecureMinimalUnitFrame(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
    -- Create a secure clickable unit button
    local f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")
    f:SetMovable(true)  -- Set this when creating the frame
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
        -- Show tooltips for these units
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
    -- Use TOPLEFT anchoring for consistent save/restore behavior
    if MattMinimalFramesDB and MattMinimalFramesDB[frameName] then
        local pos = MattMinimalFramesDB[frameName]
        f:ClearAllPoints()
        if pos.left ~= nil and pos.top ~= nil then
            -- New format: absolute left/top position
            local uiScale = UIParent:GetEffectiveScale()
            local frameScale = f:GetEffectiveScale()
            f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
        else
            -- Old format or invalid: use defaults
            f:SetPoint(point, UIParent, relPoint, xOfs, yOfs)
        end
    else
        f:ClearAllPoints()
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
        -- Save position using TOPLEFT relative to UIParent BOTTOMLEFT
        local left = self:GetLeft()
        local top = self:GetTop()
        if left and top then
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB[frameName] = {
                left = left,
                top = top,
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
    f.moveHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "OUTLINE")
    f.moveHint:SetText("Hold Shift to move")
    f.moveHint:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.moveHint:Hide()

    -- Show move hint on mouse over when frames are locked
    f:HookScript("OnEnter", function(self)
        if MattMinimalFramesDB.locked and not InCombatLockdown() then
            self.moveHint:Show()
        end
    end)
    
    f:HookScript("OnLeave", function(self)
        self.moveHint:Hide()
    end)

    ------------------------------------------------------
    -- Minimal visuals: Health Bar (using StatusBar for secret value support)
    ------------------------------------------------------
    -- Health bar background
    f.healthBarBG = f:CreateTexture(nil, "BACKGROUND")
    f.healthBarBG:SetAllPoints(f)
    f.healthBarBG:SetColorTexture(0, 0, 0, 0.5)

    -- Health bar as actual StatusBar (can handle secret values)
    f.healthBar = CreateFrame("StatusBar", nil, f)
    f.healthBar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.healthBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    f.healthBar:SetStatusBarTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
    f.healthBar:SetMinMaxValues(0, 1)
    f.healthBar:SetValue(1)
    
    -- Keep reference to the texture for color changes
    f.healthBarFG = f.healthBar:GetStatusBarTexture()

    -- Power bar (as StatusBar)
    if unit == "player" or unit == "target" then
        f.powerBarFrame = CreateFrame("Frame", nil, f)
        f.powerBarFrame:SetFrameLevel(f:GetFrameLevel() + 1)
        
        f.powerBarBG = f.powerBarFrame:CreateTexture(nil, "BACKGROUND")
        f.powerBarBG:SetColorTexture(0, 0, 0, 0.25)
        
        -- Power bar as StatusBar
        f.powerBar = CreateFrame("StatusBar", nil, f.powerBarFrame)
        f.powerBar:SetStatusBarTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
        f.powerBar:SetMinMaxValues(0, 1)
        f.powerBar:SetValue(1)
        f.powerBarFG = f.powerBar:GetStatusBarTexture()
    end

    if unit == "player" or unit == "target" then
        -- Create absorb StatusBar (overlays on top of health bar)
        f.absorbBar = CreateFrame("StatusBar", nil, f)
        f.absorbBar:SetStatusBarTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\shield.tga")
        f.absorbBar:SetMinMaxValues(0, 1)
        f.absorbBar:SetValue(0)
        f.absorbBar:SetStatusBarColor(0, 1, 1, 1.0)  -- Bright cyan for absorbs
        f.absorbBar:SetReverseFill(true)  -- Fill from right to left
        
        -- Enable texture tiling for shield pattern
        local texture = f.absorbBar:GetStatusBarTexture()
        if texture then
            texture:SetHorizTile(true)
            texture:SetVertTile(true)
        end
        
        f.absorbBar:Hide()
        f.absorbBar:SetWidth(46)
        
        -- Position at right edge for both player and target
        f.absorbBar:SetPoint("RIGHT", f.healthBar, "RIGHT", 0, 0)
        f.absorbBar:SetHeight(f.healthBar:GetHeight() or 20)
        f.absorbBar:SetFrameLevel(f.healthBar:GetFrameLevel() + 2)
    end

    -- Add highlight texture (after health bar creation, before name text)
    f.highlightTexture = f:CreateTexture(nil, "OVERLAY")
    f.highlightTexture:SetAllPoints(f)
    f.highlightTexture:SetColorTexture(1, 1, 1, 0.15)  -- White with 15% opacity
    f.highlightTexture:Hide()

    ------------------------------------------------------
    -- Name text (on overlay frame so it draws above the StatusBar)
    ------------------------------------------------------
    local fontPath = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    f.nameOverlay = CreateFrame("Frame", nil, f)
    f.nameOverlay:SetAllPoints(f)
    f.nameOverlay:SetFrameLevel(f:GetFrameLevel() + 10)
    
    f.nameText = f.nameOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
    if unit == "focus" or unit == "targettarget" then
        f.nameText:SetFont(fontPath, 10, "OUTLINE")  -- Smaller font for focus and ToT
    else
        f.nameText:SetFont(fontPath, 14, "OUTLINE")  -- Regular size for others
    end
    f.nameText:SetTextColor(1, 1, 1, 1)
    f.nameText:SetShadowOffset(1, -1)
    f.nameText:SetShadowColor(0, 0, 0, 0.9)
    if unit == "player" then
        f.nameText:SetPoint("LEFT", f, "TOPLEFT", 2, 0)
        f.nameText:SetJustifyH("LEFT")
    elseif unit == "target" then
        f.nameText:SetPoint("RIGHT", f, "TOPRIGHT", -2, 0)
        f.nameText:SetJustifyH("RIGHT")
    elseif unit == "targettarget" then
        f.nameText:SetPoint("CENTER", f, "TOP", 0, 0)
        f.nameText:SetJustifyH("CENTER")
    elseif unit == "pet" then
        f.nameText:SetPoint("CENTER", f, "TOP", 0, 0)
        f.nameText:SetJustifyH("CENTER")
    elseif unit == "focus" then
        f.nameText:SetPoint("CENTER", f, "TOP", 0, 0)
        f.nameText:SetJustifyH("CENTER")
    else
        f.nameText:SetPoint("CENTER", f, "TOP", 0, 0)
        f.nameText:SetJustifyH("CENTER")
    end
    f.nameText:SetWidth(f.originalWidth - 4)

    ------------------------------------------------------
    -- HP & Power text (on overlay frame so it draws above the StatusBar)
    ------------------------------------------------------
    f.hpText = f.nameOverlay:CreateFontString(nil, "OVERLAY")
    f.hpText:SetFont(fontPath, 13, "OUTLINE")
    f.hpText:SetTextColor(1, 1, 1)
    f.powerText = f.nameOverlay:CreateFontString(nil, "OVERLAY")
    f.powerText:SetFont(fontPath, 13, "OUTLINE")
    f.powerText:SetTextColor(1, 1, 1)
    if unit == "player" then
        f.hpText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -14.5)
        f.powerText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

        -- Create power bar frame container
        f.powerBarFrame = CreateFrame("Frame", nil, f)
        f.powerBarFrame:SetSize(DEFAULT_POWER_BAR_WIDTH + 2, DEFAULT_POWER_BAR_HEIGHT + 2)
        f.powerBarFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -DEFAULT_POWER_BAR_HORIZONTAL_OFFSET, DEFAULT_POWER_BAR_VERTICAL_OFFSET)
        f.powerBarFrame:SetMovable(true)
        f.powerBarFrame:EnableMouse(true)
        f.powerBarFrame:RegisterForDrag("LeftButton")
        f.powerBarFrame:SetScript("OnDragStart", function(self)
            if not InCombatLockdown() and IsShiftKeyDown() then
                self:StartMoving()
            end
        end)
        f.powerBarFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save position relative to parent frame
            local x, y = self:GetCenter()
            local px, py = f:GetCenter()
            if not MattMinimalFramesDB.powerBarPositions then
                MattMinimalFramesDB.powerBarPositions = {}
            end
            MattMinimalFramesDB.powerBarPositions[unit] = {x = x - px, y = y - py}
        end)

        -- Add textures to the frame container
        f.powerBarBorder = f.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
        f.powerBarBorder:SetColorTexture(0, 0, 0, 0.5)
        f.powerBarBorder:SetAllPoints()

        f.powerBarBG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBarBG:SetWidth(DEFAULT_POWER_BAR_WIDTH)
        f.powerBarBG:SetPoint("CENTER", f.powerBarBorder, "CENTER", 0, 0)

        -- Set up the StatusBar power bar position and size
        f.powerBar:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBar:SetWidth(DEFAULT_POWER_BAR_WIDTH)
        f.powerBar:SetPoint("CENTER", f.powerBarBorder, "CENTER", 0, 0)
        f.powerBar:SetAlpha(0.5)  -- 50% transparency for power bar

    elseif unit == "target" then
        f.hpText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, -14.5)
        f.powerText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)

        -- Create power bar frame container
        f.powerBarFrame = CreateFrame("Frame", nil, f)
        f.powerBarFrame:SetSize(DEFAULT_POWER_BAR_WIDTH + 2, DEFAULT_POWER_BAR_HEIGHT + 2)
        f.powerBarFrame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", DEFAULT_POWER_BAR_HORIZONTAL_OFFSET, DEFAULT_POWER_BAR_VERTICAL_OFFSET)
        f.powerBarFrame:SetMovable(true)
        f.powerBarFrame:EnableMouse(true)
        f.powerBarFrame:RegisterForDrag("LeftButton")
        f.powerBarFrame:SetScript("OnDragStart", function(self)
            if not InCombatLockdown() and IsShiftKeyDown() then
                self:StartMoving()
            end
        end)
        f.powerBarFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save position relative to parent frame
            local x, y = self:GetCenter()
            local px, py = f:GetCenter()
            if not MattMinimalFramesDB.powerBarPositions then
                MattMinimalFramesDB.powerBarPositions = {}
            end
            MattMinimalFramesDB.powerBarPositions[unit] = {x = x - px, y = y - py}
        end)

        -- Add textures to the frame container
        f.powerBarBorder = f.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
        f.powerBarBorder:SetColorTexture(0, 0, 0, 0.5)
        f.powerBarBorder:SetAllPoints()

        f.powerBarBG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBarBG:SetWidth(DEFAULT_POWER_BAR_WIDTH)
        f.powerBarBG:SetPoint("CENTER", f.powerBarBorder, "CENTER", 0, 0)

        -- Set up the StatusBar power bar position and size
        f.powerBar:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBar:SetWidth(DEFAULT_POWER_BAR_WIDTH)
        f.powerBar:SetPoint("CENTER", f.powerBarBorder, "CENTER", 0, 0)
        f.powerBar:SetAlpha(0.5)  -- 50% transparency for power bar

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
    -- COMBAT TEXTURE (for player only)
    ------------------------------------------------------
    if unit == "player" then
        f.combatTexture = f.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
        f.combatTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        f.combatTexture:SetTexCoord(0.5, 1, 0, 0.49)
        f.combatTexture:SetSize(22, 22) -- Adjust size as needed
        f.combatTexture:SetPoint("CENTER", f, "CENTER", 0, 0)
        f.combatTexture:SetDrawLayer("OVERLAY", 7)
        f.combatTexture:Hide()

        f.restingTexture = f.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
        f.restingTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        f.restingTexture:SetTexCoord(0, 0.5, 0, 0.421875)
        f.restingTexture:SetSize(20, 20) -- Adjust size as needed
        f.restingTexture:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, 10)
        f.restingTexture:SetDrawLayer("OVERLAY", 7)
        if IsResting() then
            f.restingTexture:Show()
        else
            f.restingTexture:Hide()
        end
    end

    -- Add cast bar for target frame only
    if unit == "target" then
        -- Cast bar background
        f.castBarBG = f:CreateTexture(nil, "ARTWORK", nil, 1)
        f.castBarBG:SetColorTexture(0, 0, 0, 0.5)  -- 50% transparent black
        f.castBarBG:SetHeight(3)
        f.castBarBG:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
        f.castBarBG:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
        f.castBarBG:Hide()

        -- Cast bar fill
        f.castBarFG = f:CreateTexture(nil, "ARTWORK", nil, 2)
        f.castBarFG:SetHeight(3)
        f.castBarFG:SetPoint("BOTTOMLEFT", f.castBarBG, "BOTTOMLEFT", 0, 0)
        f.castBarFG:Hide()
        
        -- Cast bar update function
        f.UpdateCastBar = function(self, elapsed)
            if not self.casting then return end
            
            local duration = GetTime() - self.castStart
            if duration > self.castDuration then
                self.casting = false
                self.castBarBG:Hide()
                self.castBarFG:Hide()
                self:SetScript("OnUpdate", nil)
                return
            end
            
            local width = self.originalWidth - 2  -- Full width minus margins
            local progress = duration / self.castDuration
            self.castBarFG:SetWidth(width * progress)
        end

        -- Register cast events
        f:RegisterEvent("UNIT_SPELLCAST_START")
        f:RegisterEvent("UNIT_SPELLCAST_STOP")
        f:RegisterEvent("UNIT_SPELLCAST_FAILED")
        f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        
        -- Add cast event handling to existing OnEvent or create new if needed
        f:HookScript("OnEvent", function(self, event, ...)
            local eventUnit = ...
            if eventUnit ~= self.unit then return end
            
            if event == "UNIT_SPELLCAST_START" then
                local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(self.unit)
                if name then
                    -- Wrap arithmetic in pcall to handle secret values
                    local success, duration = pcall(function()
                        return (endTime - startTime) / 1000
                    end)
                    
                    if success and duration then
                        self.casting = true
                        self.castStart = GetTime()
                        self.castDuration = duration
                        
                        -- Set color based on interruptibility
                        if notInterruptible then
                            self.castBarFG:SetColorTexture(0.7, 0.7, 0.7, 1) -- Gray for non-interruptible
                        else
                            self.castBarFG:SetColorTexture(1, 1, 1, 1) -- White for interruptible (changed from yellow)
                        end
                        
                        self.castBarBG:Show()
                        self.castBarFG:Show()
                        self:SetScript("OnUpdate", self.UpdateCastBar)
                    else
                        -- Secret values - hide cast bar
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

    if f.powerBarFrame then
        -- Restore saved position if it exists
        if MattMinimalFramesDB and MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit] then
            local pos = MattMinimalFramesDB.powerBarPositions[unit]
            f.powerBarFrame:ClearAllPoints()
            f.powerBarFrame:SetPoint("CENTER", f, "CENTER", pos.x, pos.y)
        end
    end

    return f
end

-- Hook into the CreateSecureMinimalUnitFrame function to set initial visibility
local originalCreateSecureMinimalUnitFrame = CreateSecureMinimalUnitFrame
CreateSecureMinimalUnitFrame = function(...)
    local frame = originalCreateSecureMinimalUnitFrame(...)
    
    -- Set initial power bar visibility
    if frame.powerBarFrame then
        frame.powerBarFrame:SetShown(MattMinimalFramesDB and MattMinimalFramesDB.showPowerBars)
        frame.powerText:SetShown(MattMinimalFramesDB and MattMinimalFramesDB.showPowerBars)
    end
    
    return frame
end

-- CREATE ALL FRAMES: use RegisterUnitWatch for each frame (no state drivers)
function MMF_CreateAllMinimalFrames()
    local function CreateSecureFrame(unit, name, width, height, x, y)
        local frame = CreateSecureMinimalUnitFrame(unit, name, width, height, "CENTER", "CENTER", x, y)
        RegisterUnitWatch(frame)
        return frame
    end

    _G["MMF_PlayerFrame"]         = CreateSecureFrame("player",       "MMF_PlayerFrame",         220, 28, -150, 0)
    _G["MMF_TargetFrame"]         = CreateSecureFrame("target",       "MMF_TargetFrame",         220, 28,  150, 0)
    _G["MMF_TargetOfTargetFrame"] = CreateSecureFrame("targettarget", "MMF_TargetOfTargetFrame", 100, 28,   0, -100)
    _G["MMF_PetFrame"]            = CreateSecureFrame("pet",          "MMF_PetFrame",            100, 28, -300, -100)
    _G["MMF_FocusFrame"]          = CreateSecureFrame("focus",        "MMF_FocusFrame",          100, 28,  300, -100)

    -- Apply settings for buffs, debuffs, and resource bar
    C_Timer.After(0, function()
        -- Buffs
        if MMF_TargetFrame and MMF_TargetFrame.BuffContainer then
            if MattMinimalFramesDB.showBuffs == false then
                MMF_TargetFrame.BuffContainer:Hide()
            else
                MMF_TargetFrame.BuffContainer:Show()
            end
        end
        -- Debuffs
        if MMF_TargetFrame and MMF_TargetFrame.DebuffContainer then
            if MattMinimalFramesDB.showDebuffs == false then
                MMF_TargetFrame.DebuffContainer:Hide()
            else
                MMF_TargetFrame.DebuffContainer:Show()
            end
        end
        -- Resource bars (player and target)
        for _, frame in ipairs({MMF_PlayerFrame, MMF_TargetFrame}) do
            if frame and frame.powerBarFrame then
                if MattMinimalFramesDB.showPowerBars == false then
                    frame.powerBarFrame:Hide()
                else
                    frame.powerBarFrame:Show()
                end
            end
        end
    end)
end

-------------------------------------------------
-- UPDATE UNIT FRAMES
-------------------------------------------------

local lastUpdate = 0
local updateInterval = 0.1  -- Update every 0.1 seconds

local function UpdateUnitFrame(frame)
    if not frame or not frame.unit or not frame.nameText then return end
    local unit = frame.unit
    local unitName = ""
    local hasValidName = false
    
    -- Safely get unit name - wrap the check inside pcall to handle secret values
    local success, result = pcall(function()
        local name = UnitName(unit)
        if name and name ~= "" then
            return name
        end
        return nil
    end)
    
    if success and result then
        unitName = result
        hasValidName = true
    end

    -- Truncate target-of-target name if needed
    -- Only update name if we have a valid name - don't clear existing name on nil/empty
    -- This prevents names from disappearing during combat when UnitName temporarily returns nil
    if unit == "targettarget" then
        if hasValidName then
            local truncated = string.sub(unitName, 1, 8)
            if #unitName > 8 then truncated = truncated .. "…" end
            pcall(function() frame.nameText:SetText(truncated) end)
        end
        -- If no valid name but unit doesn't exist, clear it
        if not UnitExists(unit) then
            pcall(function() frame.nameText:SetText("") end)
        end
    else
        if hasValidName then
            pcall(function() frame.nameText:SetText(unitName) end)
        end
        -- If no valid name but unit doesn't exist, clear it
        if not UnitExists(unit) then
            pcall(function() frame.nameText:SetText("") end)
        end
        pcall(function() frame.nameText:SetWidth(frame.originalWidth - 4) end)
    end

    -- Update health bar using StatusBar (handles secret values internally)
    local maxHP = UnitHealthMax(unit)
    local hp = UnitHealth(unit)
    
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, maxHP)
        frame.healthBar:SetValue(hp)
    end
    
    -- Shield bar - we can't compare/calculate with secret values
    -- Just hide it since we can't determine if absorbs exist
    if frame.shieldBarFG then
        frame.shieldBarFG:Hide()
    end
    if frame.shieldBarFG2 then
        frame.shieldBarFG2:Hide()
    end
    
    -- HP text - display raw HP number (pass secret value directly to SetText)
    if frame.hpText and (unit == "player" or unit == "target") then
        frame.hpText:SetText(hp)
        frame.hpText:Show()
    end

    -- Update absorb bar (shows in the missing health portion)
    if frame.absorbBar and (unit == "player" or unit == "target") then
        local absorb = UnitGetTotalAbsorbs(unit) or 0
        
        -- StatusBar fills from left to right based on absorb value
        frame.absorbBar:SetMinMaxValues(0, maxHP)
        frame.absorbBar:SetValue(absorb)
        frame.absorbBar:SetAlpha(1.0)
        frame.absorbBar:Show()
    else
        if frame.absorbBar then
            frame.absorbBar:Hide()
        end
    end

    -- Hide HP/Power if unit is targettarget or pet
    if unit == "targettarget" or unit == "pet" then
        if frame.hpText then frame.hpText:Hide() end
        if frame.powerText then frame.powerText:Hide() end
    else
        if frame.powerText then frame.powerText:Hide() end
    end

    -- Update class/unit color on health bar
    local r, g, b = MMF_GetUnitColor(unit)
    if frame.healthBar then
        frame.healthBar:SetStatusBarColor(r, g, b, 1)
    end

    -- Update power bar if it exists
    if frame.powerBar and (unit == "player" or unit == "target") then
        local powerType = UnitPowerType(unit)
        
        -- Check for shaman specs and override powerType to mana if necessary
        local useManaPowerType = false
        if unit == "player" and UnitClass(unit) == "Shaman" then
            local spec = GetSpecialization()
            if spec == 1 or spec == 2 then
                useManaPowerType = true
                powerType = 0
            end
        end
        
        local maxPower = useManaPowerType and UnitPowerMax(unit, 0) or UnitPowerMax(unit)
        local power = useManaPowerType and UnitPower(unit, 0) or UnitPower(unit)

        -- Only show power bar if unit has power (check if maxPower > 0, wrapped in pcall)
        local hasPower = false
        pcall(function()
            if maxPower and maxPower > 0 then
                hasPower = true
            end
        end)
        
        if hasPower then
            -- Just use the StatusBar to display - don't do arithmetic
            frame.powerBar:SetMinMaxValues(0, maxPower)
            frame.powerBar:SetValue(power)
            
            -- Get power color with custom mana color
            local powerColor = PowerBarColor[powerType]
            local r, g, b = 1, 1, 1
            if powerType == 0 then  -- 0 is MANA
                r, g, b = 0.2, 0.7, 1  -- Light blue color for mana
            elseif powerColor then
                r, g, b = powerColor.r, powerColor.g, powerColor.b
            end
            
            frame.powerBar:SetStatusBarColor(r, g, b, 1)
            
            if frame.powerBarBorder then frame.powerBarBorder:Show() end
            frame.powerBarBG:Show()
            frame.powerBar:Show()
        else
            -- No power - hide the bar
            if frame.powerBarBorder then frame.powerBarBorder:Hide() end
            frame.powerBarBG:Hide()
            frame.powerBar:Hide()
        end
    end
end

function MMF_UpdateAll(elapsed)
    lastUpdate = lastUpdate + (elapsed or 0)
    if lastUpdate < updateInterval then return end
    lastUpdate = 0

    -- Only update frames that exist and are shown
    for _, frame in ipairs({MMF_PlayerFrame, MMF_TargetFrame, MMF_TargetOfTargetFrame, MMF_PetFrame, MMF_FocusFrame}) do
        if frame and frame:IsShown() then
            UpdateUnitFrame(frame)
        end
    end
end

-------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------

local coreEventFrame = CreateFrame("Frame")
coreEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
coreEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
coreEventFrame:RegisterEvent("UNIT_HEALTH")
coreEventFrame:RegisterEvent("UNIT_POWER_UPDATE")
coreEventFrame:RegisterEvent("PLAYER_ALIVE")
coreEventFrame:RegisterEvent("PLAYER_DEAD")
coreEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coreEventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
-- Register events for name updates (fixes names disappearing in combat)
coreEventFrame:RegisterEvent("UNIT_NAME_UPDATE")
coreEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
coreEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
coreEventFrame:RegisterEvent("UNIT_PET")
coreEventFrame:RegisterEvent("UNIT_TARGET")

-- Pending flag for lock changes
local pendingLock = false

-- In your core event handler, after combat ends, apply any pending changes.
coreEventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingLock then
            MMF_LockFrames()
        end
        if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
            MMF_PlayerFrame.combatTexture:Hide()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
            MMF_PlayerFrame.combatTexture:Show()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_UPDATE_RESTING" then
        if MMF_PlayerFrame and MMF_PlayerFrame.restingTexture then
            if IsResting() then
                MMF_PlayerFrame.restingTexture:Show()
            else
                MMF_PlayerFrame.restingTexture:Hide()
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Immediately update target and target-of-target frames when target changes
        UpdateUnitFrame(MMF_TargetFrame)
        UpdateUnitFrame(MMF_TargetOfTargetFrame)
    elseif event == "PLAYER_FOCUS_CHANGED" then
        -- Immediately update focus frame when focus changes
        UpdateUnitFrame(MMF_FocusFrame)
    elseif event == "UNIT_PET" then
        -- Update pet frame when pet changes
        UpdateUnitFrame(MMF_PetFrame)
    elseif event == "UNIT_TARGET" then
        -- Update target-of-target when target's target changes
        if unit == "target" then
            UpdateUnitFrame(MMF_TargetOfTargetFrame)
        end
    elseif event == "UNIT_NAME_UPDATE" then
        -- Update the appropriate frame when a unit's name changes
        if unit == "player" then
            UpdateUnitFrame(MMF_PlayerFrame)
        elseif unit == "target" then
            UpdateUnitFrame(MMF_TargetFrame)
        elseif unit == "targettarget" then
            UpdateUnitFrame(MMF_TargetOfTargetFrame)
        elseif unit == "pet" then
            UpdateUnitFrame(MMF_PetFrame)
        elseif unit == "focus" then
            UpdateUnitFrame(MMF_FocusFrame)
        end
    elseif event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" then
        if unit == "player" then
            UpdateUnitFrame(MMF_PlayerFrame)
        elseif unit == "target" then
            UpdateUnitFrame(MMF_TargetFrame)
        elseif unit == "targettarget" then
            UpdateUnitFrame(MMF_TargetOfTargetFrame)
        elseif unit == "pet" then
            UpdateUnitFrame(MMF_PetFrame)
        elseif unit == "focus" then
            UpdateUnitFrame(MMF_FocusFrame)
        end
    end
end)

-- Debounced OnUpdate script to reduce CPU usage
coreEventFrame:SetScript("OnUpdate", function(self, elapsed)
    MMF_UpdateAll(elapsed)
end)

-------------------------------------------------
-- LOCK / UNLOCK FRAMES
-------------------------------------------------

-- Initialize LibCustomGlow
local LibCustomGlow = LibStub("LibCustomGlow-1.0")

function MMF_LockFrames()
    if InCombatLockdown() then
        print("Cannot lock frames during combat. Your lock request has been queued.")
        pendingLock = true
        return
    end
    pendingLock = false
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.locked = true
    local frames = { MMF_PlayerFrame, MMF_TargetFrame, MMF_TargetOfTargetFrame, MMF_PetFrame, MMF_FocusFrame }
    for _, frm in ipairs(frames) do
        if frm then
            frm:SetMovable(false)
            frm:SetClampedToScreen(true)
            frm:EnableMouse(true)
            frm:RegisterForClicks("AnyUp")
            if frm.titleText then
                frm.titleText:Hide()
            end
            MMF_ResetSecureAttributes(frm)
            if LibCustomGlow then
                LibCustomGlow.PixelGlow_Stop(frm)
            end
        end
    end
end

function MMF_UnlockFrames()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.locked = false
    local frames = { MMF_PlayerFrame, MMF_TargetFrame, MMF_TargetOfTargetFrame, MMF_PetFrame, MMF_FocusFrame }
    for _, frm in ipairs(frames) do
        if frm then
            frm:SetMovable(true)
            frm:SetClampedToScreen(false)
            frm:EnableMouse(true)
            frm:RegisterForDrag("LeftButton")
            frm:RegisterForClicks("AnyUp")
            if frm.titleText then
                frm.titleText:Show()
            end
            MMF_ResetSecureAttributes(frm)
            if LibCustomGlow then
                LibCustomGlow.PixelGlow_Stop(frm)
            end
        end
    end
end

-------------------------------------------------
-- TARGET AURA DISPLAY (Buffs & Debuffs) – Default Tooltip, Timer Updates, No Debug Prints
-------------------------------------------------

-- Get aura settings from DB or use defaults
local function GetAuraIconSize()
    return (MattMinimalFramesDB and MattMinimalFramesDB.auraIconSize) or 18
end

local function GetAuraTextScale()
    return (MattMinimalFramesDB and MattMinimalFramesDB.auraTextScale) or 1.0
end

local function GetTimerTextScale()
    return (MattMinimalFramesDB and MattMinimalFramesDB.timerTextScale) or 1.0
end

local AURA_ICON_SPACING = 2
local MAX_AURA_ICONS    = 12
local ROW_ICONS         = 4

-- Cache the aura APIs for secret value handling
local GetAuraSlots = C_UnitAuras.GetAuraSlots
local GetAuraDataBySlot = C_UnitAuras.GetAuraDataBySlot
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
local issecretvalue = issecretvalue

-- Function to update aura text scale (stack count - called from popup slider)
function MMF_UpdateAuraTextScale(scale)
    if not MMF_TargetFrame then return end
    
    local fontSize = math.max(6, math.floor(10 * scale))
    
    -- Directly update ALL count texts right now
    if MMF_TargetFrame.BuffContainer and MMF_TargetFrame.BuffContainer.auras then
        for _, aura in ipairs(MMF_TargetFrame.BuffContainer.auras) do
            if aura.count then
                aura.count:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            end
        end
    end
    
    if MMF_TargetFrame.DebuffContainer and MMF_TargetFrame.DebuffContainer.auras then
        for _, aura in ipairs(MMF_TargetFrame.DebuffContainer.auras) do
            if aura.count then
                aura.count:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            end
        end
    end
end

-- Function to update timer text scale (duration - called from popup slider)
function MMF_UpdateTimerTextScale(scale)
    if not MMF_TargetFrame then return end
    
    local fontSize = math.max(8, math.floor(12 * scale))
    
    -- Directly update ALL timer texts right now
    if MMF_TargetFrame.BuffContainer and MMF_TargetFrame.BuffContainer.auras then
        for _, aura in ipairs(MMF_TargetFrame.BuffContainer.auras) do
            if aura.timerText then
                aura.timerText:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            end
        end
    end
    
    if MMF_TargetFrame.DebuffContainer and MMF_TargetFrame.DebuffContainer.auras then
        for _, aura in ipairs(MMF_TargetFrame.DebuffContainer.auras) do
            if aura.timerText then
                aura.timerText:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            end
        end
    end
end

-- Function to update aura icon size (called from popup slider)
function MMF_UpdateAuraIconSize(size)
    if not MMF_TargetFrame then return end
    
    size = math.floor(size)
    
    -- Update buff icons
    if MMF_TargetFrame.BuffContainer and MMF_TargetFrame.BuffContainer.auras then
        -- Resize container
        MMF_TargetFrame.BuffContainer:SetSize(
            (size + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
            (size + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
        )
        
        for i, aura in ipairs(MMF_TargetFrame.BuffContainer.auras) do
            aura:SetSize(size, size)
            local row = math.floor((i - 1) / ROW_ICONS)
            local col = (i - 1) % ROW_ICONS
            aura:ClearAllPoints()
            aura:SetPoint("TOPRIGHT", MMF_TargetFrame.BuffContainer, "TOPRIGHT",
                -col * (size + AURA_ICON_SPACING),
                -row * (size + AURA_ICON_SPACING))
        end
    end
    
    -- Update debuff icons
    if MMF_TargetFrame.DebuffContainer and MMF_TargetFrame.DebuffContainer.auras then
        -- Resize container
        MMF_TargetFrame.DebuffContainer:SetSize(
            (size + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
            (size + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
        )
        
        for i, aura in ipairs(MMF_TargetFrame.DebuffContainer.auras) do
            aura:SetSize(size, size)
            local row = math.floor((i - 1) / ROW_ICONS)
            local col = (i - 1) % ROW_ICONS
            aura:ClearAllPoints()
            aura:SetPoint("TOPLEFT", MMF_TargetFrame.DebuffContainer, "TOPLEFT",
                col * (size + AURA_ICON_SPACING),
                row * (size + AURA_ICON_SPACING))
        end
    end
end

-- Function to update buff position (called from popup sliders)
function MMF_UpdateBuffPosition(x, y)
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end
    MMF_TargetFrame.BuffContainer:ClearAllPoints()
    MMF_TargetFrame.BuffContainer:SetPoint("BOTTOMRIGHT", MMF_TargetFrame, "BOTTOMRIGHT", x, y)
end

-- Function to update debuff position (called from popup sliders)
function MMF_UpdateDebuffPosition(x, y)
    if not MMF_TargetFrame or not MMF_TargetFrame.DebuffContainer then return end
    MMF_TargetFrame.DebuffContainer:ClearAllPoints()
    MMF_TargetFrame.DebuffContainer:SetPoint("TOPLEFT", MMF_TargetFrame, "TOPLEFT", x, y)
end

-- Helper functions to get buff/debuff positions from DB
local function GetBuffXOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.buffXOffset) or -3
end

local function GetBuffYOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.buffYOffset) or -60
end

local function GetDebuffXOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.debuffXOffset) or 3
end

local function GetDebuffYOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.debuffYOffset) or 27
end

local function MMF_SetupTargetAuras()
    if not MMF_TargetFrame then return end
    
    local AURA_ICON_SIZE = GetAuraIconSize()
    -- Buff container (bottom-right)
    MMF_TargetFrame.BuffContainer = CreateFrame("Frame", nil, MMF_TargetFrame)
    MMF_TargetFrame.BuffContainer:SetSize(
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
    )
    MMF_TargetFrame.BuffContainer:SetPoint("BOTTOMRIGHT", MMF_TargetFrame, "BOTTOMRIGHT", GetBuffXOffset(), GetBuffYOffset())
    MMF_TargetFrame.BuffContainer.auras = {}

    for i = 1, MAX_AURA_ICONS do
        local aura = CreateFrame("Frame", nil, MMF_TargetFrame.BuffContainer)
        aura:SetSize(AURA_ICON_SIZE, AURA_ICON_SIZE)
        local row = math.floor((i - 1) / ROW_ICONS)
        local col = (i - 1) % ROW_ICONS
        aura:SetPoint("TOPRIGHT", MMF_TargetFrame.BuffContainer, "TOPRIGHT",
            -col * (AURA_ICON_SIZE + AURA_ICON_SPACING),
            -row * (AURA_ICON_SIZE + AURA_ICON_SPACING))
        aura.icon = aura:CreateTexture(nil, "ARTWORK")
        aura.icon:SetAllPoints(aura)
        aura.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
        aura.cooldown:SetAllPoints(aura)
        aura.cooldown:SetDrawEdge(false)
        aura.cooldown:SetHideCountdownNumbers(false)  -- Show built-in countdown
        -- Get the cooldown's built-in text region (like ElvUI does)
        aura.timerText = aura.cooldown:GetRegions()
        if aura.timerText and aura.timerText.SetFont then
            aura.timerText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            aura.timerText:ClearAllPoints()
            aura.timerText:SetPoint("CENTER", aura.cooldown, "CENTER", 0, 0)
        end
        aura:SetScript("OnEnter", function(self)
            if self.auraData and self.auraData.auraInstanceID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                -- Use SetUnitAuraByAuraInstanceID for reliable tooltip display (handles secret values)
                if GameTooltip.SetUnitAuraByAuraInstanceID then
                    GameTooltip:SetUnitAuraByAuraInstanceID("target", self.auraData.auraInstanceID, self.auraFilter)
                elseif self.auraIndex then
                    GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                end
                GameTooltip:Show()
                -- No OnUpdate needed - tooltip updates automatically with auraInstanceID
            end
        end)
        aura:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        aura:Hide()
        MMF_TargetFrame.BuffContainer.auras[i] = aura
    end

    -- Debuff container (TOPLEFT, left-to-right, up)
    MMF_TargetFrame.DebuffContainer = CreateFrame("Frame", nil, MMF_TargetFrame)
    MMF_TargetFrame.DebuffContainer:SetSize(
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
    )
    MMF_TargetFrame.DebuffContainer:SetPoint("TOPLEFT", MMF_TargetFrame, "TOPLEFT", GetDebuffXOffset(), GetDebuffYOffset())
    MMF_TargetFrame.DebuffContainer.auras = {}

    for i = 1, MAX_AURA_ICONS do
        local aura = CreateFrame("Frame", nil, MMF_TargetFrame.DebuffContainer)
        aura:SetSize(AURA_ICON_SIZE, AURA_ICON_SIZE)
        local row = math.floor((i - 1) / ROW_ICONS)
        local col = (i - 1) % ROW_ICONS
        aura:SetPoint("TOPLEFT", MMF_TargetFrame.DebuffContainer, "TOPLEFT",
            col * (AURA_ICON_SIZE + AURA_ICON_SPACING),
            row * (AURA_ICON_SIZE + AURA_ICON_SPACING))
        aura.icon = aura:CreateTexture(nil, "ARTWORK")
        aura.icon:SetAllPoints(aura)
        aura.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
        aura.cooldown:SetAllPoints(aura)
        aura.cooldown:SetDrawEdge(false)
        aura.cooldown:SetHideCountdownNumbers(false)  -- Show built-in countdown
        -- Get the cooldown's built-in text region (like ElvUI does)
        aura.timerText = aura.cooldown:GetRegions()
        if aura.timerText and aura.timerText.SetFont then
            aura.timerText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            aura.timerText:ClearAllPoints()
            aura.timerText:SetPoint("CENTER", aura.cooldown, "CENTER", 0, 0)
        end
        aura.border = aura:CreateTexture(nil, "OVERLAY")
        aura.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        aura.border:SetAllPoints(aura)
        aura:SetScript("OnEnter", function(self)
            if self.auraData and self.auraData.auraInstanceID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                -- Use SetUnitAuraByAuraInstanceID for reliable tooltip display (handles secret values)
                if GameTooltip.SetUnitAuraByAuraInstanceID then
                    GameTooltip:SetUnitAuraByAuraInstanceID("target", self.auraData.auraInstanceID, self.auraFilter)
                elseif self.auraIndex then
                    GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                end
                GameTooltip:Show()
                -- No OnUpdate needed - tooltip updates automatically with auraInstanceID
            end
        end)
        aura:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        aura:Hide()
        MMF_TargetFrame.DebuffContainer.auras[i] = aura
    end
end

-- Helper function to check if a value is a secret value
local function IsSecretValue(value)
    if issecretvalue and issecretvalue(value) then
        return true
    end
    return false
end

local function NotSecretValue(value)
    if not issecretvalue or not issecretvalue(value) then
        return true
    end
    return false
end

-- Collect auras using GetAuraSlots (more reliable with secret values)
local function CollectAuras(unit, filter)
    local auras = {}
    if not GetAuraSlots then return auras end
    
    local function ProcessAuraSlot(token, ...)
        for i = 1, select('#', ...) do
            local slot = select(i, ...)
            local aura = GetAuraDataBySlot(unit, slot)
            if aura then
                table.insert(auras, aura)
            end
        end
        return token
    end
    
    local token = GetAuraSlots(unit, filter)
    while token do
        token = ProcessAuraSlot(GetAuraSlots(unit, filter, nil, token))
    end
    
    -- Also get initial batch without token
    ProcessAuraSlot(GetAuraSlots(unit, filter))
    
    return auras
end

function MMF_UpdateTargetAuras()
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end
    if not C_UnitAuras then return end

    local unit = "target"
    local buffs, debuffs = {}, {}
    
    -- Use GetAuraSlots for more reliable aura fetching (handles secret values better)
    if GetAuraSlots and GetAuraDataBySlot then
        -- Collect buffs using slots
        local function ProcessSlots(filter, targetTable)
            local token
            repeat
                local slots = {GetAuraSlots(unit, filter, 40, token)}
                token = table.remove(slots, 1) -- First return is the continuation token
                for _, slot in ipairs(slots) do
                    local aura = GetAuraDataBySlot(unit, slot)
                    if aura then
                        table.insert(targetTable, aura)
                    end
                end
            until not token
        end
        
        ProcessSlots("HELPFUL", buffs)
        ProcessSlots("HARMFUL", debuffs)
    else
        -- Fallback to GetAuraDataByIndex if slot API unavailable
        local BUFF_MAX_DISPLAY, DEBUFF_MAX_DISPLAY = 32, 16
        
        for i = 1, BUFF_MAX_DISPLAY do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not auraData then break end
            table.insert(buffs, auraData)
        end
        
        for i = 1, DEBUFF_MAX_DISPLAY do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            if not auraData then break end
            table.insert(debuffs, auraData)
        end
    end

    -- Note: Sorting disabled due to secret value restrictions
    -- Auras will display in their default order

    -- Update Buff icons
    local buffContainer = MMF_TargetFrame.BuffContainer
    if MattMinimalFramesDB.showBuffs == false then
        buffContainer:Hide()
    else
        buffContainer:Show()
        for _, aura in ipairs(buffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        local idx = 1
        for i = 1, math.min(#buffs, MAX_AURA_ICONS) do
            local auraData = buffs[i]
            local auraFrame = buffContainer.auras[idx]
            if auraFrame then
                auraFrame.icon:SetTexture(auraData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                auraFrame.auraData = auraData
                auraFrame.auraIndex = auraData._index
                auraFrame.auraFilter = "HELPFUL"
                
                -- Show stack count - handle secret values properly like ElvUI
                local auraInstanceID = auraData.auraInstanceID
                if auraFrame.count then auraFrame.count:Hide() end
                
                if auraInstanceID and GetAuraApplicationDisplayCount then
                    -- GetAuraApplicationDisplayCount returns a value that can be passed directly to SetText
                    -- It handles secret values internally - we cannot compare its result
                    if not auraFrame.count then
                        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
                        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
                    end
                    -- Always update font size (allows live scaling)
                    local scale = GetAuraTextScale()
                    auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(10 * scale)), "OUTLINE")
                    -- Pass directly to SetText - the API handles displaying appropriately
                    -- minCount=2 means it won't show for stacks of 1
                    auraFrame.count:SetText(GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 999))
                    auraFrame.count:Show()
                end
                
                -- Show cooldown using GetAuraDuration and SetCooldownFromDurationObject
                -- This properly handles secret values like ElvUI does
                -- Blizzard's cooldown frame handles the timer text automatically
                if auraFrame.cooldown then
                    if auraInstanceID and GetAuraDuration then
                        local auraDuration = GetAuraDuration(unit, auraInstanceID)
                        if auraDuration and auraFrame.cooldown.SetCooldownFromDurationObject then
                            auraFrame.cooldown:SetCooldownFromDurationObject(auraDuration)
                        else
                            auraFrame.cooldown:Clear()
                        end
                    else
                        auraFrame.cooldown:Clear()
                    end
                    
                    -- Update the cooldown's built-in timer text font (like ElvUI)
                    if auraFrame.timerText and auraFrame.timerText.SetFont then
                        local timerScale = GetTimerTextScale()
                        local timerFontSize = math.max(8, math.floor(12 * timerScale))
                        auraFrame.timerText:SetFont(STANDARD_TEXT_FONT, timerFontSize, "OUTLINE")
                    end
                end
                
                auraFrame:Show()
                idx = idx + 1
            end
        end
    end

    -- Update Debuff icons
    local debuffContainer = MMF_TargetFrame.DebuffContainer
    if MattMinimalFramesDB.showDebuffs == false then
        debuffContainer:Hide()
    else
        debuffContainer:Show()
        for _, aura in ipairs(debuffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        local idx = 1
        for i = 1, math.min(#debuffs, MAX_AURA_ICONS) do
            local auraData = debuffs[i]
            local auraFrame = debuffContainer.auras[idx]
            if auraFrame then
                auraFrame.icon:SetTexture(auraData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                auraFrame.auraData = auraData
                auraFrame.auraIndex = auraData._index
                auraFrame.auraFilter = "HARMFUL"
                
                -- Show stack count - handle secret values properly like ElvUI
                local auraInstanceID = auraData.auraInstanceID
                if auraFrame.count then auraFrame.count:Hide() end
                
                if auraInstanceID and GetAuraApplicationDisplayCount then
                    -- GetAuraApplicationDisplayCount returns a value that can be passed directly to SetText
                    -- It handles secret values internally - we cannot compare its result
                    if not auraFrame.count then
                        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
                        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
                    end
                    -- Always update font size (allows live scaling)
                    local scale = GetAuraTextScale()
                    auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(10 * scale)), "OUTLINE")
                    -- Pass directly to SetText - the API handles displaying appropriately
                    -- minCount=2 means it won't show for stacks of 1
                    auraFrame.count:SetText(GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 999))
                    auraFrame.count:Show()
                end
                
                -- Show cooldown using GetAuraDuration and SetCooldownFromDurationObject
                -- This properly handles secret values like ElvUI does
                -- Blizzard's cooldown frame handles the timer text automatically
                if auraFrame.cooldown then
                    if auraInstanceID and GetAuraDuration then
                        local auraDuration = GetAuraDuration(unit, auraInstanceID)
                        if auraDuration and auraFrame.cooldown.SetCooldownFromDurationObject then
                            auraFrame.cooldown:SetCooldownFromDurationObject(auraDuration)
                        else
                            auraFrame.cooldown:Clear()
                        end
                    else
                        auraFrame.cooldown:Clear()
                    end
                    
                    -- Update the cooldown's built-in timer text font (like ElvUI)
                    if auraFrame.timerText and auraFrame.timerText.SetFont then
                        local timerScale = GetTimerTextScale()
                        local timerFontSize = math.max(8, math.floor(12 * timerScale))
                        auraFrame.timerText:SetFont(STANDARD_TEXT_FONT, timerFontSize, "OUTLINE")
                    end
                end
                
                -- Debuff border color by dispel type (handle secret values)
                if auraFrame.border then
                    local dispelName = auraData.dispelName or auraData.debuffType
                    if NotSecretValue(dispelName) then
                        local color = DebuffTypeColor and DebuffTypeColor[dispelName or "none"] or {r=1,g=1,b=1}
                        auraFrame.border:SetVertexColor(color.r, color.g, color.b)
                    else
                        auraFrame.border:SetVertexColor(1, 1, 1) -- Default white for secret values
                    end
                end
                auraFrame:Show()
                idx = idx + 1
            end
        end
    end
end

-------------------------------------------------
-- INIT: CREATE FRAMES, AURAS, EVENTS
-------------------------------------------------

if MMF_TargetFrame then
    MMF_SetupTargetAuras()
end

local auraEventFrame = CreateFrame("Frame")
auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
auraEventFrame:RegisterEvent("UNIT_AURA")
auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
auraEventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        MMF_SetupTargetAuras()
        MMF_UpdateTargetAuras()
    elseif event == "UNIT_AURA" and unit == "target" then
        MMF_UpdateTargetAuras()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if MMF_TargetFrame and MMF_TargetFrame.DebuffContainer then
            for _, aura in ipairs(MMF_TargetFrame.DebuffContainer.auras) do
                aura:Hide()
            end
        end
        MMF_UpdateTargetAuras()
    end
end)

function MMF_SetPowerBarSize(width, height)
    if not width or not height then return end
    
    local frames = { MMF_PlayerFrame, MMF_TargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.powerBarBG then
            frame.powerBarBG:SetWidth(width)
            frame.powerBarBG:SetHeight(height)
            frame.powerBarFG:SetHeight(height)
        end
    end
    
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.powerBarWidth = width
    MattMinimalFramesDB.powerBarHeight = height
end

function MMF_SetPowerBarOffset(verticalOffset, horizontalOffset)
    if not verticalOffset then return end
    horizontalOffset = horizontalOffset or DEFAULT_POWER_BAR_HORIZONTAL_OFFSET
    
    local frames = { MMF_PlayerFrame, MMF_TargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.powerBarBorder then
            frame.powerBarBorder:ClearAllPoints()
            if frame.unit == "player" then
                frame.powerBarBorder:SetPoint("BOTTOM", frame, "BOTTOM", 0, verticalOffset)
                frame.powerBarBorder:SetPoint("RIGHT", frame, "RIGHT", -horizontalOffset, 0)
            else
                frame.powerBarBorder:SetPoint("BOTTOM", frame, "BOTTOM", 0, verticalOffset)
                frame.powerBarBorder:SetPoint("LEFT", frame, "LEFT", horizontalOffset, 0)
            end
        end
    end
    
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.powerBarVerticalOffset = verticalOffset
    MattMinimalFramesDB.powerBarHorizontalOffset = horizontalOffset
end

function MMF_UpdatePowerBarVisibility()
    local frames = { MMF_PlayerFrame, MMF_TargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.powerBarFrame then
            if MattMinimalFramesDB.showPowerBars then
                frame.powerBarFrame:Show()
                frame.powerText:Show()
            else
                frame.powerBarFrame:Hide()
                frame.powerText:Hide()
            end
        end
    end
end


