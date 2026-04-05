-- Clique click-casting support (Retail/Classic compatible).

local function RegisterFramesWithClique()
    if type(MMF_GetAllFrames) ~= "function" then return false end

    local frames = MMF_GetAllFrames()
    if type(frames) ~= "table" or not frames[1] then return false end

    if type(ClickCastFrames) ~= "table" then
        ClickCastFrames = {}
    end

    local clique = _G.Clique
    local registeredAny = false

    for _, frame in ipairs(frames) do
        if frame then
            ClickCastFrames[frame] = true
            registeredAny = true
            if clique and type(clique.RegisterUnitFrame) == "function" then
                pcall(clique.RegisterUnitFrame, clique, frame)
            end
        end
    end

    return registeredAny
end

MMF_RegisterFramesWithClique = RegisterFramesWithClique

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" then
        RegisterFramesWithClique()
        return
    end

    if event == "ADDON_LOADED" and addonName == "Clique" then
        RegisterFramesWithClique()
    end
end)
