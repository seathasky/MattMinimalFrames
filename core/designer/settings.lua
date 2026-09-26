

local D=MMF_Designer
local F=D.Form
local FONT=(MMF_GetGlobalFontPath and MMF_GetGlobalFontPath()) or "Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"

local pages={
    {key="Appearance",label="Fonts & textures",help="Default media used across MMF."},
    {key="Names",label="Names",help="Shared name formatting."},
    {key="Visibility",label="Visibility",help="Shared out-of-combat behavior."},
    {key="Healing",label="Healing & shields",help="Incoming heals, absorbs, and dispels."},
    {key="Gameplay",label="Auras & power",help="Gameplay presentation that affects several frames."},
    {key="Blizzard frames",label="Blizzard frames",help="Optional changes to Blizzard-owned frames."},
    {key="Blizzard Party / Raid",label="Blizzard Party / Raid",help="Style Blizzard's party and raid frames. Position and size them with Blizzard's own frame controls."},
    {key="Utilities",label="Help & tools",help="Onboarding, diagnostics, and convenience options."},
}
local options={
 ["Names"]={
  {"enableNameTruncation","Shorten names that are too long"},{"nameTruncationLength","Maximum name length",4,60,1},
  {"autoResizeTextOnLongName","Shrink long names so they still fit"},
 },
 ["Visibility"]={
  {"showPlayerOnTargetSelected","Show Player when a target is selected"},
  {"hideCurrentClassBarOOCNoTarget","Hide class resources outside combat with no target"},
  {"outOfCombatClassBarOpacity","Class-resource opacity outside combat",0,1,.05,"percent"},
  {"animatedRestingIcon","Animate the resting icon"},{"animatedCombatIcon","Animate the combat icon"},
  {"combatFrameOutline","Outline Player while in combat"},
 },
 ["Healing"]={
  {"showHealPrediction","Show incoming healing"},{"showOverhealPrediction","Show overhealing"},
  {"containOverhealWithinFrame","Keep overhealing inside the health bar"},
  {"showAbsorbBar","Show absorb shields"},{"showHealAbsorbBar","Show healing absorbs"},
  {"useSolidAbsorbBar","Use a solid absorb texture"},
  {"showPlayerDispelHighlight","Highlight effects you can dispel on yourself"},
  {"showTargetDispelHighlight","Highlight effects you can dispel on your target"},
 },
 ["Gameplay"]={
  {"showDruidManaPowerText","Show mana text while a Druid is shapeshifted"},
  {"showTBCTargetTapColor","Gray a Classic target tagged by another player"},
 },
 ["Blizzard frames"]={
  {"hideBlizzardPlayerBuffs","Hide Blizzard player buffs"},{"hideBlizzardPlayerDebuffs","Hide Blizzard player debuffs"},
 },
 ["Blizzard Party / Raid"]={
  {"useSharedPartyRaidNameFont","Enable MMF name styling (font, size, alignment and shortening)"},
  {"centerPartyRaidNames","Center Blizzard group names"},{"partyRaidNameOutline","Outline Blizzard group names"},
  {"partyNameFontSize","Blizzard party-name size",6,32,1},{"raidNameFontSize","Blizzard raid-name size",6,32,1},
  {"partyNameTruncateLength","Blizzard party-name length",2,40,1},{"raidNameTruncateLength","Blizzard raid-name length",2,40,1},
  {"hidePartyFrameLabel","Hide the Blizzard party label"},{"hideRaidGroupLabels","Hide Blizzard raid group labels"},
  {"hidePartyRaidRemainingHealth","Hide Blizzard group health text"},{"showSoloPartyFrame","Show the Blizzard party frame while solo"},
  {"hidePlayerInPartyFrame","Hide yourself in the Blizzard party frame"},
 },
}
D.sharedSettingOptions=options
D.settingsPages=pages

local function CanEdit()
    if InCombatLockdown() then D.Notify("Leave combat before changing settings.");return false end
    return D.ready==true
end
local function Value(key)
    local value=MattMinimalFramesDB and MattMinimalFramesDB[key]
    if value==nil and MattMinimalFrames_Defaults then value=MattMinimalFrames_Defaults[key] end
    return value
end
local function SyncDesignerSetting(setting,value)
    local map={showAbsorbBar={"absorb"},showHealAbsorbBar={"healAbsorb"},
        showPlayerDispelHighlight={"dispel","player"},showTargetDispelHighlight={"dispel","target"}}
    if setting=="showHealPrediction" then
        for key in pairs(D.Profile().units) do
            local a=D.ElementDesign(key,"myHeal");local b=D.ElementDesign(key,"otherHeal")
            if a then a.enabled=value end;if b then b.enabled=value end
        end
    elseif setting=="combatFrameOutline" then
        for _,edge in ipairs({"top","right","bottom","left"}) do local cfg=D.ElementDesign("player","combatOutline."..edge);if cfg then cfg.enabled=value end end
    elseif map[setting] then
        local id,only=map[setting][1],map[setting][2]
        for key in pairs(D.Profile().units) do if not only or key==only then local cfg=D.ElementDesign(key,id);if cfg then cfg.enabled=value end end end
    end
end
local function Apply()
    if D.liveSliderDrag then
        D.pendingSharedApply=true
        return
    end
    D.pendingSharedApply=nil
    
    if MMF_ApplyActiveProfileLive then MMF_ApplyActiveProfileLive() else D.ApplyAll() end
    if D.RefreshSettings then D.RefreshSettings() end
end
function D.FlushSharedSettings()
    if D.pendingSharedApply then Apply() end
end
local function ApplyGroupSetting(key)
    local matched=false
    for _,option in ipairs(options["Blizzard Party / Raid"]) do
        if option[1]==key then matched=true;break end
    end
    if not matched then return false end
    if key=="showSoloPartyFrame" then MMF_UpdateBlizzardSoloPartyFrameVisibility()
    elseif key=="hidePlayerInPartyFrame" then MMF_UpdateBlizzardPartySelfVisibility()
    elseif key=="hidePartyFrameLabel" or key=="hideRaidGroupLabels" then MMF_UpdateBlizzardPartyRaidLabels()
    elseif key=="hidePartyRaidRemainingHealth" then MMF_UpdateBlizzardPartyRaidHealthText()
    else MMF_UpdateBlizzardPartyRaidNameFonts() end
    if D.RefreshBlizzardGroupSample then D.RefreshBlizzardGroupSample() end
    return true
end
local function Change(key,value)
    if not CanEdit() then return end
    if MattMinimalFramesDB[key]==value then return end
    MattMinimalFramesDB[key]=value
    if key=="hideBlizzardPlayerCastBar" then
        MMF_UpdateBlizzardPlayerCastBarVisibility()
        return
    end
    if ApplyGroupSetting(key) then return end
    SyncDesignerSetting(key,value)
    Apply()
end
D.ChangeSharedSetting=Change

local function SafeButton(parent,text,width,callback)
    local b=D.UI.Button(parent,text,width or 170,callback)
    b:SetHeight(29)
    return b
end
local function Label(parent,text,size,color)
    local fs=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    D.ApplyFont(fs,FONT,size or 12,"");fs:SetText(text or "");fs:SetTextColor(unpack(color or {1,1,1,1}));fs:SetJustifyH("LEFT")
    return fs
end
local function Scroll(parent)
    return D.UI.Scroll(parent)
end

local function FontEntries()
    local entries={}
    for _,name in ipairs(MMF_GetFontOptions and MMF_GetFontOptions() or {}) do
        entries[#entries+1]={label=name,value=name,font=MMF_GetGlobalFontPathByName and MMF_GetGlobalFontPathByName(name) or FONT}
    end
    if #entries==0 then entries[1]={label="Game default",value="MMF Game Default",font=FONT} end
    return entries
end
local function TextureEntries()
    local entries={};local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if lsm then
        for _,name in ipairs(lsm:List("statusbar") or {}) do
            entries[#entries+1]={label=name,value=name,texture=lsm:Fetch("statusbar",name,true)}
        end
    end
    return entries
end
local function AddStandardOptions(pane,page)
    for _,option in ipairs(options[page] or {}) do
        local key,label,minv,maxv,step,format=unpack(option);local value=Value(key)
        if minv then
            local formatter=format=="percent" and function(v) return D.FormatNumber(v*100).."%" end or nil
            F.Slider(pane,label,D.Number(value,minv,minv,maxv),minv,maxv,step or 1,function(v) Change(key,v) end,formatter)
        else F.Toggle(pane,label,value==true,function(v) Change(key,v) end) end
    end
end

local function BlizzardGroupPreview(pane)
    local preview=pane.blizzardPreview
    if not preview then
        preview=CreateFrame("Frame",nil,pane,"BackdropTemplate")
        pane.blizzardPreview=preview
        D.UI.Backdrop(preview,D.UI.Palette.inset,D.UI.Palette.edgeSoft)
        preview:SetHeight(125)
        preview.caption=Label(preview,"Sample Blizzard group styling",11)
        preview.caption:SetPoint("TOPLEFT",12,-10)
        preview.cards={}
        for i,kind in ipairs({"party","raid"}) do
            local card=CreateFrame("Frame",nil,preview,"BackdropTemplate")
            card:SetSize(150,60);card:SetPoint("TOPLEFT",12+(i-1)*162,-47)
            D.UI.Backdrop(card,i==1 and {.12,.48,.57,1} or {.45,.24,.42,1},{0,0,0,1})
            card.caption=Label(card,i==1 and "Party" or "Raid",10)
            card.caption:SetPoint("BOTTOMLEFT",card,"TOPLEFT",0,5)
            card.name=Label(card,"",12);card.name:SetWidth(138)
            local nativeFont,nativeSize,nativeFlags=GameFontNormalSmall:GetFont()
            card.name:SetFont(nativeFont,nativeSize,nativeFlags)
            card.name:SetShadowOffset(1,-1)
            card.name:SetPoint("TOPLEFT",6,-5)
            card.health=Label(card,"86%",10);card.health:SetPoint("BOTTOM",0,4)
            card.kind=kind;preview.cards[i]=card
        end
    end
    preview:ClearAllPoints();preview:SetPoint("TOPLEFT",8,pane.cursor);preview:SetPoint("RIGHT",-8,0)
    pane.cursor=pane.cursor-137
    for _,card in ipairs(preview.cards) do
        MMF_StyleBlizzardGroupNameSample(card.name,card,card.kind,"Octoberpumpkins")
        card.health:SetShown(Value("hidePartyRaidRemainingHealth")~=true)
    end
    preview:Show()
end

function D.RefreshBlizzardGroupSample()
    local pane=D.settingsWindow and D.settingsWindow.child
    local preview=pane and pane.blizzardPreview
    if not preview or not preview:IsShown() then return end
    for _,card in ipairs(preview.cards) do
        MMF_StyleBlizzardGroupNameSample(card.name,card,card.kind,"Octoberpumpkins")
        card.health:SetShown(Value("hidePartyRaidRemainingHealth")~=true)
    end
end

function D.RefreshSettings()
    if D.liveSliderDrag then return end
    local window=D.settingsWindow
    if not window or not window.child then return end
    local page=window.pageKey or "Appearance"
    for _,button in ipairs(window.tabs or {}) do button:SetActive(button.pageKey==page) end
    local pane=F.Reset(window.child)
    if pane.blizzardPreview then pane.blizzardPreview:Hide() end
    local meta
    for _,entry in ipairs(pages) do if entry.key==page then meta=entry break end end
    F.Section(pane,meta and meta.label or page,page~="Blizzard Party / Raid" and meta and meta.help or nil)
    if page=="Blizzard Party / Raid" then
        F.Note(pane,meta.help)
        BlizzardGroupPreview(pane)
        F.Button(pane,"Move Blizzard Party / Raid",function() D.OpenBlizzardGroupMover() end)
        F.Note(pane,"Sample styling only. Your live layout and visibility are controlled by Blizzard and your group status.")
    end

    if page=="Appearance" then
        F.Dropdown(pane,"Default font",MattMinimalFramesDB.globalFont or "MMF Game Default",FontEntries(),function(v)
            if not CanEdit() then return end
            if MMF_SetGlobalFont then MMF_SetGlobalFont(v) else MattMinimalFramesDB.globalFont=v end
            Apply()
        end,MattMinimalFramesDB.globalFont or "Game default")
        F.Button(pane,"Use the default font on every text element",function()
            D.Confirm("Apply the default font to every MMF text element? Sizes and positions will stay the same.",function()
                local font=MMF_GetGlobalFontPath()
                for _,entry in ipairs(D.unitTypes) do
                    if D.Supports(entry.key) then
                        D.PushHistory(entry.key)
                        for id,cfg in pairs(D.UnitDesign(entry.key).elements) do
                            local spec=D.catalogByID[id]
                            if spec and (spec.kind=="text" or spec.kind=="auraText") then cfg.font=font end
                        end
                    end
                end
                D.ApplyAll();D.RefreshDesigner();D.RefreshSettings()
            end)
        end,"This does not change text sizes or positions.")
        F.Toggle(pane,"Override bar textures for all elements",Value("overrideBarTextures")==true,function(v)
            if not CanEdit() then return end
            MattMinimalFramesDB.overrideBarTextures=v==true
            if MMF_ApplyStatusBarTexture then MMF_ApplyStatusBarTexture() end
            Apply()
        end,"When enabled, the selected texture is applied to every MMF health, power, cast, healing, and class-resource bar.")
        local textures=TextureEntries()
        if #textures>0 and Value("overrideBarTextures")==true then
            F.Dropdown(pane,"Default bar texture",MattMinimalFramesDB.statusBarTexture,textures,function(v)
                if not CanEdit() then return end
                if MMF_SetStatusBarTexture then MMF_SetStatusBarTexture(v) else MattMinimalFramesDB.statusBarTexture=v end
                Apply()
            end,MattMinimalFramesDB.statusBarTexture or "Default")
        end
        F.Toggle(pane,"Text shadows",Value("useTextShadow")~=false,function(v) Change("useTextShadow",v) end)
        F.Toggle(pane,"Health color changes as health drops",Value("useHealthGradientColor")==true,function(v) Change("useHealthGradientColor",v) end)
        F.Note(pane,"MMF uses Naowh, Minimalistic, and Championship directly from your existing Fonts folder when those files are installed.")
    elseif page=="Utilities" then
        F.Toggle(pane,"Show beta welcome when opening MMF",not (MattMinimalFramesGlobalDB and MattMinimalFramesGlobalDB.hideBetaWelcome10),function(v)
            MattMinimalFramesGlobalDB=MattMinimalFramesGlobalDB or {}
            MattMinimalFramesGlobalDB.hideBetaWelcome10=not v
        end)
        F.Toggle(pane,"Show minimap button",not (MattMinimalFramesDB.minimap and MattMinimalFramesDB.minimap.hide),function(v)
            if not CanEdit() then return end
            MattMinimalFramesDB.minimap=MattMinimalFramesDB.minimap or {};MattMinimalFramesDB.minimap.hide=not v
            local lib=LibStub and LibStub("LibDBIcon-1.0",true)
            if lib then if v then lib:Show("MattMinimalFrames") else lib:Hide("MattMinimalFrames") end end
            D.RefreshSettings()
        end)
        F.Toggle(pane,"Play interface sounds",Value("uiSoundsEnabled")~=false,function(v) Change("uiSoundsEnabled",v) end)
        F.Button(pane,"Print diagnostic information",function() D.Notify(D.Diagnostics()) end)
    else
        AddStandardOptions(pane,page)
        if page=="Names" then F.Note(pane,"Select a Name element on the Designer tab for font, color, alignment, and per-frame options.") end
        if page=="Visibility" then F.Note(pane,"Select Whole frame on the Designer tab for visibility settings that apply to only one frame.") end
        if page=="Healing" then F.Note(pane,"Select incoming healing, absorb, or dispel elements in the preview to move and style them.") end
        if page=="Gameplay" then F.Note(pane,"Select Buffs or Debuffs in the preview to change filtering, rows, spacing, and growth direction.") end
    end
    pane:SetHeight(math.max(1,-pane.cursor+18))
end

function D.BuildSettingsPage(page,window)
    D.settingsWindow=page;page.pageKey="Appearance"
    local title=Label(page,"Global settings",18,{.95,.78,.34,1});title:SetPoint("TOPLEFT",10,-8)
    local subtitle=Label(page,"Simple options that affect more than one frame.",11,{.66,.68,.72,1});subtitle:SetPoint("TOPLEFT",10,-36)
    page.tabs={}
    for i,entry in ipairs(pages) do
        local pageKey=entry.key
        local pageLabel=entry.label
        local button=SafeButton(page,pageLabel,175,function()
            page.pageKey=pageKey
            if page.scroll and page.scroll.SetVerticalScroll then page.scroll:SetVerticalScroll(0) end
            D.RefreshSettings()
        end)
        button.pageKey=pageKey;button:SetPoint("TOPLEFT",8,-76-(i-1)*35);page.tabs[i]=button
    end
    local inset=CreateFrame("Frame",nil,page,"BackdropTemplate")
    D.UI.Backdrop(inset,D.UI.Palette.inset,D.UI.Palette.edgeSoft)
    inset:SetPoint("TOPLEFT",200,-70);inset:SetPoint("BOTTOMRIGHT",0,0)
    page.scroll,page.child=Scroll(inset);page.scroll:SetPoint("TOPLEFT",6,-6);page.scroll:SetPoint("BOTTOMRIGHT",-24,6);page.child:SetWidth(420)
end

function D.OpenSettings()
    D.Open();D.SelectMainTab("Settings");D.RefreshSettings()
end

function D.OpenBlizzardGroups()
    if not D.settingsWindow then D.Open() end
    D.settingsWindow.pageKey="Blizzard Party / Raid"
    D.settingsWindow.scroll:SetVerticalScroll(0)
    D.SelectMainTab("Settings")
end

function D.OpenBlizzardGroupMover()
    if InCombatLockdown() then D.Notify("Leave combat before moving Blizzard frames.");return end
    if not EditModeManagerFrame and C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_EditMode")
    end
    if not EditModeManagerFrame then
        D.Notify("This client does not provide Blizzard Edit Mode. Use its native party/raid frame controls.")
        return
    end
    D.SetMoveMode(false)
    if D.window then D.window:Hide() end
    ShowUIPanel(EditModeManagerFrame)
end



function D.AddFriendlyLegacyTextOptions(pane,key,id,cfg)
    local prefix=key=="targettarget" and "tot" or key
    local function Has(setting) return MattMinimalFrames_Defaults and MattMinimalFrames_Defaults[setting]~=nil end
    local function ToggleSetting(label,suffix)
        local setting=prefix..suffix
        if Has(setting) then F.Toggle(pane,label,Value(setting)==true,function(v) Change(setting,v) end) end
    end
    if id=="name" then
        F.Section(pane,"What the name shows")
        ToggleSetting("Include the unit's level","ShowNameLevel")
        ToggleSetting("Use class colors for players","ColorPlayerNameTextByClass")
        ToggleSetting("Use reaction colors for NPCs","ColorNPCNameTextByReaction")
    elseif id=="healthText" then
        local unit=D.UnitDesign(key)
        F.Section(pane,"What the health text shows")
        F.Toggle(pane,"Show the health amount",unit.showHealthValue~=false,function(v) D.CommitDesignerValue(key,"frame","showHealthValue",v) end)
        F.Toggle(pane,"Show the percentage",unit.showHealthPercent==true,function(v) D.CommitDesignerValue(key,"frame","showHealthPercent",v) end)
        ToggleSetting("Shorten large numbers","HPTextUseShortValue")
    elseif id=="powerText" and (key=="player" or key=="target") then
        local setting=key.."PowerTextMode"
        F.Section(pane,"What the power text shows")
        F.Dropdown(pane,"Text format",Value(setting),{
            {label="Amount",value="value"},{label="Percentage",value="percent"},
            {label="Amount and percentage",value="both"},{label="Amount with white percentage",value="both_white_percent"},
        },function(v) Change(setting,v) end)
        local color="color"..(key=="player" and "Player" or "Target").."PowerTextByResource"
        F.Toggle(pane,"Use the resource's color",Value(color)~=false,function(v) Change(color,v) end)
        if key=="player" then F.Toggle(pane,"Show mana while shapeshifted (Druid)",Value("showDruidManaPowerText")==true,function(v) Change("showDruidManaPowerText",v) end) end
    end
end
D.AddLegacyContextControls=D.AddFriendlyLegacyTextOptions

function D.ShowBetaWelcome()
    if InCombatLockdown() or not D.window or not D.window:IsShown() then return end
    MattMinimalFramesGlobalDB=MattMinimalFramesGlobalDB or {}
    local popup=D.betaWelcome
    if not popup then
        local UI=D.UI
        popup=CreateFrame("Frame","MMFBetaWelcome10",D.window,"BackdropTemplate")
        popup:Hide()
        D.betaWelcome=popup
        UI.Backdrop(popup,UI.Palette.bg,UI.Palette.accent)
        popup:SetSize(560,535);popup:SetPoint("CENTER",D.window,"CENTER")
        popup:SetFrameLevel(D.window:GetFrameLevel()+1000);popup:EnableMouse(true)
        local title=UI.Label(popup,"Matt's Minimal Frames 10.0",21,UI.Palette.text)
        title:SetPoint("TOPLEFT",24,-22)
        local badge=UI.Label(popup,"WORK IN PROGRESS",12,UI.Palette.section)
        badge:SetPoint("TOPLEFT",24,-54)
        local body=UI.Label(popup,"Welcome to the 10.0 beta!\n\nI’ve tried my best to make the new MMF as simple and user-friendly as possible, while still giving you plenty of control over your frames. Since this is a beta, there may still be bugs, unfinished features, or things that could simply work better.\n\nUse |cff9de8dfDesigner|r to customize your frames and |cff9de8dfEdit Mode|r to move them around. Your changes are saved to your current profile.\n\nYour 9.0 profiles migrate automatically. If anything doesn't carry over correctly, I'm sorry for the disruption. I believe the redesign is worth the transition, and your reports will help me smooth out the remaining issues.\n\nIf something feels confusing, you have a suggestion, or you run into a bug, please come by the Discord and let me know. Feedback is especially helpful right now while I’m still refining everything.\n\nThanks for testing MMF 10.0 and helping me make it better.",12,UI.Palette.text)
        body:SetPoint("TOPLEFT",24,-82);body:SetWidth(512)
        body:SetWordWrap(true);body:SetJustifyV("TOP")
        local linkLabel=UI.Label(popup,"Discord · select the link and press Ctrl+C",10,UI.Palette.section)
        linkLabel:SetPoint("TOPLEFT",body,"BOTTOMLEFT",0,-20)
        local link=UI.EditBox(popup,512);link:SetPoint("TOPLEFT",linkLabel,"BOTTOMLEFT",0,-8)
        local url="https://discord.gg/9w6ZdaksDX"
        link:SetText(url)
        link:SetScript("OnEditFocusGained",function(self) self:HighlightText() end)
        link:SetScript("OnTextChanged",function(self,user) if user then self:SetText(url);self:HighlightText() end end)
        link:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        link:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
        popup.suppress=UI.Check(popup,"Don't show automatically again",function(value)
            MattMinimalFramesGlobalDB.hideBetaWelcome10=value==true
            if D.settingsWindow and D.settingsWindow:IsShown() then D.RefreshSettings() end
        end)
        popup.suppress:SetPoint("TOPLEFT",link,"BOTTOMLEFT",0,-14);popup.suppress:SetWidth(330)
        local close=UI.Button(popup,"Got it",110,function() popup:Hide() end)
        close:SetPoint("TOPRIGHT",link,"BOTTOMRIGHT",0,-14)
        popup:SetScript("OnHide",function() link:ClearFocus() end)
        popup.LayoutWelcome=function()
            
            body:SetHeight(0)
            local textHeight=math.ceil(body:GetStringHeight())
            body:SetHeight(textHeight)
            popup:SetHeight(82+textHeight+20+math.ceil(linkLabel:GetStringHeight())+8+link:GetHeight()+14+math.max(popup.suppress:GetHeight(),close:GetHeight())+18)
        end
        UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"MMFBetaWelcome10")
    end
    popup.suppress:SetValue(MattMinimalFramesGlobalDB.hideBetaWelcome10==true)
    popup:Show();popup:Raise()
    popup.LayoutWelcome()
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent",function()
    if D.betaWelcome and D.betaWelcome:IsShown() then D.betaWelcome:Hide() end
    if D.window then D.window:Hide() end
    if D.colorPickerActive and ColorPickerFrame and ColorPickerFrame.Hide then ColorPickerFrame:Hide() end
end)
