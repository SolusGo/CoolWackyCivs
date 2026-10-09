local I=MapModData.TheShatteredEmpire
I.ReformNames={'MONARCHY','FEDERATION','DICTATORSHIP'}
I.Effects={'LOYALIST','MILITARIST','MERCHANT','POPULIST','AMBITIOUS','DISCONTENT','DEFIANCE','REVOLT','FEDERATION','MONARCHY','COUNCIL','RESTORATION','ADMINISTRATION'}
function I.Building(c,name,on)
 local id=I.ID('BUILDING_IMPERIAL_'..name)
 if id and c:GetNumRealBuilding(id)~=(on and 1 or 0) then c:SetNumRealBuilding(id,on and 1 or 0) end
end
function I.ClearCity(c) for _,name in ipairs(I.Effects) do I.Building(c,name,false) end end
function I.ApplyEffects(s,work)
 if I.Applying then return end;I.Applying=true
 local p=Players[s.pid];local w=work or I.Pending(s.pid)
 local mode=s.reform..':'..tostring(s.restorationActive==true)..':'..tostring(I.Now()<(s.councilUntil or 0))
 local function apply(c)
  local key=I.CityKey(c)
  local g=s.governors[I.CityKey(c)];if g and (not g.active or g.founded~=c:GetGameTurnFounded()) then g=nil end
  local signature=mode..':'..tostring(c:IsCapital())..':'..c:GetGameTurnFounded()..':'..(g and (g.id..':'..g.archetype..':'..g.stage..':'..tostring(g.faction)..':'..tostring(g.autonomy)) or '')
  if work and w.cityCache[key]==signature then return end
  for _,name in ipairs(I.Effects) do
   local on=false
   if name=='MONARCHY' then on=c:IsCapital() and s.reform=='MONARCHY'
   elseif name=='COUNCIL' then on=I.Now()<(s.councilUntil or 0)
   elseif name=='RESTORATION' then on=s.restorationActive
   elseif name=='ADMINISTRATION' then on=not c:IsCapital()
   elseif g then
    if name=='FEDERATION' then on=g.autonomy and s.reform=='FEDERATION'
    elseif name=='DISCONTENT' then on=g.stage==1
    elseif name=='DEFIANCE' then on=g.stage==2
    elseif name=='REVOLT' then on=g.faction~=nil
    else on=name==g.archetype and not g.faction end
   end
   I.Building(c,name,on)
  end
  w.cityCache[key]=signature
 end
 if not work or w.allCities or w.cityMode~=mode then
  local seen={};for c in p:Cities() do seen[I.CityKey(c)]=true;apply(c) end
  for key in pairs(w.cityCache) do if not seen[key] then w.cityCache[key]=nil end end
 else for key in pairs(w.cities) do local x,y=key:match('^(%d+):(%d+)$');local plot=x and Map.GetPlot(tonumber(x),tonumber(y));local c=plot and plot:GetPlotCity()
  if c and c:GetOwner()==s.pid then apply(c) else w.cityCache[key]=nil end
 end end
 w.cities={};w.allCities=nil;w.cityMode=mode
 I.Applying=false
end
function I.CharterCost(s,g) return I.GoldCost(s,g,g.faction and 2 or .5),g.faction and 10 or 5 end
function I.CanAction(pid,action,key,expected)
 if not I.IsEmpire(pid) or not Players[pid]:IsAlive() then return false,'INVALID' end
 local s=I.State(pid);local p=Players[pid];local g=key and s.governors[key]
 if action=='REFORM' then
  local valid=false;for _,name in ipairs(I.ReformNames) do if name==key then valid=true end end
  if not valid or key==s.reform then return false,'INVALID' end
  if p:GetCurrentEra()<1 then return false,'ERA_REQUIRED' end
  if I.Now()<s.reformNext then return false,'COOLDOWN' end
  if s.authority<10 then return false,'AUTHORITY_REQUIRED' end
  return true,'REFORM_COST'
 elseif action=='SUCCESSION' then
  if not s.succession or s.succession.id~=expected or not s.succession.candidates[key] then return false,'INVALID' end
  return true,'READY'
 end
 if not g or not g.active or not I.City(g,pid) or (expected and expected~=g.id) then return false,'INVALID' end
 if I.Now()<g.actionNext then return false,'COOLDOWN' end
 local demand=g.demand
 if action=='REFUSE' then return demand~=nil and I.DemandFeasible(s,g,demand),'READY' end
 if action=='REPLACE' then return not g.faction and s.authority>=8,g.faction and 'REBELLION_REQUIRED' or 'REPLACE_COST' end
 if action=='CHARTER' then
  if not I.City(g,pid):IsHasBuilding(I.ID('BUILDING_IMPERIAL_PALACE')) then return false,'PALACE_REQUIRED' end
  if g.autonomy and not g.faction then return false,'INVALID' end
  if g.faction then local f=s.factions[g.faction];if not f or not f.active or f.governor~=g.id then return false,'INVALID' end
  elseif g.stage>=2 or g.loyalty<25 then return false,'INVALID' end
  local gold,authority=I.CharterCost(s,g)
  if p:GetGold()<gold then return false,'GOLD_REQUIRED' end
  if s.authority<authority then return false,'AUTHORITY_REQUIRED' end
  return true,g.faction and 'SETTLEMENT_COST' or 'CHARTER_COST'
 end
 if action=='RECONCILE' or action=='CONCESSION' then
  local f=g.faction and s.factions[g.faction]
  if not f or not f.active or f.governor~=g.id then return false,'REBELLION_REQUIRED' end
  if action=='RECONCILE' then return s.authority>=15,'RECONCILE_COST' end
 end
 if action=='FUND' and (not demand or not I.DemandFeasible(s,g,demand)) then return false,'INVALID' end
 if action~='BRIBE' and action~='FUND' and action~='CONCESSION' then return false,'INVALID' end
 local cost=action=='FUND' and demand.cost or I.GoldCost(s,g,action=='CONCESSION' and 2 or 1)
 if p:GetGold()<cost then return false,'GOLD_REQUIRED' end
 return true,'READY'
end
function I.Action(pid,action,key,expected)
 local ok,reason=I.CanAction(pid,action,key,expected);if not ok then return false,I.Text(reason) end
 local s=I.State(pid);if s.actionBusy then return false,I.Text('INVALID') end;s.actionBusy=true
 local p=Players[pid];local g=key and s.governors[key]
 if action=='REFORM' then
  s.reform=key;s.reformNext=I.Now()+I.Scale(30);I.Authority(s,-10)
  I.Reign(s).reforms=I.Reign(s).reforms+1
  I.History(s,'REFORM',I.Text('HISTORY_REFORM',I.Text(key)))
 elseif action=='SUCCESSION' then I.SelectSuccessor(s,key)
 elseif action=='REPLACE' then
  I.Authority(s,-8);I.PoliticalRecord(g,I.Text('REPLACED'));local oldName=g.name
  local replacement=I.Appoint(s,I.City(g,pid));replacement.loyalty=math.max(55,replacement.loyalty-10);replacement.actionNext=I.Now()+I.Scale(15)
  for _,r in pairs(s.units) do if r.home==key then r.governor=replacement.id;r.oath=math.max(0,r.oath-5) end end
  I.City(replacement,pid):ChangeResistanceTurns(1)
  I.History(s,'GOVERNOR',I.Text('HISTORY_REPLACED',oldName,replacement.name))
 elseif action=='REFUSE' then I.FinishDemand(s,g,false);g.actionNext=I.Now()+I.Scale(10)
 elseif action=='CHARTER' then
  local gold,authority=I.CharterCost(s,g);p:ChangeGold(-gold);I.Authority(s,-authority)
  if g.faction then I.ResolveFaction(s,s.factions[g.faction],'AUTONOMY')
  else g.autonomy=true;g.loyalty=I.Clamp(g.loyalty+15,0,100);g.ambition=I.Clamp(g.ambition+12,0,100) end
  g.actionNext=I.Now()+I.Scale(10)
  if g.demand and g.demand.kind=='AUTONOMY' then I.FinishDemand(s,g,true) end
  I.History(s,'DECISION',I.Text('HISTORY_CHARTER',g.name))
 elseif action=='RECONCILE' then
  I.Authority(s,-15);I.ResolveFaction(s,s.factions[g.faction],'RECONCILED');g.actionNext=I.Now()+I.Scale(15)
 else
  local cost=action=='FUND' and g.demand.cost or I.GoldCost(s,g,action=='CONCESSION' and 2 or 1)
  p:ChangeGold(-cost);g.loyalty=I.Clamp(g.loyalty+12,0,100);g.relationship=I.Clamp(g.relationship+5,-100,100);g.actionNext=I.Now()+I.Scale(10)
  if action=='FUND' then I.FinishDemand(s,g,true)
  elseif action=='CONCESSION' then I.ResolveFaction(s,s.factions[g.faction],'CONCESSION') end
  I.PoliticalRecord(g,I.Text('HISTORY_PAYMENT',cost));I.History(s,'DECISION',I.Text('HISTORY_PAID',g.name,cost))
 end
 s.actionBusy=nil;if g then I.DirtyCity(s,g.key) end;I.RestorationTick(s);I.Commit(pid)
 return true,I.Text('ACTION_DONE')
end
function I.RestorationTick(s)
 local provinces=I.Provinces(s);local sum,rebels=0,0
 for _,g in ipairs(provinces) do sum=sum+g.loyalty;if g.faction then rebels=rebels+1 end end
 s.averageLoyalty=#provinces>0 and sum/#provinces or 100
 if s.authority<20 and not s.inCollapse then s.collapseSeen=true;s.inCollapse=true;s.collapseResolved=false;I.History(s,'COLLAPSE',I.Text('HISTORY_COLLAPSE')) end
 if s.inCollapse and s.authority>=40 and rebels==0 and not s.war then s.inCollapse=false;s.collapseResolved=true end
 local stable=s.authority>=75 and s.averageLoyalty>=80 and rebels==0 and not s.war and not s.succession
 if stable and s.collapseResolved then s.restorationSince=s.restorationSince or I.Now() else s.restorationSince=nil end
 if not s.restored and s.restorationSince and I.Now()-s.restorationSince>=I.Scale(20) then
  s.restored=true;I.History(s,'RESTORATION',I.Text('HISTORY_RESTORED'));I.Notify(s,I.Text('RESTORED_TITLE'),I.Text('RESTORED_NOTICE'))
 end
 s.restorationActive=s.restored and s.authority>=60 and s.averageLoyalty>=60 and rebels==0 and not s.war and not s.inCollapse
end
