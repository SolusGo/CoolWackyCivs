local K=MapModData.TheKingdoms
local function hasSlot(u,slot)
 local id=slot and K.ID('PROMOTION_KINGDOMS_GUARD_ID_'..slot)
 return id and u:IsHasPromotion(id)
end
local function allocate(s)
 local used={}
 for _,g in pairs(s.guards) do if g.alive and g.slot then used[g.slot]=true end end
 for _,e in pairs(s.pending) do if e.slot then used[e.slot]=true end end
 for slot=1,7 do if not used[slot] then return slot end end
end
local function ensureSlots(s)
 for _,cid in ipairs(K.Keys(s.guards)) do local g=s.guards[cid];if g.alive and not g.slot then g.slot=allocate(s) end end
 for _,uid in ipairs(K.Keys(s.pending)) do local e=s.pending[uid];if not e.slot then e.slot=allocate(s) end end
end
function K.PendingOf(s,u)
 for _,entry in pairs(s.pending) do
  if entry.unit==u:GetID() and entry.birth==u:GetGameTurnCreated() or hasSlot(u,entry.slot) then return entry end
 end
end
local function token(pid,cid) return '|KINGDOMS_GUARD:'..pid..':'..cid..'|' end
local function marker(u)
 local text=u.GetScriptData and u:GetScriptData() or ''
 local pid,cid=text:match('|KINGDOMS_GUARD:(%d+):(%d+)|')
 return tonumber(pid),tonumber(cid)
end
local function mark(pid,u,cid)
 if u.SetScriptData then
  local text=u:GetScriptData() or '';text=text:gsub('|KINGDOMS_GUARD:%d+:%d+|','')
  u:SetScriptData(text..token(pid,cid))
 end
 K.Promotion(u,'GUARD',true)
end
function K.GuardCount(s)
 local n=0
 for _,g in pairs(s.guards) do if g.alive then n=n+1 end end
 for _ in pairs(s.pending) do n=n+1 end
 return n
end
function K.GuardOf(s,u)
 local pid,cid=marker(u)
 if pid==s.pid and s.guards[cid] and s.guards[cid].alive then return s.guards[cid] end
 for _,g in pairs(s.guards) do if g.alive and (g.unit==u:GetID() and (not u.GetGameTurnCreated or g.birth==u:GetGameTurnCreated()) or hasSlot(u,g.slot)) then return g end end
end
function K.GuardCreated(pid,uid)
 if not K.IsKingdoms(pid) then return end
 local s=K.State(pid);local u=Players[pid]:GetUnitByID(uid)
 if not u or u:GetUnitType()~=K.ID('UNIT_KINGDOMS_GUARD') or K.GuardOf(s,u) or s.pending[uid] then return end
 K.ReconcileKingdoms(s)
 if K.GuardCount(s)>=7 then
  -- Two cities can finish pre-queued Guards in one turn. Reject/refund the excess.
  -- Native PlayerCanTrain prevents orders; this is the completion-time backstop.
  -- UnitCreated fires inside native production completion, before its production
  -- reset. Refund Gold, which cannot be erased by that later native reset.
  local cost=GameInfo.Units[u:GetUnitType()].Cost or 120
  Players[pid]:ChangeGold(K.Scale(cost*.5))
  u:Kill(false,-1);K.Notify(pid,'GUARD_CAP');return
 end
 local pool=K.ActiveHouses(s);local candidates={};local used={}
 for _=1,math.min(3,#pool) do
  local offset=K.Rand(s,#pool)
  for j=1,#pool do
   local h=pool[(offset+j-1)%#pool+1]
   if not used[h.id] then
    used[h.id]=true;local c=K.Character(s,h.id,'candidate');c.guardTrait=K.Pick(s,K.Keys(K.GuardTraits));candidates[#candidates+1]=c.id;break
   end
  end
 end
 if #candidates==0 then return end
 s.pending[uid]={unit=uid,birth=u:GetGameTurnCreated(),created=K.Now(),candidates=candidates,slot=allocate(s)}
 K.Promotion(u,'GUARD_ID_'..s.pending[uid].slot,true)
 K.Promotion(u,'GUARD',true)
 -- Pending units cannot fight anonymously before the player makes a choice.
 K.Promotion(u,'PENDING',true)
 K.Notify(pid,'GUARD_CHOOSE');K.Save(pid)
 if not Players[pid]:IsHuman() then K.AutoAppoint(pid,uid) end
end
function K.Appoint(pid,uid,cid)
 local s=K.State(pid);local pending=s.pending[uid];local u=Players[pid]:GetUnitByID(uid)
 if not K.IsKingdoms(pid) or not pending or not u or pending.birth~=u:GetGameTurnCreated() then return false end
 local valid=false;for _,id in ipairs(pending.candidates) do if id==cid then valid=true end end
 if not valid then return false end
 local c=s.characters[cid];local h=s.houses[c.house]
 if not h or not s.kingdoms[h.kingdom].active then return false end
 c.role='guard';c.appointment=K.Now();c.alive=true
 local g={character=cid,house=c.house,trait=c.guardTrait,unit=uid,birth=u:GetGameTurnCreated(),appointed=K.Now(),kills=0,battles=0,alive=true,oathNext=K.Now()+K.Scale(8),slot=pending.slot}
 s.guards[cid]=g;s.pending[uid]=nil
 K.Log('KINGSGUARD','Appointed character '..cid..' in slot '..g.slot..' to unit '..uid)
 for _,id in ipairs(pending.candidates) do if id~=cid then local other=s.characters[id];other.role='passed candidate';other.retired=K.Now();K.Loyalty(s.houses[other.house],-3) end end
 mark(pid,u,cid);K.Promotion(u,'GUARD_ID_'..g.slot,true);K.Promotion(u,'PENDING',false);K.Promotion(u,c.guardTrait:upper(),true)
 if u.SetName then u:SetName(K.CharacterName(s,c)) end
 K.Loyalty(h,15);h.prestige=h.prestige+8;h.stats.guards=h.stats.guards+1
 K.History(s,'GUARDS','GUARD_APPOINTED',{K.CharacterName(s,c),h.name},h.id);K.Notify(pid,'GUARD_APPOINTED',K.CharacterName(s,c),h.name)
 K.RefreshRealm(s);K.Commit(pid);return true
end
function K.AutoAppoint(pid,uid)
 local s=K.State(pid);local pending=s.pending[uid];if not pending then return end
 local best,score
 for _,cid in ipairs(pending.candidates) do
  local c=s.characters[cid];local h=s.houses[c.house]
  if s.kingdoms[h.kingdom].active then
   local n=K.GuardTraits[c.guardTrait].value*3+(100-h.loyalty)*K.Influence(s,h)/100
   if not score or n>score then best,score=cid,n end
  end
 end
 if best then K.Appoint(pid,uid,best) end
end
function K.GuardFallen(s,g,reason)
 if not g or not g.alive then return end
 g.alive=false;g.died=K.Now();g.oathPending=nil;local c=s.characters[g.character];c.alive=false;c.died=K.Now()
 K.Log('KINGSGUARD','Released character '..g.character..' from slot '..g.slot)
 K.History(s,'GUARDS',reason or 'GUARD_FALLEN',{K.CharacterName(s,c)},g.house)
 K.Notify(s.pid,reason or 'GUARD_FALLEN',K.CharacterName(s,c))
end
function K.GuardConverted(oldPid,newPid,oldID,newID,upgrade)
 if not K.IsKingdoms(oldPid) then
  local u=Players[newPid] and Players[newPid]:GetUnitByID(newID)
  if u then K.Promotion(u,'CIVILWAR',false);K.Promotion(u,'RULER_COMBAT',false) end;return
 end
 local s=K.State(oldPid);local old=Players[oldPid]:GetUnitByID(oldID);local u=Players[newPid] and Players[newPid]:GetUnitByID(newID)
 local g=old and K.GuardOf(s,old)
 if not g then for _,entry in pairs(s.guards) do if entry.alive and entry.unit==oldID then g=entry;break end end end
 if g and u and oldPid==newPid and upgrade then
  g.unit=newID;g.birth=u:GetGameTurnCreated();mark(newPid,u,g.character);K.Promotion(u,g.trait:upper(),true);K.Promotion(u,'GUARD_ID_'..g.slot,true)
  if u.SetName then u:SetName(K.CharacterName(s,s.characters[g.character])) end
 elseif g then
  K.GuardFallen(s,g,'GUARD_LEFT')
  if u then
   u:SetScriptData((u:GetScriptData() or ''):gsub('|KINGDOMS_GUARD:%d+:%d+|',''))
   K.Promotion(u,'GUARD',false);K.Promotion(u,g.trait:upper(),false);K.Promotion(u,'CIVILWAR',false);K.Promotion(u,'RULER_COMBAT',false)
   K.Promotion(u,'GUARD_ID_'..g.slot,false)
  end
 end
 local pending=s.pending[oldID]
 if pending then
  s.pending[oldID]=nil
  if u and oldPid==newPid and upgrade then pending.unit=newID;pending.birth=u:GetGameTurnCreated();s.pending[newID]=pending;K.Promotion(u,'PENDING',true)
  elseif u then K.Promotion(u,'PENDING',false);K.Promotion(u,'GUARD',false);K.Promotion(u,'GUARD_ID_'..pending.slot,false) end
 end
 K.Commit(oldPid)
end
function K.GuardOpposes(s,g)
 local w=s.war;local supported=w and w.supported and w.factions[w.supported]
 local f=supported and K.FactionFor(s,g.house)
 return f and f.id~=supported.id or false
end
function K.GuardTick(s)
 local p=Players[s.pid]
 ensureSlots(s)
 -- Native slot promotions survive upgrades; ScriptData is restored when CP does not copy it.
 local found={}
 for u in p:Units() do
  if not (u.IsDelayedDeath and u:IsDelayedDeath()) then
   local g=K.GuardOf(s,u);local pending=K.PendingOf(s,u)
   if g then g.unit=u:GetID();g.birth=u:GetGameTurnCreated();found[g.character]=true;mark(s.pid,u,g.character);K.Promotion(u,g.trait:upper(),true);K.Promotion(u,'GUARD_ID_'..g.slot,true)
   elseif pending then
    if pending.unit~=u:GetID() then s.pending[pending.unit]=nil;pending.unit=u:GetID();pending.birth=u:GetGameTurnCreated();s.pending[pending.unit]=pending end
    K.Promotion(u,'GUARD_ID_'..pending.slot,true);K.Promotion(u,'PENDING',true)
   elseif u:GetUnitType()==K.ID('UNIT_KINGDOMS_GUARD') then K.GuardCreated(s.pid,u:GetID()) end
  end
 end
 for _,g in pairs(s.guards) do
  if g.alive then
   local opposed=K.GuardOpposes(s,g)
   if not opposed then g.oathPending=nil end
   if not found[g.character] then K.GuardFallen(s,g)
   elseif opposed and K.Now()>=g.oathNext and not g.oathPending then
    local h=s.houses[g.house]
    if h.loyalty<20 and K.Rand(s,100)<15 then
     g.oathPending=true;K.Notify(s.pid,'GUARD_OATH',K.CharacterName(s,s.characters[g.character]))
    end
    g.oathNext=K.Now()+K.Scale(8)
   end
  end
 end
 for _,uid in ipairs(K.Keys(s.pending)) do
  local entry=s.pending[uid];local u=p:GetUnitByID(uid)
  if not u or entry.birth~=u:GetGameTurnCreated() then s.pending[uid]=nil
  else
   local valid=false;for _,cid in ipairs(entry.candidates) do local h=s.houses[s.characters[cid].house];if s.kingdoms[h.kingdom].active then valid=true end end
   if not valid then
    for _,h in ipairs(K.ActiveHouses(s)) do local c=K.Character(s,h.id,'candidate');c.guardTrait=K.Pick(s,K.Keys(K.GuardTraits));entry.candidates={c.id};break end
   end
   if not p:IsHuman() then K.AutoAppoint(s.pid,uid) end
  end
 end
end
function K.CanOath(pid,cid,action)
 local s=K.State(pid);local g=s.guards[cid]
 if not K.IsKingdoms(pid) or not g or not g.alive or not g.oathPending or not K.GuardOpposes(s,g) or not Players[pid]:GetUnitByID(g.unit) then return false,K.Text('UNAVAILABLE') end
 if action~='KEEP' and action~='RETURN' and action~='OATH' then return false,K.Text('UNAVAILABLE') end
 local cost=action=='KEEP' and K.Scale(80) or 0
 if Players[pid]:GetGold()<cost then return false,K.Text('NEED_GOLD',cost) end
 return true,K.Text('OATH_HELP_'..action,cost),cost
end
function K.Oath(pid,cid,action)
 local ok,reason,cost=K.CanOath(pid,cid,action);if not ok then return false,reason end
 local s=K.State(pid);local g=s.guards[cid];local u=Players[pid]:GetUnitByID(g.unit);local h=s.houses[g.house]
 g.oathPending=nil;g.oathNext=K.Now()+K.Scale(20);Players[pid]:ChangeGold(-cost)
 if action=='RETURN' then
  K.Loyalty(h,12);h.prestige=h.prestige+4;Players[pid]:ChangeGold(K.Scale(50));K.GuardFallen(s,g,'GUARD_RETURNED');u:Kill(false,-1)
 elseif action=='OATH' then
  local ruler=s.ruler and s.characters[s.ruler];local relation=ruler and (h.relations[ruler.house] or 0) or 0
  local chance=K.Clamp(55+h.loyalty*.2+relation*.1+(K.GuardTraits[g.trait].oath or 0)+(K.Now()-g.appointed)/K.Speed*.25+h.prestige*.05,20,95)
  local loyal=K.Rand(s,100)<chance;K.Loyalty(h,loyal and 8 or -12)
  -- Failure wounds the Guard and denies one turn of movement; never steals or deletes it.
  if not loyal then
   local cap=u.GetMaxHitPoints and math.floor(u:GetMaxHitPoints()*.8) or 80
   u:SetDamage(math.max(u:GetDamage(),math.min(cap,u:GetDamage()+20)));u:FinishMoves()
  end
  K.History(s,'GUARDS',loyal and 'OATH_KEPT' or 'OATH_FAILED',{K.CharacterName(s,s.characters[cid])},h.id)
 else K.Loyalty(h,-5);K.History(s,'GUARDS','OATH_PAID',{K.CharacterName(s,s.characters[cid])},h.id) end
 K.RefreshRealm(s);K.Commit(pid);return true,K.Text('ACTION_DONE')
end
