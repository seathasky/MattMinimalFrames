local cfg = MMF_Config or {}
local DragHelpers = _G.MMF_FrameFactoryDragHelpers or {}
local TextPositionUtils = _G.MMF_FrameFactoryTextPositions or {}

local function CanStartFrameDrag(frame)
    if DragHelpers.CanStartFrameDrag then
        return DragHelpers.CanStartFrameDrag(frame)
    end
    return false
end

local function TryStopFrameMoving(frame)
    if DragHelpers.TryStopFrameMoving then
        return DragHelpers.TryStopFrameMoving(frame)
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
        frame.hpTextDragFrame = CreateFrame("Frame", nil, frame.nameOverlay)
        frame.hpTextDragFrame:SetFrameLevel(frame.nameOverlay:GetFrameLevel() + 1)
        frame.hpTextDragFrame:SetSize(1, 1)
        if frame.hpTextDragFrame.SetHitRectInsets then
            frame.hpTextDragFrame:SetHitRectInsets(-42, -42, -9, -9)
        end
        frame.hpTextDragFrame:SetMovable(true)
        frame.hpTextDragFrame:EnableMouse(true)
        frame.hpTextDragFrame:RegisterForDrag("LeftButton")

        frame.hpTextDragFrame:SetScript("OnDragStart", function(self)
            if CanStartFrameDrag(self) then
                self:StartMoving()
            end
        end)

        frame.hpTextDragFrame:SetScript("OnDragStop", function(self)
            if not TryStopFrameMoving(self) then
                return
            end
            local left = self:GetLeft()
            local right = self:GetRight()
            local bottom = self:GetBottom()
            local frameLeft = frame:GetLeft()
            local frameRight = frame:GetRight()
            local frameBottom = frame:GetBottom()
            if not left or not right or not bottom or not frameLeft or not frameRight or not frameBottom then
                return
            end

            local anchorPoint = GetHPTextAttachPoint(unit)
            local x
            if anchorPoint == "BOTTOMRIGHT" then
                x = right - frameRight
            else
                x = left - frameLeft
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
        end)

        frame.hpTextDragFrame:SetScript("OnEnter", function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            if unit == "player" then
                GameTooltip:SetText("Player HP Text", 1, 1, 1)
            else
                GameTooltip:SetText("Target HP Text", 1, 1, 1)
            end
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
        frame.powerTextDragFrame:EnableMouse(true)
        frame.powerTextDragFrame:RegisterForDrag("LeftButton")

        frame.powerTextDragFrame:SetScript("OnDragStart", function(self)
            if CanStartFrameDrag(self) then
                self.mmfDragInProgress = true
                self:StartMoving()
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

