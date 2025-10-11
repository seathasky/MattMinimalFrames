--========================================================
-- MattMinimalFrames_Core.lua
-- Core initialization and configuration
--========================================================

----------------------------------------------------------
-- DATABASE INITIALIZATION
----------------------------------------------------------

-- Initialize saved variables with defaults
MattMinimalFramesDB = MattMinimalFramesDB or {
    showPowerBars = true,
    showBuffs = true,
    showDebuffs = true,
    powerBarWidth = 73,
    powerBarHeight = 5,
    powerBarVerticalOffset = -24,
    powerBarHorizontalOffset = 4,
}

-- Hide Blizzard frames
local function HideBlizzardFrames()
    -- Store frames we want to hide
    local framesToHide = {
        PlayerFrame,
        TargetFrame,
        FocusFrame,
        PetFrame,
    }
    
    -- Hide each frame and move it to our hider frame
    for _, frame in pairs(framesToHide) do
        if frame then
            frame:UnregisterAllEvents()
            frame:SetScript("OnShow", function(self) self:Hide() end)
            MMF_HideFrame(frame)
        end
    end
    
    -- Specifically handle ToT which might be parented to TargetFrame
    if TargetFrameToT then
        TargetFrameToT:UnregisterAllEvents()
        TargetFrameToT:SetScript("OnShow", function(self) self:Hide() end)
        MMF_HideFrame(TargetFrameToT)
    end
end

-- Optionally disable Blizzard's UnitPopup
if type(DisableAddOn) == "function" then
    DisableAddOn("Blizzard_UnitPopup")
end

----------------------------------------------------------
-- SLASH COMMANDS
----------------------------------------------------------

SLASH_MATTMINIMALFRAMES1 = "/mmf"
SlashCmdList["MATTMINIMALFRAMES"] = function()
    MMF_ShowSettings()
end

local function Initialize()
    HideBlizzardFrames()  -- Hide Blizzard frames before creating ours
    -- Create all frames
    MMF_CreateAllMinimalFrames()
    
    -- Initialize minimap button
    MMF_InitializeMinimap()
end

Initialize()
