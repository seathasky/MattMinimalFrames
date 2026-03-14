local cfg = MMF_Config or {}
local TICK_INTERVAL = cfg.UPDATE_INTERVAL or 0.1
local FALLBACK_INTERVAL = 0.8

local dirtyUnits = {}
local dirtyFrames = {}
local hasPending = false
local fullRefreshRequested = false
local fallbackElapsed = 0

local function MarkPending()
    hasPending = true
end

function MMF_RequestUnitUpdate(unit)
    if type(unit) ~= "string" or unit == "" then
        return
    end
    dirtyUnits[unit] = true
    MarkPending()
end

function MMF_RequestFrameUpdate(frame)
    if not frame then
        return
    end
    dirtyFrames[frame] = true
    MarkPending()
end

function MMF_RequestAllFramesUpdate()
    fullRefreshRequested = true
    MarkPending()
end

local function ClearPending()
    hasPending = false
    fullRefreshRequested = false
    wipe(dirtyUnits)
    wipe(dirtyFrames)
end

local function SafeUpdateUnitFrame(frame)
    if not frame or not frame:IsShown() or not MMF_UpdateUnitFrame then
        return
    end
    pcall(MMF_UpdateUnitFrame, frame)
end

local function UpdateAllFramesNow()
    if not MMF_GetAllFrames or not MMF_UpdateUnitFrame then
        return
    end
    for _, frame in ipairs(MMF_GetAllFrames()) do
        SafeUpdateUnitFrame(frame)
    end
end

function MMF_FlushRequestedUpdates()
    if not MMF_UpdateUnitFrame then
        ClearPending()
        return
    end

    if fullRefreshRequested then
        UpdateAllFramesNow()
        ClearPending()
        return
    end

    for frame in pairs(dirtyFrames) do
        SafeUpdateUnitFrame(frame)
    end

    if MMF_GetFrameForUnit then
        for unit in pairs(dirtyUnits) do
            local frame = MMF_GetFrameForUnit(unit)
            SafeUpdateUnitFrame(frame)
        end
    end

    ClearPending()
end

local function TickDispatcher()
    if hasPending then
        MMF_FlushRequestedUpdates()
        fallbackElapsed = 0
        return
    end

    fallbackElapsed = fallbackElapsed + TICK_INTERVAL
    if fallbackElapsed >= FALLBACK_INTERVAL then
        fallbackElapsed = 0
        UpdateAllFramesNow()
    end
end

local dispatcherTicker
local function StartDispatcher()
    if dispatcherTicker then
        return
    end
    if C_Timer and C_Timer.NewTicker then
        dispatcherTicker = C_Timer.NewTicker(TICK_INTERVAL, TickDispatcher)
        return
    end

    local fallbackFrame = CreateFrame("Frame")
    fallbackFrame:SetScript("OnUpdate", function(_, elapsed)
        fallbackElapsed = fallbackElapsed + elapsed
        if fallbackElapsed >= TICK_INTERVAL then
            fallbackElapsed = 0
            TickDispatcher()
        end
    end)
    dispatcherTicker = fallbackFrame
end

local dispatcherFrame = CreateFrame("Frame")
dispatcherFrame:RegisterEvent("PLAYER_LOGIN")
dispatcherFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
dispatcherFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        StartDispatcher()
        MMF_RequestAllFramesUpdate()
    elseif event == "PLAYER_ENTERING_WORLD" then
        MMF_RequestAllFramesUpdate()
    end
end)
