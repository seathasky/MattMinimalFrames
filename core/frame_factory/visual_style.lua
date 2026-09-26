

local V=MMF_Visuals
local function Solid(region,r,g,b,a)
    if not region then return end
    region.mmfAppliedPowerBackgroundColor=nil
    region.mmfDesignerSolid=true
    region.mmfSolidColor={r,g,b,a or 1}
    region:SetColorTexture(r,g,b,a or 1)
end
V.Solid=Solid
function V.ApplyStyle(frame)
    local db=MattMinimalFramesDB or {}
    local hp=MMF_FrameFactoryHealthPower
    Solid(frame.healthBarBG,hp.GetBackgroundStyle(frame.unit))
    local r,g,b,a=hp.GetBorderStyle(frame.unit)
    for _,edge in pairs(frame.healthBarBorderEdges or {}) do Solid(edge,r,g,b,a) end
    Solid(frame.powerBarBorder,0,0,0,.5)
    Solid(frame.castBarBG,0,0,0,.5)
    Solid(frame.castBarBorder,0,0,0,1)
    Solid(frame.highlightTexture,1,1,1,.2)
    
    
    local useGlobalTexture=MMF_ShouldOverrideBarTextures and MMF_ShouldOverrideBarTextures()
    local texture=useGlobalTexture and MMF_GetStatusBarTexturePath() or nil
    if texture then
        for _,field in ipairs({"healthBar","powerBar","secondaryPowerBar","castBar","myHealPrediction","otherHealPrediction","healAbsorbBar"}) do
            if frame[field] then frame[field]:SetStatusBarTexture(texture) end
        end
    end
    local shared=MMF_UnitVisualStyle
    if shared then shared.HealPrediction(frame);shared.Absorb(frame) end
    for _,field in ipairs({"nameText","hpText","powerText","pvpFlagText","designerLevel","designerClassification","designerStatus"}) do
        if frame[field] and MMF_ApplyGlobalTextShadow then MMF_ApplyGlobalTextShadow(frame[field]) end
    end
    if frame.designerResources then
        local def=MMF_GetResourceVisualDefinition and MMF_GetResourceVisualDefinition()
        for _,segment in ipairs(frame.designerResources.runes or {}) do
            if texture then segment:SetStatusBarTexture(texture) end
            if frame.mmfPreview and def then segment:SetStatusBarColor(unpack(def.color)) end
            Solid(segment.bg,.1,.1,.1,.8)
        end
        Solid(frame.designerResources.bg,0,0,0,.5)
    end
end

function V.ApplySampleColors(frame,sample)
    local shared=MMF_UnitVisualStyle
    local db=MattMinimalFramesDB or {}
    local r,g,b=MMF_GetUnitColor(frame.unit,sample)
    if db.useHealthGradientColor and shared then r,g,b=shared.HealthGradient(sample.health) end
    frame.healthBar:SetStatusBarColor(r or 1,g or 1,b or 1,MMF_GetUnitColorAlpha(frame.unit))
    if shared then
        local nr,ng,nb=shared.NameColor(frame.unit,db,sample)
        frame.nameText:SetTextColor(nr,ng,nb,1)
        local pr,pg,pb,pa=shared.PowerColor(frame.unit,sample.powerType,sample.powerToken,db)
        frame.powerBar:SetStatusBarColor(pr,pg,pb,pa)
        frame.powerBar.mmfAppliedPowerStatusColor=nil
        Solid(frame.powerBarBG,shared.PowerBackground(frame.unit,sample.powerType,sample.powerToken,db))
        if frame.secondaryPowerBar then
            frame.secondaryPowerBar:SetStatusBarColor(shared.PowerColor(frame.unit,0,"MANA",db))
            frame.secondaryPowerBar.mmfAppliedPowerStatusColor=nil
            Solid(frame.secondaryPowerBarBG,shared.PowerBackground(frame.unit,0,"MANA",db))
        end
    end
    if frame.castBar then
        local cr,cg,cb=MMF_Config.GetCastBarColor(db.castBarColor or "yellow")
        if sample.uninterruptible then cr,cg,cb=.7,.7,.7 end
        frame.castBar:SetStatusBarColor(cr,cg,cb,1)
    end
end
