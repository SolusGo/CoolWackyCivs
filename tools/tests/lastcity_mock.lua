-- Stateful, strict mocks for the native contracts exercised by Last City.
TURN=0;ACTIVE=0;WORLD_ERA=0;SAVE_DATA={};PLOT_VISITS=0
function event()
 local e={handlers={}}
 function e.Add(fn) e.handlers[#e.handlers+1]=fn end
 function e.Fire(...) for _,fn in ipairs(e.handlers) do fn(...) end end
 function e.Test(...) for _,fn in ipairs(e.handlers) do if fn(...)==false then return false end end;return true end
 return setmetatable(e,{__call=function(_,...) e.Fire(...) end})
end
function resetEvents()
 local meta={__index=function(t,k) local v=event();rawset(t,k,v);return v end}
 GameEvents=setmetatable({},meta);Events=setmetatable({},meta);LuaEvents=setmetatable({},meta)
end
resetEvents();MapModData={}
Game={GetGameTurn=function() return TURN end,GetActivePlayer=function() return ACTIVE end,
 GetGameSpeedType=function() return 0 end,GetCurrentEra=function() return WORLD_ERA end,IsNetworkMultiPlayer=function() return false end}
GameDefines={MAX_MAJOR_CIVS=22,BARBARIAN_PLAYER=63}
Modding={OpenSaveData=function() return {GetValue=function(k) return SAVE_DATA[k] end,SetValue=function(k,v) SAVE_DATA[k]=v end} end}
Locale={ConvertTextKey=function(k,...)
 local v=Translations[k] or k;local args={...}
 return (v:gsub('{(%d+)_[^}]+}',function(i) return tostring(args[tonumber(i)] or '') end))
end}
NotificationTypes={NOTIFICATION_GENERIC=1};DirectionTypes={DIRECTION_NORTH=0}
UnitAITypes={UNITAI_ATTACK=1,UNITAI_ATTACK_SEA=2,UNITAI_DEFENSE=3}
OrderTypes={ORDER_TRAIN=0,ORDER_CONSTRUCT=1};DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
MissionTypes={MISSION_MOVE_TO=1}
function dbTable(records)
 local t={};for _,row in ipairs(records) do if row.ID then t[row.ID]=row end;if row.Type then t[row.Type]=row end end
 return setmetatable(t,{__call=function(_,filter)
  local i=0
  return function()
   while i<#records do i=i+1;local row=records[i];local match=true
    if type(filter)=='table' then for k,v in pairs(filter) do if row[k]~=v then match=false end end end
    if match then return row end
   end
  end
 end})
end
function dist(x,y,a,b) local dx,dy=x-a,y-b;return math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy)) end
PLOTS={}
function plot(x,y)
 local key=x..':'..y;if PLOTS[key] then return PLOTS[key] end
 local p={x=x,y=y,owner=-1,water=false,mountain=false,impassable=false,improvement=-1,feature=-1,pillaged=false,index=(x+40)*100+y+40}
 function p:GetX() return self.x end;function p:GetY() return self.y end
 function p:GetPlotIndex() return self.index end;function p:GetOwner() return self.owner end
 function p:IsWater() return self.water end;function p:IsMountain() return self.mountain end
 function p:IsImpassable() return self.impassable end;function p:IsCity() return self.city~=nil end
 function p:GetPlotCity() return self.city end;function p:GetFeatureType() return self.feature end
 function p:GetImprovementType() return self.improvement end;function p:IsImprovementPillaged() return self.pillaged end
 function p:GetNumUnits()
  local n=0;for _,owner in pairs(Players) do for _,u in pairs(owner.units) do if u.x==self.x and u.y==self.y then n=n+1 end end end;return n
 end
 PLOTS[key]=p;return p
end
local directions={{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
Map={GetPlot=plot,PlotDistance=dist,
 PlotXYWithRangeCheck=function(x,y,dx,dy,r)
  PLOT_VISITS=PLOT_VISITS+1;if dist(x,y,x+dx,y+dy)<=r then return plot(x+dx,y+dy) end
 end,
 PlotDirection=function(x,y,d) return plot(x+directions[d+1][1],y+directions[d+1][2]) end}
function ordered(t)
 local ids={};for k in pairs(t) do ids[#ids+1]=k end;table.sort(ids);local i=0
 return function() i=i+1;return ids[i] and t[ids[i]] end
end
function newPlayer(pid,civ,human)
 local p={id=pid,civ=civ,human=human~=false,alive=true,units={},cities={},nextUnit=0,era=0,handicap=3,notifications={},wars={}}
 function p:GetCivilizationType() return self.civ end;function p:IsHuman() return self.human end
 function p:GetScriptData() return self.data or '' end;function p:SetScriptData(v) self.data=v end
 function p:IsAlive() return self.alive end;function p:IsBarbarian() return self.id==63 end
 function p:IsTurnActive() return true end;function p:GetCurrentEra() return self.era end
 function p:GetTeam() return self.id end;function p:GetHandicapType() return self.handicap end
 function p:Units() return ordered(self.units) end;function p:Cities() return ordered(self.cities) end
 function p:GetCapitalCity() return self.cities[0] end;function p:GetCityByID(id) return self.cities[id] end
 function p:GetUnitByID(id) return self.units[id] end;function p:GetNumCities() local n=0;for _ in pairs(self.cities) do n=n+1 end;return n end
 function p:AddNotification(...) self.notifications[#self.notifications+1]={...} end
 function p:KillCities() local cities={};for c in self:Cities() do cities[#cities+1]=c end;for _,c in ipairs(cities) do c:Kill() end end
 function p:KillUnits() local units={};for u in self:Units() do units[#units+1]=u end;for _,u in ipairs(units) do u:Kill(false,-1) end end
 function p:InitUnit(kind,x,y,ai,direction)
  if FAIL_UNITS then return end
  assert(kind and GameInfo.Units[kind],'Invalid unit type')
  local u=newUnit(self.id,self.nextUnit,kind,x,y);self.units[u.id]=u;self.nextUnit=self.nextUnit+1
  u.ai=ai;GameEvents.UnitCreated.Fire(self.id,u.id,kind,x,y);return u
 end
 function p:AcquireCity(c,conquest,gift)
  local old=c.owner;Players[old].cities[c.id]=nil;c.previous=old;c.owner=self.id
  if self.cities[c.id] then c.id=100+c.id end;self.cities[c.id]=c;plot(c.x,c.y).owner=self.id
  GameEvents.CityCaptureComplete.Fire(old,false,c.x,c.y,self.id,c.population,conquest)
 end
 return p
end
function newUnit(owner,id,kind,x,y)
 local def=GameInfo.Units[kind];local u={owner=owner,id=id,kind=kind,x=x,y=y,created=TURN,data='',promos={},name='',damage=0}
 function u:GetOwner() return self.owner end;function u:GetID() return self.id end
 function u:GetUnitType() return self.kind end;function u:GetX() return self.x end;function u:GetY() return self.y end
 function u:GetGameTurnCreated() return self.created end;function u:GetScriptData() return self.data end
 function u:SetScriptData(v) self.data=v end;function u:SetName(v) self.name=v end
 function u:IsCombatUnit() return (def.Combat or 0)>0 end
 function u:IsHasPromotion(id) return self.promos[id] or false end
 function u:SetHasPromotion(id,v) assert(id,'Invalid promotion');self.promos[id]=v end
 function u:Kill(delay,killer)
  GameEvents.UnitPrekill.Fire(self.owner,self.id,self.kind,self.x,self.y,delay,killer)
  Players[self.owner].units[self.id]=nil
 end
 function u:Move(x,y) self.x=x;self.y=y;GameEvents.UnitSetXY.Fire(self.owner,self.id,x,y) end
 function u:PushMission(kind,x,y,flags,append,manual)
  assert(type(append)=='number' and type(manual)=='number')
  self.mission={kind=kind,x=x,y=y}
 end
 for row in GameInfo.Unit_FreePromotions{UnitType=def.Type} do u.promos[GameInfoTypes[row.PromotionType]]=true end
 return u
end
function newCity(owner,id,x,y)
 local c={owner=owner,id=id,x=x,y=y,founded=TURN,population=1,buildings={},food=30,surplus=4,damage=0,production=30,
  productionUnit=-1,productionBuilding=-1,productionProject=-1,productionProcess=-1,original=owner,previous=-1,puppet=false,plots={}}
 function c:GetX() return self.x end;function c:GetY() return self.y end;function c:GetID() return self.id end
 function c:GetOwner() return self.owner end;function c:GetGameTurnFounded() return self.founded end
 function c:SetName(v) self.name=v end;function c:GetPopulation() return self.population end
 function c:ChangePopulation(v) self.population=self.population+v;assert(self.population>=1) end
 function c:GetNumRealBuilding(id) assert(id,'Invalid building');return self.buildings[id] or 0 end
 function c:SetNumRealBuilding(id,n) assert(id and n>=0);self.buildings[id]=n end
 function c:GetNumCityPlots() return #self.plots end;function c:GetCityIndexPlot(i) return self.plots[i+1] end
 function c:FoodDifference() return self.surplus end;function c:GetFood() return self.food end
 function c:FoodDifferenceTimes100() return math.floor(self.surplus*100+.5) end
 function c:ChangeFood(v) self.food=self.food+v;assert(self.food>=0) end
 function c:GetDamage() return self.damage end;function c:SetDamage(v) self.damage=v end
 function c:GetMaxHitPoints() return 200 end
 function c:Kill() Players[self.owner].cities[self.id]=nil;plot(self.x,self.y).city=nil;self.killed=true end
 function c:GetProduction() return self.production end;function c:ChangeProduction(v) self.production=self.production+v;assert(self.production>=0) end
 function c:GetBuildingProductionNeeded(id) return math.floor(GameInfo.Buildings[id].Cost*(GameInfo.GameSpeeds[0].ConstructPercent or GameInfo.GameSpeeds[0].TrainPercent)/100+.5) end
 function c:GetProductionUnit() return self.productionUnit end;function c:GetProductionBuilding() return self.productionBuilding end
 function c:GetProductionProject() return self.productionProject end;function c:GetProductionProcess() return self.productionProcess end
 function c:CanConstruct(id) return self:GetNumRealBuilding(id)==0 and GameEvents.CityCanConstruct.Test(self.owner,self.id,id) end
 function c:CanTrain(id) return GameEvents.PlayerCanTrain.Test(self.owner,id) end
 function c:PushOrder(order,kind,ai,save,pop,append,rush)
  assert(type(save)=='number' and type(rush)=='number','Native Lua PushOrder requires integer save/rush parameters')
  self.lastOrder={order=order,kind=kind,ai=ai};self.productionUnit=-1;self.productionBuilding=-1
  if order==OrderTypes.ORDER_TRAIN then self.productionUnit=kind else self.productionBuilding=kind end
 end
 function c:GetOriginalOwner() return self.original end;function c:GetPreviousOwner() return self.previous end
 function c:IsPuppet() return self.puppet end;function c:SetPuppet(v) self.puppet=v end
 for dx=-3,3 do for dy=-3,3 do if dist(x,y,x+dx,y+dy)<=3 then local p=plot(x+dx,y+dy);p.owner=owner;c.plots[#c.plots+1]=p end end end
 local p=plot(x,y);p.city=c;p.owner=owner;return c
end
function setup()
 Players={};Teams={}
 for pid=0,21 do
  Players[pid]=newPlayer(pid,pid==0 and GameInfoTypes.CIVILIZATION_LAST_CITY or GameInfoTypes.CIVILIZATION_AMERICA)
 end
 Players[63]=newPlayer(63,-1,false)
 for pid,p in pairs(Players) do
  Teams[pid]={techs={},IsHasTech=function(self,id) return self.techs[id] or false end,IsAtWar=function(self,id) return p.wars[id] or false end}
 end
 Players[0].cities[0]=newCity(0,0,0,0)
 Players[0]:InitUnit(GameInfoTypes.UNIT_LC_LAST_WATCH,1,0,3,0)
end
function advance(n)
 for _=1,n do TURN=TURN+1;GameEvents.PlayerDoTurn.Fire(0) end
end
function defeatWave()
 local L=MapModData.TheLastCity;local w=L.State(0).wave;assert(w and w.spawned>0)
 for _,r in ipairs(w.units) do local u=L.Unit(r);if u then u:Kill(true,0) end end
 L.InvasionTurn(L.State(0));L.Changed(L.State(0))
end
function grantTechs() for row in GameInfo.Technologies() do Teams[0].techs[row.ID]=true end end
