local I=MapModData.TheShatteredEmpire
function I.LoyaltyDelta(s,g)
 local c=I.City(g,s.pid);local cap=I.Capital(s.pid);if not c or not cap then return 0,{} end
 local parts={};local total=0
 local function add(key,value) total=total+value;parts[#parts+1]={reason=key,value=value} end
 local u=c:GetGarrisonedUnit()
 add(u and u:IsCombatUnit() and 'GARRISON' or 'UNGARRISONED',u and u:IsCombatUnit() and 3 or -2)
 if Players[s.pid]:IsCapitalConnectedToCity(c) then add('CONNECTION',2) end
 if c:IsHasBuilding(I.ID('BUILDING_IMPERIAL_PALACE')) then add('PALACE',2) end
 if g.autonomy then add('AUTONOMY',3);if s.reform=='FEDERATION' then add('FEDERATION',3) end end
 local distant=Map.PlotDistance(g.x,g.y,cap:GetX(),cap:GetY())>12
 if distant then add('DISTANCE',-2);if s.reform=='MONARCHY' then add('MONARCHY',-2) end end
 if g.ambition>70 then add('AMBITION',-3) end
 if Players[s.pid]:GetExcessHappiness()<0 then add('UNHAPPINESS',-4) end
 if s.warTurns>=I.Scale(25) then add('WAR',-3) end
 if s.strain>0 then add('STRAIN',-math.min(3,s.strain)) end
 if s.authority>=80 then add('AUTHORITY',2) elseif s.authority<40 then add('AUTHORITY',-2) end
 if g.archetype=='LOYALIST' then add('LOYALIST',2)
 elseif g.archetype=='MERCHANT' and Players[s.pid]:CalculateGoldRate()<0 then add('MERCHANT',-2)
 elseif g.archetype=='POPULIST' and c:FoodDifference()>0 then add('POPULIST',1) end
 if g.relationship>=20 then add('RELATIONSHIP',1) elseif g.relationship<=-20 then add('RELATIONSHIP',-1) end
 for _,f in pairs(s.factions) do if f.active and f.origin~=g.key then local origin=s.governors[f.origin];if origin and Map.PlotDistance(g.x,g.y,origin.x,origin.y)<=8 then add('NEARBY_REVOLT',-2);break end end end
 return I.Clamp(total,-8,8),parts
end
function I.LoyaltyTick(s)
 local p=Players[s.pid];local cap=I.Capital(s.pid)
 if I.Wars(s.pid)>0 then s.warTurns=s.warTurns+I.Scale(5) else s.warTurns=math.max(0,s.warTurns-I.Scale(10)) end
 local capacity=5+p:GetCurrentEra()*2+(s.reform=='FEDERATION' and 3 or 0)
 s.strain=math.max(0,math.floor((p:GetNumCities()-capacity+1)/3))
 if s.strain>0 then I.Authority(s,-math.min(3,s.strain)) end
 if s.warTurns>=I.Scale(35) and I.Now()-(s.lastVictory or 0)>=I.Scale(20) then I.Authority(s,-1) end
 if cap and cap:IsHasBuilding(I.ID('BUILDING_IMPERIAL_PALACE')) and I.Now()>=s.nextPalace then I.Authority(s,1);s.nextPalace=I.Now()+I.Scale(10) end
 for _,g in ipairs(I.Provinces(s)) do
  local c=I.City(g,s.pid);local delta,parts=I.LoyaltyDelta(s,g);g.delta=delta;g.reasons=parts
  g.loyalty=I.Clamp(g.loyalty+delta,0,100)
  local growth=c:GetPopulation()>g.population
  g.prestige=I.Clamp(g.prestige+(growth and 2 or .2)+(g.archetype=='AMBITIOUS' and .5 or 0),0,100);g.population=c:GetPopulation()
  local ambition=g.archetype=='LOYALIST' and 0 or g.archetype=='AMBITIOUS' and 1 or .25
  if s.reform=='DICTATORSHIP' and g.archetype=='MILITARIST' then ambition=ambition+1 end
  g.ambition=I.Clamp(g.ambition+ambition,0,100)
  if not g.faction then
   local stage=g.loyalty<25 and 2 or g.loyalty<45 and 1 or 0
   if stage>g.stage then I.Notify(s,I.Text('UNREST_TITLE'),I.Text('UNREST_NOTICE',g.name,c:GetName(),I.Text('STAGE_'..stage)),g) end
   g.stage=stage;g.critical=g.loyalty<25 and g.critical+1 or 0
   if g.critical>=2 and I.Now()>=(g.rebelNext or 0) then I.BeginRevolt(s,g) end
  end
 end
end
