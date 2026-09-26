

local D=MMF_Designer
local V=MMF_Visuals
local S=MMF_DesignerSamples
local cache={}
local bossSamples={}
local parking=CreateFrame("Frame",nil,UIParent)
parking:SetSize(220,28);parking:SetPoint("CENTER");parking:Hide()
D.previewInstances=cache

local function InitializeDesign(frame,key)
    local unit=D.UnitDesign(key)
    local first=not unit.migrated
    local nodes=V.Map(frame)
    V.ApplyStyle(frame)
    for _,spec in ipairs(D.Catalog(key,frame)) do
        local missing=unit.elements[spec.id]==nil
        local cfg=D.ElementDesign(key,spec.id)
        if first or missing then
            if nodes[spec.id] then D.CaptureVisualLayout(frame,nodes,spec,cfg) end
            D.ApplyLegacyVisibility(key,spec,cfg)
        end
    end
    if first then
        if MMF_GetShowHPValueText then unit.showHealthValue=MMF_GetShowHPValueText(frame.unit) end
        if MMF_GetShowHPPercentText then unit.showHealthPercent=MMF_GetShowHPPercentText(frame.unit) end
        D.InitializeOptionalLayout(key,unit)
        if key=="boss" then D.ApplyBossElementDefaults(unit) end
        unit.migrated=true
        unit.baseline={width=unit.width,height=unit.height,scale=unit.scale,elements=D.Copy(unit.elements)}
    end
    frame.mmfPreviewProfile=D.Profile()
    if key=="boss" then D.ApplyBossElementDefaults(unit) end
end

function D.GetPreviewFrame(key)
    if not D.Supports(key) or InCombatLockdown() then return nil end
    local frame=cache[key]
    if not frame then
        frame=V.CreatePreview(parking,key)
        cache[key]=frame
        InitializeDesign(frame,key)
        frame:Hide()
    elseif frame.mmfPreviewProfile~=D.Profile() then InitializeDesign(frame,key) end
    return frame
end

local function shown(region)
    if not region then return false end
    if region.IsVisible then return region:IsVisible() end
    return region:IsShown()
end
D.PreviewRegionShown=shown



local function Handle(root,spec,source,slot)
    local key=slot and (spec.id..":"..slot) or spec.id
    local handle=root.handles[key]
    if not handle then
        handle=CreateFrame("Frame",nil,root)
        handle.id=spec.id;handle:SetMovable(true);handle:EnableMouse(true)
        handle:RegisterForDrag("LeftButton")
        root.handles[key]=handle
        if D.BindPreviewInput then D.BindPreviewInput(handle) end
    end
    handle.source=source
    handle.visual=source
    handle.text=source and source.SetText and source or nil
    handle.bar=source and source.SetStatusBarTexture and source or nil
    handle.cooldown=source and source.SetCooldown and source or nil
    handle.model=source and source.SetUnit and source or nil
    handle:ClearAllPoints();handle:SetAllPoints(source)
    local parent=source.GetParent and source:GetParent()
    handle.visualLevel=source.GetFrameLevel and source:GetFrameLevel() or (parent and parent:GetFrameLevel() or 0)
    local layers={BACKGROUND=0,BORDER=1,ARTWORK=2,OVERLAY=3,HIGHLIGHT=4}
    local layer,sub=source.GetDrawLayer and source:GetDrawLayer()
    
    handle.pickOrder=handle.visualLevel*100+(layers[layer] or 2)*16+(sub or 0)
    handle:SetFrameLevel(root:GetFrameLevel()+400)
    handle:SetShown(shown(source))
    handle.generation=root.previewGeneration
    if not slot or slot==1 then root.nodes[spec.id]=handle end
    return handle
end

local function BuildHandles(root,frame)
    root.previewGeneration=(root.previewGeneration or 0)+1
    root.nodes={};root.handles=root.handles or {}
    local key=frame.mmfDesignerKey
    for _,spec in ipairs(D.Catalog(key,frame)) do
        if not spec.auraSub then
            local source=frame.mmfDesignerNodes[spec.id]
            if source then Handle(root,spec,source) end
        else
            local group=spec.parent=="buffs" and frame.BuffContainer or frame.DebuffContainer
            for i,button in ipairs(group and group.auras or {}) do
                local parts=MMF_AuraVisuals.Parts(button)
                local source=parts[spec.auraSub]
                if source then Handle(root,spec,source,i) end
            end
        end
    end
    for _,handle in pairs(root.handles) do
        if handle.generation~=root.previewGeneration then handle:Hide() end
    end
end

function D.RefreshPreview()
    if not D.window or not D.selection or not D.window.previewRoot then return end
    if not D.window:IsShown() or not D.window.pages.Designer:IsShown() then return end
    if InCombatLockdown() then return end
    local key=D.selection.unit;local unit=D.UnitDesign(key)
    local root=D.window.previewRoot;local frame=D.GetPreviewFrame(key)
    if not frame then return end
    for other,f in pairs(cache) do if other~=key and f:IsShown() then V.HidePreview(f) end end
    root:SetSize(unit.width,unit.height)
    local previewScale=D.Profile().zoom*unit.scale
    root:SetScale(previewScale)
    
    root:ClearAllPoints();root:SetPoint("CENTER",D.window.canvas,"CENTER",(D.panX or 0)/previewScale,(D.panY or 0)/previewScale)
    if frame:GetParent()~=root then frame:SetParent(root);V.RebasePreview(frame,root:GetFrameLevel()+1) end
    frame:ClearAllPoints();frame:SetPoint("CENTER",root,"CENTER",0,0);frame:Show()
    
    if frame:GetFrameLevel()~=root:GetFrameLevel()+1 then frame:SetFrameLevel(root:GetFrameLevel()+1) end
    V.ApplyStyle(frame)
    S.ApplyData(frame)
    V.ApplyLayout(frame,key)
    S.ApplyVisibility(frame)
    for _,sample in ipairs(bossSamples) do V.HidePreview(sample) end
    root.groupSamples=nil
    if key=="boss" then
        local stepX,stepY=D.GroupStep(frame,key)
        local columns=math.floor(D.Number(unit.groupColumns,1,1,D.byUnitType.boss.count))
        for i=2,D.byUnitType.boss.count do
            local sample=bossSamples[i-1]
            if not sample then sample=V.CreatePreview(root,key);V.Map(sample);bossSamples[i-1]=sample end
            sample:ClearAllPoints()
            sample:SetPoint("CENTER",frame,"CENTER",((i-1)%columns)*stepX,-math.floor((i-1)/columns)*stepY)
            sample:Show()
            V.ApplyStyle(sample);S.ApplyData(sample);V.ApplyLayout(sample,key);S.ApplyVisibility(sample)
        end
        root.groupSamples=bossSamples
    end
    root.instance=frame
    if D.gamePreviewEnabled and D.RefreshGamePreview then D.RefreshGamePreview() end
    BuildHandles(root,frame)
    for _,line in ipairs(D.window.gridLines or {}) do line:SetShown(D.Profile().showGrid~=false) end
    if D.UpdatePreviewOutlines then D.UpdatePreviewOutlines() end
    if D.window.previewDisclosure then
        local id=D.selection.id;local cfg=id~="frame" and D.ElementDesign(key,id)
        D.window.previewDisclosure:SetText(cfg and cfg.enabled==false and "Hidden in game — previewing only" or "")
    end
end



function D.PreviewScreenRect(region)
    if not region or not region.GetLeft then return nil end
    local l,r,t,b=region:GetLeft(),region:GetRight(),region:GetTop(),region:GetBottom()
    for _,n in ipairs({l,r,t,b}) do if not D.Readable(n) or type(n)~="number" then return nil end end
    if l==nil or r==nil or t==nil or b==nil then return nil end
    local scale=region.GetEffectiveScale and region:GetEffectiveScale() or 1
    return l*scale,r*scale,t*scale,b*scale
end
local function FitPreview()
    if not D.window or not D.selection then return end
    D.panX,D.panY=0,0
    D.RefreshPreview()
    local root=D.window.previewRoot;local canvas=D.window.canvas
    local left,right,top,bottom=D.PreviewScreenRect(root)
    if not left then return end
    for _,handle in pairs(root.handles or {}) do
        if handle:IsShown() or (D.selection.unit=="player" and handle.id=="resources") then
            local l,r,t,b=D.PreviewScreenRect(handle.source or handle)
            if l then left=math.min(left,l);right=math.max(right,r);top=math.max(top,t);bottom=math.min(bottom,b) end
        end
    end
    for _,sample in ipairs(root.groupSamples or {}) do
        local l,r,t,b=D.PreviewScreenRect(sample)
        if l then left=math.min(left,l);right=math.max(right,r);top=math.max(top,t);bottom=math.min(bottom,b) end
        for _,region in pairs(sample.mmfDesignerNodes or {}) do
            if shown(region) then
                local rl,rr,rt,rb=D.PreviewScreenRect(region)
                if rl then left=math.min(left,rl);right=math.max(right,rr);top=math.max(top,rt);bottom=math.min(bottom,rb) end
            end
        end
    end
    local cl,cr,ct,cb=D.PreviewScreenRect(canvas)
    if not cl then return end
    local scale=canvas:GetEffectiveScale()
    
    local usableLeft,usableRight=cl+32*scale,cr-32*scale
    local usableTop,usableBottom=ct-55*scale,cb+48*scale
    if usableRight<=usableLeft or usableTop<=usableBottom then return end
    local ratio=math.min((usableRight-usableLeft)/math.max(right-left,1),(usableTop-usableBottom)/math.max(top-bottom,1))
    local old=D.Profile().zoom
    local zoom=D.Number(old*ratio,1.5,.01,3)
    local cx,cy=root:GetCenter();local rs=root:GetEffectiveScale()
    D.panX=(cx*rs-(left+right)/2)/scale*(zoom/old)+((usableLeft+usableRight)-(cl+cr))/(2*scale)
    D.panY=(cy*rs-(top+bottom)/2)/scale*(zoom/old)+((usableTop+usableBottom)-(ct+cb))/(2*scale)
    D.Profile().zoom=zoom
    D.RefreshPreview()
end
function D.CenterPreview()
    local window=D.window
    if not window or not D.selection or InCombatLockdown() then return end
    if not window:IsShown() or not window.pages.Designer:IsShown() then return end
    D.previewFitRequest=(D.previewFitRequest or 0)+1
    local request,key,profile=D.previewFitRequest,D.selection.unit,D.Profile()
    D.panX,D.panY=0,0
    profile.zoom=1
    D.RefreshPreview()
    C_Timer.After(0,function()
        if request~=D.previewFitRequest or D.Profile()~=profile or not D.selection or D.selection.unit~=key then return end
        if InCombatLockdown() or not window:IsShown() or not window.pages.Designer:IsShown() or D.previewDrag or D.previewPress then return end
        FitPreview()
    end)
end
function D.ZoomPreview(delta)
    if D.previewDrag or D.previewPress then return end
    D.previewFitRequest=(D.previewFitRequest or 0)+1
    D.Profile().zoom=D.Number(D.Profile().zoom+(tonumber(delta) or 0)*.1,1.5,.01,4)
    D.RefreshPreview()
end
function D.DisposePreview()
    for _,frame in pairs(cache) do V.HidePreview(frame) end
end
