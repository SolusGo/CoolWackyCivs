local uiRecovery -- UI state is transient; never part of a gameplay save.
local uiRenderError
include("IconSupport")
include("DualOrderRuntime")

local D = MapModData.DualOrder
local dirty, elapsed, iconReady = true, 0, false

local function refresh()
 local function draw()
 if uiRecovery then uiRecovery:Sync() end
    dirty = false
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    local visible = player and player:IsAlive() and D.IsDualOrder(player)
        and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
 visible=visible and (not uiRecovery or uiRecovery:Available())
 Controls.BalanceFrame:SetHide(not visible)
    if not visible then return end
    D.RefreshPlayer(playerID)
    if not iconReady then
        IconHookup(0, 32, "DUAL_ORDER_ICON_ATLAS", Controls.CivIcon)
        iconReady = true
    end
    local state = D.GetState(playerID)
    Controls.PressureReadout:SetText("Faith: "..tostring(state.faith).."  |  Strength +"..state.combat.."%  |  Production +"..state.production.."%")
    Controls.PressureFill:SetSizeX(math.max(1,math.floor(440*math.min(5,state.wars)/5)))
    if state.active then
        Controls.BalanceLabel:SetText("BALANCE PRESSURE  |  " .. state.wars .. "/5 WARS  |  +"
            .. state.combat .. "% [ICON_STRENGTH]  +" .. state.production .. "% [ICON_PRODUCTION]")
        Controls.BalanceFrame:SetToolTipString("Active: positive Faith per turn and " .. state.wars
            .. " active war(s). Combat Strength +" .. state.combat .. "% and Production in all Cities +"
            .. state.production .. "%. Faith per turn: " .. state.faith .. ".")
    elseif state.wars == 0 then
        Controls.BalanceLabel:SetText("BALANCE PRESSURE  |  AT PEACE")
        Controls.BalanceFrame:SetToolTipString("Inactive: The Dual Order is not at war. Faith per turn: " .. state.faith .. ".")
    else
        Controls.BalanceLabel:SetText("BALANCE PRESSURE  |  FAITH REQUIRED")
        Controls.BalanceFrame:SetToolTipString("Inactive: Faith per turn must be positive. Active wars: "
            .. state.wars .. ". Faith per turn: " .. state.faith .. ".")
    end
 end
 local ok,err=pcall(draw)
 if not ok then
  dirty=true

  if uiRenderError~=tostring(err) then print("[Civilization UI] DualOrder render recovered: "..tostring(err)) end
  uiRenderError=tostring(err)
 else uiRenderError=nil end
end

local function markDirty() dirty = true end
if LuaEvents and LuaEvents.DualOrderStateChanged then LuaEvents.DualOrderStateChanged.Add(markDirty) end
Events.SerialEventGameDataDirty.Add(markDirty)
Events.SerialEventUnitInfoDirty.Add(markDirty)
Events.GameplaySetActivePlayer.Add(markDirty)
Events.ActivePlayerTurnStart.Add(markDirty)
ContextPtr:SetUpdate(function(dt)
    elapsed = elapsed + dt
    if dirty and elapsed >= 0.15 then elapsed = 0; refresh() end
end)
refresh()

-- Shared screen recovery: actual native visibility wins over stale event flags.
local helperLoaded=pcall(include,'CWC_Screen')
if CWC_Screen then
 uiRecovery=CWC_Screen.New{name='DualOrder',civ='CIVILIZATION_DUAL_ORDER',context=ContextPtr,
  roots={Controls.BalanceFrame},panels={},
  request=function() dirty=true end,
  refresh=function() dirty=true;refresh() end,
  recover=function()  end,repair=function() dirty=true end,
  close=function()  end,manageContext=true}
 uiRecovery:Refresh(true)
end
