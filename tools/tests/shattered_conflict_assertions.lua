local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0]
local g=I.Provinces(s)[1];g.loyalty=15;g.ambition=85;g.prestige=65;s.authority=15
-- Two consecutive eligible checks, never a single low-loyalty update.
I.LoyaltyTick(s);assert(not g.faction and g.critical==1);I.LoyaltyTick(s);assert(g.faction and g.rebel)
local f=s.factions[g.faction];assert(f.active and f.spawned<=3 and f.budget>=0)
local barb=Players[63];local unrelated=barb:InitUnit(GameInfoTypes.UNIT_WARRIOR,110,110,1)
I.ClearFactionUnits(f);Turn=I.Now()+I.Scale(6);I.RebellionTick(s);assert(not f.active and not g.faction)
assert(barb.units[unrelated:GetID()]==unrelated,'Faction cleanup must preserve unrelated barbarians')
-- Protected garrisons and civilians do not defect; standard low-oath field units can.
g.loyalty=5;g.rebelNext=0;local c=I.City(g,0)
local guard=p:InitUnit(GameInfoTypes.UNIT_IMPERIAL_LEGION,c.x,c.y,1);local field=p:InitUnit(GameInfoTypes.UNIT_WARRIOR,c.x+2,c.y,1)
local civilian=p:InitUnit(GameInfoTypes.UNIT_SETTLER,c.x+2,c.y+1,2)
I.UnitTick(s,false);s.units[field:GetID()].home=g.key;s.units[field:GetID()].governor=g.id;s.units[field:GetID()].oath=5
s.units[guard:GetID()].home=g.key;s.units[guard:GetID()].governor=g.id;s.units[guard:GetID()].oath=5
I.BeginRevolt(s,g);assert(p.units[guard:GetID()] and p.units[civilian:GetID()]);assert(not p.units[field:GetID()]);f=s.factions[g.faction];assert(f.defections==1)
I.ResolveFaction(s,f,'AUTONOMY');assert(g.autonomy and not g.faction and g.loyalty>=70)
-- Three coherent provinces create one claimant war; a distant severe province cannot force it.
local extra=newCity(0,90,18,19);p.cities[90]=extra;I.Reconcile(s)
for _,prov in ipairs(I.Provinces(s)) do prov.loyalty=10;prov.ambition=85;prov.prestige=60;prov.rebelNext=0 end
s.authority=20;s.nextWar=0;I.BeginCivilWar(s);assert(s.war and #s.war.provinces>=3)
local warID=s.war.id;I.BeginCivilWar(s);assert(s.war.id==warID)
local army=I.RebelCount(s);assert(army<=24)
for _,faction in pairs(s.factions) do if faction.active then
 for _=1,30 do I.SpawnRebel(s,faction,GameInfoTypes.UNIT_WARRIOR,18,19) end
 assert(faction.budget>=0 and faction.spawned<=8)
end end
assert(I.RebelCount(s)<=24)
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);assert(s.war.id==warID and I.RebelCount(s)<=24)
for _,faction in pairs(s.factions) do if faction.active then I.ResolveFaction(s,faction,'RECONCILED') end end
I.RebellionTick(s);assert(not s.war and #s.wars==1 and s.collapseResolved)
assert(s.wars[1].finish and s.wars[1].troops>0 and s.wars[1].restored>=3)
I.BeginCivilWar(s);assert(not s.war,'Civil war cooldown must prevent immediate retrigger')
-- Exhaustion guarantees a finite resolution even on inaccessible plots.
g=I.Provinces(s)[1];g.loyalty=1;g.rebelNext=0;I.BeginRevolt(s,g);f=s.factions[g.faction]
Turn=f.started+I.Scale(101);I.RebellionTick(s);assert(not f.active and f.result=='EXHAUSTED')
-- Defensive victories use final damage and respect the per-turn Authority cap.
s.authority=40;local u=p:InitUnit(GameInfoTypes.UNIT_WARRIOR,10,10,1);Map.GetPlot(10,10).owner=0
for n=1,5 do GameEvents.CombatEnded.Fire(2,900,5,100,100,0,u:GetID(),30,0,100,-1,-1,0,10,10) end
assert(s.authority==42)
GameEvents.CombatEnded.Fire(2,900,100,5,100,0,u:GetID(),100,0,100,-1,-1,0,10,10);assert(s.authority==42)
