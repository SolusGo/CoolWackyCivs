-- Strict, event-driven Civ V test double. Definitions come from the real CP database.
Saved=Saved or {};MapModData={};Turn=0;Active=0;Network=false;Plots={}
function event()
 local e={handlers={}};function e.Add(fn) e.handlers[#e.handlers+1]=fn end
 function e.Fire(...) local result=true;for _,fn in ipairs(e.handlers) do if fn(...)==false then result=false end end;return result end
 return setmetatable(e,{__call=function(_,...) return e.Fire(...) end})
end
function resetEvents()
 GameEvents={};Events={};LuaEvents={ImperialChanged=event(),ImperialRequest=event(),ImperialResponse=event()}
 for _,name in ipairs({'PlayerDoTurn','PlayerCityFounded','CityCaptureComplete','CityConstructed','UnitCreated','CityTrained','UnitConverted','UnitPrekill','CombatEnded'}) do GameEvents[name]=event() end
 for _,name in ipairs({'LoadScreenClose','GameplaySetActivePlayer','ActivePlayerTurnStart','ActivePlayerTurnEnd','SerialEventEnterCityScreen','SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed'}) do Events[name]=event() end
end
resetEvents()
Game={GetGameTurn=function() return Turn end,GetGameSpeedType=function() return 0 end,GetActivePlayer=function() return Active end,IsNetworkMultiPlayer=function() return Network end}
GameDefines={MAX_MAJOR_CIVS=22,BARBARIAN_PLAYER=63,MIN_CITY_RANGE=3}
NotificationTypes={NOTIFICATION_GENERIC=1};UnitAITypes={UNITAI_ATTACK=1,UNITAI_SETTLE=2};DomainTypes={DOMAIN_LAND=0};MissionTypes={MISSION_MOVE_TO=1}
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
Locale={ConvertTextKey=function(key,...)
 local text=Translations[key];assert(text or not key:find('TXT_KEY_IMPERIAL_'),'Missing localization: '..key);text=text or key
 local args={...};return (text:gsub('{(%d+)_[^}]+}',function(i) return tostring(args[tonumber(i)] or '') end))
end}
Modding={OpenSaveData=function() return {GetValue=function(key) return Saved[key] end,SetValue=function(key,value) SaveWriteCount=(SaveWriteCount or 0)+1;Saved[key]=value end} end}
function iter(t) local keys={};for k in pairs(t) do keys[#keys+1]=k end;table.sort(keys);local i=0;return function() i=i+1;return t[keys[i]] end end
function databaseTable(rows)
 local t={};for _,r in ipairs(rows) do if r.ID then t[r.ID]=r end;if r.Type then t[r.Type]=r end end
 return setmetatable(t,{__call=function(_,where) local i=0;return function()
  while true do i=i+1;local r=rows[i];if not r then return end;local ok=true
   for k,v in pairs(where or {}) do if r[k]~=v then ok=false end end
   if ok then return r end
  end
 end end})
end
function cityAt(x,y) for _,p in pairs(Players or {}) do for _,c in pairs(p.cities) do if c.x==x and c.y==y then return c end end end end
function newPlot(x,y)
 local plot={x=x,y=y,improvement=-1,resource=-1,owner=-1,revealed=true}
 function plot:GetX() return self.x end;function plot:GetY() return self.y end
 function plot:GetOwner() local c=cityAt(self.x,self.y);return c and c.owner or self.owner end
 function plot:GetPlotCity() return cityAt(self.x,self.y) end
 function plot:GetImprovementType() return self.improvement end;function plot:GetResourceType(team) return self.resource end
 function plot:IsImprovementPillaged() return self.pillaged or false end
 function plot:IsRevealed(team) return self.revealed end
 function plot:IsWater() return self.water or false end;function plot:IsMountain() return self.mountain or false end
 function plot:IsImpassable() return self.impassable or false end;function plot:IsCity() return self:GetPlotCity()~=nil end
 function plot:GetNumUnits() local n=0;for _,p in pairs(Players or {}) do for _,u in pairs(p.units) do if u.x==self.x and u.y==self.y then n=n+1 end end end;return n end
 return plot
end
Map={PlotDistance=function(x,y,a,b) local dx,dy=math.abs(x-a),math.abs(y-b);if WrapX then dx=math.min(dx,(MapWidth or 121)-dx) end;if WrapY then dy=math.min(dy,(MapHeight or 121)-dy) end;return math.max(dx,dy) end}
function Map.GetPlot(x,y) local width,height=MapWidth or 121,MapHeight or 121;if WrapX then x=x%width end;if WrapY then y=y%height end;if x<0 or y<0 or x>=width or y>=height then return nil end;local key=x..':'..y;if not Plots[key] then Plots[key]=newPlot(x,y) end;return Plots[key] end
function Map.PlotXYWithRangeCheck(x,y,dx,dy,r) if Map.PlotDistance(x,y,x+dx,y+dy)<=r then return Map.GetPlot(x+dx,y+dy) end end
function newCity(owner,id,x,y)
 local c={owner=owner,id=id,x=x or 10+id*5,y=y or 10+owner*35,pop=1,b={},founded=Turn,name=id==0 and 'Aeternum' or 'Valoria',food=3,resistance=0}
 function c:GetOwner() return self.owner end;function c:GetID() return self.id end
 function c:GetX() return self.x end;function c:GetY() return self.y end
 function c:GetGameTurnFounded() return self.founded end;function c:GetPopulation() return self.pop end
 function c:SetPopulation(n) self.pop=n end;function c:GetName() return self.name end;function c:SetName(n) self.name=n end
 function c:IsCapital() return self.id==0 end;function c:FoodDifference() return self.food end
 function c:GetNumRealBuilding(id) assert(id);return self.b[id] or 0 end
 function c:SetNumRealBuilding(id,n) assert(id);self.b[id]=n end
 function c:IsHasBuilding(id) assert(id);return self:GetNumRealBuilding(id)>0 end
 function c:CanConstruct(id,cont,visible,cost) assert(id and type(cont)=='number' and type(visible)=='number' and type(cost)=='number','CP construction flags are integers');return not self.blockConstruction and not (self.queuedWalls and id==GameInfoTypes.BUILDING_WALLS and cont==0) and not self:IsHasBuilding(id) end
 function c:ChangeResistanceTurns(n) self.resistance=self.resistance+n end
 function c:GetGarrisonedUnit() for _,u in pairs(Players[self.owner].units) do if u.x==self.x and u.y==self.y and u:IsCombatUnit() then return u end end end
 return c
end
function newUnit(owner,id,kind)
 local u={owner=owner,id=id,kind=kind or GameInfoTypes.UNIT_IMPERIAL_LEGION,x=10,y=10+owner*35,birth=Turn,p={},xp=0,moves=120}
 function u:GetID() return self.id end;function u:GetOwner() return self.owner end
 function u:GetUnitType() return self.kind end;function u:GetGameTurnCreated() return self.birth end
 function u:IsCombatUnit() return (GameInfo.Units[self.kind].Combat or 0)>0 end
 function u:GetDomainType() return GameInfo.Units[self.kind].Domain=='DOMAIN_LAND' and 0 or 1 end
 function u:GetX() return self.x end;function u:GetY() return self.y end;function u:GetPlot() return Map.GetPlot(self.x,self.y) end
 function u:IsHasPromotion(id) assert(id);return self.p[id] or false end;function u:SetHasPromotion(id,value) assert(id);self.p[id]=value end
 function u:IsEmbarked() return self.embarked or false end;function u:IsCargo() return self.cargo or false end
 function u:SetName(name) self.name=name end;function u:GetName() return self.name or Locale.ConvertTextKey(GameInfo.Units[self.kind].Description) end
 function u:GetNameNoDesc() return self:GetName() end
 function u:SetExperience(n) self.xp=n end;function u:GetExperience() return self.xp end
 function u:MovesLeft() return self.moves end;function u:FinishMoves() self.moves=0 end
 function u:JumpToNearestValidPlot() self.jumped=true;return true end
 function u:PushMission(kind,x,y) self.mission={kind,x,y};self.moves=0 end
 function u:Kill(delay,killer) GameEvents.UnitPrekill.Fire(self.owner,self.id,self.kind,self.x,self.y,delay,killer);Players[self.owner].units[self.id]=nil end
 return u
end
function newPlayer(pid,civ)
 local p={id=pid,civ=civ or GameInfoTypes.CIVILIZATION_SHATTERED_EMPIRE,cities={},units={},gold=2000,era=0,human=true,notices=0,alive=true,happiness=10,income=12}
 function p:GetID() return self.id end;function p:GetCivilizationType() return self.civ end
 function p:IsAlive() return self.alive end;function p:IsHuman() return self.human end
 function p:GetTeam() return self.id end;function p:GetCurrentEra() return self.era end
 function p:GetHandicapType() return 3 end;function p:GetNumCities() local n=0;for _ in pairs(self.cities) do n=n+1 end;return n end
 function p:Cities() return iter(self.cities) end;function p:Units() return iter(self.units) end
 function p:GetCityByID(id) return self.cities[id] end;function p:GetCapitalCity() return self.cities[0] end
 function p:GetUnitByID(id) return self.units[id] end;function p:GetGold() return self.gold end
 function p:ChangeGold(n) self.gold=self.gold+n;assert(self.gold>=0) end
 function p:CalculateGoldRate() return self.income end;function p:GetExcessHappiness() return self.happiness end
 function p:IsCapitalConnectedToCity(c) return c.connected or false end
 function p:GetStartingPlot() return Map.GetPlot(self.id<2 and 10 or 60+(self.id%6)*8,self.id<2 and 10+self.id*35 or 60+math.floor(self.id/6)*8) end
 function p:CanBuild(plot,build,testEra,visible)
  assert(type(testEra)=='number' and type(visible)=='number','CP CanBuild uses optional integers');local row=GameInfo.Builds[build]
  if not row or (row.PrereqTech and not Teams[self.id]:IsHasTech(GameInfoTypes[row.PrereqTech])) or plot.blockBuild then return false end
  if build==GameInfoTypes.BUILD_REPAIR then return plot.pillaged and plot:GetOwner()==self.id end
  return not plot:IsCity() and plot:GetImprovementType()<0 and plot:GetOwner()==self.id and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable()
 end
 function p:AddNotification(kind,body,title) assert(kind==1 and type(body)=='string' and type(title)=='string');self.notices=self.notices+1 end
 function p:CanFound(x,y)
  local plot=Map.GetPlot(x,y);if not plot or not plot.revealed or plot:IsWater() or plot:IsMountain() or plot:IsImpassable() or plot:IsCity() or self.noFound then return false end
  for _,other in pairs(Players) do for _,c in pairs(other.cities) do if Map.PlotDistance(x,y,c.x,c.y)<=3 then return false end end end;return true
 end
 function p:Found(x,y)
  assert(self:CanFound(x,y),'Unsafe founding');local id=1;while self.cities[id] do id=id+1 end
  self.cities[id]=newCity(self.id,id,x,y);GameEvents.PlayerCityFounded.Fire(self.id,x,y)
 end
 function p:InitUnit(kind,x,y,ai)
  local id=100;while self.units[id] do id=id+1 end;local u=newUnit(self.id,id,kind);u.x=x;u.y=y
  self.units[id]=u
  if kind==GameInfoTypes.UNIT_IMPERIAL_LEGION then u.p[GameInfoTypes.PROMOTION_IMPERIAL_DISCIPLINE]=true end
  GameEvents.UnitCreated.Fire(self.id,id,kind);return u
 end
 return p
end
function setupPlayers(fallback)
 Players={};Teams={}
 for pid=0,21 do
  local p=newPlayer(pid,pid<2 and GameInfoTypes.CIVILIZATION_SHATTERED_EMPIRE or GameInfoTypes.CIVILIZATION_ROME);Players[pid]=p
  local start=p:GetStartingPlot();p.cities[0]=newCity(pid,0,start:GetX(),start:GetY());p.noFound=fallback
  if pid<2 then local u=newUnit(pid,0);u.p[GameInfoTypes.PROMOTION_IMPERIAL_DISCIPLINE]=true;p.units[0]=u end
  local t={wars={},tech={}};function t:GetAtWarCount() local n=0;for _,v in pairs(self.wars) do if v then n=n+1 end end;return n end
  function t:IsHasTech(id) assert(id);return self.tech[id] or false end;Teams[pid]=t
 end
 Players[1].human=false;Players[63]=newPlayer(63,GameInfoTypes.CIVILIZATION_BARBARIAN)
end
function nextTurn(pid) Turn=Turn+1;GameEvents.PlayerDoTurn.Fire(pid or 0) end
function reload() __IMPERIAL_CONTEXT_LOADED=nil;resetEvents();MapModData={};include('ImperialCore') end
function upgrade(uid,newID)
 local old=Players[0].units[uid];local u=newUnit(0,newID,GameInfoTypes.UNIT_SWORDSMAN);u.name=old.name;u.x=old.x;u.y=old.y;u.xp=old.xp
 Players[0].units[newID]=u;GameEvents.UnitCreated.Fire(0,newID,u.kind)
 for id,v in pairs(old.p) do if GameInfo.UnitPromotions[id].LostWithUpgrade==0 then u.p[id]=v else u.p[id]=false end end
 GameEvents.UnitConverted.Fire(0,0,uid,newID,true);old:Kill(false,-1);return u
end
UI={IsCityScreenUp=function() return false end}
function uiControls(names)
 Controls={};Instances={}
 local function control(name)
  local c={name=name};function c:SetHide(v) self.hidden=v end;function c:SetText(v) self.text=v end
  function c:SetToolTipString(v) self.tooltip=v end;function c:SetDisabled(v) self.disabled=v end
  function c:RegisterCallback(_,fn) self.click=fn end;function c:SetSizeY(n) self.height=n end
  function c:CalculateSize() end;function c:ReprocessAnchoring() end;function c:CalculateInternalSize() end;return c
 end
 for name in names:gmatch('[^,]+') do Controls[name]=control(name) end
 InstanceManager={};function InstanceManager:new(template,root,parent)
  local m={parent=parent,instances={}};function m:ResetInstances() self.instances={};Instances[self.parent.name]=self.instances end
  function m:GetInstance() local row={[root]=control(root)};self.instances[#self.instances+1]=row;return row end;return m
 end
 IconHookup=function() end;ContextPtr={SetInputHandler=function(_,fn) Escape=fn end}
end
