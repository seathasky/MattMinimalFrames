function MMF_CreatePopupWindowController(config)
    config = config or {}

    local popup = config.popup
    local popupLayout = config.popupLayout or {}
    local minPopupWidth = config.minPopupWidth or popupLayout.width or 840
    local minPopupHeight = config.minPopupHeight or 400
    local maxPopupHeight = config.maxPopupHeight or 5000

    local function PersistPopupSize()
        if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
        MattMinimalFramesDB.popupSize = {
            width = math.floor((popup:GetWidth() or popupLayout.width or minPopupWidth) + 0.5),
            height = math.floor((popup:GetHeight() or popupLayout.height or minPopupHeight) + 0.5),
        }
    end

    local function GetParentBounds()
        local parentLeft = UIParent and (UIParent:GetLeft() or 0) or 0
        local parentRight = UIParent and UIParent:GetRight()
        if not parentRight and UIParent and UIParent.GetWidth then
            parentRight = parentLeft + (UIParent:GetWidth() or 0)
        end
        local parentBottom = UIParent and (UIParent:GetBottom() or 0) or 0
        local parentTop = UIParent and UIParent:GetTop()
        if not parentTop and UIParent and UIParent.GetHeight then
            parentTop = parentBottom + (UIParent:GetHeight() or 0)
        end
        return parentLeft, parentRight or parentLeft, parentBottom, parentTop or parentBottom
    end

    local function GetEffectiveScale(frame)
        local scale = frame and frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
        if not scale or scale <= 0 then
            return 1
        end
        return scale
    end

    local function GetPopupCenterInParentSpace(self)
        if not self or not UIParent then return nil, nil end
        local left = self:GetLeft()
        local right = self:GetRight()
        local top = self:GetTop()
        local bottom = self:GetBottom()
        if not left or not right or not top or not bottom then return nil, nil end

        -- Region coordinates use each frame's effective scale. Convert the
        -- popup center into UIParent's coordinate space before saving it.
        local popupScale = GetEffectiveScale(self)
        local parentScale = GetEffectiveScale(UIParent)
        local parentLeft, parentRight, parentBottom, parentTop = GetParentBounds()
        local popupCenterX = ((left + right) * 0.5) * popupScale
        local popupCenterY = ((top + bottom) * 0.5) * popupScale
        local parentCenterX = ((parentLeft + parentRight) * 0.5) * parentScale
        local parentCenterY = ((parentTop + parentBottom) * 0.5) * parentScale
        return (popupCenterX - parentCenterX) / parentScale,
            (popupCenterY - parentCenterY) / parentScale
    end

    local function GetDynamicMaxPopupHeight(self)
        local _, _, parentBottom, parentTop = GetParentBounds()
        local parentHeight = math.max(1, parentTop - parentBottom)
        local scale = (self and self.GetScale and self:GetScale()) or 1
        if scale <= 0 then
            scale = 1
        end
        local screenBoundMax = math.floor((parentHeight / scale) - 8)
        if screenBoundMax < minPopupHeight then
            screenBoundMax = minPopupHeight
        end
        return math.max(minPopupHeight, math.min(maxPopupHeight, screenBoundMax))
    end

    local function ClampPopupHeightToBounds(self)
        if not self then return end
        local current = self:GetHeight() or popupLayout.height or minPopupHeight
        local maxAllowed = GetDynamicMaxPopupHeight(self)
        local clamped = math.max(minPopupHeight, math.min(maxAllowed, current))
        if math.abs(clamped - current) > 0.5 then
            self:SetHeight(clamped)
        end
    end

    local function NormalizePopupAnchorToCenter(self)
        if not self or not UIParent then return nil, nil end
        local x, y = GetPopupCenterInParentSpace(self)
        if not x or not y then return nil, nil end
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", x, y)
        return x, y
    end

    local function GetPopupCenterOffsets(self)
        if not self or not UIParent then return nil, nil end
        local calculatedX, calculatedY = GetPopupCenterInParentSpace(self)
        if calculatedX and calculatedY then
            return calculatedX, calculatedY
        end

        -- Geometry can be unavailable while the popup is hidden during login.
        -- A centered saved anchor is already expressed in UIParent coordinates.
        local point, relTo, relPoint, x, y = self:GetPoint(1)
        if point == "CENTER" and (relTo == UIParent or relTo == nil) and (relPoint == "CENTER" or relPoint == nil) then
            return x or 0, y or 0
        end
        return nil, nil
    end

    local function PersistPopupPosition()
        local x, y = GetPopupCenterOffsets(popup)
        if x and y then
            if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
            MattMinimalFramesDB.popupPosition = { x = x, y = y, anchor = "CENTER" }
        end
    end

    local function ClampPopupHorizontal(self)
        if not self or not UIParent then return end
        local x, y = GetPopupCenterOffsets(self)
        if not x or not y then return end
        local parentLeft, parentRight, parentBottom, parentTop = GetParentBounds()
        local parentWidth = math.max(1, parentRight - parentLeft)
        local parentHeight = math.max(1, parentTop - parentBottom)
        local scaleRatio = GetEffectiveScale(self) / GetEffectiveScale(UIParent)
        local halfW = ((self:GetWidth() or 0) * scaleRatio) * 0.5
        local halfH = ((self:GetHeight() or 0) * scaleRatio) * 0.5

        local minX = (-parentWidth * 0.5) + halfW
        local maxX = (parentWidth * 0.5) - halfW
        local minY = (-parentHeight * 0.5) + halfH
        local maxY = (parentHeight * 0.5) - halfH
        if minX > maxX then
            minX, maxX = 0, 0
        end
        if minY > maxY then
            minY, maxY = 0, 0
        end

        local clampedX = math.max(minX, math.min(maxX, x))
        local clampedY = math.max(minY, math.min(maxY, y))
        -- StartMoving may leave a scaled frame on a different anchor. Always
        -- normalize it so subsequent scale changes cannot restore stale offsets.
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", clampedX, clampedY)
    end

    local function ApplyPopupScale(scale, preservePosition)
        local targetScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(scale)) or scale or 1.0
        local x, y

        if preservePosition and popup and popup.IsVisible and popup:IsVisible() then
            x, y = GetPopupCenterOffsets(popup)
        end

        popup:SetScale(targetScale)
        ClampPopupHeightToBounds(popup)

        if x and y then
            popup:ClearAllPoints()
            popup:SetPoint("CENTER", UIParent, "CENTER", x, y)
        end
        ClampPopupHorizontal(popup)
        PersistPopupPosition()
    end

    local function RestoreOrInitializePopupPosition(defaultCenterY)
        if MattMinimalFramesDB and MattMinimalFramesDB.popupPosition then
            local pos = MattMinimalFramesDB.popupPosition
            if pos.x and pos.y then
                popup:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
            elseif pos.left and pos.top then
                popup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
                NormalizePopupAnchorToCenter(popup)
                PersistPopupPosition()
            else
                popup:SetPoint("CENTER", UIParent, "CENTER", 0, defaultCenterY or 0)
            end
        else
            popup:SetPoint("CENTER", UIParent, "CENTER", 0, defaultCenterY or 0)
        end
        ClampPopupHorizontal(popup)
    end

    return {
        PersistPopupSize = PersistPopupSize,
        PersistPopupPosition = PersistPopupPosition,
        ClampPopupHorizontal = ClampPopupHorizontal,
        GetDynamicMaxPopupHeight = GetDynamicMaxPopupHeight,
        ApplyPopupScale = ApplyPopupScale,
        RestoreOrInitializePopupPosition = RestoreOrInitializePopupPosition,
    }
end
