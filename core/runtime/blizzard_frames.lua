local hiddenBlizzardFrames = setmetatable({}, { __mode = "k" })
local castBarHooks = setmetatable({}, { __mode = "k" })

local function HideBlizzardFrame(frame)
    if not frame or hiddenBlizzardFrames[frame] then
        return
    end

    -- Keep Blizzard's scripts, events, parent, and Lua fields intact. Replacing
    -- an OnShow script or reparenting a protected unit frame permanently taints
    -- the frame and can contaminate unrelated protected UI work later.
    -- A secure visibility driver is the supported way to keep a protected
    -- frame hidden through combat state changes.
    if type(RegisterStateDriver) == "function" then
        local ok = pcall(RegisterStateDriver, frame, "visibility", "hide")
        if ok then
            hiddenBlizzardFrames[frame] = true
            return
        end
    end

    -- Classic/non-protected fallback. Use a secure post-hook instead of
    -- replacing Blizzard's OnShow handler.
    frame:Hide()
    if type(hooksecurefunc) == "function" then
        local ok = pcall(hooksecurefunc, frame, "Show", function(self)
            if hiddenBlizzardFrames[self]
                and (type(InCombatLockdown) ~= "function" or not InCombatLockdown()) then
                self:Hide()
            end
        end)
        if ok then
            hiddenBlizzardFrames[frame] = true
        end
    end
end

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
        HideBlizzardFrame(frame)
    end
    if TargetFrameToT then
        HideBlizzardFrame(TargetFrameToT)
    end

    local compat = _G.MMF_Compat
    if compat and compat.IsClassicEra then
        local comboFrames = {
            _G.ComboFrame,
            _G.ComboPointPlayerFrame,
            _G.PlayerFrameComboPoints,
        }
        for _, frame in ipairs(comboFrames) do
            HideBlizzardFrame(frame)
        end
    end
end

local function UpdateBlizzardPlayerCastBarVisibility()
    local shouldHide = MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true
    local candidates = {
        _G.PlayerCastingBarFrame,
        _G.CastingBarFrame,
        _G.PlayerFrame and _G.PlayerFrame.castBar or nil,
    }

    for _, frame in pairs(candidates) do
        if frame then
            -- Do not touch Blizzard's cast-bar scripts unless the option is
            -- actually enabled. Keep hook bookkeeping outside the frame so no
            -- addon-owned Lua field is written onto a protected object.
            if shouldHide and not castBarHooks[frame] then
                frame:HookScript("OnShow", function(self)
                    if MattMinimalFramesDB and MattMinimalFramesDB.hideBlizzardPlayerCastBar == true then
                        self:Hide()
                    end
                end)
                castBarHooks[frame] = true
            end

            if shouldHide then
                frame:Hide()
            end
        end
    end
end

_G.MMF_HideBlizzardFrames = HideBlizzardFrames
_G.MMF_UpdateBlizzardPlayerCastBarVisibility = UpdateBlizzardPlayerCastBarVisibility
