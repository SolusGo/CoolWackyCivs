local L=MapModData.TheLastCity
L.Crises={'OUTBREAK','GATES','THEFT','DESERTION','PROTESTS','SCIENTIST','WATER_FAILURE','DESPERATE',
 'LAST_HOSPITAL','CONSPIRACY','HERO','SUPPLY_CACHE','EXPERT_ACCIDENT','REBUILD','SIEGE_CHILD'}
function L.CrisisWeight(s,key)
 local c=L.City(s);local crowd=math.max(0,c:GetPopulation()-s.housing)
 if key=='OUTBREAK' then return math.max(1,2+math.min(10,crowd*2+s.starvation/L.Speed)+(s.infection and 5 or s.wave and s.wave.era>=3 and 3 or 0)+math.min(3,s.lastPillaged)+math.min(2,math.max(0,Players[s.pid]:GetHandicapType()-3))-math.min(8,L.Medical(s)))
 elseif key=='GATES' then return (s.wave or c:GetDamage()>30) and 7 or 0
 elseif key=='THEFT' then return s.provisions<30 and 7 or 1
 elseif key=='DESERTION' then return s.morale<40 and L.Military(s.pid)>0 and 6 or 0
 elseif key=='PROTESTS' then return s.refused>0 and 2+math.min(5,s.refused) or 0
 elseif key=='SCIENTIST' then return s.experts.SCIENTISTS>0 and 2 or 0
 elseif key=='WATER_FAILURE' then return 3
 elseif key=='DESPERATE' then return not s.refugee and 3 or 0
 elseif key=='LAST_HOSPITAL' then return s.medicalCases>0 and 4 or 1
 elseif key=='CONSPIRACY' then return (s.morale<60 and 4 or 1)+((s.infiltratedUntil or 0)>L.Now() and 5 or 0)
 elseif key=='HERO' then return L.Military(s.pid)>0 and 2 or 0
 elseif key=='SUPPLY_CACHE' then return s.provisions<s.capacity-20 and 3 or 0
 elseif key=='EXPERT_ACCIDENT' then
  for _,k in ipairs(L.Skills) do if s.experts[k]>0 then return 2 end end;return 0
 elseif key=='REBUILD' then return (s.housingDamage or 0)>0 and 6 or 0
 elseif key=='SIEGE_CHILD' then return s.wave and 3 or 0 end
 return 0
end
function L.NewCrisis(s)
 local total=0;for _,key in ipairs(L.Crises) do total=total+L.CrisisWeight(s,key) end
 if total==0 then return end
 local roll=L.Rand(s,total);local chosen
 for _,key in ipairs(L.Crises) do roll=roll-L.CrisisWeight(s,key);if roll<=0 then chosen=key;break end end
 local expert
 if chosen=='EXPERT_ACCIDENT' then
  local available={};for _,k in ipairs(L.Skills) do if s.experts[k]>0 then available[#available+1]=k end end
  expert=available[L.Rand(s,#available)]
 end
 s.crisis={id=s.nextEvent,key=chosen,expert=expert,started=L.Now(),expiry=L.Now()+L.Scale(5)}
 s.nextEvent=s.nextEvent+1;L.History(s,'CRISIS',L.Text('CRISIS_'..chosen));L.Notify(s,'CRISIS_WAITING',L.Text('CRISIS_'..chosen))
end
function L.CrisisCost(s,choice)
 local key=s.crisis.key
 if choice~=1 then return 0,0 end
 local cost=(key=='GATES' and 20 or key=='OUTBREAK' and math.max(6,18-L.Medical(s)*2) or key=='SUPPLY_CACHE' and 8 or key=='HERO' and 6 or key=='SIEGE_CHILD' and 4 or 12)
 if key=='GATES' and s.survivors.ASH then cost=10 end
 if key=='WATER_FAILURE' and s.survivors.ASH then cost=6 end
 return L.Scale(cost),key=='GATES' and L.ProductionScale(20) or 0
end
function L.CrisisCheck(s,id,choice)
 if not s.crisis or id~=s.crisis.id then return false,L.Text('EVENT_EXPIRED') end
 if choice~=1 and choice~=2 and choice~=3 then return false,L.Text('UNAVAILABLE') end
 local provision,production=L.CrisisCost(s,choice);local c=L.City(s)
 if s.provisions<provision then return false,L.Text('SUPPLIES_REQUIRED',provision) end
 if production>0 and (c:GetProduction()<production or c:GetProductionProcess()>=0) then return false,L.Text('PRODUCTION_REQUIRED',production) end
 if s.crisis.key=='GATES' and choice==2 and (c:GetPopulation()<2 or not L.MilitiaPlot(s)) then return false,L.Text('MILITIA_REQUIRED') end
 return true,L.Text('CHOICE_'..s.crisis.key..'_'..choice)..(provision>0 and '[NEWLINE]'..L.Text('COST',provision,production) or '')
end
local function losePopulation(c,n) if c:GetPopulation()>1 then c:ChangePopulation(-math.min(n,c:GetPopulation()-1),true) end end
function L.ResolveCrisis(s,id,choice)
 local ok,reason=L.CrisisCheck(s,id,choice);if not ok then return false,reason end
 local r=s.crisis;local cost,prod=L.CrisisCost(s,choice);local c=L.City(s)
 if r.key=='GATES' and choice==2 and not L.SpawnMilitia(s) then return false,L.Text('MILITIA_REQUIRED') end
 s.crisis=nil;L.Provisions(s,-cost)
 if prod>0 then c:ChangeProduction(-prod) end
 local key=r.key
 if key=='OUTBREAK' then
  s.medicalCases=s.medicalCases+1
  if choice==1 then L.Morale(s,3);s.starvation=math.max(0,s.starvation-2);s.infection=nil;s.infectionNext=L.Now()+L.Scale(L.Config.InfectionCooldown)
  elseif choice==2 then L.Morale(s,-4);L.Provisions(s,-L.Scale(4))
  else L.Morale(s,-math.max(3,12-L.Medical(s)));if L.Medical(s)<3 then losePopulation(c,1) end end
 elseif key=='GATES' then
  if choice==1 then c:SetDamage(math.max(0,c:GetDamage()-60));s.gates=1
  elseif choice==2 then s.gates=1;losePopulation(c,1);L.Morale(s,-3)
  else s.gates=-1;L.Morale(s,-15);s.housingDamage=math.min(4,(s.housingDamage or 0)+2) end
  s.gatesUntil=L.Now()+L.Scale(6)
 elseif key=='THEFT' then
  if choice==1 then L.Morale(s,5)
  elseif choice==2 then L.Provisions(s,-L.Scale(5));L.Morale(s,2)
  else L.Provisions(s,-L.Scale(12));L.Morale(s,-5) end
 elseif key=='DESERTION' then
  if choice==1 then L.Morale(s,8)
  elseif choice==2 then L.Morale(s,-5);s.gates=1;s.gatesUntil=L.Now()+L.Scale(3)
  else
   local units={};for u in Players[s.pid]:Units() do if u:IsCombatUnit() then units[#units+1]=u end end
   table.sort(units,function(a,b) return a:GetID()<b:GetID() end)
   if #units>1 then units[#units]:Kill(false,-1);s.losses=s.losses+1 end;L.Morale(s,-6)
  end
 elseif key=='PROTESTS' then
  if choice==1 then L.Morale(s,10);s.refused=math.max(0,s.refused-2)
  elseif choice==2 then L.Morale(s,2);s.refused=math.max(0,s.refused-1)
  else L.Morale(s,-8) end
 elseif key=='SCIENTIST' then
  if choice==1 then L.Morale(s,5);s.experts.SCIENTISTS=math.min(50,s.experts.SCIENTISTS+1)
  elseif choice==2 then L.Morale(s,-3)
  else L.LoseExpert(s,'SCIENTISTS');L.Morale(s,-4) end
 elseif key=='WATER_FAILURE' then
  if choice==1 then s.waterUntil=0;L.Morale(s,4)
  elseif choice==2 then s.waterUntil=L.Now()+L.Scale(4);L.Morale(s,-3)
  else s.waterUntil=L.Now()+L.Scale(10);L.Morale(s,-8);s.medicalCases=s.medicalCases+1 end
 elseif key=='DESPERATE' then
  if choice==1 then losePopulation(c,0);c:ChangePopulation(2,true);s.experts.FARMERS=math.min(50,s.experts.FARMERS+1);L.Morale(s,5);s.accepted=s.accepted+1;s.survivors.DESPERATE=(s.survivors.DESPERATE or 0)+1
  elseif choice==2 then L.Morale(s,2);s.survivors.SUPPLIED=(s.survivors.SUPPLIED or 0)+1
  else L.Morale(s,-10);s.refused=s.refused+1 end
 elseif key=='LAST_HOSPITAL' then
  if choice==1 then s.experts.PHYSICIANS=math.min(50,s.experts.PHYSICIANS+1);L.Morale(s,5)
  elseif choice==2 then L.Provisions(s,-L.Scale(4));L.Morale(s,1)
  else L.LoseExpert(s,'PHYSICIANS');L.Morale(s,-8) end
 elseif key=='CONSPIRACY' then
  if choice==1 then L.Morale(s,8);s.infiltratedUntil=0
  elseif choice==2 then L.Morale(s,-3);s.infiltratedUntil=0
  else L.Morale(s,-10);s.infiltratedUntil=L.Now()+L.Scale(10) end
 elseif key=='HERO' then
  if choice==1 then L.Morale(s,12);s.experts.VETERANS=math.min(50,s.experts.VETERANS+1)
  elseif choice==2 then L.Morale(s,6)
  else L.Morale(s,2) end
 elseif key=='SUPPLY_CACHE' then
  if choice==1 then L.Provisions(s,L.Scale(40));L.Morale(s,5)
  elseif choice==2 then L.Provisions(s,L.Scale(15))
  else L.Morale(s,3) end
 elseif key=='EXPERT_ACCIDENT' then
  if choice==1 then L.Morale(s,3)
  elseif choice==2 and L.Medical(s)>1 then L.Morale(s,-2)
  else L.LoseExpert(s,r.expert);L.Morale(s,-6) end
 elseif key=='REBUILD' then
  if choice==1 then s.housingDamage=0;L.Morale(s,7)
  elseif choice==2 then s.housingDamage=math.max(0,s.housingDamage-1);L.Morale(s,2)
  else L.Morale(s,-5) end
 elseif key=='SIEGE_CHILD' then
  if choice==1 then L.Morale(s,12)
  elseif choice==2 then L.Morale(s,6)
  else L.Morale(s,2) end
 end
 L.History(s,'CRISIS_RESOLVED',L.Text('CRISIS_'..key)..': '..L.Text('CHOICE_'..key..'_'..choice))
 s.nextCrisis=L.Now()+L.Scale(L.Range(s,L.Config.CrisisMin,L.Config.CrisisMax))
 return true,L.Text('CRISIS_RESOLVED')
end
function L.CrisisTurn(s)
 if s.crisis then
  if L.Now()>s.crisis.expiry then L.ResolveCrisis(s,s.crisis.id,3) end
 elseif s.nextCrisis and L.Now()>=s.nextCrisis and not s.refugee then
  L.NewCrisis(s)
 end
end
