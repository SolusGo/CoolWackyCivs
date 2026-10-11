-- Source-ordered combat: CvUnit::setDamage -> UnitPrekill can precede the
-- attacker's damage; BattleFinished follows all damage and movement spending.
local M,T=MapModData.CR7,GameInfoTypes
local c=NewCity(0,1,0,0,1)
local function combat(a,d,attackerDamage,defenderDamage,kind)
    GameEvents.BattleStarted(kind or 0,d.x,d.y)
    GameEvents.CombatResult(a.owner,a.id,attackerDamage,a.damage+attackerDamage,100,
        d.owner,d.id,defenderDamage,d.damage+defenderDamage,100,-1,-1,0,d.x,d.y)
    d.damage=math.min(100,d.damage+defenderDamage)
    if d:IsDead() then GameEvents.UnitPrekill(d.owner,d.id,d.typ,d.x,d.y,true,a.owner) end
    a.damage=math.min(100,a.damage+attackerDamage)
    if a:IsDead() then GameEvents.UnitPrekill(a.owner,a.id,a.typ,a.x,a.y,true,d.owner) end
    a.moves=math.max(0,a.moves-60)
    GameEvents.BattleFinished()
    if d:IsDead() then Players[d.owner].units[d.id]=nil end
    if a:IsDead() then Players[a.owner].units[a.id]=nil end
end
local f=NewUnit(0,1,'UNIT_CR7_COMPLETE_FORWARD');f.moves=120
combat(f,NewUnit(1,1,'UNIT_CR7_COMPLETE_FORWARD',2,0),20,100)
Equal(f.damage,12,'Finisher heals AFTER incoming combat damage')
Equal(f.moves,120,'refund follows native movement cost');Equal(f.attacks,1)
combat(f,NewUnit(1,2,'UNIT_CR7_COMPLETE_FORWARD',2,0),0,100)
Equal(f.damage,4);Equal(f.moves,60,'second kill pays cost without another refund')
CurrentTurn=1;f.damage=0;f.moves=60
combat(NewUnit(1,3,'UNIT_CR7_COMPLETE_FORWARD',2,0),f,100,20)
Equal(f.damage,12,'defender victory heals once');Equal(f.moves,120)
local before=Ambition()
local doomed=NewUnit(0,2,'UNIT_CR7_COMPLETE_FORWARD');doomed.moves=60
combat(doomed,NewUnit(1,4,'UNIT_CR7_COMPLETE_FORWARD',2,0),100,100)
assert(doomed:IsDead());Equal(Ambition(),before,'mutual death cannot resurrect or unlock a chapter')
-- Real upgrades of free/spawned Forwards also retain the reduced promotion.
f=Upgrade(f,3,'UNIT_WWI_TANK')
assert(Has(f,'FINISHER_VETERAN') and not Has(f,'FINISHER') and not Has(f,'FORWARD_MOBILITY'))
local source=f;local ranged=Upgrade(f,4,'UNIT_ARCHER')
assert(Has(ranged,'FINISHER_VETERAN') and Has(ranged,'REINVENTION_2'))
-- Replay BOTH upgrade callbacks while the delayed-death source still exists.
Players[0].units[source.id]=source
GameEvents.UnitUpgraded(0,source.id,ranged.id,false)
GameEvents.UnitConverted(0,0,source.id,ranged.id,true)
assert(Has(ranged,'REINVENTION_2') and not Has(ranged,'REINVENTION_3'))
Players[0].units[source.id]=nil
ranged.damage=3;CurrentTurn=2
combat(ranged,NewUnit(1,5,'UNIT_ARCHER',2,0),0,100,1)
Equal(ranged.damage,0,'ranged Reinvention plus veteran healing clamps at full HP')
Equal(ranged.moves,0,'veteran Finisher has no movement refund');Equal(ranged.attacks,1)
-- A stale delayed reward cannot attach to a reused unit ID.
local enemy=NewUnit(1,6,'UNIT_ARCHER',2,0)
GameEvents.BattleStarted(1,2,0)
GameEvents.CombatResult(0,4,0,0,100,1,6,100,100,100,-1,-1,0,2,0)
GameEvents.UnitPrekill(1,6,enemy.typ,2,0,true,0)
local replacement=NewUnit(0,4,'UNIT_ARCHER');replacement.damage=50
GameEvents.BattleFinished();Equal(replacement.damage,50,'queued reward validates lineage')
-- Orphaned upgrade callbacks cannot leave entitlements for a later pair of reused IDs.
NewUnit(0,80,'UNIT_WARRIOR');NewUnit(0,81,'UNIT_INFANTRY')
GameEvents.UnitUpgraded(0,80,81,false)
Players[0].units[80]=nil;Players[0].units[81]=nil
NewUnit(0,81,'UNIT_INFANTRY')
assert(Saved['CR7|v1|0|PendingUpgrade|81']==nil,'fresh creation clears pending upgrade')
GameEvents.UnitUpgraded(0,80,81,false)
assert(Saved['CR7|v1|0|PendingUpgrade|81']==nil,'missing source cannot authorize an upgrade')
NewUnit(0,80,'UNIT_WARRIOR')
GameEvents.UnitConverted(0,0,80,81,true)
assert(not Has(Players[0].units[81],'REINVENTION_1'),'reused IDs cannot claim an orphaned upgrade')
Players[0].units[80]=nil;Players[0].units[81]=nil
-- General counter excludes unrelated changes and restores auras at birth.
Players[0].era=5;M.AddAmbition(0,165,'test',false)
replacement.level=4;replacement.x=0;replacement.y=0
local admin=NewUnit(0,5,'UNIT_GREAT_GENERAL');before=Ambition()
assert(Has(replacement,'CAPTAIN'),'new General immediately supplies aura')
Players[0].generalThreshold=Players[0].generalThreshold+100
M.OnTurn(0);Equal(Ambition(),before,'threshold-only General edit is not a birth')
local g=NewUnit(0,6,'UNIT_GREAT_GENERAL');Players[0].generalsCreated=1
GameEvents.UnitPrekill(0,g.id,g.typ,0,0,true,-1)
Equal(Ambition(),before+3,'own birth counter recognizes immediate expenditure')
Players[0].units[g.id]=nil
-- Small edits and normal teammate threshold increments cannot manufacture Admirals.
admin=NewUnit(0,7,'UNIT_GREAT_ADMIRAL');before=Ambition()
Players[0].admiralThreshold=50;M.OnTurn(0);Equal(Ambition(),before,'team-only Admiral rise excluded')
admin=NewUnit(0,8,'UNIT_GREAT_ADMIRAL');Players[0].admiralThreshold=51
M.OnTurn(0);Equal(Ambition(),before,'irregular Admiral rise excluded')
local admiral=NewUnit(0,9,'UNIT_GREAT_ADMIRAL');Players[0].admiralThreshold=151
GameEvents.UnitPrekill(0,9,admiral.typ,0,0,true,-1);Equal(Ambition(),before+3)
GameEvents.UnitPrekill(0,9,admiral.typ,0,0,false,-1);Equal(Ambition(),before+3)
Players[0].units[9]=nil
-- Conversion and ownership transfer of a GP do not increment its owner's
-- native birth counter and cannot adopt the destination's pending birth.
before=Ambition();local foreign=NewUnit(1,20,'UNIT_GREAT_GENERAL')
local captured=NewUnit(0,20,'UNIT_GREAT_GENERAL')
GameEvents.UnitConverted(1,0,20,20,false);Players[1].units[20]=nil
M.OnTurn(0);Equal(Ambition(),before,'captured General is not a birth')
captured=Upgrade(captured,21,'UNIT_GREAT_ADMIRAL')
M.OnTurn(0);Equal(Ambition(),before,'converted GP is not a birth')
local purchasedGP=NewUnit(0,22,'UNIT_GREAT_ADMIRAL')
GameEvents.CityTrained(0,1,22,false,true);Equal(Ambition(),before+3,'native Faith-born Admiral uses purchase hook')
GameEvents.CityTrained(0,1,22,false,true);M.OnTurn(0);Equal(Ambition(),before+3,'purchased GP birth cannot duplicate')
-- Flight applies immediately without unlocking another chapter.
Players[0].era=6;M.AddAmbition(0,215,'test',false)
local colony=NewCity(0,2,10,0,2);GameEvents.PlayerCityFounded(0,10,0)
Equal(colony:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS_FLIGHT),0)
Teams[0].techs[T.TECH_FLIGHT]=true;GameEvents.TeamTechResearched(0,T.TECH_FLIGHT)
Equal(colony:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS_FLIGHT),1,'Flight refreshes on its event')
-- The compatible rebate retains full native affordability, excludes civilians
-- and faith, and cannot duplicate when CityTrained is delivered again.
Players[0].gold=200
local bought=NewUnit(0,30,'UNIT_INFANTRY');GameEvents.CityTrained(0,1,30,true,false)
Players[0]:ChangeGold(-c:GetUnitPurchaseCost(bought.typ))
Equal(Players[0].gold,10,'5 percent final effective military rebate')
GameEvents.CityTrained(0,1,30,true,false);Equal(Players[0].gold,10)
local worker=NewUnit(0,31,'UNIT_WORKER');GameEvents.CityTrained(0,1,31,true,false)
Equal(Players[0].gold,10,'civilian purchases receive no discount')
local faith=NewUnit(0,32,'UNIT_INFANTRY');GameEvents.CityTrained(0,1,32,false,true)
Equal(Players[0].gold,10,'faith purchases receive no Gold rebate')
assert(not Has(bought,'ACADEMY_TRAINING') and bought.xp100==0)
-- Parent combat's General points survive a nested combat on the same unit.
local vet=NewUnit(0,33,'UNIT_INFANTRY',0,0,4)
NewUnit(1,30,'UNIT_INFANTRY',2,0);NewUnit(1,31,'UNIT_INFANTRY',3,0)
GameEvents.BattleStarted(0,2,0)
GameEvents.CombatResult(0,33,0,0,100,1,30,0,0,100,-1,-1,0,2,0)
GameEvents.BattleStarted(0,3,0)
GameEvents.CombatResult(0,33,0,0,100,1,31,0,0,100,-1,-1,0,3,0)
GameEvents.BattleFinished();assert(Has(vet,'MADRID_GG'),'nested finish restores parent modifier')
GameEvents.BattleFinished();assert(not Has(vet,'MADRID_GG'))
-- Rebuilding the original training city cannot impersonate its founding identity.
c:SetNumRealBuilding(T.BUILDING_CR7_SPORTING_ACADEMY,1)
local graduate=NewUnit(0,10,'UNIT_WARRIOR',0,0,3);M.OnTrained(0,1,10,false,false)
CurrentTurn=3;Players[0].cities[1]=nil;local refounded=NewCity(0,1,0,0,1)
Promote(graduate,T.PROMOTION_SHOCK_1);Equal(refounded.production,0,'razed/refounded academy origin excluded')
-- Reload a native counter birth before the deferred check, without replaying it.
local pending=NewUnit(0,11,'UNIT_GREAT_GENERAL');Players[0].generalsCreated=2
before=Ambition();MapModData.CR7=nil;ResetRuntimeEvents();assert(loadstring(RuntimeSource))()
M=MapModData.CR7;M.OnTurn(0);Equal(Ambition(),before+3)
MapModData.CR7=nil;ResetRuntimeEvents();assert(loadstring(RuntimeSource))()
M=MapModData.CR7;M.OnTurn(0);Equal(Ambition(),before+3,'pending GP reload cannot duplicate')
-- An old save's pending General lacks the new counter snapshot. Its full CP
-- threshold increment is still recognized once under the existing namespace.
local legacy=NewUnit(0,40,'UNIT_GREAT_GENERAL')
local token=Saved['CR7|v1|0|UnitSlot40']
Saved['CR7|v1|-1|Lineage'..token..'|GPCreated']=nil
Players[0].generalThreshold=Players[0].generalThreshold+100
before=Ambition();MapModData.CR7=nil;ResetRuntimeEvents();assert(loadstring(RuntimeSource))()
MapModData.CR7.OnTurn(0);Equal(Ambition(),before+3,'legacy pending-GP migration preserves reward')
-- Mid-turn reload preserves the original first-kill movement entitlement.
local retained=NewUnit(0,12,'UNIT_CR7_COMPLETE_FORWARD');CurrentTurn=4
Kill(retained,NewUnit(1,7,'UNIT_WARRIOR',2,0),true);Equal(retained.moves,60)
MapModData.CR7=nil;ResetRuntimeEvents();assert(loadstring(RuntimeSource))()
Kill(retained,NewUnit(1,8,'UNIT_WARRIOR',2,0),true);Equal(retained.moves,60)
-- Golden Age dummy production is removed at the actual end event, while
-- chapter/legacy policies remain present and ordinary Social Policies survive.
Players[0].era=7;M=MapModData.CR7;M.AddAmbition(0,275,'test',false)
assert(refounded:GetNumRealBuilding(T.BUILDING_CR7_GOLDEN_PRODUCTION)==1)
Players[0].golden=0;GameEvents.PlayerGoldenAge(0,false,0)
Equal(refounded:GetNumRealBuilding(T.BUILDING_CR7_GOLDEN_PRODUCTION),0)
assert(Players[0]:HasPolicy(T.POLICY_CR7_CHAPTER_7))
-- A legacy foreign Forward keeps reduced healing after its original civ dies.
local capturedForward=NewUnit(1,60,'UNIT_CR7_COMPLETE_FORWARD')
GameEvents.UnitConverted(0,1,retained.id,60,false);Players[0].units[retained.id]=nil
token=Saved['CR7|v1|1|UnitSlot60'];Saved['CR7|v1|-1|Lineage'..token..'|Forward']=nil
Players[0].alive=false
MapModData.CR7=nil;ResetRuntimeEvents();assert(loadstring(RuntimeSource))()
capturedForward=Upgrade(capturedForward,61,'UNIT_WWI_TANK')
assert(Has(capturedForward,'FINISHER_VETERAN') and not Has(capturedForward,'FINISHER'))
capturedForward.damage=50
Kill(capturedForward,NewUnit(2,1,'UNIT_WWI_TANK',2,0),true)
Equal(capturedForward.damage,45,'foreign veteran healing survives eliminated-origin reload')
print('PASS CR7 audit: source-ordered melee/ranged/defender combat, mutual deaths, duplicate upgrades, free Forwards, GP edits/reload, Flight and razed origins')
