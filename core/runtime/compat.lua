local _, MMF = ...
MMF = MMF or {}

--------------------------------------------------
-- VERSION DETECTION
--------------------------------------------------

local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE or 1
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5
local WOW_PROJECT_CLASSIC = WOW_PROJECT_CLASSIC or 2

MMF.IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
MMF.IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
MMF.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
MMF.IsClassicEra = MMF.IsClassic or MMF.IsTBC
MMF_IsRetail = MMF.IsRetail
MMF_IsTBC = MMF.IsTBC
MMF_IsClassic = MMF.IsClassic
MMF_IsClassicEra = MMF.IsClassicEra

function MMF.ShouldSuspendForBlizzardEditMode()
    if not MMF.IsRetail then
        return false
    end

    local frame = _G.EditModeManagerFrame
    if not frame then
        return false
    end

    if type(frame.IsEditModeActive) == "function" then
        local ok, active = pcall(frame.IsEditModeActive, frame)
        if ok and active == true then
            return true
        end
    end

    if type(frame.IsShown) == "function" then
        local ok, shown = pcall(frame.IsShown, frame)
        if ok and shown == true then
            return true
        end
    end

    return false
end

_G.MMF_ShouldSuspendForBlizzardEditMode = MMF.ShouldSuspendForBlizzardEditMode

local blizzardEditModeNoticeFrame

local function EnsureFrameEditModeLabel(frame)
    if not frame or frame.mmfBlizzardEditModeLabel then
        return
    end

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetDrawLayer("OVERLAY", 7)
    label:SetPoint("CENTER", frame, "CENTER", 0, 0)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetWidth(math.max((frame.GetWidth and frame:GetWidth()) or 0, 90) - 8)
    label:SetWordWrap(true)
    label:SetTextColor(0.96, 0.32, 0.32, 1)
    label:SetFontObject(GameFontNormal)
    label:SetText("Blizzard Edit Mode: use MMF Edit Mode for this frame")
    label:Hide()

    frame.mmfBlizzardEditModeLabel = label
end

local function UpdateFrameEditModeLabelText(frame)
    if not frame or not frame.mmfBlizzardEditModeLabel then
        return
    end

    local width = (frame.GetWidth and frame:GetWidth()) or 0
    local label = frame.mmfBlizzardEditModeLabel
    label:SetWidth(math.max(width - 8, 56))

    if width <= 110 then
        label:SetText("Use MMF\nEdit Mode")
    elseif width <= 150 then
        label:SetText("Blizzard Edit Mode:\nUse MMF Edit Mode")
    else
        label:SetText("Blizzard Edit Mode: use MMF Edit Mode for this frame")
    end
end

local function UpdateFrameEditModeLabels(isVisible)
    if type(MMF_GetAllFrames) ~= "function" then
        return
    end

    for _, frame in ipairs(MMF_GetAllFrames() or {}) do
        if frame then
            EnsureFrameEditModeLabel(frame)
            if frame.mmfBlizzardEditModeLabel then
                UpdateFrameEditModeLabelText(frame)
                if isVisible then
                    frame.mmfBlizzardEditModeLabel:Show()
                else
                    frame.mmfBlizzardEditModeLabel:Hide()
                end
            end
        end
    end
end

local function EnsureBlizzardEditModeNotice()
    if not MMF.IsRetail or blizzardEditModeNoticeFrame then
        return
    end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetClampedToScreen(true)
    frame:SetSize(780, 54)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -28)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0.10, 0.01, 0.01, 0.88)
    frame:SetBackdropBorderColor(0.80, 0.16, 0.16, 0.95)
    frame:Hide()

    local headline = frame:CreateFontString(nil, "OVERLAY")
    headline:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -7)
    headline:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -7)
    headline:SetJustifyH("CENTER")
    headline:SetJustifyV("MIDDLE")
    headline:SetWordWrap(false)
    headline:SetTextColor(1, 0.86, 0.18, 1)
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"
    if MMF_SetFontSafe then
        MMF_SetFontSafe(headline, MMF_Config and MMF_Config.FONT_PATH or "Fonts\\FRIZQT__.TTF", 16, fontFlags)
    else
        headline:SetFont("Fonts\\FRIZQT__.TTF", 16, fontFlags)
    end
    headline:SetText("You are in Blizzard Edit Mode")

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOPLEFT", headline, "BOTTOMLEFT", 0, -4)
    text:SetPoint("TOPRIGHT", headline, "BOTTOMRIGHT", 0, -4)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    text:SetTextColor(1, 0.93, 0.93, 1)
    text:SetFontObject(GameFontNormal)
    text:SetText("Use MMF Edit Mode for player, target, focus, and other personal frames.\nUse Blizzard Edit Mode only for party and raid frames.")

    frame.headline = headline
    frame.text = text
    blizzardEditModeNoticeFrame = frame
end

function MMF.UpdateBlizzardEditModeNotice()
    if not MMF.IsRetail then
        return
    end

    EnsureBlizzardEditModeNotice()
    if not blizzardEditModeNoticeFrame then
        return
    end

    if MMF.ShouldSuspendForBlizzardEditMode() then
        blizzardEditModeNoticeFrame:Show()
        UpdateFrameEditModeLabels(true)
    else
        blizzardEditModeNoticeFrame:Hide()
        UpdateFrameEditModeLabels(false)
    end
end

do
    local noticeDriver = CreateFrame("Frame")
    local elapsedSinceUpdate = 0

    noticeDriver:RegisterEvent("PLAYER_LOGIN")
    noticeDriver:RegisterEvent("PLAYER_ENTERING_WORLD")
    noticeDriver:SetScript("OnEvent", function()
        MMF.UpdateBlizzardEditModeNotice()
    end)
    noticeDriver:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed
        if elapsedSinceUpdate < 0.20 then
            return
        end
        elapsedSinceUpdate = 0
        MMF.UpdateBlizzardEditModeNotice()
    end)
end

--------------------------------------------------
-- API COMPATIBILITY
--------------------------------------------------

function MMF.GetSpellName(spellID)
    if _G.GetSpellInfo then
        local name = _G.GetSpellInfo(spellID)
        if name then return name end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    end
    return nil
end

MMF.IsSpellInRange = _G.IsSpellInRange
if MMF.IsRetail and C_Spell and C_Spell.IsSpellInRange then
    MMF.IsSpellInRange = C_Spell.IsSpellInRange
end

function MMF.GetSpecialization()
    if MMF.IsRetail and _G.GetSpecialization then
        return _G.GetSpecialization()
    end
    return nil
end

function MMF.GetAccessibleUnitToken(unit)
    if issecretvalue and issecretvalue(unit) then
        return nil
    end
    if canaccessvalue and not canaccessvalue(unit) then
        return nil
    end
    if unit == nil then
        return nil
    end
    if type(unit) ~= "string" or unit == "" then
        return nil
    end
    return unit
end

--------------------------------------------------
-- RANGE CHECK SPELL TABLES
--------------------------------------------------

MMF.FriendSpells_Retail = {
    DEATHKNIGHT = 47541,
    DRUID       = 8936,
    EVOKER      = 355913,
    MAGE        = 1459,
    MONK        = 116670,
    PALADIN     = 19750,
    PRIEST      = 2061,
    SHAMAN      = 8004,
    WARLOCK     = 5697,
}

MMF.HarmSpells_Retail = {
    DEATHKNIGHT = 49998,
    DEMONHUNTER = 185123,
    DRUID       = 5176,
    EVOKER      = 362969,
    HUNTER      = 75,
    MAGE        = 116,
    MONK        = 117952,
    PALADIN     = 20271,
    PRIEST      = 589,
    ROGUE       = 1752,
    SHAMAN      = 188196,
    WARLOCK     = 234153,
    WARRIOR     = 355,
}

MMF.FriendSpells_TBC = {
    DRUID   = 8936,
    MAGE    = 1459,
    PALADIN = 19750,
    PRIEST  = 2061,
    SHAMAN  = 331,
    WARLOCK = 5697,
}

MMF.HarmSpells_TBC = {
    DRUID   = 5176,
    HUNTER  = 75,
    MAGE    = 116,
    PALADIN = 20271,
    PRIEST  = 589,
    ROGUE   = 1752,
    SHAMAN  = 403,
    WARLOCK = 686,
    WARRIOR = 355,
}

MMF.FriendSpells = MMF.IsClassicEra and MMF.FriendSpells_TBC or MMF.FriendSpells_Retail
MMF.HarmSpells = MMF.IsClassicEra and MMF.HarmSpells_TBC or MMF.HarmSpells_Retail

--------------------------------------------------
-- AURA API COMPATIBILITY
--------------------------------------------------

-- Classic Era also exposes parts of C_UnitAuras, but its AuraUtil callback
-- shape is still the Classic one.  Treating API presence as a Retail signal
-- sends Era through the packed-aura path and produces empty aura lists.
MMF.HasRetailAuraAPI = MMF.IsRetail and (C_UnitAuras ~= nil)

local function IsSecretValue(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeAuraField(value)
    if IsSecretValue(value) then
        return nil
    end
    return value
end

local function CloneAuraData(aura, index)
    if type(aura) ~= "table" then
        return nil
    end

    -- C_UnitAuras aura tables can be pooled/reused internally.
    -- Copy fields we rely on so each entry remains stable for the current update pass.
    return {
        name = SafeAuraField(aura.name),
        icon = SafeAuraField(aura.icon),
        count = SafeAuraField(aura.count),
        applications = SafeAuraField(aura.applications),
        debuffType = SafeAuraField(aura.debuffType),
        dispelName = SafeAuraField(aura.dispelName),
        duration = SafeAuraField(aura.duration),
        expirationTime = SafeAuraField(aura.expirationTime),
        sourceUnit = SafeAuraField(aura.sourceUnit),
        source = SafeAuraField(aura.source),
        caster = SafeAuraField(aura.caster),
        isFromPlayerOrPlayerPet = SafeAuraField(aura.isFromPlayerOrPlayerPet),
        isFromPlayerOrPet = SafeAuraField(aura.isFromPlayerOrPet),
        castByPlayer = SafeAuraField(aura.castByPlayer),
        isPlayerAura = SafeAuraField(aura.isPlayerAura),
        isStealable = SafeAuraField(aura.isStealable),
        canApplyAura = SafeAuraField(aura.canApplyAura),
        isBossAura = SafeAuraField(aura.isBossAura),
        isHelpful = SafeAuraField(aura.isHelpful),
        isHarmful = SafeAuraField(aura.isHarmful),
        isNameplateOnly = SafeAuraField(aura.isNameplateOnly),
        spellId = SafeAuraField(aura.spellId),
        auraInstanceID = SafeAuraField(aura.auraInstanceID),
        _index = index or aura._index,
    }
end

function MMF.GetUnitAuras(unit, filter)
    local auras = {}
    local filterString = (type(filter) == "string" and filter ~= "") and filter or "HELPFUL"
    local isHelpful = filterString:find("HELPFUL", 1, true) ~= nil

    if MMF.HasRetailAuraAPI then
        -- Retail: use Blizzard's packed aura path (same pattern as FrameXML).
        if AuraUtil and AuraUtil.ForEachAura then
            local usePackedAura = true
            AuraUtil.ForEachAura(unit, filterString, 40, function(aura)
                if aura then
                    local auraCopy = CloneAuraData(aura, #auras + 1)
                    if auraCopy then
                        table.insert(auras, auraCopy)
                    end
                end
                return #auras >= 40
            end, usePackedAura)
            return auras
        end

        -- Retail hard fallback: direct C_UnitAuras indexed API only.
        local GetAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
        if GetAuraDataByIndex then
            for i = 1, 40 do
                local aura = GetAuraDataByIndex(unit, i, filterString)
                if not aura then
                    break
                end
                local auraCopy = CloneAuraData(aura, i)
                if auraCopy then
                    table.insert(auras, auraCopy)
                end
            end
        end
        return auras
    end

    -- Classic/TBC path.
    if AuraUtil and AuraUtil.ForEachAura then
        AuraUtil.ForEachAura(unit, filterString, 40, function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, _, spellId, ...)
            local value1, value2, value3 = ...
            if name then
                table.insert(auras, {
                    name = SafeAuraField(name),
                    icon = SafeAuraField(icon),
                    count = SafeAuraField(count),
                    debuffType = SafeAuraField(debuffType),
                    duration = SafeAuraField(duration),
                    expirationTime = SafeAuraField(expirationTime),
                    source = SafeAuraField(source),
                    spellId = SafeAuraField(spellId),
                    value1 = SafeAuraField(value1),
                    value2 = SafeAuraField(value2),
                    value3 = SafeAuraField(value3),
                    _index = #auras + 1,
                })
            end
            return #auras >= 40
        end)
    else
        local auraFunc = isHelpful and UnitBuff or UnitDebuff
        local unitFilter = nil
        if filterString:find("PLAYER", 1, true) then
            unitFilter = "PLAYER"
        end
        for i = 1, 40 do
            local name, icon, count, debuffType, duration, expirationTime, source, _, _, spellId, _, _, _, _, _, _, value1, value2, value3 = auraFunc(unit, i, unitFilter)
            if not name then break end
            table.insert(auras, {
                name = SafeAuraField(name),
                icon = SafeAuraField(icon),
                count = SafeAuraField(count),
                debuffType = SafeAuraField(debuffType),
                duration = SafeAuraField(duration),
                expirationTime = SafeAuraField(expirationTime),
                source = SafeAuraField(source),
                spellId = SafeAuraField(spellId),
                value1 = SafeAuraField(value1),
                value2 = SafeAuraField(value2),
                value3 = SafeAuraField(value3),
                _index = i,
            })
        end
    end
    
    return auras
end

function MMF.SetAuraCooldown(cooldownFrame, auraData, unit)
    if not cooldownFrame then return end
    
    if MMF.HasRetailAuraAPI and auraData.auraInstanceID then
        local GetAuraDuration = C_UnitAuras.GetAuraDuration
        local auraDuration = GetAuraDuration(unit, auraData.auraInstanceID)
        if auraDuration and cooldownFrame.SetCooldownFromDurationObject then
            cooldownFrame:SetCooldownFromDurationObject(auraDuration)
            return
        end
    end
    
    -- Check if duration is a secret value to avoid taint
    local isSecretDuration = issecretvalue and issecretvalue(auraData.duration)
    if not isSecretDuration then
        local ok, startTime, duration = pcall(function()
            if auraData.duration and auraData.duration > 0 and auraData.expirationTime then
                return auraData.expirationTime - auraData.duration, auraData.duration
            end
            return nil, nil
        end)
        if ok and startTime and duration then
            CooldownFrame_Set(cooldownFrame, startTime, duration, true)
            return
        end
    end
    cooldownFrame:Clear()
end

function MMF.GetAuraCount(auraData, unit)
    if MMF.HasRetailAuraAPI and auraData.auraInstanceID then
        local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
        if GetAuraApplicationDisplayCount then
            local count = GetAuraApplicationDisplayCount(unit, auraData.auraInstanceID, 2, 999)
            if type(count) == "number" then
                return count
            end
        end
        if auraData.applications and type(auraData.applications) == "number" then
            return auraData.applications
        end
    end
    return (auraData.count and type(auraData.count) == "number" and auraData.count) or 0
end

--------------------------------------------------
-- FEATURE FLAGS
--------------------------------------------------

MMF.HasDeathKnight = MMF.IsRetail
-- Vanilla Classic has no native focus unit. Do not expose controls or create a
-- secure unit frame that can never acquire a unit on Era.
MMF.HasFocusFrame = not MMF.IsClassic
MMF.HasSpecialization = MMF.IsRetail

--------------------------------------------------
-- DEBUG
--------------------------------------------------

function MMF.PrintVersion()
    local version = "Unknown"
    if MMF.IsRetail then version = "Retail"
    elseif MMF.IsTBC then version = "TBC Anniversary"
    elseif MMF.IsClassic then version = "Classic Era"
    end
    print("MattMinimalFrames running on: " .. version)
end

_G.MMF_Compat = MMF
