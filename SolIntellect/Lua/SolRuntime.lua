-- The Sol Intellect. CP city production runs BEFORE PlayerDoTurn.
-- PlayerDoneTurn arms the exact queue head for the next native city turn.
-- Completion settles that turn early; PlayerDoTurn settles unfinished work.
-- Dirty events observe order changes but never increment construction turns.
-- MapModData may survive an engine reload; only this add-in's _G can guard
-- duplicate registration. A fresh context must reopen authoritative save data.
if rawget(_G, "__SOL_RUNTIME_CONTEXT_LOADED") then return end
rawset(_G, "__SOL_RUNTIME_CONTEXT_LOADED", true)
MapModData.SolIntellect = {}
local S = MapModData.SolIntellect
S.RuntimeLoaded = true

local CIV = GameInfoTypes.CIVILIZATION_GPT_SOL
local ARCHIVE = GameInfoTypes.BUILDING_SOL_CONTEXT_ARCHIVE
local INSTITUTE = GameInfoTypes.BUILDING_SOL_REASONING_INSTITUTE
local INSIGHT = GameInfoTypes.BUILDING_SOL_INSIGHT
local CULTURE = GameInfoTypes.BUILDING_SOL_CONTEXT_CULTURE
local REASONING = GameInfoTypes.BUILDING_SOL_REASONING_INSIGHT_SCIENCE
local CONSTRUCT = OrderTypes.ORDER_CONSTRUCT
local save = Modding.OpenSaveData()
local states, refreshing, awarding = {}, false, false
local function turn() return Game.GetGameTurn() end
local function truth(value) return value == true or value == 1 end
local function isSol(player)
    return player and player:IsAlive() and player:GetCivilizationType() == CIV
end
local function clamp(value) return math.max(0, math.min(5, math.floor(tonumber(value) or 0))) end

-- Deterministic length-prefixed serialization; never executes save strings.
local function encode(value)
    local kind = type(value)
    if kind == "number" then return "n" .. tostring(value) .. ";" end
    if kind == "boolean" then return value and "b1" or "b0" end
    if kind == "string" then return "s" .. #value .. ":" .. value end
    if kind ~= "table" then error("Sol: unsupported save value " .. kind) end
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return type(a) .. tostring(a) < type(b) .. tostring(b) end)
    local out = {"t", tostring(#keys), ":"}
    for _, key in ipairs(keys) do
        out[#out + 1] = encode(key)
        out[#out + 1] = encode(value[key])
    end
    return table.concat(out)
end

local function decode(source)
    local pos = 1
    local function read(depth)
        if depth > 12 then error("Sol: invalid save depth") end
        local tag = source:sub(pos, pos)
        pos = pos + 1
        if tag == "b" then
            local bit = source:sub(pos, pos)
            pos = pos + 1
            if bit ~= "0" and bit ~= "1" then error("Sol: invalid save boolean") end
            return bit == "1"
        end
        local stop = source:find(tag == "n" and ";" or ":", pos, true)
        if not stop then error("Sol: incomplete save") end
        local n = tonumber(source:sub(pos, stop - 1))
        pos = stop + 1
        if not n then error("Sol: invalid save number") end
        if tag == "n" then return n end
        if n < 0 or n > 1000000 or n ~= math.floor(n) then error("Sol: invalid save length") end
        if tag == "s" then
            if pos + n - 1 > #source then error("Sol: truncated save") end
            local value = source:sub(pos, pos + n - 1)
            pos = pos + n
            return value
        end
        if tag ~= "t" then error("Sol: invalid save tag") end
        local result = {}
        for _ = 1, n do
            local key = read(depth + 1)
            result[key] = read(depth + 1)
        end
        return result
    end
    local result = read(0)
    if pos ~= #source + 1 then error("Sol: trailing save data") end
    return result
end

local function state(playerID)
    if not states[playerID] then
        local raw = save.GetValue("SOL_V1_PLAYER_" .. playerID)
        local loaded
        if type(raw) == "string" and raw ~= "" then
            local ok, value = pcall(decode, raw)
            if not ok or type(value) ~= "table" then error("Sol: cannot read saved state") end
            loaded = value
        end
        states[playerID] = loaded or {cities = {}, pendingScience = 0}
    end
    return states[playerID]
end
local function persist(playerID)
    save.SetValue("SOL_V1_PLAYER_" .. playerID, encode(state(playerID)))
end

local function record(playerID, city)
    local data, cityID = state(playerID), city:GetID()
    local r = data.cities[cityID]
    -- Coordinates prevent a recycled city ID from inheriting another city's state.
    if r and (r.x ~= city:GetX() or r.y ~= city:GetY()) then r = nil end
    if not r then
        r = {x = city:GetX(), y = city:GetY(), insight = 0, order = -1, item = -1,
             turns = 0, armed = false, armTurn = -1, armThings = -1,
             lastSettled = -1, completedTurn = -1, completedItem = -1, completedThings = -1}
        data.cities[cityID] = r
    end
    return r
end

local function head(city)
    local order, item = city:GetOrderFromQueue(0)
    if order == nil or order < 0 then return -1, -1 end
    return order, item
end

local function observe(playerID, city)
    local r = record(playerID, city)
    local order, item = head(city)
    if r.order ~= order or r.item ~= item then
        r.order, r.item, r.turns, r.armed = order, item, 0, false
        return true
    end
    return false
end

local function setCount(city, building, count)
    if city:GetNumRealBuilding(building) ~= count then city:SetNumRealBuilding(building, count) end
end

local specialists = {}
for info in GameInfo.Specialists() do
    -- Unemployed Citizens are not specialists worked in building slots.
    if info.Type ~= "SPECIALIST_CITIZEN" then specialists[#specialists + 1] = info.ID end
end

local function updateYields(playerID, city)
    local r = record(playerID, city)
    r.insight = clamp(r.insight)
    local count = 0
    if city:GetNumBuilding(ARCHIVE) > 0 then
        for _, specialist in ipairs(specialists) do count = count + city:GetSpecialistCount(specialist) end
    end
    setCount(city, INSIGHT, r.insight)
    setCount(city, CULTURE, math.floor(count / 3))
    setCount(city, REASONING, city:GetNumBuilding(INSTITUTE) > 0 and math.floor(r.insight / 2) or 0)
end

local function notify(playerID, city, message)
    local player = Players[playerID]
    if player:IsHuman() then
        player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message,
            Locale.ConvertTextKey("TXT_KEY_SOL_NOTICE_TITLE"), city:GetX(), city:GetY())
    end
end

local function flushScience(playerID)
    if awarding then return end
    local player, data = Players[playerID], state(playerID)
    local tech = player:GetCurrentResearch()
    local amount = math.floor(data.pendingScience or 0)
    if amount <= 0 or tech == nil or tech < 0 then return end
    -- Consume the saved bank before native research/tech events can re-enter.
    awarding = true
    data.pendingScience = 0
    persist(playerID)
    Teams[player:GetTeam()]:GetTeamTechs():ChangeResearchProgress(tech, amount, playerID)
    awarding = false
end

local function scienceBurst(cost, turns)
    if cost <= 0 or turns < 4 then return 0 end
    local percent = math.min(24, 12 + 2 * (turns - 4))
    return math.max(1, math.floor(cost * percent / 100))
end

local function isWonder(building)
    local class = GameInfo.BuildingClasses[building.BuildingClass]
    return class and ((tonumber(class.MaxGlobalInstances) or -1) > 0
        or (tonumber(class.MaxPlayerInstances) or -1) > 0)
end

local function onConstructed(playerID, cityID, buildingID, gold, faith)
    local player = Players[playerID]
    if not isSol(player) then return end
    local city = player:GetCityByID(cityID)
    if not city then return end
    local r = record(playerID, city)
    local order, item = head(city)
    local info = GameInfo.Buildings[buildingID]
    local things = city:GetNumThingsProduced()
    local duplicate = r.completedTurn == turn() and r.completedItem == buildingID and r.completedThings == things
    -- Native produce() increments ThingsProduced before CityConstructed and
    -- leaves the completed item at the queue head until after the callback.
    -- FreeStartEra grants fire CityConstructed too, but do neither of these.
    local genuine = not truth(gold) and not truth(faith) and not duplicate
        and info and order == CONSTRUCT and item == buildingID
        and r.armed and r.armTurn + 1 == turn() and things == r.armThings + 1
    if genuine then
        local duration = (r.order == order and r.item == item) and r.turns + 1 or 1
        local eligible = (tonumber(info.Cost) or -1) > 0
        local amount = eligible and scienceBurst(city:GetBuildingProductionNeeded(buildingID), duration) or 0
        local gain = eligible and isWonder(info) and r.insight < 5
        r.completedTurn, r.completedItem, r.completedThings = turn(), buildingID, things
        r.lastSettled, r.armed, r.turns, r.order, r.item = turn(), false, 0, -1, -1
        if gain then r.insight = clamp(r.insight + 1) end
        state(playerID).pendingScience = (state(playerID).pendingScience or 0) + amount
        persist(playerID)
        updateYields(playerID, city)
        flushScience(playerID)
        if amount > 0 then
            notify(playerID, city, Locale.ConvertTextKey("TXT_KEY_SOL_NOTICE_SCIENCE", city:GetName(),
                Locale.ConvertTextKey(info.Description), duration, amount))
        end
        if gain then
            notify(playerID, city, Locale.ConvertTextKey(r.insight == 5 and "TXT_KEY_SOL_NOTICE_MAX_INSIGHT"
                or "TXT_KEY_SOL_NOTICE_INSIGHT", city:GetName(), r.insight))
        end
    elseif truth(gold) or truth(faith) then
        -- Buying the actively tracked building must discard its timer too.
        if r.order == CONSTRUCT and r.item == buildingID then
            r.armed, r.turns, r.order, r.item = false, 0, -1, -1
            persist(playerID)
        end
    end
    updateYields(playerID, city)
end

local function purgeMissing(playerID, player)
    local changed = false
    for cityID, r in pairs(state(playerID).cities) do
        local city = player:GetCityByID(cityID)
        if not city or city:GetX() ~= r.x or city:GetY() ~= r.y then
            state(playerID).cities[cityID] = nil
            changed = true
        end
    end
    return changed
end

local function onDoneTurn(playerID)
    local player = Players[playerID]
    if not isSol(player) then return end
    purgeMissing(playerID, player)
    for city in player:Cities() do
        observe(playerID, city)
        local r = record(playerID, city)
        -- Duplicate end-turn calls cannot count an extra turn.
        r.armed, r.armTurn, r.armThings = true, turn(), city:GetNumThingsProduced()
        updateYields(playerID, city)
    end
    persist(playerID)
end

local function onPlayerTurn(playerID)
    local player = Players[playerID]
    if not isSol(player) then
        if player and player:GetCivilizationType() == CIV and next(state(playerID).cities) then
            state(playerID).cities = {}
            persist(playerID)
        end
        return
    end
    purgeMissing(playerID, player)
    for city in player:Cities() do
        local r = record(playerID, city)
        local order, item = head(city)
        if r.lastSettled ~= turn() and r.armed and r.armTurn + 1 == turn() then
            local worked = order >= 0 and not city:IsResistance() and not city:IsRazing()
                and city:GetNumThingsProduced() == r.armThings
            r.turns = worked and ((r.order == order and r.item == item) and r.turns + 1 or 1) or 0
            r.order, r.item, r.armed, r.lastSettled = order, item, false, turn()
        else
            if r.armed and r.armTurn + 1 < turn() then r.turns, r.armed = 0, false end
            observe(playerID, city)
        end
        updateYields(playerID, city)
    end
    persist(playerID)
    flushScience(playerID)
end

local function clearAt(playerID, x, y)
    if playerID == nil or playerID < 0 then return end
    local changed = false
    for cityID, r in pairs(state(playerID).cities) do
        if r.x == x and r.y == y then state(playerID).cities[cityID], changed = nil, true end
    end
    if changed then persist(playerID) end
end

local function onCapture(oldOwner, _, x, y, newOwner)
    clearAt(oldOwner, x, y)
    clearAt(newOwner, x, y)
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city then
        setCount(city, INSIGHT, 0)
        setCount(city, CULTURE, 0)
        setCount(city, REASONING, 0)
        if isSol(Players[newOwner]) then
            observe(newOwner, city)
            updateYields(newOwner, city)
            persist(newOwner)
        end
    end
end

local function onDestroyed(_, playerID, cityID)
    if playerID == nil or cityID == nil then return end
    if state(playerID).cities[cityID] then
        state(playerID).cities[cityID] = nil
        persist(playerID)
    end
end

local function refreshCity(playerID, cityID)
    if refreshing then return end
    local player = Players[playerID]
    if not isSol(player) then return end
    local city = player:GetCityByID(cityID)
    if not city then return end
    refreshing = true
    -- Do not erase an armed production snapshot during the next native city
    -- cycle: AI selection may change the head before genuine completion.
    local r = record(playerID, city)
    if not (r.armed and r.armTurn + 1 == turn()) and observe(playerID, city) then persist(playerID) end
    updateYields(playerID, city)
    refreshing = false
end

local function refreshActive()
    if refreshing or awarding then return end
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    if not isSol(player) then return end
    for city in player:Cities() do refreshCity(playerID, city:GetID()) end
    flushScience(playerID)
end

local function onLoad()
    for playerID, player in pairs(Players) do
        if player:GetCivilizationType() == CIV then
            purgeMissing(playerID, player)
            if isSol(player) then
                for city in player:Cities() do refreshCity(playerID, city:GetID()) end
            end
            persist(playerID)
            if isSol(player) then flushScience(playerID) end
        end
    end
end

local function onFounded(playerID, x, y)
    if not isSol(Players[playerID]) then return end
    clearAt(playerID, x, y)
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city then refreshCity(playerID, city:GetID()); persist(playerID) end
end

local function onOtherCompletion(playerID, cityID, _, gold, faith)
    local player = Players[playerID]
    if not isSol(player) then return end
    local city = player:GetCityByID(cityID)
    if not city then return end
    local r = record(playerID, city)
    if not truth(gold) and not truth(faith) and r.armed and r.armTurn + 1 == turn()
        and city:GetNumThingsProduced() > r.armThings then
        -- A unit/project consumes the native city cycle. A subsequent free
        -- building hook must not borrow its native completion-counter delta.
        r.armed, r.turns, r.order, r.item, r.lastSettled = false, 0, -1, -1, turn()
        persist(playerID)
    end
    refreshCity(playerID, cityID)
end

-- Public diagnostics used by the deterministic Lua 5.1 acceptance harness.
S.GetState, S.ScienceBurst = state, scienceBurst
S.RefreshCity, S.OnLoad = refreshCity, onLoad
GameEvents.PlayerDoneTurn.Add(onDoneTurn)
GameEvents.PlayerDoTurn.Add(onPlayerTurn)
GameEvents.CityConstructed.Add(onConstructed)
GameEvents.CityCaptureComplete.Add(onCapture)
GameEvents.PlayerCityFounded.Add(onFounded)
GameEvents.CitySoldBuilding.Add(function(playerID, cityID) refreshCity(playerID, cityID) end)
if GameEvents.CityTrained then GameEvents.CityTrained.Add(onOtherCompletion) end
if GameEvents.CityCreated then GameEvents.CityCreated.Add(onOtherCompletion) end
Events.SpecificCityInfoDirty.Add(refreshCity)
Events.SerialEventCityInfoDirty.Add(refreshActive)
Events.SerialEventGameDataDirty.Add(refreshActive)
Events.SerialEventCityDestroyed.Add(onDestroyed)
Events.LoadScreenClose.Add(onLoad)
onLoad()
print("Sol Intellect: save-backed runtime loaded")
