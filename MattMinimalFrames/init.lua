local function HideBlizzardFrames()
    local framesToHide = {
        PlayerFrame,
        TargetFrame,
        FocusFrame,
        PetFrame,
    }
    for _, frame in pairs(framesToHide) do
        if frame then
            frame:UnregisterAllEvents()
            frame:SetScript("OnShow", function(self) self:Hide() end)
            MMF_HideFrame(frame)
        end
    end
    if TargetFrameToT then
        TargetFrameToT:UnregisterAllEvents()
        TargetFrameToT:SetScript("OnShow", function(self) self:Hide() end)
        MMF_HideFrame(TargetFrameToT)
    end
end


SLASH_MATTMINIMALFRAMES1 = "/mmf"
SlashCmdList["MATTMINIMALFRAMES"] = function()
    if MMF_ShowWelcomePopup then
        MMF_ShowWelcomePopup(true)
    end
end

SLASH_MMFRELOAD1 = "/rl"
SlashCmdList["MMFRELOAD"] = ReloadUI

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
    if type(target) ~= "table" or type(defaults) ~= "table" then return end
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = DeepCopy(value)
        elseif type(target[key]) == "table" and type(value) == "table" then
            ApplyDefaultsSafe(target[key], value)
        end
    end
end

local function NormalizeLegacyIconModes(db)
    if type(db) ~= "table" then return end
    if db.playerFrameIconMode == nil and db.showPlayerClassIcon ~= nil then
        db.playerFrameIconMode = db.showPlayerClassIcon and "class" or "off"
    end
    if db.targetFrameIconMode == nil and db.showTargetFrameIcon ~= nil then
        db.targetFrameIconMode = db.showTargetFrameIcon and "class" or "off"
    end
end

function MMF_ApplyActiveProfileLive()
    if not MattMinimalFramesDB then return end

    if InCombatLockdown() and MMF_RunAfterCombat then
        MMF_RunAfterCombat(
            "apply_active_profile_live",
            function()
                MMF_ApplyActiveProfileLive()
            end,
            "|cff00ff00Matt's Minimal Frames|r: Applying profile changes after combat."
        )
        return
    end

    local function ApplyFramePositions()
        if not MMF_Config or not MMF_Config.FRAME_DEFINITIONS then return end
        for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
            local frame = _G[def.name]
            if frame then
                frame:ClearAllPoints()
                local pos = MattMinimalFramesDB[def.name]
                if pos and pos.left and pos.top then
                    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
                else
                    frame:SetPoint("CENTER", UIParent, "CENTER", def.x, def.y)
                end
            end
        end
    end

    local function ApplyPowerBarPositions()
        if not MMF_Config then return end
        local vOff = MMF_Config.POWER_BAR_VERTICAL_OFFSET or -24
        local hOff = MMF_Config.POWER_BAR_HORIZONTAL_OFFSET or 1

        local function ApplyFor(frame, unit)
            if not frame or not frame.powerBarFrame then return end
            frame.powerBarFrame:ClearAllPoints()
            local pos = MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit]
            if pos and pos.x and pos.y then
                frame.powerBarFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
            else
                if unit == "player" then
                    frame.powerBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -hOff, vOff)
                else
                    frame.powerBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", hOff, vOff)
                end
            end
        end

        ApplyFor(_G.MMF_PlayerFrame, "player")
        ApplyFor(_G.MMF_TargetFrame, "target")
    end

    ApplyFramePositions()
    if MMF_ApplyAllFrameScales then MMF_ApplyAllFrameScales() end
    ApplyPowerBarPositions()

    if MMF_SetPowerBarSize then
        MMF_SetPowerBarSize(MattMinimalFramesDB.powerBarWidth or 73, MattMinimalFramesDB.powerBarHeight or 5)
    end
    if MMF_UpdatePowerBarVisibility then MMF_UpdatePowerBarVisibility() end

    if MMF_UpdateNameTextSize then MMF_UpdateNameTextSize(MattMinimalFramesDB.nameTextSize or 12) end
    if MMF_UpdateHPTextSize then MMF_UpdateHPTextSize(MattMinimalFramesDB.hpTextSize or 13) end
    if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end

    if MMF_UpdateBuffPosition then
        MMF_UpdateBuffPosition(MattMinimalFramesDB.buffXOffset or -2, MattMinimalFramesDB.buffYOffset or -64)
    end
    if MMF_UpdateDebuffPosition then
        MMF_UpdateDebuffPosition(MattMinimalFramesDB.debuffXOffset or 3, MattMinimalFramesDB.debuffYOffset or 27)
    end
    if MMF_UpdateAuraIconSize then MMF_UpdateAuraIconSize(MattMinimalFramesDB.auraIconSize or 18) end
    if MMF_UpdateAuraTextScale then MMF_UpdateAuraTextScale(MattMinimalFramesDB.auraTextScale or 1.0) end
    if MMF_UpdateTimerTextScale then MMF_UpdateTimerTextScale(MattMinimalFramesDB.timerTextScale or 0.8) end
    if MMF_UpdateTargetAuras then MMF_UpdateTargetAuras() end

    if MMF_ApplyStatusBarTexture then MMF_ApplyStatusBarTexture() end

    if MMF_UpdatePlayerClassIconVisibility then
        MMF_UpdatePlayerClassIconVisibility(MattMinimalFramesDB.playerFrameIconMode or "off")
    end
    if MMF_UpdateTargetFrameIconVisibility then
        MMF_UpdateTargetFrameIconVisibility(MattMinimalFramesDB.targetFrameIconMode or "off")
    end
    if MMF_UpdateTargetMarkerVisibility then
        MMF_UpdateTargetMarkerVisibility(MattMinimalFramesDB.showTargetMarkers == true)
    end

    if MMF_InitializeClassResources then MMF_InitializeClassResources() end
    if MMF_UpdateClassBarLayoutForCurrentClass then MMF_UpdateClassBarLayoutForCurrentClass() end
    if MMF_ApplyGlobalFont then MMF_ApplyGlobalFont() end

    if _G.MMF_RuneBar then _G.MMF_RuneBar:SetShown(MattMinimalFramesDB.showRuneBar ~= false) end
    if _G.MMF_HolyPowerBar then _G.MMF_HolyPowerBar:SetShown(MattMinimalFramesDB.showHolyPowerBar ~= false) end
    if _G.MMF_ComboPointBar then _G.MMF_ComboPointBar:SetShown(MattMinimalFramesDB.showComboPointBar ~= false) end
    if _G.MMF_SoulShardBar then _G.MMF_SoulShardBar:SetShown(MattMinimalFramesDB.showSoulShardBar ~= false) end
    if _G.MMF_ChiBar then _G.MMF_ChiBar:SetShown(MattMinimalFramesDB.showChiBar ~= false) end
    if _G.MMF_ArcaneChargeBar then _G.MMF_ArcaneChargeBar:SetShown(MattMinimalFramesDB.showArcaneChargeBar ~= false) end
    if _G.MMF_EssenceBar then _G.MMF_EssenceBar:SetShown(MattMinimalFramesDB.showEssenceBar ~= false) end

    if MMF_ToggleMinimapButton then
        local hidden = MattMinimalFramesDB.minimap and MattMinimalFramesDB.minimap.hide
        MMF_ToggleMinimapButton(not hidden)
    end

    if MattMinimalFramesDB.locked then
        if MMF_LockFrames then MMF_LockFrames() end
    else
        if MMF_UnlockFrames then MMF_UnlockFrames() end
    end

    if MMF_GetAllFrames and MMF_UpdateUnitFrame then
        for _, frame in ipairs(MMF_GetAllFrames()) do
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end

    if MMF_WelcomePopup then
        MMF_WelcomePopup:SetScale(MattMinimalFramesDB.guiScale or 1.0)
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
    
    HideBlizzardFrames()
    MMF_CreateAllMinimalFrames()
    MMF_ApplyAllFrameScales()
    MMF_InitializeClassResources()
    MMF_ApplyStatusBarTexture()
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
    if MMF_UpdateTargetMarkers then
        MMF_UpdateTargetMarkers()
    end
    if MattMinimalFramesDB.locked then
        MMF_LockFrames()
    else
        MMF_UnlockFrames()
    end
    C_Timer.After(1, function()
        if MMF_ShowWelcomePopup then
            MMF_ShowWelcomePopup(false)
            return
        end
        C_Timer.After(1, function()
            if MMF_ShowWelcomePopup then
                MMF_ShowWelcomePopup(false)
            end
        end)
    end)
end

local function ReapplySharedMediaSelections()
    if MMF_ApplyStatusBarTexture then
        MMF_ApplyStatusBarTexture()
    end
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
local isInitialized = false
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MattMinimalFrames" then
        Initialize()
        isInitialized = true
        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_LOGIN" and isInitialized then
        -- Apply selected SharedMedia again after all addons have loaded.
        ReapplySharedMediaSelections()
    end
end)
