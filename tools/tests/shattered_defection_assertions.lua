local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0];local g=I.Provinces(s)[1];local c=I.City(g,0)
g.loyalty=5;I.BeginRevolt(s,g);local f=s.factions[g.faction];assert(f.budget==0)
local function soldier(kind,x,y,oath)
 local u=p:InitUnit(kind,x,y,1);local r=I.Track(s,u)
 if r then r.home=g.key;r.governor=g.id;r.oath=oath or 5 end
 return u
end
local guard=soldier(GameInfoTypes.UNIT_IMPERIAL_LEGION,c.x,c.y)
local civilian=soldier(GameInfoTypes.UNIT_SETTLER,c.x+2,c.y+1)
local embarked=soldier(GameInfoTypes.UNIT_WARRIOR,c.x+2,c.y+2);embarked.embarked=true
local cargo=soldier(GameInfoTypes.UNIT_WARRIOR,c.x+3,c.y+2);cargo.cargo=true
local unique=soldier(GameInfoTypes.UNIT_ROMAN_LEGION,c.x+3,c.y+1)
local marked=soldier(GameInfoTypes.UNIT_IMPERIAL_LEGION,c.x+2,c.y,35)
s.reform='DICTATORSHIP';I.Defections(s,g,f);assert(p.units[marked.id],'Effective Dictatorship Oath must protect the Legion')
s.reform='NONE';marked:SetExperience(57)
local permanent
for promo in GameInfo.UnitPromotions() do if promo.LostWithUpgrade==0 and not promo.Type:find('PROMOTION_IMPERIAL_',1,true) then permanent=promo.ID;break end end
assert(permanent);marked:SetHasPromotion(permanent,true)
local second=soldier(GameInfoTypes.UNIT_IMPERIAL_LEGION,c.x+4,c.y+1,5);local lineage=s.units[second.id].id
second=upgrade(second.id,700);assert(s.units[700].id==lineage)
local third=newUnit(0,900,GameInfoTypes.UNIT_WARRIOR);third.x=c.x+4;third.y=c.y+2;p.units[900]=third
local r=I.Track(s,third);r.home=g.key;r.governor=g.id;r.oath=5
local saves=0;local save=I.Save;I.Save=function(...) saves=saves+1;return save(...) end
I.Defections(s,g,f);I.Save=save
assert(saves==1 and f.defections==2 and f.budget==0,'Defections use their own allowance and one snapshot')
assert(not p.units[marked.id] and not p.units[700] and p.units[third.id])
assert(p.units[guard.id] and p.units[civilian.id] and p.units[embarked.id] and p.units[cargo.id] and p.units[unique.id])
local veteran
for uid in pairs(f.units) do local u=Players[63]:GetUnitByID(uid);if u.xp==57 then veteran=u end end
assert(veteran and veteran:IsHasPromotion(permanent) and not veteran:IsHasPromotion(GameInfoTypes.PROMOTION_IMPERIAL_DISCIPLINE))
I.Defections(s,g,f);assert(f.defections==2 and p.units[third.id])
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);g=s.governors[g.key];f=s.factions[f.id]
I.Defections(s,g,f);assert(f.defections==2 and p.units[third.id],'Reload cannot reset the defection cap')
-- Empire allowance survives several concurrent factions; it never exceeds six.
local origins={g}
for n=1,3 do local city=newCity(0,90+n,30+n*8,20);p.cities[city.id]=city end
I.Reconcile(s)
for _,prov in ipairs(I.Provinces(s)) do if prov.key~=g.key and #origins<4 then origins[#origins+1]=prov end end
for n=2,4 do
 local prov=origins[n];I.BeginRevolt(s,prov);local faction=s.factions[prov.faction];faction.budget=0
 for k=1,3 do local u=p:InitUnit(GameInfoTypes.UNIT_WARRIOR,prov.x+2,prov.y+k,1);local r=s.units[u.id];r.home=prov.key;r.governor=prov.id;r.oath=1 end
 I.Defections(s,prov,faction)
 assert(faction.defections==(n<=3 and 2 or 0))
end
local total=0;for _,faction in pairs(s.factions) do if faction.active then total=total+faction.defections end end;assert(total==6)
-- Global live-rebel cap also protects a defection, even with an unused allowance.
local prov=origins[4];local faction=s.factions[prov.faction];faction.budget=30
for n=1,30 do I.SpawnRebel(s,faction,GameInfoTypes.UNIT_WARRIOR,90,30) end
assert(I.RebelCount(s)==24);local count=0;for _ in pairs(p.units) do count=count+1 end
-- Free the empire allowance while retaining the global army cap.
f.defections=0;I.Defections(s,prov,faction);local after=0;for _ in pairs(p.units) do after=after+1 end;assert(after==count and faction.defections==0)
for uid in pairs(faction.units) do Players[63]:GetUnitByID(uid):Kill(false,-1);break end
assert(I.RebelCount(s)==23,'Dead rebel records cannot consume the live-army cap')
assert(I.SpawnRebel(s,faction,GameInfoTypes.UNIT_WARRIOR,90,30));assert(I.RebelCount(s)==24)
-- No safe replacement plot: retain the original soldier and all allowances.
I.ClearFactionUnits(faction);local candidates={}
for _,uid in ipairs(I.Keys(s.units)) do local r=s.units[uid];if r.home==prov.key then local u=p:GetUnitByID(uid);candidates[#candidates+1]=u;I.Near(u.x,u.y,3,function(plot) plot.impassable=true end) end end
I.Defections(s,prov,faction);assert(faction.defections==0)
for _,u in ipairs(candidates) do assert(p.units[u.id]==u) end
-- Legacy faction snapshots receive a persisted allowance without reopening spent slots.
faction.defections=3;faction.defectionLimit=nil;I.Migrate(s,0);assert(faction.defectionLimit==3)
