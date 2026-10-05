-- Tokenized Intelligence. No UI polling; persistent state is authoritative.
-- _G is local to this InGameUIAddin. MapModData can outlive the game/context,
-- so a shared Loaded flag must never suppress registration after a reload.
if rawget(_G,'__TOKEN_RUNTIME_CONTEXT_LOADED') then return end
rawset(_G,'__TOKEN_RUNTIME_CONTEXT_LOADED',true)
MapModData.TokenizedIntelligence = {}
local T = MapModData.TokenizedIntelligence
T.TOKEN_DEBUG = false
local CIV = GameInfoTypes.CIVILIZATION_TOKEN_INTELLIGENCE
local CLUSTER, CENTRE = GameInfoTypes.BUILDING_TOKEN_CLUSTER, GameInfoTypes.BUILDING_TOKEN_CENTRE
local AGENT = GameInfoTypes.UNIT_TOKEN_AGENT
local save = Modding.OpenSaveData()
local floor, max, min = math.floor, math.max, math.min
local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
local factor = max(0.1, (speed.TrainPercent or 100) / 100)
local function round(n) return floor(n + 0.5) end
function T.Scale(n) return max(1, round(n * factor)) end
local function log(s) if T.TOKEN_DEBUG then print('[TokenAI] ' .. s) end end
local function key(pid, field) return 'TOKEN_V1_P' .. pid .. '_' .. field end
function T.Get(pid, field, default)
    local v = save.GetValue(key(pid, field))
    if v == nil then return default or 0 end
    return v
end
local function put(pid, field, value) save.SetValue(key(pid, field), value) end
function T.IsToken(pid)
    local p = Players[pid]
    return p and p:IsAlive() and p:GetCivilizationType() == CIV
end
local function network() return Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer() end
local function clock(pid) return T.Get(pid, 'clock') end
local function cityIdentity(c)
    return c:GetOwner() .. '_' .. c:GetOriginalOwner() .. '_' .. c:GetGameTurnFounded() .. '_' .. c:GetX() .. '_' .. c:GetY()
end
local function unitIdentity(u)
    return u:GetOwner() .. '_' .. u:GetID() .. '_' .. u:GetGameTurnCreated() .. '_' .. u:GetUnitType()
end
local function changed(pid)
    if LuaEvents and LuaEvents.TokenStateChanged then LuaEvents.TokenStateChanged(pid) end
end
local capacities = {1000,1500,2250,3250,4500,6000,8000,10000}
local eraTypes = {'ANCIENT','CLASSICAL','MEDIEVAL','RENAISSANCE','INDUSTRIAL','MODERN','POSTMODERN','FUTURE'}
local eraRanks = {}
for i, name in ipairs(eraTypes) do
    local id = GameInfoTypes['ERA_' .. name]
    if id then eraRanks[id] = i - 1 end
end
function T.Era(pid) return eraRanks[Players[pid]:GetCurrentEra()] or 7 end
function T.Model(pid)
    local e = T.Era(pid)
    return e < 2 and 'Small Model' or e < 4 and 'General Model' or e == 4 and 'Reasoning Model'
        or e == 5 and 'Large Model' or e == 6 and 'Frontier Model' or 'General Intelligence'
end
function T.Limit(pid) local e = T.Era(pid); return e >= 7 and 3 or e >= 5 and 2 or 1 end
local specialistWeights = {SCIENTIST=15,ENGINEER=10,MERCHANT=8,WRITER=5,ARTIST=5,MUSICIAN=5}
local statsCache={}
function T.Invalidate(pid) statsCache[pid]=nil end
function T.Stats(pid)
    if statsCache[pid] then return statsCache[pid] end
    local out = {capacity=0,cities=0,population=0,specialists=0,buildings=0,modifier=0,base=0,income=0,penalty=0}
    if not T.IsToken(pid) then return out end
    local capacity = capacities[T.Era(pid)+1]
    for c in Players[pid]:Cities() do
        local a, b = c:GetNumBuilding(CLUSTER)>0, c:GetNumBuilding(CENTRE)>0
        local citizens = 2*c:GetPopulation()
        local specs = 0
        for name, weight in pairs(specialistWeights) do
            local id = GameInfoTypes['SPECIALIST_' .. name]
            if id then specs = specs + weight*c:GetSpecialistCount(id) end
        end
        local buildings = (a and 15+5*c:GetSpecialistCount(GameInfoTypes.SPECIALIST_SCIENTIST) or 0)+(b and 50 or 0)
        out.cities=out.cities+10; out.population=out.population+citizens
        out.specialists=out.specialists+specs; out.buildings=out.buildings+buildings
        if b then out.modifier=out.modifier+(10+citizens+specs+buildings)*0.1 end
        capacity = capacity+(a and 75 or 0)+(b and 500 or 0)
    end
    out.capacity=T.Scale(capacity)
    out.base=out.cities+out.population+out.specialists+out.buildings
    local level = T.Get(pid,'satExpiry') > clock(pid) and T.Get(pid,'satLevel') or 0
    out.penalty=({[0]=0,10,25,40})[level] or 0
    out.income=max(0,floor((out.base+out.modifier)*(100-out.penalty)/100))
    statsCache[pid]=out
    return out
end
function T.Tokens(pid) return min(max(0,T.Get(pid,'tokens')),T.Stats(pid).capacity) end
local function setTokens(pid, value) put(pid,'tokens',min(max(0,floor(value)),T.Stats(pid).capacity)) end
-- Bounded records: at most the model's effect limit. No transient table owns state.
local function readEffects(pid)
    local effects={}
    for name,kind,id,identity,expiry in tostring(T.Get(pid,'effects','')):gmatch('([A-Z]+):([ECU]):(%-?%d+):([%d_]+):(%d+);') do
        effects[#effects+1]={name=name,kind=kind,id=tonumber(id),identity=identity,expiry=tonumber(expiry)}
    end
    return effects
end
local function writeEffects(pid,effects)
    local records={}
    for _,e in ipairs(effects) do records[#records+1]=e.name..':'..e.kind..':'..e.id..':'..e.identity..':'..e.expiry..';' end
    put(pid,'effects',table.concat(records))
end
local function valid(pid,e)
    if e.expiry<=clock(pid) then return false end
    if e.kind=='E' then return true end
    local p=Players[pid]
    local target
    if e.kind=='C' then target=p:GetCityByID(e.id) else target=p:GetUnitByID(e.id) end
    return target and (e.kind=='C' and cityIdentity(target) or unitIdentity(target))==e.identity
end
function T.Active(pid)
    local list={}
    for _,e in ipairs(readEffects(pid)) do if valid(pid,e) then list[#list+1]=e end end
    return list
end
local buildings={'GOLD','GROWTH','RESEARCH','CULTURE','HAPPINESS','ADMIN','GRAND','TRADE'}
local promotions={'TACTICAL','SIMULATION','GRAND','FORECAST','OFFENSE','DEFENSE','MOBILITY','TARGET'}
local adaptive={OFFENSE=true,DEFENSE=true,MOBILITY=true,TARGET=true}
local function setBuilding(c,id,count)
    if c:GetNumRealBuilding(id)~=count then c:SetNumRealBuilding(id,count) end
end
local syncing=false
local function sync(pid)
    local p=Players[pid]
    if not p or not p:IsAlive() or syncing then return end
    syncing=true
    local effects=T.IsToken(pid) and T.Active(pid) or {}
    writeEffects(pid,effects)
    local empire, cities, units={},{},{}
    for _,e in ipairs(effects) do
        if e.kind=='E' then empire[e.name]=true
        elseif e.kind=='C' then cities[e.id]=cities[e.id] or {}; cities[e.id][e.name]=true
        else units[e.id]=units[e.id] or {}; units[e.id][e.name]=true end
    end
    local routes={}
    if empire.TRADE then
        for _,r in ipairs(p:GetTradeRoutes()) do
            if r.FromCity and r.FromCity:GetOwner()==pid then local id=r.FromCity:GetID();routes[id]=(routes[id] or 0)+1 end
        end
    end
    local capital=p:GetCapitalCity()
    for c in p:Cities() do
        for _,name in ipairs(buildings) do
            local active=empire[name] or (cities[c:GetID()] and cities[c:GetID()][name])
            local count=active and 1 or 0
            if name=='HAPPINESS' or name=='ADMIN' then count=empire[name] and capital and c:GetID()==capital:GetID() and 1 or 0
            elseif name=='TRADE' then count=empire.TRADE and (routes[c:GetID()] or 0) or 0 end
            setBuilding(c,GameInfoTypes['BUILDING_TOKEN_'..name],count)
        end
    end
    for u in p:Units() do
        for _,name in ipairs(promotions) do
            local active=(units[u:GetID()] and units[u:GetID()][name]) or ((name=='GRAND' or name=='FORECAST') and empire[name] and u:IsCombatUnit())
            local id=GameInfoTypes['PROMOTION_TOKEN_'..name]
            if u:IsHasPromotion(id)~=(active and true or false) then u:SetHasPromotion(id,active and true or false) end
        end
    end
    syncing=false
end
local prompts={
 {id='PRODUCTION',category='ECONOMIC',name='Optimize Production',cost=500,era=0,target='city',icon=2,help='Add up to 100 Production (speed-scaled), capped one short of the current item completion. Choose an owned city with an active production item.'},
 {id='GOLD',category='ECONOMIC',name='Optimize Gold',cost=800,era=0,duration=5,icon=0,help='+10% Gold in every owned city.'},
 {id='GROWTH',category='ECONOMIC',name='Optimize Growth',cost=700,era=0,duration=5,target='city',icon=2,help='+20% gross Food in one owned city; normal citizen consumption still applies.'},
 {id='TRADE',category='ECONOMIC',name='Optimize Trade',cost=700,era=2,duration=5,icon=3,help='+2 Gold and +1 Science in each origin city per active outgoing trade route. Includes domestic routes; the route itself is unchanged.'},
 {id='QUERY',category='RESEARCH',name='Research Query',cost=750,era=0,icon=1,help='Add up to 5% of current technology Science cost. Once per own turn, capped one short of completion; no Science overflow.'},
 {id='RESEARCH',category='RESEARCH',name='Research Optimization',cost=1200,era=2,duration=5,icon=1,help='+10% Science in every owned city.'},
 {id='TACTICAL',category='MILITARY',name='Tactical Analysis',cost=400,era=0,duration=3,target='combat',icon=5,help='+15% Combat Strength and +1 Sight for one owned combat unit.'},
 {id='ROUTE',category='MILITARY',name='Route Optimization',cost=300,era=0,target='unit',icon=10,help='+2 movement points this turn. Once per unit per turn, even after Clear Context; requires a mobile non-trade unit.'},
 {id='SIMULATION',category='MILITARY',name='Combat Simulation',cost=700,era=2,duration=2,target='combat',icon=6,help='+25% Combat Strength for one owned combat unit.'},
 {id='HAPPINESS',category='GOVERNANCE',name='Happiness Optimization',cost=750,era=2,duration=5,icon=9,help='+5 empire Happiness, applied once at the current capital.'},
 {id='CULTURE',category='GOVERNANCE',name='Cultural Analysis',cost=750,era=2,duration=5,icon=13,help='+15% Culture in every owned city.'},
 {id='ADMIN',category='GOVERNANCE',name='Emergency Administration',cost=1500,era=4,duration=5,icon=9,help='+8 empire Happiness at the capital and +10% Production in every owned city. Resistance, occupation and diplomacy continue normally.'},
 {id='FORECAST',category='ADVANCED',name='Strategic Forecast',cost=3000,era=4,capacity=5000,duration=2,icon=7,help='Live reconnaissance: +6 Sight to all owned combat units. Enemy movement inside that sight is visible; explored terrain remains mapped after expiry.'},
 {id='GRAND',category='ADVANCED',name='Grand Strategy Simulation',cost=5000,era=4,capacity=8000,duration=5,icon=6,help='+15% Science, Production and Gold in every owned city; +10% Combat Strength to all owned combat units.'},
 {id='OFFENSE',category='ADAPTIVE',name='Offensive Analysis',cost=250,era=4,duration=3,target='agent',icon=8,help='Inference Agent: +20% attack strength. Replaces its previous Adaptive mode.'},
 {id='DEFENSE',category='ADAPTIVE',name='Defensive Analysis',cost=250,era=4,duration=3,target='agent',icon=9,help='Inference Agent: +20% defense strength. Replaces its previous Adaptive mode.'},
 {id='MOBILITY',category='ADAPTIVE',name='Mobility Analysis',cost=250,era=4,duration=3,target='agent',icon=10,help='Inference Agent: +1 base Movement. Replaces its previous Adaptive mode; additional movement refreshes on the next unit turn.'},
 {id='TARGET',category='ADAPTIVE',name='Target Analysis',cost=300,era=4,duration=3,target='agent',icon=11,help='Inference Agent: +25% strength against land units. Replaces its previous Adaptive mode.'},
 {id='CLEAR',category='CONTEXT',name='Clear Context',cost=0,era=0,icon=12,help='Restore 25% Context capacity. Remove all active Prompts, cache and congestion. 15-turn cooldown. Instant grants and per-turn restrictions stay in place.'}
}
T.Prompts=prompts
local byID={}
for _,p in ipairs(prompts) do byID[p.id]=p end
function T.Cost(pid,id)
    local p=byID[id]
    if not p or p.cost==0 then return 0,false end
    local normal=T.Scale(p.cost*(T.Era(pid)>=6 and 0.9 or 1))
    local recent=T.Get(pid,'lastPrompt','')==id and clock(pid)-T.Get(pid,'cacheTurn',-1000)<=T.Scale(10)
    local uses=recent and T.Get(pid,'cacheUses') or 0
    local multiplier=uses>=2 and 7/12 or uses==1 and 0.75 or 1
    return max(round(normal*0.5),round(normal*multiplier)),recent
end
local function sameSlot(e,id,target)
    local p=byID[id]
    if p.target=='agent' and adaptive[e.name] then return e.kind=='U' and e.id==target end
    return e.name==id and (e.kind=='E' or e.id==target)
end
local function researchGrant(pid)
    local p=Players[pid];local tech=p:GetCurrentResearch()
    if not tech or tech<0 then return 0,tech end
    local team=Teams[p:GetTeam()]
    if team:IsHasTech(tech) then return 0,tech end
    local techs=team:GetTeamTechs()
    local cost=techs:GetResearchCost(tech)
    return max(0,min(max(1,floor(cost*0.05)),cost-techs:GetResearchProgress(tech)-1)),tech
end
function T.Check(pid,id,target)
    if not T.IsToken(pid) then return false,'This player does not own the Token mechanic.' end
    if network() then return false,'Network multiplayer is not synchronized by this collection.' end
    local spec=byID[id]
    if not spec then return false,'Unknown Prompt.' end
    if T.Era(pid)<spec.era then return false,'Requires '..({'Small Model','Small Model','General Model','General Model','Reasoning Model'})[spec.era+1]..'.' end
    if spec.capacity and T.Stats(pid).capacity<T.Scale(spec.capacity) then return false,'Insufficient Context Window: requires '..T.Scale(spec.capacity)..'.' end
    if spec.id=='CLEAR' then
        if T.Get(pid,'clearExpiry')>clock(pid) then return false,'Clear Context cooldown: '..(T.Get(pid,'clearExpiry')-clock(pid))..' turns.' end
    end
    local p=Players[pid]
    if spec.target then
        local u
        if spec.target=='city' then u=p:GetCityByID(target or -1) else u=p:GetUnitByID(target or -1) end
        if not u or u:GetOwner()~=pid then return false,'Choose an owned '..(spec.target=='city' and 'city' or 'unit')..'.' end
        if spec.target=='combat' and not u:IsCombatUnit() then return false,'Choose a combat unit.' end
        if spec.target=='agent' and u:GetUnitType()~=AGENT then return false,'Choose an Inference Agent.' end
        if id=='PRODUCTION' and (u:GetProductionProcess()>=0 or u:GetProductionNeeded()-u:GetProduction()<=1) then return false,'No unfinished production item can receive this grant.' end
        if id=='ROUTE' then
            if u:IsTrade() or u:MaxMoves()<=0 then return false,'Choose a mobile non-trade unit.' end
            if T.Get(pid,'route_'..unitIdentity(u),-1)==clock(pid) then return false,'This unit already optimized its route this turn.' end
        end
    end
    if id=='QUERY' then
        if T.Get(pid,'queryTurn',-1)==clock(pid) then return false,'Research Query is limited to once per own turn.' end
        if researchGrant(pid)<=0 then return false,'Choose unfinished research with room for Science.' end
    end
    if spec.duration then
        local effects=T.Active(pid);local replace=false
        for _,e in ipairs(effects) do if sameSlot(e,id,target) then replace=true end end
        if not replace and #effects>=T.Limit(pid) then return false,'Context full: '..T.Limit(pid)..' persistent Prompt(s). Wait for expiry or Clear Context.' end
    end
    if T.Tokens(pid)<T.Cost(pid,id) then return false,'Insufficient Tokens.' end
    return true,'Ready.'
end
local function saturate(pid,cost)
    if T.Get(pid,'spendClock',-1)~=clock(pid) then put(pid,'spent',0);put(pid,'spendClock',clock(pid)) end
    local spent=T.Get(pid,'spent')+cost;put(pid,'spent',spent)
    local ratio=spent/T.Stats(pid).capacity
    local level=ratio>=0.60 and 3 or ratio>=0.30 and 2 or ratio>=0.10 and 1 or 0
    if T.Era(pid)>=6 then level=max(0,level-1) end
    if level>0 then
        local old=T.Get(pid,'satExpiry')>clock(pid) and T.Get(pid,'satLevel') or 0
        put(pid,'satLevel',max(old,level))
        put(pid,'satExpiry',max(T.Get(pid,'satExpiry'),clock(pid)+T.Scale(({2,3,4})[level])))
        log('Player '..pid..' Saturation '..max(old,level))
    end
end
function T.Use(pid,id,target)
    T.Invalidate(pid)
    local ok,reason=T.Check(pid,id,target)
    if not ok then return false,reason end
    local spec=byID[id];local p=Players[pid];local cost,cached=T.Cost(pid,id)
    if id=='CLEAR' then
        writeEffects(pid,{})
        put(pid,'lastPrompt','');put(pid,'cacheUses',0);put(pid,'cacheTurn',-1000)
        put(pid,'satLevel',0);put(pid,'satExpiry',0)
        T.Invalidate(pid)
        -- Keep cumulative spend and instant-action limits: clearing is no exploit reset.
        put(pid,'clearExpiry',clock(pid)+T.Scale(15))
        setTokens(pid,T.Tokens(pid)+floor(T.Stats(pid).capacity*0.25))
    else
        -- Validate and calculate again immediately before the spend; no queued UI target owns state.
        setTokens(pid,T.Tokens(pid)-cost)
        if id=='PRODUCTION' then
            local c=p:GetCityByID(target)
            c:ChangeProduction(min(T.Scale(100),c:GetProductionNeeded()-c:GetProduction()-1))
        elseif id=='QUERY' then
            local amount,tech=researchGrant(pid)
            Teams[p:GetTeam()]:GetTeamTechs():ChangeResearchProgress(tech,amount,pid)
            put(pid,'queryTurn',clock(pid))
        elseif id=='ROUTE' then
            local u=p:GetUnitByID(target)
            put(pid,'route_'..unitIdentity(u),clock(pid))
            u:ChangeMoves(2*(GameDefines.MOVE_DENOMINATOR or 60))
        else
            local effects={}
            for _,e in ipairs(T.Active(pid)) do if not sameSlot(e,id,target) then effects[#effects+1]=e end end
            local kind=spec.target=='city' and 'C' or spec.target and 'U' or 'E'
            local object=kind=='C' and p:GetCityByID(target) or kind=='U' and p:GetUnitByID(target)
            effects[#effects+1]={name=id,kind=kind,id=target or -1,identity=kind=='E' and '0' or kind=='C' and cityIdentity(object) or unitIdentity(object),expiry=clock(pid)+T.Scale(spec.duration)}
            writeEffects(pid,effects)
        end
        put(pid,'cacheUses',cached and min(2,T.Get(pid,'cacheUses')+1) or 1)
        put(pid,'lastPrompt',id);put(pid,'cacheTurn',clock(pid))
        saturate(pid,cost)
        T.Invalidate(pid)
    end
    sync(pid);changed(pid)
    log('Player '..pid..' '..spec.name..' used. Cost '..cost)
    return true,spec.name..' applied'..(cost>0 and ' — '..cost..' Tokens.' or '.')
end
function T.Targets(pid,id)
    local spec=byID[id];local list={}
    if not T.IsToken(pid) or not spec or not spec.target then return list end
    if spec.target=='city' then
        for c in Players[pid]:Cities() do list[#list+1]={id=c:GetID(),name=c:GetName()} end
    else
        for u in Players[pid]:Units() do
            if spec.target=='unit' or spec.target=='combat' and u:IsCombatUnit() or spec.target=='agent' and u:GetUnitType()==AGENT then
                list[#list+1]={id=u:GetID(),name=u:GetName()..' ('..u:GetX()..','..u:GetY()..')'}
            end
        end
    end
    table.sort(list,function(a,b) return a.id<b.id end)
    return list
end
function T.Tooltip(pid)
    local stats=T.Stats(pid)
    local lines={'Tokens: '..T.Tokens(pid)..' / '..stats.capacity,'Model: '..T.Model(pid),
        'Generation each turn:','Cities: +'..stats.cities,'Population: +'..stats.population,
        'Specialists: +'..stats.specialists,'Inference infrastructure: +'..stats.buildings,
        'Subtotal: +'..stats.base,'Data Centre local modifiers: +'..round(stats.modifier),
        'Compute Saturation: '..({[0]='None',[10]='Light',[25]='Heavy',[40]='Critical'})[stats.penalty]..' (-'..stats.penalty..'%)',
        'Congestion remaining: '..max(0,T.Get(pid,'satExpiry')-clock(pid))..' turns','Final income: +'..stats.income,
        'Persistent Prompts: '..#T.Active(pid)..' / '..T.Limit(pid)}
    local last=T.Get(pid,'lastPrompt','')
    if byID[last] and clock(pid)-T.Get(pid,'cacheTurn',-1000)<=T.Scale(10) then
        lines[#lines+1]='Cached Response: '..byID[last].name..' ('..T.Cost(pid,last)..' Tokens next use)'
    end
    for _,e in ipairs(T.Active(pid)) do lines[#lines+1]=byID[e.name].name..': '..(e.expiry-clock(pid))..' turns' end
    lines[#lines+1]='Clear Context cooldown: '..max(0,T.Get(pid,'clearExpiry')-clock(pid))..' turns'
    lines[#lines+1]='Overflow is discarded. At maximum Context, all incoming Tokens are lost.'
    return table.concat(lines,'[NEWLINE]')
end
local function ai(pid)
    local p=Players[pid];local stats=T.Stats(pid);local tokens=T.Tokens(pid)
    if tokens<stats.capacity*0.25 then return end
    -- At most one successful action per own turn, no randomness or human UI calls.
    local function try(id,target) return T.Use(pid,id,target) end
    if p:GetExcessHappiness()<0 and try('HAPPINESS') then return end
    local atWar=Teams[p:GetTeam()]:GetAtWarCount(true)>0
    if atWar then
        for _,target in ipairs(T.Targets(pid,'TACTICAL')) do
            local u=p:GetUnitByID(target.id)
            if u:GetDamage()>0 and try(u:GetUnitType()==AGENT and 'DEFENSE' or 'TACTICAL',target.id) then return end
        end
    end
    if tokens<stats.capacity*0.7 then return end
    if try('GRAND') then return end
    for _,target in ipairs(T.Targets(pid,'PRODUCTION')) do
        local c=p:GetCityByID(target.id);local b=GameInfo.Buildings[c:GetProductionBuilding()]
        local cls=b and GameInfo.BuildingClasses[b.BuildingClass]
        if (cls and cls.MaxGlobalInstances>=0 or c:GetProductionUnit()>=0) and try('PRODUCTION',target.id) then return end
    end
    if try('QUERY') then return end
    if try('RESEARCH') then return end
    for _,target in ipairs(T.Targets(pid,'PRODUCTION')) do if try('PRODUCTION',target.id) then return end end
    if atWar then for _,target in ipairs(T.Targets(pid,'TACTICAL')) do if try('TACTICAL',target.id) then return end end end
    try('GOLD')
end
local function turn(pid)
    if not T.IsToken(pid) or network() then return end
    local gameTurn=Game.GetGameTurn()
    if T.Get(pid,'lastGameTurn',-1)==gameTurn then return end
    put(pid,'lastGameTurn',gameTurn);put(pid,'clock',clock(pid)+1)
    T.Invalidate(pid)
    sync(pid)
    local p=Players[pid];local e=T.Era(pid);local old=T.Get(pid,'era',e)
    if e~=old and p:IsHuman() then
        p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,'Your inference architecture has advanced to '..T.Model(pid)..'. Context capacity and available Prompts have increased.','MODEL UPGRADED')
    end
    put(pid,'era',e)
    local stats=T.Stats(pid);local before=T.Tokens(pid)
    -- Congestion affects exactly N future income ticks. At its expiry tick,
    -- apply the last reduced grant; Stats shows uncongested NEXT-turn income.
    local level=T.Get(pid,'satExpiry')>=clock(pid) and T.Get(pid,'satLevel') or 0
    local penalty=({[0]=0,10,25,40})[level] or 0
    local income=max(0,floor((stats.base+stats.modifier)*(100-penalty)/100))
    setTokens(pid,before+income)
    log('Player '..pid..' generated '..(T.Tokens(pid)-before)..' Tokens; '..max(0,before+income-stats.capacity)..' discarded.')
    if not p:IsHuman() then ai(pid) end
    changed(pid)
end
local function refreshPlayer(pid)
    if not T.IsToken(pid) then return end
    T.Invalidate(pid)
    sync(pid);setTokens(pid,T.Tokens(pid));changed(pid)
end
local function capture(oldOwner,capital,x,y,newOwner)
    local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
    if c then for _,name in ipairs(buildings) do setBuilding(c,GameInfoTypes['BUILDING_TOKEN_'..name],0) end end
    refreshPlayer(oldOwner);refreshPlayer(newOwner)
end
local function converted(oldOwner,newOwner,oldID,newID)
    local p=Players[newOwner];local u=p and p:GetUnitByID(newID)
    if u then for _,name in ipairs(promotions) do u:SetHasPromotion(GameInfoTypes['PROMOTION_TOKEN_'..name],false) end end
    refreshPlayer(oldOwner);refreshPlayer(newOwner)
end
local function initialize()
    for pid=0,GameDefines.MAX_CIV_PLAYERS-1 do
        if T.IsToken(pid) then
            if T.Get(pid,'initialized')==0 then
                put(pid,'initialized',1);put(pid,'era',T.Era(pid));setTokens(pid,T.Scale(250))
            end
            refreshPlayer(pid)
        end
    end
end
GameEvents.PlayerDoTurn.Add(turn)
GameEvents.CityConstructed.Add(refreshPlayer)
GameEvents.PlayerCityFounded.Add(refreshPlayer)
GameEvents.CityCaptureComplete.Add(capture)
GameEvents.UnitCreated.Add(refreshPlayer)
GameEvents.UnitConverted.Add(converted)
GameEvents.SetPopulation.Add(function(x,y)
    local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
    if city then refreshPlayer(city:GetOwner()) end
end)
GameEvents.TeamTechResearched.Add(function(teamID)
    for pid=0,GameDefines.MAX_CIV_PLAYERS-1 do
        if T.IsToken(pid) and Players[pid]:GetTeam()==teamID then refreshPlayer(pid) end
    end
end)
-- Cleanup after native conversion copied promotions. UnitPrekill is intentionally
-- not used to reconcile: it occurs before deletion and upgrade conversion.
if Events and Events.LoadScreenClose then Events.LoadScreenClose.Add(initialize) end
initialize()
