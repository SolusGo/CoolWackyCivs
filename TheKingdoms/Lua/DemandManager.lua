local K=MapModData.TheKingdoms
local buildings={BARRACKS='BUILDING_BARRACKS',MARKET='BUILDING_MARKET',LIBRARY='BUILDING_LIBRARY',SHRINE='BUILDING_SHRINE',WALL='BUILDING_KINGDOMS_WALL',CULTURE='BUILDING_MONUMENT'}
function K.DemandText(s,d)
 local text=K.Text('DEMAND_'..d.kind,d.target)
 if d.rival and Players[d.rival] then
  local info=GameInfo.Civilizations[Players[d.rival]:GetCivilizationType()]
  if info then text=text..' - '..Locale.ConvertTextKey(info.ShortDescription) end
 elseif d.tech and GameInfo.Technologies[d.tech] then text=text..' - '..Locale.ConvertTextKey(GameInfo.Technologies[d.tech].Description) end
 return text
end
local function countPlots(pid,k,improvement,resource)
 local n=0
 K.NearPlots(k.x,k.y,3,function(plot)
  if plot:GetOwner()==pid and plot:GetWorkingCity() and K.CityKey(plot:GetWorkingCity())==k.id then
   if improvement and plot:GetImprovementType()==improvement and not plot:IsImprovementPillaged() then n=n+1 end
   if resource and plot:GetResourceType(Players[pid]:GetTeam())>=0 and plot:GetImprovementType()>=0 and not plot:IsImprovementPillaged() then
    local r=GameInfo.Resources[plot:GetResourceType(Players[pid]:GetTeam())]
    if r and r.ResourceClassType=='RESOURCECLASS_RUSH' then n=n+1 elseif r and r.ResourceClassType=='RESOURCECLASS_MODERN' then n=n+1 end
   end
  end
 end)
 return n
end
local function buildable(pid,k,build)
 local n=0;local p=Players[pid]
 if not build or not p.CanBuild then return 0 end
 K.NearPlots(k.x,k.y,3,function(plot)
  if plot:GetOwner()==pid and plot:GetWorkingCity() and K.CityKey(plot:GetWorkingCity())==k.id and p:CanBuild(plot,build,false,false) then n=n+1 end
 end)
 return n
end
local function rival(pid,war)
 local p=Players[pid];local team=Teams[p:GetTeam()]
 for i=0,GameDefines.MAX_MAJOR_CIVS-1 do
  local other=Players[i]
  if other and i~=pid and other:IsAlive() and other:GetTeam()~=p:GetTeam() and team:IsHasMet(other:GetTeam()) then
   if war and team:IsAtWar(other:GetTeam()) or not war and team:CanDeclareWar(other:GetTeam()) then return i end
  end
 end
end
function K.DemandProgress(s,h,d)
 local p=Players[s.pid];local k=s.kingdoms[h.kingdom];local c=K.City(k)
 if not c or not k.active then return 0 end
 if d.building then return c:GetNumBuilding(d.building)>0 and 1 or 0 end
 if d.kind=='FARMS' or d.kind=='MINE' then return math.max(0,countPlots(s.pid,k,d.improvement)-d.baseline) end
 if d.kind=='RESOURCE' then return math.max(0,countPlots(s.pid,k,nil,true)-d.baseline) end
 if d.kind=='GROW' then return c:GetPopulation() end
 if d.kind=='GOLD' then return p:GetGold() end
 if d.kind=='FAITH' then return p:GetFaith() end
 if d.kind=='GPT' then return p:CalculateGoldRate() end
 if d.kind=='TECH' then return Teams[p:GetTeam()]:IsHasTech(d.tech) and 1 or 0 end
 if d.kind=='WAR' then return Teams[p:GetTeam()]:IsAtWar(Players[d.rival]:GetTeam()) and 1 or 0 end
 if d.kind=='PEACE' then return not Teams[p:GetTeam()]:IsAtWar(Players[d.rival]:GetTeam()) and 1 or 0 end
 if d.kind=='WAR_TURNS' then return (s.counters['war'..d.rival] or 0)-d.baseline end
 if d.kind=='EXPAND' then return K.KingdomCount(s)-d.baseline end
 if d.kind=='TRADE' then return #(p:GetTradeRoutes() or {}) end
 if d.kind=='GARRISON' then
  local n=0;for u in p:Units() do if u:IsCombatUnit() and Map.PlotDistance(k.x,k.y,u:GetX(),u:GetY())<=2 then n=n+1 end end;return n
 end
 if d.kind=='CAMP' then return (s.counters.camps or 0)-d.baseline end
 return (s.counters[d.counter] or 0)-d.baseline
end
function K.DemandValid(s,h,d)
 local k=s.kingdoms[h.kingdom];if not k or not k.active then return false end
 if d.rival and (not Players[d.rival] or not Players[d.rival]:IsAlive()) then return false end
 if d.kind=='TECH' and not GameInfo.Technologies[d.tech] then return false end
 if d.kind=='WAR' and not Teams[Players[s.pid]:GetTeam()]:IsAtWar(Players[d.rival]:GetTeam()) and not Teams[Players[s.pid]:GetTeam()]:CanDeclareWar(Players[d.rival]:GetTeam()) then return false end
 if d.kind=='FARMS' or d.kind=='MINE' then
  local progress=K.DemandProgress(s,h,d)
  if progress<d.target and progress+buildable(s.pid,k,d.build)<d.target then return false end
 end
 if d.building then local c=K.City(k);if c:GetNumBuilding(d.building)==0 and not c:CanConstruct(d.building) then return false end end
 return true
end
function K.MakeDemand(s,h,kind)
 local p=Players[s.pid];local k=s.kingdoms[h.kingdom];local c=K.City(k);if not c then return end
 local d={kind=kind,issued=K.Now(),expires=K.Now()+K.Scale(25+K.Rand(s,11)),target=1,baseline=0}
 if buildings[kind] then
  d.building=K.ID(buildings[kind]);if not d.building or c:GetNumBuilding(d.building)>0 or not c:CanConstruct(d.building) then return end
 elseif kind=='FARMS' or kind=='MINE' then
  d.improvement=K.ID(kind=='FARMS' and 'IMPROVEMENT_FARM' or 'IMPROVEMENT_MINE')
  d.build=K.ID(kind=='FARMS' and 'BUILD_FARM' or 'BUILD_MINE');d.target=kind=='FARMS' and 2 or 1
  if buildable(s.pid,k,d.build)<d.target then return end
  d.baseline=countPlots(s.pid,k,d.improvement)
 elseif kind=='RESOURCE' then
  local possible=false
  K.NearPlots(k.x,k.y,3,function(plot)
   if plot:GetOwner()==s.pid and plot:GetResourceType(p:GetTeam())>=0 and plot:GetImprovementType()<0 then
    local r=GameInfo.Resources[plot:GetResourceType(p:GetTeam())]
    if r and (r.ResourceClassType=='RESOURCECLASS_RUSH' or r.ResourceClassType=='RESOURCECLASS_MODERN') then
     for build in GameInfo.Builds() do if build.ImprovementType and p:CanBuild(plot,build.ID,false,false) then
      for _ in GameInfo.Improvement_ResourceTypes{ImprovementType=build.ImprovementType,ResourceType=r.Type} do possible=true end
     end end
    end
   end
  end)
  if not possible then return end;d.baseline=countPlots(s.pid,k,nil,true)
 elseif kind=='GROW' then
  if c:IsRazing() or c:IsFoodProduction() or c:FoodDifference()<=0 then return end;d.target=c:GetPopulation()+1
 elseif kind=='GOLD' then if p:CalculateGoldRate()<=0 then return end;d.target=p:GetGold()+K.Scale(100*(1+p:GetCurrentEra()*.25))
 elseif kind=='FAITH' then if p:GetTotalFaithPerTurn()<=0 then return end;d.target=p:GetFaith()+K.Scale(40)
 elseif kind=='GPT' then d.target=p:CalculateGoldRate()+3;if d.target<3 or d.target>15+p:GetCurrentEra()*12 then return end
 elseif kind=='TECH' then d.tech=p:GetCurrentResearch();if d.tech<0 then return end
 elseif kind=='WAR' or kind=='PEACE' or kind=='WAR_TURNS' then
  d.rival=rival(s.pid,kind~='WAR');if not d.rival then return end
  if kind=='PEACE' and (not Teams[p:GetTeam()]:CanChangeWarPeace(Players[d.rival]:GetTeam()) or (s.counters['war'..d.rival] or 0)<K.Scale(3)) then return end
  if kind=='WAR_TURNS' then d.target=K.Scale(5);d.baseline=s.counters['war'..d.rival] or 0 end
 elseif kind=='CAPTURE' then if K.Wars(s.pid)==0 then return end;d.counter='captures';d.baseline=s.counters.captures or 0
 elseif kind=='ENEMY' then if K.Wars(s.pid)==0 then return end;d.counter='enemyKills';d.baseline=s.counters.enemyKills or 0;d.target=2
 elseif kind=='BARBARIANS' or kind=='CAMP' then
  local found=false
  K.NearPlots(k.x,k.y,8,function(plot) if plot:IsRevealed(p:GetTeam()) and plot:GetImprovementType()==K.ID('IMPROVEMENT_BARBARIAN_CAMP') then found=true end end)
  if not found then return end;d.counter=kind=='CAMP' and 'camps' or 'barbarianKills';d.target=kind=='CAMP' and 1 or 2;d.baseline=s.counters[d.counter] or 0
 elseif kind=='UNITS' then
  local trainable=false
  for u in GameInfo.Units() do if (u.Combat or 0)>0 and c:CanTrain(u.ID) then trainable=true;break end end
  if not trainable then return end;d.target=2;d.counter='trained';d.baseline=s.counters.trained or 0
 elseif kind=='GARRISON' then
  d.target=2;if K.DemandProgress(s,h,d)>=2 or p:GetNumMilitaryUnits()<2 then return end
 elseif kind=='TRADE' then
  if p:GetTradeRoutesAvailable()<=#(p:GetTradeRoutes() or {}) then return end;d.target=#(p:GetTradeRoutes() or {})+1
 elseif kind=='EXPAND' then
  if p:IsMinorCiv() then return end;d.baseline=K.KingdomCount(s)
 elseif kind=='GREAT_PERSON' then
  local possible=false
  for city in p:Cities() do for spec in GameInfo.Specialists() do if spec.GreatPeopleUnitClass and city:GetSpecialistCount(spec.ID)>0 then possible=true end end end
  if not possible then return end;d.counter='greatPeople';d.baseline=s.counters.greatPeople or 0
 else return end
 return d
end
function K.ResolveDemand(s,h,result)
 local d=h.demand;if not d then return end
 K.Log('DEMAND',h.name..' '..d.kind..' '..result)
 if result=='completed' then
  K.Loyalty(h,18);h.prestige=h.prestige+5;h.influence=h.influence+3;h.stats.completed=h.stats.completed+1
  h.completed[#h.completed+1]={kind=d.kind,turn=K.Now()}
 elseif result~='invalid' then
  local refusal=result=='refused' and 10+K.TraitSum(h,'refusal') or 0
  local ruler=s.ruler and s.characters[s.ruler]
  if ruler and result=='refused' then refusal=refusal+K.TraitSum(ruler,'refusal',K.RulerTraits) end
  K.Loyalty(h,-12-refusal);h.stats.failed=h.stats.failed+1
 end
 K.History(s,'HOUSES','DEMAND_'..result:upper(),{h.name,K.DemandText(s,d)},h.id,h.kingdom)
 if result~='invalid' then K.Notify(s.pid,'DEMAND_'..result:upper(),h.name,K.DemandText(s,d)) end
 h.demand=nil;h.demandNext=K.Now()+K.Scale(15+K.Rand(s,11))
end
function K.Refuse(pid,hid)
 local s=K.State(pid);local h=s.houses[hid]
 if not K.IsKingdoms(pid) or not h or not h.demand or not s.kingdoms[h.kingdom].active then return false end
 K.ResolveDemand(s,h,'refused');K.RefreshRealm(s);K.Commit(pid);return true
end
function K.DemandTick(s)
 local active=0;local issued=false
 for i=0,GameDefines.MAX_MAJOR_CIVS-1 do
  local other=Players[i];if other and other:IsAlive() and Teams[Players[s.pid]:GetTeam()]:IsAtWar(other:GetTeam()) then
   local key='war'..i;s.counters[key]=(s.counters[key] or 0)+1
  end
 end
 for _,h in ipairs(K.ActiveHouses(s)) do
  if h.demand then
   if not K.DemandValid(s,h,h.demand) then K.ResolveDemand(s,h,'invalid')
   elseif K.DemandProgress(s,h,h.demand)>=h.demand.target then K.ResolveDemand(s,h,'completed')
   elseif K.Now()>h.demand.expires then K.ResolveDemand(s,h,'failed') else active=active+1 end
  end
 end
 local limit=math.min(5,2+math.floor(K.KingdomCount(s)/4))
 for _,h in ipairs(K.ActiveHouses(s)) do
  if not issued and not h.demand and K.Now()>=h.demandNext and active<limit then
   local choices={}
   for _,trait in ipairs(h.traits) do for _,kind in ipairs(K.HouseTraits[trait].demands) do choices[#choices+1]=kind;choices[#choices+1]=kind end end
   for _,kind in ipairs({'GROW','GREAT_PERSON','WAR_TURNS','UNITS'}) do choices[#choices+1]=kind end
   local start=K.Rand(s,#choices)
   for i=1,#choices do local d=K.MakeDemand(s,h,choices[(start+i-1)%#choices+1]);if d then h.demand=d;break end end
   h.demandNext=K.Now()+K.Scale(15+K.Rand(s,11))
   if h.demand then
    K.Log('DEMAND','Issued '..h.demand.kind..' to House '..h.id)
    active=active+1;issued=true
    K.History(s,'HOUSES','DEMAND_ISSUED',{h.name,K.DemandText(s,h.demand)},h.id,h.kingdom)
    K.Notify(s.pid,'DEMAND_ISSUED',h.name,K.DemandText(s,h.demand))
   end
  end
 end
end
