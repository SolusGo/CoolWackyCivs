local M=MapModData.CR7
local T=GameInfoTypes
local normal=T.PROMOTION_SHOCK_1
local c=NewCity(0,1,0,0,1)
local u=NewUnit(0,1,'UNIT_WARRIOR')
assert(Has(u,'HABIT'))
u.damage=45
for i=1,4 do u.level=i+1;GameEvents.UnitPromoted(0,1,normal)end
Equal(Ambition(),3,'promotion cap')
GameEvents.UnitPromoted(0,1,T.PROMOTION_CR7_REINVENTION_1)
Equal(Ambition(),3,'free promotion excluded')
-- Promotion healing occurs once per unit per turn and saved limits survive reloading.
Players[0].era=1
M.AddAmbition(0,42,'test',false)
assert(M.GetUIState(0).unlocked[2]);Equal(u.damage,45)
CurrentTurn=1
u.level=u.level+1;GameEvents.UnitPromoted(0,1,normal);Equal(u.damage,35)
u.level=u.level+1;GameEvents.UnitPromoted(0,1,normal);Equal(u.damage,35)
-- Chapter I waits for tech AND construct requirements, and only grants once.
assert(not c:IsHasBuilding(T.BUILDING_CR7_SPORTING_ACADEMY))
Teams[0].techs[T.TECH_BRONZE_WORKING]=true;c.allowConstruct=false
M.OnTurn(0);assert(not c:IsHasBuilding(T.BUILDING_CR7_SPORTING_ACADEMY))
CurrentTurn=2;c.allowConstruct=true;M.OnTurn(0)
assert(c:IsHasBuilding(T.BUILDING_CR7_SPORTING_ACADEMY))
c.buildings[T.BUILDING_CR7_SPORTING_ACADEMY]=0;CurrentTurn=3;M.OnTurn(0)
Equal(c:GetNumRealBuilding(T.BUILDING_CR7_SPORTING_ACADEMY),0,'free academy cannot repeat')
c.buildings[T.BUILDING_CR7_SPORTING_ACADEMY]=1
local graduate=NewUnit(0,2,'UNIT_WARRIOR')
M.OnTrained(0,1,2,false,false);Equal(graduate.xp100,1000,'capital plus Lisbon XP')
assert(Has(graduate,'FIRST_IN') and Has(graduate,'ACADEMY_TRAINING'))
graduate.level=4;M.OnPromoted(0,2,normal)
Equal(c.production,15);Equal(c.culture,10)
local second=NewUnit(0,3,'UNIT_WARRIOR',0,0,4)
M.OnTrained(0,1,3,false,false);Equal(c.production,15,'city era cap')
local bought=NewUnit(0,4,'UNIT_WARRIOR')
M.OnTrained(0,1,4,true,false)
assert(not Has(bought,'FIRST_IN') and not Has(bought,'ACADEMY_TRAINING'));Equal(bought.xp100,0)
-- Ordinary XP behavior before VI is preserved; Reinvention replaces tiers.
u=Upgrade(u,10,'UNIT_SPEARMAN');assert(Has(u,'REINVENTION_1'))
u=Upgrade(u,11,'UNIT_PIKEMAN');assert(Has(u,'REINVENTION_2') and not Has(u,'REINVENTION_1'))
u=Upgrade(u,12,'UNIT_RIFLEMAN');assert(Has(u,'REINVENTION_3'))
u=Upgrade(u,13,'UNIT_INFANTRY');assert(Has(u,'REINVENTION_3') and not Has(u,'REINVENTION_4'))
local fresh=NewUnit(0,20,'UNIT_INFANTRY')
assert(not Has(fresh,'REINVENTION_1'))
local admin=NewUnit(0,21,'UNIT_RIFLEMAN')
M.OnConverted(0,0,20,21,true);assert(not Has(admin,'REINVENTION_1'),'administrative conversion')
-- Era gates keep large Ambition grants from skipping era requirements.
M.AddAmbition(0,200,'test',false)
Equal(M.GetUIState(0).chapter,2)
Players[0].era=6;M.CheckChapters(0);Equal(M.GetUIState(0).chapter,6)
u.damage=80;u.xp100=12345
u=Upgrade(u,14,'UNIT_MECHANIZED_INFANTRY')
assert(Has(u,'REINVENTION_4') and not Has(u,'REINVENTION_3'))
Equal(u.damage,65,'low health upgrade healing');Equal(u.xp100,12345,'full XP retention')
M.OnConverted(0,0,13,14,true);Equal(u.damage,65,'duplicate conversion harmless')
-- Original/reduced Finisher cannot coexist. No extra attacks from restored movement.
local forward=NewUnit(0,30,'UNIT_CR7_COMPLETE_FORWARD',0,0,4)
M.OnTrained(0,1,30,false,false);forward.damage=50
local enemy=NewUnit(1,1,'UNIT_CR7_COMPLETE_FORWARD',2,0)
local before=Ambition();Kill(forward,enemy,true)
Equal(forward.damage,42,'finisher healing once');Equal(forward.moves,60);Equal(forward.attacks,1)
Equal(Ambition(),before+1)
Kill(forward,NewUnit(1,2,'UNIT_CR7_COMPLETE_FORWARD',2,0),false)
Equal(forward.moves,60,'one movement refund per turn')
forward=Upgrade(forward,31,'UNIT_WWI_TANK')
assert(not Has(forward,'FINISHER') and not Has(forward,'FORWARD_MOBILITY') and Has(forward,'FINISHER_VETERAN'))
forward.damage=50;Kill(forward,NewUnit(1,3,'UNIT_WWI_TANK',2,0),true)
Equal(forward.damage,42,'retained finisher plus Reinvention I')
-- Combat cap, weaker/civilian victims and duplicate callbacks.
CurrentTurn=10;before=Ambition()
for id=10,14 do Kill(fresh,NewUnit(1,id,'UNIT_INFANTRY',2,0),true)end
Equal(Ambition(),before+3,'combat cap')
Kill(fresh,NewUnit(1,20,'UNIT_WARRIOR',2,0),false);Equal(Ambition(),before+3)
-- Explosive movement max is sampled once before normal DLL movement refill.
forward.damage=9;M.OnTurn(0);assert(Has(forward,'EXPLOSIVE_MOVE'))
forward.damage=20;M.OnTurn(0);assert(Has(forward,'EXPLOSIVE_MOVE'),'same turn must not retoggle')
CurrentTurn=11;M.OnTurn(0);assert(not Has(forward,'EXPLOSIVE_MOVE'))
forward:GetPlot().open=false;GameEvents.UnitSetXY(0,31,0,0);assert(not Has(forward,'EXPLOSIVE_OPEN'))
forward:GetPlot().open=true;GameEvents.UnitSetXY(0,31,0,0);assert(Has(forward,'EXPLOSIVE_OPEN'))
-- Native +15 General points is only present while fighting a major-civ unit.
enemy=NewUnit(1,30,'UNIT_INFANTRY',2,0)
M.OnBattleStarted(0,2,0);M.OnCombatResult(0,31,1,0,100,1,30,1,0,100,-1,-1,0,2,0)
assert(Has(forward,'MADRID_GG'));M.OnBattleFinished();assert(not Has(forward,'MADRID_GG'))
-- Two Generals do not stack the aura. Death removes it immediately.
local g1=NewUnit(0,40,'UNIT_GREAT_GENERAL',0,0)
local g2=NewUnit(0,41,'UNIT_GREAT_GENERAL',1,0)
forward.damage=50;CurrentTurn=12;M.OnTurn(0);Equal(forward.damage,47)
M.OnPrekill(0,40,g1.typ,0,0,true,1);assert(Has(forward,'CAPTAIN'))
M.OnPrekill(0,41,g2.typ,1,0,true,1);assert(not Has(forward,'CAPTAIN'))
Players[0].units[40]=nil;Players[0].units[41]=nil
-- Defensive declarations use againstTeam, never mistake the attacking player for defender.
forward.damage=50;before=Players[0].gap
M.OnWar(1,0,true);Equal(Players[0].gap,before+50);Equal(forward.damage,45)
M.OnWar(1,0,true);Equal(Players[0].gap,before+50)
CurrentTurn=42;M.OnWar(0,1,true);Equal(Players[0].gap,before+50,'offensive war does not reward')
M.OnWar(1,0,true);Equal(Players[0].gap,before+100)
-- GP administrative creation is excluded; genuine threshold-changing birth rewarded once.
before=Ambition();local general=NewUnit(0,42,'UNIT_GREAT_GENERAL')
M.OnTurn(0);Equal(Ambition(),before)
general=NewUnit(0,43,'UNIT_GREAT_GENERAL');Players[0].generalThreshold=50
CurrentTurn=43;M.OnTurn(0);Equal(Ambition(),before+3)
M.OnTurn(0);Equal(Ambition(),before+3)
-- Population milestones survive shrink/regrowth; wonders need genuine completion.
c.population=36;before=Ambition();GameEvents.SetPopulation(0,0,1,36);Equal(Ambition(),before+6)
GameEvents.SetPopulation(0,0,36,36);Equal(Ambition(),before+6)
before=Ambition();M.OnConstructed(0,1,T.BUILDING_PYRAMID,true,false);Equal(Ambition(),before)
M.OnConstructed(0,1,T.BUILDING_PYRAMID,false,false);Equal(Ambition(),before+4)
M.OnConstructed(0,1,T.BUILDING_PYRAMID,false,false);Equal(Ambition(),before+4)
M.OnConstructed(0,1,T.BUILDING_NATIONAL_COLLEGE,false,false);Equal(Ambition(),before+6)
-- Three overseas cities, replacement after loss and Flight-dependent Tourism.
for id=2,5 do NewCity(0,id,10+id,0,2)end
M.OnTurn(0)
for id=2,4 do Equal(Players[0].cities[id]:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS),1)end
Equal(Players[0].cities[5]:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS),0)
Players[0].cities[2]=nil;Teams[0].techs[T.TECH_FLIGHT]=true;CurrentTurn=44;M.OnTurn(0)
Equal(Players[0].cities[5]:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS),1)
Equal(Players[0].cities[5]:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS_FLIGHT),1)
-- Capturing unit comes from battle role even while standing outside city.
local captured=NewCity(0,8,22,0,2);captured.originalCapital=true;captured.originalOwner=1;captured.population=10
M.OnBattleStarted(0,22,0);M.OnBattleJoined(0,31,0,false);M.OnBattleJoined(1,8,1,true)
M.OnCombatResult(0,31,1,0,100,1,-1,1,200,200,-1,-1,0,22,0)
-- At CombatResult the city still belongs to the old owner in the real DLL.
M.OnBattleJoined(1,8,1,true)
forward.damage=50;before=Ambition();local culture=Players[0].culture
M.OnCapture(1,true,22,0,0,10,true)
Equal(Ambition(),before+9,'capital plus new Golden Age');Equal(Players[0].culture,culture+30);Equal(forward.damage,35)
local experience=forward.xp100
M.OnCapture(1,true,22,0,0,10,true);Equal(Ambition(),before+9);Equal(forward.xp100,experience)
M.OnBattleFinished()
-- VII one-time effects, and repeatable rewards keep granting both independent capped modifiers.
Players[0].era=7;M.CheckChapters(0)
if M.GetUIState(0).chapter<7 then M.AddAmbition(0,275-Ambition(),'test',false)end
Equal(M.GetUIState(0).chapter,7);Equal(Players[0].freePolicies,1);Equal(forward.damage,0)
local turns=Players[0].golden;culture=Players[0].culture
M.AddAmbition(0,420,'test',false)
Equal(M.GetUIState(0).legacy,7);Equal(Players[0].golden,turns+7);Equal(Players[0].culture,culture+7*105)
for n=1,5 do assert(Players[0]:HasPolicy(T['POLICY_CR7_LEGACY_'..n]))end
local free=Players[0].freePolicies;M.CheckChapters(0);Equal(Players[0].freePolicies,free)
TestForward=forward
print('PASS CR7 runtime: caps, training, seven chapters, upgrades, combat, auras, captures, GP, overseas and legacy')
