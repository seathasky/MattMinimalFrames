

local V = {}
MMF_Visuals = V

function V.Create(frame, context)
    assert(frame and context, "MMF visuals require an owner and context")
    if frame.mmfVisualContext then return frame end
    frame.mmfVisualContext = context
    frame.mmfPreview = context.mode == "preview"
    local unit = context.unitToken or (MMF_Designer.byUnitType[context.unitKey] or {}).token
    assert(unit, "MMF visual context requires a supported unit")
    frame.unit = unit
    local deps = assert(MMF_FrameFactoryMainDeps, "MMF frame factory is not initialized")
    deps.CreateHealthBar(frame)
    deps.CreatePowerBarContainer(frame, unit)
    deps.CreateHealPredictionBar(frame)
    deps.CreateAbsorbBar(frame)

    frame.highlightOverlay = CreateFrame("Frame", nil, frame)
    frame.highlightOverlay:SetAllPoints(frame)
    frame.highlightOverlay:SetFrameLevel(frame:GetFrameLevel() + 30)
    frame.highlightOverlay:EnableMouse(false)
    frame.highlightTexture = frame.highlightOverlay:CreateTexture(nil,"OVERLAY")
    frame.highlightTexture:SetAllPoints(frame.highlightOverlay)
    frame.highlightTexture:SetColorTexture(1,1,1,.2)
    frame.highlightTexture:Hide()

    deps.CreateNameText(frame,unit)
    deps.CreateResourceText(frame,unit)
    deps.CreatePVPFlagIndicator(frame,unit)
    deps.CreateTargetMarker(frame)
    deps.SetupPowerBar(frame,unit)
    if unit=="player" then
        deps.CreatePlayerClassIcon(frame)
        deps.CreatePlayerIndicators(frame)
    elseif unit=="target" then
        deps.CreateTargetFrameIcon(frame)
    end
    deps.CreateCastBar(frame,unit)
    return frame
end



function V.DisablePreviewInput(frame)
    if not frame or not frame.mmfPreview then return end
    local function visit(object)
        if object.EnableMouse then object:EnableMouse(false) end
        if object.HasScript and object.SetScript then
            for _,script in ipairs({"OnDragStart","OnDragStop","OnMouseDown","OnMouseUp","OnClick","OnEnter","OnLeave"}) do
                if object:HasScript(script) then object:SetScript(script,nil) end
            end
        end
        if object.GetChildren then for _,child in ipairs({object:GetChildren()}) do visit(child) end end
    end
    visit(frame)
end

local function RecordChildLevels(parent)
    for _,child in ipairs({parent:GetChildren()}) do
        child.mmfVisualLevelOffset=child:GetFrameLevel()-parent:GetFrameLevel()
        RecordChildLevels(child)
    end
end
function V.RebasePreview(frame,base)
    frame:SetFrameLevel(base)
    local function visit(parent)
        for _,child in ipairs({parent:GetChildren()}) do
            child:SetFrameLevel(parent:GetFrameLevel()+(child.mmfVisualLevelOffset or 1))
            visit(child)
        end
    end
    visit(frame)
end

function V.CreatePreview(parent,key)
    local D=MMF_Designer
    assert(D.Supports(key), "Unsupported preview unit family")
    local design=D.UnitDesign(key)
    local frame=CreateFrame("Frame",nil,parent)
    frame:SetFrameLevel(parent:GetFrameLevel()+1)
    frame:SetSize(design.width,design.height)
    frame.originalWidth,frame.originalHeight=design.width,design.height
    frame:SetPoint("CENTER",parent,"CENTER",0,0)
    frame.mmfDesignerKey=key
    V.Create(frame,{mode="preview",unitKey=key})
    MMF_ExtraVisuals.Ensure(frame)
    frame.BuffContainer=MMF_AuraVisuals.CreatePreviewContainer(frame,false)
    frame.DebuffContainer=MMF_AuraVisuals.CreatePreviewContainer(frame,true)
    if key=="player" and MMF_CreateResourcePreview then frame.designerResources=MMF_CreateResourcePreview(frame) end
    RecordChildLevels(frame)
    V.DisablePreviewInput(frame)
    return frame
end

function V.Map(frame)
    local D=MMF_Designer
    local nodes={}
    for _,spec in ipairs(D.Catalog(frame.mmfDesignerKey or D.Key(frame.unit),frame)) do
        if spec.field then nodes[spec.id]=D.Resolve(frame,spec.field) end
    end
    frame.mmfDesignerNodes=nodes
    return nodes
end


function V.ApplyLayout(frame,key)
    local D=MMF_Designer
    local design=D.UnitDesign(key)
    local nodes=frame.mmfDesignerNodes or V.Map(frame)
    if frame.mmfPreview then frame:SetSize(design.width,design.height)
    else D.Root(frame,"SetSize",design.width,design.height);D.Root(frame,"SetScale",design.scale) end
    frame.originalWidth,frame.originalHeight=design.width,design.height
    MMF_UnitVisualStyle.TextLayer(frame,(frame.healthBar:GetFrameLevel() or frame:GetFrameLevel())+4)
    for _,spec in ipairs(D.Catalog(key,frame)) do
        local cfg=D.ValidateElement(key,spec.id)
        if nodes[spec.id] and cfg then
            if spec.kind=="auras" then
                local w,h=MMF_AuraVisuals.Dimensions(cfg)
                local layout=D.Copy(cfg);layout.width,layout.height=w,h
                D.ApplyNode(frame,spec.id,nodes[spec.id],layout)
            else D.ApplyNode(frame,spec.id,nodes[spec.id],cfg) end
        end
    end
end

function V.HidePreview(frame)
    if not frame or not frame.mmfPreview then return end
    frame:Hide()
    if frame.restingAnim then frame.restingAnim:Stop() end
    if frame.combatPulseDriver then frame.combatPulseDriver:Hide() end
end
