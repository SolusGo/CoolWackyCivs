local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0]
p.cities[90]=newCity(0,90,18,19);I.Reconcile(s)
local function war()
 s.nextWar=0;s.authority=20
 for _,g in ipairs(I.Provinces(s)) do g.loyalty=10;g.ambition=85;g.prestige=60;g.rebelNext=0;g.actionNext=0;g.demand=nil end
 I.BeginCivilWar(s);assert(s.war and #s.war.provinces==3)
 local factions={};for _,fid in ipairs(I.Keys(s.factions)) do local f=s.factions[fid];if f.active and f.war==s.war.id then factions[#factions+1]=f end end
 assert(#factions==3);s.authority=50;return factions
end
local function finish(factions,results,expected,bonus,reform)
 s.reform=reform or 'NONE';local before=s.authority
 for n,f in ipairs(factions) do
  I.ResolveFaction(s,f,results[n]);local after=s.authority;I.ResolveFaction(s,f,results[n]);assert(s.authority==after,'Faction resolution rewarded twice')
 end
 local perFaction=0;for _,r in ipairs(results) do if r=='SUPPRESSED' then perFaction=perFaction+(reform=='MONARCHY' and 7 or 5) elseif r=='EXHAUSTED' then perFaction=perFaction-5 end end
 assert(s.authority==before+perFaction)
 I.RebellionTick(s);assert(not s.war);local w=s.wars[#s.wars]
 assert(w.result==expected and w.victoryBonus==bonus and s.authority==before+perFaction+bonus)
 assert(w.victories==w.suppressed and w.suppressed+w.negotiated+w.exhausted+w.lost+w.unknown==3)
 assert(s.history[#s.history].text:find(I.Text('RESULT_'..expected),1,true))
 assert(s.history[#s.history].text:find(I.Text('WAR_OUTCOMES',w.suppressed,w.negotiated,w.exhausted,w.lost,w.unknown,w.victoryBonus),1,true))
 local record=I.Encode(w);local governor=I.Provinces(s)[1];local identity=governor.id;local oath=s.units[0].oath
 I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0)
 assert(I.Encode(s.wars[#s.wars])==record and s.governors[governor.key].id==identity and s.units[0].oath==oath)
 local authority=s.authority;I.RebellionTick(s);I.Initialize(0);assert(s.authority==authority,'Completed war rewarded again')
 return s.wars[#s.wars]
end
local w=finish(war(),{'SUPPRESSED','SUPPRESSED','SUPPRESSED'},'MILITARY',10);assert(w.suppressed==3 and w.restored==3)
w=finish(war(),{'SUPPRESSED','SUPPRESSED','SUPPRESSED'},'MILITARY',10,'MONARCHY')
w=finish(war(),{'AUTONOMY','CONCESSION','RECONCILED'},'NEGOTIATED',0);assert(w.negotiated==3 and s.collapseResolved)
-- Diplomacy remains eligible for Empire Reborn under the unchanged stability rules.
s.authority=80;s.succession=nil;s.averageLoyalty=90;for _,g in ipairs(I.Provinces(s)) do g.loyalty=90 end
I.RestorationTick(s);for n=1,I.Scale(20) do Turn=Turn+1;I.RestorationTick(s) end;assert(s.restored)
w=finish(war(),{'SUPPRESSED','CONCESSION','AUTONOMY'},'MIXED',3);assert(w.suppressed==1 and w.negotiated==2)
w=finish(war(),{'SUPPRESSED','RECONCILED','SUPPRESSED'},'MIXED',6)
w=finish(war(),{'SUPPRESSED','EXHAUSTED','RECONCILED'},'EXHAUSTED',0);assert(w.exhausted==1)
w=finish(war(),{'EXHAUSTED','EXHAUSTED','EXHAUSTED'},'EXHAUSTED',0)
w=finish(war(),{'SUPPRESSED','LOST','RECONCILED'},'FAILED',0);assert(w.lost==1)

-- Upgrade an active legacy war: rebuild only provable outcomes, once.
local factions=war();I.ResolveFaction(s,factions[1],'AUTONOMY')
local legacy=s.war;legacy.outcomesVersion=nil;legacy.suppressed=nil;legacy.negotiated=nil;legacy.exhausted=nil;legacy.lost=nil;legacy.unknown=nil;legacy.victories=1
local warID=legacy.id;I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0)
assert(s.war.id==warID and s.war.negotiated==1 and s.war.suppressed==0 and s.war.victories==0 and s.war.unknown==0)
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);assert(s.war.negotiated==1)
for _,f in pairs(s.factions) do if f.active and f.war==warID then I.ResolveFaction(s,f,'RECONCILED') end end
local authority=s.authority;I.RebellionTick(s);assert(s.authority==authority and s.wars[#s.wars].result=='NEGOTIATED' and s.wars[#s.wars].negotiated==3)
-- A pruned ambiguous legacy victory receives no invented military credit.
factions=war();I.ResolveFaction(s,factions[1],'AUTONOMY');s.factions[factions[1].id]=nil
legacy=s.war;legacy.outcomesVersion=nil;legacy.victories=1;I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0)
assert(s.war.unknown==1 and s.war.victories==0)
for _,f in pairs(s.factions) do if f.active then I.ResolveFaction(s,f,'SUPPRESSED') end end
authority=s.authority;I.RebellionTick(s);assert(s.authority==authority and s.wars[#s.wars].result=='FAILED')
-- Preserve historical legacy records and already-paid rewards byte for byte.
s.wars[#s.wars+1]={id=999,name='Legacy peace',result='RESTORED',restored=3,victories=3,start=0,finish=1,leader='Old claimant',troops=9,authorityLost=10,authorityRecovered=10}
local old=I.Encode(s.wars[#s.wars]);authority=s.authority;I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0)
assert(I.Encode(s.wars[#s.wars])==old and s.authority==authority)
-- A stale Governor identity cannot convert a lost province into suppression.
factions=war();local f=factions[1];s.governors[f.origin].id=s.governors[f.origin].id+1000
assert(not I.CanAction(0,'CONCESSION',f.origin,s.governors[f.origin].id),'Stale faction must reject negotiation')
I.ResolveFaction(s,f,'SUPPRESSED');assert(f.result=='LOST' and s.war.lost==1 and s.war.suppressed==0 and s.authority==50)
-- Simulated replacement record now drops its obsolete faction link.
s.governors[f.origin].faction=nil;s.governors[f.origin].rebel=false;s.governors[f.origin].stage=0
for n=2,3 do I.ResolveFaction(s,factions[n],'RECONCILED') end;I.RebellionTick(s);assert(s.wars[#s.wars].result=='FAILED')
-- Native kill callbacks must not reenter a live resolution and duplicate rewards.
factions=war();f=factions[1];local fid=f.id;local nested=false
GameEvents.UnitPrekill.Add(function(pid) if pid==63 and not nested then nested=true;I.ResolveFaction(s,s.factions[fid],'SUPPRESSED') end end)
I.ResolveFaction(s,f,'SUPPRESSED');assert(nested and s.authority==55 and s.war.suppressed==1)
for n=2,3 do I.ResolveFaction(s,factions[n],'RECONCILED') end;I.RebellionTick(s)
-- AI concessions use the shared payment rules and never become military wins.
factions=war();p.human=false;p.gold=100000;s.authority=80
local beforeGold=p.gold;I.AITick(s);assert(s.war.negotiated==2 and s.war.suppressed==0 and p.gold<beforeGold)
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);I.AITick(s)
assert(s.war.negotiated==3 and s.war.suppressed==0);authority=s.authority;I.RebellionTick(s)
assert(s.authority==authority and s.wars[#s.wars].result=='NEGOTIATED' and s.wars[#s.wars].victoryBonus==0)
-- Authority remains bounded when rewards approach the ceiling.
p.human=true;factions=war();s.authority=99
for _,faction in ipairs(factions) do I.ResolveFaction(s,faction,'SUPPRESSED') end;I.RebellionTick(s)
assert(s.authority==100 and s.wars[#s.wars].victoryBonus==0)
