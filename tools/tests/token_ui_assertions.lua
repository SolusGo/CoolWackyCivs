function control()
    local c={}
    function c:SetHide(b) self.hidden=b end
    function c:SetText(s) self.text=s end
    function c:SetDisabled(b) self.disabled=b end
    function c:SetToolTipString(s) self.tooltip=s end
    function c:RegisterCallback(_,f) self.click=f end
    function c:CalculateSize() end
    function c:ReprocessAnchoring() end
    function c:CalculateInternalSize() end
    return c
end
Controls={}
for name in ControlNames:gmatch('[^,]+') do Controls[name]=control() end
Managers={};InstanceManager={}
function InstanceManager:new(template,button,parent)
    local manager={rows={}}
    function manager:ResetInstances() self.rows={} end
    function manager:GetInstance()
        local row={CategoryButton=control(),PromptButton=control(),TargetButton=control(),Icon=control(),Name=control(),Cost=control()}
        self.rows[#self.rows+1]=row;return row
    end
    Managers[template]=manager
    return manager
end
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','ActivePlayerTurnEnd','SerialEventGameDataDirty','SerialEventUnitInfoDirty','SerialEventCityInfoDirty','SerialEventEnterCityScreen','SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed'}) do Events[name]=event() end
ActivePlayer=0;Game.GetActivePlayer=function() return ActivePlayer end
IconHookup=function() end;include=function(n) if n=='TokenRuntime' then assert(loadstring(RuntimeSource))() end end
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
ContextPtr={SetInputHandler=function(self,f) self.input=f end}
UI={IsCityScreenUp=function() return false end}
local T=MapModData.TokenizedIntelligence
bank(0,1000)
assert(loadstring(UISource))()
assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
Controls.Status.click();assert(not Controls.Panel.hidden)
assert(#Managers.TokenCategory.rows==7 and #Managers.TokenPrompt.rows==4)
Managers.TokenPrompt.rows[1].PromptButton.click()
assert(Controls.Execute.disabled and #Managers.TokenTarget.rows==1)
Managers.TokenTarget.rows[1].TargetButton.click();assert(not Controls.Execute.disabled)
Controls.Execute.click();assert(Players[0].cities[0].production==100)
bank(0,0);Events.SerialEventGameDataDirty.Fire()
assert(Managers.TokenPrompt.rows[1].PromptButton.disabled and Controls.Execute.disabled)
local before=Players[0].cities[0].production
Controls.Execute.click();assert(Players[0].cities[0].production==before)
-- A Prompt with a live target other than the first remains refreshable at slot limit.
local other=newCity(0,1);Players[0].cities[1]=other;T.Invalidate(0);bank(0,1000)
assert(T.Use(0,'GROWTH',1));bank(0,1000);Events.SerialEventGameDataDirty.Fire()
assert(not Managers.TokenPrompt.rows[3].PromptButton.disabled)
Managers.TokenPrompt.rows[3].PromptButton.click()
assert(Controls.Execute.disabled)
Managers.TokenTarget.rows[2].TargetButton.click();assert(not Controls.Execute.disabled)
Events.SerialEventEnterCityScreen.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.SerialEventExitCityScreen.Fire();assert(Controls.Panel.hidden and not Controls.Launcher.hidden)
Controls.Status.click();Events.AILeaderMessage.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.LeavingLeaderViewMode.Fire();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=11});Events.SerialEventGameMessagePopupShown.Fire({Type=12})
assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed.Fire(11);assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed.Fire(12);assert(not Controls.Launcher.hidden)
Controls.Status.click();assert(ContextPtr.input(KeyEvents.KeyDown,Keys.VK_ESCAPE));assert(Controls.Panel.hidden)
ActivePlayer=2;Events.GameplaySetActivePlayer.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
ActivePlayer=1;Events.GameplaySetActivePlayer.Fire();assert(not Controls.Launcher.hidden)
Network=true;Events.ActivePlayerTurnStart.Fire();assert(Controls.Launcher.hidden and Controls.Panel.hidden)
Network=false;ActivePlayer=0;Events.GameplaySetActivePlayer.Fire();Controls.Status.click()
Events.ActivePlayerTurnEnd.Fire();assert(Controls.Panel.hidden)
print('PASS Token UI: own-player visibility, costs/target validation, dispatch, full-slot refresh, city/diplomacy/nested popups, Escape and multiplayer hide')
