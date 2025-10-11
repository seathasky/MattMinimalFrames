--========================================================
-- MattMinimalFrames_FrameManager.lua
-- Frame updates, lock/unlock, and event handling
--========================================================

-- Initialize LibCustomGlow
local LibCustomGlow = LibStub("LibCustomGlow-1.0")

-- Update tracking
local lastUpdate = 0
local updateInterval = 0.1

----------------------------------------------------------
-- FRAME UPDATE LOGIC
----------------------------------------------------------

local function UpdateUnitFrame(frame)
    if not frame or not frame.unit or not frame.nameText then return end
    local unit = frame.unit
    local unitName = UnitName(unit) or ""

    -- Truncate target-of-target name if needed
    if unit == "targettarget" then
        local truncated = string.sub(unitName, 1, 8)
        if #unitName > 8 then truncated = truncated .. "…" end
        frame.nameText:SetText(truncated)
    else
        frame.nameText:SetText(unitName)
        frame.nameText:SetWidth(frame.originalWidth - 4)
    end

    local hp = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    local healthPercent = (maxHP > 0) and math.floor((hp / maxHP) * 100) or 0

    if frame.hpText then
        frame.hpText:SetText(MMF_FormatNumber(hp) .. " | " .. healthPercent .. "%")
    end

    -- Hide HP/Power if unit is targettarget or pet
    if unit == "targettarget" or unit == "pet" then
        frame.hpText:Hide()
        frame.powerText:Hide()
    else
        frame.hpText:Show()
        frame.powerText:Hide()
    end

    -- Adjust the health bar foreground
    local healthPercent = (maxHP > 0) and (hp / maxHP) or 0
    local fullWidth = frame.originalWidth - 2
    if hp == 0 then
        frame.healthBarFG:SetWidth(1)
    else
        frame.healthBarFG:Show()
        local newWidth = math.max(1, fullWidth * healthPercent)
        frame.healthBarFG:SetWidth(newWidth)
    end

    -- Update class/unit color
    local r, g, b = MMF_GetUnitColor(unit)
    frame.healthBarFG:SetVertexColor(r, g, b, 1)

    -- Update the absorb shield bar (behind health bar)
    if (unit == "player" or unit == "target") and frame.shieldBarFG then
        local shield = UnitGetTotalAbsorbs(unit) or 0
        if shield > 0 and hp < maxHP then
            frame.shieldBarFG:Show()
            local shieldWidth = math.min(fullWidth - frame.healthBarFG:GetWidth(), fullWidth * (shield / maxHP))
            frame.shieldBarFG:SetWidth(shieldWidth)
            frame.shieldBarFG:SetVertexColor(1, 1, 1, 1)
            frame.shieldBarFG:SetAlpha(0.5)
        else
            frame.shieldBarFG:Hide()
        end
    end

    -- Update the absorb shield bar (above health bar, only at full HP)
    if (unit == "player" or unit == "target") and frame.shieldBarFG2 then
        local shield = UnitGetTotalAbsorbs(unit) or 0
        if shield > 0 and hp == maxHP then
            frame.shieldBarFG2:Show()
        else
            frame.shieldBarFG2:Hide()
        end
    end

    -- Update power bar if it exists
    if frame.powerBarFG and (unit == "player" or unit == "target") then
        local powerType = UnitPowerType(unit)
        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        
        -- Check for shaman specs and override powerType to mana if necessary
        if UnitClass(unit) == "Shaman" then
            local spec = GetSpecialization()
            if spec == 1 or spec == 2 then
                powerType = 0
                power = UnitPower(unit, 0)
                maxPower = UnitPowerMax(unit, 0)
            end
        end

        -- Hide power bar if unit doesn't use power
        if maxPower <= 0 or powerType == 7 then
            frame.powerBarBorder:Hide()
            frame.powerBarBG:Hide()
            frame.powerBarFG:Hide()
            return
        end
        
        local powerPercent = power / maxPower
        
        -- Get power color with custom mana color
        local powerColor = PowerBarColor[powerType]
        local r, g, b = 1, 1, 1
        if powerType == 0 then
            r, g, b = 0.2, 0.7, 1
        elseif powerColor then
            r, g, b = powerColor.r, powerColor.g, powerColor.b
        end
        
        -- Update power bar width
        local width = frame.powerBarBG:GetWidth() * powerPercent
        frame.powerBarFG:ClearAllPoints()
        frame.powerBarFG:SetPoint("BOTTOMLEFT", frame.powerBarBG, "BOTTOMLEFT", 0, 0)
        frame.powerBarFG:SetWidth(width)
        
        frame.powerBarFG:SetVertexColor(r, g, b, 1)
        
        frame.powerBarBorder:Show()
        frame.powerBarBG:Show()
        frame.powerBarFG:Show()
    end
end

function MMF_UpdateAll(elapsed)
    lastUpdate = lastUpdate + (elapsed or 0)
    if lastUpdate < updateInterval then return end
    lastUpdate = 0

    -- Only update frames that exist and are shown
    for _, frame in ipairs({MMF_PlayerFrame, MMF_TargetFrame, MMF_TargetOfTargetFrame, MMF_PetFrame, MMF_FocusFrame}) do
        if frame and frame:IsShown() then
            UpdateUnitFrame(frame)
        end
    end
end

----------------------------------------------------------
-- LOCK / UNLOCK FRAMES
----------------------------------------------------------

function MMF_LockFrames()
    if InCombatLockdown() then
        print("|cff33ccffMattMinimalFrames:|r Cannot lock frames during combat.")
        return
    end
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
            if LibCustomGlow then
                LibCustomGlow.PixelGlow_Stop(frm)
            end
        end
    end
end

----------------------------------------------------------
-- EVENT HANDLING
----------------------------------------------------------

function MMF_InitializeFrameEvents()
    local coreEventFrame = CreateFrame("Frame")
    coreEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    coreEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    coreEventFrame:RegisterEvent("UNIT_HEALTH")
    coreEventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    coreEventFrame:RegisterEvent("PLAYER_ALIVE")
    coreEventFrame:RegisterEvent("PLAYER_DEAD")
    coreEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    coreEventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")

    coreEventFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_REGEN_ENABLED" then
            if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
                MMF_PlayerFrame.combatTexture:Hide()
            end
        elseif event == "PLAYER_REGEN_DISABLED" then
            if MMF_PlayerFrame and MMF_PlayerFrame.combatTexture then
                MMF_PlayerFrame.combatTexture:Show()
            end
        elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_UPDATE_RESTING" then
            if MMF_PlayerFrame and MMF_PlayerFrame.restingTexture then
                if IsResting() then
                    MMF_PlayerFrame.restingTexture:Show()
                else
                    MMF_PlayerFrame.restingTexture:Hide()
                end
            end
        elseif event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" then
            if unit == "player" then
                UpdateUnitFrame(MMF_PlayerFrame)
            elseif unit == "target" then
                UpdateUnitFrame(MMF_TargetFrame)
            elseif unit == "targettarget" then
                UpdateUnitFrame(MMF_TargetOfTargetFrame)
            elseif unit == "pet" then
                UpdateUnitFrame(MMF_PetFrame)
            elseif unit == "focus" then
                UpdateUnitFrame(MMF_FocusFrame)
            end
        end
    end)

    -- Debounced OnUpdate script to reduce CPU usage
    coreEventFrame:SetScript("OnUpdate", function(self, elapsed)
        MMF_UpdateAll(elapsed)
    end)
end
