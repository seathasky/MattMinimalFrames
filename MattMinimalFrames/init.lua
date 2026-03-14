local function HideBlizzardFrames()
    local framesToHide = {
        PlayerFrame,
        TargetFrame,
        FocusFrame,
        PetFrame,
        _G.Boss1TargetFrame,
        _G.Boss2TargetFrame,
        _G.Boss3TargetFrame,
        _G.Boss4TargetFrame,
        _G.Boss5TargetFrame,
        _G.BossTargetFrameContainer,
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

    local compat = _G.MMF_Compat
    if compat and compat.IsClassicEra then
        local comboFrames = {
            _G.ComboFrame,
            _G.ComboPointPlayerFrame,
            _G.PlayerFrameComboPoints,
        }
        for _, frame in ipairs(comboFrames) do
            if frame then
                if frame.UnregisterAllEvents then
                    frame:UnregisterAllEvents()
                end
                frame:SetScript("OnShow", function(self) self:Hide() end)
                MMF_HideFrame(frame)
            end
        end
    end
end

local function UpdateBlizzardPlayerCastBarVisibility()
    local shouldHide = MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true
    local frames = {
        _G.PlayerCastingBarFrame,
        _G.CastingBarFrame,
    }

    for _, frame in ipairs(frames) do
        if frame then
            if not frame.mmfHideBlizzardCastBarHooked then
                frame:HookScript("OnShow", function(self)
                    if MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true then
                        self:Hide()
                    end
                end)
                frame.mmfHideBlizzardCastBarHooked = true
            end

            if shouldHide then
                frame:Hide()
            end
        end
    end
end

MMF_UpdateBlizzardPlayerCastBarVisibility = UpdateBlizzardPlayerCastBarVisibility

local trackedPartyRaidNameStyles = setmetatable({}, { __mode = "k" })
local compactPartyRaidNameHookInstalled = false
local compactPartyRaidLabelHookInstalled = false

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
    local unitToken = frame.unitToken
    if type(unitToken) == "string" and unitToken:match("^party%d+$") then
        return true
    end
    local frameName = SafeGetName(frame)
    if type(frameName) == "string" and frameName:match("^PartyMemberFrame%d+$") then
        return true
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

local function IsPartyRaidNameStylingEnabled()
    if not MattMinimalFramesDB then
        return false
    end
    return MattMinimalFramesDB.useSharedPartyRaidNameFont == true
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
    if compactPartyRaidLabelHookInstalled then
        return
    end
    if type(hooksecurefunc) ~= "function" then
        return
    end

    if type(_G.CompactRaidGroup_InitializeForGroup) == "function" then
        hooksecurefunc("CompactRaidGroup_InitializeForGroup", function(frame)
            ApplyPartyRaidLabelVisibilityForFrame(frame)
        end)
    end
    if type(_G.CompactRaidGroup_UpdateLayout) == "function" then
        hooksecurefunc("CompactRaidGroup_UpdateLayout", function(frame)
            ApplyPartyRaidLabelVisibilityForFrame(frame)
        end)
    end
    if type(_G.CompactPartyFrame_Generate) == "function" then
        hooksecurefunc("CompactPartyFrame_Generate", function()
            if _G.CompactPartyFrame then
                ApplyPartyRaidLabelVisibilityForFrame(_G.CompactPartyFrame)
            end
        end)
    end
    if type(_G.CompactRaidFrameContainer_LayoutFrames) == "function" then
        hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", function()
            ApplyPartyRaidLabelVisibilityToAllFrames()
        end)
    end

    compactPartyRaidLabelHookInstalled = true
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
    if not IsBlizzardCompactRaidMemberFrame(frame) and not IsBlizzardPartyRaidUnitFrame(frame) and not IsBlizzardNonRaidPartyMemberFrame(frame) then
        return
    end

    local truncateLen = GetPartyRaidNameTruncateLength(frame)

    local unitToken = frame and (frame.unit or frame.displayedUnit or frame.unitToken) or nil
    local fullName = nil
    if type(unitToken) == "string" and UnitExists and UnitExists(unitToken) and UnitName then
        local unitName = UnitName(unitToken)
        if type(unitName) == "string" and unitName ~= "" then
            fullName = unitName
        end
    end
    if not fullName or fullName == "" then
        fullName = fontString.GetText and fontString:GetText() or nil
    end
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
        and not IsBlizzardNonRaidPartyMemberFrame(frame)
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
    if not IsBlizzardPartyRaidUnitFrame(frame) and not IsBlizzardNonRaidPartyMemberFrame(frame) then
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
        if not IsBlizzardCompactRaidMemberFrame(frame) and not IsBlizzardPartyRaidUnitFrame(frame) and not IsBlizzardNonRaidPartyMemberFrame(frame) then
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
        if not IsBlizzardPartyRaidUnitFrame(frame) and not IsBlizzardNonRaidPartyMemberFrame(frame) then
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
end

local function EnsurePartyRaidNameHook()
    if compactPartyRaidNameHookInstalled then
        return
    end
    if type(hooksecurefunc) ~= "function" then
        return
    end
    if type(_G.CompactUnitFrame_UpdateName) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            if IsPartyRaidNameStylingEnabled() then
                ApplyPartyRaidNameStyleForFrame(frame)
            end
        end)
    end
    if type(_G.PartyMemberFrameMixin) == "table" then
        if type(_G.PartyMemberFrameMixin.UpdateMember) == "function" then
            hooksecurefunc(_G.PartyMemberFrameMixin, "UpdateMember", function(self)
                if IsPartyRaidNameStylingEnabled() then
                    ApplyPartyRaidNameStyleForFrame(self)
                end
            end)
        end
        if type(_G.PartyMemberFrameMixin.UpdateNameTextAnchors) == "function" then
            hooksecurefunc(_G.PartyMemberFrameMixin, "UpdateNameTextAnchors", function(self)
                if IsPartyRaidNameStylingEnabled() then
                    ApplyPartyRaidNameStyleForFrame(self)
                end
            end)
        end
    end
    compactPartyRaidNameHookInstalled = true
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
        MMF_RefreshBlizzardPartyRaidNameFonts()
    end
    if MMF_UpdateBlizzardPartyRaidLabels then
        MMF_UpdateBlizzardPartyRaidLabels()
    end
end


SLASH_MATTMINIMALFRAMES1 = "/mmf"
SlashCmdList["MATTMINIMALFRAMES"] = function()
    if MMF_ShowWelcomePopup then
        MMF_ShowWelcomePopup(true)
    end
end

SLASH_MMFRELOAD1 = "/rl"
SlashCmdList["MMFRELOAD"] = ReloadUI

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = DeepCopy(v)
    end
    return out
end

local function ApplyDefaultsSafe(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then return end
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = DeepCopy(value)
        elseif type(target[key]) == "table" and type(value) == "table" then
            ApplyDefaultsSafe(target[key], value)
        end
    end
end

local function NormalizeLegacyIconModes(db)
    if type(db) ~= "table" then return end
    if db.playerFrameIconMode == nil and db.showPlayerClassIcon ~= nil then
        db.playerFrameIconMode = db.showPlayerClassIcon and "class" or "off"
    end
    if db.targetFrameIconMode == nil and db.showTargetFrameIcon ~= nil then
        db.targetFrameIconMode = db.showTargetFrameIcon and "class" or "off"
    end
end

local function NormalizeLegacyPartyRaidFontSetting(db)
    if type(db) ~= "table" then
        return
    end
    if db.useNaowhPartyRaidNames ~= nil then
        if db.useSharedPartyRaidNameFont == nil then
            db.useSharedPartyRaidNameFont = (db.useNaowhPartyRaidNames == true)
        elseif db.useNaowhPartyRaidNames == true and db.useSharedPartyRaidNameFont ~= true then
            db.useSharedPartyRaidNameFont = true
        end
        db.useNaowhPartyRaidNames = nil
    end
    if db.partyNameFontSize == nil then
        db.partyNameFontSize = tonumber(db.partyRaidNameFontSize) or 16
    end
    if db.raidNameFontSize == nil then
        db.raidNameFontSize = tonumber(db.partyRaidNameFontSize) or 16
    end
    if db.partyNameTruncateLength == nil then
        db.partyNameTruncateLength = 0
    end
end

local function NormalizeGUIScaleSetting()
    if not MattMinimalFramesDB or not MMF_ClampGUIScale then
        return
    end
    MattMinimalFramesDB.guiScale = MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)
end

function MMF_ApplyActiveProfileLive()
    if not MattMinimalFramesDB then return end

    if InCombatLockdown() and MMF_RunAfterCombat then
        MMF_RunAfterCombat(
            "apply_active_profile_live",
            function()
                MMF_ApplyActiveProfileLive()
            end,
            "|cff00ff00Matt's Minimal Frames|r: Applying profile changes after combat."
        )
        return
    end

    local function ApplyFramePositions()
        if not MMF_Config or not MMF_Config.FRAME_DEFINITIONS then return end
        for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
            local frame = _G[def.name]
            if frame then
                frame:ClearAllPoints()
                local pos = MattMinimalFramesDB[def.name]
                if pos and pos.left and pos.top then
                    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
                else
                    frame:SetPoint("CENTER", UIParent, "CENTER", def.x, def.y)
                end
            end
        end
    end

    local function ApplyPowerBarPositions()
        if not MMF_Config then return end
        local vOff = MMF_Config.POWER_BAR_VERTICAL_OFFSET or -24
        local hOff = MMF_Config.POWER_BAR_HORIZONTAL_OFFSET or 1

        local function ApplyFor(frame, unit)
            if not frame or not frame.powerBarFrame then return end
            frame.powerBarFrame:ClearAllPoints()
            local pos = MattMinimalFramesDB.powerBarPositions and MattMinimalFramesDB.powerBarPositions[unit]
            if pos and pos.x and pos.y then
                frame.powerBarFrame:SetPoint("CENTER", frame, "CENTER", pos.x, pos.y)
            else
                if unit == "player" then
                    frame.powerBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -hOff, vOff)
                else
                    frame.powerBarFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", hOff, vOff)
                end
            end
        end

        ApplyFor(_G.MMF_PlayerFrame, "player")
        ApplyFor(_G.MMF_TargetFrame, "target")
    end

    ApplyFramePositions()
    if MMF_ApplyAllFrameScales then MMF_ApplyAllFrameScales() end
    ApplyPowerBarPositions()
    if MMF_ApplyPowerTextPositions then MMF_ApplyPowerTextPositions() end

    if MMF_SetPowerBarSize then
        local playerPowerW = MattMinimalFramesDB.playerPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73
        local playerPowerH = MattMinimalFramesDB.playerPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5
        local targetPowerW = MattMinimalFramesDB.targetPowerBarWidth or MattMinimalFramesDB.powerBarWidth or 73
        local targetPowerH = MattMinimalFramesDB.targetPowerBarHeight or MattMinimalFramesDB.powerBarHeight or 5
        MMF_SetPowerBarSize(playerPowerW, playerPowerH, "player")
        MMF_SetPowerBarSize(targetPowerW, targetPowerH, "target")
    end
    if MMF_UpdatePowerBarVisibility then MMF_UpdatePowerBarVisibility() end

    if MMF_UpdateNameTextSize then MMF_UpdateNameTextSize(MattMinimalFramesDB.nameTextSize or 12) end
    if MMF_UpdateHPTextSize then MMF_UpdateHPTextSize(MattMinimalFramesDB.hpTextSize or 13) end
    if MMF_UpdateFrameTextOffsets then MMF_UpdateFrameTextOffsets() end

    if MMF_UpdateBuffPosition then
        MMF_UpdateBuffPosition(MattMinimalFramesDB.buffXOffset or -2, MattMinimalFramesDB.buffYOffset or -64)
    end
    if MMF_UpdateDebuffPosition then
        MMF_UpdateDebuffPosition(MattMinimalFramesDB.debuffXOffset or 3, MattMinimalFramesDB.debuffYOffset or 27)
    end
    if MMF_UpdateAuraLayout then MMF_UpdateAuraLayout() end
    if MMF_UpdateAuraTextScale then MMF_UpdateAuraTextScale(MattMinimalFramesDB.auraTextScale or 1.0) end
    if MMF_UpdateTimerTextScale then MMF_UpdateTimerTextScale(MattMinimalFramesDB.timerTextScale or 0.8) end
    if MMF_UpdateTargetAuras then MMF_UpdateTargetAuras() end

    if MMF_ApplyStatusBarTexture then MMF_ApplyStatusBarTexture() end

    if MMF_UpdatePlayerClassIconVisibility then
        MMF_UpdatePlayerClassIconVisibility(MattMinimalFramesDB.playerFrameIconMode or "off")
    end
    if MMF_UpdateTargetFrameIconVisibility then
        MMF_UpdateTargetFrameIconVisibility(MattMinimalFramesDB.targetFrameIconMode or "off")
    end
    if MMF_UpdateTargetMarkerVisibility then
        MMF_UpdateTargetMarkerVisibility(MattMinimalFramesDB.showTargetMarkers == true)
    end
    if MMF_UpdateHideRestingIconSetting then
        MMF_UpdateHideRestingIconSetting(MattMinimalFramesDB.hideRestingIcon == true)
    end
    if MMF_UpdateAnimatedRestingIconSetting then
        MMF_UpdateAnimatedRestingIconSetting(MattMinimalFramesDB.animatedRestingIcon ~= false)
    end
    if MMF_UpdateHideCombatIconSetting then
        MMF_UpdateHideCombatIconSetting(MattMinimalFramesDB.hideCombatIcon == true)
    end
    if MMF_UpdateAnimatedCombatIconSetting then
        MMF_UpdateAnimatedCombatIconSetting(MattMinimalFramesDB.animatedCombatIcon ~= false)
    end
    if MMF_UpdateCombatFrameOutlineSetting then
        MMF_UpdateCombatFrameOutlineSetting(MattMinimalFramesDB.combatFrameOutline == true)
    end
    if MMF_UpdateCombatFrameVisibility then
        MMF_UpdateCombatFrameVisibility()
    end
    if MMF_UpdateBlizzardPlayerCastBarVisibility then
        MMF_UpdateBlizzardPlayerCastBarVisibility()
    end
    if MMF_UpdateBlizzardPartyRaidNameFonts then
        MMF_UpdateBlizzardPartyRaidNameFonts()
    end

    if MMF_InitializeClassResources then MMF_InitializeClassResources() end
    if MMF_UpdateClassBarLayoutForCurrentClass then MMF_UpdateClassBarLayoutForCurrentClass() end
    if MMF_ApplyGlobalFont then MMF_ApplyGlobalFont() end
    if MMF_ApplyPetActionBarPosition then MMF_ApplyPetActionBarPosition() end

    if _G.MMF_RuneBar then _G.MMF_RuneBar:SetShown(MattMinimalFramesDB.showRuneBar ~= false) end
    if _G.MMF_HolyPowerBar then _G.MMF_HolyPowerBar:SetShown(MattMinimalFramesDB.showHolyPowerBar ~= false) end
    if _G.MMF_ComboPointBar then _G.MMF_ComboPointBar:SetShown(MattMinimalFramesDB.showComboPointBar ~= false) end
    if _G.MMF_SoulShardBar then _G.MMF_SoulShardBar:SetShown(MattMinimalFramesDB.showSoulShardBar ~= false) end
    if _G.MMF_ChiBar then _G.MMF_ChiBar:SetShown(MattMinimalFramesDB.showChiBar ~= false) end
    if _G.MMF_ArcaneChargeBar then _G.MMF_ArcaneChargeBar:SetShown(MattMinimalFramesDB.showArcaneChargeBar ~= false) end
    if _G.MMF_EssenceBar then _G.MMF_EssenceBar:SetShown(MattMinimalFramesDB.showEssenceBar ~= false) end

    if MMF_ToggleMinimapButton then
        local hidden = MattMinimalFramesDB.minimap and MattMinimalFramesDB.minimap.hide
        MMF_ToggleMinimapButton(not hidden)
    end

    if MattMinimalFramesDB.locked then
        if MMF_LockFrames then MMF_LockFrames() end
    else
        if MMF_UnlockFrames then MMF_UnlockFrames() end
    end

    if MMF_GetAllFrames and MMF_UpdateUnitFrame then
        for _, frame in ipairs(MMF_GetAllFrames()) do
            if frame then
                MMF_UpdateUnitFrame(frame)
            end
        end
    end

    if MMF_WelcomePopup then
        local guiScale = (MMF_ClampGUIScale and MMF_ClampGUIScale(MattMinimalFramesDB.guiScale)) or 1.0
        if MMF_WelcomePopup.ApplyGUIScale then
            MMF_WelcomePopup:ApplyGUIScale(guiScale, true)
        else
            MMF_WelcomePopup:SetScale(guiScale)
        end
    end
end

local function Initialize()
    if MMF_Profiles_Initialize then
        MMF_Profiles_Initialize()
    elseif not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end

    if MMF_NormalizeActiveProfile then
        MMF_NormalizeActiveProfile()
    else
        NormalizeLegacyIconModes(MattMinimalFramesDB)
        if MattMinimalFrames_Defaults then
            ApplyDefaultsSafe(MattMinimalFramesDB, MattMinimalFrames_Defaults)
        end
    end
    NormalizeLegacyPartyRaidFontSetting(MattMinimalFramesDB)
    if MattMinimalFramesDB then
        -- Always reset preview-only aura test mode on UI load/reload.
        MattMinimalFramesDB.auraTestMode = false
        MattMinimalFramesDB.layoutTestMode = false
    end
    NormalizeGUIScaleSetting()
    if MattMinimalFramesDB and MattMinimalFramesDB.unlockFramesEditMode == true then
        reopenMainGUIAfterEditModeReset = true
        MattMinimalFramesDB.unlockFramesEditMode = false
        MattMinimalFramesDB.mmfLockedBeforeEditMode = nil
        MattMinimalFramesDB.mmfGridBeforeEditMode = nil
        MattMinimalFramesDB.showAlignmentGrid = false
        if MMF_ToggleAlignmentGrid then
            MMF_ToggleAlignmentGrid(false)
        end
    end
    if MMF_EnsureStatusBarTextureSelection then
        MMF_EnsureStatusBarTextureSelection()
    end
    
    HideBlizzardFrames()
    UpdateBlizzardPlayerCastBarVisibility()
    if MMF_UpdateBlizzardPartyRaidNameFonts then
        MMF_UpdateBlizzardPartyRaidNameFonts()
    end
    MMF_CreateAllMinimalFrames()
    if MMF_UpdateCombatFrameVisibility then
        MMF_UpdateCombatFrameVisibility()
    end
    MMF_ApplyAllFrameScales()
    MMF_InitializeClassResources()
    MMF_ApplyStatusBarTexture()
    if MMF_ApplyPetActionBarPosition then
        MMF_ApplyPetActionBarPosition()
    end
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
    if MMF_UpdateTargetMarkers then
        MMF_UpdateTargetMarkers()
    end
    if MattMinimalFramesDB.locked then
        MMF_LockFrames()
    else
        MMF_UnlockFrames()
    end
end

local function ReapplySharedMediaSelections()
    if MMF_ApplyStatusBarTexture then
        MMF_ApplyStatusBarTexture()
    end
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
end

local isInitialized = false
local startupStyleRetryToken = 0
local reopenMainGUIAfterEditModeReset = false

local function RequestAllFrameTextRefresh()
    if MMF_RequestAllFramesUpdate then
        MMF_RequestAllFramesUpdate()
        return
    end
    if InCombatLockdown and InCombatLockdown() then
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

local function ScheduleStartupStyleReapply()
    if not C_Timer or not C_Timer.After then
        return
    end

    startupStyleRetryToken = startupStyleRetryToken + 1
    local token = startupStyleRetryToken
    local retryDelays = { 0, 0.25, 0.75, 1.5 }

    for _, delay in ipairs(retryDelays) do
        C_Timer.After(delay, function()
            if token ~= startupStyleRetryToken or not isInitialized then
                return
            end
            ReapplySharedMediaSelections()
            RequestAllFrameTextRefresh()
        end)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MattMinimalFrames" then
        Initialize()
        isInitialized = true
        ScheduleStartupStyleReapply()
        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_LOGIN" and isInitialized then
        HideBlizzardFrames()
        if MMF_ResolveCharacterProfile then
            MMF_ResolveCharacterProfile(true)
        elseif MMF_NormalizeActiveProfile then
            MMF_NormalizeActiveProfile()
            if MMF_ApplyActiveProfileLive then
                MMF_ApplyActiveProfileLive()
            end
        end
        if MattMinimalFramesDB then
            MattMinimalFramesDB.auraTestMode = false
            MattMinimalFramesDB.layoutTestMode = false
        end
        if MMF_UpdateTargetAuras then
            MMF_UpdateTargetAuras()
        end

        -- Apply selected SharedMedia again after all addons have loaded.
        ReapplySharedMediaSelections()
        UpdateBlizzardPlayerCastBarVisibility()
        if MMF_UpdateBlizzardPartyRaidNameFonts then
            MMF_UpdateBlizzardPartyRaidNameFonts()
        end
        ScheduleStartupStyleReapply()
        if reopenMainGUIAfterEditModeReset and MMF_ShowWelcomePopup then
            reopenMainGUIAfterEditModeReset = false
            MMF_ShowWelcomePopup(true)
        end
    end
end)
