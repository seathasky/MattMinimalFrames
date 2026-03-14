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

local function GetAuraUnitPrefix(unitToken)
    if unitToken == "player" then
        return "player"
    end
    return "target"
end

local function GetAuraIconSizeForType(isDebuff, unitToken)
    local db = MattMinimalFramesDB or {}
    local prefix = GetAuraUnitPrefix(unitToken)
    local key = (prefix == "player")
        and (isDebuff and "playerDebuffAuraIconSize" or "playerBuffAuraIconSize")
        or (isDebuff and "debuffAuraIconSize" or "buffAuraIconSize")
    local size = math.floor(tonumber(db[key]) or tonumber(db.auraIconSize) or MMF_GetAuraIconSize() or 18)
    if size < 12 then size = 12 end
    if size > 40 then size = 40 end
    return size
end

local function GetAuraIconsPerRow(isDebuff, unitToken)
    local db = MattMinimalFramesDB or {}
    local prefix = GetAuraUnitPrefix(unitToken)
    local key = (prefix == "player")
        and (isDebuff and "playerDebuffAuraIconsPerRow" or "playerBuffAuraIconsPerRow")
        or (isDebuff and "debuffAuraIconsPerRow" or "buffAuraIconsPerRow")
    local perRow = math.floor(tonumber(db[key]) or tonumber(db.auraIconsPerRow) or cfg.AURA_ROW_ICONS or 4)
    if perRow < 1 then perRow = 1 end
    if perRow > MAX_AURA_ICONS then perRow = MAX_AURA_ICONS end
    return perRow
end

local function GetAuraRows(isDebuff, unitToken)
    local db = MattMinimalFramesDB or {}
    local prefix = GetAuraUnitPrefix(unitToken)
    local key = (prefix == "player")
        and (isDebuff and "playerDebuffAuraRows" or "playerBuffAuraRows")
        or (isDebuff and "debuffAuraRows" or "buffAuraRows")
    local rows = math.floor(tonumber(db[key]) or tonumber(db.auraRows) or 3)
    if rows < 1 then rows = 1 end
    if rows > MAX_AURA_ICONS then rows = MAX_AURA_ICONS end
    return rows
end

local function GetVisibleAuraLimit(isDebuff, unitToken)
    return math.min(MAX_AURA_ICONS, GetAuraIconsPerRow(isDebuff, unitToken) * GetAuraRows(isDebuff, unitToken))
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

local function GetAuraDirectionValue(isDebuff, unitToken)
    local db = MattMinimalFramesDB or {}
    if unitToken == "player" then
        if isDebuff then
            return NormalizeAuraDirection(db.playerDebuffAuraDirection, "left_up")
        end
        return NormalizeAuraDirection(db.playerBuffAuraDirection, "right_down")
    end
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
    local ownerFrame = container and container.mmfAuraOwnerFrame
    if not ownerFrame then
        local unitToken = container and container.mmfAuraUnit
        if unitToken == "player" then
            ownerFrame = MMF_PlayerFrame
        else
            ownerFrame = MMF_TargetFrame
        end
    end
    if not ownerFrame then
        return
    end

    local unitToken = container and container.mmfAuraUnit or "target"
    local defaultX, defaultY
    if unitToken == "player" then
        defaultX = isDebuff and -2 or 2
        defaultY = isDebuff and 27 or -6
    else
        defaultX = isDebuff and 3 or -2
        defaultY = isDebuff and 27 or -6
    end
    local offsetX = tonumber(x) or defaultX
    local offsetY = tonumber(y) or defaultY

    container:ClearAllPoints()
    if unitToken == "player" then
        if isDebuff then
            container:SetPoint("TOPRIGHT", ownerFrame, "TOPRIGHT", offsetX, offsetY)
        else
            container:SetPoint("TOPLEFT", ownerFrame, "BOTTOMLEFT", offsetX, offsetY)
        end
    else
        if isDebuff then
            container:SetPoint("TOPLEFT", ownerFrame, "TOPLEFT", offsetX, offsetY)
        else
            container:SetPoint("TOPRIGHT", ownerFrame, "BOTTOMRIGHT", offsetX, offsetY)
        end
    end
end

local function IsAuraDragModeEnabled()
    local db = MattMinimalFramesDB or {}
    return (db.unlockFramesEditMode == true)
        or (db.layoutTestMode == true)
        or (db.auraTestMode == true)
end

local function CanStartAuraContainerDrag(container)
    if not container then
        return false
    end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return false
    end
    if not IsAuraDragModeEnabled() then
        return false
    end
    local db = MattMinimalFramesDB or {}
    if db.unlockFramesEditMode == true then
        return true
    end
    return type(IsShiftKeyDown) == "function" and IsShiftKeyDown() == true
end

local function GetAuraOffsetKeysForContainer(container, isDebuff)
    local unitToken = (container and container.mmfAuraUnit) or "target"
    if unitToken == "player" then
        if isDebuff then
            return "playerDebuffXOffset", "playerDebuffYOffset", -2, 27
        end
        return "playerBuffXOffset", "playerBuffYOffset", 2, -6
    end
    if isDebuff then
        return "debuffXOffset", "debuffYOffset", 3, 27
    end
    return "buffXOffset", "buffYOffset", -2, -6
end

local function GetAuraDirectionKeyForContainer(container, isDebuff)
    local unitToken = (container and container.mmfAuraUnit) or "target"
    if unitToken == "player" then
        return isDebuff and "playerDebuffAuraDirection" or "playerBuffAuraDirection"
    end
    return isDebuff and "debuffAuraDirection" or "buffAuraDirection"
end

local function StartAuraContainerDrag(container)
    if container.mmfAuraDragging then
        return
    end

    local isDebuff = container.mmfAuraIsDebuff == true
    local xKey, yKey, defaultX, defaultY = GetAuraOffsetKeysForContainer(container, isDebuff)
    local db = MattMinimalFramesDB or {}
    local startX = tonumber(db[xKey]) or defaultX
    local startY = tonumber(db[yKey]) or defaultY
    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if scale <= 0 then
        scale = 1
    end
    local cursorX, cursorY = GetCursorPosition()

    container.mmfAuraDragState = {
        xKey = xKey,
        yKey = yKey,
        startOffsetX = startX,
        startOffsetY = startY,
        startCursorX = (cursorX or 0) / scale,
        startCursorY = (cursorY or 0) / scale,
    }
    container.mmfAuraDragging = true
    container:SetScript("OnUpdate", function(self)
        local state = self.mmfAuraDragState
        if not state then
            return
        end
        local s = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
        if s <= 0 then
            s = 1
        end
        local cx, cy = GetCursorPosition()
        local dx = ((cx or 0) / s) - state.startCursorX
        local dy = ((cy or 0) / s) - state.startCursorY
        local newX = math.floor((state.startOffsetX + dx) + 0.5)
        local newY = math.floor((state.startOffsetY + dy) + 0.5)
        MattMinimalFramesDB[state.xKey] = newX
        MattMinimalFramesDB[state.yKey] = newY
        ApplyAuraContainerPosition(self, self.mmfAuraIsDebuff == true, newX, newY)
    end)
end

local function StopAuraContainerDrag(container)
    if not container then
        return
    end
    container.mmfAuraDragging = nil
    container:SetScript("OnUpdate", nil)
    container.mmfAuraDragState = nil
    container.mmfSuppressClickPopup = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, function()
            if container then
                container.mmfSuppressClickPopup = nil
            end
        end)
    else
        container.mmfSuppressClickPopup = nil
    end
    if MMF_UpdateAuraLayout then
        MMF_UpdateAuraLayout()
    elseif MMF_UpdateTargetAuras then
        MMF_UpdateTargetAuras()
        if MMF_UpdatePlayerAuras then
            MMF_UpdatePlayerAuras()
        end
    end
end

local function IsAuraEditModeActive()
    local db = MattMinimalFramesDB or {}
    return db.unlockFramesEditMode == true
end

local function EnsureAuraOptionsPopup()
    if _G.MMF_AuraOptionsPopup then
        return _G.MMF_AuraOptionsPopup
    end

    local popup = CreateFrame("Frame", "MMF_AuraOptionsPopup", UIParent, "BackdropTemplate")
    popup:SetSize(230, 112)
    popup:SetFrameStrata("DIALOG")
    popup:SetToplevel(true)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.04, 0.04, 0.05, 0.72)
    popup:SetBackdropBorderColor(0.1, 0.1, 0.12, 0.9)
    popup:Hide()

    local title = popup:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(title, "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    else
        title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    end
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetTextColor(1, 1, 1)
    title:SetText("Aura Options")
    popup.title = title

    local close = CreateFrame("Button", nil, popup)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -6, -6)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(closeText, "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    else
        closeText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    end
    closeText:SetPoint("CENTER")
    closeText:SetTextColor(0.8, 0.8, 0.8)
    closeText:SetText("x")
    close:SetScript("OnClick", function() popup:Hide() end)

    local function CreatePopupButton(yOffset, label)
        local btn = CreateFrame("Button", nil, popup, "BackdropTemplate")
        btn:SetSize(206, 24)
        btn:SetPoint("TOP", popup, "TOP", 0, yOffset)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
        btn:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        local txt = btn:CreateFontString(nil, "OVERLAY")
        if MMF_SetFontSafe then
            MMF_SetFontSafe(txt, "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        else
            txt:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        end
        txt:SetPoint("CENTER")
        txt:SetTextColor(0.9, 0.9, 0.9)
        txt:SetText(label)
        return btn
    end

    popup.resetPositionBtn = CreatePopupButton(-28, "Reset Aura Position")
    popup.resetDirectionBtn = CreatePopupButton(-58, "Reset Aura Direction")
    _G.MMF_AuraOptionsPopup = popup
    return popup
end

local function ResetAuraContainerToDefaults(container)
    if not container then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    local isDebuff = container.mmfAuraIsDebuff == true
    local xKey, yKey, defaultX, defaultY = GetAuraOffsetKeysForContainer(container, isDebuff)
    local directionKey = GetAuraDirectionKeyForContainer(container, isDebuff)
    local defaults = MattMinimalFrames_Defaults or {}

    MattMinimalFramesDB[xKey] = tonumber(defaults[xKey]) or defaultX
    MattMinimalFramesDB[yKey] = tonumber(defaults[yKey]) or defaultY
    if defaults[directionKey] ~= nil then
        MattMinimalFramesDB[directionKey] = defaults[directionKey]
    end
end

local function ResetAuraContainerDirectionToDefault(container)
    if not container then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    local isDebuff = container.mmfAuraIsDebuff == true
    local directionKey = GetAuraDirectionKeyForContainer(container, isDebuff)
    local defaults = MattMinimalFrames_Defaults or {}
    if defaults[directionKey] ~= nil then
        MattMinimalFramesDB[directionKey] = defaults[directionKey]
    end
end

local function RefreshAuraContainers()
    if MMF_UpdateAuraLayout then
        MMF_UpdateAuraLayout()
    elseif MMF_UpdateTargetAuras then
        MMF_UpdateTargetAuras()
        if MMF_UpdatePlayerAuras then
            MMF_UpdatePlayerAuras()
        end
    end
end

local function ShowAuraContainerOptionsPopup(container)
    if not container or not IsAuraEditModeActive() then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    local popup = EnsureAuraOptionsPopup()
    local unitToken = (container.mmfAuraUnit == "player") and "Player" or "Target"
    local auraType = (container.mmfAuraIsDebuff == true) and "Debuffs" or "Buffs"
    popup.title:SetText(unitToken .. " " .. auraType .. " Options")

    popup.resetPositionBtn:SetScript("OnClick", function()
        ResetAuraContainerToDefaults(container)
        RefreshAuraContainers()
        popup:Hide()
    end)
    popup.resetDirectionBtn:SetScript("OnClick", function()
        ResetAuraContainerDirectionToDefault(container)
        RefreshAuraContainers()
        popup:Hide()
    end)

    popup:ClearAllPoints()
    popup:SetPoint("TOP", container, "BOTTOM", 0, -8)
    popup:Show()
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

local function IsAuraFakePreviewEnabled()
    local db = MattMinimalFramesDB or {}
    if db.auraTestMode == true then
        return IsAuraTestModeEnabled()
    end
    return (db.unlockFramesEditMode == true) or (db.layoutTestMode == true)
end

local function IsAuraLabelPreviewEnabled()
    local db = MattMinimalFramesDB or {}
    return (db.auraTestMode == true)
        or (db.unlockFramesEditMode == true)
        or (db.layoutTestMode == true)
end

local function UpdateAuraContainerLabel(container, shouldShow)
    if not container or not container.mmfAuraLabel then
        return
    end
    if shouldShow and container:IsShown() then
        container.mmfAuraLabel:Show()
    else
        container.mmfAuraLabel:Hide()
    end
end

local function SetBlizzardAuraFrameVisible(frame, visible)
    if not frame then
        return
    end

    if visible then
        frame:SetAlpha(1)
        frame:SetScale(1)
        frame:EnableMouse(true)
        frame:Show()
    else
        frame:SetAlpha(0)
        frame:SetScale(0.0001)
        frame:EnableMouse(false)
        frame:Show()
    end
end

function MMF_UpdateBlizzardPlayerAuraVisibility()
    local db = MattMinimalFramesDB or {}
    local hideBuffs = (db.hideBlizzardPlayerBuffs == true)
    local hideDebuffs = (db.hideBlizzardPlayerDebuffs == true)

    SetBlizzardAuraFrameVisible(_G.BuffFrame, not hideBuffs)
    SetBlizzardAuraFrameVisible(_G.TemporaryEnchantFrame, not hideBuffs)
    SetBlizzardAuraFrameVisible(_G.DebuffFrame, not hideDebuffs)

    if type(BuffFrame_UpdateAllBuffAnchors) == "function" then
        pcall(BuffFrame_UpdateAllBuffAnchors)
    end
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

    local unitToken = (container and container.mmfAuraUnit) or "target"
    local iconSize = math.floor(tonumber(size) or GetAuraIconSizeForType(isDebuff, unitToken) or 18)
    local perRow = GetAuraIconsPerRow(isDebuff, unitToken)
    local rows = GetAuraRows(isDebuff, unitToken)

    container:SetSize(
        (iconSize + AURA_ICON_SPACING) * perRow - AURA_ICON_SPACING,
        (iconSize + AURA_ICON_SPACING) * rows - AURA_ICON_SPACING
    )

    local direction = GetAuraDirectionConfig(GetAuraDirectionValue(isDebuff, unitToken))
    local hSign = direction.horizontalSign
    local vSign = direction.verticalSign
    local primary = direction.primary
    local step = iconSize + AURA_ICON_SPACING

    local visibleLimit = GetVisibleAuraLimit(isDebuff, unitToken)
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

    local basePoint
    if unitToken == "player" then
        basePoint = isDebuff and "TOPRIGHT" or "TOPLEFT"
    else
        basePoint = isDebuff and "TOPLEFT" or "TOPRIGHT"
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

    if container.mmfAuraLabel then
        container.mmfAuraLabel:ClearAllPoints()
        if isDebuff then
            local extraAbove = 0
            if vSign > 0 then
                extraAbove = math.max(0, (effectiveRows - 1) * step)
            end
            container.mmfAuraLabel:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 6 + extraAbove)
        else
            container.mmfAuraLabel:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -3)
        end
    end
end

--------------------------------------------------
-- UPDATE FUNCTIONS (called from popup sliders)
--------------------------------------------------

function MMF_UpdateAuraTextScale(scale)
    if not MMF_TargetFrame and not MMF_PlayerFrame then return end
    
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
    
    if MMF_TargetFrame then
        updateContainer(MMF_TargetFrame.BuffContainer)
        updateContainer(MMF_TargetFrame.DebuffContainer)
    end
    if MMF_PlayerFrame then
        updateContainer(MMF_PlayerFrame.BuffContainer)
        updateContainer(MMF_PlayerFrame.DebuffContainer)
    end
end

function MMF_UpdateTimerTextScale(scale)
    if not MMF_TargetFrame and not MMF_PlayerFrame then return end
    
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
    
    if MMF_TargetFrame then
        updateContainer(MMF_TargetFrame.BuffContainer)
        updateContainer(MMF_TargetFrame.DebuffContainer)
    end
    if MMF_PlayerFrame then
        updateContainer(MMF_PlayerFrame.BuffContainer)
        updateContainer(MMF_PlayerFrame.DebuffContainer)
    end
end

function MMF_UpdateAuraIconSize(size)
    if not MMF_TargetFrame then return end

    size = math.floor(size)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    MattMinimalFramesDB.auraIconSize = size
    LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, size, GetActiveAuraCount(MMF_TargetFrame.BuffContainer))
    LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, size, GetActiveAuraCount(MMF_TargetFrame.DebuffContainer))
    if MMF_PlayerFrame then
        LayoutAuraContainer(MMF_PlayerFrame.BuffContainer, false, size, GetActiveAuraCount(MMF_PlayerFrame.BuffContainer))
        LayoutAuraContainer(MMF_PlayerFrame.DebuffContainer, true, size, GetActiveAuraCount(MMF_PlayerFrame.DebuffContainer))
    end
end

function MMF_UpdateAuraLayout()
    if not MMF_TargetFrame and not MMF_PlayerFrame then
        return
    end
    if MMF_TargetFrame.BuffContainer then
        ApplyAuraContainerPosition(MMF_TargetFrame.BuffContainer, false, MMF_GetBuffXOffset(), MMF_GetBuffYOffset())
    end
    if MMF_TargetFrame.DebuffContainer then
        ApplyAuraContainerPosition(MMF_TargetFrame.DebuffContainer, true, MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset())
    end
    if MMF_PlayerFrame and MMF_PlayerFrame.BuffContainer then
        ApplyAuraContainerPosition(MMF_PlayerFrame.BuffContainer, false, MattMinimalFramesDB and MattMinimalFramesDB.playerBuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.playerBuffYOffset)
    end
    if MMF_PlayerFrame and MMF_PlayerFrame.DebuffContainer then
        ApplyAuraContainerPosition(MMF_PlayerFrame.DebuffContainer, true, MattMinimalFramesDB and MattMinimalFramesDB.playerDebuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.playerDebuffYOffset)
    end
    if MMF_TargetFrame then
        LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, nil, GetActiveAuraCount(MMF_TargetFrame.BuffContainer))
        LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, nil, GetActiveAuraCount(MMF_TargetFrame.DebuffContainer))
    end
    if MMF_PlayerFrame then
        LayoutAuraContainer(MMF_PlayerFrame.BuffContainer, false, nil, GetActiveAuraCount(MMF_PlayerFrame.BuffContainer))
        LayoutAuraContainer(MMF_PlayerFrame.DebuffContainer, true, nil, GetActiveAuraCount(MMF_PlayerFrame.DebuffContainer))
    end
    if MMF_UpdateTargetAuras then MMF_UpdateTargetAuras() end
    if MMF_UpdatePlayerAuras then MMF_UpdatePlayerAuras() end
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

function MMF_UpdatePlayerBuffPosition(x, y)
    if not MMF_PlayerFrame or not MMF_PlayerFrame.BuffContainer then return end
    ApplyAuraContainerPosition(MMF_PlayerFrame.BuffContainer, false, x, y)
    if MMF_UpdateAuraLayout then
        MMF_UpdateAuraLayout()
    end
end

function MMF_UpdatePlayerDebuffPosition(x, y)
    if not MMF_PlayerFrame or not MMF_PlayerFrame.DebuffContainer then return end
    ApplyAuraContainerPosition(MMF_PlayerFrame.DebuffContainer, true, x, y)
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
    aura:EnableMouse(true)
    aura:RegisterForDrag("LeftButton")

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
    aura:SetScript("OnDragStart", function(self)
        local container = self and self:GetParent()
        if CanStartAuraContainerDrag(container) then
            StartAuraContainerDrag(container)
        end
    end)
    aura:SetScript("OnDragStop", function(self)
        local container = self and self:GetParent()
        StopAuraContainerDrag(container)
    end)
    aura:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then
            return
        end
        local container = self and self:GetParent()
        if not container then
            return
        end
        if container.mmfAuraDragging or container.mmfSuppressClickPopup then
            return
        end
        ShowAuraContainerOptionsPopup(container)
    end)
    
    aura:Hide()
    return aura
end

--------------------------------------------------
-- CONTAINER SETUP
--------------------------------------------------

local function CreateAuraContainer(parent, isDebuff, unitToken)
    local iconSize = GetAuraIconSizeForType(isDebuff, unitToken)

    local container = CreateFrame("Frame", nil, parent)
    container.mmfAuraUnit = unitToken
    container.mmfAuraOwnerFrame = parent
    container.mmfAuraIsDebuff = isDebuff
    container:SetMovable(true)
    container:EnableMouse(true)
    container:RegisterForDrag("LeftButton")

    if isDebuff then
        if unitToken == "player" then
            ApplyAuraContainerPosition(container, true, MattMinimalFramesDB and MattMinimalFramesDB.playerDebuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.playerDebuffYOffset)
        else
            ApplyAuraContainerPosition(container, true, MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset())
        end
    else
        if unitToken == "player" then
            ApplyAuraContainerPosition(container, false, MattMinimalFramesDB and MattMinimalFramesDB.playerBuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.playerBuffYOffset)
        else
            ApplyAuraContainerPosition(container, false, MMF_GetBuffXOffset(), MMF_GetBuffYOffset())
        end
    end

    container.auras = {}
    for i = 1, MAX_AURA_ICONS do
        container.auras[i] = CreateAuraIcon(container, i, isDebuff, iconSize)
    end

    LayoutAuraContainer(container, isDebuff, iconSize, 1)

    local label = container:CreateFontString(nil, "OVERLAY")
    label:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "OUTLINE")
    if isDebuff then
        label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 6)
    else
        label:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -3)
    end
    local unitPrefix = (unitToken == "player") and "PLAYER " or "TARGET "
    label:SetText(unitPrefix .. (isDebuff and "DEBUFFS" or "BUFFS"))
    label:SetTextColor(0.95, 0.96, 0.98)
    label:SetShadowColor(0, 0, 0, 1)
    label:SetShadowOffset(1, -1)
    label:SetDrawLayer("OVERLAY", 7)
    label:Hide()
    container.mmfAuraLabel = label

    container:HookScript("OnShow", function(self)
        UpdateAuraContainerLabel(self, IsAuraLabelPreviewEnabled())
    end)
    container:HookScript("OnHide", function(self)
        UpdateAuraContainerLabel(self, false)
    end)
    container:SetScript("OnDragStart", function(self)
        if CanStartAuraContainerDrag(self) then
            StartAuraContainerDrag(self)
        end
    end)
    container:SetScript("OnDragStop", function(self)
        StopAuraContainerDrag(self)
    end)
    container:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then
            return
        end
        if self.mmfAuraDragging or self.mmfSuppressClickPopup then
            return
        end
        ShowAuraContainerOptionsPopup(self)
    end)

    return container
end

function MMF_SetupTargetAuras()
    if MMF_TargetFrame then
        MMF_TargetFrame.BuffContainer = CreateAuraContainer(MMF_TargetFrame, false, "target")
        MMF_TargetFrame.DebuffContainer = CreateAuraContainer(MMF_TargetFrame, true, "target")
    end
    if MMF_PlayerFrame then
        MMF_PlayerFrame.BuffContainer = CreateAuraContainer(MMF_PlayerFrame, false, "player")
        MMF_PlayerFrame.DebuffContainer = CreateAuraContainer(MMF_PlayerFrame, true, "player")
    end
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

    local unitToken = (container and container.mmfAuraUnit) or "target"
    local fakeCount = GetVisibleAuraLimit(isDebuff, unitToken)
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

local function UpdateUnitAuras(unit)
    local frame = (unit == "player") and MMF_PlayerFrame or MMF_TargetFrame
    if not frame or not frame.BuffContainer or not frame.DebuffContainer then return end

    local db = MattMinimalFramesDB or {}
    local showLabels = IsAuraLabelPreviewEnabled()
    local showBuffsKey = (unit == "player") and "showPlayerBuffs" or "showBuffs"
    local showDebuffsKey = (unit == "player") and "showPlayerDebuffs" or "showDebuffs"

    if IsAuraFakePreviewEnabled() then
        local forcePlayerPreview = (unit == "player")
        if unit == "target" then
            SetAuraTestPreviewFrameState(true)
        end
        local buffContainer = frame.BuffContainer
        if not forcePlayerPreview and db[showBuffsKey] == false then
            buffContainer:Hide()
            UpdateAuraContainerLabel(buffContainer, false)
        else
            buffContainer:Show()
            PopulateFakeAuras(buffContainer, false)
            LayoutAuraContainer(buffContainer, false, nil, math.min(16, GetVisibleAuraLimit(false, unit)))
            UpdateAuraContainerLabel(buffContainer, showLabels)
        end

        local debuffContainer = frame.DebuffContainer
        if not forcePlayerPreview and db[showDebuffsKey] == false then
            debuffContainer:Hide()
            UpdateAuraContainerLabel(debuffContainer, false)
        else
            debuffContainer:Show()
            PopulateFakeAuras(debuffContainer, true)
            LayoutAuraContainer(debuffContainer, true, nil, math.min(16, GetVisibleAuraLimit(true, unit)))
            UpdateAuraContainerLabel(debuffContainer, showLabels)
        end
        return
    end

    if unit == "target" then
        SetAuraTestPreviewFrameState(false)
    end

    if type(UnitExists) == "function" and not UnitExists(unit) then
        ClearAuraContainer(frame.BuffContainer)
        ClearAuraContainer(frame.DebuffContainer)
        UpdateAuraContainerLabel(frame.BuffContainer, false)
        UpdateAuraContainerLabel(frame.DebuffContainer, false)
        return
    end

    local buffs = GetUnitAuras(unit, "HELPFUL")
    local debuffs = nil
    if unit == "target" and db.onlyShowPlayerDebuffsOnTarget == true and HasRetailAuraAPI then
        debuffs = GetRetailPlayerDebuffs(unit)
    else
        debuffs = GetUnitAuras(unit, "HARMFUL")
    end

    local buffContainer = frame.BuffContainer
    if db[showBuffsKey] == false then
        buffContainer:Hide()
        UpdateAuraContainerLabel(buffContainer, false)
    else
        buffContainer:Show()
        ClearAuraContainer(buffContainer)
        local shownBuffs = math.min(#buffs, GetVisibleAuraLimit(false, unit))
        for i = 1, shownBuffs do
            local auraFrame = buffContainer.auras[i]
            if auraFrame then
                UpdateAuraIcon(auraFrame, buffs[i], "HELPFUL", unit, i)
            end
        end
        LayoutAuraContainer(buffContainer, false, nil, shownBuffs)
        UpdateAuraContainerLabel(buffContainer, showLabels)
    end

    local debuffContainer = frame.DebuffContainer
    if db[showDebuffsKey] == false then
        debuffContainer:Hide()
        UpdateAuraContainerLabel(debuffContainer, false)
    else
        debuffContainer:Show()
        ClearAuraContainer(debuffContainer)

        local debuffsToDisplay = debuffs
        if unit == "target" and db.onlyShowPlayerDebuffsOnTarget == true and not HasRetailAuraAPI then
            debuffsToDisplay = {}
            for i = 1, #debuffs do
                local auraData = debuffs[i]
                if IsPlayerOwnedDebuff(auraData) then
                    debuffsToDisplay[#debuffsToDisplay + 1] = auraData
                end
            end
        end

        local shownDebuffs = math.min(#debuffsToDisplay, GetVisibleAuraLimit(true, unit))
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
        LayoutAuraContainer(debuffContainer, true, nil, shownDebuffs)
        UpdateAuraContainerLabel(debuffContainer, showLabels)
    end
end

function MMF_UpdateTargetAuras()
    UpdateUnitAuras("target")
end

function MMF_UpdatePlayerAuras()
    UpdateUnitAuras("player")
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
auraEventFrame:RegisterEvent("SPELLS_CHANGED")
auraEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
auraEventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        MMF_SetupTargetAuras()
        MMF_UpdateBlizzardPlayerAuraVisibility()
        MMF_UpdateTargetAuras()
        MMF_UpdatePlayerAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        MMF_UpdateTargetAuras()
        MMF_UpdatePlayerAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "UNIT_AURA" and unit == "target" then
        MMF_UpdateTargetAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "UNIT_AURA" and unit == "player" then
        MMF_UpdateBlizzardPlayerAuraVisibility()
        MMF_UpdatePlayerAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if MMF_TargetFrame then
            ClearAuraContainer(MMF_TargetFrame.BuffContainer)
            ClearAuraContainer(MMF_TargetFrame.DebuffContainer)
        end
        MMF_UpdateTargetAuras()
        MMF_UpdatePlayerAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    end
end)
