local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = DeepCopy(v)
    end
    return out
end

local function ApplyDefaultsSafe(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = DeepCopy(value)
        elseif type(target[key]) == "table" and type(value) == "table" then
            ApplyDefaultsSafe(target[key], value)
        end
    end
end

local function NormalizeLegacyIconModes(db)
    if type(db) ~= "table" then
        return
    end
    if db.playerFrameIconMode == nil and db.showPlayerClassIcon ~= nil then
        db.playerFrameIconMode = db.showPlayerClassIcon and "class" or "off"
    end
    if db.targetFrameIconMode == nil and db.showTargetFrameIcon ~= nil then
        db.targetFrameIconMode = db.showTargetFrameIcon and "class" or "off"
    end
end

local function NormalizeLegacyPartyRaidFontSetting(db)
    if type(db) ~= "table" then
        return
    end
    if db.useNaowhPartyRaidNames ~= nil then
        if db.useSharedPartyRaidNameFont == nil then
            db.useSharedPartyRaidNameFont = (db.useNaowhPartyRaidNames == true)
        elseif db.useNaowhPartyRaidNames == true and db.useSharedPartyRaidNameFont ~= true then
            db.useSharedPartyRaidNameFont = true
        end
        db.useNaowhPartyRaidNames = nil
    end
    if db.partyNameFontSize == nil then
        db.partyNameFontSize = tonumber(db.partyRaidNameFontSize) or 16
    end
    if db.raidNameFontSize == nil then
        db.raidNameFontSize = tonumber(db.partyRaidNameFontSize) or 16
    end
    if db.partyNameTruncateLength == nil then
        db.partyNameTruncateLength = 0
    end
end

local function NormalizeGUIScaleSetting()
    if not MattMinimalFramesDB or not MMF_ClampGUIScale then
        return
    end
    MattMinimalFramesDB.guiScale = MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)
end

local function NormalizeLegacyTextEffectsSetting(db)
    if type(db) ~= "table" then
        return
    end
    if db.useTextShadow == nil then
        if db.useTextOutline == false then
            db.useTextShadow = false
        else
            db.useTextShadow = true
        end
    end
end

_G.MMF_Startup_ApplyDefaultsSafe = ApplyDefaultsSafe
_G.MMF_Startup_NormalizeLegacyIconModes = NormalizeLegacyIconModes
_G.MMF_Startup_NormalizeLegacyPartyRaidFontSetting = NormalizeLegacyPartyRaidFontSetting
_G.MMF_Startup_NormalizeGUIScaleSetting = NormalizeGUIScaleSetting
_G.MMF_Startup_NormalizeLegacyTextEffectsSetting = NormalizeLegacyTextEffectsSetting
