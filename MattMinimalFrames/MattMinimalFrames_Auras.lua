--========================================================
-- MattMinimalFrames_Auras.lua
-- Target aura display (buffs and debuffs)
--========================================================

-- Constants
local AURA_ICON_SIZE    = 18
local AURA_ICON_SPACING = 2
local MAX_AURA_ICONS    = 12
local ROW_ICONS         = 4

----------------------------------------------------------
-- SETUP AURA CONTAINERS
----------------------------------------------------------

function MMF_SetupTargetAuras()
    if not MMF_TargetFrame then return end

    -- Buff container (bottom-right)
    MMF_TargetFrame.BuffContainer = CreateFrame("Frame", nil, MMF_TargetFrame)
    MMF_TargetFrame.BuffContainer:SetSize(
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
    )
    MMF_TargetFrame.BuffContainer:SetPoint("BOTTOMRIGHT", MMF_TargetFrame, "BOTTOMRIGHT", -3, -60)
    MMF_TargetFrame.BuffContainer.auras = {}

    for i = 1, MAX_AURA_ICONS do
        local aura = CreateFrame("Frame", nil, MMF_TargetFrame.BuffContainer)
        aura:SetSize(AURA_ICON_SIZE, AURA_ICON_SIZE)
        local row = math.floor((i - 1) / ROW_ICONS)
        local col = (i - 1) % ROW_ICONS
        aura:SetPoint("TOPRIGHT", MMF_TargetFrame.BuffContainer, "TOPRIGHT",
            -col * (AURA_ICON_SIZE + AURA_ICON_SPACING),
            -row * (AURA_ICON_SIZE + AURA_ICON_SPACING))
        
        aura.icon = aura:CreateTexture(nil, "ARTWORK")
        aura.icon:SetAllPoints(aura)
        aura.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
        aura.cooldown:SetAllPoints(aura)
        
        aura.timerFrame = CreateFrame("Frame", nil, aura)
        aura.timerFrame:SetAllPoints(aura)
        aura.timerFrame:SetFrameLevel(aura.cooldown:GetFrameLevel() + 10)
        
        aura.timerText = aura.timerFrame:CreateFontString(nil, "OVERLAY")
        aura.timerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        aura.timerText:SetPoint("TOP", aura.timerFrame, "TOP", 0, -2)
        aura.timerText:SetJustifyH("CENTER")
        aura.timerText:Hide()
        
        aura:SetScript("OnEnter", function(self)
            if self.auraIndex and self.auraFilter then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                GameTooltip:Show()
                self:SetScript("OnUpdate", function(self, elapsed)
                    if GameTooltip:GetOwner() == self then
                        GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                    end
                end)
            end
        end)
        
        aura:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self:SetScript("OnUpdate", nil)
        end)
        
        aura:Hide()
        MMF_TargetFrame.BuffContainer.auras[i] = aura
    end

    -- Debuff container (TOPLEFT, left-to-right, up)
    MMF_TargetFrame.DebuffContainer = CreateFrame("Frame", nil, MMF_TargetFrame)
    MMF_TargetFrame.DebuffContainer:SetSize(
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * ROW_ICONS - AURA_ICON_SPACING,
        (AURA_ICON_SIZE + AURA_ICON_SPACING) * 3 - AURA_ICON_SPACING
    )
    MMF_TargetFrame.DebuffContainer:SetPoint("TOPLEFT", MMF_TargetFrame, "TOPLEFT", 3, 27)
    MMF_TargetFrame.DebuffContainer.auras = {}

    for i = 1, MAX_AURA_ICONS do
        local aura = CreateFrame("Frame", nil, MMF_TargetFrame.DebuffContainer)
        aura:SetSize(AURA_ICON_SIZE, AURA_ICON_SIZE)
        local row = math.floor((i - 1) / ROW_ICONS)
        local col = (i - 1) % ROW_ICONS
        aura:SetPoint("TOPLEFT", MMF_TargetFrame.DebuffContainer, "TOPLEFT",
            col * (AURA_ICON_SIZE + AURA_ICON_SPACING),
            row * (AURA_ICON_SIZE + AURA_ICON_SPACING))
        
        aura.icon = aura:CreateTexture(nil, "ARTWORK")
        aura.icon:SetAllPoints(aura)
        aura.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
        aura.cooldown:SetAllPoints(aura)
        
        aura.timerFrame = CreateFrame("Frame", nil, aura)
        aura.timerFrame:SetAllPoints(aura)
        aura.timerFrame:SetFrameLevel(aura.cooldown:GetFrameLevel() + 10)
        
        aura.timerText = aura.timerFrame:CreateFontString(nil, "OVERLAY")
        aura.timerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        aura.timerText:SetPoint("TOP", aura.timerFrame, "TOP", 0, -2)
        aura.timerText:SetJustifyH("CENTER")
        aura.timerText:Hide()
        
        aura.border = aura:CreateTexture(nil, "OVERLAY")
        aura.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        aura.border:SetAllPoints(aura)
        
        aura:SetScript("OnEnter", function(self)
            if self.auraIndex and self.auraFilter then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                GameTooltip:Show()
                self:SetScript("OnUpdate", function(self, elapsed)
                    if GameTooltip:GetOwner() == self then
                        GameTooltip:SetUnitAura("target", self.auraIndex, self.auraFilter)
                    end
                end)
            end
        end)
        
        aura:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self:SetScript("OnUpdate", nil)
        end)
        
        aura:Hide()
        MMF_TargetFrame.DebuffContainer.auras[i] = aura
    end
end

----------------------------------------------------------
-- UPDATE AURAS
----------------------------------------------------------

function MMF_UpdateTargetAuras()
    if not MMF_TargetFrame or not MMF_TargetFrame.BuffContainer then return end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return end

    local unit = "target"
    local buffs, debuffs = {}, {}
    local BUFF_MAX_DISPLAY, DEBUFF_MAX_DISPLAY = 32, 16

    -- Gather buffs (HELPFUL)
    for i = 1, BUFF_MAX_DISPLAY do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not auraData then break end
        auraData._index = i
        table.insert(buffs, auraData)
    end

    -- Gather debuffs (HARMFUL)
    for i = 1, DEBUFF_MAX_DISPLAY do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        if not auraData then break end
        auraData._index = i
        table.insert(debuffs, auraData)
    end

    -- Sort: permanent first, then by time left ascending
    local function auraSort(a, b)
        local aPermanent = (a.duration == 0)
        local bPermanent = (b.duration == 0)
        if aPermanent ~= bPermanent then
            return aPermanent
        elseif aPermanent and bPermanent then
            return (a.name < b.name)
        else
            return (a.expirationTime - GetTime()) < (b.expirationTime - GetTime())
        end
    end
    table.sort(buffs, auraSort)
    table.sort(debuffs, auraSort)

    -- Update Buff icons
    local buffContainer = MMF_TargetFrame.BuffContainer
    if MattMinimalFramesDB.showBuffs == false then
        buffContainer:Hide()
    else
        buffContainer:Show()
        for _, aura in ipairs(buffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        local idx = 1
        for i = 1, math.min(#buffs, MAX_AURA_ICONS) do
            local auraData = buffs[i]
            local auraFrame = buffContainer.auras[idx]
            if auraFrame then
                auraFrame.icon:SetTexture(auraData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                auraFrame.auraData = auraData
                auraFrame.auraIndex = auraData._index
                auraFrame.auraFilter = "HELPFUL"
                
                -- Show stack count if >1
                local count = auraData.applications or auraData.count or 0
                if count > 1 then
                    if not auraFrame.count then
                        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
                        auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -2, 2)
                    end
                    auraFrame.count:SetText(count)
                    auraFrame.count:Show()
                elseif auraFrame.count then
                    auraFrame.count:Hide()
                end
                
                -- Show cooldown if duration > 0
                if auraData.duration and auraData.duration > 0 and auraData.expirationTime then
                    auraFrame.cooldown:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration)
                    auraFrame.cooldown:Show()
                    auraFrame.timerText:Show()
                    auraFrame.timerText:SetText("")
                    auraFrame:SetScript("OnUpdate", function(self, elapsed)
                        local now = GetTime()
                        local timeLeft = (auraData.expirationTime or 0) - now
                        if timeLeft > 0 and timeLeft < 60 then
                            self.timerText:SetText(tostring(math.floor(timeLeft)))
                            self.timerText:Show()
                        else
                            self.timerText:SetText("")
                            self.timerText:Hide()
                            if timeLeft <= 0 then
                                self:SetScript("OnUpdate", nil)
                            end
                        end
                    end)
                else
                    auraFrame.cooldown:Hide()
                    auraFrame.timerText:Hide()
                    auraFrame:SetScript("OnUpdate", nil)
                end
                auraFrame:Show()
                idx = idx + 1
            end
        end
    end

    -- Update Debuff icons
    local debuffContainer = MMF_TargetFrame.DebuffContainer
    if MattMinimalFramesDB.showDebuffs == false then
        debuffContainer:Hide()
    else
        debuffContainer:Show()
        for _, aura in ipairs(debuffContainer.auras) do
            aura:Hide()
            if aura.timerText then aura.timerText:Hide() end
        end
        local idx = 1
        for i = 1, math.min(#debuffs, MAX_AURA_ICONS) do
            local auraData = debuffs[i]
            local auraFrame = debuffContainer.auras[idx]
            if auraFrame then
                auraFrame.icon:SetTexture(auraData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                auraFrame.auraData = auraData
                auraFrame.auraIndex = auraData._index
                auraFrame.auraFilter = "HARMFUL"
                
                -- Show stack count if >1
                local count = auraData.applications or auraData.count or 0
                if count > 1 then
                    if not auraFrame.count then
                        auraFrame.count = auraFrame:CreateFontString(nil, "OVERLAY")
                        auraFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                        auraFrame.count:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", -2, 2)
                    end
                    auraFrame.count:SetText(count)
                    auraFrame.count:Show()
                elseif auraFrame.count then
                    auraFrame.count:Hide()
                end
                
                -- Show cooldown if duration > 0
                if auraData.duration and auraData.duration > 0 and auraData.expirationTime then
                    auraFrame.cooldown:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration)
                    auraFrame.cooldown:Show()
                    auraFrame.timerText:Show()
                    auraFrame.timerText:SetText("")
                    auraFrame:SetScript("OnUpdate", function(self, elapsed)
                        local now = GetTime()
                        local timeLeft = (auraData.expirationTime or 0) - now
                        if timeLeft >= 1 and timeLeft < 60 then
                            self.timerText:SetText(string.format("%d", math.floor(timeLeft)))
                            self.timerText:Show()
                        else
                            self.timerText:SetText("")
                            self.timerText:Hide()
                            if timeLeft <= 0 then
                                self:SetScript("OnUpdate", nil)
                            end
                        end
                    end)
                else
                    auraFrame.cooldown:Hide()
                    auraFrame.timerText:Hide()
                    auraFrame:SetScript("OnUpdate", nil)
                end
                
                -- Debuff border color by dispel type
                if auraFrame.border then
                    local color = DebuffTypeColor and DebuffTypeColor[auraData.dispelName or auraData.debuffType or "none"] or {r=1,g=1,b=1}
                    auraFrame.border:SetVertexColor(color.r, color.g, color.b)
                end
                auraFrame:Show()
                idx = idx + 1
            end
        end
    end
end

----------------------------------------------------------
-- EVENT HANDLING
----------------------------------------------------------

function MMF_InitializeAuras()
    if MMF_TargetFrame then
        MMF_SetupTargetAuras()
    end

    local auraEventFrame = CreateFrame("Frame")
    auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    auraEventFrame:RegisterEvent("UNIT_AURA")
    auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    auraEventFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_ENTERING_WORLD" then
            MMF_SetupTargetAuras()
            MMF_UpdateTargetAuras()
        elseif event == "UNIT_AURA" and unit == "target" then
            MMF_UpdateTargetAuras()
        elseif event == "PLAYER_TARGET_CHANGED" then
            if MMF_TargetFrame and MMF_TargetFrame.DebuffContainer then
                for _, aura in ipairs(MMF_TargetFrame.DebuffContainer.auras) do
                    aura:Hide()
                end
            end
            MMF_UpdateTargetAuras()
        end
    end)
end
