include('IconSupport')
include('InstanceManager')
include('ImperialCore')
local I=MapModData.TheShatteredEmpire
local tabs=InstanceManager:new('ImperialTabInstance','TabChoice',Controls.ImperialTabs)
local rows=InstanceManager:new('ImperialRowInstance','RowChoice',Controls.ImperialList)
local actions=InstanceManager:new('ImperialActionInstance','ActionChoice',Controls.ImperialActions)
local opened,cityView,leaderView,refreshing=false,false,false,false
local tab,selected,message='OVERVIEW',nil,''
local blocked={};local refresh
local function world() return not cityView and not leaderView and next(blocked)==nil and not (UI and UI.IsCityScreenUp and UI.IsCityScreenUp()) end
local function rounded(n) return tostring(math.floor(n+.5)) end
local function line(parts,text) parts[#parts+1]=text end
local function row(text,key)
 local item=rows:GetInstance();item.RowChoice:SetText(text)
 item.RowChoice:RegisterCallback(Mouse.eLClick,function() selected=key;message='';refresh() end)
end
local function action(s,label,kind,key,expected)
 local ok,reason=I.CanAction(s.pid,kind,key,expected)
 if not ok then return end
 local item=actions:GetInstance();item.ActionChoice:SetText(label);item.ActionChoice:SetToolTipString(I.Text(reason))
 item.ActionChoice:RegisterCallback(Mouse.eLClick,function()
  if world() and Game.GetActivePlayer()==s.pid then LuaEvents.ImperialRequest(s.pid,kind,key,expected);refresh() end
 end)
end
local function governors(s,parts,decisions)
 local provinces=I.Provinces(s)
 for _,g in ipairs(provinces) do row(g.cityName..'[NEWLINE]'..g.name..' - '..rounded(g.loyalty),g.key) end
 local g=s.governors[selected or (provinces[1] and provinces[1].key)];if not g or not g.active then return end
 line(parts,I.Text('GOVERNOR_DETAIL',g.cityName,g.name,I.Text(g.archetype),rounded(g.loyalty),rounded(g.ambition),rounded(g.prestige),I.Text('STAGE_'..g.stage)))
 line(parts,I.Text('GOVERNOR_DATES',g.id,g.appointed,rounded(g.relationship),g.autonomy and I.Text('YES') or I.Text('NO')))
 line(parts,I.Text('LOYALTY_CHANGE',g.delta or 0))
 for _,part in ipairs(g.reasons or {}) do line(parts,I.Text('REASON_'..part.reason)..': '..(part.value>0 and '+' or '')..part.value) end
 if g.demand then
  line(parts,I.Text('DEMAND_DETAIL',I.Text('DEMAND_'..g.demand.kind),g.demand.deadline,g.demand.cost))
  if g.demand.target then line(parts,I.Text('DEMAND_TARGET',g.demand.target)) end
  if g.demand.x then line(parts,I.Text('DEMAND_LOCATION',g.demand.x,g.demand.y)) end
 end
 if decisions then
  for _,kind in ipairs({'BRIBE','CHARTER','REPLACE','FUND','REFUSE','CONCESSION','RECONCILE'}) do
   local cost=kind=='FUND' and g.demand and g.demand.cost or I.GoldCost(s,g,kind=='CONCESSION' and 2 or 1)
   local label=I.Text('ACTION_'..kind)
   if kind=='BRIBE' or kind=='FUND' or kind=='CONCESSION' then label=label..' ('..cost..' [ICON_GOLD])' end
   action(s,label,kind,g.key,g.id)
  end
  line(parts,I.Text('DECISION_HELP'))
 end
 for _,e in ipairs(g.history) do line(parts,I.Text('TURN',e.turn)..' - '..e.text) end
end
local function overview(s,parts)
 local loyal,unrest,rebels=0,0,0
 for _,g in ipairs(I.Provinces(s)) do if g.faction then rebels=rebels+1 elseif g.loyalty<45 then unrest=unrest+1 else loyal=loyal+1 end end
 line(parts,I.Text('OVERVIEW_DETAIL',loyal,unrest,rebels,s.strain,rounded(s.averageLoyalty),s.warTurns))
 line(parts,I.Text('OVERVIEW_HELP'))
 if s.war then line(parts,I.Text('WAR_DETAIL',s.war.name,s.war.leader,s.war.start,#s.war.provinces,s.war.troops,s.war.defections)) end
 if s.succession then line(parts,I.Text('SUCCESSION_PENDING',s.succession.deadline)) end
 line(parts,I.Text('RESTORATION_DETAIL',s.restorationActive and I.Text('ACTIVE') or s.restored and I.Text('DORMANT') or I.Text('LOCKED'),s.restorationSince and I.Now()-s.restorationSince or 0,I.Scale(20)))
 for _,w in ipairs(s.wars) do row(w.name..'[NEWLINE]'..I.Text('TURN',w.start),w.id)
  if selected==w.id then line(parts,I.Text('WAR_RECORD',w.name,w.leader,w.start,w.finish,I.Text('RESULT_'..w.result),w.restored,w.troops,w.authorityLost,w.authorityRecovered)) end
 end
end
local function military(s,parts)
 local groups={};local total,count=0,0
 for _,uid in ipairs(I.Keys(s.units)) do local r=s.units[uid];local key=r.home or 'CAPITAL';groups[key]=groups[key] or {};groups[key][#groups[key]+1]=r;total=total+I.Oath(s,r,Players[s.pid]:GetUnitByID(uid));count=count+1 end
 line(parts,I.Text('MILITARY_OVERVIEW',count,count>0 and rounded(total/count) or 100))
 line(parts,I.Text('MILITARY_HELP'))
 for _,key in ipairs(I.Keys(groups)) do local g=s.governors[key];row(g and g.cityName or I.Text('CAPITAL_ARMY'),key)
  if selected==key or not selected then for _,r in ipairs(groups[key]) do
   local unit=Players[s.pid]:GetUnitByID(r.unit)
   if unit then local oath=I.Oath(s,r,unit);line(parts,I.Text('UNIT_DETAIL',unit:GetName(),r.id,rounded(oath),I.Text(oath>=80 and 'OATH_FANATIC' or oath>=60 and 'OATH_RELIABLE' or oath>=40 and 'OATH_QUESTIONABLE' or oath>=20 and 'OATH_MUTINY' or 'OATH_DEFECTION'),r.battles,r.kills)) end
  end end
 end
end
local function dynasty(s,parts)
 if s.succession then
  line(parts,I.Text('SUCCESSION_PENDING',s.succession.deadline))
  for _,kind in ipairs({'BLOOD','STEEL','COUNCIL'}) do local c=s.succession.candidates[kind]
   line(parts,c.name..' - '..I.Text('HEIR_'..kind)..'[NEWLINE]'..I.Text('HEIR_HELP_'..kind)..'[NEWLINE]'..c.trait)
   action(s,I.Text('SELECT_HEIR',c.name),'SUCCESSION',kind,s.succession.id)
  end
 end
 for n,r in ipairs(s.dynasty) do row(r.name,n)
  if selected==n or n==#s.dynasty then line(parts,I.Text('DYNASTY_RECORD',r.name,r.start,r.finish or I.Now(),r.length or I.Now()-r.start,r.wars,r.rebellions,r.acquired,r.lost,r.reforms)..'[NEWLINE]'..(r.trait or '')) end
 end
end
refresh=function()
 if refreshing or I.Applying then return end;refreshing=true
 local pid=Game.GetActivePlayer();local p=Players[pid]
 local visible=I.IsEmpire(pid) and p:IsHuman() and p:IsAlive() and world()
 Controls.ImperialLauncher:SetHide(not visible);Controls.ImperialPanel:SetHide(not visible or not opened)
 if not visible then refreshing=false;return end
 local s=I.State(pid)
 Controls.ImperialStatus:SetText(I.Text('LAUNCHER',rounded(s.authority),I.Condition(s.authority)));IconHookup(0,24,'IMPERIAL_OBJECT_ATLAS',Controls.ImperialIcon)
 if not opened then refreshing=false;return end
 IconHookup(1,64,'IMPERIAL_OBJECT_ATLAS',Controls.ImperialEmblem);Controls.ImperialTitle:SetText(I.Text('TITLE'))
 Controls.ImperialSummary:SetText(I.Text('SUMMARY',I.Reign(s).name,rounded(s.authority),I.Condition(s.authority),I.Text(s.reform)))
 tabs:ResetInstances();rows:ResetInstances();actions:ResetInstances()
 for _,name in ipairs({'OVERVIEW','GOVERNORS','DECISIONS','MILITARY','REFORMS','DYNASTY','CHRONICLE'}) do
  local key=name;local item=tabs:GetInstance();item.TabChoice:SetText(I.Text('TAB_'..key))
  item.TabChoice:RegisterCallback(Mouse.eLClick,function() tab=key;selected=nil;message='';refresh() end)
 end
 local parts={}
 if tab=='OVERVIEW' then overview(s,parts)
 elseif tab=='GOVERNORS' or tab=='DECISIONS' then governors(s,parts,tab=='DECISIONS')
 elseif tab=='MILITARY' then military(s,parts)
 elseif tab=='DYNASTY' then dynasty(s,parts)
 elseif tab=='REFORMS' then
  line(parts,I.Text('REFORM_OVERVIEW',I.Text(s.reform),math.max(0,s.reformNext-I.Now())))
  for _,name in ipairs(I.ReformNames) do line(parts,I.Text(name)..'[NEWLINE]'..I.Text('REFORM_HELP_'..name));action(s,I.Text('ADOPT_REFORM',I.Text(name)),'REFORM',name) end
 else for _,e in ipairs(s.history) do line(parts,I.Text('TURN',e.turn)..' - '..e.text) end end
 Controls.ImperialDetailText:SetText(table.concat(parts,'[NEWLINE][NEWLINE]'))
 local lines=0;for _,part in ipairs(parts) do lines=lines+math.max(1,math.ceil(#part/65))+2 end
 Controls.ImperialDetailText:SetSizeY(math.max(40,lines*22))
 for _,stack in ipairs({Controls.ImperialTabs,Controls.ImperialList,Controls.ImperialActions,Controls.ImperialDetailStack}) do stack:CalculateSize();stack:ReprocessAnchoring() end
 Controls.ImperialListScroll:CalculateInternalSize();Controls.ImperialDetailScroll:CalculateInternalSize();Controls.ImperialMessage:SetText(message~='' and message or I.Text('UI_HINT'))
 refreshing=false
end
Controls.ImperialStatus:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
Controls.ImperialClose:RegisterCallback(Mouse.eLClick,function() opened=false;refresh() end)
ContextPtr:SetInputHandler(function(msg,key) if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then opened=false;refresh();return true end;return false end)
LuaEvents.ImperialChanged.Add(function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
LuaEvents.ImperialResponse.Add(function(pid,ok,text) if pid==Game.GetActivePlayer() then message=text;refresh() end end)
Events.LoadScreenClose.Add(refresh)
Events.GameplaySetActivePlayer.Add(function() opened=false;selected=nil;refresh() end)
Events.ActivePlayerTurnStart.Add(refresh)
Events.ActivePlayerTurnEnd.Add(function() opened=false;refresh() end)
Events.SerialEventEnterCityScreen.Add(function() cityView=true;opened=false;refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityView=false;refresh() end)
Events.AILeaderMessage.Add(function() leaderView=true;opened=false;refresh() end)
Events.LeavingLeaderViewMode.Add(function() leaderView=false;refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function(info) if info and info.Type then blocked[info.Type]=true;opened=false;refresh() end end)
Events.SerialEventGameMessagePopupProcessed.Add(function(kind) blocked[kind]=nil;refresh() end)
refresh()
