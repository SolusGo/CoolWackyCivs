local I=MapModData.TheShatteredEmpire
function I.RebelCount(s)
 local n=0;local barb=Players[GameDefines.BARBARIAN_PLAYER or 63]
 for _,f in pairs(s.factions) do if f.active then for uid,r in pairs(f.units) do
  local u=barb and barb:GetUnitByID(uid)
  if u and u:GetGameTurnCreated()==r.birth and (not r.name or u:GetNameNoDesc()==r.name) then n=n+1 else f.units[uid]=nil end
 end end end;return n
end
function I.RebelType(s)
 local team=Teams[Players[s.pid]:GetTeam()];local selected=I.ID('UNIT_WARRIOR')
 for _,name in ipairs({'UNIT_SPEARMAN','UNIT_SWORDSMAN','UNIT_LONGSWORDSMAN','UNIT_MUSKETMAN','UNIT_RIFLEMAN','UNIT_GREAT_WAR_INFANTRY','UNIT_INFANTRY','UNIT_MECHANIZED_INFANTRY'}) do
  local row=GameInfo.Units[I.ID(name)]
  if row and (not row.PrereqTech or team:IsHasTech(I.ID(row.PrereqTech))) then selected=row.ID end
 end
 return selected
end
function I.SpawnRebel(s,f,kind,x,y,defection)
 if not f or not f.active or (not defection and f.budget<=0) or I.RebelCount(s)>=24 then return end
 local barb=Players[GameDefines.BARBARIAN_PLAYER or 63];if not barb then return end
 local choices={}
 I.Near(x,y,3,function(plot)
  if not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable() and not plot:IsCity() and plot:GetNumUnits()==0 and (plot:GetOwner()==-1 or plot:GetOwner()==s.pid) then choices[#choices+1]=plot end
 end)
 table.sort(choices,function(a,b) local da=Map.PlotDistance(x,y,a:GetX(),a:GetY());local db=Map.PlotDistance(x,y,b:GetX(),b:GetY());if da~=db then return da<db end;if a:GetX()~=b:GetX() then return a:GetX()<b:GetX() end;return a:GetY()<b:GetY() end)
 local plot=choices[1];if not plot then return end
 local u=barb:InitUnit(kind,plot:GetX(),plot:GetY(),UnitAITypes.UNITAI_ATTACK)
 if not u then return end
 local name=I.Text('REBEL_UNIT',f.name)..' ['..f.id..':'..(f.spawned+1)..']'
 u:SetName(name);u:FinishMoves()
 f.units[u:GetID()]={birth=u:GetGameTurnCreated(),kind=kind,name=name};if not defection then f.budget=f.budget-1 end;f.spawned=f.spawned+1
 if s.war and f.war==s.war.id then s.war.troops=s.war.troops+1 end
 return u
end
function I.BeginRevolt(s,g)
 if g.faction or not g.active then return end
 local active=0;for _,f in pairs(s.factions) do if f.active then active=active+1 end end;if active>=6 then return end
 local c=I.City(g,s.pid);if not c then return end
 local strength=math.min(8,3+math.floor(c:GetPopulation()/5)+math.floor(g.prestige/35)+(c:IsHasBuilding(I.ID('BUILDING_BARRACKS')) and 1 or 0)+(s.reform=='MONARCHY' and 1 or 0)+(Players[s.pid]:GetHandicapType()>=5 and 1 or 0))
 local f={id=s.nextFaction,name=g.name,governor=g.id,origin=g.key,active=true,started=I.Now(),budget=strength,spawned=0,units={},nextReinforce=I.Now()+I.Scale(10),defections=0,defectionLimit=2}
 s.nextFaction=s.nextFaction+1;s.factions[f.id]=f;g.faction=f.id;g.stage=3;g.rebel=true;g.demand=nil
 I.Authority(s,-6);I.Reign(s).rebellions=I.Reign(s).rebellions+1
 I.History(s,'REBELLION',I.Text('HISTORY_REBEL',g.name,c:GetName()))
 I.Notify(s,I.Text('REVOLT_TITLE'),I.Text('REVOLT_NOTICE',g.name,c:GetName()),g)
 for _=1,math.min(3,strength) do I.SpawnRebel(s,f,I.RebelType(s),g.x,g.y) end
 I.Defections(s,g,f)
 I.DirtyCity(s,g.key)
end
function I.ClearFactionUnits(f)
 local barb=Players[GameDefines.BARBARIAN_PLAYER or 63]
 for _,uid in ipairs(I.Keys(f.units)) do local r=f.units[uid];local u=barb and barb:GetUnitByID(uid)
  if u and u:GetGameTurnCreated()==r.birth and (not r.name or u:GetNameNoDesc()==r.name) then u:Kill(false,-1) end
 end
 f.units={}
end
function I.ResolveFaction(s,f,result)
 if not f or not f.active then return end
 local g=s.governors[f.origin];I.ClearFactionUnits(f);f.active=false;f.ended=I.Now();f.result=result
 if g and g.id==f.governor then
  g.faction=nil;g.rebel=false;g.stage=0;g.critical=0;g.rebelNext=I.Now()+I.Scale(40);g.demandNext=I.Now()+I.Scale(20)
  if result=='SUPPRESSED' then g.loyalty=math.max(60,g.loyalty);g.ambition=math.max(0,g.ambition-15);I.Authority(s,s.reform=='MONARCHY' and 7 or 5)
  elseif result=='AUTONOMY' then g.autonomy=true;g.settlement=true;g.loyalty=math.max(70,g.loyalty);g.ambition=I.Clamp(g.ambition+20,0,100)
  elseif result=='CONCESSION' then g.loyalty=math.max(65,g.loyalty)
  elseif result=='RECONCILED' then g.loyalty=math.max(75,g.loyalty);g.relationship=I.Clamp(g.relationship+20,-100,100)
  elseif result=='EXHAUSTED' then g.autonomy=true;g.loyalty=55;I.Authority(s,-5) end
  I.DirtyCity(s,g.key)
 end
 if result~='LOST' and s.war and f.war==s.war.id then
  s.war.restored=s.war.restored+1
  if result~='EXHAUSTED' then s.war.victories=(s.war.victories or 0)+1 end
 end
 I.History(s,'REBELLION',I.Text('HISTORY_REBEL_END',f.name,I.Text('RESULT_'..result)))
end
function I.BeginCivilWar(s)
 if s.war or s.authority>=30 or I.Now()<s.nextWar then return end
 local provinces=I.Provinces(s);local claimant
 for _,g in ipairs(provinces) do if g.loyalty<25 and g.ambition>=60 and (not claimant or g.ambition+g.prestige>claimant.ambition+claimant.prestige) then claimant=g end end
 if not claimant then return end
 local supporters={}
 for _,g in ipairs(provinces) do
  if g.loyalty<25 and Map.PlotDistance(claimant.x,claimant.y,g.x,g.y)<=14 then supporters[#supporters+1]=g end
 end
 if #supporters<3 then return end
 local active,existing=0,0
 for _,f in pairs(s.factions) do if f.active then active=active+1 end end
 for _,g in ipairs(supporters) do if g.faction then existing=existing+1 end end
 if existing+math.min(#supporters-existing,math.max(0,6-active))<3 then return end
 local w={id=s.nextWarID,name=I.Text('WAR_NAME',#supporters),leader=claimant.name,claimant=claimant.id,start=I.Now(),provinces={},troops=0,defections=0,restored=0,authorityBefore=s.authority,authorityLost=0,authorityRecovered=0}
 s.nextWarID=s.nextWarID+1;s.war=w;s.nextWar=I.Now()+I.Scale(60);I.Authority(s,-10);s.collapseSeen=true;s.collapseResolved=false
 I.Reign(s).wars=I.Reign(s).wars+1
 for _,g in ipairs(supporters) do
  if not g.faction then I.BeginRevolt(s,g) end
  if g.faction then local f=s.factions[g.faction];f.war=w.id;w.provinces[#w.provinces+1]={key=g.key,name=g.cityName,governor=g.name};w.troops=w.troops+f.spawned;w.defections=w.defections+f.defections end
 end
 -- Nearby undecided governors join only when personally estranged or militarist.
 for _,g in ipairs(provinces) do if not g.faction and g.loyalty<45 and g.ambition>50 and (g.relationship<0 or g.archetype==claimant.archetype) and Map.PlotDistance(claimant.x,claimant.y,g.x,g.y)<=8 then
  I.BeginRevolt(s,g);if g.faction then local f=s.factions[g.faction];f.war=w.id;w.provinces[#w.provinces+1]={key=g.key,name=g.cityName,governor=g.name};w.troops=w.troops+f.spawned;w.defections=w.defections+f.defections end
 end end
 I.History(s,'CIVILWAR',I.Text('HISTORY_WAR',w.name,w.leader,#w.provinces));I.Notify(s,w.name,I.Text('WAR_NOTICE',w.leader,#w.provinces),claimant)
end
function I.RebellionTick(s)
 local barb=Players[GameDefines.BARBARIAN_PLAYER or 63]
 for _,fid in ipairs(I.Keys(s.factions)) do local f=s.factions[fid]
  if f.active then
   local g=s.governors[f.origin];local count=0
   for uid,r in pairs(f.units) do local u=barb and barb:GetUnitByID(uid)
    if u and u:GetGameTurnCreated()==r.birth and (not r.name or u:GetNameNoDesc()==r.name) then count=count+1 else f.units[uid]=nil end
   end
   if not g or g.id~=f.governor or not g.active then I.ResolveFaction(s,f,'LOST')
   elseif I.Now()>=f.started+I.Scale(100) then I.ResolveFaction(s,f,'EXHAUSTED')
   elseif count==0 and I.Now()>=f.started+I.Scale(5) then I.ResolveFaction(s,f,f.spawned>0 and 'SUPPRESSED' or 'EXHAUSTED')
   elseif I.Now()>=f.nextReinforce then
    f.nextReinforce=I.Now()+I.Scale(10);g.stage=4;I.DirtyCity(s,g.key)
    if count<4 then I.SpawnRebel(s,f,I.RebelType(s),g.x,g.y) end
   end
  end
 end
 I.BeginCivilWar(s)
 if s.war then
  local active=0;for _,f in pairs(s.factions) do if f.active and f.war==s.war.id then active=active+1 end end
  if active==0 then
   local w=s.war;w.finish=I.Now();w.result=w.restored>0 and 'RESTORED' or 'LOST'
   if w.restored>0 then
    if (w.victories or 0)>0 then I.Authority(s,10) end
    s.collapseResolved=true
   end
   s.wars[#s.wars+1]=w;if #s.wars>30 then table.remove(s.wars,1) end
   I.History(s,'CIVILWAR',I.Text('HISTORY_WAR_END',w.name,I.Text('RESULT_'..w.result)));s.war=nil;s.nextWar=I.Now()+I.Scale(50)
  end
 end
 local inactive={};for fid,f in pairs(s.factions) do if not f.active then inactive[#inactive+1]=fid end end;table.sort(inactive)
 for n=1,math.max(0,#inactive-30) do s.factions[inactive[n]]=nil end
end
