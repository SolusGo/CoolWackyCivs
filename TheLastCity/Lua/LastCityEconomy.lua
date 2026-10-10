local L=MapModData.TheLastCity
function L.Military(pid)
 local n=0
 -- Count combat units even if a promotion exempts them from gold maintenance.
 -- Summoned defenders consume supplies for their complete lifespan as well.
 for u in Players[pid]:Units() do local row=GameInfo.Units[u:GetUnitType()]
  -- CP IsCombatUnit tests melee strength only. Bombers/missiles still consume
  -- supplies despite having zero melee Combat in the database.
  if u:IsCombatUnit() or (row and (row.RangedCombat or 0)>0) then n=n+1 end
 end
 return n
end
function L.Stats(s)
 local c=L.City(s);if not c then return {income=0,consumption=0,net=0,military=0,population=0,housing=s.housing,capacity=s.capacity,pillaged=0} end
 local housing,capacity,income=L.Config.Housing,L.Config.Storage,L.Config.BaseIncome
 if L.Has(c,'DISTRICT') then housing=housing+L.Config.DistrictHousing;income=income+L.Config.DistrictIncome end
 for _,b in ipairs(L.Infrastructure) do if L.Has(c,b.key) then housing=housing+(b.housing or 0);capacity=capacity+(b.storage or 0);income=income+(b.income or 0) end end
 local farms,pillaged=0,0
 -- Native city plot iterator is bounded (usually 37, CP may extend it).
 -- Count only owned, completed, unpillaged supply improvements.
 for i=0,c:GetNumCityPlots()-1 do local p=c:GetCityIndexPlot(i)
  if p and p:GetOwner()==s.pid then
   local improvement=p:GetImprovementType()
   if improvement>=0 then
    if p:IsImprovementPillaged() then pillaged=pillaged+1
    elseif improvement==L.ID('IMPROVEMENT_FARM') or improvement==L.ID('IMPROVEMENT_FISHING_BOATS') then farms=farms+1 end
   end
  end
 end
 housing=math.max(L.Config.Housing,housing-(s.housingDamage or 0))
 income=math.max(0,income+farms+s.assigned.FARMERS*L.Config.FarmerIncome-((s.waterUntil or 0)>L.Now() and 3 or 0))
 local military=L.Military(s.pid)
 local base=math.ceil(c:GetPopulation()*L.Config.PopulationConsumption+military*L.Config.MilitaryConsumption)
 local infection=s.infection and L.Now()<s.infection.untilTurn and math.max(0,s.infection.severity-math.floor(L.Medical(s)/2)) or 0
 local blockade=s.pressure and L.Now()<s.pressure.expiry and L.BlockadeDrain(s) or 0
 local consumption=math.ceil(base*L.Rations[s.ration].consumption)+infection+blockade
 return {income=income,consumption=consumption,net=income-consumption,military=military,
  population=c:GetPopulation(),housing=housing,capacity=capacity,pillaged=pillaged,farms=farms,base=base,infection=infection,blockade=blockade}
end
function L.Medical(s) return s.assigned.PHYSICIANS+(L.Has(L.City(s),'HOSPITAL') and 2 or 0) end
function L.Condition(s)
 return s.morale>=80 and 'UNITED' or s.morale>=60 and 'STABLE' or s.morale>=40 and 'ANXIOUS' or s.morale>=20 and 'UNREST' or 'BREAKING'
end
function L.ApplyEffects(s)
 if s.incompatible then return end
 local c=L.City(s);if not c then return end
 local stats=L.Stats(s);s.housing=stats.housing;s.capacity=stats.capacity;s.provisions=L.Clamp(s.provisions,0,s.capacity)
 for _,k in ipairs({'ENGINEERS','SCIENTISTS','SCHOLARS'}) do L.Building(c,k,s.assigned[k]) end
 local condition=L.Condition(s)
 for _,k in ipairs({'UNITED','ANXIOUS','UNREST','BREAKING'}) do L.Building(c,k,k==condition and 1 or 0) end
 L.Building(c,'LEGACY',math.min(math.floor(L.Config.MaxDefense/2),s.majorSieges))
 L.Building(c,'GATES_UP',s.gates>0 and s.gatesUntil>L.Now() and 1 or 0)
 L.Building(c,'GATES_DOWN',s.gates<0 and s.gatesUntil>L.Now() and 1 or 0)
 L.Building(c,'ENDURES',s.dawn=='ENDURES' and 1 or 0)
end
function L.SetRation(s,key)
 if not L.Rations[key] or key==s.ration then return false,L.Text('UNAVAILABLE') end
 if L.Now()<s.rationNext then return false,L.Text('RATION_WAIT',s.rationNext-L.Now()) end
 s.ration=key;s.rationNext=L.Now()+L.Scale(L.Config.PolicyCooldown)
 L.History(s,'RATION_CHANGED',L.Text(key));return true,L.Text('RATION_CHANGED')
end
function L.Assign(s,key,delta)
 if not s.experts[key] or (delta~=1 and delta~=-1) then return false,L.Text('UNAVAILABLE') end
 local n=s.assigned[key]+delta
 if n<0 or n>math.min(L.Config.ExpertCap,s.experts[key]) then return false,L.Text('EXPERT_CAP') end
 s.assigned[key]=n;return true,L.Text('ASSIGNMENT_CHANGED')
end
function L.LoseExpert(s,key)
 if s.experts[key]>0 then
  s.experts[key]=s.experts[key]-1;s.assigned[key]=math.min(s.assigned[key],s.experts[key])
  L.History(s,'EXPERT_LOST',L.Text(key));return true
 end
 return false
end
function L.DawnReady(s)
 local c=L.City(s)
 return not s.fallen and not s.incompatible and c and L.Has(c,'DISTRICT') and Players[s.pid]:GetCurrentEra()>=6
  and Teams[Players[s.pid]:GetTeam()]:IsHasTech(L.ID('TECH_ATOMIC_THEORY'))
  and s.wavesSurvived>=12 and s.morale>=55 and s.provisions>=150
end
function L.CanInfrastructure(s,key)
 if s.fallen or s.incompatible then return false,L.Text('UNAVAILABLE') end
 local c=L.City(s);if not c then return false,L.Text('UNAVAILABLE') end
 local def;for _,b in ipairs(L.Infrastructure) do if b.key==key then def=b;break end end
 if not def then return false,L.Text('UNAVAILABLE') end
 if L.Has(c,key) then return false,L.Text('BUILT') end
 if not L.Has(c,'DISTRICT') then return false,L.Text('DISTRICT_REQUIRED') end
 if not Teams[Players[s.pid]:GetTeam()]:IsHasTech(L.ID(def.tech)) then return false,L.Text('TECH_REQUIRED') end
 if key=='DAWN' and (not L.DawnReady(s) or s.dawn~='LOCKED') then return false,L.Text('DAWN_REQUIREMENTS') end
 return true,L.Text('BUILD_HELP',c:GetBuildingProductionNeeded(L.ID('BUILDING_LC_'..key)))
end
function L.QueueInfrastructure(s,key)
 local ok,reason=L.CanInfrastructure(s,key);if not ok then return false,reason end
 local c=L.City(s);local id=L.ID('BUILDING_LC_'..key)
 if not c:CanConstruct(id) then return false,L.Text('UNAVAILABLE') end
 -- Real native production order, replacing the current queue at user's request.
 c:PushOrder(OrderTypes.ORDER_CONSTRUCT,id,-1,0,true,false,0)
 return true,L.Text('QUEUED')
end
function L.EconomyTurn(s)
 L.InfectionTurn(s)
 local c=L.City(s);local stats=L.Stats(s)
 s.housing=stats.housing;s.capacity=stats.capacity;s.peakMilitary=math.max(s.peakMilitary,stats.military)
 L.Provisions(s,stats.net)
 local overcrowd=math.max(0,stats.population-s.housing)
 local penalty=overcrowd==0 and 0 or overcrowd<=2 and .4 or overcrowd<=5 and 1.2 or 2.5
 -- Normalize gradual attrition/recovery by speed: three hundred Marathon
 -- turns between encounters must not triple the cumulative Morale penalty.
 local morale=(L.Rations[s.ration].morale-penalty)/L.Speed
 if s.provisions<=0 then
  s.starvation=s.starvation+1;morale=morale-math.min(5,1+s.starvation/L.Scale(3))/L.Speed
  if s.starvation>=L.Scale(L.Config.StarvePopulationAfter) and c:GetPopulation()>1 and L.Rand(s,10000)<=math.floor(100*math.max(3,math.min(22,5+math.floor(s.starvation/L.Speed)*2)-L.Medical(s)*2)/L.Speed) then
   c:ChangePopulation(-1,true);L.History(s,'STARVATION_DEATH');L.Notify(s,'STARVATION_DEATH')
  end
 else
  s.starvation=math.max(0,s.starvation-2)
  if stats.net>=0 and overcrowd==0 and not s.wave and not s.pressure and c:GetDamage()<25 then morale=morale+(.35+s.assigned.SCHOLARS*.08)/L.Speed end
 end
 if c:GetDamage()>s.lastDamage then morale=morale-math.min(6,(c:GetDamage()-s.lastDamage)/25) end
 if stats.pillaged>s.lastPillaged then morale=morale-math.min(5,(stats.pillaged-s.lastPillaged)*2);L.History(s,'PILLAGED') end
 s.lastDamage=c:GetDamage();s.lastPillaged=stats.pillaged;L.Morale(s,morale)
 -- Verified alternative to a nonexistent Lua growth setter: adjust stored Food
 -- by a fraction of positive net Food, retaining fractional remainders. Normal
 -- Civ V growth/starvation remains in charge of population. No Food is minted
 -- when the native city surplus is nonpositive.
 local growth=L.Rations[s.ration].growth-(s.provisions==0 and 60 or s.starvation>0 and 20 or 0)
 local surplus=math.max(0,c:FoodDifferenceTimes100()/100)
 -- PlayerDoTurn runs AFTER native city growth. Bound a negative adjustment by
 -- the food actually retained; a growth threshold may already have consumed
 -- this turn's surplus. Generous food cannot buy a second threshold directly:
 -- native growth will examine it on the next city turn.
 s.foodRemainder=s.foodRemainder+surplus*growth/100
 local delta=s.foodRemainder>=0 and math.floor(s.foodRemainder+1e-8) or math.ceil(s.foodRemainder-1e-8)
 if delta~=0 then
  local applied=math.max(-c:GetFood(),delta);c:ChangeFood(applied);s.foodRemainder=s.foodRemainder-applied
  -- Do not carry an unlimited food debt after emptying a city's growth store.
  if applied~=delta then s.foodRemainder=0 end
  if math.abs(s.foodRemainder)<1e-8 then s.foodRemainder=0 end
 end
 if s.gatesUntil<=L.Now() then s.gates=0 end
 -- Casualty deduplication only needs tokens for living/delayed units. Keep the
 -- map bounded over long games instead of retaining every historical soldier.
 local live={}
 for u in Players[s.pid]:Units() do
  local token=(u:GetScriptData() or ''):match('|(LCDEF_'..s.pid..'_%d+)|')
  if token and s.lossSeen[token] then live[token]=true end
 end
 s.lossSeen=live
 for i=#s.temporary,1,-1 do local r=s.temporary[i]
  if r.expiry<=L.Now() then local u=L.Unit(r)
   if u then u:Kill(false,-1) end;table.remove(s.temporary,i)
  end
 end
end
