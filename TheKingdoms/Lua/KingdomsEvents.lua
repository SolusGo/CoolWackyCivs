local K=MapModData.TheKingdoms
local function hook(name,fn)
 if GameEvents[name] and GameEvents[name].Add then GameEvents[name].Add(fn)
 else K.Log('KINGDOMS','Optional hook unavailable: '..name) end
end
local function update(pid)
 if K.IsKingdoms(pid) then local s=K.State(pid);K.ReconcileKingdoms(s);K.RefreshRealm(s);K.Claims(s);K.Commit(pid) end
end
hook('PlayerDoTurn',K.Turn)
hook('PlayerCityFounded',update)
hook('CityCaptureComplete',function(oldOwner,capital,x,y,newOwner,population,conquest)
 local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity();if c then K.ClearCity(c) end
 if K.IsKingdoms(newOwner) then
  local s=K.State(newOwner);if conquest then s.counters.captures=(s.counters.captures or 0)+1 end
  for _,h in ipairs(K.ActiveHouses(s)) do if K.HasTrait(h,'Militaristic') or K.HasTrait(h,'Expansionist') then h.prestige=h.prestige+2;h.claimBonus=h.claimBonus+1 end end
 end
 update(oldOwner);update(newOwner)
end)
hook('SetPopulation',function(x,y) local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity();if c then update(c:GetOwner()) end end)
hook('CityConstructed',update)
hook('UnitCreated',function(pid,uid,kind)
 if not K.IsKingdoms(pid) then return end
 local s=K.State(pid);local u=Players[pid]:GetUnitByID(uid);if not u then return end
 local info=GameInfo.Units[kind]
 if info and info.Special=='SPECIALUNIT_PEOPLE' then s.counters.greatPeople=(s.counters.greatPeople or 0)+1 end
 if kind==K.ID('UNIT_KINGDOMS_GUARD') then K.GuardCreated(pid,uid) end
 if u:IsCombatUnit() then K.Promotion(u,'CIVILWAR',s.war~=nil) end
 K.Commit(pid)
end)
hook('CityTrained',function(pid,city,uid)
 if not K.IsKingdoms(pid) then return end
 local u=Players[pid]:GetUnitByID(uid);local s=K.State(pid)
 if u and u:IsCombatUnit() then s.counters.trained=(s.counters.trained or 0)+1 end
 K.GuardCreated(pid,uid);K.Commit(pid)
end)
hook('PlayerCanTrain',function(pid,kind)
 if K.IsKingdoms(pid) and kind==K.ID('UNIT_KINGDOMS_GUARD') then return K.GuardCount(K.State(pid))<7 end
 return true
end)
hook('UnitConverted',K.GuardConverted)
hook('UnitPrekill',function(pid,uid,kind,x,y,delay,killer)
 if delay then return end -- Final kill only; delayed/final pairs must never double-count.
 if K.IsKingdoms(pid) then
  local s=K.State(pid)
  for _,g in pairs(s.guards) do if g.alive and g.unit==uid then
   local replacement
   for other in Players[pid]:Units() do
    if other:GetID()~=uid and K.GuardOf(s,other)==g then replacement=other;break end
   end
   if replacement then g.unit=replacement:GetID();g.birth=replacement:GetGameTurnCreated()
   else K.GuardFallen(s,g) end
  end end
  local pending=s.pending[uid]
  if pending then
   s.pending[uid]=nil
   for other in Players[pid]:Units() do
    if other:GetID()~=uid then
     local slot=K.ID('PROMOTION_KINGDOMS_GUARD_ID_'..pending.slot)
     if slot and other:IsHasPromotion(slot) then pending.unit=other:GetID();pending.birth=other:GetGameTurnCreated();s.pending[pending.unit]=pending;break end
    end
   end
  end
  K.Commit(pid)
 end
 if killer and killer>=0 and killer~=pid and K.IsKingdoms(killer) then
  local s=K.State(killer);local info=GameInfo.Units[kind]
  if info and (info.Combat or 0)>0 then
   local key=pid==(GameDefines.BARBARIAN_PLAYER or 63) and 'barbarianKills' or 'enemyKills'
   s.counters[key]=(s.counters[key] or 0)+1
   for _,h in ipairs(K.ActiveHouses(s)) do if K.HasTrait(h,'Militaristic') then h.prestige=h.prestige+.3;h.stats.kills=(h.stats.kills or 0)+1 end end
   K.Commit(killer)
  end
 end
end)
hook('BarbariansCampCleared',function(x,y,pid)
 if K.IsKingdoms(pid) then local s=K.State(pid);s.counters.camps=(s.counters.camps or 0)+1;K.Commit(pid) end
end)
hook('CombatEnded',function(ap,au,ad,af,am,dp,du,dd,df,dm)
 local function record(pid,uid,kill)
  if not K.IsKingdoms(pid) then return end
  local s=K.State(pid);local u=Players[pid]:GetUnitByID(uid);local g=u and K.GuardOf(s,u)
  if not g then for _,entry in pairs(s.guards) do if entry.unit==uid and (entry.alive or entry.died==K.Now()) and (not u or entry.birth==u:GetGameTurnCreated()) then g=entry;break end end end
  if g then
   g.battles=g.battles+1;if kill then g.kills=g.kills+1;s.houses[g.house].prestige=s.houses[g.house].prestige+1 end
   local c=s.characters[g.character];c.stats.kills=g.kills;c.stats.battles=g.battles;K.Commit(pid)
  end
 end
 record(ap,au,du>=0 and df>=dm);record(dp,du,au>=0 and af>=am)
end)
hook('TeamTechResearched',function(team)
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if K.IsKingdoms(pid) and Players[pid]:GetTeam()==team then update(pid) end end
end)
if Events.LoadScreenClose then Events.LoadScreenClose.Add(function()
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if K.IsKingdoms(pid) then K.Initialize(pid) end end
end) end
