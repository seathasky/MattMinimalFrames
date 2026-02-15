MMF_Config = {
    POWER_BAR_WIDTH = 73,
    POWER_BAR_HEIGHT = 5,
    POWER_BAR_VERTICAL_OFFSET = -24,
    POWER_BAR_HORIZONTAL_OFFSET = 1,
    AURA_ICON_SPACING = 2,
    MAX_AURA_ICONS = 12,
    AURA_ROW_ICONS = 4,
    UPDATE_INTERVAL = 0.1,
    FONT_PATH = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf",
    TEXTURE_PATH = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga",
    SHIELD_TEXTURE_PATH = "Interface\\AddOns\\MattMinimalFrames\\Textures\\shield.tga",
    FRAME_DEFINITIONS = {
        { unit = "player",       name = "MMF_PlayerFrame",         width = 220, height = 28, x = -150, y = 0,    label = "Player Frame" },
        { unit = "target",       name = "MMF_TargetFrame",         width = 220, height = 28, x = 150,  y = 0,    label = "Target Frame" },
        { unit = "targettarget", name = "MMF_TargetOfTargetFrame", width = 100, height = 28, x = 0,    y = -100, label = "Target of Target" },
        { unit = "pet",          name = "MMF_PetFrame",            width = 100, height = 28, x = -300, y = -100, label = "Pet Frame" },
        { unit = "focus",        name = "MMF_FocusFrame",          width = 100, height = 28, x = 300,  y = -100, label = "Focus Frame" },
    },
    CAST_BAR_COLORS = {
        { value = "white",  label = "White",   r = 1,   g = 1,   b = 1 },
        { value = "yellow", label = "Yellow",  r = 1,   g = 1,   b = 0 },
        { value = "gold",   label = "Gold",    r = 0.95, g = 0.85, b = 0.35 },
        { value = "orange", label = "Orange",  r = 1,   g = 0.5, b = 0 },
        { value = "red",    label = "Red",     r = 0.9, g = 0.2, b = 0.2 },
        { value = "gray",   label = "Gray",    r = 0.6, g = 0.6, b = 0.6 },
    },
}

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local STATUSBAR = LSM and LSM.MediaType and LSM.MediaType.STATUSBAR or "statusbar"
local FONT = LSM and LSM.MediaType and LSM.MediaType.FONT or "font"
local MMF_STATUSBAR_DEFAULT = "MMF Melli"
local MMF_FONT_DEFAULT = "MMF Naowh"
local MMF_FONT_DEFAULT_PATH = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
local fontApplyToken = 0
local fontValidationString = nil

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

local function GetFontValidationString()
    if fontValidationString then
        return fontValidationString
    end
    local parent = UIParent or _G.UIParent
    if not parent then
        return nil
    end
    local probe = parent:CreateFontString(nil, "OVERLAY")
    probe:Hide()
    fontValidationString = probe
    return fontValidationString
end

local function IsUsableFontPath(fontPath)
    if type(fontPath) ~= "string" or fontPath == "" then
        return false
    end

    local probe = GetFontValidationString()
    if not probe then
        return false
    end

    local ok, applied = pcall(probe.SetFont, probe, fontPath, 12, "OUTLINE")
    if ok and applied ~= false then
        return true
    end

    ok, applied = pcall(probe.SetFont, probe, fontPath, 12, "")
    return ok and applied ~= false
end

local MMF_STATUSBAR_REGISTRY = {
    { name = "MMF Melli", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga" },
    { name = "MMF Melli Dark", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\MelliDark.tga" },
    { name = "MMF Melli Dark Rough", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\MelliDarkRough.tga" },
    { name = "MMF Flat", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Flat.tga" },
    { name = "MMF Smooth", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Smooth.tga" },
    { name = "MMF Smooth v2", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Smoothv2.tga" },
    { name = "MMF Glaze", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glaze.tga" },
    { name = "MMF Graphite", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Graphite.tga" },
    { name = "MMF Charcoal", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Charcoal.tga" },
    { name = "MMF Steel", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Steel.tga" },
    { name = "MMF Tube", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Tube.tga" },
    { name = "MMF Outline", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Outline.tga" },
    { name = "MMF Minimalist", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Minimalist.tga" },
    { name = "MMF Wglass", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Wglass.tga" },
    { name = "MMF Aluminium", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Aluminium.tga" },
    { name = "MMF Armory", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Armory.tga" },
    { name = "MMF BantoBar", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\BantoBar.tga" },
    { name = "MMF Bars", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Bars.tga" },
    { name = "MMF Bumps", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Bumps.tga" },
    { name = "MMF Button", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Button.tga" },
    { name = "MMF Cilo", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Cilo.tga" },
    { name = "MMF Cloud", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Cloud.tga" },
    { name = "MMF Comet", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Comet.tga" },
    { name = "MMF Dabs", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Dabs.tga" },
    { name = "MMF DarkBottom", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\DarkBottom.tga" },
    { name = "MMF Diagonal", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Diagonal.tga" },
    { name = "MMF Falumn", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Falumn.tga" },
    { name = "MMF Fifths", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Fifths.tga" },
    { name = "MMF Fourths", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Fourths.tga" },
    { name = "MMF Frost", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Frost.tga" },
    { name = "MMF Glamour", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glamour.tga" },
    { name = "MMF Glamour2", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glamour2.tga" },
    { name = "MMF Glamour3", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glamour3.tga" },
    { name = "MMF Glamour4", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glamour4.tga" },
    { name = "MMF Glamour5", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glamour5.tga" },
    { name = "MMF Glamour6", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glamour6.tga" },
    { name = "MMF Glamour7", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glamour7.tga" },
    { name = "MMF Glass", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glass.tga" },
    { name = "MMF Glaze2", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Glaze2.tga" },
    { name = "MMF Gloss", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Gloss.tga" },
    { name = "MMF Hatched", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Hatched.tga" },
    { name = "MMF Healbot", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Healbot.tga" },
    { name = "MMF LiteStep", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\LiteStep.tga" },
    { name = "MMF LiteStepLite", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\LiteStepLite.tga" },
    { name = "MMF Lyfe", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Lyfe.tga" },
    { name = "MMF NormTex", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\NormTex.tga" },
    { name = "MMF NormTex2", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\NormTex2.tga" },
    { name = "MMF NormTex3", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\NormTex3.tga" },
    { name = "MMF Otravi", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Otravi.tga" },
    { name = "MMF Perl", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Perl.tga" },
    { name = "MMF Perl2", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Perl2.tga" },
    { name = "MMF Pill", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Pill.tga" },
    { name = "MMF Rain", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Rain.tga" },
    { name = "MMF Rocks", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Rocks.tga" },
    { name = "MMF Round", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Round.tga" },
    { name = "MMF Ruben", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Ruben.tga" },
    { name = "MMF Runes", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Runes.tga" },
    { name = "MMF Skewed", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Skewed.tga" },
    { name = "MMF Smudge", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Smudge.tga" },
    { name = "MMF Striped", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Striped.tga" },
    { name = "MMF Water", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Water.tga" },
    { name = "MMF Wisps", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Wisps.tga" },
    { name = "MMF Xeon", path = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Xeon.tga" },
}
local MMF_LEGACY_STATUSBAR_ALIASES = {}
local MMF_FONT_REGISTRY = {
    { name = MMF_FONT_DEFAULT, path = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf" },
}

function MMF_RegisterStatusBarMedia()
    if not LSM then return end
    for _, media in ipairs(MMF_STATUSBAR_REGISTRY) do
        if not LSM:IsValid(STATUSBAR, media.name) then
            LSM:Register(STATUSBAR, media.name, media.path)
        end
    end
end

function MMF_RegisterFontMedia()
    if not LSM then return end
    for _, media in ipairs(MMF_FONT_REGISTRY) do
        if not LSM:IsValid(FONT, media.name) then
            LSM:Register(FONT, media.name, media.path)
        end
    end
end

function MMF_GetStatusBarTextureOptions()
    local list = {}
    if LSM then
        local names = LSM:List(STATUSBAR) or {}
        for _, name in ipairs(names) do
            local normalized = NormalizeMediaName(name)
            if normalized then
                list[#list + 1] = normalized
            end
        end
    else
        for _, media in ipairs(MMF_STATUSBAR_REGISTRY) do
            local normalized = NormalizeMediaName(media.name)
            if normalized then
                list[#list + 1] = normalized
            end
        end
    end
    table.sort(list, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    return list
end

function MMF_EnsureStatusBarTextureSelection()
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local selected = NormalizeMediaName(MattMinimalFramesDB.statusBarTexture) or MMF_STATUSBAR_DEFAULT
    local legacyAlias = MMF_LEGACY_STATUSBAR_ALIASES[selected]
    if legacyAlias then
        selected = legacyAlias
    end

    if LSM and not LSM:IsValid(STATUSBAR, selected) then
        selected = MMF_STATUSBAR_DEFAULT
    end

    MattMinimalFramesDB.statusBarTexture = selected
    return selected
end

function MMF_GetStatusBarTexturePath()
    local selected = MMF_EnsureStatusBarTextureSelection and MMF_EnsureStatusBarTextureSelection() or MMF_STATUSBAR_DEFAULT
    if LSM then
        local fetched = LSM:Fetch(STATUSBAR, selected, true)
        if fetched then
            return fetched
        end
        local fallback = LSM:Fetch(STATUSBAR, MMF_STATUSBAR_DEFAULT, true)
        if fallback then
            return fallback
        end
    end
    return MMF_Config.TEXTURE_PATH
end

function MMF_GetFontOptions()
    local list = {}
    if LSM then
        local names = LSM:List(FONT) or {}
        for _, name in ipairs(names) do
            local normalized = NormalizeMediaName(name)
            if normalized then
                list[#list + 1] = normalized
            end
        end
    else
        for _, media in ipairs(MMF_FONT_REGISTRY) do
            local normalized = NormalizeMediaName(media.name)
            if normalized then
                list[#list + 1] = normalized
            end
        end
    end
    if #list == 0 then
        list[#list + 1] = MMF_FONT_DEFAULT
    end
    table.sort(list, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    return list
end

function MMF_GetGlobalFontPath()
    local selected = NormalizeMediaName(MattMinimalFramesDB and MattMinimalFramesDB.globalFont) or MMF_FONT_DEFAULT
    if LSM then
        local fetched = LSM:Fetch(FONT, selected, true)
        if fetched and IsUsableFontPath(fetched) then
            return fetched
        end
        local fallback = LSM:Fetch(FONT, MMF_FONT_DEFAULT, true)
        if fallback and IsUsableFontPath(fallback) then
            return fallback
        end
    end
    return MMF_FONT_DEFAULT_PATH
end

local function GetGlobalFontPathByName(fontName)
    local selected = NormalizeMediaName(fontName) or MMF_FONT_DEFAULT
    if LSM then
        local fetched = LSM:Fetch(FONT, selected, true)
        if fetched and IsUsableFontPath(fetched) then
            return fetched, true
        end
        local fallback = LSM:Fetch(FONT, MMF_FONT_DEFAULT, true)
        if fallback and IsUsableFontPath(fallback) then
            return fallback, false
        end
    end
    return MMF_FONT_DEFAULT_PATH, selected == MMF_FONT_DEFAULT
end

function MMF_SetGlobalFont(fontName)
    fontName = NormalizeMediaName(fontName)
    if not fontName then return end
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.globalFont = fontName
    local resolvedPath, matched = GetGlobalFontPathByName(fontName)
    MMF_Config.FONT_PATH = resolvedPath or MMF_Config.FONT_PATH
    fontApplyToken = fontApplyToken + 1
    local thisToken = fontApplyToken
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end

    -- Some SharedMedia fonts can register slightly later on reload/login.
    -- Retry briefly so a single selection applies immediately and persists.
    if not matched and C_Timer and C_Timer.After then
        local attempts = 0
        local function RetryApply()
            attempts = attempts + 1
            if thisToken ~= fontApplyToken then return end
            if not MattMinimalFramesDB or MattMinimalFramesDB.globalFont ~= fontName then return end

            local retryPath, retryMatched = GetGlobalFontPathByName(fontName)
            if retryPath then
                MMF_Config.FONT_PATH = retryPath
            end
            if MMF_ApplyGlobalFont then
                MMF_ApplyGlobalFont()
            end

            if (not retryMatched) and attempts < 40 then
                C_Timer.After(0.2, RetryApply)
            end
        end
        C_Timer.After(0.2, RetryApply)
    end
end

function MMF_Config.GetCastBarColor(key)
    for _, opt in ipairs(MMF_Config.CAST_BAR_COLORS) do
        if opt.value == key then
            return opt.r, opt.g, opt.b
        end
    end
    return 1, 1, 1
end

MMF_RegisterStatusBarMedia()
MMF_RegisterFontMedia()

if LSM and LSM.RegisterCallback then
    LSM.RegisterCallback("MMF_SHARED_MEDIA_WATCHER", "LibSharedMedia_Registered", function(eventName, mediaType, mediaKey)
        if eventName ~= "LibSharedMedia_Registered" then return end
        if not MattMinimalFramesDB then return end
        local normalizedKey = NormalizeMediaName(mediaKey)

        if mediaType == FONT and normalizedKey and normalizedKey == NormalizeMediaName(MattMinimalFramesDB.globalFont) then
            MMF_Config.FONT_PATH = MMF_GetGlobalFontPath() or MMF_Config.FONT_PATH
            if MMF_ApplyGlobalFont then
                MMF_ApplyGlobalFont()
            end
        elseif mediaType == STATUSBAR and normalizedKey and normalizedKey == NormalizeMediaName(MattMinimalFramesDB.statusBarTexture) then
            if MMF_ApplyStatusBarTexture then
                MMF_ApplyStatusBarTexture()
            end
        end
    end)
end

function MMF_GetAllFrames()
    return {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }
end

function MMF_GetFrameForUnit(unit)
    local map = {
        player = MMF_PlayerFrame,
        target = MMF_TargetFrame,
        targettarget = MMF_TargetOfTargetFrame,
        pet = MMF_PetFrame,
        focus = MMF_FocusFrame,
    }
    return map[unit]
end

function MMF_GetFrameDefinition(unit)
    for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
        if def.unit == unit then
            return def
        end
    end
    return nil
end

function MMF_FormatNumber(num)
    if type(num) ~= "number" then return "0" end
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

function MMF_GetUnitColor(unit)
    if not unit then return 1, 1, 1 end
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local colors = RAID_CLASS_COLORS[class]
            if colors then
                return colors.r, colors.g, colors.b
            end
        end
    else
        if UnitIsEnemy("player", unit) then
            return 0.8, 0.2, 0.2
        elseif not UnitIsFriend("player", unit) then
            return 1, 1, 0
        else
            return 0.2, 0.8, 0.2
        end
    end
    
    return 1, 1, 1
end

function MMF_ResetSecureAttributes(frame)
    if not frame or not frame.unit then return end
    frame:SetAttribute("unit", frame.unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("target", frame.unit)
    frame:SetAttribute("type2", "togglemenu")
    frame:SetAttribute("alt-type2", "focus")
    frame:SetAttribute("focus", frame.unit)
    frame:SetAttribute("shift-alt-type2", "macro")
    frame:SetAttribute("shift-alt-macrotext2", "/clearfocus")
end

function MMF_GetAuraIconSize()
    return (MattMinimalFramesDB and MattMinimalFramesDB.auraIconSize) or 18
end

function MMF_GetAuraTextScale()
    return (MattMinimalFramesDB and MattMinimalFramesDB.auraTextScale) or 1.0
end

function MMF_GetTimerTextScale()
    return (MattMinimalFramesDB and MattMinimalFramesDB.timerTextScale) or 0.8
end

function MMF_GetBuffXOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.buffXOffset) or -3
end

function MMF_GetBuffYOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.buffYOffset) or -60
end

function MMF_GetDebuffXOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.debuffXOffset) or 3
end

function MMF_GetDebuffYOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.debuffYOffset) or 27
end

function MMF_GetNameTextSize()
    return (MattMinimalFramesDB and MattMinimalFramesDB.nameTextSize) or 12
end

function MMF_GetHPTextSize()
    return (MattMinimalFramesDB and MattMinimalFramesDB.hpTextSize) or 13
end

local function GetUnitPrefix(unit)
    if unit == "targettarget" then return "tot" end
    return unit
end

function MMF_GetNameTextXOffset(unit)
    if not MattMinimalFramesDB then return 0 end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "NameTextXOffset"
    if MattMinimalFramesDB[key] ~= nil then
        return MattMinimalFramesDB[key]
    end
    return MattMinimalFramesDB.nameTextXOffset or 0
end

function MMF_GetNameTextYOffset(unit)
    if not MattMinimalFramesDB then return 0 end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "NameTextYOffset"
    if MattMinimalFramesDB[key] ~= nil then
        return MattMinimalFramesDB[key]
    end
    return MattMinimalFramesDB.nameTextYOffset or 0
end

function MMF_GetHPTextXOffset(unit)
    if not MattMinimalFramesDB then return 0 end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "HPTextXOffset"
    if MattMinimalFramesDB[key] ~= nil then
        return MattMinimalFramesDB[key]
    end
    return MattMinimalFramesDB.hpTextXOffset or 0
end

function MMF_GetHPTextYOffset(unit)
    if not MattMinimalFramesDB then return 0 end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "HPTextYOffset"
    if MattMinimalFramesDB[key] ~= nil then
        return MattMinimalFramesDB[key]
    end
    return MattMinimalFramesDB.hpTextYOffset or 0
end

function MMF_IsNameTextHidden(unit)
    if not MattMinimalFramesDB then return false end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "HideNameText"
    return MattMinimalFramesDB[key] == true
end

function MMF_IsHPTextHidden(unit)
    if not MattMinimalFramesDB then return false end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "HideHPText"
    return MattMinimalFramesDB[key] == true
end

local function ApplyFrameTextOffsets(frame)
    if not frame then return end
    local unit = frame.unit
    local nameX = MMF_GetNameTextXOffset(unit)
    local nameY = MMF_GetNameTextYOffset(unit)
    local hpX = MMF_GetHPTextXOffset(unit)
    local hpY = MMF_GetHPTextYOffset(unit)

    if frame.nameText then
        local positions = {
            player = { point = "LEFT", relPoint = "TOPLEFT", x = 2, y = 0, justify = "LEFT" },
            target = { point = "RIGHT", relPoint = "TOPRIGHT", x = -2, y = 0, justify = "RIGHT" },
            targettarget = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
            pet = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
            focus = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        }
        local pos = positions[unit] or positions.focus
        frame.nameText:ClearAllPoints()
        frame.nameText:SetPoint(pos.point, frame, pos.relPoint, pos.x + nameX, pos.y + nameY)
        frame.nameText:SetJustifyH(pos.justify)
    end

    if frame.hpText then
        frame.hpText:ClearAllPoints()
        if frame.unit == "player" then
            frame.hpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0 + hpX, -14.5 + hpY)
        elseif frame.unit == "target" then
            frame.hpText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2 + hpX, -14.5 + hpY)
        elseif frame.unit == "targettarget" or frame.unit == "pet" then
            frame.hpText:SetPoint("BOTTOM", frame, "BOTTOM", 0 + hpX, 0 + hpY)
        elseif frame.unit ~= "focus" then
            frame.hpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3 + hpX, 3 + hpY)
        end
    end
end

function MMF_UpdateFrameTextOffsets()
    local frames = {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }
    for _, frame in ipairs(frames) do
        ApplyFrameTextOffsets(frame)
    end
end

function MMF_UpdateNameTextSize(size)
    local frames = {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }
    
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or MMF_Config.FONT_PATH
    for _, frame in ipairs(frames) do
        if frame and frame.nameText then
            if MMF_SetFontSafe then
                MMF_SetFontSafe(frame.nameText, fontPath, size, "OUTLINE")
            else
                frame.nameText:SetFont(fontPath, size, "OUTLINE")
            end
            if frame.unit and UnitExists(frame.unit) then
                local currentText = frame.nameText:GetText()
                frame.nameText:SetText("")
                frame.nameText:SetText(currentText)
            end
        end
    end
end

function MMF_UpdateHPTextSize(size)
    local frames = {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }
    
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or MMF_Config.FONT_PATH
    for _, frame in ipairs(frames) do
        if frame and frame.hpText then
            if MMF_SetFontSafe then
                MMF_SetFontSafe(frame.hpText, fontPath, size, "OUTLINE")
            else
                frame.hpText:SetFont(fontPath, size, "OUTLINE")
            end
            pcall(function()
                if frame.unit and UnitExists(frame.unit) then
                    local currentText = frame.hpText:GetText()
                    if currentText then
                        frame.hpText:SetText("")
                        C_Timer.After(0.01, function()
                            frame.hpText:SetText(currentText)
                        end)
                    end
                end
            end)
        end
    end
end

function MMF_GetFrameScaleX(unit)
    if not MattMinimalFramesDB then return 1.0 end
    local key = unit:gsub("targettarget", "tot") .. "FrameScaleX"
    return MattMinimalFramesDB[key] or 1.0
end

function MMF_GetFrameScaleY(unit)
    if not MattMinimalFramesDB then return 1.0 end
    local key = unit:gsub("targettarget", "tot") .. "FrameScaleY"
    return MattMinimalFramesDB[key] or 1.0
end

function MMF_UpdateFrameScale(unit)
    local frame = MMF_GetFrameForUnit(unit)
    if not frame then return end
    local def = MMF_GetFrameDefinition(unit)
    if not def then return end
    local originalWidth = def.width
    local originalHeight = def.height
    local scaleX = MMF_GetFrameScaleX(unit)
    local scaleY = MMF_GetFrameScaleY(unit)
    local newWidth = originalWidth * scaleX
    local newHeight = originalHeight * scaleY
    frame:SetSize(newWidth, newHeight)
    frame.originalWidth = newWidth
    frame.originalHeight = newHeight
    if frame.healthBar then
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end
    if frame.absorbBar then
        frame.absorbBar:ClearAllPoints()
    end
    if frame.nameText then
        frame.nameText:SetWidth(newWidth - 4)
    end
    ApplyFrameTextOffsets(frame)
    if frame.castBarFrame then
        frame.castBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
        frame.castBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        if frame.castBarText then
            if frame.unit == "target" then
                frame.castBarText:SetWidth(newWidth - 8)
            else
                frame.castBarText:SetWidth(newWidth - 2)
            end
        end
    end
    if frame.classIcon then
        local iconSize = math.max(8, newHeight)
        frame.classIcon:SetSize(iconSize, iconSize)
        frame.classIcon:ClearAllPoints()
        frame.classIcon:SetPoint("RIGHT", frame, "LEFT", 0, 0)
    end
    if frame.targetIcon then
        local iconSize = math.max(8, newHeight)
        frame.targetIcon:SetSize(iconSize, iconSize)
        frame.targetIcon:ClearAllPoints()
        frame.targetIcon:SetPoint("LEFT", frame, "RIGHT", 0, 0)
    end
    if frame.targetMarker then
        local markerSize = math.max(10, math.floor(newHeight * 0.75))
        frame.targetMarker:SetSize(markerSize, markerSize)
        frame.targetMarker:ClearAllPoints()
        frame.targetMarker:SetPoint("CENTER", frame, "CENTER", 0, 0)
    end
    if MMF_UpdateTargetMarkers then
        MMF_UpdateTargetMarkers()
    end
    if MMF_UpdateTargetFrameIconVisibility and unit == "target" then
        MMF_UpdateTargetFrameIconVisibility()
    end
end

function MMF_ApplyAllFrameScales()
    local units = {"player", "target", "targettarget", "focus", "pet"}
    for _, unit in ipairs(units) do
        MMF_UpdateFrameScale(unit)
    end
end
