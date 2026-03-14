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

local PROFILE_DB_VERSION = 4

local function ApplyDefaults(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then return end
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = DeepCopy(value)
        elseif type(target[key]) == "table" and type(value) == "table" then
            ApplyDefaults(target[key], value)
        end
    end
end

local function NormalizeMediaName(value)
    if type(value) ~= "string" then
        return nil
    end
    local trimmed = value:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return nil
    end
    return trimmed
end

local function NormalizePositiveNumber(value, fallback)
    local num = tonumber(value)
    if type(num) ~= "number" or num ~= num or num <= 0 then
        num = fallback
    end
    return num
end

local function NormalizeToggle(value)
    return (value == true or value == 1)
end

local VALID_TEXT_SIZE_UNITS = {
    player = true,
    target = true,
    targettarget = true,
    pet = true,
    focus = true,
    boss = true,
    playerCastBar = true,
    targetCastBar = true,
}

local function SanitizeProfileTextSettings(profile)
    if type(profile) ~= "table" then
        return
    end

    profile.nameTextSize = NormalizePositiveNumber(profile.nameTextSize, 12)
    profile.hpTextSize = NormalizePositiveNumber(profile.hpTextSize, 13)

    local unitPrefixes = { "player", "target", "tot", "pet", "focus", "boss" }
    for _, prefix in ipairs(unitPrefixes) do
        local nameKey = prefix .. "NameTextSize"
        if profile[nameKey] ~= nil then
            profile[nameKey] = NormalizePositiveNumber(profile[nameKey], profile.nameTextSize)
        end

        local hpKey = prefix .. "HPTextSize"
        if profile[hpKey] ~= nil then
            profile[hpKey] = NormalizePositiveNumber(profile[hpKey], profile.hpTextSize)
        end
    end

    local castbarPrefixes = { "playerCastBar", "targetCastBar" }
    for _, prefix in ipairs(castbarPrefixes) do
        local spellNameKey = prefix .. "SpellNameTextSize"
        if profile[spellNameKey] ~= nil then
            profile[spellNameKey] = NormalizePositiveNumber(profile[spellNameKey], profile.nameTextSize)
        end

        local castTimeKey = prefix .. "CastTimeTextSize"
        if profile[castTimeKey] ~= nil then
            profile[castTimeKey] = NormalizePositiveNumber(profile[castTimeKey], 9)
        end
    end

    profile.powerTextScale = NormalizePositiveNumber(profile.powerTextScale, 1.0)
    profile.playerPowerTextScale = NormalizePositiveNumber(profile.playerPowerTextScale, profile.powerTextScale)
    profile.targetPowerTextScale = NormalizePositiveNumber(profile.targetPowerTextScale, profile.powerTextScale)

    local normalizedFont = NormalizeMediaName(profile.globalFont)
    if normalizedFont then
        profile.globalFont = normalizedFont
    else
        profile.globalFont = "MMF Naowh"
    end

    if type(profile.textSizeUnit) ~= "string" or not VALID_TEXT_SIZE_UNITS[profile.textSizeUnit] then
        profile.textSizeUnit = "player"
    end

    local hideTextKeys = {
        "playerHideNameText",
        "targetHideNameText",
        "totHideNameText",
        "petHideNameText",
        "focusHideNameText",
        "bossHideNameText",
        "playerHideHPText",
        "targetHideHPText",
        "totHideHPText",
        "petHideHPText",
        "focusHideHPText",
        "bossHideHPText",
    }
    for _, key in ipairs(hideTextKeys) do
        profile[key] = NormalizeToggle(profile[key])
    end
    profile.hideBossFrames = NormalizeToggle(profile.hideBossFrames)
end

local function MigrateProfile(profile)
    if type(profile) ~= "table" then return end

    local version = tonumber(profile.dbVersion) or 0

    if version < 1 then
        if profile.playerFrameIconMode == nil and profile.showPlayerClassIcon ~= nil then
            profile.playerFrameIconMode = profile.showPlayerClassIcon and "class" or "off"
        end
        if profile.targetFrameIconMode == nil and profile.showTargetFrameIcon ~= nil then
            profile.targetFrameIconMode = profile.showTargetFrameIcon and "class" or "off"
        end
    end

    if version < 2 then
        if type(profile.minimap) ~= "table" then
            profile.minimap = {}
        end
        if profile.minimap.hide == nil then
            profile.minimap.hide = false
        end
    end

    if version < 3 then
        -- New name-overflow features should start disabled for existing profiles.
        profile.enableNameTruncation = false
        profile.autoResizeTextOnLongName = false
        local len = tonumber(profile.nameTruncationLength) or 14
        if len < 5 then len = 5 end
        if len > 30 then len = 30 end
        profile.nameTruncationLength = len
    end

    if version < 4 then
        -- Safety migration: force both toggles off so neither feature is enabled by default.
        profile.enableNameTruncation = false
        profile.autoResizeTextOnLongName = false
        local len = tonumber(profile.nameTruncationLength) or 14
        if len < 5 then len = 5 end
        if len > 30 then len = 30 end
        profile.nameTruncationLength = len
    end

    profile.dbVersion = PROFILE_DB_VERSION
end

local PROFILE_LAYOUT_KEYS = {
    "MMF_PlayerFrame",
    "MMF_TargetFrame",
    "MMF_TargetOfTargetFrame",
    "MMF_PetFrame",
    "MMF_FocusFrame",
    "MMF_Boss1Frame",
    "MMF_Boss2Frame",
    "MMF_Boss3Frame",
    "MMF_Boss4Frame",
    "MMF_Boss5Frame",
    "powerBarPositions",
    "powerTextPositions",
    "castBarPositions",
    "popupPosition",
}

local function ClearLayoutState(profile)
    if type(profile) ~= "table" then return end
    for _, key in ipairs(PROFILE_LAYOUT_KEYS) do
        profile[key] = nil
    end
end

local function GetCurrentCharacterKey()
    local name, realm = UnitFullName and UnitFullName("player")
    if type(name) == "string" and name ~= "" then
        if type(realm) == "string" and realm ~= "" then
            return name .. "-" .. realm
        end
        return name
    end

    local fullName = GetUnitName and GetUnitName("player", true)
    if type(fullName) == "string" and fullName ~= "" then
        return fullName
    end

    name = UnitName and UnitName("player")
    if type(name) ~= "string" or name == "" then
        return nil
    end

    realm = GetRealmName and GetRealmName()
    if type(realm) == "string" and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

local function SetCurrentCharacterProfile(profileName)
    if type(profileName) ~= "string" or profileName == "" then
        return
    end
    local characterKey = GetCurrentCharacterKey()
    if type(characterKey) ~= "string" or characterKey == "" then
        return
    end
    MattMinimalFramesProfilesDB.characterProfiles[characterKey] = profileName
end

local function ApplyCharacterProfilePreference()
    if type(MattMinimalFramesProfilesDB.profiles.Default) ~= "table" then
        MattMinimalFramesProfilesDB.profiles.Default = {}
    end

    local characterKey = GetCurrentCharacterKey()
    if type(characterKey) ~= "string" or characterKey == "" then
        MattMinimalFramesProfilesDB.activeProfile = "Default"
        return
    end

    local mappedProfile = MattMinimalFramesProfilesDB.characterProfiles[characterKey]
    if type(mappedProfile) == "string" and mappedProfile ~= "" and type(MattMinimalFramesProfilesDB.profiles[mappedProfile]) == "table" then
        MattMinimalFramesProfilesDB.activeProfile = mappedProfile
        return
    end

    MattMinimalFramesProfilesDB.activeProfile = "Default"
    MattMinimalFramesProfilesDB.characterProfiles[characterKey] = "Default"
end

local function EnsureProfilesRoot()
    if type(MattMinimalFramesProfilesDB) ~= "table" then
        MattMinimalFramesProfilesDB = {}
    end
    if type(MattMinimalFramesProfilesDB.profiles) ~= "table" then
        MattMinimalFramesProfilesDB.profiles = {}
    end
    if type(MattMinimalFramesProfilesDB.characterProfiles) ~= "table" then
        MattMinimalFramesProfilesDB.characterProfiles = {}
    end
    if type(MattMinimalFramesProfilesDB.activeProfile) ~= "string" or MattMinimalFramesProfilesDB.activeProfile == "" then
        MattMinimalFramesProfilesDB.activeProfile = "Default"
    end
    if type(MattMinimalFramesProfilesDB.schemaVersion) ~= "number" then
        MattMinimalFramesProfilesDB.schemaVersion = 1
    end
end

local function SanitizeProfilesMap()
    for name, profile in pairs(MattMinimalFramesProfilesDB.profiles) do
        if type(name) ~= "string" or name == "" or type(profile) ~= "table" then
            MattMinimalFramesProfilesDB.profiles[name] = nil
        end
    end
    if not next(MattMinimalFramesProfilesDB.profiles) then
        MattMinimalFramesProfilesDB.profiles["Default"] = {}
    end
end

local function SanitizeCharacterProfilesMap()
    for characterKey, profileName in pairs(MattMinimalFramesProfilesDB.characterProfiles) do
        if type(characterKey) ~= "string" or characterKey == "" or type(profileName) ~= "string" or profileName == "" then
            MattMinimalFramesProfilesDB.characterProfiles[characterKey] = nil
        elseif type(MattMinimalFramesProfilesDB.profiles[profileName]) ~= "table" then
            MattMinimalFramesProfilesDB.characterProfiles[characterKey] = nil
        end
    end
end

local function MigrateLegacyDBIntoDefault()
    local hasProfiles = false
    for _ in pairs(MattMinimalFramesProfilesDB.profiles) do
        hasProfiles = true
        break
    end
    if hasProfiles then return end

    local legacy = type(MattMinimalFramesDB) == "table" and MattMinimalFramesDB or {}
    MattMinimalFramesProfilesDB.profiles["Default"] = DeepCopy(legacy)
    MattMinimalFramesProfilesDB.activeProfile = "Default"
end

local function EnsureProfile(name)
    if type(name) ~= "string" or name == "" then
        name = "Default"
    end
    if type(MattMinimalFramesProfilesDB.profiles[name]) ~= "table" then
        MattMinimalFramesProfilesDB.profiles[name] = {}
    end
    local profile = MattMinimalFramesProfilesDB.profiles[name]
    MigrateProfile(profile)
    if type(MattMinimalFrames_Defaults) == "table" then
        ApplyDefaults(profile, MattMinimalFrames_Defaults)
    end
    -- Normalize persisted checkbox values (`true/false` vs `1/nil`/stringy values).
    profile.enableNameTruncation = (profile.enableNameTruncation == true or profile.enableNameTruncation == 1)
    profile.autoResizeTextOnLongName = (profile.autoResizeTextOnLongName == true or profile.autoResizeTextOnLongName == 1)
    local len = tonumber(profile.nameTruncationLength) or 14
    if len < 5 then len = 5 end
    if len > 30 then len = 30 end
    profile.nameTruncationLength = len
    SanitizeProfileTextSettings(profile)
    profile.dbVersion = PROFILE_DB_VERSION
    return profile
end

local function EnsureAllProfiles()
    for name in pairs(MattMinimalFramesProfilesDB.profiles) do
        EnsureProfile(name)
    end
end

local function EnsureActiveProfileExists()
    local active = MattMinimalFramesProfilesDB.activeProfile
    if type(active) ~= "string" or active == "" then
        active = "Default"
        MattMinimalFramesProfilesDB.activeProfile = active
    end
    if type(MattMinimalFramesProfilesDB.profiles[active]) ~= "table" then
        MattMinimalFramesProfilesDB.activeProfile = "Default"
        EnsureProfile("Default")
    end
end

local function BindActiveProfile()
    local name = MattMinimalFramesProfilesDB.activeProfile
    local profile = EnsureProfile(name)
    MattMinimalFramesDB = profile
end

local function ResolveAndBindCharacterProfile()
    EnsureActiveProfileExists()
    SanitizeCharacterProfilesMap()
    local previousActiveProfile = MattMinimalFramesProfilesDB.activeProfile
    ApplyCharacterProfilePreference()
    EnsureActiveProfileExists()
    BindActiveProfile()
    return previousActiveProfile ~= MattMinimalFramesProfilesDB.activeProfile
end

function MMF_Profiles_Initialize()
    EnsureProfilesRoot()
    SanitizeProfilesMap()
    MigrateLegacyDBIntoDefault()
    EnsureProfile("Default")
    EnsureAllProfiles()
    ResolveAndBindCharacterProfile()
end

function MMF_NormalizeActiveProfile()
    EnsureProfilesRoot()
    SanitizeProfilesMap()
    EnsureProfile("Default")
    EnsureAllProfiles()
    ResolveAndBindCharacterProfile()
end

function MMF_ResolveCharacterProfile(applyLive)
    EnsureProfilesRoot()
    SanitizeProfilesMap()
    EnsureProfile("Default")
    EnsureAllProfiles()
    local profileChanged = ResolveAndBindCharacterProfile()

    if applyLive and MMF_ApplyActiveProfileLive then
        MMF_ApplyActiveProfileLive()
    end

    return profileChanged, MMF_GetActiveProfileName()
end

function MMF_GetActiveProfileName()
    if type(MattMinimalFramesProfilesDB) ~= "table" then return "Default" end
    return MattMinimalFramesProfilesDB.activeProfile or "Default"
end

function MMF_GetProfileNames()
    if type(MattMinimalFramesProfilesDB) ~= "table" or type(MattMinimalFramesProfilesDB.profiles) ~= "table" then
        return { "Default" }
    end
    local list = {}
    for name in pairs(MattMinimalFramesProfilesDB.profiles) do
        list[#list + 1] = name
    end
    if #list == 0 then
        list[1] = "Default"
    end
    table.sort(list, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    return list
end

function MMF_SwitchProfile(name)
    if type(name) ~= "string" or name == "" then return false end
    EnsureProfilesRoot()
    if type(MattMinimalFramesProfilesDB.profiles[name]) ~= "table" then
        return false
    end
    MattMinimalFramesProfilesDB.activeProfile = name
    SetCurrentCharacterProfile(name)
    BindActiveProfile()
    if MMF_ApplyActiveProfileLive then
        MMF_ApplyActiveProfileLive()
    end
    return true
end

function MMF_CreateProfile(name, copyFrom)
    if type(name) ~= "string" then return false, "Invalid name" end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return false, "Profile name is empty" end
    EnsureProfilesRoot()
    if MattMinimalFramesProfilesDB.profiles[name] then
        return false, "Profile already exists"
    end

    local source = {}
    local isBlankProfile = (copyFrom == false)
    if copyFrom == nil then
        local sourceName = MMF_GetActiveProfileName()
        source = MattMinimalFramesProfilesDB.profiles[sourceName] or {}
    elseif type(copyFrom) == "string" and copyFrom ~= "" then
        source = MattMinimalFramesProfilesDB.profiles[copyFrom] or {}
    elseif copyFrom == false then
        source = {}
    end
    MattMinimalFramesProfilesDB.profiles[name] = DeepCopy(source)
    if isBlankProfile then
        ClearLayoutState(MattMinimalFramesProfilesDB.profiles[name])
    end
    EnsureProfile(name)
    return true
end

function MMF_DeleteProfile(name)
    if type(name) ~= "string" or name == "" then return false end
    EnsureProfilesRoot()
    if name == "Default" then return false end
    if name == MMF_GetActiveProfileName() then return false end
    if not MattMinimalFramesProfilesDB.profiles[name] then return false end
    MattMinimalFramesProfilesDB.profiles[name] = nil
    for characterKey, profileName in pairs(MattMinimalFramesProfilesDB.characterProfiles) do
        if profileName == name then
            MattMinimalFramesProfilesDB.characterProfiles[characterKey] = nil
        end
    end
    return true
end

function MMF_ResetProfile(name)
    EnsureProfilesRoot()
    local profileName = name or MMF_GetActiveProfileName()
    if type(profileName) ~= "string" or profileName == "" then
        profileName = "Default"
    end
    MattMinimalFramesProfilesDB.profiles[profileName] = {}
    EnsureProfile(profileName)
    if profileName == MMF_GetActiveProfileName() then
        BindActiveProfile()
        if MMF_ApplyActiveProfileLive then
            MMF_ApplyActiveProfileLive()
        end
    end
    return true
end

function MMF_ResetActiveProfile()
    return MMF_ResetProfile(MMF_GetActiveProfileName())
end
