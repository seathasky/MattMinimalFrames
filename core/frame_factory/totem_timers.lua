local T={}
MMF_TotemTimers=T

local sampleIcons={"Spell_Fire_SearingTotem","Spell_Nature_StoneSkinTotem",
    "Spell_Nature_HealingStreamTotem","Spell_Nature_Windfury"}

local function Readable(value)
    return not (issecretvalue and issecretvalue(value)) and not (canaccessvalue and not canaccessvalue(value))
end

local function Layout(holder)
    local count=#holder.buttons
    local size=math.max(1,math.min(holder:GetHeight()-12,(holder:GetWidth()-(count-1)*4)/count))
    for index,button in ipairs(holder.buttons) do
        button:ClearAllPoints()
        button:SetSize(size,size)
        button:SetPoint("TOPLEFT",holder,"TOPLEFT",(index-1)*(size+4),0)
    end
end

function T.Create(frame)
    if frame.shamanTotemTimers then return frame.shamanTotemTimers end
    if frame.unit~="player" or select(2,UnitClass("player"))~="SHAMAN" then return end
    local holder=CreateFrame("Frame",nil,frame)
    frame.shamanTotemTimers=holder
    holder.buttons={}
    holder:SetSize(140,36)
    holder:SetPoint("CENTER",frame,"CENTER",0,-82)
    local count=math.max(1,type(GetNumTotemSlots)=="function" and GetNumTotemSlots() or MAX_TOTEMS or 4)
    for index=1,count do
        local button=CreateFrame("Frame",nil,holder)
        holder.buttons[index]=button
        button.slot=(SHAMAN_TOTEM_PRIORITIES and SHAMAN_TOTEM_PRIORITIES[index]) or index
        button.icon=button:CreateTexture(nil,"ARTWORK")
        button.icon:SetAllPoints(button)
        button.icon:SetTexCoord(.08,.92,.08,.92)
        button.cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate")
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetReverse(true)
        button.cooldown:EnableMouse(false)
        button.timer=MMF_ExtraVisuals.Text(button,"timerText",button,10,"")
        button.timer:SetPoint("TOP",button,"BOTTOM",0,-1)
        button.timer:SetSize(40,12)
        button:EnableMouse(not frame.mmfPreview)
        button:SetScript("OnEnter",function(self)
            if GameTooltip and GameTooltip.SetTotem then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:SetTotem(self.slot)
            end
        end)
        button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        button:Hide()
    end
    holder:SetScript("OnSizeChanged",Layout)
    Layout(holder)
    holder:Hide()
    return holder
end

function T.Update(frame)
    local holder=frame.shamanTotemTimers
    if not holder or frame.mmfPreview then return end
    local enabled=select(2,UnitClass("player"))=="SHAMAN"
        and MMF_Designer.IsEnabled("player","shamanTotemTimers")
    holder:SetShown(enabled)
    if not enabled then return end
    for _,button in ipairs(holder.buttons) do
        local haveTotem,name,start,duration,icon,modRate
        if type(GetTotemInfo)=="function" then
            haveTotem,name,start,duration,icon,modRate=GetTotemInfo(button.slot)
        end
        if (Readable(haveTotem) and not haveTotem)
            or (Readable(duration) and type(duration)=="number" and duration<=0) then
            button:Hide()
        else
            -- Retail can return secret timing values; pass those straight to the cooldown widget.
            button.icon:SetTexture(icon)
            if type(GetTotemDuration)=="function" and button.cooldown.SetCooldownFromDurationObject then
                button.cooldown:SetCooldownFromDurationObject(GetTotemDuration(button.slot))
            else
                button.cooldown:SetCooldown(start,duration,modRate)
            end
            local remaining
            if type(GetTotemTimeLeft)=="function" then remaining=GetTotemTimeLeft(button.slot) end
            if Readable(remaining) and remaining==nil and Readable(start) and Readable(duration) and type(start)=="number" and type(duration)=="number" then
                remaining=start+duration-GetTime()
            end
            local publicTime=Readable(remaining)
            if publicTime and type(remaining)=="number" then
                button.timer:SetText(remaining>=60 and string.format("%dm",math.ceil(remaining/60)) or tostring(math.max(0,math.ceil(remaining))))
            else button.timer:SetText("") end
            if button.cooldown.SetHideCountdownNumbers then button.cooldown:SetHideCountdownNumbers(publicTime) end
            button:SetShown(haveTotem)
        end
    end
end

function T.Sample(frame)
    local holder=frame.shamanTotemTimers
    if not holder then return end
    for index,button in ipairs(holder.buttons) do
        local duration=30+index*15
        button.icon:SetTexture("Interface\\Icons\\"..sampleIcons[(index-1)%4+1])
        button.cooldown:SetCooldown(GetTime()-10,duration)
        if button.cooldown.SetHideCountdownNumbers then button.cooldown:SetHideCountdownNumbers(true) end
        button.timer:SetText(tostring(duration-10))
        button:Show()
    end
end
