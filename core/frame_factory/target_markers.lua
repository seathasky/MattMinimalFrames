local function NotSecretValue(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return true
end

local function ApplyRaidMarkerTexture(texture, index)
    if not texture or not index then return false end

    if SetRaidTargetIconTexture then
        local ok = pcall(SetRaidTargetIconTexture, texture, index)
        if ok then
            return true
        end
    end

    if not NotSecretValue(index) then return false end
    if type(index) ~= "number" then return false end
    local validIndex = nil
    pcall(function()
        if index >= 1 and index <= 8 then
            validIndex = index
        end
    end)
    if not validIndex then return false end

    texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    local col = (validIndex - 1) % 4
    local row = math.floor((validIndex - 1) / 4)
    local left = col * 0.25
    local right = left + 0.25
    local top = row * 0.5
    local bottom = top + 0.5
    texture:SetTexCoord(left, right, top, bottom)
    return true
end

local function UpdateFrameTargetMarker(frame)
    if not frame or not frame.targetMarker then return end
    if not MattMinimalFramesDB or MattMinimalFramesDB.showTargetMarkers ~= true then
        frame.targetMarker:Hide()
        return
    end
    if not frame.unit or not UnitExists(frame.unit) then
        frame.targetMarker:Hide()
        return
    end
    local index = GetRaidTargetIndex(frame.unit)
    if not index then
        frame.targetMarker:Hide()
        return
    end
    local applied = ApplyRaidMarkerTexture(frame.targetMarker, index)
    if not applied then
        frame.targetMarker:Hide()
        return
    end
    frame.targetMarker:Show()
end

local function CreateTargetMarker(frame)
    if not frame or frame.targetMarker or not frame.nameOverlay then return end
    local marker = frame.nameOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
    marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    local markerSize = math.max(10, math.floor((frame:GetHeight() or frame.originalHeight or 28) * 0.75))
    marker:SetSize(markerSize, markerSize)
    marker:SetPoint("CENTER", frame, "CENTER", 0, 0)
    marker:Hide()
    frame.targetMarker = marker
    UpdateFrameTargetMarker(frame)
end

_G.MMF_FrameFactoryTargetMarkers = {
    ApplyRaidMarkerTexture = ApplyRaidMarkerTexture,
    UpdateFrameTargetMarker = UpdateFrameTargetMarker,
    CreateTargetMarker = CreateTargetMarker,
}
