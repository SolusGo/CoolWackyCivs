-- CP v151 native ordering: UnitCreated precedes GP count increment; produce()
-- increments ThingsProduced and retains the head through CityConstructed.
MapModData={}
Saved={};Modding={OpenSaveData=function()return {
    GetValue=function(k)return Saved[k]end,SetValue=function(k,v)Saved[k]=v end}end}
GameInfoTypes={CIVILIZATION_BOY_TOUCHED_PARADISE=1,CIVILIZATION_ETERNAL_NUMBER_TEN=2,
 UNIT_PARADISE_EL_DIEZ=10,BUILDING_PARADISE_POTRERO=20,BUILDING_PARADISE_LAST_DANCE=21,
 ERA_RENAISSANCE=3,ERA_INDUSTRIAL=4,ERA_MODERN=5,YIELD_SCIENCE=3,YIELD_CULTURE=4,
 UNITCLASS_SCIENTIST=100,UNITCLASS_WRITER=101,UNITCLASS_GREAT_GENERAL=102,UNITCLASS_GREAT_ADMIRAL=103,
 UNITCLASS_ENGINEER=106,UNITCLASS_MERCHANT=107,UNITCLASS_ARTIST=104,UNITCLASS_MUSICIAN=105}
for n,name in ipairs({'PRESENCE','CAPITAL','PRESSURE_5','PRESSURE_10','HOPE','MEMORIAL','FULFILLED'})do
 GameInfoTypes['BUILDING_PARADISE_'..name]=29+n
end
GameDefines={MAX_MAJOR_CIVS=2,MAX_CIV_PLAYERS=6,GREAT_GENERALS_THRESHOLD_INCREASE=50,GREAT_GENERALS_THRESHOLD_INCREASE_TEAM=50}
UnitAITypes={UNITAI_WORKER=1};OrderTypes={ORDER_CONSTRUCT=1}
NotificationTypes={NOTIFICATION_GENERIC=1}
local currentTurn,speed,active=0,1,1
Game={GetGameTurn=function()return currentTurn end,GetGameSpeedType=function()return speed end,GetActivePlayer=function()return active end}
function SetTurn(n)currentTurn=n end
function SetSpeed(n)speed=n end
function SetActive(n)active=n end
function Event()
 local e={handlers={}}
 e.Add=function(f)e.handlers[#e.handlers+1]=f end
 return setmetatable(e,{__call=function(self,...)for _,f in ipairs(self.handlers)do f(...)end end})
end
function ResetEvents()
 GameEvents={}
 for _,name in ipairs({'PlayerDoTurn','PlayerCityFounded','UnitCreated','CityTrained','UnitPrekill','UnitCaptured',
  'UnitConverted','UnitSetXY','CityConstructed','CityCaptureComplete','PlayerGoldenAge','MinorAlliesChanged',
  'CityCanConstruct','PlayerCanTrain','PlayerCanGiftUnit','TeamTechResearched','GreatWorkCreated','CapitalChanged'})do GameEvents[name]=Event()end
 LuaEvents={ParadiseChanged=Event(),ParadiseStory=Event()}
end
ResetEvents()
local function info(rows)
 local t={}
 for _,r in ipairs(rows)do t[r.ID]=r;t[r.Type]=r end
 return setmetatable(t,{__call=function()local i=0;return function()i=i+1;return rows[i]end end})
end
GameInfo={
 GameSpeeds=info({{ID=0,Type='QUICK',TrainPercent=67,GoldenAgePercent=67},{ID=1,Type='STANDARD',TrainPercent=100,GoldenAgePercent=100},
  {ID=2,Type='EPIC',TrainPercent=150,GoldenAgePercent=150},{ID=3,Type='MARATHON',TrainPercent=300,GoldenAgePercent=300}}),
 Units=info({{ID=10,Type='UNIT_PARADISE_EL_DIEZ',Class='UNITCLASS_PARADISE_EL_DIEZ'},
  {ID=80,Type='UNIT_SCIENTIST',Class='UNITCLASS_SCIENTIST',Special='SPECIALUNIT_PEOPLE'},
  {ID=81,Type='UNIT_WRITER',Class='UNITCLASS_WRITER',Special='SPECIALUNIT_PEOPLE'},
  {ID=82,Type='UNIT_GREAT_GENERAL',Class='UNITCLASS_GREAT_GENERAL',Special='SPECIALUNIT_PEOPLE'},
  {ID=83,Type='UNIT_GREAT_ADMIRAL',Class='UNITCLASS_GREAT_ADMIRAL',Special='SPECIALUNIT_PEOPLE'},
  {ID=84,Type='UNIT_PROPHET',Class='UNITCLASS_PROPHET',Special='SPECIALUNIT_PEOPLE',FoundReligion=1},
  {ID=85,Type='UNIT_ENGINEER',Class='UNITCLASS_ENGINEER',Special='SPECIALUNIT_PEOPLE'},
  {ID=86,Type='UNIT_MERCHANT',Class='UNITCLASS_MERCHANT',Special='SPECIALUNIT_PEOPLE'},
  {ID=87,Type='UNIT_ARTIST',Class='UNITCLASS_ARTIST',Special='SPECIALUNIT_PEOPLE'},
  {ID=88,Type='UNIT_MUSICIAN',Class='UNITCLASS_MUSICIAN',Special='SPECIALUNIT_PEOPLE'}}),
 Buildings=info({{ID=20,Type='BUILDING_PARADISE_POTRERO',BuildingClass='BUILDINGCLASS_AMPHITHEATER',Cost=100},
  {ID=21,Type='BUILDING_PARADISE_LAST_DANCE',BuildingClass='BUILDINGCLASS_PARADISE_LAST_DANCE',Cost=450},
  {ID=22,Type='BUILDING_WONDER_A',BuildingClass='BUILDINGCLASS_WONDER_A',Cost=250},
  {ID=23,Type='BUILDING_WONDER_B',BuildingClass='BUILDINGCLASS_WONDER_B',Cost=250},
  {ID=24,Type='BUILDING_WONDER_C',BuildingClass='BUILDINGCLASS_WONDER_C',Cost=250},
  {ID=30,Type='BUILDING_PARADISE_PRESENCE',BuildingClass='BUILDINGCLASS_PARADISE_PRESENCE',Cost=-1}}),
 BuildingClasses=info({{ID=1,Type='BUILDINGCLASS_AMPHITHEATER',MaxGlobalInstances=-1},
  {ID=2,Type='BUILDINGCLASS_PARADISE_LAST_DANCE',MaxGlobalInstances=-1,MaxPlayerInstances=1},
  {ID=3,Type='BUILDINGCLASS_WONDER_A',MaxGlobalInstances=1},{ID=4,Type='BUILDINGCLASS_WONDER_B',MaxGlobalInstances=1},
  {ID=5,Type='BUILDINGCLASS_WONDER_C',MaxGlobalInstances=1}}),
 Eras=info({{ID=0,Type='ERA_ANCIENT',Description='Ancient'},{ID=3,Type='ERA_RENAISSANCE',Description='Renaissance'},
  {ID=4,Type='ERA_INDUSTRIAL',Description='Industrial'},{ID=5,Type='ERA_MODERN',Description='Modern'}})}
local plots={}
Map={GetPlot=function(x,y)return plots[x..','..y]end}
function Plot(x,y)
 local p={x=x,y=y,units={}}
 function p:GetPlotCity()return self.city end
 function p:GetNumUnits()return #self.units end
 function p:GetUnit(n)return self.units[n+1]end
 plots[x..','..y]=p;return p
end
function City(owner,id,x,y)
 local c={owner=owner,id=id,x=x,y=y,founded=currentTurn,buildings={},produced=0,order=-1,item=-1,thresholds={[100]=100,[101]=100},
 science=20,culture=12,wltkd=0,cultureStored=0}
 function c:GetOwner()return self.owner end
 function c:GetID()return self.id end
 function c:GetX()return self.x end;function c:GetY()return self.y end
 function c:GetGameTurnFounded()return self.founded end
 function c:GetName()return 'City '..self.id end
 function c:Plot()return Map.GetPlot(self.x,self.y)end
 function c:GetNumRealBuilding(i)return self.buildings[i] or 0 end
 function c:SetNumRealBuilding(i,n)self.buildings[i]=n end
 function c:IsHasBuilding(i)return self:GetNumRealBuilding(i)>0 end
 function c:GetNumThingsProduced()return self.produced end
 function c:GetOrderFromQueue(n)return self.order,self.item end
 function c:GetSpecialistUpgradeThreshold(i)
  -- CP's default Scientist/Engineer/Merchant pool is player-wide, not city-local.
  if i==106 or i==107 then i=100 end
  return Players[self.owner].thresholds[i] or 100
 end
 function c:GetYieldRateTimes100(i)return (i==3 and self.science or self.culture)*100 end
 function c:ChangeWeLoveTheKingDayCounter(n)self.wltkd=self.wltkd+n end
 function c:ChangeJONSCultureStored(n)self.cultureStored=self.cultureStored+n end
 local plot=Map.GetPlot(x,y)or Plot(x,y);plot.city=c
 return c
end
local nextID=0
function Unit(owner,typ,x,y)
 nextID=nextID+1
 local u={owner=owner,id=nextID,typ=typ,x=x,y=y,created=currentTurn,dead=false,delayed=false}
 function u:GetID()return self.id end
 function u:GetUnitType()return self.typ end
 function u:GetGameTurnCreated()return self.created end
 function u:GetX()return self.x end;function u:GetY()return self.y end
 function u:GetPlot()return Map.GetPlot(self.x,self.y)end
 function u:IsDead()return self.dead end
 function u:IsDelayedDeath()return self.delayed end
 function u:IsCombatUnit()return false end
 function u:SetNoMaintenance(v)self.noMaintenance=v end
 function u:SetName(v)self.name=v end
 function u:Kill(delay,killer)
  GameEvents.UnitPrekill(self.owner,self.id,self.typ,self.x,self.y,delay,killer)
  self.dead=true;self.delayed=delay
  local plot=self:GetPlot()
  for i=#plot.units,1,-1 do if plot.units[i]==self then table.remove(plot.units,i)end end
  Players[self.owner].unitList[self.id]=nil
 end
 local plot=Map.GetPlot(x,y)or Plot(x,y);plot.units[#plot.units+1]=u
 Players[owner].unitList[u.id]=u
 return u
end
function Move(u,c)
 local plot=u:GetPlot()
 for i=#plot.units,1,-1 do if plot.units[i]==u then table.remove(plot.units,i)end end
 u.x,u.y=c.x,c.y;c:Plot().units[#c:Plot().units+1]=u
 GameEvents.UnitSetXY(u.owner,u.id,u.x,u.y)
end
local function iterator(values)
 local keys={};for k in pairs(values)do keys[#keys+1]=k end;table.sort(keys)
 local n=0;return function()n=n+1;return values[keys[n]]end
end
Players={};Teams={}
for id=0,5 do
 local p={id=id,civ=id==1 and 1 or 2,team=id==1 and 7 or id,alive=true,human=id<2,era=0,cities={},unitList={},
  capital=1,thresholds={[100]=100,[101]=100},generals=0,admiralMod=0,prophetCost=200,research=1,
  science=0,culture=0,gap=0,ga=0,greatWorks=0,notifications={},friendship=0,permanentWar=false,met=true,war=false,turnActive=true,navalXP=0}
 function p:GetCivilizationType()return self.civ end
 function p:IsAlive()return self.alive end
 function p:IsHuman()return self.human end
 function p:IsMinorCiv()return self.id>=2 end
 function p:GetCurrentEra()return self.era end
 function p:GetTeam()return self.team end
 function p:IsTurnActive()return self.turnActive end
 function p:IsGoldenAge()return self.ga>0 end
 function p:GetCapitalCity()return self.cities[self.capital]end
 function p:GetCityByID(n)return self.cities[n]end
 function p:GetUnitByID(n)return self.unitList[n]end
 function p:Cities()return iterator(self.cities)end
 function p:Units()return iterator(self.unitList)end
 function p:InitUnit(typ,x,y,ai)
  local u=Unit(self.id,typ,x,y);GameEvents.UnitCreated(self.id,u.id,typ,x,y);return u
 end
 function p:AddNotification(kind,body,title,x,y)self.notifications[#self.notifications+1]=body end
 function p:GetNumGreatWorks()return self.greatWorks end
 function p:ChangeGoldenAgeProgressMeter(n)self.gap=self.gap+n end
 function p:ChangeGoldenAgeTurns(n)self.ga=self.ga+n;GameEvents.PlayerGoldenAge(self.id,true,n)end
 function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:GetCurrentResearch()return self.research end
 function p:GetGreatGeneralsCreated(exclude)return self.generals end
 function p:GetGreatAdmiralsThresholdModifier()return self.admiralMod end
 function p:GetNavalCombatExperience()return self.navalXP end
 function p:GreatAdmiralThreshold()return 100 end
 function p:GetMinimumFaithNextGreatProphet()return self.prophetCost end
 function p:IsMinorPermanentWar(team)assert(team==7,'permanent-war API takes a team, not player ID');return self.permanentWar end
 function p:GetMinorCivFriendshipWithMajor(id)return self.friendship end
 function p:ChangeMinorCivFriendshipWithMajor(id,n)self.friendship=self.friendship+n end
 Players[id]=p
 local team={}
 function team:IsHasMet(other)return Players[other] and Players[other].met end
 function team:IsAtWar(other)return Players[other] and Players[other].war end
 function team:GetTeamTechs()return {ChangeResearchProgress=function(self,tech,n,id)Players[id].science=Players[id].science+n end}end
 Teams[p.team]=team
end
Players[1].cities[1]=City(1,1,3,3)
Players[1].cities[2]=City(1,2,5,3)
Players[0].cities[1]=City(0,1,1,1)
function NativeGP(typ,source,cityID,beforeIncrement)
 local p=Players[1]
 local c=cityID and p.cities[cityID] or p:GetCapitalCity()
 if typ==83 and source=='generated' then p.navalXP=100 end
 local u=p:InitUnit(typ,c.x,c.y)
 if beforeIncrement then beforeIncrement(u)end
 local class=typ==81 and 101 or typ==87 and 104 or typ==88 and 105 or 100
 if source=='generated' then
  if typ==82 then p.generals=p.generals+1 elseif typ==83 then p.admiralMod=p.admiralMod+100;p.navalXP=0
  elseif typ==84 then p.prophetCost=p.prophetCost+100
  else p.thresholds[class]=(p.thresholds[class] or 100)+100 end
 elseif source=='purchased' then
  if typ==84 then p.prophetCost=p.prophetCost+100 elseif typ==82 then p.generals=p.generals+1
  elseif typ==83 then p.admiralMod=p.admiralMod+100
  else p.thresholds[class]=(p.thresholds[class] or 100)+100 end
  GameEvents.CityTrained(1,c.id,u.id,false,true)
 elseif source=='free' and typ==83 then p.admiralMod=p.admiralMod+100
 end
 return u
end
function NativeConstruct(c,building,kind)
 c.order,c.item=1,building;c.buildings[building]=1
 if kind~='free' and kind~='purchased' then c.produced=c.produced+1 end
 GameEvents.CityConstructed(c.owner,c.id,building,kind=='purchased',false)
 c.order,c.item=-1,-1
end
function NextTurn(n)
 for _=1,(n or 1)do
  currentTurn=currentTurn+1
  for c in Players[1]:Cities()do if c:IsHasBuilding(30)then Players[1].gap=Players[1].gap+2 end end
  GameEvents.PlayerDoTurn(1)
 end
end
function GoldenStart()
 Players[1].ga=10;GameEvents.PlayerGoldenAge(1,true,10)
end
function GoldenEnd()
 Players[1].ga=0;GameEvents.PlayerGoldenAge(1,false,0)
end
function AdvanceEra(n)
 Players[1].era=n;GameEvents.TeamTechResearched(7,1,1)
end
function S()return MapModData.Paradise.GetUIState(1)end
function Hero()return Players[1]:GetUnitByID(S().heroID)end
function HeroCount()
 local n=0;for u in Players[1]:Units()do if u.typ==10 and not u.dead then n=n+1 end end;return n
end
