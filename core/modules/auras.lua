local Compat = _G.MMF_Compat
local cfg = MMF_Config
local AURA_ICON_SPACING = cfg.AURA_ICON_SPACING
local MAX_AURA_ICONS = cfg.MAX_AURA_ICONS
local AURA_ICON_CONTENT_INSET = 1
local AURA_DEBUFF_BORDER_OUTSET = 1
local GetUnitAuras = Compat.GetUnitAuras
local SetAuraCooldown = Compat.SetAuraCooldown
local GetAuraCount = Compat.GetAuraCount
local HasRetailAuraAPI = Compat.HasRetailAuraAPI
local UsesRestrictedAuraAPI = HasRetailAuraAPI and (
    (type(GetBuildOption) == "function" and GetBuildOption("RestrictedAuraAPI") == true)
    or (C_Secrets and type(C_Secrets.HasSecretRestrictions) == "function" and C_Secrets.HasSecretRestrictions())
)

local issecretvalue = issecretvalue

local function ShouldSuspendForBlizzardEditMode()
    return _G.MMF_ShouldSuspendForBlizzardEditMode and _G.MMF_ShouldSuspendForBlizzardEditMode() == true
end





local function NotSecretValue(value)
    return not issecretvalue or not issecretvalue(value)
end

local function IsBossAuraUnit(unit)
    return NotSecretValue(unit) and type(unit) == "string" and unit:match("^boss[1-5]$") ~= nil
end

local function ShouldUseOmniCCAuraText()
    if not Compat.IsTBC or type(_G.OmniCC) ~= "table" then
        return false
    end

    return type(_G.OmniCC.Cooldown) == "table"
end

local function ConfigureOmniCCAuraText(cooldownFrame)
    local useOmniCC = ShouldUseOmniCCAuraText()
    cooldownFrame:SetHideCountdownNumbers(useOmniCC)

    if not useOmniCC then
        cooldownFrame._occ_settings_force = nil
        return false
    end

    local omniCC = _G.OmniCC
    if not cooldownFrame.mmfOmniCCSettings and type(omniCC.GetDefaultTheme) == "function" then
        local settings = omniCC:GetDefaultTheme()
        if settings then
            cooldownFrame.mmfOmniCCSettings = setmetatable({ minSize = 0 }, { __index = settings })
        end
    end
    cooldownFrame._occ_settings_force = cooldownFrame.mmfOmniCCSettings
    cooldownFrame._occ_settings = cooldownFrame.mmfOmniCCSettings
    return true
end

local function SetOmniCCAuraTimer(cooldownFrame, auraData)
    if not Compat.IsTBC then
        return
    end

    local omniCCCooldown = _G.OmniCC and _G.OmniCC.Cooldown
    if type(omniCCCooldown) ~= "table" or type(omniCCCooldown.SetTimer) ~= "function" then
        return
    end

    if type(omniCCCooldown.Initialize) == "function" then
        omniCCCooldown.Initialize(cooldownFrame)
    end

    local duration = tonumber(auraData and auraData.duration) or 0
    local expirationTime = tonumber(auraData and auraData.expirationTime) or 0
    if duration > 0 and expirationTime > 0 then
        omniCCCooldown.SetTimer(cooldownFrame, expirationTime - duration, duration, 1)
    else
        omniCCCooldown.SetTimer(cooldownFrame, 0, 0, 1)
    end
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
    auraFrame.isTemporaryEnchant = nil
    auraFrame.temporaryEnchantIndex = nil
    auraFrame.inventorySlot = nil

    if auraFrame.count then
        auraFrame.count:Hide()
    end
    if auraFrame.cooldown then
        auraFrame.cooldown:Clear()
    end
    if auraFrame.timerText then
        auraFrame.timerText:Hide()
    end

    auraFrame:EnableMouse(false)
    auraFrame:Hide()
end

local function ClearAuraContainer(container)
    if not container then
        return
    end
    
    
    if container.mmfSecureAuraContainer then
        return
    end
    if not container.auras then
        return
    end

    for _, aura in ipairs(container.auras) do
        ClearAuraFrameState(aura)
    end
end

local function GetAuraUnitPrefix(unitToken)
    if unitToken == "player" then
        return "player"
    elseif unitToken == "focus" then
        return "focus"
    end
    return "target"
end

local function GetAuraIconSizeForType(isDebuff, unitToken)
    if IsBossAuraUnit(unitToken) then return 18 end
    local db = MattMinimalFramesDB or {}
    local prefix = GetAuraUnitPrefix(unitToken)
    local key
    if prefix == "player" then
        key = isDebuff and "playerDebuffAuraIconSize" or "playerBuffAuraIconSize"
    elseif prefix == "focus" then
        key = isDebuff and "focusDebuffAuraIconSize" or "focusBuffAuraIconSize"
    else
        key = isDebuff and "debuffAuraIconSize" or "buffAuraIconSize"
    end
    local size = math.floor(tonumber(db[key]) or tonumber(db.auraIconSize) or MMF_GetAuraIconSize() or 18)
    if size < 12 then size = 12 end
    if size > 40 then size = 40 end
    return size
end

local function GetAuraIconsPerRow(isDebuff, unitToken)
    if IsBossAuraUnit(unitToken) then return MAX_AURA_ICONS end
    local db = MattMinimalFramesDB or {}
    local prefix = GetAuraUnitPrefix(unitToken)
    local key
    if prefix == "player" then
        key = isDebuff and "playerDebuffAuraIconsPerRow" or "playerBuffAuraIconsPerRow"
    elseif prefix == "focus" then
        key = isDebuff and "focusDebuffAuraIconsPerRow" or "focusBuffAuraIconsPerRow"
    else
        key = isDebuff and "debuffAuraIconsPerRow" or "buffAuraIconsPerRow"
    end
    local perRow = math.floor(tonumber(db[key]) or tonumber(db.auraIconsPerRow) or cfg.AURA_ROW_ICONS or 4)
    if perRow < 1 then perRow = 1 end
    if perRow > MAX_AURA_ICONS then perRow = MAX_AURA_ICONS end
    return perRow
end

local function GetAuraRows(isDebuff, unitToken)
    if IsBossAuraUnit(unitToken) then return 1 end
    local db = MattMinimalFramesDB or {}
    local prefix = GetAuraUnitPrefix(unitToken)
    local key
    if prefix == "player" then
        key = isDebuff and "playerDebuffAuraRows" or "playerBuffAuraRows"
    elseif prefix == "focus" then
        key = isDebuff and "focusDebuffAuraRows" or "focusBuffAuraRows"
    else
        key = isDebuff and "debuffAuraRows" or "buffAuraRows"
    end
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
    if IsBossAuraUnit(unitToken) then return "left_down" end
    local db = MattMinimalFramesDB or {}

    if unitToken == "player" then
        if isDebuff then
            return NormalizeAuraDirection(db.playerDebuffAuraDirection, "left_up")
        end
        return NormalizeAuraDirection(db.playerBuffAuraDirection, "right_down")
    elseif unitToken == "focus" then
        if isDebuff then
            return NormalizeAuraDirection(db.focusDebuffAuraDirection, "right_up")
        end
        return NormalizeAuraDirection(db.focusBuffAuraDirection, "left_down")
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
        elseif unitToken == "focus" then
            ownerFrame = MMF_FocusFrame
        else
            ownerFrame = MMF_TargetFrame
        end
    end
    if not ownerFrame then
        return
    end

    local unitToken = container and container.mmfAuraUnit or "target"
    if IsBossAuraUnit(unitToken) then
        local scale = math.max(0.75, math.min(2.0, tonumber(MattMinimalFramesDB and MattMinimalFramesDB.bossDebuffIconScale) or 1.0))
        if container.mmfBossDebuffScale ~= scale then
            container:SetScale(scale)
            container.mmfBossDebuffScale = scale
        end
        container:ClearAllPoints()
        container:SetPoint("TOPRIGHT", ownerFrame, "LEFT", -6, GetAuraIconSizeForType(true, unitToken) * 0.5)
        return
    end
    local defaultX, defaultY
    if unitToken == "player" then
        defaultX = isDebuff and -2 or 2
        defaultY = isDebuff and 27 or -6
    elseif unitToken == "focus" then
        defaultX = isDebuff and 3 or -2
        defaultY = isDebuff and 27 or -6
    else
        defaultX = isDebuff and 3 or -2
        defaultY = isDebuff and 27 or -6
    end
    local offsetX = tonumber(x) or defaultX
    local offsetY = tonumber(y) or defaultY

    local anchorPoint
    local relativeTo = ownerFrame
    local relativePoint

    if unitToken == "player" then
        if isDebuff then
            anchorPoint = "TOPRIGHT"
            relativePoint = "TOPRIGHT"
        else
            anchorPoint = "TOPLEFT"
            relativePoint = "BOTTOMLEFT"
        end
    else
        if isDebuff then
            anchorPoint = "TOPLEFT"
            relativePoint = "TOPLEFT"
        else
            anchorPoint = "TOPRIGHT"
            relativePoint = "BOTTOMRIGHT"
        end
    end

    container:ClearAllPoints()
    container:SetPoint(anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
end

local function IsAuraDragModeEnabled()
    local db = MattMinimalFramesDB or {}
    return (db.unlockFramesEditMode == true)
        or (db.layoutTestMode == true)
        or (db.auraTestMode == true)
end

local function CanStartAuraContainerDrag(container)
    if MMF_Designer then return false end
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
    if db.enableTextDragInEditMode == true then
        return false
    end
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
    elseif unitToken == "focus" then
        if isDebuff then
            return "focusDebuffXOffset", "focusDebuffYOffset", 3, 27
        end
        return "focusBuffXOffset", "focusBuffYOffset", -2, -6
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
    elseif unitToken == "focus" then
        return isDebuff and "focusDebuffAuraDirection" or "focusBuffAuraDirection"
    end
    return isDebuff and "debuffAuraDirection" or "buffAuraDirection"
end

local function StartAuraContainerDrag(container)
    if container.mmfAuraDragging then
        return
    end
    local dragHelpers = _G.MMF_FrameFactoryDragHelpers or {}
    if dragHelpers.TryClaimDragOwner and not dragHelpers.TryClaimDragOwner(container, "aura container") then
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
    if not container.mmfAuraDragging then
        return
    end
    local dragHelpers = _G.MMF_FrameFactoryDragHelpers or {}
    if dragHelpers.ReleaseDragOwner then
        dragHelpers.ReleaseDragOwner(container)
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
        if MMF_UpdateFocusAuras then
            MMF_UpdateFocusAuras()
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
    MMF_SetFontSafe(title, MMF_GetDefaultFontPath(), 10, "")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetTextColor(1, 1, 1)
    title:SetText("Aura Options")
    popup.title = title

    local close = CreateFrame("Button", nil, popup)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -6, -6)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    MMF_SetFontSafe(closeText, MMF_GetDefaultFontPath(), 10, "")
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
        MMF_SetFontSafe(txt, MMF_GetDefaultFontPath(), 10, "")
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
        if MMF_UpdateFocusAuras then
            MMF_UpdateFocusAuras()
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
    local unitToken = "Target"
    if container.mmfAuraUnit == "player" then
        unitToken = "Player"
    elseif container.mmfAuraUnit == "focus" then
        unitToken = "Focus"
    end
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

local blizzardAuraVisibilityState = setmetatable({}, { __mode = "k" })
local eraBlizzardAuraVisibilityHooks = setmetatable({}, { __mode = "k" })

local function SetBlizzardAuraFrameVisible(frame, visible)
    if not frame then
        return
    end

    if visible then
        
        
        
        local state = blizzardAuraVisibilityState[frame]
        if state then
            frame:SetAlpha(state.alpha or 1)
            frame:SetScale(state.scale or 1)
            frame:EnableMouse(state.mouseEnabled ~= false)
            blizzardAuraVisibilityState[frame] = nil
        end
    else
        if not blizzardAuraVisibilityState[frame] then
            blizzardAuraVisibilityState[frame] = {
                alpha = frame:GetAlpha(),
                scale = frame:GetScale(),
                mouseEnabled = frame:IsMouseEnabled(),
            }
        end
        frame:SetAlpha(0)
        frame:SetScale(0.0001)
        frame:EnableMouse(false)
        frame:Show()
    end
end

local function EnsureEraBlizzardAuraVisibilityHook(frame, dbKey)
    
    
    
    if not Compat.IsClassic or not frame or eraBlizzardAuraVisibilityHooks[frame] then
        return
    end
    if type(hooksecurefunc) ~= "function" or type(frame.UpdateShownState) ~= "function" then
        return
    end

    local ok = pcall(hooksecurefunc, frame, "UpdateShownState", function(self)
        local db = MattMinimalFramesDB or {}
        SetBlizzardAuraFrameVisible(self, db[dbKey] ~= true)
    end)
    if ok then
        eraBlizzardAuraVisibilityHooks[frame] = true
    end
end

function MMF_UpdateBlizzardPlayerAuraVisibility()
    local db = MattMinimalFramesDB or {}
    local hideBuffs = (db.hideBlizzardPlayerBuffs == true)
    local hideDebuffs = (db.hideBlizzardPlayerDebuffs == true)

    EnsureEraBlizzardAuraVisibilityHook(_G.BuffFrame, "hideBlizzardPlayerBuffs")
    EnsureEraBlizzardAuraVisibilityHook(_G.DebuffFrame, "hideBlizzardPlayerDebuffs")

    SetBlizzardAuraFrameVisible(_G.BuffFrame, not hideBuffs)
    SetBlizzardAuraFrameVisible(_G.TemporaryEnchantFrame, not hideBuffs)
    SetBlizzardAuraFrameVisible(_G.DebuffFrame, not hideDebuffs)

    if Compat.IsClassic then

        if (not hideBuffs or not hideDebuffs) and type(_G.BuffFrame_Update) == "function" then
            pcall(_G.BuffFrame_Update)
        end
        if not hideBuffs and _G.BuffFrame and type(_G.BuffFrame.Update) == "function" then
            pcall(_G.BuffFrame.Update, _G.BuffFrame)
            if type(_G.BuffFrame.UpdateGridLayout) == "function" then
                pcall(_G.BuffFrame.UpdateGridLayout, _G.BuffFrame)
            end
        end
        if not hideDebuffs and _G.DebuffFrame and type(_G.DebuffFrame.Update) == "function" then
            pcall(_G.DebuffFrame.Update, _G.DebuffFrame)
            if type(_G.DebuffFrame.UpdateGridLayout) == "function" then
                pcall(_G.DebuffFrame.UpdateGridLayout, _G.DebuffFrame)
            end
        end
        if not hideDebuffs and type(_G.DebuffFrame_Update) == "function" then
            pcall(_G.DebuffFrame_Update)
        end
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
    if container and container.mmfSecureAuraContainer then
        return 0
    end
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

local function GetAuraOffsetsForUnit(unit, isDebuff)
    local db = MattMinimalFramesDB or {}
    if unit == "player" then
        if isDebuff then
            return db.playerDebuffXOffset, db.playerDebuffYOffset
        end
        return db.playerBuffXOffset, db.playerBuffYOffset
    elseif unit == "focus" then
        if isDebuff then
            return db.focusDebuffXOffset, db.focusDebuffYOffset
        end
        return db.focusBuffXOffset, db.focusBuffYOffset
    end
    if isDebuff then
        return MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset()
    end
    return MMF_GetBuffXOffset(), MMF_GetBuffYOffset()
end

local function ConfigureSecureAuraContainer(container, isDebuff)
    if MMF_Designer and MMF_Designer.ready and MMF_Designer.ConfigureAuraContainer then
        return MMF_Designer.ConfigureAuraContainer(container,isDebuff)
    end
    if not container or not container.mmfSecureAuraContainer then
        return
    end

    local unitToken = container.mmfAuraUnit or "target"
    local iconSize = GetAuraIconSizeForType(isDebuff, unitToken)
    local perRow = GetAuraIconsPerRow(isDebuff, unitToken)
    local rows = GetAuraRows(isDebuff, unitToken)
    local visibleLimit = GetVisibleAuraLimit(isDebuff, unitToken)
    local lineSize = (iconSize * perRow) + (AURA_ICON_SPACING * math.max(0, perRow - 1))
    local direction = GetAuraDirectionConfig(GetAuraDirectionValue(isDebuff, unitToken))
    local groupKey = container.mmfAuraGroupKey
    local filter


    local aurasAreSecret = C_Secrets
        and type(C_Secrets.ShouldAurasBeSecret) == "function"
        and C_Secrets.ShouldAurasBeSecret()
    if container.mmfAppliedIconSize ~= iconSize and not aurasAreSecret then
        local frameCount = container:GetAuraGroupFrameCount(groupKey)
        for frameIndex = 1, frameCount do
            local auraButton = container:GetAuraGroupFrame(groupKey, frameIndex)
            if auraButton then
                auraButton:SetSize(iconSize, iconSize)
            end
        end
        container.mmfAppliedIconSize = iconSize
    end

    if isDebuff then
        local db = MattMinimalFramesDB or {}
        filter = (IsBossAuraUnit(unitToken) or (unitToken == "target" and db.onlyShowPlayerDebuffsOnTarget == true))
            and "HARMFUL|PLAYER"
            or "HARMFUL"
    else
        filter = "HELPFUL"
    end

    container:SetAuraGroupFilterString(groupKey, filter)
    container:SetAuraGroupMaxFrameCount(groupKey, visibleLimit)
    local groupLayoutSignature = table.concat({
        tostring(AURA_ICON_SPACING),
        tostring(iconSize),
    }, ":")
    if container.mmfAuraGroupLayoutSignature ~= groupLayoutSignature then
        container:SetAuraGroupLayout(groupKey, {
            elementSpacing = AURA_ICON_SPACING,
            lineSpacing = AURA_ICON_SPACING,
            elementWidth = iconSize,
            elementHeight = iconSize,
        })
        container.mmfAuraGroupLayoutSignature = groupLayoutSignature
    end

    local horizontalDirection = direction.horizontalSign < 0
        and AnchorUtil.FlowDirection.Left
        or AnchorUtil.FlowDirection.Right
    local verticalDirection = direction.verticalSign > 0
        and AnchorUtil.FlowDirection.Up
        or AnchorUtil.FlowDirection.Down
    local layoutAxis = direction.primary == "vertical"
        and AnchorUtil.FlowLayoutAxis.Vertical
        or AnchorUtil.FlowLayoutAxis.Horizontal
    local maximumLineSize = lineSize
    if direction.primary == "vertical" then
        maximumLineSize = (iconSize * rows) + (AURA_ICON_SPACING * math.max(0, rows - 1))
    end
    local anchorPoint
    if unitToken == "player" or IsBossAuraUnit(unitToken) then
        anchorPoint = isDebuff and "TOPRIGHT" or "TOPLEFT"
    else
        anchorPoint = isDebuff and "TOPLEFT" or "TOPRIGHT"
    end

    container:SetFlowLayoutAxis(layoutAxis)
    container:SetFlowLayoutAnchorPoint(anchorPoint)
    container:SetFlowLayoutGrowthDirection(horizontalDirection, verticalDirection)
    container:SetFlowLayoutMaximumLineSize(math.max(1, maximumLineSize))
end

local function LayoutAuraContainer(container, isDebuff, size, activeCount)
    if MMF_Designer and MMF_Designer.ready and MMF_Designer.ConfigureAuraContainer then
        return MMF_Designer.ConfigureAuraContainer(container,isDebuff)
    end
    if container and container.mmfSecureAuraContainer then
        ConfigureSecureAuraContainer(container, isDebuff)
        return
    end
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
    local activeRaw = math.floor(tonumber(activeCount) or GetActiveAuraCount(container) or 0)
    local active = activeRaw
    if active < 1 then
        active = 1
    end
    if active > visibleLimit then
        active = visibleLimit
    end
    local activeMouseCount = activeRaw
    if activeMouseCount < 0 then
        activeMouseCount = 0
    end
    if activeMouseCount > visibleLimit then
        activeMouseCount = visibleLimit
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
    if unitToken == "player" or IsBossAuraUnit(unitToken) then
        basePoint = isDebuff and "TOPRIGHT" or "TOPLEFT"
    else
        basePoint = isDebuff and "TOPLEFT" or "TOPRIGHT"
    end

    for i, aura in ipairs(container.auras) do
        aura:SetSize(iconSize, iconSize)
        aura:EnableMouse(i <= activeMouseCount)
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
        local baselineRows = math.min(rows, 3)
        local buffRows = math.max(effectiveRows, baselineRows)
        local buffCols = perRow
        container:SetSize(
            (step * buffCols) - AURA_ICON_SPACING,
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

    if container.SetHitRectInsets then
        if vSign > 0 then
            local extraAbove = math.max(0, (effectiveRows - 1) * step)
            container:SetHitRectInsets(0, 0, -extraAbove, extraAbove)
        else
            container:SetHitRectInsets(0, 0, 0, 0)
        end
    end
end





function MMF_UpdateAuraTextScale(scale)
    if not MMF_TargetFrame and not MMF_PlayerFrame and not MMF_FocusFrame then return end
    
    local fontSize = math.max(6, math.floor(10 * scale))
    
    local function updateContainer(container)
        if container and container.mmfSecureAuraContainer then
            local aurasAreSecret = C_Secrets
                and type(C_Secrets.ShouldAurasBeSecret) == "function"
                and C_Secrets.ShouldAurasBeSecret()
            if aurasAreSecret then
                return
            end
            local groupKey = container.mmfAuraGroupKey
            local frameCount = container:GetAuraGroupFrameCount(groupKey)
            for frameIndex = 1, frameCount do
                local auraButton = container:GetAuraGroupFrame(groupKey, frameIndex)
                if auraButton then
                    local countText = auraButton:GetApplicationCount()
                    if countText then
                        MMF_SetFontSafe(countText, STANDARD_TEXT_FONT, fontSize, (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
                    end
                end
            end
            return
        end
        if container and container.auras then
            for _, aura in ipairs(container.auras) do
                if aura.count then
                    MMF_SetFontSafe(aura.count, STANDARD_TEXT_FONT, fontSize, (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
                end
            end
        end
    end
    
    if MMF_TargetFrame then
        updateContainer(MMF_TargetFrame.BuffContainer)
        updateContainer(MMF_TargetFrame.DebuffContainer)
        updateContainer(MMF_TargetFrame.BuffPreviewContainer)
        updateContainer(MMF_TargetFrame.DebuffPreviewContainer)
    end
    if MMF_PlayerFrame then
        updateContainer(MMF_PlayerFrame.BuffContainer)
        updateContainer(MMF_PlayerFrame.DebuffContainer)
        updateContainer(MMF_PlayerFrame.BuffPreviewContainer)
        updateContainer(MMF_PlayerFrame.DebuffPreviewContainer)
    end
    if MMF_FocusFrame then
        updateContainer(MMF_FocusFrame.BuffContainer)
        updateContainer(MMF_FocusFrame.DebuffContainer)
        updateContainer(MMF_FocusFrame.BuffPreviewContainer)
        updateContainer(MMF_FocusFrame.DebuffPreviewContainer)
    end
end

function MMF_UpdateTimerTextScale(scale)
    if not MMF_TargetFrame and not MMF_PlayerFrame and not MMF_FocusFrame then return end
    
    local fontSize = math.max(8, math.floor(12 * scale))
    
    local function updateContainer(container)
        if container and container.mmfSecureAuraContainer then
            local aurasAreSecret = C_Secrets
                and type(C_Secrets.ShouldAurasBeSecret) == "function"
                and C_Secrets.ShouldAurasBeSecret()
            if aurasAreSecret then
                return
            end
            local groupKey = container.mmfAuraGroupKey
            local frameCount = container:GetAuraGroupFrameCount(groupKey)
            for frameIndex = 1, frameCount do
                local auraButton = container:GetAuraGroupFrame(groupKey, frameIndex)
                if auraButton then
                    local cooldown = auraButton:GetDurationCooldown()
                    if cooldown then
                        local regions = { cooldown:GetRegions() }
                        for _, region in ipairs(regions) do
                            if region and region.SetFont then
                                MMF_SetFontSafe(region, STANDARD_TEXT_FONT, fontSize, (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
                            end
                        end
                    end
                end
            end
            return
        end
        if container and container.auras then
            for _, aura in ipairs(container.auras) do
                if aura.timerText then
                    MMF_SetFontSafe(aura.timerText, STANDARD_TEXT_FONT, fontSize, (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
                end
            end
        end
    end
    
    if MMF_TargetFrame then
        updateContainer(MMF_TargetFrame.BuffContainer)
        updateContainer(MMF_TargetFrame.DebuffContainer)
        updateContainer(MMF_TargetFrame.BuffPreviewContainer)
        updateContainer(MMF_TargetFrame.DebuffPreviewContainer)
    end
    if MMF_PlayerFrame then
        updateContainer(MMF_PlayerFrame.BuffContainer)
        updateContainer(MMF_PlayerFrame.DebuffContainer)
        updateContainer(MMF_PlayerFrame.BuffPreviewContainer)
        updateContainer(MMF_PlayerFrame.DebuffPreviewContainer)
    end
    if MMF_FocusFrame then
        updateContainer(MMF_FocusFrame.BuffContainer)
        updateContainer(MMF_FocusFrame.DebuffContainer)
        updateContainer(MMF_FocusFrame.BuffPreviewContainer)
        updateContainer(MMF_FocusFrame.DebuffPreviewContainer)
    end
end

function MMF_UpdateAuraIconSize(size)
    if not MMF_TargetFrame and not MMF_PlayerFrame and not MMF_FocusFrame then return end

    size = math.floor(size)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    MattMinimalFramesDB.auraIconSize = size
    if MMF_TargetFrame then
        LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, size, GetActiveAuraCount(MMF_TargetFrame.BuffContainer))
        LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, size, GetActiveAuraCount(MMF_TargetFrame.DebuffContainer))
    end
    if MMF_PlayerFrame then
        LayoutAuraContainer(MMF_PlayerFrame.BuffContainer, false, size, GetActiveAuraCount(MMF_PlayerFrame.BuffContainer))
        LayoutAuraContainer(MMF_PlayerFrame.DebuffContainer, true, size, GetActiveAuraCount(MMF_PlayerFrame.DebuffContainer))
    end
    if MMF_FocusFrame then
        LayoutAuraContainer(MMF_FocusFrame.BuffContainer, false, size, GetActiveAuraCount(MMF_FocusFrame.BuffContainer))
        LayoutAuraContainer(MMF_FocusFrame.DebuffContainer, true, size, GetActiveAuraCount(MMF_FocusFrame.DebuffContainer))
    end
end

function MMF_UpdateAuraLayout()
    if not MMF_TargetFrame and not MMF_PlayerFrame and not MMF_FocusFrame then
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
    if MMF_FocusFrame and MMF_FocusFrame.BuffContainer then
        ApplyAuraContainerPosition(MMF_FocusFrame.BuffContainer, false, MattMinimalFramesDB and MattMinimalFramesDB.focusBuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.focusBuffYOffset)
    end
    if MMF_FocusFrame and MMF_FocusFrame.DebuffContainer then
        ApplyAuraContainerPosition(MMF_FocusFrame.DebuffContainer, true, MattMinimalFramesDB and MattMinimalFramesDB.focusDebuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.focusDebuffYOffset)
    end
    if MMF_TargetFrame then
        LayoutAuraContainer(MMF_TargetFrame.BuffContainer, false, nil, GetActiveAuraCount(MMF_TargetFrame.BuffContainer))
        LayoutAuraContainer(MMF_TargetFrame.DebuffContainer, true, nil, GetActiveAuraCount(MMF_TargetFrame.DebuffContainer))
    end
    if MMF_PlayerFrame then
        LayoutAuraContainer(MMF_PlayerFrame.BuffContainer, false, nil, GetActiveAuraCount(MMF_PlayerFrame.BuffContainer))
        LayoutAuraContainer(MMF_PlayerFrame.DebuffContainer, true, nil, GetActiveAuraCount(MMF_PlayerFrame.DebuffContainer))
    end
    if MMF_FocusFrame then
        LayoutAuraContainer(MMF_FocusFrame.BuffContainer, false, nil, GetActiveAuraCount(MMF_FocusFrame.BuffContainer))
        LayoutAuraContainer(MMF_FocusFrame.DebuffContainer, true, nil, GetActiveAuraCount(MMF_FocusFrame.DebuffContainer))
    end
    if MMF_UpdateTargetAuras then MMF_UpdateTargetAuras() end
    if MMF_UpdatePlayerAuras then MMF_UpdatePlayerAuras() end
    if MMF_UpdateFocusAuras then MMF_UpdateFocusAuras() end
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

function MMF_UpdateFocusBuffPosition(x, y)
    if not MMF_FocusFrame or not MMF_FocusFrame.BuffContainer then return end
    ApplyAuraContainerPosition(MMF_FocusFrame.BuffContainer, false, x, y)
    if MMF_UpdateAuraLayout then
        MMF_UpdateAuraLayout()
    end
end

function MMF_UpdateFocusDebuffPosition(x, y)
    if not MMF_FocusFrame or not MMF_FocusFrame.DebuffContainer then return end
    ApplyAuraContainerPosition(MMF_FocusFrame.DebuffContainer, true, x, y)
    if MMF_UpdateAuraLayout then
        MMF_UpdateAuraLayout()
    end
end





local function CreateAuraIcon(parent, index, isDebuff, iconSize)

    local aura = CreateFrame("Button", nil, parent)
    aura:SetSize(iconSize, iconSize)
    aura:EnableMouse(true)
    aura:RegisterForDrag("LeftButton")
    aura:RegisterForClicks("RightButtonUp")

    MMF_AuraVisuals.Create(aura, isDebuff, false)
    aura:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        local unit = self.auraUnit or "target"
        local tooltipSet = false

        if self.isTemporaryEnchant and self.inventorySlot and GameTooltip.SetInventoryItem then
            pcall(GameTooltip.SetInventoryItem, GameTooltip, "player", self.inventorySlot)
            tooltipSet = (GameTooltip:NumLines() or 0) > 0
        elseif HasRetailAuraAPI then
            
            if self.auraInstanceID and GameTooltip.SetUnitAuraByAuraInstanceID then
                pcall(GameTooltip.SetUnitAuraByAuraInstanceID, GameTooltip, unit, self.auraInstanceID)
                tooltipSet = (GameTooltip:NumLines() or 0) > 0
            end
        else
            if self.auraIndex then
                pcall(GameTooltip.SetUnitAura, GameTooltip, unit, self.auraIndex, self.auraFilter)
                tooltipSet = (GameTooltip:NumLines() or 0) > 0
            end
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
    aura:SetScript("OnClick", function(self, button)
        if button ~= "RightButton" then
            return
        end
        
        
        
        if self.isTemporaryEnchant then
            return
        end

        if self.auraUnit == "player"
            and self.auraFilter == "HELPFUL"
            and type(CancelUnitBuff) == "function"
            and self.auraIndex then
            CancelUnitBuff("player", self.auraIndex, "HELPFUL")
        end
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





local function CreateAuraContainer(parent, isDebuff, unitToken, forcePreviewContainer)
    local iconSize = GetAuraIconSizeForType(isDebuff, unitToken)

    if UsesRestrictedAuraAPI and not forcePreviewContainer then
        local function InitializeAuraButton(auraButton)
            local currentIconSize = GetAuraIconSizeForType(isDebuff, unitToken)
            auraButton:SetSize(currentIconSize, currentIconSize)
            auraButton:SetTooltipAnchorPoint("ANCHOR_RIGHT")

            
            
            
            if unitToken == "player" and not isDebuff and auraButton.SetCancelAuraButtons then
                auraButton:SetCancelAuraButtons("RightButtonUp")
            end

            MMF_AuraVisuals.Create(auraButton, isDebuff, true)
            if MMF_Designer and MMF_Designer.StyleAuraButton then MMF_Designer.StyleAuraButton(auraButton,unitToken,isDebuff) end
        end

        local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        container.mmfSecureAuraContainer = true
        container.mmfAuraUnit = unitToken
        container.mmfAuraOwnerFrame = parent
        container.mmfAuraIsDebuff = isDebuff
        container.mmfAuraGroupKey = isDebuff and "Debuffs" or "Buffs"
        container:SetUnit(unitToken)
        local initialFilter = IsBossAuraUnit(unitToken) and "HARMFUL|PLAYER" or (isDebuff and "HARMFUL" or "HELPFUL")
        container:AddAuraGroup(container.mmfAuraGroupKey, initialFilter, {
            maxFrameCount = GetVisibleAuraLimit(isDebuff, unitToken),
            initializeFrame = InitializeAuraButton,
            layout = {
                elementSpacing = AURA_ICON_SPACING,
                lineSpacing = AURA_ICON_SPACING,
                elementWidth = iconSize,
                elementHeight = iconSize,
            },
        })
        ConfigureSecureAuraContainer(container, isDebuff)
        local enabled = not IsBossAuraUnit(unitToken) or not MattMinimalFramesDB or MattMinimalFramesDB.showBossDebuffs ~= false
        container:SetEnabled(enabled)
        container:SetShown(enabled)

        local x, y = GetAuraOffsetsForUnit(unitToken, isDebuff)
        ApplyAuraContainerPosition(container, isDebuff, x, y)
        return container
    end

    local container = CreateFrame("Frame", nil, parent)
    container.mmfAuraUnit = unitToken
    container.mmfAuraOwnerFrame = parent
    container.mmfAuraIsDebuff = isDebuff
    container:SetMovable(not IsBossAuraUnit(unitToken))
    container:EnableMouse(true)
    container:RegisterForDrag("LeftButton")

    if isDebuff then
        if unitToken == "player" then
            ApplyAuraContainerPosition(container, true, MattMinimalFramesDB and MattMinimalFramesDB.playerDebuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.playerDebuffYOffset)
        elseif unitToken == "focus" then
            ApplyAuraContainerPosition(container, true, MattMinimalFramesDB and MattMinimalFramesDB.focusDebuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.focusDebuffYOffset)
        else
            ApplyAuraContainerPosition(container, true, MMF_GetDebuffXOffset(), MMF_GetDebuffYOffset())
        end
    else
        if unitToken == "player" then
            ApplyAuraContainerPosition(container, false, MattMinimalFramesDB and MattMinimalFramesDB.playerBuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.playerBuffYOffset)
        elseif unitToken == "focus" then
            ApplyAuraContainerPosition(container, false, MattMinimalFramesDB and MattMinimalFramesDB.focusBuffXOffset, MattMinimalFramesDB and MattMinimalFramesDB.focusBuffYOffset)
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
    MMF_SetFontSafe(label, MMF_GetDefaultFontPath(), 10, (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
    if isDebuff then
        label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 6)
    else
        label:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -3)
    end
    local unitPrefix = "TARGET "
    if unitToken == "player" then
        unitPrefix = "PLAYER "
    elseif unitToken == "focus" then
        unitPrefix = "FOCUS "
    elseif IsBossAuraUnit(unitToken) then
        unitPrefix = string.upper(unitToken) .. " MY "
    end
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
        if IsBossAuraUnit(unitToken) then return end
        if CanStartAuraContainerDrag(self) then
            StartAuraContainerDrag(self)
        end
    end)
    container:SetScript("OnDragStop", function(self)
        StopAuraContainerDrag(self)
    end)
    container:SetScript("OnMouseUp", function(self, button)
        if IsBossAuraUnit(unitToken) then return end
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
        if not MMF_TargetFrame.BuffContainer then
            MMF_TargetFrame.BuffContainer = CreateAuraContainer(MMF_TargetFrame, false, "target")
        end
        if not MMF_TargetFrame.DebuffContainer then
            MMF_TargetFrame.DebuffContainer = CreateAuraContainer(MMF_TargetFrame, true, "target")
        end
        if UsesRestrictedAuraAPI and not MMF_TargetFrame.BuffPreviewContainer then
            MMF_TargetFrame.BuffPreviewContainer = CreateAuraContainer(MMF_TargetFrame, false, "target", true)
            MMF_TargetFrame.BuffPreviewContainer:Hide()
        end
        if UsesRestrictedAuraAPI and not MMF_TargetFrame.DebuffPreviewContainer then
            MMF_TargetFrame.DebuffPreviewContainer = CreateAuraContainer(MMF_TargetFrame, true, "target", true)
            MMF_TargetFrame.DebuffPreviewContainer:Hide()
        end
    end
    if MMF_PlayerFrame then
        if not MMF_PlayerFrame.BuffContainer then
            MMF_PlayerFrame.BuffContainer = CreateAuraContainer(MMF_PlayerFrame, false, "player")
        end
        if not MMF_PlayerFrame.DebuffContainer then
            MMF_PlayerFrame.DebuffContainer = CreateAuraContainer(MMF_PlayerFrame, true, "player")
        end
        if UsesRestrictedAuraAPI and not MMF_PlayerFrame.BuffPreviewContainer then
            MMF_PlayerFrame.BuffPreviewContainer = CreateAuraContainer(MMF_PlayerFrame, false, "player", true)
            MMF_PlayerFrame.BuffPreviewContainer:Hide()
        end
        if UsesRestrictedAuraAPI and not MMF_PlayerFrame.DebuffPreviewContainer then
            MMF_PlayerFrame.DebuffPreviewContainer = CreateAuraContainer(MMF_PlayerFrame, true, "player", true)
            MMF_PlayerFrame.DebuffPreviewContainer:Hide()
        end
    end
    if MMF_FocusFrame then
        if not MMF_FocusFrame.BuffContainer then
            MMF_FocusFrame.BuffContainer = CreateAuraContainer(MMF_FocusFrame, false, "focus")
        end
        if not MMF_FocusFrame.DebuffContainer then
            MMF_FocusFrame.DebuffContainer = CreateAuraContainer(MMF_FocusFrame, true, "focus")
        end
        if UsesRestrictedAuraAPI and not MMF_FocusFrame.BuffPreviewContainer then
            MMF_FocusFrame.BuffPreviewContainer = CreateAuraContainer(MMF_FocusFrame, false, "focus", true)
            MMF_FocusFrame.BuffPreviewContainer:Hide()
        end
        if UsesRestrictedAuraAPI and not MMF_FocusFrame.DebuffPreviewContainer then
            MMF_FocusFrame.DebuffPreviewContainer = CreateAuraContainer(MMF_FocusFrame, true, "focus", true)
            MMF_FocusFrame.DebuffPreviewContainer:Hide()
        end
    end
    for i = 1, 5 do
        local frame = _G["MMF_Boss" .. i .. "Frame"]
        if frame and not frame.DebuffContainer then
            frame.DebuffContainer = CreateAuraContainer(frame, true, "boss" .. i)
            if UsesRestrictedAuraAPI then
                frame.DebuffPreviewContainer = CreateAuraContainer(frame, true, "boss" .. i, true)
                frame.DebuffPreviewContainer:Hide()
            end
        end
    end
end





local function UpdateAuraIcon(auraFrame, auraData, filter, unit, index)
    if not auraFrame or type(auraData) ~= "table" or not auraData.icon then
        ClearAuraFrameState(auraFrame)
        return
    end

    local auraInstanceID = auraData and auraData.auraInstanceID or nil

    auraFrame.icon:SetTexture(auraData.icon)
    auraFrame.auraData = auraData
    auraFrame.auraIndex = (auraData and auraData._index) or index
    auraFrame.auraFilter = filter
    auraFrame.auraUnit = unit
    auraFrame.auraInstanceID = auraInstanceID
    auraFrame.isTemporaryEnchant = auraData.isTemporaryEnchant == true
    auraFrame.temporaryEnchantIndex = auraData.temporaryEnchantIndex
    auraFrame.inventorySlot = auraData.inventorySlot
    
    if auraFrame.count then auraFrame.count:Hide() end
    if auraInstanceID and C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount then
        if not auraFrame.count then
            auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
            auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
        end
        local scale = MMF_GetAuraTextScale()
        MMF_SetFontSafe(auraFrame.count, MMF_GetDefaultFontPath(), math.max(6, math.floor(10 * scale)), (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
        auraFrame.count:SetText(C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 999))
        auraFrame.count:Show()
    elseif auraData.count and auraData.count > 1 then
        if not auraFrame.count then
            auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
            auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
        end
        local scale = MMF_GetAuraTextScale()
        MMF_SetFontSafe(auraFrame.count, MMF_GetDefaultFontPath(), math.max(6, math.floor(10 * scale)), (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
        auraFrame.count:SetText(auraData.count)
        auraFrame.count:Show()
    end
    if auraFrame.cooldown then
        local useOmniCC = false
        if Compat.IsTBC then
            useOmniCC = ConfigureOmniCCAuraText(auraFrame.cooldown)
        end

        SetAuraCooldown(auraFrame.cooldown, auraData, unit)

        if useOmniCC then
            SetOmniCCAuraTimer(auraFrame.cooldown, auraData)
        end
        
        if auraFrame.timerText and auraFrame.timerText.SetFont then
            local timerScale = MMF_GetTimerTextScale()
            local timerFontSize = math.max(8, math.floor(12 * timerScale))
            MMF_SetFontSafe(auraFrame.timerText, STANDARD_TEXT_FONT, timerFontSize, (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
        end
    end
    
    auraFrame:EnableMouse(true)
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
    auraFrame.isTemporaryEnchant = nil
    auraFrame.temporaryEnchantIndex = nil
    auraFrame.inventorySlot = nil
    auraFrame.icon:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\MMF.png")

    if not auraFrame.count then
        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -1, 1)
    end
    local scale = MMF_GetAuraTextScale()
    MMF_SetFontSafe(auraFrame.count, MMF_GetDefaultFontPath(), math.max(6, math.floor(10 * scale)), (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
    local count = (index % 4) + 1
    auraFrame.count:SetText(count > 1 and count or "")
    auraFrame.count:Show()

    if auraFrame.cooldown then
        auraFrame.cooldown:SetHideCountdownNumbers(false)
        auraFrame.cooldown:SetCooldown(GetTime(), 75 + ((index % 3) * 15))
        auraFrame.cooldown:Show()
    end
    if auraFrame.timerText and auraFrame.timerText.SetFont then
        local timerScale = MMF_GetTimerTextScale()
        MMF_SetFontSafe(auraFrame.timerText, STANDARD_TEXT_FONT, math.max(8, math.floor(12 * timerScale)), (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE")
        auraFrame.timerText:Show()
    end

    if auraFrame.border then
        if isDebuff then
            auraFrame.border:SetVertexColor(1, 0.25, 0.25)
        else
            auraFrame.border:SetVertexColor(1, 1, 1)
        end
    end

    auraFrame:EnableMouse(true)
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

local function CopyRetailAuraData(aura, index)
    if type(aura) ~= "table" then
        return nil
    end

    return {
        
        name = aura.name,
        icon = aura.icon,
        count = aura.count,
        applications = aura.applications,
        debuffType = aura.debuffType,
        dispelName = aura.dispelName,
        duration = aura.duration,
        expirationTime = aura.expirationTime,
        sourceUnit = aura.sourceUnit,
        source = aura.source,
        caster = aura.caster,
        isFromPlayerOrPlayerPet = aura.isFromPlayerOrPlayerPet,
        isFromPlayerOrPet = aura.isFromPlayerOrPet,
        castByPlayer = aura.castByPlayer,
        isPlayerAura = aura.isPlayerAura,
        spellId = aura.spellId,
        auraInstanceID = aura.auraInstanceID,
        _index = index,
    }
end

local function GetRetailAurasByFilter(unit, filter)
    local out = {}
    if not HasRetailAuraAPI then
        return out
    end

    if AuraUtil and AuraUtil.ForEachAura then
        local auraIndex = 0
        local usePackedAura = true
        AuraUtil.ForEachAura(unit, filter, 40, function(auraData)
            auraIndex = auraIndex + 1
            local auraCopy = CopyRetailAuraData(auraData, auraIndex)
            if auraCopy then
                out[#out + 1] = auraCopy
            end
            return #out >= 40
        end, usePackedAura)
        return out
    end

    return out
end

local function GetRetailPlayerDebuffs(unit)
    local debuffs = GetRetailAurasByFilter(unit, "HARMFUL|PLAYER")
    if debuffs and #debuffs > 0 then
        return debuffs
    end

    return debuffs or {}
end

local UpdateBossAuras
local function EnsureBossAuraShowHook(frame)
    if frame and not frame.mmfBossAuraShowHooked then
        frame.mmfBossAuraShowHooked = true
        frame:HookScript("OnShow", function(self)
            UpdateBossAuras(self.unit)
        end)
    end
end

UpdateBossAuras = function(unitFilter)
    if MMF_Designer and MMF_Designer.ready then
        for i=1,5 do
            local unit = "boss"..i
            if not unitFilter or unitFilter == unit then
                local frame = MMF_GetFrameForUnit(unit)
                if frame then
                    EnsureBossAuraShowHook(frame)
                    if frame:IsShown() then
                        MMF_Designer.RefreshAuras(frame)
                    end
                end
            end
        end
        return
    end
    local preview = IsAuraFakePreviewEnabled()
    local showDebuffs = not MattMinimalFramesDB or MattMinimalFramesDB.showBossDebuffs ~= false
    for i = 1, 5 do
        local unit = "boss" .. i
        if not unitFilter or unitFilter == unit then
            local frame = _G["MMF_Boss" .. i .. "Frame"]
            EnsureBossAuraShowHook(frame)
            local container = frame and frame.DebuffContainer
            if container then
                local shown = showDebuffs and frame:IsShown()
                if container.mmfSecureAuraContainer then
                    
                    ApplyAuraContainerPosition(container, true)
                    local enabled = shown and not preview
                    if container:IsEnabled() ~= enabled then container:SetEnabled(enabled) end
                    container:SetShown(enabled)
                    container = frame.DebuffPreviewContainer
                end
                if container then
                    ClearAuraContainer(container)
                    if shown and preview then
                        container:Show()
                        for index = 1, 3 do UpdateFakeAuraIcon(container.auras[index], index, true) end
                        LayoutAuraContainer(container, true, nil, 3)
                    elseif shown and not UsesRestrictedAuraAPI and UnitExists(unit) then
                        container:Show()
                        
                        local filter = "HARMFUL|PLAYER"
                        local debuffs = HasRetailAuraAPI and GetRetailAurasByFilter(unit, filter) or GetUnitAuras(unit, filter)
                        local count = math.min(#debuffs, GetVisibleAuraLimit(true, unit))
                        for index = 1, count do
                            UpdateAuraIcon(container.auras[index], debuffs[index], filter, unit, index)
                        end
                        LayoutAuraContainer(container, true, nil, count)
                    else
                        container:Hide()
                    end
                    UpdateAuraContainerLabel(container, false)
                    ApplyAuraContainerPosition(container, true)
                end
            end
        end
    end
end

_G.MMF_UpdateBossAuras = UpdateBossAuras

local function GetLegacyTemporaryEnchants()
    local enchants = {}
    if (Compat.IsRetail or HasRetailAuraAPI) or type(GetWeaponEnchantInfo) ~= "function" then
        return enchants
    end

    local hasMainHand, mainExpirationMS, mainCharges, mainEnchantID,
        hasOffHand, offExpirationMS, offCharges, offEnchantID,
        hasRanged, rangedExpirationMS, rangedCharges, rangedEnchantID = GetWeaponEnchantInfo()

    local function AddEnchant(hasEnchant, expirationMS, charges, enchantID, inventorySlot, enchantIndex)
        if not hasEnchant then
            return
        end

        local icon = GetInventoryItemTexture and GetInventoryItemTexture("player", inventorySlot)
        if not icon then
            return
        end

        local remaining = (tonumber(expirationMS) or 0) / 1000
        enchants[#enchants + 1] = {
            icon = icon,
            count = tonumber(charges) or 0,
            duration = remaining,
            expirationTime = remaining > 0 and (GetTime() + remaining) or 0,
            spellId = enchantID,
            isTemporaryEnchant = true,
            temporaryEnchantIndex = enchantIndex,
            inventorySlot = inventorySlot,
        }
    end

    AddEnchant(hasMainHand, mainExpirationMS, mainCharges, mainEnchantID, 16, 1)
    AddEnchant(hasOffHand, offExpirationMS, offCharges, offEnchantID, 17, 2)
    AddEnchant(hasRanged, rangedExpirationMS, rangedCharges, rangedEnchantID, 18, 3)
    return enchants
end

MMF_GetLegacyTemporaryEnchants = GetLegacyTemporaryEnchants

local function UpdateUnitAuras(unit)
    if MMF_Designer and MMF_Designer.ready then
        return MMF_Designer.RefreshAuras(MMF_GetFrameForUnit(unit))
    end
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit)
    if not frame or not frame.BuffContainer or not frame.DebuffContainer then return end

    local db = MattMinimalFramesDB or {}
    local showLabels = IsAuraLabelPreviewEnabled()
    local showBuffsKey = (unit == "player") and "showPlayerBuffs"
        or (unit == "focus") and "showFocusBuffs"
        or "showBuffs"
    local showDebuffsKey = (unit == "player") and "showPlayerDebuffs"
        or (unit == "focus") and "showFocusDebuffs"
        or "showDebuffs"

    if UsesRestrictedAuraAPI then
        local buffContainer = frame.BuffContainer
        local debuffContainer = frame.DebuffContainer
        local buffPreview = frame.BuffPreviewContainer
        local debuffPreview = frame.DebuffPreviewContainer

        if IsAuraFakePreviewEnabled() and buffPreview and debuffPreview then
            buffContainer:SetEnabled(false)
            debuffContainer:SetEnabled(false)
            buffContainer:Hide()
            debuffContainer:Hide()

            if unit == "target" then
                SetAuraTestPreviewFrameState(true)
            end

            local forcePlayerPreview = unit == "player"
            local showBuffs = forcePlayerPreview or db[showBuffsKey] ~= false
            local showDebuffs = forcePlayerPreview or db[showDebuffsKey] ~= false

            if showBuffs then
                buffPreview:Show()
                PopulateFakeAuras(buffPreview, false)
                LayoutAuraContainer(buffPreview, false, nil, math.min(16, GetVisibleAuraLimit(false, unit)))
                UpdateAuraContainerLabel(buffPreview, showLabels)
            else
                ClearAuraContainer(buffPreview)
                buffPreview:Hide()
                UpdateAuraContainerLabel(buffPreview, false)
            end

            if showDebuffs then
                debuffPreview:Show()
                PopulateFakeAuras(debuffPreview, true)
                LayoutAuraContainer(debuffPreview, true, nil, math.min(16, GetVisibleAuraLimit(true, unit)))
                UpdateAuraContainerLabel(debuffPreview, showLabels)
            else
                ClearAuraContainer(debuffPreview)
                debuffPreview:Hide()
                UpdateAuraContainerLabel(debuffPreview, false)
            end

            local buffX, buffY = GetAuraOffsetsForUnit(unit, false)
            local debuffX, debuffY = GetAuraOffsetsForUnit(unit, true)
            ApplyAuraContainerPosition(buffPreview, false, buffX, buffY)
            ApplyAuraContainerPosition(debuffPreview, true, debuffX, debuffY)
            return
        end

        if buffPreview then
            ClearAuraContainer(buffPreview)
            buffPreview:Hide()
            UpdateAuraContainerLabel(buffPreview, false)
        end
        if debuffPreview then
            ClearAuraContainer(debuffPreview)
            debuffPreview:Hide()
            UpdateAuraContainerLabel(debuffPreview, false)
        end
        if unit == "target" then
            SetAuraTestPreviewFrameState(false)
        end

        ConfigureSecureAuraContainer(buffContainer, false)
        ConfigureSecureAuraContainer(debuffContainer, true)

        local showBuffs = db[showBuffsKey] ~= false
        local showDebuffs = db[showDebuffsKey] ~= false
        buffContainer:SetEnabled(showBuffs)
        debuffContainer:SetEnabled(showDebuffs)
        buffContainer:SetShown(showBuffs)
        debuffContainer:SetShown(showDebuffs)

        local buffX, buffY = GetAuraOffsetsForUnit(unit, false)
        local debuffX, debuffY = GetAuraOffsetsForUnit(unit, true)
        ApplyAuraContainerPosition(buffContainer, false, buffX, buffY)
        ApplyAuraContainerPosition(debuffContainer, true, debuffX, debuffY)
        return
    end

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
        local buffX, buffY = GetAuraOffsetsForUnit(unit, false)
        local debuffX, debuffY = GetAuraOffsetsForUnit(unit, true)
        ApplyAuraContainerPosition(buffContainer, false, buffX, buffY)
        ApplyAuraContainerPosition(debuffContainer, true, debuffX, debuffY)
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

    local buffs = HasRetailAuraAPI and GetRetailAurasByFilter(unit, "HELPFUL") or GetUnitAuras(unit, "HELPFUL")
    if unit == "player" and Compat.IsClassic then
        local temporaryEnchants = GetLegacyTemporaryEnchants()
        if #temporaryEnchants > 0 then
            local combinedBuffs = {}
            for i = 1, #temporaryEnchants do
                combinedBuffs[#combinedBuffs + 1] = temporaryEnchants[i]
            end
            for i = 1, #buffs do
                combinedBuffs[#combinedBuffs + 1] = buffs[i]
            end
            buffs = combinedBuffs
        end
    end
    local debuffs = nil
    if unit == "target" and db.onlyShowPlayerDebuffsOnTarget == true and HasRetailAuraAPI then
        debuffs = GetRetailPlayerDebuffs(unit)
    else
        debuffs = HasRetailAuraAPI and GetRetailAurasByFilter(unit, "HARMFUL") or GetUnitAuras(unit, "HARMFUL")
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

    local buffX, buffY = GetAuraOffsetsForUnit(unit, false)
    local debuffX, debuffY = GetAuraOffsetsForUnit(unit, true)
    ApplyAuraContainerPosition(buffContainer, false, buffX, buffY)
    ApplyAuraContainerPosition(debuffContainer, true, debuffX, debuffY)
end

function MMF_UpdateTargetAuras()
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    UpdateUnitAuras("target")
end

function MMF_UpdatePlayerAuras()
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    UpdateUnitAuras("player")
end

function MMF_UpdateFocusAuras()
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    UpdateUnitAuras("focus")
end





local pendingAuraResync = {}
local pendingTargetRefreshBurst = false
local pendingEraPlayerAuraRefreshBurst = false

local function QueueTargetRefreshBurst()
    if UsesRestrictedAuraAPI then
        return
    end
    if pendingTargetRefreshBurst then
        return
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end

    pendingTargetRefreshBurst = true
    local attempts = 0

    local function RunPass()
        attempts = attempts + 1
        MMF_UpdateTargetAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end

        if attempts < 4 then
            C_Timer.After(0.10, RunPass)
        else
            pendingTargetRefreshBurst = false
        end
    end

    C_Timer.After(0.02, RunPass)
end

local function QueueEraPlayerAuraRefreshBurst()
    if not Compat.IsClassic or pendingEraPlayerAuraRefreshBurst then
        return
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end

    pendingEraPlayerAuraRefreshBurst = true
    local attempts = 0

    local function RunPass()
        attempts = attempts + 1
        MMF_UpdateBlizzardPlayerAuraVisibility()
        MMF_UpdatePlayerAuras()

        if attempts < 6 then

            C_Timer.After(0.15 * attempts, RunPass)
        else
            pendingEraPlayerAuraRefreshBurst = false
        end
    end


    C_Timer.After(0.02, RunPass)
end

local function QueueAuraResync(unit)
    if UsesRestrictedAuraAPI then
        return
    end
    if not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end
    if pendingAuraResync[unit] then
        return
    end

    pendingAuraResync[unit] = true
    C_Timer.After(0.12, function()
        pendingAuraResync[unit] = nil
        if unit == "target" then
            MMF_UpdateTargetAuras()
            if MMF_UpdateDispelHighlights then
                MMF_UpdateDispelHighlights()
            end
        elseif unit == "player" then
            MMF_UpdateBlizzardPlayerAuraVisibility()
            MMF_UpdatePlayerAuras()
            if MMF_UpdateDispelHighlights then
                MMF_UpdateDispelHighlights()
            end
        elseif unit == "focus" then
            MMF_UpdateFocusAuras()
            if MMF_UpdateDispelHighlights then
                MMF_UpdateDispelHighlights()
            end
        end
    end)
end

local auraEventFrame = CreateFrame("Frame")
auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
auraEventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
auraEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
auraEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
auraEventFrame:RegisterEvent("UNIT_AURA")
auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
auraEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
auraEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
auraEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
auraEventFrame:RegisterEvent("SPELLS_CHANGED")
auraEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
if Compat.IsClassic then
    auraEventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
end
auraEventFrame:SetScript("OnEvent", function(self, event, unit)
    if Compat and Compat.GetAccessibleUnitToken then
        unit = Compat.GetAccessibleUnitToken(unit)
    end
    if ShouldSuspendForBlizzardEditMode() then
        return
    end

    if UsesRestrictedAuraAPI and event == "UNIT_AURA" then
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        MMF_SetupTargetAuras()
        MMF_UpdateBlizzardPlayerAuraVisibility()
        MMF_UpdateTargetAuras()
        MMF_UpdatePlayerAuras()
        MMF_UpdateFocusAuras()
        UpdateBossAuras()
        QueueEraPlayerAuraRefreshBurst()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "PLAYER_LEAVING_WORLD" then
        if MMF_TargetFrame then
            ClearAuraContainer(MMF_TargetFrame.BuffContainer)
            ClearAuraContainer(MMF_TargetFrame.DebuffContainer)
        end
        if MMF_PlayerFrame then
            ClearAuraContainer(MMF_PlayerFrame.BuffContainer)
            ClearAuraContainer(MMF_PlayerFrame.DebuffContainer)
        end
        if MMF_FocusFrame then
            ClearAuraContainer(MMF_FocusFrame.BuffContainer)
            ClearAuraContainer(MMF_FocusFrame.DebuffContainer)
        end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        MMF_UpdateTargetAuras()
        MMF_UpdatePlayerAuras()
        MMF_UpdateFocusAuras()
        UpdateBossAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "UNIT_AURA" and IsBossAuraUnit(unit) then
        UpdateBossAuras(unit)
    elseif event == "UNIT_AURA" and unit == "target" then
        MMF_UpdateTargetAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
        QueueAuraResync("target")
    elseif event == "UNIT_AURA" and unit == "player" then
        MMF_UpdateBlizzardPlayerAuraVisibility()
        MMF_UpdatePlayerAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
        QueueAuraResync("player")
    elseif event == "UNIT_INVENTORY_CHANGED" and (unit == nil or unit == "player") then
        MMF_UpdatePlayerAuras()
    elseif event == "UNIT_AURA" and unit == "focus" then
        MMF_UpdateFocusAuras()
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
        QueueAuraResync("focus")
    elseif event == "PLAYER_TARGET_CHANGED" then
        if MMF_TargetFrame then
            ClearAuraContainer(MMF_TargetFrame.BuffContainer)
            ClearAuraContainer(MMF_TargetFrame.DebuffContainer)
        end
        MMF_UpdateTargetAuras()
        if UsesRestrictedAuraAPI and MMF_TargetFrame then
            if MMF_TargetFrame.BuffContainer and MMF_TargetFrame.BuffContainer:IsEnabled() then
                MMF_TargetFrame.BuffContainer:UpdateAllAuras()
            end
            if MMF_TargetFrame.DebuffContainer and MMF_TargetFrame.DebuffContainer:IsEnabled() then
                MMF_TargetFrame.DebuffContainer:UpdateAllAuras()
            end
        end
        MMF_UpdatePlayerAuras()
        MMF_UpdateFocusAuras()
        QueueTargetRefreshBurst()
        QueueAuraResync("target")
        QueueAuraResync("player")
        QueueAuraResync("focus")
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "PLAYER_FOCUS_CHANGED" then
        if MMF_FocusFrame then
            ClearAuraContainer(MMF_FocusFrame.BuffContainer)
            ClearAuraContainer(MMF_FocusFrame.DebuffContainer)
        end
        MMF_UpdateFocusAuras()
        if UsesRestrictedAuraAPI and MMF_FocusFrame then
            if MMF_FocusFrame.BuffContainer and MMF_FocusFrame.BuffContainer:IsEnabled() then
                MMF_FocusFrame.BuffContainer:UpdateAllAuras()
            end
            if MMF_FocusFrame.DebuffContainer and MMF_FocusFrame.DebuffContainer:IsEnabled() then
                MMF_FocusFrame.DebuffContainer:UpdateAllAuras()
            end
        end
        QueueAuraResync("focus")
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "GROUP_ROSTER_UPDATE" then
        MMF_UpdateTargetAuras()
        MMF_UpdatePlayerAuras()
        MMF_UpdateFocusAuras()
        QueueAuraResync("target")
        QueueAuraResync("player")
        QueueAuraResync("focus")
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        if MMF_UpdateDispelHighlights then
            MMF_UpdateDispelHighlights()
        end
    end
end)

if Compat.IsRetail then
    local wasEditModeSuspended = ShouldSuspendForBlizzardEditMode()
    local function RefreshAfterEditModeCloses()
        local isEditModeSuspended = ShouldSuspendForBlizzardEditMode()
        if wasEditModeSuspended and not isEditModeSuspended then
            MMF_UpdateBlizzardPlayerAuraVisibility()
            MMF_UpdateTargetAuras()
            MMF_UpdatePlayerAuras()
            MMF_UpdateFocusAuras()
            UpdateBossAuras()
            if MMF_UpdateDispelHighlights then
                MMF_UpdateDispelHighlights()
            end
        end
        wasEditModeSuspended = isEditModeSuspended
    end

    if C_Timer and type(C_Timer.NewTicker) == "function" then
        auraEventFrame.mmfEditModeResumeTicker = C_Timer.NewTicker(0.25, RefreshAfterEditModeCloses)
    else
        local elapsedSinceCheck = 0
        auraEventFrame:SetScript("OnUpdate", function(_, elapsed)
            elapsedSinceCheck = elapsedSinceCheck + (elapsed or 0)
            if elapsedSinceCheck >= 0.25 then
                elapsedSinceCheck = 0
                RefreshAfterEditModeCloses()
            end
        end)
    end
end


MMF_CreateAuraContainer = CreateAuraContainer
MMF_UpdateAurasForUnit = UpdateUnitAuras
MMF_UpdateAuraIconData = UpdateAuraIcon
MMF_UsesRestrictedAuraAPI = UsesRestrictedAuraAPI
