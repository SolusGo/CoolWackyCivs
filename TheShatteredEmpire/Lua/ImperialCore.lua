-- Sole simulation owner, loaded once by ImperialAdministration for all players.
if __IMPERIAL_CONTEXT_LOADED then return end
__IMPERIAL_CONTEXT_LOADED=true
MapModData.TheShatteredEmpire={States={}}
local I=MapModData.TheShatteredEmpire
I.ID=function(name) return GameInfoTypes[name] end
I.Now=function() return Game.GetGameTurn() end
local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
I.Speed=(speed and speed.TrainPercent or 100)/100
I.Scale=function(n) return math.max(1,math.floor(n*I.Speed+.5)) end
I.Clamp=function(n,a,b) return math.max(a,math.min(b,n)) end
I.Text=function(key,...) return Locale.ConvertTextKey('TXT_KEY_IMPERIAL_'..key,...) end
I.Log=function(category,message) if I.Debug then print('[ShatteredEmpire]['..category..'] '..message) end end
function I.IsEmpire(pid)
 local p=Players[pid]
 return p and p:GetCivilizationType()==I.ID('CIVILIZATION_SHATTERED_EMPIRE')
  and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
end
function I.Keys(t) local keys={};for k in pairs(t) do keys[#keys+1]=k end;table.sort(keys);return keys end
function I.Rand(s,n) s.rng=(s.rng*48271)%2147483647;return s.rng%n+1 end
function I.Near(x,y,r,fn)
 local seen={}
 for dx=-r,r do for dy=-r,r do local p=Map.PlotXYWithRangeCheck(x,y,dx,dy,r)
  if p then local key=p:GetX()..':'..p:GetY();if not seen[key] then seen[key]=true;fn(p) end end
 end end
end
function I.CityKey(c) return c:GetX()..':'..c:GetY() end
function I.City(g,pid)
 local plot=Map.GetPlot(g.x,g.y);local c=plot and plot:GetPlotCity()
 if c and c:GetOwner()==pid and c:GetGameTurnFounded()==g.founded then return c end
end
function I.Capital(pid) return Players[pid]:GetCapitalCity() end
function I.Wars(pid) return Teams[Players[pid]:GetTeam()]:GetAtWarCount(true) end
function I.Provinces(s)
 local result={};for _,key in ipairs(I.Keys(s.governors)) do local g=s.governors[key];if g.active then result[#result+1]=g end end;return result
end
function I.Promotion(u,name,enabled)
 local id=I.ID('PROMOTION_IMPERIAL_'..name)
 if u and id and u:IsHasPromotion(id)~=(enabled and true or false) then u:SetHasPromotion(id,enabled and true or false) end
end
function I.Authority(s,delta)
 local previous=s.authority;s.authority=I.Clamp(previous+delta,0,100)
 if s.war then
  local applied=s.authority-previous
  if applied<0 then s.war.authorityLost=s.war.authorityLost-applied else s.war.authorityRecovered=s.war.authorityRecovered+applied end
 end
end
function I.Condition(n) return I.Text(n>=80 and 'GOLDEN' or n>=60 and 'STABLE' or n>=40 and 'STRAINED' or n>=20 and 'FRACTURED' or 'COLLAPSE') end
include('ImperialPersistence')
include('ImperialChronicle')
include('ImperialStartingCities')
include('ImperialGovernors')
include('ImperialLoyalty')
include('ImperialLegions')
include('ImperialRebellions')
include('ImperialReforms')
include('ImperialSuccession')
include('ImperialAI')
function I.Commit(pid)
 I.ApplyEffects(I.State(pid));I.Save(pid)
 if LuaEvents.ImperialChanged then LuaEvents.ImperialChanged(pid) end
end
function I.Initialize(pid)
 if not I.IsEmpire(pid) then return end
 local s=I.State(pid);I.Start(s);I.Reconcile(s);I.UnitTick(s,false);I.Commit(pid);return s
end
function I.Turn(pid)
 if not I.IsEmpire(pid) then return end
 local s=I.State(pid);if s.lastTurn==I.Now() then return end;s.lastTurn=I.Now()
 if not Players[pid]:IsAlive() then
  for _,g in pairs(s.governors) do g.active=false end
  I.RebellionTick(s);I.Commit(pid);return
 end
 I.Start(s);I.Reconcile(s);I.SuccessionTick(s)
 local political=I.Now()>=s.nextPolitical
 if political then
  s.nextPolitical=I.Now()+I.Scale(5);I.LoyaltyTick(s);I.UnitTick(s,true)
 else I.UnitTick(s,false) end
 I.DemandTick(s);I.RebellionTick(s);I.AITick(s);I.RestorationTick(s);I.Commit(pid)
end
include('ImperialEvents')
for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if I.IsEmpire(pid) then I.Initialize(pid) end end
