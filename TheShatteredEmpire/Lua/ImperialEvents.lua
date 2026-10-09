local I=MapModData.TheShatteredEmpire
local function hook(name,fn)
 if GameEvents[name] and GameEvents[name].Add then GameEvents[name].Add(function(...) return I.Atomic(fn,...) end) else I.Log('HOOK','Unavailable: '..name) end
end
local function capture(s,key,stamp)
 s.captures=s.captures or {};if s.captures[key] and s.captures[key].stamp==stamp then return false end
 s.captures[key]={stamp=stamp,turn=I.Now()}
 local keys=I.Keys(s.captures);if #keys>256 then table.sort(keys,function(a,b) if s.captures[a].turn~=s.captures[b].turn then return s.captures[a].turn<s.captures[b].turn end;return a<b end);s.captures[keys[1]]=nil end
 return true
end
hook('PlayerDoTurn',I.Turn)
hook('PlayerCityFounded',function(pid,x,y)
 if I.IsEmpire(pid) then local s=I.State(pid);local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
  if c then I.StartCity(s,c);I.DirtyCity(s,I.CityKey(c)) end
  if not s.startBusy then I.Start(s);I.Reconcile(s);I.Commit(pid) end
 end
end)
hook('CityCaptureComplete',function(oldOwner,wasCapital,x,y,newOwner,population,conquest)
 local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
 local key=x..':'..y;local stamp=oldOwner..':'..newOwner..':'..I.Now()..':'..(c and c:GetGameTurnFounded() or -1)
 if I.IsEmpire(oldOwner) or I.IsEmpire(newOwner) then if c then I.ClearCity(c) end end
 if I.IsEmpire(oldOwner) and oldOwner~=newOwner then
  local s=I.State(oldOwner);if capture(s,key,stamp) then
  I.Authority(s,wasCapital and -20 or -8);I.Reign(s).lost=I.Reign(s).lost+1
  I.History(s,'LOSS',I.Text('HISTORY_LOST',c and c:GetName() or I.Text('UNKNOWN_CITY')));I.Reconcile(s);I.RebellionTick(s);I.RestorationTick(s);I.Commit(oldOwner)
  end
 end
 if I.IsEmpire(newOwner) then
  local s=I.State(newOwner);capture(s,key,stamp)
  if conquest and not s.conquests[key] then s.conquests[key]=true;I.Authority(s,4);s.lastVictory=I.Now();I.Reign(s).acquired=I.Reign(s).acquired+1
   I.History(s,'CONQUEST',I.Text('HISTORY_CONQUEST',c and c:GetName() or I.Text('UNKNOWN_CITY'),I.Reign(s).name))
  end
  I.Reconcile(s);I.RestorationTick(s);if c then I.DirtyCity(s,I.CityKey(c));I.Pending(newOwner).cityCache[I.CityKey(c)]=nil end;I.Commit(newOwner)
 end
end)
hook('CityConstructed',function(pid,cityID)
 if I.IsEmpire(pid) then local s=I.State(pid);local c=Players[pid]:GetCityByID(cityID);local g=c and s.governors[I.CityKey(c)]
  if g and g.active and I.City(g,pid) then g.prestige=I.Clamp(g.prestige+1,0,100);I.CheckDemand(s,g);I.Commit(pid) end
 end
end)
hook('UnitCreated',function(pid,uid) if I.IsEmpire(pid) then local s=I.State(pid);local u=Players[pid]:GetUnitByID(uid)
 if I.StartSettler(s,u) or I.Track(s,u) then I.Commit(pid) end
end end)
hook('CityTrained',function(pid,cityID,uid)
 if I.IsEmpire(pid) then local s=I.State(pid);local c=Players[pid]:GetCityByID(cityID);local u=Players[pid]:GetUnitByID(uid)
  local r=I.Track(s,u,c and I.CityKey(c));local g=c and s.governors[I.CityKey(c)]
  if r then r.home=g and g.active and g.key or nil;r.governor=g and g.active and g.id or nil;I.Commit(pid) end
 end
end)
hook('UnitConverted',I.Converted)
hook('UnitPrekill',function(pid,uid,kind,x,y,delay,killer)
 if delay then return end
 if I.IsEmpire(pid) then local s=I.State(pid);if s.units[uid] then s.units[uid]=nil;I.Commit(pid) end end
end)
hook('CombatEnded',function(ap,au,ad,af,am,dp,du,dd,df,dm,ip,iu,damage,x,y)
 -- CP v151 RED signature: final damage (af/df), never inflicted damage (ad/dd).
 local function record(pid,uid,enemy,final,maxHP,defensive)
  if not I.IsEmpire(pid) or not uid or uid<0 then return end
  local s=I.State(pid);local r=s.units[uid];local soldier=Players[pid]:GetUnitByID(uid)
  if not r or (soldier and r.birth~=soldier:GetGameTurnCreated()) then return end
  r.battles=r.battles+1
  if type(final)=='number' and type(maxHP)=='number' and maxHP>0 and final>=maxHP then
   r.kills=r.kills+1;r.oath=I.Clamp(r.oath+2,0,100);s.lastVictory=I.Now()
   local g=r.home and s.governors[r.home];if g and g.active and g.id==r.governor then g.prestige=I.Clamp(g.prestige+(g.archetype=='MILITARIST' and 2 or 1),0,100) end
   local plot=x and y and Map.GetPlot(x,y);local u=Players[pid]:GetUnitByID(uid)
   if defensive and enemy~=(GameDefines.BARBARIAN_PLAYER or 63) and ((plot and plot:GetOwner()==pid) or (u and u:GetPlot():GetOwner()==pid)) then
    if s.battleTurn~=I.Now() then s.battleTurn=I.Now();s.battleGains=0 end
    if s.battleGains<2 then I.Authority(s,1);s.battleGains=s.battleGains+1 end
   end
  end
  I.Commit(pid)
 end
 record(ap,au,dp,df,dm,false);record(dp,du,ap,af,am,true)
end)
if LuaEvents.ImperialRequest then LuaEvents.ImperialRequest.Add(function(pid,action,key,expected)
 local ok,message=I.Action(pid,action,key,expected)
 if LuaEvents.ImperialResponse then LuaEvents.ImperialResponse(pid,ok,message) end
end) end
if Events.LoadScreenClose then Events.LoadScreenClose.Add(function() for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if I.IsEmpire(pid) then I.Initialize(pid) end end end) end
