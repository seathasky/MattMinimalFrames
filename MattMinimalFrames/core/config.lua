MMF_Config = {
    POWER_BAR_WIDTH = 73,
    POWER_BAR_HEIGHT = 5,
    POWER_BAR_VERTICAL_OFFSET = -24,
    POWER_BAR_HORIZONTAL_OFFSET = 1,
    AURA_ICON_SPACING = 2,
    MAX_AURA_ICONS = 16,
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
        { unit = "boss1",        name = "MMF_Boss1Frame",          width = 100, height = 28, x = 500,  y = 140,  label = "Boss 1 Frame" },
        { unit = "boss2",        name = "MMF_Boss2Frame",          width = 100, height = 28, x = 500,  y = 104,  label = "Boss 2 Frame" },
        { unit = "boss3",        name = "MMF_Boss3Frame",          width = 100, height = 28, x = 500,  y = 68,   label = "Boss 3 Frame" },
        { unit = "boss4",        name = "MMF_Boss4Frame",          width = 100, height = 28, x = 500,  y = 32,   label = "Boss 4 Frame" },
        { unit = "boss5",        name = "MMF_Boss5Frame",          width = 100, height = 28, x = 500,  y = -4,   label = "Boss 5 Frame" },
    },
    CAST_BAR_COLORS = {
        { value = "white",  label = "White",   r = 1,   g = 1,   b = 1 },
        { value = "yellow", label = "Yellow",  r = 1,   g = 1,   b = 0 },
        { value = "gold",   label = "Gold",    r = 0.95, g = 0.85, b = 0.35 },
        { value = "orange", label = "Orange",  r = 1,   g = 0.5, b = 0 },
        { value = "red",    label = "Red",     r = 0.9, g = 0.2, b = 0.2 },
        { value = "gray",   label = "Gray",    r = 0.6, g = 0.6, b = 0.6 },
    },
    PLAYER_BAR_COLORS = {
        { value = "class", label = "Class (Default)" },
        { value = "green", label = "Green", r = 0.20, g = 0.80, b = 0.20 },
        { value = "white", label = "White", r = 1.00, g = 1.00, b = 1.00 },
        { value = "gray",  label = "Gray",  r = 0.60, g = 0.60, b = 0.60 },
        { value = "red",   label = "Red",   r = 0.90, g = 0.20, b = 0.20 },
        { value = "blue",  label = "Blue",  r = 0.20, g = 0.45, b = 0.95 },
    },
    TARGET_BAR_COLORS = {
        { value = "default", label = "Default" },
        { value = "green", label = "Green", r = 0.20, g = 0.80, b = 0.20 },
        { value = "white", label = "White", r = 1.00, g = 1.00, b = 1.00 },
        { value = "gray", label = "Gray", r = 0.60, g = 0.60, b = 0.60 },
        { value = "red", label = "Red", r = 0.90, g = 0.20, b = 0.20 },
        { value = "blue", label = "Blue", r = 0.20, g = 0.45, b = 0.95 },
    },
}

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local STATUSBAR = LSM and LSM.MediaType and LSM.MediaType.STATUSBAR or "statusbar"
local FONT = LSM and LSM.MediaType and LSM.MediaType.FONT or "font"
local BACKGROUND = LSM and LSM.MediaType and LSM.MediaType.BACKGROUND or "background"
local SOUND = LSM and LSM.MediaType and LSM.MediaType.SOUND or "sound"
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
local MMF_SOUND_REGISTRY = {
    { name = "MMF Are You Sure", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\are-you-sure-about-that.mp3" },
    { name = "MMF Click", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\click.mp3" },
    { name = "MMF ESPARK1", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\ESPARK1.ogg" },
    { name = "MMF HP", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\hp.mp3" },
    { name = "MMF HPC", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\hpc.mp3" },
    { name = "MMF HPF", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\hpf.mp3" },
    { name = "MMF Sonar", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\sonar.ogg" },
    { name = "MMF Sword Echo", path = "Interface\\AddOns\\MattMinimalFrames\\Sounds\\swordecho.ogg" },
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

function MMF_RegisterSoundMedia()
    if not LSM then return end
    for _, media in ipairs(MMF_SOUND_REGISTRY) do
        if not LSM:IsValid(SOUND, media.name) then
            LSM:Register(SOUND, media.name, media.path)
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

function MMF_GetIconTextureOptions(classToken)
    local entries = {}
    local engine = _G.ElvUI_JiberishIcons
    local JI = type(engine) == "table" and engine[1] or nil
    if type(JI) ~= "table" then
        return entries
    end

    local mergedClassStyles = JI.mergedStylePacks and JI.mergedStylePacks.class
    local defaultClassStyles = JI.defaultStylePacks and JI.defaultStylePacks.class
    local styleContainer = mergedClassStyles or defaultClassStyles
    if type(styleContainer) ~= "table" or type(styleContainer.styles) ~= "table" then
        return entries
    end

    local classData = JI.dataHelper and JI.dataHelper.class and JI.dataHelper.class[classToken or select(2, UnitClass("player"))]
    local previewTexString = classData and classData.texString

    for styleKey, data in pairs(styleContainer.styles) do
        local normalizedStyleKey = NormalizeMediaName(styleKey)
        if normalizedStyleKey then
            local pathRoot = NormalizeMediaName(data and data.path) or NormalizeMediaName(styleContainer.path)
            local fullPath = pathRoot and (pathRoot .. normalizedStyleKey) or nil
            local validPath = false
            if type(fullPath) == "string" and fullPath ~= "" then
                if type(JI.IsValidTexturePath) == "function" then
                    local ok, result = pcall(JI.IsValidTexturePath, JI, fullPath)
                    validPath = ok and result == true
                else
                    validPath = true
                end
            end
            if validPath then
                entries[#entries + 1] = {
                    key = normalizedStyleKey,
                    mediaType = "jiberish",
                    label = tostring((data and data.name) or normalizedStyleKey),
                    path = fullPath,
                    texString = previewTexString,
                }
            end
        end
    end

    table.sort(entries, function(a, b)
        return tostring(a.label):lower() < tostring(b.label):lower()
    end)
    return entries
end

function MMF_GetIconTexturePath(mediaKey, mediaType)
    local key = NormalizeMediaName(mediaKey)
    if not key then
        return nil
    end

    local desiredType = NormalizeMediaName(mediaType)
    if desiredType == "jiberish" then
        local engine = _G.ElvUI_JiberishIcons
        local JI = type(engine) == "table" and engine[1] or nil
        if type(JI) ~= "table" then
            return nil
        end
        local mergedClassStyles = JI.mergedStylePacks and JI.mergedStylePacks.class
        local defaultClassStyles = JI.defaultStylePacks and JI.defaultStylePacks.class
        local styleContainer = mergedClassStyles or defaultClassStyles
        if type(styleContainer) ~= "table" then
            return nil
        end
        local styleData = styleContainer.styles and styleContainer.styles[key]
        local pathRoot = NormalizeMediaName(styleData and styleData.path) or NormalizeMediaName(styleContainer.path)
        if not pathRoot then
            return nil
        end
        return pathRoot .. key
    end

    if not LSM then
        return nil
    end

    if desiredType == BACKGROUND or desiredType == STATUSBAR then
        local fetched = LSM:Fetch(desiredType, key, true)
        if type(fetched) == "string" and fetched ~= "" then
            return fetched
        end
    end

    local backgroundPath = LSM:Fetch(BACKGROUND, key, true)
    if type(backgroundPath) == "string" and backgroundPath ~= "" then
        return backgroundPath
    end
    local statusbarPath = LSM:Fetch(STATUSBAR, key, true)
    if type(statusbarPath) == "string" and statusbarPath ~= "" then
        return statusbarPath
    end

    return nil
end

function MMF_GetIconTextureCoords(mediaKey, mediaType, classToken)
    local key = NormalizeMediaName(mediaKey)
    local desiredType = NormalizeMediaName(mediaType)
    if not key or desiredType ~= "jiberish" then
        return nil
    end

    local engine = _G.ElvUI_JiberishIcons
    local JI = type(engine) == "table" and engine[1] or nil
    if type(JI) ~= "table" then
        return nil
    end

    local token = classToken
    if not token then
        return nil
    end
    local classData = JI.dataHelper and JI.dataHelper.class and JI.dataHelper.class[token]
    if classData and type(classData.texCoords) == "table" then
        return classData.texCoords
    end
    return nil
end

function MMF_EnsureStatusBarTextureSelection()
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local selected = NormalizeMediaName(MattMinimalFramesDB.statusBarTexture)
    if not selected then
        selected = MMF_STATUSBAR_DEFAULT
        MattMinimalFramesDB.statusBarTexture = selected
    end

    local legacyAlias = MMF_LEGACY_STATUSBAR_ALIASES[selected]
    if legacyAlias then
        selected = legacyAlias
        MattMinimalFramesDB.statusBarTexture = selected
    end

    -- Do not clobber a valid user selection just because another addon
    -- registers its SharedMedia entry later in the loading sequence.
    if LSM and not LSM:IsValid(STATUSBAR, selected) then
        return selected
    end

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

function MMF_GetGlobalFontPathByName(fontName)
    return GetGlobalFontPathByName(fontName)
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
MMF_RegisterSoundMedia()

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
        elseif (mediaType == BACKGROUND or mediaType == STATUSBAR) and normalizedKey then
            local playerKey = NormalizeMediaName(MattMinimalFramesDB.playerFrameIconStyle) or NormalizeMediaName(MattMinimalFramesDB.playerFrameIconMediaKey)
            local playerType = NormalizeMediaName(MattMinimalFramesDB.playerFrameIconMediaType)
            local targetKey = NormalizeMediaName(MattMinimalFramesDB.targetFrameIconStyle) or NormalizeMediaName(MattMinimalFramesDB.targetFrameIconMediaKey)
            local targetType = NormalizeMediaName(MattMinimalFramesDB.targetFrameIconMediaType)

            if playerKey and normalizedKey == playerKey and MMF_UpdatePlayerClassIconVisibility then
                if not playerType or playerType == mediaType then
                    MMF_UpdatePlayerClassIconVisibility(MMF_GetPlayerFrameIconMode and MMF_GetPlayerFrameIconMode() or "jiberish")
                end
            end
            if targetKey and normalizedKey == targetKey and MMF_UpdateTargetFrameIconVisibility then
                if not targetType or targetType == mediaType then
                    MMF_UpdateTargetFrameIconVisibility(MMF_GetTargetFrameIconMode and MMF_GetTargetFrameIconMode() or "jiberish")
                end
            end
        end
    end)
end

function MMF_GetAllFrames()
    local frames = {}
    for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
        local frame = _G[def.name]
        if frame then
            frames[#frames + 1] = frame
        end
    end
    return frames
end

function MMF_GetFrameForUnit(unit)
    if type(unit) ~= "string" or unit == "" then
        return nil
    end
    for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
        if def.unit == unit then
            return _G[def.name]
        end
    end
    return nil
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
    if num == nil then return "0" end

    if type(AbbreviateLargeNumbers) == "function" then
        local ok, text = pcall(AbbreviateLargeNumbers, num)
        if ok and text then
            return text
        end
    end

    if type(BreakUpLargeNumbers) == "function" then
        local ok, text = pcall(BreakUpLargeNumbers, num)
        if ok and text then
            return text
        end
    end

    local ok, text = pcall(function()
        return tostring(num)
    end)
    if ok and text then
        return text
    end

    return "0"
end

local function ClampColorChannel(value, fallback)
    local channel = tonumber(value)
    if not channel then
        channel = tonumber(fallback) or 1
    end
    if channel < 0 then channel = 0 end
    if channel > 1 then channel = 1 end
    return channel
end

local function ClampUnitInterval(value, fallback)
    local n = tonumber(value)
    if not n then
        n = tonumber(fallback) or 1
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function GetCustomBarColor(baseKey, fallbackR, fallbackG, fallbackB)
    if not MattMinimalFramesDB then
        return ClampColorChannel(fallbackR, 1), ClampColorChannel(fallbackG, 1), ClampColorChannel(fallbackB, 1)
    end
    return ClampColorChannel(MattMinimalFramesDB[baseKey .. "R"], fallbackR),
        ClampColorChannel(MattMinimalFramesDB[baseKey .. "G"], fallbackG),
        ClampColorChannel(MattMinimalFramesDB[baseKey .. "B"], fallbackB)
end

function MMF_GetUnitColor(unit)
    if not unit then return 1, 1, 1 end
    if unit == "target" and MattMinimalFramesDB then
        local mode = tostring(MattMinimalFramesDB.targetBarColorMode or "default"):lower()
        if mode == "custom" then
            return GetCustomBarColor("targetBarCustomColor", 0.8, 0.2, 0.2)
        end
        if mode ~= "default" then
            local colorOptions = MMF_Config and MMF_Config.TARGET_BAR_COLORS
            if type(colorOptions) == "table" then
                for _, option in ipairs(colorOptions) do
                    if option and option.value == mode and option.r and option.g and option.b then
                        return option.r, option.g, option.b
                    end
                end
            end
        end
    end
    if unit == "targettarget" and MattMinimalFramesDB then
        local mode = tostring(MattMinimalFramesDB.totBarColorMode or "default"):lower()
        if mode == "custom" then
            return GetCustomBarColor("totBarCustomColor", 0.8, 0.2, 0.2)
        end
        if mode ~= "default" then
            local colorOptions = MMF_Config and MMF_Config.TARGET_BAR_COLORS
            if type(colorOptions) == "table" then
                for _, option in ipairs(colorOptions) do
                    if option and option.value == mode and option.r and option.g and option.b then
                        return option.r, option.g, option.b
                    end
                end
            end
        end
    end
    if unit == "focus" and MattMinimalFramesDB then
        local mode = tostring(MattMinimalFramesDB.focusBarColorMode or "default"):lower()
        if mode == "custom" then
            return GetCustomBarColor("focusBarCustomColor", 0.8, 0.2, 0.2)
        end
        if mode ~= "default" then
            local colorOptions = MMF_Config and MMF_Config.TARGET_BAR_COLORS
            if type(colorOptions) == "table" then
                for _, option in ipairs(colorOptions) do
                    if option and option.value == mode and option.r and option.g and option.b then
                        return option.r, option.g, option.b
                    end
                end
            end
        end
    end
    if unit == "pet" and MattMinimalFramesDB then
        local mode = tostring(MattMinimalFramesDB.petBarColorMode or "default"):lower()
        if mode == "custom" then
            return GetCustomBarColor("petBarCustomColor", 0.2, 0.8, 0.2)
        end
        if mode ~= "default" then
            local colorOptions = MMF_Config and MMF_Config.TARGET_BAR_COLORS
            if type(colorOptions) == "table" then
                for _, option in ipairs(colorOptions) do
                    if option and option.value == mode and option.r and option.g and option.b then
                        return option.r, option.g, option.b
                    end
                end
            end
        end
    end
    if UnitIsPlayer(unit) then
        local isPlayerUnit = (unit == "player")
            or (type(UnitIsUnit) == "function" and UnitIsUnit(unit, "player"))
        if isPlayerUnit and MattMinimalFramesDB then
            local mode = tostring(MattMinimalFramesDB.playerBarColorMode or "class"):lower()
            if mode == "custom" then
                return GetCustomBarColor("playerBarCustomColor", 1, 1, 1)
            end
            if mode ~= "class" then
                local colorOptions = MMF_Config and MMF_Config.PLAYER_BAR_COLORS
                if type(colorOptions) == "table" then
                    for _, option in ipairs(colorOptions) do
                        if option and option.value == mode and option.r and option.g and option.b then
                            return option.r, option.g, option.b
                        end
                    end
                end
            end
        end
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

function MMF_GetUnitColorAlpha(unit)
    if unit == "player"
        or unit == "target"
        or unit == "targettarget"
        or unit == "focus"
        or unit == "pet" then
        return ClampUnitInterval(MattMinimalFramesDB and MattMinimalFramesDB.frameColorAlpha, 1)
    end
    return 1
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

local function GetUnitPrefix(unit)
    if unit == "targettarget" then return "tot" end
    if unit == "boss" or unit == "boss1" or unit == "boss2" or unit == "boss3" or unit == "boss4" or unit == "boss5" then
        return "boss"
    end
    return unit
end

function MMF_GetNameTextSize(unit)
    if not MattMinimalFramesDB then return 12 end
    if unit then
        local prefix = GetUnitPrefix(unit)
        local key = prefix .. "NameTextSize"
        if MattMinimalFramesDB[key] ~= nil then
            return MattMinimalFramesDB[key]
        end
    end
    return MattMinimalFramesDB.nameTextSize or 12
end

function MMF_GetHPTextSize(unit)
    if not MattMinimalFramesDB then return 13 end
    if unit then
        local prefix = GetUnitPrefix(unit)
        local key = prefix .. "HPTextSize"
        if MattMinimalFramesDB[key] ~= nil then
            return MattMinimalFramesDB[key]
        end
    end
    return MattMinimalFramesDB.hpTextSize or 13
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
            boss1 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
            boss2 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
            boss3 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
            boss4 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
            boss5 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
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
        elseif frame.unit == "targettarget" or frame.unit == "pet" or frame.unit == "focus" or frame.unit == "boss1" or frame.unit == "boss2" or frame.unit == "boss3" or frame.unit == "boss4" or frame.unit == "boss5" then
            frame.hpText:SetPoint("BOTTOM", frame, "BOTTOM", 0 + hpX, 0 + hpY)
        else
            frame.hpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3 + hpX, 3 + hpY)
        end
    end
end

function MMF_UpdateFrameTextOffsets()
    for _, frame in ipairs(MMF_GetAllFrames()) do
        ApplyFrameTextOffsets(frame)
    end
end

local function ForEachUnitFrame(unit, callback)
    if type(callback) ~= "function" then
        return
    end
    if unit then
        if unit == "boss" then
            for i = 1, 5 do
                callback(MMF_GetFrameForUnit and MMF_GetFrameForUnit("boss" .. i))
            end
            return
        end
        local frame = (MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit))
        callback(frame)
        return
    end

    for _, frame in ipairs(MMF_GetAllFrames()) do
        callback(frame)
    end
end

local function TryApplyFrameFont(region, fontPath, size, flags)
    if not region then
        return false
    end
    if MMF_SetFontSafe then
        return MMF_SetFontSafe(region, fontPath, size, flags)
    end
    if not region.SetFont then
        return false
    end

    local requestedFlags = flags or ""
    local ok, applied = pcall(region.SetFont, region, fontPath, size, requestedFlags)
    if ok and applied ~= false then
        return true
    end
    if requestedFlags ~= "" then
        ok, applied = pcall(region.SetFont, region, fontPath, size, "")
        if ok and applied ~= false then
            return true
        end
    end
    return false
end

function MMF_UpdateNameTextSize(size, unit)
    size = tonumber(size) or 12
    if size < 6 then size = 6 end
    size = math.floor(size + 0.5)
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or MMF_Config.FONT_PATH
    ForEachUnitFrame(unit, function(frame)
        if frame and frame.nameText then
            if TryApplyFrameFont(frame.nameText, fontPath, size, "OUTLINE") then
                frame.mmfAppliedNameFontSize = size
            else
                frame.mmfAppliedNameFontSize = nil
            end
            if frame.unit and UnitExists(frame.unit) then
                local currentText = frame.nameText:GetText()
                frame.nameText:SetText("")
                frame.nameText:SetText(currentText)
            end
        end
    end)
end

function MMF_UpdateHPTextSize(size, unit)
    size = tonumber(size) or 13
    if size < 6 then size = 6 end
    size = math.floor(size + 0.5)
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or MMF_Config.FONT_PATH
    ForEachUnitFrame(unit, function(frame)
        if frame and frame.hpText then
            if TryApplyFrameFont(frame.hpText, fontPath, size, "OUTLINE") then
                frame.mmfAppliedHPFontSize = size
            else
                frame.mmfAppliedHPFontSize = nil
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
    end)
end

function MMF_GetFrameScaleX(unit)
    if not MattMinimalFramesDB then return 1.0 end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "FrameScaleX"
    return MattMinimalFramesDB[key] or 1.0
end

function MMF_GetFrameScaleY(unit)
    if not MattMinimalFramesDB then return 1.0 end
    local prefix = GetUnitPrefix(unit or "player")
    local key = prefix .. "FrameScaleY"
    return MattMinimalFramesDB[key] or 1.0
end

function MMF_UpdateFrameScale(unit)
    if unit == "playerCastBar" or unit == "targetCastBar" or unit == "focusCastBar" then
        local ownerUnit = (unit == "playerCastBar" and "player")
            or (unit == "targetCastBar" and "target")
            or "focus"
        local ownerFrame = MMF_GetFrameForUnit(ownerUnit)
        if ownerFrame and ownerFrame.castBarFrame and MMF_ApplyCastBarPosition then
            MMF_ApplyCastBarPosition(ownerFrame, ownerFrame.unit)
        end
        return
    end

    if unit == "boss" then
        for i = 1, 5 do
            MMF_UpdateFrameScale("boss" .. i)
        end
        return
    end

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
    local borderSize = tonumber(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBorderSize) or 1
    borderSize = math.floor(borderSize + 0.5)
    if borderSize < 0 then borderSize = 0 end
    if borderSize > 3 then borderSize = 3 end
    local healthInset = math.max(1, borderSize)
    local borderAlpha = tonumber(MattMinimalFramesDB and MattMinimalFramesDB.healthBarBorderAlpha) or 1
    if frame.healthBar then
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", healthInset, -healthInset)
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -healthInset, healthInset)
    end
    if frame.healthBarBG then
        frame.healthBarBG:SetPoint("TOPLEFT", frame, "TOPLEFT", healthInset, -healthInset)
        frame.healthBarBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -healthInset, healthInset)
    end
    if frame.healthBarBorder then
        frame.healthBarBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.healthBarBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame.healthBarBorder:SetShown(borderSize > 0 and borderAlpha > 0)
    end
    if frame.absorbBar then
        frame.absorbBar:ClearAllPoints()
    end
    if frame.nameText then
        frame.nameText:SetWidth(newWidth - 4)
    end
    ApplyFrameTextOffsets(frame)
    if frame.castBarFrame then
        if MMF_ApplyCastBarPosition then
            MMF_ApplyCastBarPosition(frame, frame.unit)
        else
            frame.castBarFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 1)
        end
    end
    if frame.classIcon then
        local iconSize = math.max(8, newHeight)
        frame.classIcon:SetSize(iconSize, iconSize)
        if MMF_ApplyFrameIconPlacement then
            MMF_ApplyFrameIconPlacement(frame)
        else
            frame.classIcon:ClearAllPoints()
            frame.classIcon:SetPoint("RIGHT", frame, "LEFT", 0, 0)
        end
    end
    if frame.targetIcon then
        local iconSize = math.max(8, newHeight)
        frame.targetIcon:SetSize(iconSize, iconSize)
        if MMF_ApplyFrameIconPlacement then
            MMF_ApplyFrameIconPlacement(frame)
        else
            frame.targetIcon:ClearAllPoints()
            frame.targetIcon:SetPoint("LEFT", frame, "RIGHT", 0, 0)
        end
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
    local units = {"player", "target", "targettarget", "focus", "pet", "boss", "playerCastBar", "targetCastBar", "focusCastBar"}
    for _, unit in ipairs(units) do
        MMF_UpdateFrameScale(unit)
    end
end
