function MMF_BuildUnitFramesVisibilitySection(ctx)
    local unitFramesCol = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox
    local dropdownLists = ctx.dropdownLists

    local LEFT_COL_X = ctx.leftColX
    local LEFT_COL_WIDTH = ctx.leftColWidth
    local LEFT_LABEL_WIDTH = ctx.leftLabelWidth
    local LEFT_BUTTON_OFFSET = ctx.leftButtonOffset
    local LEFT_BUTTON_WIDTH = ctx.leftButtonWidth

    local visibilityTitleY = -396
    local nameUnitDropdownY = -414
    local hideNameCheckboxY = -440
    local hpUnitDropdownY = -462
    local hideHPCheckboxY = -488
    local hideBossCheckboxY = -512

    local textVisibilityTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    textVisibilityTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    textVisibilityTitle:SetPoint("TOPLEFT", LEFT_COL_X, visibilityTitleY)
    textVisibilityTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    textVisibilityTitle:SetText("TEXT VISIBILITY")

    local textHideUnitOptions = {
        { value = "player", label = "Player" },
        { value = "target", label = "Target" },
        { value = "targettarget", label = "Target of Target" },
        { value = "pet", label = "Pet" },
        { value = "focus", label = "Focus" },
        { value = "boss", label = "Boss" },
    }

    MattMinimalFramesDB.textHideNameUnit = MattMinimalFramesDB.textHideNameUnit or "player"
    MattMinimalFramesDB.textHideHPUnit = MattMinimalFramesDB.textHideHPUnit or "player"

    local function GetUnitPrefix(unit)
        if unit == "targettarget" then return "tot" end
        if unit == "boss" then return "boss" end
        return unit
    end

    local function IsValidTextHideUnit(value)
        for _, opt in ipairs(textHideUnitOptions) do
            if opt.value == value then
                return true
            end
        end
        return false
    end

    local function EnsureValidTextHideUnits()
        if not IsValidTextHideUnit(MattMinimalFramesDB.textHideNameUnit) then
            MattMinimalFramesDB.textHideNameUnit = "player"
        end
        if not IsValidTextHideUnit(MattMinimalFramesDB.textHideHPUnit) then
            MattMinimalFramesDB.textHideHPUnit = "player"
        end
    end

    local function ApplyTextVisibilityForUnit(unit)
        if not unit then return end
        if unit == "boss" and MMF_UpdateUnitFrame and MMF_GetFrameForUnit then
            for i = 1, 5 do
                local frame = MMF_GetFrameForUnit("boss" .. i)
                if frame then
                    MMF_UpdateUnitFrame(frame)
                end
            end
            return
        end
        if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
            local frame = MMF_GetFrameForUnit(unit)
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end

    local function BuildTextHideUnitOptions()
        local out = {}
        for _, option in ipairs(textHideUnitOptions) do
            out[#out + 1] = { value = option.value, label = option.label }
        end
        return out
    end

    local hideNameTextCheckbox
    local hideHPTextCheckbox

    local function SetHideNameCheckboxFromDB()
        if not hideNameTextCheckbox then return end
        local prefix = GetUnitPrefix(MattMinimalFramesDB.textHideNameUnit)
        local key = prefix .. "HideNameText"
        hideNameTextCheckbox.checkbox:SetChecked(MattMinimalFramesDB[key] == true)
        hideNameTextCheckbox.checkbox.check:SetShown(hideNameTextCheckbox.checkbox:GetChecked())
    end

    local function SetHideHPCheckboxFromDB()
        if not hideHPTextCheckbox then return end
        local prefix = GetUnitPrefix(MattMinimalFramesDB.textHideHPUnit)
        local key = prefix .. "HideHPText"
        hideHPTextCheckbox.checkbox:SetChecked(MattMinimalFramesDB[key] == true)
        hideHPTextCheckbox.checkbox.check:SetShown(hideHPTextCheckbox.checkbox:GetChecked())
    end

    EnsureValidTextHideUnits()

    local hideNameUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = LEFT_COL_X,
        y = nameUnitDropdownY,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #textHideUnitOptions,
        label = "Name Unit",
        options = BuildTextHideUnitOptions(),
        getValue = function()
            return MattMinimalFramesDB.textHideNameUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textHideNameUnit = value
            SetHideNameCheckboxFromDB()
        end,
    })
    dropdownLists.hideNameTextUnitList = hideNameUnitDropdown.list

    hideNameTextCheckbox = CreateMinimalCheckbox(unitFramesCol, "Hide Name Text", LEFT_COL_X, hideNameCheckboxY, "__tempHideNameText", false, function(checked)
        local unit = MattMinimalFramesDB.textHideNameUnit
        local prefix = GetUnitPrefix(unit)
        MattMinimalFramesDB[prefix .. "HideNameText"] = checked and true or false
        MattMinimalFramesDB.__tempHideNameText = nil
        ApplyTextVisibilityForUnit(unit)
    end)
    MattMinimalFramesDB.__tempHideNameText = nil
    SetHideNameCheckboxFromDB()

    local hideHPUnitDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = LEFT_COL_X,
        y = hpUnitDropdownY,
        width = LEFT_COL_WIDTH,
        labelWidth = LEFT_LABEL_WIDTH,
        buttonOffset = LEFT_BUTTON_OFFSET,
        buttonWidth = LEFT_BUTTON_WIDTH,
        visibleRows = #textHideUnitOptions,
        label = "HP Unit",
        options = BuildTextHideUnitOptions(),
        getValue = function()
            return MattMinimalFramesDB.textHideHPUnit
        end,
        onSelect = function(value)
            MattMinimalFramesDB.textHideHPUnit = value
            SetHideHPCheckboxFromDB()
        end,
    })
    dropdownLists.hideHPTextUnitList = hideHPUnitDropdown.list

    hideHPTextCheckbox = CreateMinimalCheckbox(unitFramesCol, "Hide HP Text", LEFT_COL_X, hideHPCheckboxY, "__tempHideHPText", false, function(checked)
        local unit = MattMinimalFramesDB.textHideHPUnit
        local prefix = GetUnitPrefix(unit)
        MattMinimalFramesDB[prefix .. "HideHPText"] = checked and true or false
        MattMinimalFramesDB.__tempHideHPText = nil
        ApplyTextVisibilityForUnit(unit)
    end)
    MattMinimalFramesDB.__tempHideHPText = nil
    SetHideHPCheckboxFromDB()

    CreateMinimalCheckbox(unitFramesCol, "Hide Boss Frames", LEFT_COL_X, hideBossCheckboxY, "hideBossFrames", false, function()
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
    end)
end

