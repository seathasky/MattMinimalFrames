


local D=MMF_Designer

D.inspectorTab="Basics"
D.showAdvancedParts=false
D.showAdvancedSettings=false

function D.FormatNumber(value,precision)
    value=D.Number(value,0)
    precision=math.floor(D.Number(precision,1,0,3))
    local text=string.format("%."..precision.."f",value)
    if precision>0 then text=text:gsub("0+$",""):gsub("%.$","") end
    if tonumber(text)==0 then return "0" end
    return text
end




D.friendlyCategories={
    {key="core",label="Main frame"},
    {key="castAuras",label="Cast bar and auras"},
    {key="indicators",label="Portrait and indicators"},
    {key="effects",label="Healing and effects"},
    {key="resources",label="Class resources"},
}

local components={
    {id="frame",label="Whole frame",category="core",members={"frame"}},
    {id="health",label="Health bar",category="core",toggleAll=true,members={"health","healthBackground","healthBorder","healthBorder.top","healthBorder.right","healthBorder.bottom","healthBorder.left"}},
    {id="name",label="Name",category="core",members={"name"}},
    {id="healthText",label="Health text",category="core",members={"healthText"}},
    {id="power",label="Power bar",category="core",toggleAll=true,members={"power","powerFill","powerBackground","powerBorder"}},
    {id="powerText",label="Power text",category="core",members={"powerText"}},
    {id="secondaryPower",label="Secondary mana bar",category="core",toggleAll=true,members={"secondaryPower","secondaryPowerBackground"}},
    {id="shamanTotemTimers",label="Shaman Totem Timers",category="core",members={"shamanTotemTimers"}},

    {id="cast",label="Cast bar",category="castAuras",toggleAll=true,members={"cast","castFill","castBackground","castBorder"}},
    {id="castName",label="Cast spell name",category="castAuras",members={"castName"}},
    {id="castTime",label="Cast timer",category="castAuras",members={"castTime"}},
    {id="castIcon",label="Cast spell icon",category="castAuras",members={"castIcon"}},
    {id="castShield",label="Interrupt shield",category="castAuras",members={"castShield"}},
    {id="buffs",label="Buffs",category="castAuras",members={"buffs","buffs.icon","buffs.count","buffs.timer","buffs.cooldown","buffs.border"}},
    {id="debuffs",label="Debuffs",category="castAuras",members={"debuffs","debuffs.icon","debuffs.count","debuffs.timer","debuffs.cooldown","debuffs.border"}},

    {id="portrait",label="Portrait or class icon",category="indicators",toggleAll=true,moveTogether=true,members={"portrait","portraitModel"}},
    {id="raidMarker",label="Raid marker",category="indicators",members={"raidMarker"}},
    {id="level",label="Level",category="indicators",members={"level"}},
    {id="classification",label="Elite / rare text",category="indicators",members={"classification"}},
    {id="pvp",label="PvP status",category="indicators",members={"pvp"}},
    {id="status",label="Dead / offline status",category="indicators",members={"status"}},
    {id="leader",label="Leader / assistant",category="indicators",members={"leader"}},
    {id="role",label="Group role",category="indicators",members={"role"}},
    {id="ready",label="Ready check",category="indicators",members={"ready"}},
    {id="resurrection",label="Incoming resurrection",category="indicators",members={"resurrection"}},
    {id="combat",label="Combat indicator",category="indicators",members={"combat"}},
    {id="resting",label="Resting indicator",category="indicators",members={"resting"}},
    {id="happiness",label="Pet happiness",category="indicators",toggleAll=true,members={"happiness","happinessBorder"}},

    {id="myHeal",label="Your incoming heals",category="effects",members={"myHeal"}},
    {id="otherHeal",label="Other incoming heals",category="effects",members={"otherHeal"}},
    {id="absorb",label="Absorb shield",category="effects",members={"absorb"}},
    {id="healAbsorb",label="Healing absorb",category="effects",members={"healAbsorb"}},
    {id="dispel",label="Dispel highlight",category="effects",members={"dispel"}},
    {id="hover",label="Mouseover highlight",category="effects",members={"hover"}},
    {id="combatOutline.top",label="Combat frame outline",category="effects",toggleAll=true,moveTogether=true,members={"combatOutline.top","combatOutline.right","combatOutline.bottom","combatOutline.left"}},
    {id="combatIconOutline1",label="Combat icon outline",category="effects",toggleAll=true,moveTogether=true,members={"combatIconOutline1","combatIconOutline2","combatIconOutline3","combatIconOutline4","combatIconOutline5","combatIconOutline6","combatIconOutline7","combatIconOutline8"}},

    {id="resources",label="Class resource bar",category="resources",members={"resources","resources.background","resource1","resource1.background","resource2","resource2.background","resource3","resource3.background","resource4","resource4.background","resource5","resource5.background","resource6","resource6.background","resource7","resource7.background","resource8","resource8.background","resource9","resource9.background","resource10","resource10.background"}},
    {id="resourceText",label="Class resource text",category="resources",members={"resourceText"}},
}
D.friendlyComponents=components
D.friendlyByID={}
D.friendlyOwner={}
for _,component in ipairs(components) do
    D.friendlyByID[component.id]=component
    for _,id in ipairs(component.members) do D.friendlyOwner[id]=component.id end
end

function D.FriendlyOwner(id)
    if id=="frame" then return "frame" end
    return D.friendlyOwner[id] or id
end
function D.FriendlyLabel(id)
    local owner=D.FriendlyOwner(id)
    local component=D.friendlyByID[owner]
    local spec=D.catalogByID[id]
    if spec and (D.showAdvancedParts or (D.selection and D.selection.id==id and owner~=id)) then return spec.label end
    return component and component.label or (spec and spec.label) or "Element"
end
function D.ComponentMembers(id)
    local component=D.friendlyByID[D.FriendlyOwner(id)]
    return component and component.members or {id}
end

function D.IsFriendlyMoveGroup(id)
    local component=D.friendlyByID[D.FriendlyOwner(id)]
    return component and component.moveTogether==true and D.showAdvancedParts~=true
end




function D.FriendlyMoveChanges(key,id,x,y)
    local cfg=D.ElementDesign(key,id)
    if not cfg then return {} end
    x=D.Number(x,cfg.x or 0,-4000,4000)
    y=D.Number(y,cfg.y or 0,-4000,4000)
    if not D.IsFriendlyMoveGroup(id) then return {{id,"x",x},{id,"y",y}} end
    local dx=x-(cfg.x or 0)
    local dy=y-(cfg.y or 0)
    local changes={}
    for _,member in ipairs(D.ComponentMembers(id)) do
        local memberCfg=D.ElementDesign(key,member)
        if memberCfg then
            changes[#changes+1]={member,"x",D.Number((memberCfg.x or 0)+dx,memberCfg.x or 0,-4000,4000)}
            changes[#changes+1]={member,"y",D.Number((memberCfg.y or 0)+dy,memberCfg.y or 0,-4000,4000)}
        end
    end
    return changes
end

local function AvailableIDs(key,frame)
    local result={frame=true}
    for _,spec in ipairs(D.Catalog(key,frame)) do result[spec.id]=true end
    return result
end
function D.FriendlyRows(key,frame,advanced)
    local available=AvailableIDs(key,frame)
    local rows={}
    if advanced then
        rows[#rows+1]={header=true,label="Every individual part",category="advanced"}
        rows[#rows+1]={id="frame",label="Whole frame",category="advanced",advanced=true}
        for _,spec in ipairs(D.Catalog(key,frame)) do
            rows[#rows+1]={id=spec.id,label=spec.label,category=D.FriendlyOwner(spec.id),advanced=true}
        end
        return rows
    end
    for _,category in ipairs(D.friendlyCategories) do
        local categoryRows={}
        for _,component in ipairs(components) do
            if component.category==category.key then
                local found=component.id=="frame"
                for _,id in ipairs(component.members) do if available[id] then found=true break end end
                if found and (component.id=="frame" or available[component.id] or available[component.members[1]]) then
                    categoryRows[#categoryRows+1]={id=component.id,label=component.label,component=component,category=category.key}
                end
            end
        end
        if #categoryRows>0 then
            rows[#rows+1]={header=true,label=category.label,category=category.key}
            for _,row in ipairs(categoryRows) do rows[#rows+1]=row end
        end
    end
    return rows
end



function D.FriendlySelection(id)
    if D.showAdvancedParts or (D.selection and D.selection.id==id) then return id end
    return D.FriendlyOwner(id)
end


function D.ShiftLayer(key,id,direction)
    if InCombatLockdown() or not D.ready then return end
    local cfg=D.ElementDesign(key,id);local spec=D.catalogByID[id]
    if not cfg or not spec then return end
    local source=D.Resolve(D.Representative(key),spec.field)
    D.PushHistory(key)
    if source and source.SetFrameLevel then cfg.layer=D.Number((cfg.layer or 0)+direction,0,0,100)
    else
        local layers={"BACKGROUND","BORDER","ARTWORK","OVERLAY","HIGHLIGHT"};local index=3
        for i,v in ipairs(layers) do if v==(cfg.drawLayer or (spec.kind=="text" and "OVERLAY" or "ARTWORK")) then index=i end end
        local sub=(cfg.layer or 0)+direction
        if sub>7 and index<#layers then index=index+1;sub=-8
        elseif sub< -8 and index>1 then index=index-1;sub=7 end
        cfg.drawLayer=layers[index];cfg.layer=D.Number(sub,0,-8,7)
    end
    D.ApplyUnit(key)
end

function D.ApplyCleanPreset(key)
    if not D.ready or InCombatLockdown() then return false end
    D.PushHistory(key)
    local unit=D.UnitDesign(key);local compact=key~="player" and key~="target"
    local width=compact and 130 or 220;local height=28
    unit.width=width;unit.height=height;unit.scale=1
    local function Place(id,w,h,x,y,parent,enabled)
        local cfg=D.ElementDesign(key,id)
        if not cfg then return end
        cfg.width=w;cfg.height=h;cfg.x=x;cfg.y=y;cfg.scale=1
        cfg.point="CENTER";cfg.relativePoint="CENTER";cfg.relativeTo=parent or "frame"
        if enabled~=nil then cfg.enabled=enabled end
    end
    Place("health",width-2,height-2,0,0,"frame",true)
    Place("healthBackground",width-2,height-2,0,0,"health",true)
    Place("healthBorder",width,height,0,0,"health",true)
    Place("healthBorder.top",width,1,0,(height-1)/2,"healthBorder",true)
    Place("healthBorder.bottom",width,1,0,-(height-1)/2,"healthBorder",true)
    Place("healthBorder.left",1,height,-(width-1)/2,0,"healthBorder",true)
    Place("healthBorder.right",1,height,(width-1)/2,0,"healthBorder",true)
    Place("name",width-8,18,0,23,"frame",true)
    Place("healthText",width-8,18,0,0,"frame",true)
    D.ElementDesign(key,"name").justify="LEFT";D.ElementDesign(key,"healthText").justify="CENTER"
    Place("power",width,5,0,-19,"frame",true)
    Place("powerFill",width-2,3,0,0,"power",true)
    Place("powerBackground",width-2,3,0,0,"power",true)
    Place("powerBorder",width,5,0,0,"power",true)
    Place("powerText",width-8,14,0,-11,"power",false)
    for _,id in ipairs({"healthText","powerText"}) do D.PlaceValueTextInside(D.ElementDesign(key,id),id) end
    local cast=key=="player" or key=="target" or key=="focus" or key=="boss" or key=="arena"
    Place("cast",width,14,0,-44,"frame",cast)
    Place("castFill",width-2,12,0,0,"cast",true)
    Place("castBackground",width-2,12,0,0,"cast",true)
    Place("castBorder",width,14,0,0,"cast",true)
    Place("castName",width-42,14,-17,0,"cast",true)
    Place("castTime",30,14,(width-34)/2,0,"cast",true)
    Place("castIcon",18,18,-width/2-12,0,"cast",true)
    Place("castShield",16,16,width/2+11,0,"cast",false)
    D.ElementDesign(key,"castName").justify="LEFT";D.ElementDesign(key,"castName").fontSize=11
    D.ElementDesign(key,"castTime").fontSize=11
    for _,id in ipairs({"castName","castTime","castIcon","castShield"}) do
        D.PlaceCastPart(D.ElementDesign(key,id),id,D.ElementDesign(key,"cast").width)
    end
    for _,id in ipairs({"buffs","debuffs"}) do
        local cfg=D.ElementDesign(key,id)
        cfg.iconSize=18;cfg.spacing=3;cfg.columns=compact and 5 or 8;cfg.rows=1;cfg.maxIcons=cfg.columns
        cfg.width=cfg.columns*21-3;cfg.height=18
        for _,field in ipairs({"growth","x","y","point","relativePoint","relativeTo"}) do
            cfg[field]=D.catalogByID[id].defaults[field]
        end
        if key=="boss" then D.PlaceBossAuras(cfg,id) end
    end
    for _,id in ipairs({"portrait","portraitModel"}) do Place(id,28,28,-width/2-20,0,"frame",false) end
    Place("raidMarker",18,18,width/2+12,0,"frame")
    Place("resources",width,7,0,-18,"cast")
    local resources=D.ElementDesign(key,"resources")
    if resources then resources.point="TOP";resources.relativePoint="BOTTOM" end
    for _,id in ipairs({"hover","dispel"}) do Place(id,width,height,0,0,"health") end
    D.ApplyUnit(key);return true
end
