"""Focused deterministic checks for The Dual Order runtime."""
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
 CIVILIZATION_DUAL_ORDER=1, BUILDING_DUAL_ORDER_HALL_CONCORDANCE=11,
 BUILDING_DUAL_ORDER_MANDATE_YIELDS=100, BUILDING_DUAL_ORDER_GOLDEN_ARMAMENT=101,
 BUILDING_DUAL_ORDER_HALL_HAPPINESS=102,
 PROMOTION_DUAL_ORDER_ZEAL=200, PROMOTION_DUAL_ORDER_ZEAL_ACTIVE=201,
 PROMOTION_DUAL_ORDER_SCHISM_STRIKE=202, PROMOTION_DUAL_ORDER_SCHISM_WOUNDED=203,
 PROMOTION_DUAL_ORDER_HOLY_SUPPORT=204,
}
for i=1,5 do
 GameInfoTypes['BUILDING_DUAL_ORDER_BALANCE_'..i]=109+i
 GameInfoTypes['PROMOTION_DUAL_ORDER_BALANCE_'..i]=209+i
end
GameDefines={MAX_MAJOR_CIVS=8,MAX_CIV_PLAYERS=8,MAX_HIT_POINTS=100}
DirectionTypes={NUM_DIRECTION_TYPES=6}
ReligionTypes={RELIGION_PANTHEON=0}
LuaEvents={DualOrderStateChanged=function() end}

local function event() local e={handlers={}}; e.Add=function(f)e.handlers[#e.handlers+1]=f end; return e end
GameEvents={}
for _,name in ipairs({'PlayerDoTurn','PlayerDoneTurn','CityTrained','CityConstructed','CityCaptureComplete',
 'UnitCreated','UnitPrekill','UnitSetXY','UnitConverted','UnitUpgraded','DeclareWar','MakePeace','ReligionFounded',
 'PlayerGoldenAge','BattleStarted','BattleJoined','BattleFinished'}) do GameEvents[name]=event() end

local function info(rows)
 local byID={}
 for _,row in ipairs(rows) do if row.ID then byID[row.ID]=row end end
 return setmetatable(byID,{__call=function()
  local i=0; return function() i=i+1; return rows[i] end
 end})
end
GameInfo={}
GameInfo.DualOrderBuildingRoles=info({
 {ID=1,BuildingClassType='BUILDINGCLASS_BARRACKS',RoleType='MANDATE'},
 {ID=2,BuildingClassType='BUILDINGCLASS_ARMORY',RoleType='MANDATE'},
 {ID=3,BuildingClassType='BUILDINGCLASS_TEMPLE',RoleType='MANDATE'},
 {ID=4,BuildingClassType='BUILDINGCLASS_BARRACKS',RoleType='MILITARY'},
 {ID=5,BuildingClassType='BUILDINGCLASS_ARMORY',RoleType='MILITARY'},
 {ID=6,BuildingClassType='BUILDINGCLASS_TEMPLE',RoleType='RELIGIOUS'},
})
GameInfo.Buildings=info({
 {ID=10,BuildingClass='BUILDINGCLASS_BARRACKS'},
 {ID=11,BuildingClass='BUILDINGCLASS_ARMORY'},
 {ID=12,BuildingClass='BUILDINGCLASS_TEMPLE'},
 {ID=13,BuildingClass='BUILDINGCLASS_BARRACKS'},
})
GameInfo.Units=info({
 {ID=50,Class='UNITCLASS_MISSIONARY',Combat=0,RangedCombat=0},
 {ID=60,Class='UNITCLASS_LONGSWORDSMAN',Combat=23,RangedCombat=0},
 {ID=61,Class='UNITCLASS_SWORDSMAN',Combat=14,RangedCombat=0},
})

local plots={}
local offsets={{1,0},{1,1},{0,1},{-1,0},{-1,-1},{0,-1}}
local function key(x,y)return x..':'..y end
function NewPlot(x,y,owner)
 local p={x=x,y=y,owner=owner or -1,units={}}
 function p:GetX()return self.x end; function p:GetY()return self.y end
 function p:GetOwner()return self.owner end; function p:GetNumUnits()return #self.units end
 function p:GetUnit(i)return self.units[i+1] end
 plots[key(x,y)]=p; return p
end
Map={}
function Map.GetPlot(x,y)return plots[key(x,y)] or NewPlot(x,y,0) end
function Map.PlotDirection(x,y,d)local o=offsets[d+1];return Map.GetPlot(x+o[1],y+o[2]) end

function NewCity(owner,id,x,y)
 local c={owner=owner,id=id,x=x,y=y,buildings={[10]=1,[11]=1,[12]=0,[13]=1},freeBuildings={[12]=1},religion=4}
 function c:GetOwner()return self.owner end; function c:GetID()return self.id end
 function c:GetNumRealBuilding(i)return self.buildings[i] or 0 end
 function c:IsHasBuilding(i)return (self.buildings[i] or 0)+(self.freeBuildings[i] or 0)>0 end
 function c:SetNumRealBuilding(i,n)self.buildings[i]=n end
 function c:GetReligiousMajority()return self.religion end
 return c
end

local nextUnit=0
function NewUnit(owner,kind,x,y,military,hp)
 nextUnit=nextUnit+1
 local u={owner=owner,id=nextUnit,kind=kind,x=x,y=y,military=military,hp=hp or 100,
  promotions={},xp=0,dead=false}
 function u:GetOwner()return self.owner end; function u:GetID()return self.id end
 function u:GetUnitType()return self.kind end; function u:GetX()return self.x end; function u:GetY()return self.y end
 function u:GetPlot()return Map.GetPlot(self.x,self.y) end
 function u:IsCombatUnit()return self.military end
 function u:IsHasPromotion(p)return self.promotions[p]==true end
 function u:SetHasPromotion(p,v)self.promotions[p]=v end
 function u:GetCurrHitPoints()return self.hp end; function u:GetMaxHitPoints()return 100 end
 function u:ChangeDamage(n)self.hp=math.max(0,math.min(100,self.hp-n)) end
 function u:ChangeExperience(n)self.xp=self.xp+n end
 Map.GetPlot(x,y).units[#Map.GetPlot(x,y).units+1]=u
 return u
end

function NewPlayer(id,civ,team)
 local p={id=id,civ=civ,team=team,alive=true,minor=false,barbarian=false,faith=5,faithTimes100=500,golden=true,
  religion=4,cityList={},unitList={},combatXP=0}
 function p:GetID()return self.id end; function p:IsAlive()return self.alive end
 function p:IsMinorCiv()return self.minor end; function p:IsBarbarian()return self.barbarian end
 function p:GetCivilizationType()return self.civ end; function p:GetTeam()return self.team end
 function p:GetTotalFaithPerTurn()return self.faith end
 function p:GetTotalFaithPerTurnTimes100()return self.faithTimes100 end
 function p:IsGoldenAge()return self.golden end
 function p:GetReligionCreatedByPlayer()return self.religion end
 function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id and not u.dead then return u end end end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:Units()local i=0;return function()repeat i=i+1 until not self.unitList[i] or not self.unitList[i].dead;return self.unitList[i]end end
 function p:ChangeCombatExperience(n)self.combatXP=self.combatXP+n end
 return p
end
Players={}
for i=0,7 do Players[i]=NewPlayer(i,i==0 and 1 or 99-i,i) end
Players[7].team=0
for i=3,6 do Players[i].alive=false end
Teams={}
for i=0,7 do Teams[i]={IsAtWar=function(_,t)return false end} end
Teams[0].IsAtWar=function(_,t)return t>=1 and t<=6 end
for i=1,6 do Teams[i].IsAtWar=function(_,t)return t==0 end end
local city=NewCity(0,1,0,0); Players[0].cityList={city}
local templar=NewUnit(0,60,0,0,true,90); templar:SetHasPromotion(202,true); Players[0].unitList={templar}
local missionary=NewUnit(0,50,1,0,false,100); Players[0].unitList[#Players[0].unitList+1]=missionary
local enemy=NewUnit(1,61,0,1,true,40); Players[1].unitList={enemy}
''')
    source = (REPO / "DualOrder/Lua/DualOrderRuntime.lua").read_text(encoding="utf-8-sig")
    lua.execute(source)
    lua.execute(source)  # Re-including the UI runtime must not duplicate event handlers.
    lua.execute(r'''
local D=MapModData.DualOrder
local city=Players[0].cityList[1]
local templar=Players[0].unitList[1]
local missionary=Players[0].unitList[2]
local enemy=Players[1].unitList[1]
assert(#GameEvents.PlayerDoTurn.handlers==1 and #GameEvents.BattleFinished.handlers==1
 and #GameEvents.UnitPrekill.handlers==1 and #GameEvents.UnitUpgraded.handlers==1,
 'runtime handlers were missing or duplicated')
local state=D.GetState(0)
assert(state.active and state.wars==2 and state.combat==4 and state.production==2)
assert(state.faithTimes100==500 and state.faith==5,'Faith state lost hundredth precision')
local mandates,military,religious=D.CityInfrastructure(city)
assert(mandates==3 and military and religious,'free or replacement infrastructure was not recognized')
assert(city.buildings[100]==3,'mandates did not count free buildings or double-counted one building class')
assert(city.buildings[111]==1,'two-war production tier missing')
assert(city.buildings[101]==1,'Golden Age military production dummy missing')
assert(city.buildings[102]==1,'founded-religion Hall happiness missing')
D.OnPlayerDoTurn(0); assert(Players[0].combatXP==1,'Hall did not add one Great General point')
D.OnCityTrained(0,1,templar:GetID(),false,false)
assert(templar:IsHasPromotion(200),'eligible trained unit did not receive Zeal')
assert(templar:IsHasPromotion(201),'Zeal territory condition not active')
assert(templar:IsHasPromotion(204),'religious adjacency bonus not active')
assert(templar:IsHasPromotion(211),'Balance Pressure combat tier missing')
assert(templar.xp==5,'Golden Age trained-unit XP missing')

local purchased=NewUnit(0,61,0,0,true,100); Players[0].unitList[#Players[0].unitList+1]=purchased
D.OnCityTrained(0,1,purchased:GetID(),true,false)
assert(not purchased:IsHasPromotion(200) and purchased.xp==0,'purchased unit incorrectly received training bonuses')

city.religion=5; D.RefreshPlayer(0)
assert(city.buildings[102]==0,'Hall happiness remained after the city changed religion')
city.religion=4; Players[0].golden=false; D.RefreshPlayer(0)
assert(city.buildings[102]==1 and city.buildings[101]==0,'religion or Golden Age dummy cleanup failed')
Players[0].golden=true; D.RefreshPlayer(0)

D.OnBattleStarted(0,0,0)
D.OnBattleJoined(0,templar:GetID(),0,false)
D.OnBattleJoined(1,enemy:GetID(),1,false)
assert(templar:IsHasPromotion(203),'Schism Strike did not recognize a below-half-health target')
D.OnUnitPrekill(1,enemy:GetID(),61,0,1,false,0)
D.OnBattleFinished()
assert(templar.hp==100,'Zeal did not heal 10 HP after a kill')
assert(not templar:IsHasPromotion(203),'temporary Schism Strike promotion leaked after battle')
enemy.dead=true

local airAttacker=NewUnit(1,61,0,1,true,100); Players[1].unitList[#Players[1].unitList+1]=airAttacker
templar.hp=90
D.OnBattleStarted(0,0,0)
D.OnBattleJoined(1,airAttacker:GetID(),0,false)
D.OnBattleJoined(0,templar:GetID(),2,false)
D.OnUnitPrekill(1,airAttacker:GetID(),61,0,1,false,0)
D.OnBattleFinished()
assert(templar.hp==100,'Zeal did not credit a role-2 interceptor kill')
airAttacker.dead=true

local exactHalf=NewUnit(1,61,0,1,true,50); Players[1].unitList[#Players[1].unitList+1]=exactHalf
D.OnBattleStarted(0,0,0)
D.OnBattleJoined(0,templar:GetID(),0,false)
D.OnBattleJoined(1,exactHalf:GetID(),1,false)
assert(not templar:IsHasPromotion(203),'Schism Strike activated at exactly 50 percent HP')
D.OnBattleFinished()

D.OnUnitPrekill(0,missionary:GetID(),50)
assert(not templar:IsHasPromotion(204),'Holy Support remained after its adjacent support was consumed')
missionary.dead=true
local replacementMissionary=NewUnit(0,50,1,0,false,100)
Players[0].unitList[#Players[0].unitList+1]=replacementMissionary
D.OnUnitCreated(0,replacementMissionary:GetID())
assert(templar:IsHasPromotion(204),'Holy Support did not refresh when adjacent support was created')

local upgraded=NewUnit(0,60,0,0,true,100)
upgraded:SetHasPromotion(200,true); upgraded:SetHasPromotion(202,true)
Players[0].unitList[#Players[0].unitList+1]=upgraded
GameEvents.UnitUpgraded.handlers[1](0,templar:GetID(),upgraded:GetID(),false)
assert(upgraded:IsHasPromotion(200) and upgraded:IsHasPromotion(201)
 and upgraded:IsHasPromotion(204),'upgrade did not preserve and refresh unique promotions')

local formerDual=NewUnit(1,61,3,3,true,100); formerDual:SetHasPromotion(211,true)
Players[1].unitList[#Players[1].unitList+1]=formerDual
D.OnUnitCreated(1,formerDual:GetID())
assert(not formerDual:IsHasPromotion(211),'Balance Pressure leaked onto a non-Dual-Order owner')

for i=3,6 do Players[i].alive=true end
D.RefreshPlayer(0); state=D.GetState(0)
assert(state.wars==5 and state.combat==10 and state.production==5,'six wars were not capped at five')
assert(city.buildings[114]==1 and templar:IsHasPromotion(214),'five-war Balance Pressure tier missing')
for i=3,6 do Players[i].alive=false end

Players[0].faith=0; Players[0].faithTimes100=1
D.RefreshPlayer(0); state=D.GetState(0)
assert(state.active and state.faith==0.01,'fractional positive Faith did not activate Balance Pressure')
Players[0].faithTimes100=0
D.RefreshPlayer(0)
state=D.GetState(0)
assert(not state.active and state.combat==0 and state.production==0,'zero Faith did not disable Balance Pressure')
assert(city.buildings[111]==0,'Balance Pressure production dummy remained active')
for i=1,5 do assert(not templar:IsHasPromotion(209+i),'Balance Pressure promotion remained active') end
Players[0].faithTimes100=-1; D.RefreshPlayer(0)
assert(not D.GetState(0).active,'negative Faith activated Balance Pressure')
print('PASS Dual Order runtime: free buildings, precise Faith gate, war cap, Golden Age, Hall, purchases, upgrades, adjacency, Zeal and Schism Strike')
''')


if __name__ == "__main__":
    main()
