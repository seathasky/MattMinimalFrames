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

MMF.HasRetailAuraAPI = (C_UnitAuras ~= nil) and not MMF.IsTBC

function MMF.GetUnitAuras(unit, filter)
    local auras = {}
    local isHelpful = (filter == "HELPFUL")
    
    if MMF.HasRetailAuraAPI then
        local GetAuraSlots = C_UnitAuras.GetAuraSlots
        local GetAuraDataBySlot = C_UnitAuras.GetAuraDataBySlot
        
        local token
        repeat
            local slots = {GetAuraSlots(unit, filter, 40, token)}
            token = table.remove(slots, 1)
            for _, slot in ipairs(slots) do
                local aura = GetAuraDataBySlot(unit, slot)
                if aura then
                    table.insert(auras, aura)
                end
            end
        until not token
    else
        if AuraUtil and AuraUtil.ForEachAura then
            local filterString = isHelpful and "HELPFUL" or "HARMFUL"
            AuraUtil.ForEachAura(unit, filterString, 40, function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, _, spellId, ...)
                if name then
                    table.insert(auras, {
                        name = name,
                        icon = icon,
                        count = count,
                        debuffType = debuffType,
                        duration = duration,
                        expirationTime = expirationTime,
                        source = source,
                        spellId = spellId,
                    })
                end
                return #auras >= 40
            end)
        else
            local auraFunc = isHelpful and UnitBuff or UnitDebuff
            for i = 1, 40 do
                local name, icon, count, debuffType, duration, expirationTime, source, _, _, spellId = auraFunc(unit, i)
                if not name then break end
                table.insert(auras, {
                    name = name,
                    icon = icon,
                    count = count,
                    debuffType = debuffType,
                    duration = duration,
                    expirationTime = expirationTime,
                    source = source,
                    spellId = spellId,
                })
            end
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
MMF.HasFocusFrame = true
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
