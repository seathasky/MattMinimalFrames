function MMF_BuildUnitFramesIconsSection(ctx)
    local unitFramesCol = ctx.parent
    local popup = ctx.popup
    local ACCENT_COLOR = ctx.accentColor
    local dropdownLists = ctx.dropdownLists
    local rightSection = ctx.rightSection
    local NormalizeSelectionValue = ctx.normalizeSelectionValue
    local GetCurrentPlayerIconModeValue = ctx.getCurrentPlayerIconModeValue
    local GetCurrentTargetIconModeValue = ctx.getCurrentTargetIconModeValue

    local RIGHT_COL_X = ctx.rightColX
    local RIGHT_COL_WIDTH = ctx.rightColWidth
    local RIGHT_LABEL_WIDTH = ctx.rightLabelWidth
    local RIGHT_BUTTON_OFFSET = ctx.rightButtonOffset
    local RIGHT_BUTTON_WIDTH = ctx.rightButtonWidth
    local RIGHT_STACK_Y_OFFSET = ctx.rightStackYOffset
    local RIGHT_FRAME_OPTIONS_Y_SHIFT = ctx.rightFrameOptionsYShift
    local ICON_RESET_BUTTON_WIDTH = ctx.iconResetButtonWidth
    local ICON_RESET_BUTTON_GAP = ctx.iconResetButtonGap

    rightSection.styleDivider = unitFramesCol:CreateTexture(nil, "ARTWORK")
    rightSection.styleDivider:SetSize(RIGHT_COL_WIDTH, 1)
    rightSection.styleDivider:SetPoint("TOPLEFT", RIGHT_COL_X, (-430 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET)
    rightSection.styleDivider:SetColorTexture(0.42, 0.42, 0.46, 1)

    rightSection.frameOptionsTitle = unitFramesCol:CreateFontString(nil, "OVERLAY")
    rightSection.frameOptionsTitle:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 12, "")
    rightSection.frameOptionsTitle:SetPoint("TOPLEFT", RIGHT_COL_X, (-442 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET)
    rightSection.frameOptionsTitle:SetTextColor(MMF_GetPopupSectionTitleColor())
    rightSection.frameOptionsTitle:SetText("FRAME OPTIONS")

    local function BuildJiberishStyleValue(styleKey)
        return string.format("jiberishstyle:%s", tostring(styleKey or ""))
    end
    local JIBERISH_DOWNLOAD_VALUE = "__mmf_jiberish_download__"
    local JIBERISH_DOWNLOAD_URL = "https://www.curseforge.com/wow/addons/jiberish-fabled-icons"

    local function ParseJiberishStyleValue(value)
        if type(value) ~= "string" then
            return nil
        end
        local styleKey = value:match("^jiberishstyle:(.+)$")
        if not styleKey then
            return nil
        end
        return styleKey
    end

    local function BuildIconModeOptions(textOnlyStyles)
        local options = {
            { value = "off", label = "|cff33ff66Off (MMF)|r" },
            { value = "class", label = "|cff33ff66Class Icon (MMF)|r" },
            { value = "portrait", label = "|cff33ff66Portrait (MMF)|r" },
        }

        local styleOptions = MMF_GetIconTextureOptions and MMF_GetIconTextureOptions() or {}
        if #styleOptions > 0 then
            options[#options + 1] = { divider = true, label = "------------------------------" }
            for _, entry in ipairs(styleOptions) do
                if entry and entry.key and entry.mediaType and entry.path then
                    local labelText = tostring(entry.label or entry.key)
                    if not textOnlyStyles then
                        local iconTag = nil
                        if entry.texString then
                            iconTag = string.format("|T%s:14:14:0:0:1024:1024:%s|t ", tostring(entry.path), tostring(entry.texString))
                        else
                            iconTag = string.format("|T%s:14:14:0:0|t ", tostring(entry.path))
                        end
                        labelText = iconTag .. labelText
                    end
                    options[#options + 1] = {
                        value = BuildJiberishStyleValue(entry.key),
                        label = labelText,
                    }
                end
            end
        else
            options[#options + 1] = { divider = true, label = "------------------------------" }
            options[#options + 1] = {
                value = JIBERISH_DOWNLOAD_VALUE,
                label = "|cffff3333Download Jiberish Icons|r",
            }
        end

        return options
    end

    local function GetCurrentPlayerIconDropdownValue()
        local mode = GetCurrentPlayerIconModeValue()
        if mode == "sharedmedia" or mode == "jiberish" then
            local styleKey = (MattMinimalFramesDB and NormalizeSelectionValue(MattMinimalFramesDB.playerFrameIconStyle, nil))
                or (MattMinimalFramesDB and NormalizeSelectionValue(MattMinimalFramesDB.playerFrameIconMediaKey, nil))
            if styleKey then
                return BuildJiberishStyleValue(styleKey)
            end
            return "off"
        end
        return mode
    end

    local function GetCurrentTargetIconDropdownValue()
        local mode = GetCurrentTargetIconModeValue()
        if mode == "sharedmedia" or mode == "jiberish" then
            local styleKey = (MattMinimalFramesDB and NormalizeSelectionValue(MattMinimalFramesDB.targetFrameIconStyle, nil))
                or (MattMinimalFramesDB and NormalizeSelectionValue(MattMinimalFramesDB.targetFrameIconMediaKey, nil))
            if styleKey then
                return BuildJiberishStyleValue(styleKey)
            end
            return "off"
        end
        return mode
    end

    rightSection.playerIconModeDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = (-458 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET,
        width = RIGHT_COL_WIDTH,
        labelWidth = RIGHT_LABEL_WIDTH,
        buttonOffset = RIGHT_BUTTON_OFFSET,
        buttonWidth = RIGHT_BUTTON_WIDTH,
        visibleRows = 10,
        preserveTextFormatting = true,
        label = "Player Icon",
        options = BuildIconModeOptions(false),
        getValue = function()
            return GetCurrentPlayerIconDropdownValue()
        end,
        optionsProvider = function()
            return BuildIconModeOptions(false)
        end,
        onSelect = function(value, _, dropdown)
            if value == JIBERISH_DOWNLOAD_VALUE then
                if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
                    local msg = "|cffff3333[MMF]|r Jiberish Icons not found. Download: " .. JIBERISH_DOWNLOAD_URL
                    DEFAULT_CHAT_FRAME:AddMessage(msg)
                end
                if dropdown and dropdown.SetSelectedValue then
                    dropdown.SetSelectedValue(GetCurrentPlayerIconDropdownValue())
                end
                return
            end
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            local styleKey = ParseJiberishStyleValue(value)
            if styleKey then
                MattMinimalFramesDB.playerFrameIconMode = "jiberish"
                MattMinimalFramesDB.playerFrameIconStyle = styleKey
                MattMinimalFramesDB.showPlayerClassIcon = false
            else
                MattMinimalFramesDB.playerFrameIconMode = value
                MattMinimalFramesDB.showPlayerClassIcon = (value == "class")
                if value ~= "sharedmedia" and value ~= "jiberish" then
                    MattMinimalFramesDB.playerFrameIconStyle = nil
                    MattMinimalFramesDB.playerFrameIconMediaType = nil
                    MattMinimalFramesDB.playerFrameIconMediaKey = nil
                end
            end
            if MMF_UpdatePlayerClassIconVisibility then
                MMF_UpdatePlayerClassIconVisibility(MattMinimalFramesDB.playerFrameIconMode)
            end
            if ctx.setUpdatePlayerIconModeButtonText then
                ctx.setUpdatePlayerIconModeButtonText(function()
                    rightSection.playerIconModeDropdown.SetSelectedValue(GetCurrentPlayerIconDropdownValue())
                end)
            end
        end,
    })
    dropdownLists.playerIconModeList = rightSection.playerIconModeDropdown.list
    if ctx.setUpdatePlayerIconModeButtonText then
        ctx.setUpdatePlayerIconModeButtonText(function()
            rightSection.playerIconModeDropdown.SetSelectedValue(GetCurrentPlayerIconDropdownValue())
        end)
    end
    rightSection.playerIconModeDropdown.SetSelectedValue(GetCurrentPlayerIconDropdownValue())

    rightSection.targetIconModeDropdown = MMF_CreateMinimalDropdown(unitFramesCol, popup, {
        accentColor = ACCENT_COLOR,
        x = RIGHT_COL_X,
        y = (-482 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET,
        width = RIGHT_COL_WIDTH,
        labelWidth = RIGHT_LABEL_WIDTH,
        buttonOffset = RIGHT_BUTTON_OFFSET,
        buttonWidth = RIGHT_BUTTON_WIDTH,
        visibleRows = 10,
        preserveTextFormatting = true,
        label = "Target Icon",
        options = BuildIconModeOptions(true),
        getValue = function()
            return GetCurrentTargetIconDropdownValue()
        end,
        optionsProvider = function()
            return BuildIconModeOptions(true)
        end,
        onSelect = function(value, _, dropdown)
            if value == JIBERISH_DOWNLOAD_VALUE then
                if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
                    local msg = "|cffff3333[MMF]|r Jiberish Icons not found. Download: " .. JIBERISH_DOWNLOAD_URL
                    DEFAULT_CHAT_FRAME:AddMessage(msg)
                end
                if dropdown and dropdown.SetSelectedValue then
                    dropdown.SetSelectedValue(GetCurrentTargetIconDropdownValue())
                end
                return
            end
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            local styleKey = ParseJiberishStyleValue(value)
            if styleKey then
                MattMinimalFramesDB.targetFrameIconMode = "jiberish"
                MattMinimalFramesDB.targetFrameIconStyle = styleKey
                MattMinimalFramesDB.showTargetFrameIcon = false
            else
                MattMinimalFramesDB.targetFrameIconMode = value
                MattMinimalFramesDB.showTargetFrameIcon = (value == "class")
                if value ~= "sharedmedia" and value ~= "jiberish" then
                    MattMinimalFramesDB.targetFrameIconStyle = nil
                    MattMinimalFramesDB.targetFrameIconMediaType = nil
                    MattMinimalFramesDB.targetFrameIconMediaKey = nil
                end
            end
            if MMF_UpdateTargetFrameIconVisibility then
                MMF_UpdateTargetFrameIconVisibility(MattMinimalFramesDB.targetFrameIconMode)
            end
        end,
    })
    dropdownLists.targetIconModeList = rightSection.targetIconModeDropdown.list

    local function NormalizeIconOffset(value)
        local offset = tonumber(value) or 0
        if offset < -200 then offset = -200 end
        if offset > 200 then offset = 200 end
        return math.floor(offset + 0.5)
    end

    local function NormalizeIconScale(value)
        local scale = tonumber(value) or 1
        if scale < 0.5 then scale = 0.5 end
        if scale > 3.0 then scale = 3.0 end
        return scale
    end

    MattMinimalFramesDB.playerFrameIconXOffset = NormalizeIconOffset(MattMinimalFramesDB.playerFrameIconXOffset)
    MattMinimalFramesDB.playerFrameIconYOffset = NormalizeIconOffset(MattMinimalFramesDB.playerFrameIconYOffset)
    MattMinimalFramesDB.targetFrameIconXOffset = NormalizeIconOffset(MattMinimalFramesDB.targetFrameIconXOffset)
    MattMinimalFramesDB.targetFrameIconYOffset = NormalizeIconOffset(MattMinimalFramesDB.targetFrameIconYOffset)
    MattMinimalFramesDB.playerFrameIconScale = NormalizeIconScale(MattMinimalFramesDB.playerFrameIconScale)
    MattMinimalFramesDB.targetFrameIconScale = NormalizeIconScale(MattMinimalFramesDB.targetFrameIconScale)

    local CreateMinimalSlider = ctx.createMinimalSlider
    local CreateMinimalCheckbox = ctx.createMinimalCheckbox

    rightSection.playerIconXSlider = CreateMinimalSlider(unitFramesCol, "Player Icon X", RIGHT_COL_X, (-506 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, RIGHT_COL_WIDTH, "playerFrameIconXOffset", -200, 200, 1, 0, function(value)
        MattMinimalFramesDB.playerFrameIconXOffset = NormalizeIconOffset(value)
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("player")
        end
    end, true)

    rightSection.playerIconYSlider = CreateMinimalSlider(unitFramesCol, "Player Icon Y", RIGHT_COL_X, (-530 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, RIGHT_COL_WIDTH, "playerFrameIconYOffset", -200, 200, 1, 0, function(value)
        MattMinimalFramesDB.playerFrameIconYOffset = NormalizeIconOffset(value)
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("player")
        end
    end, true)

    rightSection.targetIconXSlider = CreateMinimalSlider(unitFramesCol, "Target Icon X", RIGHT_COL_X, (-554 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, RIGHT_COL_WIDTH, "targetFrameIconXOffset", -200, 200, 1, 0, function(value)
        MattMinimalFramesDB.targetFrameIconXOffset = NormalizeIconOffset(value)
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("target")
        end
    end, true)

    rightSection.targetIconYSlider = CreateMinimalSlider(unitFramesCol, "Target Icon Y", RIGHT_COL_X, (-578 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, RIGHT_COL_WIDTH, "targetFrameIconYOffset", -200, 200, 1, 0, function(value)
        MattMinimalFramesDB.targetFrameIconYOffset = NormalizeIconOffset(value)
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("target")
        end
    end, true)

    rightSection.playerIconScaleSlider = CreateMinimalSlider(unitFramesCol, "Player Icon Size", RIGHT_COL_X, (-602 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, RIGHT_COL_WIDTH, "playerFrameIconScale", 0.5, 3.0, 0.05, 1.0, function(value)
        MattMinimalFramesDB.playerFrameIconScale = NormalizeIconScale(value)
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("player")
        end
    end, false)

    rightSection.targetIconScaleSlider = CreateMinimalSlider(unitFramesCol, "Target Icon Size", RIGHT_COL_X, (-626 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, RIGHT_COL_WIDTH, "targetFrameIconScale", 0.5, 3.0, 0.05, 1.0, function(value)
        MattMinimalFramesDB.targetFrameIconScale = NormalizeIconScale(value)
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("target")
        end
    end, false)

    local function CreateIconResetButton(label, x, y, onClick)
        local button = CreateFrame("Button", nil, unitFramesCol, "BackdropTemplate")
        button:SetSize(ICON_RESET_BUTTON_WIDTH, 20)
        button:SetPoint("TOPLEFT", x, y)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.08, 0.08, 0.1, 1)
        button:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)

        local text = button:CreateFontString(nil, "OVERLAY")
        text:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 9, "")
        text:SetPoint("CENTER")
        text:SetText(label)
        text:SetTextColor(0.8, 0.8, 0.8)

        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3], 0.9)
            text:SetTextColor(1, 1, 1)
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
            text:SetTextColor(0.8, 0.8, 0.8)
        end)
        button:SetScript("OnClick", function()
            if onClick then onClick() end
        end)
        return button
    end

    rightSection.resetPlayerIconButton = CreateIconResetButton("Reset Player Icon", RIGHT_COL_X, (-650 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, function()
        MattMinimalFramesDB.playerFrameIconXOffset = 0
        MattMinimalFramesDB.playerFrameIconYOffset = 0
        MattMinimalFramesDB.playerFrameIconScale = 1.0
        if rightSection.playerIconXSlider and rightSection.playerIconXSlider.slider then rightSection.playerIconXSlider.slider:SetValue(0) end
        if rightSection.playerIconYSlider and rightSection.playerIconYSlider.slider then rightSection.playerIconYSlider.slider:SetValue(0) end
        if rightSection.playerIconScaleSlider and rightSection.playerIconScaleSlider.slider then rightSection.playerIconScaleSlider.slider:SetValue(1.0) end
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("player")
        end
    end)

    rightSection.resetTargetIconButton = CreateIconResetButton("Reset Target Icon", RIGHT_COL_X + ICON_RESET_BUTTON_WIDTH + ICON_RESET_BUTTON_GAP, (-650 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, function()
        MattMinimalFramesDB.targetFrameIconXOffset = 0
        MattMinimalFramesDB.targetFrameIconYOffset = 0
        MattMinimalFramesDB.targetFrameIconScale = 1.0
        if rightSection.targetIconXSlider and rightSection.targetIconXSlider.slider then rightSection.targetIconXSlider.slider:SetValue(0) end
        if rightSection.targetIconYSlider and rightSection.targetIconYSlider.slider then rightSection.targetIconYSlider.slider:SetValue(0) end
        if rightSection.targetIconScaleSlider and rightSection.targetIconScaleSlider.slider then rightSection.targetIconScaleSlider.slider:SetValue(1.0) end
        if MMF_UpdateFrameIconPlacement then
            MMF_UpdateFrameIconPlacement("target")
        end
    end)

    rightSection.targetMarkersCheck = CreateMinimalCheckbox(unitFramesCol, "Target Markers", RIGHT_COL_X, (-678 - RIGHT_FRAME_OPTIONS_Y_SHIFT) + RIGHT_STACK_Y_OFFSET, "showTargetMarkers", false, function(checked)
        if MMF_UpdateTargetMarkerVisibility then
            MMF_UpdateTargetMarkerVisibility(checked)
        end
    end)

    rightSection.markerPreviewText = unitFramesCol:CreateFontString(nil, "OVERLAY")
    rightSection.markerPreviewText:SetFont("Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf", 10, "")
    rightSection.markerPreviewText:SetPoint("LEFT", rightSection.targetMarkersCheck, "LEFT", 116, 0)
    rightSection.markerPreviewText:SetText(
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:14:14:0:0:256:256:0:64:0:64|t" ..
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:14:14:0:0:256:256:64:128:0:64|t" ..
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:14:14:0:0:256:256:128:192:0:64|t"
    )
end

