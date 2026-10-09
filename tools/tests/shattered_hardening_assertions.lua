local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0]
local g=I.Provinces(s)[1];local c=I.City(g,0);c.b[GameInfoTypes.BUILDING_IMPERIAL_PALACE]=1
g.loyalty=75;g.ambition=20;g.actionNext=0
local gold,authority=I.CharterCost(s,g);assert(gold==I.GoldCost(s,g,.5) and authority==5)
p.gold=gold-1;local before=I.Encode(s);assert(not I.Action(0,'CHARTER',g.key,g.id));assert(before==I.Encode(s))
p.gold=100000;s.authority=4;assert(not I.Action(0,'CHARTER',g.key,g.id));assert(p.gold==100000)
s.authority=100;assert(I.Action(0,'CHARTER',g.key,g.id));assert(p.gold==100000-gold and s.authority==95 and g.autonomy and g.ambition==32)
g.actionNext=0;assert(not I.Action(0,'CHARTER',g.key,g.id),'Repeated peacetime charters must fail')
-- Already autonomous provinces can revolt again, and still pay for wartime settlement.
g.loyalty=10;g.ambition=30;I.BeginRevolt(s,g);local f=s.factions[g.faction]
gold,authority=I.CharterCost(s,g);assert(gold==I.GoldCost(s,g,2) and authority==10)
s.authority=9;before=p.gold;assert(not I.Action(0,'CHARTER',g.key,g.id));assert(f.active and p.gold==before)
s.authority=60;g.actionNext=0;local saves=0;local save=I.Save;I.Save=function(...) saves=saves+1;return save(...) end
assert(I.Action(0,'CHARTER',g.key,g.id));assert(saves==1,'One synchronous settlement must write one snapshot')
I.Save=save;assert(p.gold==before-gold and s.authority==50 and g.settlement and g.ambition==50 and not f.active)
before=p.gold;assert(not I.Action(0,'CHARTER',g.key,g.id));assert(p.gold==before)
g.actionNext=0;local old=g.id;assert(I.Action(0,'REPLACE',g.key,g.id));g=s.governors[g.key]
assert(g.id~=old and g.autonomy and g.settlement,'Legal privileges survive replacing the Governor')
local ambition=g.ambition;g.archetype='LOYALIST';I.LoyaltyTick(s);assert(g.ambition==ambition+.5)
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);g=s.governors[g.key];assert(g.settlement and g.autonomy)
-- No autonomy request, even across deterministic generation and reload.
for n=1,100 do I.NewDemand(s,g);assert(g.demand.kind~='AUTONOMY');I.FinishDemand(s,g,true) end
local function demand(kind,extra)
 local d={kind=kind,cost=20,created=Turn,deadline=Turn+I.Scale(25)};for k,v in pairs(extra or {}) do d[k]=v end;g.demand=d;return d
end
local farm=Map.GetPlot(g.x+1,g.y);farm.owner=0;farm.improvement=-1
demand('WALLS');c.queuedWalls=true;assert(I.DemandFeasible(s,g,g.demand),'Queued Walls remain a feasible request')
I.CheckDemand(s,g);assert(g.demand);c.b[GameInfoTypes.BUILDING_WALLS]=1;I.CheckDemand(s,g);assert(not g.demand);c.queuedWalls=nil
demand('FARMS',{target=1000});local loyalty,amb=g.loyalty,g.ambition;I.CheckDemand(s,g);assert(not g.demand and g.loyalty==loyalty and g.ambition==amb)
local build=GameInfo.Builds[GameInfoTypes.BUILD_FARM];if build.PrereqTech then Teams[0].tech[GameInfoTypes[build.PrereqTech]]=true end
assert(I.DemandFeasible(s,g,demand('FARMS',{target=1})))
farm.improvement=GameInfoTypes.IMPROVEMENT_FARM;assert(I.DemandComplete(s,g));I.CheckDemand(s,g);local earned=s.authority;I.CheckDemand(s,g);assert(s.authority==earned,'Completed demands cannot reward twice')
local iron=GameInfoTypes.RESOURCE_IRON;local mine=GameInfoTypes.IMPROVEMENT_MINE;farm.improvement=-1;farm.resource=iron
local d=demand('RESOURCE',{x=farm.x,y=farm.y,resource=iron,improvement=mine});local mineBuild=GameInfo.Builds[GameInfoTypes.BUILD_MINE]
if mineBuild.PrereqTech then Teams[0].tech[GameInfoTypes[mineBuild.PrereqTech]]=nil;assert(not I.DemandFeasible(s,g,d));Teams[0].tech[GameInfoTypes[mineBuild.PrereqTech]]=true end
assert(I.DemandFeasible(s,g,d));farm.resource=-1;I.CheckDemand(s,g);assert(not g.demand)
demand('CAMP',{x=-500,y=-500});I.CheckDemand(s,g);assert(not g.demand)
demand('AUTONOMY');I.CheckDemand(s,g);assert(not g.demand,'Legacy impossible autonomy requests cancel without penalty')
-- Failed petitions retain deadlines across loading and fail exactly once.
d=demand('FUNDS');local deadline=d.deadline;I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);g=s.governors[g.key]
assert(g.demand.deadline==deadline);Turn=deadline;local l=g.loyalty;I.CheckDemand(s,g);assert(g.loyalty==l-12);I.CheckDemand(s,g);assert(g.loyalty==l-12)
-- Actual native upgrade order loses active bonuses before UnitConverted.
local u=p:InitUnit(GameInfoTypes.UNIT_IMPERIAL_LEGION,c.x+2,c.y,1);s.authority=100;I.Commit(0)
local r=s.units[u:GetID()];r.oath=19;local lineage=r.id;local up=upgrade(u:GetID(),700)
assert(s.units[700].id==lineage and s.units[700].oath==19 and up:IsHasPromotion(GameInfoTypes.PROMOTION_IMPERIAL_DISCIPLINE_ACTIVE))
-- Stale Governor IDs cannot receive battle Prestige.
r=s.units[700];r.home=g.key;r.governor=g.id-1;local prestige=g.prestige
GameEvents.CombatEnded.Fire(0,700,0,0,100,2,900,0,100,100,-1,-1,0,up.x,up.y);assert(g.prestige==prestige)
-- Duplicate loss callbacks, including after reload, cannot charge Authority twice.
local foreign=Players[2].cities[0];local x,y=foreign.x,foreign.y;s.authority=80
GameEvents.CityCaptureComplete.Fire(0,false,x,y,2,1,true);assert(s.authority==72)
GameEvents.CityCaptureComplete.Fire(0,false,x,y,2,1,true);assert(s.authority==72)
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);GameEvents.CityCaptureComplete.Fire(0,false,x,y,2,1,true);assert(s.authority==72)
-- Other civilizations retain unrelated effects; native imperial captures clear ours.
foreign.b[GameInfoTypes.BUILDING_IMPERIAL_ADMINISTRATION]=1
GameEvents.CityCaptureComplete.Fire(2,false,x,y,3,1,true);assert(foreign.b[GameInfoTypes.BUILDING_IMPERIAL_ADMINISTRATION]==1)
-- A charter resolves one participant; all others keep the war active.
local extra=newCity(0,90,18,19);p.cities[90]=extra;I.Reconcile(s)
for _,prov in ipairs(I.Provinces(s)) do prov.loyalty=10;prov.ambition=90;prov.prestige=60;prov.actionNext=0;I.City(prov,0).b[GameInfoTypes.BUILDING_IMPERIAL_PALACE]=1 end
s.authority=20;s.nextWar=0;I.BeginCivilWar(s);assert(s.war and #s.war.provinces==3)
local war=s.war;local participant=I.Provinces(s)[1];s.authority=100;p.gold=100000
assert(I.Action(0,'CHARTER',participant.key,participant.id));assert(s.war==war and s.authority==90)
local active=0;for _,faction in pairs(s.factions) do if faction.active and faction.war==war.id then active=active+1 end end;assert(active==2)
for _,prov in ipairs(I.Provinces(s)) do if prov.faction then prov.actionNext=0;assert(I.Action(0,'CHARTER',prov.key,prov.id)) end end
I.RebellionTick(s);assert(not s.war and s.authority==70,'Three settlements cost 30 Authority and receive no military completion reward')
-- AI falls back to an affordable option and pays the same price as a human.
local ai=I.State(1);local player=Players[1];local prov=I.Provinces(ai)[1];local city=I.City(prov,1)
city.b[GameInfoTypes.BUILDING_IMPERIAL_PALACE]=1;prov.loyalty=10;prov.actionNext=0;I.BeginRevolt(ai,prov)
player.gold=0;ai.authority=9;I.AITick(ai);assert(prov.faction,'AI cannot bypass affordability')
ai.authority=20;I.AITick(ai);assert(not prov.faction and ai.authority==5,'AI reconciliation pays 15 Authority')
-- A newly founded capital has no Governor but still receives dirty global effects.
s.reform='MONARCHY';s.restored=true;s.authority=90;s.inCollapse=false;I.RestorationTick(s);I.Commit(0)
p.cities[0]=newCity(0,0,50,40);GameEvents.PlayerCityFounded.Fire(0,50,40)
assert(p.cities[0]:IsHasBuilding(GameInfoTypes.BUILDING_IMPERIAL_MONARCHY))
-- Captures immediately make restoration dormant when Authority falls below 60.
s.authority=64;s.restored=true;s.restorationActive=true;I.Commit(0)
GameEvents.CityCaptureComplete.Fire(0,false,foreign.x,foreign.y,2,1,true)
-- This event was previously processed this turn; use a fresh location identity.
GameEvents.CityCaptureComplete.Fire(0,false,foreign.x+1,foreign.y,2,1,true)
assert(s.authority==56 and not s.restorationActive)
