-- One InGameUIAddin owns gameplay for ALL Last City players. UI never includes
-- or reinitializes this module. This follows the collection's simulation model.
if __LAST_CITY_LOADED then return end
__LAST_CITY_LOADED=true
MapModData.TheLastCity={States={},Players={},Caches={},Busy={},Depth=0}
local L=MapModData.TheLastCity
L.ID=function(n) return GameInfoTypes[n] end
L.Now=function() return Game.GetGameTurn() end
L.Text=function(k,...) return Locale.ConvertTextKey('TXT_KEY_LC_'..k,...) end
L.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
L.Founds=function(row) return row and (row.Found==true or row.Found==1 or row.FoundAbroad==true or row.FoundAbroad==1) end
local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
L.Speed=(speed and speed.TrainPercent or 100)/100
L.Scale=function(n) return math.max(1,math.floor(n*L.Speed+.5)) end
L.Log=function(msg) if L.Config.Debug then print('[LastCity] '..msg) end end
function L.IsCity(pid)
 local p=Players[pid]
 return p and p:GetCivilizationType()==L.ID('CIVILIZATION_LAST_CITY')
  and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
end
function L.Keys(t)
 local r={};for k in pairs(t) do r[#r+1]=k end;table.sort(r);return r
end
function L.Rand(s,n) s.rng=(s.rng*48271)%2147483647;return s.rng%n+1 end
function L.Range(s,a,b) return a+L.Rand(s,b-a+1)-1 end
function L.Near(x,y,r,fn)
 local seen={}
 for dx=-r,r do for dy=-r,r do local p=Map.PlotXYWithRangeCheck(x,y,dx,dy,r)
  if p then local k=p:GetPlotIndex();if not seen[k] then seen[k]=true;fn(p) end end
 end end
end
function L.City(s)
 if not s.capital then return end
 local plot=Map.GetPlot(s.capital.x,s.capital.y);local c=plot and plot:GetPlotCity()
 if c and c:GetOwner()==s.pid and c:GetGameTurnFounded()==s.capital.founded then return c end
end
function L.Has(c,key) return c and c:GetNumRealBuilding(L.ID('BUILDING_LC_'..key))>0 end
function L.Building(c,key,count)
 local id=L.ID('BUILDING_LC_'..key)
 if id and c:GetNumRealBuilding(id)~=count then c:SetNumRealBuilding(id,count) end
end
function L.Promotion(u,key,on)
 local id=L.ID('PROMOTION_LC_'..key)
 if id and u:IsHasPromotion(id)~=(on and true or false) then u:SetHasPromotion(id,on and true or false) end
end
function L.History(s,key,detail)
 s.sequence=s.sequence+1
 s.history[#s.history+1]={id=s.sequence,turn=L.Now(),key=key,detail=detail or ''}
 while #s.history>L.Config.HistoryLimit do table.remove(s.history,1) end
end
function L.Notify(s,key,detail)
 if Players[s.pid]:IsHuman() then local c=L.City(s)
  Players[s.pid]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,L.Text(key)..(detail and '[NEWLINE]'..detail or ''),L.Text('COUNCIL'),c and c:GetX() or -1,c and c:GetY() or -1)
 end
end
function L.Morale(s,delta) s.morale=L.Clamp(s.morale+delta,0,100) end
function L.Provisions(s,delta) s.provisions=L.Clamp(s.provisions+delta,0,s.capacity) end
function L.Changed(s)
 if L.Depth>0 then s.dirty=true;return end
 L.ApplyEffects(s);L.RefreshUnits(s);L.Save(s.pid)
 if LuaEvents.LastCityChanged then LuaEvents.LastCityChanged(s.pid) end
end
function L.Atomic(s,fn,...)
 if L.Busy[s.pid] then return false,L.Text('BUSY') end
 L.Busy[s.pid]=true;L.Depth=L.Depth+1
 local result={pcall(fn,s,...)}
 L.Depth=L.Depth-1;L.Busy[s.pid]=nil
 if L.Depth==0 then s.dirty=nil;L.Changed(s) end
 if not result[1] then error(result[2],0) end
 return unpack(result,2)
end
include('LastCityConfig')
include('LastCityPersistence')
include('LastCityEconomy')
include('LastCityRefugees')
include('LastCityCrises')
include('LastCityInvasions')
include('LastCityAI')
function L.Initialize(pid)
 if not L.IsCity(pid) then return end
 local s=L.State(pid);local c=Players[pid]:GetCapitalCity()
 if s.incompatible then return s end
 if not s.capital and c then
  s.capital={x=c:GetX(),y=c:GetY(),founded=c:GetGameTurnFounded()}
  c:SetName(L.Text('CAPITAL'),false)
  s.nextRefugee=L.Now()+L.Scale(L.Range(s,L.Config.RefugeeMin,L.Config.RefugeeMax))
  s.nextCrisis=L.Now()+L.Scale(L.Range(s,L.Config.CrisisMin,L.Config.CrisisMax))
  s.nextWave=L.Now()+L.Scale(L.Config.FirstWave)
  L.History(s,'FOUNDED');L.Notify(s,'FOUNDED')
 end
 L.ReturnExtraCities(s);L.Changed(s);return s
end
function L.Turn(pid)
 if not L.IsCity(pid) then return end
 local s=L.State(pid)
 if s.incompatible then return end
 if s.lastTurn==L.Now() then return end
 if not s.capital then L.Initialize(pid) end
 L.Atomic(s,function()
  s.lastTurn=L.Now();L.ReturnExtraCities(s)
  if not L.City(s) then L.RetireWave(s);return end
  local settlers={}
  for u in Players[pid]:Units() do local def=GameInfo.Units[u:GetUnitType()]
   if L.Founds(def) then settlers[#settlers+1]=u end
  end
  for _,u in ipairs(settlers) do u:Kill(false,-1) end
  if (s.dawn=='AWAITING_SUPPLIES' or (s.dawn=='LOCKED' and L.Has(L.City(s),'DAWN'))) and s.provisions>=150 and s.morale>=55 and s.wavesSurvived>=12 then
   L.Provisions(s,-150);s.dawn='FINAL_PENDING';L.History(s,'DAWN_LAUNCHED');L.Notify(s,'DAWN_LAUNCHED')
   if not s.wave then s.nextWave=L.Now()+L.Scale(L.Config.Warning);s.warning=nil end
  end
  L.EconomyTurn(s);L.RefugeeTurn(s);L.CrisisTurn(s);L.InvasionTurn(s)
  if not Players[pid]:IsHuman() then L.AITurn(s) end
 end)
end
-- Gameplay commands always validate player, current event ID and turn state.
function L.Action(pid,kind,id,value)
 if not L.IsCity(pid) or not Players[pid]:IsHuman() or Game.GetActivePlayer()~=pid then return false,L.Text('UNAVAILABLE') end
 local s=L.State(pid)
 if s.incompatible then return false,L.Text('UNAVAILABLE') end
 if not L.City(s) or not Players[pid]:IsTurnActive() then return false,L.Text('UNAVAILABLE') end
 return L.Atomic(s,function()
  if kind=='REFUGEE' then return L.ResolveRefugee(s,id,value)
  elseif kind=='CRISIS' then return L.ResolveCrisis(s,id,value)
  elseif kind=='RATION' then return L.SetRation(s,id)
  elseif kind=='EXPERT' then return L.Assign(s,id,value)
  elseif kind=='BUILD' then return L.QueueInfrastructure(s,id) end
  return false,L.Text('UNAVAILABLE')
 end)
end
include('LastCityEvents')
for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do
 if L.IsCity(pid) then L.Players[#L.Players+1]=pid;L.Initialize(pid) end
end
