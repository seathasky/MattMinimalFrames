local function CreatePowerBarContainer(frame, unit)
    local deps = _G.MMF_FrameFactoryPowerBarDeps or {}
    local GetStatusBarTexturePath = deps.GetStatusBarTexturePath or MMF_GetStatusBarTexturePath

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
    local deps = _G.MMF_FrameFactoryPowerBarDeps or {}
    local cfg = deps.cfg or MMF_Config or {}
    local CanStartFrameDrag = deps.CanStartFrameDrag
    local TryStopFrameMoving = deps.TryStopFrameMoving
    local GetDragHintText = deps.GetDragHintText

    local defaultWidth = cfg.POWER_BAR_WIDTH
    local defaultHeight = cfg.POWER_BAR_HEIGHT
    if unit == "player" then
        defaultWidth = (MattMinimalFramesDB and (MattMinimalFramesDB.playerPowerBarWidth or MattMinimalFramesDB.powerBarWidth)) or defaultWidth
        defaultHeight = (MattMinimalFramesDB and (MattMinimalFramesDB.playerPowerBarHeight or MattMinimalFramesDB.powerBarHeight)) or defaultHeight
    elseif unit == "target" then
        defaultWidth = (MattMinimalFramesDB and (MattMinimalFramesDB.targetPowerBarWidth or MattMinimalFramesDB.powerBarWidth)) or defaultWidth
        defaultHeight = (MattMinimalFramesDB and (MattMinimalFramesDB.targetPowerBarHeight or MattMinimalFramesDB.powerBarHeight)) or defaultHeight
    else
        defaultWidth = (MattMinimalFramesDB and MattMinimalFramesDB.powerBarWidth) or defaultWidth
        defaultHeight = (MattMinimalFramesDB and MattMinimalFramesDB.powerBarHeight) or defaultHeight
    end
    local defaultVOffset = cfg.POWER_BAR_VERTICAL_OFFSET
    local defaultHOffset = cfg.POWER_BAR_HORIZONTAL_OFFSET

    frame.powerBarFrame:SetSize(defaultWidth + 2, defaultHeight + 2)
    frame.powerBarFrame:SetMovable(true)
    frame.powerBarFrame:EnableMouse(true)
    frame.powerBarFrame:RegisterForDrag("LeftButton")

    if unit == "player" then
        frame.powerBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -defaultHOffset, defaultVOffset)
    else
        frame.powerBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", defaultHOffset, defaultVOffset)
    end

    frame.powerBarFrame:SetScript("OnDragStart", function(self)
        if CanStartFrameDrag and CanStartFrameDrag(self) then
            self:StartMoving()
        end
    end)

    frame.powerBarFrame:SetScript("OnDragStop", function(self)
        if not TryStopFrameMoving or not TryStopFrameMoving(self) then
            return
        end
        local x, y = self:GetCenter()
        local px, py = frame:GetCenter()
        if not MattMinimalFramesDB.powerBarPositions then
            MattMinimalFramesDB.powerBarPositions = {}
        end
        MattMinimalFramesDB.powerBarPositions[unit] = { x = x - px, y = y - py }
    end)

    frame.powerBarFrame:SetScript("OnEnter", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        if unit == "player" then
            GameTooltip:SetText("Player Power Bar", 1, 1, 1)
        else
            GameTooltip:SetText("Target Power Bar", 1, 1, 1)
        end
        GameTooltip:AddLine(GetDragHintText and GetDragHintText() or "Shift+Drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    frame.powerBarFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.powerBarBorder = frame.powerBarFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.powerBarBorder:SetColorTexture(0, 0, 0, 0.5)
    frame.powerBarBorder:SetAllPoints()

    frame.powerBarBG:SetHeight(defaultHeight)
    frame.powerBarBG:SetWidth(defaultWidth)
    frame.powerBarBG:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)

    frame.powerBar:SetHeight(defaultHeight)
    frame.powerBar:SetWidth(defaultWidth)
    frame.powerBar:SetPoint("CENTER", frame.powerBarBorder, "CENTER", 0, 0)
    frame.powerBar:SetAlpha(0.5)

    if MattMinimalFramesDB and MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit] then
        local pos = MattMinimalFramesDB.powerBarPositions[unit]
        frame.powerBarFrame:ClearAllPoints()
        frame.powerBarFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
    end
end

_G.MMF_FrameFactoryPowerBar = {
    CreatePowerBarContainer = CreatePowerBarContainer,
    SetupPowerBar = SetupPowerBar,
}
