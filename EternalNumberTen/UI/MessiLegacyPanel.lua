local uiRecovery -- UI state is transient; never part of a gameplay save.
local uiRenderError
include('IconSupport')

local open, dirty, selected = false, true, 1
local chapterButtons = {
    Controls.Chapter1, Controls.Chapter2, Controls.Chapter3,
    Controls.Chapter4, Controls.Chapter5, Controls.Chapter6,
}

local function L(tag, ...)
    if Locale and Locale.ConvertTextKey then return Locale.ConvertTextKey(tag, ...) end
    return tag
end
local function active()
    local playerID = Game.GetActivePlayer()
    return playerID, Players[playerID]
end
local function eraText(chapter)
    if not chapter or chapter.era == nil or chapter.era < 0 then return L('TXT_KEY_MESSI_ERA_ANY') end
    local row = GameInfo.Eras[chapter.era]
    return row and L(row.Description) or tostring(chapter.era)
end
local function selectChapter(index)
    selected, dirty = index, true
end
for index, button in ipairs(chapterButtons) do
    button:RegisterCallback(Mouse.eLClick, function() selectChapter(index) end)
end

local function refresh()
 local function draw()
 if uiRecovery then uiRecovery:Sync() end
    if not dirty then return end
    dirty = false
    local playerID, player = active()
    local runtime = MapModData and MapModData.MessiLegacy or nil
    local state = player and runtime and runtime.GetUIState and runtime.GetUIState(playerID) or nil
    local visible = state ~= nil
 visible=visible and (not uiRecovery or uiRecovery:Available())
 Controls.LauncherFrame:SetHide(not visible)
    Controls.MainPanel:SetHide(not visible or not open)
    if not visible then return end
    IconHookup(0, 32, 'MESSI_ICON_ATLAS', Controls.LauncherIcon)
    IconHookup(0, 64, 'MESSI_ICON_ATLAS', Controls.CivIcon)
    Controls.LauncherButton:SetText(L('TXT_KEY_MESSI_UI_LAUNCHER') .. '  ' .. state.legacy)
    if state.nextChapter then
        Controls.LegacyLabel:SetText(L('TXT_KEY_MESSI_UI_CURRENT', state.legacy, state.nextChapter.threshold))
        Controls.NextLabel:SetText(L('TXT_KEY_MESSI_UI_NEXT', L(state.nextChapter.title))
            .. '[NEWLINE]' .. L('TXT_KEY_MESSI_UI_REQUIRES', eraText(state.nextChapter)))
    else
        Controls.LegacyLabel:SetText(L('TXT_KEY_MESSI_UI_COMPLETE', state.legacy))
        Controls.NextLabel:SetText(L('TXT_KEY_MESSI_EPILOGUE_EFFECTS'))
    end
    Controls.GoldenStar:SetHide(not state.unlocked[6])
    Controls.GoldenStar:SetText(L('TXT_KEY_MESSI_UI_GOLDEN_STAR'))
    Controls.HistoryLabel:SetText(L('TXT_KEY_MESSI_UI_HISTORY', state.epilogue, state.tourism))
    for index, button in ipairs(chapterButtons) do
        local chapter = runtime.GetChapter(index)
        local status = state.unlocked[index] and L('TXT_KEY_MESSI_UI_UNLOCKED') or L('TXT_KEY_MESSI_UI_LOCKED')
        local marker = index == selected and '[ICON_CHECKBOX] ' or ''
        button:SetText(marker .. L(chapter.title) .. '[NEWLINE]' .. status .. '  •  ' .. chapter.threshold)
    end
    local chapter = runtime.GetChapter(selected)
    Controls.ChapterTitle:SetText(L(chapter.title))
    Controls.ChapterRequirement:SetText(chapter.threshold .. ' Legacy  •  ' .. eraText(chapter))
    Controls.ChapterEffects:SetText(L(chapter.effects))
    Controls.ChapterStory:SetText(L(chapter.story))
 end
 local ok,err=pcall(draw)
 if not ok then
  dirty=true
  Controls.MainPanel:SetHide(true)
  if uiRenderError~=tostring(err) then print("[Civilization UI] EternalNumberTen render recovered: "..tostring(err)) end
  uiRenderError=tostring(err)
 else uiRenderError=nil end
end

Controls.LauncherButton:RegisterCallback(Mouse.eLClick, function() open, dirty = not open, true end)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, function() open, dirty = false, true end)
Controls.CloseButton:SetText(L('TXT_KEY_MESSI_UI_CLOSE'))
Controls.HeaderLabel:SetText(L('TXT_KEY_MESSI_UI_HEADER'))
Controls.SubtitleLabel:SetText(L('TXT_KEY_MESSI_UI_SUBTITLE'))

local function markDirty() dirty = true end
if LuaEvents and LuaEvents.MessiLegacyChanged then LuaEvents.MessiLegacyChanged.Add(markDirty) end
Events.SerialEventGameDataDirty.Add(markDirty)
Events.GameplaySetActivePlayer.Add(function() open, selected, dirty = false, 1, true end)
Events.ActivePlayerTurnStart.Add(markDirty)
Events.ActivePlayerTurnEnd.Add(function() open, dirty = false, true end)
ContextPtr:SetInputHandler(function(uiMsg, key)
 if uiRecovery and not uiRecovery:Available() then return false end
    if open and uiMsg == KeyEvents.KeyDown and key == Keys.VK_ESCAPE then open, dirty = false, true; return true end
    return false
end)
local elapsed = 0
ContextPtr:SetUpdate(function(dt)
    elapsed = elapsed + dt
    if dirty and elapsed >= 0.15 then elapsed = 0; refresh() end
end)
refresh()

-- Shared screen recovery: actual native visibility wins over stale event flags.
local helperLoaded=pcall(include,'CWC_Screen')
if CWC_Screen then
 uiRecovery=CWC_Screen.New{name='EternalNumberTen',civ='CIVILIZATION_ETERNAL_NUMBER_TEN',context=ContextPtr,
  roots={Controls.LauncherFrame,Controls.MainPanel},panels={Controls.MainPanel},
  request=function() dirty=true end,
  refresh=function() dirty=true;refresh() end,
  recover=function()  end,repair=function() dirty=true end,
  close=function() open=false end,manageContext=true}
 uiRecovery:Refresh(true)
end
