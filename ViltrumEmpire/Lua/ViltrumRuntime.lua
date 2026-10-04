-- Viltrum gameplay lives here, independently of popup rendering. SP only.
MapModData.ViltrumEmpire = MapModData.ViltrumEmpire or {}
local V = MapModData.ViltrumEmpire
if V.Initialized then return end
V.Initialized = true
local DEBUG = false
local save = Modding.OpenSaveData()
local function log(s) if DEBUG then print('[VILTRUM] ' .. s) end end
local function id(s) return GameInfoTypes[s] end
local CIV, WARRIOR, COMPLEX = id('CIVILIZATION_VILTRUM'), id('UNIT_VILTRUM_WARRIOR'), id('BUILDING_VILTRUM_COMPLEX')
local RP, MEDIEVAL = id('TECH_REPLACEABLE_PARTS'), id('ERA_MEDIEVAL')
local P, D, POL = {}, {}, {}
for _, n in ipairs({'BLOODLINE','FLIGHT','EXECUTION','PLANETBREAKER','EXECUTION_ACTIVE','PLANET_ACTIVE',
 'MOMENTUM','CONDITIONING','CONDITION_ACTIVE','HARDENED','PUREBLOOD','PURE_ACTIVE','GENOME','WARNING','QUARANTINE','NO_HEAL'}) do
 P[n] = id('PROMOTION_VILTRUM_' .. n)
end
for _, n in ipairs({'GARRISON','MOMENTUM','PURGE','QUARANTINE','DYING','RECOVERY','HAPPY'}) do D[n]=id('BUILDING_VILTRUM_'..n) end
for _, n in ipairs({'PURGE_GROWTH','QUARANTINE','DYING','RECOVERY_A','RECOVERY_B','ILLUSION'}) do POL[n]=id('POLICY_VILTRUM_'..n) end
local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
local scale = (speed and speed.TrainPercent or 100) / 100
local function turns(n) return math.max(1, math.floor(n*scale+0.5)) end
local function now() return Game.GetGameTurn() end
local function key(pid,n) return 'VILTRUM:v1:'..pid..':'..n end
local function get(pid,n,default) local a=save.GetValue(key(pid,n)); if a==nil then return default or 0 end; return a end
local function set(pid,n,v) save.SetValue(key(pid,n),v) end
local function remaining(pid,n) return math.max(0,get(pid,n)-now()) end
local function active(pid,n) return remaining(pid,n)>0 end
local function isViltrum(pid) local p=Players[pid]; return p and p:GetCivilizationType()==CIV end
local function military(u) return u and u:IsCombatUnit() end
local function land(u) return military(u) and u:GetDomainType()==DomainTypes.DOMAIN_LAND end
local function unit(pid,uid) return Players[pid] and Players[pid]:GetUnitByID(uid) end
local function promotion(u,n,b) if u and P[n] then u:SetHasPromotion(P[n],b and true or false) end end
local function has(u,n) return u and P[n] and u:IsHasPromotion(P[n]) end
local function maxHP(u) return u.GetMaxHitPoints and u:GetMaxHitPoints() or 100 end
local function alive(u) return u and u:GetDamage()<maxHP(u) and not u:IsDelayedDeath() end
local function heal(u,hp) if alive(u) then u:SetDamage(math.max(0,u:GetDamage()-hp)) end end
local function cityKey(c) return c:GetX()..':'..c:GetY()..':'..c:GetGameTurnFounded()..':'..c:GetOriginalOwner() end
local function notify(pid,title,body)
 local p=Players[pid]
 if p and p:IsHuman() then p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,body,title) end
 log(title..': '..body)
end
local function changed() if LuaEvents.ViltrumChanged then LuaEvents.ViltrumChanged() end end
local function friendly(u)
 local plot=u:GetPlot()
 if not plot then return false end
 if plot.IsFriendlyTerritory then return plot:IsFriendlyTerritory(u:GetOwner()) end
 return plot:GetTeam()==Players[u:GetOwner()]:GetTeam()
end
local function syncPeaceLocks()
 -- CP v151 retains old peace-event declarations without reliable dispatch.
 -- A temporary native flag is consulted by canChangeWarPeace (voluntary deals),
 -- while forced makePeace calls bypass it. Only flags we introduced are removed.
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do
  if isViltrum(pid) then
   local p=Players[pid];local teamID=p:GetTeam();local team=Teams[teamID]
   for other=0,(GameDefines.MAX_CIV_TEAMS or 64)-1 do
    local opposing=Teams[other]
    if opposing and other~=teamID and team.SetPermanentWarPeace then
     local k='warLock:'..teamID..':'..other
     local needed=false
     for mate=0,GameDefines.MAX_MAJOR_CIVS-1 do
      if isViltrum(mate) and Players[mate]:IsAlive() and Players[mate]:GetTeam()==teamID and active(mate,'noPeace') then needed=true end
     end
     needed=needed and team:IsAtWar(other)
     if get('world',k)==1 then
      if not needed then team:SetPermanentWarPeace(other,false);set('world',k,0) end
     elseif needed and not team:IsPermanentWarPeace(other) and not opposing:IsPermanentWarPeace(teamID) then
      set('world',k,1);team:SetPermanentWarPeace(other,true)
     end
    end
   end
  end
 end
end
local function refreshUnit(pid,u)
 if not military(u) then return end
 promotion(u,'MOMENTUM',active(pid,'momentum') and not active(pid,'quarantine'))
 promotion(u,'WARNING',has(u,'BLOODLINE') and get(pid,'outbreak')==0 and get(pid,'countdown',-1)>=0)
 promotion(u,'QUARANTINE',active(pid,'quarantine'))
 promotion(u,'NO_HEAL',land(u) and active(pid,'dying') and not friendly(u))
 promotion(u,'CONDITION_ACTIVE',has(u,'CONDITIONING') and not friendly(u))
 promotion(u,'PURE_ACTIVE',has(u,'PUREBLOOD') and maxHP(u)-u:GetDamage()<50)
 -- Temporary target promotions never persist after combat, including reload.
 promotion(u,'EXECUTION_ACTIVE',false); promotion(u,'PLANET_ACTIVE',false)
end
local function policy(p,n,b)
 local i=POL[n]
 if i and p:HasPolicy(i)~=(b and true or false) then p:SetHasPolicy(i,b and true or false) end
end
local function refresh(pid)
 if not isViltrum(pid) then return end
 local p=Players[pid]
 syncPeaceLocks()
 policy(p,'PURGE_GROWTH',active(pid,'purgeGrowth'))
 policy(p,'QUARANTINE',active(pid,'quarantine'))
 policy(p,'DYING',active(pid,'dying'))
 policy(p,'RECOVERY_A',get(pid,'scourgeChoice')==1 and active(pid,'recovery'))
 policy(p,'RECOVERY_B',get(pid,'scourgeChoice')==2 and active(pid,'recovery'))
 policy(p,'ILLUSION',active(pid,'illusion'))
 for c in p:Cities() do
  local g=c:GetGarrisonedUnit()
  local states={GARRISON=military(g),MOMENTUM=active(pid,'momentum') and not active(pid,'quarantine'),
   PURGE=get(pid,'purgeChoice')==1,QUARANTINE=active(pid,'quarantine'),DYING=active(pid,'dying'),
   RECOVERY=get(pid,'scourgeChoice')==1 and active(pid,'recovery'),HAPPY=active(pid,'purgeHappy')}
  for n,b in pairs(states) do c:SetNumRealBuilding(D[n],b and 1 or 0) end
 end
 for u in p:Units() do refreshUnit(pid,u) end
 changed()
end
local function momentum(pid,duration)
 if active(pid,'quarantine') then return end
 local r=remaining(pid,'momentum')
 local n=duration or (r>0 and r+turns(3) or turns(8))
 n=math.min(n,turns(18));set(pid,'momentum',now()+n)
 if r==0 then notify(pid,'Imperial Momentum',n..' turns: +15% military Production, +3 trained military XP, +5% city attack.') end
 log('Imperial Momentum activated: '..n..' turns')
end
local function startCountdown(pid)
 if get(pid,'outbreak')==1 or get(pid,'countdown',-1)>=0 then return end
 set(pid,'countdown',now());set(pid,'warnStart',1)
 notify(pid,'AN IMPOSSIBLE ILLNESS',
  'Reports have arrived from the outer colonies. Viltrumites are collapsing from an unknown pathogen. Their strength is fading, their flight is failing, and injuries once considered trivial are proving fatal.[NEWLINE][NEWLINE]Imperial physicians insist the outbreak is contained.[NEWLINE][NEWLINE]They are lying.[NEWLINE][NEWLINE]'..turns(8)..' turns until the Scourge. Bloodline field healing slows by approximately 25%.')
 refresh(pid)
end
local function research(pid)
 if Teams[Players[pid]:GetTeam()]:IsHasTech(RP) and get(pid,'research',-1)<0 then
  set(pid,'research',now());log('Replaceable Parts researched on turn '..now())
 end
end
local function created(pid,uid)
 if not isViltrum(pid) then return end
 local u=unit(pid,uid);if not u then return end
 if u:GetUnitType()==WARRIOR then
  log('First Viltrumite created');research(pid)
  if get(pid,'research',-1)>=0 then startCountdown(pid) end
 end
 refreshUnit(pid,u)
end
local function trained(pid,cid,uid)
 if not isViltrum(pid) then return end
 local p=Players[pid];local c=p:GetCityByID(cid);local u=unit(pid,uid)
 if not c or not military(u) then return end
 -- Native CityTrained fires exactly once for each production/purchase completion.
 if active(pid,'momentum') and not active(pid,'quarantine') then u:ChangeExperience(3) end
 if land(u) then
  if get(pid,'purgeChoice')==1 then u:ChangeExperience(3) end
  if c:IsHasBuilding(COMPLEX) then promotion(u,'CONDITIONING',true) end
 end
 if u:GetUnitType()==WARRIOR and get(pid,'scourgeChoice')>0 then promotion(u,'GENOME',true) end
 created(pid,uid)
end
local function constructed(pid,cid,bid)
 if not isViltrum(pid) or bid~=COMPLEX then return end
 local c=Players[pid]:GetCityByID(cid);if not c then return end
 local k='complex:'..cityKey(c)
 -- Shared by all owners to make reward once per original city even after trades.
 if get('world',k)==0 then set('world',k,1);c:ChangePopulation(1,true) end
end
local battles={}
local function member(m)
 if not m then return nil end
 if m.city then return Players[m.pid] and Players[m.pid]:GetCityByID(m.uid) end
 return unit(m.pid,m.uid)
end
local function battleStarted(kind,x,y) battles[#battles+1]={kind=kind,x=x,y=y} end
local function battleJoined(pid,uid,role,isCity)
 local b=battles[#battles];if not b or (role~=0 and role~=1) then return end
 local m={pid=pid,uid=uid,city=isCity==true or isCity==1}
 if role==0 then b.a=m else b.d=m end
 if not b.a or not b.d or b.prepared then return end
 b.prepared=true
 local a,d=member(b.a),member(b.d);if not a or not d then return end
 if not b.a.city then b.a.military=military(a) end
 if not b.d.city then b.d.military=military(d) end
 if b.d.city then b.capital=d:IsOriginalCapital() end
 for _,side in ipairs({b.a,b.d}) do
  local u=not side.city and member(side)
  if u and isViltrum(side.pid) then
   refreshUnit(side.pid,u)
   local other=side==b.a and b.d or b.a;local target=member(other)
   promotion(u,'EXECUTION_ACTIVE',has(u,'EXECUTION') and not other.city and military(target) and maxHP(target)-target:GetDamage()<50)
   promotion(u,'PLANET_ACTIVE',side==b.a and has(u,'PLANETBREAKER') and other.city and target:GetDamage()>target:GetMaxHitPoints()/2)
  end
 end
end
local function battleFinished()
 local b=table.remove(battles);if not b or not b.prepared then return end
 for _,m in ipairs({b.a,b.d}) do
  if not m.city then
   local u=unit(m.pid,m.uid)
   if alive(u) and isViltrum(m.pid) then
    local enemy=m==b.a and b.d or b.a;local target=member(enemy)
    if (b.kind==0 or b.kind==1) and land(u) and enemy.military and not Players[enemy.pid]:IsBarbarian() and not alive(target) then
     if not active(m.pid,'quarantine') then heal(u,active(m.pid,'dying') and 10 or 15) end
    end
    refreshUnit(m.pid,u)
   end
  end
 end
end
local function captured(old,capital,x,y,new,pop,conquest)
 -- Never award for purchases, trades or liberation callbacks.
 local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
 if not c then return end
 -- Remove Viltrum state immediately when captured by any other civilization.
 if not isViltrum(new) then for _,bid in pairs(D) do c:SetNumRealBuilding(bid,0) end;return end
 if not (conquest==true or conquest==1) or old==new then refresh(new);return end
 local b=battles[#battles]
 if b and b.x==x and b.y==y and b.a and b.a.pid==new and not b.a.city then
  local u=member(b.a)
  if has(u,'PUREBLOOD') and b.capital then heal(u,maxHP(u))
  elseif has(u,'PLANETBREAKER') then heal(u,35) end
 end
 local k='capture:'..cityKey(c)
 if c:GetOriginalOwner()==new or get(new,k)==1 then
  log('Captured city already rewarded, ignoring');refresh(new);return
 end
 set(new,k,1) -- consumed even during quarantine, so later recapture cannot farm.
 if not active(new,'quarantine') then
  local cap=Players[new]:GetCapitalCity();if cap then cap:ChangePopulation(1,true) end
  local r=c:GetResistanceTurns();if r>0 then c:ChangeResistanceTurns(-math.ceil(r*0.20)) end
  momentum(new)
  if active(new,'dying') then set(new,'dying',math.max(now(),get(new,'dying')-1)) end
 end
 refresh(new)
end
local function choosePurge(pid,choice)
 local p=Players[pid];set(pid,'purgeChoice',choice)
 if choice==1 then
  for c in p:Cities() do c:SetPopulation(math.max(1,c:GetPopulation()-1),true) end
  for u in p:Units() do if military(u) then u:ChangeExperience(10) end end
  set(pid,'purgeGeneral',now()+turns(20))
  -- The choice turn counts as the first of the twenty active turns.
  p:ChangeCombatExperience(1)
 else
  set(pid,'purgeGrowth',now()+turns(20));set(pid,'purgeHappy',now()+turns(10))
  p:ChangeJONSCulture(math.floor(75*(speed.CulturePercent or 100)/100*(1+0.15*p:GetCurrentEra())+0.5))
 end
end
local function cancelTrade(p)
 -- RecallTrader(true) resolves the active route by owner/unit ID inside CP.
 -- Take an ID snapshot because ending a route can replace its visualization unit.
 local traders={}
 for u in p:Units() do local row=GameInfo.Units[u:GetUnitType()]
  if row and row.Trade and row.Trade~=0 then traders[#traders+1]=u:GetID() end
 end
 for _,uid in ipairs(traders) do local u=p:GetUnitByID(uid)
  if u and u.RecallTrader then u:RecallTrader(true) else log('RecallTrader unavailable in this DLL') end
 end
end
local function chooseScourge(pid,choice)
 local p=Players[pid];set(pid,'scourgeChoice',choice);set(pid,'outbreakTurn',now())
 local fraction=choice==1 and 0.25 or 0.15
 for c in p:Cities() do
  local floor=c:IsCapital() and 2 or 1
  local protected=c:IsHasBuilding(COMPLEX) and 1 or 0
  local population=math.max(floor,math.floor(c:GetPopulation()*fraction))+protected
  c:SetPopulation(math.min(c:GetPopulation(),population),true)
 end
 local blood={}
 for u in p:Units() do
  if alive(u) and has(u,'BLOODLINE') and military(u) and not has(u,'HARDENED') and not has(u,'PUREBLOOD') then blood[#blood+1]=u:GetID() end
 end
 table.sort(blood)
 -- Synchronized Fisher-Yates, sorted input. Promotions persist identities through
 -- upgrades and saves; no reusable unit-ID survivor records are needed.
 for i=#blood,2,-1 do local j=Game.Rand(i,'Viltrum Scourge casualties')+1;blood[i],blood[j]=blood[j],blood[i] end
 local floor=choice==1 and math.min(2,#blood) or math.min(1,#blood)
 local survive=math.max(floor,#blood-math.floor(#blood*(choice==1 and 0.8 or 0.9)+0.5))
 log('Total Bloodline units: '..#blood..'; Scourge casualties: '..(#blood-survive)..'; Scourge survivors: '..survive)
 for i,uid in ipairs(blood) do
  local u=unit(pid,uid)
  if u then
   if i<=survive then
    promotion(u,choice==1 and 'HARDENED' or 'PUREBLOOD',true)
    if choice==2 then u:SetHasPromotion(id('PROMOTION_BLITZ'),true) end
    u:SetDamage(math.max(0,maxHP(u)-(choice==1 and 25 or 10)))
    log((choice==1 and 'Scourge-Hardened' or 'Last Pureblood')..' granted to unit '..uid)
   else u:Kill(false,-1) end
  end
 end
 if choice==1 then
  set(pid,'quarantine',now()+turns(20));set(pid,'momentum',0);cancelTrade(p)
 else
  set(pid,'dying',now()+turns(25));set(pid,'noPeace',now()+turns(10))
  if p:GetGoldenAgeTurns()>0 then p:ChangeGoldenAgeTurns(-p:GetGoldenAgeTurns()) end
 end
 set(pid,'recovered',0);set(pid,'extinctionDue',now()+turns(3))
 notify(pid,'The Scourge Virus',#blood-survive..' Viltrumites died. '..survive..' original survivors remain. The crisis has begun.')
end
local function goldCost(p) return math.max(math.floor(500*scale+0.5),math.ceil(math.max(0,p:CalculateGoldRate())*2)) end
local function rebels(pid)
 local p=Players[pid];local target=nil;local defense=nil
 for c in p:Cities() do
  if c:GetOriginalOwner()~=pid and (not defense or c:GetStrengthValue()<defense) then target,defense=c,c:GetStrengthValue() end
 end
 if not target then log('No occupied city: rebels skipped');return end
 local barb=Players[GameDefines.BARBARIAN_PLAYER or 63]
 local typ=nil
 -- Deterministic era-appropriate default unit. No biological rebel Warriors.
 for _,n in ipairs({'UNIT_INFANTRY','UNIT_RIFLEMAN','UNIT_MUSKETMAN','UNIT_LONGSWORDSMAN','UNIT_SWORDSMAN','UNIT_WARRIOR'}) do
  local row=GameInfo.Units[id(n)]
  if row and (not row.PrereqTech or Teams[p:GetTeam()]:IsHasTech(id(row.PrereqTech))) then typ=row.ID;break end
 end
 if not barb or not typ then return end
 local count=0
 for plotID=0,Map.GetNumPlots()-1 do
  local plot=Map.GetPlotByIndex(plotID)
  local distance=Map.PlotDistance(target:GetX(),target:GetY(),plot:GetX(),plot:GetY())
  if distance>=1 and distance<=3 and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable()
   and not plot:IsCity() and plot:GetNumUnits()==0 and (plot:GetOwner()==pid or plot:GetOwner()==-1) then
   barb:InitUnit(typ,plot:GetX(),plot:GetY(),UnitAITypes.UNITAI_ATTACK);count=count+1
   if count==2 then break end
  end
 end
 log('Rebels spawned: '..count)
end
local function chooseExtinction(pid,choice)
 local p=Players[pid];set(pid,'extinctionChoice',choice)
 if choice==1 then
  p:ChangeGold(-goldCost(p));set(pid,'illusion',now()+turns(20))
 else
  local cap=p:GetCapitalCity()
  if cap then p:InitUnit(id('UNIT_GREAT_GENERAL'),cap:GetX(),cap:GetY(),UnitAITypes.UNITAI_GENERAL) end
  for u in p:Units() do if has(u,'HARDENED') or has(u,'PUREBLOOD') then u:ChangeExperience(10) end end
  momentum(pid,math.max(remaining(pid,'momentum'),turns(5)));rebels(pid)
  notify(pid,'Fear Requires a Demonstration','The surviving warriors demonstrate their strength. Subject-world rebels gather. Custom diplomatic penalties are unavailable in this implementation.')
 end
end
local function choose(pid,event,choice)
 if not isViltrum(pid) or get(pid,'pending')~=event or (choice~=1 and choice~=2) then return false end
 if event==3 and choice==1 and Players[pid]:GetGold()<goldCost(Players[pid]) then return false end
 set(pid,'pending',0) -- clear before effect callbacks/reentrant UnitCreated.
 if event==1 then choosePurge(pid,choice) elseif event==2 then chooseScourge(pid,choice) else chooseExtinction(pid,choice) end
 refresh(pid);return true
end
local function aiPurge(p)
 local small,total,combat=0,0,0
 for c in p:Cities() do total=total+1;if c:GetPopulation()<=3 then small=small+1 end end
 for u in p:Units() do if military(u) then combat=combat+1 end end
 local losing=false
 for other=0,GameDefines.MAX_MAJOR_CIVS-1 do
  local o=Players[other]
  if o and o:IsAlive() and Teams[p:GetTeam()]:IsAtWar(o:GetTeam()) then
   if (p.GetWarScore and p:GetWarScore(other)<-30) or o:GetMilitaryMight()>p:GetMilitaryMight()*1.5 then losing=true end
  end
 end
 return (p:GetExcessHappiness()<0 or small>total/2 or combat<4 or losing) and 2 or 1
end
local function prompt(pid,event)
 set(pid,'pending',event)
 local p=Players[pid]
 if not p:IsHuman() or (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer()) then
  local choice=1
  if event==1 then choice=aiPurge(p)
  elseif event==2 then choice=(p:GetExcessHappiness()>=0 and p:GetNumMilitaryUnits()>=8 and p:GetMilitaryMight()>100) and 2 or 1
  elseif event==3 then choice=p:GetGold()>=goldCost(p) and 1 or 2 end
  choose(pid,event,choice)
 else
  notify(pid,'Imperial decision required','Open the Viltrum imperial status panel to choose the fate of the Empire.')
  changed()
 end
end
local function advance(pid)
 syncPeaceLocks()
 if not isViltrum(pid) then return end
 local p=Players[pid];if not p:IsAlive() then return end
 -- Repeated callbacks/reload on the same game turn cannot duplicate GG progress.
 if get(pid,'lastTurn',-1)==now() then refresh(pid);return end
 set(pid,'lastTurn',now());research(pid)
 if get(pid,'scourgeChoice')>0 and get(pid,'recovered')==0 and not active(pid,'quarantine') and not active(pid,'dying') then
  set(pid,'recovered',1);set(pid,'recovery',now()+turns(get(pid,'scourgeChoice')==1 and 20 or 15))
  notify(pid,'Repopulation Program','The crisis has ended. Recovery lasts '..remaining(pid,'recovery')..' turns.')
 end
 if active(pid,'purgeGeneral') then p:ChangeCombatExperience(1) end
 if get(pid,'pending')==0 then
  local start=get(pid,'countdown',-1)
  if get(pid,'outbreak')==0 and start>=0 and now()>=start+turns(8) then
   set(pid,'outbreak',1);log('Scourge outbreak triggered');prompt(pid,2)
  elseif get(pid,'extinctionDue')>0 and now()>=get(pid,'extinctionDue') and get(pid,'extinctionChoice')==0 then prompt(pid,3)
  elseif get(pid,'purgeTriggered')==0 and p:GetCurrentEra()>=MEDIEVAL and p:GetNumCities()>=2 and p:GetTotalPopulation()>=15 and p:GetCapitalCity() and p:GetCapitalCity():GetResistanceTurns()==0 then
   set(pid,'purgeTriggered',1);log('Great Purge triggered');prompt(pid,1)
  end
 end
 if get(pid,'outbreak')==0 then
  if get(pid,'research',-1)>=0 and get(pid,'countdown',-1)<0 then
   local found=false
   for u in p:Units() do if u:GetUnitType()==WARRIOR then found=true;break end end
   if found or now()>=get(pid,'research')+turns(12) then startCountdown(pid) end
  end
  local start=get(pid,'countdown',-1)
  if start>=0 then
   local left=math.max(0,start+turns(8)-now())
   if left<=turns(3) and left>1 and get(pid,'warnThree')==0 then set(pid,'warnThree',1);notify(pid,'The colonies fall silent',left..' turns until the Scourge.') end
   if left==1 and get(pid,'warnOne')==0 then set(pid,'warnOne',1);notify(pid,'The last healthy dawn','The Scourge strikes next turn.') end
  end
 end
 log('Quarantine remaining: '..remaining(pid,'quarantine'));refresh(pid)
end
local function peace(pid,against)
 if active(pid,'noPeace') then return false end
 -- Also reject peace initiated by a counterpart against a crusading Viltrum team.
 for other=0,GameDefines.MAX_MAJOR_CIVS-1 do
  if isViltrum(other) and Players[other]:GetTeam()==against and active(other,'noPeace') then return false end
 end
 return true
end
local function canTrain(pid,cid,typ)
 if not isViltrum(pid) or not active(pid,'quarantine') then return true end
 local row=GameInfo.Units[typ]
 return not row or (not row.Found or row.Found==0) and (not row.Trade or row.Trade==0)
end
local function moved(pid,uid)
 if not isViltrum(pid) then return end
 local u=unit(pid,uid);if u then refreshUnit(pid,u) end
 for c in Players[pid]:Cities() do c:SetNumRealBuilding(D.GARRISON,military(c:GetGarrisonedUnit()) and 1 or 0) end
end
local function paradrop(pid,uid)
 if not isViltrum(pid) then return end
 local u=unit(pid,uid);if has(u,'FLIGHT') then u:SetMadeAttack(false) end
end
V.IsViltrum=isViltrum;V.Refresh=refresh;V.Choose=choose;V.Get=get;V.Remaining=remaining;V.Turns=turns
V.Advance=advance;V.Created=created;V.Trained=trained;V.Constructed=constructed;V.Captured=captured
V.BattleStarted=battleStarted;V.BattleJoined=battleJoined;V.BattleFinished=battleFinished
V.GoldCost=goldCost;V.CanTrain=canTrain;V.CanPeace=peace;V.Paradrop=paradrop
GameEvents.PlayerDoTurn.Add(advance)
GameEvents.UnitCreated.Add(created)
GameEvents.CityTrained.Add(trained)
GameEvents.CityConstructed.Add(constructed)
GameEvents.CityCaptureComplete.Add(captured)
GameEvents.BattleStarted.Add(battleStarted);GameEvents.BattleJoined.Add(battleJoined);GameEvents.BattleFinished.Add(battleFinished)
GameEvents.UnitSetXY.Add(moved)
GameEvents.CityCanTrain.Add(canTrain)
GameEvents.PlayerCanMakePeace.Add(peace)
GameEvents.DeclareWar.Add(syncPeaceLocks)
GameEvents.MakePeace.Add(function(pid,other)
 -- Only scripted/forced peace should reach this hook while locked. Clear our
 -- flags immediately; preserve every pre-existing scenario flag.
 local p=Players[pid];if not p then return end
 local teamID=p:GetTeam()
 for _,pair in ipairs({{teamID,other},{other,teamID}}) do
  local k='warLock:'..pair[1]..':'..pair[2]
  if get('world',k)==1 then Teams[pair[1]]:SetPermanentWarPeace(pair[2],false);set('world',k,0) end
 end
end)
GameEvents.ParadropAt.Add(paradrop)
GameEvents.UnitUpgraded.Add(function(pid,old,new) if isViltrum(pid) then created(pid,new) end end)
GameEvents.TeamTechResearched.Add(function(team,tech)
 if tech==RP then for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if isViltrum(pid) and Players[pid]:GetTeam()==team then research(pid) end end end
end)
-- Read-only state restoration: do not advance time or redo any event on loading.
for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if isViltrum(pid) then refresh(pid) end end
