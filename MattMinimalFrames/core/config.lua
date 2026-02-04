-- core/config.lua
-- Constants and configuration for MattMinimalFrames

MMF_Config = {
    -- Power bar defaults
    POWER_BAR_WIDTH = 73,
    POWER_BAR_HEIGHT = 5,
    POWER_BAR_VERTICAL_OFFSET = -24,
    POWER_BAR_HORIZONTAL_OFFSET = 1,
    
    -- Aura settings
    AURA_ICON_SPACING = 2,
    MAX_AURA_ICONS = 12,
    AURA_ROW_ICONS = 4,
    
    -- Update intervals
    UPDATE_INTERVAL = 0.1,
    
    -- Font path
    FONT_PATH = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf",
    
    -- Texture paths
    TEXTURE_PATH = "Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga",
    SHIELD_TEXTURE_PATH = "Interface\\AddOns\\MattMinimalFrames\\Textures\\shield.tga",
    
    -- Frame definitions (unit, name, width, height, x, y, label)
    FRAME_DEFINITIONS = {
        { unit = "player",       name = "MMF_PlayerFrame",         width = 220, height = 28, x = -150, y = 0,    label = "Player Frame" },
        { unit = "target",       name = "MMF_TargetFrame",         width = 220, height = 28, x = 150,  y = 0,    label = "Target Frame" },
        { unit = "targettarget", name = "MMF_TargetOfTargetFrame", width = 100, height = 28, x = 0,    y = -100, label = "Target of Target" },
        { unit = "pet",          name = "MMF_PetFrame",            width = 100, height = 28, x = -300, y = -100, label = "Pet Frame" },
        { unit = "focus",        name = "MMF_FocusFrame",          width = 100, height = 28, x = 300,  y = -100, label = "Focus Frame" },
    },
}

-- Helper to get all frame objects (call after frames are created)
function MMF_GetAllFrames()
    return {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }
end

-- Unit-to-frame mapping (call after frames are created)
function MMF_GetFrameForUnit(unit)
    local map = {
        player = MMF_PlayerFrame,
        target = MMF_TargetFrame,
        targettarget = MMF_TargetOfTargetFrame,
        pet = MMF_PetFrame,
        focus = MMF_FocusFrame,
    }
    return map[unit]
end

-- Get frame definition by unit
function MMF_GetFrameDefinition(unit)
    for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
        if def.unit == unit then
            return def
        end
    end
    return nil
end

-- Utility: Format large numbers
function MMF_FormatNumber(num)
    if type(num) ~= "number" then return "0" end
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

-- Utility: Get unit color based on class/faction
function MMF_GetUnitColor(unit)
    if not unit then return 1, 1, 1 end
    
    -- For players (friendly or enemy)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local colors = RAID_CLASS_COLORS[class]
            if colors then
                return colors.r, colors.g, colors.b
            end
        end
    -- For NPCs
    else
        if UnitIsEnemy("player", unit) then
            return 0.8, 0.2, 0.2  -- Red for hostile
        elseif not UnitIsFriend("player", unit) then
            return 1, 1, 0  -- Yellow for neutral
        else
            return 0.2, 0.8, 0.2  -- Green for friendly
        end
    end
    
    return 1, 1, 1
end

-- Utility: Reset secure attributes on a frame
function MMF_ResetSecureAttributes(frame)
    if not frame or not frame.unit then return end
    frame:SetAttribute("unit", frame.unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("target", frame.unit)
    frame:SetAttribute("type2", "togglemenu")
    frame:SetAttribute("alt-type2", "focus")
    frame:SetAttribute("focus", frame.unit)
    frame:SetAttribute("shift-alt-type2", "macro")
    frame:SetAttribute("shift-alt-macrotext2", "/clearfocus")
end

-- DB helper functions
function MMF_GetAuraIconSize()
    return (MattMinimalFramesDB and MattMinimalFramesDB.auraIconSize) or 18
end

function MMF_GetAuraTextScale()
    return (MattMinimalFramesDB and MattMinimalFramesDB.auraTextScale) or 1.0
end

function MMF_GetTimerTextScale()
    return (MattMinimalFramesDB and MattMinimalFramesDB.timerTextScale) or 1.0
end

function MMF_GetBuffXOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.buffXOffset) or -3
end

function MMF_GetBuffYOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.buffYOffset) or -60
end

function MMF_GetDebuffXOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.debuffXOffset) or 3
end

function MMF_GetDebuffYOffset()
    return (MattMinimalFramesDB and MattMinimalFramesDB.debuffYOffset) or 27
end

function MMF_GetNameTextSize()
    return (MattMinimalFramesDB and MattMinimalFramesDB.nameTextSize) or 12
end

function MMF_GetHPTextSize()
    return (MattMinimalFramesDB and MattMinimalFramesDB.hpTextSize) or 13
end

function MMF_UpdateNameTextSize(size)
    local frames = {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }
    
    local fontPath = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    for _, frame in ipairs(frames) do
        if frame and frame.nameText then
            frame.nameText:SetFont(fontPath, size, "OUTLINE")
            -- Force text refresh
            if frame.unit and UnitExists(frame.unit) then
                local currentText = frame.nameText:GetText()
                frame.nameText:SetText("")
                frame.nameText:SetText(currentText)
            end
        end
    end
end

function MMF_UpdateHPTextSize(size)
    local frames = {
        MMF_PlayerFrame,
        MMF_TargetFrame,
        MMF_TargetOfTargetFrame,
        MMF_PetFrame,
        MMF_FocusFrame
    }
    
    local fontPath = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    for _, frame in ipairs(frames) do
        if frame and frame.hpText then
            frame.hpText:SetFont(fontPath, size, "OUTLINE")
            -- Force text refresh by updating the display
            pcall(function()
                if frame.unit and UnitExists(frame.unit) then
                    local currentText = frame.hpText:GetText()
                    if currentText then
                        frame.hpText:SetText("")
                        C_Timer.After(0.01, function()
                            frame.hpText:SetText(currentText)
                        end)
                    end
                end
            end)
        end
    end
end

-- Frame scale functions
function MMF_GetFrameScaleX(unit)
    if not MattMinimalFramesDB then return 1.0 end
    local key = unit:gsub("targettarget", "tot") .. "FrameScaleX"
    return MattMinimalFramesDB[key] or 1.0
end

function MMF_GetFrameScaleY(unit)
    if not MattMinimalFramesDB then return 1.0 end
    local key = unit:gsub("targettarget", "tot") .. "FrameScaleY"
    return MattMinimalFramesDB[key] or 1.0
end

function MMF_UpdateFrameScale(unit)
    local frame = MMF_GetFrameForUnit(unit)
    if not frame then return end
    
    -- Get the original dimensions from the frame definition
    local def = MMF_GetFrameDefinition(unit)
    if not def then return end
    
    local originalWidth = def.width
    local originalHeight = def.height
    
    -- Get scale values
    local scaleX = MMF_GetFrameScaleX(unit)
    local scaleY = MMF_GetFrameScaleY(unit)
    
    -- Calculate new dimensions
    local newWidth = originalWidth * scaleX
    local newHeight = originalHeight * scaleY
    
    -- Apply new size
    frame:SetSize(newWidth, newHeight)
    
    -- Update stored original dimensions for text width calculations
    frame.originalWidth = newWidth
    frame.originalHeight = newHeight
    
    -- Update health bar to match new frame size
    if frame.healthBar then
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end
    
    -- Update absorb bar height if present
    if frame.absorbBar then
        frame.absorbBar:SetHeight(frame.healthBar:GetHeight() or 20)
    end
    
    -- Update name text width
    if frame.nameText then
        frame.nameText:SetWidth(newWidth - 4)
    end
    
    -- Update cast bar if present (target frame)
    if frame.castBarBG then
        frame.castBarBG:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
        frame.castBarBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end
end

-- Apply all frame scales (call on load)
function MMF_ApplyAllFrameScales()
    local units = {"player", "target", "targettarget", "focus", "pet"}
    for _, unit in ipairs(units) do
        MMF_UpdateFrameScale(unit)
    end
end
