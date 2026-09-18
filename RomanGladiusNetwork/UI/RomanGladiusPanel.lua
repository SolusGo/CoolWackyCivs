include("InstanceManager")
include("IconSupport")
include("RomanGladiusRuntime")

local R = MapModData.RomanGladiusNetwork
local entries = InstanceManager:new("RomanGladiusServerEntry", "ServerButton", Controls.ServerStack)
local open, dirty, refreshing, iconsReady = false, true, false, false
local selectedID, message = nil, ""

local function active()
    local playerID = Game.GetActivePlayer()
    return playerID, Players[playerID]
end
local function hookupIcons()
    if iconsReady then return end
    iconsReady = true
    IconHookup(0, 32, "ROMAN_GLADIUS_ICON_ATLAS", Controls.LauncherIcon)
    IconHookup(0, 64, "ROMAN_GLADIUS_ICON_ATLAS", Controls.CivIcon)
end
local function linesText(lines, fallback, limit)
    if #lines == 0 then return fallback end
    local result = {}
    for index = 1, math.min(limit or #lines, #lines) do result[#result + 1] = lines[index] end
    return table.concat(result, "[NEWLINE]")
end
local function rosterText(city)
    local roster, result = R.GetRoster(city), {}
    for index = 1, math.min(6, #roster) do
        local player = roster[index]
        result[#result + 1] = player.name .. " — " .. player.role .. " / " .. player.trait
    end
    if city:GetPopulation() > 6 then result[#result + 1] = "+ " .. (city:GetPopulation() - 6) .. " more Players" end
    return table.concat(result, "[NEWLINE]")
end
local function selectedServer(servers)
    if selectedID then
        for _, server in ipairs(servers) do if server.id == selectedID then return server end end
    end
    if servers[1] then selectedID = servers[1].id end
    return servers[1]
end
local function buttonAction(callback)
    local playerID = active()
    if not selectedID then return end
    local ok, result = callback(playerID, selectedID)
    message = result or (ok and "Done." or "Action failed.")
    dirty = true
end
local function resolve(choice)
    buttonAction(function(playerID, cityID) return R.ResolveEvent(playerID, cityID, choice) end)
end

local function refresh()
    if refreshing then return end
    refreshing, dirty = true, false
    local playerID, player = active()
    local visible = player and player:IsAlive() and R.IsRoman(player)
        and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
    Controls.LauncherFrame:SetHide(not visible)
    Controls.MainPanel:SetHide(not visible or not open)
    if not visible then refreshing = false; return end
    hookupIcons()
    R.RefreshPlayer(playerID)
    local network = R.GetNetworkState(playerID)
    Controls.DashboardButton:SetText("OPEN NETWORK DASHBOARD  |  " .. network.population
        .. " PLAYERS  |  " .. network.incidents .. " INCIDENTS")
    Controls.DashboardButton:SetToolTipString("Manage every Server, staff team, Reputation band, chat log, and active incident.")
    if not open then refreshing = false; return end
    Controls.StatsLabel:SetText(network.servers .. " Servers Online  |  " .. network.population .. " Players  |  "
        .. network.moderators .. " Mods  |  " .. network.administrators .. " Admins[NEWLINE]"
        .. "Network Reputation " .. network.reputation .. "  |  " .. network.banned .. " Players Banned")
    local servers = R.GetServers(playerID)
    local server = selectedServer(servers)
    entries:ResetInstances()
    for _, item in ipairs(servers) do
        local entry, captured = entries:GetInstance(), item
        local state = captured.state
        local incident = state.eventInfo and "  [COLOR_NEGATIVE_TEXT]![ENDCOLOR]" or ""
        entry.ServerButton:SetText((captured.id == selectedID and "[ICON_CHECKBOX] " or "")
            .. captured.name .. "[NEWLINE]" .. state.population .. " Players  |  "
            .. state.reputation .. " " .. state.band .. incident)
        entry.ServerButton:SetToolTipString(state.activity .. " | " .. state.staffStatus
            .. " | " .. state.moderators .. " Moderators | " .. state.admin .. " Administrator")
        entry.ServerButton:RegisterCallback(Mouse.eLClick, function()
            selectedID, message, dirty = captured.id, "", true
        end)
    end
    Controls.ServerStack:CalculateSize()
    Controls.ServerStack:ReprocessAnchoring()
    Controls.ServerScroll:CalculateInternalSize()
    if not server then refreshing = false; return end
    local state, city = server.state, server.city
    Controls.ServerName:SetText(server.name)
    Controls.ServerStatus:SetText(state.population .. " Players  |  Reputation " .. state.reputation .. " — "
        .. state.band .. "  |  " .. state.activity .. "[NEWLINE]" .. state.staffStatus
        .. (state.opening and "  |  GRAND OPENING" or "") .. (state.peak and "  |  PEAK HOURS" or ""))
    Controls.StaffLabel:SetText(state.moderators .. " Moderators  |  " .. state.admin
        .. " Administrator  |  Recommended: about 1 staff per 4–6 Players")
    Controls.PromoteModButton:SetText("PROMOTE MODERATOR  |  " .. (75 + state.moderators * 25) .. " [ICON_GOLD]")
    Controls.PromoteAdminButton:SetText("PROMOTE ADMIN  |  150 [ICON_GOLD]")
    Controls.PromoteModButton:SetDisabled(not state.hasConsole or state.population < 4)
    Controls.PromoteAdminButton:SetDisabled(not state.hasConsole or state.population < 8 or state.moderators < 1 or state.admin > 0)
    Controls.DemoteModButton:SetDisabled(state.moderators < 1)
    Controls.DemoteAdminButton:SetDisabled(state.admin < 1)
    Controls.RosterLabel:SetText(rosterText(city))
    Controls.ChatLabel:SetText(linesText(R.GetChat(city), "[RomanGladius] Server online.", 5))
    local event = state.eventInfo
    Controls.EventCard:SetHide(event == nil)
    Controls.QuietCard:SetHide(event ~= nil)
    if event then
        Controls.EventTitle:SetText("ACTIVE INCIDENT  |  " .. event.name)
        Controls.EventText:SetText(event.chat)
        Controls.EventOption1:SetText(event.options[1])
        Controls.EventOption2:SetText(event.options[2])
        Controls.EventOption3:SetText(event.options[3])
    else
        Controls.LogLabel:SetText(linesText(R.GetLogs(city), "No incidents recorded. Knowledge keeps the Server alive.", 3))
    end
    Controls.MessageLabel:SetText(message)
    refreshing = false
end

Controls.DashboardButton:RegisterCallback(Mouse.eLClick, function() open = not open; dirty = true end)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, function() open = false; dirty = true end)
Controls.PromoteModButton:RegisterCallback(Mouse.eLClick, function() buttonAction(R.PromoteModerator) end)
Controls.PromoteAdminButton:RegisterCallback(Mouse.eLClick, function() buttonAction(R.PromoteAdministrator) end)
Controls.DemoteModButton:RegisterCallback(Mouse.eLClick, function() buttonAction(R.DemoteModerator) end)
Controls.DemoteAdminButton:RegisterCallback(Mouse.eLClick, function() buttonAction(R.DemoteAdministrator) end)
Controls.EventOption1:RegisterCallback(Mouse.eLClick, function() resolve(1) end)
Controls.EventOption2:RegisterCallback(Mouse.eLClick, function() resolve(2) end)
Controls.EventOption3:RegisterCallback(Mouse.eLClick, function() resolve(3) end)

local function markDirty() dirty = true end
if LuaEvents and LuaEvents.RomanGladiusStateChanged then LuaEvents.RomanGladiusStateChanged.Add(markDirty) end
Events.SerialEventGameDataDirty.Add(markDirty)
Events.SerialEventUnitInfoDirty.Add(markDirty)
Events.GameplaySetActivePlayer.Add(function() open, selectedID, message = false, nil, ""; dirty = true end)
Events.ActivePlayerTurnStart.Add(markDirty)
Events.ActivePlayerTurnEnd.Add(function() open = false; dirty = true end)
ContextPtr:SetInputHandler(function(uiMsg, key)
    if open and uiMsg == KeyEvents.KeyDown and key == Keys.VK_ESCAPE then open = false; dirty = true; return true end
    return false
end)
local elapsed = 0
ContextPtr:SetUpdate(function(dt)
    elapsed = elapsed + dt
    if dirty and elapsed >= 0.15 then elapsed = 0; refresh() end
end)
refresh()
