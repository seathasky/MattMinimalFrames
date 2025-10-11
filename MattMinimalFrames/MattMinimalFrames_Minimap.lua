--========================================================
-- MattMinimalFrames_Minimap.lua
-- Minimap button for quick settings access
--========================================================

local minimapButton

----------------------------------------------------------
-- MINIMAP BUTTON CREATION
----------------------------------------------------------

local function CreateMinimapButton()
    -- Initialize saved position if it doesn't exist
    if not MattMinimalFramesDB.minimapButton then
        MattMinimalFramesDB.minimapButton = {
            hide = false,
            position = 45
        }
    end

    -- Create the button
    minimapButton = CreateFrame("Button", "MMF_MinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Icon texture
    local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\MMF.png")
    minimapButton.icon = icon
    
    -- Border texture
    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    minimapButton.border = border
    
    -- Tooltip
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("MattMinimalFrames", 1, 1, 1)
        GameTooltip:AddLine("Click: Open settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to move", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    minimapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Click handlers
    minimapButton:SetScript("OnClick", function(self, button)
        if MMF_ShowSettings then
            MMF_ShowSettings()
        else
            print("|cff33ccffMattMinimalFrames:|r Settings not yet loaded. Try /mmf command.")
        end
    end)
    
    -- Dragging
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetMovable(true)
    
    minimapButton:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.isMoving = true
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            
            local angle = math.deg(math.atan2(py - my, px - mx))
            if angle < 0 then
                angle = angle + 360
            end
            
            MattMinimalFramesDB.minimapButton.position = angle
            self:UpdatePosition()
        end)
    end)
    
    minimapButton:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.isMoving = false
        self:SetScript("OnUpdate", nil)
    end)
    
    -- Position update function
    function minimapButton:UpdatePosition()
        local angle = math.rad(MattMinimalFramesDB.minimapButton.position or 45)
        local x = math.cos(angle) * 95  -- Increased from 80 to push button outside
        local y = math.sin(angle) * 95
        self:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    
    -- Initial position
    minimapButton:UpdatePosition()
    
    -- Show/hide based on saved setting
    if MattMinimalFramesDB.minimapButton.hide then
        minimapButton:Hide()
    else
        minimapButton:Show()
    end
end

----------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------

function MMF_InitializeMinimap()
    -- Wait for Minimap and all modules to be ready
    C_Timer.After(1, function()
        CreateMinimapButton()
    end)
end

----------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------

function MMF_ToggleMinimapButton()
    if not MattMinimalFramesDB.minimapButton then
        MattMinimalFramesDB.minimapButton = {}
    end
    
    MattMinimalFramesDB.minimapButton.hide = not MattMinimalFramesDB.minimapButton.hide
    
    if minimapButton then
        if MattMinimalFramesDB.minimapButton.hide then
            minimapButton:Hide()
            print("|cff33ccffMattMinimalFrames:|r Minimap button hidden")
        else
            minimapButton:Show()
            print("|cff33ccffMattMinimalFrames:|r Minimap button shown")
        end
    end
end
