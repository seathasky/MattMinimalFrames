
local D=MMF_Designer
local WHITE="Interface\\Buttons\\WHITE8X8"
local function IsShown(object) if not object then return false end if object.IsVisible then return object:IsVisible() end return object:IsShown() end
local function Outline(parent,r,g,b,a)
    local frame=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    frame:SetBackdrop({edgeFile=WHITE,edgeSize=1})
    frame:SetBackdropBorderColor(r or .34,g or .84,b or .72,a or 1)
    frame:EnableMouse(false);frame:Hide()
    return frame
end
function D.CanPreviewResize(id)
    if not id or id=="frame" or id=="buffs" or id=="debuffs" then return false end
    if id=="health" or id=="power" or id=="cast" or id=="resources" then return true end
    local spec=D.catalogByID[id]
    if spec and spec.kind=="text" and D.selection then
        local cfg=D.ElementDesign(D.selection.unit,id)
        if cfg and cfg.followFrameSize~=false then return false end
    end
    if not spec or spec.dynamic or spec.kind=="group" or spec.kind=="auras" then return false end
    return spec.kind=="text" or spec.kind=="auraText" or spec.kind=="icon" or spec.kind=="model"
        or spec.kind=="bar" or spec.kind=="texture" or spec.kind=="auraIcon"
        or spec.kind=="auraCooldown" or spec.kind=="auraBorder"
end

local function EnsureCanvasOutlines()
    local window=D.window
    if not window or not window.canvas then return end
    local top=window.canvas:GetFrameLevel()+800
    if not window.selectionOutline then
        window.selectionOutline=Outline(window.canvas,.34,.84,.72,1)
        window.selectionOutline:SetFrameLevel(top)
    end
    if not window.hoverOutline then
        window.hoverOutline=Outline(window.canvas,.82,.88,.93,.8)
        window.hoverOutline:SetFrameLevel(top-2)
    end
    if not window.selectionGrab then
        local grab=CreateFrame("Frame",nil,window.canvas)
        grab:SetFrameLevel(top+2);grab:EnableMouse(true);grab:SetMovable(true);grab:RegisterForDrag("LeftButton")
        grab:EnableMouseWheel(true);grab:SetScript("OnMouseWheel",function(_,delta) D.ZoomPreview(delta) end)
        grab:SetScript("OnMouseDown",function(self,button) D.BeginPreviewPress(button,D.selection and D.selection.id,self) end)
        grab:SetScript("OnMouseUp",function(_,button) D.EndPreviewPress(button) end)
        grab:SetScript("OnDragStart",function() D.BeginPreviewDrag() end)
        grab:SetScript("OnDragStop",function() D.EndPreviewPress("LeftButton") end)
        grab:SetScript("OnEnter",function() if D.selection then D.previewHover=D.selection.id;D.UpdatePreviewOutlines() end end)
        grab:SetScript("OnLeave",function() D.previewHover=nil;D.UpdatePreviewOutlines() end)
        grab:Hide();window.selectionGrab=grab
    end
    if not window.resizeHandle then
        local handle=CreateFrame("Frame",nil,window.canvas,"BackdropTemplate")
        handle:SetSize(13,13);handle:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
        handle:SetBackdropColor(.29,.82,.70,1);handle:SetBackdropBorderColor(.04,.05,.06,1)
        handle:SetFrameLevel(top+5);handle:EnableMouse(true);handle:SetMovable(true);handle:RegisterForDrag("LeftButton")
        handle:SetScript("OnMouseDown",function(self,button) D.BeginPreviewPress(button,D.selection and D.selection.id,self,"resize") end)
        handle:SetScript("OnMouseUp",function(_,button) D.EndPreviewPress(button) end)
        handle:SetScript("OnDragStart",function() D.BeginPreviewDrag() end)
        handle:SetScript("OnDragStop",function() D.EndPreviewPress("LeftButton") end)
        handle:Hide();window.resizeHandle=handle
    end
end

local function OutlineNode(outline,node,pad)
    if not outline or not node or not IsShown(node) then if outline then outline:Hide() end return end
    pad=pad or 2
    outline:ClearAllPoints()
    outline:SetPoint("TOPLEFT",node,"TOPLEFT",-pad,pad)
    outline:SetPoint("BOTTOMRIGHT",node,"BOTTOMRIGHT",pad,-pad)
    outline:Show()
end
function D.UpdatePreviewOutlines()
    if not D.window or not D.window.previewRoot then return end
    EnsureCanvasOutlines()
    local root=D.window.previewRoot
    local selected=D.selection and D.selection.id or "frame"
    local selectedNode=selected=="frame" and root or ((D.previewDrag and D.previewDrag.handle) or (D.previewPress and D.previewPress.handle) or root.nodes[selected])
    OutlineNode(D.window.selectionOutline,selectedNode,selected=="frame" and 3 or 2)
    if D.window.selectionGrab then
        if selected~="frame" and selectedNode and IsShown(selectedNode) then
            D.window.selectionGrab:ClearAllPoints()
            D.window.selectionGrab:SetPoint("TOPLEFT",selectedNode,"TOPLEFT",-3,3)
            D.window.selectionGrab:SetPoint("BOTTOMRIGHT",selectedNode,"BOTTOMRIGHT",3,-3)
            D.window.selectionGrab:Show()
        else D.window.selectionGrab:Hide() end
    end
    if selectedNode and IsShown(selectedNode) and D.CanPreviewResize(selected) then
        D.window.resizeHandle:ClearAllPoints();D.window.resizeHandle:SetPoint("CENTER",selectedNode,"BOTTOMRIGHT",0,0);D.window.resizeHandle:Show()
    else D.window.resizeHandle:Hide() end
    local hover=D.previewHover
    if hover and hover~=selected then OutlineNode(D.window.hoverOutline,hover=="frame" and root or root.nodes[hover],2)
    else D.window.hoverOutline:Hide() end
    if D.window.hoverLabel then
        local label=hover and (hover=="frame" and "Whole frame" or D.FriendlyLabel(hover)) or "Click an element, then drag it"
        D.window.hoverLabel:SetText(label)
    end
end


local function Inside(region,x,y,padding)
    local l,r,t,b=D.PreviewScreenRect(region)
    if not l then return false end
    local p=padding or 0
    return x>=l-p and x<=r+p and y>=b-p and y<=t+p
end
local function InsideCanvas(x,y)
    local w=D.window
    return w and w:IsShown() and w.pages.Designer:IsShown() and Inside(w.canvas,x,y,0)
end
function D.ResizeHandleUnderMouse()
    local w=D.window;local h=w and w.resizeHandle
    local x,y=GetCursorPosition()
    if h and IsShown(h) and InsideCanvas(x,y) and Inside(h,x,y,2) then return D.selection.id end
end
local function SelectionID(id)
    
    if D.selection and D.selection.id==id then return id end
    return D.FriendlySelection(id)
end
function D.PreviewNodesUnderMouse()
    local x,y=GetCursorPosition()
    if not InsideCanvas(x,y) then return {} end
    local root=D.window.previewRoot;local found,seen={},{}
    for _,node in pairs(root.handles or {}) do
        if IsShown(node) then
            local l,r,t,b=D.PreviewScreenRect(node)
            if l then
                local px=math.max(0,(10-(r-l))/2);local py=math.max(0,(10-(t-b))/2)
                if x>=l-px and x<=r+px and y>=b-py and y<=t+py then
                    local id=SelectionID(node.id)
                    local area=math.max((r-l)*(t-b),1)
                    local selected=D.selection and D.selection.id==id
                    local score=(selected and 10000000 or 0)+(node.pickOrder or 0)*100-math.min(area,100000)/1000
                    if not seen[id] or score>seen[id].score then
                        seen[id]={id=id,node=(id==node.id and node or root.nodes[id] or node),score=score}
                    end
                end
            end
        end
    end
    for _,item in pairs(seen) do found[#found+1]=item end
    table.sort(found,function(a,b) if a.score==b.score then return a.id<b.id end return a.score>b.score end)
    return found
end
function D.PreviewNodeUnderMouse() local nodes=D.PreviewNodesUnderMouse();return nodes[1] and nodes[1].node end
function D.PreviewElementUnderMouse() local nodes=D.PreviewNodesUnderMouse();return nodes[1] and nodes[1].id end

local function CanDrag()
    return D.ready and not InCombatLockdown() and D.window and D.window:IsShown()
        and D.window.pages.Designer:IsShown() and D.selection and not D.moveMode
end
local function SameDesign(gesture)
    return D.selection and D.selection.unit==gesture.key and D.selection.id==gesture.id
        and D.Profile()==gesture.profile and D.UnitDesign(gesture.key)==gesture.unit
end
function D.BeginPreviewPress(button,requestedID,source,mode)
    if not CanDrag() then return end
    local x,y=GetCursorPosition()
    if not InsideCanvas(x,y) then return end
    if D.previewDrag then D.CancelPreviewDrag() end
    if button=="MiddleButton" or button=="RightButton" then
        D.previewPress=nil
        D.window.canvas.pan={x=x,y=y,ox=D.panX or 0,oy=D.panY or 0,button=button}
        return
    end
    if button~="LeftButton" and button~=1 then return end
    local candidates=D.PreviewNodesUnderMouse()
    local resizeID=mode=="resize" and (requestedID or D.selection.id) or D.ResizeHandleUnderMouse()
    
    local id=resizeID or (requestedID~="frame" and requestedID) or (candidates[1] and candidates[1].id) or "frame"
    id=SelectionID(id)
    if id~="frame" and not D.catalogByID[id] then return end
    local handle=source and source.id==id and source or (candidates[1] and candidates[1].id==id and candidates[1].node)
    handle=handle or D.window.previewRoot.nodes[id]
    D.previewPress={id=id,key=D.selection.unit,unit=D.UnitDesign(D.selection.unit),profile=D.Profile(),x=x,y=y,
        mode=resizeID and "resize" or "move",source=source,handle=handle,candidates=candidates}
    if D.selection.id~=id then
        D.selection.id=id;D.inspectorTab=nil
        if D.RefreshInspector then D.RefreshInspector() end
    end
    
    D.RefreshPreview()
    D.UpdatePreviewOutlines()
end
function D.BeginPreviewDrag()
    local press=D.previewPress
    if not press or press.id=="frame" or not CanDrag() or not SameDesign(press) then return end
    D.BakeTextLayout(press.key,press.id)
    local cfg=D.ElementDesign(press.key,press.id)
    local handle=press.handle or D.window.previewRoot.nodes[press.id]
    local source=handle and handle.source
    local scale=source and source.GetEffectiveScale and source:GetEffectiveScale() or D.window.previewRoot:GetEffectiveScale()
    D.previewDrag={key=press.key,id=press.id,unit=press.unit,profile=press.profile,cfg=cfg,handle=handle,
        snapshot=D.Copy(press.unit),x=press.x,y=press.y,ox=cfg.x or 0,oy=cfg.y or 0,ow=cfg.width,oh=cfg.height,
        scale=D.Number(scale,1,.001,100),mode=press.mode,elapsed=0}
    D.previewPress=nil
    if D.window.status then D.window.status:SetText("Dragging "..D.FriendlyLabel(press.id).." — release to save; Esc to cancel") end
end
local function ApplyChanges(drag,changes)
    local changed=false
    for _,entry in ipairs(changes) do
        local cfg=D.ElementDesign(drag.key,entry[1])
        if cfg and cfg[entry[2]]~=entry[3] then cfg[entry[2]]=entry[3];changed=true end
    end
    if changed then drag.changed=true;drag.dirty=true;D.RefreshPreview() end
end
function D.UpdatePreviewDrag(elapsed,finishing)
    local drag=D.previewDrag
    if not drag then return end
    if not CanDrag() or not SameDesign(drag) then D.CancelPreviewDrag();return end
    local x,y=GetCursorPosition();local dx,dy=(x-drag.x)/drag.scale,(y-drag.y)/drag.scale
    local step=IsShiftKeyDown() and .5 or D.Profile().snap
    drag.elapsed=drag.elapsed+(elapsed or 0)
    if drag.mode=="resize" then
        local spec=D.catalogByID[drag.id]
        local width,height=D.Round(drag.ow+dx,step),D.Round(drag.oh-dy,step)
        if spec and (spec.kind=="icon" or spec.kind=="model" or spec.kind=="auraIcon" or spec.kind=="auraBorder" or spec.kind=="auraCooldown") then
            width=D.Round(drag.ow+(dx-dy)/2,step);height=width
        end
        width=D.Number(width,drag.ow,drag.id=="health" and 20 or 1,2000)
        height=D.Number(height,drag.oh,1,2000)
        drag.cfg.fitTextToContent=nil
        local changes=D.FriendlySizeChanges and D.FriendlySizeChanges(drag.key,drag.id,width,height) or {{drag.id,"width",width},{drag.id,"height",height}}
        
        if spec and spec.auraSub and spec.kind~="auraText" then changes[#changes+1]={drag.id,"fitIcon",false} end
        ApplyChanges(drag,changes)
    else
        local nx=D.Number(D.Round(drag.ox+dx,step),drag.ox,-4000,4000)
        local ny=D.Number(D.Round(drag.oy+dy,step),drag.oy,-4000,4000)
        local changes=D.FriendlyMoveChanges(drag.key,drag.id,nx,ny)
        ApplyChanges(drag,changes)
    end
    if drag.dirty and (finishing or drag.elapsed>=.04) then
        D.ApplyUnit(drag.key);drag.dirty=false;drag.elapsed=0
    end
end
function D.CancelPreviewDrag()
    local drag=D.previewDrag
    D.previewDrag=nil;D.previewPress=nil
    if D.window and D.window.canvas then D.window.canvas.pan=nil end
    if drag and drag.changed and drag.profile.units[drag.key]==drag.unit then
        
        drag.profile.units[drag.key]=D.Copy(drag.snapshot)
        if D.Profile()==drag.profile then D.ApplyUnit(drag.key) end
    end
    if D.window and D.window:IsShown() and not InCombatLockdown() then D.RefreshDesigner() end
end
function D.FinishPreviewDrag(refresh)
    local drag=D.previewDrag
    D.previewDrag=nil;D.previewPress=nil
    if drag and drag.changed and D.Profile()==drag.profile and drag.profile.units[drag.key]==drag.unit then
        D.PushHistorySnapshot(drag.key,drag.snapshot)
        D.ApplyUnit(drag.key)
    end
    if refresh~=false and D.window and D.window:IsShown() then D.RefreshDesigner() end
end
function D.UpdatePreviewInput(elapsed)
    if not D.window or not D.window:IsShown() then return end
    if not CanDrag() then if D.previewPress or D.previewDrag then D.CancelPreviewDrag() end;return end
    local pan=D.window.canvas.pan
    if pan then
        if not IsMouseButtonDown(pan.button) then D.window.canvas.pan=nil;return end
        local x,y=GetCursorPosition();local scale=D.window.canvas:GetEffectiveScale()
        D.panX=pan.ox+(x-pan.x)/scale;D.panY=pan.oy+(y-pan.y)/scale;D.RefreshPreview();return
    end
    if D.previewPress and not D.previewDrag then
        local x,y=GetCursorPosition();local p=D.previewPress
        if (x-p.x)^2+(y-p.y)^2>=9 then D.BeginPreviewDrag() end
    end
    if D.previewDrag then D.UpdatePreviewDrag(elapsed);return end
    D.hoverElapsed=(D.hoverElapsed or 0)+(elapsed or 0)
    if D.hoverElapsed>=.05 then
        D.hoverElapsed=0;local id=D.PreviewElementUnderMouse()
        if id~=D.previewHover then D.previewHover=id;D.UpdatePreviewOutlines() end
    end
end
function D.EndPreviewPress(button)
    if button=="MiddleButton" or button=="RightButton" then
        local canvas=D.window and D.window.canvas
        if canvas and canvas.pan and canvas.pan.button==button then canvas.pan=nil end
        return
    end
    if button~="LeftButton" and button~=1 and button~=nil then return end
    if D.previewDrag then D.UpdatePreviewDrag(0,true);D.FinishPreviewDrag(true);return end
    local press=D.previewPress;D.previewPress=nil
    if press then
        if #press.candidates>1 and D.ShowElementChooser then D.ShowElementChooser(press.candidates,press.source or D.window.canvas)
        else D.RefreshDesigner() end
    end
end
function D.BindPreviewInput(node)
    if node.mmfDesignerInputBound then return end
    node.mmfDesignerInputBound=true
    node:SetScript("OnMouseDown",function(self,button) D.BeginPreviewPress(button,self.id,self) end)
    node:SetScript("OnMouseUp",function(_,button) D.EndPreviewPress(button) end)
    node:SetScript("OnDragStart",function() D.BeginPreviewDrag() end)
    node:SetScript("OnDragStop",function() D.EndPreviewPress("LeftButton") end)
    node:EnableMouseWheel(true)
    node:SetScript("OnMouseWheel",function(_,delta) D.ZoomPreview(delta) end)
end
function D.CanvasMouseDown(button) D.BeginPreviewPress(button,nil,D.window and D.window.canvas) end
function D.CanvasMouseUp(button) D.EndPreviewPress(button) end
local monitor=CreateFrame("Frame")
pcall(monitor.RegisterEvent,monitor,"GLOBAL_MOUSE_UP")
monitor:RegisterEvent("PLAYER_REGEN_DISABLED")
monitor:SetScript("OnEvent",function(_,event,button)
    if event=="PLAYER_REGEN_DISABLED" then D.CancelPreviewDrag()
    elseif event=="GLOBAL_MOUSE_UP" and (D.previewPress or D.previewDrag or (D.window and D.window.canvas.pan)) then D.EndPreviewPress(button) end
end)
monitor:SetScript("OnUpdate",function(_,elapsed) D.UpdatePreviewInput(elapsed) end)
D.inputMonitor=monitor


local liveMoverController=CreateFrame("Frame")
local liveMoverElapsed=0
liveMoverController:SetScript("OnUpdate",function(_,elapsed)
    liveMoverElapsed=liveMoverElapsed+elapsed
    if liveMoverElapsed<.03 or InCombatLockdown() then return end
    liveMoverElapsed=0
    local shifted=D.ready and D.Profile().liveDragUnlocked==true and IsShiftKeyDown()
    if shifted and D.window and D.window:IsShown() then
        local left,right,top,bottom=D.PreviewScreenRect(D.window)
        local x,y=GetCursorPosition()
        if left and x>=left and x<=right and y>=bottom and y<=top then shifted=false end
    end
    D.liveMoveHandlesWanted=shifted==true
    for frame in pairs(D.frames or {}) do
        if D.UpdateMoverVisibility then D.UpdateMoverVisibility(frame) end
    end
end)
