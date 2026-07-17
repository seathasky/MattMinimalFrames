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

local function NormalizeLegacyHPTextPosition(db)
    if type(db) ~= "table" then return end
    if db.hpTextPositionMigrated then return end
    db.hpTextPositionMigrated = true
    -- Default Y shifted from -14.5 to 8 (inside the frame). Shift any saved positions by the same delta.
    local delta = 22.5
    local positions = db.hpTextPositions
    if type(positions) == "table" then
        for _, unit in ipairs({ "player", "target" }) do
            local pos = positions[unit]
            if type(pos) == "table" and type(pos.y) == "number" then
                pos.y = pos.y + delta
            end
        end
    end
end

local function NormalizeLegacyPowerBarDefaults(db)
    if type(db) ~= "table" then return end
    if not db.powerBarLayoutMigrated then
        db.powerBarLayoutMigrated = true
        db.showPlayerPowerBar = true
        db.playerPowerBarWidth = 218
        db.playerPowerBarHeight = 3
        db.showPlayerPowerText = true
        db.colorPlayerPowerTextByResource = true
        -- Reset saved bar/text positions so they pick up the new attached-bottom defaults
        if type(db.powerBarPositions) == "table" then
            db.powerBarPositions["player"] = nil
        end
        if type(db.powerTextPositions) == "table" then
            db.powerTextPositions["player"] = nil
        end
    end

    if not db.targetPowerBarLayoutMigrated then
        db.targetPowerBarLayoutMigrated = true
        db.showTargetPowerBar = true
        db.targetPowerBarWidth = 218
        db.targetPowerBarHeight = 3
        -- Reset the old short bar position so target uses the attached-bottom default.
        if type(db.powerBarPositions) == "table" then
            db.powerBarPositions["target"] = nil
        end
    end

    if not db.targetPowerTextDefaultsMigrated then
        db.targetPowerTextDefaultsMigrated = true
        db.showTargetPowerText = true
        db.colorTargetPowerTextByResource = true
    end

    if not db.targetPowerTextPositionMigrated then
        db.targetPowerTextPositionMigrated = true
        if type(db.powerTextPositions) == "table" then
            db.powerTextPositions["target"] = nil
        end
        local targetScale = tonumber(db.targetPowerTextScale)
        if targetScale == nil or math.abs(targetScale - 1.0) < 0.0001 then
            db.targetPowerTextScale = 0.77
        end
    end
end

_G.MMF_Startup_ApplyDefaultsSafe = ApplyDefaultsSafe
_G.MMF_Startup_NormalizeLegacyIconModes = NormalizeLegacyIconModes
_G.MMF_Startup_NormalizeLegacyPartyRaidFontSetting = NormalizeLegacyPartyRaidFontSetting
_G.MMF_Startup_NormalizeGUIScaleSetting = NormalizeGUIScaleSetting
_G.MMF_Startup_NormalizeLegacyTextEffectsSetting = NormalizeLegacyTextEffectsSetting
_G.MMF_Startup_NormalizeLegacyHPTextPosition = NormalizeLegacyHPTextPosition
local function NormalizeLegacyTextSizes(db)
    if type(db) ~= "table" then return end
    if db.textSizeMigratedV1 then return end
    db.textSizeMigratedV1 = true
    db.hpTextSize = 10
    db.playerPowerTextScale = 0.77
end

_G.MMF_Startup_NormalizeLegacyPowerBarDefaults = NormalizeLegacyPowerBarDefaults
_G.MMF_Startup_NormalizeLegacyTextSizes = NormalizeLegacyTextSizes
