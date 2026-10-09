local I=MapModData.TheShatteredEmpire
function I.AITick(s)
 local p=Players[s.pid];if p:IsHuman() then return end
 if s.succession then I.SelectSuccessor(s,I.BestSuccessor(s)) end
 if p:GetCurrentEra()>0 and I.Now()>=s.reformNext and s.authority>=25 then
  local wanted=(s.averageLoyalty<65 or p:GetNumCities()>8) and 'FEDERATION' or I.Wars(s.pid)>0 and 'DICTATORSHIP' or 'MONARCHY'
  if wanted~=s.reform then I.Action(s.pid,'REFORM',wanted) end
 end
 local decisions=0
 for _,g in ipairs(I.Provinces(s)) do
  if decisions<2 and I.Now()>=g.actionNext then
   local action
   if g.faction then
    if not g.autonomy and I.City(g,s.pid):IsHasBuilding(I.ID('BUILDING_IMPERIAL_PALACE')) then action='CHARTER'
    elseif p:GetGold()>I.GoldCost(s,g,2)+50 then action='CONCESSION'
    elseif s.authority>=40 then action='RECONCILE' end
   elseif g.loyalty<40 and g.ambition>70 and s.authority>=35 then action='REPLACE'
   elseif g.loyalty<60 and p:GetGold()>I.GoldCost(s,g)+100 then action='BRIBE'
   elseif g.demand and (g.demand.kind=='FUNDS' or g.demand.deadline-I.Now()<=I.Scale(5)) and p:GetGold()>g.demand.cost+75 then action='FUND'
   elseif s.reform=='FEDERATION' and not g.autonomy and g.loyalty<75 then action='CHARTER' end
   if action and I.Action(s.pid,action,g.key,g.id) then decisions=decisions+1 end
  end
  -- Assign a nearby idle, unembarked land soldier; normal tactical AI retains wars.
  local c=I.City(g,s.pid)
  if c and not c:GetGarrisonedUnit() and I.Wars(s.pid)==0 and I.Now()%I.Scale(5)==0 then
   local soldier,distance
   for u in p:Units() do if I.LandCombat(u) and not u:IsEmbarked() and not u:IsCargo() and u:MovesLeft()>0 and not u:GetPlot():IsCity() then
    local d=Map.PlotDistance(g.x,g.y,u:GetX(),u:GetY());if d<=6 and (not distance or d<distance) then soldier=u;distance=d end
   end end
   if soldier and MissionTypes and MissionTypes.MISSION_MOVE_TO then soldier:PushMission(MissionTypes.MISSION_MOVE_TO,g.x,g.y,0,0,1) end
  end
 end
end
