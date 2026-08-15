function MMF_EnsurePopupEditModePopup(config)
    config = config or {}

    local existingPopup = config.existingPopup
    local popup = config.popup
    local ACCENT_COLOR = config.accentColor or { 0.6, 0.4, 0.9 }
    local OnExitEditMode = config.onExitEditMode or function() end

    if existingPopup then
        return existingPopup
    end

    local editModePopup = CreateFrame("Frame", "MMF_EditModePopup", UIParent, "BackdropTemplate")
    editModePopup:SetSize(380, 200)
    editModePopup:SetPoint("TOP", UIParent, "TOP", 0, -120)
    editModePopup:SetFrameStrata("DIALOG")
    editModePopup:SetToplevel(true)
    editModePopup:SetMovable(true)
    editModePopup:EnableMouse(true)
    editModePopup:RegisterForDrag("LeftButton")
    editModePopup:SetScript("OnDragStart", editModePopup.StartMoving)
    editModePopup:SetScript("OnDragStop", editModePopup.StopMovingOrSizing)
    editModePopup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editModePopup:SetBackdropColor(0.04, 0.04, 0.05, 0.98)
    editModePopup:SetBackdropBorderColor(0.1, 0.1, 0.12, 1)

    local modeTitleBar = CreateFrame("Frame", nil, editModePopup)
    modeTitleBar:SetPoint("TOPLEFT", 0, 0)
    modeTitleBar:SetPoint("TOPRIGHT", 0, 0)
    modeTitleBar:SetHeight(28)

    local modeTitleBg = modeTitleBar:CreateTexture(nil, "BACKGROUND")
    modeTitleBg:SetAllPoints()
    modeTitleBg:SetColorTexture(0.07, 0.09, 0.11, 1)

    local modeTitleGlow = modeTitleBar:CreateTexture(nil, "ARTWORK")
    modeTitleGlow:SetPoint("BOTTOMLEFT", 0, 0)
    modeTitleGlow:SetPoint("BOTTOMRIGHT", 0, 0)
    modeTitleGlow:SetHeight(2)
    modeTitleGlow:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.95)

    local modeTitle = modeTitleBar:CreateFontString(nil, "OVERLAY")
    modeTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    modeTitle:SetPoint("LEFT", 12, 1)
    modeTitle:SetTextColor(1, 1, 1)
    modeTitle:SetText("Matt's Minimal Frames Edit Mode")

    local modeHelp = editModePopup:CreateFontString(nil, "OVERLAY")
    modeHelp:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 11, "")
    modeHelp:SetPoint("TOP", editModePopup, "TOP", 0, -54)
    modeHelp:SetTextColor(0.85, 0.85, 0.85)
    modeHelp:SetText("Drag frames normally. Click below to exit Edit Mode.")

    local controlLeft = 80
    local controlWidth = 220

    local openGuiContainer = CreateFrame("Frame", nil, editModePopup)
    openGuiContainer:SetSize(controlWidth, 20)
    openGuiContainer:SetPoint("TOPLEFT", editModePopup, "TOPLEFT", controlLeft, -78)

    local openGuiCheckbox = CreateFrame("CheckButton", nil, openGuiContainer)
    openGuiCheckbox:SetSize(14, 14)
    openGuiCheckbox:SetPoint("LEFT", 0, 0)

    local openGuiBg = openGuiCheckbox:CreateTexture(nil, "BACKGROUND")
    openGuiBg:SetAllPoints()
    openGuiBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local openGuiBorder = openGuiCheckbox:CreateTexture(nil, "BORDER")
    openGuiBorder:SetPoint("TOPLEFT", -1, 1)
    openGuiBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    openGuiBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local openGuiCheck = openGuiCheckbox:CreateTexture(nil, "ARTWORK")
    openGuiCheck:SetSize(8, 8)
    openGuiCheck:SetPoint("CENTER")
    openGuiCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    openGuiCheckbox.check = openGuiCheck

    local openGuiLabel = openGuiContainer:CreateFontString(nil, "OVERLAY")
    openGuiLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    openGuiLabel:SetPoint("LEFT", openGuiCheckbox, "RIGHT", 6, 0)
    openGuiLabel:SetTextColor(0.9, 0.9, 0.9)
    openGuiLabel:SetText("Open Settings GUI")

    local gridContainer = CreateFrame("Frame", nil, editModePopup)
    gridContainer:SetSize(controlWidth, 20)
    gridContainer:SetPoint("TOPLEFT", openGuiContainer, "BOTTOMLEFT", 0, -8)

    local gridCheckbox = CreateFrame("CheckButton", nil, gridContainer)
    gridCheckbox:SetSize(14, 14)
    gridCheckbox:SetPoint("LEFT", 0, 0)

    local gridBg = gridCheckbox:CreateTexture(nil, "BACKGROUND")
    gridBg:SetAllPoints()
    gridBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local gridBorder = gridCheckbox:CreateTexture(nil, "BORDER")
    gridBorder:SetPoint("TOPLEFT", -1, 1)
    gridBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    gridBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local gridCheck = gridCheckbox:CreateTexture(nil, "ARTWORK")
    gridCheck:SetSize(8, 8)
    gridCheck:SetPoint("CENTER")
    gridCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    gridCheckbox.check = gridCheck

    local gridLabel = gridContainer:CreateFontString(nil, "OVERLAY")
    gridLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    gridLabel:SetPoint("LEFT", gridCheckbox, "RIGHT", 6, 0)
    gridLabel:SetTextColor(0.9, 0.9, 0.9)
    gridLabel:SetText("Alignment Grid")

    local textDragContainer = CreateFrame("Frame", nil, editModePopup)
    textDragContainer:SetSize(controlWidth, 20)
    textDragContainer:SetPoint("TOPLEFT", gridContainer, "BOTTOMLEFT", 0, -8)

    local textDragCheckbox = CreateFrame("CheckButton", nil, textDragContainer)
    textDragCheckbox:SetSize(14, 14)
    textDragCheckbox:SetPoint("LEFT", 0, 0)

    local textDragBg = textDragCheckbox:CreateTexture(nil, "BACKGROUND")
    textDragBg:SetAllPoints()
    textDragBg:SetColorTexture(0.08, 0.08, 0.1, 1)

    local textDragBorder = textDragCheckbox:CreateTexture(nil, "BORDER")
    textDragBorder:SetPoint("TOPLEFT", -1, 1)
    textDragBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    textDragBorder:SetColorTexture(0.25, 0.25, 0.3, 1)

    local textDragCheck = textDragCheckbox:CreateTexture(nil, "ARTWORK")
    textDragCheck:SetSize(8, 8)
    textDragCheck:SetPoint("CENTER")
    textDragCheck:SetColorTexture(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 1)
    textDragCheckbox.check = textDragCheck

    local textDragLabel = textDragContainer:CreateFontString(nil, "OVERLAY")
    textDragLabel:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    textDragLabel:SetPoint("LEFT", textDragCheckbox, "RIGHT", 6, 0)
    textDragLabel:SetTextColor(0.9, 0.9, 0.9)
    textDragLabel:SetText("Move Text Mode")

    local textDragStatus = textDragContainer:CreateFontString(nil, "OVERLAY")
    textDragStatus:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    textDragStatus:SetPoint("LEFT", textDragLabel, "RIGHT", 8, 0)
    textDragStatus:SetTextColor(0.25, 0.9, 0.35)
    textDragStatus:SetText("Text Movable")
    textDragStatus:Hide()

    local textMoveBanner = CreateFrame("Frame", nil, editModePopup, "BackdropTemplate")
    textMoveBanner:SetPoint("TOPLEFT", editModePopup, "BOTTOMLEFT", 0, -2)
    textMoveBanner:SetPoint("TOPRIGHT", editModePopup, "BOTTOMRIGHT", 0, -2)
    textMoveBanner:SetHeight(38)
    textMoveBanner:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    textMoveBanner:SetBackdropColor(0.10, 0.08, 0.03, 0.98)
    textMoveBanner:SetBackdropBorderColor(0.70, 0.54, 0.16, 0.9)
    textMoveBanner:EnableMouse(false)

    local textMoveBannerTitle = textMoveBanner:CreateFontString(nil, "OVERLAY")
    textMoveBannerTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    textMoveBannerTitle:SetPoint("TOPLEFT", 12, -7)
    textMoveBannerTitle:SetTextColor(1.0, 0.80, 0.30)
    textMoveBannerTitle:SetText("MOVE TEXT MODE")

    local textMoveBannerDescription = textMoveBanner:CreateFontString(nil, "OVERLAY")
    textMoveBannerDescription:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 8, "")
    textMoveBannerDescription:SetPoint("TOPLEFT", textMoveBannerTitle, "BOTTOMLEFT", 0, -2)
    textMoveBannerDescription:SetTextColor(0.82, 0.80, 0.70)
    textMoveBannerDescription:SetText("Text is movable. Frame movement is disabled.")
    textMoveBanner:Hide()
    
    local textPositionList = CreateFrame("Frame", nil, editModePopup)
    textPositionList:SetWidth(controlWidth)
    textPositionList:SetPoint("TOPLEFT", textDragContainer, "BOTTOMLEFT", 0, -8)
    
    local textPositionTitle = textPositionList:CreateFontString(nil, "OVERLAY")
    textPositionTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    textPositionTitle:SetPoint("TOPLEFT", 0, 0)
    textPositionTitle:SetTextColor(0.55, 0.57, 0.62)
    textPositionTitle:SetText("MODIFIED TEXT")
    
    local textPositionEmpty = textPositionList:CreateFontString(nil, "OVERLAY")
    textPositionEmpty:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
    textPositionEmpty:SetPoint("TOPLEFT", textPositionTitle, "BOTTOMLEFT", 0, -4)
    textPositionEmpty:SetTextColor(0.55, 0.57, 0.62)
    textPositionEmpty:SetText("No modified text.")
    
    local textPositionRows = {}

    local function SetGridChecked(checked)
        gridCheckbox:SetChecked(checked == true)
        if gridCheckbox.check then
            gridCheckbox.check:SetShown(checked == true)
        end
    end

    local function SetOpenGuiChecked(checked)
        openGuiCheckbox:SetChecked(checked == true)
        if openGuiCheckbox.check then
            openGuiCheckbox.check:SetShown(checked == true)
        end
    end

    local function SetTextDragChecked(checked)
        textDragCheckbox:SetChecked(checked == true)
        if textDragCheckbox.check then
            textDragCheckbox.check:SetShown(checked == true)
        end
        textDragStatus:SetShown(checked == true)
        textMoveBanner:SetShown(checked == true)
    end

    local RefreshTextPositionList

    openGuiCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == true
        SetOpenGuiChecked(checked)
        if checked then
            popup:Show()
        else
            popup:Hide()
        end
    end)

    gridCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == true
        SetGridChecked(checked)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        MattMinimalFramesDB.showAlignmentGrid = checked
        if MMF_ToggleAlignmentGrid then
            MMF_ToggleAlignmentGrid(checked)
        end
    end)

    textDragCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == true
        SetTextDragChecked(checked)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        MattMinimalFramesDB.enableTextDragInEditMode = checked
        if MMF_RefreshFrameLockState then
            MMF_RefreshFrameLockState()
        end
        RefreshTextPositionList()
    end)

    local exitButton = CreateFrame("Button", nil, editModePopup, "BackdropTemplate")
    exitButton:SetSize(controlWidth, 24)
    exitButton:SetPoint("TOPLEFT", textDragContainer, "BOTTOMLEFT", 0, -12)
    exitButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    exitButton:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
    exitButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
    
    local function HasCustomTextPosition(position)
        return type(position) == "table"
            and type(position.x) == "number"
            and type(position.y) == "number"
    end
    
    local function GetMovedTextEntries()
        local db = MattMinimalFramesDB or {}
        local entries = {}
        local textEntries = {
            { label = "Player Name Text", store = "nameTextPositions", unit = "player", apply = MMF_ApplyNameTextPositions },
            { label = "Target Name Text", store = "nameTextPositions", unit = "target", apply = MMF_ApplyNameTextPositions },
            { label = "ToT Name Text", store = "nameTextPositions", unit = "targettarget", apply = MMF_ApplyNameTextPositions },
            { label = "Pet Name Text", store = "nameTextPositions", unit = "pet", apply = MMF_ApplyNameTextPositions },
            { label = "Focus Name Text", store = "nameTextPositions", unit = "focus", apply = MMF_ApplyNameTextPositions },
            { label = "Boss 1 Name Text", store = "nameTextPositions", unit = "boss1", apply = MMF_ApplyNameTextPositions },
            { label = "Boss 2 Name Text", store = "nameTextPositions", unit = "boss2", apply = MMF_ApplyNameTextPositions },
            { label = "Boss 3 Name Text", store = "nameTextPositions", unit = "boss3", apply = MMF_ApplyNameTextPositions },
            { label = "Boss 4 Name Text", store = "nameTextPositions", unit = "boss4", apply = MMF_ApplyNameTextPositions },
            { label = "Boss 5 Name Text", store = "nameTextPositions", unit = "boss5", apply = MMF_ApplyNameTextPositions },
            { label = "Player HP Text", store = "hpTextPositions", unit = "player", apply = MMF_ApplyHPTextPositions },
            { label = "Target HP Text", store = "hpTextPositions", unit = "target", apply = MMF_ApplyHPTextPositions },
            { label = "ToT HP Text", store = "hpTextPositions", unit = "targettarget", apply = MMF_ApplyHPTextPositions },
            { label = "Pet HP Text", store = "hpTextPositions", unit = "pet", apply = MMF_ApplyHPTextPositions },
            { label = "Focus HP Text", store = "hpTextPositions", unit = "focus", apply = MMF_ApplyHPTextPositions },
            { label = "Boss 1 HP Text", store = "hpTextPositions", unit = "boss1", apply = MMF_ApplyHPTextPositions },
            { label = "Boss 2 HP Text", store = "hpTextPositions", unit = "boss2", apply = MMF_ApplyHPTextPositions },
            { label = "Boss 3 HP Text", store = "hpTextPositions", unit = "boss3", apply = MMF_ApplyHPTextPositions },
            { label = "Boss 4 HP Text", store = "hpTextPositions", unit = "boss4", apply = MMF_ApplyHPTextPositions },
            { label = "Boss 5 HP Text", store = "hpTextPositions", unit = "boss5", apply = MMF_ApplyHPTextPositions },
            { label = "Player Power Text", store = "powerTextPositions", unit = "player", apply = MMF_ApplyPowerTextPositions },
            { label = "Target Power Text", store = "powerTextPositions", unit = "target", apply = MMF_ApplyPowerTextPositions },
            { label = "ToT Power Text", store = "powerTextPositions", unit = "targettarget", apply = MMF_ApplyPowerTextPositions },
            { label = "Pet Power Text", store = "powerTextPositions", unit = "pet", apply = MMF_ApplyPowerTextPositions },
            { label = "Focus Power Text", store = "powerTextPositions", unit = "focus", apply = MMF_ApplyPowerTextPositions },
            { label = "Boss 1 Power Text", store = "powerTextPositions", unit = "boss1", apply = MMF_ApplyPowerTextPositions },
            { label = "Boss 2 Power Text", store = "powerTextPositions", unit = "boss2", apply = MMF_ApplyPowerTextPositions },
            { label = "Boss 3 Power Text", store = "powerTextPositions", unit = "boss3", apply = MMF_ApplyPowerTextPositions },
            { label = "Boss 4 Power Text", store = "powerTextPositions", unit = "boss4", apply = MMF_ApplyPowerTextPositions },
            { label = "Boss 5 Power Text", store = "powerTextPositions", unit = "boss5", apply = MMF_ApplyPowerTextPositions },
            { label = "Player Cast Spell Text", store = "castBarTextPositions", unit = "player", key = "spell", apply = MMF_ApplyCastBarTextPositions },
            { label = "Player Cast Time Text", store = "castBarTextPositions", unit = "player", key = "time", apply = MMF_ApplyCastBarTextPositions },
            { label = "Target Cast Spell Text", store = "castBarTextPositions", unit = "target", key = "spell", apply = MMF_ApplyCastBarTextPositions },
            { label = "Target Cast Time Text", store = "castBarTextPositions", unit = "target", key = "time", apply = MMF_ApplyCastBarTextPositions },
            { label = "Focus Cast Spell Text", store = "castBarTextPositions", unit = "focus", key = "spell", apply = MMF_ApplyCastBarTextPositions },
            { label = "Focus Cast Time Text", store = "castBarTextPositions", unit = "focus", key = "time", apply = MMF_ApplyCastBarTextPositions },
        }
    
        for _, entry in ipairs(textEntries) do
            local positions = db[entry.store]
            local position = positions and positions[entry.unit]
            if entry.key then
                position = position and position[entry.key]
            end
            if HasCustomTextPosition(position) then
                table.insert(entries, entry)
            end
        end
        return entries
    end
    
    local function ResetTextPosition(entry)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        local positions = MattMinimalFramesDB[entry.store]
        if positions then
            if entry.key and positions[entry.unit] then
                positions[entry.unit][entry.key] = nil
                if not next(positions[entry.unit]) then
                    positions[entry.unit] = nil
                end
            else
                positions[entry.unit] = nil
            end
        end
        local anchorType = entry.store == "nameTextPositions" and "NameText"
            or entry.store == "hpTextPositions" and "HPText"
            or entry.store == "powerTextPositions" and "PowerText"
        if anchorType then
            local prefix = (MMF_GetTextFormatUnitPrefix and MMF_GetTextFormatUnitPrefix(entry.unit)) or entry.unit
            MattMinimalFramesDB[prefix .. anchorType .. "AnchorEnabled"] = nil
            MattMinimalFramesDB[prefix .. anchorType .. "AnchorPoint"] = nil
        end
        if entry.apply then
            entry.apply()
        end
        RefreshTextPositionList()
    end
    
    local function GetTextPositionRow(index)
        if textPositionRows[index] then
            return textPositionRows[index]
        end
    
        local row = CreateFrame("Frame", nil, textPositionList)
        row:SetSize(controlWidth, 20)
        row.label = row:CreateFontString(nil, "OVERLAY")
        row.label:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetTextColor(0.9, 0.9, 0.9)
    
        row.resetButton = CreateFrame("Button", nil, row, "BackdropTemplate")
        row.resetButton:SetSize(100, 18)
        row.resetButton:SetPoint("RIGHT", 0, 0)
        row.resetButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        row.resetButton:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
        row.resetButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        row.label:SetPoint("RIGHT", row.resetButton, "LEFT", -8, 0)
        row.label:SetWordWrap(false)
    
        local buttonText = row.resetButton:CreateFontString(nil, "OVERLAY")
        buttonText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 8, "")
        buttonText:SetPoint("CENTER")
        buttonText:SetTextColor(0.9, 0.9, 0.9)
        buttonText:SetText("Default Position")
        row.resetButton:SetScript("OnEnter", function()
            row.resetButton:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
        end)
        row.resetButton:SetScript("OnLeave", function()
            row.resetButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        end)
        row.resetButton:SetScript("OnClick", function()
            ResetTextPosition(row.entry)
        end)
    
        textPositionRows[index] = row
        return row
    end
    
    RefreshTextPositionList = function()
        local showList = MattMinimalFramesDB and MattMinimalFramesDB.enableTextDragInEditMode == true
        if not showList then
            textPositionList:Hide()
            exitButton:ClearAllPoints()
            exitButton:SetPoint("TOPLEFT", textDragContainer, "BOTTOMLEFT", 0, -12)
            editModePopup:SetHeight(200)
            return
        end
    
        local entries = GetMovedTextEntries()
        textPositionList:Show()
        textPositionEmpty:SetShown(#entries == 0)
        for index, row in ipairs(textPositionRows) do
            row:SetShown(index <= #entries)
        end
        for index, entry in ipairs(entries) do
            local row = GetTextPositionRow(index)
            row.entry = entry
            row.label:SetText(entry.label)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", textPositionTitle, "BOTTOMLEFT", 0, -4 - ((index - 1) * 22))
            row:Show()
        end
    
        local listHeight = #entries == 0 and 36 or (18 + (#entries * 22))
        textPositionList:SetHeight(listHeight)
        exitButton:ClearAllPoints()
        exitButton:SetPoint("TOPLEFT", textPositionList, "BOTTOMLEFT", 0, -4)
        editModePopup:SetHeight(200 + listHeight)
    end
    
    _G.MMF_RefreshEditModeTextPositionList = RefreshTextPositionList

    local exitText = exitButton:CreateFontString(nil, "OVERLAY")
    exitText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    exitText:SetPoint("CENTER")
    exitText:SetTextColor(0.9, 0.9, 0.9)
    exitText:SetText("Exit Edit Mode")

    exitButton:SetScript("OnEnter", function()
        exitButton:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.8)
    end)
    exitButton:SetScript("OnLeave", function()
        exitButton:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
    end)
    exitButton:SetScript("OnClick", function()
        if MMF_SetEditMode then
            MMF_SetEditMode(false)
        else
            MattMinimalFramesDB.unlockFramesEditMode = false
            MattMinimalFramesDB.enableTextDragInEditMode = false
            if MMF_RefreshFrameLockState then
                MMF_RefreshFrameLockState()
            end
            RefreshTextPositionList()
        end
        OnExitEditMode()
        editModePopup:Hide()
        popup:Show()
    end)

    editModePopup:SetScript("OnShow", function(self)
        local scale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB and MattMinimalFramesDB.guiScale)) or 1.0
        self:SetScale(scale)
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        if MattMinimalFramesDB.showAlignmentGrid ~= true then
            MattMinimalFramesDB.showAlignmentGrid = true
            if MMF_ToggleAlignmentGrid then
                MMF_ToggleAlignmentGrid(true)
            end
        end
        MattMinimalFramesDB.enableTextDragInEditMode = false
        if MMF_RefreshFrameLockState then
            MMF_RefreshFrameLockState()
        end
        SetOpenGuiChecked(false)
        popup:Hide()
        SetGridChecked(MattMinimalFramesDB.showAlignmentGrid == true)
        SetTextDragChecked(false)
        RefreshTextPositionList()
    end)

    editModePopup:Hide()
    return editModePopup
end
