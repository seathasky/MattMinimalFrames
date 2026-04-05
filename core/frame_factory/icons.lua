local function GetPlayerFrameIconMode()
    local mode = MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMode or nil
    if mode == "sharedmedia" and MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMediaType == "jiberish" then
        return "jiberish"
    end
    if mode == "off" or mode == "class" or mode == "portrait" or mode == "sharedmedia" or mode == "jiberish" then
        return mode
    end
    if MattMinimalFramesDB and MattMinimalFramesDB.showPlayerClassIcon ~= nil then
        if MattMinimalFramesDB.showPlayerClassIcon then
            return "class"
        end
        return "off"
    end
    return "off"
end

local function GetTargetFrameIconMode()
    local mode = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMode or nil
    if mode == "sharedmedia" and MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMediaType == "jiberish" then
        return "jiberish"
    end
    if mode == "off" or mode == "class" or mode == "portrait" or mode == "sharedmedia" or mode == "jiberish" then
        return mode
    end
    if MattMinimalFramesDB and MattMinimalFramesDB.showTargetFrameIcon ~= nil then
        if MattMinimalFramesDB.showTargetFrameIcon then
            return "class"
        end
        return "off"
    end
    return "off"
end

local function ClampIconOffset(value)
    local offset = tonumber(value) or 0
    if offset < -200 then offset = -200 end
    if offset > 200 then offset = 200 end
    return math.floor(offset + 0.5)
end

local function GetIconOffsetsForUnit(unit)
    if unit == "player" then
        local x = MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconXOffset or 0
        local y = MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconYOffset or 0
        return ClampIconOffset(x), ClampIconOffset(y)
    elseif unit == "target" then
        local x = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconXOffset or 0
        local y = MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconYOffset or 0
        return ClampIconOffset(x), ClampIconOffset(y)
    end
    return 0, 0
end

local function ClampIconScale(value)
    local scale = tonumber(value) or 1
    if scale < 0.5 then scale = 0.5 end
    if scale > 3.0 then scale = 3.0 end
    return scale
end

local function GetIconScaleForUnit(unit)
    if unit == "player" then
        return ClampIconScale(MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconScale or 1)
    elseif unit == "target" then
        return ClampIconScale(MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconScale or 1)
    end
    return 1
end

local function ApplySingleIconPlacement(frame, icon, unit)
    if not frame or not icon or (unit ~= "player" and unit ~= "target") then
        return
    end

    local baseSize = math.max(8, (frame:GetHeight() or frame.originalHeight or 28))
    local iconSize = math.max(8, math.floor((baseSize * GetIconScaleForUnit(unit)) + 0.5))
    local xOffset, yOffset = GetIconOffsetsForUnit(unit)
    icon:SetSize(iconSize, iconSize)

    icon:ClearAllPoints()
    if unit == "player" then
        icon:SetPoint("RIGHT", frame, "LEFT", xOffset, yOffset)
    else
        icon:SetPoint("LEFT", frame, "RIGHT", xOffset, yOffset)
    end
end

local function ApplyFrameIconPlacement(frame)
    if not frame or not frame.unit then return end
    if frame.unit == "player" and frame.classIcon then
        ApplySingleIconPlacement(frame, frame.classIcon, "player")
    elseif frame.unit == "target" and frame.targetIcon then
        ApplySingleIconPlacement(frame, frame.targetIcon, "target")
    end
end

local function ApplySharedMediaIconTexture(icon, mediaKey, mediaType, classToken)
    if not icon or not MMF_GetIconTexturePath then
        return false
    end
    local path = MMF_GetIconTexturePath(mediaKey, mediaType)
    if type(path) ~= "string" or path == "" then
        return false
    end
    icon:SetTexture(path)
    local coords = MMF_GetIconTextureCoords and MMF_GetIconTextureCoords(mediaKey, mediaType, classToken)
    if mediaType == "jiberish" and (type(coords) ~= "table" or #coords < 8) then
        return false
    end
    if type(coords) == "table" and #coords >= 8 then
        icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4], coords[5], coords[6], coords[7], coords[8])
    else
        icon:SetTexCoord(0, 1, 0, 1)
    end
    icon:Show()
    return true
end

local function ApplyPlayerFrameIconMode(frame, mode)
    if not frame or not frame.classIcon then return end

    ApplyFrameIconPlacement(frame)
    mode = mode or GetPlayerFrameIconMode()
    local icon = frame.classIcon
    if mode == "off" then
        icon:Hide()
        return
    end

    if mode == "portrait" then
        if SetPortraitTexture then
            SetPortraitTexture(icon, "player")
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        icon:SetTexCoord(0, 1, 0, 1)
        icon:Show()
        return
    end

    if mode == "sharedmedia" or mode == "jiberish" then
        local mediaKey = (MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconStyle) or (MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMediaKey)
        local mediaType = (mode == "jiberish" and "jiberish") or (MattMinimalFramesDB and MattMinimalFramesDB.playerFrameIconMediaType) or "jiberish"
        local _, classToken = UnitClass("player")
        if ApplySharedMediaIconTexture(icon, mediaKey, mediaType, classToken) then
            return
        end
        icon:Hide()
        return
    end

    local _, classFile = UnitClass("player")
    local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
    if not coords then
        icon:Hide()
        return
    end
    icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    local inset = 0.02
    icon:SetTexCoord(coords[1] + inset, coords[2] - inset, coords[3] + inset, coords[4] - inset)
    icon:Show()
end

local function ApplyTargetFrameIconMode(frame, mode)
    if not frame or not frame.targetIcon then return end

    ApplyFrameIconPlacement(frame)
    mode = mode or GetTargetFrameIconMode()
    local icon = frame.targetIcon
    if mode == "off" then
        icon:Hide()
        return
    end

    if not UnitExists("target") then
        icon:Hide()
        return
    end

    if mode == "portrait" then
        if SetPortraitTexture then
            SetPortraitTexture(icon, "target")
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        icon:SetTexCoord(0, 1, 0, 1)
        icon:Show()
        return
    end

    if mode == "sharedmedia" or mode == "jiberish" then
        local mediaKey = (MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconStyle) or (MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMediaKey)
        local mediaType = (mode == "jiberish" and "jiberish") or (MattMinimalFramesDB and MattMinimalFramesDB.targetFrameIconMediaType) or "jiberish"
        local _, classToken = UnitClass("target")
        if ApplySharedMediaIconTexture(icon, mediaKey, mediaType, classToken) then
            return
        end
        icon:Hide()
        return
    end

    if UnitIsPlayer("target") then
        local _, classFile = UnitClass("target")
        local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
        if coords then
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            local inset = 0.02
            icon:SetTexCoord(coords[1] + inset, coords[2] - inset, coords[3] + inset, coords[4] - inset)
            icon:Show()
            return
        end
    end

    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    if SetRaidTargetIconTexture then
        local ok = pcall(SetRaidTargetIconTexture, icon, 8)
        if ok then
            icon:Show()
            return
        end
    end
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    icon:SetTexCoord(0.75, 1.0, 0.5, 1.0)
    icon:Show()
end

local function CreatePlayerClassIcon(frame)
    if not frame or frame.classIcon then return end
    if not frame.nameOverlay then return end

    local classIcon = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    local iconSize = math.max(8, (frame:GetHeight() or frame.originalHeight or 28))
    classIcon:SetSize(iconSize, iconSize)
    frame.classIcon = classIcon
    ApplyFrameIconPlacement(frame)

    ApplyPlayerFrameIconMode(frame, GetPlayerFrameIconMode())
end

local function CreateTargetFrameIcon(frame)
    if not frame or frame.targetIcon then return end
    if not frame.nameOverlay then return end

    local targetIcon = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    local iconSize = math.max(8, (frame:GetHeight() or frame.originalHeight or 28))
    targetIcon:SetSize(iconSize, iconSize)
    frame.targetIcon = targetIcon
    ApplyFrameIconPlacement(frame)

    ApplyTargetFrameIconMode(frame, GetTargetFrameIconMode())
end

_G.MMF_FrameFactoryIcons = {
    GetPlayerFrameIconMode = GetPlayerFrameIconMode,
    GetTargetFrameIconMode = GetTargetFrameIconMode,
    ClampIconOffset = ClampIconOffset,
    GetIconOffsetsForUnit = GetIconOffsetsForUnit,
    ClampIconScale = ClampIconScale,
    GetIconScaleForUnit = GetIconScaleForUnit,
    ApplySingleIconPlacement = ApplySingleIconPlacement,
    ApplyFrameIconPlacement = ApplyFrameIconPlacement,
    ApplySharedMediaIconTexture = ApplySharedMediaIconTexture,
    ApplyPlayerFrameIconMode = ApplyPlayerFrameIconMode,
    ApplyTargetFrameIconMode = ApplyTargetFrameIconMode,
    CreatePlayerClassIcon = CreatePlayerClassIcon,
    CreateTargetFrameIcon = CreateTargetFrameIcon,
}
