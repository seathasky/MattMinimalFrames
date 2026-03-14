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
        frame.editModeHighlight:SetColorTexture(0, 0, 0, 0.35)
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

function MMF_ApplyHealthBarBackgroundColor()
    local db = MattMinimalFramesDB or {}
    local function Clamp01(value, fallback)
        local n = tonumber(value)
        if not n then
            n = tonumber(fallback) or 0
        end
        if n < 0 then n = 0 end
        if n > 1 then n = 1 end
        return n
    end

    local r = Clamp01(db.healthBarBGColorR, 0)
    local g = Clamp01(db.healthBarBGColorG, 0)
    local b = Clamp01(db.healthBarBGColorB, 0)
    local a = Clamp01(db.healthBarBGAlpha, 0.65)

    local function ClampBorderSize(value, fallback)
        local n = tonumber(value)
        if not n then
            n = tonumber(fallback) or 1
        end
        n = math.floor(n + 0.5)
        if n < 0 then n = 0 end
        if n > 3 then n = 3 end
        return n
    end

    local borderSize = ClampBorderSize(db.healthBarBorderSize, 1)
    local inset = math.max(1, borderSize)

    local frames = {}
    local seen = {}

    local function AddFrame(frame)
        if not frame or seen[frame] then
            return
        end
        seen[frame] = true
        frames[#frames + 1] = frame
    end

    if MMF_GetAllFrames then
        for _, frame in ipairs(MMF_GetAllFrames() or {}) do
            AddFrame(frame)
        end
    end

    AddFrame(_G.MMF_PlayerFrame)
    AddFrame(_G.MMF_TargetFrame)
    AddFrame(_G.MMF_TargetOfTargetFrame)
    AddFrame(_G.MMF_FocusFrame)
    AddFrame(_G.MMF_PetFrame)

    for _, frame in ipairs(frames) do
        if frame and frame.healthBarBG and frame.healthBarBG.SetColorTexture then
            if frame.healthBarBG.ClearAllPoints then
                frame.healthBarBG:ClearAllPoints()
                frame.healthBarBG:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
                frame.healthBarBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
            end
            frame.healthBarBG:SetColorTexture(r, g, b, a)
        end
        if frame and frame.healthBar and frame.healthBar.ClearAllPoints then
            frame.healthBar:ClearAllPoints()
            frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
            frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
        end
    end

    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
    end
end

function MMF_ApplyHealthBarBorderStyle()
    local db = MattMinimalFramesDB or {}

    local function Clamp01(value, fallback)
        local n = tonumber(value)
        if not n then
            n = tonumber(fallback) or 0
        end
        if n < 0 then n = 0 end
        if n > 1 then n = 1 end
        return n
    end

    local function ClampBorderSize(value, fallback)
        local n = tonumber(value)
        if not n then
            n = tonumber(fallback) or 1
        end
        n = math.floor(n + 0.5)
        if n < 0 then n = 0 end
        if n > 3 then n = 3 end
        return n
    end

    local r = Clamp01(db.healthBarBorderColorR, 0)
    local g = Clamp01(db.healthBarBorderColorG, 0)
    local b = Clamp01(db.healthBarBorderColorB, 0)
    local a = Clamp01(db.healthBarBorderAlpha, 1)
    local size = ClampBorderSize(db.healthBarBorderSize, 1)
    local inset = math.max(1, size)

    local function EnsureHealthBarBorderEdges(frame)
        if not frame then
            return nil
        end

        if not frame.healthBarBorderEdges and frame.healthBarBorder and frame.healthBarBorder.SetColorTexture then
            frame.healthBarBorder:Hide()
            frame.healthBarBorder = nil
        end

        if not frame.healthBarBorder then
            frame.healthBarBorder = CreateFrame("Frame", nil, frame)
            frame.healthBarBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            frame.healthBarBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        end

        if not frame.healthBarBorderEdges then
            frame.healthBarBorderEdges = {
                top = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
                right = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
                bottom = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
                left = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
            }
        end

        return frame.healthBarBorderEdges
    end

    local function ApplyBorderOutline(frame, edges, edgeSize)
        if not frame or not edges then
            return
        end

        edges.top:ClearAllPoints()
        edges.top:SetPoint("TOPLEFT", frame.healthBarBorder, "TOPLEFT", 0, 0)
        edges.top:SetPoint("TOPRIGHT", frame.healthBarBorder, "TOPRIGHT", 0, 0)
        edges.top:SetHeight(edgeSize)

        edges.bottom:ClearAllPoints()
        edges.bottom:SetPoint("BOTTOMLEFT", frame.healthBarBorder, "BOTTOMLEFT", 0, 0)
        edges.bottom:SetPoint("BOTTOMRIGHT", frame.healthBarBorder, "BOTTOMRIGHT", 0, 0)
        edges.bottom:SetHeight(edgeSize)

        edges.left:ClearAllPoints()
        edges.left:SetPoint("TOPLEFT", frame.healthBarBorder, "TOPLEFT", 0, -edgeSize)
        edges.left:SetPoint("BOTTOMLEFT", frame.healthBarBorder, "BOTTOMLEFT", 0, edgeSize)
        edges.left:SetWidth(edgeSize)

        edges.right:ClearAllPoints()
        edges.right:SetPoint("TOPRIGHT", frame.healthBarBorder, "TOPRIGHT", 0, -edgeSize)
        edges.right:SetPoint("BOTTOMRIGHT", frame.healthBarBorder, "BOTTOMRIGHT", 0, edgeSize)
        edges.right:SetWidth(edgeSize)
    end

    local frames = MMF_GetAllFrames and MMF_GetAllFrames() or {}
    for _, frame in ipairs(frames) do
        if frame and frame.healthBar and frame.healthBar.ClearAllPoints then
            frame.healthBar:ClearAllPoints()
            frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
            frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
        end
        if frame and frame.healthBarBG and frame.healthBarBG.ClearAllPoints then
            frame.healthBarBG:ClearAllPoints()
            frame.healthBarBG:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
            frame.healthBarBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
        end
        if frame then
            local edges = EnsureHealthBarBorderEdges(frame)
            frame.healthBarBorder:ClearAllPoints()
            frame.healthBarBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            frame.healthBarBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            for _, edge in pairs(edges) do
                edge:SetColorTexture(r, g, b, a)
            end
            ApplyBorderOutline(frame, edges, size)
            frame.healthBarBorder:SetShown(size > 0 and a > 0)
        end
    end
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
        if region.mmfSkipGlobalFont then
            return
        end
        local _, size, flags = region:GetFont()
        if not IsFiniteNumber(size) or size <= 0 then
            size = 10
            flags = ""
        end
        SafeSetFont(region, fontPath, size, flags or "")
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
            local powerScale = (MattMinimalFramesDB and MattMinimalFramesDB.powerTextScale) or 1.0
            if unit == "player" then
                powerScale = (MattMinimalFramesDB and MattMinimalFramesDB.playerPowerTextScale) or powerScale
            elseif unit == "target" then
                powerScale = (MattMinimalFramesDB and MattMinimalFramesDB.targetPowerTextScale) or powerScale
            end
            powerScale = tonumber(powerScale) or 1.0
            if powerScale < 0.5 then powerScale = 0.5 end
            if powerScale > 2.0 then powerScale = 2.0 end
            local powerSize = math.max(6, math.floor((13 * powerScale) + 0.5))
            if frame.nameText then
                if SafeSetFont(frame.nameText, fontPath, nameSize, "OUTLINE") then
                    frame.mmfAppliedNameFontSize = math.floor((tonumber(nameSize) or 12) + 0.5)
                else
                    frame.mmfAppliedNameFontSize = nil
                end
            end
            if frame.hpText then
                if SafeSetFont(frame.hpText, fontPath, hpSize, "OUTLINE") then
                    frame.mmfAppliedHPFontSize = math.floor((tonumber(hpSize) or 13) + 0.5)
                else
                    frame.mmfAppliedHPFontSize = nil
                end
            end
            if frame.powerText then
                if SafeSetFont(frame.powerText, fontPath, powerSize, "OUTLINE") then
                    frame.mmfAppliedPowerFontSize = powerSize
                else
                    frame.mmfAppliedPowerFontSize = nil
                end
            end
            if frame.castBarText then
                local castNameSize = 12
                if unit == "player" or unit == "target" or unit == "focus" then
                    local prefix = (unit == "player" and "playerCastBar")
                        or (unit == "target" and "targetCastBar")
                        or (unit == "focus" and "focusCastBar")
                        or "targetCastBar"
                    castNameSize = tonumber(MattMinimalFramesDB and MattMinimalFramesDB[prefix .. "SpellNameTextSize"])
                        or tonumber(MMF_GetNameTextSize and MMF_GetNameTextSize(unit))
                        or 12
                end
                castNameSize = math.max(6, math.floor((tonumber(castNameSize) or 12) + 0.5))
                SafeSetFont(frame.castBarText, fontPath, castNameSize, "OUTLINE")
            end
            if frame.castBarTime then
                local castTimeSize = 9
                if unit == "player" or unit == "target" or unit == "focus" then
                    local prefix = (unit == "player" and "playerCastBar")
                        or (unit == "target" and "targetCastBar")
                        or (unit == "focus" and "focusCastBar")
                        or "targetCastBar"
                    castTimeSize = tonumber(MattMinimalFramesDB and MattMinimalFramesDB[prefix .. "CastTimeTextSize"]) or 9
                end
                castTimeSize = math.max(6, math.floor((tonumber(castTimeSize) or 9) + 0.5))
                SafeSetFont(frame.castBarTime, fontPath, castTimeSize, "OUTLINE")
            end
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
