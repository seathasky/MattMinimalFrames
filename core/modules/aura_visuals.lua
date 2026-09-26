

local A={}
MMF_AuraVisuals=A

function A.Create(button,isDebuff,native)
    local icon=button:CreateTexture(nil,"ARTWORK")
    icon:SetAllPoints(button);icon:SetTexCoord(.08,.92,.08,.92)
    local cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate")
    cooldown:SetAllPoints(icon);cooldown:SetDrawEdge(false);cooldown:SetHideCountdownNumbers(false);cooldown:EnableMouse(false)
    local timer=cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
    if not timer then for _,region in ipairs({cooldown:GetRegions()}) do if region.SetFont then timer=region;break end end end
    if timer then
        MMF_SetFontSafe(timer,MMF_GetGlobalFontPath(),12,"OUTLINE")
        timer:ClearAllPoints();timer:SetPoint("CENTER",cooldown,"CENTER",0,0)
    end
    local textOverlay=CreateFrame("Frame",nil,button)
    textOverlay:SetAllPoints(button);textOverlay:SetFrameLevel(cooldown:GetFrameLevel()+2);textOverlay:EnableMouse(false)
    button.mmfAuraTextOverlay=textOverlay
    local count=textOverlay:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    MMF_SetFontSafe(count,MMF_GetGlobalFontPath(),10,"OUTLINE")
    count:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-1,1);count:SetTextColor(1,1,1,1);count:SetText("")
    local border=button:CreateTexture(nil,"OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
    border:SetPoint("TOPLEFT",button,"TOPLEFT",-1,1);border:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",1,-1)
    border:SetVertexColor(isDebuff and .8 or 0,0,0,1)
    if native then
        button.mmfDesignerIcon,button.mmfDesignerCooldown,button.mmfDesignerCount,button.mmfDesignerBorder=icon,cooldown,count,border
        button:SetIcon(icon);button:SetDurationCooldown(cooldown);button:SetApplicationCount(count)
    else button.icon,button.cooldown,button.count,button.border=icon,cooldown,count,border end
    button.timerText=timer
    return button
end
function A.Parts(button)
    local cooldown=button.mmfDesignerCooldown or button.cooldown
    local timer=cooldown and cooldown.GetCountdownFontString and cooldown:GetCountdownFontString() or button.timerText
    return {icon=button.mmfDesignerIcon or button.icon,count=button.mmfDesignerCount or button.count,
        cooldown=cooldown,timer=timer,border=button.mmfDesignerBorder or button.border}
end
function A.Dimensions(cfg)
    local D=MMF_Designer
    local size=D.Number(cfg.iconSize,18,8,100)
    local columns=math.floor(D.Number(cfg.columns,4,1,16))
    local rows=math.floor(D.Number(cfg.rows,2,1,16))
    local spacing=D.Number(cfg.spacing,2,0,32)
    local limit=math.min(math.floor(D.Number(cfg.maxIcons,16,1,16)),columns*rows)
    return columns*size+(columns-1)*spacing,rows*size+(rows-1)*spacing,size,columns,rows,spacing,limit
end
function A.Growth(cfg,isDebuff)
    local growth=cfg.growth or (isDebuff and "LEFT_UP" or "RIGHT_UP")
    local left=growth:find("LEFT",1,true)~=nil;local up=growth:find("UP",1,true)~=nil
    local point=(up and "BOTTOM" or "TOP")..(left and "RIGHT" or "LEFT")
    local vertical=growth:match("^UP_")~=nil or growth:match("^DOWN_")~=nil
    return point,left,up,vertical
end
function A.PlaceButton(button,index,container,cfg)
    local _,_,size,columns,rows,spacing=A.Dimensions(cfg)
    local point,left,up,vertical=A.Growth(cfg,container.mmfAuraIsDebuff)
    local column=vertical and math.floor((index-1)/rows) or (index-1)%columns
    local row=vertical and (index-1)%rows or math.floor((index-1)/columns)
    button:ClearAllPoints();button:SetSize(size,size)
    button:SetPoint(point,container,point,column*(size+spacing)*(left and -1 or 1),row*(size+spacing)*(up and 1 or -1))
end
function A.CreatePreviewContainer(owner,isDebuff)
    local container=CreateFrame("Frame",nil,owner)
    container.mmfPreview=true;container.mmfAuraUnit=owner.unit;container.mmfAuraIsDebuff=isDebuff;container.mmfAuraOwnerFrame=owner
    container:SetPoint("CENTER",owner,"CENTER",0,50);container:SetSize(78,38);container:EnableMouse(false)
    container.auras={}
    for i=1,16 do
        local button=CreateFrame("Frame",nil,container)
        button.mmfPreview=true;button:EnableMouse(false)
        A.Create(button,isDebuff,false)
        container.auras[i]=button
    end
    return container
end
