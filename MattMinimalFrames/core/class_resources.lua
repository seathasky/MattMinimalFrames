-- Class-specific resource bars
-- Uses compat.lua for version-specific features

local Compat = _G.MMF_Compat
local _, playerClass = UnitClass("player")

--------------------------------------------------
-- DEATH KNIGHT RUNE BAR (Retail only - DK doesn't exist in TBC)
--------------------------------------------------

-- Skip DK rune bar functionality for TBC/Classic
if not Compat.HasDeathKnight then
    function MMF_InitializeClassResources()
        -- No class-specific resources for TBC/Classic yet
    end
    function MMF_UpdateRuneBarScale(scale)
        -- No-op for TBC
    end
    return
end

local MMF_RuneBar

local function CreateRuneBar()
    if MMF_RuneBar then return MMF_RuneBar end
    
    local frame = CreateFrame("Frame", "MMF_RuneBar", UIParent)
    frame:SetSize(200, 12)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Individual runes as StatusBars (like ElvUI)
    frame.runes = {}
    local runeWidth = 30
    local runeSpacing = 4
    
    for i = 1, 6 do
        local rune = CreateFrame("StatusBar", nil, frame)
        rune:SetSize(runeWidth, 10)
        rune:SetPoint("LEFT", frame, "LEFT", (i - 1) * (runeWidth + runeSpacing) + 1, 0)
        rune:SetStatusBarTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
        rune:SetMinMaxValues(0, 1)
        rune:SetValue(1)
        rune:SetOrientation("HORIZONTAL")
        
        -- Rune background
        rune.bg = rune:CreateTexture(nil, "BACKGROUND")
        rune.bg:SetAllPoints()
        rune.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        -- Default DK rune color (cyan/blue)
        rune:SetStatusBarColor(0.3, 0.8, 1, 1)
        
        frame.runes[i] = rune
    end
    
    -- Drag handlers
    frame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left = self:GetLeft()
        local top = self:GetTop()
        if left and top then
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.runeBarPosition = { left = left, top = top }
        end
    end)
    
    -- Move hint
    frame.moveHint = frame:CreateFontString(nil, "OVERLAY")
    frame.moveHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "OUTLINE")
    frame.moveHint:SetText("Rune Bar")
    frame.moveHint:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.moveHint:Hide()
    
    frame.moveSubtext = frame:CreateFontString(nil, "OVERLAY")
    frame.moveSubtext:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "OUTLINE")
    frame.moveSubtext:SetText("Shift+Drag to move")
    frame.moveSubtext:SetPoint("TOP", frame.moveHint, "BOTTOM", 0, -2)
    frame.moveSubtext:SetTextColor(0.7, 0.7, 0.7)
    frame.moveSubtext:Hide()
    
    frame:SetScript("OnEnter", function(self)
        if not InCombatLockdown() and MattMinimalFramesDB.showMoveHints then
            self.moveHint:Show()
            self.moveSubtext:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        self.moveHint:Hide()
        self.moveSubtext:Hide()
    end)
    
    -- Restore saved position
    if MattMinimalFramesDB and MattMinimalFramesDB.runeBarPosition then
        local pos = MattMinimalFramesDB.runeBarPosition
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    end
    
    MMF_RuneBar = frame
    return frame
end

local function UpdateRuneBar(self, elapsed)
    if not MMF_RuneBar or not MMF_RuneBar:IsShown() then return end
    
    local currentTime = GetTime()
    
    for i = 1, 6 do
        local start, duration, runeReady = GetRuneCooldown(i)
        local rune = MMF_RuneBar.runes[i]
        
        if not rune then break end
        
        if runeReady then
            -- Rune is ready
            rune:SetMinMaxValues(0, 1)
            rune:SetValue(1)
            rune:SetAlpha(1)
        elseif start then
            -- Rune is recharging (similar to ElvUI's approach)
            local elapsed = currentTime - start
            rune:SetMinMaxValues(0, duration)
            rune:SetValue(elapsed)
            rune:SetAlpha(0.4)
        end
    end
end

function MMF_UpdateRuneBarScale(scale)
    if not MMF_RuneBar then return end
    MMF_RuneBar:SetScale(scale)
end

function MMF_InitializeClassResources()
    if playerClass == "DEATHKNIGHT" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showRuneBar then
            local frame = CreateRuneBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.runeBarScale) or 1.0
            frame:SetScale(scale)
            frame:Show()
            
            -- Register events (matching ElvUI's pattern)
            frame:RegisterEvent("RUNE_POWER_UPDATE")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:SetScript("OnEvent", UpdateRuneBar)
            
            -- OnUpdate for smooth StatusBar animation
            frame.elapsed = 0
            frame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed >= 0.05 then
                    UpdateRuneBar(self, self.elapsed)
                    self.elapsed = 0
                end
            end)
        end
    end
end
