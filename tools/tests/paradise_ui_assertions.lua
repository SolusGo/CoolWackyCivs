assert(not Controls.JourneyLauncher.hidden and Controls.JourneyPanel.hidden)
Controls.JourneyLauncher.callback();assert(not Controls.JourneyPanel.hidden and UIManager.modal==1)
Controls.MagicTab.callback();assert(not Controls.MagicStack.hidden and Controls.PassButton.disabled)
CityUI(true);assert(Controls.JourneyLauncher.hidden and Controls.JourneyPanel.hidden and UIManager.modal==0)
CityUI(false);assert(not Controls.JourneyPanel.hidden and UIManager.modal==1)
Controls.JourneyClose.callback();assert(UIManager.modal==0)
for i=1,3 do NativeGP(80,'generated')end;NextTurn()
Controls.JourneyLauncher.callback();Controls.MagicTab.callback();assert(not Controls.PassButton.disabled)
Controls.PassButton.callback();assert(S().dreams==0 and Players[1].science==30,'button executes authoritative magic')
Controls.JourneyClose.callback()

-- Normal native orders: Tech closes then Processed, Culture does the reverse.
for _,entry in ipairs({{'TechTree',1,false},{'SocialPolicyPopup',2,false},{'CultureOverview',3,true},{'TechPopup',4,false}})do
 OpenNative(entry[1],entry[2]);assert(Controls.JourneyLauncher.hidden and UIManager.modal==0)
 CloseNative(entry[1],entry[2],entry[3]);assert(not Controls.JourneyLauncher.hidden)
end
-- No request/shown listener should remain latched forever after an ignored request.
Events.SerialEventGameMessagePopup({Type=99});assert(Controls.JourneyLauncher.hidden)
MapReturn();assert(not Controls.JourneyLauncher.hidden)
-- Toggle-close synchronously in an EARLIER request listener; ours is called last.
OpenNative('TechTree',1);CloseNative('TechTree',1,false)
Events.SerialEventGameMessagePopup({Type=1});MapReturn();assert(not Controls.JourneyLauncher.hidden)
-- Missing completion; returning to map reconciles authoritative context visibility.
for _,entry in ipairs({{'TechTree',1},{'SocialPolicyPopup',2},{'CultureOverview',3}})do
 OpenNative(entry[1],entry[2]);CloseNative(entry[1],entry[2],false,true)
 MapReturn();assert(not Controls.JourneyLauncher.hidden,'stale known popup hid launcher')
end
-- Nested screens: closing one must never clear another, including a missing callback.
OpenNative('TechTree',1);OpenNative('SocialPolicyPopup',2)
CloseNative('TechTree',1,false,true);MapReturn();assert(Controls.JourneyLauncher.hidden)
CloseNative('SocialPolicyPopup',2,false);assert(not Controls.JourneyLauncher.hidden)
Events.SerialEventGameMessagePopupShown({Type=90});Events.SerialEventGameMessagePopupShown({Type=91})
Events.SerialEventGameMessagePopupProcessed(90);assert(Controls.JourneyLauncher.hidden)
Events.SerialEventGameMessagePopupProcessed(91);assert(not Controls.JourneyLauncher.hidden)
Events.SerialEventGameMessagePopupShown({Type=92});MapReturn();assert(not Controls.JourneyLauncher.hidden)

DiploUI(true);MapReturn();assert(Controls.JourneyLauncher.hidden)
DiploUI(false);assert(not Controls.JourneyLauncher.hidden)
ModeUI(2);assert(Controls.JourneyLauncher.hidden);ModeUI(1);assert(not Controls.JourneyLauncher.hidden)
NativeScreens.BulkUI.hidden=true;Events.SystemUpdateUI(1);MapReturn();assert(Controls.JourneyLauncher.hidden)
NativeScreens.BulkUI.hidden=false;Events.SystemUpdateUI(2);assert(not Controls.JourneyLauncher.hidden)

-- Exactly one modal across repeated events; yielding never pops another context.
Controls.JourneyLauncher.callback();local pushes=UIManager.pushes
for i=1,5 do MapReturn();Events.ActivePlayerTurnStart();LuaEvents.ParadiseChanged(1)end
assert(UIManager.modal==1 and UIManager.pushes==pushes)
OpenNative('CultureOverview',3);assert(UIManager.modal==0 and Controls.JourneyPanel.hidden)
local foreign={};UIManager:PushModal(foreign);local pops=UIManager.pops
Controls.JourneyClose.callback();assert(UIManager:IsModal(foreign) and UIManager.pops==pops)
UIManager:PopModal(foreign);CloseNative('CultureOverview',3,true);assert(not Controls.JourneyLauncher.hidden)
-- Engine/parent hide and shutdown release this context's modal idempotently.
Controls.JourneyLauncher.callback();ContextPtr.showHide(true,false);assert(UIManager.modal==0)
ContextPtr.showHide(false,false);assert(UIManager.modal==1)
ContextPtr.shutdown();ContextPtr.shutdown();assert(UIManager.modal==0)
Controls.JourneyClose.callback()

AdvanceEra(4);assert(not Controls.JourneyCinematic.hidden and Controls.CinematicArt.texture=='ParadiseHeartbreak.dds')
Controls.CinematicContinue.callback();assert(Controls.JourneyCinematic.hidden)
NativeConstruct(Players[1].cities[1],20,'built');NextTurn(8);Controls.CinematicContinue.callback()
GoldenStart();GoldenEnd();GoldenStart()
for i=1,16 do NativeGP(80,'generated')end;NextTurn();AdvanceEra(5)
NativeConstruct(Players[1].cities[1],21,'built')
assert(not Controls.JourneyCinematic.hidden and Controls.CinematicArt.texture=='ParadiseFinalPeak.dds')
assert(Controls.CinematicMemories.text:find('The Final Peak',1,true) and UIManager.modal==1)
assert(ContextPtr.input(KeyEvents.KeyDown,Keys.VK_ESCAPE) and not S().finalShown,'Escape acknowledged finale')
OpenNative('TechTree',1);assert(UIManager.modal==0 and Controls.JourneyCinematic.hidden and S().story=='FINAL')
ReloadParadise();ReloadJourneyUI();assert(Controls.JourneyCinematic.hidden and S().story=='FINAL')
NativeScreens.TechTree.hidden=true;MapReturn()
assert(not Controls.JourneyCinematic.hidden and UIManager.modal==1 and not S().finalShown)
DiploUI(true);assert(UIManager.modal==0 and S().story=='FINAL');DiploUI(false);assert(UIManager.modal==1)
SetActive(0);Events.GameplaySetActivePlayer();assert(Controls.JourneyLauncher.hidden and UIManager.modal==0)
SetActive(1);Events.GameplaySetActivePlayer();assert(not Controls.JourneyCinematic.hidden and UIManager.modal==1)
Controls.CinematicContinue.callback();assert(S().finalShown and S().story=='' and UIManager.modal==0)
ReloadParadise();ReloadJourneyUI();assert(Controls.JourneyCinematic.hidden and not Controls.JourneyLauncher.hidden)
SetActive(0);Events.GameplaySetActivePlayer();assert(Controls.JourneyLauncher.hidden)
