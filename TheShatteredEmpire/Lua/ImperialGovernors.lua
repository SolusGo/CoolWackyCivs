local I=MapModData.TheShatteredEmpire
I.Archetypes={'LOYALIST','MILITARIST','MERCHANT','POPULIST','AMBITIOUS'}
I.FirstNames={'Aurelius','Cassian','Lucius','Octavian','Severus','Valerian','Tiberius','Marcellus','Livia','Flavia','Claudia','Drusilla','Helena','Sabina','Aelia','Justina'}
I.LastNames={'Varro','Draven','Corvinus','Aquila','Voss','Maximus','Aurelian','Falco','Verus','Decimus','Thorne','Valens','Carinus','Severian','Nerva','Lucan'}
function I.Name(s) return I.FirstNames[I.Rand(s,#I.FirstNames)]..' '..I.LastNames[I.Rand(s,#I.LastNames)] end
function I.Appoint(s,c)
 local key=I.CityKey(c)
 local prior=s.governors[key]
 local g={id=s.nextGovernor,key=key,city=c:GetID(),x=c:GetX(),y=c:GetY(),founded=c:GetGameTurnFounded(),name=I.Name(s),archetype=I.Archetypes[I.Rand(s,5)],loyalty=64+I.Rand(s,21),ambition=14+I.Rand(s,26),prestige=I.Rand(s,11)-1,appointed=I.Now(),relationship=0,history={},active=true,stage=0,critical=0,autonomy=false,actionNext=0,demandNext=I.Now()+I.Scale(15+I.Rand(s,10)),population=c:GetPopulation()}
 s.nextGovernor=s.nextGovernor+1;s.governors[key]=g
 if prior and prior.active and prior.founded==g.founded then g.autonomy=prior.autonomy;g.settlement=prior.settlement end
 I.DirtyCity(s,key)
 I.History(s,'GOVERNOR',I.Text('HISTORY_APPOINTED',g.name,c:GetName(),I.Text(g.archetype)))
 return g
end
function I.Reconcile(s)
 local p=Players[s.pid];local seen={}
 for c in p:Cities() do
  local key=I.CityKey(c);seen[key]=true;local g=s.governors[key]
  if not c:IsCapital() then
   if not g or not g.active or g.founded~=c:GetGameTurnFounded() then g=I.Appoint(s,c) end
   g.active=true;g.city=c:GetID();g.cityName=c:GetName()
  elseif g then if g.active then I.DirtyCity(s,key) end;g.active=false;g.demand=nil end
 end
 for key,g in pairs(s.governors) do if not seen[key] then if g.active then I.DirtyCity(s,key) end;g.active=false;g.demand=nil end end
 -- Compact retired governors; the bounded chronicle retains their important deeds.
 local inactive={};for key,g in pairs(s.governors) do if not g.active and not g.faction then inactive[#inactive+1]=key end end
 table.sort(inactive,function(a,b) return s.governors[a].id<s.governors[b].id end)
 for n=1,math.max(0,#inactive-50) do s.governors[inactive[n]]=nil end
end
function I.GoldCost(s,g,multiplier)
 local c=I.City(g,s.pid);local income=math.max(0,Players[s.pid]:CalculateGoldRate())
 return math.ceil((30+(c and c:GetPopulation() or 1)*8+math.min(100,income)*2)*I.Speed*(multiplier or 1))
end
function I.DemandComplete(s,g)
 local d=g.demand;local c=I.City(g,s.pid);if not d or not c then return false end
 if d.kind=='GARRISON' then return c:GetGarrisonedUnit()~=nil
 elseif d.kind=='CONNECTION' then return Players[s.pid]:IsCapitalConnectedToCity(c)
 elseif d.kind=='WALLS' then return c:IsHasBuilding(I.ID('BUILDING_WALLS'))
 elseif d.kind=='GROWTH' then return c:GetPopulation()>=d.target
 elseif d.kind=='PEACE' then return I.Wars(s.pid)==0 and I.Now()>=(d.peaceStart or I.Now())+I.Scale(5)
 elseif d.kind=='FARMS' then
  local n=0;I.Near(g.x,g.y,3,function(plot) if plot:GetOwner()==s.pid and plot:GetImprovementType()==I.ID('IMPROVEMENT_FARM') and not plot:IsImprovementPillaged() then n=n+1 end end)
  return n>=d.target
 elseif d.kind=='RESOURCE' then local plot=Map.GetPlot(d.x,d.y);return plot and plot:GetOwner()==s.pid and (not d.resource or plot:GetResourceType(Players[s.pid]:GetTeam())==d.resource) and plot:GetImprovementType()==d.improvement and not plot:IsImprovementPillaged()
 elseif d.kind=='CAMP' then local plot=Map.GetPlot(d.x,d.y);return plot and plot:GetImprovementType()~=I.ID('IMPROVEMENT_BARBARIAN_CAMP')
 end
 return false
end
local function canBuild(s,plot,build)
 if not plot or not build or not plot:IsRevealed(Players[s.pid]:GetTeam()) or plot:GetOwner()~=s.pid then return false end
 local row=GameInfo.Builds[build];if not row then return false end
 if row.PrereqTech and not Teams[Players[s.pid]:GetTeam()]:IsHasTech(I.ID(row.PrereqTech)) then return false end
 return Players[s.pid]:CanBuild(plot,build,0,0)
end
local function farmCapacity(s,g)
 local farms,possible=0,0
 I.Near(g.x,g.y,3,function(plot)
  if plot:GetOwner()==s.pid and plot:IsRevealed(Players[s.pid]:GetTeam()) then
   if plot:GetImprovementType()==I.ID('IMPROVEMENT_FARM') and not plot:IsImprovementPillaged() then farms=farms+1
   elseif canBuild(s,plot,I.ID(plot:GetImprovementType()==I.ID('IMPROVEMENT_FARM') and plot:IsImprovementPillaged() and 'BUILD_REPAIR' or 'BUILD_FARM')) then possible=possible+1 end
  end
 end)
 return farms,possible
end
function I.DemandFeasible(s,g,d)
 local c=I.City(g,s.pid);if not c or not d then return false end
 if d.kind=='FUNDS' or d.kind=='GARRISON' or d.kind=='PEACE' then return true
 elseif d.kind=='AUTONOMY' then return not g.autonomy and g.stage<2 and g.loyalty>=25 and c:IsHasBuilding(I.ID('BUILDING_IMPERIAL_PALACE'))
 elseif d.kind=='GROWTH' then return c:GetPopulation()>=d.target or c:FoodDifference()>0
 elseif d.kind=='WALLS' then return c:IsHasBuilding(I.ID('BUILDING_WALLS')) or c:CanConstruct(I.ID('BUILDING_WALLS'),1,0,0)
 elseif d.kind=='CONNECTION' then
  local road=GameInfo.Builds[I.ID('BUILD_ROAD')];return I.Capital(s.pid)~=nil and road~=nil and (not road.PrereqTech or Teams[Players[s.pid]:GetTeam()]:IsHasTech(I.ID(road.PrereqTech)))
 elseif d.kind=='FARMS' then local farms,possible=farmCapacity(s,g);return farms+possible>=d.target
 elseif d.kind=='RESOURCE' then
  local plot=Map.GetPlot(d.x,d.y);if not plot or plot:GetOwner()~=s.pid or not plot:IsRevealed(Players[s.pid]:GetTeam()) then return false end
  local resource=plot:GetResourceType(Players[s.pid]:GetTeam());if resource<0 or (d.resource and d.resource~=resource) then return false end
  local row=GameInfo.Resources[resource];local improvement
  for build in GameInfo.Builds() do if build.ImprovementType and I.ID(build.ImprovementType)==d.improvement then improvement=build.ImprovementType;break end end
  local matches=false;if row and row.ResourceUsage==1 and improvement then for match in GameInfo.Improvement_ResourceTypes{ImprovementType=improvement} do if match.ResourceType==row.Type then matches=true;break end end end
  if not matches then return false end
  if I.DemandComplete(s,g) then return true end
  if plot:GetImprovementType()==d.improvement and plot:IsImprovementPillaged() then return canBuild(s,plot,I.ID('BUILD_REPAIR')) end
  for build in GameInfo.Builds() do if build.ImprovementType and I.ID(build.ImprovementType)==d.improvement and canBuild(s,plot,build.ID) then return true end end
 elseif d.kind=='CAMP' then
  local plot=Map.GetPlot(d.x,d.y);return plot~=nil and plot:IsRevealed(Players[s.pid]:GetTeam()) and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable() and (plot:GetOwner()==-1 or plot:GetOwner()==s.pid)
 end
 return false
end
function I.CancelDemand(s,g)
 if not g.demand then return end
 I.History(s,'DEMAND',I.Text('HISTORY_DEMAND_CANCELLED',g.name,I.Text('DEMAND_'..g.demand.kind)))
 g.demand=nil;g.demandNext=I.Now()+I.Scale(22)
end
function I.NewDemand(s,g)
 local c=I.City(g,s.pid);if not c or g.demand or g.faction then return end
 local choices={{kind='FUNDS'}};local p=Players[s.pid]
 if not c:GetGarrisonedUnit() then choices[#choices+1]={kind='GARRISON'} end
 local road=GameInfo.Builds[I.ID('BUILD_ROAD')]
 if not p:IsCapitalConnectedToCity(c) and road and (not road.PrereqTech or Teams[p:GetTeam()]:IsHasTech(I.ID(road.PrereqTech))) then choices[#choices+1]={kind='CONNECTION'} end
 if c:CanConstruct(I.ID('BUILDING_WALLS'),0,0,0) and not c:IsHasBuilding(I.ID('BUILDING_WALLS')) then choices[#choices+1]={kind='WALLS'} end
 if c:FoodDifference()>0 then choices[#choices+1]={kind='GROWTH',target=c:GetPopulation()+1} end
 if I.Wars(s.pid)==0 then choices[#choices+1]={kind='PEACE',peaceStart=I.Now()} end
 if not g.autonomy and c:IsHasBuilding(I.ID('BUILDING_IMPERIAL_PALACE')) then choices[#choices+1]={kind='AUTONOMY'} end
 local farms,possible=farmCapacity(s,g)
 I.Near(g.x,g.y,3,function(plot)
  if plot:IsRevealed(p:GetTeam()) and plot:GetOwner()==s.pid then
   local resource=GameInfo.Resources[plot:GetResourceType(p:GetTeam())]
   if resource and resource.ResourceUsage==1 and plot:GetImprovementType()<0 then
    for build in GameInfo.Builds() do if build.ImprovementType and canBuild(s,plot,build.ID) then
     for match in GameInfo.Improvement_ResourceTypes{ImprovementType=build.ImprovementType} do if match.ResourceType==resource.Type then choices[#choices+1]={kind='RESOURCE',x=plot:GetX(),y=plot:GetY(),resource=resource.ID,improvement=I.ID(build.ImprovementType)};break end end
    end end
   end
  end
  if plot:IsRevealed(p:GetTeam()) and plot:GetImprovementType()==I.ID('IMPROVEMENT_BARBARIAN_CAMP') then choices[#choices+1]={kind='CAMP',x=plot:GetX(),y=plot:GetY()} end
 end)
 if possible>=2 then choices[#choices+1]={kind='FARMS',target=farms+2} end
 local feasible={};for _,d in ipairs(choices) do if I.DemandFeasible(s,g,d) then feasible[#feasible+1]=d end end;choices=feasible
 local d=choices[I.Rand(s,#choices)];d.created=I.Now();d.deadline=I.Now()+I.Scale(25);d.cost=I.GoldCost(s,g)
 g.demand=d;I.Notify(s,I.Text('DEMAND_TITLE'),I.Text('DEMAND_NOTICE',g.name,c:GetName(),I.Text('DEMAND_'..d.kind),d.deadline),g)
end
function I.FinishDemand(s,g,success)
 if not g.demand then return end
 local kind=g.demand.kind;g.demand=nil;g.demandNext=I.Now()+I.Scale(s.reform=='FEDERATION' and 35 or 22)
 g.loyalty=I.Clamp(g.loyalty+(success and 10 or -12),0,100);g.ambition=I.Clamp(g.ambition+(success and 0 or 6),0,100)
 if success then I.Authority(s,2);g.prestige=I.Clamp(g.prestige+3,0,100) end
 I.PoliticalRecord(g,I.Text(success and 'DEMAND_MET' or 'DEMAND_FAILED',I.Text('DEMAND_'..kind)))
 I.History(s,'DEMAND',I.Text(success and 'HISTORY_DEMAND_MET' or 'HISTORY_DEMAND_FAILED',g.name,I.Text('DEMAND_'..kind)))
end
function I.CheckDemand(s,g)
 if not g or not g.demand then return end
 if g.demand.kind=='PEACE' and I.Wars(s.pid)>0 then g.demand.peaceStart=I.Now() end
 if not I.DemandFeasible(s,g,g.demand) then I.CancelDemand(s,g)
 elseif I.DemandComplete(s,g) then I.FinishDemand(s,g,true)
 elseif I.Now()>=g.demand.deadline then I.FinishDemand(s,g,false) end
end
function I.DemandTick(s)
 local created=s.demandCreatedTurn==I.Now() and 1 or 0
 for _,g in ipairs(I.Provinces(s)) do
  if not g.faction then
   if g.demand then
    I.CheckDemand(s,g)
   elseif I.Now()>=g.demandNext and created<1 then I.NewDemand(s,g);if g.demand then created=created+1;s.demandCreatedTurn=I.Now() end end
  end
 end
end
