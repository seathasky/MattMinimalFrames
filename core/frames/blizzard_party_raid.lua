local trackedPartyRaidNameStyles = setmetatable({}, { __mode = "k" })
local trackedPartyRaidHealthTextStyles = setmetatable({}, { __mode = "k" })
local cachedPartyRaidNameFontState = setmetatable({}, { __mode = "k" })
local cachedPartyRaidNameCenterState = setmetatable({}, { __mode = "k" })
local cachedPartyRaidNameModeState = setmetatable({}, { __mode = "k" })
local compactPartyRaidNameHookState = {
    compactUnitFrameUpdateName = false,
    compactUnitFrameUpdateHealth = false,
    compactUnitFrameUpdateHealthText = false,
    compactUnitFrameUpdateStatusText = false,
    compactUnitFrameUpdateAll = false,
    compactUnitFrameSetUnit = false,
    compactUnitFrameSetOptionTable = false,
    compactUnitFrameSetUpFrame = false,
    partyMemberUpdateMember = false,
    partyMemberUpdateNameTextAnchors = false,
}
local compactPartyRaidLabelHookState = {
    raidGroupInitialize = false,
    raidGroupLayout = false,
    partyGenerate = false,
    raidContainerLayout = false,
}
local soloPartyVisibilityHookInstalled = false
local partySelfVisibilityHookInstalled = false
local pendingPartySelfVisibilityRefresh = false
local pendingPartyRaidRosterRefresh = false
local QueuePartyRaidNameStyle
local hiddenPartySelfFrames = setmetatable({}, { __mode = "k" })

local function IsAccessibleString(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    if canaccessvalue and not canaccessvalue(value) then
        return false
    end
    return type(value) == "string"
end
local function IsReadableStyleValue(value)
    return not (issecretvalue and issecretvalue(value))
        and not (canaccessvalue and not canaccessvalue(value))
end

local function ApplySoloPartyFrameOverrideFromDB()
    if not _G.CompactPartyFrame then
        return
    end
    local showSoloParty = MattMinimalFramesDB and MattMinimalFramesDB.showSoloPartyFrame == true
    if not showSoloParty then
        return
    end
    local inGroup = (type(_G.IsInGroup) == "function" and _G.IsInGroup()) or false
    local inRaid = (type(_G.IsInRaid) == "function" and _G.IsInRaid()) or false
    local isSolo = (not inGroup) and (not inRaid)
    if isSolo then
        _G.CompactPartyFrame:SetShown(true)
    end
end

local function IsInNonRaidGroup()
    local inGroup = (type(_G.IsInGroup) == "function" and _G.IsInGroup()) or false
    local inRaid = (type(_G.IsInRaid) == "function" and _G.IsInRaid()) or false
    return inGroup and (not inRaid)
end

local function IsHideSelfInPartyEnabled()
    return MattMinimalFramesDB and MattMinimalFramesDB.hidePlayerInPartyFrame == true
end

local function ShouldHideSelfInPartyNow()
    if not IsHideSelfInPartyEnabled() then
        return false
    end
    if not IsInNonRaidGroup() then
        return false
    end
    if _G.EditModeManagerFrame and type(_G.EditModeManagerFrame.UseRaidStylePartyFrames) == "function" then
        local ok, isRaidStyle = pcall(_G.EditModeManagerFrame.UseRaidStylePartyFrames, _G.EditModeManagerFrame)
        if ok then
            return isRaidStyle == true
        end
    end
    return true
end

local function IsPlayerLikeUnitToken(unitToken)
    if type(unitToken) ~= "string" or unitToken == "" then
        return false
    end
    if unitToken == "player" or unitToken == "vehicle" then
        return true
    end
    if type(_G.UnitIsUnit) == "function" then
        local ok, isPlayer = pcall(_G.UnitIsUnit, unitToken, "player")
        if ok and isPlayer then
            return true
        end
    end
    return false
end

local function IsCompactPartyMemberFrame(frame)
    if not frame then
        return false
    end
    local parent = frame
    for _ = 1, 8 do
        if not parent or type(parent.GetParent) ~= "function" then
            parent = nil
        else
            local ok, nextParent = pcall(parent.GetParent, parent)
            parent = ok and nextParent or nil
        end
        if not parent then
            break
        end
        if parent == _G.CompactPartyFrame then
            return true
        end
    end
    return false
end

local function ApplyHideSelfToCompactPartyFrame()
    local compactPartyFrame = _G.CompactPartyFrame
    if not compactPartyFrame or type(compactPartyFrame.memberUnitFrames) ~= "table" then
        return
    end

    
    
    
    if not IsHideSelfInPartyEnabled() and next(hiddenPartySelfFrames) == nil then
        return
    end

    if type(_G.InCombatLockdown) == "function" and _G.InCombatLockdown() then
        pendingPartySelfVisibilityRefresh = true
        return
    end

    pendingPartySelfVisibilityRefresh = false
    local shouldHideSelf = ShouldHideSelfInPartyNow()

    for _, memberUnitFrame in ipairs(compactPartyFrame.memberUnitFrames) do
        local unitToken = memberUnitFrame and (memberUnitFrame.unit or memberUnitFrame.displayedUnit or memberUnitFrame.unitToken) or nil
        if memberUnitFrame and IsPlayerLikeUnitToken(unitToken) then
            if shouldHideSelf then
                memberUnitFrame:Hide()
                hiddenPartySelfFrames[memberUnitFrame] = true
            elseif hiddenPartySelfFrames[memberUnitFrame] then
                memberUnitFrame:Show()
                hiddenPartySelfFrames[memberUnitFrame] = nil
            end
        end
    end
end

local function EnsurePartySelfVisibilityHook()
    if partySelfVisibilityHookInstalled or type(hooksecurefunc) ~= "function" then
        return
    end
    if type(_G.CompactUnitFrame_SetUnit) == "function" then
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
            if IsCompactPartyMemberFrame(frame) then
                ApplyHideSelfToCompactPartyFrame()
            end
        end)
    end
    if type(_G.CompactPartyFrame_Generate) == "function" then
        hooksecurefunc("CompactPartyFrame_Generate", function()
            ApplyHideSelfToCompactPartyFrame()
        end)
    end
    partySelfVisibilityHookInstalled = true
end

local function IsRetailClient()
    local compat = _G.MMF_Compat
    return type(compat) == "table" and compat.IsRetail == true
end

local function IsFontString(region)
    return region and region.GetObjectType and region:GetObjectType() == "FontString"
end

local function SafeGetName(frame)
    if not frame or type(frame.GetName) ~= "function" then
        return nil
    end

    local ok, name = pcall(frame.GetName, frame)
    if ok then
        return name
    end
    return nil
end

local function SafeGetParent(frame)
    if not frame or type(frame.GetParent) ~= "function" then
        return nil
    end

    local ok, parent = pcall(frame.GetParent, frame)
    if ok then
        return parent
    end
    return nil
end

local function IsBlizzardPartyRaidUnitFrame(frame)
    if not frame then
        return false
    end

    local frameName = SafeGetName(frame)
    if type(frameName) == "string" then
        if frameName:match("^CompactPartyFrame") or frameName:match("^CompactRaidFrame") then
            return true
        end
    end

    local parent = frame
    for _ = 1, 10 do
        parent = SafeGetParent(parent)
        if not parent then
            break
        end
        if parent == _G.CompactPartyFrame or parent == _G.CompactRaidFrameContainer then
            return true
        end
        local parentName = SafeGetName(parent)
        if type(parentName) == "string" then
            if parentName:match("^CompactPartyFrame") or parentName:match("^CompactRaidFrame") then
                return true
            end
        end
    end

    return false
end

local function IsBlizzardNonRaidPartyMemberFrame(frame)
    if not frame then
        return false
    end
    local unitToken = frame.unit or frame.displayedUnit or frame.unitToken
    if type(unitToken) == "string" and unitToken:match("^party%d+$") then
        return true
    end
    local frameName = SafeGetName(frame)
    if type(frameName) == "string" then
        if frameName:match("^PartyMemberFrame%d+$") or frameName:match("^PartyFrameMemberFrame%d+$") then
            return true
        end
    end
    local parent = frame
    for _ = 1, 8 do
        parent = SafeGetParent(parent)
        if not parent then
            break
        end
        if parent == _G.PartyFrame then
            return true
        end
        local parentName = SafeGetName(parent)
        if type(parentName) == "string" and parentName:match("^PartyFrame") then
            return true
        end
    end
    return false
end

local function IsBlizzardCompactRaidMemberFrame(frame)
    if not frame then
        return false
    end
    local unitToken = frame.unit or frame.displayedUnit or frame.unitToken
    if type(unitToken) == "string" and unitToken:match("^raid%d+$") then
        return true
    end
    local frameName = SafeGetName(frame)
    if type(frameName) == "string" and frameName:match("^CompactRaidFrame%d+$") then
        return true
    end
    
    local parent = frame
    for _ = 1, 8 do
        parent = SafeGetParent(parent)
        if not parent then
            break
        end
        if parent == _G.CompactRaidFrameContainer then
            return true
        end
    end
    return false
end

local function IsPartyRaidMemberUnitToken(unitToken)
    if type(unitToken) ~= "string" then
        return false
    end
    return unitToken:match("^party%d+$") ~= nil
        or unitToken:match("^raid%d+$") ~= nil
        or unitToken == "player"
        or unitToken == "vehicle"
end

local function IsStylablePartyRaidNameFrame(frame)
    if IsBlizzardNonRaidPartyMemberFrame(frame) then
        return true
    end
    if not IsBlizzardPartyRaidUnitFrame(frame) then
        return false
    end
    local unitToken = frame and (frame.unit or frame.displayedUnit or frame.unitToken) or nil
    return IsPartyRaidMemberUnitToken(unitToken)
end

local function IsPartyRaidNameStylingEnabled()
    if not MattMinimalFramesDB then
        return false
    end
    return MattMinimalFramesDB.useSharedPartyRaidNameFont == true
end

local function ApplyPartyRaidHealthTextMode(mode)
    if type(mode) ~= "string" or mode == "" then
        return
    end

    local normalizedMode = string.lower(mode)
    local getter = _G.C_CVar and _G.C_CVar.GetCVar or _G.GetCVar
    if type(getter) == "function" then
        local ok, current = pcall(getter, "raidFramesHealthText")
        if ok and IsAccessibleString(current) and string.lower(current) == normalizedMode then
            return
        end
    end

    
    
    
    
    if type(_G.C_CVar) == "table" and type(_G.C_CVar.SetCVar) == "function" then
        pcall(_G.C_CVar.SetCVar, "raidFramesHealthText", normalizedMode)
    elseif type(_G.SetCVar) == "function" then
        pcall(_G.SetCVar, "raidFramesHealthText", normalizedMode)
    end

end

local VALID_PARTY_RAID_HEALTH_TEXT_MODES = {
    none = true,
    losthealth = true,
    perchealth = true,
    health = true,
}

local function NormalizePartyRaidHealthTextMode(value)
    if type(value) ~= "string" then
        return nil
    end
    local normalized = string.lower(value)
    if VALID_PARTY_RAID_HEALTH_TEXT_MODES[normalized] then
        return normalized
    end
    return nil
end

local function GetCurrentPartyRaidHealthTextMode()
    local mode = nil

    if type(_G.GetCVar) == "function" then
        local ok, value = pcall(_G.GetCVar, "raidFramesHealthText")
        if ok then
            mode = value
        end
    end
    if not mode and type(_G.C_CVar) == "table" and type(_G.C_CVar.GetCVar) == "function" then
        local ok, value = pcall(_G.C_CVar.GetCVar, "raidFramesHealthText")
        if ok then
            mode = value
        end
    end

    return NormalizePartyRaidHealthTextMode(mode)
end

function MMF_UpdateBlizzardPartyRaidHealthText()
    if not MattMinimalFramesDB then
        return
    end
    if MattMinimalFramesDB.hidePartyRaidRemainingHealth == nil then
        MattMinimalFramesDB.hidePartyRaidRemainingHealth = true
    end

    local hideRemainingHealth = (MattMinimalFramesDB.hidePartyRaidRemainingHealth == true)

    if hideRemainingHealth then
        if MattMinimalFramesDB._mmfPartyRaidHealthTextHidden ~= true then
            local currentMode = GetCurrentPartyRaidHealthTextMode()
            if currentMode and currentMode ~= "none" then
                MattMinimalFramesDB._mmfPartyRaidHealthTextBeforeHide = currentMode
            elseif not NormalizePartyRaidHealthTextMode(MattMinimalFramesDB._mmfPartyRaidHealthTextBeforeHide) then
                MattMinimalFramesDB._mmfPartyRaidHealthTextBeforeHide = "losthealth"
            end
            MattMinimalFramesDB._mmfPartyRaidHealthTextHidden = true
        end
        ApplyPartyRaidHealthTextMode("none")
        return
    end

    local restoreMode = NormalizePartyRaidHealthTextMode(MattMinimalFramesDB._mmfPartyRaidHealthTextBeforeHide)
    if not restoreMode or restoreMode == "none" then
        restoreMode = "losthealth"
    end
    ApplyPartyRaidHealthTextMode(restoreMode)
    MattMinimalFramesDB._mmfPartyRaidHealthTextHidden = false
end

local function ApplyPartyRaidLabelVisibilityForFrame(frame)
    if not frame then
        return
    end
    if not MattMinimalFramesDB then
        return
    end

    if frame == _G.CompactPartyFrame then
        if frame.title then
            frame.title:SetShown(MattMinimalFramesDB.hidePartyFrameLabel ~= true)
        end
        return
    end

    local frameName = SafeGetName(frame)
    if type(frameName) == "string" and frameName:match("^CompactRaidGroup%d+$") then
        if frame.title then
            frame.title:SetShown(MattMinimalFramesDB.hideRaidGroupLabels ~= true)
        end
        return
    end
end

local function ApplyPartyRaidLabelVisibilityToAllFrames()
    if _G.CompactPartyFrame then
        ApplyPartyRaidLabelVisibilityForFrame(_G.CompactPartyFrame)
    end

    for groupIndex = 1, 8 do
        local groupFrame = _G["CompactRaidGroup" .. groupIndex]
        if groupFrame then
            ApplyPartyRaidLabelVisibilityForFrame(groupFrame)
        end
    end

    local container = _G.CompactRaidFrameContainer
    if container and type(container.flowFrames) == "table" then
        for _, frame in ipairs(container.flowFrames) do
            ApplyPartyRaidLabelVisibilityForFrame(frame)
        end
    end
end

local function EnsurePartyRaidLabelHook()
    if type(hooksecurefunc) ~= "function" then
        return
    end

    if not compactPartyRaidLabelHookState.raidGroupInitialize and type(_G.CompactRaidGroup_InitializeForGroup) == "function" then
        hooksecurefunc("CompactRaidGroup_InitializeForGroup", function(frame)
            ApplyPartyRaidLabelVisibilityForFrame(frame)
        end)
        compactPartyRaidLabelHookState.raidGroupInitialize = true
    end
    if not compactPartyRaidLabelHookState.raidGroupLayout and type(_G.CompactRaidGroup_UpdateLayout) == "function" then
        hooksecurefunc("CompactRaidGroup_UpdateLayout", function(frame)
            ApplyPartyRaidLabelVisibilityForFrame(frame)
        end)
        compactPartyRaidLabelHookState.raidGroupLayout = true
    end
    if not compactPartyRaidLabelHookState.partyGenerate and type(_G.CompactPartyFrame_Generate) == "function" then
        hooksecurefunc("CompactPartyFrame_Generate", function()
            if _G.CompactPartyFrame then
                ApplyPartyRaidLabelVisibilityForFrame(_G.CompactPartyFrame)
            end
        end)
        compactPartyRaidLabelHookState.partyGenerate = true
    end
    if not compactPartyRaidLabelHookState.raidContainerLayout and type(_G.CompactRaidFrameContainer_LayoutFrames) == "function" then
        hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", function()
            ApplyPartyRaidLabelVisibilityToAllFrames()
        end)
        compactPartyRaidLabelHookState.raidContainerLayout = true
    end
end

local function CapturePartyRaidNameStyle(fontString)
    if not IsFontString(fontString) then
        return
    end

    if trackedPartyRaidNameStyles[fontString] then
        return
    end

    local currentPath, currentSize, currentFlags = fontString:GetFont()
    local pointCount = (fontString.GetNumPoints and fontString:GetNumPoints()) or 0
    local points = {}
    for i = 1, pointCount do
        local point, relativeTo, relativePoint, xOfs, yOfs = fontString:GetPoint(i)
        if IsAccessibleString(point) then
            local safeRelativePoint = IsAccessibleString(relativePoint) and relativePoint or point
            points[#points + 1] = {
                point = point,
                relativeTo = relativeTo,
                relativePoint = safeRelativePoint,
                xOfs = tonumber(xOfs) or 0,
                yOfs = tonumber(yOfs) or 0,
            }
        end
    end

    trackedPartyRaidNameStyles[fontString] = {
        path = currentPath,
        size = currentSize,
        flags = currentFlags,
        justifyH = fontString.GetJustifyH and fontString:GetJustifyH() or "LEFT",
        justifyV = fontString.GetJustifyV and fontString:GetJustifyV() or "MIDDLE",
        points = points,
    }
end

local function SplitFontFlags(flags)
    local out = {}
    if type(flags) ~= "string" then
        return out
    end
    for token in flags:gmatch("%S+") do
        out[#out + 1] = token
    end
    return out
end

local function JoinFontFlags(tokens)
    if type(tokens) ~= "table" or #tokens == 0 then
        return ""
    end
    return table.concat(tokens, ",")
end

local function EnsureOutlineFlag(flags)
    local tokens = SplitFontFlags(flags)
    local hasOutline = false
    for _, token in ipairs(tokens) do
        if token == "OUTLINE" then
            hasOutline = true
            break
        end
    end
    if not hasOutline then
        tokens[#tokens + 1] = "OUTLINE"
    end
    return JoinFontFlags(tokens)
end

local function RemoveOutlineFlag(flags)
    local tokens = SplitFontFlags(flags)
    local out = {}
    for _, token in ipairs(tokens) do
        if token ~= "OUTLINE" then
            out[#out + 1] = token
        end
    end
    return JoinFontFlags(out)
end

local function RestorePartyRaidNameFont(fontString, original)
    local path = original and original.path
    local size = tonumber((fontString.GetFont and select(2, fontString:GetFont())) or (original and original.size)) or 10
    local flags = (original and original.flags) or ""
    if type(path) == "string" and path ~= "" then
        MMF_SetFontSafe(fontString, path, size, flags)
    elseif MMF_SetFontSafe then
        MMF_SetFontSafe(fontString, STANDARD_TEXT_FONT, size, flags)
    else
        MMF_SetFontSafe(fontString, STANDARD_TEXT_FONT, size, flags)
    end
    cachedPartyRaidNameFontState[fontString] = nil
end

local function RestorePartyRaidNameLayout(fontString, original)
    if not fontString or not fontString.ClearAllPoints or not fontString.SetPoint then
        return
    end
    fontString:ClearAllPoints()
    local restored = false
    if original and type(original.points) == "table" then
        for _, pointData in ipairs(original.points) do
            local point = pointData and pointData.point
            if IsAccessibleString(point) then
                local safeRelativePoint = IsAccessibleString(pointData.relativePoint) and pointData.relativePoint or point
                local ok = pcall(
                    fontString.SetPoint,
                    fontString,
                    point,
                    pointData.relativeTo,
                    safeRelativePoint,
                    tonumber(pointData.xOfs) or 0,
                    tonumber(pointData.yOfs) or 0
                )
                if ok then
                    restored = true
                end
            end
        end
    end
    if not restored then
        fontString:SetPoint("LEFT")
    end
    if fontString.SetWidth then
        fontString:SetWidth(0)
    end

    if original and fontString.SetJustifyH then
        fontString:SetJustifyH(original.justifyH or "LEFT")
    end
    if original and fontString.SetJustifyV then
        fontString:SetJustifyV(original.justifyV or "MIDDLE")
    end
    cachedPartyRaidNameCenterState[fontString] = nil
end

local function ApplyPartyRaidNameFont(fontString, frame, previewKind)
    if not IsFontString(fontString) then
        return
    end
    CapturePartyRaidNameStyle(fontString)

    local original = trackedPartyRaidNameStyles[fontString]
    local fontPath = (original and original.path) or STANDARD_TEXT_FONT
    if MattMinimalFramesDB and MattMinimalFramesDB.useSharedPartyRaidNameFont == true then
        fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or STANDARD_TEXT_FONT
    end
    local currentPath, currentSize, currentFlags = fontString:GetFont()
    local size = tonumber(currentSize) or 10
    local sizeSetting = nil
    if MattMinimalFramesDB then
        if previewKind == "raid" or (not previewKind and IsBlizzardCompactRaidMemberFrame(frame)) then
            sizeSetting = MattMinimalFramesDB.raidNameFontSize
        else
            sizeSetting = MattMinimalFramesDB.partyNameFontSize
        end
        if sizeSetting == nil then
            sizeSetting = MattMinimalFramesDB.partyRaidNameFontSize
        end
    end
    if tonumber(sizeSetting) then
        size = math.floor(tonumber(sizeSetting) + 0.5)
        if size < 6 then size = 6 end
        if size > 32 then size = 32 end
    end
    local flags = (original and original.flags) or currentFlags or ""
    local globalOutlineEnabled = not (MattMinimalFramesDB and MattMinimalFramesDB.useTextOutline == false)
    if globalOutlineEnabled and MattMinimalFramesDB and MattMinimalFramesDB.partyRaidNameOutline == true then
        flags = EnsureOutlineFlag(flags)
    elseif not globalOutlineEnabled then
        flags = RemoveOutlineFlag(flags)
    end

    local cached = cachedPartyRaidNameFontState[fontString]
    if cached and cached.path == fontPath and cached.size == size and cached.flags == flags
        and IsReadableStyleValue(currentPath) and IsReadableStyleValue(currentSize) and IsReadableStyleValue(currentFlags)
        and currentPath == fontPath and currentSize == size and currentFlags == flags then
        return
    end

    MMF_SetFontSafe(fontString, fontPath, size, flags)
    cachedPartyRaidNameFontState[fontString] = {
        path = fontPath,
        size = size,
        flags = flags,
    }
end

local function ApplyPartyRaidNameCenter(fontString, frame)
    if not IsFontString(fontString) then
        return
    end
    CapturePartyRaidNameStyle(fontString)

    local anchor = frame

    if fontString.SetJustifyH and fontString:GetJustifyH() ~= "CENTER" then
        fontString:SetJustifyH("CENTER")
    end
    if fontString.SetJustifyV and fontString:GetJustifyV() ~= "MIDDLE" then
        fontString:SetJustifyV("MIDDLE")
    end

    if anchor and fontString.ClearAllPoints and fontString.SetPoint then
        local point,relative,relativePoint,x,y=fontString:GetPoint(1)
        local matches=IsReadableStyleValue(point) and IsReadableStyleValue(relative)
            and IsReadableStyleValue(relativePoint) and IsReadableStyleValue(x) and IsReadableStyleValue(y)
            and point=="CENTER" and relative==anchor and relativePoint=="CENTER" and x==0 and y==0
        if not matches or fontString:GetNumPoints()~=1 then
            fontString:ClearAllPoints()
            fontString:SetPoint("CENTER", anchor, "CENTER", 0, 0)
        end
        if fontString.SetWidth and type(anchor.GetWidth) == "function" then
            local anchorWidth = anchor:GetWidth()
            if IsReadableStyleValue(anchorWidth) and type(anchorWidth)=="number" and anchorWidth > 0 then
                local desired=math.max(8, anchorWidth - 8)
                local current=fontString:GetWidth()
                if IsReadableStyleValue(current) and current~=desired then fontString:SetWidth(desired) end
            end
        end
    end
    cachedPartyRaidNameCenterState[fontString] = { anchor = anchor }
end

local function TruncatePartyRaidNameText(text, maxChars)
    if type(text) ~= "string" then
        return text
    end
    local limit = tonumber(maxChars) or 0
    if limit <= 0 then
        return text
    end
    if utf8len and utf8sub then
        local len = utf8len(text) or 0
        if len > limit then
            return utf8sub(text, 1, limit) .. "..."
        end
        return text
    end
    if #text > limit then
        return string.sub(text, 1, limit) .. "..."
    end
    return text
end

local function GetPartyRaidNameTruncateLength(frame)
    local db = MattMinimalFramesDB
    local truncateLen = 0

    if IsBlizzardCompactRaidMemberFrame(frame) then
        truncateLen = tonumber(db and db.raidNameTruncateLength) or 0
    else
        truncateLen = tonumber(db and db.partyNameTruncateLength) or 0
    end

    if truncateLen < 0 then
        truncateLen = 0
    end
    if truncateLen > 24 then
        truncateLen = 24
    end

    return truncateLen
end

local function GetPartyRaidDisplayName(unit)
    local fullName = GetUnitName(unit, true) or UnitName(unit)
    if not IsAccessibleString(fullName) then
        return nil
    end

    if type(_G.Ambiguate) == "function" then
        local ok, shortName = pcall(_G.Ambiguate, fullName, "short")
        if ok and IsAccessibleString(shortName) then
            return shortName
        end
    end

    local okDash, dashPos = pcall(string.find, fullName, "-", 1, true)
    if okDash and dashPos and dashPos > 1 then
        local okSub, short = pcall(string.sub, fullName, 1, dashPos - 1)
        if okSub and IsAccessibleString(short) then
            return short
        end
    end

    return fullName
end

local function ApplyRaidNameTruncation(fontString, frame)
    if not IsFontString(fontString) then
        return
    end
    if not IsStylablePartyRaidNameFrame(frame) then
        return
    end

    local truncateLen = GetPartyRaidNameTruncateLength(frame)

    local unit = frame and (frame.unit or frame.displayedUnit)
    if type(unit) ~= "string" or unit == "" then
        return
    end

    local fullName = GetPartyRaidDisplayName(unit)
    if not fullName then
        return
    end

    local nextText = TruncatePartyRaidNameText(fullName, truncateLen)
    if nextText then
        local current=fontString:GetText()
        
        if IsReadableStyleValue(current) and current~=nextText then
            pcall(fontString.SetText, fontString, nextText)
        end
    end
end

local function RestoreTrackedPartyRaidNameStyles()
    for fontString, original in pairs(trackedPartyRaidNameStyles) do
        if IsFontString(fontString) and type(original) == "table" then
            RestorePartyRaidNameFont(fontString, original)
            RestorePartyRaidNameLayout(fontString, original)
        end
        cachedPartyRaidNameModeState[fontString] = nil
        trackedPartyRaidNameStyles[fontString] = nil
    end
end

local function CapturePartyRaidHealthTextStyle(fontString)
    if not IsFontString(fontString) then
        return
    end
    if trackedPartyRaidHealthTextStyles[fontString] then
        return
    end

    local currentPath, currentSize, currentFlags = fontString:GetFont()
    trackedPartyRaidHealthTextStyles[fontString] = {
        path = currentPath,
        size = currentSize,
        flags = currentFlags,
        justifyH = fontString.GetJustifyH and fontString:GetJustifyH() or "CENTER",
        justifyV = fontString.GetJustifyV and fontString:GetJustifyV() or "MIDDLE",
    }
end

local function RestorePartyRaidHealthTextStyle(fontString, original)
    if not IsFontString(fontString) then
        return
    end
    if type(original) ~= "table" then
        return
    end

    local path = original.path
    local size = tonumber(original.size) or tonumber((fontString.GetFont and select(2, fontString:GetFont())) or 10) or 10
    local flags = original.flags or ""
    if type(path) == "string" and path ~= "" then
        MMF_SetFontSafe(fontString, path, size, flags)
    end

    if fontString.SetJustifyH then
        fontString:SetJustifyH(original.justifyH or "CENTER")
    end
    if fontString.SetJustifyV then
        fontString:SetJustifyV(original.justifyV or "MIDDLE")
    end
end

local function RestoreTrackedPartyRaidHealthTextStyles()
    for fontString, original in pairs(trackedPartyRaidHealthTextStyles) do
        if IsFontString(fontString) then
            RestorePartyRaidHealthTextStyle(fontString, original)
        end
        trackedPartyRaidHealthTextStyles[fontString] = nil
    end
end

local function ApplyPartyRaidCenteredHealthTextStyle(fontString, frame)
    if not IsFontString(fontString) then
        return
    end
    if not frame then
        return
    end
    CapturePartyRaidHealthTextStyle(fontString)

    local path, size, flags = fontString:GetFont()
    local newSize = tonumber(size) or 10
    newSize = math.max(7, math.min(18, math.floor(newSize - 2 + 0.5)))
    if type(path) == "string" and path ~= "" then
        MMF_SetFontSafe(fontString, path, newSize, flags or "")
    end

    if fontString.SetJustifyH then
        fontString:SetJustifyH("CENTER")
    end
    if fontString.SetJustifyV then
        fontString:SetJustifyV("MIDDLE")
    end
end

local function ApplyPartyRaidHealthTextStyleForFrame(frame)
    if not IsStylablePartyRaidNameFrame(frame) then
        return
    end

    local shouldStyle = false
    if not shouldStyle and next(trackedPartyRaidHealthTextStyles) == nil then
        return
    end

    local candidates = {
        frame.healthText,
        frame.statusText,
        frame.healthBar and frame.healthBar.healthText,
        frame.healthBar and frame.healthBar.statusText,
        frame.healthBar and frame.healthBar.StatusText,
        frame.healthBar and frame.healthBar.TextString,
        frame.healthBar and frame.healthBar.text,
    }

    
    
    local seenCandidates = {}
    for _, candidate in ipairs(candidates) do
        if IsFontString(candidate) then
            seenCandidates[candidate] = true
        end
    end
    local function AddCandidate(fontString)
        if not IsFontString(fontString) then
            return
        end
        if fontString == frame.name or fontString == frame.Name or fontString == frame.nameText then
            return
        end
        seenCandidates[fontString] = true
    end

    local function CollectFontStrings(region)
        if not region then
            return
        end

        if region.GetRegions then
            local regions = { region:GetRegions() }
            for _, r in ipairs(regions) do
                if IsFontString(r) then
                    AddCandidate(r)
                end
            end
        end

        if region.GetChildren then
            local children = { region:GetChildren() }
            for _, child in ipairs(children) do
                if IsFontString(child) then
                    AddCandidate(child)
                else
                    CollectFontStrings(child)
                end
            end
        end
    end

    CollectFontStrings(frame.healthBar)
    CollectFontStrings(frame)

    local resolvedCandidates = {}
    for fontString in pairs(seenCandidates) do
        resolvedCandidates[#resolvedCandidates + 1] = fontString
    end
    for _, fontString in ipairs(resolvedCandidates) do
        if IsFontString(fontString) then
            if shouldStyle then
                ApplyPartyRaidCenteredHealthTextStyle(fontString, frame)
            else
                local original = trackedPartyRaidHealthTextStyles[fontString]
                if original then
                    RestorePartyRaidHealthTextStyle(fontString, original)
                    trackedPartyRaidHealthTextStyles[fontString] = nil
                end
            end
        end
    end
end

local function ApplyPartyRaidNameStyleForFontString(fontString, frame)
    if not IsFontString(fontString) then
        return
    end
    CapturePartyRaidNameStyle(fontString)
    local original = trackedPartyRaidNameStyles[fontString]

    local useSharedFont = MattMinimalFramesDB and MattMinimalFramesDB.useSharedPartyRaidNameFont == true
    local modeState = cachedPartyRaidNameModeState[fontString]

    if useSharedFont then
        ApplyPartyRaidNameFont(fontString, frame)
        cachedPartyRaidNameModeState[fontString] = "styled"
    elseif original and modeState ~= "original" then
        RestorePartyRaidNameFont(fontString, original)
        cachedPartyRaidNameModeState[fontString] = "original"
    end

    if useSharedFont and MattMinimalFramesDB and MattMinimalFramesDB.centerPartyRaidNames == true then
        ApplyPartyRaidNameCenter(fontString, frame)
    elseif original and cachedPartyRaidNameCenterState[fontString] then
        RestorePartyRaidNameLayout(fontString, original)
    end
    if useSharedFont then
        ApplyRaidNameTruncation(fontString, frame)
    end
end



function MMF_StyleBlizzardGroupNameSample(fontString, frame, kind, sampleName)
    CapturePartyRaidNameStyle(fontString)
    local original = trackedPartyRaidNameStyles[fontString]
    if IsPartyRaidNameStylingEnabled() then
        ApplyPartyRaidNameFont(fontString, frame, kind)
        if MattMinimalFramesDB.centerPartyRaidNames == true then
            ApplyPartyRaidNameCenter(fontString, frame)
        else
            RestorePartyRaidNameLayout(fontString, original)
        end
        local limit = math.max(0, math.min(24, tonumber(MattMinimalFramesDB[kind.."NameTruncateLength"]) or 0))
        fontString:SetText(TruncatePartyRaidNameText(sampleName, limit))
    else
        RestorePartyRaidNameFont(fontString, original)
        RestorePartyRaidNameLayout(fontString, original)
        fontString:SetText(sampleName)
    end
end

local function ApplyPartyRaidNameStyleForFrame(frame)
    if not IsStylablePartyRaidNameFrame(frame) then
        return
    end

    if IsFontString(frame.name) then
        ApplyPartyRaidNameStyleForFontString(frame.name, frame)
    end
    if IsFontString(frame.Name) then
        ApplyPartyRaidNameStyleForFontString(frame.Name, frame)
    end
    if IsFontString(frame.nameText) then
        ApplyPartyRaidNameStyleForFontString(frame.nameText, frame)
    end
    ApplyPartyRaidHealthTextStyleForFrame(frame)
end

local function TraverseFrameTree(frame, visitor, seen)
    if not frame or seen[frame] then
        return
    end
    seen[frame] = true
    visitor(frame)
    
    
    if IsStylablePartyRaidNameFrame(frame) then return end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        TraverseFrameTree(child, visitor, seen)
    end
end

local function ApplyPartyRaidNameStyleToAllFrames()
    local seen = {}
    if _G.CompactPartyFrame then
        TraverseFrameTree(_G.CompactPartyFrame, ApplyPartyRaidNameStyleForFrame, seen)
    end
    if _G.CompactRaidFrameContainer then
        TraverseFrameTree(_G.CompactRaidFrameContainer, ApplyPartyRaidNameStyleForFrame, seen)
    end

    if _G.PartyFrame and _G.PartyFrame.PartyMemberFramePool and _G.PartyFrame.PartyMemberFramePool.EnumerateActive then
        for memberFrame in _G.PartyFrame.PartyMemberFramePool:EnumerateActive() do
            ApplyPartyRaidNameStyleForFrame(memberFrame)
        end
    end

    for i = 1, 4 do
        local legacyFrame = _G["PartyMemberFrame" .. i]
        if legacyFrame then
            ApplyPartyRaidNameStyleForFrame(legacyFrame)
        end
    end
end

function MMF_ApplyPartyRaidNameTruncationPreview()
    if not MattMinimalFramesDB then
        return
    end
    local seen = {}
    local function Visit(frame)
        if not IsStylablePartyRaidNameFrame(frame) then
            return
        end
        if IsFontString(frame.name) then
            ApplyRaidNameTruncation(frame.name, frame)
        end
        if IsFontString(frame.Name) then
            ApplyRaidNameTruncation(frame.Name, frame)
        end
        if IsFontString(frame.nameText) then
            ApplyRaidNameTruncation(frame.nameText, frame)
        end
    end

    if _G.CompactPartyFrame then
        TraverseFrameTree(_G.CompactPartyFrame, Visit, seen)
    end
    if _G.CompactRaidFrameContainer then
        TraverseFrameTree(_G.CompactRaidFrameContainer, Visit, seen)
    end

    if _G.PartyFrame and _G.PartyFrame.PartyMemberFramePool and _G.PartyFrame.PartyMemberFramePool.EnumerateActive then
        for memberFrame in _G.PartyFrame.PartyMemberFramePool:EnumerateActive() do
            Visit(memberFrame)
        end
    end

    for i = 1, 4 do
        local legacyFrame = _G["PartyMemberFrame" .. i]
        if legacyFrame then
            Visit(legacyFrame)
        end
    end
end

function MMF_ApplyRaidNameTruncationPreview()
    MMF_ApplyPartyRaidNameTruncationPreview()
end

function MMF_RefreshBlizzardPartyRaidNameFonts()
    if not IsPartyRaidNameStylingEnabled() then return end
    local seen = {}
    local function Visit(frame)
        if not IsStylablePartyRaidNameFrame(frame) then
            return
        end
        if IsPartyRaidNameStylingEnabled() then
            QueuePartyRaidNameStyle(frame)
        end
    end
    if _G.CompactPartyFrame then
        TraverseFrameTree(_G.CompactPartyFrame, Visit, seen)
    end
    if _G.CompactRaidFrameContainer then
        TraverseFrameTree(_G.CompactRaidFrameContainer, Visit, seen)
    end

    if _G.PartyFrame and _G.PartyFrame.PartyMemberFramePool and _G.PartyFrame.PartyMemberFramePool.EnumerateActive then
        for memberFrame in _G.PartyFrame.PartyMemberFramePool:EnumerateActive() do
            Visit(memberFrame)
        end
    end

    for i = 1, 4 do
        local legacyFrame = _G["PartyMemberFrame" .. i]
        if legacyFrame then
            Visit(legacyFrame)
        end
    end
end

function MMF_UpdateBlizzardPartyRaidLabels()
    if not MattMinimalFramesDB then
        return
    end

    EnsurePartyRaidLabelHook()
    ApplyPartyRaidLabelVisibilityToAllFrames()
    if MMF_UpdateBlizzardPartyRaidHealthText then
        MMF_UpdateBlizzardPartyRaidHealthText()
    end
end

function MMF_UpdateBlizzardSoloPartyFrameVisibility()
    local showSoloParty = MattMinimalFramesDB and MattMinimalFramesDB.showSoloPartyFrame == true
    local cvarValue = showSoloParty and "1" or "0"

    if type(_G.C_PartyInfo) == "table" then
        if type(_G.C_PartyInfo.SetPartyFramesDisplaySolo) == "function" then
            pcall(_G.C_PartyInfo.SetPartyFramesDisplaySolo, showSoloParty)
        end
        
        if showSoloParty and type(_G.C_PartyInfo.SetPartyFramesDisplayed) == "function" then
            pcall(_G.C_PartyInfo.SetPartyFramesDisplayed, true)
        end
    end

    if type(_G.SetCVar) == "function" then
        pcall(_G.SetCVar, "partyFramesDisplaySolo", cvarValue)
    end
    if type(_G.C_CVar) == "table" and type(_G.C_CVar.SetCVar) == "function" then
        pcall(_G.C_CVar.SetCVar, "partyFramesDisplaySolo", cvarValue)
    end

    if _G.CompactPartyFrame and (not soloPartyVisibilityHookInstalled) and type(hooksecurefunc) == "function"
        and type(_G.CompactPartyFrame.UpdateVisibility) == "function" then
        hooksecurefunc(_G.CompactPartyFrame, "UpdateVisibility", function()
            ApplySoloPartyFrameOverrideFromDB()
        end)
        soloPartyVisibilityHookInstalled = true
    end

    ApplySoloPartyFrameOverrideFromDB()
end

function MMF_UpdateBlizzardPartySelfVisibility()
    if IsHideSelfInPartyEnabled() then
        EnsurePartySelfVisibilityHook()
    end

    ApplyHideSelfToCompactPartyFrame()
end



local pendingNameFrames={}
local applyingNameStyle={}
local nameWorkFrame=CreateFrame("Frame")
nameWorkFrame:Hide()
QueuePartyRaidNameStyle=function(frame)
    if not frame or applyingNameStyle[frame] or not IsPartyRaidNameStylingEnabled() then return end
    pendingNameFrames[frame]=true
    nameWorkFrame:Show()
end
nameWorkFrame:SetScript("OnUpdate",function(self)
    local count=0
    for frame in pairs(pendingNameFrames) do
        pendingNameFrames[frame]=nil
        if IsPartyRaidNameStylingEnabled() and not (frame.IsForbidden and frame:IsForbidden()) then
            applyingNameStyle[frame]=true
            local ok,err=pcall(ApplyPartyRaidNameStyleForFrame,frame)
            applyingNameStyle[frame]=nil
            if not ok and MMF_Designer and MMF_Designer.Report then MMF_Designer.Report("Blizzard name styling",err) end
        end
        count=count+1
        if count>=4 then break end
    end
    if not next(pendingNameFrames) then self:Hide() end
end)
local function ApplyPartyRaidNameStyleNow(frame)
    if not frame or applyingNameStyle[frame] or not IsPartyRaidNameStylingEnabled() then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    pendingNameFrames[frame]=nil
    applyingNameStyle[frame]=true
    local ok,err=pcall(ApplyPartyRaidNameStyleForFrame,frame)
    applyingNameStyle[frame]=nil
    if not ok and MMF_Designer and MMF_Designer.Report then MMF_Designer.Report("Blizzard name styling",err) end
end
local function EnsurePartyRaidNameHook()
    if type(hooksecurefunc) ~= "function" then
        return
    end
    if not compactPartyRaidNameHookState.compactUnitFrameUpdateName and type(_G.CompactUnitFrame_UpdateName) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleNow(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameUpdateName = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameUpdateHealth and type(_G.CompactUnitFrame_UpdateHealth) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidHealthTextStyleForFrame(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameUpdateHealth = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameUpdateHealthText and type(_G.CompactUnitFrame_UpdateHealthText) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateHealthText", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidHealthTextStyleForFrame(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameUpdateHealthText = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameUpdateStatusText and type(_G.CompactUnitFrame_UpdateStatusText) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateStatusText", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidHealthTextStyleForFrame(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameUpdateStatusText = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameUpdateAll and type(_G.CompactUnitFrame_UpdateAll) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleNow(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameUpdateAll = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameSetUnit and type(_G.CompactUnitFrame_SetUnit) == "function" then
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleNow(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameSetUnit = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameSetOptionTable and type(_G.CompactUnitFrame_SetOptionTable) == "function" then
        hooksecurefunc("CompactUnitFrame_SetOptionTable", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleNow(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameSetOptionTable = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameSetUpFrame and type(_G.CompactUnitFrame_SetUpFrame) == "function" then
        hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleNow(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameSetUpFrame = true
    end
    if type(_G.PartyMemberFrameMixin) == "table" then
        if not compactPartyRaidNameHookState.partyMemberUpdateMember and type(_G.PartyMemberFrameMixin.UpdateMember) == "function" then
            hooksecurefunc(_G.PartyMemberFrameMixin, "UpdateMember", function(self)
                if IsPartyRaidNameStylingEnabled() then
                    ApplyPartyRaidNameStyleNow(self)
                end
            end)
            compactPartyRaidNameHookState.partyMemberUpdateMember = true
        end
        if not compactPartyRaidNameHookState.partyMemberUpdateNameTextAnchors and type(_G.PartyMemberFrameMixin.UpdateNameTextAnchors) == "function" then
            hooksecurefunc(_G.PartyMemberFrameMixin, "UpdateNameTextAnchors", function(self)
                if IsPartyRaidNameStylingEnabled() then
                    ApplyPartyRaidNameStyleNow(self)
                end
            end)
            compactPartyRaidNameHookState.partyMemberUpdateNameTextAnchors = true
        end
    end
end

function MMF_UpdateBlizzardPartyRaidNameFonts()
    if not MattMinimalFramesDB then
        return
    end

    EnsurePartyRaidNameHook()

    if IsPartyRaidNameStylingEnabled() then
        ApplyPartyRaidNameStyleToAllFrames()
    else
        RestoreTrackedPartyRaidNameStyles()
        RestoreTrackedPartyRaidHealthTextStyles()
    end
    if MMF_UpdateBlizzardPartyRaidLabels then
        MMF_UpdateBlizzardPartyRaidLabels()
    end
end

local function ShouldRunPartySelfVisibilityRefresh()
    if pendingPartySelfVisibilityRefresh then
        return true
    end
    return MattMinimalFramesDB and MattMinimalFramesDB.hidePlayerInPartyFrame == true
end

local function RunPartyRaidRefresh()
    pendingPartyRaidRosterRefresh = false
    if MMF_UpdateBlizzardPartyRaidNameFonts then
        MMF_UpdateBlizzardPartyRaidNameFonts()
    end
    if MMF_UpdateBlizzardPartySelfVisibility and ShouldRunPartySelfVisibilityRefresh() then
        MMF_UpdateBlizzardPartySelfVisibility()
    elseif pendingPartySelfVisibilityRefresh then
        ApplyHideSelfToCompactPartyFrame()
    end
end

local function RunPartyRaidRosterRefresh()
    pendingPartyRaidRosterRefresh = false
    if MMF_RefreshBlizzardPartyRaidNameFonts then
        MMF_RefreshBlizzardPartyRaidNameFonts()
    elseif MMF_UpdateBlizzardPartyRaidNameFonts then
        MMF_UpdateBlizzardPartyRaidNameFonts()
    end
    if MMF_UpdateBlizzardPartyRaidLabels then
        MMF_UpdateBlizzardPartyRaidLabels()
    end
    if MMF_UpdateBlizzardPartySelfVisibility and ShouldRunPartySelfVisibilityRefresh() then
        MMF_UpdateBlizzardPartySelfVisibility()
    elseif pendingPartySelfVisibilityRefresh then
        ApplyHideSelfToCompactPartyFrame()
    end
end

local function QueuePartyRaidRosterRefresh()
    if pendingPartyRaidRosterRefresh then
        return
    end
    pendingPartyRaidRosterRefresh = true

    if type(_G.C_Timer) == "table" and type(_G.C_Timer.After) == "function" then
        _G.C_Timer.After(0.05, RunPartyRaidRosterRefresh)
    else
        RunPartyRaidRosterRefresh()
    end
end

local partyRaidRefreshEventFrame = CreateFrame("Frame")
partyRaidRefreshEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
partyRaidRefreshEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
partyRaidRefreshEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
if IsRetailClient() then
    partyRaidRefreshEventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
end
partyRaidRefreshEventFrame:SetScript("OnEvent", function(_, event)
    if event == "GROUP_ROSTER_UPDATE" then
        QueuePartyRaidRosterRefresh()
        return
    end
    RunPartyRaidRefresh()
end)
