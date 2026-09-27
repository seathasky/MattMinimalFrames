

local addonName = ...
local D = MMF_Designer
local Compat = MMF_Compat or {}
D.errors = {}
local function Report(context, err)
    local message = tostring(context)..": "..tostring(err)
    if D.errors[message] then return end
    D.errors[message] = true
    D.Notify(message)
end
D.Report = Report
local function ProtectedCall(context, fn, ...)
    if type(fn)~="function" then return end
    local ok, result = pcall(fn, ...)
    if not ok then Report(context, result) end
    return ok, result
end
D.Try = ProtectedCall

function D.SetLiveDragUnlocked(unlocked)
    if InCombatLockdown() then D.Notify("Leave combat before locking or unlocking frames.");return false end
    D.Profile().liveDragUnlocked=unlocked==true
    D.liveMoveHandlesWanted=false
    if D.RefreshDragLock then D.RefreshDragLock() end
    for frame in pairs(D.frames or {}) do
        if frame.mmfDesignerMover then frame.mmfDesignerMover.drag=nil end
        if not ProtectedCall("Initialize frame movers",D.RefreshMover,frame) then return false end
    end
    return true
end
local function IsTrue(fn, unit)
    if type(fn)~="function" then return false end
    local ok, value = pcall(fn, unit)
    return ok and D.Readable(value) and value == true
end
local function Public(fn, ...)
    if type(fn)~="function" then return nil end
    local ok, result = pcall(fn, ...)
    if ok and D.Readable(result) then return result end
end
D.Public = Public



local definitions = MMF_Config.FRAME_DEFINITIONS
local existing = {}
for _, def in ipairs(definitions) do existing[def.unit] = true end
for _, entry in ipairs(D.unitTypes) do
    if D.Supports(entry.key) then
        for index=1, entry.count or 1 do
            local token = entry.count and (entry.key..index) or entry.token
            if not existing[token] then
                local column=(index-1)%5
                local row=math.floor((index-1)/5)
                local grouped=entry.key=="raid" or entry.key=="raidpet"
                local x=grouped and (-250+column*110) or -480
                local y=grouped and (230-row*45) or (160-(index-1)*62)
                if entry.key=="focustarget" then x,y=340,-155
                elseif entry.key=="pettarget" then x,y=-340,-155
                elseif entry.key=="vehicle" then x,y=-150,-160
                elseif entry.key=="arena" then x,y=520,150-(index-1)*62
                elseif entry.key=="partypet" then x=x+120 end
                definitions[#definitions+1]={unit=token,name="MMF_Designer_"..token,
                    width=100,height=28,x=x,y=y,label=entry.label..(entry.count and (" "..index) or ""),designerOptional=true}
                existing[token]=true
            end
        end
    end
end

local CreateText=MMF_ExtraVisuals.Text
local resourceNames={"MMF_RuneBar","MMF_HolyPowerBar","MMF_ComboPointBar","MMF_SoulShardBar","MMF_ChiBar","MMF_ArcaneChargeBar","MMF_EssenceBar","MMF_MaelstromBar"}
function D.EnsureComponents(frame)
    if InCombatLockdown() then D.pending=true; return end
    local key=D.Key(frame.unit)
    if not key then return end
    MMF_ExtraVisuals.Ensure(frame)
    if key=="pet" and frame.petHappinessIcon then
        if frame.designerHappiness~=frame.petHappinessIcon then
            if frame.designerHappiness then frame.designerHappiness:Hide() end
            frame.designerHappiness=frame.petHappinessIcon
        end
        if frame.petHappinessDragFrame then
            frame.petHappinessDragFrame:EnableMouse(false)
            D.ClearLegacyDragScripts(frame.petHappinessDragFrame)
        end
    end
    for _,field in ipairs({"healthBarBG","powerBarBG","powerBarBorder","castBarBG","castBarBorder","secondaryPowerBarBG","petHappinessBorder"}) do
        if frame[field] then frame[field].mmfDesignerSolid=true end
    end
    for _,edges in ipairs({frame.healthBarBorderEdges or {},frame.combatFrameOutlineEdges or {}}) do for _,edge in pairs(edges) do edge.mmfDesignerSolid=true end end
    if MMF_CreateAuraContainer then
        if not frame.BuffContainer then frame.BuffContainer=MMF_CreateAuraContainer(frame,false,frame.unit) end
        if not frame.DebuffContainer then frame.DebuffContainer=MMF_CreateAuraContainer(frame,true,frame.unit) end
    end
    for _,field in ipairs({"BuffPreviewContainer","DebuffPreviewContainer"}) do
        if frame[field] then frame[field]:Hide();frame[field]:EnableMouse(false) end
    end
    if key=="player" then
        if MMF_EnsureDesignerClassResource then MMF_EnsureDesignerClassResource() end
        for _, name in ipairs(resourceNames) do
            local bar=_G[name]
            if bar then
                if not frame.designerResources then frame.designerResources=bar end
                if bar:GetParent()~=frame then
                    local x,y=D.CenterIn(bar,frame,0,-60)
                    bar:SetParent(frame);bar:ClearAllPoints();bar:SetPoint("CENTER",frame,"CENTER",x,y)
                end
                bar:EnableMouse(false);D.ClearLegacyDragScripts(bar)
                if bar.moveHint then bar.moveHint:Hide() end
                if bar.moveSubtext then bar.moveSubtext:Hide() end
            end
        end
    end
end

function D.EnsureUnitFrames(key, includeDisabled)
    if InCombatLockdown() then D.pending=true; return end
    local sample=D.byUnitType[key or ""]
    local created=false
    for _, def in ipairs(definitions) do
        local family=D.Key(def.unit)
        local wanted=(not key or family==key) and D.Supports(family)
            and (D.IsUnitEnabled(def.unit) or (includeDisabled and sample and def.unit==sample.token))
        if wanted and not _G[def.name] then
            local frame=MMF_CreateSecureUnitFrame(def.unit,def.name,def.width,def.height,"CENTER","CENTER",def.x,def.y)
            _G[def.name]=frame
            created=true
            RegisterUnitWatch(frame)
            frame:HookScript("OnShow",function(self)
                if MMF_RequestFrameUpdate then MMF_RequestFrameUpdate(self) end
                if D.ready then D.UpdateExtras(self) end
            end)
            if D.ready then D.Attach(frame) end
        end
    end
    if created and MMF_RegisterFramesWithClique then MMF_RegisterFramesWithClique() end
end
function D.Representative(key)
    
    return D.GetPreviewFrame and D.GetPreviewFrame(key)
end

local function Display(object, show)
    if object then object:SetShown(show==true) end
end
function D.UpdateExtras(frame)
    if not D.ready or not frame or not frame.mmfDesignerKey then return end
    local unit,key=frame.unit,frame.mmfDesignerKey
    if frame.shamanTotemTimers and not frame.mmfPreview then MMF_TotemTimers.Update(frame) end
    local exists=IsTrue(UnitExists,unit)
    if not exists then
        for _,field in ipairs({"designerLevel","designerClassification","designerStatus","designerLeader","designerRole","designerReady","designerResurrection","designerPortrait","designerHappiness"}) do
            Display(frame[field],false)
        end
        return
    end
    local function Enabled(id) return D.IsEnabled(key,id) end
    if frame.designerLevel then
        local level=Public(UnitLevel,unit)
        frame.designerLevel:SetText(type(level)=="number" and (level<0 and "??" or tostring(level)) or "")
        Display(frame.designerLevel,Enabled("level") and level~=nil)
    end
    if frame.designerClassification then
        local classification=Public(UnitClassification,unit)
        local labels={elite="Elite",rare="Rare",rareelite="Rare Elite",worldboss="Boss"}
        local label=classification and labels[classification]
        frame.designerClassification:SetText(label or "")
        Display(frame.designerClassification,Enabled("classification") and label~=nil)
    end
    if frame.designerStatus then
        local connected=Public(UnitIsConnected,unit)
        local text=connected==false and "OFFLINE" or IsTrue(UnitIsGhost,unit) and "GHOST" or IsTrue(UnitIsDead,unit) and "DEAD" or ""
        frame.designerStatus:SetText(text)
        Display(frame.designerStatus,Enabled("status") and text~="")
    end
    if frame.designerPortrait then
        local cfg=D.ElementDesign(key,"portrait")
        local nativeIcons=MMF_FrameFactoryIcons
        local nativeRenderer=key=="player" and nativeIcons and nativeIcons.ApplyPlayerFrameIconMode or key=="target" and nativeIcons and nativeIcons.ApplyTargetFrameIconMode
        if nativeRenderer then
            nativeRenderer(frame,Enabled("portrait") and (cfg.iconMode or "class") or "off")
        elseif Enabled("portrait") then
            if cfg.iconMode=="portrait" and SetPortraitTexture then
                SetPortraitTexture(frame.designerPortrait,unit)
                frame.designerPortrait:SetTexCoord(0,1,0,1)
            else
                local _,class=UnitClass(unit)
                local coords=D.Readable(class) and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
                if coords then
                    frame.designerPortrait:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                    frame.designerPortrait:SetTexCoord(unpack(coords))
                elseif SetPortraitTexture then
                    SetPortraitTexture(frame.designerPortrait,unit);frame.designerPortrait:SetTexCoord(0,1,0,1)
                end
            end
        end
        if not nativeRenderer then Display(frame.designerPortrait,Enabled("portrait")) end
    end
    if frame.designerLeader then
        local leader=IsTrue(UnitIsGroupLeader,unit)
        local assistant=IsTrue(UnitIsGroupAssistant,unit)
        MMF_ExtraVisuals.Leader(frame.designerLeader,leader and "leader" or "assistant")
        local legacyPlayerToggle=key=="player" and MattMinimalFramesDB
            and MattMinimalFramesDB.showLeaderIcons==true
        local rosterUnit=key=="player" or key=="party" or key=="raid"
        Display(frame.designerLeader,rosterUnit and (Enabled("leader") or legacyPlayerToggle) and (leader or assistant))
    end
    if frame.designerRole then
        local role=Public(UnitGroupRolesAssigned,unit)
        local coords={TANK={0,0.25,0,1},HEALER={0.25,0.5,0,1},DAMAGER={0.5,0.75,0,1}}
        local texcoords=role and coords[role]
        if texcoords then MMF_ExtraVisuals.Role(frame.designerRole,role) end
        Display(frame.designerRole,Enabled("role") and texcoords~=nil)
    end
    if frame.designerReady then
        local ready=Public(GetReadyCheckStatus,unit)
        local textures={ready="ReadyCheck-Ready",notready="ReadyCheck-NotReady",waiting="ReadyCheck-Waiting"}
        local texture=ready and textures[ready]
        if texture then MMF_ExtraVisuals.Ready(frame.designerReady,ready) end
        Display(frame.designerReady,Enabled("ready") and texture~=nil)
    end
    if frame.designerResurrection then
        MMF_ExtraVisuals.Resurrection(frame.designerResurrection)
        Display(frame.designerResurrection,Enabled("resurrection") and IsTrue(UnitHasIncomingResurrection,unit))
    end
    if frame.targetMarker then
        local index=Public(GetRaidTargetIndex,unit)
        local show=Enabled("raidMarker") and type(index)=="number" and index>=1 and index<=8
        if show then MMF_ExtraVisuals.RaidMarker(frame.targetMarker,index) end
        Display(frame.targetMarker,show)
    end
    if frame.pvpFlagText then
        frame.pvpFlagText:SetText("PvP")
        Display(frame.pvpFlagText,Enabled("pvp") and IsTrue(UnitIsPVP,unit))
    end
    if frame.designerHappiness and Compat.HasPetHappiness then
        local happiness=Public(Compat.GetPetHappiness)
        local show=Enabled("happiness") and type(happiness)=="number" and happiness>=1 and happiness<=3
        if show then
            MMF_ExtraVisuals.Happiness(frame.designerHappiness,happiness)
        end
        Display(frame.designerHappiness,show)
    end
end

local function SavePosition(frame,x,y)
    local profile=D.Profile()
    profile.positions=profile.positions or {}
    profile.positions[frame.unit]={x=x,y=y}
    
    local name=frame:GetName()
    if name then
        local s=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        local cx,cy=UIParent:GetCenter()
        MattMinimalFramesDB[name]={left=cx+x-frame:GetWidth()*s/2,top=cy+y+frame:GetHeight()*s/2}
    end
end
D.SavePosition=SavePosition
local function Place(frame,x,y)
    local ratio=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    D.Root(frame,"ClearAllPoints")
    D.Root(frame,"SetPoint","CENTER",UIParent,"CENTER",x/ratio,y/ratio)
end
D.Place=Place
function D.ApplyPosition(frame)
    local positions=D.Profile().positions
    local saved=positions and positions[frame.unit]
    if saved then Place(frame,D.Number(saved.x,0),D.Number(saved.y,0)) end
end
function D.GroupStep(frame,key)
    local cfg=D.UnitDesign(key)
    local left,right,bottom,top=-cfg.width/2,cfg.width/2,-cfg.height/2,cfg.height/2
    for id,object in pairs(frame.mmfDesignerNodes or {}) do
        local spec=D.catalogByID[id]
        local enabled=true
        local current=id
        local seen={}
        while current and current~="frame" and not seen[current] do
            seen[current]=true
            if D.ElementDesign(key,current).enabled==false then enabled=false;break end
            current=D.catalogByID[current] and D.catalogByID[current].parent
        end
        if enabled and spec and not spec.dynamic and object.GetWidth then
            local x,y=D.CenterIn(object,frame,0,0)
            local ratio=object:GetEffectiveScale()/frame:GetEffectiveScale()
            local hw=D.Number(object:GetWidth(),0)*ratio/2
            local hh=D.Number(object:GetHeight(),0)*ratio/2
            left=math.min(left,x-hw);right=math.max(right,x+hw)
            bottom=math.min(bottom,y-hh);top=math.max(top,y+hh)
        end
    end
    local gap=D.Number(cfg.groupSpacing,10,0,200)
    return right-left+gap,top-bottom+gap
end

function D.ArrangeGroup(key)
    if InCombatLockdown() then return false end
    local entry=D.byUnitType[key]
    if not entry or not entry.count then return false end
    D.EnsureUnitFrames(key)
    local first=MMF_GetFrameForUnit(entry.token)
    if not first then return false end
    local x,y=D.CenterIn(first,UIParent,0,0)
    local cfg=D.UnitDesign(key)
    local columns=math.floor(D.Number(cfg.groupColumns,1,1,entry.count))
    local stepX,stepY=D.GroupStep(first,key)
    for i=1,entry.count do
        local frame=MMF_GetFrameForUnit(key..i)
        if frame then
            local nx=x+((i-1)%columns)*stepX*cfg.scale
            local ny=y-math.floor((i-1)/columns)*stepY*cfg.scale
            Place(frame,nx,ny);SavePosition(frame,nx,ny)
        end
    end
    return true
end

local function MoverFrame(frame)
    if frame.mmfDesignerMover then return frame.mmfDesignerMover end
    local mover=CreateFrame("Frame",nil,frame,"BackdropTemplate")
    mover:SetFrameStrata("DIALOG");mover:SetFrameLevel(frame:GetFrameLevel()+120)
    mover:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    mover:SetBackdropBorderColor(0.33,0.83,0.72,0.9)
    mover:EnableMouse(true);mover:RegisterForDrag("LeftButton")
    local key=frame.mmfDesignerKey
    local entry=D.byUnitType[key]
    local label=entry and entry.label or frame.unit
    mover.label=CreateText(mover,"label",mover,11,label)
    mover.label:SetPoint("BOTTOM",mover,"TOP",0,3)
    mover:Hide()
    mover:SetScript("OnMouseDown",function(self,button)
        if button=="RightButton" and not InCombatLockdown() then
            D.SetMoveMode(false)
            if D.Open then D.Open(frame.mmfDesignerKey) end
        end
    end)
    mover:SetScript("OnDragStart",function(self)
        if InCombatLockdown() or not (D.moveMode or (D.Profile().liveDragUnlocked==true and IsShiftKeyDown())) then return end
        local x,y=GetCursorPosition()
        local ox,oy=D.CenterIn(frame,UIParent,0,0)
        self.drag={x=x,y=y,ox=ox,oy=oy,members={},profile=D.Profile()}
        if key=="boss" then
            for i=1,(entry and entry.count or 5) do
                local member=MMF_GetFrameForUnit("boss"..i)
                if member then
                    local mx,my=D.CenterIn(member,UIParent,0,0)
                    self.drag.members[#self.drag.members+1]={frame=member,x=mx,y=my}
                end
            end
        else
            self.drag.members[1]={frame=frame,x=ox,y=oy}
        end
    end)
    mover:SetScript("OnUpdate",function(self)
        local drag=self.drag
        if not drag or InCombatLockdown() or not (D.moveMode or D.Profile().liveDragUnlocked==true) or D.Profile()~=drag.profile then self.drag=nil;return end
        local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale()
        local step=IsShiftKeyDown() and 1 or D.Profile().snap
        local nx=D.Round(drag.ox+(x-drag.x)/scale,step)
        local ny=D.Round(drag.oy+(y-drag.y)/scale,step)
        for _,member in ipairs(drag.members) do
            local mx,my=member.x+nx-drag.ox,member.y+ny-drag.oy
            Place(member.frame,mx,my);SavePosition(member.frame,mx,my)
        end
        self.label:SetText(label.."  "..nx..", "..ny)
    end)
    mover:SetScript("OnDragStop",function(self) self.drag=nil;self.label:SetText(label);if D.RefreshMoveResetLists then D.RefreshMoveResetLists() end end)
    mover:SetScript("OnHide",function(self) self.drag=nil;self.label:SetText(label) end)
    frame.mmfDesignerMover=mover
    return mover
end
function D.RefreshMover(frame)
    if InCombatLockdown() then return end
    
    if frame.mmfDesignerKey=="boss" and frame.unit~="boss1" then
        if frame.mmfDesignerMover then
            UnregisterStateDriver(frame.mmfDesignerMover,"visibility")
            frame.mmfDesignerMover:Hide();frame.mmfDesignerMover.mmfState=nil
        end
        return
    end
    local mover=MoverFrame(frame)
    local w,h=frame:GetWidth(),frame:GetHeight()
    local left,right,bottom,top=-w/2,w/2,-h/2,h/2
    for id,object in pairs(frame.mmfDesignerNodes or {}) do
        local cfg=D.ElementDesign(frame.mmfDesignerKey,id)
        local spec=D.catalogByID[id]
        if cfg.enabled and not spec.dynamic and object.GetWidth then
            local x,y=D.CenterIn(object,frame,0,0)
            local ratio=object:GetEffectiveScale()/frame:GetEffectiveScale()
            local ow,oh=D.Number(object:GetWidth(),0)*ratio,D.Number(object:GetHeight(),0)*ratio
            left=math.min(left,x-ow/2);right=math.max(right,x+ow/2)
            bottom=math.min(bottom,y-oh/2);top=math.max(top,y+oh/2)
        end
    end
    frame.mmfDesignBounds={width=right-left,height=top-bottom}
    
    left,right,bottom,top=nil,nil,nil,nil
    local function IncludeBars(member)
        local function Include(object)
            local x,y=D.CenterIn(object,frame,0,0)
            local ratio=object:GetEffectiveScale()/frame:GetEffectiveScale()
            local hw,hh=object:GetWidth()*ratio/2,object:GetHeight()*ratio/2
            left=left and math.min(left,x-hw) or x-hw
            right=right and math.max(right,x+hw) or x+hw
            bottom=bottom and math.min(bottom,y-hh) or y-hh
            top=top and math.max(top,y+hh) or y+hh
        end
        Include(member.healthBar or member)
        local power=D.ElementDesign(member.mmfDesignerKey or D.Key(member.unit),"power")
        if member.powerBar and power and power.enabled~=false and member.powerBar:IsShown() then Include(member.powerBar) end
    end
    if frame.mmfDesignerKey=="boss" then
        for i=1,D.byUnitType.boss.count do
            local member=MMF_GetFrameForUnit("boss"..i)
            if member then IncludeBars(member) end
        end
    else
        IncludeBars(frame)
    end
    mover:ClearAllPoints();mover:SetPoint("CENTER",frame,"CENTER",(left+right)/2,(bottom+top)/2)
    mover:SetSize(math.max(4,right-left+4),math.max(4,top-bottom+4))
    D.UpdateMoverVisibility(frame)
end
function D.UpdateMoverVisibility(frame)
    if InCombatLockdown() then return end
    local mover=frame.mmfDesignerMover
    if not mover then return end
    local primary=frame.mmfDesignerKey~="boss" or frame.unit=="boss1"
    local allowed=not MMF_IsBlizzardEditModeActive() and ((D.moveMode and (not D.moveCategories or D.moveCategories.units)) or (not D.moveMode and D.Profile().liveDragUnlocked==true and (D.liveMoveHandlesWanted or mover.drag)))
    local state=primary and allowed and D.IsUnitEnabled(frame.unit) and "[combat] hide; show" or "hide"
    if mover.mmfState~=state then
        RegisterStateDriver(mover,"visibility",state);mover.mmfState=state
    end
end

local hiddenBlizzard={}
local hiddenParent=CreateFrame("Frame",nil,UIParent);hiddenParent:Hide()
local function HideNativeGroup(name,hide)
    local frame=_G[name]
    if not frame then return end
    if hide then
        if not hiddenBlizzard[frame] then hiddenBlizzard[frame]={parent=frame:GetParent()} end
        if frame:GetParent()~=hiddenParent then frame:SetParent(hiddenParent) end
    elseif hiddenBlizzard[frame] then
        frame:SetParent(hiddenBlizzard[frame].parent or UIParent)
        hiddenBlizzard[frame]=nil
    end
end
function D.UpdateVisibility(onlyKey)
    if not D.ready then return end
    if InCombatLockdown() then D.pendingVisibility=true;return end
    for frame in pairs(D.frames) do
        local key=frame.mmfDesignerKey
        if not onlyKey or onlyKey==key then
        local normal="[@"..frame.unit..",exists] show; hide"
        if key=="party" or key=="partypet" then normal="[group:raid] hide; "..normal end
        if key=="raid" or key=="raidpet" then normal="[nogroup:raid] hide; "..normal end
        local unit=D.UnitDesign(key)
        if unit.hideOutsideCombat then normal="[nocombat] hide; "..normal end
        local state=unit.enabled~=false and D.Supports(key) and ((D.moveMode and "[nocombat] show; " or "")..normal) or "hide"
        if frame.mmfDesignerState~=state then
            UnregisterUnitWatch(frame)
            RegisterStateDriver(frame,"visibility",state)
            frame.mmfDesignerState=state
        end
        D.ApplyPosition(frame)
        D.RefreshMover(frame)
        local alpha=unit.outsideCombatAlpha or 1
        if key=="player" and MattMinimalFramesDB and MattMinimalFramesDB.showPlayerOnTargetSelected==true
            and UnitExists and UnitExists("target") then alpha=1 end
        frame:SetAlpha(UnitAffectingCombat("player") and 1 or alpha)
        end
    end
    
    if (not onlyKey or onlyKey=="boss") and D.IsUnitEnabled("boss") then D.ArrangeGroup("boss") end
    local boss=MMF_GetFrameForUnit("boss1")
    if (not onlyKey or onlyKey=="boss") and boss and boss.mmfDesignerKey then D.RefreshMover(boss) end
    if not onlyKey then
    local hideParty=D.IsUnitEnabled("party")
    local hideRaid=D.IsUnitEnabled("raid")
    for _,name in ipairs({"PartyFrame","CompactPartyFrame","PartyMemberFrame1","PartyMemberFrame2","PartyMemberFrame3","PartyMemberFrame4"}) do HideNativeGroup(name,hideParty) end
    HideNativeGroup("CompactRaidFrameContainer",hideRaid)
    end
    
    MattMinimalFramesDB.locked=true
end
function D.SetMoveMode(enabled)
    enabled=enabled==true
    if enabled and MMF_IsBlizzardEditModeActive() then D.Notify("Close Blizzard Edit Mode before opening MMF Edit Mode.");return false end
    if InCombatLockdown() then D.Notify("Leave combat before moving frames.");return false end
    if D.moveMode==enabled then D.UpdateVisibility();return true end
    if enabled and D.CaptureEditPositions then D.CaptureEditPositions() end
    D.moveMode=enabled
    MattMinimalFramesDB.unlockFramesEditMode=false
    MattMinimalFramesDB.layoutTestMode=false
    MattMinimalFramesDB.auraTestMode=false
    MattMinimalFramesDB.locked=true
    if enabled and D.window then D.window:Hide() end
    if D.MoveToolbar then D.MoveToolbar(enabled) end
    D.ApplyAll()
    if MMF_RequestAllFramesUpdate then MMF_RequestAllFramesUpdate() end
    if D.RefreshMoveSamples then D.RefreshMoveSamples() end
    return true
end

function D.Diagnostics()
    local version,build,_,interface=GetBuildInfo()
    local count=0;for _ in pairs(D.frames) do count=count+1 end
    local lines={"MMF "..D.VERSION,"Client "..tostring(version).." / build "..tostring(build).." / interface "..tostring(interface),
        "Project ID "..tostring(WOW_PROJECT_ID).." (recognized: "..tostring(Compat.IsKnownProject)..")",
        "Native aura adapter: "..tostring(MMF_UsesRestrictedAuraAPI==true),
        "Duration-object casting: "..tostring(type(UnitCastingDuration)=="function" and type(UnitChannelDuration)=="function"),
        "Secure unit frames: "..count,"Profile: "..tostring(MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"),
        "Combat lockdown: "..tostring(InCombatLockdown()),"Live-client certification: not performed for this alpha."}
    local selection=D.selection
    if selection and selection.id~="frame" then
        local cfg=D.ElementDesign(selection.unit,selection.id)
        if cfg then
            lines[#lines+1]="Selected "..selection.unit.." / "..selection.id..": saved anchor="..tostring(cfg.point).." -> "..tostring(cfg.relativeTo).." / "..tostring(cfg.relativePoint)..", alignment="..tostring(cfg.justify).." / "..tostring(cfg.justifyV)
            local function Describe(label,frame)
                local object=frame and frame.mmfDesignerNodes and frame.mmfDesignerNodes[selection.id]
                if not object then return end
                local function Read(method)
                    if not object[method] then return "n/a" end
                    local ok,value=pcall(object[method],object)
                    return ok and D.Readable(value) and tostring(value) or "unavailable"
                end
                lines[#lines+1]=label..": anchor="..Read("GetPoint")..", alignment="..Read("GetJustifyH").." / "..Read("GetJustifyV")..", size="..Read("GetWidth").." x "..Read("GetHeight")
            end
            Describe("Preview",D.window and D.window.previewRoot and D.window.previewRoot.instance)
            local entry=D.byUnitType[selection.unit]
            Describe("Live",entry and MMF_GetFrameForUnit(entry.token))
        end
    end
    for err in pairs(D.errors) do lines[#lines+1]="ERROR: "..err end
    return table.concat(lines,"\n")
end
function D.Start()
    if D.ready or not MattMinimalFramesDB or not MMF_PlayerFrame then return end
    if InCombatLockdown() then D.pendingStart=true;return end
    D.Profile()
    D.EnsureUnitFrames()
    
    for _,frame in ipairs(MMF_GetAllFrames()) do D.Attach(frame) end
    D.ready=true
    D.ApplyAll()
    if MMF_RequestAllFramesUpdate then MMF_RequestAllFramesUpdate() end
    if MMF_FlushRequestedUpdates then MMF_FlushRequestedUpdates() end
end

local events=CreateFrame("Frame")
pcall(events.RegisterEvent,events,"PLAYER_TOTEM_UPDATE")
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","GROUP_ROSTER_UPDATE","PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_TARGET","UNIT_AURA","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_PET","PLAYER_SPECIALIZATION_CHANGED","READY_CHECK","READY_CHECK_CONFIRM","READY_CHECK_FINISHED","INCOMING_RESURRECT_CHANGED","RAID_TARGET_UPDATE","PLAYER_ROLES_ASSIGNED","UNIT_FLAGS","UNIT_CONNECTION","UNIT_FACTION","PLAYER_FLAGS_CHANGED","PLAYER_PVP_UPDATE","PLAYER_DEAD","PLAYER_ALIVE","UNIT_HAPPINESS","PET_UI_UPDATE","PET_BAR_UPDATE"}) do
    pcall(events.RegisterEvent,events,event)
end
local elapsedSinceRefresh=0
local function RefreshData()
    for frame in pairs(D.frames) do
        if frame:IsShown() then
            D.UpdateExtras(frame)
        end
    end
end
local rosterRefreshQueued=false
local pendingExtrasFrames={}
local allExtrasPending=false
local function QueueRosterExtrasRefresh(unit)
    if unit then
        local frame=MMF_GetFrameForUnit(unit)
        if frame then pendingExtrasFrames[frame]=true end
    else allExtrasPending=true end
    if rosterRefreshQueued then return end
    rosterRefreshQueued=true
    C_Timer.After(0.05,function()
        rosterRefreshQueued=false
        if D.ready then
            if allExtrasPending then ProtectedCall("roster extras",RefreshData)
            else
                for frame in pairs(pendingExtrasFrames) do
                    if frame:IsShown() then ProtectedCall("unit extras",D.UpdateExtras,frame) end
                end
            end
        end
        allExtrasPending=false
        wipe(pendingExtrasFrames)
    end)
end
local function RefreshUnitExtras(unit)
    if not D.Readable(unit) then return end
    local frame=MMF_GetFrameForUnit(unit)
    if frame and frame:IsShown() then
        ProtectedCall("unit extras update",D.UpdateExtras,frame)
    end
end


local function PeriodicRefresh()
    if D.ready and not MMF_ShouldSuspendForBlizzardEditMode() then
        ProtectedCall("periodic update",RefreshData)
    end
end
if C_Timer and type(C_Timer.NewTicker)=="function" then
    events.mmfPeriodicRefreshTicker=C_Timer.NewTicker(1.0,PeriodicRefresh)
else
    events:SetScript("OnUpdate",function(_,elapsed)
        if not D.ready then return end
        elapsedSinceRefresh=elapsedSinceRefresh+elapsed
        if elapsedSinceRefresh<1.0 then return end
        elapsedSinceRefresh=0
        PeriodicRefresh()
    end)
end
events:SetScript("OnEvent",function(_,event,arg1)
    if event=="ADDON_LOADED" then
        if arg1==addonName then
            ProtectedCall("startup",D.Start)
            C_Timer.After(0,function() ProtectedCall("deferred startup",D.Start);if D.ready then ProtectedCall("deferred layout",D.ApplyAll) end end)
        elseif D.ready and not InCombatLockdown() then D.UpdateVisibility() end
        return
    end
    if event=="PLAYER_LOGIN" then ProtectedCall("login",D.Start);if D.ready then ProtectedCall("login layout",D.ApplyAll) end;return end
    if event=="PLAYER_REGEN_DISABLED" then
        D.moveMode=false
        if D.window then D.window:Hide() end
        if D.moveToolbar then D.moveToolbar:Hide() end
        if MattMinimalFramesDB then MattMinimalFramesDB.unlockFramesEditMode=false;MattMinimalFramesDB.locked=true end
        
        for frame in pairs(D.frames) do
            if frame.mmfDesignerMover then frame.mmfDesignerMover.drag=nil end
            frame:SetAlpha(1)
        end
        D.pendingVisibility=true
        return
    end
    if event=="PLAYER_REGEN_ENABLED" then
        if D.pendingStart then D.pendingStart=false;ProtectedCall("post-combat startup",D.Start) end
        if D.pending then
            ProtectedCall("post-combat layout",D.ApplyAll)
        elseif D.pendingVisibility then
            ProtectedCall("post-combat visibility",D.UpdateVisibility)
        end
        D.pendingVisibility=nil
        if D.FlushPendingAuraStyles then ProtectedCall("post-combat auras",D.FlushPendingAuraStyles) end
        if D.pendingPlayerLayout then
            D.pendingPlayerLayout=nil
            ProtectedCall("post-combat player layout",D.ApplyUnit,"player")
        end
        return
    end
    if not D.ready then return end
    if event=="UNIT_AURA" and D.Readable(arg1) then
        local frame=MMF_GetFrameForUnit(arg1)
        if frame then ProtectedCall("aura update",D.RefreshAuras,frame) end
    elseif event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH" then
        
        
        if D.Readable(arg1) and MMF_GetFrameForUnit(arg1) then QueueRosterExtrasRefresh(arg1) end
    elseif event=="UNIT_TARGET" then
        
        if D.Readable(arg1) then
            local targetUnit=arg1=="target" and "targettarget" or arg1=="focus" and "focustarget" or arg1=="pet" and "pettarget"
            if targetUnit then
                RefreshUnitExtras(targetUnit)
                if MMF_RequestUnitUpdate then MMF_RequestUnitUpdate(targetUnit) end
            end
        end
    elseif event=="UNIT_FLAGS" or event=="UNIT_CONNECTION" or event=="UNIT_FACTION" or event=="UNIT_HAPPINESS" then
        RefreshUnitExtras(arg1)
    elseif event=="PLAYER_FLAGS_CHANGED" then
        RefreshUnitExtras(arg1 or "player")
        if not arg1 then RefreshUnitExtras("target") end
    elseif event=="PLAYER_PVP_UPDATE" then
        RefreshUnitExtras("player")
        RefreshUnitExtras("target")
    elseif event=="PLAYER_DEAD" or event=="PLAYER_ALIVE" then
        RefreshUnitExtras("player")
    elseif event=="PET_UI_UPDATE" or event=="PET_BAR_UPDATE" then
        RefreshUnitExtras("pet")
    elseif event=="GROUP_ROSTER_UPDATE" then
        
        QueueRosterExtrasRefresh()
    elseif event=="PLAYER_SPECIALIZATION_CHANGED" then
        if not D.Readable(arg1) or arg1~="player" then return end
        if InCombatLockdown() then D.pendingPlayerLayout=true
        else ProtectedCall("player specialization layout",D.ApplyUnit,"player") end
    elseif event=="PLAYER_ENTERING_WORLD" then
        if InCombatLockdown() then D.pending=true else ProtectedCall("roster layout",D.ApplyAll) end
    else
        ProtectedCall("unit refresh",RefreshData)
        if event=="PLAYER_TARGET_CHANGED" and not InCombatLockdown() then ProtectedCall("target visibility",D.UpdateVisibility) end
    end
end)
D.eventFrame=events


if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("EditMode.Enter",function()
        if D.window then D.window:Hide() end
        if D.moveToolbar then D.moveToolbar:Hide() end
        if not D.ready then return end
        if InCombatLockdown() then D.pending=true;return end
        D.SetMoveMode(false)
        if D.RefreshMoveSamples then D.RefreshMoveSamples() end
    end,D)
    EventRegistry:RegisterCallback("EditMode.Exit",function()
        
        C_Timer.After(0,function()
            if not D.ready or MMF_IsBlizzardEditModeActive() then return end
            if InCombatLockdown() then D.pending=true;return end
            D.ApplyAll()
            if MMF_RequestAllFramesUpdate then MMF_RequestAllFramesUpdate() end
        end)
    end,D)
end
