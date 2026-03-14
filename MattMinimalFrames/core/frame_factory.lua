local cfg = MMF_Config
local Compat = _G.MMF_Compat

local function GetStatusBarTexturePath()
    if MMF_GetStatusBarTexturePath then
        return MMF_GetStatusBarTexturePath()
    end
    return cfg.TEXTURE_PATH
end

local function NotSecretValue(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return true
end

local function GetPlayerFrameIconMode()
    local mode = MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMode or nil
    if mode == "sharedmedia" and MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMediaType == "jiberish" then
        return "jiberish"
    end
    if mode == "off" or mode == "class" or mode == "portrait" or mode == "sharedmedia" or mode == "jiberish" then
        return mode
    end
    if MattMinimalFramesDB and MattMinimalFramesDB.showPlayerClassIcon ~= nil then
        if MattMinimalFramesDB.showPlayerClassIcon then
            return "class"
        end
        return "off"
    end
    return "off"
end

local function GetTargetFrameIconMode()
    local mode = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMode or nil
    if mode == "sharedmedia" and MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMediaType == "jiberish" then
        return "jiberish"
    end
    if mode == "off" or mode == "class" or mode == "portrait" or mode == "sharedmedia" or mode == "jiberish" then
        return mode
    end
    if MattMinimalFramesDB and MattMinimalFramesDB.showTargetFrameIcon ~= nil then
        if MattMinimalFramesDB.showTargetFrameIcon then
            return "class"
        end
        return "off"
    end
    return "off"
end

local function ClampIconOffset(value)
    local offset = tonumber(value) or 0
    if offset < -200 then offset = -200 end
    if offset > 200 then offset = 200 end
    return math.floor(offset + 0.5)
end

local function GetIconOffsetsForUnit(unit)
    if unit == "player" then
        local x = MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconXOffset or 0
        local y = MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconYOffset or 0
        return ClampIconOffset(x), ClampIconOffset(y)
    elseif unit == "target" then
        local x = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconXOffset or 0
        local y = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconYOffset or 0
        return ClampIconOffset(x), ClampIconOffset(y)
    end
    return 0, 0
end

local function ClampIconScale(value)
    local scale = tonumber(value) or 1
    if scale < 0.5 then scale = 0.5 end
    if scale > 3.0 then scale = 3.0 end
    return scale
end

local function GetIconScaleForUnit(unit)
    if unit == "player" then
        return ClampIconScale(MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconScale or 1)
    elseif unit == "target" then
        return ClampIconScale(MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconScale or 1)
    end
    return 1
end

local function ApplySingleIconPlacement(frame, icon, unit)
    if not frame or not icon or (unit ~= "player" and unit ~= "target") then
        return
    end

    local baseSize = math.max(8, (frame:GetHeight() or frame.originalHeight or 28))
    local iconSize = math.max(8, math.floor((baseSize * GetIconScaleForUnit(unit)) + 0.5))
    local xOffset, yOffset = GetIconOffsetsForUnit(unit)
    icon:SetSize(iconSize, iconSize)

    icon:ClearAllPoints()
    if unit == "player" then
        icon:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
    else
        icon:SetPoint("LEFT", frame, "RIGHT", xOffset, yOffset)
    end
end

local function ApplyFrameIconPlacement(frame)
    if not frame or not frame.unit then return end
    if frame.unit == "player" and frame.classIcon then
        ApplySingleIconPlacement(frame, frame.classIcon, "player")
    elseif frame.unit == "target" and frame.targetIcon then
        ApplySingleIconPlacement(frame, frame.targetIcon, "target")
    end
end

local function ApplySharedMediaIconTexture(icon, mediaKey, mediaType, classToken)
    if not icon or not MMF_GetIconTexturePath then
        return false
    end
    local path = MMF_GetIconTexturePath(mediaKey, mediaType)
    if type(path) ~= "string" or path == "" then
        return false
    end
    icon:SetTexture(path)
    local coords = MMF_GetIconTextureCoords and MMF_GetIconTextureCoords(mediaKey, mediaType, classToken)
    if mediaType == "jiberish" and (type(coords) ~= "table" or #coords < 8) then
        return false
    end
    if type(coords) == "table" and #coords >= 8 then
        icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4], coords[5], coords[6], coords[7], coords[8])
    else
        icon:SetTexCoord(0, 1, 0, 1)
    end
    icon:Show()
    return true
end

local function ApplyPlayerFrameIconMode(frame, mode)
    if not frame or not frame.classIcon then return end

    ApplyFrameIconPlacement(frame)
    mode = mode or GetPlayerFrameIconMode()
    local icon = frame.classIcon
    if mode == "off" then
        icon:Hide()
        return
    end

    if mode == "portrait" then
        if SetPortraitTexture then
            SetPortraitTexture(icon, "player")
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        icon:SetTexCoord(0, 1, 0, 1)
        icon:Show()
        return
    end

    if mode == "sharedmedia" or mode == "jiberish" then
        local mediaKey = (MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconStyle) or (MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMediaKey)
        local mediaType = (mode == "jiberish" and "jiberish") or (MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMediaType) or "jiberish"
        local _, classToken = UnitClass("player")
        if ApplySharedMediaIconTexture(icon, mediaKey, mediaType, classToken) then
            return
        end
        icon:Hide()
        return
    end

    local _, classFile = UnitClass("player")
    local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
    if not coords then
        icon:Hide()
        return
    end
    icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    local inset = 0.02
    icon:SetTexCoord(coords[1] + inset, coords[2] - inset, coords[3] + inset, coords[4] - inset)
    icon:Show()
end

local function ApplyTargetFrameIconMode(frame, mode)
    if not frame or not frame.targetIcon then return end

    ApplyFrameIconPlacement(frame)
    mode = mode or GetTargetFrameIconMode()
    local icon = frame.targetIcon
    if mode == "off" then
        icon:Hide()
        return
    end

    if not UnitExists("target") then
        icon:Hide()
        return
    end

    if mode == "portrait" then
        if SetPortraitTexture then
            SetPortraitTexture(icon, "target")
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        icon:SetTexCoord(0, 1, 0, 1)
        icon:Show()
        return
    end

    if mode == "sharedmedia" or mode == "jiberish" then
        local mediaKey = (MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconStyle) or (MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMediaKey)
        local mediaType = (mode == "jiberish" and "jiberish") or (MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMediaType) or "jiberish"
        local _, classToken = UnitClass("target")
        if ApplySharedMediaIconTexture(icon, mediaKey, mediaType, classToken) then
            return
        end
        icon:Hide()
        return
    end

    if UnitIsPlayer("target") then
        local _, classFile = UnitClass("target")
        local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
        if coords then
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            local inset = 0.02
            icon:SetTexCoord(coords[1] + inset, coords[2] - inset, coords[3] + inset, coords[4] - inset)
            icon:Show()
            return
        end
    end

    -- NPC fallback for "class icon" mode: show skull raid marker.
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    if SetRaidTargetIconTexture then
        local ok = pcall(SetRaidTargetIconTexture, icon, 8)
        if ok then
            icon:Show()
            return
        end
    end
    -- Fallback if API is unavailable.
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    icon:SetTexCoord(0.75, 1.0, 0.5, 1.0)
    icon:Show()
end

local function ApplyRaidMarkerTexture(texture, index)
    if not texture or not index then return false end

    if SetRaidTargetIconTexture then
        local ok = pcall(SetRaidTargetIconTexture, texture, index)
        if ok then
            return true
        end
    end

    if not NotSecretValue(index) then return false end
    if type(index) ~= "number" then return false end
    local validIndex = nil
    pcall(function()
        if index >= 1 and index <= 8 then
            validIndex = index
        end
    end)
    if not validIndex then return false end

    texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    local col = (validIndex - 1) % 4
    local row = math.floor((validIndex - 1) / 4)
    local left = col * 0.25
    local right = left + 0.25
    local top = row * 0.5
    local bottom = top + 0.5
    texture:SetTexCoord(left, right, top, bottom)
    return true
end

local function UpdateFrameTargetMarker(frame)
    if not frame or not frame.targetMarker then return end
    if not MattMinimalFramesDB or MattMinimalFramesDB.showTargetMarkers ~= true then
        frame.targetMarker:Hide()
        return
    end
    if not frame.unit or not UnitExists(frame.unit) then
        frame.targetMarker:Hide()
        return
    end
    local index = GetRaidTargetIndex(frame.unit)
    if not index then
        frame.targetMarker:Hide()
        return
    end
    local applied = ApplyRaidMarkerTexture(frame.targetMarker, index)
    if not applied then
        frame.targetMarker:Hide()
        return
    end
    frame.targetMarker:Show()
end

local function CreateTargetMarker(frame)
    if not frame or frame.targetMarker or not frame.nameOverlay then return end
    local marker = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    local markerSize = math.max(10, math.floor((frame:GetHeight() or frame.originalHeight or 28) * 0.75))
    marker:SetSize(markerSize, markerSize)
    marker:SetPoint("CENTER", frame, "CENTER", 0, 0)
    marker:Hide()
    frame.targetMarker = marker
    UpdateFrameTargetMarker(frame)
end

--------------------------------------------------
-- FRAME POSITIONING
--------------------------------------------------

local function SaveFramePosition(frame, frameName)
    local left = frame:GetLeft()
    local top = frame:GetTop()
    if left and top then
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end

        local bossIndex = nil
        if type(frameName) == "string" then
            local idx = frameName:match("^MMF_Boss([1-5])Frame$")
            if idx then
                bossIndex = tonumber(idx)
            end
        end

        if bossIndex then
            local spacing = 36
            local boss1Top = top + ((bossIndex - 1) * spacing)
            for i = 1, 5 do
                local name = "MMF_Boss" .. i .. "Frame"
                local frameTop = boss1Top - ((i - 1) * spacing)
                MattMinimalFramesDB[name] = { left = left, top = frameTop }

                local bossFrame = _G[name]
                if bossFrame then
                    bossFrame:ClearAllPoints()
                    bossFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, frameTop)
                end
            end
            return
        end

        MattMinimalFramesDB[frameName] = { left = left, top = top }
    end
end

local function SaveCastBarPosition(frame, unit)
    if not frame or not frame.castBarFrame or not unit then
        return
    end
    local x, y = frame.castBarFrame:GetCenter()
    local px, py = frame:GetCenter()
    if not x or not y or not px or not py then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if not MattMinimalFramesDB.castBarPositions then
        MattMinimalFramesDB.castBarPositions = {}
    end
    MattMinimalFramesDB.castBarPositions[unit] = { x = x - px, y = y - py }
end

local function ApplyCastBarPosition(frame, unit)
    if not frame or not frame.castBarFrame or not unit then
        return
    end

    local castBarPrefix = (unit == "player" and "playerCastBar")
        or (unit == "target" and "targetCastBar")
        or (unit == "focus" and "focusCastBar")
        or nil
    local scaleX = 1.0
    local scaleY = 1.0
    if castBarPrefix and MattMinimalFramesDB then
        scaleX = tonumber(MattMinimalFramesDB[castBarPrefix .. "FrameScaleX"]) or 1.0
        scaleY = tonumber(MattMinimalFramesDB[castBarPrefix .. "FrameScaleY"]) or 1.0
    elseif unit == "focus" then
        scaleX = tonumber(MMF_GetFrameScaleX and MMF_GetFrameScaleX("focus")) or 1.0
        scaleY = tonumber(MMF_GetFrameScaleY and MMF_GetFrameScaleY("focus")) or 1.0
    end
    if scaleX < 0.5 then scaleX = 0.5 end
    if scaleX > 3.0 then scaleX = 3.0 end
    if scaleY < 0.5 then scaleY = 0.5 end
    if scaleY > 5.0 then scaleY = 5.0 end

    local baseWidth = math.max(8, (frame.originalWidth or frame:GetWidth() or 0) - 2)
    local width = math.max(8, baseWidth * scaleX)
    local height = math.max(4, 8 * scaleY)
    frame.castBarFrame:SetSize(width, height)
    frame.castBarFrame:ClearAllPoints()

    local dbPos = MattMinimalFramesDB and MattMinimalFramesDB.castBarPositions and MattMinimalFramesDB.castBarPositions[unit]
    if dbPos and dbPos.x and dbPos.y then
        frame.castBarFrame:SetPoint("CENTER", frame, "CENTER", dbPos.x, dbPos.y)
    else
        if unit == "focus" then
            frame.castBarFrame:SetPoint("TOP", frame, "BOTTOM", 0, -1)
        else
            frame.castBarFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 1)
        end
    end

    local timeWidth = 36
    if frame.castBarTime then
        frame.castBarTime:SetWidth(timeWidth)
    end
    if frame.castBarText then
        frame.castBarText:SetWidth(math.max(8, width - timeWidth - 8))
    end
end

MMF_ApplyCastBarPosition = ApplyCastBarPosition

local function RestoreFramePosition(frame, frameName, defaultPoint, defaultRelPoint, defaultX, defaultY)
    if MattMinimalFramesDB and MattMinimalFramesDB[frameName] then
        local pos = MattMinimalFramesDB[frameName]
        frame:ClearAllPoints()
        if pos.left ~= nil and pos.top ~= nil then
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
        else
            frame:SetPoint(defaultPoint, UIParent, defaultRelPoint, defaultX, defaultY)
        end
    else
        frame:ClearAllPoints()
        frame:SetPoint(defaultPoint, UIParent, defaultRelPoint, defaultX, defaultY)
    end
end

--------------------------------------------------
-- TOOLTIP HANDLERS
--------------------------------------------------

local function CreateTooltipHandlers(frame)
    frame:SetScript("OnEnter", function(self)
        if self.unit and UnitExists(self.unit) and 
           (self.unit == "target" or self.unit == "targettarget" or 
            self.unit == "player" or self.unit == "focus" or
            self.unit == "boss1" or self.unit == "boss2" or self.unit == "boss3" or self.unit == "boss4" or self.unit == "boss5") then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
            self.highlightTexture:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        if self.unit == "target" or self.unit == "targettarget" or 
           self.unit == "player" or self.unit == "focus" or
           self.unit == "boss1" or self.unit == "boss2" or self.unit == "boss3" or self.unit == "boss4" or self.unit == "boss5" then
            GameTooltip:Hide()
            self.highlightTexture:Hide()
        end
    end)
end

local function ResetFrameToDefaultPosition(frame, frameName)
    if not frame or not frameName then
        return
    end
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    local bossIndex = tostring(frameName):match("^MMF_Boss([1-5])Frame$")
    if bossIndex then
        for i = 1, 5 do
            local bossUnit = "boss" .. i
            local bossFrameName = "MMF_Boss" .. i .. "Frame"
            local bossFrame = _G[bossFrameName]
            local def = MMF_GetFrameDefinition and MMF_GetFrameDefinition(bossUnit)
            MattMinimalFramesDB[bossFrameName] = nil
            if bossFrame and def then
                bossFrame:ClearAllPoints()
                bossFrame:SetPoint(def.point or "CENTER", UIParent, def.relPoint or "CENTER", def.x or 0, def.y or 0)
            end
        end
        return
    end

    local def = MMF_GetFrameDefinition and MMF_GetFrameDefinition(frame.unit)
    MattMinimalFramesDB[frameName] = nil
    if def then
        frame:ClearAllPoints()
        frame:SetPoint(def.point or "CENTER", UIParent, def.relPoint or "CENTER", def.x or 0, def.y or 0)
    end
end

local function EnsureFrameResetPopup()
    if _G.MMF_FrameResetPopup then
        return _G.MMF_FrameResetPopup
    end

    local popup = CreateFrame("Frame", "MMF_FrameResetPopup", UIParent, "BackdropTemplate")
    popup:SetSize(230, 112)
    popup:SetFrameStrata("DIALOG")
    popup:SetToplevel(true)
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(0.04, 0.04, 0.05, 0.72)
    popup:SetBackdropBorderColor(0.1, 0.1, 0.12, 0.9)
    popup:Hide()

    local title = popup:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(title, cfg.FONT_PATH, 10, "")
    else
        title:SetFont(cfg.FONT_PATH, 10, "")
    end
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetTextColor(1, 1, 1)
    title:SetText("Frame Options")
    popup.title = title

    local close = CreateFrame("Button", nil, popup)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -6, -6)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(closeText, cfg.FONT_PATH, 10, "")
    else
        closeText:SetFont(cfg.FONT_PATH, 10, "")
    end
    closeText:SetPoint("CENTER")
    closeText:SetTextColor(0.8, 0.8, 0.8)
    closeText:SetText("x")
    close:SetScript("OnClick", function() popup:Hide() end)

    local function CreatePopupButton(yOffset, label)
        local btn = CreateFrame("Button", nil, popup, "BackdropTemplate")
        btn:SetSize(206, 24)
        btn:SetPoint("TOP", popup, "TOP", 0, yOffset)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.06, 0.08, 0.1, 0.96)
        btn:SetBackdropBorderColor(0.18, 0.22, 0.25, 1)
        local txt = btn:CreateFontString(nil, "OVERLAY")
        if MMF_SetFontSafe then
            MMF_SetFontSafe(txt, cfg.FONT_PATH, 10, "")
        else
            txt:SetFont(cfg.FONT_PATH, 10, "")
        end
        txt:SetPoint("CENTER")
        txt:SetTextColor(0.9, 0.9, 0.9)
        txt:SetText(label)
        return btn
    end

    popup.resetPositionBtn = CreatePopupButton(-28, "Reset Frame Position")
    popup.resetCastBarBtn = CreatePopupButton(-58, "Reset Cast Bar")
    _G.MMF_FrameResetPopup = popup
    return popup
end

local function ShowFrameResetPopup(frame, frameName)
    if not frame or not frameName then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    local popup = EnsureFrameResetPopup()
    popup.currentFrame = frame
    popup.currentFrameName = frameName
    popup.title:SetText((frame.frameLabel or frame.unit or "Frame") .. " Options")

    local function ResetUnitCastBarToDefaults(unitToReset)
        if unitToReset ~= "player" and unitToReset ~= "target" and unitToReset ~= "focus" then
            return
        end
        if not MattMinimalFramesDB then
            MattMinimalFramesDB = {}
        end
        if unitToReset == "player" or unitToReset == "target" or unitToReset == "focus" then
            local defaults = MattMinimalFrames_Defaults or {}
            local prefix = (unitToReset == "player" and "playerCastBar")
                or (unitToReset == "target" and "targetCastBar")
                or "focusCastBar"
            MattMinimalFramesDB[prefix .. "FrameScaleX"] = tonumber(defaults[prefix .. "FrameScaleX"]) or 1.0
            MattMinimalFramesDB[prefix .. "FrameScaleY"] = tonumber(defaults[prefix .. "FrameScaleY"]) or 1.0
        end
        if MattMinimalFramesDB.castBarPositions then
            MattMinimalFramesDB.castBarPositions[unitToReset] = nil
        end
    end

    popup.resetPositionBtn:SetScript("OnClick", function()
        ResetFrameToDefaultPosition(frame, frameName)
        if frame.unit == "player" or frame.unit == "target" or frame.unit == "focus" then
            ResetUnitCastBarToDefaults(frame.unit)
            ApplyCastBarPosition(frame, frame.unit)
        end
        if MMF_RequestFrameUpdate then
            MMF_RequestFrameUpdate(frame)
        elseif MMF_UpdateUnitFrame then
            MMF_UpdateUnitFrame(frame)
        end
        popup:Hide()
    end)

    local hasCastBar = (frame.castBarFrame ~= nil and (frame.unit == "player" or frame.unit == "target" or frame.unit == "focus"))
    popup.resetCastBarBtn:SetShown(hasCastBar)
    popup:SetHeight(hasCastBar and 112 or 82)
    if hasCastBar then
        popup.resetCastBarBtn:ClearAllPoints()
        popup.resetCastBarBtn:SetPoint("TOP", popup, "TOP", 0, -58)
    end

    if hasCastBar then
        popup.resetCastBarBtn:SetScript("OnClick", function()
            ResetUnitCastBarToDefaults(frame.unit)
            ApplyCastBarPosition(frame, frame.unit)
            popup:Hide()
        end)
    end

    popup:ClearAllPoints()
    popup:SetPoint("TOP", frame, "BOTTOM", 0, -8)
    popup:Show()
end

--------------------------------------------------
-- DRAG HANDLERS
--------------------------------------------------

local function IsEditModeDragEnabled()
    return MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true
end

local function IsTestModeShiftDragEnabled()
    return MattMinimalFramesDB and (MattMinimalFramesDB.layoutTestMode == true or MattMinimalFramesDB.auraTestMode == true)
end

local function CanStartFrameDrag(frame)
    if InCombatLockdown() then
        return false
    end
    if IsEditModeDragEnabled() then
        return frame and frame:IsMovable()
    end
    if IsTestModeShiftDragEnabled() then
        return IsShiftKeyDown() and frame and frame:IsMovable()
    end
    local isLocked = MattMinimalFramesDB and MattMinimalFramesDB.locked
    return (not isLocked) and IsShiftKeyDown() and frame and frame:IsMovable()
end

local function GetDragHintText()
    if IsEditModeDragEnabled() then
        return "Drag to move"
    end
    return "Shift+Drag to move"
end

local function CreateDragHandlers(frame, frameName)
    frame:SetScript("OnDragStart", function(self)
        if CanStartFrameDrag(self) then
            self.mmfDragInProgress = true
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        if self:IsMovable() then
            self:StopMovingOrSizing()
            SaveFramePosition(self, frameName)
            self.mmfSuppressClickPopup = true
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function()
                    if self then
                        self.mmfSuppressClickPopup = nil
                        self.mmfDragInProgress = nil
                    end
                end)
            else
                self.mmfSuppressClickPopup = nil
                self.mmfDragInProgress = nil
            end
        end
    end)

    frame.moveOverlay = frame:CreateTexture(nil, "OVERLAY")
    frame.moveOverlay:SetAllPoints()
    frame.moveOverlay:SetColorTexture(0, 0, 0, 0.35)
    frame.moveOverlay:Hide()

    frame:HookScript("OnEnter", function(self)
        if CanStartFrameDrag(self) then
            self.moveOverlay:Show()
        end
    end)

    frame:HookScript("OnLeave", function(self)
        self.moveOverlay:Hide()
    end)

    local frameDef = MMF_GetFrameDefinition(frame.unit)
    local frameLabel = frameDef and frameDef.label or frame.unit
    frame.frameLabel = frameLabel
    
    frame.moveHint = frame:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.moveHint, cfg.FONT_PATH, 10, "OUTLINE")
    else
        frame.moveHint:SetFont(cfg.FONT_PATH, 10, "OUTLINE")
    end
    frame.moveHint:SetText(frameLabel)
    frame.moveHint:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.moveHint:Hide()
    
    frame.moveSubtext = frame:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.moveSubtext, cfg.FONT_PATH, 9, "OUTLINE")
    else
        frame.moveSubtext:SetFont(cfg.FONT_PATH, 9, "OUTLINE")
    end
    frame.moveSubtext:SetText(GetDragHintText())
    frame.moveSubtext:SetPoint("TOP", frame.moveHint, "BOTTOM", 0, -2)
    frame.moveSubtext:SetTextColor(0.7, 0.7, 0.7)
    frame.moveSubtext:Hide()

    frame:HookScript("OnEnter", function(self)
        if not InCombatLockdown() and MattMinimalFramesDB.showMoveHints then
            self.moveSubtext:SetText(GetDragHintText())
            self.moveHint:Show()
            self.moveSubtext:Show()
        end
    end)
    
    frame:HookScript("OnLeave", function(self)
        self.moveHint:Hide()
        self.moveSubtext:Hide()
    end)

    frame:HookScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then
            return
        end
        if not IsEditModeDragEnabled() then
            return
        end
        if self.mmfDragInProgress or self.mmfSuppressClickPopup then
            return
        end
        ShowFrameResetPopup(self, frameName)
    end)
end

--------------------------------------------------
-- HEALTH BAR CREATION
--------------------------------------------------

local function ClampUnitInterval(value, fallback)
    local n = tonumber(value)
    if not n then
        n = tonumber(fallback) or 0
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function GetHealthBarBGColorFromDB()
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

local function GetHealthBarBorderStyleFromDB()
    local db = MattMinimalFramesDB or {}
    return ClampUnitInterval(db.healthBarBorderColorR, 0),
        ClampUnitInterval(db.healthBarBorderColorG, 0),
        ClampUnitInterval(db.healthBarBorderColorB, 0),
        ClampUnitInterval(db.healthBarBorderAlpha, 1),
        ClampBorderSize(db.healthBarBorderSize, 1)
end

local function CreateHealthBar(frame)
    frame.healthBarBG = frame:CreateTexture(nil, "BACKGROUND")
    local borderR, borderG, borderB, borderA, borderSize = GetHealthBarBorderStyleFromDB()
    local contentInset = math.max(1, borderSize)
    frame.healthBarBG:SetPoint("TOPLEFT", frame, "TOPLEFT", contentInset, -contentInset)
    frame.healthBarBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentInset, contentInset)
    local bgR, bgG, bgB, bgA = GetHealthBarBGColorFromDB()
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
end

--------------------------------------------------
-- POWER BAR CREATION
--------------------------------------------------

local function CreatePowerBarContainer(frame, unit)
    frame.powerBarFrame = CreateFrame("Frame", nil, frame)
    frame.powerBarFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    frame.powerBarBG = frame.powerBarFrame:CreateTexture(nil, "BACKGROUND")
    frame.powerBarBG:SetColorTexture(0, 0, 0, 0.25)
    
    frame.powerBar = CreateFrame("StatusBar", nil, frame.powerBarFrame)
    frame.powerBar:SetStatusBarTexture(GetStatusBarTexturePath())
    frame.powerBar:SetMinMaxValues(0, 1)
    frame.powerBar:SetValue(1)
    frame.powerBarFG = frame.powerBar:GetStatusBarTexture()
end

local function SetupPowerBar(frame, unit)
    local DEFAULT_WIDTH = cfg.POWER_BAR_WIDTH
    local DEFAULT_HEIGHT = cfg.POWER_BAR_HEIGHT
    if unit == "player" then
        DEFAULT_WIDTH = (MattMinimalFramesDB and (MattMinimalFramesDB.playerPowerBarWidth or MattMinimalFramesDB.powerBarWidth)) or DEFAULT_WIDTH
        DEFAULT_HEIGHT = (MattMinimalFramesDB and (MattMinimalFramesDB.playerPowerBarHeight or MattMinimalFramesDB.powerBarHeight)) or DEFAULT_HEIGHT
    elseif unit == "target" then
        DEFAULT_WIDTH = (MattMinimalFramesDB and (MattMinimalFramesDB.targetPowerBarWidth or MattMinimalFramesDB.powerBarWidth)) or DEFAULT_WIDTH
        DEFAULT_HEIGHT = (MattMinimalFramesDB and (MattMinimalFramesDB.targetPowerBarHeight or MattMinimalFramesDB.powerBarHeight)) or DEFAULT_HEIGHT
    else
        DEFAULT_WIDTH = (MattMinimalFramesDB and MattMinimalFramesDB.powerBarWidth) or DEFAULT_WIDTH
        DEFAULT_HEIGHT = (MattMinimalFramesDB and MattMinimalFramesDB.powerBarHeight) or DEFAULT_HEIGHT
    end
    local DEFAULT_V_OFFSET = cfg.POWER_BAR_VERTICAL_OFFSET
    local DEFAULT_H_OFFSET = cfg.POWER_BAR_HORIZONTAL_OFFSET

    frame.powerBarFrame:SetSize(DEFAULT_WIDTH + 2, DEFAULT_HEIGHT + 2)
    frame.powerBarFrame:SetMovable(true)
    frame.powerBarFrame:EnableMouse(true)
    frame.powerBarFrame:RegisterForDrag("LeftButton")
    
    if unit == "player" then
        frame.powerBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -DEFAULT_H_OFFSET, DEFAULT_V_OFFSET)
    else
        frame.powerBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", DEFAULT_H_OFFSET, DEFAULT_V_OFFSET)
    end

    frame.powerBarFrame:SetScript("OnDragStart", function(self)
        if CanStartFrameDrag(self) then
            self:StartMoving()
        end
    end)

    frame.powerBarFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local px, py = frame:GetCenter()
        if not MattMinimalFramesDB.powerBarPositions then
            MattMinimalFramesDB.powerBarPositions = {}
        end
        MattMinimalFramesDB.powerBarPositions[unit] = { x = x - px, y = y - py }
    end)

    frame.powerBarFrame:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        if unit == "player" then
            GameTooltip:SetText("Player Power Bar", 1, 1, 1)
        else
            GameTooltip:SetText("Target Power Bar", 1, 1, 1)
        end
        GameTooltip:AddLine(GetDragHintText(), 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    frame.powerBarFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    frame.powerBarBorder = frame.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.powerBarBorder:SetColorTexture(0, 0, 0, 0.5)
    frame.powerBarBorder:SetAllPoints()

    frame.powerBarBG:SetHeight(DEFAULT_HEIGHT)
    frame.powerBarBG:SetWidth(DEFAULT_WIDTH)
    frame.powerBarBG:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)

    frame.powerBar:SetHeight(DEFAULT_HEIGHT)
    frame.powerBar:SetWidth(DEFAULT_WIDTH)
    frame.powerBar:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)
    frame.powerBar:SetAlpha(0.5)

    if MattMinimalFramesDB and MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit] then
        local pos = MattMinimalFramesDB.powerBarPositions[unit]
        frame.powerBarFrame:ClearAllPoints()
        frame.powerBarFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
    end
end

local function GetDefaultPowerTextAnchor(frame, unit)
    if unit == "player" then
        if frame.powerBarFrame then
            return "TOP", frame.powerBarFrame, "BOTTOM", 0, -2
        end
        return "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0
    elseif unit == "target" then
        if frame.powerBarFrame then
            return "TOP", frame.powerBarFrame, "BOTTOM", 0, -2
        end
        return "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0
    elseif unit == "targettarget" or unit == "pet" then
        return "BOTTOM", frame, "BOTTOM", 0, 0
    end
    return "BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3
end

local function ApplyPowerTextPosition(frame, unit)
    if not frame or not frame.powerText then return end

    if frame.powerTextDragFrame and (unit == "player" or unit == "target") then
        frame.powerTextDragFrame:ClearAllPoints()
        local pos = MattMinimalFramesDB and MattMinimalFramesDB.powerTextPositions and MattMinimalFramesDB.powerTextPositions[unit]
        if pos and pos.x and pos.y then
            frame.powerTextDragFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
        else
            local point, relFrame, relPoint, x, y = GetDefaultPowerTextAnchor(frame, unit)
            frame.powerTextDragFrame:SetPoint(point, relFrame, relPoint, x, y)
        end

        frame.powerText:ClearAllPoints()
        frame.powerText:SetPoint("CENTER", frame.powerTextDragFrame, "CENTER", 0, 0)
        return
    end

    local point, relFrame, relPoint, x, y = GetDefaultPowerTextAnchor(frame, unit)
    frame.powerText:SetPoint(point, relFrame, relPoint, x, y)
end

--------------------------------------------------
-- ABSORB BAR CREATION
--------------------------------------------------

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
    frame.absorbBar:Hide()
end

--------------------------------------------------
-- HEAL PREDICTION BAR CREATION
--------------------------------------------------

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

    if Compat.IsRetail and CreateUnitHealPredictionCalculator then
        frame.healPredictionCalculator = CreateUnitHealPredictionCalculator()
    end
end

--------------------------------------------------
-- TEXT ELEMENTS
--------------------------------------------------

local function CreateNameText(frame, unit)
    local fontPath = cfg.FONT_PATH
    
    frame.nameOverlay = CreateFrame("Frame", nil, frame)
    frame.nameOverlay:SetAllPoints(frame)
    frame.nameOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    
    frame.nameText = frame.nameOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
    
    local fontSize = MMF_GetNameTextSize(unit)
    local nameX = MMF_GetNameTextXOffset and MMF_GetNameTextXOffset(unit) or 0
    local nameY = MMF_GetNameTextYOffset and MMF_GetNameTextYOffset(unit) or 0
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.nameText, fontPath, fontSize, "OUTLINE")
    else
        frame.nameText:SetFont(fontPath, fontSize, "OUTLINE")
    end
    frame.nameText:SetTextColor(1, 1, 1, 1)
    frame.nameText:SetShadowOffset(1, -1)
    frame.nameText:SetShadowColor(0, 0, 0, 0.9)
    
    local positions = {
        player = { point = "LEFT", relPoint = "TOPLEFT", x = 2, y = 0, justify = "LEFT" },
        target = { point = "RIGHT", relPoint = "TOPRIGHT", x = -2, y = 0, justify = "RIGHT" },
        targettarget = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        pet = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        focus = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        boss1 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        boss2 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        boss3 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        boss4 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
        boss5 = { point = "CENTER", relPoint = "TOP", x = 0, y = 0, justify = "CENTER" },
    }
    
    local pos = positions[unit] or positions.focus
    frame.nameText:SetPoint(pos.point, frame, pos.relPoint, pos.x + nameX, pos.y + nameY)
    frame.nameText:SetJustifyH(pos.justify)
    pcall(function()
        frame.nameText:SetWordWrap(true)
    end)
    pcall(function()
        frame.nameText:SetNonSpaceWrap(true)
    end)
    pcall(function()
        frame.nameText:SetMaxLines(0)
    end)
    frame.nameText:SetWidth(frame.originalWidth - 4)
end

local function CreateResourceText(frame, unit)
    local fontPath = cfg.FONT_PATH
    local hpSize = MMF_GetHPTextSize and MMF_GetHPTextSize(unit) or 13
    local hpX = MMF_GetHPTextXOffset and MMF_GetHPTextXOffset(unit) or 0
    local hpY = MMF_GetHPTextYOffset and MMF_GetHPTextYOffset(unit) or 0
    
    frame.hpText = frame.nameOverlay:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.hpText, fontPath, hpSize, "OUTLINE")
    else
        frame.hpText:SetFont(fontPath, hpSize, "OUTLINE")
    end
    frame.hpText:SetTextColor(1, 1, 1)
    
    frame.powerText = frame.nameOverlay:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.powerText, fontPath, 13, "OUTLINE")
    else
        frame.powerText:SetFont(fontPath, 13, "OUTLINE")
    end
    frame.powerText:SetTextColor(1, 1, 1)

    if unit == "player" or unit == "target" then
        frame.powerTextDragFrame = CreateFrame("Frame", nil, frame.nameOverlay)
        frame.powerTextDragFrame:SetFrameLevel(frame.nameOverlay:GetFrameLevel() + 1)
        frame.powerTextDragFrame:SetSize(84, 18)
        frame.powerTextDragFrame:SetMovable(true)
        frame.powerTextDragFrame:EnableMouse(true)
        frame.powerTextDragFrame:RegisterForDrag("LeftButton")

        frame.powerTextDragFrame:SetScript("OnDragStart", function(self)
            if CanStartFrameDrag(self) then
                self:StartMoving()
            end
        end)

        frame.powerTextDragFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local x, y = self:GetCenter()
            local px, py = frame:GetCenter()
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            if not MattMinimalFramesDB.powerTextPositions then
                MattMinimalFramesDB.powerTextPositions = {}
            end
            MattMinimalFramesDB.powerTextPositions[unit] = { x = x - px, y = y - py }
        end)

        frame.powerTextDragFrame:SetScript("OnEnter", function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            if unit == "player" then
                GameTooltip:SetText("Player Power Text", 1, 1, 1)
            else
                GameTooltip:SetText("Target Power Text", 1, 1, 1)
            end
            GameTooltip:AddLine(GetDragHintText(), 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)

        frame.powerTextDragFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.powerTextDragFrame:Hide()
    end
    
    if unit == "player" then
        frame.hpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0 + hpX, -14.5 + hpY)
        ApplyPowerTextPosition(frame, unit)
    elseif unit == "target" then
        frame.hpText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2 + hpX, -14.5 + hpY)
        ApplyPowerTextPosition(frame, unit)
    elseif unit == "targettarget" or unit == "pet" or unit == "focus" or unit == "boss1" or unit == "boss2" or unit == "boss3" or unit == "boss4" or unit == "boss5" then
        frame.hpText:SetPoint("BOTTOM", frame, "BOTTOM", 0 + hpX, 0 + hpY)
        ApplyPowerTextPosition(frame, unit)
    else
        frame.hpText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3 + hpX, 3 + hpY)
        ApplyPowerTextPosition(frame, unit)
    end
end

function MMF_ApplyPowerTextPositions()
    local function ApplyFor(frame, unit)
        if not frame or not frame.powerText then return end
        ApplyPowerTextPosition(frame, unit)
    end

    ApplyFor(_G.MMF_PlayerFrame, "player")
    ApplyFor(_G.MMF_TargetFrame, "target")
end

--------------------------------------------------
-- COMBAT/RESTING INDICATORS
--------------------------------------------------

local function IsPlayerInCombat()
    if UnitAffectingCombat then
        return UnitAffectingCombat("player") == true
    end
    return InCombatLockdown and InCombatLockdown() or false
end

local COMBAT_ICON_BASE_SCALE = 1.00
local COMBAT_ICON_BREATH_DELTA = 0.06
local COMBAT_ICON_BREATH_PERIOD = 0.6
local COMBAT_BORDER_IDLE_ALPHA = 0.32
local COMBAT_BORDER_PULSE_MIN_ALPHA = 0.24
local COMBAT_BORDER_PULSE_MAX_ALPHA = 0.58
local COMBAT_BORDER_RED_GB = 0.62
local COMBAT_FRAME_OUTLINE_IDLE_ALPHA = 0.50
local COMBAT_FRAME_OUTLINE_PULSE_MIN_ALPHA = 0.40
local COMBAT_FRAME_OUTLINE_PULSE_MAX_ALPHA = 0.95
local COMBAT_FRAME_OUTLINE_RED_GB = 0.35

local function SetCombatOutlineColor(frame, r, g, b, a)
    if not frame or not frame.combatIconOutlineTextures then
        return
    end
    for _, tex in ipairs(frame.combatIconOutlineTextures) do
        tex:SetVertexColor(r, g, b, a)
    end
end

local function SetCombatFrameOutlineColor(frame, r, g, b, a)
    if not frame or not frame.combatFrameOutlineEdges then
        return
    end
    for _, edge in pairs(frame.combatFrameOutlineEdges) do
        edge:SetColorTexture(r, g, b, a)
    end
end

local function IsCombatFrameOutlineEnabled()
    if not MattMinimalFramesDB then
        return false
    end
    return MattMinimalFramesDB.combatFrameOutline == true
end

local function SetPlayerCombatVisual(frame, isInCombat)
    if not frame or not frame.combatTexture then
        return
    end

    local frameOutlineEnabled = IsCombatFrameOutlineEnabled()

    frame.combatTexture:SetShown(isInCombat == true)
    if frame.combatIconOutlineTextures then
        for _, tex in ipairs(frame.combatIconOutlineTextures) do
            tex:SetShown(isInCombat == true)
        end
    end
    if frame.combatFrameOutlineEdges then
        for _, edge in pairs(frame.combatFrameOutlineEdges) do
            edge:SetShown(isInCombat == true and frameOutlineEnabled)
        end
    end

    if not frame.combatUsesAnimation then
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Hide()
        end
        frame.combatTexture:SetScale(1)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
        return
    end

    if isInCombat then
        frame.combatTexture:SetScale(COMBAT_ICON_BASE_SCALE)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        frame.combatPulseStart = GetTime and GetTime() or 0
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Show()
        end
    else
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Hide()
        end
        frame.combatTexture:SetScale(1)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
    end
end

local function CreateCombatIconOutline(frame)
    if not frame or not frame.nameOverlay or not frame.combatTexture or frame.combatIconOutlineTextures then
        return
    end

    local offsets = {
        { -0.5, 0 }, { 0.5, 0 }, { 0, -0.5 }, { 0, 0.5 },
    }

    frame.combatIconOutlineTextures = {}
    for _, offset in ipairs(offsets) do
        local dx, dy = offset[1], offset[2]
        local tex = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 6)
        tex:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        tex:SetTexCoord(0.5, 1, 0, 0.49)
        -- WoW textures are pixel-aligned; use softer alpha to emulate a thinner (~0.5px) outline.
        tex:SetVertexColor(1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        tex:SetPoint("TOPLEFT", frame.combatTexture, "TOPLEFT", dx, dy)
        tex:SetPoint("BOTTOMRIGHT", frame.combatTexture, "BOTTOMRIGHT", dx, dy)
        tex:Hide()
        frame.combatIconOutlineTextures[#frame.combatIconOutlineTextures + 1] = tex
    end
end

local function IsAnimatedCombatIconEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.animatedCombatIcon ~= false
end

local function CreateCombatFrameOutline(frame)
    if not frame or frame.combatFrameOutlineEdges then
        return
    end

    local edges = {
        top = frame:CreateTexture(nil, "OVERLAY", nil, 7),
        right = frame:CreateTexture(nil, "OVERLAY", nil, 7),
        bottom = frame:CreateTexture(nil, "OVERLAY", nil, 7),
        left = frame:CreateTexture(nil, "OVERLAY", nil, 7),
    }
    local edgeSize = 1

    edges.top:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    edges.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    edges.top:SetHeight(edgeSize)

    edges.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
    edges.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    edges.bottom:SetHeight(edgeSize)

    edges.left:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    edges.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
    edges.left:SetWidth(edgeSize)

    edges.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    edges.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    edges.right:SetWidth(edgeSize)

    frame.combatFrameOutlineEdges = edges
    SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
    for _, edge in pairs(edges) do
        edge:Hide()
    end
end

local function ConfigurePlayerCombatTexture(frame)
    if not frame or not frame.combatTexture then
        return
    end

    local canUsePulse = IsAnimatedCombatIconEnabled() or IsCombatFrameOutlineEnabled()
    if canUsePulse then
        frame.combatUsesAnimation = true
        frame.combatTexture:SetScale(COMBAT_ICON_BASE_SCALE)
        if not frame.combatPulseDriver then
            local pulseDriver = CreateFrame("Frame", nil, frame)
            pulseDriver:Hide()
            pulseDriver:SetScript("OnUpdate", function()
                if not frame.combatTexture or not frame.combatTexture:IsShown() then
                    return
                end
                local now = GetTime and GetTime() or 0
                local startTime = frame.combatPulseStart or now
                local period = COMBAT_ICON_BREATH_PERIOD
                if period <= 0 then
                    period = 2.0
                end
                local phase = ((now - startTime) / period) * (2 * math.pi)
                local normalized = (math.sin(phase - (math.pi * 0.5)) + 1) * 0.5
                local scale = COMBAT_ICON_BASE_SCALE + (COMBAT_ICON_BREATH_DELTA * normalized)
                local alpha = COMBAT_BORDER_PULSE_MIN_ALPHA + ((COMBAT_BORDER_PULSE_MAX_ALPHA - COMBAT_BORDER_PULSE_MIN_ALPHA) * normalized)
                local frameAlpha = COMBAT_FRAME_OUTLINE_PULSE_MIN_ALPHA + ((COMBAT_FRAME_OUTLINE_PULSE_MAX_ALPHA - COMBAT_FRAME_OUTLINE_PULSE_MIN_ALPHA) * normalized)

                if IsAnimatedCombatIconEnabled() then
                    frame.combatTexture:SetScale(scale)
                else
                    frame.combatTexture:SetScale(1)
                end
                frame.combatTexture:SetVertexColor(1, 1, 1, 1)
                SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, alpha)
                if IsCombatFrameOutlineEnabled() then
                    SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, frameAlpha)
                else
                    SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
                end
            end)
            frame.combatPulseDriver = pulseDriver
        end
    else
        if frame.combatPulseDriver then
            frame.combatPulseDriver:Hide()
        end
        frame.combatUsesAnimation = false
        frame.combatTexture:SetScale(1)
        frame.combatTexture:SetVertexColor(1, 1, 1, 1)
        SetCombatOutlineColor(frame, 1, COMBAT_BORDER_RED_GB, COMBAT_BORDER_RED_GB, COMBAT_BORDER_IDLE_ALPHA)
        SetCombatFrameOutlineColor(frame, 1, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_RED_GB, COMBAT_FRAME_OUTLINE_IDLE_ALPHA)
    end
end

local function SetPlayerRestingVisual(frame, isResting)
    if not frame or not frame.restingTexture then
        return
    end

    frame.restingTexture:SetShown(isResting == true)
    if not frame.restingAnim or not frame.restingUsesAnimation then
        return
    end

    if isResting then
        if not frame.restingAnim:IsPlaying() then
            frame.restingAnim:Play()
        end
    else
        frame.restingAnim:Stop()
    end
end

local function IsAnimatedRestingIconEnabled()
    if not MattMinimalFramesDB then
        return true
    end
    return MattMinimalFramesDB.animatedRestingIcon ~= false
end

local function ConfigurePlayerRestingTexture(frame)
    if not frame or not frame.restingTexture then
        return
    end

    local canUseFlipbook = (Compat and not Compat.IsTBC)
        and frame.restingTexture.SetAtlas
        and frame.restingTexture.CreateAnimationGroup
        and IsAnimatedRestingIconEnabled()

    if canUseFlipbook then
        frame.restingTexture:SetAtlas("UI-HUD-UnitFrame-Player-Rest-Flipbook")
        frame.restingTexture:SetTexCoord(0, 1, 0, 1)
        frame.restingTexture:SetSize(24, 24)
        frame.restingUsesAnimation = true

        if not frame.restingAnim then
            local animGroup = frame.restingTexture:CreateAnimationGroup()
            animGroup:SetLooping("REPEAT")
            animGroup:SetToFinalAlpha(true)

            local flipBook = animGroup:CreateAnimation("FlipBook")
            if flipBook then
                flipBook:SetOrder(1)
                flipBook:SetDuration(1.5)
                if flipBook.SetSmoothing then flipBook:SetSmoothing("NONE") end
                if flipBook.SetFlipBookRows then flipBook:SetFlipBookRows(7) end
                if flipBook.SetFlipBookColumns then flipBook:SetFlipBookColumns(6) end
                if flipBook.SetFlipBookFrames then flipBook:SetFlipBookFrames(42) end
                if flipBook.SetFlipBookFrameWidth then flipBook:SetFlipBookFrameWidth(0) end
                if flipBook.SetFlipBookFrameHeight then flipBook:SetFlipBookFrameHeight(0) end
            end
            frame.restingAnim = animGroup
        end
    else
        if frame.restingAnim then
            frame.restingAnim:Stop()
        end
        frame.restingTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        frame.restingTexture:SetTexCoord(0, 0.5, 0, 0.421875)
        frame.restingTexture:SetSize(20, 20)
        frame.restingUsesAnimation = false
    end

    frame.restingTexture:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 10)
    frame.restingTexture:SetDrawLayer("OVERLAY", 7)
end

function MMF_UpdatePlayerRestingIndicator()
    if not _G.MMF_PlayerFrame then
        return
    end
    SetPlayerRestingVisual(_G.MMF_PlayerFrame, IsResting())
end

function MMF_UpdatePlayerCombatIndicator()
    if not _G.MMF_PlayerFrame then
        return
    end
    SetPlayerCombatVisual(_G.MMF_PlayerFrame, IsPlayerInCombat())
end

function MMF_UpdateAnimatedRestingIconSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.animatedRestingIcon = (enabled == true)
    elseif MattMinimalFramesDB.animatedRestingIcon == nil then
        MattMinimalFramesDB.animatedRestingIcon = true
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.restingTexture then
        ConfigurePlayerRestingTexture(_G.MMF_PlayerFrame)
        SetPlayerRestingVisual(_G.MMF_PlayerFrame, IsResting())
    end
end

function MMF_UpdateAnimatedCombatIconSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.animatedCombatIcon = (enabled == true)
    elseif MattMinimalFramesDB.animatedCombatIcon == nil then
        MattMinimalFramesDB.animatedCombatIcon = true
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.combatTexture then
        ConfigurePlayerCombatTexture(_G.MMF_PlayerFrame)
        SetPlayerCombatVisual(_G.MMF_PlayerFrame, IsPlayerInCombat())
    end
end

function MMF_UpdateCombatFrameOutlineSetting(enabled)
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if enabled ~= nil then
        MattMinimalFramesDB.combatFrameOutline = (enabled == true)
    elseif MattMinimalFramesDB.combatFrameOutline == nil then
        MattMinimalFramesDB.combatFrameOutline = false
    end

    if _G.MMF_PlayerFrame and _G.MMF_PlayerFrame.combatTexture then
        ConfigurePlayerCombatTexture(_G.MMF_PlayerFrame)
        SetPlayerCombatVisual(_G.MMF_PlayerFrame, IsPlayerInCombat())
    end
end

local function CreatePlayerIndicators(frame)
    frame.combatTexture = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.combatTexture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.combatTexture:SetTexCoord(0.5, 1, 0, 0.49)
    frame.combatTexture:SetSize(22, 22)
    frame.combatTexture:SetPoint("CENTER", frame, "CENTER", 0, 12)
    frame.combatTexture:SetDrawLayer("OVERLAY", 7)
    CreateCombatIconOutline(frame)
    CreateCombatFrameOutline(frame)
    ConfigurePlayerCombatTexture(frame)
    SetPlayerCombatVisual(frame, IsPlayerInCombat())

    frame.restingTexture = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    ConfigurePlayerRestingTexture(frame)
    SetPlayerRestingVisual(frame, IsResting())
end

local function CreatePlayerClassIcon(frame)
    if not frame or frame.classIcon then return end
    if not frame.nameOverlay then return end

    local classIcon = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    local iconSize = math.max(8, (frame:GetHeight() or frame.originalHeight or 28))
    classIcon:SetSize(iconSize, iconSize)
    frame.classIcon = classIcon
    ApplyFrameIconPlacement(frame)

    ApplyPlayerFrameIconMode(frame, GetPlayerFrameIconMode())
end

local function CreateTargetFrameIcon(frame)
    if not frame or frame.targetIcon then return end
    if not frame.nameOverlay then return end

    local targetIcon = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    local iconSize = math.max(8, (frame:GetHeight() or frame.originalHeight or 28))
    targetIcon:SetSize(iconSize, iconSize)
    frame.targetIcon = targetIcon
    ApplyFrameIconPlacement(frame)

    ApplyTargetFrameIconMode(frame, GetTargetFrameIconMode())
end

local function CreatePVPFlagIndicator(frame, unit)
    if not frame or not frame.nameOverlay then return end
    if not Compat.IsTBC then return end
    if unit ~= "player" and unit ~= "target" then return end
    if frame.pvpFlagText then return end

    local text = frame.nameOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
    if MMF_SetFontSafe then
        MMF_SetFontSafe(text, cfg.FONT_PATH, 10, "OUTLINE")
    else
        text:SetFont(cfg.FONT_PATH, 10, "OUTLINE")
    end
    text:SetText("PVP")
    text:SetTextColor(1, 0.2, 0.2, 1)
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 0.9)

    text:ClearAllPoints()
    if unit == "player" then
        text:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
    else
        text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    end

    text:Hide()

    frame.pvpFlagText = text
end

local function UpdatePVPFlagIndicator(frame)
    if not frame or not frame.unit then return end
    if not frame.pvpFlagText then return end
    if not Compat.IsTBC then
        frame.pvpFlagText:Hide()
        return
    end

    local unit = frame.unit
    if (unit ~= "player" and unit ~= "target") or not UnitExists(unit) then
        frame.pvpFlagText:Hide()
        return
    end

    local function FormatPVPTimerText(milliseconds)
        local totalSeconds = math.floor(((tonumber(milliseconds) or 0) / 1000) + 0.5)
        if totalSeconds < 0 then totalSeconds = 0 end
        local minutes = math.floor(totalSeconds / 60)
        local seconds = totalSeconds % 60
        return string.format("%d:%02d", minutes, seconds)
    end

    local isFFA = UnitIsPVPFreeForAll(unit) == true
    local isFlagged = false
    local labelText = "PVP"
    local timerMode = false
    local textR, textG, textB = 1, 0.2, 0.2
    if unit == "player" then
        local desired = (GetPVPDesired and GetPVPDesired()) == true
        local timerRunning = (IsPVPTimerRunning and IsPVPTimerRunning()) == true
        isFlagged = isFFA or (UnitIsPVP(unit) and (desired or timerRunning))
        if timerRunning and not desired and GetPVPTimer then
            local timerText = FormatPVPTimerText(GetPVPTimer())
            local timerHex = "ffffd933"
            local _, playerClass = UnitClass("player")
            if playerClass == "ROGUE" then
                timerHex = "ffffffff"
            end
            labelText = "|cffff3333PVP|r |c" .. timerHex .. timerText .. "|r"
            timerMode = true
            textR, textG, textB = 1.0, 0.85, 0.2
        end
    else
        -- Target indicator should only reflect actual PvP flags on player targets.
        isFlagged = isFFA or (UnitIsPlayer(unit) and UnitIsPVP(unit))
    end
    if isFlagged then
        frame.pvpFlagText:SetText(labelText)
        if timerMode then
            frame.pvpFlagText:SetTextColor(1, 1, 1, 1)
        else
            frame.pvpFlagText:SetTextColor(textR, textG, textB, 1)
        end
        frame.pvpFlagText:Show()
    else
        frame.pvpFlagText:Hide()
    end
end

-- CAST BAR (Player, Target, Focus)
--------------------------------------------------

local function CreateCastBar(frame, unit)
    local settingKey = (unit == "player" and "showPlayerCastBar")
        or (unit == "target" and "showTargetCastBar")
        or (unit == "focus" and "showFocusCastBar")
        or "showTargetCastBar"
    local showCastBar = MattMinimalFramesDB and MattMinimalFramesDB[settingKey]
    if showCastBar == nil then
        showCastBar = true
    end
    if not showCastBar then return end
    
    frame.castBarFrame = CreateFrame("Frame", nil, frame)
    frame.castBarFrame:SetFrameLevel(frame.healthBar:GetFrameLevel() + 5)
    frame.castBarFrame:SetMovable(true)
    frame.castBarFrame:EnableMouse(true)
    frame.castBarFrame:RegisterForDrag("LeftButton")
    frame.castBarFrame:SetHeight(8)
    
    frame.castBarBG = frame.castBarFrame:CreateTexture(nil, "BACKGROUND")
    frame.castBarBG:SetAllPoints(frame.castBarFrame)
    frame.castBarBG:SetColorTexture(0, 0, 0, 0.5)

    frame.castBarBorder = frame.castBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.castBarBorder:SetPoint("TOPLEFT", frame.castBarFrame, "TOPLEFT", -1, 1)
    frame.castBarBorder:SetPoint("BOTTOMRIGHT", frame.castBarFrame, "BOTTOMRIGHT", 1, -1)
    frame.castBarBorder:SetColorTexture(0, 0, 0, 1)

    frame.castBar = CreateFrame("StatusBar", nil, frame.castBarFrame)
    frame.castBar:SetAllPoints(frame.castBarFrame)
    frame.castBar:SetMinMaxValues(0, 1)
    frame.castBar:SetValue(0)
    frame.castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.castBar:SetStatusBarColor(1, 1, 1, 1)
    
    frame.castBarTextOverlay = CreateFrame("Frame", nil, frame.castBarFrame)
    frame.castBarTextOverlay:SetFrameLevel(frame.castBar:GetFrameLevel() + 2)
    frame.castBarTextOverlay:SetAllPoints(frame.castBarFrame)
    frame.castBarTextOverlay:EnableMouse(false)
    
    frame.castBarText = frame.castBarTextOverlay:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.castBarText, cfg.FONT_PATH, 9, "OUTLINE")
    else
        frame.castBarText:SetFont(cfg.FONT_PATH, 9, "OUTLINE")
    end
    frame.castBarText:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.castBarText:SetWordWrap(false)
    
    frame.castBarTime = frame.castBarTextOverlay:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.castBarTime, cfg.FONT_PATH, 9, "OUTLINE")
    else
        frame.castBarTime:SetFont(cfg.FONT_PATH, 9, "OUTLINE")
    end
    frame.castBarTime:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.castBarTime:SetWordWrap(false)
    frame.castBarTime:SetPoint("RIGHT", frame.castBarTextOverlay, "RIGHT", -3, 0)
    frame.castBarTime:SetJustifyH("RIGHT")
    frame.castBarTime:SetWidth(36)
    
    frame.castBarText:SetPoint("LEFT", frame.castBarTextOverlay, "LEFT", 3, 0)
    frame.castBarText:SetPoint("RIGHT", frame.castBarTime, "LEFT", -4, 0)
    frame.castBarText:SetJustifyH("LEFT")

    ApplyCastBarPosition(frame, unit)

    frame.castBarFrame:SetScript("OnDragStart", function(self)
        if CanStartFrameDrag(self) then
            self:StartMoving()
        end
    end)

    frame.castBarFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveCastBarPosition(frame, unit)
    end)

    frame.castBarFrame:SetScript("OnEnter", function(self)
        if CanStartFrameDrag(self) then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Cast Bar", 1, 1, 1)
            GameTooltip:AddLine(GetDragHintText(), 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end
    end)
    frame.castBarFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.castBarFrame:Hide()
    
    frame.castInfo = {
        casting = false,
        channeling = false,
        castID = nil,  
        startTimeMs = nil,  -- TBC only: from UnitCastingInfo/UnitChannelInfo (ms)
        endTimeMs = nil,    -- TBC only
    }

    local function SetCastTimeText(seconds)
        if frame.castBarTime then
            if NotSecretValue(seconds) and type(seconds) == "number" and seconds > 0 then
                frame.castBarTime:SetFormattedText("%.1f", seconds)
                return true
            else
                frame.castBarTime:SetText("")
                return false
            end
        end
        return false
    end

    local function GetSafeRemainingSeconds(endTimeMs)
        if not NotSecretValue(endTimeMs) or type(endTimeMs) ~= "number" then
            return nil
        end
        return (endTimeMs / 1000) - GetTime()
    end

    local function ShowCastBar(spellName, notInterruptible, startTimeMs, endTimeMs)
        local r, g, b = MMF_Config.GetCastBarColor(MattMinimalFramesDB and MattMinimalFramesDB.castBarColor or "yellow")
        if unit == "target" then
            frame.castBar:SetStatusBarColor(r, g, b, 1)
        else
            local isUninterruptible = (NotSecretValue(notInterruptible) and notInterruptible == true)
            if isUninterruptible then
                frame.castBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
            else
                frame.castBar:SetStatusBarColor(r, g, b, 1)
            end
        end
        if spellName then
            local ok = pcall(function() frame.castBarText:SetText(spellName) end)
            if not ok then frame.castBarText:SetText("") end
        else
            frame.castBarText:SetText("")
        end
        if Compat.IsTBC then
            SetCastTimeText(GetSafeRemainingSeconds(endTimeMs))
        else
            SetCastTimeText(nil)
        end
        if Compat.IsTBC and startTimeMs and endTimeMs then
            frame.castInfo.startTimeMs = startTimeMs
            frame.castInfo.endTimeMs = endTimeMs
            local maxVal = (endTimeMs - startTimeMs) / 1000
            frame.castBar:SetMinMaxValues(0, maxVal)
            if frame.castInfo.casting then
                frame.castBar:SetValue(GetTime() - startTimeMs / 1000)
            else
                frame.castBar:SetValue(endTimeMs / 1000 - GetTime())
            end
        end
        frame.castBarFrame:Show()
    end
    
    local function HideCastBar()
        frame.castInfo.casting = false
        frame.castInfo.channeling = false
        frame.castInfo.startTimeMs = nil
        frame.castInfo.endTimeMs = nil
        SetCastTimeText(nil)
        frame.castBarFrame:Hide()
    end
    
    -- OnUpdate: TBC uses manual timing (no SetTimerDuration/UnitCastingDuration); Retail uses SetTimerDuration
    if Compat.IsTBC then
        frame.castBarFrame:SetScript("OnUpdate", function(self, elapsed)
            local info = frame.castInfo
            if info.casting and info.startTimeMs and info.endTimeMs then
                local now = GetTime()
                local startSec = info.startTimeMs / 1000
                local endSec = info.endTimeMs / 1000
                local maxVal = endSec - startSec
                local val = now - startSec
                if val >= maxVal then
                    frame.castBar:SetMinMaxValues(0, maxVal)
                    frame.castBar:SetValue(maxVal)
                    HideCastBar()
                    return
                end
                frame.castBar:SetMinMaxValues(0, maxVal)
                frame.castBar:SetValue(val)
                SetCastTimeText(maxVal - val)
            elseif info.channeling and info.startTimeMs and info.endTimeMs then
                local now = GetTime()
                local endSec = info.endTimeMs / 1000
                local startSec = info.startTimeMs / 1000
                local maxVal = endSec - startSec
                local val = endSec - now
                if val <= 0 then
                    HideCastBar()
                    return
                end
                frame.castBar:SetMinMaxValues(0, maxVal)
                frame.castBar:SetValue(val)
                SetCastTimeText(val)
            end
        end)
    else
        local StatusBarTimerDirection = Enum.StatusBarTimerDirection
        local StatusBarInterpolation = Enum.StatusBarInterpolation
        local function GetRemainingFromDurationObject(durationObject)
            if durationObject and durationObject.GetRemainingDuration then
                local ok, remaining = pcall(durationObject.GetRemainingDuration, durationObject)
                if ok and type(remaining) == "number" and NotSecretValue(remaining) then
                    return remaining
                end
            end
        end
        frame.castBarFrame:SetScript("OnUpdate", function(self, elapsed)
            local info = frame.castInfo
            if info.casting then
                local name = UnitCastingInfo(unit)
                if not name then
                    HideCastBar()
                    return
                end
                local duration = UnitCastingDuration(unit)
                if duration then
                    frame.castBar:SetTimerDuration(duration, StatusBarInterpolation.Immediate, StatusBarTimerDirection.ElapsedTime)
                    SetCastTimeText(GetRemainingFromDurationObject(duration))
                else
                    SetCastTimeText(nil)
                end
            elseif info.channeling then
                local name = UnitChannelInfo(unit)
                if not name then
                    HideCastBar()
                    return
                end
                local duration = UnitChannelDuration(unit)
                if duration then
                    frame.castBar:SetTimerDuration(duration, StatusBarInterpolation.Immediate, StatusBarTimerDirection.RemainingTime)
                    SetCastTimeText(GetRemainingFromDurationObject(duration))
                else
                    SetCastTimeText(nil)
                end
            end
        end)
    end

    -- Create a separate event frame to avoid conflicts
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    if unit == "target" then
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif unit == "focus" then
        eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end
    if Compat.IsTBC then
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", unit)
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)
    end
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
            local name, _, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
            if name then
                frame.castInfo.casting = true
                frame.castInfo.channeling = false
                frame.castInfo.castID = (unit == "player" and NotSecretValue(castID) and castID) or nil
                ShowCastBar(name, notInterruptible, startTime, endTime)
                return
            end
            name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
            if name then
                frame.castInfo.casting = false
                frame.castInfo.channeling = true
                frame.castInfo.castID = nil
                ShowCastBar(name, notInterruptible, startTime, endTime)
                return
            end
            HideCastBar()
            
        elseif event == "UNIT_SPELLCAST_START" then
            local name, _, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
            if name then
                frame.castInfo.casting = true
                frame.castInfo.channeling = false
                frame.castInfo.castID = (unit == "player" and NotSecretValue(castID) and castID) or nil
                ShowCastBar(name, notInterruptible, startTime, endTime)
            end
            
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            -- TBC: name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID
            local name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
            if name then
                frame.castInfo.casting = false
                frame.castInfo.channeling = true
                frame.castInfo.castID = nil
                ShowCastBar(name, notInterruptible, startTime, endTime)
            end
        
        elseif Compat.IsTBC and event == "UNIT_SPELLCAST_DELAYED" then
            if frame.castInfo.casting then
                local name, _, _, startTime, endTime = UnitCastingInfo(unit)
                if name and startTime and endTime then
                    frame.castInfo.startTimeMs = startTime
                    frame.castInfo.endTimeMs = endTime
                end
            end
        
        elseif Compat.IsTBC and event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
            if frame.castInfo.channeling then
                local name, _, _, startTime, endTime = UnitChannelInfo(unit)
                if name and startTime and endTime then
                    frame.castInfo.startTimeMs = startTime
                    frame.castInfo.endTimeMs = endTime
                end
            end
            
        elseif event == "UNIT_SPELLCAST_STOP" then
            if not frame.castInfo.casting then return end
            -- For target, castID is secret - use API instead of comparing
            if unit == "target" then
                if not UnitCastingInfo(unit) then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            else
                local _, eventCastID = ...
                if NotSecretValue(eventCastID) and NotSecretValue(frame.castInfo.castID) and eventCastID == frame.castInfo.castID then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            end
            
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            if frame.castInfo.channeling then
                frame.castInfo.channeling = false
                HideCastBar()
            end
            
        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            if not frame.castInfo.casting then return end
            if unit == "target" then
                if not UnitCastingInfo(unit) then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            else
                local _, eventCastID = ...
                if NotSecretValue(eventCastID) and NotSecretValue(frame.castInfo.castID) and eventCastID == frame.castInfo.castID then
                    frame.castInfo.casting = false
                    frame.castInfo.castID = nil
                    HideCastBar()
                end
            end
            
        end
    end)
end

--------------------------------------------------
-- MAIN FRAME CREATION
--------------------------------------------------

function MMF_CreateSecureUnitFrame(unit, frameName, width, height, point, relPoint, xOfs, yOfs)
    local unitButtonTemplate = "SecureUnitButtonTemplate"
    if Compat and Compat.IsRetail then
        unitButtonTemplate = "SecureUnitButtonTemplate, PingableUnitFrameTemplate"
    end

    local ok, f = pcall(CreateFrame, "Button", frameName, UIParent, unitButtonTemplate)
    if not ok or not f then
        f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")
    end
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForClicks("AnyUp")
    f:RegisterForDrag("LeftButton")
    f:SetSize(width, height)
    f.originalWidth = width
    f.originalHeight = height
    f.unit = unit

    MMF_ResetSecureAttributes(f)
    CreateTooltipHandlers(f)
    RestoreFramePosition(f, frameName, point, relPoint, xOfs, yOfs)
    CreateDragHandlers(f, frameName)
    CreateHealthBar(f)

    if unit == "player" or unit == "target" then
        CreatePowerBarContainer(f, unit)
    end

    if unit == "player" or unit == "target" or unit == "targettarget" then
        CreateHealPredictionBar(f)
        CreateAbsorbBar(f)
    end

    f.highlightTexture = f:CreateTexture(nil, "OVERLAY")
    f.highlightTexture:SetAllPoints(f)
    f.highlightTexture:SetColorTexture(1, 1, 1, 0.15)
    f.highlightTexture:Hide()

    CreateNameText(f, unit)
    CreateResourceText(f, unit)
    CreatePVPFlagIndicator(f, unit)
    CreateTargetMarker(f)

    if unit == "player" or unit == "target" then
        SetupPowerBar(f, unit)
    end

    if unit == "player" then
        CreatePlayerClassIcon(f)
        CreatePlayerIndicators(f)
    elseif unit == "target" then
        CreateTargetFrameIcon(f)
    end

    if unit == "player" or unit == "target" or unit == "focus" then
        CreateCastBar(f, unit)
    end

    return f
end

local originalCreate = MMF_CreateSecureUnitFrame
MMF_CreateSecureUnitFrame = function(...)
    local frame = originalCreate(...)
    
    if frame.powerBarFrame then
        local showPowerBar = true
        if frame.unit == "player" then
            showPowerBar = not (MattMinimalFramesDB and MattMinimalFramesDB.showPlayerPowerBar == false)
        elseif frame.unit == "target" then
            showPowerBar = (MattMinimalFramesDB and MattMinimalFramesDB.showTargetPowerBar ~= false)
        end
        frame.powerBarFrame:SetShown(showPowerBar)
        if frame.powerText then
            frame.powerText:Hide()
        end
        if frame.powerTextDragFrame then
            frame.powerTextDragFrame:Hide()
        end
    end
    
    return frame
end

function MMF_SetGUIScale(scale)
    local normalized = (MMF_ClampGUIScale and MMF_ClampGUIScale(scale)) or scale
    if MattMinimalFramesDB then
        MattMinimalFramesDB.guiScale = normalized
    end
    if MMF_WelcomePopup then
        if MMF_WelcomePopup.ApplyGUIScale then
            MMF_WelcomePopup:ApplyGUIScale(normalized, true)
        else
            MMF_WelcomePopup:SetScale(normalized)
        end
    end
end

function MMF_UpdatePlayerClassIconVisibility(enabled)
    if not MMF_PlayerFrame or not MMF_PlayerFrame.classIcon then return end
    local mode = enabled
    if type(mode) == "boolean" then
        mode = mode and "class" or "off"
    end
    if mode == nil then
        mode = GetPlayerFrameIconMode()
    end
    if mode ~= "off" and mode ~= "class" and mode ~= "portrait" and mode ~= "sharedmedia" and mode ~= "jiberish" then
        mode = "off"
    end
    if MattMinimalFramesDB then
        MattMinimalFramesDB.playerFrameIconMode = mode
        MattMinimalFramesDB.showPlayerClassIcon = (mode == "class")
    end
    ApplyPlayerFrameIconMode(MMF_PlayerFrame, mode)
end

function MMF_GetPlayerFrameIconMode()
    return GetPlayerFrameIconMode()
end

function MMF_UpdateTargetFrameIconVisibility(enabled)
    if not MMF_TargetFrame or not MMF_TargetFrame.targetIcon then return end
    local mode = enabled
    if type(mode) == "boolean" then
        mode = mode and "class" or "off"
    end
    if mode == nil then
        mode = GetTargetFrameIconMode()
    end
    if mode ~= "off" and mode ~= "class" and mode ~= "portrait" and mode ~= "sharedmedia" and mode ~= "jiberish" then
        mode = "off"
    end
    if MattMinimalFramesDB then
        MattMinimalFramesDB.targetFrameIconMode = mode
        MattMinimalFramesDB.showTargetFrameIcon = (mode == "class")
    end
    ApplyTargetFrameIconMode(MMF_TargetFrame, mode)
end

function MMF_GetTargetFrameIconMode()
    return GetTargetFrameIconMode()
end

function MMF_UpdateTargetMarkers()
    local frames = MMF_GetAllFrames and MMF_GetAllFrames() or {}
    for _, frame in ipairs(frames) do
        UpdateFrameTargetMarker(frame)
    end
end

function MMF_UpdateTargetMarkerVisibility(enabled)
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    if enabled == nil then
        enabled = MattMinimalFramesDB.showTargetMarkers == true
    end
    MattMinimalFramesDB.showTargetMarkers = enabled and true or false
    MMF_UpdateTargetMarkers()
end

function MMF_UpdatePVPFlagIndicator(frame)
    UpdatePVPFlagIndicator(frame)
end

function MMF_ApplyFrameIconPlacement(frame)
    ApplyFrameIconPlacement(frame)
end

function MMF_UpdateFrameIconPlacement(unit)
    if unit == "player" then
        ApplyFrameIconPlacement(MMF_PlayerFrame)
        if MMF_UpdatePlayerClassIconVisibility then
            MMF_UpdatePlayerClassIconVisibility(GetPlayerFrameIconMode())
        end
        return
    elseif unit == "target" then
        ApplyFrameIconPlacement(MMF_TargetFrame)
        if MMF_UpdateTargetFrameIconVisibility then
            MMF_UpdateTargetFrameIconVisibility(GetTargetFrameIconMode())
        end
        return
    end

    ApplyFrameIconPlacement(MMF_PlayerFrame)
    ApplyFrameIconPlacement(MMF_TargetFrame)
    if MMF_UpdatePlayerClassIconVisibility then
        MMF_UpdatePlayerClassIconVisibility(GetPlayerFrameIconMode())
    end
    if MMF_UpdateTargetFrameIconVisibility then
        MMF_UpdateTargetFrameIconVisibility(GetTargetFrameIconMode())
    end
end

do
    local iconEventFrame = CreateFrame("Frame")
    iconEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    iconEventFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
    iconEventFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "target")
    iconEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    iconEventFrame:SetScript("OnEvent", function(_, _, unit)
        if (not unit or unit == "player") and MMF_GetPlayerFrameIconMode and MMF_GetPlayerFrameIconMode() ~= "off" then
            MMF_UpdatePlayerClassIconVisibility(MMF_GetPlayerFrameIconMode())
        end
        if (not unit or unit == "target") and MMF_GetTargetFrameIconMode and MMF_GetTargetFrameIconMode() ~= "off" then
            MMF_UpdateTargetFrameIconVisibility(MMF_GetTargetFrameIconMode())
        end
    end)
end

do
    local markerEventFrame = CreateFrame("Frame")
    markerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    markerEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    markerEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    markerEventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    markerEventFrame:RegisterEvent("UNIT_TARGET")
    markerEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    markerEventFrame:SetScript("OnEvent", function()
        if MMF_UpdateTargetMarkers then
            MMF_UpdateTargetMarkers()
        end
    end)
end
