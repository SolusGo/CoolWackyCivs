include("IconSupport")
include("DualOrderRuntime")

local D = MapModData.DualOrder
local dirty, elapsed, iconReady = true, 0, false

local function refresh()
    dirty = false
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    local visible = player and player:IsAlive() and D.IsDualOrder(player)
        and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
    Controls.BalanceFrame:SetHide(not visible)
    if not visible then return end
    D.RefreshPlayer(playerID)
    if not iconReady then
        IconHookup(0, 32, "DUAL_ORDER_ICON_ATLAS", Controls.CivIcon)
        iconReady = true
    end
    local state = D.GetState(playerID)
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
