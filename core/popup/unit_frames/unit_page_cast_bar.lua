local function MMF_RefreshUnitPageCastBar(unit)
    if MMF_RequestUnitUpdate then
        MMF_RequestUnitUpdate(unit)
    elseif MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
    end
end

local function MMF_GetUnitPageCastBarOffset(unit)
    if MMF_GetCastBarOffsetForUnit then
        local x, y = MMF_GetCastBarOffsetForUnit(unit)
        if x ~= nil and y ~= nil then return tonumber(x) or 0, tonumber(y) or 0 end
    end
    local position = MattMinimalFramesDB and MattMinimalFramesDB.castBarPositions and MattMinimalFramesDB.castBarPositions[unit]
    if position then return tonumber(position.x) or 0, tonumber(position.y) or 0 end
    if MMF_GetCastBarDefaultOffsetForUnit then
        local x, y = MMF_GetCastBarDefaultOffsetForUnit(unit)
        return tonumber(x) or 0, tonumber(y) or 0
    end
    return 0, unit == "focus" and -19 or -9
end

local function MMF_SetUnitPageCastBarOffset(unit, x, y)
    if MMF_SetCastBarOffsetForUnit then
        MMF_SetCastBarOffsetForUnit(unit, x, y)
        return
    end
    MattMinimalFramesDB = MattMinimalFramesDB or {}
    MattMinimalFramesDB.castBarPositions = MattMinimalFramesDB.castBarPositions or {}
    MattMinimalFramesDB.castBarPositions[unit] = { x = tonumber(x) or 0, y = tonumber(y) or 0 }
    local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit)
    if frame and frame.castBarFrame and MMF_ApplyCastBarPosition then
        MMF_ApplyCastBarPosition(frame, unit)
    end
end

function MMF_BuildUnitFramesCastBarSection(ctx)
    local parent, unit = ctx.parent, ctx.unit
    if unit ~= "player" and unit ~= "target" and unit ~= "focus" and unit ~= "boss" then return end

    local CreateCheckbox = ctx.createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateSlider = ctx.createMinimalSlider or MMF_CreateMinimalSlider
    local x, rightX, width = 12, 382, 346
    MattMinimalFramesDB = MattMinimalFramesDB or {}
    local db, defaults = MattMinimalFramesDB, MattMinimalFrames_Defaults or {}
    local unitLabel = unit:sub(1, 1):upper() .. unit:sub(2)
    local castBarTitle = unit == "boss" and "BOSS CAST BARS & DEBUFFS" or string.upper(unitLabel .. " CAST BAR")
    local title = MMF_CreateUnitFramesSectionHeader and MMF_CreateUnitFramesSectionHeader(parent, castBarTitle, x, -12, "cast")
    if not title then
        title = parent:CreateFontString(nil, "OVERLAY")
        title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
        title:SetPoint("TOPLEFT", x, -12)
        if MMF_ApplyUnitFramesHeadingColor then
            MMF_ApplyUnitFramesHeadingColor(title, "cast")
        else
            title:SetTextColor(MMF_GetPopupSectionTitleColor())
        end
        title:SetText(castBarTitle)
    end

    if unit == "boss" then
        local function RefreshBossCastBars()
            for index = 1, 5 do
                local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit("boss" .. index)
                if frame and frame.castBarFrame then
                    if MMF_ApplyCastBarPosition then MMF_ApplyCastBarPosition(frame, frame.unit) end
                    if frame.mmfRefreshBossCastBar then frame.mmfRefreshBossCastBar() end
                    MMF_RefreshUnitPageCastBar(frame.unit)
                end
            end
        end
        CreateCheckbox(parent, "Enable Boss Cast Bars", x, -42, "showBossCastBar", true, RefreshBossCastBars)
        CreateCheckbox(parent, "Enable My Boss Debuffs", x, -70, "showBossDebuffs", true, function()
            if MMF_UpdateBossAuras then MMF_UpdateBossAuras() end
        end)
        CreateSlider(parent, "Debuff Icon Scale", x, -98, width, "bossDebuffIconScale", 0.75, 2.0, 0.05,
            defaults.bossDebuffIconScale or 1.0, function()
                if MMF_UpdateBossAuras then MMF_UpdateBossAuras() end
            end)
        CreateSlider(parent, "Cast Bar Width", rightX, -42, width, "bossCastBarWidth", 40, 400, 1,
            defaults.bossCastBarWidth or 98, RefreshBossCastBars, true)
        CreateSlider(parent, "Cast Bar Height", rightX, -70, width, "bossCastBarHeight", 4, 60, 1,
            defaults.bossCastBarHeight or 14, RefreshBossCastBars, true)
        return
    end

    local keyPrefix = unitLabel
    CreateCheckbox(parent, "Enable " .. keyPrefix .. " Cast Bar", x, -42, "show" .. keyPrefix .. "CastBar", true, function()
        if StaticPopup_Show then StaticPopup_Show("MMF_RELOADUI") end
    end)

    local syncing = false
    local xSlider, ySlider
    local function SyncOffsets()
        local offsetX, offsetY = MMF_GetUnitPageCastBarOffset(unit)
        syncing = true
        if xSlider and xSlider.slider then xSlider.slider:SetValue(offsetX) end
        if ySlider and ySlider.slider then ySlider.slider:SetValue(offsetY) end
        syncing = false
    end
    xSlider = CreateSlider(parent, "X Offset", x, -70, width, "__temp" .. keyPrefix .. "CastBarX", -300, 300, 1, 0, function(value)
        if syncing then return end
        local _, yValue = MMF_GetUnitPageCastBarOffset(unit)
        MMF_SetUnitPageCastBarOffset(unit, value, yValue)
    end, true)
    ySlider = CreateSlider(parent, "Y Offset", x, -98, width, "__temp" .. keyPrefix .. "CastBarY", -300, 300, 1, unit == "focus" and -19 or -9, function(value)
        if syncing then return end
        local xValue = MMF_GetUnitPageCastBarOffset(unit)
        MMF_SetUnitPageCastBarOffset(unit, xValue, value)
    end, true)

    local reset = CreateFrame("Button", nil, parent, "BackdropTemplate")
    reset:SetSize(width, 20)
    reset:SetPoint("TOPLEFT", x, -128)
    reset:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    reset:SetBackdropColor(0.06, 0.06, 0.08, 1)
    reset:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    local resetText = reset:CreateFontString(nil, "OVERLAY")
    resetText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    resetText:SetPoint("CENTER")
    resetText:SetText("RESET CAST BAR POSITION")
    resetText:SetTextColor(0.85, 0.85, 0.85)
    reset:SetScript("OnClick", function()
        if MMF_ResetCastBarOffsetForUnit then
            MMF_ResetCastBarOffsetForUnit(unit)
        elseif MattMinimalFramesDB.castBarPositions then
            MattMinimalFramesDB.castBarPositions[unit] = nil
        end
        SyncOffsets()
    end)

    local castPrefix = unit .. "CastBar"
    CreateSlider(parent, "Spell Name Size", rightX, -42, width, castPrefix .. "SpellNameTextSize", 8, 20, 1,
        db[castPrefix .. "SpellNameTextSize"] or defaults[castPrefix .. "SpellNameTextSize"] or 12,
        function() MMF_RefreshUnitPageCastBar(unit) end, true)
    CreateSlider(parent, "Cast Time Size", rightX, -70, width, castPrefix .. "CastTimeTextSize", 8, 20, 1,
        db[castPrefix .. "CastTimeTextSize"] or defaults[castPrefix .. "CastTimeTextSize"] or 9,
        function() MMF_RefreshUnitPageCastBar(unit) end, true)
    CreateSlider(parent, "Width Scale", rightX, -98, width, castPrefix .. "FrameScaleX", 0.1, 6.0, 0.05,
        db[castPrefix .. "FrameScaleX"] or defaults[castPrefix .. "FrameScaleX"] or 1.0,
        function() MMF_RefreshUnitPageCastBar(unit) end)
    CreateSlider(parent, "Height Scale", rightX, -126, width, castPrefix .. "FrameScaleY", 0.1, 10.0, 0.05,
        db[castPrefix .. "FrameScaleY"] or defaults[castPrefix .. "FrameScaleY"] or 1.0,
        function() MMF_RefreshUnitPageCastBar(unit) end)
    SyncOffsets()
    MattMinimalFramesDB["__temp" .. keyPrefix .. "CastBarX"] = nil
    MattMinimalFramesDB["__temp" .. keyPrefix .. "CastBarY"] = nil
end

function MMF_BuildUnitFramesSharedCastBarSection(ctx)
    local parent = ctx.parent
    local CreateCheckbox = ctx.createMinimalCheckbox or MMF_CreateMinimalCheckbox
    local CreateColorPicker = ctx.createMinimalColorPicker or MMF_CreateMinimalColorPicker
    local accent = ctx.accentColor or { 0.6, 0.4, 0.9 }
    MattMinimalFramesDB = MattMinimalFramesDB or {}
    local x, rightX, width = 12, 382, 346
    local title = MMF_CreateUnitFramesSectionHeader and MMF_CreateUnitFramesSectionHeader(parent, "SHARED CAST BAR", x, -12, "cast")
    if not title then
        title = parent:CreateFontString(nil, "OVERLAY")
        title:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", MMF_UNIT_FRAMES_SECTION_TITLE_SIZE or 16, "")
        title:SetPoint("TOPLEFT", x, -12)
        if MMF_ApplyUnitFramesHeadingColor then
            MMF_ApplyUnitFramesHeadingColor(title, "cast")
        else
            title:SetTextColor(MMF_GetPopupSectionTitleColor())
        end
        title:SetText("SHARED CAST BAR")
    end
    CreateCheckbox(parent, "Hide Blizzard Cast Bar", x, -42, "hideBlizzardPlayerCastBar", false, function()
        if MMF_UpdateBlizzardPlayerCastBarVisibility then MMF_UpdateBlizzardPlayerCastBarVisibility() end
        if StaticPopup_Show then StaticPopup_Show("MMF_RELOADUI") end
    end)
    if CreateColorPicker then
        CreateColorPicker(parent, {
            accentColor = accent, x = rightX, y = -42, width = width, height = 22, labelWidth = 92, buttonOffset = 96, buttonWidth = width - 96,
            label = "Cast Bar Color",
            getColor = function()
                local key = (MattMinimalFramesDB and MattMinimalFramesDB.castBarColor) or (MattMinimalFrames_Defaults and MattMinimalFrames_Defaults.castBarColor) or "yellow"
                if MMF_Config and MMF_Config.GetCastBarColor then
                    return MMF_Config.GetCastBarColor(key)
                end
                return 1, 0.82, 0
            end,
            onColorChanged = function(r, g, b)
                MattMinimalFramesDB.castBarColor = "custom"
                MattMinimalFramesDB.castBarCustomColorR, MattMinimalFramesDB.castBarCustomColorG, MattMinimalFramesDB.castBarCustomColorB = r, g, b
                if MMF_RequestAllFramesUpdate then MMF_RequestAllFramesUpdate() end
            end,
        })
    end
end
