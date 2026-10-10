local L=MapModData.TheLastCity
function L.Record(u,tag)
 local data=u:GetScriptData() or ''
 if not data:find(tag,1,true) then u:SetScriptData(data..'|'..tag..'|') end
 return {owner=u:GetOwner(),id=u:GetID(),created=u:GetGameTurnCreated(),tag=tag}
end
function L.Unit(r)
 if not r or r.dead then return end
 local p=r and Players[r.owner];local u=p and p:GetUnitByID(r.id)
 if u and u:GetGameTurnCreated()==r.created and (u:GetScriptData() or ''):find('|'..r.tag..'|',1,true) then return u end
end
function L.RefreshUnit(s,u)
 if not u or not u:IsCombatUnit() then return end
 local data=u:GetScriptData() or ''
 if not data:match('|LCDEF_'..s.pid..'_%d+|') then
  L.Record(u,'LCDEF_'..s.pid..'_'..s.nextUnit);s.nextUnit=s.nextUnit+1
 end
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
  if u:IsCombatUnit() then L.RefreshUnit(s,u) end
 end
end
local function passable(p,naval)
 return p and not p:IsCity() and not p:IsMountain() and not p:IsImpassable()
  and p:GetFeatureType()~=L.ID('FEATURE_ICE') and p:IsWater()==naval
end
function L.SpawnPlots(s)
 local c=L.City(s);local localPlots={};local land,sea={},{};local reachableLand={}
 L.Near(c:GetX(),c:GetY(),L.Config.SpawnMax,function(p) localPlots[p:GetPlotIndex()]=p end)
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
   if d>=L.Config.SpawnMin and p:GetOwner()==-1 and p:GetNumUnits()==0 then
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
   -- A single ordinary movement mission attempts to focus the assault. Native
   -- tactical AI may replace it; no scripted tactical behavior is promised.
   u:PushMission(MissionTypes.MISSION_MOVE_TO,p:GetX(),p:GetY(),0,0,0)
  end
 end
end
function L.BeginWave(s)
 local number=s.waveNumber+1;local final=s.dawn=='FINAL_PENDING'
 local major=number%L.Config.MajorEvery==0 or final
 local count,era=L.Threat(s,major,final);local land,sea=L.SpawnPlots(s)
 local naval=#land<math.min(3,count) and #sea>0;local pool=naval and sea or land
 if #pool==0 and #sea>0 then naval=true;pool=sea end
 if #pool==0 then
  s.nextWave=L.Now()+L.Scale(4);s.warning=nil
  L.History(s,'SPAWN_BLOCKED');L.Notify(s,'SPAWN_BLOCKED');return false
 end
 local owner=L.HostileOwner(s)
 local wave={number=number,major=major,final=final,era=era,naval=naval,owner=owner,started=L.Now(),
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
 if wave.spawned==0 then s.wave=nil;s.nextWave=L.Now()+L.Scale(4);s.warning=nil;L.History(s,'SPAWN_BLOCKED');return false end
 -- Never mint victory or count failed spawns as a completed wave.
 s.waveNumber=number;s.warning=nil
 if final then s.dawn='FINAL_ACTIVE' end
 L.MarkParticipants(s);L.UpdateBossAura(s);L.DirectPressure(s)
 L.History(s,'ASSAULT',L.Text(L.EraForces[era+1].name)..' ('..wave.spawned..')')
 L.Notify(s,final and 'FINAL_NIGHT' or major and 'MAJOR_ASSAULT' or 'ASSAULT',L.Text(L.EraForces[era+1].name)..' ('..wave.spawned..')')
 return true
end
function L.MarkParticipants(s)
 local w=s.wave;if not w or not w.major then return end
 local c=L.City(s)
 for u in Players[s.pid]:Units() do
  if u:IsCombatUnit() and u:IsHasPromotion(L.ID('PROMOTION_LC_WATCH')) and Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY())<=3 then
   local tag='LCP_'..s.pid..'_'..w.number..'_'..u:GetID()
   local r=L.Record(u,tag);w.participants[tostring(u:GetID())]=r
  end
 end
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
  end
 end
end
function L.RetireWave(s)
 if not s.wave then return end
 for _,r in ipairs(s.wave.units) do local u=L.Unit(r);if u then u:Kill(false,-1) end end
 s.wave=nil
end
function L.ResolveWave(s,victory)
 local w=s.wave;if not w then return end
 -- Clear first; retirement kill callbacks cannot turn a retreat into victory.
 s.wave=nil
 if victory then
  s.wavesSurvived=s.wavesSurvived+1;L.Morale(s,w.major and 12 or 6);L.Provisions(s,L.Scale(w.major and 18 or 8))
  if w.major then s.majorSieges=s.majorSieges+1;L.VeteranReward(s,w) end
  if w.bossKilled then s.bosses=s.bosses+1 end
  L.History(s,'SIEGE_VICTORY',tostring(w.number));L.Notify(s,'SIEGE_VICTORY',tostring(w.number))
  if w.final then s.dawn='ENDURES';L.History(s,'HUMANITY_ENDURES');L.Notify(s,'HUMANITY_ENDURES');s.achievement=true end
 else
  for _,r in ipairs(w.units) do local u=L.Unit(r);if u then u:Kill(false,-1) end end
  L.Morale(s,-4);L.History(s,'ENEMY_RETREAT',tostring(w.number));L.Notify(s,'ENEMY_RETREAT')
  if w.final then s.dawn='FINAL_PENDING' end
 end
 local delay=L.Range(s,L.Config.WaveMin,L.Config.WaveMax)-math.min(4,w.era)
 s.nextWave=L.Now()+L.Scale((w.final and not victory) and 8 or s.dawn=='FINAL_PENDING' and L.Config.Warning or delay);s.warning=nil
end
function L.InvasionTurn(s)
 if s.wave then local w=s.wave
  L.MarkParticipants(s);L.UpdateBossAura(s)
  local alive=0
  for _,r in ipairs(w.units) do if L.Unit(r) then alive=alive+1 end end
  if alive==0 then L.ResolveWave(s,w.spawned>0 and w.defeated==w.spawned)
  elseif L.Now()>=w.expiry then L.ResolveWave(s,false) end
 elseif s.nextWave then
  if L.Now()>=s.nextWave then L.BeginWave(s)
  elseif L.Now()>=s.nextWave-L.Scale(L.Config.Warning) and not s.warning then
   s.warning=true;local count=L.Threat(s,(s.waveNumber+1)%L.Config.MajorEvery==0,s.dawn=='FINAL_PENDING')
   L.Notify(s,'WARNING',L.Text('THREAT',count,s.nextWave-L.Now()));L.History(s,'WARNING',tostring(count))
  end
 end
end
