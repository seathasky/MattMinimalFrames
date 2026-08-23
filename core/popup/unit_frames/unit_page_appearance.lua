local function MMF_UnitPageAppearancePrefix(unit)
    if MMF_GetFrameStyleUnitPrefix then
        return MMF_GetFrameStyleUnitPrefix(unit)
    end
    return unit == "targettarget" and "tot" or unit
end

local function MMF_UnitPageClamp(value, fallback)
    local number = tonumber(value)
    if number == nil then number = fallback or 0 end
    return math.max(0, math.min(1, number))
end

function MMF_BuildUnitFramesAppearanceSection(ctx)
    local parent, unit = ctx.parent, ctx.unit
    local CreateSlider = ctx.createMinimalSlider or MMF_CreateMinimalSlider
    local prefix = MMF_UnitPageAppearancePrefix(unit)
    local db = MattMinimalFramesDB or {}
    MattMinimalFramesDB = db
    local unitLabels = { player = "PLAYER", target = "TARGET", targettarget = "TARGET OF TARGET", pet = "PET", focus = "FOCUS", boss = "BOSS" }
    local appearanceTitle = (unitLabels[unit] or string.upper(tostring(unit or "UNIT"))) .. " FRAME APPEARANCE"
    local title = MMF_CreateUnitFramesSectionHeader and MMF_CreateUnitFramesSectionHeader(parent, appearanceTitle, 12, -12, "appearance")
    if not title then
        title = parent:CreateFontString(nil, "OVERLAY")
        title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
        title:SetPoint("TOPLEFT", 12, -12)
        if MMF_ApplyUnitFramesHeadingColor then
            MMF_ApplyUnitFramesHeadingColor(title, "appearance")
        else
            title:SetTextColor(MMF_GetPopupSectionTitleColor())
        end
        title:SetText(appearanceTitle)
    end

    local function Key(suffix) return prefix .. suffix end
    local function Has(suffix) return db[Key(suffix)] ~= nil end
    local function Clear(suffix) db[Key(suffix)] = nil end
    local function Refresh()
        if MMF_RequestAllFramesUpdate then MMF_RequestAllFramesUpdate() end
    end
    local function RefreshBG()
        if MMF_ApplyHealthBarBackgroundColor then MMF_ApplyHealthBarBackgroundColor() else Refresh() end
    end
    local function RefreshBorder()
        if MMF_ApplyHealthBarBorderStyle then MMF_ApplyHealthBarBorderStyle() else Refresh() end
    end

    local frameAlpha = (MMF_GetFrameColorAlpha and MMF_GetFrameColorAlpha(unit)) or db[Key("FrameColorAlpha")] or db.frameColorAlpha or 1
    CreateSlider(parent, "Frame Alpha", 12, -70, 346, "__mmfUnitFrameAlpha", 0, 1, 0.05, frameAlpha, function(value)
        db[Key("FrameColorAlpha")] = value
        db.__mmfUnitFrameAlpha = nil
        Refresh()
    end, false, {
        onReset = function() Clear("FrameColorAlpha"); Refresh() end,
        isDefault = function() return not Has("FrameColorAlpha") end,
    })

    MMF_CreateMinimalColorPicker(parent, {
        accentColor = ctx.accentColor, x = 12, y = -98, width = 346, height = 16,
        labelWidth = 120, buttonOffset = 124, buttonWidth = 222, label = "Health Bar BG", resetLabel = "Reset",
        getColor = function()
            if MMF_GetHealthBarBGStyle then
                local r, g, b = MMF_GetHealthBarBGStyle(unit)
                return MMF_UnitPageClamp(r), MMF_UnitPageClamp(g), MMF_UnitPageClamp(b)
            end
            return MMF_UnitPageClamp(db[Key("HealthBarBGColorR")]), MMF_UnitPageClamp(db[Key("HealthBarBGColorG")]), MMF_UnitPageClamp(db[Key("HealthBarBGColorB")])
        end,
        onColorChanged = function(r, g, b)
            db[Key("HealthBarBGColorR")] = MMF_UnitPageClamp(r)
            db[Key("HealthBarBGColorG")] = MMF_UnitPageClamp(g)
            db[Key("HealthBarBGColorB")] = MMF_UnitPageClamp(b)
            RefreshBG()
        end,
        onReset = function() Clear("HealthBarBGColorR"); Clear("HealthBarBGColorG"); Clear("HealthBarBGColorB"); RefreshBG() end,
        isDefault = function() return not Has("HealthBarBGColorR") and not Has("HealthBarBGColorG") and not Has("HealthBarBGColorB") end,
    })
    local _, _, _, healthBGAlpha = MMF_GetHealthBarBGStyle and MMF_GetHealthBarBGStyle(unit)
    healthBGAlpha = healthBGAlpha or db[Key("HealthBarBGAlpha")] or db.healthBarBGAlpha or 0.65
    CreateSlider(parent, "Health BG Alpha", 12, -126, 346, "__mmfUnitHealthBGAlpha", 0, 1, 0.05, healthBGAlpha, function(value)
        db[Key("HealthBarBGAlpha")] = value
        db.__mmfUnitHealthBGAlpha = nil
        RefreshBG()
    end, false, {
        onReset = function() Clear("HealthBarBGAlpha"); RefreshBG() end,
        isDefault = function() return not Has("HealthBarBGAlpha") end,
    })

    MMF_CreateMinimalColorPicker(parent, {
        accentColor = ctx.accentColor, x = 382, y = -42, width = 346, height = 16,
        labelWidth = 110, buttonOffset = 114, buttonWidth = 232, label = "Frame Border", resetLabel = "Reset",
        getColor = function()
            if MMF_GetHealthBarBorderStyle then
                local r, g, b = MMF_GetHealthBarBorderStyle(unit)
                return MMF_UnitPageClamp(r), MMF_UnitPageClamp(g), MMF_UnitPageClamp(b)
            end
            return MMF_UnitPageClamp(db[Key("HealthBarBorderColorR")]), MMF_UnitPageClamp(db[Key("HealthBarBorderColorG")]), MMF_UnitPageClamp(db[Key("HealthBarBorderColorB")])
        end,
        onColorChanged = function(r, g, b)
            db[Key("HealthBarBorderColorR")] = MMF_UnitPageClamp(r)
            db[Key("HealthBarBorderColorG")] = MMF_UnitPageClamp(g)
            db[Key("HealthBarBorderColorB")] = MMF_UnitPageClamp(b)
            RefreshBorder()
        end,
        onReset = function() Clear("HealthBarBorderColorR"); Clear("HealthBarBorderColorG"); Clear("HealthBarBorderColorB"); RefreshBorder() end,
        isDefault = function() return not Has("HealthBarBorderColorR") and not Has("HealthBarBorderColorG") and not Has("HealthBarBorderColorB") end,
    })
    local _, _, _, borderAlpha, borderWidth = MMF_GetHealthBarBorderStyle and MMF_GetHealthBarBorderStyle(unit)
    borderWidth = borderWidth or db[Key("HealthBarBorderSize")] or db.healthBarBorderSize or 1
    CreateSlider(parent, "Border Width", 382, -70, 346, "__mmfUnitBorderWidth", 0, 3, 1, borderWidth, function(value)
        db[Key("HealthBarBorderSize")] = math.floor(value + 0.5)
        db.__mmfUnitBorderWidth = nil
        RefreshBorder()
    end, true, {
        onReset = function() Clear("HealthBarBorderSize"); RefreshBorder() end,
        isDefault = function() return not Has("HealthBarBorderSize") end,
    })
    borderAlpha = borderAlpha or db[Key("HealthBarBorderAlpha")] or db.healthBarBorderAlpha or 1
    CreateSlider(parent, "Border Alpha", 382, -98, 346, "__mmfUnitBorderAlpha", 0, 1, 0.05, borderAlpha, function(value)
        db[Key("HealthBarBorderAlpha")] = value
        db.__mmfUnitBorderAlpha = nil
        RefreshBorder()
    end, false, {
        onReset = function() Clear("HealthBarBorderAlpha"); RefreshBorder() end,
        isDefault = function() return not Has("HealthBarBorderAlpha") end,
    })

    if unit == "player" or unit == "target" or unit == "targettarget" or unit == "pet" or unit == "focus" then
        local colorKey = Key("BarColorMode")
        local customKey = Key("BarCustomColor")
        local defaultMode = unit == "player" and "class" or "default"
        MMF_CreateMinimalColorPicker(parent, {
        accentColor = ctx.accentColor, x = 12, y = -42, width = 346, height = 16,
            labelWidth = 120, buttonOffset = 124, buttonWidth = 222, label = "Frame Color", resetLabel = "Default",
            getColor = function()
                if db[colorKey] == "custom" then
                    return MMF_UnitPageClamp(db[customKey .. "R"], 0.8), MMF_UnitPageClamp(db[customKey .. "G"], 0.2), MMF_UnitPageClamp(db[customKey .. "B"], 0.2)
                end
                if MMF_GetUnitColor then
                    local r, g, b = MMF_GetUnitColor(unit)
                    return MMF_UnitPageClamp(r, 0.8), MMF_UnitPageClamp(g, 0.2), MMF_UnitPageClamp(b, 0.2)
                end
                return 0.8, 0.2, 0.2
            end,
            onColorChanged = function(r, g, b)
                db[customKey .. "R"] = MMF_UnitPageClamp(r)
                db[customKey .. "G"] = MMF_UnitPageClamp(g)
                db[customKey .. "B"] = MMF_UnitPageClamp(b)
                db[colorKey] = "custom"
                Refresh()
            end,
            onReset = function() db[colorKey] = defaultMode; Refresh() end,
            isDefault = function() return (db[colorKey] or defaultMode) == defaultMode end,
        })
    end

    -- These are display-only slider keys; the real values above remain in the
    -- established per-unit style keys.
    db.__mmfUnitFrameAlpha = nil
    db.__mmfUnitHealthBGAlpha = nil
    db.__mmfUnitBorderWidth = nil
    db.__mmfUnitBorderAlpha = nil
end
