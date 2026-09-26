
local D=MMF_Designer
local V=MMF_Visuals
local S=MMF_DesignerSamples
D.moveCategories={units=true,cast=false,buffs=false,debuffs=false,resources=false}
local previews={}
local gameSamples={}
local gameHost=CreateFrame("Frame",nil,UIParent)
gameHost:SetAllPoints(UIParent);gameHost:SetFrameStrata("HIGH");gameHost:EnableMouse(false);gameHost:Hide()

function D.SetGamePreview(enabled)
    D.gamePreviewEnabled=enabled==true and not InCombatLockdown() and not MMF_IsBlizzardEditModeActive()
    if D.window and D.window.gamePreview then D.window.gamePreview:SetActive(D.gamePreviewEnabled) end
    if D.gamePreviewEnabled then D.RefreshGamePreview()
    else
        gameHost:Hide()
        for _,sample in pairs(gameSamples) do V.HidePreview(sample) end
    end
end

function D.RefreshGamePreview()
    if not D.gamePreviewEnabled then return end
    if InCombatLockdown() or MMF_IsBlizzardEditModeActive() or not D.window or not D.window:IsShown() then
        D.SetGamePreview(false);return
    end
    local key,id=D.selection.unit,D.selection.id
    local entry=D.byUnitType[key]
    if not entry or not D.Supports(key) then D.SetGamePreview(false);return end
    local ok,err=pcall(function()
        local sample=gameSamples[key]
        if not sample then sample=V.CreatePreview(gameHost,key);V.Map(sample);gameSamples[key]=sample end
        for other,frame in pairs(gameSamples) do if other~=key then V.HidePreview(frame) end end
        local allowed={}
        local component=D.friendlyByID and D.friendlyByID[id]
        local members={[id]=true}
        if component then for _,member in ipairs(component.members) do members[member]=true end end
        for _,spec in ipairs(D.Catalog(key,sample)) do
            local current=spec.id
            local selected=id=="frame"
            local seen={}
            while not selected and current and not seen[current] do
                seen[current]=true
                selected=members[current]==true
                current=D.catalogByID[current] and D.catalogByID[current].parent
            end
            local cfg=D.ElementDesign(key,spec.id)
            allowed[spec.id]=selected and (spec.id==id or cfg.enabled~=false)
        end
        
        for element,shown in pairs(allowed) do
            if shown then
                local parent=D.catalogByID[element] and D.catalogByID[element].parent
                local seen={}
                while parent and parent~="frame" and not seen[parent] do
                    seen[parent]=true
                    local spec=D.catalogByID[parent]
                    if spec and spec.kind=="group" then allowed[parent]=true end
                    parent=spec and spec.parent
                end
            end
        end
        local design=D.UnitDesign(key)
        local live=MMF_GetFrameForUnit(entry.token)
        local scale=design.scale or 1
        local saved=D.Profile().positions and D.Profile().positions[entry.token]
        local x,y=saved and saved.x,saved and saved.y
        if live then
            scale=live:GetEffectiveScale()/UIParent:GetEffectiveScale()
            x,y=D.CenterIn(live,UIParent,0,0)
        elseif not x then
            for _,def in ipairs(MMF_Config.FRAME_DEFINITIONS) do
                if def.unit==entry.token then x,y=def.x,def.y;break end
            end
        end
        sample:SetScale(scale);sample:ClearAllPoints()
        sample:SetPoint("CENTER",UIParent,"CENTER",(x or 0)/scale,(y or 0)/scale)
        gameHost:Show();sample:Show()
        D.gamePreviewElements=allowed
        V.ApplyStyle(sample);S.ApplyData(sample);V.ApplyLayout(sample,key);S.ApplyVisibility(sample)
        for element,region in pairs(sample.mmfDesignerNodes) do
            if not allowed[element] then region:Hide() end
        end
        if key=="boss" then
            sample.groupSamples=sample.groupSamples or {}
            local stepX,stepY=D.GroupStep(sample,key)
            local columns=math.floor(D.Number(design.groupColumns,1,1,entry.count))
            for i=2,entry.count do
                local member=sample.groupSamples[i]
                if not member then member=V.CreatePreview(sample,key);V.Map(member);sample.groupSamples[i]=member end
                member:ClearAllPoints()
                member:SetPoint("CENTER",sample,"CENTER",((i-1)%columns)*stepX,-math.floor((i-1)/columns)*stepY)
                member:Show()
                V.ApplyStyle(member);S.ApplyData(member);V.ApplyLayout(member,key);S.ApplyVisibility(member)
                for element,region in pairs(member.mmfDesignerNodes) do
                    if not allowed[element] then region:Hide() end
                end
            end
        end
    end)
    D.gamePreviewElements=nil
    if not ok then D.SetGamePreview(false);D.Notify("Could not preview this element: "..tostring(err)) end
end
gameHost:RegisterEvent("PLAYER_REGEN_DISABLED")
gameHost:SetScript("OnEvent",function() D.SetGamePreview(false) end)
local grid=CreateFrame("Frame",nil,UIParent)
grid:SetAllPoints(UIParent);grid:SetFrameStrata("BACKGROUND");grid:EnableMouse(false);grid:Hide()
grid.lines={}
local function DrawGrid()
    local width,height=grid:GetWidth(),grid:GetHeight()
    if grid.width==width and grid.height==height then return end
    grid.width,grid.height=width,height
    for _,line in ipairs(grid.lines) do line:Hide() end
    local used=0
    local function Line(vertical,offset)
        used=used+1
        local line=grid.lines[used]
        if not line then line=grid:CreateTexture(nil,"ARTWORK");grid.lines[used]=line end
        line:ClearAllPoints()
        local center=offset==0
        line:SetColorTexture(1,1,1,center and .5 or .16)
        line:SetSize(vertical and 1 or width,vertical and height or 1)
        line:SetPoint("CENTER",grid,"CENTER",vertical and offset or 0,vertical and 0 or offset)
        line:Show()
    end
    Line(true,0);Line(false,0)
    for x=32,width/2,32 do Line(true,x);Line(true,-x) end
    for y=32,height/2,32 do Line(false,y);Line(false,-y) end
end
function D.RefreshMoveGrid()
    local shown=D.moveMode and not InCombatLockdown() and not MMF_IsBlizzardEditModeActive()
        and D.Profile().moveGrid==true
    grid:SetShown(shown==true)
    if shown then DrawGrid() end
end
grid:SetScript("OnSizeChanged",function(self) if self:IsShown() then DrawGrid() end end)
grid:RegisterEvent("PLAYER_REGEN_DISABLED")
grid:SetScript("OnEvent",function() grid:Hide() end)
local host=CreateFrame("Frame",nil,UIParent)
host:SetAllPoints(UIParent);host:SetFrameStrata("DIALOG");host:Hide()

function D.MoveSampleCategory(id)
    local seen={}
    while id and id~="frame" and not seen[id] do
        if id=="cast" or id=="buffs" or id=="debuffs" or id=="resources" then return id end
        seen[id]=true
        id=D.catalogByID[id] and D.catalogByID[id].parent
    end
end
local function Handle(sample,id,source)
    local h=CreateFrame("Frame",nil,host,"BackdropTemplate")
    h:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    h:SetBackdropBorderColor(.6,.4,.9,.9);h:EnableMouse(true);h:RegisterForDrag("LeftButton")
    h:SetFrameLevel(host:GetFrameLevel()+500)
    h:SetScript("OnDragStart",function(self)
        if not D.moveMode or InCombatLockdown() or not D.moveCategories[id] then return end
        local cfg=D.ElementDesign(sample.mmfDesignerKey,id)
        D.PushHistory(sample.mmfDesignerKey)
        local x,y=GetCursorPosition()
        self.drag={x=x,y=y,lastX=x,lastY=y,ox=cfg.x or 0,oy=cfg.y or 0,scale=source:GetEffectiveScale(),profile=D.Profile()}
    end)
    h:SetScript("OnUpdate",function(self)
        local drag=self.drag
        if not drag then return end
        if not D.moveMode or InCombatLockdown() or drag.profile~=D.Profile() or not D.moveCategories[id] then self.drag=nil;return end
        local x,y=GetCursorPosition()
        if x==drag.lastX and y==drag.lastY then return end
        drag.lastX,drag.lastY=x,y
        local changes=D.FriendlyMoveChanges(sample.mmfDesignerKey,id,drag.ox+(x-drag.x)/drag.scale,drag.oy+(y-drag.y)/drag.scale)
        for _,change in ipairs(changes) do D.ElementDesign(sample.mmfDesignerKey,change[1])[change[2]]=change[3] end
        drag.changed=true
        
        
        local moved={}
        for _,change in ipairs(changes) do moved[change[1]]=true end
        for _,preview in pairs(previews) do
            if preview:IsShown() and preview.mmfDesignerKey==sample.mmfDesignerKey then
                for element in pairs(moved) do
                    local region=preview.mmfDesignerNodes[element]
                    if region then
                        local cfg=D.ElementDesign(sample.mmfDesignerKey,element)
                        region:ClearAllPoints()
                        region:SetPoint(cfg.point or "CENTER",preview.mmfDesignerNodes[cfg.relativeTo] or preview,
                            cfg.relativePoint or "CENTER",cfg.x or 0,cfg.y or 0)
                    end
                end
            end
        end
    end)
    local function Finish(self)
        local drag=self.drag;self.drag=nil
        if drag and drag.changed and drag.profile==D.Profile() then
            if InCombatLockdown() then D.pending=true
            else D.ApplyUnit(sample.mmfDesignerKey) end
            if D.RefreshMoveResetLists then D.RefreshMoveResetLists() end
        end
    end
    h:SetScript("OnDragStop",Finish)
    h:SetScript("OnHide",Finish)
    return h
end
function D.RefreshMoveSamples()
    D.RefreshMoveGrid()
    if not D.moveMode or InCombatLockdown() or MMF_IsBlizzardEditModeActive() then host:Hide();return end
    host:Show()
    for live in pairs(D.frames) do
        local key=live.mmfDesignerKey
        local active=live:IsShown() and D.IsUnitEnabled(live.unit)
        local wanted=D.moveCategories.cast or D.moveCategories.buffs or D.moveCategories.debuffs or (key=="player" and D.moveCategories.resources)
        local sample=previews[live]
        if active and wanted then
            if not sample then
                sample=V.CreatePreview(host,key);sample.handles={};previews[live]=sample
                V.Map(sample)
            end
            local scale=live:GetEffectiveScale()/UIParent:GetEffectiveScale()
            local x,y=D.CenterIn(live,UIParent,0,0)
            sample:SetScale(scale);sample:ClearAllPoints();sample:SetPoint("CENTER",UIParent,"CENTER",x/scale,y/scale)
            sample.moveX,sample.moveY,sample.moveScale=x,y,scale
            sample:Show()
            D.renderMoveSamples=true
            local ok,err=pcall(function()
                V.ApplyStyle(sample);S.ApplyData(sample);V.ApplyLayout(sample,key);S.ApplyVisibility(sample)
            end)
            D.renderMoveSamples=nil
            if not ok then sample:Hide();D.Notify(err);return end
            for _,id in ipairs({"cast","buffs","debuffs","resources"}) do
                local source=sample.mmfDesignerNodes[id]
                if source then
                    local h=sample.handles[id]
                    if not h then h=Handle(sample,id,source);sample.handles[id]=h end
                    if not h.anchored then h:SetAllPoints(source);h.anchored=true end
                    h:SetShown(D.moveCategories[id]==true and source:IsShown())
                end
            end
        elseif sample then
            sample:Hide()
            for _,h in pairs(sample.handles) do h:Hide() end
        end
    end
end
function D.SetMoveCategory(id,value)
    if InCombatLockdown() then return end
    D.moveCategories[id]=value==true
    for frame in pairs(D.frames) do D.UpdateMoverVisibility(frame) end
    D.RefreshMoveSamples()
end
host:RegisterEvent("PLAYER_REGEN_DISABLED")
host:SetScript("OnEvent",function() host:Hide() end)
local elapsed=0
host:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    if elapsed<.03 then return end
    elapsed=0
    if not D.moveMode or InCombatLockdown() then host:Hide();return end
    
    
    for live,sample in pairs(previews) do
        if sample:IsShown() then
            if not live:IsShown() then
                sample:Hide()
                for _,h in pairs(sample.handles) do h:Hide() end
            else
                local scale=live:GetEffectiveScale()/UIParent:GetEffectiveScale()
                local x,y=D.CenterIn(live,UIParent,0,0)
                if x~=sample.moveX or y~=sample.moveY or scale~=sample.moveScale then
                    sample:SetScale(scale);sample:ClearAllPoints()
                    sample:SetPoint("CENTER",UIParent,"CENTER",x/scale,y/scale)
                    sample.moveX,sample.moveY,sample.moveScale=x,y,scale
                end
            end
        end
    end
end)

local positionFields={"point","relativePoint","relativeTo","x","y"}
function D.CaptureEditPositions()
    local profile=D.Profile()
    local snapshot={profile=profile,units=D.Copy(profile.units),positions={}}
    for live in pairs(D.frames) do
        local x,y=D.CenterIn(live,UIParent,0,0)
        snapshot.positions[live.unit]={x=x,y=y}
    end
    D.editPositionSnapshot=snapshot
end
function D.GetMovedEditItems(category)
    local result={}
    local snapshot=D.editPositionSnapshot
    if not snapshot or snapshot.profile~=D.Profile() then return result end
    for _,entry in ipairs(D.unitTypes) do
        local unit=D.Profile().units[entry.key]
        if unit and unit.enabled~=false and D.Supports(entry.key) then
            if category=="units" then
                local frames={};local moved=false
                for live in pairs(D.frames) do
                    if live.mmfDesignerKey==entry.key then
                        local def=snapshot.positions[live.unit]
                        local saved=D.Profile().positions and D.Profile().positions[live.unit]
                        if def and saved then
                            frames[#frames+1]={frame=live,x=def.x or 0,y=def.y or 0}
                            if math.abs(saved.x-(def.x or 0))>.5 or math.abs(saved.y-(def.y or 0))>.5 then moved=true end
                        end
                    end
                end
                if moved then result[#result+1]={key=entry.key,label=entry.label,frames=frames} end
            else
                local cfg=unit.elements[category]
                local original=snapshot.units[entry.key]
                local defaults=original and original.elements and original.elements[category]
                if cfg and defaults then
                    local moved=false
                    for _,field in ipairs(positionFields) do
                        local a,b=cfg[field],defaults[field]
                        if type(a)=="number" and type(b)=="number" then
                            if math.abs(a-b)>.01 then moved=true end
                        elseif a~=b then moved=true end
                    end
                    if moved then result[#result+1]={key=entry.key,label=entry.label,id=category,defaults=D.Copy(defaults)} end
                end
            end
        end
    end
    return result
end
function D.ResetMovedEditItem(item)
    if InCombatLockdown() then return end
    if item.frames then
        for _,entry in ipairs(item.frames) do D.Place(entry.frame,entry.x,entry.y);D.SavePosition(entry.frame,entry.x,entry.y) end
        D.UpdateVisibility()
    else
        D.PushHistory(item.key)
        local cfg=D.ElementDesign(item.key,item.id)
        local changes=D.FriendlyMoveChanges(item.key,item.id,item.defaults.x or 0,item.defaults.y or 0)
        for _,change in ipairs(changes) do D.ElementDesign(item.key,change[1])[change[2]]=change[3] end
        for _,field in ipairs(positionFields) do cfg[field]=item.defaults[field] end
        D.ApplyUnit(item.key)
    end
    D.RefreshMoveSamples()
    if D.RefreshMoveResetLists then D.RefreshMoveResetLists() end
end
