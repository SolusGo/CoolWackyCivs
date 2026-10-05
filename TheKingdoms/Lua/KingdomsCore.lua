-- One gameplay owner: included by the InGameUIAddin for human and AI players.
-- Context-local guard prevents duplicate hooks, while a fresh context reloads save data.
if __KINGDOMS_CONTEXT_LOADED then return end
__KINGDOMS_CONTEXT_LOADED=true
MapModData.TheKingdoms={States={}}
local K=MapModData.TheKingdoms
K.ID=function(name) return GameInfoTypes[name] end
K.Now=function() return Game.GetGameTurn() end
local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
K.Speed=(speed and speed.TrainPercent or 100)/100
K.Scale=function(n) return math.max(1,math.floor(n*K.Speed+.5)) end
K.Clamp=function(n,low,high) return math.max(low,math.min(high,n)) end
function K.IsKingdoms(pid)
 local p=Players[pid]
 return p and p:GetCivilizationType()==K.ID('CIVILIZATION_KINGDOMS')
  and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
end
function K.Promotion(u,name,value)
 local id=K.ID('PROMOTION_KINGDOMS_'..name)
 if u and id and u:IsHasPromotion(id)~=(value and true or false) then u:SetHasPromotion(id,value and true or false) end
end
function K.Wars(pid)
 local p=Players[pid];local team=p and Teams[p:GetTeam()];return team and team:GetAtWarCount(true) or 0
end
function K.NearPlots(x,y,radius,callback)
 local seen={}
 for dx=-radius,radius do for dy=-radius,radius do
  local plot=Map.PlotXYWithRangeCheck(x,y,dx,dy,radius)
  if plot and Map.PlotDistance(x,y,plot:GetX(),plot:GetY())<=radius then
   local key=plot:GetX()..':'..plot:GetY();if not seen[key] then seen[key]=true;callback(plot) end
  end
 end end
end
function K.ActiveKingdoms(s)
 local result={};for _,key in ipairs(K.Keys(s.kingdoms)) do if s.kingdoms[key].active then result[#result+1]=s.kingdoms[key] end end;return result
end
function K.KingdomCount(s) local n=0;for _,k in pairs(s.kingdoms) do if k.active then n=n+1 end end;return n end
function K.StabilityLabel(n,realm)
 return K.Text(n>=80 and 'UNITED' or n>=60 and 'STABLE' or n>=40 and 'UNEASY' or n>=20 and 'FRACTURED' or realm and 'CRISIS' or 'REBELLIOUS')
end
function K.LoyaltyLabel(n)
 return K.Text(n>=80 and 'DEVOTED' or n>=50 and 'LOYAL' or n>=20 and 'SUPPORTIVE' or n>=-19 and 'NEUTRAL' or n>=-49 and 'DISCONTENT' or n>=-79 and 'HOSTILE' or 'REBELLIOUS')
end
include('KingdomsDebug')
include('KingdomsData')
include('KingdomsPersistence')
include('HistoryManager')
include('CharacterManager')
include('HouseManager')
include('KingdomManager')
include('DemandManager')
include('RulerManager')
include('SuccessionManager')
include('CivilWarManager')
include('KingsGuardManager')
include('KingdomsEffects')
include('KingdomsAI')
function K.Commit(pid)
 K.Claims(K.State(pid))
 K.Save(pid)
 if LuaEvents.KingdomsChanged then LuaEvents.KingdomsChanged(pid) end
end
function K.Initialize(pid)
 if not K.IsKingdoms(pid) then return end
 local s=K.State(pid);K.ReconcileKingdoms(s);K.GuardTick(s)
 if not s.ruler and not s.war and K.KingdomCount(s)>0 then K.RulerTick(s) end
 K.Claims(s);K.RefreshRealm(s);K.Commit(pid);return s
end
function K.Turn(pid)
 if not K.IsKingdoms(pid) then return end
 local s=K.State(pid)
 if s.lastTurn==K.Now() then return end
 s.lastTurn=K.Now()
 if not Players[pid]:IsAlive() then
  for _,k in pairs(s.kingdoms) do k.active=false end;K.HouseViews[s]=nil;s.war=nil;K.ApplyEffects(s);K.Commit(pid);return
 end
 K.KingdomTick(s);K.HouseTick(s);K.DemandTick(s);K.RefreshRealm(s)
 K.Claims(s);K.RulerTick(s)
 if not s.war and s.ruler and s.realm<=10 and K.Now()>=(s.crisisNext or 0) and #K.ActiveHouses(s)>=3 then
  s.crisisNext=K.Now()+K.Scale(50);s.previousHouse=s.characters[s.ruler].house
  local c=s.characters[s.ruler];c.role='deposed ruler';c.reignLength=K.Now()-c.reignStart;s.ruler=nil
  K.History(s,'RULERS','RULER_DEPOSED',{K.CharacterName(s,c)},c.house);K.BeginCivilWar(s)
 end
 K.CivilWarTick(s);K.GuardTick(s);K.AITick(s);K.RefreshRealm(s);K.Claims(s);K.Commit(pid)
end
include('KingdomsEvents')
for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if K.IsKingdoms(pid) then K.Initialize(pid) end end
