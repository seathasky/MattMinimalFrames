
local _, ns = ...
local D = {}
_G.MMF_Designer = D
if ns then ns.Designer = D end
D.VERSION = "10.0.0-designer-shared-preview1-rebuilt"
D.SCHEMA = 1
D.frames, D.history = {}, {}
D.points = {"CENTER", "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
D.unitTypes = {
    {key="player", label="Player", token="player"},
    {key="target", label="Target", token="target"},
    {key="targettarget", label="Target of Target", token="targettarget"},
    {key="focus", label="Focus", token="focus", focus=true},
    {key="focustarget", label="Target of Focus", token="focustarget", focus=true, optional=true},
    {key="pet", label="Pet", token="pet"},
    {key="pettarget", label="Pet Target", token="pettarget", optional=true},
    {key="boss", label="Boss", token="boss1", count=5},
    {key="party", label="Party", token="party1", count=4, optional=true},
    {key="raid", label="Raid", token="raid1", count=40, optional=true},
    {key="arena", label="Arena", token="arena1", count=5, optional=true, arena=true},
    {key="partypet", label="Party Pets", token="partypet1", count=4, optional=true},
    {key="raidpet", label="Raid Pets", token="raidpet1", count=40, optional=true},
    {key="vehicle", label="Vehicle", token="vehicle", optional=true, vehicle=true},
}
D.byUnitType = {}
for _, entry in ipairs(D.unitTypes) do D.byUnitType[entry.key] = entry end

function D.Readable(value)
    return not (issecretvalue and issecretvalue(value))
        and not (canaccessvalue and not canaccessvalue(value))
end
function D.Number(value, fallback, minimum, maximum)
    if not D.Readable(value) or type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        value = fallback or 0
    end
    if minimum then value = math.max(minimum, value) end
    if maximum then value = math.min(maximum, value) end
    return value
end
function D.Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}; seen[value] = result
    for key, item in pairs(value) do result[D.Copy(key, seen)] = D.Copy(item, seen) end
    return result
end
function D.Round(value, step)
    step = D.Number(step, 1, 0.5, 64)
    return math.floor(value / step + 0.5) * step
end
function D.Key(unit)
    if type(unit) ~= "string" or not D.Readable(unit) then return nil end
    if D.byUnitType[unit] then return unit end
    for _, prefix in ipairs({"partypet", "raidpet", "party", "raid", "arena", "boss"}) do
        if unit:match("^" .. prefix .. "%d+$") then return prefix end
    end
    return nil
end
D.suspendedUnitTypes = {party=true, raid=true, partypet=true, raidpet=true}
function D.Supports(key)
    if D.suspendedUnitTypes[key] then return false, "Use Blizzard Party / Raid settings for group frames." end
    local entry = D.byUnitType[key]
    if not entry then return false, "Unknown unit type" end
    local compat = _G.MMF_Compat or {}
    if entry.focus and compat.HasFocusFrame == false then return false, "This client does not provide a native focus unit." end
    if entry.arena and compat.IsClassic and not compat.IsForever then return false, "Arena units are not available in Classic Era." end
    if entry.vehicle and type(UnitInVehicle) ~= "function" then return false, "This client does not expose vehicle units." end
    return true
end
function D.Profile()
    MattMinimalFramesDB = MattMinimalFramesDB or {}
    local db = MattMinimalFramesDB
    if type(db.designer) ~= "table" then
        
        MattMinimalFramesGlobalDB = MattMinimalFramesGlobalDB or {}
        local backups = MattMinimalFramesGlobalDB.designerV9Backups or {}
        MattMinimalFramesGlobalDB.designerV9Backups = backups
        local name = MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default"
        if not backups[name] then backups[name] = D.Copy(db) end
        db.designer = {version=D.SCHEMA, units={}, snap=1, zoom=1.5, showGrid=true}
    end
    local profile = db.designer
    if type(profile.units) ~= "table" then profile.units = {} end
    profile.version = D.SCHEMA
    profile.snap = D.Number(profile.snap, 1, 0.5, 32)
    profile.zoom = D.Number(profile.zoom, 1.5, 0.01, 4)
    if D.NormalizeBarTextureDefaults then D.NormalizeBarTextureDefaults(profile) end
    if D.NormalizeLeaderIndicatorLayout then D.NormalizeLeaderIndicatorLayout(profile) end
    if D.NormalizeEmptyTextSizes then D.NormalizeEmptyTextSizes(profile) end
    return profile
end



D.catalog = {}
D.catalogByID = {}
local MELLI_TEXTURE = (MMF_Config and MMF_Config.TEXTURE_PATH)
    or "Interface\\AddOns\\MattMinimalFrames\\Textures\\Melli.tga"
local function Element(id, label, kind, field, parent, width, height, x, y, enabled, only)
    local entry = {id=id, label=label, kind=kind, field=field, parent=parent or "frame", only=only,
        defaults={point="CENTER", relativePoint="CENTER", relativeTo=parent or "frame", x=x or 0, y=y or 0,
            width=width or 20, height=height or 20, scale=1, opacity=1, enabled=enabled~=false,
            layer=(kind=="text" and 15 or 2), fontSize=12, fontFlags="OUTLINE", justify="CENTER", colorMode="auto"}}
    if kind=="text" or kind=="auraText" then
        entry.defaults.font="Interface\\AddOns\\MattMinimalFrames\\Fonts\\Naowh.ttf"
    end
    if kind=="bar" then
        entry.defaults.texture=MELLI_TEXTURE
    end
    D.catalog[#D.catalog+1], D.catalogByID[id] = entry, entry
    return entry
end
Element("health", "Health bar", "bar", "healthBar", nil, 218, 26)
Element("healthBackground", "Health background", "texture", "healthBarBG", "health", 218, 26)
Element("healthBorder", "Health border", "group", "healthBarBorder", "health", 220, 28)
for _, edge in ipairs({"top", "right", "bottom", "left"}) do
    Element("healthBorder."..edge, "Border: "..edge, "texture", "healthBarBorderEdges."..edge, "healthBorder",
        (edge=="left" or edge=="right") and 1 or 220, (edge=="top" or edge=="bottom") and 1 or 26)
end
Element("name", "Name", "text", "nameText", nil, 216, 18, 0, 18)
Element("healthText", "Health text", "text", "hpText", "health", 130, 18, -4, 0)
Element("power", "Power bar group", "group", "powerBarFrame", nil, 220, 5, 0, -16)
Element("powerFill", "Power bar", "bar", "powerBar", "power", 218, 3)
Element("powerBackground", "Power background", "texture", "powerBarBG", "power", 218, 3)
Element("powerBorder", "Power border", "texture", "powerBarBorder", "power", 220, 5)
Element("powerText", "Power text", "text", "powerText", "health", 100, 16, 4, 0, false)
Element("secondaryPower", "Secondary mana bar", "bar", "secondaryPowerBar", "power", 218, 3, 0, -5, true, "player")
Element("secondaryPowerBackground", "Secondary mana background", "texture", "secondaryPowerBarBG", "secondaryPower", 218, 3, 0, 0, true, "player")
Element("myHeal", "Your incoming heals", "bar", "myHealPrediction", "health", 218, 26)
Element("otherHeal", "Other incoming heals", "bar", "otherHealPrediction", "health", 218, 26)
Element("absorb", "Absorb shield", "bar", "absorbBar", "health", 218, 26)
Element("healAbsorb", "Healing absorb", "bar", "healAbsorbBar", "health", 218, 26)
for _, id in ipairs({"myHeal", "otherHeal", "absorb", "healAbsorb"}) do
    
    
    D.catalogByID[id].defaults.followHealth = true
    D.catalogByID[id].dynamic = true
end
Element("dispel", "Dispel highlight", "texture", "dispelHighlight", "health", 218, 26)
Element("hover", "Mouseover highlight", "texture", "highlightTexture", "health", 220, 28)
Element("cast", "Cast bar group", "group", "castBarFrame", nil, 220, 8, 0, -42)
Element("castFill", "Cast bar", "bar", "castBar", "cast", 220, 8)
Element("castBackground", "Cast background", "texture", "castBarBG", "cast", 220, 8)
Element("castBorder", "Cast border", "texture", "castBarBorder", "cast", 222, 10)
Element("castName", "Cast spell name", "text", "castBarText", "cast", 170, 16, -20, 0)
Element("castTime", "Cast remaining time", "text", "castBarTime", "cast", 36, 16, 90, 0)
Element("castIcon", "Cast spell icon", "icon", "designerCastIcon", "cast", 18, 18, -123, 0, false)
Element("castShield", "Uninterruptible indicator", "icon", "designerCastShield", "cast", 16, 16, 121, 0, false)
for _, id in ipairs({"buffs", "debuffs"}) do
    local field = id=="buffs" and "BuffContainer" or "DebuffContainer"
    local title = id=="buffs" and "Buffs" or "Debuffs"
    local spec = Element(id, title, "auras", field, nil, 78, 38, id=="buffs" and -68 or 68, 50)
    spec.defaults.iconSize, spec.defaults.columns, spec.defaults.rows = 18, 4, 2
    spec.defaults.spacing, spec.defaults.growth = 2, id=="buffs" and "RIGHT_UP" or "LEFT_UP"
    spec.defaults.point=id=="buffs" and "BOTTOMLEFT" or "BOTTOMRIGHT"
    spec.defaults.relativePoint=id=="buffs" and "TOPLEFT" or "TOPRIGHT"
    spec.defaults.relativeTo="health"
    spec.defaults.x,spec.defaults.y=0,8
    spec.defaults.filter, spec.defaults.maxIcons = "all", 16
    Element(id..".icon", title..": icon", "auraIcon", nil, id, 18, 18).auraSub = "icon"
    Element(id..".count", title..": stack text", "auraText", nil, id, 20, 12, 0, -4).auraSub = "count"
    Element(id..".timer", title..": cooldown text", "auraText", nil, id, 26, 14).auraSub = "timer"
    Element(id..".cooldown", title..": cooldown sweep", "auraCooldown", nil, id, 18, 18).auraSub = "cooldown"
    Element(id..".border", title..": border", "auraBorder", nil, id, 20, 20).auraSub = "border"
    D.catalogByID[id..".count"].defaults.fontSize=10
    D.catalogByID[id..".timer"].defaults.fontSize=10
end
Element("portrait", "Portrait / class icon", "icon", "designerPortrait", nil, 28, 28, -128, 0, false).defaults.iconMode="class"
Element("portraitModel", "Animated portrait model", "model", "portraitModel", nil, 28, 28, -128, 0)
Element("happinessBorder", "Pet happiness border", "texture", "petHappinessBorder", "happiness", 20, 20, 0, 0, true, "pet")
for _,edge in ipairs({"top","right","bottom","left"}) do
    Element("combatOutline."..edge,"Combat frame outline: "..edge,"texture","combatFrameOutlineEdges."..edge,"frame",
        (edge=="left" or edge=="right") and 1 or 222,(edge=="top" or edge=="bottom") and 1 or 30,0,0,true,"player")
end
for index=1,8 do
    Element("combatIconOutline"..index,"Combat icon outline "..index,"texture","combatIconOutlineTextures."..index,"combat",22,22,0,0,true,"player")
end
Element("raidMarker", "Raid target marker", "icon", "targetMarker", nil, 18, 18, 0, 34)
Element("pvp", "PvP status", "text", "pvpFlagText", nil, 28, 16, 122, 8, false)
Element("level", "Level", "text", "designerLevel", nil, 32, 16, -124, 18, false)
Element("classification", "Elite / rare classification", "text", "designerClassification", nil, 44, 16, 128, 0, false)
Element("status", "Dead / ghost / offline status", "text", "designerStatus", "health", 160, 18)
local leaderElement=Element("leader", "Leader / assistant", "icon", "designerLeader", nil, 14, 14, 2, -2, false)
leaderElement.defaults.point,leaderElement.defaults.relativePoint="TOPLEFT","TOPLEFT"
Element("role", "Group role", "icon", "designerRole", nil, 14, 14, -114, 18, false)
Element("ready", "Ready check", "icon", "designerReady", nil, 20, 20, 0, 0)
Element("resurrection", "Incoming resurrection", "icon", "designerResurrection", nil, 20, 20, 30, 0)
Element("combat", "Combat indicator", "icon", "combatTexture", nil, 22, 22, 0, 12, true, "player")
Element("resting", "Resting indicator", "icon", "restingTexture", nil, 20, 20, 0, 12, true, "player")
Element("happiness", "Pet happiness", "icon", "designerHappiness", nil, 18, 18, 60, 0, true, "pet")
Element("resources", "Class resource group", "group", "designerResources", nil, 220, 8, 0, -60, false, "player")
D.catalogByID.resources.defaults.point="TOP"
D.catalogByID.resources.defaults.relativePoint="BOTTOM"
D.catalogByID.resources.defaults.relativeTo="cast"
D.catalogByID.resources.defaults.y=-18
Element("resources.background", "Class resource background", "texture", "designerResources.bg", "resources", 220, 8, 0, 0, true, "player")
D.catalogByID["resources.background"].defaults.drawLayer="BACKGROUND"
D.catalogByID["resources.background"].defaults.layer=0
for i=1,10 do
    Element("resource"..i, "Class resource "..i, "bar", "designerResources.runes."..i, "resources", 34, 6, -92+(i-1)*37, 0, true, "player")
    Element("resource"..i..".background", "Resource "..i.." background", "texture", "designerResources.runes."..i..".bg", "resource"..i, 34, 6, 0, 0, true, "player")
    D.catalogByID["resource"..i..".background"].defaults.drawLayer="BACKGROUND"
    D.catalogByID["resource"..i..".background"].defaults.layer=0
end
Element("resourceText", "Class resource value", "text", "designerResources.valueText", "resources", 50, 16, 0, 0, true, "player")

function D.PlaceCastPart(cfg,id,width)
    local name=id=="castName"
    local text=name or id=="castTime"
    cfg.relativeTo="cast"
    cfg.point=(name or id=="castShield") and "LEFT" or "RIGHT"
    cfg.relativePoint=text and cfg.point or (id=="castIcon" and "LEFT" or "RIGHT")
    cfg.x=(name or id=="castShield") and 4 or -4
    cfg.y=0
    if text then
        cfg.justify=name and "LEFT" or "RIGHT";cfg.justifyV="MIDDLE"
        cfg.width=name and math.max(12,width-44) or 36
        cfg.fitTextToContent=nil;cfg.textSizeReference=nil
    end
end
for _,id in ipairs({"castName","castTime","castIcon","castShield"}) do
    D.PlaceCastPart(D.catalogByID[id].defaults,id,220)
end
function D.PlaceBossAuras(cfg,id)
    cfg.relativeTo="health";cfg.point="RIGHT";cfg.relativePoint="LEFT"
    cfg.x=-8;cfg.y=id=="buffs" and 20 or 0
    cfg.growth="LEFT_DOWN";cfg.columns=4;cfg.rows=1;cfg.maxIcons=4
    cfg.iconSize=16;cfg.spacing=2;cfg.enabled=id=="debuffs"
end

function D.PlaceValueTextInside(cfg,id)
    local side=id=="powerText" and "LEFT" or "RIGHT"
    cfg.point,cfg.relativePoint,cfg.relativeTo=side,side,"health"
    cfg.x,cfg.y=id=="powerText" and 4 or -4,0
    cfg.justify,cfg.justifyV=side,"MIDDLE"
    cfg.fitTextToContent=true
    cfg.textSizeReference=nil
end
for _,id in ipairs({"healthText","powerText"}) do
    D.PlaceValueTextInside(D.catalogByID[id].defaults,id)
end

function D.NormalizeLeaderIndicatorLayout(profile)
    if profile.leaderIndicatorLayoutMigrated then return end
    local function MigrateLeader(elements,key)
        local cfg=type(elements)=="table" and elements.leader
        if type(cfg)~="table" then return end
        local x,y=tonumber(cfg.x),tonumber(cfg.y)
        local oldDefault=cfg.point=="CENTER" and cfg.relativePoint=="CENTER"
            and (cfg.relativeTo==nil or cfg.relativeTo=="frame")
            and x and y and math.abs(x+96)<1 and math.abs(y-31)<1
        if not oldDefault then return end
        local target=key=="target"
        cfg.point=target and "TOPRIGHT" or "TOPLEFT"
        cfg.relativePoint=cfg.point
        cfg.relativeTo="frame"
        cfg.x=target and -2 or 2
        cfg.y=-2
    end
    for key,unit in pairs(profile.units or {}) do
        if type(unit)=="table" then
            MigrateLeader(unit.elements,key)
            if type(unit.baseline)=="table" then MigrateLeader(unit.baseline.elements,key) end
        end
    end
    profile.leaderIndicatorLayoutMigrated=true
end

function D.NormalizeBarTextureDefaults(profile)
    if profile.melliTextureDefaultsMigrated then return end
    local function NormalizeElements(elements)
        if type(elements)~="table" then return end
        for id, cfg in pairs(elements) do
            local spec=D.catalogByID[id]
            if spec and spec.kind=="bar" and type(cfg)=="table" then
                local texture=cfg.texture
                if type(texture)~="string" or texture=="" or texture:match("^-?%d+$") then
                    cfg.texture=MELLI_TEXTURE
                end
            end
        end
    end
    for _, unit in pairs(profile.units or {}) do
        if type(unit)=="table" then
            NormalizeElements(unit.elements)
            if type(unit.baseline)=="table" then NormalizeElements(unit.baseline.elements) end
        end
    end
    profile.melliTextureDefaultsMigrated=true
end

function D.NormalizeEmptyTextSizes(profile)
    if profile.emptyTextSizesMigrated then return end
    local function Repair(elements, frameWidth)
        if type(elements)~="table" then return end
        for id,cfg in pairs(elements) do
            local spec=D.catalogByID[id]
            
            
            if spec and spec.kind=="text" and type(cfg)=="table"
                and type(cfg.width)=="number" and cfg.width<=1.01 then
                cfg.width=math.min(spec.defaults.width, D.Number(frameWidth,220,20,1000))
                cfg.height=math.max(D.Number(cfg.height,spec.defaults.height),spec.defaults.height,cfg.fontSize or 12)
                cfg.textSizeReference=nil
            end
        end
    end
    for _,unit in pairs(profile.units or {}) do
        if type(unit)=="table" then
            Repair(unit.elements,unit.width)
            if type(unit.baseline)=="table" then Repair(unit.baseline.elements,unit.baseline.width or unit.width) end
        end
    end
    profile.emptyTextSizesMigrated=true
end

function D.Resolve(frame, path)
    if not frame or not path then return nil end
    local current = frame
    for part in path:gmatch("[^.]+") do
        if current == nil then return nil end
        current = current[tonumber(part) or part]
    end
    return current
end
function D.Catalog(key, frame)
    local result = {}
    for _, spec in ipairs(D.catalog) do
        if not spec.only or spec.only == key then
            
            local resource = spec.id:match("^resource")
            if (not resource or not frame or D.Resolve(frame, spec.field)) and
                (not frame or spec.auraSub or D.Resolve(frame,spec.field)) then
                result[#result+1] = spec
            end
        end
    end
    return result
end
local hiddenKeys = {player="hidePlayerFrame", target="hideTargetFrame", targettarget="hideTargetOfTargetFrame", pet="hidePetFrame", focus="hideFocusFrame", boss="hideBossFrames"}
function D.UnitDesign(key)
    key = D.Key(key) or key
    local entry = D.byUnitType[key]
    if not entry then return nil end
    local profile = D.Profile()
    local unit = profile.units[key]
    if type(unit) ~= "table" then
        local compact = key~="player" and key~="target"
        unit = {width=compact and 100 or 220, height=28, scale=1, elements={}, enabled=not entry.optional,
            outsideCombatAlpha=1, groupColumns=(key=="raid" or key=="raidpet") and 5 or 1, groupSpacing=10}
        local legacyHide = hiddenKeys[key]
        if legacyHide and MattMinimalFramesDB[legacyHide] then unit.enabled=false end
        profile.units[key] = unit
    end
    if type(unit.elements) ~= "table" then unit.elements={} end
    unit.width = D.Number(unit.width, 220, 20, 1000)
    unit.height = D.Number(unit.height, 28, 4, 400)
    unit.scale = D.Number(unit.scale, 1, 0.25, 3)
    return unit
end
D.bossElementDefaults={
    raidMarker=true,
    portrait=false,portraitModel=false,level=false,classification=false,pvp=false,
    status=false,leader=false,role=false,ready=false,resurrection=false,combat=false,resting=false,
    myHeal=false,otherHeal=false,absorb=false,healAbsorb=false,dispel=false,hover=false,
}
for _,edge in ipairs({"top","right","bottom","left"}) do D.bossElementDefaults["combatOutline."..edge]=false end
for i=1,8 do D.bossElementDefaults["combatIconOutline"..i]=false end

function D.ApplyBossElementDefaults(unit)
    if unit.bossElementDefaultsV1 then return end
    for id,enabled in pairs(D.bossElementDefaults) do
        if unit.elements[id] then unit.elements[id].enabled=enabled end
        local baseline=unit.baseline and unit.baseline.elements
        if baseline and baseline[id] then baseline[id].enabled=enabled end
    end
    unit.bossElementDefaultsV1=true
end

function D.ElementDesign(key, id)
    local unit = D.UnitDesign(key)
    local spec = D.catalogByID[id]
    if not unit or not spec then return nil end
    if type(unit.elements[id]) ~= "table" then
        unit.elements[id] = D.Copy(spec.defaults)
        if key=="boss" and D.bossElementDefaults[id]~=nil then unit.elements[id].enabled=D.bossElementDefaults[id] end
        if key=="boss" and (id=="buffs" or id=="debuffs") then D.PlaceBossAuras(unit.elements[id],id) end
        if unit.width < 150 and (id=="health" or id=="healthBackground") then unit.elements[id].width=unit.width-2 end
        if id=="leader" and key=="target" then
            unit.elements[id].point,unit.elements[id].relativePoint="TOPRIGHT","TOPRIGHT"
            unit.elements[id].x,unit.elements[id].y=-2,-2
        end
    end
    if spec.kind=="bar" then
        local texture=unit.elements[id].texture
        
        
        
        if type(texture)~="string" or texture=="" or texture:match("^-?%d+$") then
            unit.elements[id].texture=MELLI_TEXTURE
        end
    end
    
    
    if (id=="resources.background" or id:match("^resource%d+%.background$"))
        and unit.elements[id].drawLayer==nil then
        unit.elements[id].drawLayer="BACKGROUND"
        unit.elements[id].layer=0
    end
    return unit.elements[id]
end
function D.IsUnitEnabled(unit)
    local key = D.Key(unit)
    return key and D.Supports(key) and D.UnitDesign(key).enabled ~= false or false
end



function D.RebuildResourceLayout(key)
    if key ~= "player" or not MMF_GetResourceVisualDefinition then return end
    local info = MMF_GetResourceVisualDefinition()
    if not info then return end
    local unit = D.UnitDesign(key)
    local signature = "2:" .. info.prefix .. ":" .. info.count
    if unit.resourceLayoutSignature == signature then return end
    local function Rebuild(elements)
        local group = elements and elements.resources
        if not group then return end
        local width = D.Number(group.width, 220, 1, 2000)
        local height = D.Number(group.height, 8, 1, 2000)
        local inset = math.min(1, width / (info.count * 4), height / 4)
        local gap = math.min(3, width / (info.count * 4))
        local segmentWidth = (width - inset * 2 - gap * (info.count - 1)) / info.count
        local segmentHeight = height - inset * 2
        local background = D.Copy(D.catalogByID["resources.background"].defaults)
        background.width, background.height = width, height
        elements["resources.background"] = background
        for i = 1, 10 do
            local id = "resource" .. i
            elements[id], elements[id .. ".background"] = nil, nil
            if i <= info.count then
                local segment = D.Copy(D.catalogByID[id].defaults)
                segment.width, segment.height = segmentWidth, segmentHeight
                segment.x = -width / 2 + inset + segmentWidth / 2 + (i - 1) * (segmentWidth + gap)
                segment.y = 0
                elements[id] = segment
                local bg = D.Copy(D.catalogByID[id .. ".background"].defaults)
                bg.width, bg.height = segmentWidth, segmentHeight
                elements[id .. ".background"] = bg
            end
        end
    end
    Rebuild(unit.elements)
    if unit.baseline then Rebuild(unit.baseline.elements) end
    unit.resourceLayoutSignature = signature
end
function D.IsEnabled(unit, id)
    local key = D.Key(unit)
    if not key then return false end
    local db = MattMinimalFramesDB
    local profile = db and type(db.designer)=="table" and db.designer
    local unitDesign = profile and type(profile.units)=="table" and profile.units[key]
    local elements = type(unitDesign)=="table" and type(unitDesign.elements)=="table" and unitDesign.elements
    local spec = elements and elements[id]
    if type(spec)~="table" then spec = D.ElementDesign(key, id) end
    return spec and spec.enabled ~= false or false
end
function D.SetParent(key, id, parent)
    local unit = D.UnitDesign(key)
    if not unit or not D.catalogByID[id] then return false end
    if parent~="frame" and not D.catalogByID[parent] then return false end
    local seen = {[id]=true}; local current = parent
    while current and current~="frame" do
        if seen[current] then return false end
        seen[current]=true
        local other = D.ElementDesign(key, current)
        current = other and other.relativeTo or "frame"
    end
    D.ElementDesign(key, id).relativeTo = parent
    return true
end
function D.ValidateElement(key, id)
    local value = D.ElementDesign(key, id)
    if not value then return end
    for _, prop in ipairs({"point", "relativePoint"}) do
        local found=false
        for _, point in ipairs(D.points) do if point==value[prop] then found=true; break end end
        if not found then value[prop]="CENTER" end
    end
    value.x=D.Number(value.x,0,-4000,4000); value.y=D.Number(value.y,0,-4000,4000)
    value.width=D.Number(value.width,20,1,2000); value.height=D.Number(value.height,20,1,2000)
    value.scale=D.Number(value.scale,1,0.1,5); value.opacity=D.Number(value.opacity,1,0,1)
    value.fontSize=D.Number(value.fontSize,12,6,96); value.layer=D.Number(value.layer,2,-8,100)
    if not D.SetParent(key,id,value.relativeTo or "frame") then value.relativeTo="frame" end
    return value
end
function D.PushHistory(key)
    local name = (MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default")..":"..key
    local history = D.history[name]
    if not history then history={undo={},redo={}}; D.history[name]=history end
    history.undo[#history.undo+1] = D.Copy(D.UnitDesign(key))
    if #history.undo>50 then table.remove(history.undo,1) end
    history.redo={}
end
function D.PushHistorySnapshot(key,snapshot)
    local name=(MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default")..":"..key
    local history=D.history[name]
    if not history then history={undo={},redo={}};D.history[name]=history end
    history.undo[#history.undo+1]=D.Copy(snapshot)
    if #history.undo>50 then table.remove(history.undo,1) end
    history.redo={}
end
function D.Undo(key, redo)
    local name = (MMF_GetActiveProfileName and MMF_GetActiveProfileName() or "Default")..":"..key
    local history=D.history[name]
    if not history then return false end
    local from, to = redo and history.redo or history.undo, redo and history.undo or history.redo
    if #from==0 then return false end
    to[#to+1]=D.Copy(D.UnitDesign(key))
    D.Profile().units[key]=table.remove(from)
    if D.ApplyUnit then D.ApplyUnit(key) end
    return true
end
function D.CopyDesign(source, destination)
    if source==destination or not D.byUnitType[source] or not D.byUnitType[destination] then return false end
    D.PushHistory(destination)
    local enabled=D.UnitDesign(destination).enabled
    local copy=D.Copy(D.UnitDesign(source)); copy.enabled=enabled
    for id in pairs(copy.elements) do
        local spec=D.catalogByID[id]
        if not spec or (spec.only and spec.only~=destination) then copy.elements[id]=nil end
    end
    copy.migrated=true
    D.Profile().units[destination]=copy
    if D.ApplyUnit then D.ApplyUnit(destination) end
    return true
end
function D.Notify(message)
    print("|cff63d6bfMMF Designer|r: "..tostring(message))
end
