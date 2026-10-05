local K=MapModData.TheKingdoms
function K.Factions(s)
 local factions=s.war and s.war.factions or {};local total=0
 for _,f in ipairs(factions) do total=total+math.max(1,f.strength) end
 for _,f in ipairs(factions) do f.percent=100*math.max(1,f.strength)/math.max(1,total) end
 return factions
end
function K.FactionFor(s,hid)
 for _,f in ipairs(s.war and s.war.factions or {}) do for _,id in ipairs(f.members) do if id==hid then return f end end end
end
function K.MoveFaction(s,hid,target)
 local previous=K.FactionFor(s,hid)
 if previous and previous.id==target.id then return end
 if previous then
  if previous.house==hid then return end -- Claimants never defect from their own coalition.
  for i=#previous.members,1,-1 do if previous.members[i]==hid then table.remove(previous.members,i) end end
  previous.strength=math.max(1,previous.strength-s.houses[hid].power)
 end
 target.members[#target.members+1]=hid;target.strength=target.strength+s.houses[hid].power
 K.History(s,'CIVILWARS','FACTION_DEFECTED',{s.houses[hid].name,s.houses[target.house].name},hid)
 K.Notify(s.pid,'FACTION_DEFECTED',s.houses[hid].name,s.houses[target.house].name)
end
function K.BeginCivilWar(s,claims)
 if s.war then return end
 claims=claims or K.Claims(s);if #claims<2 then return end
 s.civilWars=(s.civilWars or 0)+1
 local n=#claims>=8 and 3 or 2
 local w={number=s.civilWars,start=K.Now(),deadline=K.Now()+K.Scale(20),nextEvent=K.Now()+K.Scale(3),
  factions={},supported=nil,actionNext=0,rebelsSpawned=0,events={}}
 s.war=w
 for i=1,n do
  local h=s.houses[claims[i].house];local c=K.Character(s,h.id,'claimant')
  w.factions[i]={id=i,house=h.id,claimant=c.id,members={h.id},strength=40+h.claim*.2+h.power}
 end
 for _,h in ipairs(K.ActiveHouses(s)) do
  if not K.FactionFor(s,h.id) then
   local best,score
   for _,f in ipairs(w.factions) do
    local relation=h.relations[f.house] or 0
    local value=relation*.8+s.houses[f.house].prestige*.1+K.Rand(s,16)
    if f.house==s.previousHouse then value=value+h.loyalty*.3+K.TraitSum(h,'dynasty') end
    if K.HasTrait(h,'Opportunistic') then value=value+f.strength*.15 end
    if not score or value>score then best,score=f,value end
   end
   best.members[#best.members+1]=h.id;best.strength=best.strength+h.power
  end
  h.stats.wars=h.stats.wars+1
 end
 K.History(s,'CIVILWARS','CIVIL_WAR_BEGAN',{w.number,n});K.Notify(s.pid,'CIVIL_WAR_BEGAN',w.number,n)
 K.Log('CIVILWAR','Started war '..w.number);K.RefreshRealm(s)
end
local function rebel(s,k)
 local w=s.war;if w.rebelsSpawned>=4 then return false end
 local era=Players[s.pid]:GetCurrentEra()
 local types={'UNIT_WARRIOR','UNIT_SPEARMAN','UNIT_LONGSWORDSMAN','UNIT_MUSKETMAN','UNIT_RIFLEMAN','UNIT_GREAT_WAR_INFANTRY','UNIT_INFANTRY','UNIT_MECHANIZED_INFANTRY'}
 local unit=K.ID(types[math.min(8,era+1)]) or K.ID('UNIT_WARRIOR')
 local barb=Players[GameDefines.BARBARIAN_PLAYER or 63];if not barb or not barb:IsAlive() then return false end
 local plots={}
 K.NearPlots(k.x,k.y,2,function(plot)
  if plot:GetOwner()==s.pid and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable() and not plot:IsCity() and plot:GetNumUnits()==0 then plots[#plots+1]=plot end
 end)
 if #plots==0 then return false end
 local plot=K.Pick(s,plots)
 local u=barb:InitUnit(unit,plot:GetX(),plot:GetY(),UnitAITypes.UNITAI_ATTACK)
 if not u then return false end
 w.rebelsSpawned=w.rebelsSpawned+1;k.riotUntil=K.Now()+K.Scale(4)
 K.History(s,'CIVILWARS','RIOT',{k.name},nil,k.id);K.Notify(s.pid,'RIOT',k.name);return true
end
K.CivilEvents={
 function(s,a,b)
  a.strength=a.strength+12;b.strength=math.max(1,b.strength-6)
  return 'WAR_BATTLE',{s.houses[a.house].name,s.houses[b.house].name}
 end,
 function(s,a,b)
  local candidates={};for _,id in ipairs(b.members) do if id~=b.house then candidates[#candidates+1]=id end end
  if #candidates>0 then K.MoveFaction(s,K.Pick(s,candidates),a) end
  return 'WAR_INTRIGUE',{s.houses[a.house].name}
 end,
 function(s,a)
  local lost=math.min(Players[s.pid]:GetGold(),K.Scale(30+Players[s.pid]:GetCurrentEra()*10));Players[s.pid]:ChangeGold(-lost)
  a.strength=a.strength+8;return 'WAR_TREASURY',{lost,s.houses[a.house].name}
 end,
 function(s,a)
  local kingdoms=K.ActiveKingdoms(s);local k=K.Pick(s,kingdoms)
  for _,id in ipairs(k.houses) do K.MoveFaction(s,id,a) end
  a.strength=a.strength+10;return 'WAR_KINGDOM',{k.name,s.houses[a.house].name}
 end,
 function(s,a)
  local unstable={};for _,k in ipairs(K.ActiveKingdoms(s)) do if k.stability<40 then unstable[#unstable+1]=k end end
  if #unstable>0 then rebel(s,K.Pick(s,unstable)) end
  a.strength=a.strength+5;return 'WAR_UNREST',{s.houses[a.house].name}
 end
}
function K.EndCivilWar(s,winner)
 local w=s.war;if not w then return end
 for _,f in ipairs(w.factions) do
  for _,id in ipairs(f.members) do
   local h=s.houses[id]
   if f.id==winner.id then h.prestige=h.prestige+12;h.influence=h.influence+4;K.Loyalty(h,25)
   else h.prestige=math.max(0,h.prestige-8);K.Loyalty(h,-8);h.claimBonus=h.claimBonus+3 end
  end
  if f.id~=winner.id then local c=s.characters[f.claimant];c.role='former claimant';c.defeated=K.Now() end
 end
 w.ended=K.Now();w.winner=winner.house;s.warHistory=s.warHistory or {};s.warHistory[#s.warHistory+1]=w
 s.war=nil
 for _,k in pairs(s.kingdoms) do k.riotUntil=0 end
 for _,g in pairs(s.guards) do g.oathPending=nil end
 K.Crown(s,winner.house,winner.claimant,true)
 K.History(s,'CIVILWARS','CIVIL_WAR_ENDED',{w.number,s.houses[winner.house].name,K.Now()-w.start})
 K.Notify(s.pid,'CIVIL_WAR_ENDED',w.number,s.houses[winner.house].name,K.Now()-w.start)
 -- Cleanup runs for every known city and every owned combat unit immediately.
 K.RefreshRealm(s);K.Log('CIVILWAR','Resolved '..w.number)
end
function K.CivilWarTick(s)
 local w=s.war;if not w then return end
 if K.KingdomCount(s)==0 then s.war=nil;K.ApplyEffects(s);return end
 if K.Now()>=w.nextEvent then
  local a=K.Pick(s,w.factions);local b=a;while b.id==a.id do b=K.Pick(s,w.factions) end
  local key,args=K.Pick(s,K.CivilEvents)(s,a,b)
  local entry=K.History(s,'CIVILWARS',key,args);w.events[#w.events+1]=entry.id
  K.Notify(s.pid,key,unpack(args));w.nextEvent=K.Now()+K.Scale(3+K.Rand(s,3))
 end
 local leading
 for _,f in ipairs(K.Factions(s)) do if not leading or f.strength>leading.strength then leading=f end end
 if K.Now()>=w.deadline or K.Now()-w.start>=K.Scale(5) and leading.percent>=70 then K.EndCivilWar(s,leading) end
end
K.WarActions={FUND={gold=100,strength=15},MILITARY={gold=50,strength=25,production=true},
 DENOUNCE={gold=40,strength=8,hostility=8},CONCESSION={gold=80,strength=12,concession=true},
 TREASURY={gold=200,strength=20,loyalty=8},ALLIANCE={gold=90,strength=10,alliance=true},NEUTRAL={gold=0,strength=0}}
function K.CanSupport(pid,fid,action)
 if not K.IsKingdoms(pid) then return false,K.Text('UNAVAILABLE') end
 local s=K.State(pid);local w=s.war;local a=K.WarActions[action]
 if not w or not a or action~='NEUTRAL' and not w.factions[fid] then return false,K.Text('UNAVAILABLE') end
 if K.Now()<w.actionNext then return false,K.Text('COOLDOWN',w.actionNext-K.Now()) end
 local cost=a.gold==0 and 0 or K.Scale(a.gold*(1+Players[pid]:GetCurrentEra()*.2))
 if Players[pid]:GetGold()<cost then return false,K.Text('NEED_GOLD',cost) end
 if a.production and Players[pid]:GetNumMilitaryUnits()<2 then return false,K.Text('NEED_ARMY') end
 return true,K.Text(action=='NEUTRAL' and 'WAR_ACTION_HELP_NEUTRAL' or 'WAR_ACTION_HELP',cost,a.strength),cost
end
function K.Support(pid,fid,action)
 local ok,reason,cost=K.CanSupport(pid,fid,action);if not ok then return false,reason end
 local s=K.State(pid);local w=s.war;local f=w.factions[fid];local a=K.WarActions[action]
 Players[pid]:ChangeGold(-cost);w.actionNext=K.Now()+K.Scale(4)
 if action=='NEUTRAL' then
  w.supported=nil
  K.History(s,'CIVILWARS','WAR_NEUTRAL',{})
 else
  w.supported=fid;f.strength=f.strength+a.strength
  for _,other in ipairs(w.factions) do for _,id in ipairs(other.members) do K.Loyalty(s.houses[id],other.id==fid and (a.loyalty or 4) or -(a.hostility or 4)) end end
  if a.production then s.suppliesUntil=K.Now()+K.Scale(5) end
  if a.concession then for _,id in ipairs(f.members) do local h=s.houses[id];h.influence=h.influence+2;s.kingdoms[h.kingdom].estatesUntil=K.Now()+K.Scale(8) end end
  if a.alliance then for _,id in ipairs(f.members) do K.Relation(s,id,f.house,15) end end
  K.History(s,'CIVILWARS','WAR_SUPPORTED',{s.houses[f.house].name,K.Text('WAR_ACTION_'..action)})
 end
 -- Withdrawing or changing backing also withdraws obsolete opposition prompts.
 for _,g in pairs(s.guards) do if not K.GuardOpposes(s,g) then g.oathPending=nil end end
 K.Factions(s);K.RefreshRealm(s);K.Commit(pid);return true,K.Text('ACTION_DONE')
end
