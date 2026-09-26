local cfg = MMF_Config or {}
local Compat = _G.MMF_Compat
local TICK_INTERVAL = cfg.UPDATE_INTERVAL or 0.1


local FALLBACK_INTERVAL = 3.0

local function ShouldSuspendForBlizzardEditMode()
    return _G.MMF_ShouldSuspendForBlizzardEditMode and _G.MMF_ShouldSuspendForBlizzardEditMode() == true
end

local dirtyUnits = {}
local dirtyFrames = {}
local updatedFrames = {}
local hasPending = false
local fullRefreshRequested = false
local fallbackElapsed = 0
local dispatcherStarted = false
local flushScheduled = false
local flushFrame
local flushElapsed = 0
local fallbackFrame
local dispatcherFrame

local function FlushScheduledUpdates()
    flushScheduled = false
    if hasPending then
        MMF_FlushRequestedUpdates()
    end
end

local function ScheduleFlush()
    if flushScheduled or not dispatcherStarted then
        return
    end

    flushScheduled = true
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(TICK_INTERVAL, FlushScheduledUpdates)
        return
    end

    if not flushFrame then
        flushFrame = CreateFrame("Frame")
    end
    flushElapsed = 0
    flushFrame:SetScript("OnUpdate", function(self, elapsed)
        flushElapsed = flushElapsed + (elapsed or 0)
        if flushElapsed >= TICK_INTERVAL then
            self:SetScript("OnUpdate", nil)
            FlushScheduledUpdates()
        end
    end)
end

local function MarkPending()
    hasPending = true
    ScheduleFlush()
end

function MMF_RequestUnitUpdate(unit)
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    if type(unit) ~= "string" or unit == "" then
        return
    end
    dirtyUnits[unit] = true
    MarkPending()
end

function MMF_RequestFrameUpdate(frame)
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    if not frame then
        return
    end
    dirtyFrames[frame] = true
    MarkPending()
end

function MMF_RequestAllFramesUpdate()
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
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
    local ok,err=pcall(MMF_UpdateUnitFrame, frame)
    if not ok and MMF_Designer and MMF_Designer.Report then
        MMF_Designer.Report("unit update "..tostring(frame.unit),err)
    end
end

local function SafeUpdateUnitFrameOnce(frame)
    if not frame or updatedFrames[frame] then
        return
    end
    updatedFrames[frame] = true
    SafeUpdateUnitFrame(frame)
end

local function ResolveFramesForUnit(unit)
    local resolved = {}
    if type(unit) ~= "string" or unit == "" then
        return resolved
    end

    if MMF_GetFrameForUnit then
        local directFrame = MMF_GetFrameForUnit(unit)
        if directFrame then
            resolved[directFrame] = true
        end
    end

    if next(resolved) then
        return resolved
    end

    if not (Compat and Compat.IsTBC == true) then
        return resolved
    end

    if type(UnitIsUnit) ~= "function" or not MMF_Config or type(MMF_Config.FRAME_DEFINITIONS) ~= "table" then
        return resolved
    end

    for _, def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
        local trackedUnit = def and def.unit
        if type(trackedUnit) == "string" and trackedUnit ~= unit then
            local ok, isSameUnit = pcall(UnitIsUnit, unit, trackedUnit)
            if ok and isSameUnit and MMF_GetFrameForUnit then
                local aliasFrame = MMF_GetFrameForUnit(trackedUnit)
                if aliasFrame then
                    resolved[aliasFrame] = true
                end
            end
        end
    end

    return resolved
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
    wipe(updatedFrames)
    if ShouldSuspendForBlizzardEditMode() then
        ClearPending()
        return
    end
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
        SafeUpdateUnitFrameOnce(frame)
    end

    for unit in pairs(dirtyUnits) do
        local resolvedFrames = ResolveFramesForUnit(unit)
        for frame in pairs(resolvedFrames) do
            SafeUpdateUnitFrameOnce(frame)
        end
    end

    ClearPending()
end

local function TickFallbackRefresh()
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    if not hasPending then
        UpdateAllFramesNow()
    end
end

local function StartFallbackRefresh()
    if C_Timer and type(C_Timer.NewTicker) == "function" then
        dispatcherFrame.mmfFallbackTicker = C_Timer.NewTicker(FALLBACK_INTERVAL, TickFallbackRefresh)
    elseif C_Timer and type(C_Timer.After) == "function" then
        local function ScheduleNextFallback()
            C_Timer.After(FALLBACK_INTERVAL, function()
                TickFallbackRefresh()
                ScheduleNextFallback()
            end)
        end
        ScheduleNextFallback()
    else
        fallbackFrame = CreateFrame("Frame")
        fallbackFrame:SetScript("OnUpdate", function(_, elapsed)
            fallbackElapsed = fallbackElapsed + (elapsed or 0)
            if fallbackElapsed >= FALLBACK_INTERVAL then
                fallbackElapsed = 0
                TickFallbackRefresh()
            end
        end)
    end
end

local function StartDispatcher()
    if dispatcherStarted then
        return
    end
    dispatcherStarted = true
    StartFallbackRefresh()
    ScheduleFlush()
end

dispatcherFrame = CreateFrame("Frame")
dispatcherFrame:RegisterEvent("PLAYER_LOGIN")
dispatcherFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
dispatcherFrame:SetScript("OnEvent", function(_, event)
    if ShouldSuspendForBlizzardEditMode() then
        return
    end
    if event == "PLAYER_LOGIN" then
        StartDispatcher()
        MMF_RequestAllFramesUpdate()
    elseif event == "PLAYER_ENTERING_WORLD" then
        MMF_RequestAllFramesUpdate()
    end
end)
