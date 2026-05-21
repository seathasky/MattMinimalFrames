local function IsBossUnit(unit)
    return unit == "boss1" or unit == "boss2" or unit == "boss3" or unit == "boss4" or unit == "boss5"
end

local state = {
    enabled = false,
    ticker = nil,
    frame = nil,
    wrapped = false,
    originalUpdateUnitFrame = nil,
    sim = {},
}

local SIM_TARGET_POOL = {
    "Tankor",
    "MeleeOne",
    "MeleeTwo",
    "RangedOne",
    "RangedTwo",
    "Healz",
}

local function PickRandomTargetName(exclude)
    local count = #SIM_TARGET_POOL
    if count == 0 then
        return "Unknown"
    end
    if count == 1 then
        return SIM_TARGET_POOL[1]
    end

    local picked = exclude
    local safety = 0
    while picked == exclude and safety < 10 do
        local idx = math.random(1, count)
        picked = SIM_TARGET_POOL[idx]
        safety = safety + 1
    end

    return picked or SIM_TARGET_POOL[1]
end

local function EnsureDB()
    if not MattMinimalFramesDB then
        MattMinimalFramesDB = {}
    end
    if MattMinimalFramesDB.debugBossSimEnabled == nil then
        MattMinimalFramesDB.debugBossSimEnabled = false
    end
    return MattMinimalFramesDB
end

local function EnsureSimData()
    for i = 1, 5 do
        if not state.sim[i] then
            local maxHP = 1000000 + (i * 150000)
            state.sim[i] = {
                name = "Debug Boss " .. i,
                maxHP = maxHP,
                hp = math.floor(maxHP * (0.85 - (i * 0.05))),
                phase = i * 0.65,
                speed = 0.8 + (i * 0.25),
                targetName = PickRandomTargetName(nil),
                nextTargetSwapIn = 1.5 + (i * 0.35),
            }
        end
    end
end

local function SetBossUnitWatchSuspended(frame, suspend)
    if not frame then
        return
    end

    if suspend then
        if frame.mmfDebugBossSimUnitWatchSuspended then
            return
        end
        if type(UnregisterUnitWatch) == "function" then
            local ok = pcall(UnregisterUnitWatch, frame)
            if ok then
                frame.mmfDebugBossSimUnitWatchSuspended = true
            end
        end
    else
        if not frame.mmfDebugBossSimUnitWatchSuspended then
            return
        end
        if type(InCombatLockdown) == "function" and InCombatLockdown() then
            return
        end
        if type(RegisterUnitWatch) == "function" then
            pcall(RegisterUnitWatch, frame)
        end
        frame.mmfDebugBossSimUnitWatchSuspended = nil
    end
end

local function ApplySimVisual(frame)
    if not frame or not frame.unit then
        return
    end
    local idx = tonumber(string.match(frame.unit, "boss([1-5])") or "")
    if not idx then
        return
    end

    local sim = state.sim[idx]
    if not sim then
        return
    end

    SetBossUnitWatchSuspended(frame, true)

    frame:Show()
    frame:SetAlpha(1)

    if frame.nameText then
        frame.nameText:Show()
        frame.nameText:SetText(string.format("%s  >  %s", sim.name, sim.targetName or "Unknown"))
    end

    if frame.healthBar then
        frame.healthBar:Show()
        frame.healthBar:SetMinMaxValues(0, sim.maxHP)
        frame.healthBar:SetValue(sim.hp)

        local pct = 0
        if sim.maxHP > 0 then
            pct = sim.hp / sim.maxHP
        end
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end

        local r, g, b
        if pct > 0.5 then
            local t = (pct - 0.5) * 2
            r, g, b = 1 - t, 1, 0
        else
            local t = pct * 2
            r, g, b = 1, t, 0
        end

        frame.healthBar:SetStatusBarColor(r, g, b, 1)
    end

    if frame.healthBarBG then
        frame.healthBarBG:Show()
    end
    if frame.healthBarBorder then
        frame.healthBarBorder:Show()
    end

    if frame.hpText then
        frame.hpText:Show()
        local percent = 0
        if sim.maxHP > 0 then
            percent = math.floor((sim.hp / sim.maxHP) * 100 + 0.5)
        end
        frame.hpText:SetText(string.format("%d%% | %s", percent, BreakUpLargeNumbers and BreakUpLargeNumbers(sim.hp) or tostring(sim.hp)))
    end

    if frame.powerBar then
        frame.powerBar:Hide()
    end
    if frame.powerBarBG then
        frame.powerBarBG:Hide()
    end
    if frame.powerBarBorder then
        frame.powerBarBorder:Hide()
    end
    if frame.powerText then
        frame.powerText:Hide()
    end
end

local function AdvanceSim(elapsed)
    EnsureSimData()
    for i = 1, 5 do
        local s = state.sim[i]
        s.phase = s.phase + (elapsed * s.speed)

        s.nextTargetSwapIn = (s.nextTargetSwapIn or 2.0) - elapsed
        if s.nextTargetSwapIn <= 0 then
            s.targetName = PickRandomTargetName(s.targetName)
            s.nextTargetSwapIn = 1.2 + (math.random() * 2.0)
        end

        local wave = (math.sin(s.phase) * 0.5) + 0.5
        local dmgPressure = (math.sin((s.phase * 0.35) + i) * 0.5) + 0.5
        local floorPct = 0.05 + (0.1 * dmgPressure)
        local targetPct = floorPct + ((1 - floorPct) * wave)
        s.hp = math.floor(s.maxHP * targetPct)
        if s.hp < 1 then
            s.hp = 1
        end
    end
end

local function Tick()
    if not state.enabled then
        return
    end

    AdvanceSim(0.1)

    for i = 1, 5 do
        local unit = "boss" .. i
        local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit(unit) or _G["MMF_Boss" .. i .. "Frame"]
        if frame then
            ApplySimVisual(frame)
            if MMF_RequestFrameUpdate then
                MMF_RequestFrameUpdate(frame)
            end
        end
    end

    if MMF_FlushRequestedUpdates then
        MMF_FlushRequestedUpdates()
    end
end

local function StartTicker()
    if state.ticker then
        return
    end

    if C_Timer and C_Timer.NewTicker then
        state.ticker = C_Timer.NewTicker(0.1, Tick)
        return
    end

    if not state.frame then
        state.frame = CreateFrame("Frame")
    end

    local elapsedSince = 0
    state.frame:SetScript("OnUpdate", function(_, elapsed)
        if not state.enabled then
            return
        end
        elapsedSince = elapsedSince + (elapsed or 0)
        if elapsedSince >= 0.1 then
            elapsedSince = 0
            Tick()
        end
    end)
end

local function StopTicker()
    if state.ticker and state.ticker.Cancel then
        state.ticker:Cancel()
    end
    state.ticker = nil

    if state.frame then
        state.frame:SetScript("OnUpdate", nil)
    end
end

local function RestoreBossUnitWatch()
    for i = 1, 5 do
        local frame = MMF_GetFrameForUnit and MMF_GetFrameForUnit("boss" .. i) or _G["MMF_Boss" .. i .. "Frame"]
        if frame then
            SetBossUnitWatchSuspended(frame, false)
        end
    end
end

local function EnsureWrappedUpdate()
    if state.wrapped or type(MMF_UpdateUnitFrame) ~= "function" then
        return
    end

    state.originalUpdateUnitFrame = MMF_UpdateUnitFrame
    MMF_UpdateUnitFrame = function(frame)
        state.originalUpdateUnitFrame(frame)

        if not state.enabled or not frame or not IsBossUnit(frame.unit) then
            return
        end

        if type(UnitExists) == "function" and UnitExists(frame.unit) then
            return
        end

        ApplySimVisual(frame)
    end

    state.wrapped = true
end

function MMF_DebugBossSimSetEnabled(enabled)
    EnsureDB()
    local desired = enabled == true
    state.enabled = desired
    MattMinimalFramesDB.debugBossSimEnabled = desired

    if desired then
        EnsureSimData()
        EnsureWrappedUpdate()
        StartTicker()
        Tick()
        print("|cff00ff00MMF Debug|r: Boss sim enabled.")
    else
        StopTicker()
        RestoreBossUnitWatch()
        if MMF_RequestAllFramesUpdate then
            MMF_RequestAllFramesUpdate()
        end
        if MMF_FlushRequestedUpdates then
            MMF_FlushRequestedUpdates()
        end
        if MMF_UpdateCombatFrameVisibility then
            MMF_UpdateCombatFrameVisibility()
        end
        print("|cff00ff00MMF Debug|r: Boss sim disabled.")
    end
end

function MMF_DebugBossSimIsEnabled()
    return state.enabled == true
end

SLASH_MMFDEBUG1 = "/mmfdebug"
SlashCmdList["MMFDEBUG"] = function(msg)
    local input = string.lower((msg or ""):gsub("^%s+", ""):gsub("%s+$", ""))

    if input == "on" or input == "start" or input == "1" then
        MMF_DebugBossSimSetEnabled(true)
        return
    end

    if input == "off" or input == "stop" or input == "0" then
        MMF_DebugBossSimSetEnabled(false)
        return
    end

    if input == "toggle" then
        MMF_DebugBossSimSetEnabled(not MMF_DebugBossSimIsEnabled())
        return
    end

    print("|cff00ff00MMF Debug|r: /mmfdebug on | off | toggle")
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    EnsureDB()
    EnsureWrappedUpdate()
    if MattMinimalFramesDB.debugBossSimEnabled == true then
        MMF_DebugBossSimSetEnabled(true)
    end
end)
