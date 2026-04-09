local trackedPartyRaidNameStyles = setmetatable({}, { __mode = "k" })
local trackedPartyRaidHealthTextStyles = setmetatable({}, { __mode = "k" })
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

    if type(_G.InCombatLockdown) == "function" and _G.InCombatLockdown() then
        pendingPartySelfVisibilityRefresh = true
        return
    end

    pendingPartySelfVisibilityRefresh = false
    local shouldHideSelf = ShouldHideSelfInPartyNow()
    local changedAnyFrame = false

    for _, memberUnitFrame in ipairs(compactPartyFrame.memberUnitFrames) do
        local unitToken = memberUnitFrame and (memberUnitFrame.unit or memberUnitFrame.displayedUnit or memberUnitFrame.unitToken) or nil
        if memberUnitFrame and IsPlayerLikeUnitToken(unitToken) then
            if shouldHideSelf then
                if memberUnitFrame:IsShown() then
                    changedAnyFrame = true
                end
                memberUnitFrame:Hide()
            else
                changedAnyFrame = true
                memberUnitFrame:Show()
            end
        end
    end

    if changedAnyFrame and type(compactPartyFrame.UpdateLayout) == "function" then
        pcall(compactPartyFrame.UpdateLayout, compactPartyFrame)
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
    -- Fallback: member frames usually live under the raid container hierarchy.
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

    if type(_G.CompactUnitFrameProfiles_SetSetting) == "function" then
        pcall(_G.CompactUnitFrameProfiles_SetSetting, "healthText", normalizedMode)
    end
    if type(_G.SetCVar) == "function" then
        pcall(_G.SetCVar, "raidFramesHealthText", normalizedMode)
    end
    if type(_G.C_CVar) == "table" and type(_G.C_CVar.SetCVar) == "function" then
        pcall(_G.C_CVar.SetCVar, "raidFramesHealthText", normalizedMode)
    end

    if type(_G.CompactUnitFrameProfiles_ApplyCurrentSettings) == "function" then
        pcall(_G.CompactUnitFrameProfiles_ApplyCurrentSettings)
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

    if type(_G.CompactUnitFrameProfiles_GetSetting) == "function" then
        local ok, value = pcall(_G.CompactUnitFrameProfiles_GetSetting, "healthText")
        if ok then
            mode = value
        end
    end
    if not mode and type(_G.GetCVar) == "function" then
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
        points[#points + 1] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs,
        }
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

local function RestorePartyRaidNameFont(fontString, original)
    local path = original and original.path
    local size = tonumber((fontString.GetFont and select(2, fontString:GetFont())) or (original and original.size)) or 10
    local flags = (original and original.flags) or ""
    if type(path) == "string" and path ~= "" then
        pcall(fontString.SetFont, fontString, path, size, flags)
    elseif MMF_SetFontSafe then
        MMF_SetFontSafe(fontString, STANDARD_TEXT_FONT, size, flags)
    else
        pcall(fontString.SetFont, fontString, STANDARD_TEXT_FONT, size, flags)
    end
end

local function RestorePartyRaidNameLayout(fontString, original)
    if not fontString or not fontString.ClearAllPoints or not fontString.SetPoint then
        return
    end
    fontString:ClearAllPoints()
    local restored = false
    if original and type(original.points) == "table" then
        for _, pointData in ipairs(original.points) do
            if pointData and pointData.point then
                fontString:SetPoint(
                    pointData.point,
                    pointData.relativeTo,
                    pointData.relativePoint,
                    pointData.xOfs,
                    pointData.yOfs
                )
                restored = true
            end
        end
    end
    if not restored then
        fontString:SetPoint("LEFT")
    end

    if original and fontString.SetJustifyH then
        fontString:SetJustifyH(original.justifyH or "LEFT")
    end
    if original and fontString.SetJustifyV then
        fontString:SetJustifyV(original.justifyV or "MIDDLE")
    end
end

local function ApplyPartyRaidNameFont(fontString, frame)
    if not IsFontString(fontString) then
        return
    end
    CapturePartyRaidNameStyle(fontString)

    local original = trackedPartyRaidNameStyles[fontString]
    local fontPath = (original and original.path) or STANDARD_TEXT_FONT
    if MattMinimalFramesDB and MattMinimalFramesDB.useSharedPartyRaidNameFont == true then
        fontPath = (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or STANDARD_TEXT_FONT
    end
    local _, currentSize, currentFlags = fontString:GetFont()
    local size = tonumber(currentSize) or 10
    local sizeSetting = nil
    if MattMinimalFramesDB then
        if IsBlizzardCompactRaidMemberFrame(frame) then
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
    if MattMinimalFramesDB and MattMinimalFramesDB.partyRaidNameOutline == true then
        flags = EnsureOutlineFlag(flags)
    end

    if MMF_SetFontSafe then
        MMF_SetFontSafe(fontString, fontPath, size, flags)
    else
        pcall(fontString.SetFont, fontString, fontPath, size, flags)
    end
end

local function ApplyPartyRaidNameCenter(fontString, frame)
    if not IsFontString(fontString) then
        return
    end
    CapturePartyRaidNameStyle(fontString)

    if fontString.SetJustifyH then
        fontString:SetJustifyH("CENTER")
    end
    if fontString.SetJustifyV then
        fontString:SetJustifyV("MIDDLE")
    end

    -- Anchor to the unit frame itself to avoid tainting Blizzard health bar state.
    local anchor = frame
    if anchor and fontString.ClearAllPoints and fontString.SetPoint then
        fontString:ClearAllPoints()
        fontString:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    end
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

local function ApplyRaidNameTruncation(fontString, frame)
    if not IsFontString(fontString) then
        return
    end
    if not IsStylablePartyRaidNameFrame(frame) then
        return
    end

    local truncateLen = GetPartyRaidNameTruncateLength(frame)

    local fullName = fontString.GetText and fontString:GetText() or nil
    if type(fullName) ~= "string" or fullName == "" then
        return
    end

    local nextText = TruncatePartyRaidNameText(fullName, truncateLen)
    local currentText = fontString.GetText and fontString:GetText() or nil
    if nextText and nextText ~= currentText then
        pcall(fontString.SetText, fontString, nextText)
    end
end

local function RestoreTrackedPartyRaidNameStyles()
    for fontString, original in pairs(trackedPartyRaidNameStyles) do
        if IsFontString(fontString) and type(original) == "table" then
            RestorePartyRaidNameFont(fontString, original)
            RestorePartyRaidNameLayout(fontString, original)
        end
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
        pcall(fontString.SetFont, fontString, path, size, flags)
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
        pcall(fontString.SetFont, fontString, path, newSize, flags or "")
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

    -- Disabled: do not apply runtime HP text size/style overrides here.
    -- Keep Blizzard text sizing untouched.
    local shouldStyle = false

    local candidates = {
        frame.healthText,
        frame.statusText,
        frame.healthBar and frame.healthBar.healthText,
        frame.healthBar and frame.healthBar.statusText,
        frame.healthBar and frame.healthBar.StatusText,
        frame.healthBar and frame.healthBar.TextString,
        frame.healthBar and frame.healthBar.text,
    }

    -- Blizzard may use different health-text regions across versions; include
    -- all FontStrings under the healthBar tree as additional candidates.
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

    if MattMinimalFramesDB and MattMinimalFramesDB.useSharedPartyRaidNameFont == true then
        ApplyPartyRaidNameFont(fontString, frame)
    elseif original then
        RestorePartyRaidNameFont(fontString, original)
    end
    if MattMinimalFramesDB
        and MattMinimalFramesDB.useSharedPartyRaidNameFont == true
        and MattMinimalFramesDB.centerPartyRaidNames == true
    then
        ApplyPartyRaidNameCenter(fontString, frame)
    elseif original then
        RestorePartyRaidNameLayout(fontString, original)
    end
    if MattMinimalFramesDB and MattMinimalFramesDB.useSharedPartyRaidNameFont == true then
        ApplyRaidNameTruncation(fontString, frame)
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
    local seen = {}
    local function Visit(frame)
        if not IsStylablePartyRaidNameFrame(frame) then
            return
        end
        if IsPartyRaidNameStylingEnabled() then
            ApplyPartyRaidNameStyleForFrame(frame)
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
        -- Enabling solo-party should guarantee the party frames system is shown.
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

    if type(_G.CompactPartyFrame_UpdateVisibility) == "function" then
        pcall(_G.CompactPartyFrame_UpdateVisibility)
    end
    if type(_G.CompactPartyFrame_Generate) == "function" then
        pcall(_G.CompactPartyFrame_Generate)
    end
    if _G.CompactPartyFrame and type(_G.CompactPartyFrame.TryUpdate) == "function" then
        pcall(_G.CompactPartyFrame.TryUpdate, _G.CompactPartyFrame)
    end

    if _G.CompactPartyFrame and (not soloPartyVisibilityHookInstalled) and type(hooksecurefunc) == "function" then
        hooksecurefunc(_G.CompactPartyFrame, "UpdateVisibility", function()
            ApplySoloPartyFrameOverrideFromDB()
        end)
        soloPartyVisibilityHookInstalled = true
    end

    ApplySoloPartyFrameOverrideFromDB()
end

function MMF_UpdateBlizzardPartySelfVisibility()
    EnsurePartySelfVisibilityHook()

    if type(_G.CompactPartyFrame_Generate) == "function" then
        pcall(_G.CompactPartyFrame_Generate)
    end
    if _G.CompactPartyFrame and type(_G.CompactPartyFrame.TryUpdate) == "function" then
        pcall(_G.CompactPartyFrame.TryUpdate, _G.CompactPartyFrame)
    end

    ApplyHideSelfToCompactPartyFrame()
end

local function EnsurePartyRaidNameHook()
    if type(hooksecurefunc) ~= "function" then
        return
    end
    if not compactPartyRaidNameHookState.compactUnitFrameUpdateName and type(_G.CompactUnitFrame_UpdateName) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleForFrame(frame)
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
                ApplyPartyRaidNameStyleForFrame(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameUpdateAll = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameSetUnit and type(_G.CompactUnitFrame_SetUnit) == "function" then
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleForFrame(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameSetUnit = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameSetOptionTable and type(_G.CompactUnitFrame_SetOptionTable) == "function" then
        hooksecurefunc("CompactUnitFrame_SetOptionTable", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleForFrame(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameSetOptionTable = true
    end
    if not compactPartyRaidNameHookState.compactUnitFrameSetUpFrame and type(_G.CompactUnitFrame_SetUpFrame) == "function" then
        hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleForFrame(frame)
            end
        end)
        compactPartyRaidNameHookState.compactUnitFrameSetUpFrame = true
    end
    if type(_G.PartyMemberFrameMixin) == "table" then
        if not compactPartyRaidNameHookState.partyMemberUpdateMember and type(_G.PartyMemberFrameMixin.UpdateMember) == "function" then
            hooksecurefunc(_G.PartyMemberFrameMixin, "UpdateMember", function(self)
                if IsPartyRaidNameStylingEnabled() then
                    ApplyPartyRaidNameStyleForFrame(self)
                end
            end)
            compactPartyRaidNameHookState.partyMemberUpdateMember = true
        end
        if not compactPartyRaidNameHookState.partyMemberUpdateNameTextAnchors and type(_G.PartyMemberFrameMixin.UpdateNameTextAnchors) == "function" then
            hooksecurefunc(_G.PartyMemberFrameMixin, "UpdateNameTextAnchors", function(self)
                if IsPartyRaidNameStylingEnabled() then
                    ApplyPartyRaidNameStyleForFrame(self)
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
        MMF_RefreshBlizzardPartyRaidNameFonts()
    else
        RestoreTrackedPartyRaidNameStyles()
        RestoreTrackedPartyRaidHealthTextStyles()
        MMF_RefreshBlizzardPartyRaidNameFonts()
    end
    if MMF_UpdateBlizzardPartyRaidLabels then
        MMF_UpdateBlizzardPartyRaidLabels()
    end
end

local partyRaidRefreshEventFrame = CreateFrame("Frame")
partyRaidRefreshEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
partyRaidRefreshEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
partyRaidRefreshEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
if IsRetailClient() then
    partyRaidRefreshEventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
end
partyRaidRefreshEventFrame:SetScript("OnEvent", function()
    if MMF_UpdateBlizzardPartyRaidNameFonts then
        MMF_UpdateBlizzardPartyRaidNameFonts()
    end
    if MMF_UpdateBlizzardPartySelfVisibility then
        MMF_UpdateBlizzardPartySelfVisibility()
    elseif pendingPartySelfVisibilityRefresh then
        ApplyHideSelfToCompactPartyFrame()
    end
end)
