-- Each case runs in a fresh runtime against the actual activated CP database.
RegressionCases={}
function RegressionCases.settler_veto_does_not_depend_on_capital_initialization()
 S.capital=nil
 assert(not GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_SETTLER))
 assert(GameEvents.PlayerCanTrain.Test(1,GameInfoTypes.UNIT_SETTLER))
 Players[0].cities={}
 assert(GameEvents.PlayerCanFoundCity.Test(0,0,0),'The starting Settler can still found Last Light')
 assert(not GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_SETTLER))
 Players[0].cities[0]=C;GameEvents.PlayerCityFounded.Fire(0)
 assert(S.capital and not GameEvents.PlayerCanFoundCity.Test(0,3,3))
 assert(not GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_SETTLER))
end
function RegressionCases.granted_dawn_cannot_bypass_era_or_technology()
 L.Building(C,'DISTRICT',1);L.Building(C,'DAWN',1);S.wavesSurvived=12;S.morale=65;S.provisions=200
 GameEvents.CityConstructed.Fire(0,C.id,GameInfoTypes.BUILDING_LC_DAWN,false,false)
 assert(S.dawn=='AWAITING_SUPPLIES' and S.provisions==200)
 Players[0].era=6;advance(1);assert(S.dawn=='AWAITING_SUPPLIES' and S.provisions==200)
 Teams[0].techs[GameInfoTypes.TECH_ATOMIC_THEORY]=true;advance(1)
 assert(S.dawn=='FINAL_PENDING' and S.provisions==55)
end
function RegressionCases.upgrade_tags_require_exact_boundaries()
 S.waveNumber=4;assert(L.BeginWave(S));local watch=Players[0]:GetUnitByID(0)
 S.nextUnit=10;local upgraded=Players[0]:InitUnit(GameInfoTypes.UNIT_PIKEMAN,1,0,3,0)
 for k,v in pairs(watch.promos) do upgraded.promos[k]=v end
 watch:Kill(false,-1);GameEvents.UnitUpgraded.Fire(0,0,upgraded.id,false)
 local record=S.wave.participants[tostring(upgraded.id)]
 assert(L.Unit(record)==upgraded,'LCDEF_0_10 must not suppress the distinct LCDEF_0_1 tag')
 upgraded:Move(5,0);defeatWave()
 assert(upgraded:IsHasPromotion(GameInfoTypes.PROMOTION_LC_VETERAN_1),'Recorded participants remain eligible after leaving the local radius')
end
function RegressionCases.collapse_requires_sustained_military_failure()
 Players[0]:GetUnitByID(0):Kill(false,-1);assert(L.BeginWave(S))
 local a=L.Unit(S.wave.units[1]);local b=L.Unit(S.wave.units[2]);a:Move(-1,0);b:Move(0,-1)
 C.damage=180;TURN=1;L.InvasionTurn(S);assert(S.collapse==1 and not S.fallen)
 L.InvasionTurn(S);assert(S.collapse==1,'A second callback must not advance collapse')
 local g=Players[0]:InitUnit(GameInfoTypes.UNIT_WARRIOR,2,0,3,0)
 TURN=2;L.InvasionTurn(S);assert(S.collapse==0);g:Kill(false,-1)
 b:Move(5,0);TURN=3;L.InvasionTurn(S);assert(S.collapse==0,'One raider cannot destroy the sanctuary')
 b:Move(0,-1);TURN=4;L.InvasionTurn(S);C.damage=100;TURN=5;L.InvasionTurn(S);assert(S.collapse==0)
 C.damage=180;TURN=6;L.InvasionTurn(S);L.Save(0)
 L.States={};S=L.State(0);assert(S.collapse==1 and not S.fallen)
 TURN=7;L.InvasionTurn(S);assert(not S.fallen)
 TURN=8;L.InvasionTurn(S);assert(S.fallen and C.killed and not S.wave and Players[0]:GetNumCities()==0)
 assert(next(Players[0].units)==nil and S.wavesSurvived==0)
 assert(not L.Action(0,'RATION','STRICT'))
 -- Native testAlive will mark this empty player dead; the mock deliberately
 -- does not pretend that the real defeat screen has been exercised.
 L.Save(0);L.States={};S=L.State(0);assert(S.fallen)
end
function RegressionCases.expanded_crowded_map_and_blockade_retry()
 L.Near(0,0,8,function(p) if dist(0,0,p.x,p.y)>=4 then p.owner=1 end end)
 -- A corridor through our own territory reaches neutral plots outside radius8.
 for x=4,9 do plot(x,0).owner=0 end
 PLOT_VISITS=0;assert(L.BeginWave(S));assert(PLOT_VISITS<1500)
 local expanded=false
 for _,r in ipairs(S.wave.units) do local u=L.Unit(r)
  assert(plot(u.x,u.y).owner==-1);if dist(0,0,u.x,u.y)>8 then expanded=true end
 end
 assert(expanded);defeatWave();local wins=S.wavesSurvived;local number=S.waveNumber
 L.Near(0,0,16,function(p) if not p:IsCity() then p.owner=1 end end)
 assert(not L.BeginWave(S) and S.pressure and not S.wave)
 S.provisions=100;local morale=S.morale;TURN=1;L.Turn(0);local after=S.provisions
 L.InvasionTurn(S);assert(S.provisions==after and after<100 and S.morale<morale)
 L.Save(0);L.States={};S=L.State(0);assert(S.pressure)
 TURN=S.pressure.expiry;L.InvasionTurn(S);assert(not S.pressure and S.nextWave>TURN)
 assert(S.wavesSurvived==wins and S.waveNumber==number)
 TURN=S.nextWave;L.InvasionTurn(S);assert(S.pressure,'Blocked waves must keep retrying')
end
function RegressionCases.impassable_routes_and_partial_final_are_not_success()
 for dir=0,5 do local p=Map.PlotDirection(0,0,dir);p.mountain=true end
 local land,sea=L.SpawnPlots(S,16);assert(#land==0 and #sea==0)
 S.dawn='FINAL_PENDING';assert(not L.BeginWave(S) and S.pressure and not S.achievement)
 S.pressure=nil
 for dir=0,5 do Map.PlotDirection(0,0,dir).mountain=false end
 local count=0;local init=Players[63].InitUnit
 Players[63].InitUnit=function(self,...) count=count+1;if count>1 then return nil end;return init(self,...) end
 assert(L.BeginWave(S) and S.wave.final and not S.wave.finalEligible)
 defeatWave();assert(S.dawn=='FINAL_PENDING' and not S.achievement)
 count=0;assert(L.BeginWave(S));S.wave.finalEligible=nil -- original schema-1 wave
 defeatWave();assert(S.dawn=='FINAL_PENDING' and not S.achievement,'Undersized legacy Final Night must also retry')
end
function RegressionCases.crowded_22_player_borders_use_owned_outskirts()
 L.Near(0,0,16,function(p) if dist(0,0,p.x,p.y)>3 then p.owner=1 end end)
 local land,sea=L.SpawnPlots(S,16);assert(#land==0 and #sea==0)
 assert(L.BeginWave(S) and S.wave.ambush and S.wave.spawned<=3)
 for _,r in ipairs(S.wave.units) do local u=L.Unit(r)
  assert(plot(u.x,u.y).owner==0 and dist(0,0,u.x,u.y)>=3)
 end
 defeatWave();assert(S.wavesSurvived==1)
end
function RegressionCases.plague_resistance_duration_caps_and_treatment()
 local rand=L.Rand;L.Rand=function() return 1 end
 S.assigned.PHYSICIANS=0;assert(L.Infect(S,7,3));local severity=S.infection.severity;local expiry=S.infection.untilTurn
 assert(severity==4 and expiry<=L.Scale(8));assert(not L.Infect(S,7,3) and S.infection.untilTurn==expiry)
 local unprotected=L.Stats(S).consumption
 L.Save(0);L.States={};S=L.State(0);assert(S.infection.severity==severity)
 S.experts.PHYSICIANS=5;S.assigned.PHYSICIANS=5;L.Building(C,'HOSPITAL',1)
 assert(L.Stats(S).consumption<unprotected)
 TURN=1;L.InfectionTurn(S);local morale=S.morale;local treated=S.infection.untilTurn
 L.InfectionTurn(S);assert(S.morale==morale and S.infection.untilTurn==treated)
 TURN=treated;L.InfectionTurn(S);assert(not S.infection and not L.Infect(S,7,3))
 TURN=S.infectionNext;assert(L.Infect(S,7,3) and S.infection.severity<severity)
 S.crisis={id=900,key='OUTBREAK'};S.provisions=100;assert(L.ResolveCrisis(S,900,1) and not S.infection)
 -- Identical rolls: a medic reduces probability, not just supply drain.
 S.infectionNext=0;S.assigned.PHYSICIANS=0;L.Building(C,'HOSPITAL',0)
 L.Rand=function() return 30 end;assert(L.Infect(S,3,2));S.infection=nil
 S.assigned.PHYSICIANS=5;assert(not L.Infect(S,3,2));L.Rand=rand
end
function RegressionCases.plague_exposure_is_local_and_once_per_turn()
 Players[0].era=3;grantTechs();assert(L.BeginWave(S));local u=L.Unit(S.wave.units[1])
 local rand=L.Rand;local rolls=0;L.Rand=function() rolls=rolls+1;return 1 end
 TURN=1;L.SiegeExposure(S);assert(not S.infection and rolls==0)
 u:Move(-1,0);TURN=2;L.SiegeExposure(S);assert(S.infection and rolls==1)
 local untilTurn=S.infection.untilTurn;L.SiegeExposure(S);assert(rolls==1 and S.infection.untilTurn==untilTurn);L.Rand=rand
end
function RegressionCases.orphan_cities_capitals_and_city_states()
 Players[1].human=false;Players[2].alive=false
 local c=newCity(0,3,12,0);c.previous=2;c.original=2;Players[0].cities[3]=c
 L.ReturnExtraCities(S);assert(c.owner==1 and not S.fallen and Players[0]:GetNumCities()==1)
 Players[22]=newPlayer(22,GameInfoTypes.CIVILIZATION_AMERICA,false)
 local minor=newCity(0,4,20,0);minor.previous=2;minor.original=2;Players[0].cities[4]=minor
 L.ReturnExtraCities(S);assert(minor.owner==22 and not Players[2].alive)
 Players[22].alive=false;Players[1].alive=false
 local last=newCity(0,5,25,0);last.previous=2;last.original=2;Players[0].cities[5]=last
 L.ReturnExtraCities(S);assert(last.killed and not C.killed and Players[0]:GetNumCities()==1)
 local identity=L.Encode(S.capital);L.Save(0);L.States={};S=L.State(0);assert(L.Encode(S.capital)==identity and L.City(S)==C)
end
function RegressionCases.distinct_games_earlier_saves_and_missing_banks()
 L.Building(C,'DISTRICT',1);L.ApplyEffects(S)
 L.NewRefugee(S);S.provisions=100;assert(L.ResolveRefugee(S,S.refugee.id,'QUARANTINE'));assert(L.BeginWave(S));L.Save(0)
 local earlier=L.Encode(S);local slot={};for k,v in pairs(SAVE_DATA) do slot[k]=v end;local marker=Players[0].data
 TURN=1;L.Turn(0);L.Save(0);local later=S.provisions
 SAVE_DATA=slot;Players[0].data=marker;TURN=0;L.States={};S=L.State(0)
 assert(S.provisions==L.Decode(earlier).provisions and S.refugee.status=='QUARANTINE' and S.wave)
 SAVE_DATA={};L.States={};S=L.State(0);assert(S.incompatible,'Missing banks must not mint starting rewards')
 -- A fresh game's separate native save database and empty script data.
 Players[0].data='';L.States={};S=L.State(0);assert(not S.incompatible and not S.capital and S.provisions==45)
 -- Cross-game/native-bank mismatch fails closed even if a backend is stale.
 SAVE_DATA=slot;Players[0].data='|LCSTATE2_0_123|';L.States={};S=L.State(0);assert(S.incompatible)
 Players[0].data='';L.States={};S=L.State(0);assert(S.incompatible,'Schema2 banks require their native save marker')
end
function RegressionCases.matching_backup_and_legacy_schema_migration()
 L.NewRefugee(S);L.Save(0);local active=SAVE_DATA.LASTCITY_P0_active;local backup=active=='A' and 'B' or 'A'
 local copies={}
 for key,value in pairs(SAVE_DATA) do if key:find('LASTCITY_P0_'..active..'_',1,true)==1 then
  copies[key:gsub('LASTCITY_P0_'..active..'_','LASTCITY_P0_'..backup..'_')]=value
 end end
 for key,value in pairs(copies) do SAVE_DATA[key]=value end
 SAVE_DATA['LASTCITY_P0_'..active..'_sum']=-1;L.States={};S=L.State(0);assert(not S.incompatible and S.refugee)
 S.version=1;S.collapse=nil;local legacy=L.Decode(L.Encode(S));local migrated=L.Migrate(legacy,0)
 assert(migrated.version==2 and migrated.collapse==0 and migrated.refugee.id==S.refugee.id and migrated.provisions==S.provisions)
end
function RegressionCases.same_context_reload_reopens_state_without_reticking()
 Modding.OpenSaveData=function()
  local scope=SAVE_DATA
  return {GetValue=function(k) return scope[k] end,SetValue=function(k,v) scope[k]=v end}
 end
 L.ReloadPersistence();S=L.State(0)
 S.provisions=99;S.lastTurn=0;L.Save(0)
 local slot={};for k,v in pairs(SAVE_DATA) do slot[k]=v end;local marker=Players[0].data
 S.provisions=14;TURN=1;S.lastTurn=1;L.Save(0)
 SAVE_DATA=slot;Players[0].data=marker;TURN=0
 Events.LoadScreenClose.Fire();S=L.State(0);assert(S.provisions==99 and S.lastTurn==0)
 assert(#GameEvents.PlayerDoTurn.handlers==1);L.Turn(0);assert(S.provisions==99)
 -- Reused context, fresh independent game with a different Warden slot/speed.
 SAVE_DATA={};Players[0].civ=GameInfoTypes.CIVILIZATION_AMERICA;Players[0].data=''
 Players[3].civ=GameInfoTypes.CIVILIZATION_LAST_CITY;Players[3].cities[0]=newCity(3,0,30,0)
 ACTIVE=3;GameInfo.GameSpeeds[0].GrowthPercent=300
 Events.LoadScreenClose.Fire();assert(#L.Players==1 and L.Players[1]==3 and L.Speed==3)
 local fresh=L.State(3);assert(fresh.provisions==45 and fresh.pid==3 and fresh.capital.x==30)
end
function RegressionCases.conversion_never_counts_as_combat_or_duplicate_veterans()
 S.waveNumber=4;assert(L.BeginWave(S));local r=S.wave.units[1];local u=L.Unit(r)
 -- Simulate a capture path that reports attributed prekill before conversion.
 GameEvents.UnitPrekill.Fire(r.owner,r.id,u.kind,u.x,u.y,true,0);assert(S.wave.defeated==1)
 local converted=Players[0]:InitUnit(u.kind,2,0,3,0)
 GameEvents.UnitConverted.Fire(r.owner,0,r.id,converted.id,false)
 assert(S.wave.defeated==0 and r.invalid)
 u:Kill(false,-1)
 for i=2,#S.wave.units do local enemy=L.Unit(S.wave.units[i]);enemy:Kill(true,0) end
 L.InvasionTurn(S);assert(S.wavesSurvived==0 and not S.achievement and S.bosses==0)
 S.waveNumber=9;assert(L.BeginWave(S));local watch=Players[0]:GetUnitByID(0)
 L.Promotion(watch,'VETERAN_3',true)
 local foreign=Players[1]:InitUnit(watch.kind,2,0,3,0);for k,v in pairs(watch.promos) do foreign.promos[k]=v end
 GameEvents.UnitConverted.Fire(0,1,watch.id,foreign.id,false)
 assert(S.wave.participants['0'].invalid and not foreign:IsHasPromotion(GameInfoTypes.PROMOTION_LC_VETERAN_3))
 watch:Kill(false,-1);defeatWave()
 assert(not foreign:IsHasPromotion(GameInfoTypes.PROMOTION_LC_VETERAN_1))
end
function RegressionCases.hostile_major_peace_and_defeat_cleanup()
 Players[1].human=false;Players[0].wars[1]=true;assert(L.BeginWave(S));assert(S.wave.owner==1)
 Players[0].wars[1]=false;L.InvasionTurn(S);assert(not S.wave and S.pressure and S.wavesSurvived==0 and next(Players[1].units)==nil)
 S.pressure=nil;Players[0].wars[1]=true;assert(L.BeginWave(S));local w=S.wave
 Players[1]:AcquireCity(C,true,false)
 assert(S.fallen and not C.killed,'Conquest callback must never delete the captured city')
 GameEvents.PlayerDoTurn.Fire(1);assert(not S.wave and next(Players[0].units)==nil and C.owner==1 and not C.killed)
end
function RegressionCases.economy_projection_repair_housing_and_fractional_food()
 C.population=10;S.assigned.FARMERS=2;L.Building(C,'DISTRICT',1)
 plot(1,0).improvement=GameInfoTypes.IMPROVEMENT_FARM
 local income=L.Stats(S).income;plot(1,0).pillaged=true;assert(L.Stats(S).income==income-1)
 plot(1,0).pillaged=false;assert(L.Stats(S).income==income)
 L.Building(C,'RESIDENTIAL',1);L.Building(C,'STORAGE',1);local stats=L.Stats(S);assert(stats.housing==26 and stats.capacity==275)
 L.Building(C,'RESIDENTIAL',0);assert(L.Stats(S).housing==18)
 S.housingDamage=4;S.crisis={id=301,key='REBUILD'};S.provisions=100;L.ResolveCrisis(S,301,1);assert(L.Stats(S).housing==18)
 S.ration='STRICT';S.provisions=200;C.food=0;C.surplus=2.75;L.EconomyTurn(S);assert(C.food==0 and S.foodRemainder>-.5)
 S.foodRemainder=0;C.food=30
 for i=1,8 do TURN=i;L.EconomyTurn(S) end
 assert(C.food==27 and math.abs(S.foodRemainder+.3)<.000001)
 C.surplus=-3;local food=C.food;S.ration='GENEROUS';S.foodRemainder=0;L.EconomyTurn(S);assert(C.food==food)
 local military=L.Military(0);local bomber=Players[0]:InitUnit(GameInfoTypes.UNIT_BOMBER,0,0,3,0)
 assert(not bomber:IsCombatUnit() and L.Military(0)==military+1)
 local losses=S.losses;bomber:Kill(true,1);assert(S.losses==losses+1 and L.Military(0)==military)
end
function RegressionCases.refugee_bag_expiration_positive_quarantine_and_ash()
 local seen={};S.provisions=200;L.Building(C,'DISTRICT',1)
 for i=1,#L.Caravans do L.NewRefugee(S);assert(not seen[S.refugee.key]);seen[S.refugee.key]=true;S.refugee=nil end
 L.NewRefugee(S);TURN=S.refugee.expiry+1;local population=C.population
 assert(not L.ResolveRefugee(S,S.refugee.id,'ACCEPT') and C.population==population)
 TURN=0;S.refugee={id=700,key='MERCY',skill='PHYSICIANS',risk='MEDICAL',riskRoll=20,population=1,cost=6,paid=3,quarantined=true,expiry=10,status='CLEARED'}
 S.experts.PHYSICIANS=5;S.assigned.PHYSICIANS=5;local before=S.experts.PHYSICIANS
 assert(L.ResolveRefugee(S,700,'ACCEPT') and S.experts.PHYSICIANS==before+2,'Quarantine must not suppress positive expertise awards')
 S.survivors.ASH=1;S.crisis={id=701,key='GATES'};local provisions,production=L.CrisisCost(S,1)
 assert(provisions==L.Scale(10) and production==L.ProductionScale(20))
end
function RegressionCases.ai_queue_stability_and_dawn_priority()
 Players[0].human=false;grantTechs();L.Building(C,'DISTRICT',1)
 S.experts.FARMERS=5;C.population=20;S.provisions=20;S.nextWave=TURN+L.Scale(3)
 C.productionBuilding=GameInfoTypes.BUILDING_LC_RESIDENTIAL
 L.AITurn(S);assert(S.assigned.FARMERS==5 and C.productionBuilding==GameInfoTypes.BUILDING_LC_RESIDENTIAL)
 C.productionBuilding=-1;C.population=10;Players[0].era=6;S.wavesSurvived=12;S.morale=65;S.provisions=180;S.nextWave=999
 L.AITurn(S);assert(C.productionBuilding==GameInfoTypes.BUILDING_LC_DAWN)
 for _=1,5 do L.AITurn(S);assert(C.productionBuilding==GameInfoTypes.BUILDING_LC_DAWN) end
end
function RegressionCases.cosmetic_actions_do_not_refresh_every_unit_or_save_twice()
 local refresh=L.RefreshUnits;local calls=0;L.RefreshUnits=function(s) calls=calls+1;return refresh(s) end
 L.Changed(S);L.Save(0);local active=SAVE_DATA.LASTCITY_P0_active
 L.Save(0);assert(SAVE_DATA.LASTCITY_P0_active==active,'Identical snapshots should not switch banks')
 L.Action(0,'RATION','STRICT');assert(calls==0)
 S.experts.ENGINEERS=1;L.Action(0,'EXPERT','ENGINEERS',1);assert(calls==0)
 S.experts.VETERANS=1;L.Action(0,'EXPERT','VETERANS',1);assert(calls==1)
end
function RegressionCases.boss_rewards_survive_reload_and_clear_aura_once()
 S.waveNumber=4;assert(L.BeginWave(S));local w=S.wave;local boss=L.Unit(w.units[1]);local ally=L.Unit(w.units[2])
 ally:Move(boss.x+1,boss.y);L.UpdateBossAura(S);assert(ally:IsHasPromotion(GameInfoTypes.PROMOTION_LC_COMMAND))
 local morale=S.morale;boss:Kill(true,0)
 assert(not ally:IsHasPromotion(GameInfoTypes.PROMOTION_LC_COMMAND))
 L.InvasionTurn(S);assert(S.morale==morale+6 and S.bosses==1)
 L.InvasionTurn(S);assert(S.morale==morale+6)
 L.Save(0);L.States={};S=L.State(0);L.InvasionTurn(S);assert(S.bosses==1 and S.morale==morale+6)
 defeatWave();assert(S.bosses==1 and S.majorSieges==1)
end
