include('IconSupport')
include('InstanceManager')
include('KingdomsCore')
local K=MapModData.TheKingdoms
local tabs=InstanceManager:new('KingdomsTabInstance','TabChoice',Controls.RealmTabs)
local rows=InstanceManager:new('KingdomsRowInstance','RowChoice',Controls.RealmList)
local actions=InstanceManager:new('KingdomsActionInstance','ActionChoice',Controls.RealmActions)
local opened,cityView,leaderView,refreshing=false,false,false,false
local tab,chosen,message,filter='OVERVIEW',nil,'','ALL'
local blocked={}
local seenAppointments={}
local refresh
local function worldView()
 return not cityView and not leaderView and next(blocked)==nil and not (UI and UI.IsCityScreenUp and UI.IsCityScreenUp())
end
local function number(n) return tostring(math.floor(n+.5)) end
local function line(parts,text) parts[#parts+1]=text end
local function action(label,help,ok,callback)
 local row=actions:GetInstance();row.ActionChoice:SetText(label);row.ActionChoice:SetToolTipString(help);row.ActionChoice:SetDisabled(not ok)
 row.ActionChoice:RegisterCallback(Mouse.eLClick,function() if not worldView() then return end;callback();refresh() end)
end
local function row(label,id,tooltip)
 local item=rows:GetInstance();item.RowChoice:SetText((chosen==id and '[ICON_CHECKBOX] ' or '')..label)
 item.RowChoice:SetToolTipString(tooltip or label)
 item.RowChoice:RegisterCallback(Mouse.eLClick,function() chosen=id;message='';refresh() end)
end
local function traits(h,kind)
 local result={};for _,name in ipairs(h.traits or {}) do result[#result+1]=K.Text((kind or 'TRAIT_')..name:upper()) end;return table.concat(result,', ')
end
local function describeHouse(pid,s,h,parts)
 local k=s.kingdoms[h.kingdom]
 line(parts,K.Text('HOUSE',h.name));line(parts,K.Text('HOUSE_ORIGIN',s.kingdoms[h.origin].name,K.Date(h.founded)))
 line(parts,K.Text('HERALDRY',K.Text('SYMBOL_'..h.crest.symbol:upper()),h.crest.background+1,h.crest.color+1))
 line(parts,K.Text('FOUNDER',K.CharacterName(s,s.characters[h.founder])));line(parts,K.Text('HEAD',K.CharacterName(s,s.characters[h.head])))
 if h.parent then line(parts,K.Text('PARENT',s.houses[h.parent].name)) end
 local children={};for _,id in ipairs(h.children) do children[#children+1]=s.houses[id].name end
 if #children>0 then line(parts,K.Text('DESCENDANTS',table.concat(children,', '))) end
 line(parts,K.Text('TRAITS',traits(h)))
 line(parts,K.Text('HOUSE_STATS',number(K.Influence(s,h)),number(h.loyalty),K.LoyaltyLabel(h.loyalty),number(h.prestige),number(h.claim),number(h.power)))
 line(parts,K.Text('HOUSE_HISTORY',h.stats.rulers,h.stats.guards,h.stats.wars,h.stats.completed,h.stats.failed))
 if h.demand then line(parts,K.Text('ACTIVE_DEMAND',K.DemandText(s,h.demand),number(K.DemandProgress(s,h,h.demand)),h.demand.target,math.max(0,h.demand.expires-K.Now())))
 else line(parts,K.Text('NO_DEMAND')) end
 for _,id in ipairs(K.Keys(h.relations)) do local other=s.houses[id];if other then line(parts,K.Text('HOUSE_RELATION',other.name,K.RelationshipLabel(h.relations[id]),h.relations[id])) end end
 if k.active then
  for _,name in ipairs({'GIFT','ESTATES','CHARTER','AUTHORITY'}) do
   local key=name;local ok,help=K.CanAppease(pid,h.id,key)
   if key~='AUTHORITY' or K.HasTrait(h,'Militaristic') then action(K.Text('ACTION_'..key),help,ok,function() local _,text=K.Appease(pid,h.id,key);message=text end) end
  end
  if h.demand then action(K.Text('REFUSE'),K.Text('REFUSE_HELP'),true,function() K.Refuse(pid,h.id);message=K.Text('ACTION_DONE') end) end
 end
 line(parts,K.Text('HOUSE_TIMELINE'))
 local byID={};for _,entry in ipairs(s.history) do byID[entry.id]=entry end
 for i=math.max(1,#h.timeline-19),#h.timeline do local e=byID[h.timeline[i]];if e then line(parts,K.Date(e.turn)..': '..K.HistoryText(e)) end end
end
local function overview(s,parts)
 local ruler=s.ruler and s.characters[s.ruler]
 line(parts,K.Text('CURRENT_RULER',K.CharacterName(s,ruler)))
 if ruler then
  line(parts,K.Text('REIGN',K.Now()-ruler.reignStart,ruler.legitimacy));line(parts,K.Text('TRAITS',traits(ruler,'RULER_TRAIT_')))
  line(parts,K.Text('RULER_EFFECTS',K.TraitSum(ruler,'building',K.RulerTraits),K.TraitSum(ruler,'science',K.RulerTraits),K.TraitSum(ruler,'gold',K.RulerTraits),K.TraitSum(ruler,'production',K.RulerTraits),K.TraitSum(ruler,'military',K.RulerTraits)))
 end
 line(parts,K.Text('REALM_STABILITY',s.realm,K.StabilityLabel(s.realm,true)))
 local loyal,neutral,hostile=0,0,0
 for _,h in ipairs(K.ActiveHouses(s)) do if h.loyalty>=20 then loyal=loyal+1 elseif h.loyalty<-19 then hostile=hostile+1 else neutral=neutral+1 end end
 line(parts,K.Text('HOUSE_COUNTS',loyal,neutral,hostile));line(parts,K.Text('GUARD_COUNT',K.GuardCount(s)))
 line(parts,K.Text('OVERVIEW_HELP'))
end
local function kingdoms(pid,s,parts)
 local kingdoms=K.ActiveKingdoms(s)
 for _,k in ipairs(kingdoms) do row(K.Text('KINGDOM_ROW',k.name,k.population,#k.houses,k.stability),k.id) end
 if chosen and s.houses[tonumber(chosen)] then describeHouse(pid,s,s.houses[tonumber(chosen)],parts);return end
 local k=s.kingdoms[chosen] or kingdoms[1]
 if not k then line(parts,K.Text('NO_KINGDOMS'));return end
 line(parts,K.Text('KINGDOM_DETAIL',k.name,k.population,k.stability,K.StabilityLabel(k.stability),#k.houses,K.HouseTarget(k.population)))
 for _,h in ipairs(K.ActiveHouses(s,k.id)) do
  local house=h
  line(parts,K.Text('HOUSE_ROW',h.name,number(K.Influence(s,h)),number(h.loyalty),number(h.prestige)))
  action(K.Text('INSPECT_HOUSE',h.name),traits(h),true,function() chosen=tostring(house.id) end)
 end
end
local function succession(pid,s,parts)
 if s.war then
  line(parts,K.Text('WAR_DETAIL',s.war.number,K.Now()-s.war.start,math.max(0,s.war.deadline-K.Now())))
  line(parts,K.Text('WAR_PENALTIES'))
  local fs=K.Factions(s);for _,f in ipairs(fs) do row(K.Text('FACTION_ROW',s.houses[f.house].name,number(f.percent)),f.id) end
  local supported=s.war.supported and fs[s.war.supported]
  local house=supported and s.houses[supported.house]
  line(parts,house and K.Text('PLAYER_SUPPORT',house.name) or K.Text('PLAYER_SUPPORT_NEUTRAL',K.Text('NEUTRAL')))
  local f=fs[tonumber(chosen) or s.war.supported] or fs[1]
  if f then
   line(parts,K.Text('CLAIMANT',K.CharacterName(s,s.characters[f.claimant])))
   local members={};for _,id in ipairs(f.members) do members[#members+1]=s.houses[id].name end
   line(parts,K.Text('MEMBERS',table.concat(members,', ')))
   for _,name in ipairs({'FUND','MILITARY','DENOUNCE','CONCESSION','TREASURY','ALLIANCE','NEUTRAL'}) do
    local key=name;local ok,help=K.CanSupport(pid,f.id,key)
    action(K.Text('WAR_ACTION_'..key),help,ok,function() local _,text=K.Support(pid,f.id,key);message=text end)
   end
  end
  for i=math.max(1,#s.history-15),#s.history do local e=s.history[i];if e.category=='CIVILWARS' then line(parts,K.Date(e.turn)..': '..K.HistoryText(e)) end end
 else
  line(parts,K.Text('CLAIMS_HELP'))
  for _,claim in ipairs(s.claims) do
   local h=s.houses[claim.house];row(K.Text('CLAIM_ROW',h.name,number(claim.percent)),h.id)
   if chosen==h.id then describeHouse(pid,s,h,parts) end
  end
  for i=#s.history,1,-1 do local e=s.history[i];if e.category=='RULERS' then line(parts,K.Date(e.turn)..': '..K.HistoryText(e)) end end
 end
end
local function guards(pid,s,parts)
 line(parts,K.Text('GUARD_COUNT',K.GuardCount(s)));line(parts,K.Text('GUARDS_HELP'))
 for _,uid in ipairs(K.Keys(s.pending)) do
  local entry=s.pending[uid];line(parts,K.Text('GUARD_CANDIDATES',uid))
  for _,cid in ipairs(entry.candidates) do
   local candidateID,unitID=cid,uid
   local candidate=s.characters[cid];local h=s.houses[candidate.house]
   local label=K.CharacterName(s,candidate)..' - '..K.Text('GUARD_TRAIT_'..candidate.guardTrait:upper())
   local help=K.Text('GUARD_TRAIT_HELP_'..candidate.guardTrait:upper())..'[NEWLINE]'..K.Text('APPOINT_HELP',h.name)
   action(label,help,s.kingdoms[h.kingdom].active,function() if K.Appoint(pid,unitID,candidateID) then message=K.Text('ACTION_DONE') end end)
  end
 end
 for _,cid in ipairs(K.Keys(s.guards)) do
  local characterID=cid
  local g=s.guards[cid];local c=s.characters[cid]
  if g.alive then
   row(K.CharacterName(s,c),cid)
   if chosen==cid or g.oathPending then
    line(parts,K.Text('GUARD_DETAIL',K.CharacterName(s,c),K.Text('GUARD_TRAIT_'..g.trait:upper()),K.Date(g.appointed),g.kills,g.battles))
    line(parts,K.Text('GUARD_TRAIT_HELP_'..g.trait:upper()))
    if g.oathPending and K.GuardOpposes(s,g) then
     line(parts,K.Text('GUARD_OATH',K.CharacterName(s,c)))
     for _,name in ipairs({'KEEP','RETURN','OATH'}) do
      local key=name;local ok,help=K.CanOath(pid,cid,key)
      action(K.Text('OATH_'..key),help,ok,function() local _,text=K.Oath(pid,characterID,key);message=text end)
     end
    end
   end
  end
 end
end
local function chronicle(s,parts)
 line(parts,K.Text('CHRONICLE_HELP'))
 for _,name in ipairs({'ALL','RULERS','HOUSES','CIVILWARS','GUARDS','KINGDOMS'}) do
  local key=name;row(K.Text('FILTER_'..key),'FILTER:'..key)
  if chosen=='FILTER:'..key then filter=key end
 end
 for i=#s.history,1,-1 do local e=s.history[i];if filter=='ALL' or e.category==filter then line(parts,K.Date(e.turn)..': '..K.HistoryText(e)) end end
end
refresh=function()
 if refreshing or K.ApplyingEffects then return end
 refreshing=true
 local pid=Game.GetActivePlayer();local p=Players[pid]
 local visible=K.IsKingdoms(pid) and p:IsAlive() and p:IsHuman() and worldView()
 Controls.RealmLauncher:SetHide(not visible);Controls.RealmPanel:SetHide(not visible or not opened)
 if not visible then refreshing=false;return end
 local s=K.State(pid)
 local newAppointment=false
 for uid,entry in pairs(s.pending) do
  local identity=uid..':'..entry.created
  if not seenAppointments[identity] then seenAppointments[identity]=true;newAppointment=true end
 end
 if newAppointment then opened=true;tab='GUARDS';chosen=nil end
 Controls.RealmPanel:SetHide(not opened)
 Controls.RealmStatus:SetText(K.Text('LAUNCHER',s.realm,K.StabilityLabel(s.realm,true)))
 IconHookup(0,24,'KINGDOMS_OBJECT_ATLAS',Controls.RealmIcon)
 if not opened then refreshing=false;return end
 K.Log('UI','Refresh '..tab..' for player '..pid)
 IconHookup(1,64,'KINGDOMS_OBJECT_ATLAS',Controls.RealmEmblem)
 Controls.RealmTitle:SetText(K.Text('TITLE'))
 local ruler=s.ruler and s.characters[s.ruler]
 Controls.RealmSummary:SetText(K.Text('SUMMARY',K.CharacterName(s,ruler),s.realm,K.StabilityLabel(s.realm,true),K.KingdomCount(s),#K.ActiveHouses(s),K.GuardCount(s)))
 tabs:ResetInstances();rows:ResetInstances();actions:ResetInstances()
 for _,name in ipairs({'OVERVIEW','KINGDOMS','SUCCESSION','GUARDS','CHRONICLE'}) do
  local key=name;local item=tabs:GetInstance();item.TabChoice:SetText(K.Text('TAB_'..key))
  item.TabChoice:RegisterCallback(Mouse.eLClick,function() tab=key;chosen=nil;message='';refresh() end)
 end
 local parts={}
 if tab=='OVERVIEW' then overview(s,parts)
 elseif tab=='KINGDOMS' then kingdoms(pid,s,parts)
 elseif tab=='SUCCESSION' then succession(pid,s,parts)
 elseif tab=='GUARDS' then guards(pid,s,parts)
 else chronicle(s,parts) end
 local text=table.concat(parts,'[NEWLINE][NEWLINE]')
 Controls.RealmDetailText:SetText(text)
 -- Height tracks content only on dirty refresh. Long histories scroll; no update callback.
 local lines=0;for _,part in ipairs(parts) do lines=lines+math.max(1,math.ceil(#part/72))+2 end
 Controls.RealmDetailText:SetSizeY(math.max(40,lines*22))
 for _,stack in ipairs({Controls.RealmTabs,Controls.RealmList,Controls.RealmActions,Controls.RealmDetailStack}) do stack:CalculateSize();stack:ReprocessAnchoring() end
 Controls.RealmListScroll:CalculateInternalSize();Controls.RealmDetailScroll:CalculateInternalSize()
 Controls.RealmMessage:SetText(message~='' and message or K.Text('UI_HINT'))
 refreshing=false
end
Controls.RealmStatus:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
Controls.RealmClose:RegisterCallback(Mouse.eLClick,function() opened=false;refresh() end)
ContextPtr:SetInputHandler(function(msg,key) if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then opened=false;refresh();return true end;return false end)
LuaEvents.KingdomsChanged.Add(function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
Events.LoadScreenClose.Add(refresh)
Events.GameplaySetActivePlayer.Add(function() opened=false;chosen=nil;refresh() end)
Events.ActivePlayerTurnStart.Add(refresh)
Events.ActivePlayerTurnEnd.Add(function() opened=false;refresh() end)
Events.SerialEventEnterCityScreen.Add(function() cityView=true;opened=false;refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityView=false;refresh() end)
Events.AILeaderMessage.Add(function() leaderView=true;opened=false;refresh() end)
Events.LeavingLeaderViewMode.Add(function() leaderView=false;refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function(info) if info and info.Type then blocked[info.Type]=true;opened=false;refresh() end end)
Events.SerialEventGameMessagePopupProcessed.Add(function(typ) blocked[typ]=nil;refresh() end)
refresh()
