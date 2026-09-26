
local D = MMF_Designer






function D.ClearLegacyDragScripts(object)
    if not object or type(object.SetScript) ~= "function"
        or type(object.HasScript) ~= "function" then return end
    local supportsStart = object:HasScript("OnDragStart")
    if D.Readable(supportsStart) and supportsStart then
        object:SetScript("OnDragStart", nil)
    end
    local supportsStop = object:HasScript("OnDragStop")
    if D.Readable(supportsStop) and supportsStop then
        object:SetScript("OnDragStop", nil)
    end
end
local layoutMethods = {"ClearAllPoints", "SetPoint", "SetAllPoints", "SetSize", "SetWidth", "SetHeight", "SetScale", "SetFont", "SetJustifyH", "SetJustifyV", "SetDrawLayer", "SetFrameLevel", "SetOrientation", "SetReverseFill"}
local function Call(object, method, ...)
    local raw = object and object.mmfDesignerRaw
    local fn = raw and raw[method] or object and object[method]
    if fn then return fn(object, ...) end
end
D.Raw = Call



function D.ApplyFont(object, path, size, flags)
    if not object or type(object.SetFont) ~= "function" then return false end
    local raw = object.mmfDesignerRaw
    local setter = raw and raw.SetFont or object.SetFont
    return MMF_SetFontSafe(object, path, D.Number(size, 12, 6, 96), flags, setter)
end
function D.Root(frame,method,...)
    local originals=frame.mmfDesignerRootMethods
    local fn=originals and originals[method] or frame[method]
    if fn then return fn(frame,...) end
end
local function OwnRoot(frame)
    if frame.mmfDesignerRootMethods then return end
    local originals={};frame.mmfDesignerRootMethods=originals
    for _,method in ipairs({"ClearAllPoints","SetPoint","SetAllPoints","SetSize","SetWidth","SetHeight","SetScale"}) do
        local name,original=method,frame[method]
        if original then
            originals[name]=original
            frame[name]=function(self,...)
                if D.capturing then return original(self,...) end
                
            end
        end
    end
end
local function SafeGet(object, method, fallback, ...)
    if not object or not object[method] then return fallback end
    local ok, value = pcall(object[method], object, ...)
    if ok and D.Readable(value) and value ~= nil then return value end
    return fallback
end
D.SafeGet = SafeGet
local function Config(object)
    local info = object.mmfDesignerInfo
    if not info then return nil end
    local db = MattMinimalFramesDB
    local profile = db and type(db.designer)=="table" and db.designer
    local unit = profile and type(profile.units)=="table" and profile.units[info.key]
    local elements = type(unit)=="table" and type(unit.elements)=="table" and unit.elements
    local cfg = elements and elements[info.id]
    
    
    if type(cfg)=="table" then return cfg end
    return D.ElementDesign(info.key, info.id)
end
local function Own(object, key, spec)
    if not object or object.mmfDesignerRaw then return end
    local raw = {}
    object.mmfDesignerRaw = raw
    object.mmfDesignerInfo = {key=key, id=spec.id, dynamic=spec.dynamic}
    
    
    if spec.id=="dispel" then
        object.mmfDesignerWantsShown=SafeGet(object,"IsShown",false)
    end
    object.mmfDesignerAutomaticColors={}
    if object.mmfSolidColor then object.mmfDesignerAutomaticColors.SetColorTexture=D.Copy(object.mmfSolidColor) end
    for _,pair in ipairs({{"SetTextColor","GetTextColor"},{"SetStatusBarColor","GetStatusBarColor"},{"SetVertexColor","GetVertexColor"}}) do
        
        
        if object[pair[2]] and not (pair[1]=="SetVertexColor" and object.SetTextColor) then
            local ok,r,g,b,a=pcall(object[pair[2]],object)
            if ok and D.Readable(r) and D.Readable(g) and D.Readable(b) then object.mmfDesignerAutomaticColors[pair[1]]={r,g,b,a or 1} end
        end
    end
    for _, method in ipairs(layoutMethods) do
        if type(object[method])=="function" then
            local original, name = object[method], method
            raw[name]=original
            object[name]=function(self, ...)
                if D.capturing then return original(self, ...) end
                local cfg=Config(self)
                if not cfg then return original(self, ...) end
                if spec.dynamic and cfg.followHealth then
                    
                    
                    if name=="SetPoint" then
                        local point, relative, relativePoint, x, y = ...
                        if type(relative)=="table" or type(relative)=="userdata" then
                            return original(self, point, relative, relativePoint, (x or 0)+(cfg.x or 0), (y or 0)+(cfg.y or 0))
                        end
                    end
                    if name~="SetFont" and name~="SetDrawLayer" and name~="SetFrameLevel" then
                        return original(self, ...)
                    end
                end
                
            end
        end
    end
    for _, method in ipairs({"Show", "Hide", "SetShown", "SetAlpha", "SetTextColor", "SetStatusBarColor", "SetColorTexture", "SetVertexColor", "SetStatusBarTexture"}) do
        if type(object[method])=="function" then raw[method]=object[method] end
    end
    if raw.Show then
        object.Show=function(self)
            self.mmfDesignerWantsShown=true
            local cfg=Config(self)
            if cfg and cfg.enabled==false then return raw.Hide(self) end
            return raw.Show(self)
        end
        object.Hide=function(self)
            self.mmfDesignerWantsShown=false
            return raw.Hide(self)
        end
    end
    if raw.SetShown then
        object.SetShown=function(self, shown)
            local cfg=Config(self)
            if D.Readable(shown) then self.mmfDesignerWantsShown=shown end
            if cfg and cfg.enabled==false then return raw.Hide(self) end
            return raw.SetShown(self, shown)
        end
    end
    if raw.SetAlpha then
        object.SetAlpha=function(self, alpha)
            local cfg=Config(self)
            if cfg and D.Readable(alpha) and type(alpha)=="number" and alpha~=0 then
                return raw.SetAlpha(self, cfg.opacity or 1)
            end
            return raw.SetAlpha(self, alpha)
        end
    end
    for _, method in ipairs({"SetTextColor", "SetStatusBarColor", "SetColorTexture", "SetVertexColor"}) do
        if raw[method] then
            local original=raw[method]
            object[method]=function(self, ...)
                local r,g,b,a=...
                local colorMethod=self.SetTextColor and (method=="SetTextColor" or method=="SetVertexColor") and "SetTextColor" or method
                if self.SetTextColor then self.mmfDesignerAutomaticColors.SetVertexColor=nil end
                if D.Readable(r) and D.Readable(g) and D.Readable(b) and D.Readable(a) then
                    self.mmfDesignerAutomaticColors[colorMethod]={r,g,b,a or 1}
                else
                    
                    self.mmfDesignerAutomaticColors[colorMethod]=nil
                end
                local cfg=Config(self)
                if cfg and cfg.colorMode=="custom" and type(cfg.color)=="table" then return original(self, unpack(cfg.color)) end
                return original(self, ...)
            end
        end
    end
    if raw.SetStatusBarTexture then
        object.SetStatusBarTexture=function(self, texture)
            local cfg=Config(self)
            if not (MMF_ShouldOverrideBarTextures and MMF_ShouldOverrideBarTextures())
                and cfg and cfg.texture and cfg.texture~="" then
                return raw.SetStatusBarTexture(self,cfg.texture)
            end
            return raw.SetStatusBarTexture(self,texture)
        end
    end
end
D.Own = Own

local function CenterIn(object, relative, fallbackX, fallbackY)
    if not object or not object.GetCenter or not relative.GetCenter then return fallbackX or 0, fallbackY or 0 end
    local ok, x, y=pcall(object.GetCenter,object)
    local rok, rx, ry=pcall(relative.GetCenter,relative)
    if not ok or not rok or not D.Readable(x) or not D.Readable(y) or not D.Readable(rx) or not D.Readable(ry)
        or type(x)~="number" or type(y)~="number" or type(rx)~="number" or type(ry)~="number" then
        return fallbackX or 0, fallbackY or 0
    end
    local s=SafeGet(object,"GetEffectiveScale",1)
    local rs=SafeGet(relative,"GetEffectiveScale",1)
    return (x*s-rx*rs)/rs, (y*s-ry*rs)/rs
end
D.CenterIn = CenterIn
local function CaptureNode(frame, nodes, spec, cfg)
    local object=nodes[spec.id]
    if not object then return end
    local relative=nodes[cfg.relativeTo] or frame
    if not spec.dynamic then
        cfg.x,cfg.y=CenterIn(object,relative,cfg.x,cfg.y)
        local ratio=SafeGet(object,"GetEffectiveScale",1)/SafeGet(relative,"GetEffectiveScale",1)
        cfg.x,cfg.y=cfg.x/ratio,cfg.y/ratio
    end
    local width=SafeGet(object,"GetWidth",cfg.width)
    local height=SafeGet(object,"GetHeight",cfg.height)
    cfg.width=D.Number(width>0 and width or cfg.width,cfg.width,1,2000)
    cfg.height=D.Number(height>0 and height or cfg.height,cfg.height,1,2000)
    if spec.kind=="text" then
        
        
        if width<=1.01 then cfg.width=math.min(spec.defaults.width or 20,frame:GetWidth()) end
        cfg.height=math.max(cfg.height,spec.defaults.height or 12)
    end
    cfg.opacity=D.Number(SafeGet(object,"GetAlpha",1),1,0,1)
    cfg.scale=D.Number(SafeGet(object,"GetScale",1),1,0.1,5)
    if object.GetFont then
        local ok,path,size,flags=pcall(object.GetFont,object)
        if ok then
            
            
            cfg.font=(MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or spec.defaults.font or path
            cfg.fontSize=D.Number(size,12,6,96);cfg.fontFlags=flags or ""
        end
        cfg.justify=SafeGet(object,"GetJustifyH","CENTER")
        cfg.justifyV=SafeGet(object,"GetJustifyV","MIDDLE")
    end
    if object.GetDrawLayer then
        local ok,layer,sub=pcall(object.GetDrawLayer,object)
        if ok then cfg.drawLayer=layer; cfg.layer=D.Number(sub,0,-8,7) end
    elseif object.GetFrameLevel then
        cfg.layer=D.Number(SafeGet(object,"GetFrameLevel",1)-SafeGet(frame,"GetFrameLevel",1),2,0,100)
    end
    if object.GetStatusBarTexture then
        
        
        if spec.kind=="bar" and (type(cfg.texture)~="string" or cfg.texture=="") then
            cfg.texture=(MMF_Config and MMF_Config.TEXTURE_PATH)
                or "Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga"
        end
        cfg.orientation=SafeGet(object,"GetOrientation","HORIZONTAL")
        cfg.reverseFill=SafeGet(object,"GetReverseFill",false)
    end
    if object.GetTextColor then
        local ok,r,g,b,a=pcall(object.GetTextColor,object)
        if ok and D.Readable(r) and D.Readable(g) and D.Readable(b) then cfg.color={r,g,b,a or 1} end
    elseif object.GetStatusBarColor then
        local ok,r,g,b,a=pcall(object.GetStatusBarColor,object)
        if ok and D.Readable(r) and D.Readable(g) and D.Readable(b) then cfg.color={r,g,b,a or 1} end
    elseif object.GetVertexColor then
        local ok,r,g,b,a=pcall(object.GetVertexColor,object)
        if ok and D.Readable(r) and D.Readable(g) and D.Readable(b) then cfg.color={r,g,b,a or 1} end
    end
end
local function LegacyVisibility(key, spec, cfg)
    local db=MattMinimalFramesDB or {}
    local unitTitle=key:sub(1,1):upper()..key:sub(2)
    if spec.id=="name" and MMF_IsNameTextHidden then cfg.enabled=not MMF_IsNameTextHidden(key)
    elseif spec.id=="healthText" and MMF_IsHPTextHidden then cfg.enabled=not MMF_IsHPTextHidden(key)
    elseif spec.id=="power" then cfg.enabled=(key=="player" or key=="target") and db["show"..unitTitle.."PowerBar"]~=false
    elseif spec.id=="powerText" then cfg.enabled=db["show"..unitTitle.."PowerText"]==true
    elseif spec.id=="cast" then
        cfg.enabled=(key=="player" or key=="target" or key=="focus" or key=="boss") and db["show"..unitTitle.."CastBar"]~=false
    elseif spec.id=="buffs" or spec.id=="debuffs" then
        local title=spec.id=="buffs" and "Buffs" or "Debuffs"
        local setting=key=="target" and ("show"..title) or ("show"..unitTitle..title)
        cfg.enabled=(key=="player" or key=="target" or key=="focus" or (key=="boss" and spec.id=="debuffs")) and db[setting]~=false
    elseif spec.id=="combat" then cfg.enabled=db.hideCombatIcon~=true
    elseif spec.id=="resting" then cfg.enabled=db.hideRestingIcon~=true
    elseif spec.id=="raidMarker" then cfg.enabled=db.showTargetMarkers==true
    elseif spec.id=="classification" and key=="target" then cfg.enabled=db.showTargetClassification~=false
    elseif spec.id=="leader" then cfg.enabled=db.showLeaderIcons==true
    elseif spec.id=="pvp" and (key=="player" or key=="target") then
        local compat=_G.MMF_Compat or {}
        cfg.enabled=compat.IsTBC and db.showTBCPVPFlagIndicator~=false or (not compat.IsTBC and db.showPVPFlagIndicator==true)
    elseif spec.id=="myHeal" or spec.id=="otherHeal" then cfg.enabled=db.showHealPrediction~=false
    elseif spec.id=="absorb" then cfg.enabled=db.showAbsorbBar~=false
    elseif spec.id=="healAbsorb" then cfg.enabled=db.showHealAbsorbBar~=false
    elseif spec.id=="dispel" and key=="player" then cfg.enabled=db.showPlayerDispelHighlight==true
    elseif spec.id=="dispel" and key=="target" then cfg.enabled=db.showTargetDispelHighlight==true
    elseif spec.id:match("^combatOutline%.") and key=="player" then cfg.enabled=db.combatFrameOutline==true
    elseif spec.id=="debuffs" and key=="target" and db.onlyShowPlayerDebuffsOnTarget==true then cfg.filter="mine"
    elseif spec.id=="portrait" and (key=="player" or key=="target") then
        cfg.iconMode=db[key.."FrameIconMode"] or "off"; cfg.enabled=cfg.iconMode~="off"
        if cfg.iconMode=="off" then cfg.iconMode="class" end
    end
end
D.CaptureVisualLayout=CaptureNode
D.ApplyLegacyVisibility=LegacyVisibility

function D.InitializeOptionalLayout(key,unit)
    if D.byUnitType[key].optional then
        unit.width,unit.height,unit.scale=100,28,1
        local function Set(id,width,height,x,y,enabled,parent)
            local e=D.ElementDesign(key,id)
            if not e then return end
            e.width,e.height,e.x,e.y=width,height,x or 0,y or 0
            e.point,e.relativePoint,e.relativeTo="CENTER","CENTER",parent or "frame"
            if enabled~=nil then e.enabled=enabled end
        end
        Set("health",98,26,0,0,true)
        Set("healthBackground",98,26,0,0,true,"health")
        Set("healthBorder",100,28,0,0,true,"health")
        for _,edge in ipairs({"top","right","bottom","left"}) do
            local side=edge=="left" or edge=="right"
            Set("healthBorder."..edge,side and 1 or 100,side and 26 or 1,
                edge=="left" and -49.5 or edge=="right" and 49.5 or 0,
                edge=="top" and 13.5 or edge=="bottom" and -13.5 or 0,true,"healthBorder")
        end
        Set("name",100,14,0,22,true); D.ElementDesign(key,"name").fontSize=11
        Set("healthText",94,14,0,0,true); D.ElementDesign(key,"healthText").fontSize=10
        Set("power",100,5,0,-18,true)
        Set("powerFill",98,3,0,0,true,"power")
        Set("powerBackground",98,3,0,0,true,"power")
        Set("powerBorder",100,5,0,0,true,"power")
        Set("powerText",90,12,0,0,false,"power")
        local casts=key=="party" or key=="arena" or key=="focustarget" or key=="pettarget"
        Set("cast",100,8,0,-32,casts)
        Set("castFill",100,8,0,0,true,"cast")
        Set("castBackground",100,8,0,0,true,"cast")
        Set("castBorder",102,10,0,0,true,"cast")
        Set("castName",72,14,-12,0,true,"cast");D.ElementDesign(key,"castName").fontSize=9
        Set("castTime",24,14,37,0,true,"cast");D.ElementDesign(key,"castTime").fontSize=9
        Set("castIcon",14,14,-60,0,false,"cast")
        Set("castShield",14,14,60,0,false,"cast")
        Set("hover",100,28,0,0,true,"health")
        Set("dispel",98,26,0,0,true,"health")
        for _,id in ipairs({"buffs","debuffs"}) do
            Set(id,62,14,0,id=="debuffs" and 42 or 58,id=="debuffs" and (key=="party" or key=="raid"))
            local e=D.ElementDesign(key,id)
            e.iconSize,e.columns,e.rows,e.maxIcons,e.spacing=14,4,1,4,2
        end
    end
end

function D.Attach(frame)
    if not frame or InCombatLockdown() then return end
    local key=D.Key(frame.unit)
    if not key then return end
    if D.EnsureComponents then D.EnsureComponents(frame) end
    MMF_Visuals.ApplyStyle(frame)
    local unit=D.UnitDesign(key)
    local first=not unit.migrated
    local nodes=D.frames[frame] or {}
    D.frames[frame]=nodes; frame.mmfDesignerNodes=nodes; frame.mmfDesignerKey=key
    for _, spec in ipairs(D.Catalog(key,frame)) do
        local object=D.Resolve(frame,spec.field)
        if object then nodes[spec.id]=object end
    end
    if first then
        unit.width=D.Number(frame:GetWidth(),unit.width,20,1000)
        unit.height=D.Number(frame:GetHeight(),unit.height,4,400)
        unit.scale=D.Number(frame:GetScale(),1,0.25,3)
        if unit.showHealthValue==nil and MMF_GetShowHPValueText then unit.showHealthValue=MMF_GetShowHPValueText(frame.unit) end
        if unit.showHealthPercent==nil and MMF_GetShowHPPercentText then unit.showHealthPercent=MMF_GetShowHPPercentText(frame.unit) end
    end
    for _, spec in ipairs(D.Catalog(key,frame)) do
        local object=nodes[spec.id]
        local new=not unit.elements[spec.id]
        local cfg=D.ElementDesign(key,spec.id)
        if first then
            if object then CaptureNode(frame,nodes,spec,cfg) end
            LegacyVisibility(key,spec,cfg)
        elseif new and spec.id:match("^resource") and object then
            
            
            CaptureNode(frame,nodes,spec,cfg)
        end
        if spec.id=="resources" and not unit.resourcesBelowCastV1 then
            local baseline=unit.baseline and unit.baseline.elements and unit.baseline.elements.resources
            local unchanged=baseline~=nil
            for _,field in ipairs({"point","relativePoint","relativeTo","x","y"}) do
                if not baseline or cfg[field]~=baseline[field] then unchanged=false end
            end
            if first or new or unchanged then
                for _,field in ipairs({"point","relativePoint","relativeTo","x","y"}) do
                    cfg[field]=spec.defaults[field]
                    if baseline then baseline[field]=spec.defaults[field] end
                end
            end
            unit.resourcesBelowCastV1=true
        end
        if object then
            Own(object,key,spec)
            if not spec.dynamic and spec.kind~="auras" then
                D.ClearLegacyDragScripts(object)
            end
        end
    end
    if first then D.InitializeOptionalLayout(key,unit) end
    D.RebuildResourceLayout(key)
    if not unit.auraCornersV1 then
        for _,id in ipairs({"buffs","debuffs"}) do
            local cfg=D.ElementDesign(key,id)
            local baseline=unit.baseline and unit.baseline.elements and unit.baseline.elements[id]
            local unchanged=baseline~=nil
            for _,field in ipairs({"point","relativePoint","relativeTo","x","y","growth"}) do
                if not baseline or cfg[field]~=baseline[field] then unchanged=false end
            end
            local defaults=D.catalogByID[id].defaults
            for _,field in ipairs({"point","relativePoint","relativeTo","x","y","growth"}) do
                if first or unchanged then cfg[field]=defaults[field] end
                if baseline then baseline[field]=defaults[field] end
            end
        end
        unit.auraCornersV1=true
    end
    if not unit.valueTextInsideV1 then
        for _,id in ipairs({"healthText","powerText"}) do
            local cfg=D.ElementDesign(key,id)
            local baseline=unit.baseline and unit.baseline.elements and unit.baseline.elements[id]
            local unchanged=baseline~=nil
            for _,field in ipairs({"point","relativePoint","x","y"}) do
                if not baseline or cfg[field]~=baseline[field] then unchanged=false end
            end
            if first or unchanged then D.PlaceValueTextInside(cfg,id) end
            if baseline then D.PlaceValueTextInside(baseline,id) end
        end
        unit.valueTextInsideV1=true
    end
    if not unit.castPartAnchorsV1 then
        local cast=D.ElementDesign(key,"cast")
        for _,id in ipairs({"castName","castTime","castIcon","castShield"}) do
            local cfg=D.ElementDesign(key,id)
            D.PlaceCastPart(cfg,id,cast.width)
            local baseline=unit.baseline and unit.baseline.elements
            if baseline and baseline[id] then D.PlaceCastPart(baseline[id],id,baseline.cast and baseline.cast.width or cast.width) end
        end
        unit.castPartAnchorsV1=true
    end
    if key=="boss" and not unit.bossAuraSideV1 then
        for _,id in ipairs({"buffs","debuffs"}) do
            D.PlaceBossAuras(D.ElementDesign(key,id),id)
            local baseline=unit.baseline and unit.baseline.elements
            if baseline and baseline[id] then D.PlaceBossAuras(baseline[id],id) end
        end
        unit.bossAuraSideV1=true
    end
    if key=="boss" then D.ApplyBossElementDefaults(unit) end
    
    for _, field in ipairs({"nameTextDragFrame","hpTextDragFrame","powerTextDragFrame","castBarTextDragFrame","castBarTimeDragFrame"}) do
        local object=frame[field]
        if object then object:EnableMouse(false); D.ClearLegacyDragScripts(object) end
    end
    if frame.powerBarFrame then frame.powerBarFrame:EnableMouse(false) end
    if frame.castBarFrame then frame.castBarFrame:EnableMouse(false) end
    local profile=D.Profile()
    profile.positions=profile.positions or {}
    if not profile.positions[frame.unit] then
        local x,y=CenterIn(frame,UIParent,0,0)
        profile.positions[frame.unit]={x=x,y=y}
    end
    OwnRoot(frame)
    unit.migrated=true
    if not unit.baseline then
        unit.baseline={width=unit.width,height=unit.height,scale=unit.scale,elements=D.Copy(unit.elements)}
    end
    return nodes
end

function D.TextReference(id,cfg)
    local parent=cfg.relativeTo or "frame"
    if parent=="frame" and cfg.followFrameSize~=false then
        local attached={name="health",healthText="health",castName="cast",castTime="cast",powerText="power",resourceText="resources"}
        return attached[id] or parent
    end
    return parent
end
function D.TextLayout(key,id,cfg)
    local spec=D.catalogByID[id]
    if not spec or spec.kind~="text" or cfg.followFrameSize==false then return cfg end
    local parent=D.TextReference(id,cfg)
    local reference=parent=="frame" and D.UnitDesign(key) or D.ElementDesign(key,parent)
    if not reference then return cfg end
    local width,height=math.max(1,reference.width),math.max(1,reference.height)
    local base=cfg.textSizeReference
    if base and base.parent=="frame" and parent~="frame" and (cfg.relativeTo or "frame")=="frame" then
        
        
        base.parent=parent
    end
    if not base or base.parent~=parent then
        base={parent=parent,width=width,height=height}
        cfg.textSizeReference=base
    end
    local sx,sy=width/math.max(1,base.width),height/math.max(1,base.height)
    local layout=D.Copy(cfg)
    layout.relativeTo=parent
    layout.width=cfg.width*sx;layout.height=cfg.height*sy
    layout.x=(cfg.x or 0)*sx;layout.y=(cfg.y or 0)*sy
    return layout
end
function D.BakeTextLayout(key,id)
    local cfg=D.ElementDesign(key,id)
    if not cfg then return end
    local layout=D.TextLayout(key,id,cfg)
    if layout==cfg then return end
    for _,field in ipairs({"width","height","x","y","relativeTo"}) do cfg[field]=layout[field] end
    local parent=cfg.relativeTo or "frame"
    local reference=parent=="frame" and D.UnitDesign(key) or D.ElementDesign(key,parent)
    if reference then cfg.textSizeReference={parent=parent,width=reference.width,height=reference.height} end
end
function D.ApplyNode(frame, id, object, cfg)
    if not object or not cfg then return end
    cfg=D.TextLayout(frame.mmfDesignerKey or D.Key(frame.unit),id,cfg)
    local spec=D.catalogByID[id]
    local nodes=frame.mmfDesignerNodes or {}
    local relative=nodes[cfg.relativeTo] or frame
    if spec.dynamic and object.SetParent then
        local parent=cfg.followHealth and frame.healPredictionClip or frame
        if parent and object:GetParent()~=parent then object:SetParent(parent) end
    end
    if not (spec.dynamic and cfg.followHealth) then
        Call(object,"ClearAllPoints")
        Call(object,"SetScale",cfg.scale or 1)
        if object.SetFont and cfg.fitTextToContent then
            
            
            Call(object,"SetSize",0,0)
        else
            Call(object,"SetSize",cfg.width,cfg.height)
        end
        Call(object,"SetPoint",cfg.point or "CENTER",relative,cfg.relativePoint or "CENTER",cfg.x or 0,cfg.y or 0)
    end
    Call(object,"SetAlpha",cfg.opacity or 1)
    if object.SetFrameLevel then
        local parent = object:GetParent()
        local parentLevel = (parent and parent:GetFrameLevel()) or 0
        
        
        
        
        Call(object,"SetFrameLevel",math.max(parentLevel + (parent and 1 or 0),frame:GetFrameLevel()+(cfg.layer or 2)))
    elseif object.SetDrawLayer then
        Call(object,"SetDrawLayer",cfg.drawLayer or (object.SetFont and "OVERLAY" or "ARTWORK"),math.max(-8,math.min(7,cfg.layer or 0)))
    end
    if object.SetFont then
        local path=cfg.font or (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or STANDARD_TEXT_FONT or MMF_GetDefaultFontPath()
        D.ApplyFont(object,path,cfg.fontSize or 12,cfg.fontFlags or "")
        Call(object,"SetJustifyH",cfg.justify or "CENTER")
        Call(object,"SetJustifyV",cfg.justifyV or "MIDDLE")
    end
    if object.SetStatusBarTexture and cfg.texture
        and not (MMF_ShouldOverrideBarTextures and MMF_ShouldOverrideBarTextures()) then
        Call(object,"SetStatusBarTexture",cfg.texture)
    end
    if object.SetOrientation and cfg.orientation then Call(object,"SetOrientation",cfg.orientation) end
    if object.SetReverseFill and cfg.reverseFill~=nil then Call(object,"SetReverseFill",cfg.reverseFill) end
    if cfg.colorMode=="custom" and cfg.color then
        local method=object.SetTextColor and "SetTextColor" or object.SetStatusBarColor and "SetStatusBarColor" or object.mmfDesignerSolid and "SetColorTexture" or "SetVertexColor"
        Call(object,method,unpack(cfg.color))
    elseif object.mmfDesignerAutomaticColors then
        for method,color in pairs(object.mmfDesignerAutomaticColors) do Call(object,method,unpack(color)) end
    end
    if cfg.enabled==false then Call(object,"Hide")
    elseif object.mmfDesignerWantsShown~=false then Call(object,"Show") end
end
function D.ApplyFrame(frame)
    if InCombatLockdown() then D.pending=true; return end
    local key=frame.mmfDesignerKey or D.Key(frame.unit)
    if not key then return end
    local nodes=D.Attach(frame)
    if not nodes then return end
    local unit=D.UnitDesign(key)
    MMF_Visuals.ApplyStyle(frame)
    MMF_Visuals.ApplyLayout(frame,key)
    if MMF_UpdateDispelHighlight then MMF_UpdateDispelHighlight(frame) end
    if D.ApplyAuras then D.ApplyAuras(frame) end
    if D.UpdateExtras then D.UpdateExtras(frame) end
    if D.RefreshMover then D.RefreshMover(frame) end
    if MMF_RequestFrameUpdate then MMF_RequestFrameUpdate(frame) end
    if key=="player" and MMF_RefreshClassResourceVisibility then MMF_RefreshClassResourceVisibility() end
end
function D.ApplyUnit(key)
    if InCombatLockdown() then D.pending=true; return false end
    if D.EnsureUnitFrames then D.EnsureUnitFrames(key) end
    for frame in pairs(D.frames) do if frame.mmfDesignerKey==key then D.ApplyFrame(frame) end end
    if D.UpdateVisibility then D.UpdateVisibility(key) end
    return true
end
function D.ApplyAll()
    if InCombatLockdown() then D.pending=true; return end
    if D.EnsureUnitFrames then D.EnsureUnitFrames() end
    for _, frame in ipairs(MMF_GetAllFrames and MMF_GetAllFrames() or {}) do D.ApplyFrame(frame) end
    if D.UpdateVisibility then D.UpdateVisibility() end
    D.pending=false
end
function D.ResetElement(key,id)
    D.PushHistory(key)
    local unit=D.UnitDesign(key)
    local baseline=unit.baseline and unit.baseline.elements and unit.baseline.elements[id]
    unit.elements[id]=D.Copy(baseline or D.catalogByID[id].defaults)
    D.ApplyUnit(key)
end
function D.ResetDesign(key)
    D.PushHistory(key)
    local unit=D.UnitDesign(key)
    if unit.baseline then
        unit.elements=D.Copy(unit.baseline.elements)
        unit.width,unit.height,unit.scale=unit.baseline.width,unit.baseline.height,unit.baseline.scale
    else unit.elements={} end
    D.ApplyUnit(key)
end
