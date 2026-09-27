
local D=MMF_Designer
local S={}
MMF_DesignerSamples=S
local X=MMF_ExtraVisuals
local buffs={
    {icon="Spell_Holy_Renew",stacks=3,duration=24},
    {icon="Spell_Holy_MagicalSentry",stacks=0,duration=0},
    {icon="Spell_Frost_FrostArmor02",stacks=2,duration=32},
    {icon="Spell_Nature_Regeneration",stacks=0,duration=20},
    {icon="Spell_Holy_WordFortitude",stacks=0,duration=0},
    {icon="Spell_Nature_LightningShield",stacks=4,duration=30},
}
local debuffs={
    {icon="Spell_Shadow_ShadowWordPain",stacks=3,duration=24,type="Magic"},
    {icon="Spell_Nature_CorrosiveBreath",stacks=2,duration=28,type="Poison"},
    {icon="Spell_Shadow_CurseOfTounges",stacks=0,duration=32,type="Curse"},
    {icon="Spell_Shadow_AbominationExplosion",stacks=0,duration=20,type="Disease"},
    {icon="Ability_Gouge",stacks=0,duration=12,type="none"},
}
S.AuraFixtures={buffs=buffs,debuffs=debuffs}
local conditional={combat=true,resting=true,leader=true,role=true,ready=true,resurrection=true,status=true,hover=true,
    dispel=true,classification=true,myHeal=true,otherHeal=true,absorb=true,healAbsorb=true}
local effects={myHeal=true,otherHeal=true,absorb=true,healAbsorb=true}

local function public(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...)
    if ok and D.Readable(value) then return value end
end
function S.State(frame)
    local key=frame.mmfDesignerKey
    local source=frame.unit
    local exists=public(UnitExists,source)==true
    local class=select(2,UnitClass(exists and source or "player"))
    if not D.Readable(class) then class=select(2,UnitClass("player")) end
    local party=key=="player" or key=="party" or key=="raid" or key=="arena"
    local isPlayer=exists and public(UnitIsPlayer,source)==true or (not exists and party)
    local enemy=exists and public(UnitIsEnemy,"player",source)==true or (not exists and (key=="target" or key=="boss" or key=="arena" or key=="focus"))
    local powerType,powerToken=0,"MANA"
    if exists and UnitPowerType then
        local pt,token=UnitPowerType(source)
        if D.Readable(pt) and D.Readable(token) then powerType,powerToken=pt or 0,token or "MANA" end
    end
    if key=="player" and class=="SHAMAN" and MMF_Compat.IsRetail then powerType,powerToken=0,"MANA" end
    local state=D.sampleState or "normal"
    local name=exists and public(UnitName,source) or nil
    if type(name)~="string" or name=="" then name=(D.byUnitType[key] or {}).label or "Unit" end
    local selected=D.selection and D.selection.id
    return {name=name,source=exists and source or "player",exists=exists,class=class,isPlayer=isPlayer,
        isEnemy=enemy,isFriend=not enemy,powerType=powerType,powerToken=powerToken,power=.86,
        health=(state=="low" and .22 or state=="healing" and .62 or state=="status" and 0 or 1),
        casting=true,channeling=state=="channel",uninterruptible=state=="uninterruptible" or selected=="castShield",
        scene=state,key=key}
end

function S.SelectedPath(id)
    local selected=D.selection and D.selection.id
    local seen={}
    while selected and selected~="frame" and not seen[selected] do
        if id==selected then return true end
        seen[selected]=true
        selected=D.catalogByID[selected] and D.catalogByID[selected].parent
    end
    return false
end
function S.Shown(key,id,state)
    if D.gamePreviewElements then return D.gamePreviewElements[id]==true end
    if D.renderMoveSamples then
        local category=D.MoveSampleCategory(id)
        if not category or not D.moveCategories[category] then return false end
        local cfg=D.ElementDesign(key,id)
        if id~=category and cfg and cfg.enabled==false then return false end
        if key=="boss" and category=="buffs" and D.ElementDesign(key,"buffs").enabled==false then return false end
        return true
    end
    local cfg=D.ElementDesign(key,id)
    if not cfg then return false end
    local reveal=D.showHiddenElements==true or state=="all" or S.SelectedPath(id)
    if not reveal and cfg.enabled==false then return false end
    local parent=D.catalogByID[id] and D.catalogByID[id].parent
    if parent and parent~="frame" and not S.Shown(key,parent,state) then return false end
    if reveal then return true end
    if id:match("^combatOutline") or id:match("^combatIconOutline") then return state=="combat" end
    if not conditional[id] then return true end
    if effects[id] then return state=="healing" end
    if id=="combat" then return state=="combat" end
    if id=="resting" then return state=="resting" end
    if id=="status" then return state=="status" end
    if id=="dispel" then return state=="auras" end
    return state=="indicators"
end

function S.ApplyData(frame)
    local state=S.State(frame);frame.mmfSampleState=state
    local key=frame.mmfDesignerKey
    local design=D.UnitDesign(key)
    local format=MMF_UnitVisualStyle
    MMF_Visuals.ApplySampleColors(frame,state)
    local name=format.DisplayName(frame.unit,state.name)
    
    if state.exists then name=format.DecoratedName(frame.unit,name,MattMinimalFramesDB) end
    frame.nameText:SetText(name)
    frame.mmfCachedNameText = nil
    frame.mmfNameTextCacheSet = nil
    frame.mmfNameResizeCache = nil
    local showPercent=design.showHealthPercent
    if showPercent==nil then showPercent=MMF_GetShowHPPercentText and MMF_GetShowHPPercentText(frame.unit)~=false end
    local showValue=design.showHealthValue
    if showValue==nil then showValue=MMF_GetShowHPValueText and MMF_GetShowHPValueText(frame.unit)==true end
    local max=public(UnitHealthMax,frame.unit)
    if type(max)~="number" or max<=0 then max=10000 end
    local value=math.floor(max*state.health)
    local percent=tostring(math.floor(state.health*100+.5)).."%"
    local short=MMF_GetUseShortHPValue and MMF_GetUseShortHPValue(frame.unit) or (MattMinimalFramesDB and MattMinimalFramesDB.useShortHPValue)
    frame.hpText:SetText(format.FormatHealth(value,showPercent,showValue,short,percent))
    frame.healthBar:SetMinMaxValues(0,1);frame.healthBar:SetValue(state.health)
    frame.powerBar:SetMinMaxValues(0,1);frame.powerBar:SetValue(state.power)
    if frame.powerText then frame.powerText:SetText("86%") end
    if frame.secondaryPowerBar then frame.secondaryPowerBar:SetMinMaxValues(0,1);frame.secondaryPowerBar:SetValue(.72) end
    if frame.castBar then
        frame.castBar:SetMinMaxValues(0,1);frame.castBar:SetValue(state.channeling and .7 or .55)
        frame.castBarText:SetText(state.channeling and "Tranquility" or "Healing Wave")
        frame.castBarTime:SetText("1.8")
        frame.designerCastIcon:SetTexture(state.channeling and "Interface\\Icons\\Spell_Nature_Tranquility" or "Interface\\Icons\\Spell_Nature_HealingWaveGreater")
        frame.designerCastIcon:SetTexCoord(.08,.92,.08,.92)
        X.CastShield(frame.designerCastShield)
    end
    if frame.designerLevel then frame.designerLevel:SetText(tostring(public(UnitLevel,state.source) or 70)) end
    if frame.designerClassification then frame.designerClassification:SetText(D.sampleChoices.classification or "Elite") end
    if frame.designerStatus then frame.designerStatus:SetText(D.sampleChoices.status or "OFFLINE") end
    if frame.pvpFlagText then frame.pvpFlagText:SetText("PVP") end
    X.Leader(frame.designerLeader,D.sampleChoices.leader or "leader")
    X.Role(frame.designerRole,D.sampleChoices.role or "HEALER")
    X.Ready(frame.designerReady,D.sampleChoices.ready or "ready")
    X.Resurrection(frame.designerResurrection)
    X.RaidMarker(frame.targetMarker,D.sampleChoices.raidMarker or 8)
    X.Happiness(frame.designerHappiness,D.sampleChoices.happiness or 3)
    if frame.shamanTotemTimers then MMF_TotemTimers.Sample(frame) end
    local portrait=D.ElementDesign(key,"portrait")
    local mode=portrait.iconMode or "class"
    if D.selection and D.selection.id=="portraitModel" then mode="portrait_animated" end
    local icons=MMF_FrameFactoryIcons
    if key=="player" then icons.ApplyPlayerFrameIconMode(frame,mode)
    elseif key=="target" then icons.ApplyTargetFrameIconMode(frame,mode,state.source)
    elseif mode=="portrait_animated" then icons.ApplyAnimatedPortrait(frame,state.source)
    elseif mode=="class" then
        local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[state.class]
        if coords then frame.designerPortrait:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");icons.ApplyClassCoords(frame.designerPortrait,coords) end
    else icons.ApplyUnitPortrait(frame.designerPortrait,state.source,mode) end
    frame.mmfSamplePortraitMode=mode
    if frame.restingTexture then
        local indicators=MMF_FrameFactoryIndicators
        indicators.ConfigureResting(frame);indicators.ConfigureCombat(frame)
        indicators.SetRestingState(frame,S.Shown(key,"resting",state.scene))
        indicators.SetCombatState(frame,S.Shown(key,"combat",state.scene))
    end
    if frame.designerResources then
        local resources=frame.designerResources
        for i,rune in ipairs(resources.runes or {}) do rune:SetMinMaxValues(0,1);rune:SetValue(i<=3 and 1 or .25) end
        if resources.valueText then resources.valueText:SetText("55") end
    end
end

local function Prediction(frame,id,fraction,start)
    local cfg=D.ElementDesign(frame.mmfDesignerKey,id)
    local object=frame.mmfDesignerNodes[id]
    if not object then return end
    object:SetMinMaxValues(0,1);object:SetValue(1)
    if not cfg.followHealth then object:SetValue(fraction);return end
    local health=frame.healthBar;local h=D.ElementDesign(frame.mmfDesignerKey,"health")
    object:ClearAllPoints()
    local width,height=health:GetWidth(),health:GetHeight()
    if h.orientation=="VERTICAL" then
        object:SetSize(width,height*fraction)
        local point=h.reverseFill and "TOP" or "BOTTOM"
        object:SetPoint(point,health,point,cfg.x or 0,(h.reverseFill and -1 or 1)*height*start+(cfg.y or 0))
    else
        object:SetSize(width*fraction,height)
        local point=h.reverseFill and "RIGHT" or "LEFT"
        object:SetPoint(point,health,point,(h.reverseFill and -1 or 1)*width*start+(cfg.x or 0),cfg.y or 0)
    end
end

function S.ApplyAuras(frame,isDebuff)
    local key=frame.mmfDesignerKey;local state=frame.mmfSampleState
    local id=isDebuff and "debuffs" or "buffs"
    local container=isDebuff and frame.DebuffContainer or frame.BuffContainer
    local cfg=D.ElementDesign(key,id);local A=MMF_AuraVisuals
    local w,h,_,_,_,_,limit=A.Dimensions(cfg)
    container:SetSize(w,h)
    local visible=S.Shown(key,id,state.scene)
    container:SetShown(visible)
    local fixtures=isDebuff and debuffs or buffs
    for i,button in ipairs(container.auras) do
        if i<=limit and visible then
            A.PlaceButton(button,i,container,cfg)
            local sample=fixtures[(i-1)%#fixtures+1]
            local parts=A.Parts(button)
            parts.icon:SetTexture("Interface\\Icons\\"..sample.icon)
            parts.count:SetText(sample.stacks>0 and tostring(sample.stacks) or "")
            if sample.duration>0 then
                if not button.mmfSampleCooldownUntil or GetTime()>=button.mmfSampleCooldownUntil then
                    parts.cooldown:SetCooldown(GetTime()-4,sample.duration)
                    button.mmfSampleCooldownUntil=GetTime()+sample.duration-5
                end
                if parts.timer then parts.timer:SetText(tostring(sample.duration-4)) end
            else
                if parts.cooldown.Clear then parts.cooldown:Clear() else parts.cooldown:SetCooldown(0,0) end
                if parts.timer then parts.timer:SetText("") end
            end
            if isDebuff then
                local color=DebuffTypeColor and (DebuffTypeColor[sample.type] or DebuffTypeColor.none)
                parts.border:SetVertexColor(color and color.r or .8,color and color.g or 0,color and color.b or 0,1)
            else parts.border:SetVertexColor(0,0,0,1) end
            D.StyleAuraButton(button,frame.unit,isDebuff)
            for suffix,region in pairs(parts) do
                if region then region:SetShown(S.Shown(key,id.."."..suffix,state.scene)) end
            end
            
            
            local sweep=S.Shown(key,id..".cooldown",state.scene)
            local timer=S.Shown(key,id..".timer",state.scene)
            parts.cooldown:SetShown(sample.duration>0 and (sweep or timer))
            if parts.cooldown.SetDrawSwipe then parts.cooldown:SetDrawSwipe(sweep) end
            parts.cooldown:SetHideCountdownNumbers(not timer)
            button:Show()
        else button:Hide() end
    end
end

function S.ApplyVisibility(frame)
    local key=frame.mmfDesignerKey;local state=frame.mmfSampleState
    for _,spec in ipairs(D.Catalog(key,frame)) do
        local region=frame.mmfDesignerNodes[spec.id]
        if region then region:SetShown(S.Shown(key,spec.id,state.scene)) end
    end
    if frame.portraitModel then
        local show=S.Shown(key,"portrait",state.scene)
        if D.selection and D.selection.id=="portraitModel" then show=true end
        frame.portraitModel:SetShown(show and frame.mmfSamplePortraitMode=="portrait_animated")
        frame.designerPortrait:SetShown(show and frame.mmfSamplePortraitMode~="portrait_animated")
    end
    if frame.designerCastShield then frame.designerCastShield:SetShown(S.Shown(key,"castShield",state.scene) and state.uninterruptible) end
    
    
    local selected=D.selection and D.selection.id
    if state.scene=="healing" or state.scene=="all" or effects[selected] then
        frame.healthBar:SetValue(.62)
        if frame.hpText then
            local design=D.UnitDesign(key)
            frame.hpText:SetText(MMF_UnitVisualStyle.FormatHealth(6200,design.showHealthPercent~=false,design.showHealthValue==true,true,"62%"))
        end
        Prediction(frame,"myHeal",.16,.62);Prediction(frame,"otherHeal",.10,.78)
        Prediction(frame,"absorb",.12,.88);Prediction(frame,"healAbsorb",.08,.54)
    end
    S.ApplyAuras(frame,false);S.ApplyAuras(frame,true)
end
