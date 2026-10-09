local I=MapModData.TheShatteredEmpire
function I.LandCombat(u) return u and u:IsCombatUnit() and u:GetDomainType()==DomainTypes.DOMAIN_LAND end
function I.Home(s,u)
 local nearest,distance
 for _,g in ipairs(I.Provinces(s)) do local d=Map.PlotDistance(u:GetX(),u:GetY(),g.x,g.y)
  if not distance or d<distance then nearest=g;distance=d end
 end
 local cap=I.Capital(s.pid)
 if cap and (not distance or Map.PlotDistance(u:GetX(),u:GetY(),cap:GetX(),cap:GetY())<distance) then return end
 return nearest
end
function I.Oath(s,r,u)
 local discipline=u and u:IsHasPromotion(I.ID('PROMOTION_IMPERIAL_DISCIPLINE'))
 return I.Clamp(r.oath+(s.reform=='DICTATORSHIP' and discipline and 15 or 0),0,100)
end
function I.Track(s,u,home)
 if not I.LandCombat(u) then return end
 local id=u:GetID();local record=s.units[id]
 if not record or record.birth~=u:GetGameTurnCreated() then
  local g=home and s.governors[home] or I.Home(s,u)
  record={id=s.nextUnit,unit=id,birth=u:GetGameTurnCreated(),home=g and g.key,governor=g and g.id,oath=75,battles=0,kills=0,veteran=false,kind=u:GetUnitType()}
  s.nextUnit=s.nextUnit+1;s.units[id]=record
  I.DirtyUnit(s,id)
 end
 return record
end
function I.UnitEffects(s,u)
 local marked=u:IsHasPromotion(I.ID('PROMOTION_IMPERIAL_DISCIPLINE'))
 I.Promotion(u,'DISCIPLINE_ACTIVE',marked and s.authority>=60)
 I.Promotion(u,'REBEL_COMBAT',s.reform=='DICTATORSHIP')
end
function I.ApplyUnitEffects(s,w)
 w=w or I.Pending(s.pid);local mode=tostring(s.authority>=60)..':'..tostring(s.reform=='DICTATORSHIP')
 if w.unitMode~=mode then
  for u in Players[s.pid]:Units() do if I.LandCombat(u) then I.UnitEffects(s,u) end end
 else for uid in pairs(w.units) do local u=Players[s.pid]:GetUnitByID(uid);if I.LandCombat(u) then I.UnitEffects(s,u) end end end
 w.unitMode=mode;w.units={}
end
function I.UnitTick(s,political)
 local p=Players[s.pid];local alive={};local w=I.Pending(s.pid)
 local mode=tostring(s.authority>=60)..':'..tostring(s.reform=='DICTATORSHIP');local all=w.unitMode~=mode
 for u in p:Units() do if I.LandCombat(u) then
  local r=I.Track(s,u);alive[u:GetID()]=true
  local g=r.home and s.governors[r.home]
  if g and g.id~=r.governor then r.governor=g.id end
  if g and not g.active then r.home=nil;r.governor=nil;g=nil end
  if political then
   local target=s.authority*.45+(g and g.loyalty or s.authority)*.55
   if g and g.prestige>60 and g.loyalty<45 then target=target-10 end
   if g and g.archetype=='MILITARIST' and g.loyalty<45 then target=target-5 end
   r.oath=I.Clamp(r.oath+I.Clamp(math.floor((target-r.oath)/4),-8,8),0,100)
  end
  r.veteran=u:GetExperience()>=30
  if all or w.units[u:GetID()] then I.UnitEffects(s,u) end
 end end
 for uid in pairs(s.units) do if not alive[uid] then s.units[uid]=nil end end
 w.unitMode=mode;w.units={}
end
function I.Converted(oldOwner,newOwner,oldID,newID,upgrade)
 if not I.IsEmpire(oldOwner) then
  if I.IsEmpire(newOwner) then local s=I.State(newOwner);local u=Players[newOwner]:GetUnitByID(newID);if I.Track(s,u) then I.DirtyUnit(s,newID);I.Commit(newOwner) end end
  return
 end
 local s=I.State(oldOwner);local r=s.units[oldID]
 local old=Players[oldOwner]:GetUnitByID(oldID)
 if r and (not old or r.birth==old:GetGameTurnCreated()) then
  if newOwner==oldOwner then
   local u=Players[newOwner]:GetUnitByID(newID)
   if u and I.LandCombat(u) then r.unit=newID;r.birth=u:GetGameTurnCreated();r.kind=u:GetUnitType();s.units[newID]=r;I.DirtyUnit(s,newID) end
  else
   local u=Players[newOwner] and Players[newOwner]:GetUnitByID(newID)
   if I.IsEmpire(newOwner) then
    local recipient=I.State(newOwner);if I.Track(recipient,u) then I.DirtyUnit(recipient,newID);I.Commit(newOwner) end
   else for _,name in ipairs({'DISCIPLINE','DISCIPLINE_ACTIVE','REBEL_COMBAT'}) do I.Promotion(u,name,false) end end
  end
  if oldID~=newID or oldOwner~=newOwner then s.units[oldID]=nil end
 end
 I.Commit(oldOwner)
end
local vanilla={'UNIT_WARRIOR','UNIT_SPEARMAN','UNIT_SWORDSMAN','UNIT_PIKEMAN','UNIT_LONGSWORDSMAN','UNIT_MUSKETMAN','UNIT_RIFLEMAN','UNIT_GREAT_WAR_INFANTRY','UNIT_INFANTRY','UNIT_MECHANIZED_INFANTRY','UNIT_ARCHER','UNIT_COMPOSITE_BOWMAN','UNIT_CROSSBOWMAN','UNIT_GATLINGGUN','UNIT_MACHINE_GUN','UNIT_BAZOOKA','UNIT_IMPERIAL_LEGION'}
function I.CanDefect(u)
 if not I.LandCombat(u) or u:IsEmbarked() or u:IsCargo() or not u:GetPlot() or u:GetPlot():IsCity() then return false end
 for _,name in ipairs(vanilla) do if u:GetUnitType()==I.ID(name) then return true end end
 return false
end
function I.Defections(s,g,f)
 if not g or not g.active or not I.City(g,s.pid) or not f or not f.active or f.governor~=g.id or g.faction~=f.id or f.defectionBusy then return end
 f.defectionBusy=true
 local activeDefections=0;for _,faction in pairs(s.factions) do if faction.active then activeDefections=activeDefections+(faction.defections or 0) end end
 local done=0;local max=math.min(math.max(0,(f.defectionLimit or 2)-(f.defections or 0)),math.max(0,6-activeDefections))
 for _,uid in ipairs(I.Keys(s.units)) do local r=s.units[uid];local u=Players[s.pid]:GetUnitByID(uid)
  if done<max and r.home==g.key and r.governor==g.id and u and I.Oath(s,r,u)<40 and r.birth==u:GetGameTurnCreated() and I.CanDefect(u) then
   -- Create a validated replacement first; only then remove the imperial unit.
   local rebel=I.SpawnRebel(s,f,u:GetUnitType(),u:GetX(),u:GetY(),true)
   if rebel then
    for _,name in ipairs({'DISCIPLINE','DISCIPLINE_ACTIVE','REBEL_COMBAT'}) do I.Promotion(rebel,name,false) end
    rebel:SetExperience(u:GetExperience())
    for promo in GameInfo.UnitPromotions() do
     if promo.LostWithUpgrade==0 and not promo.Type:find('PROMOTION_IMPERIAL_',1,true) and u:IsHasPromotion(promo.ID) then rebel:SetHasPromotion(promo.ID,true) end
    end
    -- Reserve the allowance before native Kill callbacks can reenter.
    f.defections=(f.defections or 0)+1;done=done+1
    if s.war and f.war==s.war.id then s.war.defections=s.war.defections+1 end
    u:Kill(false,-1);s.units[uid]=nil
    I.History(s,'DEFECTION',I.Text('HISTORY_DEFECTION',g.name,Locale.ConvertTextKey(GameInfo.Units[r.kind].Description)))
   end
  end
 end
 f.defectionBusy=nil
 if done>0 then I.Commit(s.pid) end
end
