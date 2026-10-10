include('InstanceManager')
include('LastCityCore')
local L=MapModData.TheLastCity
local rows=InstanceManager:new('LastCityRow','RowRoot',Controls.Rows)
local experts=InstanceManager:new('LastCityExpert','ExpertRoot',Controls.Rows)
local tabs=InstanceManager:new('LastCityTab','TabButton',Controls.Tabs)
local opened,cityView,leaderView,refreshing=false,false,false,false
local blocked={};local category='OVERVIEW';local selected,message=nil,''
local tabOrder={'OVERVIEW','REFUGEES','EXPERTS','RATIONS','BUILDINGS','CRISES','HISTORY'}
local achievementShown=false
local function worldView()
 return not cityView and not leaderView and next(blocked)==nil and not (UI.IsCityScreenUp and UI.IsCityScreenUp())
end
local refresh
local function row(text,button,callback,enabled,tooltip)
 local r=rows:GetInstance();r.RowText:SetText(text)
 r.RowRoot:SetToolTipString(tooltip or text);r.RowButton:SetHide(not callback)
 if callback then r.RowButton:SetText(button);r.RowButton:SetDisabled(enabled==false);r.RowButton:SetToolTipString(tooltip or text);r.RowButton:RegisterCallback(Mouse.eLClick,callback) end
 return r
end
local function choose(kind,id,value,preview,ok)
 selected={kind=kind,id=id,value=value,preview=preview,ok=ok};message='';refresh()
end
refresh=function()
 if refreshing then return end;refreshing=true
 local pid=Game.GetActivePlayer();local p=Players[pid]
 local visible=L.IsCity(pid) and p:IsHuman() and p:IsAlive() and worldView()
 Controls.Launcher:SetHide(not visible);Controls.Panel:SetHide(not visible or not opened)
 if not visible then refreshing=false;return end
 local s=L.State(pid)
 if s.incompatible then Controls.Open:SetText(L.Text('SAVE_UNSUPPORTED'));Controls.Panel:SetHide(true);refreshing=false;return end
 local c=L.City(s)
 if not c then Controls.Open:SetText(L.Text('FOUND_FIRST'));Controls.Panel:SetHide(true);refreshing=false;return end
 local stats=L.Stats(s)
 Controls.Open:SetText(L.Text('STATUS',math.floor(s.provisions),math.floor(s.morale))..' | '..L.Text('COUNCIL'))
 if not opened then refreshing=false;return end
 local invasion=s.wave and L.Text('WAVE_ACTIVE',s.wave.number,s.wave.spawned-s.wave.defeated) or L.Text('NEXT_WAVE',math.max(0,(s.nextWave or L.Now())-L.Now()))
 Controls.Summary:SetText(L.Text('DASHBOARD',stats.population,stats.housing,math.floor(s.provisions),stats.capacity,stats.income,stats.consumption,stats.net)..'[NEWLINE]'..L.Text('MORALE_STATUS',math.floor(s.morale*10)/10,L.Text(L.Condition(s)),L.Text(s.ration))..' | '..invasion)
 tabs:ResetInstances()
 for _,key in ipairs(tabOrder) do local value=key;local r=tabs:GetInstance()
  r.TabButton:SetText((value==category and '[ICON_CHECKBOX] ' or '')..L.Text(value));r.TabButton:RegisterCallback(Mouse.eLClick,function() category=value;selected=nil;message='';refresh() end)
 end
 Controls.Tabs:CalculateSize();Controls.Tabs:ReprocessAnchoring();rows:ResetInstances();experts:ResetInstances()
 if category=='OVERVIEW' then
  row(L.Text('OVERVIEW_HELP'))
  row(L.Text('LEGACY_STATUS',s.wavesSurvived,s.majorSieges,s.bosses,math.min(30,s.majorSieges*2),s.losses))
  row(L.Text('EXPERT_OVERVIEW',s.accepted,s.refused,s.starvation))
  row(L.Text('DAWN_'..s.dawn))
  if s.refugee then row(L.Text('REFUGEES_WAITING'),L.Text('REFUGEES'),function() category='REFUGEES';refresh() end) end
  if s.crisis then row(L.Text('CRISIS_WAITING'),L.Text('CRISES'),function() category='CRISES';refresh() end) end
 elseif category=='REFUGEES' then local r=s.refugee
  if r then
   row(L.Text('CARAVAN_'..r.key)..'[NEWLINE]'..L.Text('CARAVAN_DETAILS',r.survivors,r.population,L.Text(r.skill)))
   row(L.Text('STORY_'..r.key)..'[NEWLINE]'..L.Text('RISK_'..r.risk))
   if r.status=='QUARANTINE' then row(L.Text('QUARANTINE_WAIT',math.max(0,r.due-L.Now())))
   else
    for _,choice in ipairs({'ACCEPT','QUARANTINE','REFUSE'}) do local value=choice
     local ok,reason=L.RefugeeCheck(s,r.id,value)
     row(reason,L.Text(value),function() choose('REFUGEE',r.id,value,reason,ok) end,ok and p:IsTurnActive(),reason)
    end
   end
  else row(L.Text('NO_REFUGEES',math.max(0,(s.nextRefugee or L.Now())-L.Now()))) end
 elseif category=='EXPERTS' then
  row(L.Text('EXPERTS_HELP'))
  for _,key in ipairs(L.Skills) do local value=key;local r=experts:GetInstance()
   r.ExpertText:SetText(L.Text('EXPERT_ROW',L.Text(value),s.experts[value],s.assigned[value],L.Config.ExpertCap));r.ExpertRoot:SetToolTipString(L.Text('SKILL_'..value))
   r.ExpertPlus:SetDisabled(not p:IsTurnActive() or s.assigned[value]>=math.min(L.Config.ExpertCap,s.experts[value]));r.ExpertMinus:SetDisabled(not p:IsTurnActive() or s.assigned[value]==0)
   r.ExpertPlus:RegisterCallback(Mouse.eLClick,function() local _,msg=L.Action(pid,'EXPERT',value,1);message=msg;refresh() end)
   r.ExpertMinus:RegisterCallback(Mouse.eLClick,function() local _,msg=L.Action(pid,'EXPERT',value,-1);message=msg;refresh() end)
  end
 elseif category=='RATIONS' then
  row(L.Text('RATION_HELP',math.max(0,s.rationNext-L.Now())))
  for _,key in ipairs(L.RationOrder) do local value=key;local r=L.Rations[value]
   local preview=L.Text('RATION_PREVIEW',L.Text(value),math.ceil(stats.base*r.consumption),stats.income-math.ceil(stats.base*r.consumption),r.morale,r.growth)
   local ok=s.ration~=value and L.Now()>=s.rationNext
   row(preview,L.Text('SELECT'),function() choose('RATION',value,nil,preview,ok) end,ok and p:IsTurnActive(),preview)
  end
 elseif category=='BUILDINGS' then
  row(L.Text('BUILDINGS_HELP'))
  for _,b in ipairs(L.Infrastructure) do local key=b.key;local ok,reason=L.CanInfrastructure(s,key)
   local text=L.Text('BUILDING_'..key)..'[NEWLINE]'..L.Text('BUILDING_HELP_'..key)
   row(text,L.Has(c,key) and L.Text('BUILT') or L.Text('QUEUE'),function() choose('BUILD',key,nil,text..'[NEWLINE]'..reason,ok) end,ok and p:IsTurnActive(),reason)
  end
 elseif category=='CRISES' then local r=s.crisis
  if r then
   row(L.Text('CRISIS_'..r.key)..'[NEWLINE]'..L.Text('CRISIS_STORY_'..r.key))
   if r.key=='GATES' and s.survivors.ASH then row(L.Text('ASH_SOLUTION')) end
   for n=1,3 do local choice=n;local ok,reason=L.CrisisCheck(s,r.id,choice)
    row(ok and reason or L.Text('CHOICE_'..r.key..'_'..choice)..'[NEWLINE]'..reason,L.Text('SELECT'),function() choose('CRISIS',r.id,choice,reason,ok) end,ok and p:IsTurnActive(),reason)
   end
  else row(L.Text('NO_CRISIS')) end
 elseif category=='HISTORY' then
  row(L.Text('LEGACY_STATUS',s.wavesSurvived,s.majorSieges,s.bosses,math.min(30,s.majorSieges*2),s.losses))
  for i=#s.history,1,-1 do local h=s.history[i];row(L.Text('HISTORY_ROW',h.turn,L.Text(h.key),h.detail)) end
 end
 Controls.Rows:CalculateSize();Controls.Rows:ReprocessAnchoring();Controls.Scroll:CalculateInternalSize()
 Controls.Preview:SetText(message~='' and message or selected and selected.preview or L.Text('SELECT_HELP'))
 Controls.Confirm:SetDisabled(not selected or not selected.ok or not p:IsTurnActive());Controls.Confirm:SetText(L.Text('CONFIRM'))
 refreshing=false
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;selected=nil;refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;selected=nil;refresh() end)
Controls.Confirm:RegisterCallback(Mouse.eLClick,function()
 if not selected or not worldView() then return end
 local command=selected;selected=nil
 local _,msg=L.Action(Game.GetActivePlayer(),command.kind,command.id,command.value);message=msg;refresh()
end)
ContextPtr:SetInputHandler(function(msg,key)
 if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then opened=false;selected=nil;refresh();return true end
 return false
end)
LuaEvents.LastCityChanged.Add(function(pid)
 if pid==Game.GetActivePlayer() then
  local s=L.State(pid)
  if not s.incompatible and s.dawn=='ENDURES' and not achievementShown and worldView() then opened=true;category='OVERVIEW';achievementShown=true end
  refresh()
 end
end)
Events.LoadScreenClose.Add(refresh)
Events.GameplaySetActivePlayer.Add(function() opened=false;selected=nil;refresh() end)
Events.ActivePlayerTurnStart.Add(function() selected=nil;refresh() end)
Events.ActivePlayerTurnEnd.Add(function() opened=false;selected=nil;refresh() end)
Events.SerialEventEnterCityScreen.Add(function() cityView=true;opened=false;refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityView=false;refresh() end)
Events.AILeaderMessage.Add(function() leaderView=true;opened=false;refresh() end)
Events.LeavingLeaderViewMode.Add(function() leaderView=false;refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function(info) if info and info.Type then blocked[info.Type]=true;opened=false;refresh() end end)
Events.SerialEventGameMessagePopupProcessed.Add(function(typ) blocked[typ]=nil;refresh() end)
Events.SerialEventCityInfoDirty.Add(function() if opened then refresh() end end)
refresh()
