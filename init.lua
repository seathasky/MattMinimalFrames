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
        if reopenMainGUIAfterEditModeReset and MMF_ShowWelcomePopup then
            reopenMainGUIAfterEditModeReset = false
            MMF_ShowWelcomePopup(true)
        end
        return
    end
end)
