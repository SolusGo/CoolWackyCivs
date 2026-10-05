include('IconSupport')
include('ViltrumRuntime')
local V=MapModData.ViltrumEmpire
local opened=false
local queued=false
local cityView=false
local leaderView=false
local popups={}
local function worldView()
 if cityView or leaderView or (UI and UI.IsCityScreenUp and UI.IsCityScreenUp()) then return false end
 return next(popups)==nil
end
local function refresh()
 local pid=Game.GetActivePlayer();local p=Players[pid]
 local visible=p and p:IsAlive() and V.IsViltrum(pid) and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
 local world=worldView()
 Controls.Launcher:SetHide(not visible or not world or queued)
 if not visible then
  if queued then queued=false;UIManager:DequeuePopup(ContextPtr);ContextPtr:SetHide(false) end
  opened=false;Controls.Panel:SetHide(true);return
 end
 local pending=V.Get(pid,'pending')
 if pending~=0 and not queued then
  queued=true;UIManager:QueuePopup(ContextPtr,PopupPriority.InGameUtmost)
 elseif pending==0 and queued then
  queued=false;UIManager:DequeuePopup(ContextPtr);ContextPtr:SetHide(false)
 end
 -- Decisions reopen from persisted pending state after a load. Never use UI
 -- closures as gameplay state. The runtime validates event and choice again.
 Controls.Panel:SetHide(pending==0 and (not opened or not world))
 Controls.Launcher:SetHide(not world or pending~=0)
 Controls.Close:SetHide(pending~=0)
 IconHookup(0,64,'VILTRUM_ICON_ATLAS',Controls.Emblem)
 local labels={'Momentum: '..V.Remaining(pid,'momentum')..' turns'}
 local start=V.Get(pid,'countdown',-1)
 if start>=0 and V.Get(pid,'outbreak')==0 then labels[#labels+1]='Scourge in '..math.max(0,start+V.Turns(8)-Game.GetGameTurn())..' turns' end
 for _,n in ipairs({'quarantine','dying','recovery','noPeace','illusion'}) do
  local left=V.Remaining(pid,n);if left>0 then labels[#labels+1]=n..': '..left..' turns' end
 end
 Controls.State:SetText(table.concat(labels,'[NEWLINE]'))
 Controls.ChoiceA:SetHide(pending==0);Controls.ChoiceB:SetHide(pending==0)
 local names={[1]='PURGE_EVENT',[2]='SCOURGE_EVENT',[3]='EXTINCTION'}
 local title=names[pending] or 'TRAIT'
 Controls.EventTitle:SetText(Locale.ConvertTextKey('TXT_KEY_VILTRUM_'..title))
 local body=Locale.ConvertTextKey('TXT_KEY_VILTRUM_'..title..'_HELP')
 if pending==2 then body='The pathogen has reached Viltrum. Choose the fate of your people.[NEWLINE][NEWLINE]Quarantine sacrifices the economy to preserve more survivors. The Crusade preserves conquest rewards and produces Last Purebloods, at catastrophic population and military cost.[NEWLINE][NEWLINE]Capitals retain at least 2 citizens; Breeding Complexes protect one extra.[NEWLINE][NEWLINE]Hover each choice for its effects.' end
 if pending==3 then body='The galaxy must not know how few Viltrumites remain. If subject worlds discover the truth, rebellion will spread faster than the virus itself.[NEWLINE][NEWLINE]Buy secrecy, or demonstrate the strength of the survivors.[NEWLINE][NEWLINE]Hover each choice for its effects.' elseif pending==0 then body=Locale.ConvertTextKey('TXT_KEY_VILTRUM_STRATEGY') end
 Controls.EventText:SetText(body)
 IconHookup(pending==2 and 3 or pending==3 and 5 or 2,128,'VILTRUM_OBJECT_ATLAS',Controls.EventIcon)
 local a,b,ah,bh='','','',''
 if pending==1 then
  a='ONLY THE STRONG SHALL REMAIN';b='STRENGTH REQUIRES AN EMPIRE TO RULE'
  ah='Each city loses 1 Population, minimum 1. Existing military units +10 XP; future land combat units +3 XP. Permanent +3% military Production; +1 General progress/turn for '..V.Turns(20)..' turns.'
  bh='+10% Growth for '..V.Turns(20)..' turns; +1 Happiness/city for '..V.Turns(10)..' turns. Culture = round(75 × CulturePercent / 100 × (1 + 0.15 × current era index)).'
 elseif pending==2 then
  a='ENFORCE TOTAL QUARANTINE';b='CONTINUE THE CRUSADE'
  ah='Lose 75% population and approximately 80% Bloodline units; two survivors if available. 25 HP and Scourge-Hardened. '..V.Turns(20)..' turns of quarantine, then '..V.Turns(20)..' turns of full recovery. Existing routes are recalled. Training and purchasing new Settlers, Caravans and Cargo Ships are blocked. No population growth or conquest rewards; starvation remains possible.'
  bh='Lose 85% population and approximately 90% Bloodline units; one survivor if available. 10 HP and Last Pureblood. '..V.Turns(25)..' turns of Dying Empire, shortened by first foreign conquests; no voluntary peace for '..V.Turns(10)..' turns. Then '..V.Turns(15)..' turns of +15% Growth.'
 elseif pending==3 then
  local cost=V.GoldCost(p);a='MAINTAIN THE ILLUSION — '..cost..' GOLD';b='FEAR REQUIRES A DEMONSTRATION'
  ah='+25% spy defense and +10% city strength for '..V.Turns(20)..' turns.'
  bh='Free Great General; true survivors +10 XP; Momentum for at least '..V.Turns(5)..' turns; two rebels near the weakest occupied city. No custom diplomatic penalty.'
 end
 Controls.ChoiceA:SetText(a);Controls.ChoiceB:SetText(b)
 Controls.ChoiceA:SetToolTipString(ah);Controls.ChoiceB:SetToolTipString(bh)
 Controls.ChoiceA:SetDisabled(pending==3 and p:GetGold()<V.GoldCost(p))
end
local function choose(n)
 local pid=Game.GetActivePlayer()
 if V.Choose(pid,V.Get(pid,'pending'),n) then opened=false end
 refresh()
end
Controls.Status:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;refresh() end)
Controls.ChoiceA:RegisterCallback(Mouse.eLClick,function() choose(1) end)
Controls.ChoiceB:RegisterCallback(Mouse.eLClick,function() choose(2) end)
LuaEvents.ViltrumChanged.Add(refresh)
Events.LoadScreenClose.Add(refresh)
Events.GameplaySetActivePlayer.Add(function() opened=false;refresh() end)
Events.ActivePlayerTurnStart.Add(refresh)
Events.SerialEventEnterCityScreen.Add(function() cityView=true;refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityView=false;refresh() end)
Events.AILeaderMessage.Add(function() leaderView=true;refresh() end)
Events.LeavingLeaderViewMode.Add(function() leaderView=false;refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function(info)
 if info and info.Type then popups[info.Type]=true;refresh() end
end)
Events.SerialEventGameMessagePopupProcessed.Add(function(typ)
 popups[typ]=nil;refresh()
end)
refresh()
