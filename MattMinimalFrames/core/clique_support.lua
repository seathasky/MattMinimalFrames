-- Clique click-casting support (TBC only)

local registered = false

local function RegisterFramesWithClique()
    if registered then return end
    if not ClickCastFrames then return end

    local frames = MMF_GetAllFrames()
    if not frames or not frames[1] then return end

    for _, frame in ipairs(frames) do
        if frame then
            ClickCastFrames[frame] = true
        end
    end
    registered = true
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    RegisterFramesWithClique()
    self:UnregisterAllEvents()
end)
