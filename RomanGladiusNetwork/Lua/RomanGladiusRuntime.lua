-- RomanGladius Network: per-Server population yields, staff, Reputation, events, logs, and milestones.
if MapModData.RomanGladiusNetwork and MapModData.RomanGladiusNetwork.Loaded then return end
MapModData.RomanGladiusNetwork = MapModData.RomanGladiusNetwork or {}
local R = MapModData.RomanGladiusNetwork

local save = Modding.OpenSaveData()
local CIV = GameInfoTypes.CIVILIZATION_ROMAN_GLADIUS_NETWORK
local OWNER = GameInfoTypes.UNIT_ROMAN_GLADIUS_SERVER_OWNER
local CONSOLE = GameInfoTypes.BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE
local settlerPopulationOption = Game.IsCustomModOption
    and Game.IsCustomModOption("BALANCE_SETTLERS_CONSUME_POPULATION")
local SETTLERS_CONSUME_POPULATION = settlerPopulationOption == true or settlerPopulationOption == 1
local B = {
    gold = GameInfoTypes.BUILDING_ROMAN_GLADIUS_PLAYER_GOLD,
    science = GameInfoTypes.BUILDING_ROMAN_GLADIUS_PLAYER_SCIENCE,
    culture = GameInfoTypes.BUILDING_ROMAN_GLADIUS_PLAYER_CULTURE,
    moderator = GameInfoTypes.BUILDING_ROMAN_GLADIUS_MODERATOR,
    legendary = GameInfoTypes.BUILDING_ROMAN_GLADIUS_LEGENDARY,
    thriving = GameInfoTypes.BUILDING_ROMAN_GLADIUS_THRIVING,
    troubled = GameInfoTypes.BUILDING_ROMAN_GLADIUS_TROUBLED,
    toxic = GameInfoTypes.BUILDING_ROMAN_GLADIUS_TOXIC,
    dead = GameInfoTypes.BUILDING_ROMAN_GLADIUS_DEAD,
    owner = GameInfoTypes.BUILDING_ROMAN_GLADIUS_OWNER_ONLINE,
    opening = GameInfoTypes.BUILDING_ROMAN_GLADIUS_GRAND_OPENING,
    peak = GameInfoTypes.BUILDING_ROMAN_GLADIUS_PEAK_HOURS,
    happy = GameInfoTypes.BUILDING_ROMAN_GLADIUS_MILESTONE_HAPPINESS,
    success = GameInfoTypes.BUILDING_ROMAN_GLADIUS_SUCCESSFUL_NETWORK,
}
local reputationBuildings = {B.legendary, B.thriving, B.troubled, B.toxic, B.dead}
local names = {"Steve2004","EnderSteve","DiamondMiner","CraftKing42","RedstoneRose","BlockBuilder",
    "SpawnScout","NetherKnight","PickaxePete","BeaconBelle","CreeperKeeper","QuartzFox",
    "OakArchitect","MinecartMax","LanternLass","WitherWatcher"}
local traits = {"Builder","PvPer","Redstoner","Veteran","Troll","Donator","Potential Staff","Cheater"}

R.Events = {
    CHEATER = {name="Suspected Cheater", chat="[DiamondMiner] OWNER! This guy is flying!",
        options={"Ban Player", "Investigate", "Ignore"}},
    GRIEFER = {name="Griefer Attack", chat="[BlockBuilder] someone destroyed spawn",
        options={"Roll Back — 50 [ICON_GOLD]", "Let Staff Handle It", "Ignore Damage"}},
    MOD_ABUSE = {name="Moderator Abuse", chat="[Steve2004] mod gave his friend items",
        options={"Demote Moderator", "Investigate Incident", "Defend Staff"}},
    CIVIL_WAR = {name="Staff Civil War", chat="[CraftKing42 MOD] we need to talk about the staff team",
        options={"Demote One Moderator", "Demote Both", "Let Them Resolve It"}},
    CRASH = {name="Server Crash", chat="*** Connection timed out. ***",
        options={"Restart Immediately", "Debug the Problem", "Roll Back — 40 [ICON_GOLD]"}},
    DUPLICATION = {name="Duplication Exploit", chat="[RedstoneRose] I found something weird with these items",
        options={"Patch — 50 [ICON_PRODUCTION]", "Study the Exploit", "Leave It Active"}},
    COMMUNITY = {name="Community Build", chat="[OakArchitect] everyone meet at spawn—we are building something big",
        options={"Build a Castle", "Build a Redstone Machine", "Build a Spawn Hub"}},
    DONATOR = {name="Generous Donator", chat="[BeaconBelle] I would love to support the Server",
        options={"Offer a Cosmetic Rank", "Offer Gameplay Advantages", "Politely Decline"}},
}
-- Staff incidents are placed last so Servers without enough staff cannot roll them.
local negativeEvents = {"CHEATER","GRIEFER","CRASH","DUPLICATION","MOD_ABUSE","CIVIL_WAR"}
local positiveEvents = {"COMMUNITY","DONATOR"}

local function truth(value) return value == true or value == 1 end
local function turn() return Game.GetGameTurn() end
local function getNumber(key, fallback)
    local value = save.GetValue(key)
    return value == nil and fallback or tonumber(value) or fallback
end
local function getText(key, fallback)
    local value = save.GetValue(key)
    return value == nil and fallback or tostring(value)
end
local function setNumber(key, value) save.SetValue(key, math.floor(tonumber(value) or 0)) end
local function setText(key, value) save.SetValue(key, tostring(value or "")) end
local function isRoman(player)
    if type(player) == "number" then player = Players[player] end
    return player and player:IsAlive() and player:GetCivilizationType() == CIV
end
local function cityIdentity(city)
    local founded = city.GetGameTurnFounded and city:GetGameTurnFounded() or 0
    return table.concat({city:GetOwner(), city:GetID(), city:GetX(), city:GetY(), founded}, ":")
end
local function cityPrefix(city) return "ROMAN_GLADIUS_V1_C" .. cityIdentity(city) .. "_" end
local function playerKey(playerID, suffix) return "ROMAN_GLADIUS_V1_P" .. playerID .. "_" .. suffix end
local function hasBuilding(city, building)
    if not building then return false end
    if city.IsHasBuilding then return city:IsHasBuilding(building) end
    return (city:GetNumRealBuilding(building) or 0) > 0
end
local function setBuilding(city, building, amount)
    if building and city:GetNumRealBuilding(building) ~= amount then city:SetNumRealBuilding(building, amount) end
end
local function cityCount(player)
    local count = 0
    for _ in player:Cities() do count = count + 1 end
    return count
end
local function totalPopulation(player)
    local total = 0
    for city in player:Cities() do total = total + city:GetPopulation() end
    return total
end
local function notify(playerID, title, text, city)
    local player = Players[playerID]
    if not player or not player:IsHuman() then return end
    if player.AddNotification and NotificationTypes then
        player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, title,
            city and city:GetX() or -1, city and city:GetY() or -1)
    elseif Events and Events.GameplayAlertMessage then Events.GameplayAlertMessage(title .. ": " .. text) end
end
local function changed(playerID)
    if LuaEvents and LuaEvents.RomanGladiusStateChanged then LuaEvents.RomanGladiusStateChanged(playerID) end
end
local function random(maximum, label)
    if maximum <= 0 then return 0 end
    if Game.Rand then return Game.Rand(maximum, label) end
    return 0
end

function R.IsRoman(player) return isRoman(player) end

local function addLine(city, channel, text)
    local prefix = cityPrefix(city) .. channel .. "_"
    for index = 6, 2, -1 do setText(prefix .. index, getText(prefix .. (index - 1), "")) end
    setText(prefix .. 1, text)
end
local function addLog(city, text) addLine(city, "LOG", "Turn " .. turn() .. ": " .. text) end
local function addChat(city, text) addLine(city, "CHAT", text) end
local function readLines(city, channel)
    local result, prefix = {}, cityPrefix(city) .. channel .. "_"
    for index = 1, 6 do
        local line = getText(prefix .. index, "")
        if line ~= "" then result[#result + 1] = line end
    end
    return result
end
function R.GetLogs(city) return readLines(city, "LOG") end
function R.GetChat(city) return readLines(city, "CHAT") end

local function state(city)
    local prefix = cityPrefix(city)
    local reputation = math.max(0, math.min(100, getNumber(prefix .. "REP", 50)))
    local moderators = math.max(0, getNumber(prefix .. "MODS", 0))
    local admin = getNumber(prefix .. "ADMIN", 0) > 0 and 1 or 0
    local maximumModerators = math.max(0, city:GetPopulation() - admin)
    if moderators > maximumModerators then
        moderators = maximumModerators
        setNumber(prefix .. "MODS", moderators)
    end
    local openingUntil = getNumber(prefix .. "OPENING", -1)
    local peakUntil = getNumber(prefix .. "PEAK", -1)
    local event = getText(prefix .. "EVENT", "")
    if event ~= "" and not R.Events[event] then
        event = ""
        setText(prefix .. "EVENT", "")
    end
    return {reputation=reputation, moderators=moderators, admin=admin,
        openingUntil=openingUntil, peakUntil=peakUntil, event=event}
end
local function saveState(city, value)
    local prefix = cityPrefix(city)
    setNumber(prefix .. "REP", math.max(0, math.min(100, value.reputation)))
    setNumber(prefix .. "MODS", math.max(0, value.moderators))
    setNumber(prefix .. "ADMIN", value.admin > 0 and 1 or 0)
    setNumber(prefix .. "OPENING", value.openingUntil or -1)
    setNumber(prefix .. "PEAK", value.peakUntil or -1)
    setText(prefix .. "EVENT", value.event or "")
end
local function reputationLabel(value)
    if value >= 90 then return "Legendary" end
    if value >= 70 then return "Thriving" end
    if value >= 50 then return "Stable" end
    if value >= 30 then return "Troubled" end
    if value >= 10 then return "Toxic" end
    return "Dead Server"
end
local function activityLabel(value)
    if value >= 70 then return "Active" end
    if value < 40 then return "Inactive" end
    return "Quiet"
end
local function staffStatus(city, value)
    local population = city:GetPopulation()
    if population < 4 then return "Community-run" end
    local strength = value.moderators + value.admin * 2
    local needed = math.max(1, math.floor((population + 4) / 5))
    if strength < needed then return "Undermoderated" end
    if value.moderators > math.max(2, math.floor((population + 2) / 3)) then return "Overmoderated" end
    return "Well staffed"
end
function R.GetCityState(city)
    local value = state(city)
    value.band = reputationLabel(value.reputation)
    value.activity = activityLabel(value.reputation)
    value.staffStatus = staffStatus(city, value)
    value.population = city:GetPopulation()
    value.hasConsole = hasBuilding(city, CONSOLE)
    value.opening = value.openingUntil >= turn()
    value.peak = value.peakUntil >= turn()
    value.eventInfo = R.Events[value.event]
    return value
end
function R.ChangeReputation(city, amount, reason)
    local value = state(city)
    local before = value.reputation
    value.reputation = math.max(0, math.min(100, before + amount))
    saveState(city, value)
    if reason and value.reputation ~= before then
        local sign = value.reputation > before and "+" or ""
        addLog(city, reason .. " (Reputation " .. sign .. (value.reputation - before) .. ")")
    end
    R.RefreshCity(city)
    changed(city:GetOwner())
    return value.reputation
end

function R.RefreshCity(city)
    local player = Players[city:GetOwner()]
    local roman = isRoman(player)
    local population = city:GetPopulation()
    setBuilding(city, B.gold, roman and math.floor(population / 2) or 0)
    setBuilding(city, B.science, roman and math.floor(population / 4) or 0)
    setBuilding(city, B.culture, roman and math.floor(population / 5) or 0)
    local value = state(city)
    local enabled = roman and hasBuilding(city, CONSOLE)
    setBuilding(city, B.moderator, enabled and value.moderators or 0)
    for _, building in ipairs(reputationBuildings) do setBuilding(city, building, 0) end
    if enabled then
        if value.reputation >= 90 then setBuilding(city, B.legendary, 1)
        elseif value.reputation >= 70 then setBuilding(city, B.thriving, 1)
        elseif value.reputation < 10 then setBuilding(city, B.dead, 1)
        elseif value.reputation < 30 then setBuilding(city, B.toxic, 1)
        elseif value.reputation < 50 then setBuilding(city, B.troubled, 1) end
    end
    local capital = player and player.GetCapitalCity and player:GetCapitalCity()
    setBuilding(city, B.owner, roman and capital == city and 1 or 0)
    setBuilding(city, B.opening, roman and value.openingUntil >= turn() and 1 or 0)
    setBuilding(city, B.peak, roman and value.peakUntil >= turn() and 1 or 0)
    setBuilding(city, B.happy, roman and getNumber(playerKey(city:GetOwner(), "M50"), 0) > 0 and 1 or 0)
    setBuilding(city, B.success, roman and getNumber(playerKey(city:GetOwner(), "M100"), 0) > 0 and 1 or 0)
end
local function refreshPlayer(playerID)
    local player = Players[playerID]
    if not player then return end
    for city in player:Cities() do R.RefreshCity(city) end
end

local function actionCity(playerID, cityID)
    local player = Players[playerID]
    local city = player and player:GetCityByID(cityID)
    if not isRoman(player) or not city or not hasBuilding(city, CONSOLE) then return nil, "A Server Console is required." end
    return city
end
function R.PromoteModerator(playerID, cityID)
    local city, why = actionCity(playerID, cityID)
    if not city then return false, why end
    local value = state(city)
    if city:GetPopulation() < 4 then return false, "A Server needs at least 4 Players before appointing a Moderator." end
    if value.moderators + value.admin >= city:GetPopulation() then return false, "No ordinary Player is available for promotion." end
    local cost = 75 + value.moderators * 25
    local player = Players[playerID]
    if player:GetGold() < cost then return false, "Promotion requires " .. cost .. " Gold." end
    player:ChangeGold(-cost)
    value.moderators = value.moderators + 1
    saveState(city, value)
    addLog(city, "A trusted Player was promoted to Moderator for " .. cost .. " Gold.")
    addChat(city, "*** A new Moderator joined the staff team. ***")
    R.ChangeReputation(city, 3, "Staff coverage improved")
    return true, "Moderator promoted."
end
function R.PromoteAdministrator(playerID, cityID)
    local city, why = actionCity(playerID, cityID)
    if not city then return false, why end
    local value = state(city)
    if city:GetPopulation() < 8 then return false, "A Server needs at least 8 Players before appointing an Administrator." end
    if value.admin > 0 then return false, "This Server already has an Administrator." end
    if value.moderators < 1 then return false, "Promote a Moderator first." end
    local player = Players[playerID]
    if player:GetGold() < 150 then return false, "Administrator promotion requires 150 Gold." end
    player:ChangeGold(-150)
    value.moderators, value.admin = value.moderators - 1, 1
    saveState(city, value)
    addLog(city, "A Moderator was promoted to Administrator; upkeep is 2 Gold per turn.")
    addChat(city, "*** Administrator permissions granted. ***")
    R.ChangeReputation(city, 5, "Senior staff appointed")
    return true, "Administrator promoted."
end
function R.DemoteModerator(playerID, cityID)
    local city, why = actionCity(playerID, cityID)
    if not city then return false, why end
    local value = state(city)
    if value.moderators < 1 then return false, "This Server has no Moderator to demote." end
    value.moderators = value.moderators - 1
    saveState(city, value)
    addLog(city, "A Moderator returned to the Player roster.")
    R.ChangeReputation(city, -2, "Staff demotion unsettled the community")
    return true, "Moderator demoted."
end
function R.DemoteAdministrator(playerID, cityID)
    local city, why = actionCity(playerID, cityID)
    if not city then return false, why end
    local value = state(city)
    if value.admin < 1 then return false, "This Server has no Administrator to demote." end
    value.admin, value.moderators = 0, value.moderators + 1
    saveState(city, value)
    addLog(city, "The Administrator returned to Moderator duty.")
    R.ChangeReputation(city, -4, "Administrator demoted")
    return true, "Administrator demoted to Moderator."
end

local function rewardScience(player, amount)
    if player.ChangeOverflowResearch then player:ChangeOverflowResearch(amount) end
end
local function rewardCulture(player, amount)
    if player.ChangeJONSCulture then player:ChangeJONSCulture(amount) end
end
local function eventResult(city, choice)
    local value = state(city)
    local event = value.event
    local player = Players[city:GetOwner()]
    local message, rep = "Incident closed.", 0
    if event == "CHEATER" then
        if choice == 1 then
            if city:GetPopulation() <= 1 then return false, "Banning requires at least 2 Players." end
            city:ChangePopulation(-1, true)
            rep, message = 8, "The accused Player was banned."
            setNumber(playerKey(city:GetOwner(), "BANNED"), getNumber(playerKey(city:GetOwner(), "BANNED"), 0) + 1)
        elseif choice == 2 then
            if random(100, "RomanGladius cheater investigation") < 60 then rep, message = 6, "The investigation confirmed cheating; evidence was published."
            else rep, message = -4, "The accusation was false and trust suffered." end
        else rep, message = -10, "The report was ignored and the exploit spread." end
    elseif event == "GRIEFER" then
        if choice == 1 then
            if player:GetGold() < 50 then return false, "Rolling back requires 50 Gold." end
            player:ChangeGold(-50); rep, message = 8, "A clean backup restored the damaged builds."
        elseif choice == 2 and value.moderators + value.admin > 0 then rep, message = 4, "The staff contained the griefing."
        elseif choice == 2 then rep, message = -8, "There were no staff members available to help."
        else rep, message = -10, "The griefed builds were abandoned." end
    elseif event == "MOD_ABUSE" then
        if choice == 1 then
            if value.moderators < 1 then return false, "There is no Moderator to demote." end
            value.moderators = value.moderators - 1; rep, message = 7, "The abusive Moderator was demoted."
        elseif choice == 2 then
            if random(100, "RomanGladius moderator investigation") < 65 then rep, message = 5, "The logs exposed command abuse."
            else rep, message = -3, "The investigation found no abuse." end
        else player:ChangeGold(30); rep, message = -9, "Defending the staff member deepened the controversy." end
    elseif event == "CIVIL_WAR" then
        if choice == 1 then
            if value.moderators < 1 then return false, "There is no Moderator to demote." end
            value.moderators = value.moderators - 1; rep, message = 4, "One Moderator was removed and the argument cooled."
        elseif choice == 2 then
            if value.moderators < 2 then return false, "Demoting both combatants requires 2 Moderators." end
            value.moderators = value.moderators - 2; rep, message = 9, "Both combatants were removed from staff."
        elseif random(100, "RomanGladius staff civil war") < 45 then rep, message = 3, "The staff reconciled on their own."
        else rep, message = -10, "The dispute consumed the staff chat." end
    elseif event == "CRASH" then
        if choice == 1 then rep, message = -2, "The Server restarted quickly, but the cause remains."
        elseif choice == 2 then rewardScience(player, 30); rep, message = 4, "Debugging found the faulty configuration and produced useful research."
        else
            if player:GetGold() < 40 then return false, "Rolling back requires 40 Gold." end
            player:ChangeGold(-40); rep, message = 6, "The previous stable build was restored."
        end
    elseif event == "DUPLICATION" then
        if choice == 1 then
            if city:GetProduction() < 50 then return false, "Patching immediately requires 50 Production stored in the City." end
            city:ChangeProduction(-50); rep, message = 8, "The exploit was patched immediately."
        elseif choice == 2 then
            rewardScience(player, 45)
            if random(100, "RomanGladius duplication study") < 35 then rep, message = -8, "The study leaked and the economy was flooded."
            else rep, message = 3, "The exploit was understood and safely closed." end
        else player:ChangeGold(90); rep, message = -12, "The exploit enriched a few Players and damaged everyone's trust." end
    elseif event == "COMMUNITY" then
        if choice == 1 then city:ChangeProduction(60); rewardCulture(player, 20); rep, message = 6, "The community raised a castle together."
        elseif choice == 2 then rewardScience(player, 60); rep, message = 5, "The redstone machine became a technical landmark."
        else player:ChangeGold(60); rep, message = 8, "The new Spawn Hub welcomed every Player." end
    elseif event == "DONATOR" then
        if choice == 1 then player:ChangeGold(75); rep, message = 6, "A cosmetic rank funded the Server without harming fair play."
        elseif choice == 2 then player:ChangeGold(175); rep, message = -10, "Powerful paid advantages split the community."
        else rep, message = 2, "The offer was declined with thanks." end
    end
    value.event = ""
    value.reputation = math.max(0, math.min(100, value.reputation + rep))
    saveState(city, value)
    addLog(city, message .. " Reputation " .. (rep >= 0 and "+" or "") .. rep .. ".")
    addChat(city, "*** " .. message .. " ***")
    R.RefreshCity(city)
    changed(city:GetOwner())
    return true, message
end
function R.ResolveEvent(playerID, cityID, choice)
    local city, why = actionCity(playerID, cityID)
    if not city then return false, why end
    local event = state(city).event
    if event == "" or not R.Events[event] then return false, "This Server has no unresolved incident." end
    if type(choice) ~= "number" or choice ~= math.floor(choice) or choice < 1 or choice > 3 then
        return false, "Choose a valid response."
    end
    return eventResult(city, choice)
end
function R.SetEvent(city, event)
    if not city or not isRoman(city:GetOwner()) or not hasBuilding(city, CONSOLE) or not R.Events[event] then
        return false
    end
    local value = state(city)
    if value.event ~= "" then return false end
    value.event = event
    saveState(city, value)
    addChat(city, R.Events[event].chat)
    addLog(city, R.Events[event].name .. " requires an Owner decision.")
    changed(city:GetOwner())
    return true
end

local function positiveAutomatic(city)
    local value = state(city)
    local pick = random(3, "RomanGladius positive event")
    if pick == 0 then
        city:ChangePopulation(1, true)
        value.reputation = math.min(100, value.reputation + 10)
        addChat(city, "*** A popular creator sent new Players to the Server. ***")
        addLog(city, "Viral Server: +1 Player and +10 Reputation.")
    elseif pick == 1 then
        city:ChangePopulation(1, true)
        value.reputation = math.min(100, value.reputation + 4)
        rewardCulture(Players[city:GetOwner()], 30)
        addChat(city, "[Veteran] good to see the old place still online")
        addLog(city, "Veteran Returns: +1 Player, Culture, and Reputation.")
    else
        value.peakUntil = turn() + 9
        value.reputation = math.min(100, value.reputation + 5)
        addChat(city, "*** New concurrent Player record! ***")
        addLog(city, "Player Record: Peak Hours active for 10 turns.")
    end
    saveState(city, value)
    R.RefreshCity(city)
end
local function generateEvent(city)
    local value = state(city)
    if value.event ~= "" or not hasBuilding(city, CONSOLE) then return end
    local population = city:GetPopulation()
    local chance = 10 + math.min(20, population)
    if value.reputation < 50 then chance = chance + 15 end
    chance = math.max(5, chance - math.min(10, value.moderators * 2 + value.admin * 6))
    if random(100, "RomanGladius event check") >= chance then return end
    if value.reputation >= 70 and random(100, "RomanGladius positive check") < 45 then
        if random(100, "RomanGladius community choice") < 55 then
            local event = positiveEvents[random(#positiveEvents, "RomanGladius positive choice") + 1]
            R.SetEvent(city, event)
        else positiveAutomatic(city) end
    else
        local limit = value.moderators >= 2 and #negativeEvents
            or value.moderators + value.admin >= 1 and 5 or 4
        local event = negativeEvents[random(limit, "RomanGladius incident choice") + 1]
        R.SetEvent(city, event)
    end
    local player = Players[city:GetOwner()]
    if player:IsHuman() and state(city).event ~= "" then
        notify(city:GetOwner(), "Server Event: " .. R.Events[state(city).event].name,
            city:GetName() .. " needs an Owner decision in the Network Dashboard.", city)
    elseif not player:IsHuman() and state(city).event ~= "" then
        local preferred = value.admin > 0 and 1 or 2
        local resolved = eventResult(city, preferred)
        if not resolved then
            for choice = 1, 3 do
                if choice ~= preferred and eventResult(city, choice) then break end
            end
        end
    end
end

local function applyMilestones(playerID)
    local player = Players[playerID]
    local population = totalPopulation(player)
    local maximum = math.max(population, getNumber(playerKey(playerID, "MAXPOP"), 0))
    setNumber(playerKey(playerID, "MAXPOP"), maximum)
    if maximum >= 10 and getNumber(playerKey(playerID, "M10"), 0) == 0 then
        setNumber(playerKey(playerID, "M10"), 1); player:ChangeGold(100)
        notify(playerID, "Network Milestone", "10 Players Online — Small Community: gained 100 Gold.")
    end
    if maximum >= 25 and getNumber(playerKey(playerID, "M25"), 0) == 0 then
        setNumber(playerKey(playerID, "M25"), 1)
        local capital = player:GetCapitalCity()
        if capital then local value = state(capital); value.moderators = value.moderators + 1; saveState(capital, value) end
        notify(playerID, "Network Milestone", "25 Players Online — Growing Network: the Capital gained a free Moderator.")
    end
    if maximum >= 50 and getNumber(playerKey(playerID, "M50"), 0) == 0 then
        setNumber(playerKey(playerID, "M50"), 1)
        notify(playerID, "Network Milestone", "50 Players Online — Established Network: every Server gains +1 Happiness.")
    end
    if maximum >= 100 and getNumber(playerKey(playerID, "M100"), 0) == 0 then
        setNumber(playerKey(playerID, "M100"), 1)
        notify(playerID, "Network Milestone", "100 Players Online — Successful Network: +10% Gold, +10% Culture, and +10 Reputation equilibrium.")
    end
end
local function processCity(city)
    local value = state(city)
    if not hasBuilding(city, CONSOLE) then R.RefreshCity(city); return end
    local player = Players[city:GetOwner()]
    if value.admin > 0 then player:ChangeGold(-2) end
    local status = staffStatus(city, value)
    local capital = player:GetCapitalCity()
    local equilibrium = 50 + (capital == city and 10 or 0)
        + (getNumber(playerKey(city:GetOwner(), "M100"), 0) > 0 and 10 or 0)
    local delta = 0
    if status == "Undermoderated" then delta = -2
    elseif status == "Overmoderated" then delta = -1
    elseif value.reputation < equilibrium then delta = 1 + (value.admin > 0 and 1 or 0)
    elseif value.reputation > equilibrium and value.reputation < 70 then delta = -1 end
    value.reputation = math.max(0, math.min(100, value.reputation + delta))
    if value.reputation < 30 and turn() % 10 == (city:GetID() % 10) then
        local lossChance = value.reputation < 10 and 45 or 18
        if city:GetPopulation() > 1 and random(100, "RomanGladius player departure") < lossChance then
            city:ChangePopulation(-1, true)
            addChat(city, "*** " .. names[random(#names, "RomanGladius leaving player") + 1] .. " left the server. ***")
            addLog(city, "Low Reputation caused a Player to leave.")
        end
    end
    saveState(city, value)
    R.RefreshCity(city)
    if turn() % 6 == (city:GetID() % 6) then generateEvent(city) end
end
local function staffAI(playerID, city)
    if not hasBuilding(city, CONSOLE) then return end
    local player, value = Players[playerID], state(city)
    local needed = city:GetPopulation() >= 4 and math.max(1, math.floor((city:GetPopulation() + 4) / 5)) or 0
    local strength = value.moderators + value.admin * 2
    if strength < needed and player:GetGold() >= 75 + value.moderators * 25 then
        R.PromoteModerator(playerID, city:GetID())
        value = state(city)
    end
    if city:GetPopulation() >= 8 and value.admin == 0 and value.moderators >= 2 and player:GetGold() >= 150 then
        R.PromoteAdministrator(playerID, city:GetID())
    end
end
local function onPlayerTurn(playerID)
    local player = Players[playerID]
    if not isRoman(player) then return end
    applyMilestones(playerID)
    for city in player:Cities() do
        if not player:IsHuman() then staffAI(playerID, city) end
        processCity(city)
    end
    changed(playerID)
end

local function founded(playerID, x, y)
    local player = Players[playerID]
    if not isRoman(player) then return end
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if not city or city:GetOwner() ~= playerID then return end
    local count = cityCount(player)
    local launchCost = math.max(0, (count - 1) * 100)
    if launchCost > 0 then player:ChangeGold(-launchCost) end
    city:SetNumRealBuilding(CONSOLE, 1)
    local value = state(city)
    value.reputation, value.openingUntil = 60, turn() + 9
    saveState(city, value)
    addLog(city, "Grand Opening: launched for " .. launchCost .. " Gold with 60 Reputation.")
    addChat(city, "*** Welcome to " .. city:GetName() .. "! ***")
    notify(playerID, "Server Launched", city:GetName() .. " is online. Grand Opening is active for 10 turns.", city)
    R.RefreshCity(city)
    changed(playerID)
end
local function canTrain(playerID, unitType)
    if unitType ~= OWNER then return true end
    local player = Players[playerID]
    if not isRoman(player) then return false end
    for city in player:Cities() do if city:GetPopulation() > 2 then return true end end
    return false
end
local function cityCanTrain(playerID, cityID, unitType)
    if unitType ~= OWNER then return true end
    local player = Players[playerID]
    local city = player and player:GetCityByID(cityID)
    return isRoman(player) and city and city:GetPopulation() > 2
end
local function trained(playerID, cityID, unitID, boughtWithGold, boughtWithFaith)
    local player = Players[playerID]
    if not isRoman(player) then return end
    local unit = player:GetUnitByID(unitID)
    if not unit or unit:GetUnitType() ~= OWNER then return end
    local city = player:GetCityByID(cityID)
    local populationCost = SETTLERS_CONSUME_POPULATION
        and not truth(boughtWithGold) and not truth(boughtWithFaith) and 1 or 2
    if city and city:GetPopulation() > populationCost then
        city:ChangePopulation(-populationCost, true)
        addLog(city, "Two Players left to prepare a new Server launch.")
        R.RefreshCity(city)
    end
end
local function canFound(playerID)
    local player = Players[playerID]
    if not isRoman(player) then return true end
    return player:GetGold() >= cityCount(player) * 100
end
local function capture(_, _, x, y, newOwner)
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city then
        if isRoman(newOwner) then
            local value = state(city); value.reputation = 40; value.moderators = 0; value.admin = 0; value.event = ""
            saveState(city, value); addLog(city, "Captured Server joined the Network at 40 Reputation.")
        end
        R.RefreshCity(city)
    end
end

function R.GetRoster(city)
    local value, roster = state(city), {}
    local population = city:GetPopulation()
    for index = 1, math.min(population, 12) do
        local nameIndex = ((city:GetID() * 7 + index * 3) % #names) + 1
        local traitIndex = ((city:GetID() * 5 + index * 2) % #traits) + 1
        local role = "Player"
        if value.admin > 0 and index == 1 then role = "Administrator"
        elseif index <= value.moderators + value.admin then role = "Moderator" end
        roster[#roster + 1] = {name=names[nameIndex], trait=traits[traitIndex], role=role}
    end
    return roster
end
function R.GetServers(playerID)
    local result, player = {}, Players[playerID]
    if not isRoman(player) then return result end
    for city in player:Cities() do
        local value = R.GetCityState(city)
        result[#result + 1] = {id=city:GetID(), name=city:GetName(), city=city, state=value}
    end
    table.sort(result, function(a, b) return a.id < b.id end)
    return result
end
function R.GetNetworkState(playerID)
    local player = Players[playerID]
    local result = {population=0, servers=0, moderators=0, administrators=0, reputation=0,
        incidents=0, banned=getNumber(playerKey(playerID, "BANNED"), 0), maxPopulation=getNumber(playerKey(playerID, "MAXPOP"), 0)}
    if not isRoman(player) then return result end
    for city in player:Cities() do
        local value = state(city)
        result.population = result.population + city:GetPopulation()
        result.servers = result.servers + 1
        result.moderators = result.moderators + value.moderators
        result.administrators = result.administrators + value.admin
        result.reputation = result.reputation + value.reputation
        if value.event ~= "" then result.incidents = result.incidents + 1 end
    end
    result.reputation = result.servers > 0 and math.floor(result.reputation / result.servers + 0.5) or 0
    return result
end

R.RefreshPlayer, R.OnPlayerTurn, R.OnCityFounded, R.OnCityTrained = refreshPlayer, onPlayerTurn, founded, trained
GameEvents.PlayerDoTurn.Add(onPlayerTurn)
GameEvents.PlayerCityFounded.Add(founded)
GameEvents.CityTrained.Add(trained)
GameEvents.PlayerCanTrain.Add(canTrain)
if GameEvents.CityCanTrain then GameEvents.CityCanTrain.Add(cityCanTrain) end
if GameEvents.PlayerCanFoundCity then GameEvents.PlayerCanFoundCity.Add(canFound) end
GameEvents.CityCaptureComplete.Add(capture)
if GameEvents.CityConstructed then GameEvents.CityConstructed.Add(function(playerID) refreshPlayer(playerID) end) end
if GameEvents.CityPopulationChanged then GameEvents.CityPopulationChanged.Add(function(playerID) refreshPlayer(playerID) end) end
if GameEvents.CapitalChanged then GameEvents.CapitalChanged.Add(refreshPlayer) end
for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do if Players[playerID] then refreshPlayer(playerID) end end
R.Loaded = true
print("RomanGladius Network: runtime loaded")
