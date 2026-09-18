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
GameDefines={MAX_MAJOR_CIVS=4,MAX_CIV_PLAYERS=4,MAX_HIT_POINTS=100}
DirectionTypes={NUM_DIRECTION_TYPES=6}
ReligionTypes={RELIGION_PANTHEON=0}
LuaEvents={DualOrderStateChanged=function() end}

local function event() local e={handlers={}}; e.Add=function(f)e.handlers[#e.handlers+1]=f end; return e end
GameEvents={}
for _,name in ipairs({'PlayerDoTurn','PlayerDoneTurn','CityTrained','CityConstructed','CityCaptureComplete',
 'UnitCreated','UnitSetXY','UnitConverted','UnitUpgraded','DeclareWar','MakePeace','ReligionFounded',
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
 local c={owner=owner,id=id,x=x,y=y,buildings={[10]=1,[11]=1,[12]=1},religion=4}
 function c:GetOwner()return self.owner end; function c:GetID()return self.id end
 function c:GetNumRealBuilding(i)return self.buildings[i] or 0 end
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
 local p={id=id,civ=civ,team=team,alive=true,minor=false,barbarian=false,faith=5,golden=true,
  religion=4,cityList={},unitList={},combatXP=0}
 function p:GetID()return self.id end; function p:IsAlive()return self.alive end
 function p:IsMinorCiv()return self.minor end; function p:IsBarbarian()return self.barbarian end
 function p:GetCivilizationType()return self.civ end; function p:GetTeam()return self.team end
 function p:GetTotalFaithPerTurn()return self.faith end; function p:IsGoldenAge()return self.golden end
 function p:GetReligionCreatedByPlayer()return self.religion end
 function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id and not u.dead then return u end end end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:Units()local i=0;return function()repeat i=i+1 until not self.unitList[i] or not self.unitList[i].dead;return self.unitList[i]end end
 function p:ChangeCombatExperience(n)self.combatXP=self.combatXP+n end
 return p
end
Players={[0]=NewPlayer(0,1,0),[1]=NewPlayer(1,99,1),[2]=NewPlayer(2,98,2),[3]=NewPlayer(3,97,3)}
Teams={
 [0]={IsAtWar=function(_,t)return t==1 or t==2 end},
 [1]={IsAtWar=function(_,t)return t==0 end},
 [2]={IsAtWar=function(_,t)return t==0 end},
 [3]={IsAtWar=function()return false end},
}
local city=NewCity(0,1,0,0); Players[0].cityList={city}
local templar=NewUnit(0,60,0,0,true,90); templar:SetHasPromotion(202,true); Players[0].unitList={templar}
local missionary=NewUnit(0,50,1,0,false,100); Players[0].unitList[#Players[0].unitList+1]=missionary
local enemy=NewUnit(1,61,0,1,true,40); Players[1].unitList={enemy}
''')
    lua.execute((REPO / "DualOrder/Lua/DualOrderRuntime.lua").read_text(encoding="utf-8-sig"))
    lua.execute(r'''
local D=MapModData.DualOrder
local city=Players[0].cityList[1]
local templar=Players[0].unitList[1]
local missionary=Players[0].unitList[2]
local enemy=Players[1].unitList[1]
assert(#GameEvents.PlayerDoTurn.handlers==1 and #GameEvents.BattleFinished.handlers==1)
local state=D.GetState(0)
assert(state.active and state.wars==2 and state.combat==4 and state.production==2)
assert(city.buildings[100]==3,'mandate building count did not include all three classes')
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

D.OnBattleStarted(0,0,0)
D.OnBattleJoined(0,templar:GetID(),0,false)
D.OnBattleJoined(1,enemy:GetID(),1,false)
assert(templar:IsHasPromotion(203),'Schism Strike did not recognize a below-half-health target')
enemy.dead=true
D.OnBattleFinished()
assert(templar.hp==100,'Zeal did not heal 10 HP after a kill')
assert(not templar:IsHasPromotion(203),'temporary Schism Strike promotion leaked after battle')

Players[0].faith=0
D.RefreshPlayer(0)
state=D.GetState(0)
assert(not state.active and state.combat==0 and state.production==0,'zero Faith did not disable Balance Pressure')
assert(city.buildings[111]==0,'Balance Pressure production dummy remained active')
for i=1,5 do assert(not templar:IsHasPromotion(209+i),'Balance Pressure promotion remained active') end
print('PASS Dual Order runtime: mandates, faith gate, war cap tiers, Golden Age, Hall, Zeal and Schism Strike')
''')


if __name__ == "__main__":
    main()
