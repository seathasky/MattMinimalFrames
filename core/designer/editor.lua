


local D = MMF_Designer
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"


local theme = (MMF_GetPopupTheme and MMF_GetPopupTheme()) or {}
local accent = (MMF_GetPopupAccentColor and MMF_GetPopupAccentColor()) or {0.6,0.4,0.9}
local C = {
    bg={0.11,0.12,0.14,1}, panel={0.17,0.185,0.21,1},
    inset={0.075,0.085,0.105,1}, edge={0.40,0.44,0.50,1},
    edgeSoft={0.28,0.31,0.36,1}, accent={accent[1],accent[2],accent[3],1},
    selected={0.23,0.24,0.30,1}, text={0.96,0.97,0.98,1},
    muted={0.77,0.81,0.86,1}, green={0.36,0.85,0.60,1},
    red=theme.danger or {1,0.38,0.38,1}, section=theme.section or {0.62,0.92,0.88,1},
}

local function SafeCreate(kind, name, parent, template)
    if template then
        local ok, frame = pcall(CreateFrame, kind, name, parent, template)
        if ok and frame then return frame end
    end
    return CreateFrame(kind, name, parent)
end

local function ApplyFont(region, size, flags, path)
    if region then D.ApplyFont(region, path or (MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or FONT, size or 12, flags or "") end
end

local function Backdrop(frame, color, border)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({bgFile=WHITE, edgeFile=WHITE, edgeSize=1})
    frame:SetBackdropColor(unpack(color or C.panel))
    frame:SetBackdropBorderColor(unpack(border or C.edge))
end

local function Label(parent, text, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ApplyFont(fs, size or 12)
    fs:SetText(text or "")
    fs:SetTextColor(unpack(color or C.text))
    fs:SetJustifyH("LEFT")
    return fs
end

local function FlatButton(parent, text, width, callback)
    local b = SafeCreate("Button", nil, parent, "BackdropTemplate")
    b.template = false
    b:SetSize(width or 100, 25)
    Backdrop(b, C.panel, C.edge)
    b.label = Label(b, text or "", 11)
    b.label:SetPoint("LEFT", 8, 0)
    b.label:SetPoint("RIGHT", -8, 0)
    b.label:SetJustifyH("CENTER")
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(self.active and C.accent or C.edge)) end)
    b:SetScript("OnClick", function(self, button) if self.action then self.action(self, button) end end)
    b.action = callback
    function b:SetLabel(value) self.label:SetText(value or "") end
    function b:SetActive(active)
        self.active = active == true
        Backdrop(self, self.active and C.selected or C.panel, self.active and C.accent or C.edge)
    end
    return b
end


local function Button(parent,text,width,callback) return FlatButton(parent,text,width,callback) end
local function DangerButton(parent,text,width,callback)
    local button=Button(parent,text,width,callback)
    local function Paint(hover)
        Backdrop(button,hover and {.65,.08,.08,1} or {.38,.035,.035,1},{1,.25,.20,1})
    end
    ApplyFont(button.label,10,"OUTLINE")
    button.label:SetTextColor(1,.9,.85,1)
    button:SetScript("OnEnter",function() Paint(true) end)
    button:SetScript("OnLeave",function() Paint(false) end)
    Paint(false)
    return button
end

local function Tab(parent,text,width,callback)
    local b=FlatButton(parent,text,width,callback)
    b.line=b:CreateTexture(nil,"OVERLAY");b.line:SetColorTexture(unpack(C.accent))
    b.line:SetHeight(2);b.line:SetPoint("BOTTOMLEFT",3,0);b.line:SetPoint("BOTTOMRIGHT",-3,0)
    function b:SetActive(active)
        self.active=active==true
        Backdrop(self,self.active and C.selected or C.bg,C.edgeSoft)
        self.line:SetShown(self.active)
        self.label:SetTextColor(unpack(self.active and C.text or C.muted))
    end
    b:SetActive(false);return b
end

local function Tooltip(frame, title, body)
    frame:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "Matt's Minimal Frames", 1,1,1)
        if body and GameTooltip.AddLine then GameTooltip:AddLine(body, .78,.80,.84, true) end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

local function EditBox(parent, width)
    local e = SafeCreate("EditBox", nil, parent, "BackdropTemplate")
    Backdrop(e, C.inset, C.edgeSoft)
    e:SetSize(width or 70, 22)
    e:SetAutoFocus(false)
    ApplyFont(e, 11)
    if e.SetTextInsets then e:SetTextInsets(5,5,0,0) end
    e:SetScript("OnEscapePressed", function(self)
        self:SetText(self.previous or "")
        self:ClearFocus()
    end)
    return e
end

local function Check(parent, text, callback)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(28)
    holder.check = SafeCreate("CheckButton", nil, holder, "BackdropTemplate")
    holder.check:SetSize(18,18)
    Backdrop(holder.check,C.inset,C.edge)
    local mark=holder.check:CreateTexture(nil,"ARTWORK")
    mark:SetPoint("TOPLEFT",4,-4);mark:SetPoint("BOTTOMRIGHT",-4,4)
    mark:SetColorTexture(unpack(C.accent));holder.check:SetCheckedTexture(mark)
    holder.check:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
    holder.check:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.edge)) end)
    holder.check:SetPoint("LEFT", 0, 0)
    holder.label = Label(holder, text or "", 11)
    holder.label:SetPoint("LEFT", holder.check, "RIGHT", 8, 0)
    holder.label:SetPoint("RIGHT", 0, 0)
    holder.check:SetScript("OnClick", function(self)
        if holder.action then holder.action(self:GetChecked() == true) end
    end)
    holder:SetScript("OnMouseUp", function() holder.check:Click() end)
    holder.action = callback
    function holder:SetValue(value) self.check:SetChecked(value == true) end
    function holder:SetLabel(value) self.label:SetText(value or "") end
    return holder
end

local function Scroll(parent)
    local scroll = SafeCreate("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local bar=scroll.ScrollBar
    if bar then
        for _,region in ipairs({bar:GetRegions()}) do
            if region:GetObjectType()=="Texture" then region:SetAlpha(0) end
        end
        local thumb=bar:GetThumbTexture()
        if thumb then thumb:SetTexture(WHITE);thumb:SetVertexColor(unpack(C.accent));thumb:SetSize(7,24);thumb:SetAlpha(1) end
        for _,entry in ipairs({{bar.ScrollUpButton or scroll.ScrollUpButton,"^"},{bar.ScrollDownButton or scroll.ScrollDownButton,"v"}}) do
            local button=entry[1]
            if button then
                for _,method in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetDisabledTexture"}) do
                    local texture=button[method] and button[method](button)
                    if texture then texture:SetAlpha(0) end
                end
                local label=Label(button,entry[2],10,C.muted);label:SetPoint("CENTER")
            end
        end
    end
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1,1)
    scroll:SetScrollChild(child)
    return scroll, child
end



local menu
local function HideMenu() if menu then menu:Hide() end end
local function Menu(anchor, entries, callback, width)
    if not menu then
        menu = SafeCreate("Frame", "MMFDesignerMenu", UIParent, "BackdropTemplate")
        Backdrop(menu, C.bg, C.edge)
        menu:SetFrameStrata("TOOLTIP")
        menu:EnableMouse(true)
        menu.scroll, menu.child = Scroll(menu)
        menu.scroll:SetPoint("TOPLEFT", 6, -6)
        menu.scroll:SetPoint("BOTTOMRIGHT", -24, 6)
        local function ScrollTo(value)
            local limit=math.max(0,menu.child:GetHeight()-menu.scroll:GetHeight())
            local offset=math.max(0,math.min(limit,value))
            menu.scroll:SetVerticalScroll(offset)
            local bar=menu.scroll.ScrollBar
            if bar and bar:GetValue()~=offset then bar:SetValue(offset) end
        end
        local function ScrollWheel(_,delta)
            menu.mouseAwayElapsed=0
            ScrollTo(menu.scroll:GetVerticalScroll()-delta*54)
        end
        menu.scrollWheel=ScrollWheel
        menu:EnableMouseWheel(true);menu:SetScript("OnMouseWheel",ScrollWheel)
        menu.scroll:EnableMouseWheel(true);menu.scroll:SetScript("OnMouseWheel",ScrollWheel)
        local bar=menu.scroll.ScrollBar
        if bar then
            bar:SetScript("OnValueChanged",function(_,value) ScrollTo(value) end)
            local up=bar.ScrollUpButton or menu.scroll.ScrollUpButton
            local down=bar.ScrollDownButton or menu.scroll.ScrollDownButton
            if up then up:SetScript("OnClick",function() ScrollTo(menu.scroll:GetVerticalScroll()-27) end) end
            if down then down:SetScript("OnClick",function() ScrollTo(menu.scroll:GetVerticalScroll()+27) end) end
        end
        menu.rows = {}
        menu:Hide()
        menu:SetScript("OnHide", function(self)
            self.callback=nil
            self.anchor=nil
            self.mouseAwayElapsed=0
        end)
        menu:SetScript("OnUpdate", function(self, elapsed)
            if (self.anchor and self.anchor:IsMouseOver()) or self:IsMouseOver() then
                self.mouseAwayElapsed=0
                return
            end
            self.mouseAwayElapsed=(self.mouseAwayElapsed or 0)+(elapsed or 0)
            if self.mouseAwayElapsed>=0.15 then self:Hide() end
        end)
    end
    menu:Hide()
    menu.callback = callback
    menu.anchor = anchor
    menu.mouseAwayElapsed = 0
    width = width or 310
    local height = math.min(500, math.max(44, #entries*27+12))
    menu:SetSize(width, height)
    menu.child:SetWidth(width-30)
    menu.child:SetHeight(math.max(1,#entries*27))
    if menu.scroll.SetVerticalScroll then menu.scroll:SetVerticalScroll(0) end
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)
    menu:SetClampedToScreen(true)
    for index, entry in ipairs(entries) do
        if type(entry) ~= "table" then entry={label=tostring(entry), value=entry} end
        local row = menu.rows[index]
        if not row then
            row = FlatButton(menu.child, "", width-32)
            row:SetHeight(26)
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel",menu.scrollWheel)
            row.label:SetJustifyH("LEFT")
            row.icon = row:CreateTexture(nil,"ARTWORK")
            row.icon:SetSize(18,18)
            row.icon:SetPoint("LEFT",4,0)
            row.check = Label(row,"",12,C.green)
            row.check:SetWidth(15)
            row.check:SetJustifyH("CENTER")
            row.check:SetPoint("RIGHT",-4,0)
            menu.rows[index]=row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index-1)*27)
        row:SetWidth(width-32)
        row:Show()
        row.icon:Hide()
        row.check:SetText(entry.checked and "x" or "")
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", entry.texture and 27 or 8, 0)
        row.label:SetPoint("RIGHT", -22, 0)
        row.label:SetText(entry.label or tostring(entry.value))
        ApplyFont(row.label, entry.header and 10 or 11, "", entry.font or FONT)
        if entry.texture then row.icon:SetTexture(entry.texture);row.icon:Show() end
        if entry.header then
            row:SetActive(false)
            Backdrop(row,C.inset,C.edgeSoft)
            row.label:SetTextColor(unpack(C.muted))
            row.action=nil
        else
            row.label:SetTextColor(entry.disabled and .48 or .95,entry.disabled and .49 or .95,entry.disabled and .52 or .98,1)
            Backdrop(row,C.panel,C.edgeSoft)
            local value = entry.value
            local selectedEntry = entry
            local disabled = entry.disabled == true
            row.action=function()
                if disabled then return end
                local fn=menu.callback
                menu:Hide()
                if fn then fn(value,selectedEntry) end
            end
        end
    end
    for i=#entries+1,#menu.rows do menu.rows[i]:Hide() end
    menu:Show()
    local bar=menu.scroll.ScrollBar
    if bar then
        local limit=math.max(0,menu.child:GetHeight()-menu.scroll:GetHeight())
        bar:SetMinMaxValues(0,limit);bar:SetValue(0)
        bar:SetShown(limit>0)
    end
end
D.HideDesignerMenu = HideMenu

local function MediaEntries(kind, current)
    local list={}
    if kind=="font" then
        local bundled={
            {label="MMF Naowh",value="Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"},
            {label="MMF Minimalistic",value="Interface\\AddOns\\MattMinimalFrames\\Fonts\\Minimalistic.ttf"},
            {label="MMF Championship",value="Interface\\AddOns\\MattMinimalFrames\\Fonts\\Championship.ttf"},
        }
        list[#list+1]={label="MMF fonts",header=true}
        for _,entry in ipairs(bundled) do
            local available = not MMF_IsFontPathUsable or MMF_IsFontPathUsable(entry.value)
            list[#list+1]={label=entry.label..(available and "" or " (not installed)"),value=entry.value,font=available and entry.value or FONT,disabled=not available}
        end
        list[#list+1]={label="Game default",value=MMF_GetDefaultFontPath(),font=MMF_GetDefaultFontPath()}
    else
        list[#list+1]={label="MMF and SharedMedia textures",header=true}
    end
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if lsm then
        local hash=lsm:HashTable(kind) or {}
        local names={}
        for name in pairs(hash) do names[#names+1]=name end
        table.sort(names,function(a,b) return tostring(a):lower()<tostring(b):lower() end)
        local seen={}
        for _,entry in ipairs(list) do if entry.value then seen[tostring(entry.value):lower()]=true end end
        for _,name in ipairs(names) do
            local value=hash[name]
            if not seen[tostring(value):lower()] then
                list[#list+1]={label=name,value=value,font=kind=="font" and value or nil,texture=kind=="statusbar" and value or nil}
            end
        end
    end
    if current then
        local found=false
        for _,entry in ipairs(list) do if entry.value==current then found=true break end end
        if not found then list[#list+1]={label="Current selection",value=current,font=kind=="font" and current or nil,texture=kind=="statusbar" and current or nil} end
    end
    return list
end

local function MediaName(kind,value)
    if not value or value=="" then return kind=="font" and "Default font" or "Default texture" end
    local normalized=tostring(value):gsub("/","\\"):lower()
    local known={
        ["interface\\addons\\mattminimalframes\\fonts\\naowh.ttf"]="MMF Naowh",
        ["interface\\addons\\mattminimalframes\\fonts\\minimalistic.ttf"]="MMF Minimalistic",
        ["interface\\addons\\mattminimalframes\\fonts\\championship.ttf"]="MMF Championship",
    }
    if known[normalized] then return known[normalized] end
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if lsm then for name,path in pairs(lsm:HashTable(kind) or {}) do if path==value then return name end end end
    return value==MMF_GetDefaultFontPath() and "Game default" or tostring(value):match("([^\\/]+)$") or tostring(value)
end

local function CanEdit()
    if InCombatLockdown() then D.Notify("Leave combat before changing the designer.");return false end
    return D.ready==true
end

local function PushCommitHistory(key)
    if D.liveSliderDrag then
        if D.liveSliderHistoryPushed then return end
        D.liveSliderHistoryPushed=true
    end
    D.PushHistory(key)
end

local function RefreshAfterCommit(noRefresh)
    if noRefresh then return end
    if D.liveSliderDrag then
        
        
        D.RefreshPreview()
    else
        D.RefreshDesigner()
    end
end

local function Commit(key,id,property,value,noRefresh)
    if not CanEdit() then return end
    PushCommitHistory(key)
    local cfg=id=="frame" and D.UnitDesign(key) or D.ElementDesign(key,id)
    if not cfg then return end
    if property=="relativeTo" then
        if not D.SetParent(key,id,value) then D.Notify("That attachment would create a loop.");return end
    else cfg[property]=value end
    if property=="width" or property=="height" then cfg.fitTextToContent=nil end
    D.ApplyUnit(key)
    RefreshAfterCommit(noRefresh)
end

local function CommitMany(key,changes)
    if not CanEdit() then return end
    PushCommitHistory(key)
    for _,change in ipairs(changes) do
        local id,property,value=change[1],change[2],change[3]
        local cfg=id=="frame" and D.UnitDesign(key) or D.ElementDesign(key,id)
        if cfg then
            if property=="relativeTo" then D.SetParent(key,id,value) else cfg[property]=value end
            if property=="width" or property=="height" then cfg.fitTextToContent=nil end
        end
    end
    D.ApplyUnit(key)
    RefreshAfterCommit(false)
end
D.CommitDesignerValue=Commit

local function SetLegacy(key,value)
    if MattMinimalFramesDB then MattMinimalFramesDB[key]=value end
end
local function ResourceVisibilitySetting()
    local _,class=UnitClass("player")
    local byClass={DEATHKNIGHT="showRuneBar",PALADIN="showHolyPowerBar",ROGUE="showComboPointBar",DRUID="showComboPointBar",
        WARLOCK="showSoulShardBar",MONK="showChiBar",MAGE="showArcaneChargeBar",EVOKER="showEssenceBar",SHAMAN="showMaelstromBar"}
    return byClass[class]
end
local function SyncLegacyVisibility(key,id,value)
    local owner=D.FriendlyOwner(id)
    local cap=key:sub(1,1):upper()..key:sub(2)
    if owner=="power" and (key=="player" or key=="target") then SetLegacy("show"..cap.."PowerBar",value)
    elseif owner=="powerText" and (key=="player" or key=="target") then SetLegacy("show"..cap.."PowerText",value)
    elseif owner=="cast" then
        local map={player="showPlayerCastBar",target="showTargetCastBar",focus="showFocusCastBar",boss="showBossCastBar"}
        if map[key] then SetLegacy(map[key],value) end
    elseif owner=="buffs" or owner=="debuffs" then
        local title=owner=="buffs" and "Buffs" or "Debuffs"
        local setting=key=="target" and ("show"..title) or ("show"..cap..title)
        if MattMinimalFrames_Defaults and MattMinimalFrames_Defaults[setting]~=nil then SetLegacy(setting,value) end
    elseif owner=="combat" then SetLegacy("hideCombatIcon",not value)
    elseif owner=="resting" then SetLegacy("hideRestingIcon",not value)
    elseif owner=="raidMarker" then SetLegacy("showTargetMarkers",value)
    elseif owner=="classification" and key=="target" then SetLegacy("showTargetClassification",value)
    elseif owner=="leader" and key=="player" then SetLegacy("showLeaderIcons",value)
    elseif owner=="pvp" then SetLegacy("showPVPFlagIndicator",value);SetLegacy("showTBCPVPFlagIndicator",value)
    elseif owner=="portrait" and (key=="player" or key=="target") then
        local cfg=D.ElementDesign(key,"portrait")
        SetLegacy(key.."FrameIconMode",value and ((cfg and cfg.iconMode) or "class") or "off")
        SetLegacy(key=="player" and "showPlayerClassIcon" or "showTargetFrameIcon",value)
    elseif owner=="myHeal" or owner=="otherHeal" then
        local other=owner=="myHeal" and "otherHeal" or "myHeal"
        local otherCfg=D.ElementDesign(key,other)
        SetLegacy("showHealPrediction",value or (otherCfg and otherCfg.enabled~=false) or false)
    elseif owner=="absorb" then SetLegacy("showAbsorbBar",value)
    elseif owner=="healAbsorb" then SetLegacy("showHealAbsorbBar",value)
    elseif owner=="dispel" and key=="player" then SetLegacy("showPlayerDispelHighlight",value)
    elseif owner=="dispel" and key=="target" then SetLegacy("showTargetDispelHighlight",value)
    elseif owner=="combatOutline.top" then SetLegacy("combatFrameOutline",value)
    elseif owner=="resources" and key=="player" then local setting=ResourceVisibilitySetting();if setting then SetLegacy(setting,value) end end
end
local function SetComponentEnabled(key,id,value)
    if not CanEdit() then return end
    SyncLegacyVisibility(key,id,value)
    local classResource=key=="player" and D.FriendlyOwner(id)=="resources"
    if classResource and value and MMF_InitializeClassResources then
        MMF_InitializeClassResources()
    end
    local component=D.friendlyByID and D.friendlyByID[D.FriendlyOwner(id)]
    if component and component.toggleAll then
        local changes={}
        for _,member in ipairs(component.members) do if D.catalogByID[member] then changes[#changes+1]={member,"enabled",value} end end
        CommitMany(key,changes)
    else Commit(key,id,"enabled",value) end
    if classResource and MMF_RefreshClassResourceVisibility then MMF_RefreshClassResourceVisibility() end
end
D.SetDesignerElementEnabled=SetComponentEnabled

function D.FriendlySizeChanges(key,id,width,height)
    width=D.Number(width,20,1,2000);height=D.Number(height,20,1,2000)
    local changes={{id,"width",width},{id,"height",height}}
    if id=="frame" then
        local unit=D.UnitDesign(key)
        local sx,sy=width/math.max(1,unit.width),height/math.max(1,unit.height)
        
        
        for _,entry in ipairs(D.Catalog(key)) do
            if entry.kind=="text" then D.TextLayout(key,entry.id,D.ElementDesign(key,entry.id)) end
        end
        for _,entry in ipairs(D.Catalog(key)) do
            local child=D.ElementDesign(key,entry.id)
            if entry.kind~="text" and entry.kind~="auraText" then
                for _,axis in ipairs({{"width",sx},{"height",sy},{"x",sx},{"y",sy}}) do
                    local field,factor=axis[1],axis[2]
                    if type(child[field])=="number" then
                        changes[#changes+1]={entry.id,field,child[field]*factor}
                    end
                end
            end
        end
        return changes
    end
    local spec=D.catalogByID[id]
    if spec and spec.auraSub and spec.kind~="auraText" then
        changes[#changes+1]={id,"fitIcon",false}
    end
    if id=="health" then
        changes[#changes+1]={"healthBackground","width",width};changes[#changes+1]={"healthBackground","height",height}
        changes[#changes+1]={"healthBorder","width",width+2};changes[#changes+1]={"healthBorder","height",height+2}
        for _,edge in ipairs({"top","bottom"}) do changes[#changes+1]={"healthBorder."..edge,"width",width+2} end
        for _,edge in ipairs({"left","right"}) do changes[#changes+1]={"healthBorder."..edge,"height",height} end
        for _,overlay in ipairs({"hover","dispel"}) do if D.catalogByID[overlay] then changes[#changes+1]={overlay,"width",width};changes[#changes+1]={overlay,"height",height} end end
    elseif id=="power" then
        changes[#changes+1]={"powerFill","width",math.max(1,width-2)};changes[#changes+1]={"powerFill","height",math.max(1,height-2)}
        changes[#changes+1]={"powerBackground","width",math.max(1,width-2)};changes[#changes+1]={"powerBackground","height",math.max(1,height-2)}
        changes[#changes+1]={"powerBorder","width",width};changes[#changes+1]={"powerBorder","height",height}
    elseif id=="cast" then
        changes[#changes+1]={"castFill","width",math.max(1,width-2)};changes[#changes+1]={"castFill","height",math.max(1,height-2)}
        changes[#changes+1]={"castBackground","width",math.max(1,width-2)};changes[#changes+1]={"castBackground","height",math.max(1,height-2)}
        changes[#changes+1]={"castBorder","width",width};changes[#changes+1]={"castBorder","height",height}
    elseif id=="portrait" then
        changes[#changes+1]={"portraitModel","width",width};changes[#changes+1]={"portraitModel","height",height}
    elseif id=="resources" then
        local cfg=D.ElementDesign(key,id)
        local sx,sy=width/math.max(1,cfg.width),height/math.max(1,cfg.height)
        for _,entry in ipairs(D.Catalog(key)) do
            if entry.id~=id and entry.id:match("^resource") and entry.kind~="text" then
                local child=D.ElementDesign(key,entry.id)
                changes[#changes+1]={entry.id,"width",D.Number(child.width*sx,1,1,2000)}
                changes[#changes+1]={entry.id,"height",D.Number(child.height*sy,1,1,2000)}
                if child.relativeTo==id or (child.relativeTo and child.relativeTo:match("^resource%d")) then
                    changes[#changes+1]={entry.id,"x",(child.x or 0)*sx}
                    changes[#changes+1]={entry.id,"y",(child.y or 0)*sy}
                end
            end
        end
    end
    return changes
end
local function ResizeComponent(key,id,width,height) CommitMany(key,D.FriendlySizeChanges(key,id,width,height)) end
local function MoveComponent(key,id,x,y)
    local changes=D.FriendlyMoveChanges and D.FriendlyMoveChanges(key,id,x,y) or {{id,"x",x},{id,"y",y}}
    CommitMany(key,changes)
end
local function HealthBorderThickness(key,value)
    value=D.Number(value,1,0,12)
    local health=D.ElementDesign(key,"health");local width=health.width;local height=health.height
    local changes={{"healthBorder","width",width+2*value},{"healthBorder","height",height+2*value}}
    for _,edge in ipairs({"top","bottom"}) do changes[#changes+1]={"healthBorder."..edge,"width",width+2*value};changes[#changes+1]={"healthBorder."..edge,"height",value} end
    for _,edge in ipairs({"left","right"}) do changes[#changes+1]={"healthBorder."..edge,"width",value};changes[#changes+1]={"healthBorder."..edge,"height",height} end
    changes[#changes+1]={"healthBorder.top","y",(height+value)/2};changes[#changes+1]={"healthBorder.bottom","y",-(height+value)/2}
    changes[#changes+1]={"healthBorder.left","x",-(width+value)/2};changes[#changes+1]={"healthBorder.right","x",(width+value)/2}
    CommitMany(key,changes)
end

local function CopyTargetsFor(id,currentKey)
    local entries={}
    for _,entry in ipairs(D.unitTypes) do
        if entry.key~=currentKey and D.Supports(entry.key) then
            local frame=D.Representative(entry.key);local available={frame=true}
            for _,spec in ipairs(D.Catalog(entry.key,frame)) do available[spec.id]=true end
            local members=id=="frame" and {"frame"} or D.ComponentMembers(id)
            local compatible=id=="frame"
            if id~="frame" then for _,member in ipairs(members) do if available[member] then compatible=true break end end end
            if compatible then entries[#entries+1]={label=entry.label,value=entry.key} end
        end
    end
    return entries
end
local function CopySelectedTo(sourceKey,id,destinationKey)
    if id=="frame" then return D.CopyDesign(sourceKey,destinationKey) end
    local sourceUnit=D.UnitDesign(sourceKey);local destination=D.UnitDesign(destinationKey)
    if not sourceUnit or not destination then return false end
    local frame=D.Representative(destinationKey);local available={}
    for _,spec in ipairs(D.Catalog(destinationKey,frame)) do available[spec.id]=true end
    D.PushHistory(destinationKey)
    local copied=false
    for _,member in ipairs(D.ComponentMembers(id)) do
        if available[member] and sourceUnit.elements[member] then destination.elements[member]=D.Copy(sourceUnit.elements[member]);copied=true end
    end
    if copied then D.ApplyUnit(destinationKey) end
    return copied
end
local function OpenCopyMenu(button,key,id)
    local entries=CopyTargetsFor(id,key)
    if #entries==0 then D.Notify("There are no compatible frames to copy this to.");return end
    Menu(button,entries,function(destination)
        if CopySelectedTo(key,id,destination) then D.Notify(D.FriendlyLabel(id).." copied to "..D.byUnitType[destination].label..".") end
        D.RefreshDesigner()
    end)
end
local function ResetSelected(key,id)
    if id=="frame" then
        D.Confirm("Reset this frame design to its saved starting layout? Its screen position will stay where it is.",function() D.ResetDesign(key);D.RefreshDesigner() end)
    else
        D.Confirm("Reset "..D.FriendlyLabel(id).."? Everything else will stay exactly as it is.",function()
            local members=D.ComponentMembers(id);D.PushHistory(key);local unit=D.UnitDesign(key)
            for _,member in ipairs(members) do
                local baseline=unit.baseline and unit.baseline.elements and unit.baseline.elements[member]
                if D.catalogByID[member] then unit.elements[member]=D.Copy(baseline or D.catalogByID[member].defaults) end
            end
            D.ApplyUnit(key);D.RefreshDesigner()
        end)
    end
end


local function ResetForm(pane)
    pane.cursor=-8;pane.used={};pane.pool=pane.pool or {}
    for _,pool in pairs(pane.pool) do for _,object in ipairs(pool) do object:Hide() end end
    return pane
end
local function Use(pane,kind,factory)
    pane.used[kind]=(pane.used[kind] or 0)+1;local index=pane.used[kind]
    pane.pool[kind]=pane.pool[kind] or {}
    local object=pane.pool[kind][index]
    if not object then object=factory();pane.pool[kind][index]=object end
    object:ClearAllPoints();object:Show();return object
end
local function Place(pane,object,height)
    object:SetPoint("TOPLEFT",8,pane.cursor);object:SetPoint("RIGHT",-8,0)
    pane.cursor=pane.cursor-height
end
local function Section(pane,text,help)
    local f=Use(pane,"section",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(31)
        x.line=x:CreateTexture(nil,"BACKGROUND");x.line:SetColorTexture(unpack(C.edgeSoft));x.line:SetHeight(1);x.line:SetPoint("BOTTOMLEFT",0,2);x.line:SetPoint("BOTTOMRIGHT",0,2)
        x.title=Label(x,"",14,C.section);x.title:SetPoint("LEFT",2,3)
        x.help=Label(x,"",10,C.muted);x.help:SetPoint("RIGHT",-2,3)
        return x
    end)
    f.title:SetText(text or "");f.help:SetText(help or "");Place(pane,f,34)
end
local function Note(pane,text)
    local f=Use(pane,"note",function() local x=Label(pane,"",10,C.muted);x:SetWordWrap(true);return x end)
    f:SetText(text or "");local h=math.max(26,(f.GetStringHeight and f:GetStringHeight() or 15)+10);f:SetHeight(h);Place(pane,f,h)
end
local function ToggleRow(pane,title,value,action,help)
    local f=Use(pane,"toggle",function()
        local x=Check(pane,"",nil);x:SetHeight(30);return x
    end)
    f:SetLabel(title);f:SetValue(value);f.action=action
    if help then Tooltip(f,title,help) end
    Place(pane,f,32)
end
local function ButtonRow(pane,title,action,help)
    local f=Use(pane,"button",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(31);x.button=Button(x,"",250);x.button:SetPoint("LEFT",190,0);return x
    end)
    f.button:SetLabel(title);f.button.action=action
    if help then Tooltip(f.button,title,help) end
    Place(pane,f,34)
end
local function DualButtonRow(pane,leftText,leftAction,rightText,rightAction)
    local f=Use(pane,"dual",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(31);x.left=Button(x,"",190);x.right=Button(x,"",190);x.left:SetPoint("LEFT",190,0);x.right:SetPoint("LEFT",x.left,"RIGHT",8,0);return x
    end)
    f.left:SetLabel(leftText);f.left.action=leftAction;f.right:SetLabel(rightText);f.right.action=rightAction;Place(pane,f,34)
end
local function NumberRow(pane,title,value,minv,maxv,step,action,suffix)
    local f=Use(pane,"number",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(42)
        x.label=Label(x,"",11);x.label:SetPoint("LEFT",2,0);x.label:SetWidth(180)
        x.minus=Button(x,"-",28);x.minus:SetPoint("LEFT",190,0)
        x.edit=EditBox(x,90);x.edit:SetPoint("LEFT",x.minus,"RIGHT",5,0)
        x.plus=Button(x,"+",28);x.plus:SetPoint("LEFT",x.edit,"RIGHT",5,0)
        x.suffix=Label(x,"",10,C.muted);x.suffix:SetPoint("LEFT",x.plus,"RIGHT",8,0)
        return x
    end)
    step=step or 1;f.label:SetText(title or "");f.suffix:SetText(suffix or "")
    local display=D.FormatNumber(value,step<1 and 1 or 0);f.edit.previous=display;f.edit:SetText(display);if f.edit.SetCursorPosition then f.edit:SetCursorPosition(0) end
    local function Apply(value2) action(D.Number(value2,value,minv,maxv)) end
    f.minus.action=function() Apply((tonumber(f.edit:GetText()) or value)-step) end
    f.plus.action=function() Apply((tonumber(f.edit:GetText()) or value)+step) end
    f.edit:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    f.edit:SetScript("OnEditFocusLost",function(self)
        if self:GetText()==self.previous then return end
        local n=tonumber(self:GetText());if not n then self:SetText(self.previous);return end;Apply(n)
    end)
    Place(pane,f,44)
end
local function SliderRow(pane,title,value,minv,maxv,step,action,formatter)
    local f=Use(pane,"slider",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(44)
        x.label=Label(x,"",11);x.label:SetPoint("LEFT",2,0);x.label:SetWidth(180)
        x.slider=SafeCreate("Slider",nil,x);x.slider:SetOrientation("HORIZONTAL")
        local track=x.slider:CreateTexture(nil,"BACKGROUND");track:SetPoint("LEFT");track:SetPoint("RIGHT");track:SetHeight(4);track:SetColorTexture(unpack(C.edgeSoft))
        local thumb=x.slider:CreateTexture(nil,"OVERLAY");thumb:SetSize(10,16);thumb:SetColorTexture(unpack(C.accent));x.slider:SetThumbTexture(thumb)
        x.slider:SetPoint("LEFT",190,0);x.slider:SetWidth(285);x.slider:SetHeight(24);x.slider:EnableMouse(true)
        x.value=Label(x,"",10,C.muted);x.value:SetPoint("LEFT",x.slider,"RIGHT",12,0);x.value:SetWidth(72);x.value:SetJustifyH("RIGHT")
        
        x.slider:EnableMouse(false)
        x.input=CreateFrame("Frame",nil,x.slider)
        x.input:SetAllPoints(x.slider);x.input:SetFrameLevel(x.slider:GetFrameLevel()+5)
        x.input:EnableMouse(true)
        return x
    end)
    f.label:SetText(title or "");f.slider.updating=true
    f.slider:SetMinMaxValues(minv,maxv);if f.slider.SetValueStep then f.slider:SetValueStep(step or 1) end;if f.slider.SetObeyStepOnDrag then f.slider:SetObeyStepOnDrag(true) end
    f.slider:SetValue(D.Number(value,minv,minv,maxv));f.slider.updating=false
    f.value:SetText(formatter and formatter(value) or D.FormatNumber(value,step and step<1 and 1 or 0))
    local pendingValue,lastApplied,lastUpdate=nil,value,0
    local function FlushValue()
        local nextValue=pendingValue;pendingValue=nil
        if nextValue~=nil and nextValue~=lastApplied then
            lastApplied=nextValue;lastUpdate=GetTime();action(nextValue)
        end
    end
    f.slider:SetScript("OnValueChanged",function(self,newValue)
        if self.updating then return end
        newValue=D.Round(newValue,step or 1);f.value:SetText(formatter and formatter(newValue) or D.FormatNumber(newValue,step and step<1 and 1 or 0))
        pendingValue=newValue
        if not D.liveSliderDrag or GetTime()-lastUpdate>=.033 then FlushValue() end
    end)
    local function UpdateDrag(self)
        if not self.dragging or InCombatLockdown() then return end
        local slider=f.slider
        local scale=slider:GetEffectiveScale()
        local cursor=GetCursorPosition()/scale
        local thumb=slider:GetThumbTexture()
        local half=thumb and thumb:GetWidth()/2 or 0
        local start=slider:GetLeft()+half
        local span=math.max(1,slider:GetWidth()-2*half)
        local fraction=math.max(0,math.min(1,(cursor-start-(self.grabOffset or 0))/span))
        local low,high=slider:GetMinMaxValues()
        slider:SetValue(math.max(low,math.min(high,D.Round(low+fraction*(high-low),step or 1))))
    end
    local function FinishDrag(self,refresh)
        if not self.dragging then return end
        self.dragging=nil;self.grabOffset=nil
        FlushValue()
        D.liveSliderDrag=nil;D.liveSliderHistoryPushed=nil
        if D.FlushSharedSettings then D.FlushSharedSettings() end
        if refresh then
            if D.mainTab=="Settings" and D.RefreshSettings then D.RefreshSettings()
            else D.RefreshDesigner() end
        end
    end
    f.input:SetScript("OnMouseDown",function(self,button)
        if button~="LeftButton" or not CanEdit() then return end
        D.liveSliderDrag=true;D.liveSliderHistoryPushed=false;self.dragging=true
        local cursor=GetCursorPosition()/f.slider:GetEffectiveScale()
        local thumb=f.slider:GetThumbTexture()
        local center=thumb and thumb:GetCenter()
        self.grabOffset=center and math.abs(cursor-center)<=thumb:GetWidth()/2+3 and cursor-center or 0
        UpdateDrag(self)
    end)
    f.input:SetScript("OnUpdate",function(self)
        if not self.dragging then return end
        if InCombatLockdown() then FinishDrag(self,false);return end
        if not IsMouseButtonDown("LeftButton") then FinishDrag(self,true);return end
        UpdateDrag(self)
        if pendingValue~=nil and GetTime()-lastUpdate>=.033 then FlushValue() end
    end)
    f.input:SetScript("OnMouseUp",function(self,button)
        if button=="LeftButton" then UpdateDrag(self);FinishDrag(self,true) end
    end)
    f.input:SetScript("OnHide",function(self) FinishDrag(self,false) end)
    Place(pane,f,46)
end
local function DropdownRow(pane,title,value,entries,action,display)
    local f=Use(pane,"dropdown",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(37);x.label=Label(x,"",11);x.label:SetPoint("LEFT",2,0);x.label:SetWidth(180);x.button=Button(x,"",350);x.button:SetPoint("LEFT",190,0);return x
    end)
    f.label:SetText(title or "")
    local shown=display or tostring(value or "Default")
    if not display then for _,entry in ipairs(entries) do if entry.value==value then shown=entry.label break end end end
    f.button:SetLabel(shown.."  v")
    f.button.action=function(self) Menu(self,entries,action,360) end
    Place(pane,f,39)
end
local function ColorRow(pane,title,key,ids,allowAutomatic)
    if type(ids)=="string" then ids={ids} end
    local cfg=D.ElementDesign(key,ids[1]);if not cfg then return end
    local f=Use(pane,"color",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(37);x.label=Label(x,"",11);x.label:SetPoint("LEFT",2,0);x.label:SetWidth(180)
        x.swatch=SafeCreate("Button",nil,x,"BackdropTemplate");x.swatch:SetPoint("LEFT",190,0);x.swatch:SetSize(24,24)
        Backdrop(x.swatch,C.inset,C.edge)
        local fill=x.swatch:CreateTexture(nil,"ARTWORK");fill:SetPoint("TOPLEFT",4,-4);fill:SetPoint("BOTTOMRIGHT",-4,4)
        function x.swatch:SetColorRGB(r,g,b) fill:SetColorTexture(r,g,b,1) end
        x.mode=Button(x,"",180);x.mode:SetPoint("LEFT",x.swatch,"RIGHT",10,0);return x
    end)
    f.label:SetText(title or "")
    local color=cfg.color or {1,1,1,1};if f.swatch.SetColorRGB then f.swatch:SetColorRGB(color[1] or 1,color[2] or 1,color[3] or 1) end
    local function ApplyColor(r,g,b)
        D.PushHistory(key)
        for _,id in ipairs(ids) do local c=D.ElementDesign(key,id);if c then c.colorMode="custom";c.color={r,g,b,(c.color and c.color[4]) or 1} end end
        D.ApplyUnit(key);D.RefreshDesigner()
    end
    f.swatch:SetScript("OnClick",function()
        if not CanEdit() or not ColorPickerFrame then return end
        local before={color[1] or 1,color[2] or 1,color[3] or 1}
        local function Changed()
            local picker=ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker or ColorPickerFrame
            if picker and picker.GetColorRGB then ApplyColor(picker:GetColorRGB()) end
        end
        local info={r=before[1],g=before[2],b=before[3],hasOpacity=false,swatchFunc=Changed,cancelFunc=function() ApplyColor(unpack(before)) end}
        if ColorPickerFrame.SetupColorPickerAndShow then ColorPickerFrame:SetupColorPickerAndShow(info)
        else ColorPickerFrame.func=Changed;ColorPickerFrame.cancelFunc=info.cancelFunc;ColorPickerFrame:SetColorRGB(unpack(before));ColorPickerFrame:Show() end
    end)
    local mode=cfg.colorMode=="custom" and "Custom color" or "Automatic color"
    f.mode:SetLabel(mode)
    f.mode.action=function()
        if cfg.colorMode=="custom" and allowAutomatic then
            local changes={};for _,id in ipairs(ids) do changes[#changes+1]={id,"colorMode","auto"} end;CommitMany(key,changes)
        else f.swatch:Click() end
    end
    Place(pane,f,39)
end
local function QuickPosition(pane,key,id,cfg)
    local f=Use(pane,"grid",function()
        local x=CreateFrame("Frame",nil,pane);x:SetHeight(105);x.label=Label(x,"Quick position",11);x.label:SetPoint("TOPLEFT",2,0);x.buttons={}
        local points={"TOPLEFT","TOP","TOPRIGHT","LEFT","CENTER","RIGHT","BOTTOMLEFT","BOTTOM","BOTTOMRIGHT"}
        local labels={"Top left","Top","Top right","Left","Center","Right","Bottom left","Bottom","Bottom right"}
        for i,point in ipairs(points) do
            local b=Button(x,labels[i],112);b:SetSize(112,22);b:SetPoint("TOPLEFT",190+((i-1)%3)*118,-math.floor((i-1)/3)*25);b.point=point;x.buttons[i]=b
        end
        return x
    end)
    for _,b in ipairs(f.buttons) do
        local spec=D.catalogByID[id]
        local isText=spec and (spec.kind=="text" or spec.kind=="auraText")
        local reference=isText and cfg.followFrameSize~=false and D.TextReference(id,{relativeTo=spec.parent or "frame"}) or "frame"
        local horizontal=b.point:find("LEFT") and "LEFT" or b.point:find("RIGHT") and "RIGHT" or "CENTER"
        local vertical=b.point:find("TOP") and "TOP" or b.point:find("BOTTOM") and "BOTTOM" or "MIDDLE"
        b:SetActive(cfg.point==b.point and cfg.relativePoint==b.point and cfg.relativeTo==reference
            and (cfg.x or 0)==0 and (cfg.y or 0)==0
            and (not isText or (cfg.fitTextToContent and cfg.justify==horizontal and (cfg.justifyV or "MIDDLE")==vertical)))
        b.action=function(self)
            local changes={{id,"point",self.point},{id,"relativePoint",self.point},{id,"relativeTo",reference},{id,"x",0},{id,"y",0}}
            if isText then
                changes[#changes+1]={id,"fitTextToContent",true}
                changes[#changes+1]={id,"justify",horizontal}
                changes[#changes+1]={id,"justifyV",vertical}
            end
            if id=="portrait" and D.IsFriendlyMoveGroup and D.IsFriendlyMoveGroup(id) then
                changes[#changes+1]={"portraitModel","point",self.point};changes[#changes+1]={"portraitModel","relativePoint",self.point}
                changes[#changes+1]={"portraitModel","x",0};changes[#changes+1]={"portraitModel","y",0}
                changes[#changes+1]={"portraitModel","relativeTo","frame"}
            end
            CommitMany(key,changes)
        end
    end
    Place(pane,f,108)
end

D.Form={Reset=ResetForm,Section=Section,Note=Note,Toggle=ToggleRow,Button=ButtonRow,Dual=DualButtonRow,Number=NumberRow,Slider=SliderRow,Dropdown=DropdownRow,Color=ColorRow}
D.UI={SafeCreate=SafeCreate,Backdrop=Backdrop,Label=Label,Button=Button,FlatButton=FlatButton,EditBox=EditBox,Check=Check,Scroll=Scroll,Menu=Menu,MediaEntries=MediaEntries,MediaName=MediaName,Tooltip=Tooltip,Palette=C,CanEdit=CanEdit}


local function AvailableParents(key,id)
    local parents={{label="Whole frame",value="frame"}}
    local frame=D.Representative(key)
    for _,other in ipairs(D.Catalog(key,frame)) do
        if other.id~=id and not other.auraSub then parents[#parents+1]={label=other.label,value=other.id} end
    end
    return parents
end
local function TextSizeLock(pane,key,id,cfg)
    local spec=D.catalogByID[id]
    if not spec or spec.kind~="text" then return end
    ToggleRow(pane,"Follow frame size",cfg.followFrameSize~=false,function(enabled)
        if not CanEdit() then return end
        local function ChangeLock()
            D.PushHistory(key)
            D.BakeTextLayout(key,id)
            local current=D.ElementDesign(key,id)
            current.followFrameSize=enabled
            current.textSizeReference=nil
            D.ApplyUnit(key);D.RefreshDesigner()
        end
        if enabled then ChangeLock()
        else
            D.RefreshInspector()
            D.Confirm("Unlock this text? It will keep its current placement, but will no longer adjust when its frame or bar is resized. You will need to size and position it manually. You can enable Follow frame size again at any time.",ChangeLock)
        end
    end)
    Note(pane,cfg.followFrameSize~=false and "Text follows the size of its attached frame or bar while keeping its relative position." or "Manual sizing is enabled. Frame size changes will not adjust this text's size or offsets.")
end
local function PositionPage(pane,key,id,cfg,spec)
    TextSizeLock(pane,key,id,cfg)
    Section(pane,"Move and size","Drag in the preview for the fastest setup")
    NumberRow(pane,"Left / right",cfg.x or 0,-4000,4000,1,function(v) MoveComponent(key,id,v,cfg.y or 0) end,"px")
    NumberRow(pane,"Down / up",cfg.y or 0,-4000,4000,1,function(v) MoveComponent(key,id,cfg.x or 0,v) end,"px")
    if spec and spec.kind~="auras" and not (spec.kind=="text" and cfg.followFrameSize~=false) then
        NumberRow(pane,"Width",cfg.width,id=="health" and 20 or 1,2000,1,function(v) ResizeComponent(key,id,v,cfg.height) end,"px")
        NumberRow(pane,"Height",cfg.height,1,2000,1,function(v) ResizeComponent(key,id,cfg.width,v) end,"px")
    elseif spec and spec.kind=="auras" then
        Note(pane,"Aura group size follows icon size, spacing, rows, and columns. Adjust these on the Auras tab.")
    end
    local groupedOutline=id=="combatOutline.top" or id=="combatIconOutline1"
    if groupedOutline then
        Note(pane,"This is a multi-piece outline. Dragging or changing the offsets moves every piece together.")
    else
        QuickPosition(pane,key,id,cfg)
        Section(pane,"Attachment")
        DropdownRow(pane,"Attach to",cfg.relativeTo or "frame",AvailableParents(key,id),function(v)
            if id=="portrait" and D.IsFriendlyMoveGroup and D.IsFriendlyMoveGroup(id) then
                CommitMany(key,{{"portrait","relativeTo",v},{"portraitModel","relativeTo",v}})
            else Commit(key,id,"relativeTo",v) end
        end)
        Note(pane,"Most users can leave attachment on Whole frame. It only changes what the offsets are measured from.")
    end
end
local function AdvancedPage(pane,key,id,cfg,spec)
    Section(pane,"Advanced positioning")
    SliderRow(pane,"Element scale",(cfg.scale or 1)*100,10,500,5,function(v) Commit(key,id,"scale",v/100) end,function(v) return D.FormatNumber(v).."%" end)
    local points={};for _,point in ipairs(D.points) do points[#points+1]={label=point:gsub("([A-Z])"," %1"):gsub("^ ",""),value=point} end
    DropdownRow(pane,"Element anchor",cfg.point or "CENTER",points,function(v) Commit(key,id,"point",v) end)
    DropdownRow(pane,"Reference anchor",cfg.relativePoint or "CENTER",points,function(v) Commit(key,id,"relativePoint",v) end)
    SliderRow(pane,"Opacity",(cfg.opacity or 1)*100,0,100,5,function(v) Commit(key,id,"opacity",v/100) end,function(v) return D.FormatNumber(v).."%" end)
    Section(pane,"Layering")
    DualButtonRow(pane,"Bring forward",function() D.ShiftLayer(key,id,1);D.RefreshDesigner() end,"Send backward",function() D.ShiftLayer(key,id,-1);D.RefreshDesigner() end)
    NumberRow(pane,"Layer order",cfg.layer or 0,-8,100,1,function(v) Commit(key,id,"layer",math.floor(v)) end)
    if spec and spec.kind=="bar" then
        DropdownRow(pane,"Fill direction",cfg.orientation or "HORIZONTAL",{{label="Horizontal",value="HORIZONTAL"},{label="Vertical",value="VERTICAL"}},function(v) Commit(key,id,"orientation",v) end)
    end
    Section(pane,"Reset")
    ButtonRow(pane,"Reset only this element",function() ResetSelected(key,id) end)
end
local function TextPage(pane,key,id,cfg)
    TextSizeLock(pane,key,id,cfg)
    Section(pane,"Font")
    DropdownRow(pane,"Font",cfg.font or MMF_GetGlobalFontPath(),MediaEntries("font",cfg.font),function(v) Commit(key,id,"font",v) end,MediaName("font",cfg.font or MMF_GetGlobalFontPath()))
    SliderRow(pane,"Text size",cfg.fontSize or 12,6,64,1,function(v) Commit(key,id,"fontSize",v) end,function(v) return D.FormatNumber(v).." px" end)
    DropdownRow(pane,"Outline",cfg.fontFlags or "",{{label="None",value=""},{label="Outline",value="OUTLINE"},{label="Thick outline",value="THICKOUTLINE"},{label="Crisp outline",value="MONOCHROME,OUTLINE"}},function(v) Commit(key,id,"fontFlags",v) end)
    DropdownRow(pane,"Text alignment",cfg.justify or "CENTER",{{label="Left",value="LEFT"},{label="Center",value="CENTER"},{label="Right",value="RIGHT"}},function(v) Commit(key,id,"justify",v) end)
    ColorRow(pane,"Text color",key,id,true)
    if D.AddFriendlyLegacyTextOptions then D.AddFriendlyLegacyTextOptions(pane,key,id,cfg) end
end
local function StylePage(pane,key,id,cfg,spec)
    local choices=D.componentSamples and D.componentSamples[id]
    if choices then
        Section(pane,"Preview example")
        DropdownRow(pane,"Show example",D.sampleChoices[id] or choices[1].value,choices,function(value)
            D.sampleChoices[id]=value;D.RefreshPreview()
        end)
        Note(pane,"This only changes the example. Your in-game indicator follows the unit's actual state.")
    end
    if id=="health" then
        Section(pane,"Health bar")
        DropdownRow(pane,"Texture",cfg.texture,MediaEntries("statusbar",cfg.texture),function(v) Commit(key,id,"texture",v) end,MediaName("statusbar",cfg.texture))
        ColorRow(pane,"Health color",key,"health",true)
        ColorRow(pane,"Background color",key,"healthBackground",true)
        ColorRow(pane,"Border color",key,{"healthBorder.top","healthBorder.right","healthBorder.bottom","healthBorder.left"},true)
        local top=D.ElementDesign(key,"healthBorder.top")
        SliderRow(pane,"Border thickness",top and top.height or 1,0,12,1,function(v) HealthBorderThickness(key,v) end,function(v) return D.FormatNumber(v).." px" end)
    elseif id=="power" or id=="cast" then
        local fill=id=="power" and "powerFill" or "castFill";local bg=id=="power" and "powerBackground" or "castBackground";local border=id=="power" and "powerBorder" or "castBorder"
        local fcfg=D.ElementDesign(key,fill)
        Section(pane,id=="power" and "Power bar" or "Cast bar")
        if key=="player" and id=="cast" then
            ToggleRow(pane,"Hide Blizzard's player cast bar",MattMinimalFramesDB.hideBlizzardPlayerCastBar~=false,function(v)
                D.ChangeSharedSetting("hideBlizzardPlayerCastBar",v)
            end,"Hide Blizzard's cast bar while using MMF's player cast bar.")
        end
        DropdownRow(pane,"Texture",fcfg.texture,MediaEntries("statusbar",fcfg.texture),function(v) Commit(key,fill,"texture",v) end,MediaName("statusbar",fcfg.texture))
        ColorRow(pane,"Bar color",key,fill,true);ColorRow(pane,"Background color",key,bg,true);ColorRow(pane,"Border color",key,border,true)
        ToggleRow(pane,"Fill in reverse",fcfg.reverseFill==true,function(v) Commit(key,fill,"reverseFill",v) end)
    elseif id=="portrait" then
        Section(pane,"Portrait or class icon")
        local modes={{label="Class icon",value="class"},{label="Portrait",value="portrait"},{label="Cropped portrait",value="portrait_zoomed"},{label="Close portrait",value="portrait_more_zoomed"}}
        if key=="player" or key=="target" then modes[#modes+1]={label="Animated portrait",value="portrait_animated"};modes[#modes+1]={label="SharedMedia icon",value="sharedmedia"};modes[#modes+1]={label="Jiberish icon",value="jiberish"} end
        DropdownRow(pane,"Display",cfg.iconMode or "class",modes,function(v) Commit(key,id,"iconMode",v) end)
        SliderRow(pane,"Size",cfg.width,8,200,1,function(v) CommitMany(key,{{id,"width",v},{id,"height",v},{"portraitModel","width",v},{"portraitModel","height",v}}) end,function(v) return D.FormatNumber(v).." px" end)
        ColorRow(pane,"Tint",key,id,true)
    elseif id=="resources" then
        Section(pane,"Class resources")
        ColorRow(pane,"Background color",key,"resources.background",true)
        ButtonRow(pane,"Edit resource number",function() D.SelectElement("resourceText",true) end)
        Note(pane,"Use Individual parts in the elements list to style each class-resource segment separately.")
    elseif spec and (spec.kind=="text" or spec.kind=="auraText") then TextPage(pane,key,id,cfg)
    else
        Section(pane,"Appearance")
        if spec and spec.kind=="bar" then
            DropdownRow(pane,"Texture",cfg.texture,MediaEntries("statusbar",cfg.texture),function(v) Commit(key,id,"texture",v) end,MediaName("statusbar",cfg.texture))
            ToggleRow(pane,"Fill in reverse",cfg.reverseFill==true,function(v) Commit(key,id,"reverseFill",v) end)
        end
        ColorRow(pane,"Color",key,id,true)
        SliderRow(pane,"Opacity",(cfg.opacity or 1)*100,0,100,5,function(v) Commit(key,id,"opacity",v/100) end,function(v) return D.FormatNumber(v).."%" end)
        if spec and spec.dynamic then ToggleRow(pane,"Follow the current health fill",cfg.followHealth~=false,function(v) Commit(key,id,"followHealth",v) end) end
        if spec and (spec.auraSub=="icon" or spec.auraSub=="cooldown" or spec.auraSub=="border") then ToggleRow(pane,"Match the aura icon size",cfg.fitIcon~=false,function(v) Commit(key,id,"fitIcon",v) end) end
    end
end
local function AuraPage(pane,key,id,cfg)
    local title=id=="buffs" and "Buffs" or "Debuffs"
    Section(pane,title.." layout")
    SliderRow(pane,"Icon size",cfg.iconSize or 18,8,80,1,function(v) Commit(key,id,"iconSize",v) end,function(v) return D.FormatNumber(v).." px" end)
    SliderRow(pane,"Space between icons",cfg.spacing or 2,0,20,1,function(v) Commit(key,id,"spacing",v) end,function(v) return D.FormatNumber(v).." px" end)
    NumberRow(pane,"Icons per row",cfg.columns or 4,1,16,1,function(v) Commit(key,id,"columns",math.floor(v)) end)
    NumberRow(pane,"Rows",cfg.rows or 1,1,16,1,function(v) Commit(key,id,"rows",math.floor(v)) end)
    NumberRow(pane,"Maximum icons",cfg.maxIcons or 16,1,16,1,function(v) Commit(key,id,"maxIcons",math.floor(v)) end)
    DropdownRow(pane,"Start corner / fill",cfg.growth or (id=="debuffs" and "LEFT_UP" or "RIGHT_UP"),{
        {label="Top left: right, then down",value="RIGHT_DOWN"},
        {label="Top left: down, then right",value="DOWN_RIGHT"},
        {label="Top right: left, then down",value="LEFT_DOWN"},
        {label="Top right: down, then left",value="DOWN_LEFT"},
        {label="Bottom left: right, then up",value="RIGHT_UP"},
        {label="Bottom left: up, then right",value="UP_RIGHT"},
        {label="Bottom right: left, then up",value="LEFT_UP"},
        {label="Bottom right: up, then left",value="UP_LEFT"},
    },function(v) Commit(key,id,"growth",v) end)
    Note(pane,"The first icon starts at this corner of the aura area. Rows and columns set when it wraps.")
    DropdownRow(pane,"Auras from",cfg.filter or "all",{{label="Everyone",value="all"},{label="Only mine",value="mine"}},function(v) Commit(key,id,"filter",v) end)
    Section(pane,"Aura text")
    DualButtonRow(pane,"Edit stack number",function() D.SelectElement(id..".count",true) end,"Edit cooldown text",function() D.SelectElement(id..".timer",true) end)
    DualButtonRow(pane,"Edit icon",function() D.SelectElement(id..".icon",true) end,"Edit border",function() D.SelectElement(id..".border",true) end)
end
local function FramePage(pane,key,cfg)
    Section(pane,"Frame size")
    Note(pane,"Resize the unit's layout together. Overall size also scales text and icons.")
    SliderRow(pane,"Width",cfg.width,40,600,1,function(v) ResizeComponent(key,"frame",v,cfg.height) end,function(v) return D.FormatNumber(v).." px" end)
    SliderRow(pane,"Height",cfg.height,4,180,1,function(v) ResizeComponent(key,"frame",cfg.width,v) end,function(v) return D.FormatNumber(v).." px" end)
    SliderRow(pane,"Overall size",cfg.scale*100,25,300,5,function(v) Commit(key,"frame","scale",v/100) end,function(v) return D.FormatNumber(v).."%" end)
    Section(pane,"Easy actions")
    ButtonRow(pane,"Move this complete frame on screen",function() D.SetMoveMode(true) end,"Edit Mode moves the complete frame with all its elements.")
    DualButtonRow(pane,"Apply clean MMF layout",function() D.Confirm("Apply the clean MMF layout? Undo can restore the current design.",function() D.ApplyCleanPreset(key);D.RefreshDesigner() end) end,"Copy another frame",function(self)
        local entries={};for _,entry in ipairs(D.unitTypes) do if entry.key~=key and D.Supports(entry.key) then entries[#entries+1]={label=entry.label,value=entry.key} end end
        Menu(self,entries,function(source) D.Representative(source);D.CopyDesign(source,key);D.RefreshDesigner() end)
    end)
end
local function VisibilityPage(pane,key,cfg)
    Section(pane,"When this frame shows")
    ToggleRow(pane,"Frame enabled",cfg.enabled~=false,function(v) Commit(key,"frame","enabled",v) end)
    ToggleRow(pane,"Hide outside combat",cfg.hideOutsideCombat==true,function(v) Commit(key,"frame","hideOutsideCombat",v) end)
    SliderRow(pane,"Outside-combat visibility",(cfg.outsideCombatAlpha or 1)*100,0,100,5,function(v) Commit(key,"frame","outsideCombatAlpha",v/100) end,function(v) return D.FormatNumber(v).."%" end)
end
local function GroupPage(pane,key,cfg)
    Section(pane,"Group layout")
    NumberRow(pane,"Frames per row",cfg.groupColumns or 1,1,D.byUnitType[key].count or 10,1,function(v) Commit(key,"frame","groupColumns",math.floor(v)) end)
    SliderRow(pane,"Space between frames",cfg.groupSpacing or 10,0,80,1,function(v) Commit(key,"frame","groupSpacing",v) end,function(v) return D.FormatNumber(v).." px" end)
    if key=="boss" then
        Note(pane,"All five bosses share this design. Spacing updates automatically as you resize frames or their elements. The first boss stays in place; the others follow.")
    else
        ButtonRow(pane,"Arrange this group now",function() D.ArrangeGroup(key);D.RefreshDesigner() end)
        Note(pane,"Arrange the members using the current frame size and spacing.")
    end
end

local function TabsFor(key,id,spec)
    if id=="frame" then
        local tabs={{key="frame",label="Frame"},{key="visibility",label="Visibility"}}
        if D.byUnitType[key] and D.byUnitType[key].count then tabs[#tabs+1]={key="group",label="Group layout"} end
        return tabs
    end
    if id=="buffs" or id=="debuffs" then return {{key="auras",label="Auras"},{key="position",label="Position"},{key="advanced",label="Advanced"}} end
    if spec and (spec.kind=="text" or spec.kind=="auraText") then return {{key="style",label="Text"},{key="position",label="Position"},{key="advanced",label="Advanced"}} end
    return {{key="style",label="Appearance"},{key="position",label="Position"},{key="advanced",label="Advanced"}}
end

function D.RefreshInspector()
    local window=D.window;if not window or not D.selection then return end
    local key=D.selection.unit;local id=D.selection.id or "frame"
    if id~="frame" then D.BakeTextLayout(key,id) end
    local cfg=id=="frame" and D.UnitDesign(key) or D.ElementDesign(key,id);if not cfg then return end
    local spec=D.catalogByID[id]
    local title=id=="frame" and ((D.byUnitType[key] and D.byUnitType[key].label or "Unit").." frame") or D.FriendlyLabel(id)
    title=title:gsub("(%a)([%w']*)",function(first,rest) return first:upper()..rest end)
    window.selectedTitle:SetText("|cffffd166CURRENT ELEMENT:|r  |cff72f0d1"..title.."|r")
    local elementEnabled=cfg.enabled~=false
    window.selectedShown:SetValue(elementEnabled)
    window.selectedShown.label:SetTextColor(unpack(elementEnabled and C.green or C.red))
    window.selectedShown.action=function(value)
        window.selectedShown.label:SetTextColor(unpack(value and C.green or C.red))
        SetComponentEnabled(key,id,value)
    end
    window.hideSelected:SetLabel(cfg.enabled==false and "Show" or "Hide")
    window.hideSelected.action=function() SetComponentEnabled(key,id,cfg.enabled==false) end
    window.resetSelected.action=function() ResetSelected(key,id) end
    window.copySelected.action=function(self) OpenCopyMenu(self,key,id) end

    local tabs=TabsFor(key,id,spec);window.inspectorTabs=window.inspectorTabs or {}
    local valid=false
    for _,tab in ipairs(tabs) do if tab.key==D.inspectorTab then valid=true break end end
    if not valid then D.inspectorTab=tabs[1].key end
    local previous
    for index,tab in ipairs(tabs) do
        local b=window.inspectorTabs[index]
        if not b then b=Tab(window.inspectorTabBar,"",105);window.inspectorTabs[index]=b end
        b:ClearAllPoints();if previous then b:SetPoint("LEFT",previous,"RIGHT",5,0) else b:SetPoint("LEFT",0,0) end
        local tabKey=tab.key
        b:SetLabel(tab.label);b:SetActive(D.inspectorTab==tabKey);b.action=function() D.inspectorTab=tabKey;D.RefreshInspector() end;b:Show();previous=b
    end
    for i=#tabs+1,#window.inspectorTabs do window.inspectorTabs[i]:Hide() end

    local pane=ResetForm(window.optionsChild)
    if id=="frame" then
        if D.inspectorTab=="frame" then FramePage(pane,key,cfg)
        elseif D.inspectorTab=="visibility" then VisibilityPage(pane,key,cfg)
        elseif D.inspectorTab=="group" then GroupPage(pane,key,cfg) end
    elseif D.inspectorTab=="position" then PositionPage(pane,key,id,cfg,spec)
    elseif D.inspectorTab=="advanced" then AdvancedPage(pane,key,id,cfg,spec)
    elseif D.inspectorTab=="auras" then AuraPage(pane,key,id,cfg)
    else StylePage(pane,key,id,cfg,spec) end
    pane:SetHeight(math.max(1,-pane.cursor+12))
end

function D.SelectElement(id,forceExact)
    if D.previewDrag then D.FinishPreviewDrag(false) end
    local focus=GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus();if focus and focus.ClearFocus then focus:ClearFocus() end
    if forceExact==false then id=D.FriendlySelection(id or "frame") end
    if id~="frame" and not D.catalogByID[id] then id="frame" end
    if D.CancelPreviewDrag and (D.previewPress or D.previewDrag) then D.CancelPreviewDrag() end
    D.selection.id=id;D.inspectorTab=nil
    D.RefreshDesigner()
end

local function AvailableFriendlyRows(key,advanced)
    local rows=D.FriendlyRows(key,D.Representative(key),advanced)
    local result={}
    for _,row in ipairs(rows) do
        if row.header then result[#result+1]={label=row.label,header=true}
        else
            local cfg=row.id=="frame" and D.UnitDesign(key) or D.ElementDesign(key,row.id)
            result[#result+1]={label=row.label,value=row.id,checked=cfg and cfg.enabled~=false}
        end
    end
    return result
end
local function RefreshElementList()
    local window=D.window
    if not window or not window.elementList then return end
    local panel=window.elementList
    local key=D.selection.unit
    local entries=AvailableFriendlyRows(key,D.showAdvancedParts)
    panel.title:SetText((D.byUnitType[key].label or key).." elements")
    if panel.unit~=key then panel.scroll:SetVerticalScroll(0);panel.unit=key end
    local cursor=0
    for index,entry in ipairs(entries) do
        local row=panel.rows[index]
        if not row then
            row=Button(panel.child,"",144)
            row:SetHeight(19);row.label:SetJustifyH("LEFT");row.label:SetWordWrap(false)
            ApplyFont(row.label,9)
            function row:SetActive(active)
                self.active=active==true
                Backdrop(self,self.active and C.selected or C.inset,C.inset)
                self:SetBackdropBorderColor(0,0,0,0)
                self.marker:SetShown(self.active)
            end
            row.marker=row:CreateTexture(nil,"OVERLAY")
            row.marker:SetColorTexture(unpack(C.accent));row.marker:SetWidth(2)
            row.marker:SetPoint("TOPLEFT",0,-2);row.marker:SetPoint("BOTTOMLEFT",0,2)
            row.divider=row:CreateTexture(nil,"ARTWORK")
            row.divider:SetColorTexture(unpack(C.edgeSoft));row.divider:SetHeight(1)
            row.divider:SetPoint("BOTTOMLEFT",8,0);row.divider:SetPoint("BOTTOMRIGHT",-8,0)
            row:SetScript("OnEnter",function(self)
                if not self.active then self:SetBackdropColor(unpack(C.panel)) end
            end)
            row:SetScript("OnLeave",function(self) self:SetActive(self.active) end)
            panel.rows[index]=row
        end
        if entry.header and index>1 then cursor=cursor+12 end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",0,-cursor)
        row:SetHeight(entry.header and 28 or 19)
        cursor=cursor+(entry.header and 32 or 20)
        row:SetLabel(entry.header and string.upper(entry.label) or entry.label)
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT",entry.header and 4 or 16,0)
        row.label:SetPoint("RIGHT",-4,0)
        row.label:SetWordWrap(entry.header==true)
        ApplyFont(row.label,entry.header and 10 or 9,entry.header and "OUTLINE" or "")
        row.divider:SetShown(entry.header==true)
        row:SetActive(not entry.header and D.selection.id==entry.value)
        row.label:SetTextColor(unpack(entry.header and {1,0.82,0.40,1} or entry.checked and C.green or {0.60,0.60,0.60,1}))
        row:EnableMouse(not entry.header)
        if entry.header then
            row.action=nil
        else
            local id=entry.value
            row.action=function() D.SelectElement(id,D.showAdvancedParts) end
        end
        row:Show()
    end
    for i=#entries+1,#panel.rows do panel.rows[i]:Hide() end
    panel.child:SetHeight(math.max(1,cursor))
    panel.parts:SetLabel(D.showAdvancedParts and "Simple list" or "Individual parts")
end

local function AddElementMenu(button)
    local key=D.selection.unit;local rows=AvailableFriendlyRows(key,D.showAdvancedParts);local entries={}
    local header
    for _,entry in ipairs(rows) do
        if entry.header then header=entry
        else
            local cfg=entry.value=="frame" and D.UnitDesign(key) or D.ElementDesign(key,entry.value)
            if cfg and cfg.enabled==false then
                if header then entries[#entries+1]=header;header=nil end
                entries[#entries+1]=entry
            end
        end
    end
    if #entries==0 then D.Notify("Every available element is already shown.");return end
    Menu(button,entries,function(id)
        local cfg=id=="frame" and D.UnitDesign(key) or D.ElementDesign(key,id)
        if cfg and cfg.enabled==false then SetComponentEnabled(key,id,true) end
        D.SelectElement(id,D.showAdvancedParts)
    end,340)
end

function D.ShowElementChooser(candidates,anchor)
    if not candidates or #candidates<2 then return false end
    local entries={{label="Select an element",header=true}}
    for _,candidate in ipairs(candidates) do entries[#entries+1]={label=D.FriendlyLabel(candidate.id),value=candidate.id,checked=D.selection and D.selection.id==candidate.id} end
    Menu(anchor or (D.window and D.window.canvas),entries,function(id) D.SelectElement(id,D.showAdvancedParts) end,300)
    return true
end

local function UnitMenu(button)
    local entries={};local categories={{"Solo frames",{"player","target","targettarget","focus","focustarget","pet","pettarget","vehicle"}},{"Encounter frames",{"boss","arena"}}}
    for _,category in ipairs(categories) do
        entries[#entries+1]={label=category[1],header=true}
        for _,key in ipairs(category[2]) do
            local entry=D.byUnitType[key]
            if entry then local supported,reason=D.Supports(key);entries[#entries+1]={value=key,label=entry.label..(supported and "" or " - unavailable"),disabled=not supported,reason=reason} end
        end
    end
    entries[#entries+1]={label="Blizzard frames",header=true}
    entries[#entries+1]={label="Blizzard Party / Raid",value="blizzardGroups"}
    Menu(button,entries,function(key)
        if key=="blizzardGroups" then D.OpenBlizzardGroups();return end
        D.selection={unit=key,id="frame"};D.panX,D.panY=0,0;D.Representative(key);D.RefreshDesigner();D.CenterPreview()
    end,300)
end
local function PresetMenu(button)
    local key=D.selection.unit
    Menu(button,{{label="Starting layouts",header=true},{label="Clean MMF layout",value="clean"},{label="Reset to saved starting layout",value="reset"},{label="Copy another frame",value="copy"}},function(value)
        if value=="clean" then D.Confirm("Apply the clean MMF layout? Undo can restore the current design.",function() D.ApplyCleanPreset(key);D.RefreshDesigner() end)
        elseif value=="reset" then ResetSelected(key,"frame")
        elseif value=="copy" then
            local entries={};for _,entry in ipairs(D.unitTypes) do if entry.key~=key and D.Supports(entry.key) then entries[#entries+1]={label=entry.label,value=entry.key} end end
            Menu(button,entries,function(source) D.Representative(source);D.CopyDesign(source,key);D.RefreshDesigner() end)
        end
    end,290)
end


function D.RefreshDragLock()
    local window=D.window
    if not window or not window.dragLock then return end
    local profileName=MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
    window.currentProfileTitle:SetText("Current Profile: |cff5cd999"..profileName:gsub("|","||").."|r")
    local unlocked=D.Profile().liveDragUnlocked==true
    window.dragLock:SetLabel(unlocked and "Unlocked" or "Locked")
    window.dragLock.label:SetTextColor(unpack(unlocked and C.green or C.text))
    window.dragLock:SetActive(unlocked)
end
local function CreateRootWindow()
    local window=SafeCreate("Frame","MattMinimalFramesDesigner",UIParent,"BackdropTemplate")
    Backdrop(window,C.bg,C.edge)
    window:SetSize(920,820);window:SetPoint("CENTER");window:SetFrameStrata("DIALOG");window:SetClampedToScreen(true);window:EnableMouse(true);window:SetMovable(true)
    local scale=MattMinimalFramesDB.guiScale or math.min(1,(UIParent:GetWidth() or 1920)/940,(UIParent:GetHeight() or 1080)/840)
    window:SetScale(MMF_ClampGUIScale(scale))
    function window:ApplyGUIScale(value,save)
        local nextScale=MMF_ClampGUIScale(value)
        local ratio=self:GetEffectiveScale()/UIParent:GetEffectiveScale()
        local left,top=self:GetLeft(),self:GetTop()
        if left and top then
            self:ClearAllPoints()
            self:SetScale(nextScale)
            self:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left*ratio/nextScale,top*ratio/nextScale)
        else self:SetScale(nextScale) end
        if save then MattMinimalFramesDB.guiScale=nextScale end
    end
    local grip=Button(window,"",24)
    grip:SetSize(24,20);grip:SetPoint("BOTTOMRIGHT",-2,2);grip:SetFrameLevel(window:GetFrameLevel()+20)
    local gripIcon=grip:CreateTexture(nil,"ARTWORK")
    gripIcon:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    gripIcon:SetSize(16,16);gripIcon:SetPoint("CENTER")
    grip:HookScript("OnEnter",function() gripIcon:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight") end)
    grip:HookScript("OnLeave",function() gripIcon:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") end)
    grip:RegisterForDrag("LeftButton")
    Tooltip(grip,"GUI scale","Drag up to shrink or down to enlarge (10%–150%).")
    grip:SetScript("OnDragStart",function(self)
        local _,y=GetCursorPosition()
        self.scaleDrag={y=y,scale=window:GetScale(),height=window:GetHeight()*UIParent:GetEffectiveScale()}
    end)
    grip:SetScript("OnUpdate",function(self)
        local drag=self.scaleDrag
        if not drag then return end
        local _,y=GetCursorPosition()
        window:ApplyGUIScale(drag.scale+(drag.y-y)/drag.height,true)
    end)
    local function StopScaling(self)
        if not self.scaleDrag then return end
        self.scaleDrag=nil
        if D.RefreshSettings then D.RefreshSettings() end
    end
    grip:SetScript("OnDragStop",StopScaling)
    grip:SetScript("OnHide",StopScaling)
    local titleBar=window:CreateTexture(nil,"BACKGROUND")
    titleBar:SetPoint("TOPLEFT",1,-1);titleBar:SetPoint("TOPRIGHT",-1,-1);titleBar:SetHeight(32)
    titleBar:SetColorTexture(unpack(C.panel))
    local divider=window:CreateTexture(nil,"BORDER")
    divider:SetPoint("TOPLEFT",1,-33);divider:SetPoint("TOPRIGHT",-1,-33);divider:SetHeight(1)
    divider:SetColorTexture(unpack(C.edgeSoft))
    window.TitleText=Label(window,"Matt's Minimal Frames",17,C.text)
    ApplyFont(window.TitleText,17,"OUTLINE")
    window.TitleText:SetPoint("TOPLEFT",16,-8)
    window.TitleText:SetWordWrap(false)
    window.TitleText:SetWidth(290)
    local getAddonMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local addonVersion
    if type(getAddonMetadata) == "function" then
        local ok, version = pcall(getAddonMetadata, "MattMinimalFrames", "Version")
        if ok then addonVersion = version end
    end
    window.versionText=Label(window,"Version: "..tostring(addonVersion or "Unknown"),11,C.green)
    ApplyFont(window.versionText,11,"")
    window.versionText:SetPoint("LEFT",window.TitleText,"LEFT",window.TitleText:GetStringWidth()+8,0)
    window.versionText:SetWordWrap(false)
    window.currentProfileTitle=Label(window,"",12,C.text)
    ApplyFont(window.currentProfileTitle,12,"OUTLINE")
    window.currentProfileTitle:SetPoint("TOP",window,"TOP",0,-10)
    window.currentProfileTitle:SetWidth(260);window.currentProfileTitle:SetJustifyH("CENTER")
    window.currentProfileTitle:SetWordWrap(false)
    local drag=CreateFrame("Frame",nil,window);drag:SetPoint("TOPLEFT",1,-1);drag:SetHeight(32);drag:EnableMouse(true);drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function() window:StartMoving() end);drag:SetScript("OnDragStop",function() window:StopMovingOrSizing() end)
    drag:SetScript("OnHide",function() window:StopMovingOrSizing() end)
    if not window.CloseButton then window.CloseButton=Button(window,"X",28,function() window:Hide() end);window.CloseButton:SetPoint("TOPRIGHT",-6,-6) end
    window.dragLock=Button(window,"Locked",90,function()
        D.SetLiveDragUnlocked(D.Profile().liveDragUnlocked~=true)
    end)
    window.dragLock:RegisterForClicks("LeftButtonUp")
    window.dragLock:SetFrameLevel(window:GetFrameLevel()+10)
    window.dragLock:SetPoint("TOPRIGHT",-140,-5)
    
    drag:SetPoint("TOPRIGHT",window.dragLock,"TOPLEFT",-6,4)
    window.moveFrames=Button(window,"Edit Mode",90,function() D.SetMoveMode(true) end)
    window.moveFrames:SetPoint("LEFT",window.dragLock,"RIGHT",6,0)
    window.moveFrames:SetFrameLevel(window.dragLock:GetFrameLevel())
    
    local editFill={0.32,0.20,0.49,1}
    local editHover={0.43,0.28,0.63,1}
    local editEdge={0.76,0.58,1,1}
    Backdrop(window.moveFrames,editFill,editEdge)
    ApplyFont(window.moveFrames.label,12,"OUTLINE")
    window.moveFrames.label:SetTextColor(1,1,1,1)
    window.moveFrames:SetScript("OnEnter",function(self) Backdrop(self,editHover,{0.9,0.78,1,1}) end)
    window.moveFrames:SetScript("OnLeave",function(self) Backdrop(self,editFill,editEdge) end)
    Tooltip(window.dragLock,"Frame movement","Unlock to Shift-drag whole frames outside Edit Mode. Lock to prevent movement.")
    window:HookScript("OnShow",function()
        D.RefreshDragLock()
        if D.ShowBetaWelcome and not (MattMinimalFramesGlobalDB and MattMinimalFramesGlobalDB.hideBetaWelcome10) then
            D.ShowBetaWelcome()
        end
    end)
    window:HookScript("OnHide",function()
        if D.betaWelcome then D.betaWelcome:Hide() end
        if D.SetGamePreview then D.SetGamePreview(false) end
    end)

    window.tabBar=CreateFrame("Frame",nil,window);window.tabBar:SetPoint("TOPLEFT",18,-38);window.tabBar:SetSize(880,30)
    window.pages={};window.mainTabs={}
    local defs={{key="Designer",label="Designer"},{key="Settings",label="Global settings"},{key="Profiles",label="Profiles"}}
    local previous
    for i,def in ipairs(defs) do
        local b=Tab(window.tabBar,def.label,125);if previous then b:SetPoint("LEFT",previous,"RIGHT",5,0) else b:SetPoint("LEFT",0,0) end;previous=b
        local pageKey=def.key
        b.pageKey=pageKey;window.mainTabs[i]=b
        local page=CreateFrame("Frame",nil,window);page:SetPoint("TOPLEFT",14,-72);page:SetPoint("BOTTOMRIGHT",-14,14);page:Hide();window.pages[pageKey]=page
        b.action=function() D.SelectMainTab(pageKey) end
    end
    return window
end

local function BuildDesignerPage(page,window)
    page.toolbar=CreateFrame("Frame",nil,page);page.toolbar:SetPoint("TOPLEFT",0,0);page.toolbar:SetPoint("TOPRIGHT",0,0);page.toolbar:SetHeight(32)
    window.unitButton=Button(page.toolbar,"Player",155,UnitMenu);window.unitButton:SetPoint("LEFT",0,0)
    local function StyleUnitSelector(hover)
        Backdrop(window.unitButton,hover and {.40,.27,.56,1} or {.28,.19,.40,1},hover and {.90,.78,1,1} or {.72,.52,.95,1})
    end
    ApplyFont(window.unitButton.label,12,"OUTLINE")
    window.unitButton.label:SetTextColor(1,1,1,1)
    window.unitButton:SetScript("OnEnter",function() StyleUnitSelector(true) end)
    window.unitButton:SetScript("OnLeave",function() StyleUnitSelector(false) end)
    StyleUnitSelector(false)
    Tooltip(window.unitButton,"Choose a unit frame","Select Player, Target, Focus, Boss, or another unit to edit its elements.")
    window.undo=Button(page.toolbar,"Undo",60,function() if D.Undo(D.selection.unit) then D.RefreshDesigner() end end);window.undo:SetPoint("LEFT",window.unitButton,"RIGHT",6,0)
    window.redo=Button(page.toolbar,"Redo",60,function() if D.Undo(D.selection.unit,true) then D.RefreshDesigner() end end);window.redo:SetPoint("LEFT",window.undo,"RIGHT",4,0)
    window.presets=Button(page.toolbar,"Presets",82,PresetMenu);window.presets:SetPoint("LEFT",window.redo,"RIGHT",8,0)
    local tips=CreateFrame("Frame",nil,page.toolbar)
    tips:SetPoint("BOTTOMRIGHT",-4,2);tips:SetSize(210,48)
    tips:EnableMouse(false)
    local tipsTitle=Label(tips,"Preview tips",9,{.64,.88,.73,1})
    ApplyFont(tipsTitle,10,"OUTLINE")
    tipsTitle:SetPoint("TOPRIGHT",0,-2);tipsTitle:SetWidth(210);tipsTitle:SetJustifyH("RIGHT")
    for i,text in ipairs({"Left-click to select.","Right / middle-drag to pan.","Mouse wheel to zoom."}) do
        local line=Label(tips,text,9,{.56,.77,.63,1})
        line:SetPoint("TOPRIGHT",0,-15-(i-1)*11)
        line:SetWidth(210);line:SetJustifyH("RIGHT");line:SetWordWrap(false)
    end

    window.canvas=SafeCreate("Frame",nil,page,"BackdropTemplate");window.canvas:SetPoint("TOPLEFT",172,-38);window.canvas:SetPoint("TOPRIGHT",0,-38);window.canvas:SetHeight(295);window.canvas:SetClipsChildren(true);window.canvas:EnableMouse(true);window.canvas:EnableMouseWheel(true)
    local panel=SafeCreate("Frame",nil,page,"BackdropTemplate");window.elementList=panel
    panel:SetPoint("TOPLEFT",0,-38);panel:SetPoint("BOTTOMLEFT",window.canvas,"BOTTOMLEFT",-172,0);panel:SetWidth(172)
    Backdrop(panel,C.inset,C.edge);panel:EnableMouse(true)
    panel.title=Label(panel,"Elements",10,C.section);panel.title:SetPoint("TOPLEFT",10,-10)
    panel.scroll,panel.child=Scroll(panel)
    panel.scroll:SetPoint("TOPLEFT",5,-26);panel.scroll:SetPoint("BOTTOMRIGHT",-21,49)
    panel.child:SetWidth(144);panel.rows={}
    panel.parts=Button(panel,"Individual parts",156,function()
        D.showAdvancedParts=not D.showAdvancedParts
        if not D.showAdvancedParts then D.selection.id=D.FriendlySelection(D.selection.id) end
        D.RefreshDesigner()
    end);panel.parts:SetPoint("BOTTOMLEFT",8,27);panel.parts:SetHeight(18);ApplyFont(panel.parts.label,9)
    if window.canvas.SetBackdrop then Backdrop(window.canvas,C.inset,C.edge) end
    
    local scenery=window.canvas:CreateTexture(nil,"ARTWORK",nil,-7)
    scenery:SetPoint("TOPLEFT",1,-1);scenery:SetPoint("BOTTOMRIGHT",-1,1)
    
    scenery:SetTexture("Interface\\AddOns\\MattMinimalFrames\\Images\\designer_elwynn.tga")
    scenery:SetAlpha(0.60)
    local shade=window.canvas:CreateTexture(nil,"ARTWORK",nil,-6)
    shade:SetAllPoints(scenery);shade:SetColorTexture(0.025,0.03,0.04,0.48)
    local function CropScenery()
        local width,height=window.canvas:GetWidth()-2,window.canvas:GetHeight()-2
        if width<=0 or height<=0 then return end
        local ratio=width/height
        local sourceRatio=16/9 
        if ratio>sourceRatio then
            local visible=sourceRatio/ratio
            scenery:SetTexCoord(0,1,(1-visible)/2,(1+visible)/2)
        else
            local visible=ratio/sourceRatio
            scenery:SetTexCoord((1-visible)/2,(1+visible)/2,0,1)
        end
    end
    window.canvas:HookScript("OnSizeChanged",CropScenery)
    CropScenery()
    window.canvas:SetScript("OnMouseDown",function(_,button) if D.CanvasMouseDown then D.CanvasMouseDown(button) end end)
    window.canvas:SetScript("OnMouseUp",function(_,button) if D.CanvasMouseUp then D.CanvasMouseUp(button) end end)
    window.canvas:SetScript("OnMouseWheel",function(_,delta) if D.ZoomPreview then D.ZoomPreview(delta) end end)
    window.gridLines={}
    for x=10,900,20 do local line=window.canvas:CreateTexture(nil,"ARTWORK",nil,-5);line:SetColorTexture(.65,.70,.76,.12);line:SetSize(1,293);line:SetPoint("TOPLEFT",x,-1);window.gridLines[#window.gridLines+1]=line end
    for y=10,290,20 do local line=window.canvas:CreateTexture(nil,"ARTWORK",nil,-5);line:SetColorTexture(.65,.70,.76,.12);line:SetSize(900,1);line:SetPoint("TOPLEFT",1,-y);window.gridLines[#window.gridLines+1]=line end
    window.previewRoot=CreateFrame("Frame",nil,window.canvas);window.previewRoot:SetSize(220,28);window.previewRoot:SetPoint("CENTER");window.previewRoot.nodes={};window.previewRoot:SetFrameLevel(window.canvas:GetFrameLevel()+20)
    window.canvasChrome=CreateFrame("Frame",nil,window.canvas)
    window.canvasChrome:SetAllPoints(window.canvas);window.canvasChrome:SetFrameLevel(window.canvas:GetFrameLevel()+1200)
    window.canvasChrome:EnableMouse(false)
    window.hoverLabel=Label(window.canvasChrome,"Click an element, then drag it",10,C.muted);window.hoverLabel:SetPoint("TOP",0,-26);window.hoverLabel:SetJustifyH("CENTER")
    window.addElement=Button(panel,"Add",52,function(self) AddElementMenu(self) end);window.addElement:SetPoint("BOTTOMLEFT",8,6);window.addElement:SetHeight(18);ApplyFont(window.addElement.label,9)
    window.showHidden=Button(panel,"Show hidden",98,function(self) D.showHiddenElements=not D.showHiddenElements;self:SetActive(D.showHiddenElements);D.RefreshPreview() end);window.showHidden:SetPoint("LEFT",window.addElement,"RIGHT",6,0);window.showHidden:SetHeight(18);ApplyFont(window.showHidden.label,9)
    window.previewState=Button(window.canvasChrome,"Sample: Your design",172,function(self)
        Menu(self,D.sampleScenes,function(value)
            D.sampleState=value
            local label="Your design";for _,scene in ipairs(D.sampleScenes) do if scene.value==value then label=scene.label end end
            self:SetLabel("Sample: "..label);D.RefreshPreview()
        end,310)
    end);window.previewState:SetPoint("BOTTOMRIGHT",-8,8)
    window.fit=Button(window.canvasChrome,"Fit",48,function() D.CenterPreview() end);window.fit:SetPoint("RIGHT",window.previewState,"LEFT",-5,0)
    window.grid=Button(window.canvasChrome,"Grid",52,function(self) D.Profile().showGrid=not D.Profile().showGrid;self:SetActive(D.Profile().showGrid~=false);D.RefreshPreview() end);window.grid:SetPoint("RIGHT",window.fit,"LEFT",-5,0)
    window.largePreview=Button(window.canvasChrome,"Large preview",96,function() D.SetLargePreview(not window.largePreviewMode) end);window.largePreview:SetPoint("RIGHT",window.grid,"LEFT",-5,0)
    window.gamePreview=Button(window.canvasChrome,"Preview in Game",110,function() D.SetGamePreview(not D.gamePreviewEnabled) end)
    window.gamePreview:SetPoint("RIGHT",window.largePreview,"LEFT",-5,0)
    Tooltip(window.gamePreview,"Preview in Game","Show a temporary sample of the selected element at its live position. Click again to stop. Your GUI stays open.")

    window.selectionBar=SafeCreate("Frame",nil,page,"BackdropTemplate");window.selectionBar:SetPoint("TOPLEFT",0,-340);window.selectionBar:SetPoint("TOPRIGHT",0,-340);window.selectionBar:SetHeight(42);Backdrop(window.selectionBar,C.selected,C.accent)
    local selectionAccent=window.selectionBar:CreateTexture(nil,"OVERLAY")
    selectionAccent:SetColorTexture(1,.82,.40,1);selectionAccent:SetWidth(4)
    selectionAccent:SetPoint("TOPLEFT",1,-1);selectionAccent:SetPoint("BOTTOMLEFT",1,1)
    window.selectedTitle=Label(window.selectionBar,"CURRENT ELEMENT",17)
    ApplyFont(window.selectedTitle,17,"THICKOUTLINE")
    window.selectedTitle:SetPoint("LEFT",16,0);window.selectedTitle:SetWidth(485);window.selectedTitle:SetWordWrap(false)
    window.selectedShown=Check(window.selectionBar,"Enable Element",nil);window.selectedShown:SetPoint("LEFT",515,0);window.selectedShown:SetWidth(145)
    window.selectedShown.label:SetTextColor(unpack(C.green))
    window.hideSelected=Button(window.selectionBar,"Hide",60);window.hideSelected:SetPoint("RIGHT",window.selectionBar,"RIGHT",-10,0);window.hideSelected:Hide()
    window.resetSelected=Button(window.selectionBar,"Reset",60);window.resetSelected:SetPoint("RIGHT",window.selectionBar,"RIGHT",-10,0)
    window.copySelected=Button(window.selectionBar,"Copy",60);window.copySelected:SetPoint("RIGHT",window.resetSelected,"LEFT",-5,0)

    window.inspectorTabBar=CreateFrame("Frame",nil,page);window.inspectorTabBar:SetPoint("TOPLEFT",4,-387);window.inspectorTabBar:SetSize(870,27)
    window.optionsInset=SafeCreate("Frame",nil,page,"BackdropTemplate");window.optionsInset:SetPoint("TOPLEFT",0,-418);window.optionsInset:SetPoint("BOTTOMRIGHT",0,25)
    Backdrop(window.optionsInset,C.inset,C.edgeSoft)
    window.optionsScroll,window.optionsChild=Scroll(window.optionsInset);window.optionsScroll:SetPoint("TOPLEFT",5,-5);window.optionsScroll:SetPoint("BOTTOMRIGHT",-22,5);window.optionsChild:SetWidth(850)
    window.previewDisclosure=Label(window.canvasChrome,"",10,C.section)
    window.previewDisclosure:SetPoint("TOPRIGHT",-12,-8)
    window.status=Label(page,"",10,C.muted);window.status:SetPoint("BOTTOMLEFT",4,5);window.status:SetPoint("RIGHT",-4,0)


end

function D.SetLargePreview(enabled)
    local window=D.window;if not window or not window.canvas then return end
    enabled=enabled==true;window.largePreviewMode=enabled
    for _,region in ipairs({window.selectionBar,window.inspectorTabBar,window.optionsInset,window.status}) do if region then region:SetShown(not enabled) end end
    window.canvas:ClearAllPoints()
    window.canvas:SetPoint("TOPLEFT",window.pages.Designer,"TOPLEFT",172,-38)
    window.canvas:SetPoint("TOPRIGHT",window.pages.Designer,"TOPRIGHT",0,-38)
    if enabled then
        window.canvas:SetPoint("BOTTOM",window.pages.Designer,"BOTTOM",0,0)
        window.largePreview:SetLabel("Exit large preview")
    else
        window.canvas:SetHeight(295)
        window.largePreview:SetLabel("Large preview")
    end
    D.CenterPreview()
end

local function BuildProfilesPage(page,window)
    local title=Label(page,"Profiles",18,C.section);title:SetPoint("TOPLEFT",10,-10)
    local note=Label(page,"Each profile keeps its own frame designs and global settings. Changes save automatically.",11,C.muted);note:SetPoint("TOPLEFT",10,-42);note:SetWidth(620);note:SetWordWrap(true)
    window.profileCurrent=Label(page,"",14);window.profileCurrent:SetPoint("TOPLEFT",10,-86)
    window.profileSwitch=Button(page,"Switch profile",180,function(self)
        local entries={};for _,name in ipairs(MMF_GetProfileNames()) do entries[#entries+1]={label=name,value=name,checked=name==MMF_GetActiveProfileName()} end
        Menu(self,entries,function(name) D.SetMoveMode(false);MMF_SwitchProfile(name);D.selection={unit="player",id="frame"};D.RefreshDesigner();D.RefreshProfilesPage() end,300)
    end);window.profileSwitch:SetPoint("TOPLEFT",10,-122)
    local newLabel=Label(page,"New profile name",11);newLabel:SetPoint("TOPLEFT",10,-176)
    window.profileName=EditBox(page,370);window.profileName:SetPoint("TOPLEFT",10,-197)
    window.profileCreate=Button(page,"Create new profile",180,function()
        if not CanEdit() then return end
        local name=(window.profileName:GetText() or ""):match("^%s*(.-)%s*$")
        if name=="" then D.Notify("Enter a profile name first.");return end
        local ok,err=MMF_CreateProfile(name,false)
        if not ok then D.Notify(err or "Could not create that profile.");return end
        D.SetMoveMode(false)
        
        
        MMF_SwitchProfile(name,true)
        ReloadUI()
    end);window.profileCreate:SetPoint("TOPLEFT",10,-235)
    Tooltip(window.profileCreate,"Create new profile","Starts from MMF defaults, switches to the new profile, and reloads the UI.")
    window.profileCopy=Button(page,"Copy active profile",180,function()
        if not CanEdit() then return end
        local name=(window.profileName:GetText() or ""):match("^%s*(.-)%s*$");if name=="" then D.Notify("Enter a profile name first.");return end
        local ok,err=MMF_CreateProfile(name);if ok then MMF_SwitchProfile(name);window.profileName:SetText("");D.RefreshDesigner();D.RefreshProfilesPage() else D.Notify(err or "Could not create that profile.") end
    end);window.profileCopy:SetPoint("LEFT",window.profileCreate,"RIGHT",8,0)
    local createNote=Label(page,"New profiles start from MMF defaults and reload the UI. Copies keep your current setup.",11,C.muted)
    createNote:SetPoint("TOPLEFT",10,-272);createNote:SetWidth(620);createNote:SetWordWrap(true)
    window.profileDelete=Button(page,"Delete another profile",200,function(self)
        local entries={};local active=MMF_GetActiveProfileName();for _,name in ipairs(MMF_GetProfileNames()) do if name~=active and name~="Default" then entries[#entries+1]={label=name,value=name} end end
        if #entries==0 then D.Notify("There are no inactive custom profiles to delete.");return end
        Menu(self,entries,function(name) D.Confirm("Delete profile '"..name.."'? This cannot be undone.",function() MMF_DeleteProfile(name);D.RefreshProfilesPage() end) end,300)
    end);window.profileDelete:SetPoint("TOPLEFT",10,-320)
    local backup=Label(page,"Back up your WTF folder before large changes or before testing on another WoW client.",11,C.muted);backup:SetPoint("TOPLEFT",10,-370);backup:SetWidth(620);backup:SetWordWrap(true)
    window.resetEntireProfile=DangerButton(page,"RESET PROFILE SETTINGS",180,function() D.ConfirmFreshProfileReset() end)
    window.resetEntireProfile:SetPoint("TOPLEFT",10,-420)
    local resetNote=Label(page,"Restores the active profile to fresh-user defaults. Keeps its name and your other profiles.",11,C.muted)
    resetNote:SetPoint("TOPLEFT",10,-455);resetNote:SetWidth(620);resetNote:SetWordWrap(true)
end

function D.RefreshProfilesPage()
    D.RefreshDragLock()
    if D.window and D.window.profileCurrent then D.window.profileCurrent:SetText("Active profile: "..(MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default")) end
end

local function MakeWindow()
    if D.window then return D.window end
    local window=CreateRootWindow();D.window=window;MMF_WelcomePopup=window
    BuildDesignerPage(window.pages.Designer,window)
    if D.BuildSettingsPage then D.BuildSettingsPage(window.pages.Settings,window) end
    BuildProfilesPage(window.pages.Profiles,window)
    window:SetScript("OnHide",function()
        HideMenu();if D.CancelPreviewDrag then D.CancelPreviewDrag() end
        if D.DisposePreview then D.DisposePreview() end
        if D.confirm then D.confirm:Hide() end
    end)
    window:EnableKeyboard(true);if window.SetPropagateKeyboardInput then window:SetPropagateKeyboardInput(true) end
    window:SetScript("OnKeyDown",function(self,key)
        if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end;return end
        local handled=false
        if key=="ESCAPE" then if menu and menu:IsShown() then menu:Hide() elseif D.previewDrag or D.previewPress then D.CancelPreviewDrag() elseif self.largePreviewMode then D.SetLargePreview(false) else self:Hide() end;handled=true
        elseif IsControlKeyDown() and (key=="Z" or key=="Y") and D.selection then D.Undo(D.selection.unit,key=="Y");D.RefreshDesigner();handled=true
        elseif D.selection and D.selection.id~="frame" and (key=="LEFT" or key=="RIGHT" or key=="UP" or key=="DOWN") then
            local cfg=D.ElementDesign(D.selection.unit,D.selection.id);local step=IsShiftKeyDown() and 10 or D.Profile().snap;local property=(key=="LEFT" or key=="RIGHT") and "x" or "y"
            Commit(D.selection.unit,D.selection.id,property,(cfg[property] or 0)+((key=="LEFT" or key=="DOWN") and -step or step));handled=true
        end
        if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(not handled) end
    end)
    window:Hide();return window
end

function D.SelectMainTab(key)
    local window=D.window or MakeWindow();key=key or "Designer"
    if key~="Designer" and D.SetGamePreview then D.SetGamePreview(false) end
    for _,button in ipairs(window.mainTabs) do button:SetActive(button.pageKey==key) end
    for name,page in pairs(window.pages) do page:SetShown(name==key) end
    D.mainTab=key
    if key=="Designer" then D.RefreshDesigner();D.CenterPreview()
    elseif key=="Settings" and D.RefreshSettings then D.RefreshSettings()
    elseif key=="Profiles" then D.RefreshProfilesPage() end
end

function D.RefreshDesigner()
    if D.selection and D.suspendedUnitTypes[D.selection.unit] then D.selection={unit="player",id="frame"} end
    if D.liveSliderDrag then D.RefreshPreview();return end
    D.RefreshDragLock()
    local window=D.window;if not window or not window:IsShown() or not D.selection then return end
    if not window.pages.Designer:IsShown() then return end
    local entry=D.byUnitType[D.selection.unit];window.unitButton:SetLabel((entry and entry.label or "Player").."  v")
    window.showHidden:SetActive(D.showHiddenElements==true);window.grid:SetActive(D.Profile().showGrid~=false)
    D.RefreshPreview();D.RefreshInspector();RefreshElementList()
    if window.fittedUnit~=D.selection.unit or window.fittedProfile~=D.Profile() then
        window.fittedUnit=D.selection.unit;window.fittedProfile=D.Profile()
        D.CenterPreview()
    end
    local profile=MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
    if not D.previewDrag then window.status:SetText("Saved to "..profile..". Click an element and drag it. Click overlapping elements to choose the exact one.") end
end
D.RefreshEditor=D.RefreshDesigner
D.RefreshSelectionUI=D.RefreshDesigner

function D.Confirm(text,callback)
    if not D.confirm then
        local f=SafeCreate("Frame",nil,UIParent,"BackdropTemplate");Backdrop(f,C.panel,C.edge);f:SetSize(460,150);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");f:EnableMouse(true)
        f.message=Label(f,"",12);f.message:SetPoint("TOPLEFT",18,-18);f.message:SetSize(424,70);f.message:SetWordWrap(true)
        f.yes=Button(f,"Confirm",100,function() local fn=f.action;f:Hide();if CanEdit() and fn then fn() end end);f.yes:SetPoint("BOTTOMRIGHT",-18,14)
        f.no=Button(f,"Cancel",100,function() f:Hide() end);f.no:SetPoint("RIGHT",f.yes,"LEFT",-8,0);f:Hide();D.confirm=f
    end
    D.confirm:SetHeight(150);D.confirm.message:SetHeight(70)
    Backdrop(D.confirm,C.panel,C.edge);D.confirm.message:SetTextColor(unpack(C.text))
    D.confirm.yes:SetLabel("Confirm");D.confirm.yes:SetWidth(100);D.confirm.yes:SetActive(false)
    D.confirm.message:SetText(text or "Are you sure?");D.confirm.action=callback;D.confirm:Show()
end

function D.ConfirmFreshProfileReset()
    if not CanEdit() then return end
    local profileName=MMF_GetActiveProfileName()
    local profile=D.Profile()
    local function Prompt(text,label,callback)
        D.Confirm(text,callback)
        D.confirm:SetHeight(190);D.confirm.message:SetHeight(110)
        D.confirm.yes:SetLabel(label);D.confirm.yes:SetWidth(175)
        Backdrop(D.confirm,C.panel,{1,.2,.15,1})
        Backdrop(D.confirm.yes,{.45,.04,.04,1},{1,.2,.15,1})
        D.confirm.message:SetTextColor(1,.72,.65,1)
    end
    Prompt("RESET PROFILE SETTINGS - 1 OF 2\nReset '"..profileName.."' to fresh-user defaults? Its name and profile entry will be kept. Custom settings and layouts will return to fresh-user defaults. Other profiles are unchanged.","Continue to final warning",function()
        Prompt("FINAL CONFIRMATION - 2 OF 2\nReset all settings and layouts in '"..profileName.."'? The profile will NOT be deleted. This reset cannot be undone. The UI will reload with fresh-user defaults.","RESET SETTINGS",function()
            if profile~=D.Profile() or profileName~=MMF_GetActiveProfileName() then D.Notify("Profile changed. Reset cancelled.");return end
            D.SetMoveMode(false)
            if D.window then D.window:Hide() end
            D.history={};D.editPositionSnapshot=nil
            
            MMF_ResetProfile(profileName,true)
            ReloadUI()
        end)
    end)
end

function D.RefreshMoveResetLists()
    local toolbar=D.moveToolbar
    if not toolbar or not D.GetMovedEditItems then return end
    for id,panel in pairs(toolbar.resetLists) do
        local items=D.GetMovedEditItems(id)
        panel.child:SetHeight(math.max(1,#items*23))
        for index,item in ipairs(items) do
            local row=panel.rows[index]
            if not row then
                row=CreateFrame("Frame",nil,panel.child);row:SetSize(130,22)
                row.label=Label(row,"",9,C.muted);row.label:SetPoint("LEFT",2,0);row.label:SetWidth(78);row.label:SetWordWrap(false)
                row.reset=Button(row,"Reset",44);row.reset:SetHeight(19);ApplyFont(row.reset.label,9);row.reset:SetPoint("RIGHT")
                panel.rows[index]=row
            end
            row:SetPoint("TOPLEFT",0,-(index-1)*23);row.label:SetText(item.label)
            row.reset.action=function() D.ResetMovedEditItem(item) end
            row:Show()
        end
        for index=#items+1,#panel.rows do panel.rows[index]:Hide() end
        panel:SetShown(#items>0)
        panel.empty:SetShown(#items==0)
    end
end

function D.MoveToolbar(show)
    if not D.moveToolbar then
        local f=SafeCreate("Frame",nil,UIParent,"BackdropTemplate");Backdrop(f,C.bg,C.edge)
        f:SetSize(862,226);f:SetFrameStrata("DIALOG");f:SetMovable(true);f:SetClampedToScreen(true)
        local saved=D.Profile().moveWindow or {}
        f:SetScale(saved.scale or .85)
        if saved.x and saved.y then
            f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",saved.x,saved.y)
        else
            f:SetPoint("TOP",UIParent,"TOP",0,-45/f:GetScale())
        end
        local function SaveWindow()
            D.Profile().moveWindow={scale=f:GetScale(),x=f:GetLeft(),y=f:GetTop()}
        end
        local titleBar=CreateFrame("Frame",nil,f);titleBar:SetPoint("TOPLEFT",1,-1);titleBar:SetPoint("TOPRIGHT",-700,-1);titleBar:SetHeight(35)
        titleBar:EnableMouse(true);titleBar:RegisterForDrag("LeftButton")
        titleBar:SetScript("OnDragStart",function() f:StartMoving() end)
        titleBar:SetScript("OnDragStop",function() f:StopMovingOrSizing();SaveWindow() end)
        local title=Label(titleBar,"EDIT MODE",13,C.section);ApplyFont(title,13,"OUTLINE");title:SetPoint("LEFT",12,0)
        f.gridCheck=Check(f,"Show grid",function(value)
            D.Profile().moveGrid=value==true
            D.RefreshMoveGrid()
        end)
        f.gridCheck:SetPoint("TOPLEFT",180,-6);f.gridCheck:SetWidth(125)
        local hint=Label(f,"Check a section to move it. Reset restores that item to your layout before entering Edit Mode.",10,C.muted);hint:SetPoint("TOPLEFT",14,-39)
        local done=Button(f,"Done",65,function() D.SetMoveMode(false);D.Open() end);done:SetPoint("TOPRIGHT",-10,-6)
        local blizzard=Button(f,"Move Blizzard Party / Raid",190,function() D.OpenBlizzardGroupMover() end)
        blizzard:SetPoint("TOPRIGHT",-85,-6)
        Tooltip(blizzard,"Move Blizzard Party / Raid","Opens Blizzard Edit Mode. Move and save these frames there; MMF's editor closes first.")
        f.checks={};f.resetLists={}
        local left=12
        for _,entry in ipairs({{"units","Unit frames"},{"cast","Cast bars"},{"buffs","Buffs"},{"debuffs","Debuffs"},{"resources","Class resources"}}) do
            local id=entry[1]
            local section=SafeCreate("Frame",nil,f,"BackdropTemplate");Backdrop(section,C.inset,C.edgeSoft)
            section:SetPoint("TOPLEFT",left,-60);section:SetSize(162,142)
            local check=Check(section,entry[2],function(value) D.SetMoveCategory(id,value) end)
            check:SetPoint("TOPLEFT",8,-5);check:SetWidth(146);ApplyFont(check.label,10,"OUTLINE")
            local rule=section:CreateTexture(nil,"ARTWORK");rule:SetColorTexture(unpack(C.edgeSoft));rule:SetHeight(1)
            rule:SetPoint("TOPLEFT",8,-36);rule:SetPoint("TOPRIGHT",-8,-36)
            local scroll,child=Scroll(section);scroll:SetPoint("TOPLEFT",8,-43);scroll:SetWidth(130);scroll:SetHeight(90)
            child:SetWidth(130);scroll.child=child;scroll.rows={};f.resetLists[id]=scroll
            scroll.empty=Label(section,"No moved items",9,C.muted);scroll.empty:SetPoint("TOPLEFT",10,-48)
            left=left+169;f.checks[id]=check
        end
        local grip=CreateFrame("Button",nil,f);grip:SetSize(20,20);grip:SetPoint("BOTTOMRIGHT",-3,3)
        local icon=grip:CreateTexture(nil,"ARTWORK");icon:SetAllPoints();icon:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        Tooltip(grip,"Scale Edit Mode","Drag upward to shrink or downward to enlarge.")
        grip:SetScript("OnMouseDown",function(self,button)
            if button~="LeftButton" then return end
            local _,y=GetCursorPosition()
            self.drag={y=y,scale=f:GetScale(),left=f:GetLeft()*f:GetScale(),top=f:GetTop()*f:GetScale()}
        end)
        grip:SetScript("OnUpdate",function(self)
            local drag=self.drag;if not drag then return end
            if not IsMouseButtonDown("LeftButton") then self.drag=nil;SaveWindow();return end
            local _,y=GetCursorPosition()
            local scale=math.max(.3,math.min(1.5,drag.scale+(drag.y-y)/(f:GetHeight()*UIParent:GetEffectiveScale())))
            f:SetScale(scale);f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",drag.left/scale,drag.top/scale)
        end)
        grip:SetScript("OnMouseUp",function(self) self.drag=nil;SaveWindow() end)
        f:HookScript("OnHide",function() grip.drag=nil;f:StopMovingOrSizing();SaveWindow() end)
        f:Hide();D.moveToolbar=f
    end
    for id,check in pairs(D.moveToolbar.checks) do check:SetValue(D.moveCategories[id]) end
    D.moveToolbar.gridCheck:SetValue(D.Profile().moveGrid==true)
    D.moveToolbar:SetShown(show==true)
    if D.RefreshMoveGrid then D.RefreshMoveGrid() end
    if show then D.RefreshMoveResetLists() end
end

function D.Open(key)
    if not CanEdit() then return end
    if D.moveMode then D.SetMoveMode(false) end
    key=key or (D.selection and D.selection.unit) or "player";if not D.Supports(key) then key="player" end
    D.selection=D.selection or {unit=key,id="frame"};if D.selection.unit~=key then D.selection={unit=key,id="frame"} end
    local window=MakeWindow();D.Representative(key);window:Show();D.SelectMainTab(D.mainTab or "Designer")

    D.RefreshDesigner()
    D.CenterPreview()
end
function D.OpenSettings() D.Open();D.SelectMainTab("Settings") end
function MMF_ShowWelcomePopup() D.Open() end
function MMF_ToggleWelcomePopup() if D.window and D.window:IsShown() then D.window:Hide() else D.Open() end end

local function Slash(message)
    local command=(message or ""):match("^%s*(%S*)") or ""
    if command=="move" then D.SetMoveMode(not D.moveMode)
    elseif command=="diagnose" or command=="diagnostics" then D.Notify(D.Diagnostics())
    elseif command=="settings" then D.OpenSettings()
    elseif command=="help" then D.Notify("/mmf opens the designer; /mmf move moves complete frames; /mmf settings opens global settings; /mmf diagnose prints build details.")
    else D.Open() end
end

SlashCmdList.MATTMINIMALFRAMES = Slash
SlashCmdList.MMF = Slash
SLASH_MATTMINIMALFRAMES1 = "/mmf"
