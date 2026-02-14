local Compat = _G.MMF_Compat
local _, playerClass = UnitClass("player")

local function GetStatusBarTexturePath()
    if MMF_GetStatusBarTexturePath then
        return MMF_GetStatusBarTexturePath()
    end
    return "Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga"
end

if not Compat.HasDeathKnight then
    function MMF_InitializeClassResources() end
    function MMF_GetCurrentClassBarConfig() return nil end
    function MMF_UpdateClassBarLayout() end
    function MMF_UpdateClassBarLayoutForCurrentClass() end
    function MMF_ResetCurrentClassBarSettings() return false end
    function MMF_UpdateRuneBarScale() end
    function MMF_UpdateHolyPowerBarScale() end
    function MMF_UpdateComboPointBarScale() end
    function MMF_UpdateSoulShardBarScale() end
    function MMF_UpdateChiBarScale() end
    function MMF_UpdateArcaneChargeBarScale() end
    function MMF_UpdateEssenceBarScale() end
    return
end

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local BAR_LAYOUT_DEFAULTS = {
    runeBar = { width = 30, height = 10, spacing = 4, x = 0, y = 48, maxRunes = 6, legacyPosKey = "runeBarPosition" },
    holyPowerBar = { width = 30, height = 10, spacing = 4, x = 0, y = 48, maxRunes = 5, legacyPosKey = "holyPowerBarPosition" },
    comboPointBar = { width = 30, height = 10, spacing = 4, x = 0, y = 48, maxRunes = 7, legacyPosKey = "MMF_ComboPointBarPosition" },
    soulShardBar = { width = 30, height = 10, spacing = 4, x = 0, y = 48, maxRunes = 5, legacyPosKey = "MMF_SoulShardBarPosition" },
    chiBar = { width = 30, height = 10, spacing = 4, x = 0, y = 48, maxRunes = 6, legacyPosKey = "MMF_ChiBarPosition" },
    arcaneChargeBar = { width = 30, height = 10, spacing = 4, x = 0, y = 48, maxRunes = 4, legacyPosKey = "MMF_ArcaneChargeBarPosition" },
    essenceBar = { width = 30, height = 10, spacing = 4, x = 0, y = 48, maxRunes = 5, legacyPosKey = "MMF_EssenceBarPosition" },
}

local CLASS_BAR_CONFIG = {
    DEATHKNIGHT = {
        prefix = "runeBar",
        showKey = "showRuneBar",
        classLabel = "Death Knight",
        classColor = {0.77, 0.12, 0.23},
        showLabel = "Show Rune Bar",
        resourceLabel = "Runes",
    },
    PALADIN = {
        prefix = "holyPowerBar",
        showKey = "showHolyPowerBar",
        classLabel = "Paladin",
        classColor = {1.0, 0.6, 0.8},
        showLabel = "Show Holy Power Bar",
        resourceLabel = "Holy Power",
    },
    ROGUE = {
        prefix = "comboPointBar",
        showKey = "showComboPointBar",
        classLabel = "Rogue",
        classColor = {1.0, 0.96, 0.41},
        showLabel = "Show Combo Point Bar",
        resourceLabel = "Combo Points",
    },
    DRUID = {
        prefix = "comboPointBar",
        showKey = "showComboPointBar",
        classLabel = "Druid",
        classColor = {1.0, 0.49, 0.04},
        showLabel = "Show Combo Point Bar",
        resourceLabel = "Combo Points",
    },
    WARLOCK = {
        prefix = "soulShardBar",
        showKey = "showSoulShardBar",
        classLabel = "Warlock",
        classColor = {0.58, 0.51, 0.79},
        showLabel = "Show Soul Shard Bar",
        resourceLabel = "Soul Shards",
    },
    MONK = {
        prefix = "chiBar",
        showKey = "showChiBar",
        classLabel = "Monk",
        classColor = {0.0, 1.0, 0.6},
        showLabel = "Show Chi Bar",
        resourceLabel = "Chi",
    },
    MAGE = {
        prefix = "arcaneChargeBar",
        showKey = "showArcaneChargeBar",
        classLabel = "Mage",
        classColor = {0.4, 0.8, 1.0},
        showLabel = "Show Arcane Charge Bar",
        resourceLabel = "Arcane Charges",
        note = "Only active while Arcane specialization is selected.",
    },
    EVOKER = {
        prefix = "essenceBar",
        showKey = "showEssenceBar",
        classLabel = "Evoker",
        classColor = {0.94, 0.3, 0.8},
        showLabel = "Show Essence Bar",
        resourceLabel = "Essence",
    },
}

local MMF_RuneBar
local MMF_HolyPowerBar
local MMF_ComboPointBar
local MMF_SoulShardBar
local MMF_ChiBar
local MMF_ArcaneChargeBar
local MMF_EssenceBar

local SafeEq
local SafeNe
local SafeLe

local function IsArcaneSpec()
    if playerClass ~= "MAGE" then return false end
    local spec = Compat.GetSpecialization()
    local arcaneSpec = (_G.SPEC_MAGE_ARCANE ~= nil) and _G.SPEC_MAGE_ARCANE or 1
    return SafeEq(spec, arcaneSpec)
end

function MMF_GetCurrentClassBarConfig()
    return CLASS_BAR_CONFIG[playerClass]
end

local function GetFrameByPrefix(prefix)
    if prefix == "runeBar" then return MMF_RuneBar end
    if prefix == "holyPowerBar" then return MMF_HolyPowerBar end
    if prefix == "comboPointBar" then return MMF_ComboPointBar end
    if prefix == "soulShardBar" then return MMF_SoulShardBar end
    if prefix == "chiBar" then return MMF_ChiBar end
    if prefix == "arcaneChargeBar" then return MMF_ArcaneChargeBar end
    if prefix == "essenceBar" then return MMF_EssenceBar end
    return nil
end

local function RoundInt(num)
    return math.floor((num or 0) + 0.5)
end

SafeEq = function(a, b)
    local ok, result = pcall(function()
        return a == b
    end)
    return ok and result or false
end

SafeNe = function(a, b)
    local ok, result = pcall(function()
        return a ~= b
    end)
    return ok and result or true
end

SafeLe = function(a, b)
    local ok, result = pcall(function()
        return a <= b
    end)
    return ok and result or false
end

local function GetPowerCountSafe(powerType, maxCount)
    local raw = 0
    pcall(function()
        raw = UnitPower("player", powerType) or 0
    end)
    local count = 0
    for i = 1, maxCount do
        if SafeLe(i, raw) then
            count = i
        end
    end
    return count
end

local function GetPowerMaxCountSafe(powerType, fallbackMax)
    local raw = fallbackMax
    pcall(function()
        raw = UnitPowerMax("player", powerType) or fallbackMax
    end)
    raw = tonumber(raw) or fallbackMax
    if raw < 1 then
        raw = fallbackMax
    end
    local count = 1
    for i = 1, fallbackMax do
        if SafeLe(i, raw) then
            count = i
        end
    end
    return count
end

local function GetDBNumber(key, defaultValue)
    if MattMinimalFramesDB and type(MattMinimalFramesDB[key]) == "number" then
        return MattMinimalFramesDB[key]
    end
    return defaultValue
end

local function GetLayout(prefix)
    local d = BAR_LAYOUT_DEFAULTS[prefix]
    if not d then
        return 30, 10, 4, 0, 0
    end

    local width = math.max(6, RoundInt(GetDBNumber(prefix .. "Width", d.width)))
    local height = math.max(4, RoundInt(GetDBNumber(prefix .. "Height", d.height)))
    local spacing = math.max(0, RoundInt(GetDBNumber(prefix .. "Spacing", d.spacing)))
    local x = GetDBNumber(prefix .. "X", d.x)
    local y = GetDBNumber(prefix .. "Y", d.y)
    return width, height, spacing, x, y
end

local function SaveCenterOffsets(frame, prefix)
    if not frame or not prefix then return end
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end

    local cx, cy = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if cx and cy and ux and uy then
        MattMinimalFramesDB[prefix .. "X"] = RoundInt(cx - ux)
        MattMinimalFramesDB[prefix .. "Y"] = RoundInt(cy - uy)
    end

    -- Keep an absolute fallback point like unit frames for extra persistence safety.
    local left, top = frame:GetLeft(), frame:GetTop()
    local frameName = frame:GetName()
    if frameName and left and top then
        MattMinimalFramesDB[frameName] = { left = left, top = top }
    end
end

local function GetVisibleRunes(prefix)
    local d = BAR_LAYOUT_DEFAULTS[prefix]
    if not d then return 1 end

    if prefix == "comboPointBar" then
        return GetPowerMaxCountSafe(Enum.PowerType.ComboPoints, d.maxRunes)
    end
    if prefix == "chiBar" then
        return GetPowerMaxCountSafe(Enum.PowerType.Chi, d.maxRunes)
    end
    if prefix == "holyPowerBar" then
        return GetPowerMaxCountSafe(Enum.PowerType.HolyPower, d.maxRunes)
    end
    if prefix == "essenceBar" then
        return GetPowerMaxCountSafe(Enum.PowerType.Essence, d.maxRunes)
    end
    return d.maxRunes
end

local function ApplyLayout(frame, prefix, visibleRunes)
    if not frame or not prefix then return end
    local d = BAR_LAYOUT_DEFAULTS[prefix]
    if not d then return end

    local width, height, spacing, x, y = GetLayout(prefix)
    local maxRunes = frame.mmfMaxRunes or d.maxRunes
    local visible = 1
    local rawVisible = visibleRunes or maxRunes
    for i = 1, maxRunes do
        if SafeLe(i, rawVisible) then
            visible = i
        end
    end
    local totalWidth = (width * visible) + (spacing * math.max(0, visible - 1)) + 2

    frame:SetSize(totalWidth, height + 2)
    if frame.bg then
        frame.bg:SetAllPoints()
    end

    for i, rune in ipairs(frame.runes or {}) do
        rune:ClearAllPoints()
        rune:SetSize(width, height)
        rune:SetPoint("LEFT", frame, "LEFT", (i - 1) * (width + spacing) + 1, 0)
        if rune.bg then
            rune.bg:SetAllPoints()
        end
    end

    frame:ClearAllPoints()
    local usedAbsoluteFallback = false
    if MattMinimalFramesDB then
        local frameName = frame:GetName()
        local pos = frameName and MattMinimalFramesDB[frameName]
        local savedX = MattMinimalFramesDB[prefix .. "X"]
        local savedY = MattMinimalFramesDB[prefix .. "Y"]
        local hasCustomCenter = type(savedX) == "number" and type(savedY) == "number" and (savedX ~= d.x or savedY ~= d.y)
        if (not hasCustomCenter) and type(pos) == "table" and type(pos.left) == "number" and type(pos.top) == "number" then
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
            usedAbsoluteFallback = true
        end
    end
    if not usedAbsoluteFallback then
        frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    frame.mmfVisibleRunes = visible
end

local function ApplyLegacyScale(frame, prefix)
    if not frame or not prefix then return end
    local scale = 1
    if MattMinimalFramesDB and type(MattMinimalFramesDB[prefix .. "Scale"]) == "number" then
        scale = MattMinimalFramesDB[prefix .. "Scale"]
    end
    if scale < 0.5 then scale = 0.5 end
    if scale > 3.0 then scale = 3.0 end
    frame:SetScale(scale)
end

local function MigrateLegacyPosition(frame, prefix)
    if not frame or not prefix or not MattMinimalFramesDB then return end
    if MattMinimalFramesDB[prefix .. "X"] ~= nil and MattMinimalFramesDB[prefix .. "Y"] ~= nil then return end

    local d = BAR_LAYOUT_DEFAULTS[prefix]
    if not d or not d.legacyPosKey then return end
    local legacyPos = MattMinimalFramesDB[d.legacyPosKey]
    if not legacyPos or legacyPos.left == nil or legacyPos.top == nil then return end

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", legacyPos.left, legacyPos.top)
    SaveCenterOffsets(frame, prefix)
end

local function CreateBaseResourceBar(frameName, prefix, moveLabel, color, numRunes, initialValue)
    local frame = CreateFrame("Frame", frameName, UIParent)
    frame.mmfLayoutKey = prefix
    frame.mmfMaxRunes = numRunes
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.5)

    frame.runes = {}
    for i = 1, numRunes do
        local rune = CreateFrame("StatusBar", nil, frame)
        rune:SetStatusBarTexture(GetStatusBarTexturePath())
        rune:SetMinMaxValues(0, 1)
        rune:SetValue(initialValue or 0)
        rune:SetOrientation("HORIZONTAL")
        rune.bg = rune:CreateTexture(nil, "BACKGROUND")
        rune.bg:SetAllPoints()
        rune.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        rune:SetStatusBarColor(color[1], color[2], color[3], 1)
        frame.runes[i] = rune
    end

    frame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveCenterOffsets(self, self.mmfLayoutKey)
    end)

    frame.moveHint = frame:CreateFontString(nil, "OVERLAY")
    frame.moveHint:SetFont((MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "OUTLINE")
    frame.moveHint:SetText(moveLabel)
    frame.moveHint:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.moveHint:Hide()

    frame.moveSubtext = frame:CreateFontString(nil, "OVERLAY")
    frame.moveSubtext:SetFont((MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "OUTLINE")
    frame.moveSubtext:SetText("Shift+Drag to move")
    frame.moveSubtext:SetPoint("TOP", frame.moveHint, "BOTTOM", 0, -2)
    frame.moveSubtext:SetTextColor(0.7, 0.7, 0.7)
    frame.moveSubtext:Hide()

    frame:SetScript("OnEnter", function(self)
        if not InCombatLockdown() and MattMinimalFramesDB and MattMinimalFramesDB.showMoveHints then
            self.moveHint:Show()
            self.moveSubtext:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        self.moveHint:Hide()
        self.moveSubtext:Hide()
    end)

    ApplyLayout(frame, prefix, GetVisibleRunes(prefix))
    MigrateLegacyPosition(frame, prefix)
    ApplyLayout(frame, prefix, GetVisibleRunes(prefix))
    return frame
end

local function CreateRuneBar()
    if MMF_RuneBar then return MMF_RuneBar end
    MMF_RuneBar = CreateBaseResourceBar("MMF_RuneBar", "runeBar", "Rune Bar", {0.3, 0.8, 1.0}, 6, 1)
    _G.MMF_RuneBar = MMF_RuneBar
    return MMF_RuneBar
end

local function CreateHolyPowerBar()
    if MMF_HolyPowerBar then return MMF_HolyPowerBar end
    MMF_HolyPowerBar = CreateBaseResourceBar("MMF_HolyPowerBar", "holyPowerBar", "Holy Power Bar", {0.95, 0.9, 0.2}, 5, 0)
    _G.MMF_HolyPowerBar = MMF_HolyPowerBar
    return MMF_HolyPowerBar
end

local function CreateComboPointBar()
    if MMF_ComboPointBar then return MMF_ComboPointBar end
    MMF_ComboPointBar = CreateBaseResourceBar("MMF_ComboPointBar", "comboPointBar", "Combo Point", {1, 0.8, 0.2}, 7, 0)
    _G.MMF_ComboPointBar = MMF_ComboPointBar
    return MMF_ComboPointBar
end

local function CreateSoulShardBar()
    if MMF_SoulShardBar then return MMF_SoulShardBar end
    MMF_SoulShardBar = CreateBaseResourceBar("MMF_SoulShardBar", "soulShardBar", "Soul Shard", {0.9, 0.5, 1}, 5, 0)
    _G.MMF_SoulShardBar = MMF_SoulShardBar
    return MMF_SoulShardBar
end

local function CreateChiBar()
    if MMF_ChiBar then return MMF_ChiBar end
    MMF_ChiBar = CreateBaseResourceBar("MMF_ChiBar", "chiBar", "Chi", {0.2, 1, 0.8}, 6, 0)
    _G.MMF_ChiBar = MMF_ChiBar
    return MMF_ChiBar
end

local function CreateArcaneChargeBar()
    if MMF_ArcaneChargeBar then return MMF_ArcaneChargeBar end
    MMF_ArcaneChargeBar = CreateBaseResourceBar("MMF_ArcaneChargeBar", "arcaneChargeBar", "Arcane Charge", {0.4, 0.7, 1}, 4, 0)
    _G.MMF_ArcaneChargeBar = MMF_ArcaneChargeBar
    return MMF_ArcaneChargeBar
end

local function CreateEssenceBar()
    if MMF_EssenceBar then return MMF_EssenceBar end
    MMF_EssenceBar = CreateBaseResourceBar("MMF_EssenceBar", "essenceBar", "Essence", {1, 0.5, 0.7}, 5, 0)
    _G.MMF_EssenceBar = MMF_EssenceBar
    return MMF_EssenceBar
end

--------------------------------------------------
-- LAYOUT UPDATE API
--------------------------------------------------

function MMF_UpdateClassBarLayout(prefix)
    local frame = GetFrameByPrefix(prefix)
    if not frame then return end
    ApplyLayout(frame, prefix, GetVisibleRunes(prefix))
end

function MMF_UpdateClassBarLayoutForCurrentClass()
    local cfg = MMF_GetCurrentClassBarConfig()
    if not cfg or not cfg.prefix then return end
    MMF_UpdateClassBarLayout(cfg.prefix)
end

function MMF_ResetCurrentClassBarSettings()
    local cfg = MMF_GetCurrentClassBarConfig()
    if not cfg or not cfg.prefix or not cfg.showKey then
        return false
    end
    if not MattMinimalFramesDB or not MattMinimalFrames_Defaults then
        return false
    end

    local prefix = cfg.prefix
    local d = MattMinimalFrames_Defaults
    local keys = {
        cfg.showKey,
        prefix .. "Scale",
        prefix .. "Width",
        prefix .. "Height",
        prefix .. "Spacing",
        prefix .. "X",
        prefix .. "Y",
    }

    local showChanged = false
    for _, key in ipairs(keys) do
        if d[key] ~= nil then
            if key == cfg.showKey and MattMinimalFramesDB[key] ~= d[key] then
                showChanged = true
            end
            MattMinimalFramesDB[key] = d[key]
        end
    end

    MMF_UpdateClassBarLayout(prefix)
    return showChanged
end

--------------------------------------------------
-- BAR UPDATE LOGIC
--------------------------------------------------

local function UpdateRuneBar()
    if not MMF_RuneBar or not MMF_RuneBar:IsShown() then return end
    local currentTime = GetTime()

    for i = 1, 6 do
        local start, duration, runeReady = GetRuneCooldown(i)
        local rune = MMF_RuneBar.runes[i]
        if not rune then break end

        if runeReady then
            rune:SetMinMaxValues(0, 1)
            rune:SetValue(1)
            rune:SetAlpha(1)
        elseif start then
            local ok = pcall(function()
                local elapsed = currentTime - start
                rune:SetMinMaxValues(0, duration or 1)
                rune:SetValue(elapsed)
            end)
            if not ok then
                rune:SetMinMaxValues(0, 1)
                rune:SetValue(0)
            end
            rune:SetAlpha(0.4)
        end
    end
end

local function UpdateHolyPowerBar(self, event, unit)
    if not MMF_HolyPowerBar or not MMF_HolyPowerBar:IsShown() then return end
    if event and unit and unit ~= "player" then return end

    local numHolyPower = GetPowerCountSafe(Enum.PowerType.HolyPower, MMF_HolyPowerBar.mmfMaxRunes)
    local maxHolyPower = GetPowerMaxCountSafe(Enum.PowerType.HolyPower, MMF_HolyPowerBar.mmfMaxRunes)
    if SafeNe(MMF_HolyPowerBar.mmfVisibleRunes, maxHolyPower) then
        ApplyLayout(MMF_HolyPowerBar, "holyPowerBar", maxHolyPower)
    end

    for i = 1, MMF_HolyPowerBar.mmfMaxRunes do
        local rune = MMF_HolyPowerBar.runes[i]
        if rune then
            if SafeLe(i, maxHolyPower) then
                rune:Show()
                if SafeLe(i, numHolyPower) then
                    rune:SetValue(1)
                    rune:SetAlpha(1)
                else
                    rune:SetValue(0)
                    rune:SetAlpha(0.4)
                end
            else
                rune:Hide()
            end
        end
    end
end

local function UpdateComboPointBar()
    if not MMF_ComboPointBar or not MMF_ComboPointBar:IsShown() then return end

    local numComboPoints = GetPowerCountSafe(Enum.PowerType.ComboPoints, MMF_ComboPointBar.mmfMaxRunes)
    local maxComboPoints = GetPowerMaxCountSafe(Enum.PowerType.ComboPoints, MMF_ComboPointBar.mmfMaxRunes)
    if SafeNe(MMF_ComboPointBar.mmfVisibleRunes, maxComboPoints) then
        ApplyLayout(MMF_ComboPointBar, "comboPointBar", maxComboPoints)
    end

    for i = 1, MMF_ComboPointBar.mmfMaxRunes do
        local rune = MMF_ComboPointBar.runes[i]
        if rune then
            if SafeLe(i, maxComboPoints) then
                rune:Show()
                if SafeLe(i, numComboPoints) then
                    rune:SetValue(1)
                    rune:SetAlpha(1)
                else
                    rune:SetValue(0)
                    rune:SetAlpha(0.4)
                end
            else
                rune:Hide()
            end
        end
    end
end

local function UpdateSoulShardBar()
    if not MMF_SoulShardBar or not MMF_SoulShardBar:IsShown() then return end

    local numSoulShards = GetPowerCountSafe(Enum.PowerType.SoulShards, MMF_SoulShardBar.mmfMaxRunes)
    for i = 1, MMF_SoulShardBar.mmfMaxRunes do
        local rune = MMF_SoulShardBar.runes[i]
        if rune then
            if SafeLe(i, numSoulShards) then
                rune:SetValue(1)
                rune:SetAlpha(1)
            else
                rune:SetValue(0)
                rune:SetAlpha(0.4)
            end
        end
    end
end

local function UpdateChiBar()
    if not MMF_ChiBar or not MMF_ChiBar:IsShown() then return end

    local numChi = GetPowerCountSafe(Enum.PowerType.Chi, MMF_ChiBar.mmfMaxRunes)
    local maxChi = GetPowerMaxCountSafe(Enum.PowerType.Chi, MMF_ChiBar.mmfMaxRunes)
    if SafeNe(MMF_ChiBar.mmfVisibleRunes, maxChi) then
        ApplyLayout(MMF_ChiBar, "chiBar", maxChi)
    end

    for i = 1, MMF_ChiBar.mmfMaxRunes do
        local rune = MMF_ChiBar.runes[i]
        if rune then
            if SafeLe(i, maxChi) then
                rune:Show()
                if SafeLe(i, numChi) then
                    rune:SetValue(1)
                    rune:SetAlpha(1)
                else
                    rune:SetValue(0)
                    rune:SetAlpha(0.4)
                end
            else
                rune:Hide()
            end
        end
    end
end

local function UpdateArcaneChargeBar()
    if not MMF_ArcaneChargeBar or not MMF_ArcaneChargeBar:IsShown() then return end
    if not IsArcaneSpec() then return end

    local numCharges = GetPowerCountSafe(Enum.PowerType.ArcaneCharges, MMF_ArcaneChargeBar.mmfMaxRunes)
    for i = 1, MMF_ArcaneChargeBar.mmfMaxRunes do
        local rune = MMF_ArcaneChargeBar.runes[i]
        if rune then
            if SafeLe(i, numCharges) then
                rune:SetValue(1)
                rune:SetAlpha(1)
            else
                rune:SetValue(0)
                rune:SetAlpha(0.4)
            end
        end
    end
end

local function ArcaneChargeBar_OnSpecChange()
    if not MMF_ArcaneChargeBar then return end
    if not (MattMinimalFramesDB and MattMinimalFramesDB.showArcaneChargeBar) then return end
    if IsArcaneSpec() then
        MMF_ArcaneChargeBar:Show()
        UpdateArcaneChargeBar()
    else
        MMF_ArcaneChargeBar:Hide()
    end
end

local function UpdateEssenceBar()
    if not MMF_EssenceBar or not MMF_EssenceBar:IsShown() then return end

    local numEssence = GetPowerCountSafe(Enum.PowerType.Essence, MMF_EssenceBar.mmfMaxRunes)
    local maxEssence = GetPowerMaxCountSafe(Enum.PowerType.Essence, MMF_EssenceBar.mmfMaxRunes)
    if SafeNe(MMF_EssenceBar.mmfVisibleRunes, maxEssence) then
        ApplyLayout(MMF_EssenceBar, "essenceBar", maxEssence)
    end

    for i = 1, MMF_EssenceBar.mmfMaxRunes do
        local rune = MMF_EssenceBar.runes[i]
        if rune then
            if SafeLe(i, maxEssence) then
                rune:Show()
                if SafeLe(i, numEssence) then
                    rune:SetValue(1)
                    rune:SetAlpha(1)
                else
                    rune:SetValue(0)
                    rune:SetAlpha(0.4)
                end
            else
                rune:Hide()
            end
        end
    end
end

--------------------------------------------------
-- LEGACY SCALE API (COMPAT)
--------------------------------------------------

function MMF_UpdateRuneBarScale(scale)
    if MMF_RuneBar then MMF_RuneBar:SetScale(scale) end
end

function MMF_UpdateHolyPowerBarScale(scale)
    if MMF_HolyPowerBar then MMF_HolyPowerBar:SetScale(scale) end
end

function MMF_UpdateComboPointBarScale(scale)
    if MMF_ComboPointBar then MMF_ComboPointBar:SetScale(scale) end
end

function MMF_UpdateSoulShardBarScale(scale)
    if MMF_SoulShardBar then MMF_SoulShardBar:SetScale(scale) end
end

function MMF_UpdateChiBarScale(scale)
    if MMF_ChiBar then MMF_ChiBar:SetScale(scale) end
end

function MMF_UpdateArcaneChargeBarScale(scale)
    if MMF_ArcaneChargeBar then MMF_ArcaneChargeBar:SetScale(scale) end
end

function MMF_UpdateEssenceBarScale(scale)
    if MMF_EssenceBar then MMF_EssenceBar:SetScale(scale) end
end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function MMF_InitializeClassResources()
    if playerClass == "DEATHKNIGHT" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showRuneBar then
            local frame = CreateRuneBar()
            ApplyLegacyScale(frame, "runeBar")
            frame:Show()
            frame:RegisterEvent("RUNE_POWER_UPDATE")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:SetScript("OnEvent", UpdateRuneBar)
            frame.elapsed = 0
            frame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed >= 0.05 then
                    UpdateRuneBar()
                    self.elapsed = 0
                end
            end)
        end
    elseif playerClass == "PALADIN" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showHolyPowerBar then
            local frame = CreateHolyPowerBar()
            ApplyLegacyScale(frame, "holyPowerBar")
            frame:Show()
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            frame:RegisterEvent("PLAYER_TALENT_UPDATE")
            frame:SetScript("OnEvent", UpdateHolyPowerBar)
            UpdateHolyPowerBar(frame)
        end
    elseif playerClass == "ROGUE" or playerClass == "DRUID" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showComboPointBar then
            local frame = CreateComboPointBar()
            ApplyLegacyScale(frame, "comboPointBar")
            frame:Show()
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            frame:RegisterEvent("PLAYER_TALENT_UPDATE")
            frame:SetScript("OnEvent", UpdateComboPointBar)
            UpdateComboPointBar(frame)
        end
    elseif playerClass == "WARLOCK" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showSoulShardBar then
            local frame = CreateSoulShardBar()
            ApplyLegacyScale(frame, "soulShardBar")
            frame:Show()
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:SetScript("OnEvent", UpdateSoulShardBar)
            UpdateSoulShardBar(frame)
        end
    elseif playerClass == "MONK" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showChiBar then
            local frame = CreateChiBar()
            ApplyLegacyScale(frame, "chiBar")
            frame:Show()
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            frame:RegisterEvent("PLAYER_TALENT_UPDATE")
            frame:SetScript("OnEvent", UpdateChiBar)
            UpdateChiBar(frame)
        end
    elseif playerClass == "MAGE" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showArcaneChargeBar then
            local frame = CreateArcaneChargeBar()
            ApplyLegacyScale(frame, "arcaneChargeBar")
            if IsArcaneSpec() then
                frame:Show()
            else
                frame:Hide()
            end
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            frame:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
                    ArcaneChargeBar_OnSpecChange()
                end
                if event ~= "PLAYER_SPECIALIZATION_CHANGED" then
                    UpdateArcaneChargeBar(self)
                end
            end)
            UpdateArcaneChargeBar(frame)
        end
    elseif playerClass == "EVOKER" then
        if MattMinimalFramesDB and MattMinimalFramesDB.showEssenceBar then
            local frame = CreateEssenceBar()
            ApplyLegacyScale(frame, "essenceBar")
            frame:Show()
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
            frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            frame:RegisterEvent("PLAYER_TALENT_UPDATE")
            frame:SetScript("OnEvent", UpdateEssenceBar)
            UpdateEssenceBar(frame)
        end
    end
end
