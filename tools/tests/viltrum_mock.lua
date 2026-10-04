Saved={};MapModData={};T=0;RNGCalls=0
GameInfoTypes={CIVILIZATION_VILTRUM=100,UNIT_VILTRUM_WARRIOR=200,BUILDING_VILTRUM_COMPLEX=300,
 TECH_REPLACEABLE_PARTS=10,ERA_MEDIEVAL=2,UNIT_GREAT_GENERAL=201,UNIT_INFANTRY=202,PROMOTION_BLITZ=450,
 UNIT_RIFLEMAN=203,UNIT_MUSKETMAN=204,UNIT_LONGSWORDSMAN=205,UNIT_SWORDSMAN=206,UNIT_WARRIOR=207}
for i,n in ipairs({'BLOODLINE','FLIGHT','EXECUTION','PLANETBREAKER','EXECUTION_ACTIVE','PLANET_ACTIVE',
 'MOMENTUM','CONDITIONING','CONDITION_ACTIVE','HARDENED','PUREBLOOD','PURE_ACTIVE','GENOME','WARNING','QUARANTINE','NO_HEAL'}) do GameInfoTypes['PROMOTION_VILTRUM_'..n]=400+i end
for i,n in ipairs({'GARRISON','MOMENTUM','PURGE','QUARANTINE','DYING','RECOVERY','HAPPY'}) do GameInfoTypes['BUILDING_VILTRUM_'..n]=500+i end
for i,n in ipairs({'PURGE_GROWTH','QUARANTINE','DYING','RECOVERY_A','RECOVERY_B','ILLUSION'}) do GameInfoTypes['POLICY_VILTRUM_'..n]=600+i end
Modding={OpenSaveData=function()return{GetValue=function(k)return Saved[k]end,SetValue=function(k,v)Saved[k]=v end}end}
GameDefines={MAX_MAJOR_CIVS=4,BARBARIAN_PLAYER=63};DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
UnitAITypes={UNITAI_ATTACK=1,UNITAI_GENERAL=2};NotificationTypes={NOTIFICATION_GENERIC=1}
Game={GetGameTurn=function()return T end,GetGameSpeedType=function()return 0 end,GetActivePlayer=function()return 0 end,
 IsNetworkMultiPlayer=function()return false end,Rand=function(n,label)RNGCalls=RNGCalls+1;return RNGCalls%n end}
GameInfo={GameSpeeds={[0]={TrainPercent=100,CulturePercent=100}},Units={}}
for _,n in ipairs({'UNIT_INFANTRY','UNIT_RIFLEMAN','UNIT_MUSKETMAN','UNIT_LONGSWORDSMAN','UNIT_SWORDSMAN','UNIT_WARRIOR'})do
 local i=GameInfoTypes[n];GameInfo.Units[i]={ID=i,Type=n}
end
GameInfo.Units[208]={ID=208,Found=1};GameInfo.Units[209]={ID=209,Trade=1}
function resetEvents()
 GameEvents={};LuaEvents={}
 for _,n in ipairs({'PlayerDoTurn','UnitCreated','CityTrained','CityConstructed','CityCaptureComplete','BattleStarted','BattleJoined',
 'BattleFinished','DeclareWar','MakePeace','UnitSetXY','CityCanTrain','PlayerCanMakePeace','ParadropAt','UnitUpgraded','TeamTechResearched'})do
  local handlers={};GameEvents[n]={Add=function(f)handlers[#handlers+1]=f end,
   Fire=function(...)for _,f in ipairs(handlers)do f(...) end end,handlers=handlers}
 end
 LuaEvents.ViltrumChanged=function()end
end
resetEvents()
local function iter(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys);local i=0
 return function()i=i+1;return t[keys[i]]end
end
Plots={}
function plot(x,y,owner)
 local k=x..':'..y;local p=Plots[k]
 if p then return p end
 p={x=x,y=y,owner=owner or -1,units={}};Plots[k]=p
 function p:GetX()return self.x end;function p:GetY()return self.y end
 function p:GetOwner()return self.owner end;function p:GetTeam()return self.owner end
 function p:IsFriendlyTerritory(pid)return self.owner==pid end
 function p:GetPlotCity()return self.city end;function p:IsCity()return self.city~=nil end
 function p:IsWater()return self.water or false end;function p:IsMountain()return self.mountain or false end
 function p:IsImpassable()return self.impassable or false end;function p:GetNumUnits()return #self.units end
 return p
end
Map={GetPlot=function(x,y)return Plots[x..':'..y]end,GetNumPlots=function()return 10 end,
 GetPlotByIndex=function(i)return plot(i,1,-1)end,PlotDistance=function(x,y,a,b)return math.max(math.abs(x-a),math.abs(y-b))end}
Teams={}
for i=0,3 do Teams[i]={tech={},war={},permanent={}};Teams[i].IsHasTech=function(self,t)return self.tech[t] or false end;Teams[i].IsAtWar=function(self,t)return self.war[t] or false end;Teams[i].IsPermanentWarPeace=function(self,t)return self.permanent[t] or false end;Teams[i].SetPermanentWarPeace=function(self,t,b)self.permanent[t]=b end end
Players={}
function newPlayer(pid,civ,human)
 local p={pid=pid,civ=civ,human=human,alive=true,cities={},units={},policies={},notifications={},era=0,gold=1000,income=40,happy=5,culture=0,general=0,ga=0}
 Players[pid]=p
 function p:GetCivilizationType()return self.civ end;function p:GetTeam()return self.pid end
 function p:IsAlive()return self.alive end;function p:IsHuman()return self.human end;function p:IsBarbarian()return self.pid==63 end
 function p:Cities()return iter(self.cities)end;function p:Units()return iter(self.units)end
 function p:GetUnitByID(uid)return self.units[uid]end;function p:GetCityByID(cid)return self.cities[cid]end
 function p:GetCapitalCity()return self.capital end;function p:GetCurrentEra()return self.era end
 function p:GetNumCities()local n=0;for _ in self:Cities()do n=n+1 end;return n end
 function p:GetTotalPopulation()local n=0;for c in self:Cities()do n=n+c.pop end;return n end
 function p:HasPolicy(i)return self.policies[i] or false end;function p:SetHasPolicy(i,b)self.policies[i]=b end
 function p:GetExcessHappiness()return self.happy end;function p:GetNumMilitaryUnits()local n=0;for u in self:Units()do if u.combat then n=n+1 end end;return n end
 function p:GetMilitaryMight()return self:GetNumMilitaryUnits()*50 end
 function p:ChangeCombatExperience(n)self.general=self.general+n end;function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:GetGold()return self.gold end;function p:ChangeGold(n)self.gold=self.gold+n end;function p:CalculateGoldRate()return self.income end
 function p:GetGoldenAgeTurns()return self.ga end;function p:ChangeGoldenAgeTurns(n)self.ga=self.ga+n end
 function p:AddNotification(typ,body,title)self.notifications[#self.notifications+1]={body=body,title=title}end
 function p:InitUnit(typ,x,y,ai)local uid=1000;while self.units[uid]do uid=uid+1 end;return newUnit(self,uid,typ,true,x,y)end
 return p
end
function newCity(p,cid,pop,x,y,original)
 local c={cid=cid,owner=p.pid,pop=pop,x=x or cid*5,y=y or 0,original=original or p.pid,founded=T,buildings={},resistance=0,damage=0,originalCapital=false,strength=300}
 p.cities[cid]=c;local tile=plot(c.x,c.y,p.pid);tile.city=c
 if not p.capital then p.capital=c;c.originalCapital=true end
 function c:GetX()return self.x end;function c:GetY()return self.y end;function c:GetGameTurnFounded()return self.founded end
 function c:GetOriginalOwner()return self.original end;function c:GetID()return self.cid end
 function c:GetPopulation()return self.pop end;function c:ChangePopulation(n)self.pop=self.pop+n end;function c:SetPopulation(n)self.pop=n end
 function c:IsCapital()return Players[self.owner].capital==self end;function c:IsOriginalCapital()return self.originalCapital end
 function c:GetResistanceTurns()return self.resistance end;function c:ChangeResistanceTurns(n)self.resistance=math.max(0,self.resistance+n)end
 function c:IsHasBuilding(i)return (self.buildings[i] or 0)>0 end;function c:SetNumRealBuilding(i,n)self.buildings[i]=n end
 function c:GetGarrisonedUnit()return self.garrison end;function c:GetStrengthValue()return self.strength end
 function c:GetDamage()return self.damage end;function c:GetMaxHitPoints()return 200 end
 return c
end
function newUnit(p,uid,typ,combat,x,y)
 local u={uid=uid,owner=p.pid,typ=typ or 202,combat=combat~=false,domain=0,damage=0,xp=0,promotions={},tile=plot(x or 0,y or 0,p.pid)}
 p.units[uid]=u
 function u:GetID()return self.uid end;function u:GetOwner()return self.owner end;function u:GetUnitType()return self.typ end
 function u:IsCombatUnit()return self.combat end;function u:GetDomainType()return self.domain end;function u:GetDamage()return self.damage end
 function u:GetMaxHitPoints()return 100 end;function u:IsDelayedDeath()return self.dead or false end
 function u:SetDamage(n)self.damage=n end;function u:SetHasPromotion(i,b)self.promotions[i]=b end;function u:IsHasPromotion(i)return self.promotions[i] or false end
 function u:ChangeExperience(n)self.xp=self.xp+n end;function u:GetPlot()return self.tile end
 function u:Kill()self.dead=true;Players[self.owner].units[self.uid]=nil end
 function u:SetMadeAttack(b)self.madeAttack=b end;function u:RecallTrader(b)self.recalled=b end
 if typ==200 then for _,n in ipairs({'BLOODLINE','FLIGHT','EXECUTION','PLANETBREAKER'})do u.promotions[GameInfoTypes['PROMOTION_VILTRUM_'..n]]=true end end
 return u
end
P=newPlayer(0,100,true);Foreign=newPlayer(1,101,true);Barb=newPlayer(63,102,false)
function state(n,v,pid)Saved['VILTRUM:v1:'..(pid or 0)..':'..n]=v end
function reload()MapModData={};resetEvents();assert(loadstring(RuntimeSource))()end
