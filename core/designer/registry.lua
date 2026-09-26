
local D=MMF_Designer
function D.Available(key,spec)
    if not D.Supports(key) then return false end
    if spec.only and spec.only~=key then return false end
    local id=spec.id
    if id=="leader" then return key=="player" or key=="party" or key=="raid" end
    if id=="happiness" or id=="happinessBorder" then return key=="pet" and type(GetPetHappiness)=="function" end
    if id=="secondaryPower" or id=="secondaryPowerBackground" then return key=="player" and MMF_Compat.IsRetail end
    if id:match("^combatIconOutline") then return key=="player" and (tonumber(id:match("(%d+)$")) or 0)<=4 end
    if id:match("^resource") then
        if key~="player" or not MMF_GetResourceVisualDefinition then return false end
        local info=MMF_GetResourceVisualDefinition()
        if not info then return false end
        local index=tonumber(id:match("^resource(%d+)"))
        if index then return index<=info.count end
        if id=="resourceText" then return info.hasText end
    end
    return true
end
function D.Catalog(key,frame)
    local result={}
    for _,spec in ipairs(D.catalog) do if D.Available(key,spec) then result[#result+1]=spec end end
    return result
end



D.componentSamples={
    leader={{label="Leader",value="leader"},{label="Assistant",value="assistant"}},
    role={{label="Tank",value="TANK"},{label="Healer",value="HEALER"},{label="Damage",value="DAMAGER"}},
    ready={{label="Ready",value="ready"},{label="Not ready",value="notready"},{label="Waiting",value="waiting"}},
    status={{label="Dead",value="DEAD"},{label="Ghost",value="GHOST"},{label="Offline",value="OFFLINE"}},
    classification={{label="Elite",value="Elite"},{label="Rare",value="Rare"},{label="Rare elite",value="Rare Elite"}},
    happiness={{label="Happy",value=3},{label="Content",value=2},{label="Unhappy",value=1}},
}
D.componentSamples.raidMarker={}
for index,label in ipairs({"Star","Circle","Diamond","Triangle","Moon","Square","Cross","Skull"}) do
    D.componentSamples.raidMarker[index]={label=label,value=index}
end
D.sampleChoices={}
D.sampleScenes={
    {label="Your design",value="normal"},{label="Low health",value="low"},{label="Casting",value="casting"},
    {label="Channeling",value="channel"},{label="Uninterruptible cast",value="uninterruptible"},
    {label="Buffs and debuffs",value="auras"},{label="Incoming healing and shields",value="healing"},
    {label="In combat",value="combat"},{label="Resting",value="resting"},
    {label="Group indicators",value="indicators"},{label="Class resources",value="resources"},
    {label="Dead / ghost / offline",value="status"},{label="All available elements",value="all"},
}
