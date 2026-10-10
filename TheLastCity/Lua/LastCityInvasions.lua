local L=MapModData.TheLastCity
function L.Record(u,tag)
 local data=u:GetScriptData() or ''
 if not data:find('|'..tag..'|',1,true) then u:SetScriptData(data..'|'..tag..'|') end
 return {owner=u:GetOwner(),id=u:GetID(),created=u:GetGameTurnCreated(),tag=tag}
end
function L.Unit(r)
 if not r or r.dead or r.invalid then return end
 local p=r and Players[r.owner];local u=p and p:GetUnitByID(r.id)
 if u and u:GetGameTurnCreated()==r.created and (u:GetScriptData() or ''):find('|'..r.tag..'|',1,true) then return u end
end
function L.RefreshUnit(s,u)
 if not u then return end
 local row=GameInfo.Units[u:GetUnitType()]
 if not u:IsCombatUnit() and (not row or (row.RangedCombat or 0)==0) then return end
 local data=u:GetScriptData() or ''
 if not data:match('|LCDEF_'..s.pid..'_%d+|') then
  L.Record(u,'LCDEF_'..s.pid..'_'..s.nextUnit);s.nextUnit=s.nextUnit+1
 end
 if not u:IsCombatUnit() then return end
 local c=L.City(s);local near=c and Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())<=3
 L.Promotion(u,'SANCTUARY',near);L.Promotion(u,'NO_CONQUEST',s.capital~=nil)
 L.Promotion(u,'RESOLVE',near and s.morale>=80)
 for n=1,5 do
  L.Promotion(u,'TRAINING_'..n,near and s.assigned.VETERANS==n)
 end
 local rank=0
 for n=1,5 do if u:IsHasPromotion(L.ID('PROMOTION_LC_VETERAN_'..n)) then rank=math.max(rank,n) end end
 for n=1,5 do L.Promotion(u,'VETERAN_ACTIVE_'..n,near and rank==n) end
end
function L.RefreshUnits(s)
 if s.incompatible then return end
 for u in Players[s.pid]:Units() do
  L.RefreshUnit(s,u)
 end
end
local function passable(p,naval)
 return p and not p:IsCity() and not p:IsMountain() and not p:IsImpassable()
  and p:GetFeatureType()~=L.ID('FEATURE_ICE') and p:IsWater()==naval
end
function L.SpawnPlots(s,radius,ownApproach)
 local c=L.City(s);local localPlots={};local land,sea={},{};local reachableLand={}
 L.Near(c:GetX(),c:GetY(),radius or L.Config.SpawnMax,function(p) localPlots[p:GetPlotIndex()]=p end)
 -- Bounded flood fills prove a passable local route to the capital. Same land
 -- area alone cannot detect an impassable mountain barrier.
 for _,naval in ipairs({false,true}) do
  local queue,seen={},{}
  local function add(p)
   if not p or seen[p:GetPlotIndex()] or not localPlots[p:GetPlotIndex()] then return end
   if not passable(p,naval) then return end
   local owner=p:GetOwner()
   if owner~=-1 and owner~=s.pid then return end
   seen[p:GetPlotIndex()]=true;queue[#queue+1]=p
  end
  for dir=0,5 do add(Map.PlotDirection(c:GetX(),c:GetY(),dir)) end
  if naval then
   -- A capital one tile inland on a small island can still be threatened by
   -- ranged ships. Seed its connected nearby coast, not disconnected islands.
   for _,p in ipairs(reachableLand) do
    if Map.PlotDistance(p:GetX(),p:GetY(),c:GetX(),c:GetY())<=2 then
     for dir=0,5 do add(Map.PlotDirection(p:GetX(),p:GetY(),dir)) end
    end
   end
  end
  local head=1
  while head<=#queue do local p=queue[head];head=head+1
   local d=Map.PlotDistance(p:GetX(),p:GetY(),c:GetX(),c:GetY())
   if d>=(ownApproach and 3 or L.Config.SpawnMin) and p:GetNumUnits()==0 and ((not ownApproach and p:GetOwner()==-1) or (ownApproach and p:GetOwner()==s.pid)) then
    local pool=naval and sea or land;pool[#pool+1]=p
   end
   for dir=0,5 do add(Map.PlotDirection(p:GetX(),p:GetY(),dir)) end
  end
  if not naval then reachableLand=queue end
 end
 table.sort(land,function(a,b) return a:GetPlotIndex()<b:GetPlotIndex() end)
 table.sort(sea,function(a,b) return a:GetPlotIndex()<b:GetPlotIndex() end)
 return land,sea
end
function L.MilitiaPlot(s)
 local c=L.City(s);local found
 L.Near(c:GetX(),c:GetY(),2,function(p)
  if not found and passable(p,false) and p:GetOwner()==s.pid and p:GetNumUnits()==0 then found=p end
 end)
 return found
end
function L.SelectUnit(s,era,role,naval)
 local team=Teams[Players[s.pid]:GetTeam()]
 for e=math.min(era+1,#L.EraForces),1,-1 do
  local choices=naval and L.EraForces[e].sea or L.EraForces[e].land
  local name=choices[(role-1)%#choices+1];local row=GameInfo.Units[name]
  if row and (not row.PrereqTech or team:IsHasTech(L.ID(row.PrereqTech))) then return row.ID end
 end
 return L.ID(naval and 'UNIT_TRIREME' or 'UNIT_WARRIOR')
end
function L.SpawnMilitia(s)
 local p=L.MilitiaPlot(s);if not p then return false end
 local u=Players[s.pid]:InitUnit(L.SelectUnit(s,Players[s.pid]:GetCurrentEra(),1,false),p:GetX(),p:GetY(),UnitAITypes.UNITAI_DEFENSE,DirectionTypes.DIRECTION_NORTH)
 if not u then return false end
 local r=L.Record(u,'LCMIL_'..s.pid..'_'..s.nextEvent);r.expiry=L.Now()+L.Scale(6)
 s.temporary[#s.temporary+1]=r;L.RefreshUnit(s,u);return true
end
function L.Threat(s,major,final)
 local era=Players[s.pid]:GetCurrentEra()
 local world=Game.GetCurrentEra and Game.GetCurrentEra() or era
 era=math.min(7,math.max(era,math.min(world,era+1)))
 local handicap=Players[s.pid]:GetHandicapType()
 local adapt=math.min(2,math.floor(s.peakMilitary/6))
 local count=3+math.floor(s.wavesSurvived/3)+math.floor(era/2)+math.min(2,math.max(0,handicap-3))+adapt
 if major then count=count+3 end
 if final then count=count+5 end
 return math.min(L.Config.MaxEnemies,count),era
end
function L.HostileOwner(s)
 -- Reuse an already hostile major's normal city-capturing AI when present.
 -- Otherwise barbarians are the reliable, slot-free attrition fallback.
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[pid]
  if p and p:IsAlive() and not p:IsHuman() and pid~=s.pid and Teams[Players[s.pid]:GetTeam()]:IsAtWar(p:GetTeam()) then return pid end
 end
 return GameDefines.BARBARIAN_PLAYER
end
function L.DirectPressure(s)
 local w=s.wave;local c=L.City(s);if not w or not c then return end
 local targets={}
 L.Near(c:GetX(),c:GetY(),3,function(p)
  if passable(p,w.naval) and p:GetNumUnits()==0 and (p:GetOwner()==s.pid or p:GetOwner()==-1) then targets[#targets+1]=p end
 end)
 table.sort(targets,function(a,b) return a:GetPlotIndex()<b:GetPlotIndex() end)
 if #targets==0 then return end
 for i,r in ipairs(w.units) do local u=L.Unit(r)
  if u then
   local p=targets[(i-1)%#targets+1]
   -- Reissue only distant approaches, once per sanctuary turn. Leave nearby
   -- units to native combat AI; never overwrite their attacks with movement.
   if Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())>3 then
    u:PushMission(MissionTypes.MISSION_MOVE_TO,p:GetX(),p:GetY(),0,0,0)
   end
  end
 end
end
function L.BeginWave(s)
 if s.wave or s.fallen then return false end
 s.pressure=nil
 local number=s.waveNumber+1;local final=s.dawn=='FINAL_PENDING'
 local major=number%L.Config.MajorEvery==0 or final
 local count,era=L.Threat(s,major,final);local land,sea=L.SpawnPlots(s)
 if math.max(#land,#sea)<count then land,sea=L.SpawnPlots(s,L.Config.SpawnExpanded) end
 local naval=#land<math.min(3,count) and #sea>0;local pool=naval and sea or land
 if #pool==0 and #sea>0 then naval=true;pool=sea end
 local ambush=false
 if #pool==0 or (final and #pool<math.ceil(count*.75)) then
  -- Last City's own empty outskirts are a legal enemy approach: barbarians
  -- and the chosen major are already at war. No third-party borders are used.
  land,sea=L.SpawnPlots(s,L.Config.SpawnExpanded,true)
  naval=#land<math.min(3,count) and #sea>0;pool=naval and sea or land
  if #pool>0 then ambush=true;if not final then count=math.min(count,major and 5 or 3) end end
 end
 if #pool==0 or (final and #pool<math.ceil(count*.75)) then
  L.BeginPressure(s,era,final);return false
 end
 local owner=L.HostileOwner(s)
 s.collapse=0
 local wave={number=number,major=major,final=final,era=era,naval=naval,ambush=ambush,owner=owner,started=L.Now(),
  expiry=L.Now()+L.Scale(L.Config.WaveTimeout),units={},participants={},spawned=0,defeated=0,bossKilled=false}
 s.wave=wave
 for i=1,math.min(count,#pool) do
  local index=L.Rand(s,#pool);local p=table.remove(pool,index)
  local unitType=L.SelectUnit(s,era,i,naval)
  local ai=naval and UnitAITypes.UNITAI_ATTACK_SEA or UnitAITypes.UNITAI_ATTACK
  local u=Players[owner]:InitUnit(unitType,p:GetX(),p:GetY(),ai,DirectionTypes.DIRECTION_NORTH)
  if u then
   local tag='LCW_'..s.pid..'_'..number..'_'..i
   local r=L.Record(u,tag);r.boss=major and i==1;wave.units[#wave.units+1]=r;wave.spawned=wave.spawned+1
   L.Promotion(u,'INVADER',true)
   if naval then
    -- Early ships normally have an ocean-impassable promotion. Remove only
    -- these verified stock restrictions from hostile fleets so the flood-fill
    -- route across open water is actually traversable on tiny island maps.
    for _,name in ipairs({'PROMOTION_OCEAN_IMPASSABLE','PROMOTION_OCEAN_IMPASSABLE_UNTIL_ASTRONOMY'}) do
     local id=L.ID(name);if id then u:SetHasPromotion(id,false) end
    end
   end
   if r.boss then L.Promotion(u,'BOSS',true);u:SetName(L.Text(final and 'FINAL_COMMANDER' or 'HARROWER')) end
   if era>=3 then L.Promotion(u,'PLAGUE',true) end
   if final then L.Promotion(u,'ELITE',true) end
  end
 end
 if wave.spawned==0 then s.wave=nil;L.BeginPressure(s,era,final);return false end
 wave.finalEligible=not final or wave.spawned>=math.ceil(count*.75)
 -- Never mint victory or count failed spawns as a completed wave.
 s.waveNumber=number;s.warning=nil
 if final then s.dawn='FINAL_ACTIVE' end
 L.MarkParticipants(s);L.UpdateBossAura(s);L.DirectPressure(s)
 if ambush then L.History(s,'OUTSKIRTS_RAID');L.Notify(s,'OUTSKIRTS_RAID') end
 L.History(s,'ASSAULT',L.Text(L.EraForces[era+1].name)..' ('..wave.spawned..')')
 L.Notify(s,final and 'FINAL_NIGHT' or major and 'MAJOR_ASSAULT' or 'ASSAULT',L.Text(L.EraForces[era+1].name)..' ('..wave.spawned..')')
 return true
end
function L.MarkParticipant(s,u)
 local w=s.wave;if not w or not w.major or not u then return end
 local c=L.City(s)
  if c and u:IsCombatUnit() and u:IsHasPromotion(L.ID('PROMOTION_LC_WATCH')) and Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())<=3 then
   L.RefreshUnit(s,u)
   local tag=(u:GetScriptData() or ''):match('|(LCDEF_'..s.pid..'_%d+)|')
   local r=L.Record(u,tag);w.participants[tostring(u:GetID())]=r
  end
end
function L.MarkParticipants(s)
 if not s.wave or not s.wave.major then return end
 for u in Players[s.pid]:Units() do L.MarkParticipant(s,u) end
end
function L.UpdateBossAura(s)
 local w=s.wave;if not w then return end
 local boss
 for _,r in ipairs(w.units) do if r.boss then boss=L.Unit(r);break end end
 for _,r in ipairs(w.units) do local u=L.Unit(r)
  if u then L.Promotion(u,'COMMAND',boss and Map.PlotDistance(u:GetX(),u:GetY(),boss:GetX(),boss:GetY())<=2) end
 end
end
function L.VeteranReward(s,w)
 for _,key in ipairs(L.Keys(w.participants)) do local u=L.Unit(w.participants[key])
  if u and u:GetOwner()==s.pid then
   local rank=0;for n=1,5 do if u:IsHasPromotion(L.ID('PROMOTION_LC_VETERAN_'..n)) then rank=math.max(rank,n) end end
   rank=math.min(L.Config.MaxVeteran,rank+1)
   for n=1,5 do L.Promotion(u,'VETERAN_'..n,n==rank) end
   s.unitDirty=true
  end
 end
end
function L.RetireWave(s)
 if not s.wave then return end
 for _,r in ipairs(s.wave.units) do local u=L.Unit(r);if u then u:Kill(false,-1) end end
 s.wave=nil;s.collapse=0
end
function L.ResolveWave(s,victory)
 local w=s.wave;if not w then return end
 -- Clear first; retirement kill callbacks cannot turn a retreat into victory.
 s.wave=nil;s.collapse=0
 L.BossReward(s,w)
 if victory then
  s.wavesSurvived=s.wavesSurvived+1;L.Morale(s,w.major and 12 or 6);L.Provisions(s,L.Scale(w.major and 18 or 8))
  if w.major then s.majorSieges=s.majorSieges+1;L.VeteranReward(s,w) end
  L.History(s,'SIEGE_VICTORY',tostring(w.number));L.Notify(s,'SIEGE_VICTORY',tostring(w.number))
  if w.final then
   if w.finalEligible==true or (w.finalEligible==nil and w.spawned>=math.ceil(L.Config.MaxEnemies*.75)) then
    s.dawn='ENDURES'
    if not s.achievement then L.History(s,'HUMANITY_ENDURES');L.Notify(s,'HUMANITY_ENDURES');s.achievement=true end
   else s.dawn='FINAL_PENDING' end
  end
 else
  for _,r in ipairs(w.units) do local u=L.Unit(r);if u then u:Kill(false,-1) end end
  L.Morale(s,-4);L.History(s,'ENEMY_RETREAT',tostring(w.number));L.Notify(s,'ENEMY_RETREAT')
  if w.final then s.dawn='FINAL_PENDING' end
 end
 local delay=L.Range(s,L.Config.WaveMin,L.Config.WaveMax)-math.min(4,w.era)
 s.nextWave=L.Now()+L.Scale((w.final and not victory) and 8 or s.dawn=='FINAL_PENDING' and L.Config.Warning or delay);s.warning=nil
end
function L.InvasionTurn(s)
 if s.fallen then return end
 if s.pressure then
  L.PressureTurn(s);return
 end
 if s.wave then local w=s.wave
  if w.owner~=GameDefines.BARBARIAN_PLAYER and not Teams[Players[s.pid]:GetTeam()]:IsAtWar(Players[w.owner]:GetTeam()) then
   local era,final=w.era,w.final;L.ResolveWave(s,false);L.BeginPressure(s,era,final);return
  end
  L.MarkParticipants(s);L.UpdateBossAura(s)
  L.SiegeExposure(s)
  if s.fallen then return end
  L.BossReward(s,w)
  local alive=0
  for _,r in ipairs(w.units) do if L.Unit(r) then alive=alive+1 end end
  if alive==0 then L.ResolveWave(s,w.spawned>0 and w.defeated==w.spawned)
  elseif L.Now()>=w.expiry then L.ResolveWave(s,false);L.BeginPressure(s,w.era,w.final)
  else L.DirectPressure(s) end
 elseif s.nextWave then
  if L.Now()>=s.nextWave then L.BeginWave(s)
  elseif L.Now()>=s.nextWave-L.Scale(L.Config.Warning) and not s.warning then
   s.warning=true;local count=L.Threat(s,(s.waveNumber+1)%L.Config.MajorEvery==0,s.dawn=='FINAL_PENDING')
   L.Notify(s,'WARNING',L.Text('THREAT',count,s.nextWave-L.Now()));L.History(s,'WARNING',tostring(count))
  end
 end
end

function L.BossReward(s,w)
 if w.bossKilled and not w.bossRewarded then
  w.bossRewarded=true;s.bosses=s.bosses+1;L.Morale(s,6);L.History(s,'HARROWER_DEFEATED');L.Notify(s,'HARROWER_DEFEATED')
 end
end

-- A blocked map still produces attrition, never imaginary combat victories.
-- Retry physical spawning after a bounded infrastructure/blockade encounter.
function L.BeginPressure(s,era,final)
 s.pressure={era=era,final=final,expiry=L.Now()+L.Scale(L.Config.PressureTurns),lastTurn=-1}
 s.warning=nil;s.collapse=0
 L.Log('Physical wave blocked after radius '..L.Config.SpawnExpanded..'; siege pressure scheduled')
 L.History(s,'SPAWN_BLOCKED');L.Notify(s,'SPAWN_BLOCKED')
end
function L.PressureTurn(s)
 local r=s.pressure;if r.lastTurn==L.Now() then return end;r.lastTurn=L.Now()
 if L.Now()>=r.expiry then
  s.pressure=nil;s.nextWave=L.Now()+L.Scale(4);s.warning=nil;L.History(s,'PRESSURE_ENDED');return
 end
 local drain,defense=L.BlockadeDrain(s)
 -- Supply cost is included in Stats and applied once by EconomyTurn. Council
 -- projections and ration previews therefore include this exact cost.
 L.Morale(s,-.6/L.Speed)
 -- Sabotage consumes food stores and damages shelter; stationed defenders
 -- mitigate it. No scripted city HP damage or native defeat is fabricated.
 if not r.sabotaged and L.Now()>=r.expiry-L.Scale(3) then
  r.sabotaged=true
  if defense<3 then s.housingDamage=math.min(4,(s.housingDamage or 0)+1) end
  L.History(s,'BLOCKADE',tostring(drain))
 end
end

function L.BlockadeDrain(s)
 local c=L.City(s);local stationed=0
 for u in Players[s.pid]:Units() do
  if u:IsCombatUnit() and c and Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())<=3 then stationed=stationed+1 end
 end
 local defense=math.min(3,stationed)+math.min(2,s.assigned.VETERANS)
 local r=s.pressure
 return math.max(1,6+math.floor(r.era/2)+(r.final and 2 or 0)-defense),defense
end
function L.Infect(s,era,exposure)
 if (s.infectionNext or 0)>L.Now() or s.infection then return false end
 local medical=L.Medical(s)
 local chance=math.max(4,18+math.min(3,exposure)*7+math.max(0,era-3)*3-medical*5)
 if L.Rand(s,100)>chance then return false end
 local severity=math.max(1,math.min(4,1+math.floor(era/2)+math.min(1,exposure-1)-math.floor(medical/2)))
 local duration=L.Scale(math.max(2,math.min(L.Config.InfectionMaxTurns,5+math.floor(era/2)-medical)))
 s.infection={severity=severity,untilTurn=L.Now()+duration,lastTurn=-1}
 s.medicalCases=s.medicalCases+1
 L.History(s,'INFECTION');L.Notify(s,'INFECTION');return true
end
function L.InfectionTurn(s)
 local r=s.infection;if not r or r.lastTurn==L.Now() then return end
 r.lastTurn=L.Now()
 if L.Now()>=r.untilTurn then
  s.infection=nil;s.infectionNext=L.Now()+L.Scale(L.Config.InfectionCooldown)
  L.History(s,'INFECTION_RECOVERED');return
 end
 local medical=L.Medical(s)
 L.Morale(s,-math.max(.1,r.severity*.3-medical*.08)/L.Speed)
 -- Treatment shortens existing infections as well as resisting new exposure.
 if medical>=3 then r.untilTurn=math.max(L.Now()+1,r.untilTurn-1) end
 if medical==0 and r.severity>=3 and L.City(s):GetPopulation()>1 and L.Rand(s,10000)<=math.floor(150/L.Speed) then
  L.City(s):ChangePopulation(-1,true);L.History(s,'INFECTION_DEATH')
 end
end
function L.SiegeExposure(s)
 local w=s.wave;local c=L.City(s);if not w or not c or w.exposureTurn==L.Now() then return end
 w.exposureTurn=L.Now()
 local close,adjacent,plague,defenders=0,0,0,0
 for _,r in ipairs(w.units) do local u=L.Unit(r)
  if u then local distance=Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())
   if distance<=2 then close=close+1;if distance<=1 then adjacent=adjacent+1 end
    if u:IsHasPromotion(L.ID('PROMOTION_LC_PLAGUE')) then plague=plague+1 end
   end
  end
 end
 for u in Players[s.pid]:Units() do
  if u:IsCombatUnit() and Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())<=2 then defenders=defenders+1 end
 end
 if plague>0 then L.Infect(s,w.era,plague) end
 if close>=2 and adjacent>0 and defenders==0 and c:GetDamage()>=math.ceil(c:GetMaxHitPoints()*L.Config.CollapseDamage) then
  s.collapse=(s.collapse or 0)+1
  if s.collapse==1 then L.Notify(s,'WALLS_BREACHED');L.History(s,'WALLS_BREACHED') end
  if s.collapse>=L.Scale(L.Config.CollapseTurns) then L.Fall(s) end
 else s.collapse=0 end
end
function L.Fall(s)
 if not s.fallen then
  s.fallen=true;s.fallTurn=L.Now();s.refugee=nil;s.crisis=nil;s.pressure=nil
  L.History(s,'LAST_LIGHT_FALLEN');L.Notify(s,'LAST_LIGHT_FALLEN');L.Save(s.pid)
 end
 L.FinishFall(s)
end
function L.FinishFall(s)
 -- Called only at a player-turn boundary, NEVER from combat/acquisition.
 -- Verified CP 5.4.6 Lua bindings route through native safe iterator snapshots.
 -- CvGame::testAlive -> verifyAlive performs native elimination/game state.
 L.RetireWave(s)
 local p=Players[s.pid]
 if p:GetNumCities()>0 then p:KillCities() end
 p:KillUnits();L.Save(s.pid)
end
