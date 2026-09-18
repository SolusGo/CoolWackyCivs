-- The Filthy Realm: Filth, Filthy Points, active abilities, Peace Lords and AI.
-- Loaded through FilthyPanel.xml so gameplay and UI share one authoritative state.

MapModData.FilthyRealm = MapModData.FilthyRealm or {}
local F = MapModData.FilthyRealm
if F.RuntimeLoaded then return end
F.RuntimeLoaded = true

local function ID(name) return GameInfoTypes[name] end
local I = {
    Civilization = ID("CIVILIZATION_FILTHY_REALM"),
    Kitchen = ID("BUILDING_FILTHY_KITCHEN"),
    PeaceLord = ID("UNIT_FILTHY_PEACE_LORD"),
    Salamander = ID("UNIT_FILTHY_SALAMANDER_MAN"),
    Filth = {}, Distorted = {},
    Strength10 = ID("PROMOTION_FILTHY_CITY_STRENGTH_10"),
    Strength15 = ID("PROMOTION_FILTHY_CITY_STRENGTH_15"),
    Humiliated = ID("PROMOTION_FILTHY_HUMILIATED"),
    SalamanderEnemy = ID("PROMOTION_FILTHY_SALAMANDER_ENEMY"),
    SalamanderFriend = ID("PROMOTION_FILTHY_SALAMANDER_FRIEND"),
    DistortionZOC = ID("PROMOTION_FILTHY_DISTORTION_ZOC"),
    Stopped = ID("PROMOTION_FILTHY_STOPPED")
}
for level = 1, 5 do
    I.Filth[level] = ID("BUILDING_FILTHY_LEVEL_" .. level)
    I.Distorted[level] = ID("BUILDING_FILTHY_DISTORTED_" .. level)
end
F.IDs = I

local MAX_MAJOR = GameDefines.MAX_MAJOR_CIVS or 22
local MAX_CIV = GameDefines.MAX_CIV_PLAYERS or 64
local MOVE = GameDefines.MOVE_DENOMINATOR or 60
local save = Modding.OpenSaveData()
local routeCache, battles = {}, {}
local snapshotGreatWorks

local function truth(value) return value == true or value == 1 end
local function turn() return Game.GetGameTurn() end
local function playerKey(playerID, suffix) return "FILTHY_V1_P" .. playerID .. "_" .. suffix end
local function cityKey(city)
    local founded = city.GetGameTurnFounded and city:GetGameTurnFounded() or -1
    -- Coordinates plus founding turn identify the physical city across captures,
    -- so Ravioli cooldowns cannot be reset by transferring ownership.
    return table.concat({city:GetX(), city:GetY(), founded}, "_")
end
local function getNumber(key, fallback)
    local value = tonumber(save.GetValue(key))
    return value == nil and (fallback or 0) or value
end
local function setNumber(key, value) save.SetValue(key, math.floor(tonumber(value) or 0)) end
local function setPromo(unit, promotion, enabled)
    if unit and promotion and promotion >= 0 and unit:IsHasPromotion(promotion) ~= enabled then
        unit:SetHasPromotion(promotion, enabled)
    end
end
local function isFilthy(player)
    if type(player) == "number" then player = Players[player] end
    return player and player:IsAlive() and I.Civilization and player:GetCivilizationType() == I.Civilization
end
local function isMilitary(unit)
    return unit and unit.IsCombatUnit and unit:IsCombatUnit() and not unit:IsTrade()
end
local function atWar(a, b)
    return a and b and Teams[a:GetTeam()] and Teams[a:GetTeam()]:IsAtWar(b:GetTeam())
end
local function cityByID(ownerID, cityID)
    local player = Players[ownerID]
    return player and player:GetCityByID(cityID) or nil
end
local function notify(playerID, text, x, y)
    local player = Players[playerID]
    if not player or not player:IsHuman() then return end
    if x and y and player.AddNotification then
        player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text,
            Locale.ConvertTextKey("TXT_KEY_TRAIT_FILTHY_SHORT"), x, y)
    elseif Events and Events.GameplayAlertMessage then
        Events.GameplayAlertMessage(text)
    end
end
local function changed(playerID)
    if LuaEvents and LuaEvents.FilthyStateChanged then LuaEvents.FilthyStateChanged(playerID) end
end

function F.GetPoints(playerID) return getNumber(playerKey(playerID, "POINTS"), 0) end
function F.ChangePoints(playerID, amount)
    if not isFilthy(playerID) then return F.GetPoints(playerID) end
    local value = math.max(0, F.GetPoints(playerID) + math.floor(amount or 0))
    setNumber(playerKey(playerID, "POINTS"), value)
    changed(playerID)
    return value
end
function F.IsFilthy(player) return isFilthy(player) end

local unitMarker = "%[FILTHY1:([^%]]*)%]"
local function unitState(unit)
    local state = {salUntil=-1, intervention=0, humUntil=-1, stopUntil=-1}
    local raw = unit and (unit:GetScriptData() or ""):match(unitMarker)
    if raw then
        local a, b, c, d = raw:match("^(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+)$")
        state.salUntil, state.intervention, state.humUntil, state.stopUntil =
            tonumber(a) or -1, tonumber(b) or 0, tonumber(c) or -1, tonumber(d) or -1
    end
    return state
end
local function setUnitState(unit, state)
    if not unit then return end
    local original = (unit:GetScriptData() or ""):gsub(unitMarker, "")
    unit:SetScriptData(original .. "[FILTHY1:" .. table.concat({
        state.salUntil or -1, state.intervention or 0, state.humUntil or -1, state.stopUntil or -1
    }, ",") .. "]")
end
F.GetUnitState, F.SetUnitState = unitState, setUnitState

local function isDistortedBy(playerID, city)
    if getNumber(playerKey(playerID, "DISTORT_EXPIRES"), -1) <= turn()
        or getNumber(playerKey(playerID, "DISTORT_OWNER"), -1) ~= city:GetOwner()
        or getNumber(playerKey(playerID, "DISTORT_CITY"), -1) ~= city:GetID() then return false end
    local savedX = getNumber(playerKey(playerID, "DISTORT_X"), -999)
    local savedY = getNumber(playerKey(playerID, "DISTORT_Y"), -999)
    local savedFounded = getNumber(playerKey(playerID, "DISTORT_FOUNDED"), -999)
    return (savedX == -999 or savedX == city:GetX())
        and (savedY == -999 or savedY == city:GetY())
        and (savedFounded == -999 or not city.GetGameTurnFounded
            or savedFounded == city:GetGameTurnFounded())
end
local function isDistorted(city)
    for playerID = 0, MAX_MAJOR - 1 do
        if isFilthy(playerID) and isDistortedBy(playerID, city) then return true, playerID end
    end
    return false, -1
end
local function getFilth(city)
    if not city then return 0, false end
    for level = 5, 1, -1 do
        if city:GetNumRealBuilding(I.Distorted[level]) > 0 then return level, true end
        if city:GetNumRealBuilding(I.Filth[level]) > 0 then return level, false end
    end
    return 0, false
end
F.GetFilth = getFilth

local function writeFilth(city, level)
    local distorted = level > 0 and isDistorted(city)
    for index = 1, 5 do
        city:SetNumRealBuilding(I.Filth[index], (level == index and not distorted) and 1 or 0)
        city:SetNumRealBuilding(I.Distorted[index], (level == index and distorted) and 1 or 0)
    end
end
local function setFilth(city, level, sourcePlayerID)
    if not city then return 0 end
    if isFilthy(city:GetOwner()) then level = 0 end
    local old = getFilth(city)
    level = math.max(0, math.min(5, math.floor(level or 0)))
    writeFilth(city, level)
    if level ~= old and F.RefreshCombat then F.RefreshCombat() end
    if level > old and sourcePlayerID and isFilthy(sourcePlayerID) then
        F.ChangePoints(sourcePlayerID, 2 * (level - old))
        notify(sourcePlayerID, Locale.ConvertTextKey("TXT_KEY_FILTHY_FILTH_GAINED", city:GetName(), level), city:GetX(), city:GetY())
    end
    return level
end
function F.ChangeFilth(city, delta, sourcePlayerID)
    local level = getFilth(city)
    return setFilth(city, level + (delta or 0), sourcePlayerID)
end

local function routeKey(route)
    local from, to = route.FromCity, route.ToCity
    if not from or not to then return nil end
    return table.concat({from:GetOwner(), from:GetX(), from:GetY(), to:GetOwner(), to:GetX(), to:GetY()}, ":")
end
local function currentRoutes(playerID)
    local player, routes, counts = Players[playerID], {}, {}
    if not player or not player.GetTradeRoutes then return routes, counts end
    for _, route in ipairs(player:GetTradeRoutes()) do
        local key = routeKey(route)
        if key then
            routes[#routes + 1] = route
            counts[key] = (counts[key] or 0) + 1
        end
    end
    return routes, counts
end
local function routeConnected(city)
    for playerID = 0, MAX_MAJOR - 1 do
        local player = Players[playerID]
        if isFilthy(player) and player.GetTradeRoutes then
            for _, route in ipairs(player:GetTradeRoutes()) do
                if route.FromCity == city or route.ToCity == city then return true end
            end
        end
    end
    return false
end
local function tourismConnected(city)
    local ownerID = city:GetOwner()
    for playerID = 0, MAX_MAJOR - 1 do
        local player = Players[playerID]
        if isFilthy(player) and playerID ~= ownerID then
            if player.GetInfluenceLevel then
                local familiar = InfluenceLevelTypes and InfluenceLevelTypes.INFLUENCE_LEVEL_FAMILIAR or 2
                if (player:GetInfluenceLevel(ownerID) or 0) >= familiar then return true end
            elseif player.GetInfluenceOn and (player:GetInfluenceOn(ownerID) or 0) >= 100 then
                return true
            end
        end
    end
    return false
end
local function nearbyFilthyMilitary(city, distance)
    for playerID = 0, MAX_MAJOR - 1 do
        local player = Players[playerID]
        if isFilthy(player) then
            for unit in player:Units() do
                if isMilitary(unit) and Map.PlotDistance(unit:GetX(), unit:GetY(), city:GetX(), city:GetY()) <= distance then
                    return true
                end
            end
        end
    end
    return false
end

local function processTrade(playerID)
    local player = Players[playerID]
    if not isFilthy(player) then return end
    local routes, counts = currentRoutes(playerID)
    if routeCache[playerID] then
        for key, count in pairs(counts) do
            local added = count - (routeCache[playerID][key] or 0)
            if added > 0 then F.ChangePoints(playerID, added * 5) end
        end
    end
    routeCache[playerID] = counts
    for _, route in ipairs(routes) do
        local from, to = route.FromCity, route.ToCity
        if from and to and from:GetOwner() == playerID and to:GetOwner() ~= playerID then
            local interval = from:GetNumRealBuilding(I.Kitchen) > 0 and 4 or 6
            if turn() % interval == 0 then F.ChangeFilth(to, 1, playerID) end
        end
    end
end

local function processTourism(playerID)
    local player = Players[playerID]
    if not isFilthy(player) or turn() % 10 ~= 0 then return end
    for otherID = 0, MAX_CIV - 1 do
        local other = Players[otherID]
        if other and other:IsAlive() and otherID ~= playerID and not other:IsMinorCiv() then
            local capital = other:GetCapitalCity()
            if capital and tourismConnected(capital) then F.ChangeFilth(capital, 1, playerID) end
        end
    end
end

local function processDecay(playerID)
    local player = Players[playerID]
    if not player or not player:IsAlive() or isFilthy(player) or turn() % 10 ~= 0 then return end
    for city in player:Cities() do
        local level = getFilth(city)
        if level > 0 and not routeConnected(city) and not tourismConnected(city)
            and not nearbyFilthyMilitary(city, 3) then
            setFilth(city, level - 1)
        end
    end
end

local function processGreatWorks(playerID)
    local player = Players[playerID]
    if not isFilthy(player) then return end
    local periodic, total = 0, 0
    for city in player:Cities() do
        local count = city.GetNumGreatWorks and city:GetNumGreatWorks() or 0
        total = total + count
        if turn() % 5 == 0 and city:GetNumRealBuilding(I.Kitchen) > 0 then
            periodic = periodic + math.min(3, count)
        end
    end
    -- Current Community Patch exposes GreatWorkCreated, which is authoritative and
    -- cannot be exploited by moving works between cities. The high-water fallback
    -- only supports older DLLs where that event is absent.
    if not GameEvents.GreatWorkCreated then
        local key = playerKey(playerID, "GREAT_WORK_HIGH_WATER")
        local previous = getNumber(key, total)
        if total > previous then F.ChangePoints(playerID, (total - previous) * 10) end
        setNumber(key, math.max(previous, total))
    end
    if periodic > 0 then F.ChangePoints(playerID, periodic) end
    -- Keep the slot snapshot current after normal Great Work moves. Creation is
    -- handled synchronously by GreatWorkCreated before the next player turn.
    if snapshotGreatWorks then snapshotGreatWorks(playerID) end
end

local greatWorkSlots = {}
if GameInfo and GameInfo.Buildings then
    for building in GameInfo.Buildings() do
        local count = tonumber(building.GreatWorkCount) or 0
        local classID = count > 0 and ID(building.BuildingClass) or nil
        if classID then greatWorkSlots[classID] = math.max(greatWorkSlots[classID] or 0, count) end
    end
end
local knownGreatWorks, knownGreatWorkCounts = {}, {}
local function scanGreatWorks(playerID, previousWorks, previousCounts, greatWorkType)
    local player = Players[playerID]
    if not player then return nil, {}, {} end
    local found, fallback, works, counts = nil, nil, {}, {}
    for city in player:Cities() do
        local key = cityKey(city)
        local count = city.GetNumGreatWorks and city:GetNumGreatWorks() or 0
        counts[key] = count
        if count > (previousCounts[key] or 0) then fallback = fallback or city end
        if city.GetBuildingGreatWork then
            for classID, slots in pairs(greatWorkSlots) do
                for slot = 0, slots - 1 do
                    local workID = city:GetBuildingGreatWork(classID, slot)
                    if workID and workID >= 0 then
                        works[workID] = true
                        if not previousWorks[workID] then
                            fallback = fallback or city
                            local matches = true
                            if greatWorkType ~= nil and Game.GetGreatWorkType then
                                local ok, workType = pcall(Game.GetGreatWorkType, workID)
                                matches = ok and workType == greatWorkType
                            end
                            if matches then found = found or city end
                        end
                    end
                end
            end
        end
    end
    return found or fallback, works, counts
end
snapshotGreatWorks = function(playerID)
    local _, works, counts = scanGreatWorks(playerID, {}, {}, nil)
    knownGreatWorks[playerID], knownGreatWorkCounts[playerID] = works, counts
end
local function greatWorkCity(playerID, greatWorkType)
    local city, works, counts = scanGreatWorks(playerID,
        knownGreatWorks[playerID] or {}, knownGreatWorkCounts[playerID] or {}, greatWorkType)
    knownGreatWorks[playerID], knownGreatWorkCounts[playerID] = works, counts
    return city
end
local function onGreatWorkCreated(playerID, unitID, greatWorkType)
    local player = Players[playerID]
    if not isFilthy(player) then return end
    F.ChangePoints(playerID, 10)
    -- The Community Patch fires this after killing the creator and supplies a
    -- GreatWorkType, not the new instance ID. Compare occupied slots with the
    -- previous snapshot to find the city that actually received the new work.
    local city = greatWorkCity(playerID, greatWorkType)
    if city and city:GetNumRealBuilding(I.Kitchen) > 0 then city:ChangeFood(25) end
end
F.OnGreatWorkCreated = onGreatWorkCreated

local function storedDistortionCity(playerID)
    local city = cityByID(getNumber(playerKey(playerID, "DISTORT_OWNER"), -1),
        getNumber(playerKey(playerID, "DISTORT_CITY"), -1))
    if not city then return nil end
    local savedX = getNumber(playerKey(playerID, "DISTORT_X"), -999)
    local savedY = getNumber(playerKey(playerID, "DISTORT_Y"), -999)
    local savedFounded = getNumber(playerKey(playerID, "DISTORT_FOUNDED"), -999)
    if (savedX ~= -999 and city:GetX() ~= savedX)
        or (savedY ~= -999 and city:GetY() ~= savedY)
        or (savedFounded ~= -999 and city.GetGameTurnFounded
            and city:GetGameTurnFounded() ~= savedFounded) then return nil end
    return city
end
local function distortionCity(playerID)
    if getNumber(playerKey(playerID, "DISTORT_EXPIRES"), -1) <= turn() then return nil end
    return storedDistortionCity(playerID)
end
local function refreshCombat(unit)
    if not unit then return end
    local ownerID, best = unit:GetOwner(), 0
    if isFilthy(ownerID) and isMilitary(unit) then
        for otherID = 0, MAX_CIV - 1 do
            local other = Players[otherID]
            if other and other:IsAlive() and otherID ~= ownerID then
                for city in other:Cities() do
                    local level = getFilth(city)
                    if level >= 4 and Map.PlotDistance(unit:GetX(), unit:GetY(), city:GetX(), city:GetY()) <= 3 then
                        best = math.max(best, level == 5 and 15 or 10)
                    end
                end
            end
        end
    end
    setPromo(unit, I.Strength10, best == 10)
    setPromo(unit, I.Strength15, best == 15)
    local target = isFilthy(ownerID) and distortionCity(ownerID) or nil
    setPromo(unit, I.DistortionZOC, target ~= nil and isMilitary(unit)
        and Map.PlotDistance(unit:GetX(), unit:GetY(), target:GetX(), target:GetY()) <= 2)
end
local function refreshAllCombat()
    for playerID = 0, MAX_CIV - 1 do
        local player = Players[playerID]
        if player and player:IsAlive() then for unit in player:Units() do refreshCombat(unit) end end
    end
end

local function activeSalamanders(excludedOwner, excludedID)
    local salamanders = {}
    for playerID = 0, MAX_MAJOR - 1 do
        local player = Players[playerID]
        if isFilthy(player) then
            for unit in player:Units() do
                if unit:GetUnitType() == I.Salamander and unitState(unit).salUntil > turn()
                    and not (unit:GetOwner() == excludedOwner and unit:GetID() == excludedID) then
                    salamanders[#salamanders + 1] = unit
                end
            end
        end
    end
    return salamanders
end
local function refreshAuraUnit(unit, salamanders)
    if not unit then return end
    setPromo(unit, I.SalamanderEnemy, false)
    setPromo(unit, I.SalamanderFriend, false)
    if not isMilitary(unit) then return end
    for _, salamander in ipairs(salamanders) do
        local owner = Players[salamander:GetOwner()]
        local player = Players[unit:GetOwner()]
        if Map.PlotDistance(unit:GetX(), unit:GetY(), salamander:GetX(), salamander:GetY()) <= 1 then
            if unit:GetOwner() == salamander:GetOwner() then setPromo(unit, I.SalamanderFriend, true)
            elseif atWar(owner, player) then setPromo(unit, I.SalamanderEnemy, true) end
        end
    end
end
local function refreshAuras(excludedOwner, excludedID)
    local salamanders = activeSalamanders(excludedOwner, excludedID)
    for playerID = 0, MAX_CIV - 1 do
        local player = Players[playerID]
        if player and player:IsAlive() then
            for unit in player:Units() do refreshAuraUnit(unit, salamanders) end
        end
    end
end

local function refreshTemporary(playerID)
    local player = Players[playerID]
    if not player then return end
    local expired = {}
    for unit in player:Units() do
        local state = unitState(unit)
        if unit:GetUnitType() == I.Salamander and state.salUntil >= 0 and state.salUntil <= turn() then
            expired[#expired + 1] = unit
        else
            setPromo(unit, I.Humiliated, state.humUntil > turn())
            setPromo(unit, I.Stopped, state.stopUntil > turn())
            if state.stopUntil > turn() then unit:SetMoves(0) end
        end
    end
    for _, unit in ipairs(expired) do unit:Kill(true, -1) end
end

function F.GetForeignCities(playerID, requireFilth)
    local result, player = {}, Players[playerID]
    if not isFilthy(player) then return result end
    for ownerID = 0, MAX_CIV - 1 do
        local owner = Players[ownerID]
        if owner and owner:IsAlive() and ownerID ~= playerID then
            for city in owner:Cities() do
                local level = getFilth(city)
                if not requireFilth or level > 0 then
                    result[#result + 1] = {owner=ownerID,id=city:GetID(),name=city:GetName(),
                        level=level,x=city:GetX(),y=city:GetY(),cooldown=math.max(0,
                        getNumber(playerKey(playerID, "RAVIOLI_" .. cityKey(city)), 0) - turn())}
                end
            end
        end
    end
    table.sort(result, function(a,b)
        if a.name ~= b.name then return a.name < b.name end
        if a.owner ~= b.owner then return a.owner < b.owner end
        return a.id < b.id
    end)
    return result
end

local function spend(playerID, cost)
    if F.GetPoints(playerID) < cost then return false, "Not enough Filthy Points." end
    F.ChangePoints(playerID, -cost)
    return true
end
local function freeAdjacentCapitalPlot(player)
    local capital = player and player:GetCapitalCity()
    if not capital then return nil end
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local plot = Map.PlotDirection(capital:GetX(), capital:GetY(), direction)
        if plot and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable()
            and not plot:IsCity() and plot:GetNumUnits() == 0 then return plot end
    end
    return nil
end
function F.UseSalamander(playerID)
    local player, cost = Players[playerID], 25
    if not isFilthy(player) then return false, "Only the Filthy Realm can use this ability." end
    local plot = freeAdjacentCapitalPlot(player)
    if not plot then return false, "The Capital needs a free adjacent land tile." end
    local ok, why = spend(playerID, cost); if not ok then return false, why end
    local unit = player:InitUnit(I.Salamander, plot:GetX(), plot:GetY())
    if not unit then F.ChangePoints(playerID, cost); return false, "Salamander Man could not enter the Realm." end
    local state = unitState(unit); state.salUntil = turn() + 5; setUnitState(unit, state)
    unit:SetMoves(unit:MaxMoves())
    refreshAuras()
    notify(playerID, Locale.ConvertTextKey("TXT_KEY_FILTHY_SALAMANDER_NOTIFICATION"), plot:GetX(), plot:GetY())
    return true, "Salamander Man summoned for 5 turns."
end
function F.UseDistortion(playerID, ownerID, cityID)
    local city, cost = cityByID(ownerID, cityID), 40
    if not isFilthy(playerID) or not city or city:GetOwner() == playerID or getFilth(city) < 1 then
        return false, "Choose a foreign City with at least 1 Filth."
    end
    local ready = getNumber(playerKey(playerID, "DISTORT_READY"), 0)
    if ready > turn() then return false, "Realm Distortion is on cooldown for " .. (ready - turn()) .. " turns." end
    local ok, why = spend(playerID, cost); if not ok then return false, why end
    local old = distortionCity(playerID)
    setNumber(playerKey(playerID, "DISTORT_OWNER"), ownerID)
    setNumber(playerKey(playerID, "DISTORT_CITY"), cityID)
    setNumber(playerKey(playerID, "DISTORT_X"), city:GetX())
    setNumber(playerKey(playerID, "DISTORT_Y"), city:GetY())
    setNumber(playerKey(playerID, "DISTORT_FOUNDED"),
        city.GetGameTurnFounded and city:GetGameTurnFounded() or -1)
    setNumber(playerKey(playerID, "DISTORT_EXPIRES"), turn() + 5)
    setNumber(playerKey(playerID, "DISTORT_READY"), turn() + 10)
    if old then writeFilth(old, getFilth(old)) end
    writeFilth(city, getFilth(city))
    refreshAllCombat()
    changed(playerID)
    return true, city:GetName() .. " is distorted for 5 turns."
end

local amounts = {GOLD=25, SCIENCE=15, CULTURE=15, FOOD=20, PRODUCTION=20}
function F.UseRavioli(playerID, ownerID, cityID, category)
    local player, target, city = Players[playerID], Players[ownerID], cityByID(ownerID, cityID)
    category = tostring(category or ""):upper()
    if not isFilthy(player) or not target or not city or ownerID == playerID or not amounts[category] then
        return false, "Choose a foreign City and one yield category."
    end
    local key = playerKey(playerID, "RAVIOLI_" .. cityKey(city))
    local ready = getNumber(key, 0)
    if ready > turn() then return false, city:GetName() .. " cannot be targeted for " .. (ready - turn()) .. " turns." end
    local ok, why = spend(playerID, 60); if not ok then return false, why end
    local era = math.max(0, player:GetCurrentEra()) + 1
    local requested, transferred = amounts[category] * era, 0
    if category == "GOLD" then
        transferred = math.min(requested, math.max(0, target:GetGold()))
        target:ChangeGold(-transferred); player:ChangeGold(transferred)
    elseif category == "SCIENCE" then
        transferred = requested
        player:ChangeOverflowResearch(transferred)
    elseif category == "CULTURE" then
        local available = target.GetJONSCulture and target:GetJONSCulture() or requested
        transferred = math.min(requested, math.max(0, available))
        target:ChangeJONSCulture(-transferred); player:ChangeJONSCulture(transferred)
    elseif category == "FOOD" then
        transferred = math.min(requested, math.max(0, city:GetFood()))
        city:ChangeFood(-transferred)
        local capital = player:GetCapitalCity(); if capital then capital:ChangeFood(transferred) end
    elseif category == "PRODUCTION" then
        transferred = math.min(requested, math.max(0, city:GetProduction()))
        city:ChangeProduction(-transferred)
        local capital = player:GetCapitalCity(); if capital then capital:ChangeProduction(transferred) end
    end
    setNumber(key, turn() + 15)
    changed(playerID)
    return true, "Stole " .. transferred .. " " .. category .. " from " .. city:GetName() .. "."
end

local function inStopArea(player, enemy)
    for unit in player:Units() do
        if isMilitary(unit) and Map.PlotDistance(unit:GetX(), unit:GetY(), enemy:GetX(), enemy:GetY()) <= 4 then return true end
    end
    return false
end
function F.UseStop(playerID)
    local player = Players[playerID]
    if not isFilthy(player) then return false, "Only the Filthy Realm can use this ability." end
    local ready = getNumber(playerKey(playerID, "STOP_READY"), 0)
    if ready > turn() then return false, "It's Time to Stop is on cooldown for " .. (ready - turn()) .. " turns." end
    if F.GetPoints(playerID) < 80 then return false, "Not enough Filthy Points." end
    local affected = {}
    for otherID = 0, MAX_CIV - 1 do
        local other = Players[otherID]
        if other and other:IsAlive() and atWar(player, other) then
            for unit in other:Units() do if isMilitary(unit) and inStopArea(player, unit) then affected[#affected + 1] = unit end end
        end
    end
    if #affected == 0 then return false, "No enemy military unit is within 4 tiles of your military." end
    spend(playerID, 80)
    for _, unit in ipairs(affected) do
        local state = unitState(unit); state.stopUntil = turn() + 1; setUnitState(unit, state)
        setPromo(unit, I.Stopped, true); unit:SetMoves(0)
    end
    setNumber(playerKey(playerID, "STOP_READY"), turn() + 20)
    changed(playerID)
    return true, #affected .. " enemy units have stopped."
end

function F.GetCooldown(playerID, ability)
    local suffix = ability == "DISTORTION" and "DISTORT_READY" or ability == "STOP" and "STOP_READY" or nil
    return suffix and math.max(0, getNumber(playerKey(playerID, suffix), 0) - turn()) or 0
end

local function interventionTarget(peaceLord, target)
    if not peaceLord or peaceLord:GetUnitType() ~= I.PeaceLord or unitState(peaceLord).intervention == 1 then return false end
    if not target or not isMilitary(target) or not atWar(Players[peaceLord:GetOwner()], Players[target:GetOwner()]) then return false end
    return target:GetCurrHitPoints() < 30 and Map.PlotDistance(peaceLord:GetX(), peaceLord:GetY(), target:GetX(), target:GetY()) == 1
end
local function canRetreatInto(target, plot)
    if not plot or plot:IsImpassable() or plot:IsCity() or plot:GetNumUnits() > 0 then return false end
    -- VP's Lua binding calls CvUnit::canMoveInto through CanMoveThrough.
    if target.CanMoveThrough then
        local ok, allowed = pcall(target.CanMoveThrough, target, plot)
        if ok then return truth(allowed) end
    end
    local domain = target:GetDomainType()
    if domain == DomainTypes.DOMAIN_SEA then return plot:IsWater() end
    if domain == DomainTypes.DOMAIN_LAND then
        return (target.IsEmbarked and target:IsEmbarked() and plot:IsWater())
            or (not plot:IsWater() and not plot:IsMountain())
    end
    return false
end
local function retreatPlot(peaceLord, target)
    local candidates, current = {}, Map.PlotDistance(peaceLord:GetX(), peaceLord:GetY(), target:GetX(), target:GetY())
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local plot = Map.PlotDirection(target:GetX(), target:GetY(), direction)
        if canRetreatInto(target, plot)
            and Map.PlotDistance(peaceLord:GetX(), peaceLord:GetY(), plot:GetX(), plot:GetY()) > current then
            candidates[#candidates + 1] = plot
        end
    end
    table.sort(candidates, function(a,b)
        local da = Map.PlotDistance(peaceLord:GetX(), peaceLord:GetY(), a:GetX(), a:GetY())
        local db = Map.PlotDistance(peaceLord:GetX(), peaceLord:GetY(), b:GetX(), b:GetY())
        return da > db
    end)
    return candidates[1]
end
function F.GetInterventionTargets(playerID)
    local result, player = {}, Players[playerID]
    if not isFilthy(player) then return result end
    for peaceLord in player:Units() do
        if peaceLord:GetUnitType() == I.PeaceLord and unitState(peaceLord).intervention == 0 then
            for otherID = 0, MAX_CIV - 1 do
                local other = Players[otherID]
                if other and other:IsAlive() and atWar(player, other) then
                    for target in other:Units() do
                        if interventionTarget(peaceLord, target) and retreatPlot(peaceLord, target) then
                            result[#result + 1] = {peace=peaceLord:GetID(),owner=otherID,target=target:GetID(),
                                text=peaceLord:GetName() .. " -> " .. target:GetName() .. " (" .. target:GetCurrHitPoints() .. " HP)"}
                        end
                    end
                end
            end
        end
    end
    return result
end
function F.UseIntervention(playerID, peaceID, targetOwnerID, targetID)
    local player, targetOwner = Players[playerID], Players[targetOwnerID]
    local peaceLord = player and player:GetUnitByID(peaceID) or nil
    local target = targetOwner and targetOwner:GetUnitByID(targetID) or nil
    local plot = interventionTarget(peaceLord, target) and retreatPlot(peaceLord, target) or nil
    if not plot then return false, "The target is no longer eligible or has no valid retreat tile." end
    target:SetXY(plot:GetX(), plot:GetY())
    target:SetMoves(0)
    local state = unitState(peaceLord); state.intervention = 1; setUnitState(peaceLord, state)
    F.ChangePoints(playerID, 10)
    notify(playerID, Locale.ConvertTextKey("TXT_KEY_FILTHY_INTERVENTION_NOTIFICATION", peaceLord:GetName(), target:GetName()), plot:GetX(), plot:GetY())
    return true, target:GetName() .. " was forced to retreat."
end

local function closestForeignCity(ownerID, x, y, maximum)
    local owner, best, distance = Players[ownerID], nil, maximum + 1
    if not owner then return nil end
    for city in owner:Cities() do
        local value = Map.PlotDistance(x, y, city:GetX(), city:GetY())
        if value <= maximum and value < distance then best, distance = city, value end
    end
    return best
end
local function battleKiller(victimOwnerID, victimUnitID, killerPlayerID)
    local battle = battles[#battles]
    if not battle then return nil end
    local victimRole
    for role, member in pairs(battle) do
        if member.playerID == victimOwnerID and member.unitID == victimUnitID and not member.isCity then victimRole = role end
    end
    if victimRole == nil then return nil end
    if victimRole == 0 then
        for _, role in ipairs({2,1}) do
            local member = battle[role]
            if member and member.playerID == killerPlayerID and not member.isCity then
                return Players[killerPlayerID]:GetUnitByID(member.unitID)
            end
        end
    else
        local member = battle[0]
        if member and member.playerID == killerPlayerID and not member.isCity then
            return Players[killerPlayerID]:GetUnitByID(member.unitID)
        end
    end
    return nil
end
local function onPrekill(ownerID, unitID, unitType, x, y, delay, killerPlayerID)
    local owner, killer = Players[ownerID], killerPlayerID and Players[killerPlayerID]
    local victim = owner and owner:GetUnitByID(unitID) or nil
    if victim and victim:GetUnitType() == I.Salamander then refreshAuras(ownerID, unitID) end
    if not victim or not isMilitary(victim) or not isFilthy(killer) or not atWar(owner, killer) then return end
    local plot = Map.GetPlot(x, y)
    F.ChangePoints(killerPlayerID, plot and plot:GetOwner() == ownerID and 3 or 2)
    local city = closestForeignCity(ownerID, x, y, 3)
    if city then F.ChangeFilth(city, 1, killerPlayerID) end
    local unit = battleKiller(ownerID, unitID, killerPlayerID)
    if unit and unit:GetUnitType() == I.PeaceLord then
        F.ChangePoints(killerPlayerID, 5)
        for otherID = 0, MAX_CIV - 1 do
            local other = Players[otherID]
            if other and other:IsAlive() and atWar(killer, other) then
                for enemy in other:Units() do
                    if isMilitary(enemy) and Map.PlotDistance(unit:GetX(), unit:GetY(), enemy:GetX(), enemy:GetY()) <= 1 then
                        local state = unitState(enemy); state.humUntil = turn() + 1; setUnitState(enemy, state)
                        setPromo(enemy, I.Humiliated, true)
                    end
                end
            end
        end
    end
end
local function onPillage(playerID, unitID)
    local player, unit = Players[playerID], Players[playerID] and Players[playerID]:GetUnitByID(unitID)
    if not isFilthy(player) or not unit then return end
    F.ChangePoints(playerID, 3)
    local plot = unit:GetPlot()
    local ownerID = plot and plot:GetOwner() or -1
    if ownerID >= 0 and ownerID ~= playerID then
        local city = closestForeignCity(ownerID, unit:GetX(), unit:GetY(), 3)
        if city then F.ChangeFilth(city, 1, playerID) end
    end
end
local function onCapture(oldOwner, isCapital, x, y, newOwner)
    local plot, player = Map.GetPlot(x, y), Players[newOwner]
    local city = plot and plot:GetPlotCity() or nil
    if isFilthy(player) then
        F.ChangePoints(newOwner, 20)
        if city then setFilth(city, 0) end
    elseif city then
        writeFilth(city, getFilth(city))
    end
    refreshAllCombat()
end
local function onCityTrained(playerID, cityID, unitID)
    local city = cityByID(playerID, cityID)
    if city and isDistorted(city) then
        local unit = Players[playerID] and Players[playerID]:GetUnitByID(unitID) or nil
        if unit and unit:GetExperience() > 0 then unit:ChangeExperience(-math.min(10, unit:GetExperience())) end
    end
end
local function onDeclareWar(playerID, againstTeam, aggressor)
    if not truth(aggressor) then return end
    for targetID = 0, MAX_MAJOR - 1 do
        local target = Players[targetID]
        if isFilthy(target) and target:GetTeam() == againstTeam then
            local key = playerKey(targetID, "WAR_" .. tostring(playerID))
            if getNumber(key, 0) == 0 then setNumber(key, 1); F.ChangePoints(targetID, 20) end
        end
    end
    refreshAuras()
end
local function onMakePeace(playerID, againstTeam)
    local actor = Players[playerID]
    for targetID = 0, MAX_MAJOR - 1 do
        local target = Players[targetID]
        if isFilthy(target) then
            if target:GetTeam() == againstTeam then
                setNumber(playerKey(targetID, "WAR_" .. tostring(playerID)), 0)
            elseif actor and actor:GetTeam() == target:GetTeam() then
                for otherID = 0, MAX_CIV - 1 do
                    local other = Players[otherID]
                    if other and other:GetTeam() == againstTeam then
                        setNumber(playerKey(targetID, "WAR_" .. tostring(otherID)), 0)
                    end
                end
            end
        end
    end
    refreshAuras()
end
local function processWarStates(playerID)
    local player = Players[playerID]
    if not isFilthy(player) then return end
    for otherID = 0, MAX_CIV - 1 do
        local other = Players[otherID]
        if other and otherID ~= playerID and not atWar(player, other) then
            setNumber(playerKey(playerID, "WAR_" .. tostring(otherID)), 0)
        end
    end
end
local function onDenounced(denouncerID, targetID)
    if not isFilthy(targetID) or denouncerID == targetID then return end
    local key = playerKey(targetID, "DENOUNCED_" .. tostring(denouncerID))
    if getNumber(key, 0) == 0 then setNumber(key, 1); F.ChangePoints(targetID, 10) end
end
local function processDenunciations(playerID)
    if not isFilthy(playerID) then return end
    for otherID = 0, MAX_MAJOR - 1 do
        local other = Players[otherID]
        if other and other:IsAlive() and otherID ~= playerID then
            local key = playerKey(playerID, "DENOUNCED_" .. tostring(otherID))
            local active = other.IsDenouncedPlayer and other:IsDenouncedPlayer(playerID)
            if active and getNumber(key, 0) == 0 then F.ChangePoints(playerID, 10) end
            setNumber(key, active and 1 or 0)
        end
    end
end
local function onResolution(resolutionID, proposerID, choice, enact, passed)
    local info = GameInfo.Resolutions[resolutionID]
    if not truth(enact) or not truth(passed) or not info or not truth(info.EmbargoPlayer) then return end
    local targetID = tonumber(choice)
    if not targetID or not isFilthy(targetID) then return end
    local key = playerKey(targetID, "RESOLUTION_" .. tostring(resolutionID) .. "_" .. turn())
    if getNumber(key, 0) == 0 then setNumber(key, 1); F.ChangePoints(targetID, 25) end
end
F.OnTargetedResolution = function(targetID, resolutionID)
    if isFilthy(targetID) then
        local key = playerKey(targetID, "RESOLUTION_" .. tostring(resolutionID) .. "_" .. turn())
        if getNumber(key, 0) == 0 then setNumber(key, 1); F.ChangePoints(targetID, 25) end
    end
end

local function useAI(playerID)
    local player = Players[playerID]
    if not isFilthy(player) or player:IsHuman() then return end
    if F.GetPoints(playerID) >= 80 and F.GetCooldown(playerID, "STOP") == 0 then
        local ok = F.UseStop(playerID); if ok then return end
    end
    if F.GetPoints(playerID) >= 60 then
        local cities = F.GetForeignCities(playerID, false)
        for _, target in ipairs(cities) do if target.cooldown == 0 then
            local ok = F.UseRavioli(playerID, target.owner, target.id, "GOLD"); if ok then return end
        end end
    end
    if F.GetPoints(playerID) >= 40 and F.GetCooldown(playerID, "DISTORTION") == 0 then
        local cities = F.GetForeignCities(playerID, true)
        table.sort(cities, function(a,b) return a.level > b.level end)
        if cities[1] then local ok = F.UseDistortion(playerID, cities[1].owner, cities[1].id); if ok then return end end
    end
    if F.GetPoints(playerID) >= 25 then F.UseSalamander(playerID) end
end

local function onPlayerTurn(playerID)
    local player = Players[playerID]
    if not player or not player:IsAlive() then return end
    refreshTemporary(playerID)
    if isFilthy(player) then
        local expiry = getNumber(playerKey(playerID, "DISTORT_EXPIRES"), -1)
        if expiry >= 0 and expiry <= turn() then
            local city = storedDistortionCity(playerID)
            if city then writeFilth(city, getFilth(city)) end
            setNumber(playerKey(playerID, "DISTORT_EXPIRES"), -1)
        end
        processTrade(playerID)
        processTourism(playerID)
        processGreatWorks(playerID)
        processDenunciations(playerID)
        processWarStates(playerID)
        useAI(playerID)
    else processDecay(playerID) end
    refreshAuras()
    for unit in player:Units() do refreshCombat(unit) end
    changed(playerID)
end
local function onMoved(playerID, unitID)
    local unit = Players[playerID] and Players[playerID]:GetUnitByID(unitID)
    if not unit then return end
    refreshCombat(unit)
    if unit:GetUnitType() == I.Salamander then refreshAuras()
    elseif isMilitary(unit) then refreshAuraUnit(unit, activeSalamanders()) end
end

F.OnPlayerTurn, F.OnPillage, F.OnPrekill, F.OnMoved = onPlayerTurn, onPillage, onPrekill, onMoved
F.RefreshCombat, F.RefreshAuras = refreshAllCombat, refreshAuras

GameEvents.PlayerDoTurn.Add(onPlayerTurn)
GameEvents.UnitPrekill.Add(onPrekill)
GameEvents.CityCaptureComplete.Add(onCapture)
GameEvents.CityTrained.Add(onCityTrained)
GameEvents.BattleStarted.Add(function() battles[#battles + 1] = {} end)
GameEvents.BattleJoined.Add(function(playerID, unitID, role, isCity)
    local battle = battles[#battles]; if battle then battle[role] = {playerID=playerID,unitID=unitID,isCity=truth(isCity)} end
end)
GameEvents.BattleFinished.Add(function()
    if #battles > 0 then table.remove(battles) end
    refreshAuras()
end)
if GameEvents.UnitSetXY then GameEvents.UnitSetXY.Add(onMoved) end
if GameEvents.PlayerCanGiftUnit then
    GameEvents.PlayerCanGiftUnit.Add(function(playerID, minorID, unitID)
        local player = Players[playerID]
        local unit = player and player:GetUnitByID(unitID) or nil
        return not unit or unit:GetUnitType() ~= I.Salamander
    end)
end
if GameEvents.UnitPillageGold then
    GameEvents.UnitPillageGold.Add(function(playerID, unitID, improvementID, gold)
        onPillage(playerID, unitID)
        return gold
    end)
end
if GameEvents.DeclareWar then GameEvents.DeclareWar.Add(onDeclareWar) end
if GameEvents.MakePeace then GameEvents.MakePeace.Add(onMakePeace) end
if GameEvents.PlayerDenouncedPlayer then GameEvents.PlayerDenouncedPlayer.Add(onDenounced)
elseif GameEvents.DenouncedPlayer then GameEvents.DenouncedPlayer.Add(onDenounced) end
if GameEvents.ResolutionResult then GameEvents.ResolutionResult.Add(onResolution) end
if GameEvents.PlayerTargetedByResolution then GameEvents.PlayerTargetedByResolution.Add(F.OnTargetedResolution) end
if GameEvents.GreatWorkCreated then GameEvents.GreatWorkCreated.Add(onGreatWorkCreated) end
if GameEvents.UnitConverted then GameEvents.UnitConverted.Add(function() refreshAuras(); refreshAllCombat() end) end

for playerID = 0, MAX_MAJOR - 1 do
    local player = Players[playerID]
    if isFilthy(player) then
        local _, counts = currentRoutes(playerID)
        routeCache[playerID] = counts
        snapshotGreatWorks(playerID)
    end
end
refreshAuras()
refreshAllCombat()
print("Filthy Realm: runtime loaded")
