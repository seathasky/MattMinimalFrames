-- Class-specific resource bars
-- Uses compat.lua for version-specific features

local Compat = _G.MMF_Compat
local _, playerClass = UnitClass("player")

--------------------------------------------------
-- DEATH KNIGHT RUNE BAR (Retail only)
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
    
    -- Individual runes as StatusBars
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

--------------------------------------------------
-- PALADIN HOLY POWER BAR (Retail only)
--------------------------------------------------

local MMF_HolyPowerBar

local function CreateHolyPowerBar()
    if MMF_HolyPowerBar then return MMF_HolyPowerBar end
    
    local frame = CreateFrame("Frame", "MMF_HolyPowerBar", UIParent)
    frame:SetSize(166, 12)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Individual holy power runes as StatusBars (matching DK style)
    frame.runes = {}
    local runeWidth = 30
    local runeSpacing = 4
    
    for i = 1, 5 do
        local rune = CreateFrame("StatusBar", nil, frame)
        rune:SetSize(runeWidth, 10)
        rune:SetPoint("LEFT", frame, "LEFT", (i - 1) * (runeWidth + runeSpacing) + 1, 0)
        rune:SetStatusBarTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
        rune:SetMinMaxValues(0, 1)
        rune:SetValue(0)
        rune:SetOrientation("HORIZONTAL")
        
        -- Rune background
        rune.bg = rune:CreateTexture(nil, "BACKGROUND")
        rune.bg:SetAllPoints()
        rune.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        -- Paladin holy power color (golden yellow)
        rune:SetStatusBarColor(0.95, 0.9, 0.2, 1)
        
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
            MattMinimalFramesDB.holyPowerBarPosition = { left = left, top = top }
        end
    end)
    
    -- Move hint
    frame.moveHint = frame:CreateFontString(nil, "OVERLAY")
    frame.moveHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "OUTLINE")
    frame.moveHint:SetText("Holy Power Bar")
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
    if MattMinimalFramesDB and MattMinimalFramesDB.holyPowerBarPosition then
        local pos = MattMinimalFramesDB.holyPowerBarPosition
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    end
    
    MMF_HolyPowerBar = frame
    return frame
end

--------------------------------------------------
-- GENERIC CLASS RESOURCE BAR FACTORY
--------------------------------------------------

local function CreateClassResourceBar(barName, resourceType, maxValue, color, numRunes)
    local frame = CreateFrame("Frame", barName, UIParent)
    local runeWidth = 30
    local runeSpacing = 4
    local totalWidth = (runeWidth * numRunes) + (runeSpacing * (numRunes - 1)) + 2
    
    frame:SetSize(totalWidth, 12)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Individual resource nodes as StatusBars
    frame.runes = {}
    for i = 1, numRunes do
        local rune = CreateFrame("StatusBar", nil, frame)
        rune:SetSize(runeWidth, 10)
        rune:SetPoint("LEFT", frame, "LEFT", (i - 1) * (runeWidth + runeSpacing) + 1, 0)
        rune:SetStatusBarTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga")
        rune:SetMinMaxValues(0, 1)
        rune:SetValue(0)
        rune:SetOrientation("HORIZONTAL")
        
        -- Rune background
        rune.bg = rune:CreateTexture(nil, "BACKGROUND")
        rune.bg:SetAllPoints()
        rune.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        -- Set color
        rune:SetStatusBarColor(color[1], color[2], color[3], 1)
        
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
            MattMinimalFramesDB[barName .. "Position"] = { left = left, top = top }
        end
    end)
    
    -- Move hint
    frame.moveHint = frame:CreateFontString(nil, "OVERLAY")
    frame.moveHint:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "OUTLINE")
    frame.moveHint:SetText(barName:gsub("MMF_", ""):gsub("Bar", ""))
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
    if MattMinimalFramesDB and MattMinimalFramesDB[barName .. "Position"] then
        local pos = MattMinimalFramesDB[barName .. "Position"]
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    end
    
    frame.resourceType = resourceType
    return frame
end

--------------------------------------------------
-- COMBO POINTS (Rogue/Feral Druid)
--------------------------------------------------

local MMF_ComboPointBar

local function CreateComboPointBar()
    -- Create with max possible combo points (7 to handle all talents), show/hide dynamically
    return CreateClassResourceBar("MMF_ComboPointBar", Enum.PowerType.ComboPoints, 9, {1, 0.8, 0.2}, 7)
end

local function UpdateComboPointBar(self)
    if not MMF_ComboPointBar or not MMF_ComboPointBar:IsShown() then return end
    
    local numComboPoints = UnitPower("player", Enum.PowerType.ComboPoints)
    local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
    
    -- Resize bar based on max combo points (handles Deeper Stratagem dynamically)
    local runeWidth = 30
    local runeSpacing = 4
    local totalWidth = (runeWidth * maxComboPoints) + (runeSpacing * (maxComboPoints - 1)) + 2
    MMF_ComboPointBar:SetWidth(totalWidth)
    
    -- Show/hide runes based on max combo points
    for i = 1, 7 do
        local rune = MMF_ComboPointBar.runes[i]
        if rune then
            if i <= maxComboPoints then
                rune:Show()
                if i <= numComboPoints then
                    rune:SetValue(1)
                    rune:SetAlpha(1)
                else
                    rune:SetValue(0)
                    rune:SetAlpha(0.4)
                end
            else
                rune:Hide()
            end
        end
    end
end

--------------------------------------------------
-- SOUL SHARDS (Warlock)
--------------------------------------------------

local MMF_SoulShardBar

local function CreateSoulShardBar()
    return CreateClassResourceBar("MMF_SoulShardBar", Enum.PowerType.SoulShards, 5, {0.9, 0.5, 1}, 5)
end

local function UpdateSoulShardBar(self)
    if not MMF_SoulShardBar or not MMF_SoulShardBar:IsShown() then return end
    
    local numSoulShards = UnitPower("player", Enum.PowerType.SoulShards)
    
    for i = 1, 5 do
        local rune = MMF_SoulShardBar.runes[i]
        if rune then
            if i <= numSoulShards then
                rune:SetValue(1)
                rune:SetAlpha(1)
            else
                rune:SetValue(0)
                rune:SetAlpha(0.4)
            end
        end
    end
end

--------------------------------------------------
-- CHI (Windwalker Monk)
--------------------------------------------------

local MMF_ChiBar

local function CreateChiBar()
    return CreateClassResourceBar("MMF_ChiBar", Enum.PowerType.Chi, 6, {0.2, 1, 0.8}, 6)
end

local function UpdateChiBar(self)
    if not MMF_ChiBar or not MMF_ChiBar:IsShown() then return end
    
    local numChi = UnitPower("player", Enum.PowerType.Chi)
    local maxChi = UnitPowerMax("player", Enum.PowerType.Chi)
    
    for i = 1, maxChi do
        local rune = MMF_ChiBar.runes[i]
        if rune then
            if i <= numChi then
                rune:SetValue(1)
                rune:SetAlpha(1)
            else
                rune:SetValue(0)
                rune:SetAlpha(0.4)
            end
        end
    end
end

--------------------------------------------------
-- ARCANE CHARGES (Arcane Mage)
--------------------------------------------------

local MMF_ArcaneChargeBar

local function CreateArcaneChargeBar()
    return CreateClassResourceBar("MMF_ArcaneChargeBar", Enum.PowerType.ArcaneCharges, 4, {0.4, 0.7, 1}, 4)
end

local function UpdateArcaneChargeBar(self)
    if not MMF_ArcaneChargeBar or not MMF_ArcaneChargeBar:IsShown() then return end
    
    local numCharges = UnitPower("player", Enum.PowerType.ArcaneCharges)
    
    for i = 1, 4 do
        local rune = MMF_ArcaneChargeBar.runes[i]
        if rune then
            if i <= numCharges then
                rune:SetValue(1)
                rune:SetAlpha(1)
            else
                rune:SetValue(0)
                rune:SetAlpha(0.4)
            end
        end
    end
end

--------------------------------------------------
-- ESSENCE (Evoker)
--------------------------------------------------

local MMF_EssenceBar

local function CreateEssenceBar()
    return CreateClassResourceBar("MMF_EssenceBar", Enum.PowerType.Essence, 5, {1, 0.5, 0.7}, 5)
end

local function UpdateEssenceBar(self)
    if not MMF_EssenceBar or not MMF_EssenceBar:IsShown() then return end
    
    local numEssence = UnitPower("player", Enum.PowerType.Essence)
    local maxEssence = UnitPowerMax("player", Enum.PowerType.Essence)
    
    for i = 1, maxEssence do
        local rune = MMF_EssenceBar.runes[i]
        if rune then
            if i <= numEssence then
                rune:SetValue(1)
                rune:SetAlpha(1)
            else
                rune:SetValue(0)
                rune:SetAlpha(0.4)
            end
        end
    end
end

local function UpdateHolyPowerBar(self, event, unit)
    if not MMF_HolyPowerBar or not MMF_HolyPowerBar:IsShown() then return end
    
    -- Only update for player unit
    if event and unit and unit ~= "player" then return end
    
    local numHolyPower = UnitPower("player", Enum.PowerType.HolyPower)
    local maxHolyPower = UnitPowerMax("player", Enum.PowerType.HolyPower)
    
    -- Update each rune based on current holy power
    for i = 1, maxHolyPower do
        local rune = MMF_HolyPowerBar.runes[i]
        if rune then
            if i <= numHolyPower then
                -- Holy power is active
                rune:SetValue(1)
                rune:SetAlpha(1)
            else
                -- Holy power is inactive
                rune:SetValue(0)
                rune:SetAlpha(0.4)
            end
        end
    end
end

function MMF_UpdateHolyPowerBarScale(scale)
    if not MMF_HolyPowerBar then return end
    MMF_HolyPowerBar:SetScale(scale)
end

function MMF_UpdateComboPointBarScale(scale)
    if not MMF_ComboPointBar then return end
    MMF_ComboPointBar:SetScale(scale)
end

function MMF_UpdateSoulShardBarScale(scale)
    if not MMF_SoulShardBar then return end
    MMF_SoulShardBar:SetScale(scale)
end

function MMF_UpdateChiBarScale(scale)
    if not MMF_ChiBar then return end
    MMF_ChiBar:SetScale(scale)
end

function MMF_UpdateArcaneChargeBarScale(scale)
    if not MMF_ArcaneChargeBar then return end
    MMF_ArcaneChargeBar:SetScale(scale)
end

function MMF_UpdateEssenceBarScale(scale)
    if not MMF_EssenceBar then return end
    MMF_EssenceBar:SetScale(scale)
end

function MMF_InitializeClassResources()
    if playerClass == "DEATHKNIGHT" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showRuneBar then
            local frame = CreateRuneBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.runeBarScale) or 1.0
            frame:SetScale(scale)
            frame:Show()
            
            frame:RegisterEvent("RUNE_POWER_UPDATE")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:SetScript("OnEvent", UpdateRuneBar)
            
            frame.elapsed = 0
            frame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed >= 0.05 then
                    UpdateRuneBar(self, self.elapsed)
                    self.elapsed = 0
                end
            end)
        end
    elseif playerClass == "PALADIN" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showHolyPowerBar then
            local frame = CreateHolyPowerBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.holyPowerBarScale) or 1.0
            frame:SetScale(scale)
            frame:Show()
            
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:SetScript("OnEvent", UpdateHolyPowerBar)
            
            UpdateHolyPowerBar(frame)
        end
    elseif playerClass == "ROGUE" or playerClass == "DRUID" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showComboPointBar then
            MMF_ComboPointBar = CreateComboPointBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.comboPointBarScale) or 1.0
            MMF_ComboPointBar:SetScale(scale)
            MMF_ComboPointBar:Show()
            
            MMF_ComboPointBar:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            MMF_ComboPointBar:RegisterEvent("PLAYER_ENTERING_WORLD")
            MMF_ComboPointBar:SetScript("OnEvent", UpdateComboPointBar)
            
            UpdateComboPointBar(MMF_ComboPointBar)
        end
    elseif playerClass == "WARLOCK" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showSoulShardBar then
            MMF_SoulShardBar = CreateSoulShardBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.soulShardBarScale) or 1.0
            MMF_SoulShardBar:SetScale(scale)
            MMF_SoulShardBar:Show()
            
            MMF_SoulShardBar:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            MMF_SoulShardBar:RegisterEvent("PLAYER_ENTERING_WORLD")
            MMF_SoulShardBar:SetScript("OnEvent", UpdateSoulShardBar)
            
            UpdateSoulShardBar(MMF_SoulShardBar)
        end
    elseif playerClass == "MONK" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showChiBar then
            MMF_ChiBar = CreateChiBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.chiBarScale) or 1.0
            MMF_ChiBar:SetScale(scale)
            MMF_ChiBar:Show()
            
            MMF_ChiBar:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            MMF_ChiBar:RegisterEvent("PLAYER_ENTERING_WORLD")
            MMF_ChiBar:SetScript("OnEvent", UpdateChiBar)
            
            UpdateChiBar(MMF_ChiBar)
        end
    elseif playerClass == "MAGE" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showArcaneChargeBar then
            MMF_ArcaneChargeBar = CreateArcaneChargeBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.arcaneChargeBarScale) or 1.0
            MMF_ArcaneChargeBar:SetScale(scale)
            MMF_ArcaneChargeBar:Show()
            
            MMF_ArcaneChargeBar:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            MMF_ArcaneChargeBar:RegisterEvent("PLAYER_ENTERING_WORLD")
            MMF_ArcaneChargeBar:SetScript("OnEvent", UpdateArcaneChargeBar)
            
            UpdateArcaneChargeBar(MMF_ArcaneChargeBar)
        end
    elseif playerClass == "EVOKER" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showEssenceBar then
            MMF_EssenceBar = CreateEssenceBar()
            local scale = (MattMinimalFramesDB and MattMinimalFramesDB.essenceBarScale) or 1.0
            MMF_EssenceBar:SetScale(scale)
            MMF_EssenceBar:Show()
            
            MMF_EssenceBar:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            MMF_EssenceBar:RegisterEvent("PLAYER_ENTERING_WORLD")
            MMF_EssenceBar:SetScript("OnEvent", UpdateEssenceBar)
            
            UpdateEssenceBar(MMF_EssenceBar)
        end
    end
end
