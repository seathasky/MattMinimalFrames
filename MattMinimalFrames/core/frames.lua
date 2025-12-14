--========================================================
-- MattMinimalFrames_Frames.lua
--========================================================


-------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------

function MMF_FormatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

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
local DEFAULT_POWER_BAR_HORIZONTAL_OFFSET = 4  -- Distance from edge of frame

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
    -- Minimal visuals: Health BG & FG
    ------------------------------------------------------
    -- "Health bar" background (using texture instead of StatusBar)
    f.healthBarBG = f:CreateTexture(nil, "BACKGROUND")
    f.healthBarBG:SetAllPoints(f)
    f.healthBarBG:SetColorTexture(0, 0, 0, 0.5)  -- (0,0,0,0) for fully invisible

    -- "Health bar" foreground (using texture instead of StatusBar)
    f.healthBarFG = f:CreateTexture(nil, "ARTWORK")
    f.healthBarFG:ClearAllPoints()
    f.healthBarFG:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.healthBarFG:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    f.healthBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
    f.healthBarFG:SetTexCoord(0, 1, 0, 1)

    -- Power bar (using texture instead of StatusBar)
    if unit == "player" or unit == "target" then
        f.powerBarFrame = CreateFrame("Frame", nil, f)
        f.powerBarFrame:SetFrameLevel(f:GetFrameLevel() + 1)
        
        f.powerBarBG = f.powerBarFrame:CreateTexture(nil, "BACKGROUND")
        f.powerBarBG:SetColorTexture(0, 0, 0, 0.25)
        
        f.powerBarFG = f.powerBarFrame:CreateTexture(nil, "ARTWORK")
        f.powerBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
    end

    if unit == "player" or unit == "target" then
        -- Create the shield texture behind the health bar
        f.shieldBarFG = f:CreateTexture(nil, "BACKGROUND")
        f.shieldBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\shield.tga")
        f.shieldBarFG:SetHorizTile(true)
        f.shieldBarFG:SetVertTile(true)
        f.shieldBarFG:SetPoint("TOPLEFT", f.healthBarFG, "TOPRIGHT", 0, 0)
        f.shieldBarFG:SetPoint("BOTTOMLEFT", f.healthBarFG, "BOTTOMRIGHT", 0, 0)
        f.shieldBarFG:SetTexCoord(0, 1, 0, 1)
        f.shieldBarFG:SetDrawLayer("BACKGROUND", 0)
        f.shieldBarFG:SetAlpha(0.5)  -- Set 50% transparency
        f.shieldBarFG:Hide()

        -- Create the overlay shield texture at the end of the frame
        f.shieldBarFG2 = f:CreateTexture(nil, "OVERLAY")
        f.shieldBarFG2:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\white.tga")
        f.shieldBarFG2:SetWidth(2)
        f.shieldBarFG2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -1)
        f.shieldBarFG2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 1)
        f.shieldBarFG2:SetTexCoord(0, 1, 0, 1)
        f.shieldBarFG2:SetDrawLayer("OVERLAY", 7)
        f.shieldBarFG2:Hide()

        -- Adjust the height dynamically based on the frame's height
        f:SetScript("OnSizeChanged", function(self)
            f.shieldBarFG2:SetHeight(self:GetHeight() - 2)
        end)
    end

    -- Add highlight texture (after health bar creation, before name text)
    f.highlightTexture = f:CreateTexture(nil, "OVERLAY")
    f.highlightTexture:SetAllPoints(f)
    f.highlightTexture:SetColorTexture(1, 1, 1, 0.15)  -- White with 15% opacity
    f.highlightTexture:Hide()

    ------------------------------------------------------
    -- Name text
    ------------------------------------------------------
    local fontPath = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    f.nameText = f:CreateFontString(nil, "OVERLAY")
    if unit == "focus" or unit == "targettarget" then
        f.nameText:SetFont(fontPath, 10, "OUTLINE")  -- Smaller font for focus and ToT
    else
        f.nameText:SetFont(fontPath, 14, "OUTLINE")  -- Regular size for others
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
    -- HP & Power text
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

        -- Create power bar frame container
        f.powerBarFrame = CreateFrame("Frame", nil, f)
        f.powerBarFrame:SetSize(DEFAULT_POWER_BAR_WIDTH + 2, DEFAULT_POWER_BAR_HEIGHT + 2)
        f.powerBarFrame:SetPoint("BOTTOM", f, "BOTTOM", 0, DEFAULT_POWER_BAR_VERTICAL_OFFSET)
        f.powerBarFrame:SetPoint("RIGHT", f, "RIGHT", -DEFAULT_POWER_BAR_HORIZONTAL_OFFSET, 0)
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

        f.powerBarBG = f.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 1)
        f.powerBarBG:SetColorTexture(0, 0, 0, 0.25)  -- 75% transparency for background
        f.powerBarBG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBarBG:SetWidth(DEFAULT_POWER_BAR_WIDTH)
        f.powerBarBG:SetPoint("CENTER", f.powerBarBorder, "CENTER", 0, 0)

        f.powerBarFG = f.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 2)
        f.powerBarFG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
        f.powerBarFG:SetAlpha(0.5)  -- 50% transparency for power bar
        f.powerBarFG:SetPoint("BOTTOMLEFT", f.powerBarBG, "BOTTOMLEFT", 0, 0)

    elseif unit == "target" then
        f.hpText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, -14.5)
        f.powerText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)

        -- Create power bar frame container
        f.powerBarFrame = CreateFrame("Frame", nil, f)
        f.powerBarFrame:SetSize(DEFAULT_POWER_BAR_WIDTH + 2, DEFAULT_POWER_BAR_HEIGHT + 2)
        f.powerBarFrame:SetPoint("BOTTOM", f, "BOTTOM", 0, DEFAULT_POWER_BAR_VERTICAL_OFFSET)
        f.powerBarFrame:SetPoint("LEFT", f, "LEFT", DEFAULT_POWER_BAR_HORIZONTAL_OFFSET, 0)
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

        f.powerBarBG = f.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 1)
        f.powerBarBG:SetColorTexture(0, 0, 0, 0.25)  -- 75% transparency for background
        f.powerBarBG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBarBG:SetWidth(DEFAULT_POWER_BAR_WIDTH)
        f.powerBarBG:SetPoint("CENTER", f.powerBarBorder, "CENTER", 0, 0)

        f.powerBarFG = f.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 2)
        f.powerBarFG:SetHeight(DEFAULT_POWER_BAR_HEIGHT)
        f.powerBarFG:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
        f.powerBarFG:SetAlpha(0.5)  -- 50% transparency for power bar
        f.powerBarFG:SetPoint("BOTTOMLEFT", f.powerBarBG, "BOTTOMLEFT", 0, 0)

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
        f.combatTexture = f:CreateTexture(nil, "OVERLAY")
        f.combatTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        f.combatTexture:SetTexCoord(0.5, 1, 0, 0.49)
        f.combatTexture:SetSize(22, 22) -- Adjust size as needed
        f.combatTexture:SetPoint("CENTER", f, "CENTER", 0, 0)
        f.combatTexture:Hide()

        f.restingTexture = f:CreateTexture(nil, "OVERLAY")
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
                    self.casting = true
                    self.castStart = GetTime()
                    self.castDuration = (endTime - startTime) / 1000
                    
                    -- Set color based on interruptibility
                    if notInterruptible then
                        self.castBarFG:SetColorTexture(0.7, 0.7, 0.7, 1) -- Gray for non-interruptible
                    else
                        self.castBarFG:SetColorTexture(1, 1, 1, 1) -- White for interruptible (changed from yellow)
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

    if f.powerBarFrame then
        -- Restore saved position if it exists
        if MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit] then
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
    local unitName = UnitName(unit) or ""

    -- Truncate target-of-target name if needed
    if unit == "targettarget" then
        local truncated = string.sub(unitName, 1, 8)
        if #unitName > 8 then truncated = truncated .. "…" end
        frame.nameText:SetText(truncated)
    else
        frame.nameText:SetText(unitName)
        frame.nameText:SetWidth(frame.originalWidth - 4)
    end

    local hp = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    local healthPercent = (maxHP > 0) and math.floor((hp / maxHP) * 100) or 0

    if frame.hpText then
        frame.hpText:SetText(MMF_FormatNumber(hp) .. " | " .. healthPercent .. "%")
    end

    -- Hide HP/Power if unit is targettarget or pet
    if unit == "targettarget" or unit == "pet" then
        frame.hpText:Hide()
        frame.powerText:Hide()
    else
        frame.hpText:Show()
        frame.powerText:Hide()  -- Only showing HP% by default
    end

    -- Adjust the health bar foreground
    local healthPercent = (maxHP > 0) and (hp / maxHP) or 0
    local fullWidth = frame.originalWidth - 2
    if hp == 0 then
        frame.healthBarFG:SetWidth(1)
    else
        frame.healthBarFG:Show()
        local newWidth = math.max(1, fullWidth * healthPercent)
        frame.healthBarFG:SetWidth(newWidth)
    end

    -- Update class/unit color
    local r, g, b = MMF_GetUnitColor(unit)
    frame.healthBarFG:SetVertexColor(r, g, b, 1)

    -- Update the absorb shield bar for player and target frames (behind health bar)
    if (unit == "player" or unit == "target") and frame.shieldBarFG then
        local shield = UnitGetTotalAbsorbs(unit) or 0
        if shield > 0 and hp < maxHP then
            frame.shieldBarFG:Show()
            local shieldWidth = math.min(fullWidth - frame.healthBarFG:GetWidth(), fullWidth * (shield / maxHP))
            frame.shieldBarFG:SetWidth(shieldWidth)
            frame.shieldBarFG:SetVertexColor(1, 1, 1, 1)  -- Keep full vertex color
            frame.shieldBarFG:SetAlpha(0.5)  -- Ensure 50% transparency is maintained
        else
            frame.shieldBarFG:Hide()
        end
    end

    -- Update the absorb shield bar for player and target frames (above health bar)
    -- Only show if there is a shield AND unit is at full health.
    if (unit == "player" or unit == "target") and frame.shieldBarFG2 then
        local shield = UnitGetTotalAbsorbs(unit) or 0
        if shield > 0 and hp == maxHP then
            frame.shieldBarFG2:Show()
        else
            frame.shieldBarFG2:Hide()
        end
    end

    -- Update power bar if it exists
    if frame.powerBarFG and (unit == "player" or unit == "target") then
        local powerType = UnitPowerType(unit)
        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        
        -- Check for shaman specs and override powerType to mana if necessary
        if UnitClass(unit) == "Shaman" then
            local spec = GetSpecialization()
            if spec == 1 or spec == 2 then  -- 1: Elemental, 2: Enhancement
                powerType = 0  -- 0 is MANA
                power = UnitPower(unit, 0)
                maxPower = UnitPowerMax(unit, 0)
            end
        end

        -- Hide power bar if unit doesn't use power
        if maxPower <= 0 or powerType == 7 then -- 7 is SPELL_POWER_ALTERNATE which some NPCs use
            frame.powerBarBorder:Hide()
            frame.powerBarBG:Hide()
            frame.powerBarFG:Hide()
            return
        end
        
        local powerPercent = power / maxPower
        
        -- Get power color with custom mana color
        local powerColor = PowerBarColor[powerType]
        local r, g, b = 1, 1, 1
        if powerType == 0 then  -- 0 is MANA
            r, g, b = 0.2, 0.7, 1  -- Light blue color for mana
        elseif powerColor then
            r, g, b = powerColor.r, powerColor.g, powerColor.b
        end
        
        -- Update power bar width
        local width = frame.powerBarBG:GetWidth() * powerPercent
        frame.powerBarFG:ClearAllPoints()
        frame.powerBarFG:SetPoint("BOTTOMLEFT", frame.powerBarBG, "BOTTOMLEFT", 0, 0)
        frame.powerBarFG:SetWidth(width)
        
        frame.powerBarFG:SetVertexColor(r, g, b, 1)
        
        frame.powerBarBorder:Show()
        frame.powerBarBG:Show()
        frame.powerBarFG:Show()
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

local AURA_ICON_SIZE    = 18
local AURA_ICON_SPACING = 2
local MAX_AURA_ICONS    = 12
local ROW_ICONS         = 4

local function MMF_SetupTargetAuras()
    if not MMF_TargetFrame then return end

    -- Buff container (bottom-right)
    MMF_TargetFrame.BuffContainer = CreateFrame("Frame", nil, MMF_TargetFrame)
    MMF_TargetFrame.BuffContainer:SetSize(
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
    )
    MMF_TargetFrame.BuffContainer:SetPoint("BOTTOMRIGHT", MMF_TargetFrame, "BOTTOMRIGHT", -3, -60)
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
        -- Create a frame above the cooldown spiral for timer text
        aura.timerFrame = CreateFrame("Frame", nil, aura)
        aura.timerFrame:SetAllPoints(aura)
        aura.timerFrame:SetFrameLevel(aura.cooldown:GetFrameLevel() + 10)
        aura.timerText = aura.timerFrame:CreateFontString(nil, "OVERLAY")
        aura.timerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        aura.timerText:SetPoint("TOP", aura.timerFrame, "TOP", 0, -2)
        aura.timerText:SetJustifyH("CENTER")
        aura.timerText:Hide()
        aura:SetScript("OnEnter", function(self)
            if self.auraIndex and self.auraFilter then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                GameTooltip:Show()
                self:SetScript("OnUpdate", function(self, elapsed)
                    if GameTooltip:GetOwner() == self then
                        GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                    end
                end)
            end
        end)
        aura:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self:SetScript("OnUpdate", nil)
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
    MMF_TargetFrame.DebuffContainer:SetPoint("TOPLEFT", MMF_TargetFrame, "TOPLEFT", 3, 27)
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
        -- Create a frame above the cooldown spiral for timer text
        aura.timerFrame = CreateFrame("Frame", nil, aura)
        aura.timerFrame:SetAllPoints(aura)
        aura.timerFrame:SetFrameLevel(aura.cooldown:GetFrameLevel() + 10)
        aura.timerText = aura.timerFrame:CreateFontString(nil, "OVERLAY")
        aura.timerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        aura.timerText:SetPoint("TOP", aura.timerFrame, "TOP", 0, -2)
        aura.timerText:SetJustifyH("CENTER")
        aura.timerText:Hide()
        aura.border = aura:CreateTexture(nil, "OVERLAY")
        aura.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        aura.border:SetAllPoints(aura)
        aura:SetScript("OnEnter", function(self)
            if self.auraIndex and self.auraFilter then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                GameTooltip:Show()
                self:SetScript("OnUpdate", function(self, elapsed)
                    if GameTooltip:GetOwner() == self then
                        GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                    end
                end)
            end
        end)
        aura:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self:SetScript("OnUpdate", nil)
        end)
        aura:Hide()
        MMF_TargetFrame.DebuffContainer.auras[i] = aura
    end
end

local function MMF_UpdateTargetAuras()
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return end

    local unit = "target"
    local buffs, debuffs = {}, {}
    -- Blizzard default maxes
    local BUFF_MAX_DISPLAY, DEBUFF_MAX_DISPLAY = 32, 16

    -- Gather buffs (HELPFUL)
    for i = 1, BUFF_MAX_DISPLAY do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not auraData then break end
        auraData._index = i
        table.insert(buffs, auraData)
    end

    -- Gather debuffs (HARMFUL) -- show all, not just player's
    for i = 1, DEBUFF_MAX_DISPLAY do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        if not auraData then break end
        auraData._index = i
        table.insert(debuffs, auraData)
    end

    -- Sort: permanent first, then by time left ascending
    local function auraSort(a, b)
        local aPermanent = (a.duration == 0)
        local bPermanent = (b.duration == 0)
        if aPermanent ~= bPermanent then
            return aPermanent
        elseif aPermanent and bPermanent then
            return (a.name < b.name)
        else
            return (a.expirationTime - GetTime()) < (b.expirationTime - GetTime())
        end
    end
    table.sort(buffs, auraSort)
    table.sort(debuffs, auraSort)

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
                -- Show stack count if >1
                local count = auraData.applications or auraData.count or 0
                if count > 1 then
                    if not auraFrame.count then
                        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
                        auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -2, 2)
                    end
                    auraFrame.count:SetText(count)
                    auraFrame.count:Show()
                elseif auraFrame.count then
                    auraFrame.count:Hide()
                end
                -- Show cooldown if duration > 0
                if auraData.duration and auraData.duration > 0 and auraData.expirationTime then
                    auraFrame.cooldown:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration)
                    auraFrame.cooldown:Show()
                    -- Timer text
                    auraFrame.timerText:Show()
                    auraFrame.timerText:SetText("")
                    auraFrame:SetScript("OnUpdate", function(self, elapsed)
                        local now = GetTime()
                        local timeLeft = (auraData.expirationTime or 0) - now
                        if timeLeft > 0 and timeLeft < 60 then
                            self.timerText:SetText(tostring(math.floor(timeLeft)))
                            self.timerText:Show()
                        else
                            self.timerText:SetText("")
                            self.timerText:Hide()
                            if timeLeft <= 0 then
                                self:SetScript("OnUpdate", nil)
                            end
                        end
                    end)
                else
                    auraFrame.cooldown:Hide()
                    auraFrame.timerText:Hide()
                    auraFrame:SetScript("OnUpdate", nil)
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
                -- Show stack count if >1
                local count = auraData.applications or auraData.count or 0
                if count > 1 then
                    if not auraFrame.count then
                        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
                        auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -2, 2)
                    end
                    auraFrame.count:SetText(count)
                    auraFrame.count:Show()
                elseif auraFrame.count then
                    auraFrame.count:Hide()
                end
                -- Show cooldown if duration > 0
                if auraData.duration and auraData.duration > 0 and auraData.expirationTime then
                    auraFrame.cooldown:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration)
                    auraFrame.cooldown:Show()
                    -- Timer text
                    auraFrame.timerText:Show()
                    auraFrame.timerText:SetText("")
                    auraFrame:SetScript("OnUpdate", function(self, elapsed)
                        local now = GetTime()
                        local timeLeft = (auraData.expirationTime or 0) - now
                        if timeLeft >= 1 and timeLeft < 60 then
                            self.timerText:SetText(string.format("%d", math.floor(timeLeft)))
                            self.timerText:Show()
                        else
                            self.timerText:SetText("")
                            self.timerText:Hide()
                            if timeLeft <= 0 then
                                self:SetScript("OnUpdate", nil)
                            end
                        end
                    end)
                else
                    auraFrame.cooldown:Hide()
                    auraFrame.timerText:Hide()
                    auraFrame:SetScript("OnUpdate", nil)
                end
                -- Debuff border color by dispel type
                if auraFrame.border then
                    local color = DebuffTypeColor and DebuffTypeColor[auraData.dispelName or auraData.debuffType or "none"] or {r=1,g=1,b=1}
                    auraFrame.border:SetVertexColor(color.r, color.g, color.b)
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


