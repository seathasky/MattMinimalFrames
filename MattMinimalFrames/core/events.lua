-- core/events.lua
-- Event handling for MattMinimalFrames

-- Initialize LibCustomGlow
local LibCustomGlow = LibStub("LibCustomGlow-1.0")

-- Pending flag for lock changes
local pendingLock = false

--------------------------------------------------
-- FRAME LOCKING
--------------------------------------------------

function MMF_LockFrames()
    if InCombatLockdown() then
        print("Cannot lock frames during combat. Your lock request has been queued.")
        pendingLock = true
        return
    end
    pendingLock = false
    
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.locked = true
    
    local frames = { MMF_PlayerFrame, MMF_TargetFrame, MMF_TargetOfTargetFrame, MMF_PetFrame, MMF_FocusFrame }
    for _, frm in ipairs(frames) do
        if frm then
            frm:SetMovable(false)
            frm:SetClampedToScreen(true)
            frm:EnableMouse(true)
            frm:RegisterForClicks("AnyUp")
            if frm.titleText then
                frm.titleText:Hide()
            end
            MMF_ResetSecureAttributes(frm)
            if LibCustomGlow then
                LibCustomGlow.PixelGlow_Stop(frm)
            end
        end
    end
end

function MMF_UnlockFrames()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.locked = false
    
    local frames = { MMF_PlayerFrame, MMF_TargetFrame, MMF_TargetOfTargetFrame, MMF_PetFrame, MMF_FocusFrame }
    for _, frm in ipairs(frames) do
        if frm then
            frm:SetMovable(true)
            frm:SetClampedToScreen(false)
            frm:EnableMouse(true)
            frm:RegisterForDrag("LeftButton")
            frm:RegisterForClicks("AnyUp")
            if frm.titleText then
                frm.titleText:Show()
            end
            MMF_ResetSecureAttributes(frm)
            if LibCustomGlow then
                LibCustomGlow.PixelGlow_Stop(frm)
            end
        end
    end
end

--------------------------------------------------
-- CORE EVENT HANDLER
--------------------------------------------------

local coreEventFrame = CreateFrame("Frame")
coreEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
coreEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
coreEventFrame:RegisterEvent("UNIT_HEALTH")
coreEventFrame:RegisterEvent("UNIT_POWER_UPDATE")
coreEventFrame:RegisterEvent("PLAYER_ALIVE")
coreEventFrame:RegisterEvent("PLAYER_DEAD")
coreEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coreEventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
coreEventFrame:RegisterEvent("UNIT_NAME_UPDATE")
coreEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
coreEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
coreEventFrame:RegisterEvent("UNIT_PET")
coreEventFrame:RegisterEvent("UNIT_TARGET")

coreEventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingLock then
            MMF_LockFrames()
        end
        if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
            MMF_PlayerFrame.combatTexture:Hide()
        end
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
            MMF_PlayerFrame.combatTexture:Show()
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_UPDATE_RESTING" then
        if MMF_PlayerFrame and MMF_PlayerFrame.restingTexture then
            MMF_PlayerFrame.restingTexture:SetShown(IsResting())
        end
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        MMF_UpdateUnitFrame(MMF_TargetFrame)
        MMF_UpdateUnitFrame(MMF_TargetOfTargetFrame)
        
    elseif event == "PLAYER_FOCUS_CHANGED" then
        MMF_UpdateUnitFrame(MMF_FocusFrame)
        
    elseif event == "UNIT_PET" then
        MMF_UpdateUnitFrame(MMF_PetFrame)
        
    elseif event == "UNIT_TARGET" then
        if unit == "target" then
            MMF_UpdateUnitFrame(MMF_TargetOfTargetFrame)
        end
        
    elseif event == "UNIT_NAME_UPDATE" then
        local frameMap = {
            player = MMF_PlayerFrame,
            target = MMF_TargetFrame,
            targettarget = MMF_TargetOfTargetFrame,
            pet = MMF_PetFrame,
            focus = MMF_FocusFrame,
        }
        if frameMap[unit] then
            MMF_UpdateUnitFrame(frameMap[unit])
        end
        
    elseif event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" then
        local frameMap = {
            player = MMF_PlayerFrame,
            target = MMF_TargetFrame,
            targettarget = MMF_TargetOfTargetFrame,
            pet = MMF_PetFrame,
            focus = MMF_FocusFrame,
        }
        if frameMap[unit] then
            MMF_UpdateUnitFrame(frameMap[unit])
        end
    end
end)

-- OnUpdate for throttled updates
coreEventFrame:SetScript("OnUpdate", function(self, elapsed)
    MMF_UpdateAll(elapsed)
end)
