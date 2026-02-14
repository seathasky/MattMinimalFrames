local LibCustomGlow = LibStub("LibCustomGlow-1.0")

--------------------------------------------------
-- FRAME LOCKING
--------------------------------------------------

local function ApplyFrameLockState(locked)
    for _, frm in ipairs(MMF_GetAllFrames()) do
        if frm then
            frm:SetMovable(true)
            frm:SetClampedToScreen(locked)
            frm:EnableMouse(true)
            frm:RegisterForDrag("LeftButton")
            frm:RegisterForClicks("AnyUp")
            if frm.titleText then
                frm.titleText:SetShown(not locked)
            end
            MMF_ResetSecureAttributes(frm)
            if LibCustomGlow then
                LibCustomGlow.PixelGlow_Stop(frm)
            end
        end
    end
end

function MMF_LockFrames()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.locked = true

    local queuedMessage = "|cff00ff00Matt's Minimal Frames|r: Locking frames after combat."
    if MMF_RunAfterCombat then
        MMF_RunAfterCombat("frame_lock_state", function()
            ApplyFrameLockState(true)
        end, queuedMessage)
        return
    end

    if InCombatLockdown() then
        print(queuedMessage)
        return
    end

    ApplyFrameLockState(true)
end

function MMF_UnlockFrames()
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.locked = false

    local queuedMessage = "|cff00ff00Matt's Minimal Frames|r: Unlocking frames after combat."
    if MMF_RunAfterCombat then
        MMF_RunAfterCombat("frame_lock_state", function()
            ApplyFrameLockState(false)
        end, queuedMessage)
        return
    end

    if InCombatLockdown() then
        print(queuedMessage)
        return
    end

    ApplyFrameLockState(false)
end

--------------------------------------------------
-- CORE EVENT HANDLER
--------------------------------------------------

local function RequestUnitUpdate(unit)
    if MMF_RequestUnitUpdate then
        MMF_RequestUnitUpdate(unit)
        return
    end
    if MMF_GetFrameForUnit and MMF_UpdateUnitFrame then
        local frame = MMF_GetFrameForUnit(unit)
        if frame then
            MMF_UpdateUnitFrame(frame)
        end
    end
end

local function RequestFrameUpdate(frame)
    if not frame then return end
    if MMF_RequestFrameUpdate then
        MMF_RequestFrameUpdate(frame)
        return
    end
    if MMF_UpdateUnitFrame then
        MMF_UpdateUnitFrame(frame)
    end
end

local function RequestAllUpdates()
    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
        return
    end
    if MMF_GetAllFrames and MMF_UpdateUnitFrame then
        for _, frame in ipairs(MMF_GetAllFrames()) do
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end
end

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
coreEventFrame:RegisterEvent("UNIT_HEAL_PREDICTION")
coreEventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")

coreEventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        if MMF_FlushCombatQueue then
            MMF_FlushCombatQueue()
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
        if event == "PLAYER_ENTERING_WORLD" then
            RequestAllUpdates()
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        RequestFrameUpdate(MMF_TargetFrame)
        RequestFrameUpdate(MMF_TargetOfTargetFrame)

    elseif event == "PLAYER_FOCUS_CHANGED" then
        RequestFrameUpdate(MMF_FocusFrame)

    elseif event == "UNIT_PET" then
        RequestFrameUpdate(MMF_PetFrame)

    elseif event == "UNIT_TARGET" then
        if unit == "target" then
            RequestFrameUpdate(MMF_TargetOfTargetFrame)
        end

    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        RequestUnitUpdate(unit)

    elseif event == "PLAYER_ALIVE" or event == "PLAYER_DEAD" then
        RequestUnitUpdate("player")
    end
end)
