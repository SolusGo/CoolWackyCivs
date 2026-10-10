local M=MapModData.CR7;local T=GameInfoTypes
local c=NewCity(0,1,0,0,1)
local normal=T.PROMOTION_SHOCK_1
local admin=NewUnit(0,1,'UNIT_WARRIOR',0,0,6)
local before=Ambition();M.OnTurn(0);Equal(Ambition(),before,'administrative Level 6 excluded')
Promote(admin,normal);Equal(Ambition(),before+4,'earned promotion plus first Level 6')
CurrentTurn=1;Players[0].era=1;before=Ambition();M.OnTurn(0)
Equal(Ambition(),before,'existing veteran does not trigger again in new era')
local newcomer=NewUnit(0,2,'UNIT_WARRIOR',0,0,6);M.OnTrained(0,1,2,false,false)
Equal(Ambition(),before+3,'different unit legitimately reaches Level 6 in new era')
local general=NewUnit(0,3,'UNIT_GREAT_GENERAL');before=Ambition()
Players[0].generalThreshold=50
M.OnPrekill(0,3,general.typ,0,0,true,-1)
Equal(Ambition(),before+3,'birth-turn expenditure rewarded')
Players[0].units[3]=nil
-- A bare administrative GP before a real one cannot steal the birth reward.
NewUnit(0,4,'UNIT_GREAT_ADMIRAL');local admiral=NewUnit(0,5,'UNIT_GREAT_ADMIRAL')
before=Ambition();Players[0].admiralThreshold=50
M.OnPrekill(0,5,admiral.typ,0,0,true,-1);Equal(Ambition(),before+3)
-- Per-era academy entitlement follows ownership changes and foreign upgrades.
M.AddAmbition(0,20,'test',false);c:SetNumRealBuilding(T.BUILDING_CR7_SPORTING_ACADEMY,1)
local graduate=NewUnit(0,6,'UNIT_WARRIOR',0,0,4);M.OnTrained(0,1,6,false,false)
Equal(c.production,15)
local transferred=NewUnit(1,6,'UNIT_WARRIOR',1,0,4)
for id,v in pairs(graduate.promotions)do transferred.promotions[id]=v end
M.OnConverted(0,1,6,6,false);Players[0].units[6]=nil
assert(not Has(transferred,'HABIT') and Has(transferred,'FIRST_IN'))
transferred=Upgrade(transferred,7,'UNIT_SPEARMAN')
local returned=NewUnit(0,7,'UNIT_SPEARMAN',0,0,4)
for id,v in pairs(transferred.promotions)do returned.promotions[id]=v end
M.OnConverted(1,0,7,7,false);Players[1].units[7]=nil
M.OnPromoted(0,7,normal);Equal(c.production,15,'returning graduate cannot repeat reward')
-- A captured Finisher is reduced on its next genuine upgrade, retaining identity.
local forward=NewUnit(0,8,'UNIT_CR7_COMPLETE_FORWARD');M.OnTrained(0,1,8,false,false)
transferred=NewUnit(1,8,'UNIT_CR7_COMPLETE_FORWARD')
M.OnConverted(0,1,8,8,false);Players[0].units[8]=nil
transferred=Upgrade(transferred,9,'UNIT_WWI_TANK')
assert(Has(transferred,'FINISHER_VETERAN') and not Has(transferred,'FINISHER'))
transferred.damage=50;Kill(transferred,NewUnit(0,30,'UNIT_WWI_TANK',2,0),true)
Equal(transferred.damage,45,'retained kill healing follows ownership')
-- Actual production replaces overseas dummy effects with zero upon foreign transfer.
Players[0].era=6;M.AddAmbition(0,215,'test',false)
local colony=NewCity(0,2,12,0,2);M.OnTurn(0)
Equal(colony:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS),1)
Players[0].cities[2]=nil;colony.owner=1;Players[1].cities[2]=colony
M.OnCapture(0,false,12,0,1,1,false)
Equal(colony:GetNumRealBuilding(T.BUILDING_CR7_OVERSEAS),0)
-- CP peace cessions can report conquest=true, but have no military combat frame.
local ceded=NewCity(0,20,20,0,2);ceded.originalCapital=true;ceded.originalOwner=1
before=Ambition();M.OnCapture(1,true,20,0,0,10,true);Equal(Ambition(),before,'peace cession excluded')
-- Queued resolutions can finish in a different order from their Started hooks.
local f=NewUnit(0,50,'UNIT_CR7_COMPLETE_FORWARD');M.OnTrained(0,1,50,false,false);f.damage=50
local ea=NewUnit(1,50,'UNIT_WARRIOR',3,0);local eb=NewUnit(1,51,'UNIT_WARRIOR',4,0)
M.OnBattleStarted(0,3,0);M.OnBattleStarted(0,4,0)
M.OnCombatResult(0,50,1,0,100,1,50,1,100,100,-1,-1,0,3,0)
M.OnPrekill(1,50,ea.typ,3,0,true,0);M.OnBattleFinished();Equal(f.damage,42)
M.OnCombatResult(0,50,1,0,100,1,51,1,100,100,-1,-1,0,4,0)
M.OnPrekill(1,51,eb.typ,4,0,true,0);M.OnBattleFinished();Equal(f.damage,34);Equal(f.moves,60)
-- Nested resolution restores the outer combat identity.
CurrentTurn=CurrentTurn+1;f.damage=50;f.moves=0
ea=NewUnit(1,52,'UNIT_WARRIOR',3,0);eb=NewUnit(1,53,'UNIT_WARRIOR',4,0)
M.OnBattleStarted(0,3,0);M.OnCombatResult(0,50,1,0,100,1,52,1,100,100,-1,-1,0,3,0)
M.OnBattleStarted(0,4,0);M.OnCombatResult(0,50,1,0,100,1,53,1,100,100,-1,-1,0,4,0)
M.OnPrekill(1,53,eb.typ,4,0,true,0);M.OnBattleFinished()
M.OnPrekill(1,52,ea.typ,3,0,true,0);M.OnBattleFinished();Equal(f.damage,34);Equal(f.moves,60)
print('PASS CR7 lifecycle: genuine GP births, milestone identity, ownership, foreign upgrades and city transfers')
