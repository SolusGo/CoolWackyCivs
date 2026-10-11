-- Native UI lifecycle fixture: actual screen visibility is separate from events.
function SetupJourneyUI()
 local oldScreens,oldUI=NativeScreens,UI
 Locale={ConvertTextKey=function(key)return key end};Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
 InterfaceModeTypes={INTERFACEMODE_SELECTION=1};SystemUpdateUIType={BulkHideUI=1,BulkShowUI=2}
 ButtonPopupTypes={BUTTONPOPUP_TECH_TREE=1,BUTTONPOPUP_CHOOSEPOLICY=2,BUTTONPOPUP_CULTURE_OVERVIEW=3,
  BUTTONPOPUP_CHOOSETECH=4,BUTTONPOPUP_CHOOSE_TECH_TO_STEAL=5}
 UI={city=false,mode=1,IsCityScreenUp=function()return UI.city end,GetInterfaceMode=function()return UI.mode end}
 UIManager={modal=0,pushes=0,pops=0,contexts={},GetScreenSizeVal=function()return 1024,768 end,
  IsModal=function(self,ctx)return self.contexts[ctx] or false end,
  PushModal=function(self,ctx)
   assert(not self.contexts[ctx],'duplicate modal push');self.contexts[ctx]=true
   self.modal=self.modal+1;self.pushes=self.pushes+1
  end,
  PopModal=function(self,ctx)
   assert(self.contexts[ctx],'popping a foreign or absent modal');self.contexts[ctx]=nil
   self.modal=self.modal-1;self.pops=self.pops+1
  end}
 Vector4=function(...)return {...}end
 function Control()
  local c={hidden=false,disabled=false}
  function c:IsHidden()return self.hidden end;function c:SetHide(v)self.hidden=v end
  function c:SetDisabled(v)self.disabled=v end;function c:SetText(v)self.text=v end
  function c:SetTexture(v)self.texture=v end;function c:SetColor(v)self.color=v end
  function c:SetSizeVal(x,y)self.size={x,y}end;function c:SetToolTipString(v)self.tooltip=v end
  function c:RegisterCallback(button,f)self.callback=f end
  function c:CalculateSize()end;function c:ReprocessAnchoring()end;function c:CalculateInternalSize()end
  return c
 end
 NativeScreens={}
 for _,name in ipairs({'TechTree','TechPopup','SocialPolicyPopup','CultureOverview','GenericPopup',
  'GameMenu','LeaderHeadRoot','CityView','BulkUI'})do
  NativeScreens[name]=Control();NativeScreens[name].hidden=name~='BulkUI'
  if oldScreens and oldScreens[name] then NativeScreens[name].hidden=oldScreens[name].hidden end
 end
 if oldUI then UI.city=oldUI.city;UI.mode=oldUI.mode end
 ContextPtr={SetInputHandler=function(self,f)self.input=f end,
  LookUpControl=function(self,path)
   if path=='/InGame/WorldView/InfoCorner/TechPanel/TechPopup' then return NativeScreens.TechPopup end
   if path=='/LeaderHeadRoot' then return NativeScreens.LeaderHeadRoot end
   local name=path:match('^/InGame/(.+)$')
   if name~='TechPopup' and name~='LeaderHeadRoot' then return NativeScreens[name]end
  end,
  SetShowHideHandler=function(self,f)self.showHide=f end,SetShutdown=function(self,f)self.shutdown=f end,
  SetUpdate=function()error('UI polling is forbidden')end}
 Controls=setmetatable({},{__index=function(t,k)local c=Control();rawset(t,k,c);return c end})
 IconHookup=function(n,size,atlas,c)c.icon=n end
 InstanceManager={new=function()return {ResetInstances=function()end,GetInstance=function()return {
  MemoryRoot=Control(),MemoryIcon=Control(),MemoryTitle=Control(),MemoryText=Control()}end}end}
 Events={}
 for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','ActivePlayerTurnEnd','SerialEventEnterCityScreen',
  'SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopup',
  'SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed','InterfaceModeChanged',
  'SystemUpdateUI','UnitSelectionChanged'})do Events[name]=Event()end
end
function CityUI(value)
 UI.city=value;NativeScreens.CityView.hidden=not value
 if value then Events.SerialEventEnterCityScreen()else Events.SerialEventExitCityScreen()end
end
function DiploUI(value)
 NativeScreens.LeaderHeadRoot.hidden=not value
 if value then Events.AILeaderMessage()else Events.LeavingLeaderViewMode()end
end
function ModeUI(value)
 local old=UI.mode;UI.mode=value;Events.InterfaceModeChanged(old,value)
end
function MapReturn()Events.UnitSelectionChanged(Game.GetActivePlayer(),1,3,3,0,true)end
function OpenNative(name,typ)
 Events.SerialEventGameMessagePopup({Type=typ});NativeScreens[name].hidden=false
 Events.SerialEventGameMessagePopupShown({Type=typ})
end
function CloseNative(name,typ,processedFirst,missingProcessed)
 if processedFirst and not missingProcessed then Events.SerialEventGameMessagePopupProcessed(typ)end
 NativeScreens[name].hidden=true
 if not processedFirst and not missingProcessed then Events.SerialEventGameMessagePopupProcessed(typ)end
end
