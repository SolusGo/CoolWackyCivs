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
UI={IsCityScreenUp=function() return false end,GetInterfaceMode=function() return 1 end};ContextPtr={SetInputHandler=function(self,fn) self.input=fn end}
local originalInclude=include;include=function(name) if name~='InstanceManager' then originalInclude(name) end end
assert(loadstring(UISource))()
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
Events.SerialEventGameMessagePopupProcessed.Fire(9);assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed.Fire(9);assert(not Controls.Launcher.hidden)
Controls.Open.click();Managers.LastCityTab.rows[4].TabButton.click()
TURN=S.rationNext;LuaEvents.LastCityChanged(0)
Managers.LastCityRow.rows[2].RowButton.click();LuaEvents.LastCityChanged(0);assert(Controls.Confirm.disabled)
S.infection={severity=4,untilTurn=TURN+8,lastTurn=-1};LuaEvents.LastCityChanged(0)
local expected=math.ceil(L.Stats(S).base*L.Rations.GENEROUS.consumption)+L.Stats(S).infection
assert(Managers.LastCityRow.rows[2].RowText.text:find(tostring(expected),1,true))
S.fallen=true;LuaEvents.LastCityChanged(0);assert(Controls.Launcher.hidden and Controls.Panel.hidden)
S.fallen=nil;L.Save(0);Events.AILeaderMessage.Fire();Events.SerialEventGameMessagePopupShown.Fire({Type=88})
Events.LoadScreenClose.Fire();S=L.State(0)
assert(not Controls.Launcher.hidden and Controls.Panel.hidden and #Managers.LastCityTab.rows==7)
