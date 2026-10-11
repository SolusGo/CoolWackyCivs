function control()
 local c={};function c:SetText(v) self.text=v end;function c:SetHide(v) self.hidden=v end
 function c:SetDisabled(v) self.disabled=v end;function c:SetToolTipString(v) self.tooltip=v end
 function c:RegisterCallback(_,fn) self.click=fn end;function c:CalculateSize() end
 function c:ReprocessAnchoring() end;function c:CalculateInternalSize() end;return c
end
Controls={};for key in ControlNames:gmatch('[^,]+') do Controls[key]=control() end
Managers={};InstanceManager={}
function InstanceManager:new(name)
 local m={rows={}};function m:ResetInstances() self.rows={} end
 function m:GetInstance() local r={RowRoot=control(),RowText=control(),RowButton=control(),ExpertRoot=control(),ExpertText=control(),TabButton=control(),ExpertPlus=control(),ExpertMinus=control()};self.rows[#self.rows+1]=r;return r end
 Managers[name]=m;return m
end
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
InterfaceModeTypes={INTERFACEMODE_SELECTION=1}
ButtonPopupTypes={BUTTONPOPUP_CHOOSEPRODUCTION=77}
UI={IsCityScreenUp=function() return false end,GetInterfaceMode=function() return 1 end};ContextPtr={SetInputHandler=function(self,fn) self.input=fn end}
local originalInclude=include;include=function(name) if name~='InstanceManager' then originalInclude(name) end end
assert(loadstring(UISource))()
L=MapModData.TheLastCity;S=L.State(0);C=Players[0].cities[0]
assert(L and #GameEvents.PlayerDoTurn.handlers==1 and #GameEvents.PlayerCanTrain.handlers==1)
assert(not GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_SETTLER))
assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
Controls.Open.click();assert(not Controls.Panel.hidden and #Managers.LastCityTab.rows==7)
Managers.LastCityTab.rows[4].TabButton.click();Managers.LastCityRow.rows[2].RowButton.click()
assert(S.ration=='STANDARD' and not Controls.Confirm.disabled);Controls.Confirm.click();assert(S.ration=='GENEROUS')
Managers.LastCityTab.rows[3].TabButton.click();S.experts.ENGINEERS=1;LuaEvents.LastCityChanged(0)
Managers.LastCityExpert.rows[1].ExpertPlus.click();assert(S.assigned.ENGINEERS==1)
L.Building(C,'DISTRICT',1);L.ApplyEffects(S);L.NewRefugee(S);S.provisions=100;S.refugee.riskRoll=100
Managers.LastCityTab.rows[2].TabButton.click();Managers.LastCityRow.rows[3].RowButton.click()
local pop=C.population;Controls.Confirm.click();assert(C.population>pop and not S.refugee)
Controls.Confirm.click();assert(not S.refugee)
Events.SerialEventEnterCityScreen.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.SerialEventExitCityScreen.Fire();assert(Controls.Panel.hidden and not Controls.Launcher.hidden)
Controls.Open.click();Events.AILeaderMessage.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.LeavingLeaderViewMode.Fire();Controls.Open.click()
Events.SerialEventGameMessagePopupShown.Fire({Type=99});assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed.Fire(99);assert(not Controls.Launcher.hidden)
ACTIVE=1;Events.GameplaySetActivePlayer.Fire();assert(Controls.Launcher.hidden and Controls.Panel.hidden)
ACTIVE=0;Events.GameplaySetActivePlayer.Fire();Controls.Open.click()
assert(ContextPtr.input(KeyEvents.KeyDown,Keys.VK_ESCAPE));assert(Controls.Panel.hidden)
assert(#Managers.LastCityTab.rows==7,'Refreshing must reuse tab instances')
Events.InterfaceModeChanged.Fire(1,2);assert(Controls.Launcher.hidden)
Events.InterfaceModeChanged.Fire(2,1);assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=9})
Events.SerialEventGameMessagePopupShown.Fire({Type=9})
Events.SerialEventGameMessagePopupProcessed.Fire(9);assert(not Controls.Launcher.hidden,'Repeated shown notifications must need only one close')
Events.SerialEventGameMessagePopupProcessed.Fire(9);assert(not Controls.Launcher.hidden,'Extra close notifications are harmless')
Events.SerialEventGameMessagePopupShown.Fire({Type=9})
Events.SerialEventGameMessagePopupShown.Fire({Type=10})
Events.SerialEventGameMessagePopupProcessed.Fire(9);assert(Controls.Launcher.hidden,'A different popup still blocks the Council')
Events.SerialEventGameMessagePopupProcessed.Fire(10);assert(not Controls.Launcher.hidden)
-- Match EUI's production notification order: processed, shown, city entry/exit.
Events.SerialEventGameMessagePopupProcessed.Fire(77)
Events.SerialEventGameMessagePopupShown.Fire({Type=77})
Events.SerialEventEnterCityScreen.Fire();assert(Controls.Launcher.hidden)
Events.SerialEventExitCityScreen.Fire();assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
-- Closing production must not release a separate technology/policy popup.
Events.SerialEventGameMessagePopupShown.Fire({Type=10})
Events.SerialEventGameMessagePopupShown.Fire({Type=77})
Events.SerialEventEnterCityScreen.Fire();Events.SerialEventExitCityScreen.Fire()
assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed.Fire(10);assert(not Controls.Launcher.hidden)
for turn=1,4 do
 Events.ActivePlayerTurnEnd.Fire();Events.ActivePlayerTurnStart.Fire()
 Events.SerialEventGameMessagePopupShown.Fire({Type=9})
 Events.SerialEventGameMessagePopupShown.Fire({Type=9})
 Events.SerialEventGameMessagePopupProcessed.Fire(9)
 assert(not Controls.Launcher.hidden,'Council must recover across repeated turns and popup cycles')
end
Controls.Open.click();Managers.LastCityTab.rows[4].TabButton.click()
TURN=S.rationNext;LuaEvents.LastCityChanged(0)
Managers.LastCityRow.rows[2].RowButton.click();LuaEvents.LastCityChanged(0);assert(Controls.Confirm.disabled)
S.infection={severity=4,untilTurn=TURN+8,lastTurn=-1};LuaEvents.LastCityChanged(0)
local expected=math.ceil(L.Stats(S).base*L.Rations.GENEROUS.consumption)+L.Stats(S).infection
assert(Managers.LastCityRow.rows[2].RowText.text:find(tostring(expected),1,true))
-- The same event-driven Council must show the transformation and live inputs.
S.dawn='ENDURES';S.morale=80;S.majorSieges=15;S.provisions=200;S.infection=nil
for _,key in ipairs(L.Skills) do S.experts[key]=5;S.assigned[key]=5 end
for _,key in ipairs({'DISTRICT','BARRACKS','RESIDENTIAL','SHELTER','STORAGE','DEPOT','WATER','HOSPITAL'}) do L.Building(C,key,1) end
L.Changed(S)
assert(Controls.Title.text==L.Text('ASCENDANT') and Controls.Open.text:find('HUMANITY ASCENDANT',1,true))
assert(Controls.Summary.text:find('Housing 68',1,true) and Controls.Summary.text:find('/ 550',1,true))
assert(Controls.Summary.text:find('Income +82',1,true) and Controls.Summary.text:find('+100% Production',1,true))
assert(Managers.LastCityRow.rows[1].RowText.text:find(L.Text('ASC_SUBTITLE'),1,true))
assert(Managers.LastCityRow.rows[2].RowText.text:find('City Defense +60%',1,true))
assert(Managers.LastCityRow.rows[3].RowText.text:find('Science +500%',1,true))
assert(Managers.LastCityRow.rows[4].RowText.text:find('+700%',1,true))
local sequence=S.sequence;local provisions=S.provisions
for _=1,100 do LuaEvents.LastCityChanged(0) end
assert(S.sequence==sequence and S.provisions==provisions and C:GetNumRealBuilding(GameInfoTypes.BUILDING_LC_ASC_ENGINEERS)==5)
Managers.LastCityTab.rows[3].TabButton.click()
assert(Managers.LastCityExpert.rows[1].ExpertText.text:find('+500% Production',1,true))
assert(Managers.LastCityExpert.rows[1].ExpertRoot.tooltip==L.Text('ASC_SKILL_ENGINEERS'))
assert(Managers.LastCityExpert.rows[3].ExpertText.text:find('power: 15',1,true))
Managers.LastCityExpert.rows[4].ExpertMinus.click();assert(S.assigned.VETERANS==4)
assert(Managers.LastCityExpert.rows[4].ExpertText.text:find('+40% local Defense',1,true))
Managers.LastCityTab.rows[4].TabButton.click()
assert(Managers.LastCityRow.rows[2].RowText.text:find('adjustment 50%',1,true))
S.provisions=0;LuaEvents.LastCityChanged(0)
assert(Managers.LastCityRow.rows[2].RowText.text:find('adjustment -10%',1,true))
S.provisions=200;Managers.LastCityTab.rows[5].TabButton.click()
assert(Managers.LastCityRow.rows[2].RowText.text:find('+8 Housing',1,true))
assert(Managers.LastCityRow.rows[8].RowText.text:find('+16 Provisions',1,true))
S.morale=59;L.Changed(S);Managers.LastCityTab.rows[1].TabButton.click()
assert(Controls.Summary.text:find('-5% Production',1,true))
assert(Managers.LastCityRow.rows[4].RowText.text:find('+595%',1,true))
Managers.LastCityTab.rows[7].TabButton.click()
assert(Managers.LastCityRow.rows[1].RowText.text:find('City Defense +60%',1,true))
S.fallen=true;LuaEvents.LastCityChanged(0);assert(Controls.Launcher.hidden and Controls.Panel.hidden)
S.fallen=nil;L.Save(0);Events.AILeaderMessage.Fire();Events.SerialEventGameMessagePopupShown.Fire({Type=88})
Events.LoadScreenClose.Fire();S=L.State(0)
assert(not Controls.Launcher.hidden and Controls.Panel.hidden and #Managers.LastCityTab.rows==7)
