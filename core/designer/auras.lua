

local D = MMF_Designer
D.nativeAuraButtons=setmetatable({}, {__mode="k"})
local pendingButtons=setmetatable({}, {__mode="k"})
local pendingContainers=setmetatable({}, {__mode="k"})
local function AuraConfig(unit, isDebuff)
    local key=D.Key(unit)
    return key and D.ElementDesign(key,isDebuff and "debuffs" or "buffs"),key
end
local function AuraRegion(button, region, key, id, iconSize)
    if not region then return end
    local cfg=D.ElementDesign(key,id)
    local spec=D.catalogByID[id]
    if not cfg or not spec then return end
    if not button.mmfPreview then D.Own(region,key,spec) end
    local width,height=cfg.width,cfg.height
    if cfg.fitIcon~=false and (spec.auraSub=="icon" or spec.auraSub=="cooldown" or spec.auraSub=="border") then
        width,height=iconSize,iconSize
        if spec.auraSub=="border" then width,height=width+2,height+2 end
    end
    D.Raw(region,"ClearAllPoints")
    D.Raw(region,"SetPoint",cfg.point or "CENTER",button,cfg.relativePoint or "CENTER",cfg.x or 0,cfg.y or 0)
    if region.SetFont and cfg.fitTextToContent then D.Raw(region,"SetSize",0,0)
    else D.Raw(region,"SetSize",width,height) end
    D.Raw(region,"SetScale",cfg.scale or 1)
    D.Raw(region,"SetAlpha",cfg.opacity or 1)
    if region.SetFrameLevel then
        D.Raw(region,"SetFrameLevel",button:GetFrameLevel()+math.max(1,math.floor(cfg.layer or 1)))
    elseif region.SetDrawLayer then
        D.Raw(region,"SetDrawLayer",cfg.drawLayer or (region.SetFont and "OVERLAY" or "ARTWORK"),math.max(-8,math.min(7,cfg.layer or 0)))
    end
    if region.SetFont then
        local path=cfg.font or (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or STANDARD_TEXT_FONT
        D.ApplyFont(region,path,cfg.fontSize or 10,cfg.fontFlags or "OUTLINE")
        D.Raw(region,"SetJustifyH",cfg.justify or "CENTER")
    end
    if cfg.colorMode=="custom" and cfg.color then
        D.Raw(region,region.SetTextColor and "SetTextColor" or "SetVertexColor",unpack(cfg.color))
    end
    if cfg.enabled==false then D.Raw(region,"Hide")
    elseif region.mmfDesignerWantsShown~=false then D.Raw(region,"Show") end
end
function D.StyleAuraButton(button,unit,isDebuff)
    
    
    if not button then return end
    if button.IsForbidden and button:IsForbidden() then
        D.nativeAuraButtons[button]=nil
        return
    end
    local cfg,key=AuraConfig(unit,isDebuff)
    if not cfg then return end
    local native=button.mmfDesignerIcon~=nil
    if native and not button.mmfPreview then D.nativeAuraButtons[button]={unit=unit,isDebuff=isDebuff} end
    if not button.mmfPreview and InCombatLockdown() and button.mmfDesignerStyled then
        pendingButtons[button]={unit=unit,isDebuff=isDebuff}
        return
    end
    pendingButtons[button]=nil
    local id=isDebuff and "debuffs" or "buffs"
    local size=D.Number(cfg.iconSize,18,8,100)
    
    button:SetSize(size,size)
    if not native then
        D.ClearLegacyDragScripts(button); button:SetScript("OnMouseUp",nil)
        if not button.count then
            
            
            button.count=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            button.count:SetTextColor(1,1,1,1)
            button.count:SetText("")
        end
        if not button.border then
            button.border=button:CreateTexture(nil,"OVERLAY")
            button.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
            button.border:SetVertexColor(0,0,0,1)
        end
    elseif not button.mmfDesignerBorder then
        button.mmfDesignerBorder=button:CreateTexture(nil,"OVERLAY")
        button.mmfDesignerBorder:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        button.mmfDesignerBorder:SetVertexColor(0,0,0,1)
    end
    local icon=button.mmfDesignerIcon or button.icon
    local count=button.mmfDesignerCount or button.count
    local cooldown=button.mmfDesignerCooldown or button.cooldown
    local border=button.mmfDesignerBorder or button.border
    AuraRegion(button,icon,key,id..".icon",size)
    AuraRegion(button,count,key,id..".count",size)
    AuraRegion(button,cooldown,key,id..".cooldown",size)
    AuraRegion(button,border,key,id..".border",size)
    if cooldown then
        local timerCfg=D.ElementDesign(key,id..".timer")
        cooldown:SetHideCountdownNumbers(timerCfg.enabled==false)
        local sweepCfg=D.ElementDesign(key,id..".cooldown")
        if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(sweepCfg.enabled~=false) end
        
        if sweepCfg.enabled==false and timerCfg.enabled~=false then D.Raw(cooldown,"Show") end
        local countdown=cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
        if countdown then AuraRegion(button,countdown,key,id..".timer",size) end
        for _, region in ipairs({cooldown:GetRegions()}) do
            if region~=countdown and region.SetFont then AuraRegion(button,region,key,id..".timer",size) end
        end
        if button.timerText and button.timerText~=countdown then
            AuraRegion(button,button.timerText,key,id..".timer",size)
        end
    end
    if button.mmfAuraTextOverlay and cooldown then button.mmfAuraTextOverlay:SetFrameLevel(cooldown:GetFrameLevel()+2) end
    button.mmfDesignerStyled=true
end
function D.ConfigureAuraContainer(container,isDebuff)
    if not container then return end
    local unit=container.mmfAuraUnit
    local cfg,key=AuraConfig(unit,isDebuff)
    if not cfg then return end
    if InCombatLockdown() then pendingContainers[container]={isDebuff=isDebuff}; return end
    pendingContainers[container]=nil
    local width,height,size,columns,rows,spacing,limit=MMF_AuraVisuals.Dimensions(cfg)
    local point,left,up,vertical=MMF_AuraVisuals.Growth(cfg,isDebuff)
    if container.mmfSecureAuraContainer then
        local group=container.mmfAuraGroupKey
        local filter=isDebuff and "HARMFUL" or "HELPFUL"
        if cfg.filter=="mine" then filter=filter.."|PLAYER" end
        container:SetAuraGroupFilterString(group,filter)
        container:SetAuraGroupMaxFrameCount(group,limit)
        container:SetAuraGroupLayout(group,{elementSpacing=spacing,lineSpacing=spacing,elementWidth=size,elementHeight=size})
        container:SetFlowLayoutAxis(vertical and AnchorUtil.FlowLayoutAxis.Vertical or AnchorUtil.FlowLayoutAxis.Horizontal)
        container:SetFlowLayoutAnchorPoint(point)
        container:SetFlowLayoutGrowthDirection(left and AnchorUtil.FlowDirection.Left or AnchorUtil.FlowDirection.Right,up and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down)
        local lineCount=vertical and rows or columns
        container:SetFlowLayoutMaximumLineSize(lineCount*size+(lineCount-1)*spacing)
        container:SetEnabled(cfg.enabled~=false)
        container:SetShown(cfg.enabled~=false)
        for button,info in pairs(D.nativeAuraButtons) do
            if button.IsForbidden and button:IsForbidden() then
                D.nativeAuraButtons[button]=nil
            elseif info.unit==unit and info.isDebuff==isDebuff then
                D.StyleAuraButton(button,unit,isDebuff)
            end
        end
    else
        D.ClearLegacyDragScripts(container); container:SetScript("OnMouseUp",nil)
        container:EnableMouse(false)
        for index,button in ipairs(container.auras or {}) do
            MMF_AuraVisuals.PlaceButton(button,index,container,cfg)
            D.StyleAuraButton(button,unit,isDebuff)
            if index>limit then button:Hide() end
        end
        if container.mmfAuraLabel then container.mmfAuraLabel:Hide() end
        container:SetShown(cfg.enabled~=false)
    end
    
    cfg.width,cfg.height=width,height
    D.Raw(container,"SetSize",cfg.width,cfg.height)
end
function D.RefreshAuras(frame)
    if not frame or not frame.mmfDesignerKey then return end
    for _, isDebuff in ipairs({false,true}) do
        local id=isDebuff and "debuffs" or "buffs"
        local container=isDebuff and frame.DebuffContainer or frame.BuffContainer
        local cfg=D.ElementDesign(frame.mmfDesignerKey,id)
        if container and not container.mmfSecureAuraContainer then
            if cfg.enabled==false or not UnitExists(frame.unit) then
                for _,button in ipairs(container.auras or {}) do button:Hide() end
            else
                local filter=isDebuff and "HARMFUL" or "HELPFUL"
                
                
                local sourceAuras=_G.MMF_Compat.GetUnitAuras(frame.unit,filter) or {}
                local auras={}
                if frame.unit=="player" and not isDebuff and MMF_GetLegacyTemporaryEnchants then
                    for _,enchant in ipairs(MMF_GetLegacyTemporaryEnchants()) do auras[#auras+1]=enchant end
                end
                for _,aura in ipairs(sourceAuras) do
                    local source=aura.sourceUnit or aura.source or aura.caster
                    if cfg.filter~="mine" or source=="player" or source=="pet" or source=="vehicle"
                        or aura.isFromPlayerOrPlayerPet==true or aura.isFromPlayerOrPet==true then
                        auras[#auras+1]=aura
                    end
                end
                local limit=math.min(cfg.maxIcons or 16,(cfg.columns or 4)*(cfg.rows or 2),#(container.auras or {}))
                for index,button in ipairs(container.auras or {}) do
                    if index<=limit and auras[index] then
                        MMF_UpdateAuraIconData(button,auras[index],isDebuff and "HARMFUL" or "HELPFUL",frame.unit,index)
                        
                        if not InCombatLockdown() then D.StyleAuraButton(button,frame.unit,isDebuff) end
                    else button:Hide() end
                end
            end
        end
    end
end
function D.ApplyAuras(frame)
    D.ConfigureAuraContainer(frame.BuffContainer,false)
    D.ConfigureAuraContainer(frame.DebuffContainer,true)
    D.RefreshAuras(frame)
end



function D.FlushPendingAuraStyles()
    if InCombatLockdown() then return end
    for container,info in pairs(pendingContainers) do
        pendingContainers[container]=nil
        D.Try("deferred aura container",D.ConfigureAuraContainer,container,info.isDebuff)
    end
    for button,info in pairs(pendingButtons) do
        pendingButtons[button]=nil
        D.Try("deferred aura style",D.StyleAuraButton,button,info.unit,info.isDebuff)
    end
end
