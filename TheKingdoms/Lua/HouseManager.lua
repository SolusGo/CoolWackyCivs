local K=MapModData.TheKingdoms
-- Ephemeral indexed views contain references only; all political data remains in snapshots.
K.HouseViews=setmetatable({},{__mode='k'})
function K.ActiveHouses(s,kingdom)
 local views=K.HouseViews[s]
 if not views then
  views={all={},kingdoms={}}
  for _,id in ipairs(K.Keys(s.houses)) do
   local h=s.houses[id];local k=s.kingdoms[h.kingdom]
   if k and k.active then
    views.all[#views.all+1]=h;views.kingdoms[h.kingdom]=views.kingdoms[h.kingdom] or {}
    local list=views.kingdoms[h.kingdom];list[#list+1]=h
   end
  end
  K.HouseViews[s]=views
 end
 return kingdom and (views.kingdoms[kingdom] or {}) or views.all
end
function K.Influence(s,h)
 local total=0;for _,other in ipairs(K.ActiveHouses(s,h.kingdom)) do total=total+other.influence end
 return total>0 and 100*h.influence/total or 0
end
function K.Relation(s,a,b,delta)
 if a==b or not s.houses[a] or not s.houses[b] then return end
 local value=K.Clamp((s.houses[a].relations[b] or 0)+delta,-100,100)
 s.houses[a].relations[b]=value;s.houses[b].relations[a]=value
end
function K.Loyalty(h,delta) h.loyalty=K.Clamp(h.loyalty+delta,-100,100) end
function K.HouseName(s,parent)
 local used={};for _,h in pairs(s.houses) do used[h.name]=true end
 if parent then
  local suffixes={'crest','mere','hold','ford','watch','ward','haven','fell'}
  for _,suffix in ipairs(suffixes) do local n=parent.name..suffix;if not used[n] then return n end end
 end
 local start=K.Rand(s,#K.HouseNames)
 for i=1,#K.HouseNames do local n=K.HouseNames[(start+i-1)%#K.HouseNames+1];if not used[n] then return n end end
 -- Never loop indefinitely when the pool is exhausted, even with thousands of historical Houses.
 return (parent and parent.name or 'Crown')..'ward'..s.nextHouse
end
function K.NewHouse(s,k,parent)
 local id=s.nextHouse;s.nextHouse=id+1
 local keys=K.Keys(K.HouseTraits);local a=K.Pick(s,keys);local b=a
 while b==a do b=K.Pick(s,keys) end
 local h={id=id,name=K.HouseName(s,parent),kingdom=k.id,origin=k.id,parent=parent and parent.id,
 founded=K.Now(),loyalty=35+K.Rand(s,21),prestige=8+K.Rand(s,13),influence=35+K.Rand(s,20),claim=0,claimBonus=0,power=0,
 traits={a,b},relations={},children={},timeline={},completed={},stats={rulers=0,guards=0,wars=0,completed=0,failed=0},
 demandNext=K.Now()+K.Scale(15+K.Rand(s,11)),actionNext=0,splitNext=K.Now()+K.Scale(60),
 crest={symbol=K.Pick(s,K.Symbols),background=K.Rand(s,4),color=K.Rand(s,8)}}
 s.houses[id]=h;k.houses[#k.houses+1]=id;K.HouseViews[s]=nil
 local founder=K.Character(s,id,'head');h.founder=founder.id;h.head=founder.id
 if parent then
  h.prestige=math.floor(parent.prestige*.35);h.influence=math.max(10,parent.influence*.35)
  parent.influence=math.max(5,parent.influence-h.influence);parent.children[#parent.children+1]=id
  h.traits[1]=parent.traits[1];if h.traits[1]==h.traits[2] then h.traits[2]=a==h.traits[1] and b or a end
  for rid,value in pairs(parent.relations) do if rid~=id then K.Relation(s,id,rid,math.floor(value*.5)) end end
  K.Relation(s,id,parent.id,-45);parent.splitNext=K.Now()+K.Scale(75)
 end
 local neighbours=K.ActiveHouses(s,k.id)
 for _,other in ipairs(neighbours) do if other.id~=id and not h.relations[other.id] then K.Relation(s,id,other.id,K.Rand(s,81)-40) end end
 local all=K.ActiveHouses(s)
 for _=1,2 do local other=K.Pick(s,all);if other.id~=id and (not parent or other.id~=parent.id) then K.Relation(s,id,other.id,K.Rand(s,61)-30) end end
 K.History(s,'HOUSES',parent and 'HOUSE_SPLIT' or 'HOUSE_FOUNDED',parent and {parent.name,h.name,k.name} or {h.name,k.name},id,k.id)
 K.Notify(s.pid,parent and 'HOUSE_SPLIT' or 'HOUSE_FOUNDED',unpack(parent and {parent.name,h.name,k.name} or {h.name,k.name}))
 K.Log('HOUSE','Created '..id..' '..h.name)
 return h
end
function K.HouseTick(s)
 local ruler=s.ruler and s.characters[s.ruler]
 local war=K.Wars(s.pid)
 for _,h in ipairs(K.ActiveHouses(s)) do
  h.prestige=h.prestige+0.025/K.Speed
  local k=s.kingdoms[h.kingdom];h.power=K.Influence(s,h)*k.population/100+h.prestige/12+(h.stats.kills or 0)*.1
  if K.Now()%K.Scale(3)==0 then
   local drift=h.loyalty>40 and -1 or (h.loyalty<30 and 1 or 0)
   drift=drift+K.TraitSum(h,'loyalty')+(war>0 and K.TraitSum(h,'war') or 0)
   if ruler then
    drift=drift+K.TraitSum(ruler,'loyalty',K.RulerTraits)
    if war==0 and K.TraitSum(h,'war')<0 then drift=drift-K.TraitSum(ruler,'peaceDiscontent',K.RulerTraits) end
   end
   if k.occupied then drift=drift-2 end
   if s.war then drift=drift-1 end
   K.Loyalty(h,drift)
  end
  if k.population>(h.lastPopulation or k.population) then h.influence=h.influence+1;K.Loyalty(h,1) end
  h.lastPopulation=k.population
  if not s.war and K.Now()>=h.splitNext and h.loyalty<-45 and #k.houses<K.HouseTarget(k.population)+1 and #k.houses<8 and K.Rand(s,100)<3 then
   K.NewHouse(s,k,h)
  end
  local head=s.characters[h.head]
  if head and K.Now()-head.created>K.Scale(60+head.id%25) then
   head.alive=false;head.died=K.Now();h.head=K.Character(s,h.id,'head').id
   K.History(s,'HOUSES','HEAD_CHANGED',{h.name,K.CharacterName(s,s.characters[h.head])},h.id,k.id)
  end
 end
 if K.Now()>=(s.relationshipNext or 0) then
  local houses=K.ActiveHouses(s)
  if #houses>1 then
   local a=K.Pick(s,houses);local b=K.Pick(s,houses)
   if a.id~=b.id then
    local change=K.Rand(s,2)==0 and -18 or 18
    change=change+K.TraitSum(a,'alliance')+K.TraitSum(b,'alliance')
    K.Relation(s,a.id,b.id,change)
    K.History(s,'HOUSES','RELATION_CHANGED',{a.name,b.name,K.RelationshipLabel(a.relations[b.id])},a.id)
   end
  end
  s.relationshipNext=K.Now()+K.Scale(12+K.Rand(s,9))
 end
end
function K.CanAppease(pid,hid,action)
 if not K.IsKingdoms(pid) then return false,K.Text('UNAVAILABLE') end
 local s=K.State(pid);local h=s.houses[hid];local a=K.Actions[action]
 if not h or not a or not s.kingdoms[h.kingdom].active then return false,K.Text('UNAVAILABLE') end
 if K.Now()<h.actionNext then return false,K.Text('COOLDOWN',h.actionNext-K.Now()) end
 if a.militaristic and not K.HasTrait(h,'Militaristic') then return false,K.Text('MILITARISTIC_ONLY') end
 local cost=K.Scale(a.gold*(1+Players[pid]:GetCurrentEra()*.2))
 if Players[pid]:GetGold()<cost then return false,K.Text('NEED_GOLD',cost) end
 return true,K.Text('ACTION_HELP_'..action,cost,a.loyalty,a.influence),cost
end
function K.Appease(pid,hid,action)
 local ok,reason,cost=K.CanAppease(pid,hid,action);if not ok then return false,reason end
 local s=K.State(pid);local h=s.houses[hid];local a=K.Actions[action]
 Players[pid]:ChangeGold(-cost);K.Loyalty(h,a.loyalty);h.influence=h.influence+a.influence
 h.prestige=h.prestige+(a.prestige or 0);h.claimBonus=h.claimBonus+(a.claim or 0)
 h.actionNext=K.Now()+K.Scale(10)
 if a.penalty then s.kingdoms[h.kingdom].estatesUntil=K.Now()+K.Scale(a.penalty) end
 K.History(s,'HOUSES','APPEASED',{h.name,K.Text('ACTION_'..action)},hid,h.kingdom)
 K.RefreshRealm(s);K.Commit(pid);return true,K.Text('ACTION_DONE')
end
function K.RelationshipLabel(n)
 return K.Text(n<=-80 and 'REL_FEUD' or n<=-40 and 'REL_RIVAL' or n<=-15 and 'REL_DISTRUST' or n<20 and 'REL_NEUTRAL' or n<50 and 'REL_FRIENDLY' or n<80 and 'REL_ALLIED' or 'REL_MARRIAGE')
end
