local queuedActions = {}
local queuedByKey = {}

local function RunAction(entry)
    if not entry or type(entry.fn) ~= "function" then
        return
    end
    local ok, err = pcall(entry.fn)
    if not ok and geterrorhandler then
        geterrorhandler()("MattMinimalFrames combat queue error: " .. tostring(err))
    end
end

local function EnqueueAction(key, fn, message)
    if type(fn) ~= "function" then
        return false
    end

    if key and queuedByKey[key] then
        queuedByKey[key].fn = fn
        queuedByKey[key].message = message
        return true
    end

    local entry = {
        key = key,
        fn = fn,
        message = message,
    }

    queuedActions[#queuedActions + 1] = entry
    if key then
        queuedByKey[key] = entry
    end

    if message and message ~= "" then
        print(message)
    end

    return true
end

function MMF_FlushCombatQueue()
    if InCombatLockdown() then
        return false
    end

    local pending = queuedActions
    queuedActions = {}
    queuedByKey = {}

    for _, entry in ipairs(pending) do
        RunAction(entry)
    end

    return true
end

function MMF_ClearCombatQueuedAction(key)
    if not key or not queuedByKey[key] then
        return false
    end

    local target = queuedByKey[key]
    queuedByKey[key] = nil
    for i = #queuedActions, 1, -1 do
        if queuedActions[i] == target then
            table.remove(queuedActions, i)
            break
        end
    end
    return true
end

function MMF_RunAfterCombat(key, fn, message)
    if type(key) == "function" and fn == nil then
        fn = key
        key = nil
    end

    if type(fn) ~= "function" then
        return false, "invalid_fn"
    end

    if InCombatLockdown() then
        EnqueueAction(key, fn, message)
        return false, "queued"
    end

    RunAction({ fn = fn })
    return true
end

function MMF_IsCombatActionQueued(key)
    if not key then
        return #queuedActions > 0
    end
    return queuedByKey[key] ~= nil
end

local combatQueueFrame = CreateFrame("Frame")
combatQueueFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatQueueFrame:SetScript("OnEvent", function()
    MMF_FlushCombatQueue()
end)
