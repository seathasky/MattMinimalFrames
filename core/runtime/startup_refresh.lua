local startupStyleRetryToken = 0

local function ReapplySharedMediaSelections()
    if MMF_ApplyStatusBarTexture then
        MMF_ApplyStatusBarTexture()
    end
    if MMF_ApplyGlobalFont then
        MMF_ApplyGlobalFont()
    end
end

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

local function ScheduleStartupStyleReapply(isInitializedFn)
    if not C_Timer or not C_Timer.After then
        return
    end

    startupStyleRetryToken = startupStyleRetryToken + 1
    local token = startupStyleRetryToken
    local retryDelays = { 0, 0.25, 0.75, 1.5 }

    for _, delay in ipairs(retryDelays) do
        C_Timer.After(delay, function()
            local isInitialized = false
            if type(isInitializedFn) == "function" then
                isInitialized = isInitializedFn() == true
            end
            if token ~= startupStyleRetryToken or not isInitialized then
                return
            end
            ReapplySharedMediaSelections()
            RequestAllFrameTextRefresh()
        end)
    end
end

_G.MMF_Startup_ReapplySharedMediaSelections = ReapplySharedMediaSelections
_G.MMF_Startup_RequestAllFrameTextRefresh = RequestAllFrameTextRefresh
_G.MMF_Startup_ScheduleStyleReapply = ScheduleStartupStyleReapply
