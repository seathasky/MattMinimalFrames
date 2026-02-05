local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local Compat = _G.MMF_Compat

local ADDON_NAME = "MattMinimalFrames"
local ICON_PATH = "Interface\\AddOns\\MattMinimalFrames\\Images\\MMF.png"
local ACCENT_COLOR = Compat.IsTBC and {0.2, 0.9, 0.4} or {0.6, 0.4, 0.9}

local pendingOpenAfterCombat = false

local MMF_LDB = LDB:NewDataObject(ADDON_NAME, {
    type = "launcher",
    text = ADDON_NAME,
    icon = ICON_PATH,
    OnClick = function(self, button)
        if button == "LeftButton" then
            if InCombatLockdown() then
                print("|cff00ff00Matt's Minimal Frames|r: Settings will open when combat ends.")
                pendingOpenAfterCombat = true
                return
            end
            if MMF_WelcomePopup and MMF_WelcomePopup:IsShown() then
                MMF_WelcomePopup:Hide()
            else
                MMF_ShowWelcomePopup(true)
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Matt's Minimal Frames", ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3])
        tooltip:AddLine("|cff00ff00Click:|r Toggle settings", 0.8, 0.8, 0.8)
        tooltip:AddLine("|cff00ff00Drag:|r Move button", 0.8, 0.8, 0.8)
    end,
})

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

local function InitializeMinimapButton()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    if not MattMinimalFramesDB.minimap then
        MattMinimalFramesDB.minimap = { hide = false }
    end

    LDBIcon:Register(ADDON_NAME, MMF_LDB, MattMinimalFramesDB.minimap)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeMinimapButton()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingOpenAfterCombat then
            pendingOpenAfterCombat = false
            MMF_ShowWelcomePopup(true)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if MMF_WelcomePopup and MMF_WelcomePopup:IsShown() then
            MMF_WelcomePopup:Hide()
        end
    end
end)
