local I=MapModData.TheShatteredEmpire
I.Archetypes={'LOYALIST','MILITARIST','MERCHANT','POPULIST','AMBITIOUS'}
I.FirstNames={'Aurelius','Cassian','Lucius','Octavian','Severus','Valerian','Tiberius','Marcellus','Livia','Flavia','Claudia','Drusilla','Helena','Sabina','Aelia','Justina'}
I.LastNames={'Varro','Draven','Corvinus','Aquila','Voss','Maximus','Aurelian','Falco','Verus','Decimus','Thorne','Valens','Carinus','Severian','Nerva','Lucan'}
function I.Name(s) return I.FirstNames[I.Rand(s,#I.FirstNames)]..' '..I.LastNames[I.Rand(s,#I.LastNames)] end
function I.Appoint(s,c)
 local key=I.CityKey(c)
 local g={id=s.nextGovernor,key=key,city=c:GetID(),x=c:GetX(),y=c:GetY(),founded=c:GetGameTurnFounded(),name=I.Name(s),archetype=I.Archetypes[I.Rand(s,5)],loyalty=64+I.Rand(s,21),ambition=14+I.Rand(s,26),prestige=I.Rand(s,11)-1,appointed=I.Now(),relationship=0,history={},active=true,stage=0,critical=0,autonomy=false,actionNext=0,demandNext=I.Now()+I.Scale(15+I.Rand(s,10)),population=c:GetPopulation()}
 s.nextGovernor=s.nextGovernor+1;s.governors[key]=g
 I.History(s,'GOVERNOR',I.Text('HISTORY_APPOINTED',g.name,c:GetName(),I.Text(g.archetype)))
 return g
end
function I.Reconcile(s)
 local p=Players[s.pid];local seen={}
 for c in p:Cities() do
  local key=I.CityKey(c);seen[key]=true;local g=s.governors[key]
  if not c:IsCapital() then
   if not g or g.founded~=c:GetGameTurnFounded() then g=I.Appoint(s,c) end
   g.active=true;g.city=c:GetID();g.cityName=c:GetName()
  elseif g then g.active=false;g.demand=nil end
 end
 for key,g in pairs(s.governors) do if not seen[key] then g.active=false;g.demand=nil end end
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
 elseif d.kind=='RESOURCE' then local plot=Map.GetPlot(d.x,d.y);return plot and plot:GetOwner()==s.pid and plot:GetImprovementType()==d.improvement and not plot:IsImprovementPillaged()
 elseif d.kind=='CAMP' then local plot=Map.GetPlot(d.x,d.y);return plot and plot:GetImprovementType()~=I.ID('IMPROVEMENT_BARBARIAN_CAMP')
 end
 return false
end
function I.NewDemand(s,g)
 local c=I.City(g,s.pid);if not c then return end
 local choices={{kind='FUNDS'}};local p=Players[s.pid]
 if not c:GetGarrisonedUnit() then choices[#choices+1]={kind='GARRISON'} end
 local road=GameInfo.Builds[I.ID('BUILD_ROAD')]
 if not p:IsCapitalConnectedToCity(c) and road and (not road.PrereqTech or Teams[p:GetTeam()]:IsHasTech(I.ID(road.PrereqTech))) then choices[#choices+1]={kind='CONNECTION'} end
 if c:CanConstruct(I.ID('BUILDING_WALLS'),0,0,0) and not c:IsHasBuilding(I.ID('BUILDING_WALLS')) then choices[#choices+1]={kind='WALLS'} end
 if c:FoodDifference()>0 then choices[#choices+1]={kind='GROWTH',target=c:GetPopulation()+1} end
 if I.Wars(s.pid)==0 then choices[#choices+1]={kind='PEACE',peaceStart=I.Now()} end
 if c:IsHasBuilding(I.ID('BUILDING_IMPERIAL_PALACE')) then choices[#choices+1]={kind='AUTONOMY'} end
 local farms,possible=0,0
 I.Near(g.x,g.y,3,function(plot)
  if plot:IsRevealed(p:GetTeam()) and plot:GetOwner()==s.pid then
   if plot:GetImprovementType()==I.ID('IMPROVEMENT_FARM') then farms=farms+1
   elseif p:CanBuild(plot,I.ID('BUILD_FARM'),0,0) then possible=possible+1 end
   local resource=GameInfo.Resources[plot:GetResourceType(p:GetTeam())]
   if resource and resource.ResourceUsage==1 and plot:GetImprovementType()<0 then
    for build in GameInfo.Builds() do if build.ImprovementType and p:CanBuild(plot,build.ID,0,0) then
     for match in GameInfo.Improvement_ResourceTypes{ImprovementType=build.ImprovementType} do if match.ResourceType==resource.Type then choices[#choices+1]={kind='RESOURCE',x=plot:GetX(),y=plot:GetY(),improvement=I.ID(build.ImprovementType)};break end end
    end end
   end
  end
  if plot:IsRevealed(p:GetTeam()) and plot:GetImprovementType()==I.ID('IMPROVEMENT_BARBARIAN_CAMP') then choices[#choices+1]={kind='CAMP',x=plot:GetX(),y=plot:GetY()} end
 end)
 if possible>=2 then choices[#choices+1]={kind='FARMS',target=farms+2} end
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
function I.DemandTick(s)
 local created=0
 for _,g in ipairs(I.Provinces(s)) do
  if not g.faction then
   if g.demand then
    if g.demand.kind=='PEACE' and I.Wars(s.pid)>0 then g.demand.peaceStart=I.Now() end
    if I.DemandComplete(s,g) then I.FinishDemand(s,g,true)
    elseif I.Now()>=g.demand.deadline then I.FinishDemand(s,g,false) end
   elseif I.Now()>=g.demandNext and created<1 then I.NewDemand(s,g);created=created+1 end
  end
 end
end
