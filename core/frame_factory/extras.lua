
local X={}
MMF_ExtraVisuals=X

function X.Text(parent,field,owner,size,text)
    if owner[field] then return owner[field] end
    local object=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    MMF_SetFontSafe(object,MMF_GetGlobalFontPath(),size or 12,"OUTLINE")
    object:SetText(text or "");object:SetTextColor(1,1,1,1);object:SetWordWrap(false)
    owner[field]=object
    return object
end
function X.Icon(parent,field,owner,texture)
    if owner[field] then return owner[field] end
    local object=parent:CreateTexture(nil,"OVERLAY")
    if texture then object:SetTexture(texture) end
    owner[field]=object
    return object
end
function X.Ensure(frame)
    local D=MMF_Designer
    local key=frame.mmfDesignerKey or D.Key(frame.unit)
    local overlay=frame.nameOverlay or frame
    if frame.mmfDesignerExtrasCreated then return end
    local fields={designerLevel="level",designerClassification="classification",designerStatus="status",
        designerLeader="leader",designerRole="role",designerReady="ready",designerResurrection="resurrection",designerPortrait="portrait"}
    if key=="pet" and type(GetPetHappiness)=="function" then
        X.CreateHappiness(frame)
        frame.designerHappiness=frame.petHappinessIcon
    end
    if frame.castBarFrame then fields.designerCastIcon="castIcon";fields.designerCastShield="castShield" end
    for field,id in pairs(fields) do
        local spec=D.catalogByID[id]
        local parent=(id=="castIcon" or id=="castShield") and (frame.castBarTextOverlay or frame.castBarFrame) or overlay
        local object=spec.kind=="text" and X.Text(parent,field,frame,12) or X.Icon(parent,field,frame)
        local cfg=spec.defaults
        object:SetSize(cfg.width,cfg.height)
        object:SetPoint(cfg.point,frame,cfg.relativePoint,cfg.x,cfg.y)
        object:Hide()
    end
    if frame.designerCastShield then X.CastShield(frame.designerCastShield) end
    local oldIcon=frame.classIcon or frame.targetIcon
    if oldIcon then frame.designerPortrait:Hide();frame.designerPortrait=oldIcon end
    if not frame.portraitModel then
        local model=CreateFrame("PlayerModel",nil,overlay)
        model:SetSize(28,28);model:SetPoint("CENTER",frame,"CENTER",-128,0)
        model:SetFrameLevel(overlay:GetFrameLevel()+1);model:EnableMouse(false);model:Hide()
        frame.portraitModel=model;frame.portraitModelUnit=frame.unit
    end
    frame.mmfDesignerExtrasCreated=true
end
function X.Leader(region,state)
    if not region then return end
    region:SetTexture(state=="assistant" and "Interface\\GroupFrame\\UI-Group-AssistantIcon" or "Interface\\GroupFrame\\UI-Group-LeaderIcon")
    region:SetTexCoord(0,1,0,1)
end
function X.Role(region,role)
    if not region then return end
    region:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
    if GetTexCoordsForRoleSmallCircle then
        local a,b,c,d=GetTexCoordsForRoleSmallCircle(role)
        if a then region:SetTexCoord(a,b,c,d);return end
    end
    
    local coords={TANK={0,19/64,22/64,41/64},HEALER={20/64,39/64,1/64,20/64},DAMAGER={20/64,39/64,22/64,41/64}}
    region:SetTexCoord(unpack(coords[role] or coords.DAMAGER))
end
function X.Ready(region,state)
    if not region then return end
    local files={ready="ReadyCheck-Ready",notready="ReadyCheck-NotReady",waiting="ReadyCheck-Waiting"}
    region:SetTexture("Interface\\RaidFrame\\"..(files[state] or files.ready));region:SetTexCoord(0,1,0,1)
end
function X.Resurrection(region)
    if region then region:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez");region:SetTexCoord(0,1,0,1) end
end
function X.CastShield(region)
    if region then region:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield");region:SetTexCoord(0,1,0,1) end
end
function X.RaidMarker(region,index)
    if region then return MMF_FrameFactoryTargetMarkers.ApplyRaidMarkerTexture(region,index) end
end

function X.Happiness(region,happiness)
    if not region then return end
    region:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
    local offsets={[1]=.375,[2]=.1875,[3]=0}
    local left=offsets[happiness] or 0
    local inset=.145 
    region:SetTexCoord(left+.1875*inset,left+.1875*(1-inset),.359375*inset,.359375*(1-inset))
end
function X.CreateHappiness(frame)
    if frame.petHappinessDragFrame then return frame.petHappinessDragFrame end
    local holder=CreateFrame("Frame",nil,frame)
    holder:SetSize(18,18);holder:SetFrameLevel(frame:GetFrameLevel()+40);holder:EnableMouse(false)
    local db=MattMinimalFramesDB or {};local p=db.petFrameHappinessPosition or {}
    holder:SetPoint("CENTER",frame,"CENTER",tonumber(db.petHappinessFrameCenterX) or tonumber(p.x) or -37,
        tonumber(db.petHappinessFrameCenterY) or tonumber(p.y) or 0)
    local icon=holder:CreateTexture(nil,"ARTWORK");icon:SetAllPoints(holder);X.Happiness(icon,3)
    local border=holder:CreateTexture(nil,"BORDER")
    border:SetPoint("TOPLEFT",holder,"TOPLEFT",-1,1);border:SetPoint("BOTTOMRIGHT",holder,"BOTTOMRIGHT",1,-1)
    border:SetColorTexture(0,0,0,1);border.mmfDesignerSolid=true;border.mmfSolidColor={0,0,0,1}
    frame.petHappinessDragFrame,frame.petHappinessIcon,frame.petHappinessBorder=holder,icon,border
    return holder
end
