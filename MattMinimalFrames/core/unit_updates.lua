-- core/unit_updates.lua
-- Unit frame update logic for MattMinimalFrames

local cfg = MMF_Config
local lastUpdate = 0

--------------------------------------------------
-- UNIT FRAME UPDATE
--------------------------------------------------

local function UpdateUnitFrame(frame)
    if not frame or not frame.unit or not frame.nameText then return end
    local unit = frame.unit
    local unitName = ""
    local hasValidName = false
    
    -- Safely get unit name
    local success, result = pcall(function()
        local name = UnitName(unit)
        if name and name ~= "" then
            return name
        end
        return nil
    end)
    
    if success and result then
        unitName = result
        hasValidName = true
    end

    -- Update name text
    if unit == "targettarget" then
        if hasValidName then
            local truncated = string.sub(unitName, 1, 8)
            if #unitName > 8 then truncated = truncated .. "…" end
            pcall(function() frame.nameText:SetText(truncated) end)
        end
        if not UnitExists(unit) then
            pcall(function() frame.nameText:SetText("") end)
        end
    else
        if hasValidName then
            pcall(function() frame.nameText:SetText(unitName) end)
        end
        if not UnitExists(unit) then
            pcall(function() frame.nameText:SetText("") end)
        end
        pcall(function() frame.nameText:SetWidth(frame.originalWidth - 4) end)
    end

    -- Update health bar
    local maxHP = UnitHealthMax(unit)
    local hp = UnitHealth(unit)
    
    if frame.healthBar then
        frame.healthBar:SetMinMaxValues(0, maxHP)
        frame.healthBar:SetValue(hp)
    end
    
    -- Hide shield bars (can't calculate with secret values)
    if frame.shieldBarFG then frame.shieldBarFG:Hide() end
    if frame.shieldBarFG2 then frame.shieldBarFG2:Hide() end
    
    -- HP text
    if frame.hpText and (unit == "player" or unit == "target") then
        frame.hpText:SetText(hp)
        frame.hpText:Show()
    end

    -- Update absorb bar
    if frame.absorbBar and (unit == "player" or unit == "target") then
        local absorb = UnitGetTotalAbsorbs(unit) or 0
        frame.absorbBar:SetMinMaxValues(0, maxHP)
        frame.absorbBar:SetValue(absorb)
        frame.absorbBar:SetAlpha(1.0)
        frame.absorbBar:Show()
    elseif frame.absorbBar then
        frame.absorbBar:Hide()
    end

    -- Hide HP/Power for ToT and pet
    if unit == "targettarget" or unit == "pet" then
        if frame.hpText then frame.hpText:Hide() end
        if frame.powerText then frame.powerText:Hide() end
    else
        if frame.powerText then frame.powerText:Hide() end
    end

    -- Update health bar color
    local r, g, b = MMF_GetUnitColor(unit)
    if frame.healthBar then
        frame.healthBar:SetStatusBarColor(r, g, b, 1)
    end

    -- Update power bar
    if frame.powerBar and (unit == "player" or unit == "target") then
        local powerType = UnitPowerType(unit)
        
        -- Shaman spec handling
        local useManaPowerType = false
        if unit == "player" and UnitClass(unit) == "Shaman" then
            local spec = GetSpecialization()
            if spec == 1 or spec == 2 then
                useManaPowerType = true
                powerType = 0
            end
        end
        
        local maxPower = useManaPowerType and UnitPowerMax(unit, 0) or UnitPowerMax(unit)
        local power = useManaPowerType and UnitPower(unit, 0) or UnitPower(unit)

        local hasPower = false
        pcall(function()
            if maxPower and maxPower > 0 then
                hasPower = true
            end
        end)
        
        if hasPower then
            frame.powerBar:SetMinMaxValues(0, maxPower)
            frame.powerBar:SetValue(power)
            
            local powerColor = PowerBarColor[powerType]
            local r, g, b = 1, 1, 1
            if powerType == 0 then
                r, g, b = 0.2, 0.7, 1  -- Light blue for mana
            elseif powerColor then
                r, g, b = powerColor.r, powerColor.g, powerColor.b
            end
            
            frame.powerBar:SetStatusBarColor(r, g, b, 1)
            
            if frame.powerBarBorder then frame.powerBarBorder:Show() end
            frame.powerBarBG:Show()
            frame.powerBar:Show()
        else
            if frame.powerBarBorder then frame.powerBarBorder:Hide() end
            frame.powerBarBG:Hide()
            frame.powerBar:Hide()
        end
    end
end

-- Export for use by other modules
MMF_UpdateUnitFrame = UpdateUnitFrame

--------------------------------------------------
-- UPDATE ALL FRAMES
--------------------------------------------------

function MMF_UpdateAll(elapsed)
    lastUpdate = lastUpdate + (elapsed or 0)
    if lastUpdate < cfg.UPDATE_INTERVAL then return end
    lastUpdate = 0

    local frames = {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }

    for _, frame in ipairs(frames) do
        if frame and frame:IsShown() then
            UpdateUnitFrame(frame)
        end
    end
end

--------------------------------------------------
-- POWER BAR UTILITIES
--------------------------------------------------

function MMF_SetPowerBarSize(width, height)
    if not width or not height then return end
    
    local frames = { MMF_PlayerFrame, MMF_TargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.powerBarFrame then
            frame.powerBarFrame:SetSize(width + 2, height + 2)
            frame.powerBarBG:SetWidth(width)
            frame.powerBarBG:SetHeight(height)
            frame.powerBar:SetWidth(width)
            frame.powerBar:SetHeight(height)
            frame.powerBarFG:SetHeight(height)
        end
    end
    
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.powerBarWidth = width
    MattMinimalFramesDB.powerBarHeight = height
end

function MMF_SetPowerBarOffset(verticalOffset, horizontalOffset)
    if not verticalOffset then return end
    horizontalOffset = horizontalOffset or cfg.POWER_BAR_HORIZONTAL_OFFSET
    
    local frames = { MMF_PlayerFrame, MMF_TargetFrame }
    for _, frame in ipairs(frames) do
        if frame and frame.powerBarBorder then
            frame.powerBarBorder:ClearAllPoints()
            if frame.unit == "player" then
                frame.powerBarBorder:SetPoint("BOTTOM", frame, "BOTTOM", 0, verticalOffset)
                frame.powerBarBorder:SetPoint("RIGHT", frame, "RIGHT", -horizontalOffset, 0)
            else
                frame.powerBarBorder:SetPoint("BOTTOM", frame, "BOTTOM", 0, verticalOffset)
                frame.powerBarBorder:SetPoint("LEFT", frame, "LEFT", horizontalOffset, 0)
            end
        end
    end
    
    if not MattMinimalFramesDB then MattMinimalFramesDB = {} end
    MattMinimalFramesDB.powerBarVerticalOffset = verticalOffset
    MattMinimalFramesDB.powerBarHorizontalOffset = horizontalOffset
end

function MMF_UpdatePowerBarVisibility()
    -- Player power bar
    if MMF_PlayerFrame and MMF_PlayerFrame.powerBarFrame then
        MMF_PlayerFrame.powerBarFrame:SetShown(MattMinimalFramesDB.showPlayerPowerBar ~= false)
        MMF_PlayerFrame.powerText:SetShown(MattMinimalFramesDB.showPlayerPowerBar ~= false)
    end
    
    -- Target power bar
    if MMF_TargetFrame and MMF_TargetFrame.powerBarFrame then
        MMF_TargetFrame.powerBarFrame:SetShown(MattMinimalFramesDB.showTargetPowerBar ~= false)
        MMF_TargetFrame.powerText:SetShown(MattMinimalFramesDB.showTargetPowerBar ~= false)
    end
end


