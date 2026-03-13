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

local function ClearAuraFrameState(auraFrame)
    if not auraFrame then
        return
    end

    auraFrame.auraData = nil
    auraFrame.auraIndex = nil
    auraFrame.auraFilter = nil
    auraFrame.auraUnit = nil
    auraFrame.auraInstanceID = nil

    if auraFrame.count then
        auraFrame.count:Hide()
    end
    if auraFrame.cooldown then
        auraFrame.cooldown:Clear()
    end
    if auraFrame.timerText then
        auraFrame.timerText:Hide()
    end

    auraFrame:Hide()
end

local function ClearAuraContainer(container)
    if not container or not container.auras then
        return
    end

    for _, aura in ipairs(container.auras) do
        ClearAuraFrameState(aura)
    end
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

local function NormalizeAuraDirection(value, fallback)
    local v = type(value) == "string" and value or nil
    if v == "left_down"
        or v == "left_up"
        or v == "right_down"
        or v == "right_up"
        or v == "down_left"
        or v == "down_right"
        or v == "up_left"
        or v == "up_right" then
        return v
    end
    return fallback
end

local function GetAuraDirectionValue(isDebuff)
    local db = MattMinimalFramesDB or {}
    if isDebuff then
        return NormalizeAuraDirection(db.debuffAuraDirection, "right_up")
    end
    return NormalizeAuraDirection(db.buffAuraDirection, "left_down")
end

local function GetAuraDirectionConfig(directionValue)
    local direction = NormalizeAuraDirection(directionValue, "right_up")
    local horizontal = direction:match("left") and "left" or "right"
    local vertical = direction:match("up") and "up" or "down"
    local primary = (direction:find("down_") or direction:find("up_")) and "vertical" or "horizontal"

    local hSign = horizontal == "left" and -1 or 1
    local vSign = vertical == "up" and 1 or -1

    return {
        primary = primary,
        horizontalSign = hSign,
        verticalSign = vSign,
    }
end

local function ApplyAuraContainerPosition(container, isDebuff, x, y)
    if not container then
        return
    end
    local targetFrame = MMF_TargetFrame
    if not targetFrame then
        return
    end

    local offsetX = tonumber(x) or (isDebuff and 3 or -2)
    local offsetY = tonumber(y) or (isDebuff and 27 or -6)

    container:ClearAllPoints()
    if isDebuff then
        container:SetPoint("TOPLEFT", targetFrame, "TOPLEFT", offsetX, offsetY)
    else
        container:SetPoint("TOPRIGHT", targetFrame, "BOTTOMRIGHT", offsetX, offsetY)
    end
end

local function IsAuraTestModeEnabled()
    if not MattMinimalFramesDB or MattMinimalFramesDB.auraTestMode ~= true then
        return false
    end

    -- Outside of edit/layout preview, suppress fake aura previews in combat.
    local isPreviewMode = (MattMinimalFramesDB.unlockFramesEditMode == true)
        or (MattMinimalFramesDB.layoutTestMode == true)
    if not isPreviewMode and (type(InCombatLockdown) == "function") and InCombatLockdown() then
        return false
    end

    return true
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

local function GetActiveAuraCount(container)
    if not container or not container.auras then
        return 0
    end
    local count = 0
    for _, aura in ipairs(container.auras) do
        if aura and aura.IsShown and aura:IsShown() then
            count = count + 1
        end
    end
    return count
end

local function LayoutAuraContainer(container, isDebuff, size, activeCount)
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

    local direction = GetAuraDirectionConfig(GetAuraDirectionValue(isDebuff))
    local hSign = direction.horizontalSign
    local vSign = direction.verticalSign
    local primary = direction.primary
    local step = iconSize + AURA_ICON_SPACING

    local visibleLimit = GetVisibleAuraLimit()
    local active = math.floor(tonumber(activeCount) or GetActiveAuraCount(container) or 0)
    if active < 1 then
        active = 1
    end
    if active > visibleLimit then
        active = visibleLimit
    end

    local effectiveRows = rows
    local effectiveCols = perRow
    if primary == "horizontal" then
        effectiveRows = math.max(1, math.min(rows, math.ceil(active / perRow)))
    else
        effectiveRows = math.max(1, math.min(rows, active))
        effectiveCols = math.max(1, math.min(perRow, math.ceil(active / effectiveRows)))
    end

    for i, aura in ipairs(container.auras) do
        aura:SetSize(iconSize, iconSize)
        local index = i - 1
        local row, col
        if primary == "vertical" then
            row = index % effectiveRows
            col = math.floor(index / effectiveRows)
        else
            row = math.floor(index / perRow)
            col = index % perRow
        end
        aura:ClearAllPoints()
        local basePoint = isDebuff and "TOPLEFT" or "TOPRIGHT"
        aura:SetPoint(basePoint, container, basePoint, col * step * hSign, row * step * vSign)
    end

    if isDebuff then
        container:SetSize(
            (step * effectiveCols) - AURA_ICON_SPACING,
            (step * effectiveRows) - AURA_ICON_SPACING
        )
    else
        -- Keep old default visual spacing (3 rows) while avoiding extreme vertical drift
        -- when users set large row counts but only a few buffs are visible.
        local baselineRows = math.min(rows, 3)
        local buffRows = math.max(effectiveRows, baselineRows)
        container:SetSize(
            (step * perRow) - AURA_ICON_SPACING,
            (step * buffRows) - AURA_ICON_SPACING
        )
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
    LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, size, GetActiveAuraCount(MMF_TargetFrame.BuffContainer))
    LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, size, GetActiveAuraCount(MMF_TargetFrame.DebuffContainer))
end

function MMF_UpdateAuraLayout()
    if not MMF_TargetFrame then
        return
    end
    if MMF_TargetFrame.BuffContainer then
        ApplyAuraContainerPosition(MMF_TargetFrame.BuffContainer, false, MMF_GetBuffXOffset(), MMF_GetBuffYOffset())
    end
    if MMF_TargetFrame.DebuffContainer then
        ApplyAuraContainerPosition(MMF_TargetFrame.DebuffContainer, true, MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset())
    end
    local size = MMF_GetAuraIconSize()
    LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, size, GetActiveAuraCount(MMF_TargetFrame.BuffContainer))
    LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, size, GetActiveAuraCount(MMF_TargetFrame.DebuffContainer))
    if MMF_UpdateTargetAuras then
        MMF_UpdateTargetAuras()
    end
end

function MMF_UpdateBuffPosition(x, y)
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end
    ApplyAuraContainerPosition(MMF_TargetFrame.BuffContainer, false, x, y)
    if MMF_UpdateAuraLayout then
        MMF_UpdateAuraLayout()
    end
end

function MMF_UpdateDebuffPosition(x, y)
    if not MMF_TargetFrame or not MMF_TargetFrame.DebuffContainer then return end
    ApplyAuraContainerPosition(MMF_TargetFrame.DebuffContainer, true, x, y)
    if MMF_UpdateAuraLayout then
        MMF_UpdateAuraLayout()
    end
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

        local unit = self.auraUnit or "target"
        local tooltipSet = false

        if self.auraInstanceID and GameTooltip.SetUnitAuraByAuraInstanceID then
            tooltipSet = GameTooltip:SetUnitAuraByAuraInstanceID(unit, self.auraInstanceID, self.auraFilter) and true or false
        end
        if not tooltipSet and self.auraIndex then
            tooltipSet = GameTooltip:SetUnitAura(unit, self.auraIndex, self.auraFilter) and true or false
        end

        if tooltipSet then
            GameTooltip:Show()
        else
            GameTooltip:Hide()
        end
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
        ApplyAuraContainerPosition(container, true, MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset())
    else
        ApplyAuraContainerPosition(container, false, MMF_GetBuffXOffset(), MMF_GetBuffYOffset())
    end

    container.auras = {}
    for i = 1, MAX_AURA_ICONS do
        container.auras[i] = CreateAuraIcon(container, i, isDebuff, iconSize)
    end

    LayoutAuraContainer(container, isDebuff, iconSize, 1)

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
    local auraInstanceID = NotSecretValue(auraData and auraData.auraInstanceID) and auraData.auraInstanceID or nil

    auraFrame.icon:SetTexture(auraData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    auraFrame.auraData = auraData
    auraFrame.auraIndex = index or auraData._index
    auraFrame.auraFilter = filter
    auraFrame.auraUnit = unit
    auraFrame.auraInstanceID = auraInstanceID
    
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
    auraFrame.auraUnit = nil
    auraFrame.auraInstanceID = nil
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
            ClearAuraFrameState(aura)
            end
        end
end

local function IsPlayerOwnedDebuff(auraData)
    if type(auraData) ~= "table" then
        return false
    end

    local fromPlayerOrPet = nil
    if NotSecretValue(auraData.isFromPlayerOrPlayerPet) then
        fromPlayerOrPet = auraData.isFromPlayerOrPlayerPet
    elseif NotSecretValue(auraData.isFromPlayerOrPet) then
        fromPlayerOrPet = auraData.isFromPlayerOrPet
    elseif NotSecretValue(auraData.castByPlayer) then
        fromPlayerOrPet = auraData.castByPlayer
    elseif NotSecretValue(auraData.isPlayerAura) then
        fromPlayerOrPet = auraData.isPlayerAura
    end
    if fromPlayerOrPet then
        return true
    end

    local sourceUnit = nil
    if NotSecretValue(auraData.sourceUnit) then
        sourceUnit = auraData.sourceUnit
    elseif NotSecretValue(auraData.source) then
        sourceUnit = auraData.source
    elseif NotSecretValue(auraData.caster) then
        sourceUnit = auraData.caster
    end

    return sourceUnit == "player" or sourceUnit == "pet" or sourceUnit == "vehicle"
end

local function GetRetailPlayerDebuffs(unit)
    local debuffs = GetUnitAuras(unit, "HARMFUL|PLAYER")
    if debuffs and #debuffs > 0 then
        return debuffs
    end

    if type(UnitDebuff) ~= "function" then
        return debuffs or {}
    end

    local fallback = {}
    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, source, _, _, spellId = UnitDebuff(unit, i, "PLAYER")
        if not name then
            break
        end
        fallback[#fallback + 1] = {
            name = name,
            icon = icon,
            count = count,
            debuffType = debuffType,
            duration = duration,
            expirationTime = expirationTime,
            source = source,
            spellId = spellId,
            _index = i,
        }
    end

    return fallback
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
            LayoutAuraContainer(buffContainer, false, MMF_GetAuraIconSize(), math.min(16, GetVisibleAuraLimit()))
        end

        local debuffContainer = MMF_TargetFrame.DebuffContainer
        if MattMinimalFramesDB.showDebuffs == false then
            debuffContainer:Hide()
        else
            debuffContainer:Show()
            PopulateFakeAuras(debuffContainer, true)
            LayoutAuraContainer(debuffContainer, true, MMF_GetAuraIconSize(), math.min(16, GetVisibleAuraLimit()))
        end
        return
    end

    SetAuraTestPreviewFrameState(false)

    local unit = "target"
    if type(UnitExists) == "function" and not UnitExists(unit) then
        ClearAuraContainer(MMF_TargetFrame.BuffContainer)
        ClearAuraContainer(MMF_TargetFrame.DebuffContainer)
        return
    end

    local buffs = GetUnitAuras(unit, "HELPFUL")
    local debuffs = nil
    if MattMinimalFramesDB.onlyShowPlayerDebuffsOnTarget == true and HasRetailAuraAPI then
        debuffs = GetRetailPlayerDebuffs(unit)
    else
        debuffs = GetUnitAuras(unit, "HARMFUL")
    end
    local buffContainer = MMF_TargetFrame.BuffContainer
    if MattMinimalFramesDB.showBuffs == false then
        buffContainer:Hide()
    else
        buffContainer:Show()
        ClearAuraContainer(buffContainer)
        local shownBuffs = math.min(#buffs, GetVisibleAuraLimit())
        for i = 1, shownBuffs do
            local auraFrame = buffContainer.auras[i]
            if auraFrame then
                UpdateAuraIcon(auraFrame, buffs[i], "HELPFUL", unit, i)
            end
        end
        LayoutAuraContainer(buffContainer, false, MMF_GetAuraIconSize(), shownBuffs)
    end
    local debuffContainer = MMF_TargetFrame.DebuffContainer
    if MattMinimalFramesDB.showDebuffs == false then
        debuffContainer:Hide()
    else
        debuffContainer:Show()
        ClearAuraContainer(debuffContainer)

        local debuffsToDisplay = debuffs
        if MattMinimalFramesDB.onlyShowPlayerDebuffsOnTarget == true and not HasRetailAuraAPI then
            debuffsToDisplay = {}
            for i = 1, #debuffs do
                local auraData = debuffs[i]
                if IsPlayerOwnedDebuff(auraData) then
                    debuffsToDisplay[#debuffsToDisplay + 1] = auraData
                end
            end
        end

        local shownDebuffs = math.min(#debuffsToDisplay, GetVisibleAuraLimit())
        for i = 1, shownDebuffs do
            local auraFrame = debuffContainer.auras[i]
            if auraFrame then
                local debuffData = debuffsToDisplay[i]
                UpdateAuraIcon(auraFrame, debuffData, "HARMFUL", unit, i)
                if auraFrame.border then
                    local dispelName = debuffData.dispelName or debuffData.debuffType
                    if NotSecretValue(dispelName) then
                        local color = DebuffTypeColor and DebuffTypeColor[dispelName or "none"] or {r=1,g=1,b=1}
                        auraFrame.border:SetVertexColor(color.r, color.g, color.b)
                    else
                        auraFrame.border:SetVertexColor(1, 1, 1)
                    end
                end
            end
        end
        LayoutAuraContainer(debuffContainer, true, MMF_GetAuraIconSize(), shownDebuffs)
    end
end

--------------------------------------------------
-- AURA EVENTS
--------------------------------------------------

local auraEventFrame = CreateFrame("Frame")
auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
auraEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
auraEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
auraEventFrame:RegisterEvent("UNIT_AURA")
auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
auraEventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        MMF_SetupTargetAuras()
        MMF_UpdateTargetAuras()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        MMF_UpdateTargetAuras()
    elseif event == "UNIT_AURA" and unit == "target" then
        MMF_UpdateTargetAuras()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if MMF_TargetFrame then
            ClearAuraContainer(MMF_TargetFrame.BuffContainer)
            ClearAuraContainer(MMF_TargetFrame.DebuffContainer)
        end
        MMF_UpdateTargetAuras()
    end
end)
