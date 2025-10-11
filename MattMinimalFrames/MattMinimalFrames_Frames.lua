--========================================================
-- MattMinimalFrames_Frames.lua
-- Frame creation and layout
--========================================================

----------------------------------------------------------
-- FRAME CREATION
----------------------------------------------------------

function MMF_CreateAllMinimalFrames()
    -- Create all unit frames using the UnitFrames module
    local function CreateSecureFrame(unit, name, width, height, x, y)
        local frame = MMF_CreateSecureMinimalUnitFrame(unit, name, width, height, "CENTER", "CENTER", x, y)
        RegisterUnitWatch(frame)
        return frame
    end

    _G["MMF_PlayerFrame"]         = CreateSecureFrame("player",       "MMF_PlayerFrame",         220, 28, -150, 0)
    _G["MMF_TargetFrame"]         = CreateSecureFrame("target",       "MMF_TargetFrame",         220, 28,  150, 0)
    _G["MMF_TargetOfTargetFrame"] = CreateSecureFrame("targettarget", "MMF_TargetOfTargetFrame", 100, 28,   0, -100)
    _G["MMF_PetFrame"]            = CreateSecureFrame("pet",          "MMF_PetFrame",            100, 28, -300, -100)
    _G["MMF_FocusFrame"]          = CreateSecureFrame("focus",        "MMF_FocusFrame",          100, 28,  300, -100)

    -- Apply settings for buffs, debuffs, and resource bar
    C_Timer.After(0, function()
        -- Buffs
        if MMF_TargetFrame and MMF_TargetFrame.BuffContainer then
            if MattMinimalFramesDB.showBuffs == false then
                MMF_TargetFrame.BuffContainer:Hide()
            else
                MMF_TargetFrame.BuffContainer:Show()
            end
        end
        -- Debuffs
        if MMF_TargetFrame and MMF_TargetFrame.DebuffContainer then
            if MattMinimalFramesDB.showDebuffs == false then
                MMF_TargetFrame.DebuffContainer:Hide()
            else
                MMF_TargetFrame.DebuffContainer:Show()
            end
        end
        -- Resource bars (player and target)
        for _, frame in ipairs({MMF_PlayerFrame, MMF_TargetFrame}) do
            if frame and frame.powerBarFrame then
                if MattMinimalFramesDB.showPowerBars == false then
                    frame.powerBarFrame:Hide()
                else
                    frame.powerBarFrame:Show()
                end
            end
        end
    end)
    
    -- Initialize auras from Auras module
    MMF_InitializeAuras()
    
    -- Initialize frame events from FrameManager module
    MMF_InitializeFrameEvents()
end
