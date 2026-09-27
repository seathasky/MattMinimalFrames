local _, MMF = ...
MMF = MMF or {}





local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE or 1
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5
local WOW_PROJECT_CLASSIC = WOW_PROJECT_CLASSIC or 2
local interfaceVersion = select(4, GetBuildInfo())

MMF.IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
MMF.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)



MMF.IsForever = (WOW_PROJECT_FOREVER ~= nil and WOW_PROJECT_ID == WOW_PROJECT_FOREVER)
    or (WOW_PROJECT_CLASSIC_FOREVER ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC_FOREVER)
    or (interfaceVersion >= 16000 and interfaceVersion < 17000)
    or (interfaceVersion >= 160000 and interfaceVersion < 170000)
-- Explicit Forever identification takes precedence over the shared project ID.
MMF.IsRetail = not MMF.IsForever and (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
MMF.IsKnownProject = MMF.IsRetail or MMF.IsClassic or MMF.IsTBC or MMF.IsForever

MMF.HasPetHappiness = not MMF.IsRetail and (MMF.IsClassic or MMF.IsForever or MMF.IsTBC)

function MMF.GetPetHappiness()
    if not MMF.HasPetHappiness then return nil end
    local getter = C_PetInfo and C_PetInfo.GetPetHappiness
    if type(getter) ~= "function" then getter = _G.GetPetHappiness end
    if type(getter) == "function" then return getter() end
    return nil
end

MMF.IsClassicEra = not MMF.IsRetail
MMF_IsRetail = MMF.IsRetail
MMF_IsTBC = MMF.IsTBC
MMF_IsClassic = MMF.IsClassic
MMF_IsClassicEra = MMF.IsClassicEra

function MMF.IsBlizzardEditModeActive()
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

_G.MMF_IsBlizzardEditModeActive = MMF.IsBlizzardEditModeActive

function MMF.ShouldSuspendForBlizzardEditMode()
    
    
    if MMF_Designer and MMF_Designer.ready then return false end
    return MMF.IsBlizzardEditModeActive()
end
_G.MMF_ShouldSuspendForBlizzardEditMode = MMF.ShouldSuspendForBlizzardEditMode





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
    if MMF.IsRetail then
        local getter = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or _G.GetSpecialization
        if getter then return getter() end
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








MMF.HasRetailAuraAPI = C_UnitAuras ~= nil and type(C_UnitAuras.GetAuraDataByIndex)=="function"

function MMF.CanReadAuras()
    -- Check before calling an aura API: restricted clients can reject the call itself.
    if C_Secrets and type(C_Secrets.ShouldAurasBeSecret) == "function" then
        return not C_Secrets.ShouldAurasBeSecret()
    end
    -- Do not enumerate on a restricted build without a runtime access predicate.
    if type(GetBuildOption) == "function" and GetBuildOption("RestrictedAuraAPI") == true then
        return false
    end
    if C_Secrets and type(C_Secrets.HasSecretRestrictions) == "function" then
        return not C_Secrets.HasSecretRestrictions()
    end
    return true
end

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
    if not MMF.CanReadAuras() then return auras end
    local filterString = (type(filter) == "string" and filter ~= "") and filter or "HELPFUL"
    local isHelpful = filterString:find("HELPFUL", 1, true) ~= nil

    if MMF.HasRetailAuraAPI then
        
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
        if type(auraFunc) ~= "function" then return auras end
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
        local auraDuration = type(GetAuraDuration)=="function" and GetAuraDuration(unit, auraData.auraInstanceID) or nil
        if auraDuration and cooldownFrame.SetCooldownFromDurationObject then
            cooldownFrame:SetCooldownFromDurationObject(auraDuration)
            return
        end
    end
    
    
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





MMF.HasDeathKnight = MMF.IsRetail


MMF.HasFocusFrame = not MMF.IsClassic
MMF.HasSpecialization = MMF.IsRetail





function MMF.PrintVersion()
    local version = "Unknown"
    if MMF.IsRetail then version = "Retail"
    elseif MMF.IsTBC then version = "TBC Anniversary"
    elseif MMF.IsClassic then version = "Classic Era"
    end
    print("MattMinimalFrames running on: " .. version)
end

_G.MMF_Compat = MMF
