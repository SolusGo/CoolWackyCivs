-- Fresh Lua 5.1 runtime per case, with actual activated CP SQL definitions.
-- These helpers inspect native building/promotion inputs, not UI summaries.
AscendantCases={}
local function count(key) return C:GetNumRealBuilding(GameInfoTypes['BUILDING_LC_'..key]) end
local function yieldModifier(yield)
 local total=0
 for row in GameInfo.Building_YieldModifiers{YieldType='YIELD_'..yield} do
  total=total+(C.buildings[GameInfoTypes[row.BuildingType]] or 0)*row.Yield
 end
 return total
end
local function cityDefense()
 local total=0
 for row in GameInfo.Buildings() do total=total+(C.buildings[row.ID] or 0)*row.GlobalDefenseMod end
 return total
end
local function defense(u)
 local total=0
 for row in GameInfo.UnitPromotions() do if u:IsHasPromotion(row.ID) then total=total+row.DefenseMod end end
 return total
end
local function promo(u,key) return u:IsHasPromotion(GameInfoTypes['PROMOTION_LC_'..key]) end
local function developed()
 L.Building(C,'DISTRICT',1)
 for _,key in ipairs({'BARRACKS','RESIDENTIAL','SHELTER','STORAGE','DEPOT','WATER','HOSPITAL'}) do L.Building(C,key,1) end
 for _,key in ipairs(L.Skills) do S.experts[key]=5;S.assigned[key]=5 end
 S.nextWave=99999;S.nextCrisis=99999;S.nextRefugee=99999;S.provisions=200;S.morale=80
end
local function achievementCount()
 local n=0;for _,h in ipairs(S.history) do if h.key=='HUMANITY_ENDURES' then n=n+1 end end;return n
end
function AscendantCases.only_completed_phase_unlocks_and_pre_balance_is_preserved()
 developed();S.majorSieges=15
 local watch=Players[0]:GetUnitByID(0);L.Promotion(watch,'VETERAN_5',true)
 for _,phase in ipairs({'LOCKED','AWAITING_SUPPLIES','FINAL_PENDING','FINAL_ACTIVE'}) do
  S.dawn=phase;S.achievement=true;S.wavesSurvived=12;S.unitDirty=true;L.Changed(S)
  assert(not L.IsAscendant(S),'Achievement flag or normal victories must not unlock Ascendant')
  assert(L.Stats(S).housing==40 and L.Stats(S).capacity==375 and L.Stats(S).income==20)
  assert(yieldModifier('SCIENCE')==15 and yieldModifier('CULTURE')==15 and yieldModifier('PRODUCTION')==25)
  assert(count('ENDURES')==0 and count('ASC_UNITED')==0 and count('ASC_LEGACY')==0)
  assert(cityDefense()==30 and L.LegacyDefense(S)==30 and defense(watch)==45)
  assert(L.RationGrowth(S,'GENEROUS')==15 and L.Medical(S)==7)
  for _,key in ipairs({'ENGINEERS','SCIENTISTS','SCHOLARS'}) do assert(count(key)==5 and count('ASC_'..key)==0) end
 end
 S.dawn='ENDURES';S.unitDirty=true;L.Changed(S)
 assert(L.IsAscendant(S) and defense(watch)==130 and cityDefense()==60)
 assert(L.Stats(S).housing==68 and L.Stats(S).capacity==550 and L.Stats(S).income==82)
 assert(yieldModifier('SCIENCE')==500 and yieldModifier('CULTURE')==400 and yieldModifier('PRODUCTION')==700)
 assert(L.RationGrowth(S,'GENEROUS')==50 and L.Medical(S)==17)
end
function AscendantCases.zero_one_three_five_assignments_native_effects_caps_and_losses()
 S.dawn='ENDURES';S.morale=80;local watch=Players[0]:GetUnitByID(0)
 for _,key in ipairs(L.Skills) do S.experts[key]=5 end
 L.Changed(S)
 for _,n in ipairs({0,1,3,5}) do
  for _,key in ipairs(L.Skills) do
   while S.assigned[key]<n do assert(L.Action(0,'EXPERT',key,1)) end
  end
  assert(yieldModifier('SCIENCE')==100*n and yieldModifier('CULTURE')==80*n)
  assert(yieldModifier('PRODUCTION')==200+100*n and L.Stats(S).income==4+12*n)
  assert(defense(watch)==50+10*n and L.Medical(S)==3*n)
  for _,key in ipairs({'ENGINEERS','SCIENTISTS','SCHOLARS'}) do assert(count(key)==0 and count('ASC_'..key)==n) end
 end
 for _,key in ipairs(L.Skills) do assert(not L.Action(0,'EXPERT',key,1));assert(S.assigned[key]==5) end
 for _,key in ipairs(L.Skills) do L.LoseExpert(S,key) end;L.Changed(S)
 assert(yieldModifier('SCIENCE')==400 and yieldModifier('CULTURE')==320 and yieldModifier('PRODUCTION')==600)
 assert(L.Stats(S).income==52 and defense(watch)==90 and L.Medical(S)==12)
 assert(not L.Action(0,'EXPERT','SCIENTISTS',1))
 for _,key in ipairs(L.Skills) do
  S.experts[key]=50
  while S.assigned[key]>0 do assert(L.Action(0,'EXPERT',key,-1)) end
 end
 assert(yieldModifier('SCIENCE')==0 and yieldModifier('CULTURE')==0 and yieldModifier('PRODUCTION')==200)
 assert(L.Stats(S).income==4 and L.Medical(S)==0 and defense(watch)==50)
end
function AscendantCases.morale_conditions_and_negative_penalties()
 developed();S.dawn='ENDURES';local watch=Players[0]:GetUnitByID(0)
 for _,r in ipairs({{80,700,100},{79.9,600,80},{59.9,595,80},{39.9,585,80},{19.9,570,80}}) do
  S.morale=r[1];L.Changed(S)
  assert(yieldModifier('PRODUCTION')==r[2] and defense(watch)==r[3])
  assert(count('UNITED')==0 and count('ASC_UNITED')==(r[1]>=80 and 1 or 0))
  assert(not promo(watch,'RESOLVE') and promo(watch,'ASC_RESOLVE')==(r[1]>=80))
 end
 -- Changing phase back reconciles both sets even with the same Morale/assignments.
 S.dawn='LOCKED';S.morale=80;L.Changed(S)
 assert(count('UNITED')==1 and count('ASC_UNITED')==0 and yieldModifier('PRODUCTION')==25)
 assert(defense(watch)==30 and promo(watch,'SANCTUARY') and not promo(watch,'ASC_SANCTUARY'))
end
function AscendantCases.infrastructure_improvements_damage_storage_and_no_free_stock()
 S.dawn='ENDURES';S.provisions=123;L.Changed(S)
 assert(S.housing==12 and S.capacity==200 and S.provisions==123 and L.Stats(S).income==4)
 local housing=12
 for _,r in ipairs({{'DISTRICT',12},{'BARRACKS',8},{'RESIDENTIAL',16},{'SHELTER',20}}) do
  L.Building(C,r[1],1);GameEvents.CityConstructed.Fire(0,C.id,GameInfoTypes['BUILDING_LC_'..r[1]])
  housing=housing+r[2];assert(S.housing==housing and S.provisions==123)
 end
 S.housingDamage=4;L.Changed(S);assert(S.housing==64)
 L.Building(C,'STORAGE',1);L.Changed(S);assert(S.capacity==350 and S.provisions==123)
 L.Building(C,'DEPOT',1);L.Changed(S);assert(S.capacity==550 and S.provisions==123)
 S.provisions=540;L.Changed(S);assert(S.provisions==540)
 plot(1,0).improvement=GameInfoTypes.IMPROVEMENT_FARM
 plot(0,1).improvement=GameInfoTypes.IMPROVEMENT_FISHING_BOATS
 plot(-1,0).improvement=GameInfoTypes.IMPROVEMENT_FARM;plot(-1,0).pillaged=true
 plot(-2,0).improvement=GameInfoTypes.IMPROVEMENT_FARM;plot(-2,0).owner=1
 plot(4,0).improvement=GameInfoTypes.IMPROVEMENT_FARM;plot(4,0).owner=0
 assert(L.Stats(S).income==12 and L.Stats(S).farms==2)
 plot(-1,0).pillaged=false;assert(L.Stats(S).income==15)
 L.Building(C,'WATER',1);assert(L.Stats(S).income==31)
 S.waterUntil=10;assert(L.Stats(S).income==28);TURN=10;assert(L.Stats(S).income==31)
 L.Building(C,'WATER',0);assert(L.Stats(S).income==15)
 S.dawn='LOCKED';L.Changed(S);assert(S.housing==36 and S.capacity==375 and S.provisions==375)
 assert(L.Stats(S).income==9)
end
function AscendantCases.final_victory_is_immediate_and_failure_or_construction_is_not_unlock()
 developed();grantTechs();Players[0].era=6;WORLD_ERA=6;S.wavesSurvived=12
 L.Building(C,'DAWN',1);GameEvents.CityConstructed.Fire(0,C.id,GameInfoTypes.BUILDING_LC_DAWN)
 assert(S.dawn=='FINAL_PENDING' and not L.IsAscendant(S) and yieldModifier('PRODUCTION')==25)
 assert(L.BeginWave(S));assert(S.dawn=='FINAL_ACTIVE' and not L.IsAscendant(S))
 TURN=S.wave.expiry;L.InvasionTurn(S)
 assert(S.dawn=='FINAL_PENDING' and not L.IsAscendant(S) and count('ENDURES')==0)
 S.pressure=nil;S.morale=80;assert(L.BeginWave(S));local w=S.wave
 for _,r in ipairs(w.units) do L.Unit(r):Kill(true,0) end
 L.InvasionTurn(S) -- production trigger reconciles without an extra manual Changed.
 assert(S.dawn=='ENDURES' and count('ENDURES')==1 and yieldModifier('PRODUCTION')==700)
 assert(S.housing==68 and S.capacity==550 and achievementCount()==1 and S.achievement)
 local sieges=S.majorSieges;L.InvasionTurn(S);assert(S.majorSieges==sieges and achievementCount()==1)
 TURN=S.nextWave;L.InvasionTurn(S);assert(S.wave and not S.wave.final and S.dawn=='ENDURES')
 defeatWave();assert(S.majorSieges>=sieges and achievementCount()==1 and L.IsAscendant(S))
 assert(not GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_SETTLER))
 assert(not GameEvents.PlayerCanFoundCity.Test(0,5,5) and Players[0]:GetNumCities()==1)
end
function AscendantCases.old_completed_and_pending_saves_reconcile_without_replaying()
 developed();S.dawn='ENDURES';S.majorSieges=12;S.achievement=true
 L.History(S,'HUMANITY_ENDURES');local watch=Players[0]:GetUnitByID(0);L.Promotion(watch,'VETERAN_4',true)
 -- Native inputs left by the previous implementation, before new SQL bonuses.
 for _,key in ipairs({'ENGINEERS','SCIENTISTS','SCHOLARS'}) do L.Building(C,key,5) end
 L.Building(C,'LEGACY',12);L.Building(C,'UNITED',1);L.Promotion(watch,'VETERAN_ACTIVE_4',true)
 S.housing=40;S.capacity=375;S.provisions=300;L.Save(0)
 local history=S.sequence;local notifications=#Players[0].notifications;local tick=S.lastTurn
 for _=1,5 do
  Events.LoadScreenClose.Fire();S=L.State(0)
  assert(S.dawn=='ENDURES' and S.provisions==300 and S.housing==68 and S.capacity==550)
  assert(S.majorSieges==12 and cityDefense()==48 and defense(watch)==124)
  assert(yieldModifier('PRODUCTION')==700 and yieldModifier('SCIENCE')==500 and yieldModifier('CULTURE')==400)
  assert(S.sequence==history and S.lastTurn==tick and achievementCount()==1 and #Players[0].notifications==notifications)
  assert(count('LEGACY')==0 and count('ASC_LEGACY')==12)
 end
 local legacy=L.Decode(L.Encode(S));legacy.version=1
 legacy=L.Migrate(legacy,0);assert(legacy.version==2 and legacy.dawn=='ENDURES' and legacy.majorSieges==12)
 L.States[0]=legacy;S=legacy;L.Changed(S)
 assert(yieldModifier('PRODUCTION')==700 and S.provisions==300 and achievementCount()==1)
 for _,phase in ipairs({'LOCKED','AWAITING_SUPPLIES','FINAL_PENDING','FINAL_ACTIVE'}) do
  S.dawn=phase;L.Save(0);Events.LoadScreenClose.Fire();S=L.State(0)
  assert(not L.IsAscendant(S) and count('ENDURES')==0 and count('ASC_ENGINEERS')==0 and count('ENGINEERS')==5)
  assert(S.provisions==300 and S.housing==40 and S.capacity==375 and defense(watch)==42)
 end
end
function AscendantCases.local_defense_movement_creation_upgrades_transfer_and_legacy_caps()
 developed();S.dawn='ENDURES';local watch=Players[0]:GetUnitByID(0)
 for _,n in ipairs({0,1,3,5}) do
  for k=1,5 do L.Promotion(watch,'VETERAN_'..k,k==n) end
  S.unitDirty=true;L.Changed(S);assert(defense(watch)==100+n*6)
  for k=1,5 do assert(not promo(watch,'VETERAN_ACTIVE_'..k) and promo(watch,'ASC_VETERAN_ACTIVE_'..k)==(k==n)) end
 end
 watch:Move(4,0);assert(defense(watch)==0 and promo(watch,'VETERAN_5') and promo(watch,'NO_CONQUEST'))
 watch:Move(3,0);assert(defense(watch)==130)
 local fresh=Players[0]:InitUnit(GameInfoTypes.UNIT_LC_LAST_WATCH,2,0,3,0);assert(defense(fresh)==100 and not promo(fresh,'VETERAN_1'))
 local upgraded=Players[0]:InitUnit(GameInfoTypes.UNIT_PIKEMAN,3,0,3,0)
 for k,v in pairs(watch.promos) do if GameInfo.UnitPromotions[k].LostWithUpgrade==0 then upgraded.promos[k]=v end end
 local old=watch.id;watch:Kill(false,-1);GameEvents.UnitUpgraded.Fire(0,old,upgraded.id,false)
 assert(defense(upgraded)==130 and promo(upgraded,'VETERAN_5'))
 -- Simulate a native capture copying promotions, then invoke owner reconciliation.
 Players[0].units[upgraded.id]=nil;upgraded.owner=1;Players[1].units[upgraded.id]=upgraded
 GameEvents.UnitConverted.Fire(0,1,old,upgraded.id,false)
 assert(defense(upgraded)==0)
 for row in GameInfo.UnitPromotions() do if row.Type:match('^PROMOTION_LC_') then assert(not upgraded:IsHasPromotion(row.ID)) end end
 Players[1].units[upgraded.id]=nil;upgraded.owner=0;Players[0].units[upgraded.id]=upgraded
 GameEvents.UnitConverted.Fire(1,0,upgraded.id,upgraded.id,false)
 assert(defense(upgraded)==100 and not promo(upgraded,'VETERAN_5'))
 -- Transfers between two Ascendant sanctuaries also erase earned history.
 Players[1].civ=GameInfoTypes.CIVILIZATION_LAST_CITY;Players[1].cities[0]=newCity(1,0,20,0)
 L.Players[#L.Players+1]=1;local other=L.Initialize(1);other.dawn='ENDURES';other.morale=80
 other.experts.VETERANS=5;other.assigned.VETERANS=5;L.Changed(other)
 L.Promotion(upgraded,'WATCH',true);L.Promotion(upgraded,'VETERAN_5',true);L.RefreshUnit(S,upgraded)
 Players[0].units[upgraded.id]=nil;upgraded.owner=1;upgraded.x=21;Players[1].units[upgraded.id]=upgraded
 GameEvents.UnitConverted.Fire(0,1,upgraded.id,upgraded.id,false)
 assert(defense(upgraded)==100 and not promo(upgraded,'VETERAN_5') and not promo(upgraded,'ASC_VETERAN_ACTIVE_5'))
 for _,n in ipairs({0,1,3,15,16,999}) do
  S.majorSieges=n;L.Changed(S);assert(cityDefense()==math.min(60,4*n) and L.LegacyDefense(S)==math.min(60,4*n))
  assert(count('LEGACY')==0 and count('ASC_LEGACY')==math.min(15,n))
 end
 local siege=S.majorSieges;S.waveNumber=4;assert(L.BeginWave(S));defeatWave();L.InvasionTurn(S)
 assert(S.majorSieges==siege+1 and cityDefense()==60 and promo(fresh,'VETERAN_1'))
end
function AscendantCases.generous_fractional_growth_exactly_once_and_other_rations_unchanged()
 developed();S.dawn='ENDURES';S.ration='GENEROUS';C.surplus=1.25;S.foodRemainder=0;C.food=30;L.Changed(S)
 local food=C.food
 for _=1,8 do advance(1);local after=C.food;GameEvents.PlayerDoTurn.Fire(0);L.Changed(S);assert(C.food==after) end
 assert(C.food==food+5 and S.foodRemainder==0)
 for _,r in ipairs({{'STANDARD',0},{'STRICT',-15},{'EMERGENCY',-35}}) do assert(L.RationGrowth(S,r[1])==r[2]) end
 C.surplus=-1;food=C.food;advance(4);assert(C.food==food)
 S.starvation=2;assert(L.GrowthAdjustment(S,'GENEROUS')==30)
 S.provisions=0;assert(L.GrowthAdjustment(S,'GENEROUS')==-10)
 S.dawn='LOCKED';assert(L.GrowthAdjustment(S,'GENEROUS')==-45)
end
function AscendantCases.medical_bounded_probability_cost_duration_and_crises_remain_real()
 developed();S.dawn='ENDURES';L.Changed(S);C.population=10
 assert(L.Medical(S)==17 and L.CrisisWeight(S,'OUTBREAK')>=1)
 local random=L.Rand;L.Rand=function(_,n) return 1 end
 assert(L.Infect(S,7,4),'Even maximum medical protection must allow disease')
 assert(S.infection.severity==1 and S.infection.untilTurn-TURN==L.Scale(2))
 local morale=S.morale;L.InfectionTurn(S);assert(S.morale<morale and L.Stats(S).infection==0)
 assert(not L.Infect(S,7,4),'Infection cannot stack')
 -- Maximum protection preserves the 4% caravan complication floor.
 S.experts.PHYSICIANS=50;L.NewRefugee(S);local r=S.refugee;r.skill='PHYSICIANS';r.risk='DISEASE';r.riskRoll=4
 local cases=S.medicalCases;local stock=S.provisions;local cost=r.cost
 assert(L.ResolveRefugee(S,r.id,'ACCEPT') and S.medicalCases==cases+1)
 assert(S.experts.PHYSICIANS==50 and S.assigned.PHYSICIANS==5 and S.provisions==stock-cost-L.Scale(2))
 L.NewRefugee(S);r=S.refugee;r.skill='PHYSICIANS';r.risk='DISEASE';r.riskRoll=2;S.provisions=500
 assert(L.ResolveRefugee(S,r.id,'QUARANTINE'));assert(not L.ResolveRefugee(S,r.id,'ACCEPT'))
 TURN=r.due;L.RefugeeTurn(S);cases=S.medicalCases
 assert(L.ResolveRefugee(S,r.id,'ACCEPT') and S.medicalCases==cases+1,'Quarantined disease retains a bounded 2% floor')
 assert(S.experts.PHYSICIANS==50 and S.assigned.PHYSICIANS==5)
 S.crisis={id=200,key='OUTBREAK'};assert(L.CrisisCost(S,1)==L.Scale(6))
 S.infection.severity=4;morale=S.morale;assert(L.ResolveCrisis(S,200,3));assert(S.morale==morale-3 and S.medicalCases>0)
 S.infection=nil;S.infectionNext=0
 S.assigned.PHYSICIANS=0;L.Building(C,'HOSPITAL',0);assert(L.Infect(S,7,4) and S.infection.severity==4)
 assert(S.infection.untilTurn-TURN<=L.Scale(8) and L.Stats(S).infection==4)
 local population=C.population;L.InfectionTurn(S);assert(C.population==population-1,'An unprotected severe infection still threatens Population')
 S.assigned.PHYSICIANS=5;L.Building(C,'HOSPITAL',1)
 for _,key in ipairs(L.Crises) do for choice=1,3 do
  C.population=20;C.production=100;S.provisions=500;S.morale=65;S.experts.ENGINEERS=5;S.assigned.ENGINEERS=5
  S.crisis={id=300,key=key,expert='ENGINEERS',expiry=999};assert(L.CrisisCheck(S,300,choice),key)
  assert(L.ResolveCrisis(S,300,choice),key);assert(not L.ResolveCrisis(S,300,choice))
  assert(S.provisions>=0 and S.provisions<=550 and C.population>=1 and S.morale>=0 and S.morale<=100)
 end end
 -- Improved medical care never eliminates starvation's bounded mortality floor.
 S.assigned.PHYSICIANS=5;S.assigned.FARMERS=0;L.Building(C,'WATER',0)
 C.population=100;S.provisions=0;S.starvation=L.Scale(5);L.EconomyTurn(S)
 assert(C.population==99 and S.provisions==0 and S.starvation==L.Scale(5)+1)
 L.Rand=random
end
function AscendantCases.endless_survival_normal_island_and_crowded_22_player_maps()
 developed();S.dawn='ENDURES';L.Changed(S)
 assert(L.BeginWave(S));assert(not S.wave.final);defeatWave();assert(S.dawn=='ENDURES')
 L.Near(0,0,16,function(p) if dist(0,0,p.x,p.y)>1 then p.water=true end end)
 PLOT_VISITS=0;assert(L.BeginWave(S) and S.wave.naval and PLOT_VISITS<500)
 defeatWave();assert(S.dawn=='ENDURES' and Players[0]:GetNumCities()==1)
 L.Near(0,0,16,function(p) p.water=false;if dist(0,0,p.x,p.y)>3 then p.owner=1 end end)
 PLOT_VISITS=0;assert(L.BeginWave(S) and S.wave.ambush and PLOT_VISITS<6000)
 defeatWave();local wins=S.wavesSurvived
 L.Near(0,0,16,function(p) if not p:IsCity() then p.owner=1 end end)
 assert(not L.BeginWave(S) and S.pressure and S.dawn=='ENDURES' and S.wavesSurvived==wins)
 S.nextRefugee=TURN;L.RefugeeTurn(S);assert(S.refugee)
 S.refugee=nil;S.nextCrisis=TURN;L.CrisisTurn(S);assert(S.crisis)
 assert(not GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_SETTLER))
 assert(GameEvents.PlayerCanTrain.Test(1,GameInfoTypes.UNIT_SETTLER) and GameEvents.PlayerCanFoundCity.Test(1,5,5))
end
function AscendantSpeeds()
 developed();S.dawn='ENDURES';S.majorSieges=15;L.Changed(S)
 assert(yieldModifier('PRODUCTION')==700 and yieldModifier('SCIENCE')==500 and yieldModifier('CULTURE')==400)
 assert(L.Stats(S).income==82 and S.housing==68 and S.capacity==550 and L.Medical(S)==17)
 assert(cityDefense()==60 and defense(Players[0]:GetUnitByID(0))==100)
 S.ration='GENEROUS';C.surplus=1.25;C.food=30;S.foodRemainder=0;advance(8);assert(C.food==35)
 assert(L.SetRation(S,'STRICT') and S.rationNext==TURN+L.Scale(L.Config.PolicyCooldown))
 assert(not L.SetRation(S,'GENEROUS'))
 assert(L.BeginWave(S));assert(S.wave.expiry==TURN+L.Scale(18) and not S.wave.final)
 defeatWave();assert(S.nextWave>=TURN+L.Scale(20) and S.nextWave<=TURN+L.Scale(24))
 S.nextRefugee=TURN;L.RefugeeTurn(S);assert(S.refugee and S.refugee.expiry==TURN+L.Scale(L.Config.RefugeeExpiry))
end
