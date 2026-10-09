local I=MapModData.TheShatteredEmpire
local function valid(s,plot)
 if not plot or plot:IsWater() or plot:IsMountain() or plot:IsImpassable() or plot:IsCity() or plot:GetNumUnits()>0 then return false end
 if plot:GetOwner()~=-1 and plot:GetOwner()~=s.pid then return false end
 -- setRevealed triggers wonder discovery even with terrain-only visibility.
 local feature=GameInfo.Features[plot:GetFeatureType()]
 if feature and (feature.NaturalWonder==true or feature.NaturalWonder==1 or feature.PseudoNaturalWonder==true or feature.PseudoNaturalWonder==1 or feature.NoCity==true or feature.NoCity==1) then return false end
 local range=GameDefines.MIN_CITY_RANGE or 3
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do local other=Players[pid]
  if other and other:IsAlive() then
   local start=other:GetStartingPlot()
   if pid~=s.pid and start and Map.PlotDistance(start:GetX(),start:GetY(),plot:GetX(),plot:GetY())<=range+3 then return false end
   for c in other:Cities() do if Map.PlotDistance(c:GetX(),c:GetY(),plot:GetX(),plot:GetY())<=range then return false end end
  end
 end
 return true
end
local function restoreFog(plot,e,team)
 -- A successfully founded city (or legitimate sight gained in a callback)
 -- keeps its native visibility. Failed probes restore only our terrain bit.
 if e.revealWasHidden and plot and not plot:IsCity() and plot:GetVisibilityCount(team)==0 then plot:SetRevealed(team,false,1,-1) end
end
local function land(plot) return plot and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable() end
-- Flood only the local search radius. A sea or mountain barrier cannot be crossed.
local function accessible(cap)
 local origin=Map.GetPlot(cap:GetX(),cap:GetY());local seen={[I.CityKey(origin)]=origin};local queue={origin};local head=1
 while head<=#queue do local plot=queue[head];head=head+1
  I.Near(plot:GetX(),plot:GetY(),1,function(adj)
   local key=I.CityKey(adj)
   if not seen[key] and land(adj) and Map.PlotDistance(cap:GetX(),cap:GetY(),adj:GetX(),adj:GetY())<=8 then seen[key]=adj;queue[#queue+1]=adj end
  end)
 end
 return seen
end
function I.StartCity(s,c)
 for slot=1,2 do local e=s.entitlements[slot]
  if e and e.kind=='pendingCity' and c:GetX()==e.x and c:GetY()==e.y and c:GetGameTurnFounded()==e.turn then
   c:SetName(I.Text(slot==1 and 'PROVINCE_I' or 'PROVINCE_II'));c:SetPopulation(1,true)
   s.entitlements[slot]={kind='city',key=I.CityKey(c)};return true
  end
 end
end
function I.StartSettler(s,u)
 if not u or u:GetUnitType()~=I.ID('UNIT_SETTLER') then return false end
 for slot=1,2 do local e=s.entitlements[slot]
  if e and e.kind=='pendingSettler' and u:GetGameTurnCreated()==e.turn and ((e.existing and not e.existing[u:GetID()]) or (not e.existing and u:GetX()==e.x and u:GetY()==e.y)) then
   s.entitlements[slot]={kind='settler',unit=u:GetID(),birth=u:GetGameTurnCreated()};return true
  end
 end
 return false
end
function I.Start(s)
 if s.startComplete or s.startBusy then return end
 local p=Players[s.pid];local cap=p and p:GetCapitalCity();if not cap then return end
 -- Existing saves receive politics, never a mid-campaign free empire.
 if not s.startBegun and (not s.startEligible or cap:GetGameTurnFounded()~=I.Now()) then s.startComplete=true;return end
 s.startBusy=true
 if not s.startBegun then
  s.startBegun=true;cap:SetPopulation(math.max(2,cap:GetPopulation()),true)
  I.History(s,'FOUNDING',I.Text('HISTORY_FOUNDING',cap:GetName()))
 end
 local reachable=accessible(cap)
 for slot=1,2 do
  local e=s.entitlements[slot]
  if e and e.kind=='pendingCity' then local plot=Map.GetPlot(e.x,e.y);local c=plot and plot:GetPlotCity()
   if c and c:GetGameTurnFounded()==e.turn then
    if c:GetOwner()==s.pid then I.StartCity(s,c) else s.entitlements[slot]={kind='city',key=I.CityKey(c)} end
   else restoreFog(plot,e,p:GetTeam());s.entitlements[slot]=nil end
  elseif e and e.kind=='pendingSettler' then
   for u in p:Units() do if I.StartSettler(s,u) then break end end
   if s.entitlements[slot].kind=='pendingSettler' then s.entitlements[slot]=nil end
  end
  if not s.entitlements[slot] then
  local choices={}
  I.Near(cap:GetX(),cap:GetY(),8,function(plot)
   if reachable[I.CityKey(plot)] and valid(s,plot) then
    local food=0;I.Near(plot:GetX(),plot:GetY(),1,function(adj) if not adj:IsWater() and not adj:IsMountain() then food=food+1 end;if adj:IsRevealed(p:GetTeam()) and adj:GetResourceType(p:GetTeam())>=0 then food=food+2 end end)
    choices[#choices+1]={plot=plot,score=food-Map.PlotDistance(cap:GetX(),cap:GetY(),plot:GetX(),plot:GetY())}
   end
  end)
  table.sort(choices,function(a,b) if a.score~=b.score then return a.score>b.score end;if a.plot:GetX()~=b.plot:GetX() then return a.plot:GetX()<b.plot:GetX() end;return a.plot:GetY()<b.plot:GetY() end)
  local c
  for _,choice in ipairs(choices) do
   local plot=choice.plot;local team=p:GetTeam()
   local pending={kind='pendingCity',x=plot:GetX(),y=plot:GetY(),turn=I.Now(),revealWasHidden=not plot:IsRevealed(team)}
   s.entitlements[slot]=pending -- Persist intent before any native callback.
   local ok,err=pcall(function()
    -- CP CanFound and Found both require revelation. Only this candidate is
    -- exposed; integer 1 suppresses owner/improvement/route discovery, and no
    -- scouting unit is supplied. Native founding still validates every rule.
    if pending.revealWasHidden then plot:SetRevealed(team,true,1,-1) end
    if p:CanFound(plot:GetX(),plot:GetY()) then p:Found(plot:GetX(),plot:GetY()) end
   end)
   c=plot:GetPlotCity();restoreFog(plot,pending,team)
   if c then
    if c:GetOwner()==s.pid then I.StartCity(s,c) else s.entitlements[slot]={kind='city',key=I.CityKey(c)} end
   else s.entitlements[slot]=nil end
   if not ok then s.startBusy=nil;error(err,0) end
   if c then break end
  end
  if c then
   if c:GetOwner()==s.pid then I.StartCity(s,c) end
  else
   local existing={};for u in p:Units() do existing[u:GetID()]=true end
   s.entitlements[slot]={kind='pendingSettler',x=cap:GetX(),y=cap:GetY(),turn=I.Now(),existing=existing}
   local u=p:InitUnit(I.ID('UNIT_SETTLER'),cap:GetX(),cap:GetY(),UnitAITypes.UNITAI_SETTLE)
   if u then s.entitlements[slot]={kind='settler',unit=u:GetID(),birth=u:GetGameTurnCreated()};u:JumpToNearestValidPlot() else s.entitlements[slot]=nil end
  end
 end end
 local function complete(e) return e and (e.kind=='city' or e.kind=='settler') end
 s.startBusy=nil;s.startComplete=complete(s.entitlements[1]) and complete(s.entitlements[2]) or false
end
