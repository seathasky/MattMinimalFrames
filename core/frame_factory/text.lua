local cfg = MMF_Config or {}
local DragHelpers = _G.MMF_FrameFactoryDragHelpers or {}
local TextPositionUtils = _G.MMF_FrameFactoryTextPositions or {}

local function CanStartFrameDrag(frame, allowTextMoveMode)
    if DragHelpers.CanStartFrameDrag then
        return DragHelpers.CanStartFrameDrag(frame, allowTextMoveMode)
    end
    return false
end

local function TryStopFrameMoving(frame)
    if DragHelpers.TryStopFrameMoving then
        return DragHelpers.TryStopFrameMoving(frame)
    end
    return false
end

local function TryBeginFrameMoving(frame, ownerName, allowTextMoveMode)
    if DragHelpers.TryBeginFrameMoving then
        return DragHelpers.TryBeginFrameMoving(frame, ownerName, allowTextMoveMode)
    end
    if CanStartFrameDrag(frame, allowTextMoveMode) then
        frame:StartMoving()
        return true
    end
    return false
end

local function GetDragHintText()
    if DragHelpers.GetDragHintText then
        return DragHelpers.GetDragHintText()
    end
    return "Shift+Drag to move"
end

local function GetHPTextAttachPoint(unit)
    if TextPositionUtils.GetHPTextAttachPoint then
        return TextPositionUtils.GetHPTextAttachPoint(unit)
    end
    if unit == "player" then
        return "BOTTOMRIGHT"
    elseif unit == "target" then
        return "BOTTOMLEFT"
    elseif unit == "targettarget"
        or unit == "pet"
        or unit == "focus"
        or unit == "boss1"
        or unit == "boss2"
        or unit == "boss3"
        or unit == "boss4"
        or unit == "boss5"
    then
        return "BOTTOM"
    end
    return "BOTTOMRIGHT"
end

local function PrepareTextDrag(frame, text, handle)
    if not frame or not text or not handle then
        return
    end

    local textX, textY = text:GetCenter()
    local frameX, frameY = frame:GetCenter()
    if not textX or not textY or not frameX or not frameY then
        return
    end

    handle:ClearAllPoints()
    handle:SetPoint("CENTER", frame, "CENTER", textX - frameX, textY - frameY)
    text:ClearAllPoints()
    text:SetPoint("CENTER", handle, "CENTER", 0, 0)
    if text.SetJustifyH then
        text:SetJustifyH("CENTER")
    end
end

local NAME_TEXT_DEFAULTS = {
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

local function ApplyNameTextPosition(frame, unit)
    if not frame or not frame.nameText then
        return
    end
    if frame.nameTextDragFrame and frame.nameTextDragFrame.mmfDragInProgress then
        return
    end

    local nameX = MMF_GetNameTextXOffset and MMF_GetNameTextXOffset(unit) or 0
    local nameY = MMF_GetNameTextYOffset and MMF_GetNameTextYOffset(unit) or 0
    local pos = NAME_TEXT_DEFAULTS[unit] or NAME_TEXT_DEFAULTS.focus
    local saved = MattMinimalFramesDB and MattMinimalFramesDB.nameTextPositions and MattMinimalFramesDB.nameTextPositions[unit]
    local hasCustomPosition = type(saved) == "table" and type(saved.x) == "number" and type(saved.y) == "number"

    frame.nameText:ClearAllPoints()
    if hasCustomPosition and frame.nameTextDragFrame then
        frame.nameTextDragFrame:ClearAllPoints()
        frame.nameTextDragFrame:SetPoint("CENTER", frame, "CENTER", saved.x, saved.y)
        frame.nameText:SetPoint("CENTER", frame.nameTextDragFrame, "CENTER", 0, 0)
        frame.nameText:SetJustifyH("CENTER")
        return
    end

    if MMF_IsNameTextAnchorEnabled and MMF_IsNameTextAnchorEnabled(unit) then
        local preset = MMF_GetTextAnchorPreset and MMF_GetTextAnchorPreset(MMF_GetNameTextAnchorPoint(unit))
        preset = preset or { point = "TOP", relPoint = "TOP", x = 0, y = -2, justify = "CENTER" }
        if frame.nameTextDragFrame then
            frame.nameTextDragFrame:ClearAllPoints()
            frame.nameTextDragFrame:SetPoint(preset.point, frame, preset.relPoint, preset.x, preset.y)
        end
        frame.nameText:SetPoint(preset.point, frame, preset.relPoint, preset.x, preset.y)
        frame.nameText:SetJustifyH(preset.justify or "CENTER")
        return
    end

    if frame.nameTextDragFrame then
        frame.nameTextDragFrame:ClearAllPoints()
        frame.nameTextDragFrame:SetPoint(pos.point, frame, pos.relPoint, pos.x + nameX, pos.y + nameY)
    end
    frame.nameText:SetPoint(pos.point, frame, pos.relPoint, pos.x + nameX, pos.y + nameY)
    frame.nameText:SetJustifyH(pos.justify)
end

_G.MMF_ApplyNameTextPosition = ApplyNameTextPosition

_G.MMF_ApplyNameTextPositions = function()
    if not MMF_GetAllFrames then
        return
    end
    for _, frame in ipairs(MMF_GetAllFrames()) do
        ApplyNameTextPosition(frame, frame.unit)
    end
end

local function CreateNameText(frame, unit)
    local fontPath = cfg.FONT_PATH
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"

    frame.nameOverlay = CreateFrame("Frame", nil, frame)
    frame.nameOverlay:SetAllPoints(frame)
    frame.nameOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)

    frame.nameText = frame.nameOverlay:CreateFontString(nil, "OVERLAY", nil, 7)

    local fontSize = MMF_GetNameTextSize(unit)
    local nameX = MMF_GetNameTextXOffset and MMF_GetNameTextXOffset(unit) or 0
    local nameY = MMF_GetNameTextYOffset and MMF_GetNameTextYOffset(unit) or 0
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.nameText, fontPath, fontSize, fontFlags)
    else
        frame.nameText:SetFont(fontPath, fontSize, fontFlags)
    end
    frame.nameText:SetTextColor(1, 1, 1, 1)
    if MMF_ApplyGlobalTextShadow then
        MMF_ApplyGlobalTextShadow(frame.nameText)
    end

    frame.nameTextDragFrame = CreateFrame("Frame", nil, frame.nameOverlay)
    frame.nameTextDragFrame:SetFrameLevel(frame.nameOverlay:GetFrameLevel() + 1)
    frame.nameTextDragFrame:SetSize(math.max(40, (frame.originalWidth or frame:GetWidth() or 84) - 4), 18)
    frame.nameTextDragFrame:SetMovable(true)
    frame.nameTextDragFrame:EnableMouse(false)
    frame.nameTextDragFrame:RegisterForDrag("LeftButton")
    frame.nameTextDragFrame:SetScript("OnDragStart", function(self)
        local started = TryBeginFrameMoving(self, unit .. " name text", true)
        self.mmfDragInProgress = started or nil
        if started then
            PrepareTextDrag(frame, frame.nameText, self)
        end
    end)
    frame.nameTextDragFrame:SetScript("OnDragStop", function(self)
        if not TryStopFrameMoving(self) then
            self.mmfDragInProgress = nil
            return
        end
        local x, y = self:GetCenter()
        local frameX, frameY = frame:GetCenter()
        if not x or not y or not frameX or not frameY then
            self.mmfDragInProgress = nil
            return
        end
        MattMinimalFramesDB = MattMinimalFramesDB or {}
        MattMinimalFramesDB.nameTextPositions = MattMinimalFramesDB.nameTextPositions or {}
        MattMinimalFramesDB.nameTextPositions[unit] = { x = x - frameX, y = y - frameY }
        self.mmfDragInProgress = nil
        ApplyNameTextPosition(frame, unit)
        if MMF_RefreshEditModeTextPositionList then
            MMF_RefreshEditModeTextPositionList()
        end
    end)
    frame.nameTextDragFrame:SetScript("OnEnter", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetText((unit == "targettarget" and "Target of Target" or unit:gsub("^%l", string.upper)) .. " Name Text", 1, 1, 1)
        GameTooltip:AddLine(GetDragHintText(), 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    frame.nameTextDragFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ApplyNameTextPosition(frame, unit)
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
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"
    local hpSize = MMF_GetHPTextSize and MMF_GetHPTextSize(unit) or 13

    -- Match the name text's draw sublevel so the glyph outline stays above
    -- borders and status-bar artwork on compact frames such as ToT and focus.
    frame.hpText = frame.nameOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.hpText, fontPath, hpSize, fontFlags)
    else
        frame.hpText:SetFont(fontPath, hpSize, fontFlags)
    end
    frame.hpText:SetTextColor(1, 1, 1)
    if MMF_ApplyGlobalTextShadow then
        MMF_ApplyGlobalTextShadow(frame.hpText)
    end

    frame.powerText = frame.nameOverlay:CreateFontString(nil, "OVERLAY")
    if MMF_SetFontSafe then
        MMF_SetFontSafe(frame.powerText, fontPath, 13, fontFlags)
    else
        frame.powerText:SetFont(fontPath, 13, fontFlags)
    end
    frame.powerText:SetTextColor(1, 1, 1)
    if MMF_ApplyGlobalTextShadow then
        MMF_ApplyGlobalTextShadow(frame.powerText)
    end

    do
        frame.hpTextDragFrame = CreateFrame("Frame", nil, frame.nameOverlay)
        frame.hpTextDragFrame:SetFrameLevel(frame.nameOverlay:GetFrameLevel() + 1)
        frame.hpTextDragFrame:SetSize(84, 18)
        if frame.hpTextDragFrame.SetHitRectInsets then
            frame.hpTextDragFrame:SetHitRectInsets(0, 0, 0, 0)
        end
        frame.hpTextDragFrame:SetMovable(true)
        frame.hpTextDragFrame:EnableMouse(false)
        frame.hpTextDragFrame:RegisterForDrag("LeftButton")

        frame.hpTextDragFrame:SetScript("OnDragStart", function(self)
            local started = TryBeginFrameMoving(self, unit .. " hp text", true)
            self.mmfDragInProgress = started or nil
        end)

        frame.hpTextDragFrame:SetScript("OnDragStop", function(self)
            if not TryStopFrameMoving(self) then
                self.mmfDragInProgress = nil
                return
            end
            local left = self:GetLeft()
            local right = self:GetRight()
            local bottom = self:GetBottom()
            local frameLeft = frame:GetLeft()
            local frameRight = frame:GetRight()
            local center = self:GetCenter()
            local frameCenter = frame:GetCenter()
            local frameBottom = frame:GetBottom()
            if not left or not right or not bottom or not frameLeft or not frameRight or not center or not frameCenter or not frameBottom then
                self.mmfDragInProgress = nil
                return
            end

            local anchorPoint = GetHPTextAttachPoint(unit)
            local x
            if anchorPoint == "BOTTOMRIGHT" then
                x = right - frameRight
            elseif anchorPoint == "BOTTOMLEFT" then
                x = left - frameLeft
            else
                x = center - frameCenter
            end
            local y = bottom - frameBottom
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            if not MattMinimalFramesDB.hpTextPositions then
                MattMinimalFramesDB.hpTextPositions = {}
            end
            MattMinimalFramesDB.hpTextPositions[unit] = {
                mode = "edge",
                x = x,
                y = y,
            }
            self.mmfDragInProgress = nil
            if MMF_RefreshEditModeTextPositionList then
                MMF_RefreshEditModeTextPositionList()
            end
        end)

        frame.hpTextDragFrame:SetScript("OnEnter", function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetText((unit == "targettarget" and "Target of Target" or unit:gsub("^%l", string.upper)) .. " HP Text", 1, 1, 1)
            GameTooltip:AddLine(GetDragHintText(), 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)

        frame.hpTextDragFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.hpTextDragFrame:Hide()

        frame.powerTextDragFrame = CreateFrame("Frame", nil, frame.nameOverlay)
        frame.powerTextDragFrame:SetFrameLevel(frame.nameOverlay:GetFrameLevel() + 1)
        frame.powerTextDragFrame:SetSize(84, 18)
        frame.powerTextDragFrame:SetMovable(true)
        frame.powerTextDragFrame:EnableMouse(false)
        frame.powerTextDragFrame:RegisterForDrag("LeftButton")

        frame.powerTextDragFrame:SetScript("OnDragStart", function(self)
            if TryBeginFrameMoving(self, unit .. " power text", true) then
                self.mmfDragInProgress = true
                if unit ~= "player" and unit ~= "target" then
                    PrepareTextDrag(frame, frame.powerText, self)
                end
            end
        end)

        frame.powerTextDragFrame:SetScript("OnDragStop", function(self)
            if not TryStopFrameMoving(self) then
                self.mmfDragInProgress = nil
                return
            end
            local x, y = self:GetCenter()
            local px, py = frame:GetCenter()
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            if not MattMinimalFramesDB.powerTextPositions then
                MattMinimalFramesDB.powerTextPositions = {}
            end
            MattMinimalFramesDB.powerTextPositions[unit] = { x = x - px, y = y - py }
            self.mmfDragInProgress = nil
            if MMF_RefreshEditModeTextPositionList then
                MMF_RefreshEditModeTextPositionList()
            end
        end)

        frame.powerTextDragFrame:SetScript("OnEnter", function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetText((unit == "targettarget" and "Target of Target" or unit:gsub("^%l", string.upper)) .. " Power Text", 1, 1, 1)
            GameTooltip:AddLine(GetDragHintText(), 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)

        frame.powerTextDragFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.powerTextDragFrame:Hide()
    end

    if MMF_ApplyHPTextPosition then
        MMF_ApplyHPTextPosition(frame, unit)
    end
    if MMF_ApplyPowerTextPosition then
        MMF_ApplyPowerTextPosition(frame, unit)
    end
end

_G.MMF_FrameFactoryText = {
    CreateNameText = CreateNameText,
    CreateResourceText = CreateResourceText,
}

