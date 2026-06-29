local function CreateDragHandlers(frame, frameName)
    local deps = _G.MMF_FrameFactoryDragSetupDeps or {}
    local CanStartFrameDrag = deps.CanStartFrameDrag
    local TryBeginFrameMoving = deps.TryBeginFrameMoving
    local TryStopFrameMoving = deps.TryStopFrameMoving
    local SaveFramePosition = deps.SaveFramePosition
    local ShowFrameResetPopup = deps.ShowFrameResetPopup
    local GetDragHintText = deps.GetDragHintText
    local GetFrameDefinition = deps.GetFrameDefinition or MMF_GetFrameDefinition
    local cfg = deps.cfg or MMF_Config or {}
    local SetFontSafe = deps.SetFontSafe or MMF_SetFontSafe
    local fontFlags = (MMF_GetGlobalTextFontFlags and MMF_GetGlobalTextFontFlags()) or "OUTLINE"

    frame:SetScript("OnDragStart", function(self)
        local started = false
        if TryBeginFrameMoving then
            started = TryBeginFrameMoving(self, frameName)
        elseif CanStartFrameDrag and CanStartFrameDrag(self) then
            self.mmfDragInProgress = true
            self:StartMoving()
            started = true
        end
        if started then
            self.mmfDragInProgress = true
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        if not TryStopFrameMoving or not TryStopFrameMoving(self) then
            self.mmfDragInProgress = nil
            return
        end

        if SaveFramePosition then
            SaveFramePosition(self, frameName)
        end
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
    end)

    frame.moveOverlay = frame:CreateTexture(nil, "OVERLAY")
    frame.moveOverlay:SetAllPoints()
    frame.moveOverlay:SetColorTexture(0, 0, 0, 0.35)
    frame.moveOverlay:Hide()

    frame:HookScript("OnEnter", function(self)
        if CanStartFrameDrag and CanStartFrameDrag(self) then
            self.moveOverlay:Show()
        end
    end)

    frame:HookScript("OnLeave", function(self)
        self.moveOverlay:Hide()
    end)

    local frameDef = GetFrameDefinition and GetFrameDefinition(frame.unit)
    local frameLabel = frameDef and frameDef.label or frame.unit
    frame.frameLabel = frameLabel

    frame.moveHint = frame:CreateFontString(nil, "OVERLAY")
    if SetFontSafe then
        SetFontSafe(frame.moveHint, cfg.FONT_PATH, 10, fontFlags)
    else
        frame.moveHint:SetFont(cfg.FONT_PATH, 10, fontFlags)
    end
    frame.moveHint:SetText(frameLabel)
    frame.moveHint:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.moveHint:Hide()

    frame.moveSubtext = frame:CreateFontString(nil, "OVERLAY")
    if SetFontSafe then
        SetFontSafe(frame.moveSubtext, cfg.FONT_PATH, 9, fontFlags)
    else
        frame.moveSubtext:SetFont(cfg.FONT_PATH, 9, fontFlags)
    end
    frame.moveSubtext:SetText(GetDragHintText and GetDragHintText() or "Shift+Drag to move")
    frame.moveSubtext:SetPoint("TOP", frame.moveHint, "BOTTOM", 0, -2)
    frame.moveSubtext:SetTextColor(0.7, 0.7, 0.7)
    frame.moveSubtext:Hide()

    frame:HookScript("OnEnter", function(self)
        if not InCombatLockdown() and MattMinimalFramesDB.showMoveHints then
            self.moveSubtext:SetText(GetDragHintText and GetDragHintText() or "Shift+Drag to move")
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
        if not deps.IsEditModeDragEnabled or not deps.IsEditModeDragEnabled() then
            return
        end
        if self.mmfDragInProgress or self.mmfSuppressClickPopup then
            return
        end
        if ShowFrameResetPopup then
            ShowFrameResetPopup(self, frameName)
        end
    end)
end

_G.MMF_FrameFactoryDragSetup = {
    CreateDragHandlers = CreateDragHandlers,
}
