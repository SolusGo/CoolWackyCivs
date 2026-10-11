-- Optional UI: event-driven, no gameplay includes, timers, polling or save writes.
include('IconSupport')
include('InstanceManager')
local rows=InstanceManager:new('ParadiseMemoryRow','MemoryRoot',Controls.MemoryStack)
local open,modal,selected,story=false,false,'OVERVIEW',''
local blocked,message={},''
local rendering=false
local shownPopups,closingScreens={},{}
local contextHidden=false
-- IDs from BNW InGame.xml and the installed CP UI. Inspect this bounded set
-- only on lifecycle events; never scan the map or run an update timer.
local screens={'TechTree','TechPopup','SocialPolicyPopup','CultureOverview','GenericPopup',
    'TextPopup','DeclareWarPopup','NotificationLogPopup','WhosWinningPopup','NewEraPopup',
    'NaturalWonderPopup','GoodyHutPopup','BarbarianCampPopup','GoldenAgePopup','GreatPersonRewardPopup',
    'TechAwardPopup','WonderPopup','CityStateGreetingPopup','CityStateDiploPopup','DiploOverview',
    'MilitaryOverview','EconomicOverview','Demographics','VictoryProgress','ChoosePantheon',
    'ChooseReligion','EspionageOverview','ReligionOverview','ChooseMayaBonus','ChooseFaithGreatPerson',
    'SetUnitName','SetCityName','ProductionPopup','LeagueOverviewPopup','ChooseArchaeology',
    'ChooseIdeology','ChooseInternationalTradeRoute','ChooseTradeRouteNewHome','GreatWorkSplash',
    'TradeRouteOverview','LeagueProjectPopup','ChooseGoodyHutRewardPopup','ChooseAdmiralNewPort',
    'LeagueSplash','GameMenu','CivilopediaScreen','LeaderHeadRoot','LeaderTrade','DiscussLeader'}
local popupScreens={}
for _,entry in ipairs({{'BUTTONPOPUP_TECH_TREE','TechTree'},{'BUTTONPOPUP_CHOOSETECH','TechPopup'},
    {'BUTTONPOPUP_CHOOSE_TECH_TO_STEAL','TechPopup'},{'BUTTONPOPUP_CHOOSEPOLICY','SocialPolicyPopup'},
    {'BUTTONPOPUP_CULTURE_OVERVIEW','CultureOverview'}}) do
    local typ=ButtonPopupTypes and ButtonPopupTypes[entry[1]]
    if typ then popupScreens[typ]=entry[2] end
end
local function screen(name)
    local c=ContextPtr:LookUpControl('/InGame/'..name)
    -- The compact tech chooser is nested in InfoCorner; diplomacy is an
    -- engine-loaded root rather than a child of BNW InGame.xml.
    if not c and name=='TechPopup' then
        c=ContextPtr:LookUpControl('/InGame/WorldView/InfoCorner/TechPanel/TechPopup')
    elseif not c and name=='LeaderHeadRoot' then c=ContextPtr:LookUpControl('/LeaderHeadRoot') end
    return c
end
local function screenVisible(name)
    local c=screen(name)
    if c and c:IsHidden() then closingScreens[name]=nil end
    return c and not c:IsHidden() and not closingScreens[name]
end
local function text(key) return Locale.ConvertTextKey('TXT_KEY_PARADISE_'..key) end
local function runtime() return MapModData.Paradise end
local function uiState()
    local r=runtime();local p=Game.GetActivePlayer()
    return r and r.GetUIState and Players[p] and Players[p]:IsHuman() and r.GetUIState(p)
end
local function eraName(id)
    local row=GameInfo.Eras[id]
    return row and Locale.ConvertTextKey(row.Description) or tostring(id)
end
local function hidden(mapReturn)
    local nativeScreen=false
    for _,name in ipairs(screens) do if screenVisible(name) then nativeScreen=true end end
    local bulk=screen('BulkUI');if bulk then blocked.bulk=bulk:IsHidden() end
    if UI.IsCityScreenUp then blocked.city=UI.IsCityScreenUp() end
    if UI.GetInterfaceMode then blocked.mode=UI.GetInterfaceMode()~=InterfaceModeTypes.INTERFACEMODE_SELECTION end
    for typ in pairs(shownPopups) do
        local name=popupScreens[typ]
        if name and screen(name) and not screenVisible(name) then shownPopups[typ]=nil end
    end
    -- A map-selection/return/turn event is the fallback for an unknown mod popup
    -- that omits Processed. Never dismiss a still-visible native fullscreen UI.
    if mapReturn and not nativeScreen and not blocked.city and not blocked.mode and not blocked.bulk then
        shownPopups={};blocked.diplo=false
    end
    if contextHidden or nativeScreen then return true end
    for _,value in pairs(blocked) do if value then return true end end
    return next(shownPopups)~=nil
end
local function setModal(value)
    local present=modal
    if UIManager.IsModal then present=UIManager:IsModal(ContextPtr) end
    if present~=value then
        if value then UIManager:PushModal(ContextPtr) else UIManager:PopModal(ContextPtr) end
    end
    modal=value
end
local function rewards(s)
    return 'The Final Peak: '..s.finalTurns..' Golden Age turns; Pressure ends forever; +2 global Happiness; '
        ..'+10% Culture and +10% Great Person generation empire-wide; capital memorial +2 Culture / +4 Tourism. '
        ..'All current cities celebrate. Baseline brilliance and Moments of Magic continue.'
end
local function memoriesText(s)
    local lines={'THE JOURNEY REMEMBERS'}
    for _,m in ipairs(s.memories) do
        lines[#lines+1]='Turn '..m.turn..' | '..m.title..' — '..m.description
    end
    return table.concat(lines,'[NEWLINE][NEWLINE]')
end
local function refresh(obstructed,mapReturn)
    if rendering then return end
    rendering=true
    local s=uiState();local invisible=not s or obstructed or hidden(mapReturn)
    Controls.JourneyLauncher:SetHide(invisible or open or story~='')
    if invisible then
        Controls.JourneyPanel:SetHide(true);Controls.JourneyCinematic:SetHide(true);setModal(false)
        rendering=false;return
    end
    -- Rebuild a pending cinematic after reload or a temporarily obstructing screen.
    story=s.story or ''
    Controls.JourneyLauncher:SetHide(open or story~='')
    Controls.JourneyPanel:SetHide(not open or story~='')
    Controls.JourneyCinematic:SetHide(story=='')
    setModal(open or story~='')
    Controls.JourneyLauncher:SetText('THE JOURNEY | Dreams '..s.dreams..' | Act '..s.act)
    if story~='' then
        local w,h=UIManager:GetScreenSizeVal()
        Controls.JourneyCinematic:SetSizeVal(w,h);Controls.CinematicArt:SetSizeVal(w,h)
        Controls.CinematicShade:SetSizeVal(w,380)
        Controls.CinematicArt:SetTexture(story=='FINAL' and 'ParadiseFinalPeak.dds'
            or story=='RECOVERY' and 'ParadiseJourney.dds' or 'ParadiseHeartbreak.dds')
        Controls.CinematicAccent:SetColor(story=='FINAL' and Vector4(0.97,0.82,0.31,1) or Vector4(0.36,0.72,0.91,1))
        Controls.CinematicTitle:SetText(text(story..'_TITLE'))
        Controls.CinematicStory:SetText(text(story..'_STORY'))
        Controls.CinematicRewards:SetText(story=='FINAL' and rewards(s)
            or story=='DENIED' and ('Pressure '..s.pressure..' / 100. Recovery: -30 Pressure, +5 Dreams, a permanent Memory. '
                ..'El Potrero alternative: '..s.practiceTurns..' owner turns. Remaining: '
                ..(s.challenge and math.max(0,s.challenge.deadline-s.clock) or 0)..' turns.') or '')
        Controls.CinematicMemories:SetText(story=='FINAL' and memoriesText(s) or '')
        Controls.CinematicDetails:CalculateSize();Controls.CinematicDetails:ReprocessAnchoring()
        Controls.CinematicScroll:CalculateInternalSize()
    end
    if not open or story~='' then rendering=false;return end
    IconHookup(0,64,'PARADISE_ICON_ATLAS',Controls.JourneyEmblem)
    Controls.JourneyAccent:SetColor(s.fulfilled and Vector4(0.97,0.82,0.31,1) or Vector4(0.36,0.72,0.91,1))
    Controls.JourneyStatus:SetText('Act '..s.act..' | '..s.dreams..' Dreams | '..s.lifetime..' lifetime Dreams'
        ..(s.act>=2 and (' | Pressure '..s.pressure..' / 100') or ''))
    Controls.JourneyArt:SetTexture(s.fulfilled and 'ParadiseEpilogue.dds' or s.act==2 and 'ParadiseWeight.dds' or 'ParadiseJourney.dds')
    Controls.MagicStack:SetHide(selected~='MAGIC');rows:ResetInstances()
    Controls.JourneyHeading:SetText(text(selected=='PEAK' and 'PEAK' or selected))
    local body=''
    if selected=='OVERVIEW' then
        local acts={'HE WAS BEAUTIFUL','THE WEIGHT OF EXPECTATION','THE LAST DANCE'}
        body=(s.fulfilled and 'FULFILLED — THE BEAUTY REMAINS' or acts[s.act])..'[NEWLINE][NEWLINE]'
            ..'El Diez: '..(s.recoveryRemaining>=0 and ('returns in '..s.recoveryRemaining..' owner turns (waits for a free civilian slot)') or s.location)
            ..'[NEWLINE]Brilliance throughout the journey: +5% Great Person generation; +1 capital Culture. '
            ..'Inspiration: +2 city Culture, +2 Golden Age Points / owner turn and +10% local Great Person generation.'
        if s.act>=2 and not s.fulfilled then
            body=body..'[NEWLINE][NEWLINE]Pressure '..s.pressure..': '
                ..(s.pressure>=75 and '-10%' or s.pressure>=50 and '-5%' or 'No')..' Culture / Production penalty. '
                ..'Act II adds 1 Pressure every three scaled owner turns. First era achievements ease the burden.'
        end
        if s.challenge then body=body..'[NEWLINE][NEWLINE]RECOVERY: '..math.max(0,s.challenge.deadline-s.clock)
            ..' owner turns remaining. Begin a Golden Age, generate a Great Person, build a World Wonder or form a first alliance. '
            ..'Alternative: inspire an El Potrero city for '..s.practiceTurns..' owner turns; progress '..s.challenge.practice..' / '..s.practiceTurns..'.'
        elseif s.comebackDue then body=body..'[NEWLINE][NEWLINE]A new comeback opens in '..math.max(0,s.comebackDue-s.clock)..' owner turns.' end
        body=body..'[NEWLINE][NEWLINE]Final Peak: '..s.lifetime..' / 40 lifetime Dreams; '..s.objectiveCount..' / 3 distinct objectives.'
            ..'[NEWLINE]Dream rewards: Great Person 2; World Wonder 4; first Golden Age / era 3; '
            ..'first new alliance / era 2; first constructed El Potrero / era 1; recovery 5.'
    elseif selected=='MEMORIES' then
        body='Major milestones remain part of the story, across every era and every save.'
        local icons={magic=4,heartbreak=7,pressure=7,fulfillment=3,epilogue=3,potrero=1,wonder=2}
        for _,m in ipairs(s.memories) do
            local row=rows:GetInstance()
            IconHookup(icons[m.category] or 0,32,'PARADISE_OBJECT_ATLAS',row.MemoryIcon)
            row.MemoryTitle:SetText(m.title)
            row.MemoryText:SetText('Turn '..m.turn..' | '..eraName(m.era)..(m.city~='' and (' | '..m.city) or '')
                ..'[NEWLINE]'..m.description)
            row.MemoryRoot:CalculateSize();row.MemoryRoot:ReprocessAnchoring()
        end
    elseif selected=='MAGIC' then
        body='Hosting city: '..s.location..'. Each choice costs 6 Dreams; one choice per era. '
            ..'The same abilities remain available in all three acts and after fulfillment.'
        for _,entry in ipairs({{'PASS','Pass',4},{'HOPE','Hope',5},{'BEAUTY','Beauty',6}}) do
            local kind,prefix,icon=unpack(entry)
            IconHookup(icon,64,'PARADISE_OBJECT_ATLAS',Controls[prefix..'Icon'])
            Controls[prefix..'Button']:SetDisabled(not s.magic[kind].enabled)
            Controls[prefix..'Button']:SetToolTipString(s.magic[kind].reason)
        end
        Controls.PassDetails:SetText('A Pass Nobody Saw: '..s.science..' Science and '..s.culture..' Culture '
            ..'(1.5 city turns, minimum 10 each, capped at 250 + 100 per era index). '..s.magic.PASS.reason)
        Controls.HopeDetails:SetText('When All Hope Was Lost: +20% Production and +15% defense from buildings for '
            ..s.hopeTurns..' owner turns. A city transfer ends the effect. '..s.magic.HOPE.reason)
        Controls.BeautyDetails:SetText('The Beautiful Game: '..s.beautyPoints..' Golden Age Points; +10 Influence '
            ..'with up to two met, peaceful City-States, lowest nonnegative relations first. '..s.magic.BEAUTY.reason)
    else
        body=(s.fulfilled and rewards(s) or ('Reach the Modern Era; earn 40 lifetime Dreams ('..s.lifetime
            ..'); complete three objectives ('..s.objectiveCount..'). Dreams already spent still count. '
            ..'The Last Dance costs 450 base Production at Radio and is built normally in a city.'
            ..'[NEWLINE][NEWLINE]'..(s.eligible and 'THE LAST DANCE IS AVAILABLE FOR CONSTRUCTION' or 'Eligibility is still developing.')))
        for _,o in ipairs(s.objectives) do body=body..'[NEWLINE][NEWLINE]'
            ..(o.done and '[ICON_CHECKBOX]' or '[ICON_BULLET]')..' '..o.title..': '..o.progress end
        if s.fulfilled then body=body..'[NEWLINE][NEWLINE]The Dream Is Complete. The Beauty Remains. '
            ..'Continue toward a normal Civilization V victory. Dreams and magic continue.' end
    end
    Controls.JourneyBody:SetText(body);Controls.JourneyMessage:SetText(message)
    Controls.MemoryStack:CalculateSize();Controls.MemoryStack:ReprocessAnchoring()
    Controls.MagicStack:CalculateSize();Controls.MagicStack:ReprocessAnchoring()
    Controls.JourneyDetails:CalculateSize();Controls.JourneyDetails:ReprocessAnchoring()
    Controls.JourneyScroll:CalculateInternalSize()
    rendering=false
end
Controls.JourneyLauncher:RegisterCallback(Mouse.eLClick,function()open=true;refresh()end)
Controls.JourneyClose:RegisterCallback(Mouse.eLClick,function()open=false;refresh()end)
Controls.CinematicContinue:RegisterCallback(Mouse.eLClick,function()
    local r=runtime();local pending=story;story=''
    if r then r.AcknowledgeStory(Game.GetActivePlayer(),pending) end
    refresh()
end)
for _,entry in ipairs({{'OverviewTab','OVERVIEW'},{'MemoriesTab','MEMORIES'},{'MagicTab','MAGIC'},{'PeakTab','PEAK'}}) do
    local tab=entry[2]
    Controls[entry[1]]:RegisterCallback(Mouse.eLClick,function()selected=tab;message='';refresh()end)
end
for _,entry in ipairs({{'PassButton','PASS'},{'HopeButton','HOPE'},{'BeautyButton','BEAUTY'}}) do
    local kind=entry[2]
    Controls[entry[1]]:RegisterCallback(Mouse.eLClick,function()
        local r=runtime()
        if r then local ok;ok,message=r.UseMagic(Game.GetActivePlayer(),kind) end
        refresh()
    end)
end
LuaEvents.ParadiseChanged.Add(function(p)if p==Game.GetActivePlayer() then refresh()end end)
LuaEvents.ParadiseStory.Add(function(p)if p==Game.GetActivePlayer() then refresh()end end)
local function subscribe(name,handler) if Events[name] then Events[name].Add(handler) end end
local function returnToMap() refresh(false,true) end
subscribe('GameplaySetActivePlayer',function()
    open=false;story='';message='';blocked={};shownPopups={};closingScreens={};setModal(false);refresh()
end)
subscribe('ActivePlayerTurnStart',returnToMap)
subscribe('ActivePlayerTurnEnd',function()open=false;refresh()end)
subscribe('SerialEventEnterCityScreen',function()blocked.city=true;refresh(true)end)
subscribe('SerialEventExitCityScreen',function()blocked.city=false;returnToMap()end)
subscribe('AILeaderMessage',function()blocked.diplo=true;refresh(true)end)
subscribe('LeavingLeaderViewMode',function()blocked.diplo=false;returnToMap()end)
subscribe('SerialEventGameMessagePopup',function(info)
    local name=info and popupScreens[info.Type]
    if name then closingScreens[name]=nil end
    -- Requests can be ignored, toggled closed or processed synchronously by an
    -- earlier listener. Yield the modal now, but never create a sticky request.
    refresh(true)
end)
subscribe('SerialEventGameMessagePopupShown',function(info)
    local typ=info and info.Type or 'unknown'
    local name=popupScreens[typ];if name then closingScreens[name]=nil end
    shownPopups[typ]=true;refresh(true)
end)
subscribe('SerialEventGameMessagePopupProcessed',function(typ)
    shownPopups[typ or 'unknown']=nil
    -- Culture Overview emits Processed BEFORE DequeuePopup; Policy emits it
    -- on hide. Honor completion in either order without clearing other screens.
    local name=popupScreens[typ];if name then closingScreens[name]=true end
    refresh()
end)
subscribe('InterfaceModeChanged',function(old,current)
    blocked.mode=current~=InterfaceModeTypes.INTERFACEMODE_SELECTION
    refresh(false,not blocked.mode)
end)
subscribe('UnitSelectionChanged',function(p,id,x,y,z,selected)
    if p==Game.GetActivePlayer() and selected then returnToMap() end
end)
subscribe('SystemUpdateUI',function(typ)
    if typ==SystemUpdateUIType.BulkHideUI then blocked.bulk=true;refresh(true)
    elseif typ==SystemUpdateUIType.BulkShowUI then blocked.bulk=false;returnToMap() end
end)
ContextPtr:SetShowHideHandler(function(isHidden,initial)
    contextHidden=isHidden
    if isHidden then setModal(false) elseif not initial then returnToMap() end
end)
ContextPtr:SetShutdown(function()setModal(false)end)
ContextPtr:SetInputHandler(function(event,key)
    if event==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then
        if story~='' then return true end -- finale needs an explicit Continue acknowledgement
        if open then open=false;refresh();return true end
    end
    return false
end)
refresh()
