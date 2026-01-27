-- core/auras.lua
-- Aura (buff/debuff) display for MattMinimalFrames
-- Uses compat.lua for version-specific aura APIs

local Compat = _G.MMF_Compat
local cfg = MMF_Config
local AURA_ICON_SPACING = cfg.AURA_ICON_SPACING
local MAX_AURA_ICONS = cfg.MAX_AURA_ICONS
local ROW_ICONS = cfg.AURA_ROW_ICONS

-- Cache compat functions
local GetUnitAuras = Compat.GetUnitAuras
local SetAuraCooldown = Compat.SetAuraCooldown
local GetAuraCount = Compat.GetAuraCount
local HasRetailAuraAPI = Compat.HasRetailAuraAPI

local issecretvalue = issecretvalue

--------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------

local function NotSecretValue(value)
    return not issecretvalue or not issecretvalue(value)
end

--------------------------------------------------
-- UPDATE FUNCTIONS (called from popup sliders)
--------------------------------------------------

function MMF_UpdateAuraTextScale(scale)
    if not MMF_TargetFrame then return end
    
    local fontSize = math.max(6, math.floor(10 * scale))
    
    local function updateContainer(container)
        if container and container.auras then
            for _, aura in ipairs(container.auras) do
                if aura.count then
                    aura.count:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
                end
            end
        end
    end
    
    updateContainer(MMF_TargetFrame.BuffContainer)
    updateContainer(MMF_TargetFrame.DebuffContainer)
end

function MMF_UpdateTimerTextScale(scale)
    if not MMF_TargetFrame then return end
    
    local fontSize = math.max(8, math.floor(12 * scale))
    
    local function updateContainer(container)
        if container and container.auras then
            for _, aura in ipairs(container.auras) do
                if aura.timerText then
                    aura.timerText:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
                end
            end
        end
    end
    
    updateContainer(MMF_TargetFrame.BuffContainer)
    updateContainer(MMF_TargetFrame.DebuffContainer)
end

function MMF_UpdateAuraIconSize(size)
    if not MMF_TargetFrame then return end
    
    size = math.floor(size)
    
    local function updateContainer(container, anchorPoint, getX, getY)
        if not container or not container.auras then return end
        
        container:SetSize(
            (size + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
            (size + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
        )
        
        for i, aura in ipairs(container.auras) do
            aura:SetSize(size, size)
            local row = math.floor((i - 1) / ROW_ICONS)
            local col = (i - 1) % ROW_ICONS
            aura:ClearAllPoints()
            aura:SetPoint(anchorPoint, container, anchorPoint, getX(col, size), getY(row, size))
        end
    end
    
    -- Buffs: anchor TOPRIGHT, grow left
    updateContainer(MMF_TargetFrame.BuffContainer, "TOPRIGHT",
        function(col, s) return -col * (s + AURA_ICON_SPACING) end,
        function(row, s) return -row * (s + AURA_ICON_SPACING) end)
    
    -- Debuffs: anchor TOPLEFT, grow right
    updateContainer(MMF_TargetFrame.DebuffContainer, "TOPLEFT",
        function(col, s) return col * (s + AURA_ICON_SPACING) end,
        function(row, s) return row * (s + AURA_ICON_SPACING) end)
end

function MMF_UpdateBuffPosition(x, y)
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end
    MMF_TargetFrame.BuffContainer:ClearAllPoints()
    MMF_TargetFrame.BuffContainer:SetPoint("BOTTOMRIGHT", MMF_TargetFrame, "BOTTOMRIGHT", x, y)
end

function MMF_UpdateDebuffPosition(x, y)
    if not MMF_TargetFrame or not MMF_TargetFrame.DebuffContainer then return end
    MMF_TargetFrame.DebuffContainer:ClearAllPoints()
    MMF_TargetFrame.DebuffContainer:SetPoint("TOPLEFT", MMF_TargetFrame, "TOPLEFT", x, y)
end

--------------------------------------------------
-- AURA ICON CREATION
--------------------------------------------------

local function CreateAuraIcon(parent, index, isDebuff, iconSize)
    local aura = CreateFrame("Frame", nil, parent)
    aura:SetSize(iconSize, iconSize)
    
    local row = math.floor((index - 1) / ROW_ICONS)
    local col = (index - 1) % ROW_ICONS
    
    if isDebuff then
        aura:SetPoint("TOPLEFT", parent, "TOPLEFT",
            col * (iconSize + AURA_ICON_SPACING),
            row * (iconSize + AURA_ICON_SPACING))
    else
        aura:SetPoint("TOPRIGHT", parent, "TOPRIGHT",
            -col * (iconSize + AURA_ICON_SPACING),
            -row * (iconSize + AURA_ICON_SPACING))
    end
    
    -- Icon texture
    aura.icon = aura:CreateTexture(nil, "ARTWORK")
    aura.icon:SetAllPoints(aura)
    aura.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Cooldown frame
    aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
    aura.cooldown:SetAllPoints(aura)
    aura.cooldown:SetDrawEdge(false)
    aura.cooldown:SetHideCountdownNumbers(false)
    
    -- Timer text from cooldown
    aura.timerText = aura.cooldown:GetRegions()
    if aura.timerText and aura.timerText.SetFont then
        aura.timerText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        aura.timerText:ClearAllPoints()
        aura.timerText:SetPoint("CENTER", aura.cooldown, "CENTER", 0, 0)
    end
    
    -- Debuff border
    if isDebuff then
        aura.border = aura:CreateTexture(nil, "OVERLAY")
        aura.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        aura.border:SetAllPoints(aura)
    end
    
    -- Tooltip handlers
    aura:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- Retail uses auraInstanceID, TBC uses index
        if self.auraData and self.auraData.auraInstanceID and GameTooltip.SetUnitAuraByAuraInstanceID then
            GameTooltip:SetUnitAuraByAuraInstanceID("target", self.auraData.auraInstanceID, self.auraFilter)
        elseif self.auraIndex then
            GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
        end
        GameTooltip:Show()
    end)
    
    aura:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    aura:Hide()
    return aura
end

--------------------------------------------------
-- CONTAINER SETUP
--------------------------------------------------

local function CreateAuraContainer(parent, isDebuff)
    local iconSize = MMF_GetAuraIconSize()
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(
        (iconSize + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
        (iconSize + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
    )
    
    if isDebuff then
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset())
    else
        container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", MMF_GetBuffXOffset(), MMF_GetBuffYOffset())
    end
    
    container.auras = {}
    for i = 1, MAX_AURA_ICONS do
        container.auras[i] = CreateAuraIcon(container, i, isDebuff, iconSize)
    end
    
    return container
end

function MMF_SetupTargetAuras()
    if not MMF_TargetFrame then return end
    
    MMF_TargetFrame.BuffContainer = CreateAuraContainer(MMF_TargetFrame, false)
    MMF_TargetFrame.DebuffContainer = CreateAuraContainer(MMF_TargetFrame, true)
end

--------------------------------------------------
-- AURA UPDATE
--------------------------------------------------

-- Unified aura icon update (uses compat layer)
local function UpdateAuraIcon(auraFrame, auraData, filter, unit, index)
    auraFrame.icon:SetTexture(auraData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    auraFrame.auraData = auraData
    auraFrame.auraIndex = index or auraData._index
    auraFrame.auraFilter = filter
    
    local auraInstanceID = auraData.auraInstanceID
    
    -- Stack count - hide first, then show if needed
    if auraFrame.count then auraFrame.count:Hide() end
    
    -- Retail: use GetAuraApplicationDisplayCount directly (avoid comparing secret values)
    if auraInstanceID and C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount then
        if not auraFrame.count then
            auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
            auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
        end
        local scale = MMF_GetAuraTextScale()
        auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(10 * scale)), "OUTLINE")
        auraFrame.count:SetText(C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 999))
        auraFrame.count:Show()
    elseif auraData.count and auraData.count > 1 then
        -- TBC/Classic fallback
        if not auraFrame.count then
            auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
            auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
        end
        local scale = MMF_GetAuraTextScale()
        auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(10 * scale)), "OUTLINE")
        auraFrame.count:SetText(auraData.count)
        auraFrame.count:Show()
    end
    
    -- Cooldown (uses compat layer)
    if auraFrame.cooldown then
        SetAuraCooldown(auraFrame.cooldown, auraData, unit)
        
        if auraFrame.timerText and auraFrame.timerText.SetFont then
            local timerScale = MMF_GetTimerTextScale()
            local timerFontSize = math.max(8, math.floor(12 * timerScale))
            auraFrame.timerText:SetFont(STANDARD_TEXT_FONT, timerFontSize, "OUTLINE")
        end
    end
    
    auraFrame:Show()
end

function MMF_UpdateTargetAuras()
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end

    local unit = "target"
    
    -- Use compat layer for aura retrieval (handles both TBC and Retail)
    local buffs = GetUnitAuras(unit, "HELPFUL")
    local debuffs = GetUnitAuras(unit, "HARMFUL")

    -- Update Buffs
    local buffContainer = MMF_TargetFrame.BuffContainer
    if MattMinimalFramesDB.showBuffs == false then
        buffContainer:Hide()
    else
        buffContainer:Show()
        for _, aura in ipairs(buffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        
        for i = 1, math.min(#buffs, MAX_AURA_ICONS) do
            local auraFrame = buffContainer.auras[i]
            if auraFrame then
                UpdateAuraIcon(auraFrame, buffs[i], "HELPFUL", unit, i)
            end
        end
    end

    -- Update Debuffs
    local debuffContainer = MMF_TargetFrame.DebuffContainer
    if MattMinimalFramesDB.showDebuffs == false then
        debuffContainer:Hide()
    else
        debuffContainer:Show()
        for _, aura in ipairs(debuffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        
        for i = 1, math.min(#debuffs, MAX_AURA_ICONS) do
            local auraFrame = debuffContainer.auras[i]
            if auraFrame then
                UpdateAuraIcon(auraFrame, debuffs[i], "HARMFUL", unit, i)
                
                -- Debuff border color
                if auraFrame.border then
                    local dispelName = debuffs[i].dispelName or debuffs[i].debuffType
                    if NotSecretValue(dispelName) then
                        local color = DebuffTypeColor and DebuffTypeColor[dispelName or "none"] or {r=1,g=1,b=1}
                        auraFrame.border:SetVertexColor(color.r, color.g, color.b)
                    else
                        auraFrame.border:SetVertexColor(1, 1, 1)
                    end
                end
            end
        end
    end
end

--------------------------------------------------
-- AURA EVENTS
--------------------------------------------------

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
