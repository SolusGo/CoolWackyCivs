include("IconSupport")

local iconReady = false
local fills = {Controls.Fill1,Controls.Fill2,Controls.Fill3,Controls.Fill4,Controls.Fill5,
    Controls.Fill6,Controls.Fill7,Controls.Fill8,Controls.Fill9,Controls.Fill10}

local function refresh()
    local M = MapModData and MapModData.MasayaKid or nil
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    local visible = player and player:IsAlive() and M and M.IsMasaya and M.GetUIState
        and M.IsMasaya(player)
        and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
    Controls.JoyFrame:SetHide(not visible)
    if not visible then return end
    if not iconReady then
        IconHookup(3, 32, "MASAYA_KID_OBJECT_ATLAS", Controls.JoyIcon)
        iconReady = true
    end
    local state = M.GetUIState(playerID)
    if not state then Controls.JoyFrame:SetHide(true); return end
    Controls.JoyLabel:SetText("JOY OF FLIGHT  |  " .. state.joy .. " / 100")
    local filled = math.floor(state.joy / 10)
    for index, control in ipairs(fills) do control:SetHide(index > filled) end
    if state.beyond then
        Controls.StateLabel:SetText("BEYOND THE SKY  |  " .. state.turns .. " TURNS REMAINING")
    elseif state.cantStop then
        Controls.StateLabel:SetText("CAN'T STOP FLYING")
    else
        Controls.StateLabel:SetText("BUILD JOY THROUGH FLIGHT")
    end
    Controls.JoyFrame:SetToolTipString(
        "Joy comes from revealed tiles first recorded during Masaya movement, combat XP, promotions, strong opponents, " ..
        "Level 4 units, Junior FC Prodigy combats, and garrisoned Grav-Shoe Practice Rooms. " ..
        "At 50 Joy, Can't Stop Flying activates. At 100 Joy, Beyond the Sky lasts 6 turns.")
end

local function stateChanged(playerID)
    if playerID == Game.GetActivePlayer() then refresh() end
end
if LuaEvents and LuaEvents.MasayaKidStateChanged then
    LuaEvents.MasayaKidStateChanged.Add(stateChanged)
end
Events.SerialEventGameDataDirty.Add(refresh)
Events.SerialEventUnitInfoDirty.Add(refresh)
Events.GameplaySetActivePlayer.Add(refresh)
Events.ActivePlayerTurnStart.Add(refresh)
refresh()
