include('IconSupport')
include('InstanceManager')
include('TokenRuntime')
local T=MapModData.TokenizedIntelligence
local categories=InstanceManager:new('TokenCategory','CategoryButton',Controls.CategoryStack)
local prompts=InstanceManager:new('TokenPrompt','PromptButton',Controls.PromptStack)
local targets=InstanceManager:new('TokenTarget','TargetButton',Controls.TargetStack)
local categoryList={'ECONOMIC','RESEARCH','MILITARY','GOVERNANCE','ADVANCED','ADAPTIVE','CONTEXT'}
local opened,cityView,leaderView,refreshing=false,false,false,false
local popups={}
local category,chosen,target,message='ECONOMIC',nil,nil,''
local function worldView()
    return not cityView and not leaderView and next(popups)==nil
        and not (UI and UI.IsCityScreenUp and UI.IsCityScreenUp())
end
local refresh
local function promptTooltip(pid,spec)
    local cost,cached=T.Cost(pid,spec.id)
    return spec.help..'[NEWLINE]Normal Cost: '..(spec.cost==0 and 0 or T.Scale(spec.cost*(T.Era(pid)>=6 and 0.9 or 1)))
        ..' Tokens[NEWLINE]Current Cost: '..cost..' Tokens'..(cached and ' — Cached Response' or '')
        ..(spec.duration and '[NEWLINE]Duration: '..T.Scale(spec.duration)..' turns. Uses one persistent Prompt slot.' or '')
        ..(spec.capacity and '[NEWLINE]Requires: '..T.Scale(spec.capacity)..' Context capacity.' or '')
end
refresh=function()
    if refreshing then return end
    refreshing=true
    local pid=Game.GetActivePlayer()
    local visible=T.IsToken(pid) and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer()) and worldView()
    Controls.Launcher:SetHide(not visible)
    Controls.Panel:SetHide(not visible or not opened)
    if not visible then refreshing=false;return end
    local stats=T.Stats(pid)
    Controls.Status:SetText('Tokens: '..T.Tokens(pid)..' / '..stats.capacity..' (+'..stats.income..') | PROMPTS')
    Controls.Status:SetToolTipString(T.Tooltip(pid))
    IconHookup(0,24,'TOKEN_OBJECT_ATLAS',Controls.TokenIcon)
    if not opened then refreshing=false;return end
    IconHookup(0,64,'TOKEN_ICON_ATLAS',Controls.Emblem)
    Controls.Summary:SetText(T.Model(pid)..' | '..T.Tokens(pid)..' / '..stats.capacity..' Tokens (+'..stats.income..'/turn)')
    Controls.Summary:SetToolTipString(T.Tooltip(pid))
    categories:ResetInstances()
    for _,name in ipairs(categoryList) do
        local value=name;local row=categories:GetInstance()
        row.CategoryButton:SetText((category==value and '[ICON_CHECKBOX] ' or '')..value)
        row.CategoryButton:RegisterCallback(Mouse.eLClick,function() category=value;chosen,target=nil,nil;message='';refresh() end)
    end
    Controls.CategoryStack:CalculateSize();Controls.CategoryStack:ReprocessAnchoring()
    prompts:ResetInstances()
    for _,spec in ipairs(T.Prompts) do
        if spec.category==category then
            local action=spec;local row=prompts:GetInstance()
            local availableTargets=T.Targets(pid,action.id)
            local previewTarget=action.id==chosen and target or nil
            if not previewTarget and availableTargets[1] then previewTarget=availableTargets[1].id end
            local ok,reason=T.Check(pid,action.id,previewTarget)
            -- A full Context may allow refreshing a targeted effect on a city
            -- other than the first city. Keep that Prompt selectable.
            if not ok and action.target then
                for _,entry in ipairs(availableTargets) do
                    if T.Check(pid,action.id,entry.id) then ok=true;reason='Choose an eligible owned target.';break end
                end
            end
            local cost,cached=T.Cost(pid,action.id)
            row.Name:SetText((chosen==action.id and '[ICON_CHECKBOX] ' or '')..action.name)
            row.Cost:SetText(cost..' Tokens'..(cached and ' | CACHED RESPONSE' or '')..(not ok and ' | Unavailable — hover for reason' or ''))
            row.PromptButton:SetDisabled(not ok)
            row.PromptButton:SetToolTipString(promptTooltip(pid,action)..(not ok and '[NEWLINE]'..reason or ''))
            IconHookup(action.icon,32,'TOKEN_OBJECT_ATLAS',row.Icon)
            row.PromptButton:RegisterCallback(Mouse.eLClick,function() chosen=action.id;target=nil;message='';refresh() end)
        end
    end
    Controls.PromptStack:CalculateSize();Controls.PromptStack:ReprocessAnchoring();Controls.PromptScroll:CalculateInternalSize()
    local spec
    for _,candidate in ipairs(T.Prompts) do if candidate.id==chosen then spec=candidate;break end end
    targets:ResetInstances()
    Controls.PromptIcon:SetHide(spec==nil)
    Controls.PromptTitle:SetText(spec and spec.name or 'Choose a Prompt')
    Controls.Description:SetText(spec and promptTooltip(pid,spec) or 'Choose a category and a Prompt. Select an owned target below when needed. Unavailable Prompts stay visible; hover to see their requirements.')
    if spec then
        IconHookup(spec.icon,45,'TOKEN_OBJECT_ATLAS',Controls.PromptIcon)
        for _,entry in ipairs(T.Targets(pid,spec.id)) do
            local item=entry;local row=targets:GetInstance()
            row.TargetButton:SetText((target==item.id and '[ICON_CHECKBOX] ' or '')..item.name)
            row.TargetButton:RegisterCallback(Mouse.eLClick,function() target=item.id;message='';refresh() end)
        end
    end
    Controls.TargetStack:CalculateSize();Controls.TargetStack:ReprocessAnchoring();Controls.TargetScroll:CalculateInternalSize()
    local active={}
    for _,e in ipairs(T.Active(pid)) do
        local name=e.name
        for _,candidate in ipairs(T.Prompts) do if candidate.id==e.name then name=candidate.name end end
        active[#active+1]=name..' ('..(e.expiry-T.Get(pid,'clock'))..' turns)'
    end
    Controls.Active:SetText('Active '..#active..' / '..T.Limit(pid)..': '..(#active>0 and table.concat(active,'; ') or 'none'))
    local ok,reason=false,'Choose a Prompt.'
    if spec then ok,reason=T.Check(pid,spec.id,target) end
    Controls.Execute:SetDisabled(not ok)
    Controls.Execute:SetText(spec and 'EXECUTE '..spec.name:upper()..' — '..T.Cost(pid,spec.id)..' TOKENS' or 'EXECUTE PROMPT')
    Controls.Execute:SetToolTipString(reason)
    Controls.Message:SetText(message~='' and message or reason)
    refreshing=false
end
Controls.Status:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;refresh() end)
Controls.Execute:RegisterCallback(Mouse.eLClick,function()
    local pid=Game.GetActivePlayer()
    if not worldView() then return end
    local ok,result=T.Use(pid,chosen,target)
    message=result;refresh()
end)
ContextPtr:SetInputHandler(function(msg,key)
    if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then opened=false;refresh();return true end
    return false
end)
LuaEvents.TokenStateChanged.Add(function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
Events.LoadScreenClose.Add(refresh)
Events.GameplaySetActivePlayer.Add(function() opened=false;chosen,target=nil,nil;refresh() end)
Events.ActivePlayerTurnStart.Add(refresh)
Events.ActivePlayerTurnEnd.Add(function() opened=false;refresh() end)
Events.SerialEventGameDataDirty.Add(function() T.Invalidate(Game.GetActivePlayer());refresh() end)
Events.SerialEventCityInfoDirty.Add(function() T.Invalidate(Game.GetActivePlayer());refresh() end)
Events.SerialEventUnitInfoDirty.Add(function() if opened then refresh() end end)
Events.SerialEventEnterCityScreen.Add(function() cityView=true;opened=false;refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityView=false;refresh() end)
Events.AILeaderMessage.Add(function() leaderView=true;opened=false;refresh() end)
Events.LeavingLeaderViewMode.Add(function() leaderView=false;refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function(info)
    if info and info.Type then popups[info.Type]=true;opened=false;refresh() end
end)
Events.SerialEventGameMessagePopupProcessed.Add(function(typ) popups[typ]=nil;refresh() end)
refresh()
