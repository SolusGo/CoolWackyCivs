-- Strict Lua 5.1 test doubles. Database definitions are loaded from a real CP cache clone.
Saved=Saved or {};MapModData={};Turn=0;Active=0;Network=false
function event()
 local e={handlers={}}
 function e.Add(fn) e.handlers[#e.handlers+1]=fn end
 function e.Fire(...) local result=true;for _,fn in ipairs(e.handlers) do if fn(...)==false then result=false end end;return result end
 return setmetatable(e,{__call=function(_,...) return e.Fire(...) end})
end
function resetEvents()
 GameEvents={};Events={};LuaEvents={KingdomsChanged=event()}
 for _,name in ipairs({'PlayerDoTurn','PlayerCityFounded','CityCaptureComplete','SetPopulation','CityConstructed','UnitCreated','CityTrained','PlayerCanTrain','UnitConverted','UnitPrekill','BarbariansCampCleared','CombatEnded','TeamTechResearched'}) do GameEvents[name]=event() end
 for _,name in ipairs({'LoadScreenClose','GameplaySetActivePlayer','ActivePlayerTurnStart','ActivePlayerTurnEnd','SerialEventEnterCityScreen','SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed','SerialEventGameDataDirty','SerialEventCityInfoDirty'}) do Events[name]=event() end
end
resetEvents()
Game={GetGameTurn=function() return Turn end,GetGameSpeedType=function() return 0 end,GetActivePlayer=function() return Active end,IsNetworkMultiPlayer=function() return Network end,GetTurnYear=function(t) return -4000+t*40 end}
GameDefines={MAX_MAJOR_CIVS=3,BARBARIAN_PLAYER=63}
NotificationTypes={NOTIFICATION_GENERIC=1};UnitAITypes={UNITAI_ATTACK=1};DomainTypes={DOMAIN_LAND=0};Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
Locale={ConvertTextKey=function(key,...)
 local text=Translations[key];assert(text or not key:find('TXT_KEY_KINGDOMS_'),'Missing localization: '..key);text=text or key
 local args={...};return (text:gsub('{(%d+)_[^}]+}',function(i) return tostring(args[tonumber(i)] or '') end))
end}
Modding={OpenSaveData=function() return {GetValue=function(key) return Saved[key] end,SetValue=function(key,value) Saved[key]=value end} end}
function iter(t) local keys={};for k in pairs(t) do keys[#keys+1]=k end;table.sort(keys);local i=0;return function() i=i+1;return t[keys[i]] end end
function databaseTable(rows)
 local t={};for _,r in ipairs(rows) do if r.ID then t[r.ID]=r end;if r.Type then t[r.Type]=r end end
 return setmetatable(t,{__call=function(_,where)
  local i=0;return function()
   while true do i=i+1;local r=rows[i];if not r then return end;local ok=true
    for k,v in pairs(where or {}) do if r[k]~=v then ok=false end end
    if ok then return r end
   end
  end
 end})
end
Plots={}
function cityAt(x,y)
 for _,p in pairs(Players or {}) do for _,c in pairs(p.cities) do if c.x==x and c.y==y then return c end end end
end
function newPlot(x,y)
 local plot={x=x,y=y,improvement=-1,resource=-1,owner=-1}
 for _,p in pairs(Players or {}) do for _,c in pairs(p.cities) do if math.max(math.abs(x-c.x),math.abs(y-c.y))<=3 then plot.owner=c.owner end end end
 function plot:GetX() return self.x end
 function plot:GetY() return self.y end
 function plot:GetOwner() local c=cityAt(self.x,self.y);return c and c.owner or self.owner end
 function plot:GetPlotCity() return cityAt(self.x,self.y) end
 function plot:GetWorkingCity()
  for _,p in pairs(Players or {}) do for _,c in pairs(p.cities) do if c.owner==self:GetOwner() and Map.PlotDistance(self.x,self.y,c.x,c.y)<=3 then return c end end end
 end
 function plot:GetImprovementType() return self.improvement end
 function plot:GetResourceType(team) return self.resource end
 function plot:IsImprovementPillaged() return self.pillaged or false end
 function plot:IsRevealed(team) return true end
 function plot:IsWater() return self.water or false end
 function plot:IsMountain() return false end
 function plot:IsImpassable() return false end
 function plot:IsCity() return self:GetPlotCity()~=nil end
 function plot:GetNumUnits()
  local n=0;for _,p in pairs(Players or {}) do for _,u in pairs(p.units) do if u.x==self.x and u.y==self.y then n=n+1 end end end;return n
 end
 return plot
end
Map={PlotDistance=function(x,y,a,b) return math.max(math.abs(x-a),math.abs(y-b)) end}
function Map.GetPlot(x,y) local key=x..':'..y;if not Plots[key] then Plots[key]=newPlot(x,y) end;return Plots[key] end
function Map.PlotXYWithRangeCheck(x,y,dx,dy,radius)
 if Map.PlotDistance(x,y,x+dx,y+dy)<=radius then return Map.GetPlot(x+dx,y+dy) end
end
function newCity(owner,id,x,y)
 local c={owner=owner,id=id,x=x or id*8,y=y or owner*12,pop=3,b={},founded=Turn,original=owner,production=0,name=id==0 and 'Kings Throne' or 'Stormwatch',food=3}
 function c:GetOwner() return self.owner end
 function c:GetOriginalOwner() return self.original end
 function c:GetID() return self.id end
 function c:GetX() return self.x end
 function c:GetY() return self.y end
 function c:GetGameTurnFounded() return self.founded end
 function c:GetPopulation() return self.pop end
 function c:GetName() return self.name end
 function c:IsOccupied() return self.occupied or false end
 function c:IsNoOccupiedUnhappiness() return false end
 function c:IsRazing() return false end
 function c:IsFoodProduction() return false end
 function c:FoodDifference() return self.food end
 function c:GetNumBuilding(id) assert(id);return self.b[id] or 0 end
 c.GetNumRealBuilding=c.GetNumBuilding
 function c:SetNumRealBuilding(id,n) assert(id);self.b[id]=n end
 function c:CanConstruct(id) assert(id);return not self.blockConstruction and self:GetNumBuilding(id)==0 end
 function c:CanTrain(id) assert(id);return true end
 function c:GetSpecialistCount(id) return 0 end
 function c:ChangeProduction(n) self.production=self.production+n end
 return c
end
function newUnit(owner,id,kind)
 local u={owner=owner,id=id,kind=kind or GameInfoTypes.UNIT_WARRIOR,x=0,y=owner*12,birth=Turn,p={},damage=0,script='',moves=120}
 function u:GetID() return self.id end
 function u:GetOwner() return self.owner end
 function u:GetUnitType() return self.kind end
 function u:GetGameTurnCreated() return self.birth end
 function u:IsCombatUnit() return (GameInfo.Units[self.kind].Combat or 0)>0 end
 function u:GetX() return self.x end
 function u:GetY() return self.y end
 function u:GetPlot() return Map.GetPlot(self.x,self.y) end
 function u:GetScriptData() return self.script end
 function u:SetScriptData(data) self.script=data end
 function u:IsHasPromotion(id) assert(id);return self.p[id] or false end
 function u:SetHasPromotion(id,value) assert(id);self.p[id]=value end
 function u:SetName(name) self.name=name end
 function u:GetName() return self.name or 'Warrior' end
 function u:GetDamage() return self.damage end
 function u:GetMaxHitPoints() return 100 end
 function u:SetDamage(n) self.damage=n end
 function u:FinishMoves() self.moves=0 end
 function u:Kill(delay,killer)
  GameEvents.UnitPrekill.Fire(self.owner,self.id,self.kind,self.x,self.y,delay,killer)
  Players[self.owner].units[self.id]=nil
 end
 return u
end
function newPlayer(pid,civ)
 local p={id=pid,civ=civ or GameInfoTypes.CIVILIZATION_KINGDOMS,cities={},units={},gold=2000,faith=100,era=2,human=true,routes={},notices=0,research=GameInfoTypes.TECH_GUNPOWDER,alive=true}
 function p:GetID() return self.id end
 function p:GetCivilizationType() return self.civ end
 function p:IsAlive() return self.alive end
 function p:IsHuman() return self.human end
 function p:IsMinorCiv() return false end
 function p:GetCurrentEra() return self.era end
 function p:GetTeam() return self.id end
 function p:Cities() return iter(self.cities) end
 function p:Units() return iter(self.units) end
 function p:GetCityByID(id) return self.cities[id] end
 function p:GetCapitalCity() return self.cities[0] or self.cities[1] end
 function p:GetUnitByID(id) return self.units[id] end
 function p:GetGold() return self.gold end
 function p:ChangeGold(n) self.gold=self.gold+n;assert(self.gold>=0) end
 function p:CalculateGoldRate() return 12 end
 function p:GetFaith() return self.faith end
 function p:GetTotalFaithPerTurn() return 5 end
 function p:GetCurrentResearch() return self.research end
 function p:GetTradeRoutes() return self.routes end
 function p:GetTradeRoutesAvailable() return 3 end
 function p:GetNumMilitaryUnits() local n=0;for u in self:Units() do if u:IsCombatUnit() then n=n+1 end end;return n end
 function p:CanBuild(plot,build,era,visible) return not plot:IsCity() and plot:GetImprovementType()<0 and plot:GetOwner()==self.id end
 function p:AddNotification(body,title) self.notices=self.notices+1 end
 function p:InitUnit(kind,x,y,ai)
  local id=100;while self.units[id] do id=id+1 end
  local u=newUnit(self.id,id,kind);u.x=x;u.y=y;self.units[id]=u;GameEvents.UnitCreated.Fire(self.id,id,kind);return u
 end
 return p
end
function setupPlayers()
 Players={[0]=newPlayer(0),[1]=newPlayer(1),[2]=newPlayer(2,GameInfoTypes.CIVILIZATION_ENGLAND),[63]=newPlayer(63,GameInfoTypes.CIVILIZATION_BARBARIAN)}
 Players[1].human=false
 for pid=0,2 do Players[pid].cities[0]=newCity(pid,0);Players[pid].units[0]=newUnit(pid,0) end
 Teams={}
 for _,pid in ipairs({0,1,2,63}) do
  local t={wars={},tech={}}
  function t:GetAtWarCount() local n=0;for _,v in pairs(self.wars) do if v then n=n+1 end end;return n end
  function t:IsAtWar(id) return self.wars[id] or false end
  function t:IsHasMet(id) return id~=63 end
  function t:CanDeclareWar(id) return id~=63 and not self:IsAtWar(id) end
  function t:CanChangeWarPeace(id) return self:IsAtWar(id) end
  function t:IsHasTech(id) return self.tech[id] or false end
  Teams[pid]=t
 end
end
function nextTurn(pid) Turn=Turn+1;GameEvents.PlayerDoTurn.Fire(pid or 0) end
function reload()
 __KINGDOMS_CONTEXT_LOADED=nil;resetEvents();MapModData={};include('KingdomsCore')
end
function createGuard(uid,pid)
 pid=pid or 0;local u=newUnit(pid,uid,GameInfoTypes.UNIT_KINGDOMS_GUARD);Players[pid].units[uid]=u
 GameEvents.UnitCreated.Fire(pid,uid,u.kind);return u
end
function upgradeGuard(uid,newID,withHook)
 local old=Players[0].units[uid];local u=newUnit(0,newID,GameInfoTypes.UNIT_MUSKETMAN)
 -- Native CP copies names/promotions, NOT ScriptData. Exercise the real contract.
 u.name=old.name;for id,value in pairs(old.p) do u.p[id]=value end
 Players[0].units[newID]=u;GameEvents.UnitCreated.Fire(0,newID,u.kind)
 if withHook~=false then GameEvents.UnitConverted.Fire(0,0,uid,newID,true) end
 old:Kill(false,-1);return u
end
UI={IsCityScreenUp=function() return false end}
function uiControls(names)
 Controls={};Instances={}
 local function control(name)
  local c={name=name}
  function c:SetHide(v) self.hidden=v end
  function c:SetText(v) self.text=v end
  function c:SetToolTipString(v) self.tooltip=v end
  function c:SetDisabled(v) self.disabled=v end
  function c:RegisterCallback(_,fn) self.click=fn end
  function c:SetSizeY(n) self.height=n end
  function c:CalculateSize() end
  function c:ReprocessAnchoring() end
  function c:CalculateInternalSize() end
  return c
 end
 for name in names:gmatch('[^,]+') do Controls[name]=control(name) end
 InstanceManager={}
 function InstanceManager:new(template,root,parent)
  local manager={parent=parent,instances={}}
  function manager:ResetInstances() self.instances={};Instances[self.parent.name]=self.instances end
  function manager:GetInstance() local row={[root]=control(root)};self.instances[#self.instances+1]=row;return row end
  return manager
 end
 IconHookup=function() end
 ContextPtr={SetInputHandler=function(_,fn) Escape=fn end}
end
