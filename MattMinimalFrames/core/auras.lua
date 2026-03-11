local Compat = _G.MMF_Compat
local cfg = MMF_Config
local AURA_ICON_SPACING = cfg.AURA_ICON_SPACING
local MAX_AURA_ICONS = cfg.MAX_AURA_ICONS
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

local function GetAuraIconsPerRow()
    local perRow = math.floor(tonumber(MattMinimalFramesDB and MattMinimalFramesDB.auraIconsPerRow) or cfg.AURA_ROW_ICONS or 4)
    if perRow < 1 then perRow = 1 end
    if perRow > MAX_AURA_ICONS then perRow = MAX_AURA_ICONS end
    return perRow
end

local function GetAuraRows()
    local rows = math.floor(tonumber(MattMinimalFramesDB and MattMinimalFramesDB.auraRows) or 3)
    if rows < 1 then rows = 1 end
    if rows > MAX_AURA_ICONS then rows = MAX_AURA_ICONS end
    return rows
end

local function GetVisibleAuraLimit()
    return math.min(MAX_AURA_ICONS, GetAuraIconsPerRow() * GetAuraRows())
end

local function IsAuraTestModeEnabled()
    return MattMinimalFramesDB and MattMinimalFramesDB.auraTestMode == true
end

local function SetAuraTestPreviewFrameState(enabled)
    local targetFrame = _G.MMF_TargetFrame
    if not targetFrame then
        return
    end

    local function ApplyState()
        if enabled then
            if not targetFrame.mmfAuraTestUnitWatchSuspended
                and not targetFrame.mmfUnitWatchSuspended
                and type(UnregisterUnitWatch) == "function" then
                local ok = pcall(UnregisterUnitWatch, targetFrame)
                if ok then
                    targetFrame.mmfAuraTestUnitWatchSuspended = true
                end
            end
            targetFrame:Show()
        else
            if targetFrame.mmfAuraTestUnitWatchSuspended and type(RegisterUnitWatch) == "function" then
                pcall(RegisterUnitWatch, targetFrame)
                targetFrame.mmfAuraTestUnitWatchSuspended = nil
            end
            local editMode = MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
            local layoutTestMode = MattMinimalFramesDB and MattMinimalFramesDB.layoutTestMode == true
            if not editMode and not layoutTestMode and type(UnitExists) == "function" and not UnitExists("target") then
                targetFrame:Hide()
            end
        end

        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
        if MMF_RequestUnitUpdate then
            MMF_RequestUnitUpdate("target")
        elseif MMF_UpdateUnitFrame then
            MMF_UpdateUnitFrame(targetFrame)
        end
    end

    if (type(InCombatLockdown) == "function") and InCombatLockdown() then
        if MMF_RunAfterCombat then
            MMF_RunAfterCombat("mmf_aura_test_preview_frame_state", ApplyState)
        end
        return
    end

    ApplyState()
end

local function LayoutAuraContainer(container, isDebuff, size)
    if not container or not container.auras then
        return
    end

    local iconSize = math.floor(tonumber(size) or MMF_GetAuraIconSize() or 18)
    local perRow = GetAuraIconsPerRow()
    local rows = GetAuraRows()

    container:SetSize(
        (iconSize + AURA_ICON_SPACING) * perRow - AURA_ICON_SPACING,
        (iconSize + AURA_ICON_SPACING) * rows - AURA_ICON_SPACING
    )

    for i, aura in ipairs(container.auras) do
        aura:SetSize(iconSize, iconSize)
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        aura:ClearAllPoints()
        if isDebuff then
            aura:SetPoint("TOPLEFT", container, "TOPLEFT", col * (iconSize + AURA_ICON_SPACING), row * (iconSize + AURA_ICON_SPACING))
        else
            aura:SetPoint("TOPRIGHT", container, "TOPRIGHT", -col * (iconSize + AURA_ICON_SPACING), -row * (iconSize + AURA_ICON_SPACING))
        end
    end
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
    LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, size)
    LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, size)
end

function MMF_UpdateAuraLayout()
    if not MMF_TargetFrame then
        return
    end
    local size = MMF_GetAuraIconSize()
    LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, size)
    LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, size)
    if MMF_UpdateTargetAuras then
        MMF_UpdateTargetAuras()
    end
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

    aura.icon = aura:CreateTexture(nil, "ARTWORK")
    aura.icon:SetAllPoints(aura)
    aura.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
    aura.cooldown:SetAllPoints(aura)
    aura.cooldown:SetDrawEdge(false)
    aura.cooldown:SetHideCountdownNumbers(false)
    aura.cooldown:EnableMouse(false)
    aura.timerText = aura.cooldown:GetRegions()
    if aura.timerText and aura.timerText.SetFont then
        aura.timerText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        aura.timerText:ClearAllPoints()
        aura.timerText:SetPoint("CENTER", aura.cooldown, "CENTER", 0, 0)
    end
    if isDebuff then
        aura.border = aura:CreateTexture(nil, "OVERLAY")
        aura.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        aura.border:SetAllPoints(aura)
    end
    aura:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
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

    if isDebuff then
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset())
    else
        container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", MMF_GetBuffXOffset(), MMF_GetBuffYOffset())
    end

    container.auras = {}
    for i = 1, MAX_AURA_ICONS do
        container.auras[i] = CreateAuraIcon(container, i, isDebuff, iconSize)
    end

    LayoutAuraContainer(container, isDebuff, iconSize)

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

local function UpdateAuraIcon(auraFrame, auraData, filter, unit, index)
    auraFrame.icon:SetTexture(auraData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    auraFrame.auraData = auraData
    auraFrame.auraIndex = index or auraData._index
    auraFrame.auraFilter = filter
    
    local auraInstanceID = auraData.auraInstanceID
    if auraFrame.count then auraFrame.count:Hide() end
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
        if not auraFrame.count then
            auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
            auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
        end
        local scale = MMF_GetAuraTextScale()
        auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(10 * scale)), "OUTLINE")
        auraFrame.count:SetText(auraData.count)
        auraFrame.count:Show()
    end
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

local function UpdateFakeAuraIcon(auraFrame, index, isDebuff)
    if not auraFrame then
        return
    end

    auraFrame.auraData = nil
    auraFrame.auraIndex = nil
    auraFrame.auraFilter = nil
    auraFrame.icon:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\MMF.png")

    if not auraFrame.count then
        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
    end
    local scale = MMF_GetAuraTextScale()
    auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", math.max(6, math.floor(10 * scale)), "OUTLINE")
    local count = (index % 4) + 1
    auraFrame.count:SetText(count > 1 and count or "")
    auraFrame.count:Show()

    if auraFrame.cooldown then
        auraFrame.cooldown:Hide()
    end
    if auraFrame.timerText then
        auraFrame.timerText:Hide()
    end

    if auraFrame.border then
        if isDebuff then
            auraFrame.border:SetVertexColor(1, 0.25, 0.25)
        else
            auraFrame.border:SetVertexColor(1, 1, 1)
        end
    end

    auraFrame:Show()
end

local function PopulateFakeAuras(container, isDebuff)
    if not container or not container.auras then
        return
    end

    local fakeCount = GetVisibleAuraLimit()
    if fakeCount > 16 then
        fakeCount = 16
    end

    for i, aura in ipairs(container.auras) do
        if i <= fakeCount then
            UpdateFakeAuraIcon(aura, i, isDebuff)
        else
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
    end
end

function MMF_UpdateTargetAuras()
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end

    if IsAuraTestModeEnabled() then
        SetAuraTestPreviewFrameState(true)
        local buffContainer = MMF_TargetFrame.BuffContainer
        if MattMinimalFramesDB.showBuffs == false then
            buffContainer:Hide()
        else
            buffContainer:Show()
            PopulateFakeAuras(buffContainer, false)
        end

        local debuffContainer = MMF_TargetFrame.DebuffContainer
        if MattMinimalFramesDB.showDebuffs == false then
            debuffContainer:Hide()
        else
            debuffContainer:Show()
            PopulateFakeAuras(debuffContainer, true)
        end
        return
    end

    SetAuraTestPreviewFrameState(false)

    local unit = "target"
    local buffs = GetUnitAuras(unit, "HELPFUL")
    local debuffs = GetUnitAuras(unit, "HARMFUL")
    local buffContainer = MMF_TargetFrame.BuffContainer
    if MattMinimalFramesDB.showBuffs == false then
        buffContainer:Hide()
    else
        buffContainer:Show()
        for _, aura in ipairs(buffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        
        for i = 1, math.min(#buffs, GetVisibleAuraLimit()) do
            local auraFrame = buffContainer.auras[i]
            if auraFrame then
                UpdateAuraIcon(auraFrame, buffs[i], "HELPFUL", unit, i)
            end
        end
    end
    local debuffContainer = MMF_TargetFrame.DebuffContainer
    if MattMinimalFramesDB.showDebuffs == false then
        debuffContainer:Hide()
    else
        debuffContainer:Show()
        for _, aura in ipairs(debuffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        
        for i = 1, math.min(#debuffs, GetVisibleAuraLimit()) do
            local auraFrame = debuffContainer.auras[i]
            if auraFrame then
                UpdateAuraIcon(auraFrame, debuffs[i], "HARMFUL", unit, i)
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
