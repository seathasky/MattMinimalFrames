local function ApplyDefaultsSafe(target, defaults)
    if _G.MMF_Startup_ApplyDefaultsSafe then
        _G.MMF_Startup_ApplyDefaultsSafe(target, defaults)
    end
end

local function NormalizeLegacyIconModes(db)
    if _G.MMF_Startup_NormalizeLegacyIconModes then
        _G.MMF_Startup_NormalizeLegacyIconModes(db)
    end
end

local function NormalizeLegacyPartyRaidFontSetting(db)
    if _G.MMF_Startup_NormalizeLegacyPartyRaidFontSetting then
        _G.MMF_Startup_NormalizeLegacyPartyRaidFontSetting(db)
    end
end

local function NormalizeGUIScaleSetting()
    if _G.MMF_Startup_NormalizeGUIScaleSetting then
        _G.MMF_Startup_NormalizeGUIScaleSetting()
    end
end

local function NormalizeLegacyTextEffectsSetting(db)
    if _G.MMF_Startup_NormalizeLegacyTextEffectsSetting then
        _G.MMF_Startup_NormalizeLegacyTextEffectsSetting(db)
    end
end

local function NormalizeLegacyHPTextPosition(db)
    if _G.MMF_Startup_NormalizeLegacyHPTextPosition then
        _G.MMF_Startup_NormalizeLegacyHPTextPosition(db)
    end
end

local function NormalizeLegacyPowerBarDefaults(db)
    if _G.MMF_Startup_NormalizeLegacyPowerBarDefaults then
        _G.MMF_Startup_NormalizeLegacyPowerBarDefaults(db)
        local profiles = MattMinimalFramesProfilesDB and MattMinimalFramesProfilesDB.profiles
        if type(profiles) == "table" then
            for _, profile in pairs(profiles) do
                _G.MMF_Startup_NormalizeLegacyPowerBarDefaults(profile)
            end
        end
    end
end

local function NormalizeLegacyTextSizes(db)
    if _G.MMF_Startup_NormalizeLegacyTextSizes then
        _G.MMF_Startup_NormalizeLegacyTextSizes(db)
    end
end

local function Initialize()
    if MMF_Profiles_Initialize then
        MMF_Profiles_Initialize()
    elseif not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    if MMF_NormalizeActiveProfile then
        MMF_NormalizeActiveProfile()
    else
        NormalizeLegacyIconModes(MattMinimalFramesDB)
        if MattMinimalFrames_Defaults then
            ApplyDefaultsSafe(MattMinimalFramesDB, MattMinimalFrames_Defaults)
        end
    end
    NormalizeLegacyPartyRaidFontSetting(MattMinimalFramesDB)
    NormalizeLegacyTextEffectsSetting(MattMinimalFramesDB)
    NormalizeLegacyHPTextPosition(MattMinimalFramesDB)
    NormalizeLegacyPowerBarDefaults(MattMinimalFramesDB)
    NormalizeLegacyTextSizes(MattMinimalFramesDB)
    if MattMinimalFramesDB then
        -- Always reset preview-only aura test mode on UI load/reload.
        MattMinimalFramesDB.auraTestMode = false
        MattMinimalFramesDB.layoutTestMode = false
    end
    NormalizeGUIScaleSetting()
    if MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true then
        reopenMainGUIAfterEditModeReset = true
        MattMinimalFramesDB.unlockFramesEditMode = false
        MattMinimalFramesDB.mmfLockedBeforeEditMode = nil
        MattMinimalFramesDB.mmfGridBeforeEditMode = nil
        MattMinimalFramesDB.showAlignmentGrid = false
        if MMF_ToggleAlignmentGrid then
            MMF_ToggleAlignmentGrid(false)
        end
    end
    if MMF_EnsureStatusBarTextureSelection then
        MMF_EnsureStatusBarTextureSelection()
    end
    
    if MMF_HideBlizzardFrames then
        MMF_HideBlizzardFrames()
    end
    if MMF_UpdateBlizzardPlayerCastBarVisibility then
        MMF_UpdateBlizzardPlayerCastBarVisibility()
    end
    if MMF_UpdateBlizzardPartyRaidNameFonts then
        MMF_UpdateBlizzardPartyRaidNameFonts()
    end
    if MMF_UpdateBlizzardSoloPartyFrameVisibility then
        MMF_UpdateBlizzardSoloPartyFrameVisibility()
    end
    if MMF_UpdateBlizzardPartySelfVisibility then
        MMF_UpdateBlizzardPartySelfVisibility()
    end
    MMF_CreateAllMinimalFrames()
    if MMF_UpdateCombatFrameVisibility then
        MMF_UpdateCombatFrameVisibility()
    end
    MMF_ApplyAllFrameScales()
    MMF_InitializeClassResources()
    MMF_ApplyStatusBarTexture()
    if MMF_ApplyPetActionBarPosition then
        MMF_ApplyPetActionBarPosition()
    end
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
    if MMF_ApplyToolsNoteState then
        MMF_ApplyToolsNoteState()
    end
    if MMF_UpdateTargetMarkers then
        MMF_UpdateTargetMarkers()
    end
    if MattMinimalFramesDB.locked then
        MMF_LockFrames()
    else
        MMF_UnlockFrames()
    end
end

local isInitialized = false
local reopenMainGUIAfterEditModeReset = false

local function ReapplySharedMediaSelections()
    if _G.MMF_Startup_ReapplySharedMediaSelections then
        _G.MMF_Startup_ReapplySharedMediaSelections()
    end
end

local function ScheduleStartupStyleReapply()
    if _G.MMF_Startup_ScheduleStyleReapply then
        _G.MMF_Startup_ScheduleStyleReapply(function()
            return isInitialized == true
        end)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MattMinimalFrames" then
        Initialize()
        isInitialized = true
        ScheduleStartupStyleReapply()
        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_LOGIN" and isInitialized then
        if MMF_HideBlizzardFrames then
            MMF_HideBlizzardFrames()
        end
        if MMF_ResolveCharacterProfile then
            MMF_ResolveCharacterProfile(true)
        elseif MMF_NormalizeActiveProfile then
            MMF_NormalizeActiveProfile()
            if MMF_ApplyActiveProfileLive then
                MMF_ApplyActiveProfileLive()
            end
        end
        if MattMinimalFramesDB then
            MattMinimalFramesDB.auraTestMode = false
            MattMinimalFramesDB.layoutTestMode = false
        end
        if MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end

        -- Apply selected SharedMedia again after all addons have loaded.
        ReapplySharedMediaSelections()
        if MMF_UpdateBlizzardPlayerCastBarVisibility then
            MMF_UpdateBlizzardPlayerCastBarVisibility()
        end
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        if MMF_UpdateBlizzardSoloPartyFrameVisibility then
            MMF_UpdateBlizzardSoloPartyFrameVisibility()
        end
        if MMF_UpdateBlizzardPartySelfVisibility then
            MMF_UpdateBlizzardPartySelfVisibility()
        end
        ScheduleStartupStyleReapply()
        if MMF_TryShowChangelog then
            MMF_TryShowChangelog()
        else
            -- Inline fallback: show changelog if the module didn't load
            if MattMinimalFramesDB and MattMinimalFramesDB.changelogSeenVersion ~= "7.7.2" then
                local f = CreateFrame("Frame", "MMF_ChangelogPopup", UIParent)
                f:SetSize(430, 220)
                f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
                f:SetFrameStrata("DIALOG")
                f:SetFrameLevel(200)
                f:SetMovable(true)
                f:EnableMouse(true)
                f:RegisterForDrag("LeftButton")
                f:SetScript("OnDragStart", function(self) self:StartMoving() end)
                f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
                local bg = f:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.05, 0.06, 0.08, 0.97)
                local titleBG = f:CreateTexture(nil, "BACKGROUND", nil, 1)
                titleBG:SetPoint("TOPLEFT", 1, -1)
                titleBG:SetPoint("TOPRIGHT", -1, -1)
                titleBG:SetHeight(28)
                titleBG:SetColorTexture(0.07, 0.09, 0.12, 1)
                local ttl = f:CreateFontString(nil, "OVERLAY")
                ttl:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
                ttl:SetPoint("TOPLEFT", 12, -8)
                ttl:SetTextColor(0.90, 0.72, 0.22, 1)
                ttl:SetText("Matt's Minimal Frames  |cffffffff- v7.7.2|r")
                local cb = CreateFrame("Button", nil, f)
                cb:SetSize(24, 24)
                cb:SetPoint("TOPRIGHT", -6, -3)
                local ct = cb:CreateFontString(nil, "OVERLAY")
                ct:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 13, "")
                ct:SetAllPoints()
                ct:SetJustifyH("CENTER")
                ct:SetTextColor(0.5, 0.5, 0.5)
                ct:SetText("X")
                cb:SetScript("OnClick", function() f:Hide() end)
                local div = f:CreateTexture(nil, "ARTWORK")
                div:SetSize(410, 1)
                div:SetPoint("TOPLEFT", 10, -30)
                div:SetColorTexture(0.14, 0.16, 0.20, 1)
                local lines = {
                    "* Classic Era is now officially supported as its own addon build.",
                    "* Mana bar now sits flush at the bottom of the player frame as a thin strip.",
                    "* Health and mana values display inside the frame - HP right, mana left.",
                    "* Cleaner defaults: smaller text, smarter positions, ERA EDITION branding.",
                }
                local y = -44
                for _, line in ipairs(lines) do
                    local t = f:CreateFontString(nil, "OVERLAY")
                    t:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
                    t:SetPoint("TOPLEFT", 14, y)
                    t:SetWidth(400)
                    t:SetJustifyH("LEFT")
                    t:SetTextColor(0.78, 0.80, 0.84)
                    t:SetText(line)
                    y = y - 26
                end
                local div2 = f:CreateTexture(nil, "ARTWORK")
                div2:SetSize(410, 1)
                div2:SetPoint("BOTTOMLEFT", 10, 34)
                div2:SetColorTexture(0.14, 0.16, 0.20, 1)
                local ck = CreateFrame("CheckButton", nil, f)
                ck:SetSize(14, 14)
                ck:SetPoint("BOTTOMLEFT", 12, 12)
                local ckBG = ck:CreateTexture(nil, "BACKGROUND")
                ckBG:SetAllPoints()
                ckBG:SetColorTexture(0.1, 0.1, 0.12, 1)
                local ckMark = ck:CreateFontString(nil, "OVERLAY")
                ckMark:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
                ckMark:SetAllPoints()
                ckMark:SetJustifyH("CENTER")
                ckMark:SetTextColor(0.9, 0.72, 0.22, 1)
                ckMark:SetText("")
                ck:SetScript("OnClick", function(self)
                    local on = not self.on
                    self.on = on
                    ckMark:SetText(on and "+" or "")
                    if on and MattMinimalFramesDB then
                        MattMinimalFramesDB.changelogSeenVersion = "7.7.2"
                        f:Hide()
                    end
                end)
                local ckL = f:CreateFontString(nil, "OVERLAY")
                ckL:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
                ckL:SetPoint("LEFT", ck, "RIGHT", 6, 0)
                ckL:SetTextColor(0.55, 0.57, 0.62)
                ckL:SetText("Don't show this again")
                f:Show()
            end
        end
        if reopenMainGUIAfterEditModeReset and MMF_ShowWelcomePopup then
            reopenMainGUIAfterEditModeReset = false
            MMF_ShowWelcomePopup(true)
        end
        return
    end
end)
