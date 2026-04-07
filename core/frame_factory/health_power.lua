local cfg = MMF_Config or {}

local function GetStatusBarTexturePath()
    if MMF_GetStatusBarTexturePath then
        return MMF_GetStatusBarTexturePath()
    end
    return cfg.TEXTURE_PATH
end

local function ClampUnitInterval(value, fallback)
    local n = tonumber(value)
    if not n then
        n = tonumber(fallback) or 0
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function GetHealthBarBGColorFromDB(unit)
    if MMF_GetHealthBarBGStyle then
        return MMF_GetHealthBarBGStyle(unit)
    end

    local db = MattMinimalFramesDB or {}
    return ClampUnitInterval(db.healthBarBGColorR, 0),
        ClampUnitInterval(db.healthBarBGColorG, 0),
        ClampUnitInterval(db.healthBarBGColorB, 0),
        ClampUnitInterval(db.healthBarBGAlpha, 0.65)
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

local function GetHealthBarBorderStyleFromDB(unit)
    if MMF_GetHealthBarBorderStyle then
        return MMF_GetHealthBarBorderStyle(unit)
    end

    local db = MattMinimalFramesDB or {}
    return ClampUnitInterval(db.healthBarBorderColorR, 0),
        ClampUnitInterval(db.healthBarBorderColorG, 0),
        ClampUnitInterval(db.healthBarBorderColorB, 0),
        ClampUnitInterval(db.healthBarBorderAlpha, 1),
        ClampBorderSize(db.healthBarBorderSize, 1)
end

local function IsHealthFillTopToBottomEnabled()
    return MattMinimalFramesDB and MattMinimalFramesDB.healthFillTopToBottom == true
end

local function ApplyHealthFillDirection(frame)
    if not frame or not frame.healthBar then
        return
    end

    local orientation = IsHealthFillTopToBottomEnabled() and "VERTICAL" or "HORIZONTAL"

    if frame.healthBar.SetOrientation then
        frame.healthBar:SetOrientation(orientation)
    end
    if frame.healthBar.SetReverseFill then
        frame.healthBar:SetReverseFill(false)
    end

    if frame.myHealPrediction and frame.myHealPrediction.SetOrientation then
        frame.myHealPrediction:SetOrientation(orientation)
        if frame.myHealPrediction.SetReverseFill then
            frame.myHealPrediction:SetReverseFill(false)
        end
    end

    if frame.otherHealPrediction and frame.otherHealPrediction.SetOrientation then
        frame.otherHealPrediction:SetOrientation(orientation)
        if frame.otherHealPrediction.SetReverseFill then
            frame.otherHealPrediction:SetReverseFill(false)
        end
    end

    if frame.healAbsorbBar and frame.healAbsorbBar.SetOrientation then
        frame.healAbsorbBar:SetOrientation(orientation)
        if frame.healAbsorbBar.SetReverseFill then
            frame.healAbsorbBar:SetReverseFill(true)
        end
    end

    if frame.absorbBar and frame.absorbBar.SetOrientation then
        frame.absorbBar:SetOrientation(orientation)
        if frame.absorbBar.SetReverseFill then
            frame.absorbBar:SetReverseFill(false)
        end
    end
end

local function CreateHealthBar(frame)
    frame.healthBarBG = frame:CreateTexture(nil, "BACKGROUND")
    local borderR, borderG, borderB, borderA, borderSize = GetHealthBarBorderStyleFromDB(frame and frame.unit)
    local contentInset = math.max(1, borderSize)
    frame.healthBarBG:SetPoint("TOPLEFT", frame, "TOPLEFT", contentInset, -contentInset)
    frame.healthBarBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentInset, contentInset)
    local bgR, bgG, bgB, bgA = GetHealthBarBGColorFromDB(frame and frame.unit)
    frame.healthBarBG:SetColorTexture(bgR, bgG, bgB, bgA)

    frame.healthBarBorder = CreateFrame("Frame", nil, frame)
    frame.healthBarBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.healthBarBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    frame.healthBarBorderEdges = {
        top = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
        right = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
        bottom = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
        left = frame.healthBarBorder:CreateTexture(nil, "ARTWORK"),
    }

    local function ApplyHealthBorderOutline(size)
        local edgeSize = math.max(0, math.floor((tonumber(size) or 0) + 0.5))
        frame.healthBarBorderEdges.top:ClearAllPoints()
        frame.healthBarBorderEdges.top:SetPoint("TOPLEFT", frame.healthBarBorder, "TOPLEFT", 0, 0)
        frame.healthBarBorderEdges.top:SetPoint("TOPRIGHT", frame.healthBarBorder, "TOPRIGHT", 0, 0)
        frame.healthBarBorderEdges.top:SetHeight(edgeSize)

        frame.healthBarBorderEdges.bottom:ClearAllPoints()
        frame.healthBarBorderEdges.bottom:SetPoint("BOTTOMLEFT", frame.healthBarBorder, "BOTTOMLEFT", 0, 0)
        frame.healthBarBorderEdges.bottom:SetPoint("BOTTOMRIGHT", frame.healthBarBorder, "BOTTOMRIGHT", 0, 0)
        frame.healthBarBorderEdges.bottom:SetHeight(edgeSize)

        frame.healthBarBorderEdges.left:ClearAllPoints()
        frame.healthBarBorderEdges.left:SetPoint("TOPLEFT", frame.healthBarBorder, "TOPLEFT", 0, -edgeSize)
        frame.healthBarBorderEdges.left:SetPoint("BOTTOMLEFT", frame.healthBarBorder, "BOTTOMLEFT", 0, edgeSize)
        frame.healthBarBorderEdges.left:SetWidth(edgeSize)

        frame.healthBarBorderEdges.right:ClearAllPoints()
        frame.healthBarBorderEdges.right:SetPoint("TOPRIGHT", frame.healthBarBorder, "TOPRIGHT", 0, -edgeSize)
        frame.healthBarBorderEdges.right:SetPoint("BOTTOMRIGHT", frame.healthBarBorder, "BOTTOMRIGHT", 0, edgeSize)
        frame.healthBarBorderEdges.right:SetWidth(edgeSize)
    end

    for _, edge in pairs(frame.healthBarBorderEdges) do
        edge:SetColorTexture(borderR, borderG, borderB, borderA)
    end
    ApplyHealthBorderOutline(borderSize)
    frame.healthBarBorder:SetShown(borderSize > 0 and borderA > 0)

    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", contentInset, -contentInset)
    frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentInset, contentInset)
    frame.healthBar:SetStatusBarTexture(GetStatusBarTexturePath())
    frame.healthBar:SetMinMaxValues(0, 1)
    frame.healthBar:SetValue(1)
    frame.healthBarFG = frame.healthBar:GetStatusBarTexture()
    ApplyHealthFillDirection(frame)

    frame.dispelOverlay = CreateFrame("Frame", nil, frame.healthBar)
    frame.dispelOverlay:SetAllPoints(frame)
    frame.dispelOverlay:SetFrameLevel(frame.healthBar:GetFrameLevel() + 2)
    frame.dispelHighlight = frame.dispelOverlay:CreateTexture(nil, "OVERLAY")
    frame.dispelHighlight:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.dispelHighlight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.dispelHighlight:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\GradientH")
    frame.dispelHighlight:SetAlpha(1)
    frame.dispelHighlight:SetBlendMode("BLEND")
    frame.dispelHighlight:Hide()
end

local function CreateAbsorbBar(frame)
    local db = MattMinimalFramesDB or {}
    local r = ClampUnitInterval(db.absorbBarColorR, 0.62)
    local g = ClampUnitInterval(db.absorbBarColorG, 0.84)
    local b = ClampUnitInterval(db.absorbBarColorB, 1.0)
    local a = ClampUnitInterval(db.absorbBarColorA, 0.7)
    local useSolid = (db.useSolidAbsorbBar == true)

    frame.absorbBar = CreateFrame("StatusBar", nil, frame.healPredictionClip)
    if useSolid and MMF_GetStatusBarTexturePath then
        frame.absorbBar:SetStatusBarTexture(MMF_GetStatusBarTexturePath())
    else
        frame.absorbBar:SetStatusBarTexture("Interface\\AddOns\\MattMinimalFrames\\Textures\\shield.tga")
    end
    frame.absorbBar:SetStatusBarColor(r, g, b, a)
    frame.absorbBar:GetStatusBarTexture():SetVertexColor(r, g, b, a)

    local absorbTex = frame.absorbBar:GetStatusBarTexture()
    if absorbTex then
        absorbTex:SetHorizTile(not useSolid)
        absorbTex:SetVertTile(not useSolid)
        if useSolid then
            absorbTex:SetTexCoord(0, 1, 0, 1)
        else
            absorbTex:SetTexCoord(0, 8, 0, 1)
        end
    end

    frame.absorbBar:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
    ApplyHealthFillDirection(frame)
    frame.absorbBar:Hide()
end

local function CreateHealPredictionBar(frame)
    local Compat = _G.MMF_Compat

    frame.healPredictionClip = CreateFrame("Frame", nil, frame.healthBar)
    frame.healPredictionClip:SetAllPoints(frame.healthBar)
    frame.healPredictionClip:SetClipsChildren(true)
    frame.healPredictionClip:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)

    frame.myHealPrediction = CreateFrame("StatusBar", nil, frame.healPredictionClip)
    frame.myHealPrediction:SetStatusBarTexture(GetStatusBarTexturePath())
    frame.myHealPrediction:GetStatusBarTexture():SetVertexColor(0, 0.827, 0.765, 0.7)
    frame.myHealPrediction:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
    frame.myHealPrediction:Hide()

    frame.otherHealPrediction = CreateFrame("StatusBar", nil, frame.healPredictionClip)
    frame.otherHealPrediction:SetStatusBarTexture(GetStatusBarTexturePath())
    frame.otherHealPrediction:GetStatusBarTexture():SetVertexColor(0, 0.631, 0.557, 0.7)
    frame.otherHealPrediction:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
    frame.otherHealPrediction:Hide()

    -- Heal absorb bar.
    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.healPredictionClip)
    frame.healAbsorbBar:SetStatusBarTexture(GetStatusBarTexturePath())
    frame.healAbsorbBar:SetStatusBarColor(0.85, 0.15, 0.15, 0.65)
    do
        local healAbsorbTex = frame.healAbsorbBar:GetStatusBarTexture()
        if healAbsorbTex then
            healAbsorbTex:SetVertexColor(0.85, 0.15, 0.15, 0.65)
            healAbsorbTex:SetHorizTile(false)
            healAbsorbTex:SetVertTile(false)
            healAbsorbTex:SetTexCoord(0, 1, 0, 1)
        end
    end
    frame.healAbsorbBar:SetFrameLevel(frame.healthBar:GetFrameLevel() + 3)
    frame.healAbsorbBar:Hide()

    ApplyHealthFillDirection(frame)

    if Compat.IsRetail and CreateUnitHealPredictionCalculator then
        frame.healPredictionCalculator = CreateUnitHealPredictionCalculator()
    end
end

local function ApplyHealthFillDirections(getAllFramesFn)
    if type(getAllFramesFn) ~= "function" then
        return
    end
    for _, frame in ipairs(getAllFramesFn()) do
        ApplyHealthFillDirection(frame)
    end
end

_G.MMF_FrameFactoryHealthPower = {
    ApplyHealthFillDirection = ApplyHealthFillDirection,
    CreateHealthBar = CreateHealthBar,
    CreateAbsorbBar = CreateAbsorbBar,
    CreateHealPredictionBar = CreateHealPredictionBar,
    ApplyHealthFillDirections = ApplyHealthFillDirections,
}
