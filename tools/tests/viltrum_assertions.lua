local V=MapModData.ViltrumEmpire
local I=GameInfoTypes
local function has(u,n)return u:IsHasPromotion(I['PROMOTION_VILTRUM_'..n])end
local cap=newCity(P,0,12,0,0);local second=newCity(P,1,8,5,0)
local a=newUnit(P,1,200);a.damage=60
local d=newUnit(Foreign,2,202);d.damage=80
GameEvents.BattleStarted.Fire(0,10,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,2,1,false)
assert(has(a,'EXECUTION_ACTIVE'),'Execution not enabled against <50 HP target')
d:Kill();GameEvents.BattleFinished.Fire();assert(a.damage==45 and not has(a,'EXECUTION_ACTIVE'),'military kill heal/cleanup')
d=newUnit(Foreign,3,202);d.damage=50
GameEvents.BattleStarted.Fire(0,10,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,3,1,false)
assert(not has(a,'EXECUTION_ACTIVE'),'exactly 50 HP target got Execution');GameEvents.BattleFinished.Fire()
d=newUnit(Foreign,4,208,false)
GameEvents.BattleStarted.Fire(0,10,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,4,1,false);d:Kill();GameEvents.BattleFinished.Fire();assert(a.damage==45,'civilian kill healed')
d=newUnit(Barb,2,202)
GameEvents.BattleStarted.Fire(0,10,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(63,2,1,false);d:Kill();GameEvents.BattleFinished.Fire();assert(a.damage==45,'barbarian farm heal')
local city=newCity(P,2,6,10,0,1);city.damage=101;city.resistance=5
GameEvents.BattleStarted.Fire(0,10,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(0,2,1,true)
assert(has(a,'PLANET_ACTIVE'),'wounded city bonus missing')
GameEvents.CityCaptureComplete.Fire(1,false,10,0,0,6,true)
assert(a.damage==10 and cap.pop==13 and city.resistance==4 and V.Remaining(0,'momentum')==8,'capture effects')
GameEvents.BattleFinished.Fire();assert(not has(a,'PLANET_ACTIVE'),'city bonus stuck')
GameEvents.CityCaptureComplete.Fire(1,false,10,0,0,6,true);assert(cap.pop==13 and V.Remaining(0,'momentum')==8,'recapture reward duplication')
for n=3,8 do newCity(P,n,3,n*5,0,1);GameEvents.CityCaptureComplete.Fire(1,false,n*5,0,0,3,true)end
assert(V.Remaining(0,'momentum')==18,'Momentum cap')
cap.garrison=a;V.Refresh(0);assert(cap.buildings[I.BUILDING_VILTRUM_GARRISON]==1,'garrison absent')
cap.garrison=nil;GameEvents.UnitSetXY.Fire(0,1);assert(cap.buildings[I.BUILDING_VILTRUM_GARRISON]==0,'garrison stuck')
cap.buildings[300]=1;local pop=cap.pop
GameEvents.CityConstructed.Fire(0,0,300);GameEvents.CityConstructed.Fire(0,0,300);assert(cap.pop==pop+1,'complex duplicated reward')
cap.buildings[300]=0;cap.buildings[300]=1;GameEvents.CityConstructed.Fire(0,0,300);assert(cap.pop==pop+1,'rebuild farming')
local trainee=newUnit(P,10,202);GameEvents.CityTrained.Fire(0,0,10);assert(trainee.xp==3 and has(trainee,'CONDITIONING'),'conditioning/Momentum training')
trainee.tile=plot(1,1,-1);GameEvents.UnitSetXY.Fire(0,10);assert(has(trainee,'CONDITION_ACTIVE'),'outside strength')
trainee.tile=plot(0,0,0);GameEvents.UnitSetXY.Fire(0,10);assert(not has(trainee,'CONDITION_ACTIVE'),'friendly strength stuck')
GameEvents.ParadropAt.Fire(0,1);assert(a.madeAttack==false,'postdrop attack unavailable')
local before=cap.pop;reload();V=MapModData.ViltrumEmpire
assert(V.Remaining(0,'momentum')==18,'Momentum lost on reload')
GameEvents.CityConstructed.Fire(0,0,300);GameEvents.CityCaptureComplete.Fire(1,false,10,0,0,6,true);assert(cap.pop==before,'save reload duplication')
for _,e in pairs(GameEvents)do assert(#e.handlers==1,'duplicate event listeners')end
P.era=2;T=1;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'pending')==1,'Purge trigger')
assert(V.Choose(0,1,1));assert(cap.pop==before-1 and a.xp==10,'Purge immediate')
assert(not V.Choose(0,1,1),'repeat Purge choice')
local fresh=newUnit(P,20,202);GameEvents.CityTrained.Fire(0,0,20);assert(fresh.xp==6,'permanent +3 future land XP')
T=2;GameEvents.PlayerDoTurn.Fire(0);local gg=P.general;GameEvents.PlayerDoTurn.Fire(0);assert(P.general==gg,'GG duplicated same turn')
Teams[0].tech[10]=true;GameEvents.TeamTechResearched.Fire(0,10);assert(V.Get(0,'research')==2,'research turn')
GameEvents.UnitCreated.Fire(0,1);assert(V.Get(0,'countdown')==2 and has(a,'WARNING'),'first Warrior countdown')
T=7;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'warnThree')==1,'three turn warning')
T=9;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'warnOne')==1,'last warning')
T=10;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'pending')==2 and V.Get(0,'outbreak')==1,'outbreak deadline')
-- Ten Bloodline units and a conventional/civilian force.
for n=21,29 do newUnit(P,n,200)end
local conventional=newUnit(P,30,202);local civilian=newUnit(P,31,208,false)
cap.pop=20;second.pop=8;assert(V.Choose(0,2,1))
assert(cap.pop==6 and second.pop==2,'quarantine population/protection')
local count=0;for u in P:Units()do if has(u,'BLOODLINE')then count=count+1;assert(has(u,'HARDENED') and u.damage==75,'survivor marker/HP')end end
assert(count==2 and P.units[30] and P.units[31] and RNGCalls==9,'casualty count/safe RNG')
assert(V.Remaining(0,'quarantine')==20 and V.Remaining(0,'momentum')==0,'quarantine timers')
assert(not V.CanTrain(0,0,208) and not V.CanTrain(0,0,209) and V.CanTrain(0,0,202),'quarantine training restrictions')
local protected=newCity(P,9,5,45,0,1);local before=cap.pop
GameEvents.CityCaptureComplete.Fire(1,false,45,0,0,5,true);assert(cap.pop==before and V.Remaining(0,'momentum')==0,'quarantine conquest')
local post=newUnit(P,40,200);GameEvents.CityTrained.Fire(0,0,40)
assert(has(post,'GENOME') and not has(post,'HARDENED') and not has(post,'PUREBLOOD'),'new unit inherited original survivor')
T=13;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'pending')==3,'extinction timing')
local gold=P.gold;assert(V.Choose(0,3,1));assert(P.gold==gold-500 and V.Remaining(0,'illusion')==20,'illusion cost/duration')
reload();V=MapModData.ViltrumEmpire;assert(V.Remaining(0,'quarantine')==17 and has(post,'GENOME'),'crisis reload')
T=30;GameEvents.PlayerDoTurn.Fire(0);assert(V.Remaining(0,'recovery')==20 and V.Remaining(0,'quarantine')==0,'quarantine recovery')
assert(not P:HasPolicy(I.POLICY_VILTRUM_QUARANTINE) and P:HasPolicy(I.POLICY_VILTRUM_RECOVERY_A),'policy cleanup')
GameEvents.CityCaptureComplete.Fire(1,false,45,0,0,5,true);assert(cap.pop==before,'quarantine capture consumed history')
T=60;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'outbreak')==1 and V.Get(0,'scourgeChoice')==1 and V.Get(0,'pending')==0,'outbreak repeated')
print('PASS Viltrum combat, one-time rewards, Momentum, Purge, quarantine, warnings, recovery, follow-up and reload')
