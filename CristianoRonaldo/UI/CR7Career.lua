-- UI-only: no polling, gameplay handlers, save writes, or gameplay mutations.
include('IconSupport')
local selected,open=1,false
local blocked={}
local queue={}
local function text(key) return Locale.ConvertTextKey(key) end
local function tag(n,suffix) return 'TXT_KEY_CR7_CHAPTER_'..n..'_'..suffix end
local function fmt(n) return n==math.floor(n) and tostring(n) or string.format('%.2f',n) end
local function state()
    local runtime=MapModData.CR7
    return runtime and runtime.GetUIState and runtime.GetUIState(Game.GetActivePlayer())
end
local function eraName(n)
    local row=GameInfo.Eras[n]
    return row and text(row.Description) or tostring(n)
end
local function invisible() for _,value in pairs(blocked) do if value then return true end end return false end
local function refresh()
    local s=state()
    local hidden=not s or invisible()
    Controls.Launcher:SetHide(hidden)
    Controls.Career:SetHide(hidden or not open)
    Controls.UnlockPopup:SetHide(hidden or #queue==0)
    if hidden then return end
    IconHookup(0,64,'CR7_ICON_ATLAS',Controls.Emblem)
    local nextChapter=s.chapter+1
    local target=nextChapter<=7 and fmt(s.thresholds[nextChapter]) or 'LEGACY'
    Controls.Launcher:SetText('CR7 | Ambition: '..fmt(s.ambition)..' / '..target..' | Chapter '..s.chapter)
    if nextChapter<=7 then
        Controls.Progress:SetText('Next: '..text(tag(nextChapter,'TITLE'))..' | '..fmt(s.ambition)..' / '..target
            ..' Ambition ('..math.min(100,math.floor(s.ambition/s.thresholds[nextChapter]*100))..'%) | '..eraName(s.eras[nextChapter]))
    else Controls.Progress:SetText('All seven Career Chapters complete | Ambition: '..fmt(s.ambition)) end
    for n=1,7 do
        Controls['Chapter'..n]:SetText(text(tag(n,'TITLE'))..'[NEWLINE]'
            ..(s.unlocked[n] and '[ICON_CHECKBOX] COMPLETED' or 'LOCKED')..' | '..fmt(s.thresholds[n]))
    end
    Controls.ChapterTitle:SetText(text(tag(selected,'TITLE')))
    Controls.Requirement:SetText(fmt(s.thresholds[selected])..' Ambition | '..eraName(s.eras[selected])
        ..' | '..(s.unlocked[selected] and 'COMPLETED' or 'LOCKED'))
    IconHookup(14+selected,64,'CR7_OBJECT_ATLAS',Controls.ChapterImage)
    Controls.Story:SetText(text(tag(selected,'STORY')))
    Controls.Effects:SetText(text(tag(selected,'EFFECTS')))
    Controls.Details:CalculateSize();Controls.Details:ReprocessAnchoring()
    Controls.ChapterList:CalculateSize();Controls.ChapterList:ReprocessAnchoring()
    Controls.DetailScroll:CalculateInternalSize();Controls.ChapterScroll:CalculateInternalSize()
    Controls.Legacy:SetText(s.chapter==7 and ('The Story Is Still Being Written: '..fmt(s.legacyProgress)..' / '
        ..fmt(s.legacyStep)..' additional Ambition | '..s.legacy..' rewards completed[NEWLINE]Permanent: +'
        ..math.min(5,s.legacy)..'% Military Production and +'..math.min(5,s.legacy)..'% Tourism')
        or 'Earned chapters and veteran development remain permanent. Select a chapter to inspect its history and bonuses.')
    if #queue>0 then
        local n=queue[1]
        IconHookup(14+n,80,'CR7_OBJECT_ATLAS',Controls.UnlockIcon)
        Controls.UnlockTitle:SetText('CAREER CHAPTER '..n..' | '..text(tag(n,'TITLE')))
        Controls.UnlockStory:SetText(text(tag(n,'STORY')))
        Controls.UnlockEffects:SetText(text(tag(n,'EFFECTS')))
        Controls.UnlockDetails:CalculateSize();Controls.UnlockDetails:ReprocessAnchoring()
        Controls.UnlockScroll:CalculateInternalSize()
    end
end
for n=1,7 do
    local chapterIndex=n
    Controls['Chapter'..n]:RegisterCallback(Mouse.eLClick,function()selected=chapterIndex;refresh()end)
end
Controls.Launcher:RegisterCallback(Mouse.eLClick,function()open=not open;refresh()end)
Controls.Close:RegisterCallback(Mouse.eLClick,function()open=false;refresh()end)
Controls.UnlockClose:RegisterCallback(Mouse.eLClick,function()table.remove(queue,1);refresh()end)
LuaEvents.CR7Changed.Add(function(p) if p==Game.GetActivePlayer() then refresh() end end)
LuaEvents.CR7ChapterUnlocked.Add(function(p,n)
    if p==Game.GetActivePlayer() and Players[p]:IsHuman() then queue[#queue+1]=n;refresh() end
end)
local function subscribe(name,handler) if Events[name] then Events[name].Add(handler) end end
subscribe('GameplaySetActivePlayer',function()open=false;queue={};refresh()end)
subscribe('ActivePlayerTurnStart',refresh)
subscribe('ActivePlayerTurnEnd',function()open=false;refresh()end)
subscribe('SerialEventEnterCityScreen',function()blocked.city=true;refresh()end)
subscribe('SerialEventExitCityScreen',function()blocked.city=false;refresh()end)
subscribe('AILeaderMessage',function()blocked.diplo=true;refresh()end)
subscribe('LeavingLeaderViewMode',function()blocked.diplo=false;refresh()end)
local function popupShown(info)
    local popupType=info and info.Type or 'unknown'
    blocked['popup|'..popupType]=true;refresh()
end
subscribe('SerialEventGameMessagePopup',popupShown)
subscribe('SerialEventGameMessagePopupShown',popupShown)
subscribe('SerialEventGameMessagePopupProcessed',function(popupType)
    blocked['popup|'..(popupType or 'unknown')]=nil;refresh()
end)
subscribe('InterfaceModeChanged',function(previous,current)
    blocked.mode=InterfaceModeTypes and current~=InterfaceModeTypes.INTERFACEMODE_SELECTION
    refresh()
end)
ContextPtr:SetInputHandler(function(message,key)
    if message==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then
        if #queue>0 then table.remove(queue,1);refresh();return true end
        if open then open=false;refresh();return true end
    end
    return false
end)
refresh()
