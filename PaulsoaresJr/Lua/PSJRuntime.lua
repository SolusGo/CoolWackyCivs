-- The First Night, BNW + Community Patch v151. No timers or UI polling.
if rawget(_G, "__PSJ_RUNTIME_LOADED") then return end
rawset(_G, "__PSJ_RUNTIME_LOADED", true)
local save = Modding.OpenSaveData()
local I = GameInfoTypes
local CIV, SURVIVOR, HOUSE = I.CIVILIZATION_PSJ_FIRST_NIGHT, I.UNIT_PSJ_SURVIVOR, I.BUILDING_PSJ_STARTER_HOUSE
local LEARNING, ANCIENT, VETERAN = I.PROMOTION_PSJ_LEARNING, I.ERA_ANCIENT, I.PROMOTION_PSJ_BEGINNING
local MODERN, CLASSICAL = I.ERA_MODERN, I.ERA_CLASSICAL
local memories = {
    FIRST_SHELTER={10,0,0}, FIRST_NIGHT={5,5,0}, FIRST_DANGER={10,0,0},
    FIRST_MINE={0,10,0}, FIRST_HARVEST={5,0,5}, FIRST_JOURNEY={10,10,0},
    FIRST_FRIEND={10,0,0}, FIRST_WONDER={15,10,0}, BEYOND_HOME={15,0,0}, SOMETHING_NEW={10,10,0}
}
local memoryOrder = {"FIRST_SHELTER","FIRST_NIGHT","FIRST_DANGER","FIRST_MINE","FIRST_HARVEST",
    "FIRST_JOURNEY","FIRST_FRIEND","FIRST_WONDER","BEYOND_HOME","SOMETHING_NEW"}
local function key(pid, suffix) return "PSJ_V1_P" .. pid .. "_" .. suffix end
local function get(pid, suffix, fallback)
    local value = save.GetValue(key(pid, suffix))
    if value == nil then return fallback end
    return tonumber(value) or fallback
end
local function set(pid, suffix, value) save.SetValue(key(pid, suffix), value) end
local function now() return Game.GetGameTurn() end
local function paul(pid)
    local p = Players[pid]
    return p and p:IsAlive() and not p:IsMinorCiv() and not p:IsBarbarian() and p:GetCivilizationType() == CIV and p or nil
end
local function unit(pid, uid) local p=Players[pid]; return p and p:GetUnitByID(uid) or nil end
local function L(k, ...) return Locale.ConvertTextKey(k, ...) end
local function log(s) print("[PSJ] " .. s) end
local function notify(p, title, body, ...)
    if p and p:IsHuman() and p:GetID() == Game.GetActivePlayer() then
        p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, L(body,...), L(title))
    end
end
local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
local function scaled(n, kind)
    return math.floor(n * ((speed and tonumber(speed[kind .. "Percent"])) or 100) / 100 + 0.5)
end
local function reward(p, culture, science, food)
    local c,s,f = scaled(culture or 0,"Culture"),scaled(science or 0,"Research"),scaled(food or 0,"Growth")
    if c > 0 then p:ChangeJONSCulture(c) end
    if s > 0 then
        local tech = p:GetCurrentResearch()
        local team = Teams[p:GetTeam()]
        if tech and tech >= 0 and team then team:GetTeamTechs():ChangeResearchProgress(tech,s,p:GetID())
        else p:ChangeOverflowResearch(s) end
    end
    local capital = p:GetCapitalCity()
    if f > 0 and capital then capital:ChangeFood(f) end
    return c,s,f
end
local function earn(pid, name)
    local p = paul(pid)
    if not p or get(pid,"MEM_"..name,-1) >= 0 then return false end
    set(pid,"MEM_"..name,p:GetCurrentEra()) -- Commit marker before granting yields.
    local r = memories[name]
    local c,s,f = reward(p,r[1],r[2],r[3])
    notify(p,"TXT_KEY_PSJ_"..name,"TXT_KEY_PSJ_"..name.."_NOTICE",c,s,f)
    log("Memory earned: " .. name .. " for player " .. pid .. " in era " .. p:GetCurrentEra())
    return true
end

-- Identity lives on the unit, survives save/reload, and is explicitly copied on
-- same-owner upgrades. No reusable engine unit ID is used as persistent identity.
local marker = "%[PSJ1:([^%]]*)%]"
local fields = {"serial","origin","ancient","outside","lastTurn","returned","originArea","landmassCount"}
-- -1 marks a seven-field save awaiting migration from its saved area flags.
local defaults = {0,-1,0,0,-1,0,-1,-1}
local function read(u)
    local raw = (u:GetScriptData() or ""):match(marker)
    if not raw then return nil end
    local d,n = {},1
    for v in raw:gmatch("[^,]+") do if fields[n] then d[fields[n]]=tonumber(v) or defaults[n] end; n=n+1 end
    for i,k in ipairs(fields) do if d[k]==nil then d[k]=defaults[i] end end
    return d
end
local function write(u,d)
    local values={}
    for i,k in ipairs(fields) do values[i]=d[k] end
    u:SetScriptData((u:GetScriptData() or ""):gsub(marker,"").."[PSJ1:"..table.concat(values,",").."]")
end
local function identify(u)
    -- Transfer intentionally strips Learning; unit type alone cannot establish
    -- a new personal lineage, even when a later caller sees the same Survivor.
    if not u or not LEARNING or not u:IsHasPromotion(LEARNING) then return nil end
    local d=read(u)
    if d then return d end
    local pid=u:GetOwner()
    if not paul(pid) or u:GetUnitType()~=SURVIVOR then return nil end
    local serial=(tonumber(save.GetValue("PSJ_V1_SERIAL")) or 0)+1
    save.SetValue("PSJ_V1_SERIAL",serial)
    local plot=u:GetPlot()
    d={serial=serial,origin=pid,ancient=Players[pid]:GetCurrentEra()==ANCIENT and 1 or 0,
       outside=0,lastTurn=-1,returned=0,originArea=plot and plot:GetArea() or -1,landmassCount=0}
    write(u,d)
    return d
end
local function relevant(u)
    if not u then return nil end
    local d=read(u) or identify(u)
    if not d or d.origin~=u:GetOwner() or not paul(u:GetOwner()) or not u:IsHasPromotion(LEARNING) then return nil end
    return d
end
local function refreshVeteran(u,d)
    local p=paul(u:GetOwner())
    if p and d.origin==p:GetID() and d.ancient==1 and p:GetCurrentEra()>=MODERN and not u:IsHasPromotion(VETERAN) then
        u:SetHasPromotion(VETERAN,true)
        log("Survivor "..d.serial.." granted BEEN_HERE_SINCE_BEGINNING")
    end
end
local function journey(pid,u)
    local p=paul(pid)
    if not p or not u or get(pid,"MEM_FIRST_JOURNEY",-1)>=0 then return end
    local c=p:GetCapitalCity()
    local w,h=Map.GetGridSize()
    local distance=math.min(10,math.max(4,math.floor(math.min(w,h)/3)))
    if c and Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())>=distance then
        if earn(pid,"FIRST_JOURNEY") and relevant(u) then u:ChangeExperience(15) end
    end
end
local function moved(pid,uid)
    local p,u=paul(pid),unit(pid,uid)
    if not p or not u then return end
    journey(pid,u)
    local d=relevant(u)
    local plot=u:GetPlot()
    if not d or not plot or plot:IsWater() then return end
    local area=plot:GetArea()
    if d.originArea<0 then d.originArea=area; write(u,d) end
    if area~=d.originArea and d.landmassCount>=0 and d.landmassCount<3 then
        local k="PSJ_V1_U"..d.serial.."_AREA_"..area
        if not save.GetValue(k) then
            save.SetValue(k,1)
            d.landmassCount=d.landmassCount+1
            write(u,d) -- Persist both markers before granting XP.
            u:ChangeExperience(10)
        end
    end
end

-- Original Home is fixed to city coordinates AND foundation turn. A later city
-- on a razed Home's tile cannot inherit it; captured Home loses dummies immediately.
local function observeCapital(pid)
    local p=paul(pid); local c=p and p:GetCapitalCity()
    if c and get(pid,"CAP_X",-1)<0 then
        set(pid,"CAP_X",c:GetX()); set(pid,"CAP_Y",c:GetY())
        set(pid,"CAP_FOUND",c:GetGameTurnFounded()); set(pid,"CAP_OBSERVED",now())
    end
end
local function homeCity(pid)
    local x,y=get(pid,"CAP_X",-1),get(pid,"CAP_Y",-1)
    if x<0 or y<0 then return nil end
    local plot=Map.GetPlot(x,y); local c=plot and plot:GetPlotCity()
    if c and c:GetGameTurnFounded()==get(pid,"CAP_FOUND",-1) and c:GetOriginalOwner()==pid then return c end
    return nil
end
local function houses(pid)
    local p=paul(pid)
    if not p then return end
    for c in p:Cities() do if c:GetNumBuilding(HOUSE)>0 then earn(pid,"FIRST_SHELTER"); break end end
    local home=homeCity(pid)
    if home and home:GetOwner()==pid and home:GetNumBuilding(HOUSE)>0 and get(pid,"HOME_ERA",-1)<0 then
        set(pid,"HOME_ERA",p:GetCurrentEra())
    end
    local tier=0
    local birth=get(pid,"HOME_ERA",-1)
    if home and home:GetOwner()==pid and home:GetNumBuilding(HOUSE)>0 and birth>=0 then
        tier=math.min(3,math.max(0,math.floor((p:GetCurrentEra()-birth)/2)))
    end
    if home then for i=1,3 do home:SetNumRealBuilding(I["BUILDING_PSJ_HOME_"..i],tier==i and 1 or 0) end end
end
local function contacts(pid)
    local p=paul(pid)
    if not p or get(pid,"MEM_FIRST_FRIEND",-1)>=0 then return end
    local t=Teams[p:GetTeam()]
    for other=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local q=Players[other]
        if q and q:IsAlive() and not q:IsBarbarian() and q:GetTeam()~=p:GetTeam() and t:IsHasMet(q:GetTeam()) then
            earn(pid,"FIRST_FRIEND"); return
        end
    end
end
local function changedEra(pid,era)
    local p=paul(pid)
    if not p then return end
    local previous=get(pid,"ERA",-1)
    if previous<0 then set(pid,"ERA",era); return end
    if era<=previous then return end
    set(pid,"ERA",era)
    log("Era changed: player "..pid.." -> "..era)
    -- Only actual entries, not reconstructed intermediate eras, produce narratives.
    local row=GameInfo.Eras[era]
    if row and (row.Type=="ERA_CLASSICAL" or row.Type=="ERA_MEDIEVAL" or row.Type=="ERA_RENAISSANCE" or
        row.Type=="ERA_INDUSTRIAL" or row.Type=="ERA_INFORMATION") and get(pid,"NARRATIVE_"..era,0)==0 then
        set(pid,"NARRATIVE_"..era,1)
        notify(p,"TXT_KEY_PSJ_"..row.Type,"TXT_KEY_PSJ_"..row.Type.."_TEXT")
    end
    local total,count=0,0
    for _,name in ipairs(memoryOrder) do
        local born=get(pid,"MEM_"..name,-1)
        if born>=0 and born<era then total=total+3*(era-born); count=count+1 end
    end
    if total>0 then
        local c,s=reward(p,total,total,0)
        notify(p,"TXT_KEY_PSJ_OLD_MEMORIES","TXT_KEY_PSJ_OLD_MEMORIES_TEXT",count,c,s)
        log("Memory recall reward: "..c.." Culture / "..s.." Science")
    end
    if era==CLASSICAL then earn(pid,"SOMETHING_NEW") end
    houses(pid)
    for u in p:Units() do local d=relevant(u); if d then refreshVeteran(u,d) end end
end
local function turn(pid)
    local p=paul(pid)
    if not p then return end
    -- Prevent duplicate turn callbacks, including save/reload during this turn.
    if get(pid,"TURN",-1)==now() then return end
    set(pid,"TURN",now())
    observeCapital(pid)
    changedEra(pid,p:GetCurrentEra())
    if get(pid,"CAP_X",-1)>=0 and now()>get(pid,"CAP_OBSERVED",now()) then earn(pid,"FIRST_NIGHT") end
    if p:GetNumCities()>=2 then earn(pid,"BEYOND_HOME") end
    houses(pid); contacts(pid)
    local c=p:GetCapitalCity()
    for u in p:Units() do
        journey(pid,u)
        local d=relevant(u)
        if d then
            refreshVeteran(u,d)
            local plot=u:GetPlot()
            if plot and d.lastTurn~=now() then
                d.lastTurn=now()
                if plot:GetOwner()~=pid then d.outside=d.outside+1
                elseif d.outside<10 then d.outside=0 end
                if d.returned==0 and d.outside>=10 and c and
                    Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())<=2 then
                    d.returned=1
                    write(u,d)
                    local amount=reward(p,15,0,0)
                    notify(p,"TXT_KEY_PSJ_HOME_AGAIN","TXT_KEY_PSJ_HOME_AGAIN_TEXT",amount)
                end
                write(u,d)
            end
        end
    end
end
local function founded(pid)
    if not paul(pid) then return end
    observeCapital(pid)
    if Players[pid]:GetNumCities()>=2 then earn(pid,"BEYOND_HOME") end
    houses(pid)
end
local function constructed(pid,cityID,building)
    if paul(pid) and building==HOUSE then earn(pid,"FIRST_SHELTER"); houses(pid) end
end
local function capture(oldOwner,isCapital,x,y,newOwner)
    -- Dummies are NeverCapture, but normalize both original owners immediately.
    if paul(oldOwner) then houses(oldOwner) end
    if paul(newOwner) then founded(newOwner) end
end
local function built(pid,uid,x,y,buildID)
    if not paul(pid) then return end
    local b=GameInfo.Builds[buildID]; local plot=Map.GetPlot(x,y)
    if not b or not b.ImprovementType or not plot or plot:IsImprovementPillaged() then return end
    local improvement=I[b.ImprovementType]
    if plot:GetImprovementType()~=improvement then return end
    if b.ImprovementType=="IMPROVEMENT_MINE" then earn(pid,"FIRST_MINE") end
    local res=plot:GetResourceType(Players[pid]:GetTeam())
    local r=GameInfo.Resources[res]
    if r and (r.ResourceClassType=="RESOURCECLASS_BONUS" or r.ResourceClassType=="RESOURCECLASS_LUXURY") then
        for row in GameInfo.Resource_YieldChanges{ResourceType=r.Type,YieldType="YIELD_FOOD"} do
            if row.Yield>0 then
                for valid in GameInfo.Improvement_ResourceTypes{ImprovementType=b.ImprovementType,ResourceType=r.Type} do
                    if valid then earn(pid,"FIRST_HARVEST"); return end
                end
            end
        end
    end
end
local function prekill(pid,uid,unitType,x,y,delay,killer)
    local victim=Players[pid]
    if victim and victim:IsBarbarian() and killer and killer>=0 and paul(killer) then earn(killer,"FIRST_DANGER") end
end
local function teamEra(team,era)
    for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=paul(pid); if p and p:GetTeam()==team then changedEra(pid,era) end end
end
local function meet(a,b)
    for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=paul(pid); if p and (p:GetTeam()==a or p:GetTeam()==b) then contacts(pid) end end
end
local function wonder(team,feature,x,y,first,discoverer,uid)
    for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=paul(pid); if p and p:GetTeam()==team then earn(pid,"FIRST_WONDER") end end
    -- A five-argument DLL event has no unit attribution: no invented XP.
    local u=discoverer and uid and unit(discoverer,uid)
    if u and relevant(u) then
        local k="NW_"..x.."_"..y
        if get(discoverer,k,0)==0 then set(discoverer,k,1); u:ChangeExperience(10) end
    end
end
local function goody(pid,uid,goodyType,x,y)
    local u=unit(pid,uid)
    if not relevant(u) then return end
    local k="RUIN_"..x.."_"..y
    if get(pid,k,0)==0 then set(pid,k,1); u:ChangeExperience(5) end
end
local upgradeSnapshots={}
local function upgraded(pid,oldID,newID)
    local old=unit(pid,oldID)
    local d=old and relevant(old)
    if d then upgradeSnapshots[pid..":"..newID]=d end
end
local function converted(oldOwner,newOwner,oldID,newID,isUpgrade)
    local u=unit(newOwner,newID)
    if not u then return end
    local k=oldOwner..":"..newID
    local old=unit(oldOwner,oldID)
    local d=upgradeSnapshots[k] or (old and read(old)) or read(u)
    upgradeSnapshots[k]=nil
    local validSource=old and old:IsHasPromotion(LEARNING) or (not old and u:IsHasPromotion(LEARNING))
    if (isUpgrade==true or isUpgrade==1) and oldOwner==newOwner and paul(newOwner) and d and d.origin==newOwner and validSource then
        write(u,d); u:SetHasPromotion(LEARNING,true); refreshVeteran(u,d)
    elseif d then
        u:SetScriptData((u:GetScriptData() or ""):gsub(marker,""))
        u:SetHasPromotion(LEARNING,false); u:SetHasPromotion(VETERAN,false)
    end
end
local function created(pid,uid)
    local u=unit(pid,uid)
    if paul(pid) and u and u:GetUnitType()==SURVIVOR then identify(u) end
end
local function initialize()
    local legacyUnits,landAreas={},{}
    for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do
        local p=paul(pid)
        if p then
            if get(pid,"ERA",-1)<0 then set(pid,"ERA",p:GetCurrentEra()) end
            observeCapital(pid)
            for u in p:Units() do
                if u:GetUnitType()==SURVIVOR and u:IsHasPromotion(LEARNING) then identify(u) end
                local d=relevant(u)
                if d and d.landmassCount<0 then legacyUnits[#legacyUnits+1]={unit=u,data=d} end
            end
        end
    end
    -- One load-time map scan handles Natural Wonders already revealed by the map.
    for index=0,Map.GetNumPlots()-1 do
        local plot=Map.GetPlotByIndex(index)
        -- Reuse the existing single load-time scan for old unit records. There
        -- is no new map scan or per-turn migration work.
        if #legacyUnits>0 and plot and not plot:IsWater() then landAreas[plot:GetArea()]=true end
        if plot and plot:IsNaturalWonder() then
            for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=paul(pid)
                if p and plot:IsRevealed(p:GetTeam(),false) then earn(pid,"FIRST_WONDER") end
            end
        end
    end
    for _,entry in ipairs(legacyUnits) do
        local d,count=entry.data,0
        for area in pairs(landAreas) do
            if area~=d.originArea and save.GetValue("PSJ_V1_U"..d.serial.."_AREA_"..area) then
                count=count+1
                if count==3 then break end
            end
        end
        d.landmassCount=count
        write(entry.unit,d)
    end
end
local handlers={PlayerDoTurn=turn,PlayerCityFounded=founded,CityConstructed=constructed,
    CityCaptureComplete=capture,PlayerBuilt=built,UnitPrekill=prekill,TeamSetEra=teamEra,
    TeamMeet=meet,NaturalWonderDiscovered=wonder,GoodyHutReceivedBonus=goody,
    UnitSetXY=moved,UnitCreated=created,UnitUpgraded=upgraded,UnitConverted=converted}
for name,fn in pairs(handlers) do if GameEvents[name] then GameEvents[name].Add(fn) end end
initialize()
log("The First Night runtime loaded")
