-- core/minimap.lua
-- Minimap button for MattMinimalFrames using LibDBIcon
-- Works on both Retail and TBC

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local ADDON_NAME = "MattMinimalFrames"
local ICON_PATH = "Interface\\AddOns\\MattMinimalFrames\\Images\\MMF.png"

--------------------------------------------------
-- DATA BROKER OBJECT
--------------------------------------------------

local MMF_LDB = LDB:NewDataObject(ADDON_NAME, {
    type = "launcher",
    text = ADDON_NAME,
    icon = ICON_PATH,
    OnClick = function(self, button)
        if button == "LeftButton" then
            MMF_ShowWelcomePopup(true)
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("MattMinimalFrames", 1, 1, 1)
        tooltip:AddLine("|cff00ff00Click:|r Open settings", 0.8, 0.8, 0.8)
        tooltip:AddLine("|cff00ff00Drag:|r Move button", 0.8, 0.8, 0.8)
    end,
})

--------------------------------------------------
-- TOGGLE FUNCTION
--------------------------------------------------

function MMF_ToggleMinimapButton(show)
    if not MattMinimalFramesDB.minimap then
        MattMinimalFramesDB.minimap = {}
    end
    
    if show then
        MattMinimalFramesDB.minimap.hide = false
        LDBIcon:Show(ADDON_NAME)
    else
        MattMinimalFramesDB.minimap.hide = true
        LDBIcon:Hide(ADDON_NAME)
    end
end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

local function InitializeMinimapButton()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    if not MattMinimalFramesDB.minimap then
        MattMinimalFramesDB.minimap = { hide = false }
    end
    
    -- Register with LibDBIcon
    LDBIcon:Register(ADDON_NAME, MMF_LDB, MattMinimalFramesDB.minimap)
end

--------------------------------------------------
-- EVENT FRAME
--------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeMinimapButton()
    end
end)
