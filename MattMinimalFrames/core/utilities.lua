MMF_UIHider = CreateFrame("Frame")
MMF_UIHider:Hide()

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

local function IsFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function SafeSetFont(region, fontPath, size, flags)
    if not region or not region.SetFont then
        return false
    end
    if not IsFiniteNumber(size) or size <= 0 then
        return false
    end

    local fallbackPath = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    local requestedPath = fontPath
    if type(requestedPath) ~= "string" or requestedPath == "" then
        requestedPath = fallbackPath
    end

    local requestedFlags = flags or ""
    local ok, applied = pcall(region.SetFont, region, requestedPath, size, requestedFlags)
    if ok and applied ~= false then
        return true
    end

    if requestedFlags ~= "" then
        ok, applied = pcall(region.SetFont, region, requestedPath, size, "")
        if ok and applied ~= false then
            return true
        end
    end

    ok, applied = pcall(region.SetFont, region, fallbackPath, size, requestedFlags)
    if ok and applied ~= false then
        return true
    end

    ok, applied = pcall(region.SetFont, region, fallbackPath, size, "")
    return ok and applied ~= false
end

function MMF_SetFontSafe(region, fontPath, size, flags)
    return SafeSetFont(region, fontPath, size, flags)
end

function MMF_ClampGUIScale(value)
    local scale = tonumber(value)
    if not IsFiniteNumber(scale) then
        return 1.0
    end
    if scale < 0.5 then
        return 0.5
    end
    if scale > 1.5 then
        return 1.5
    end
    return math.floor(scale * 10 + 0.5) / 10
end

function MMF_AddEditModeHighlight(frame, name)
    if frame and name then
        frame.editModeHighlight = frame:CreateTexture(nil, "OVERLAY")
        frame.editModeHighlight:SetAllPoints()
        frame.editModeHighlight:SetColorTexture(1, 1, 1, 0.3)
        frame.editModeHighlight:Hide()
        frame.editModeName = name
    end
end

function MMF_HideFrame(frame)
    if frame then
        frame:Hide()
        frame:SetParent(MMF_UIHider)
    end
end

function MMF_ShowFrame(frame, parent)
    if frame then
        frame:SetParent(parent or UIParent)
        frame:Show()
    end
end

--------------------------------------------------
-- ALIGNMENT GRID
--------------------------------------------------

local alignmentGrid = nil

function MMF_ToggleAlignmentGrid(show)
    if not show then
        if alignmentGrid then alignmentGrid:Hide() end
        return
    end

    if not alignmentGrid then
        alignmentGrid = CreateFrame("Frame", "MMF_AlignmentGrid", UIParent)
        alignmentGrid:SetAllPoints(UIParent)
        alignmentGrid:SetFrameStrata("LOW")
        alignmentGrid:EnableMouse(false)

        local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
        local sp = 25

        -- Center crosshair
        local cv = alignmentGrid:CreateTexture(nil, "OVERLAY")
        cv:SetColorTexture(0.784, 0.271, 0.980, 0.5)
        cv:SetSize(2, sh)
        cv:SetPoint("CENTER", alignmentGrid, "CENTER", 0, 0)

        local ch = alignmentGrid:CreateTexture(nil, "OVERLAY")
        ch:SetColorTexture(0.784, 0.271, 0.980, 0.5)
        ch:SetSize(sw, 2)
        ch:SetPoint("CENTER", alignmentGrid, "CENTER", 0, 0)

        -- Grid lines radiating from center 
        for i = 1, math.floor(sw / sp / 2) do
            local off = i * sp
            local r = alignmentGrid:CreateTexture(nil, "ARTWORK")
            r:SetColorTexture(1, 1, 1, 0.25)
            r:SetSize(1, sh)
            r:SetPoint("CENTER", alignmentGrid, "CENTER", off, 0)
            local l = alignmentGrid:CreateTexture(nil, "ARTWORK")
            l:SetColorTexture(1, 1, 1, 0.25)
            l:SetSize(1, sh)
            l:SetPoint("CENTER", alignmentGrid, "CENTER", -off, 0)
        end

        for i = 1, math.floor(sh / sp / 2) do
            local off = i * sp
            local u = alignmentGrid:CreateTexture(nil, "ARTWORK")
            u:SetColorTexture(1, 1, 1, 0.25)
            u:SetSize(sw, 1)
            u:SetPoint("CENTER", alignmentGrid, "CENTER", 0, off)
            local d = alignmentGrid:CreateTexture(nil, "ARTWORK")
            d:SetColorTexture(1, 1, 1, 0.25)
            d:SetSize(sw, 1)
            d:SetPoint("CENTER", alignmentGrid, "CENTER", 0, -off)
        end
    end

    alignmentGrid:Show()
end

--------------------------------------------------
-- STATUSBAR TEXTURE
--------------------------------------------------

function MMF_ApplyStatusBarTexture()
    local texturePath = MMF_GetStatusBarTexturePath and MMF_GetStatusBarTexturePath()
    if not texturePath then return end

    local frames = MMF_GetAllFrames and MMF_GetAllFrames() or {}
    for _, frame in ipairs(frames) do
        if frame then
            if frame.healthBar then
                frame.healthBar:SetStatusBarTexture(texturePath)
            end
            if frame.powerBar then
                frame.powerBar:SetStatusBarTexture(texturePath)
            end
            if frame.myHealPrediction then
                frame.myHealPrediction:SetStatusBarTexture(texturePath)
            end
            if frame.otherHealPrediction then
                frame.otherHealPrediction:SetStatusBarTexture(texturePath)
            end
            if frame.castBar then
                frame.castBar:SetStatusBarTexture(texturePath)
            end
        end
    end

    local classBars = {
        _G.MMF_RuneBar,
        _G.MMF_HolyPowerBar,
        _G.MMF_ComboPointBar,
        _G.MMF_SoulShardBar,
        _G.MMF_ChiBar,
        _G.MMF_ArcaneChargeBar,
        _G.MMF_EssenceBar,
    }

    for _, bar in ipairs(classBars) do
        if bar and bar.runes then
            for _, rune in ipairs(bar.runes) do
                if rune and rune.SetStatusBarTexture then
                    rune:SetStatusBarTexture(texturePath)
                end
            end
        end
    end
end

function MMF_SetStatusBarTexture(textureName)
    textureName = NormalizeMediaName(textureName)
    if not textureName then return end
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.statusBarTexture = textureName
    MMF_ApplyStatusBarTexture()
end

--------------------------------------------------
-- GLOBAL FONT
--------------------------------------------------

local function ApplyFontToPopupTree(frame, fontPath)
    if not frame or not fontPath then return end

    local function ApplyToRegion(region)
        if not region or not region.GetObjectType or region:GetObjectType() ~= "FontString" then
            return
        end
        local _, size, flags = region:GetFont()
        if IsFiniteNumber(size) and size > 0 then
            SafeSetFont(region, fontPath, size, flags or "")
        end
    end

    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        ApplyToRegion(region)
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        ApplyFontToPopupTree(child, fontPath)
    end
end

function MMF_ApplyGlobalFont()
    local fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or (MMF_Config and MMF_Config.FONT_PATH)
    if not fontPath then return end
    if MMF_Config then
        MMF_Config.FONT_PATH = fontPath
    end

    local frames = MMF_GetAllFrames and MMF_GetAllFrames() or {}
    for _, frame in ipairs(frames) do
        if frame then
            local unit = frame.unit
            local nameSize = (MMF_GetNameTextSize and MMF_GetNameTextSize(unit)) or 12
            local hpSize = (MMF_GetHPTextSize and MMF_GetHPTextSize(unit)) or 13
            if frame.nameText then SafeSetFont(frame.nameText, fontPath, nameSize, "OUTLINE") end
            if frame.hpText then SafeSetFont(frame.hpText, fontPath, hpSize, "OUTLINE") end
            if frame.powerText then SafeSetFont(frame.powerText, fontPath, 13, "OUTLINE") end
            if frame.castBarText then SafeSetFont(frame.castBarText, fontPath, 9, "OUTLINE") end
            if frame.moveHint then SafeSetFont(frame.moveHint, fontPath, 10, "OUTLINE") end
            if frame.moveSubtext then SafeSetFont(frame.moveSubtext, fontPath, 9, "OUTLINE") end
        end
    end

    local classBars = {
        _G.MMF_RuneBar,
        _G.MMF_HolyPowerBar,
        _G.MMF_ComboPointBar,
        _G.MMF_SoulShardBar,
        _G.MMF_ChiBar,
        _G.MMF_ArcaneChargeBar,
        _G.MMF_EssenceBar,
    }
    for _, bar in ipairs(classBars) do
        if bar then
            if bar.moveHint then SafeSetFont(bar.moveHint, fontPath, 10, "OUTLINE") end
            if bar.moveSubtext then SafeSetFont(bar.moveSubtext, fontPath, 9, "OUTLINE") end
        end
    end

    if MMF_WelcomePopup then
        ApplyFontToPopupTree(MMF_WelcomePopup, fontPath)
    end
end
