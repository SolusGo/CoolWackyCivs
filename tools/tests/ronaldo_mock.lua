-- Deterministic CP-shaped model. Production handlers are loaded unchanged.
Saved={};CurrentTurn=0;ActivePlayer=0
MapModData={}
Modding={OpenSaveData=function()return {
 GetValue=function(k)return Saved[k]end,SetValue=function(k,v)Saved[k]=v end}end}
Game={GetGameSpeedType=function()return TestSpeed end,GetGameTurn=function()return CurrentTurn end,
 GetActivePlayer=function()return ActivePlayer end}
GameDefines={MAX_MAJOR_CIVS=2,MOVE_DENOMINATOR=60}
local function event()
 local e={handlers={}}
 e.Add=function(f)e.handlers[#e.handlers+1]=f end
 return setmetatable(e,{__call=function(self,...)for _,f in ipairs(self.handlers)do f(...)end end})
end
function ResetRuntimeEvents()
 GameEvents=setmetatable({},{__index=function(t,k)local e=event();rawset(t,k,e);return e end})
 LuaEvents=setmetatable({},{__index=function(t,k)local e=event();rawset(t,k,e);return e end})
end
ResetRuntimeEvents()
Plots={}
local function plot(x,y)
 local key=x..','..y
 if not Plots[key] then
  local p={x=x,y=y,area=1,owner=0,open=true}
  function p:GetPlotCity()return self.city end
  function p:GetArea()return self.area end
  function p:GetOwner()return self.owner end
  function p:IsOpenGround()return self.open end
  Plots[key]=p
 end
 return Plots[key]
end
Map={GetPlot=plot,PlotDistance=function(x,y,a,b)return math.max(math.abs(x-a),math.abs(y-b))end}
Teams={}
for p=0,1 do
 local team={techs={}}
 function team:IsHasTech(id)return self.techs[id]or false end
 Teams[p]=team
end
Players={}
local function iterator(items)
 local ids={};for id in pairs(items)do ids[#ids+1]=id end;table.sort(ids)
 local n=0;return function()n=n+1;return items[ids[n]]end
end
for p=0,1 do
 local player={id=p,era=0,units={},cities={},policies={},culture=0,gap=0,golden=0,freePolicies=0,gold=0,
  generalThreshold=0,admiralThreshold=0}
 function player:IsAlive()return true end
 function player:GetCivilizationType()return self.id==0 and GameInfoTypes.CIVILIZATION_RELENTLESS_SEVEN or -1 end
 function player:GetTeam()return self.id end
 function player:GetCurrentEra()return self.era end
 function player:IsHuman()return self.id==0 end
 function player:Units()return iterator(self.units)end
 function player:Cities()return iterator(self.cities)end
 function player:GetUnitByID(id)return self.units[id]end
 function player:GetCityByID(id)return self.cities[id]end
 function player:GetCapitalCity()return self.cities[1]end
 function player:IsGoldenAge()return self.golden>0 end
 function player:SetHasPolicy(id,value)self.policies[id]=value end
 function player:HasPolicy(id)return self.policies[id]or false end
 function player:ChangeGoldenAgeTurns(n)
  local start=self.golden==0;self.golden=self.golden+n
  if start then GameEvents.PlayerGoldenAge(self.id,true,n)end
 end
 function player:GetNumFreePolicies()return self.freePolicies end
 function player:SetNumFreePolicies(n)self.freePolicies=n end
 function player:ChangeJONSCulture(n)self.culture=self.culture+n end
 function player:ChangeGoldenAgeProgressMeter(n)self.gap=self.gap+n end
 function player:ChangeGold(n)self.gold=self.gold+n end
 function player:GetGreatGeneralsThresholdModifier()return self.generalThreshold end
 function player:GetGreatAdmiralsThresholdModifier()return self.admiralThreshold end
 Players[p]=player
end
function NewCity(p,id,x,y,area)
 local c={owner=p,id=id,x=x,y=y,founded=CurrentTurn,buildings={},production=0,culture=0,population=1,wltkd=0}
 local cp=plot(x,y);cp.city=c;cp.area=area or 1;cp.owner=p
 function c:GetX()return self.x end;function c:GetY()return self.y end
 function c:GetID()return self.id end
 function c:GetOwner()return self.owner end;function c:GetGameTurnFounded()return self.founded end
 function c:GetOriginalOwner()return self.originalOwner or self.owner end
 function c:IsOriginalCapital()return self.originalCapital or false end
 function c:GetPopulation()return self.population end
 function c:IsCapital()return self.id==1 end
 function c:Plot()return cp end
 function c:GetNumRealBuilding(id)return self.buildings[id]or 0 end
 function c:SetNumRealBuilding(id,n)self.buildings[id]=n end
 function c:IsHasBuilding(id)return self:GetNumRealBuilding(id)>0 end
 function c:CanConstruct(id,cont,visible,ignore)
  assert(type(cont)=='number' and type(visible)=='number' and type(ignore)=='number','CP construct flags must be integers')
  return self.allowConstruct~=false
 end
 function c:ChangeProduction(n)self.production=self.production+n end
 function c:ChangeJONSCultureStored(n)self.culture=self.culture+n end
 function c:ChangeWeLoveTheKingDayCounter(n)self.wltkd=self.wltkd+n end
 function c:GetUnitPurchaseCost(id)return 200 end
 Players[p].cities[id]=c;return c
end
function NewUnit(p,id,typ,x,y,level)
 local u={owner=p,id=id,typ=GameInfoTypes[typ],x=x or 0,y=y or 0,level=level or 1,
  promotions={},damage=0,xp100=0,moves=0,attacks=1}
 function u:GetOwner()return self.owner end;function u:GetID()return self.id end
 function u:GetUnitType()return self.typ end
 function u:GetX()return self.x end;function u:GetY()return self.y end
 function u:GetPlot()return plot(self.x,self.y)end
 function u:GetLevel()return self.level end
 function u:IsHasPromotion(id)return self.promotions[id]or false end
 function u:SetHasPromotion(id,value)self.promotions[id]=value end
 function u:IsDead()return self.dead or self.damage>=100 end
 function u:GetDamage()return self.damage end
 function u:SetDamage(n)self.damage=n end
 function u:GetMaxHitPoints()return 100 end
 function u:ChangeExperience(n,maxXP,combat,borders,global)
  assert(type(combat)=='number' and type(borders)=='number' and type(global)=='number','CP flags must be integers')
  self.xp100=self.xp100+n*100
 end
 function u:GetExperienceTimes100()return self.xp100 end
 function u:SetExperienceTimes100(n)self.xp100=n end
 function u:ChangeMoves(n)self.moves=self.moves+n end
 Players[p].units[id]=u
 for _,r in ipairs(FreePromotions)do
  if r.UnitType==typ then u:SetHasPromotion(GameInfoTypes[r.PromotionType],true)end
 end
 GameEvents.UnitCreated(p,id,u.typ,u.x,u.y)
 return u
end
function Upgrade(old,newID,typ)
 local new=NewUnit(old.owner,newID,typ,old.x,old.y,old.level)
 GameEvents.UnitUpgraded(old.owner,old.id,newID,false)
 -- CP performs normal copying after UnitUpgraded and before UnitConverted.
 for id,value in pairs(old.promotions)do
  if value and GameInfo.UnitPromotions[id].LostWithUpgrade~=1 then new.promotions[id]=true end
 end
 new.damage=old.damage;new.xp100=math.min(old.xp100,1000)
 GameEvents.UnitConverted(old.owner,old.owner,old.id,newID,true)
 Players[old.owner].units[old.id]=nil
 return new
end
function Kill(attacker,victim,repeatCallback)
 GameEvents.BattleStarted(0,victim.x,victim.y)
 GameEvents.CombatResult(attacker.owner,attacker.id,1,0,100,victim.owner,victim.id,1,100,100,-1,-1,0,victim.x,victim.y)
 GameEvents.UnitPrekill(victim.owner,victim.id,victim.typ,victim.x,victim.y,true,attacker.owner)
 if repeatCallback then GameEvents.UnitPrekill(victim.owner,victim.id,victim.typ,victim.x,victim.y,false,attacker.owner)end
 GameEvents.BattleFinished()
 Players[victim.owner].units[victim.id]=nil
end
function Promote(u,id)
 u.level=u.level+1;u.promotions[id]=true
 GameEvents.UnitPromoted(u.owner,u.id,id)
end
function Ambition()return MapModData.CR7.GetUIState(0).ambition end
function Has(u,name)return u:IsHasPromotion(GameInfoTypes['PROMOTION_CR7_'..name])end
function Equal(actual,expected,message)
 assert(actual==expected,(message or 'mismatch')..': expected '..tostring(expected)..', got '..tostring(actual))
end
