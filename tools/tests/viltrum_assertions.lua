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
local city=newCity(P,2,6,10,0,1);city.damage=101;city.resistance=5;transferCity(city,Foreign)
GameEvents.BattleStarted.Fire(0,10,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,2,1,true)
assert(has(a,'PLANET_ACTIVE'),'wounded city bonus missing')
transferCity(city,P);GameEvents.CityCaptureComplete.Fire(1,false,10,0,0,6,true)
assert(a.damage==10 and cap.pop==13 and city.resistance==4 and V.Remaining(0,'momentum')==8,'capture effects')
GameEvents.BattleFinished.Fire();assert(not has(a,'PLANET_ACTIVE'),'city bonus stuck')
GameEvents.CityCaptureComplete.Fire(1,false,10,0,0,6,true);assert(cap.pop==13 and V.Remaining(0,'momentum')==8,'recapture reward duplication')
for n=3,8 do local capturedCity=newCity(P,n,3,n*5,0,1);conquerCity(capturedCity)end
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
for n,e in pairs(GameEvents)do local expected=(n=='DeclareWar' or n=='MakePeace')and 0 or 1;assert(#e.handlers==expected,'listener count '..n)end
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
conquerCity(protected);assert(cap.pop==before and V.Remaining(0,'momentum')==0,'quarantine conquest')
local post=newUnit(P,40,200);GameEvents.CityTrained.Fire(0,0,40)
assert(not has(post,'GENOME') and not has(post,'HARDENED') and not has(post,'PUREBLOOD'),'new unit inherited original survivor')
T=13;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'pending')==3,'extinction timing')
local gold=P.gold;assert(V.Choose(0,3,1));assert(P.gold==gold-500 and V.Remaining(0,'illusion')==20,'illusion cost/duration')
reload();V=MapModData.ViltrumEmpire;assert(V.Remaining(0,'quarantine')==17 and not has(post,'GENOME'),'crisis reload')
T=30;GameEvents.PlayerDoTurn.Fire(0);assert(V.Remaining(0,'recovery')==20 and V.Remaining(0,'quarantine')==0,'quarantine recovery')
local rebuiltWarrior=newUnit(P,41,200);GameEvents.CityTrained.Fire(0,0,41);assert(has(rebuiltWarrior,'GENOME'),'post-crisis Genome missing')
assert(not P:HasPolicy(I.POLICY_VILTRUM_QUARANTINE) and P:HasPolicy(I.POLICY_VILTRUM_RECOVERY_A),'policy cleanup')
conquerCity(protected);assert(cap.pop==before,'quarantine capture consumed history')
T=60;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'outbreak')==1 and V.Get(0,'scourgeChoice')==1 and V.Get(0,'pending')==0,'outbreak repeated')
print('PASS Viltrum combat, one-time rewards, Momentum, Purge, quarantine, warnings, recovery, follow-up and reload')

-- Each audit case starts from a fresh engine double and the unmodified production
-- runtime. These cases deliberately use complete CP callback argument lists.
local function reset()
 assert(loadstring(MockSource))();assert(loadstring(RuntimeSource))()
 return MapModData.ViltrumEmpire,GameInfoTypes
end
for choice=1,2 do
 local V,I=reset();newCity(P,0,10);newUnit(P,1,200)
 state('pending',2);state('outbreak',1);assert(V.Choose(0,2,choice))
 local crisis=choice==1 and 'quarantine' or 'dying'
 local survivor=nil;for u in P:Units()do survivor=u end
 local aux=newUnit(P,80,212);GameEvents.CityTrained.Fire(0,0,80,false,false);assert(not aux:IsHasPromotion(I.PROMOTION_VILTRUM_BLOODLINE) and not aux:IsHasPromotion(I.PROMOTION_VILTRUM_FLIGHT),'Auxiliary inherited biology/flight')
 local fresh=newUnit(P,2,200);GameEvents.CityTrained.Fire(0,0,2,false,false)
 assert(not fresh:IsHasPromotion(I.PROMOTION_VILTRUM_GENOME),'Genome granted inside '..crisis)
 reload();V=MapModData.ViltrumEmpire
 local bought=newUnit(P,3,200);GameEvents.CityTrained.Fire(0,0,3,true,false)
 assert(not bought:IsHasPromotion(I.PROMOTION_VILTRUM_GENOME),'reload enabled crisis Genome')
 assert(not survivor:IsHasPromotion(I.PROMOTION_VILTRUM_GENOME),'original survivor gained Genome')
 local beforeUpgrade=newUnit(P,4,202);beforeUpgrade.promotions=fresh.promotions;fresh:Kill()
 GameEvents.UnitUpgraded.Fire(0,2,4,false)
 assert(not beforeUpgrade:IsHasPromotion(I.PROMOTION_VILTRUM_GENOME),'upgrade created Genome')
 T=V.Get(0,crisis) -- CP CityTrained runs before PlayerDoTurn at expiry.
 local post=newUnit(P,5,200);GameEvents.CityTrained.Fire(0,0,5,false,true)
 assert(V.Get(0,'recovered')==1 and post:IsHasPromotion(I.PROMOTION_VILTRUM_GENOME),'expiry-boundary Genome missing')
 assert(not survivor:IsHasPromotion(I.PROMOTION_VILTRUM_GENOME),'recovery retroactively marked survivor')
 local upgraded=newUnit(P,6,202);upgraded.promotions=post.promotions;post:Kill();GameEvents.UnitUpgraded.Fire(0,5,6,false)
 reload();assert(upgraded:IsHasPromotion(I.PROMOTION_VILTRUM_GENOME),'upgrade/reload removed Genome')
end
print('PASS audit Genome: both crises, Gold/Faith completions, expiry boundary, survivors, upgrades and reload')

for _,kind in ipairs({'original','relocated','noncapital','ordinary'})do
 local V,I=reset();newCity(P,0,10)
 local a=newUnit(P,1,200);a.damage=80
 local unrelated=newUnit(P,2,200);unrelated.damage=80
 if kind~='ordinary'then a:SetHasPromotion(I.PROMOTION_VILTRUM_PUREBLOOD,true)end
 newCity(Foreign,0,10,20,0)
 local c=newCity(Foreign,1,5,5,0)
 if kind=='original'then c.originalCapital=true;Foreign.capital=c
 elseif kind=='relocated'or kind=='ordinary'then Foreign.capital=c;c.originalCapital=false end
 GameEvents.BattleStarted.Fire(0,5,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,1,1,true)
 -- Bystanders must not replace the attacker or defending city.
 GameEvents.BattleJoined.Fire(0,2,3,false)
 transferCity(c,P);GameEvents.CityCaptureComplete.Fire(1,c.originalCapital,5,0,0,5,true,0,0)
 local expected=(kind=='original'or kind=='relocated')and 0 or 45
 assert(a.damage==expected and unrelated.damage==80,'personal current capital heal '..kind)
 a.damage=70;GameEvents.CityCaptureComplete.Fire(1,true,5,0,0,5,true,0,0)
 assert(a.damage==70,'duplicate callback repeated personal capture heal')
 GameEvents.BattleFinished.Fire()
 a.damage=80;GameEvents.CityCaptureComplete.Fire(1,true,5,0,0,5,false,0,0)
 assert(a.damage==80,'trade/liberation healed unit')
end
print('PASS audit capitals: original, relocated, non-capital, ordinary, bystander and trade/callback safeguards')

do
 local V,I=reset();local c=newCity(P,0,10);state('quarantine',20);V.Refresh(0)
 for _,typ in ipairs({208,209,210})do assert(not V.CanTrain(0,0,typ),'Settler/Caravan/Cargo Ship gate')end
 for _,typ in ipairs({211,202,200,212})do assert(V.CanTrain(0,0,typ),'Worker/ordinary military/Warrior blocked')end
 assert(V.CanTrain(1,0,208),'foreign training blocked')
 -- Native CP getGrowthMods is additive then clamped; all negative food bypasses it.
 c.food=12.5;c.growthBonus=35;V.Refresh(0)
 assert(c:FoodDifferenceTimes100()==0,'Purge/WLTKD bonus bypassed quarantine')
 c:Grow();assert(c.pop==10 and c.food==12.5,'stored food changed during zero surplus')
 c.growthBonus=135;Events.SerialEventCityInfoDirty.Fire();assert(c:FoodDifferenceTimes100()==0,'new growth bonus escaped event gate')
 reload();V=MapModData.ViltrumEmpire;c:Grow();assert(c.pop==10 and c.food==12.5,'growth freeze changed on reload')
 c.food=45;V.Refresh(0);c:Grow();assert(c.pop==10 and c.food==29,'above-threshold food caused phantom growth')
 c.food=1;c.surplus=-200;Events.SerialEventCityInfoDirty.Fire();c:Grow();assert(c.pop==9 and c.food==0,'quarantine disabled starvation')
 T=20;GameEvents.PlayerDoTurn.Fire(0)
 for i=0,13 do assert(not P:HasPolicy(700+i),'compensation policy leaked into recovery')end
 assert(V.CanTrain(0,0,208)and V.CanTrain(0,0,209)and V.CanTrain(0,0,210),'training blocked after expiry')
end
print('PASS audit quarantine: training types, additive growth bonuses, event refresh, stored food, starvation, reload and cleanup')

-- Protection is an extra survivor, capped at the original population; floors
-- cannot create citizens in a tiny city. 48 combinations cover both branches.
for choice=1,2 do for _,pop in ipairs({1,2,3,5,10,20})do for _,capital in ipairs({false,true})do for _,complex in ipairs({false,true})do
 local V=reset();if not capital then newCity(P,0,10)end
 local c=newCity(P,1,pop,5,0);if complex then c.buildings[300]=1 end
 state('pending',2);state('outbreak',1);assert(V.Choose(0,2,choice))
 local expected=math.min(pop,math.max(capital and 2 or 1,math.floor(pop*(choice==1 and .25 or .15)))+(complex and 1 or 0))
 assert(c.pop==expected and c.pop<=pop,'Complex protection exceeded pre-outbreak population')
end end end end
print('PASS audit population protection: 48 branch/population/Complex/capital combinations')

do
 local V,I=reset();local c=newCity(P,0,10);local far=newCity(P,1,10,10,0)
 local a=newUnit(P,1,200);c.garrison=a;V.Refresh(0)
 local before=far.writes;c.garrison=nil;a.tile=plot(1,0);GameEvents.UnitSetXY.Fire(0,1,1,0)
 assert(c.buildings[I.BUILDING_VILTRUM_GARRISON]==0 and far.writes==before,'movement scanned unrelated city')
 far.garrison=a;a.tile=plot(10,0);GameEvents.UnitSetXY.Fire(0,1,10,0)
 assert(far.buildings[I.BUILDING_VILTRUM_GARRISON]==1,'city entry did not update garrison')
 reload();V=MapModData.ViltrumEmpire;far.garrison=nil;a.tile=nil;P.units[1]=nil;GameEvents.UnitSetXY.Fire(0,1,-1,-1)
 assert(far.buildings[I.BUILDING_VILTRUM_GARRISON]==0,'garrison death/load cache failed')
 local reads=WarChecks;GameEvents.PlayerDoTurn.Fire(1);assert(WarChecks==reads,'foreign turn scanned peace locks')
 V.Refresh(0);assert(WarChecks==reads,'ordinary refresh scanned peace locks')
 state('noPeace',10);Teams[0].war[2]=true;Teams[2].war[0]=true
 Events.WarStateChanged.Fire(0,2,true);assert(Teams[0]:IsPermanentWarPeace(2),'post-state declaration failed')
 Foreign.team=2;assert(not V.CanPeace(1,0),'team/player IDs mixed in peace gate')
 Teams[0].war[2]=false;Teams[2].war[0]=false;Events.WarStateChanged.Fire(0,2,false)
 assert(not Teams[0]:IsPermanentWarPeace(2),'post-state forced peace failed')
 Teams[0].permanent[2]=true;Teams[0].war[2]=true;Events.WarStateChanged.Fire(0,2,true)
 T=10;GameEvents.PlayerDoTurn.Fire(0);assert(Teams[0]:IsPermanentWarPeace(2),'scenario flag removed')
 reads=WarChecks;T=11;GameEvents.PlayerDoTurn.Fire(0);assert(WarChecks==reads,'expired lock scans continued')
end
print('PASS audit performance: targeted garrisons, load/death, foreign turns, ordinary refreshes, team IDs and peace events')

do
 local V,I=reset();newCity(P,0,10);local a=newUnit(P,1,200);local d=newUnit(Foreign,1,202);d.damage=80
 GameEvents.BattleStarted.Fire(0,1,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,1,1,false)
 assert(a:IsHasPromotion(I.PROMOTION_VILTRUM_EXECUTION_ACTIVE))
 -- CP withdrawal and RED abort omit Finished. A fresh battle retires the stale state.
 GameEvents.BattleStarted.Fire(1,2,0);assert(not a:IsHasPromotion(I.PROMOTION_VILTRUM_EXECUTION_ACTIVE),'withdrawal leaked target bonus')
 d.damage=50;GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,1,1,false)
 GameEvents.BattleJoined.Fire(0,1,2,false);GameEvents.BattleJoined.Fire(0,1,3,false)
 assert(not a:IsHasPromotion(I.PROMOTION_VILTRUM_EXECUTION_ACTIVE),'interceptor/bystander overwrote target')
 GameEvents.BattleFinished.Fire();GameEvents.BattleFinished.Fire()
 GameEvents.BattleStarted.Fire(0,1,0);d.damage=80;GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,1,1,false)
 reload();assert(not a:IsHasPromotion(I.PROMOTION_VILTRUM_EXECUTION_ACTIVE),'reload retained unfinished combat bonus')
 a.moves=60;a.attacks=3;GameEvents.ParadropAt.Fire(0,1,0,0,7,0)
 assert(a.attacks==0 and a.moves==60,'drop reset did not preserve one native move/reset attack counter')
 a:SetHasPromotion(I.PROMOTION_BLITZ,true);a.attacks=3;GameEvents.ParadropAt.Fire(0,1,0,0,7,0);assert(a.attacks==0 and a.moves==60,'Blitz drop counter failed')
 local ordinary=newUnit(P,2,202);ordinary.attacks=1;GameEvents.ParadropAt.Fire(0,2,0,0,7,0);assert(ordinary.attacks==1,'ordinary paradrop modified')
end
print('PASS audit combat: missing Finished, repeated finish, bystanders/interceptors, reload and native paradrop counter semantics')

for _,queued in ipairs({false,true})do
 local V,I=reset();newCity(P,0,10);local a=newUnit(P,1,200);a.damage=60
 local d=newUnit(Foreign,1,202);d.damage=80;local support=newUnit(Foreign,2,202)
 GameEvents.BattleStarted.Fire(0,5,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,1,1,false)
 -- Native Attack generates melee info before defensive support. Support can
 -- complete immediately or queue an animation and postpone the outer melee.
 GameEvents.BattleStarted.Fire(1,0,0);GameEvents.BattleJoined.Fire(1,2,0,false);GameEvents.BattleJoined.Fire(0,1,1,false)
 GameEvents.CombatResult.Fire(1,2,0,0,100,0,1,0,60,100,-1,-1,0,0,0);GameEvents.BattleFinished.Fire()
 if queued then
  -- A different combat may resolve before the queued melee retries.
  local extra=newUnit(P,3,202);local enemy=newUnit(Foreign,3,202)
  GameEvents.BattleStarted.Fire(0,8,0);GameEvents.BattleJoined.Fire(0,3,0,false);GameEvents.BattleJoined.Fire(1,3,1,false)
 end
 GameEvents.CombatResult.Fire(0,1,0,60,100,1,1,0,100,100,-1,-1,0,5,0);d:Kill();GameEvents.BattleFinished.Fire()
 assert(a.damage==45 and not a:IsHasPromotion(I.PROMOTION_VILTRUM_EXECUTION_ACTIVE),'support lost outer kill context')
 if queued then GameEvents.CombatResult.Fire(0,3,0,0,100,1,3,0,0,100,-1,-1,0,8,0);GameEvents.BattleFinished.Fire()end
end
do
 local V,I=reset();local cap=newCity(P,0,10);local a=newUnit(P,1,200);a.damage=70;a:SetHasPromotion(I.PROMOTION_VILTRUM_PUREBLOOD,true)
 local c=newCity(Foreign,0,5,5,0);Foreign.capital=c
 GameEvents.BattleStarted.Fire(0,5,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,0,1,true)
 -- Simulate a later unrelated battle becoming the last generated context.
 local other=newUnit(P,2,202);local foe=newUnit(Foreign,2,202)
 GameEvents.BattleStarted.Fire(0,8,0);GameEvents.BattleJoined.Fire(0,2,0,false);GameEvents.BattleJoined.Fire(1,2,1,false)
 GameEvents.CombatResult.Fire(0,1,0,70,100,1,-1,0,200,200,-1,-1,0,5,0)
 transferCity(c,P);GameEvents.CityCaptureComplete.Fire(1,true,5,0,0,5,true,0,0);GameEvents.BattleFinished.Fire()
 assert(a.damage==0 and cap.pop==11,'identity-keyed city capture selected wrong combat')
 GameEvents.CombatResult.Fire(0,2,0,0,100,1,2,0,0,100,-1,-1,0,8,0);GameEvents.BattleFinished.Fire()
 local ceded=newCity(P,2,5,10,0,1);local before=cap.pop
 GameEvents.CityCaptureComplete.Fire(1,false,10,0,0,5,true,0,0)
 assert(cap.pop==before and V.Get(0,'capture:10:0:0:1')==0,'peace-ceded city awarded/consumed conquest history')
 conquerCity(ceded);assert(cap.pop==before+1,'ceded city cannot earn later real conquest reward')
end
print('PASS audit combat identity: nested/queued support, out-of-order resolution, personal city capture and peace cessions')
do
 local V,I=reset();newCity(P,0,10);local foreignCity=newCity(Foreign,0,5,9,0)
 local defender=newUnit(P,1,200);defender.damage=60
 GameEvents.BattleStarted.Fire(1,0,0);GameEvents.BattleJoined.Fire(1,0,0,true);GameEvents.BattleJoined.Fire(0,1,1,false)
 local other=newUnit(P,2,200);other.damage=50;local enemy=newUnit(Foreign,2,202)
 GameEvents.BattleStarted.Fire(0,5,0);GameEvents.BattleJoined.Fire(0,2,0,false);GameEvents.BattleJoined.Fire(1,2,1,false);enemy:Kill()
 -- CP city bombardment reports both attacker player and unit as -1.
 GameEvents.CombatResult.Fire(-1,-1,0,0,100,0,1,0,60,100,-1,-1,0,0,0);GameEvents.BattleFinished.Fire()
 assert(other.damage==50 and defender.damage==60,'anonymous city attacker selected unrelated combat')
 GameEvents.CombatResult.Fire(0,2,0,50,100,1,2,0,100,100,-1,-1,0,5,0);GameEvents.BattleFinished.Fire()
 assert(other.damage==35,'queued unit kill context lost after city bombardment')
end
print('PASS audit city bombardment: native anonymous city-attacker identity and unrelated queued combat')

for _,resistance in ipairs({1,2,3,5,9,10})do
 local V=reset();newCity(P,0,10);local c=newCity(P,1,5,5,0,1);c.resistance=resistance
 conquerCity(c)
 assert(c.resistance==resistance-math.ceil(resistance*.20),'rounded-up resistance changed')
end
print('PASS audit resistance: ceil 20%, minimum one turn, six boundary cases')
