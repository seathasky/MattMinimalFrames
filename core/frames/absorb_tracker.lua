-- TBC/Classic absorb shield tracker.
-- The TBC Anniversary client exposes UnitGetTotalAbsorbs as a no-op stub,
-- so we approximate it by detecting known absorb buffs and decrementing
-- them from the combat log.

local Compat = _G.MMF_Compat
if not Compat or not Compat.IsClassicEra then
    return
end

-- spellID -> max absorb amount (base values, no talent multipliers).
-- The combat-log decrement keeps the displayed value honest even when
-- talents push the real cap higher.
local ABSORB_SPELLS = {
    -- Priest: Power Word: Shield
    [17]    = 44,
    [592]   = 88,
    [600]   = 158,
    [3747]  = 234,
    [6065]  = 301,
    [6066]  = 381,
    [10898] = 484,
    [10899] = 605,
    [10900] = 763,
    [10901] = 942,
    [25217] = 1125,
    [25218] = 1265,

    -- Warlock pet: Sacrifice (Imp).
    [7812]  = 30,
    [19438] = 65,
    [19440] = 130,
    [19441] = 220,
    [19442] = 340,
    [19443] = 500,
    [27273] = 730,

    -- Mage: Frost Ward
    [6143]  = 165,
    [8461]  = 290,
    [8462]  = 470,
    [10177] = 675,
    [28609] = 875,
    [32796] = 1075,

    -- Mage: Fire Ward
    [543]   = 165,
    [8457]  = 290,
    [8458]  = 470,
    [10223] = 675,
    [10225] = 875,
    [27128] = 1075,
    [43010] = 1450,

    -- Mage: Ice Barrier (self-only)
    [11426] = 138,
    [13031] = 205,
    [13032] = 290,
    [13033] = 365,
    [27134] = 455,
    [33405] = 550,
    [43038] = 730,
    [43039] = 1075,

    -- Mage: Mana Shield (drains mana but still acts as an absorb)
    [1463]  = 90,
    [8494]  = 152,
    [8495]  = 216,
    [10191] = 304,
    [10192] = 408,
    [10193] = 520,
    [27131] = 690,
    [43019] = 1075,

    -- Consumables: Stoneshield Potion / Ironshield Potion (best-effort).
    [4079]  = 1000,
    [11859] = 1500,
    [17540] = 2000,

    -- Soulshield (Warlock).
    [29858] = 1100,
}

-- Spells the local player sees on themselves only (mage personal wards).
local SELF_ONLY = {
    [11426]=true,[13031]=true,[13032]=true,[13033]=true,[27134]=true,[33405]=true,[43038]=true,[43039]=true,
    [1463]=true,[8494]=true,[8495]=true,[10191]=true,[10192]=true,[10193]=true,[27131]=true,[43019]=true,
    [6143]=true,[8461]=true,[8462]=true,[10177]=true,[28609]=true,[32796]=true,
    [543]=true,[8457]=true,[8458]=true,[10223]=true,[10225]=true,[27128]=true,[43010]=true,
}

-- shieldsByGUID[guid][spellID] = { amount = number, expirationTime = number }
local shieldsByGUID = {}

local UnitGUID = UnitGUID
local UnitBuff = UnitBuff
local GetTime = GetTime
local Compat_GetSpellName = Compat.GetSpellName

local function GetSpellName(spellID)
    return Compat_GetSpellName and Compat_GetSpellName(spellID)
end

local NAME_TO_SPELLID = {}
do
    for spellID in pairs(ABSORB_SPELLS) do
        local name = GetSpellName(spellID)
        if name then
            NAME_TO_SPELLID[name] = NAME_TO_SPELLID[name] or spellID
        end
    end
end

local function GetTotalAbsorbForGUID(guid)
    local shields = shieldsByGUID[guid]
    if not shields then return 0 end
    local total = 0
    local now = GetTime()
    for spellID, info in pairs(shields) do
        if info.expirationTime > 0 and info.expirationTime <= now then
            shields[spellID] = nil
        elseif info.amount > 0 then
            total = total + info.amount
        end
    end
    return total
end

function MMF_GetTotalAbsorbs(unit)
    if not unit then return 0 end
    local guid = UnitGUID(unit)
    if not guid then return 0 end
    return GetTotalAbsorbForGUID(guid)
end

local function ScanUnitBuffs(unit)
    if not unit or not UnitExists(unit) then return false end
    local guid = UnitGUID(unit)
    if not guid then return false end

    local isSelf = (unit == "player")
    local seen
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime, _, _, _, spellID = UnitBuff(unit, i)
        if not name then break end

        if not spellID and NAME_TO_SPELLID[name] then
            spellID = NAME_TO_SPELLID[name]
        end

        if spellID and ABSORB_SPELLS[spellID] then
            if not SELF_ONLY[spellID] or isSelf then
                seen = seen or {}
                seen[spellID] = expirationTime or 0
            end
        end
    end

    local shields = shieldsByGUID[guid]
    local changed = false

    if seen then
        shields = shields or {}
        shieldsByGUID[guid] = shields
        for spellID, expiration in pairs(seen) do
            local existing = shields[spellID]
            if not existing or existing.expirationTime ~= expiration then
                shields[spellID] = {
                    amount = ABSORB_SPELLS[spellID],
                    expirationTime = expiration,
                }
                changed = true
            end
        end
        for spellID in pairs(shields) do
            if not seen[spellID] then
                shields[spellID] = nil
                changed = true
            end
        end
        if next(shields) == nil then
            shieldsByGUID[guid] = nil
        end
    elseif shields then
        shieldsByGUID[guid] = nil
        changed = true
    end

    return changed
end

local UNIT_TOKENS = {
    "player", "target", "focus", "pet", "targettarget",
    "party1", "party2", "party3", "party4",
    "partypet1", "partypet2", "partypet3", "partypet4",
    "raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8",
    "raid9","raid10","raid11","raid12","raid13","raid14","raid15","raid16",
    "raid17","raid18","raid19","raid20","raid21","raid22","raid23","raid24",
    "raid25","raid26","raid27","raid28","raid29","raid30","raid31","raid32",
    "raid33","raid34","raid35","raid36","raid37","raid38","raid39","raid40",
    "boss1","boss2","boss3","boss4","boss5",
}

local function RefreshFramesForGUID(guid)
    if not guid or not MMF_GetFrameForUnit or not MMF_UpdateUnitFrame then return end
    for _, unit in ipairs(UNIT_TOKENS) do
        if UnitGUID(unit) == guid then
            local frame = MMF_GetFrameForUnit(unit)
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end
end

local function ApplyAbsorbedDamage(destGUID, absorbedAmount)
    if not destGUID or not absorbedAmount or absorbedAmount <= 0 then return end
    local shields = shieldsByGUID[destGUID]
    if not shields then return end

    local remaining = absorbedAmount
    local list = {}
    for spellID, info in pairs(shields) do
        list[#list + 1] = { spellID = spellID, info = info }
    end
    table.sort(list, function(a, b) return a.info.amount < b.info.amount end)

    for _, entry in ipairs(list) do
        if remaining <= 0 then break end
        local info = entry.info
        if info.amount <= remaining then
            remaining = remaining - info.amount
            shields[entry.spellID] = nil
        else
            info.amount = info.amount - remaining
            remaining = 0
        end
    end

    if next(shields) == nil then
        shieldsByGUID[destGUID] = nil
    end
    RefreshFramesForGUID(destGUID)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

frame:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "UNIT_AURA" then
        local unit = arg1
        if unit then
            local changed = ScanUnitBuffs(unit)
            if changed then
                local guid = UnitGUID(unit)
                RefreshFramesForGUID(guid)
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        ScanUnitBuffs("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        ScanUnitBuffs("focus")
    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(shieldsByGUID)
        ScanUnitBuffs("player")
        ScanUnitBuffs("target")
        ScanUnitBuffs("focus")
    elseif event == "GROUP_ROSTER_UPDATE" then
        for i = 1, 4 do ScanUnitBuffs("party" .. i) end
        for i = 1, 40 do ScanUnitBuffs("raid" .. i) end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        -- CLEU header is 11 fields, then payload.
        local _, subEvent, _,
              _, _, _, _,
              destGUID, _, _, _,
              p1, p2, p3, p4, p5, p6, p7, p8, p9 = CombatLogGetCurrentEventInfo()
        if not destGUID or not shieldsByGUID[destGUID] then return end

        local absorbed = 0
        if subEvent == "SWING_DAMAGE" then
            absorbed = tonumber(p6) or 0
        elseif subEvent == "SWING_MISSED" then
            if p1 == "ABSORB" then absorbed = tonumber(p3) or 0 end
        elseif subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE"
            or subEvent == "RANGE_DAMAGE" then
            absorbed = tonumber(p9) or 0
        elseif subEvent == "SPELL_MISSED" or subEvent == "SPELL_PERIODIC_MISSED"
            or subEvent == "RANGE_MISSED" then
            if p4 == "ABSORB" then absorbed = tonumber(p6) or 0 end
        elseif subEvent == "ENVIRONMENTAL_DAMAGE" then
            absorbed = tonumber(p7) or 0
        end

        if absorbed > 0 then
            ApplyAbsorbedDamage(destGUID, absorbed)
        end
    end
end)

_G.MMF_GetTotalAbsorbs = MMF_GetTotalAbsorbs

-- /mmfabsorb — list currently tracked shields on player/target/focus.
SLASH_MMFABSORB1 = "/mmfabsorb"
SlashCmdList["MMFABSORB"] = function()
    local function report(label, unit)
        if not UnitExists(unit) then return end
        local guid = UnitGUID(unit)
        local total = GetTotalAbsorbForGUID(guid)
        local name = UnitName(unit) or "?"
        print(string.format("|cff62d4ffMMF Absorb|r [%s=%s] total=%d", label, name, total))
        local shields = shieldsByGUID[guid]
        if shields then
            for spellID, info in pairs(shields) do
                local sname = GetSpellName(spellID) or ("spell " .. spellID)
                print(string.format("   - %s (id=%d): %d remaining, expires=%.1fs",
                    sname, spellID, info.amount,
                    info.expirationTime > 0 and (info.expirationTime - GetTime()) or -1))
            end
        end
    end
    report("player", "player")
    report("target", "target")
    report("focus",  "focus")
end
