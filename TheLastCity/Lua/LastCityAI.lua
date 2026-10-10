local L=MapModData.TheLastCity
function L.AITurn(s)
 local c=L.City(s);if not c then return end
 for _,k in ipairs(L.Skills) do s.assigned[k]=math.min(L.Config.ExpertCap,s.experts[k]) end
 local stats=L.Stats(s)
 if L.Now()>=s.rationNext then
  local chosen=s.provisions<15 and 'EMERGENCY' or (stats.net<0 and s.provisions<60) and 'STRICT' or s.provisions>120 and s.morale<75 and 'GENEROUS' or 'STANDARD'
  if s.ration~=chosen then L.SetRation(s,chosen) end
 end
 if s.refugee and s.refugee.status~='QUARANTINE' then local r=s.refugee
  local chosen='REFUSE'
  if c:GetPopulation()+r.population<=s.housing+2 and s.provisions>=r.cost-(r.paid or 0)+15 then chosen='ACCEPT'
  elseif not r.quarantined and s.provisions>=r.cost+12 and L.RefugeeCheck(s,r.id,'QUARANTINE') then chosen='QUARANTINE' end
  L.ResolveRefugee(s,r.id,chosen)
 end
 if s.crisis then
  local chosen=L.CrisisCheck(s,s.crisis.id,1) and 1 or L.CrisisCheck(s,s.crisis.id,2) and 2 or 3
  L.ResolveCrisis(s,s.crisis.id,chosen)
 end
 -- Native production choices, never instant free buildings/units. Do not erase
 -- an in-progress order on every turn: intervene only when idle or threatened.
 local threat=s.wave or s.nextWave and s.nextWave-L.Now()<=L.Scale(5)
 local needsArmy=stats.military<math.max(2,math.min(7,2+math.floor(s.wavesSurvived/3)))
 local idle=c:GetProductionBuilding()<0 and c:GetProductionUnit()<0 and c:GetProductionProject()<0
 local emergency=s.wave and stats.military<2 and c:GetProductionBuilding()~=L.ID('BUILDING_LC_DAWN') and L.Now()>=(s.aiDefenseNext or 0)
 if threat and needsArmy and c:GetProductionUnit()<0 and (idle or emergency) then
  local unit=L.SelectUnit(s,Players[s.pid]:GetCurrentEra(),1,false)
  local watch=L.ID('UNIT_LC_LAST_WATCH')
  if c:CanTrain(watch) then unit=watch end
  if c:CanTrain(unit) then c:PushOrder(OrderTypes.ORDER_TRAIN,unit,UnitAITypes.UNITAI_DEFENSE,0,true,false,0);s.aiDefenseNext=L.Now()+L.Scale(5) end
 elseif idle then
  if not L.Has(c,'DISTRICT') and c:CanConstruct(L.ID('BUILDING_LC_DISTRICT')) then
   c:PushOrder(OrderTypes.ORDER_CONSTRUCT,L.ID('BUILDING_LC_DISTRICT'),-1,0,true,false,0)
  else
   local priority={'BARRACKS','RESIDENTIAL','HOSPITAL','WATER','STORAGE','SHELTER','DEPOT','DAWN'}
   if L.CanInfrastructure(s,'DAWN') then table.insert(priority,1,'DAWN') end
   if stats.population>stats.housing then table.insert(priority,1,'RESIDENTIAL');table.insert(priority,2,'SHELTER') end
   if stats.net<0 or s.provisions<25 then table.insert(priority,1,'WATER') end
   for _,key in ipairs(priority) do
    if L.CanInfrastructure(s,key) and c:CanConstruct(L.ID('BUILDING_LC_'..key)) then L.QueueInfrastructure(s,key);break end
   end
  end
 end
end
