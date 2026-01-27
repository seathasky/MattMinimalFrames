-- core/compat.lua
-- Centralized compatibility layer for Retail and TBC Anniversary

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

-- Export to global for easy access
MMF_IsRetail = MMF.IsRetail
MMF_IsTBC = MMF.IsTBC
MMF_IsClassic = MMF.IsClassic
MMF_IsClassicEra = MMF.IsClassicEra

--------------------------------------------------
-- API COMPATIBILITY
--------------------------------------------------

-- GetSpellInfo: Works differently in retail vs classic
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

-- IsSpellInRange: Different API location
MMF.IsSpellInRange = _G.IsSpellInRange
if C_Spell and C_Spell.IsSpellInRange then
    MMF.IsSpellInRange = C_Spell.IsSpellInRange
end

-- GetSpecialization: Only exists in retail
function MMF.GetSpecialization()
    if MMF.IsRetail and _G.GetSpecialization then
        return _G.GetSpecialization()
    end
    return nil
end

--------------------------------------------------
-- RANGE CHECK SPELL TABLES
--------------------------------------------------

-- Retail spells (includes all modern classes)
MMF.FriendSpells_Retail = {
    DEATHKNIGHT = 47541,  -- Death Coil
    DRUID       = 8936,   -- Regrowth
    EVOKER      = 355913, -- Emerald Blossom
    MAGE        = 1459,   -- Arcane Intellect
    MONK        = 116670, -- Vivify
    PALADIN     = 19750,  -- Flash of Light
    PRIEST      = 2061,   -- Flash Heal
    SHAMAN      = 8004,   -- Healing Surge
    WARLOCK     = 5697,   -- Unending Breath
}

MMF.HarmSpells_Retail = {
    DEATHKNIGHT = 49998,  -- Death Strike
    DEMONHUNTER = 185123, -- Throw Glaive
    DRUID       = 5176,   -- Wrath
    EVOKER      = 362969, -- Azure Strike
    HUNTER      = 75,     -- Auto Shot
    MAGE        = 116,    -- Frostbolt
    MONK        = 117952, -- Crackling Jade Lightning
    PALADIN     = 20271,  -- Judgment
    PRIEST      = 589,    -- Shadow Word: Pain
    ROGUE       = 1752,   -- Sinister Strike
    SHAMAN      = 188196, -- Lightning Bolt
    WARLOCK     = 234153, -- Drain Life
    WARRIOR     = 355,    -- Taunt
}

-- TBC spells (only classes that exist in TBC)
MMF.FriendSpells_TBC = {
    DRUID   = 8936,  -- Regrowth (40 yd)
    MAGE    = 1459,  -- Arcane Intellect (30 yd)
    PALADIN = 19750, -- Flash of Light (40 yd)
    PRIEST  = 2061,  -- Flash Heal (40 yd)
    SHAMAN  = 331,   -- Healing Wave (40 yd)
    WARLOCK = 5697,  -- Unending Breath (30 yd)
}

MMF.HarmSpells_TBC = {
    DRUID   = 5176,  -- Wrath (30 yd)
    HUNTER  = 75,    -- Auto Shot
    MAGE    = 116,   -- Frostbolt (30 yd)
    PALADIN = 20271, -- Judgment (10 yd)
    PRIEST  = 589,   -- Shadow Word: Pain (30 yd)
    ROGUE   = 1752,  -- Sinister Strike (melee)
    SHAMAN  = 403,   -- Lightning Bolt (30 yd)
    WARLOCK = 686,   -- Shadow Bolt (30 yd)
    WARRIOR = 355,   -- Taunt (25 yd)
}

-- Select appropriate tables based on version
MMF.FriendSpells = MMF.IsTBC and MMF.FriendSpells_TBC or MMF.FriendSpells_Retail
MMF.HarmSpells = MMF.IsTBC and MMF.HarmSpells_TBC or MMF.HarmSpells_Retail

--------------------------------------------------
-- AURA API COMPATIBILITY
--------------------------------------------------

-- Check if we have retail aura API
MMF.HasRetailAuraAPI = (C_UnitAuras ~= nil) and not MMF.IsTBC

-- Process auras - returns a normalized table regardless of API
function MMF.GetUnitAuras(unit, filter)
    local auras = {}
    local isHelpful = (filter == "HELPFUL")
    
    if MMF.HasRetailAuraAPI then
        -- Retail: Use C_UnitAuras
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
        -- TBC/Classic: Use AuraUtil or UnitBuff/UnitDebuff
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
            -- Fallback to UnitBuff/UnitDebuff
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

-- Set cooldown on aura icon (different APIs)
function MMF.SetAuraCooldown(cooldownFrame, auraData, unit)
    if not cooldownFrame then return end
    
    if MMF.HasRetailAuraAPI and auraData.auraInstanceID then
        -- Retail: Use duration object
        local GetAuraDuration = C_UnitAuras.GetAuraDuration
        local auraDuration = GetAuraDuration(unit, auraData.auraInstanceID)
        if auraDuration and cooldownFrame.SetCooldownFromDurationObject then
            cooldownFrame:SetCooldownFromDurationObject(auraDuration)
            return
        end
    end
    
    -- TBC/Classic: Use CooldownFrame_Set
    if auraData.duration and auraData.duration > 0 and auraData.expirationTime then
        CooldownFrame_Set(cooldownFrame, auraData.expirationTime - auraData.duration, auraData.duration, true)
    else
        cooldownFrame:Clear()
    end
end

-- Get aura stack count
function MMF.GetAuraCount(auraData, unit)
    if MMF.HasRetailAuraAPI and auraData.auraInstanceID then
        local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
        if GetAuraApplicationDisplayCount then
            local count = GetAuraApplicationDisplayCount(unit, auraData.auraInstanceID, 2, 999)
            -- Retail API can return empty string or non-number; ensure we always return a number
            if type(count) == "number" then
                return count
            end
        end
        -- Fallback to applications field in retail aura data
        if auraData.applications and type(auraData.applications) == "number" then
            return auraData.applications
        end
    end
    -- TBC/Classic fallback
    return (auraData.count and type(auraData.count) == "number" and auraData.count) or 0
end

--------------------------------------------------
-- FEATURE FLAGS
--------------------------------------------------

-- Death Knight features (doesn't exist in TBC)
MMF.HasDeathKnight = MMF.IsRetail

-- Focus frame (exists in TBC)
MMF.HasFocusFrame = true

-- Specialization system
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

-- Make MMF table globally accessible
_G.MMF_Compat = MMF
