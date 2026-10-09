local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0];Turn=1
for n=10,109 do local c=newCity(0,n,2+(n%10)*11,18+math.floor(n/10)*9);p.cities[n]=c;c.b[GameInfoTypes.BUILDING_IMPERIAL_PALACE]=1 end
for n=1000,1599 do p.units[n]=newUnit(0,n,GameInfoTypes.UNIT_WARRIOR) end
I.Reconcile(s);I.UnitTick(s,false);I.Commit(0);assert(#I.Provinces(s)>=100)
local buildings,visits=0,0;local building=I.Building;I.Building=function(...) buildings=buildings+1;return building(...) end
local units=p.Units;p.Units=function(self) local it=units(self);return function() local u=it();if u then visits=visits+1 end;return u end end
for n=1,50 do p:InitUnit(GameInfoTypes.UNIT_WARRIOR,10,10,1) end
for n=1,100 do GameEvents.CombatEnded.Fire(0,0,0,10,100,2,0,0,10,100,-1,-1,0,10,10) end
assert(buildings==0 and visits==0,'Combat and creation must not refresh every city or scan the army')
local g=I.Provinces(s)[1];g.actionNext=0;g.loyalty=60;p.gold=1000000
assert(I.Action(0,'CHARTER',g.key,g.id));assert(buildings<=#I.Effects and visits==0,'A local charter dirties only its province')
I.Authority(s,-1000);I.Commit(0);assert(visits>=650 and visits<=652,'Authority threshold changes require one army refresh')
I.Building=building;p.Units=units
-- Active conflict, expiring demands, repeated decisions and AI actions share turn saves.
local provinces=I.Provinces(s)
for n,prov in ipairs(provinces) do
 prov.demandNext=Turn+I.Scale(1000);prov.demand={kind='FUNDS',cost=20,created=Turn,deadline=Turn+I.Scale(10)}
 prov.loyalty=90
end
for _,id in ipairs({10,11,20,21}) do local prov=s.governors[I.CityKey(p.cities[id])];prov.loyalty=10;prov.ambition=90;prov.prestige=60;I.BeginRevolt(s,prov) end
s.nextWar=0;s.authority=20;I.BeginCivilWar(s);assert(s.war)
for n=1,100 do
 nextTurn(0)
 if n%7==0 then local prov=I.Provinces(s)[10];prov.actionNext=0;p.gold=1000000;I.Action(0,'BRIBE',prov.key,prov.id) end
 if n==15 then for _,f in pairs(s.factions) do if f.active then I.ResolveFaction(s,f,'RECONCILED') end end end
 if n%20==0 then I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0) end
 assert(I.RebelCount(s)<=24 and #s.history<=300)
end
for _,prov in ipairs(I.Provinces(s)) do prov.loyalty=90 end
for _,f in pairs(s.factions) do if f.active then I.ResolveFaction(s,f,'RECONCILED') end end
I.RebellionTick(s);assert(not s.war and #s.wars>=1)
-- Succession and restoration flags still apply city effects after dirty-cache reload.
s.succession=nil;s.authority=90;s.collapseResolved=true;s.inCollapse=false;s.restored=false;s.restorationSince=nil
for _,prov in ipairs(I.Provinces(s)) do prov.loyalty=90;prov.faction=nil end
I.RestorationTick(s);Turn=Turn+I.Scale(20);I.RestorationTick(s);I.Commit(0);assert(s.restorationActive)
for c in p:Cities() do assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_IMPERIAL_RESTORATION)==1) end
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);assert(s.restorationActive)
for c in p:Cities() do assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_IMPERIAL_RESTORATION)==1) end
-- Two AI decisions nested in one turn serialize the final state only once.
local ai=I.State(1);Players[1].era=1;Players[1].gold=100000;ai.authority=90;ai.averageLoyalty=80;ai.reformNext=0
for _,prov in ipairs(I.Provinces(ai)) do prov.loyalty=30;prov.ambition=95;prov.actionNext=0 end
local saves=0;local save=I.Save;I.Save=function(pid) if pid==1 then saves=saves+1 end;return save(pid) end
Turn=Turn+1;I.Turn(1);I.Save=save;assert(saves==1,'AI decisions and the owning turn share a final snapshot')
