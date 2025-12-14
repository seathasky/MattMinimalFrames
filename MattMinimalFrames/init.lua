-- MattMinimalFrames_Init.lua

local function HideBlizzardFrames()
    local framesToHide = {
        PlayerFrame,
        TargetFrame,
        FocusFrame,
        PetFrame,
    }
    for _, frame in pairs(framesToHide) do
        if frame then
            frame:UnregisterAllEvents()
            frame:SetScript("OnShow", function(self) self:Hide() end)
            MMF_HideFrame(frame)
        end
    end
    if TargetFrameToT then
        TargetFrameToT:UnregisterAllEvents()
        TargetFrameToT:SetScript("OnShow", function(self) self:Hide() end)
        MMF_HideFrame(TargetFrameToT)
    end
end


SLASH_MATTMINIMALFRAMES1 = "/mmf"
SlashCmdList["MATTMINIMALFRAMES"] = function()
    MMF_ShowWelcomePopup(true)
end

local function Initialize()
    HideBlizzardFrames()
    MMF_CreateAllMinimalFrames()
    if MattMinimalFramesDB.locked then
        MMF_LockFrames()
    else
        MMF_UnlockFrames()
    end
    C_Timer.After(1, function() MMF_ShowWelcomePopup(false) end)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "MattMinimalFrames" then
        Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
