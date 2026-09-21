"""Focused deterministic checks for The Filthy Realm runtime."""
from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))


def main() -> None:
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
MapModData = {}
GameInfoTypes = {
 CIVILIZATION_FILTHY_REALM=1, BUILDING_FILTHY_KITCHEN=2,
 UNIT_FILTHY_PEACE_LORD=3, UNIT_FILTHY_SALAMANDER_MAN=4,
 PROMOTION_FILTHY_CITY_STRENGTH_10=20, PROMOTION_FILTHY_CITY_STRENGTH_15=21,
 PROMOTION_FILTHY_HUMILIATED=22, PROMOTION_FILTHY_SALAMANDER_ENEMY=23,
 PROMOTION_FILTHY_SALAMANDER_FRIEND=24, PROMOTION_FILTHY_DISTORTION_ZOC=25,
 PROMOTION_FILTHY_STOPPED=26, BUILDINGCLASS_MOCK_GW=60
}
for i=1,5 do
 GameInfoTypes['BUILDING_FILTHY_LEVEL_'..i]=30+i
 GameInfoTypes['BUILDING_FILTHY_DISTORTED_'..i]=40+i
end
GameDefines={MAX_MAJOR_CIVS=3,MAX_CIV_PLAYERS=4,MOVE_DENOMINATOR=60}
DomainTypes={DOMAIN_LAND=1,DOMAIN_SEA=2}
DirectionTypes={NUM_DIRECTION_TYPES=6}
InfluenceLevelTypes={INFLUENCE_LEVEL_FAMILIAR=2}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key,...) return key end}
LuaEvents={FilthyStateChanged=function() end}
Events={GameplayAlertMessage=function() end}
Game={current=12,GetGameTurn=function() return Game.current end,IsNetworkMultiPlayer=function() return false end,
 GetGreatWorkType=function(id) if id==1000 then return 55 end return -1 end}
GameInfo={Resolutions={},Buildings=function()
 local rows={{GreatWorkCount=1,BuildingClass='BUILDINGCLASS_MOCK_GW'}}; local i=0
 return function() i=i+1; return rows[i] end
end}
local storage={}
Modding={OpenSaveData=function() return {
 GetValue=function(key) return storage[key] end,
 SetValue=function(key,value) storage[key]=value end
} end}
local function event() local e={handlers={}}; e.Add=function(f)e.handlers[#e.handlers+1]=f end; return e end
GameEvents={}
for _,name in ipairs({'PlayerDoTurn','UnitPrekill','CityCaptureComplete','CityTrained','BattleStarted',
 'BattleJoined','BattleFinished','UnitSetXY','PlayerCanGiftUnit','UnitPillageGold','DeclareWar',
 'MakePeace','ResolutionResult','GreatWorkCreated','UnitConverted'}) do GameEvents[name]=event() end

local plots={}
local function plotKey(x,y) return x..':'..y end
function NewPlot(x,y,owner)
 local p={x=x,y=y,owner=owner or -1,water=false,mountain=false,city=false,units=0,allow=true,impassable=false}
 function p:GetX()return self.x end; function p:GetY()return self.y end
 function p:GetOwner()return self.owner end; function p:IsWater()return self.water end
 function p:IsMountain()return self.mountain end; function p:IsImpassable()return self.impassable end
 function p:IsCity()return self.city end; function p:GetNumUnits()return self.units end
 function p:GetPlotCity()return self.cityObj end
 plots[plotKey(x,y)]=p; return p
end
Map={}
function Map.GetPlot(x,y) return plots[plotKey(x,y)] or NewPlot(x,y,-1) end
function Map.PlotDirection(x,y,d)
 local offsets={{1,0},{1,1},{0,1},{-1,0},{-1,-1},{0,-1}}
 local o=offsets[d+1]; return Map.GetPlot(x+o[1],y+o[2])
end
function Map.PlotDistance(x1,y1,x2,y2) return math.max(math.abs(x1-x2),math.abs(y1-y2)) end

function NewCity(owner,id,x,y,name)
 local c={owner=owner,id=id,x=x,y=y,name=name,buildings={},workSlots={},food=100,production=80,works=0,founded=0}
 function c:GetOwner()return self.owner end; function c:GetID()return self.id end
 function c:GetX()return self.x end; function c:GetY()return self.y end; function c:GetName()return self.name end
 function c:GetGameTurnFounded()return self.founded end
 function c:GetNumRealBuilding(id)return self.buildings[id] or 0 end
 function c:SetNumRealBuilding(id,n)self.buildings[id]=n end
 function c:GetNumGreatWorks()return self.works end
 function c:GetBuildingGreatWork(class,slot)return self.workSlots[class..':'..slot] or -1 end
 function c:GetFood()return self.food end; function c:ChangeFood(n)self.food=self.food+n end
 function c:GetProduction()return self.production end; function c:ChangeProduction(n)self.production=self.production+n end
 local p=Map.GetPlot(x,y); p.city=true; p.cityObj=c; p.owner=owner
 return c
end

local nextUnit=100
function NewUnit(owner,kind,x,y,military,hp)
 nextUnit=nextUnit+1
 local u={owner=owner,id=nextUnit,kind=kind,x=x,y=y,military=military or false,hp=hp or 100,
  moves=120,promotions={},script='',dead=false,domain=DomainTypes.DOMAIN_LAND,name='Unit '..nextUnit,embarked=false}
 function u:GetOwner()return self.owner end; function u:GetID()return self.id end; function u:GetUnitType()return self.kind end
 function u:GetX()return self.x end; function u:GetY()return self.y end; function u:GetPlot()return Map.GetPlot(self.x,self.y) end
 function u:IsCombatUnit()return self.military end; function u:IsTrade()return false end
 function u:IsHasPromotion(p)return self.promotions[p]==true end; function u:SetHasPromotion(p,v)self.promotions[p]=v end
 function u:GetScriptData()return self.script end; function u:SetScriptData(v)self.script=v end
 function u:MaxMoves()return 120 end; function u:SetMoves(v)self.moves=v end; function u:GetMoves()return self.moves end
 function u:GetCurrHitPoints()return self.hp end; function u:GetDomainType()return self.domain end
 function u:IsEmbarked()return self.embarked end
 function u:CanMoveThrough(plot)
  if not plot.allow or plot:IsImpassable() or plot:IsCity() or plot:GetNumUnits()>0 then return false end
  if self.domain==DomainTypes.DOMAIN_SEA then return plot:IsWater() end
  return (self.embarked and plot:IsWater()) or (not plot:IsWater() and not plot:IsMountain())
 end
 function u:GetGreatWorkSlotType()return 1 end
 function u:SetXY(x,y)self.x=x;self.y=y end; function u:Kill()self.dead=true end
 function u:GetName()return self.name end; function u:GetExperience()return 0 end; function u:ChangeExperience()end
 return u
end

function NewPlayer(id,civ,team)
 local p={id=id,civ=civ,team=team,alive=true,human=id==0,minor=false,gold=200,culture=100,research=0,era=0,
  cityList={},unitList={},denounced={},tradeRoutes={}}
 function p:IsAlive()return self.alive end; function p:IsHuman()return self.human end
 function p:IsMinorCiv()return self.minor end; function p:GetCivilizationType()return self.civ end; function p:GetTeam()return self.team end
 function p:GetCurrentEra()return self.era end; function p:GetGold()return self.gold end; function p:ChangeGold(n)self.gold=self.gold+n end
 function p:GetJONSCulture()return self.culture end; function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:ChangeOverflowResearch(n)self.research=self.research+n end
 function p:GetCapitalCity()return self.cityList[1] end; function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id and not u.dead then return u end end end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:Units()local i=0;return function()repeat i=i+1 until not self.unitList[i] or not self.unitList[i].dead;return self.unitList[i]end end
 function p:GetTradeRoutes()return self.tradeRoutes end; function p:GetInfluenceLevel()return 0 end
 function p:GetCityOfClosestGreatWorkSlot()return self:GetCapitalCity() end
 function p:IsDenouncedPlayer(other)return self.denounced[other]==true end
 function p:AddNotification()end
 function p:InitUnit(kind,x,y)local u=NewUnit(self.id,kind,x,y,false,100);self.unitList[#self.unitList+1]=u;return u end
 return p
end
Players={[0]=NewPlayer(0,1,0),[1]=NewPlayer(1,99,1),[3]=NewPlayer(3,98,3)}
Players[3].minor=true; Players[3].human=false
Teams={
 [0]={IsAtWar=function(self,t)return t==1 or t==3 end},
 [1]={IsAtWar=function(self,t)return t==0 end},
 [3]={IsAtWar=function(self,t)return t==0 end}
}
local capital=NewCity(0,1,0,0,'The Rice Fields'); Players[0].cityList={capital}
local targetCity=NewCity(1,2,6,6,'Target City'); Players[1].cityList={targetCity}
local minorCity=NewCity(3,3,9,9,'Minor City'); Players[3].cityList={minorCity}
''')
    lua.execute((REPO / "FilthyRealm/Lua/FilthyRuntime.lua").read_text(encoding="utf-8-sig"))
    lua.execute(r'''
local F=MapModData.FilthyRealm
assert(#GameEvents.PlayerDoTurn.handlers==1)
assert(#GameEvents.UnitPillageGold.handlers==1)
assert(#GameEvents.ResolutionResult.handlers==1)
assert(#GameEvents.GreatWorkCreated.handlers==1)
assert(F.GetPoints(0)==0)
F.ChangeFilth(Players[1].cityList[1],1,0)
local level,distorted=F.GetFilth(Players[1].cityList[1])
assert(level==1 and not distorted and F.GetPoints(0)==2,'Filth gain or +2 FP failed')
F.ChangePoints(0,100)
local ok=F.UseDistortion(0,1,2); assert(ok and F.GetCooldown(0,'DISTORTION')==10)
level,distorted=F.GetFilth(Players[1].cityList[1]); assert(level==1 and distorted,'distorted building not selected')

-- A razed/refounded city reusing the old numeric ID must not inherit Distortion.
local originalTarget=Players[1].cityList[1]
local replacement=NewCity(1,2,20,20,'Replacement City'); replacement.founded=99
Players[1].cityList[1]=replacement
local probe=NewUnit(0,92,20,19,true,100); Players[0].unitList[#Players[0].unitList+1]=probe
F.RefreshCombat(); assert(not probe:IsHasPromotion(25),'Distortion leaked to a reused city ID')
Players[1].cityList[1]=originalTarget

ok=F.UseRavioli(0,1,2,'GOLD'); assert(ok,'Ravioli activation failed')
assert(Players[0].gold==225 and Players[1].gold==175 and F.GetPoints(0)==2,'Ravioli transfer/cost incorrect')
Players[1].cityList={}; originalTarget.owner=3; Players[3].cityList[#Players[3].cityList+1]=originalTarget
ok=F.UseRavioli(0,3,2,'GOLD'); assert(not ok,'city transfer reset the Ravioli cooldown')
table.remove(Players[3].cityList); originalTarget.owner=1; Players[1].cityList={originalTarget}
F.ChangePoints(0,25); ok=F.UseSalamander(0); assert(ok,'Salamander summon failed')
local salamander
for _,unit in ipairs(Players[0].unitList) do if unit:GetUnitType()==4 then salamander=unit end end
assert(salamander and F.GetUnitState(salamander).salUntil==17)

local peace=NewUnit(0,3,1,1,true,100); Players[0].unitList[#Players[0].unitList+1]=peace
local victim=NewUnit(1,90,2,1,true,25); Players[1].unitList[#Players[1].unitList+1]=victim
local targets=F.GetInterventionTargets(0); assert(#targets==1,'eligible Intervention target missing')
ok=F.UseIntervention(0,peace:GetID(),1,victim:GetID()); assert(ok and F.GetUnitState(peace).intervention==1)
assert(F.GetPoints(0)==12,'Intervention did not award 10 FP')

-- Retreats must honor the unit's normal plot legality, not merely terrain domain.
local peace2=NewUnit(0,3,10,10,true,100); Players[0].unitList[#Players[0].unitList+1]=peace2
local blocked=NewUnit(1,93,11,10,true,25); Players[1].unitList[#Players[1].unitList+1]=blocked
Map.GetPlot(12,10).allow=false; Map.GetPlot(12,11).allow=false
targets=F.GetInterventionTargets(0)
for _,entry in ipairs(targets) do assert(entry.peace~=peace2:GetID(),'Intervention offered an illegal retreat') end

local enemy=NewUnit(1,91,3,1,true,100); Players[1].unitList[#Players[1].unitList+1]=enemy
enemy:SetXY(2,0); GameEvents.UnitSetXY.handlers[1](1,enemy:GetID())
assert(enemy:IsHasPromotion(23),'enemy entering Salamander aura was not updated immediately')
enemy:SetXY(5,0); GameEvents.UnitSetXY.handlers[1](1,enemy:GetID())
assert(not enemy:IsHasPromotion(23),'enemy leaving Salamander aura kept the debuff')
enemy:SetXY(3,1)

-- Minor-civilization cities and units are foreign/enemy targets too.
local anchor=NewUnit(0,94,8,8,true,100); Players[0].unitList[#Players[0].unitList+1]=anchor
F.ChangeFilth(Players[3].cityList[1],4,0)
assert(anchor:IsHasPromotion(20),'Filth combat bonus ignored a City-State city')
local sawMinor=false
for _,entry in ipairs(F.GetForeignCities(0,true)) do if entry.owner==3 then sawMinor=true end end
assert(sawMinor,'City-State city missing from foreign-city abilities')
local minorEnemy=NewUnit(3,95,9,8,true,100); Players[3].unitList[#Players[3].unitList+1]=minorEnemy
F.ChangePoints(0,80); ok=F.UseStop(0); assert(ok,'Stop activation failed')
assert(enemy:GetMoves()==0 and enemy:IsHasPromotion(26),'Stop did not exhaust/suppress enemy')
assert(minorEnemy:GetMoves()==0 and minorEnemy:IsHasPromotion(26),'Stop ignored a City-State enemy')
assert(F.GetCooldown(0,'STOP')==20,'Stop cooldown incorrect')
local returned=GameEvents.UnitPillageGold.handlers[1](0,peace:GetID(),5,40)
assert(returned==40,'pillage hook changed base gold reward')

-- The battle stack must identify a Peace Lord killer and apply every reward once.
local killer=NewUnit(0,3,6,5,true,100); Players[0].unitList[#Players[0].unitList+1]=killer
local doomed=NewUnit(1,96,6,6,true,10); Players[1].unitList[#Players[1].unitList+1]=doomed
local humiliated=NewUnit(1,97,7,5,true,100); Players[1].unitList[#Players[1].unitList+1]=humiliated
GameEvents.BattleStarted.handlers[1]()
GameEvents.BattleJoined.handlers[1](0,killer:GetID(),0,false)
GameEvents.BattleJoined.handlers[1](1,doomed:GetID(),1,false)
local killPoints=F.GetPoints(0)
GameEvents.UnitPrekill.handlers[1](1,doomed:GetID(),96,6,6,false,0)
assert(F.GetPoints(0)==killPoints+10,'Peace Lord territory kill rewards were incomplete or duplicated')
assert(humiliated:IsHasPromotion(22),'Peace Lord kill did not humiliate an adjacent enemy')
GameEvents.BattleFinished.handlers[1]()

-- GreatWorkCreated is authoritative: moving works cannot replay the creation reward.
local capital=Players[0]:GetCapitalCity(); capital:SetNumRealBuilding(2,1)
local beforePoints,beforeFood=F.GetPoints(0),capital:GetFood()
capital.workSlots['60:0']=1000; capital.works=1; peace.dead=true
GameEvents.GreatWorkCreated.handlers[1](0,peace:GetID(),55)
assert(F.GetPoints(0)==beforePoints+10 and capital:GetFood()==beforeFood+25,'Great Work reward failed')
Game.current=13; F.OnPlayerTurn(0)
assert(F.GetPoints(0)==beforePoints+10,'moving/counting Great Works replayed the creation reward')

-- Parallel routes between the same city pair each count exactly once.
beforePoints=F.GetPoints(0)
local route={FromCity=capital,ToCity=originalTarget}
Players[0].tradeRoutes={route,{FromCity=capital,ToCity=originalTarget}}
F.OnPlayerTurn(0); assert(F.GetPoints(0)==beforePoints+10,'parallel new routes did not award +5 each')
F.OnPlayerTurn(0); assert(F.GetPoints(0)==beforePoints+10,'unchanged routes awarded points twice')

-- Peace can be initiated by either side; a later new declaration must reward once again.
beforePoints=F.GetPoints(0)
GameEvents.DeclareWar.handlers[1](1,0,true)
GameEvents.DeclareWar.handlers[1](1,0,true)
assert(F.GetPoints(0)==beforePoints+20,'war declaration reward duplicated or failed')
GameEvents.MakePeace.handlers[1](0,1,true)
GameEvents.DeclareWar.handlers[1](1,0,true)
assert(F.GetPoints(0)==beforePoints+40,'Frank-initiated peace did not reset the war reward state')
GameEvents.DeclareWar.handlers[1](3,0,true)
GameEvents.MakePeace.handlers[1](0,3,true)
GameEvents.DeclareWar.handlers[1](3,0,true)
assert(F.GetPoints(0)==beforePoints+80,'City-State peace did not reset the war reward state')

-- Denunciation and targeted-resolution transitions are one-shot while unchanged.
beforePoints=F.GetPoints(0); Players[1].denounced[0]=true
F.OnPlayerTurn(0); F.OnPlayerTurn(0)
assert(F.GetPoints(0)==beforePoints+10,'denunciation transition reward duplicated or failed')
Players[1].denounced[0]=false; F.OnPlayerTurn(0); Players[1].denounced[0]=true; F.OnPlayerTurn(0)
assert(F.GetPoints(0)==beforePoints+20,'renewed denunciation was not rewarded')
GameInfo.Resolutions[7]={EmbargoPlayer=1}; beforePoints=F.GetPoints(0)
GameEvents.ResolutionResult.handlers[1](7,1,0,true,true)
GameEvents.ResolutionResult.handlers[1](7,1,0,true,true)
assert(F.GetPoints(0)==beforePoints+25,'targeted resolution reward duplicated or failed')

-- Exercise the remaining deterministic Ravioli categories and receiver edge paths.
local cultureCity=NewCity(1,4,30,30,'Culture City'); Players[1].cityList[#Players[1].cityList+1]=cultureCity
F.ChangePoints(0,60); local oldMine,oldTheirs=Players[0].culture,Players[1].culture
ok=F.UseRavioli(0,1,4,'CULTURE'); assert(ok and Players[0].culture==oldMine+15 and Players[1].culture==oldTheirs-15)
local foodCity=NewCity(1,5,31,30,'Food City'); foodCity.food=11; Players[1].cityList[#Players[1].cityList+1]=foodCity
F.ChangePoints(0,60); beforeFood=capital:GetFood(); ok=F.UseRavioli(0,1,5,'FOOD')
assert(ok and foodCity:GetFood()==0 and capital:GetFood()==beforeFood+11,'Food Ravioli transfer failed')
local productionCity=NewCity(1,6,32,30,'Production City'); productionCity.production=9; Players[1].cityList[#Players[1].cityList+1]=productionCity
F.ChangePoints(0,60); local oldProduction=capital:GetProduction(); ok=F.UseRavioli(0,1,6,'PRODUCTION')
assert(ok and productionCity:GetProduction()==0 and capital:GetProduction()==oldProduction+9,'Production Ravioli transfer failed')
 local scienceCity=NewCity(1,7,33,30,'Science City'); Players[1].cityList[#Players[1].cityList+1]=scienceCity
 F.ChangePoints(0,60); local oldResearch=Players[0].research; ok=F.UseRavioli(0,1,7,'SCIENCE')
 assert(ok and Players[0].research==oldResearch+15,'Science Ravioli grant failed')

 -- NeverCapture Filth buildings disappear before CityCaptureComplete; the
 -- save-backed city level must restore them through repeated normal captures.
 local conquest=NewCity(1,8,40,40,'Conquest City');conquest.founded=4
 Players[1].cityList[#Players[1].cityList+1]=conquest
 F.ChangeFilth(conquest,5,0);assert(F.GetFilth(conquest)==5)
 for i=31,45 do conquest.buildings[i]=0 end
 conquest.owner=3;Players[3].cityList[#Players[3].cityList+1]=conquest
 GameEvents.CityCaptureComplete.handlers[1](1,false,40,40,3,5,true)
 assert(F.GetFilth(conquest)==5 and conquest.buildings[35]==1,'maximum Filth was lost on normal capture')
 for i=31,45 do conquest.buildings[i]=0 end
 conquest.owner=1
 GameEvents.CityCaptureComplete.handlers[1](3,false,40,40,1,5,true)
 assert(F.GetFilth(conquest)==5 and conquest.buildings[35]==1,'Filth failed across repeated ownership changes')
 for i=31,45 do conquest.buildings[i]=0 end
 F.RestoreFilth()
 assert(F.GetFilth(conquest)==5 and conquest.buildings[35]==1,'save/load restoration lost conquered Filth')
 for i=31,45 do conquest.buildings[i]=0 end
 conquest.owner=0;Players[0].cityList[#Players[0].cityList+1]=conquest
 GameEvents.CityCaptureComplete.handlers[1](1,false,40,40,0,5,true)
 assert(F.GetFilth(conquest)==0,'Filthy capture did not intentionally cleanse Filth')
 local clean=NewCity(1,9,42,40,'Clean City');Players[1].cityList[#Players[1].cityList+1]=clean
 clean.owner=3;GameEvents.CityCaptureComplete.handlers[1](1,false,42,40,3,5,true)
 assert(F.GetFilth(clean)==0,'zero-Filth city gained Filth on capture')

 -- Conversion policy: per-unit entitlements/lifetimes survive only on their
 -- matching type; LostWithUpgrade debuffs clear on upgrades but survive capture.
 local upgrading=NewUnit(0,3,45,40,true,100);Players[0].unitList[#Players[0].unitList+1]=upgrading
 F.SetUnitState(upgrading,{salUntil=20,intervention=1,humUntil=20,stopUntil=20})
 F.OnPrekill(0,upgrading:GetID(),3,45,40,false,-1);upgrading.dead=true
 local upgraded=NewUnit(0,3,45,40,true,100);upgraded.script='[OTHER:kept]';Players[0].unitList[#Players[0].unitList+1]=upgraded
 F.OnUnitConverted(0,0,upgrading:GetID(),upgraded:GetID(),true)
 local upgradedState=F.GetUnitState(upgraded)
 assert(upgradedState.intervention==1 and upgradedState.humUntil==-1 and upgradedState.stopUntil==-1,
  'upgrade conversion policy did not preserve/drop the intended fields')
 assert(upgraded.script:find('%[OTHER:kept%]') and not upgraded:IsHasPromotion(22) and not upgraded:IsHasPromotion(26),
  'upgrade conversion corrupted foreign ScriptData or retained temporary promotions')
 local afflicted=NewUnit(1,90,46,40,true,100);Players[1].unitList[#Players[1].unitList+1]=afflicted
 F.SetUnitState(afflicted,{salUntil=-1,intervention=0,humUntil=20,stopUntil=20})
 F.OnPrekill(1,afflicted:GetID(),90,46,40,false,-1);afflicted.dead=true
 local capturedUnit=NewUnit(3,90,46,40,true,100);Players[3].unitList[#Players[3].unitList+1]=capturedUnit
 F.OnUnitConverted(1,3,afflicted:GetID(),capturedUnit:GetID(),false)
 local capturedState=F.GetUnitState(capturedUnit)
 assert(capturedState.humUntil==20 and capturedState.stopUntil==20 and capturedUnit:GetMoves()==0
  and capturedUnit:IsHasPromotion(22) and capturedUnit:IsHasPromotion(26),
  'capture conversion lost simultaneous temporary effects')
 local summoned=NewUnit(0,4,47,40,true,100);Players[0].unitList[#Players[0].unitList+1]=summoned
 F.SetUnitState(summoned,{salUntil=21,intervention=0,humUntil=-1,stopUntil=-1})
 F.OnPrekill(0,summoned:GetID(),4,47,40,false,-1);summoned.dead=true
 local convertedSummon=NewUnit(0,4,47,40,true,100);Players[0].unitList[#Players[0].unitList+1]=convertedSummon
 F.OnUnitConverted(0,0,summoned:GetID(),convertedSummon:GetID(),false)
 assert(F.GetUnitState(convertedSummon).salUntil==21,'Salamander lifetime did not survive conversion/save state')
 ''')
    print("PASS Filthy Lua adversarial mock: abilities, persistence, movement, City-States, diplomacy, routes and Great Works")


if __name__ == "__main__":
    main()
