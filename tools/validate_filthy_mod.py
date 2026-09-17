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
 PROMOTION_FILTHY_STOPPED=26
}
for i=1,5 do
 GameInfoTypes['BUILDING_FILTHY_LEVEL_'..i]=30+i
 GameInfoTypes['BUILDING_FILTHY_DISTORTED_'..i]=40+i
end
GameDefines={MAX_MAJOR_CIVS=3,MAX_CIV_PLAYERS=3,MOVE_DENOMINATOR=60}
DomainTypes={DOMAIN_LAND=1,DOMAIN_SEA=2}
DirectionTypes={NUM_DIRECTION_TYPES=6}
InfluenceLevelTypes={INFLUENCE_LEVEL_FAMILIAR=2}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key,...) return key end}
LuaEvents={FilthyStateChanged=function() end}
Events={GameplayAlertMessage=function() end}
Game={current=12,GetGameTurn=function() return Game.current end,IsNetworkMultiPlayer=function() return false end}
GameInfo={Resolutions={}}
local storage={}
Modding={OpenSaveData=function() return {
 GetValue=function(key) return storage[key] end,
 SetValue=function(key,value) storage[key]=value end
} end}
local function event() local e={handlers={}}; e.Add=function(f)e.handlers[#e.handlers+1]=f end; return e end
GameEvents={}
for _,name in ipairs({'PlayerDoTurn','UnitPrekill','CityCaptureComplete','CityTrained','BattleStarted',
 'BattleJoined','BattleFinished','UnitSetXY','PlayerCanGiftUnit','UnitPillageGold','DeclareWar',
 'MakePeace','ResolutionResult'}) do GameEvents[name]=event() end

local plots={}
local function plotKey(x,y) return x..':'..y end
function NewPlot(x,y,owner)
 local p={x=x,y=y,owner=owner or -1,water=false,mountain=false,city=false,units=0}
 function p:GetX()return self.x end; function p:GetY()return self.y end
 function p:GetOwner()return self.owner end; function p:IsWater()return self.water end
 function p:IsMountain()return self.mountain end; function p:IsImpassable()return false end
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
 local c={owner=owner,id=id,x=x,y=y,name=name,buildings={},food=100,production=80,works=0,founded=0}
 function c:GetOwner()return self.owner end; function c:GetID()return self.id end
 function c:GetX()return self.x end; function c:GetY()return self.y end; function c:GetName()return self.name end
 function c:GetGameTurnFounded()return self.founded end
 function c:GetNumRealBuilding(id)return self.buildings[id] or 0 end
 function c:SetNumRealBuilding(id,n)self.buildings[id]=n end
 function c:GetNumGreatWorks()return self.works end
 function c:GetFood()return self.food end; function c:ChangeFood(n)self.food=self.food+n end
 function c:GetProduction()return self.production end; function c:ChangeProduction(n)self.production=self.production+n end
 local p=Map.GetPlot(x,y); p.city=true; p.cityObj=c; p.owner=owner
 return c
end

local nextUnit=100
function NewUnit(owner,kind,x,y,military,hp)
 nextUnit=nextUnit+1
 local u={owner=owner,id=nextUnit,kind=kind,x=x,y=y,military=military or false,hp=hp or 100,
  moves=120,promotions={},script='',dead=false,domain=DomainTypes.DOMAIN_LAND,name='Unit '..nextUnit}
 function u:GetOwner()return self.owner end; function u:GetID()return self.id end; function u:GetUnitType()return self.kind end
 function u:GetX()return self.x end; function u:GetY()return self.y end; function u:GetPlot()return Map.GetPlot(self.x,self.y) end
 function u:IsCombatUnit()return self.military end; function u:IsTrade()return false end
 function u:IsHasPromotion(p)return self.promotions[p]==true end; function u:SetHasPromotion(p,v)self.promotions[p]=v end
 function u:GetScriptData()return self.script end; function u:SetScriptData(v)self.script=v end
 function u:MaxMoves()return 120 end; function u:SetMoves(v)self.moves=v end; function u:GetMoves()return self.moves end
 function u:GetCurrHitPoints()return self.hp end; function u:GetDomainType()return self.domain end
 function u:SetXY(x,y)self.x=x;self.y=y end; function u:Kill()self.dead=true end
 function u:GetName()return self.name end; function u:GetExperience()return 0 end; function u:ChangeExperience()end
 return u
end

function NewPlayer(id,civ,team)
 local p={id=id,civ=civ,team=team,alive=true,human=id==0,gold=200,culture=100,research=0,era=0,
  cityList={},unitList={},denounced={}}
 function p:IsAlive()return self.alive end; function p:IsHuman()return self.human end
 function p:IsMinorCiv()return false end; function p:GetCivilizationType()return self.civ end; function p:GetTeam()return self.team end
 function p:GetCurrentEra()return self.era end; function p:GetGold()return self.gold end; function p:ChangeGold(n)self.gold=self.gold+n end
 function p:GetJONSCulture()return self.culture end; function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:ChangeOverflowResearch(n)self.research=self.research+n end
 function p:GetCapitalCity()return self.cityList[1] end; function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id and not u.dead then return u end end end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:Units()local i=0;return function()repeat i=i+1 until not self.unitList[i] or not self.unitList[i].dead;return self.unitList[i]end end
 function p:GetTradeRoutes()return {} end; function p:GetInfluenceLevel()return 0 end
 function p:IsDenouncedPlayer(other)return self.denounced[other]==true end
 function p:AddNotification()end
 function p:InitUnit(kind,x,y)local u=NewUnit(self.id,kind,x,y,false,100);self.unitList[#self.unitList+1]=u;return u end
 return p
end
Players={[0]=NewPlayer(0,1,0),[1]=NewPlayer(1,99,1)}
Teams={[0]={IsAtWar=function(self,t)return t==1 end},[1]={IsAtWar=function(self,t)return t==0 end}}
local capital=NewCity(0,1,0,0,'The Rice Fields'); Players[0].cityList={capital}
local targetCity=NewCity(1,2,6,6,'Target City'); Players[1].cityList={targetCity}
''')
    lua.execute((REPO / "FilthyRealm/Lua/FilthyRuntime.lua").read_text(encoding="utf-8-sig"))
    lua.execute(r'''
local F=MapModData.FilthyRealm
assert(#GameEvents.PlayerDoTurn.handlers==1)
assert(#GameEvents.UnitPillageGold.handlers==1)
assert(#GameEvents.ResolutionResult.handlers==1)
assert(F.GetPoints(0)==0)
F.ChangeFilth(Players[1].cityList[1],1,0)
local level,distorted=F.GetFilth(Players[1].cityList[1])
assert(level==1 and not distorted and F.GetPoints(0)==2,'Filth gain or +2 FP failed')
F.ChangePoints(0,100)
local ok=F.UseDistortion(0,1,2); assert(ok and F.GetCooldown(0,'DISTORTION')==10)
level,distorted=F.GetFilth(Players[1].cityList[1]); assert(level==1 and distorted,'distorted building not selected')
ok=F.UseRavioli(0,1,2,'GOLD'); assert(ok,'Ravioli activation failed')
assert(Players[0].gold==225 and Players[1].gold==175 and F.GetPoints(0)==2,'Ravioli transfer/cost incorrect')
F.ChangePoints(0,25); ok=F.UseSalamander(0); assert(ok,'Salamander summon failed')
local salamander=Players[0].unitList[1]; assert(salamander:GetUnitType()==4 and F.GetUnitState(salamander).salUntil==17)

local peace=NewUnit(0,3,1,1,true,100); Players[0].unitList[#Players[0].unitList+1]=peace
local victim=NewUnit(1,90,2,1,true,25); Players[1].unitList[#Players[1].unitList+1]=victim
local targets=F.GetInterventionTargets(0); assert(#targets==1,'eligible Intervention target missing')
ok=F.UseIntervention(0,peace:GetID(),1,victim:GetID()); assert(ok and F.GetUnitState(peace).intervention==1)
assert(F.GetPoints(0)==12,'Intervention did not award 10 FP')

local enemy=NewUnit(1,91,3,1,true,100); Players[1].unitList[#Players[1].unitList+1]=enemy
F.ChangePoints(0,80); ok=F.UseStop(0); assert(ok,'Stop activation failed')
assert(enemy:GetMoves()==0 and enemy:IsHasPromotion(26),'Stop did not exhaust/suppress enemy')
assert(F.GetCooldown(0,'STOP')==20,'Stop cooldown incorrect')
local returned=GameEvents.UnitPillageGold.handlers[1](0,peace:GetID(),5,40)
assert(returned==40,'pillage hook changed base gold reward')
''')
    print("PASS Filthy Lua mock: Filth, points, distortion, Ravioli, Salamander, Intervention, Stop, pillage")


if __name__ == "__main__":
    main()
