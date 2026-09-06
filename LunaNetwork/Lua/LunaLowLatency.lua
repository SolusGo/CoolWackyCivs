-- The Luna Network: save-backed production refunds and temporary deployment speed.
MapModData.LunaNetwork = MapModData.LunaNetwork or {}
local L = MapModData.LunaNetwork
if L.RuntimeLoaded then return end
L.RuntimeLoaded = true

local function ID(name) return GameInfoTypes[name] end
local CIV_LUNA = ID("CIVILIZATION_GPT_LUNA")
local PACKET_SETTLER = ID("UNIT_LUNA_PACKET_SETTLER")
local RAPID_RESPONSE = ID("PROMOTION_LUNA_RAPID_RESPONSE")
local LAND, SEA = DomainTypes.DOMAIN_LAND, DomainTypes.DOMAIN_SEA
local save = Modding.OpenSaveData()
local states = {}

local function truth(value) return value == true or value == 1 end
local function currentTurn() return Game.GetGameTurn() end
local function isLuna(player)
    return player ~= nil and player:IsAlive() and player:GetCivilizationType() == CIV_LUNA
end

-- Length-prefixed persistence avoids executable serialization and survives save/load.
local function encode(value)
    local kind = type(value)
    if kind == "number" then return "n" .. tostring(value) .. ";" end
    if kind == "boolean" then return value and "b1" or "b0" end
    if kind == "string" then return "s" .. #value .. ":" .. value end
    if kind ~= "table" then error("Luna: unsupported save value " .. kind) end
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return type(a) .. tostring(a) < type(b) .. tostring(b) end)
    local output = {"t", tostring(#keys), ":"}
    for _, key in ipairs(keys) do
        output[#output + 1] = encode(key)
        output[#output + 1] = encode(value[key])
    end
    return table.concat(output)
end

local function decode(source)
    local position = 1
    local function read(depth)
        if depth > 12 then error("Luna: malformed save nesting") end
        local tag = source:sub(position, position)
        position = position + 1
        if tag == "b" then
            local flag = source:sub(position, position)
            position = position + 1
            return flag == "1"
        end
        local delimiter = tag == "n" and ";" or ":"
        local stop = source:find(delimiter, position, true)
        if stop == nil then error("Luna: incomplete save") end
        local count = tonumber(source:sub(position, stop - 1))
        position = stop + 1
        if count == nil then error("Luna: invalid save number") end
        if tag == "n" then return count end
        if count < 0 or count > 1000000 or count ~= math.floor(count) then error("Luna: invalid save length") end
        if tag == "s" then
            if position + count - 1 > #source then error("Luna: truncated save string") end
            local value = source:sub(position, position + count - 1)
            position = position + count
            return value
        end
        if tag ~= "t" then error("Luna: invalid save tag") end
        local value = {}
        for _ = 1, count do value[read(depth + 1)] = read(depth + 1) end
        return value
    end
    local value = read(0)
    if position ~= #source + 1 then error("Luna: trailing save data") end
    return value
end

local function state(playerID)
    if states[playerID] == nil then
        local loaded = nil
        local raw = save.GetValue("LUNA_V1_PLAYER_" .. tostring(playerID))
        if currentTurn() > 0 and type(raw) == "string" and raw ~= "" then
            local ok, value = pcall(decode, raw)
            if not ok or type(value) ~= "table" then
                error("Luna: could not read persistent state: " .. tostring(value))
            end
            loaded = value
        end
        states[playerID] = loaded or {cities = {}, units = {}}
        states[playerID].cities = states[playerID].cities or {}
        states[playerID].units = states[playerID].units or {}
    end
    return states[playerID]
end

local function persist(playerID)
    save.SetValue("LUNA_V1_PLAYER_" .. tostring(playerID), encode(state(playerID)))
end

local function cityRecord(playerID, city, create)
    local data = state(playerID)
    local cityID = city:GetID()
    local record = data.cities[cityID]
    if record ~= nil and (record.x ~= city:GetX() or record.y ~= city:GetY()) then
        data.cities[cityID] = nil
        record = nil
    end
    if record == nil and create then
        record = {x = city:GetX(), y = city:GetY(), pending = 0}
        data.cities[cityID] = record
    end
    return record
end

local function hasConstruction(city)
    return city:GetProductionUnit() >= 0
        or city:GetProductionBuilding() >= 0
        or (city.GetProductionProject ~= nil and city:GetProductionProject() >= 0)
end

local function tryApplyPending(playerID, city)
    local record = cityRecord(playerID, city, false)
    local amount = record and math.floor(tonumber(record.pending) or 0) or 0
    if amount <= 0 or not hasConstruction(city) then return false end
    city:ChangeProduction(amount)
    record.pending = 0
    persist(playerID)
    return true
end

local function addRefund(playerID, city, amount)
    if amount <= 0 then return end
    local record = cityRecord(playerID, city, true)
    record.pending = math.floor(tonumber(record.pending) or 0) + amount
    persist(playerID)
    tryApplyPending(playerID, city)
end

local function isMilitary(unit)
    return unit ~= nil and unit.IsCombatUnit ~= nil and unit:IsCombatUnit()
end

local function isRapidDomain(unit)
    local domain = unit:GetDomainType()
    return domain == LAND or domain == SEA
end

local function productionRefund(cost)
    cost = math.floor(tonumber(cost) or 0)
    if cost <= 0 then return 0 end
    return math.max(1, math.floor(cost * 0.10))
end

local function eligibleBuilding(buildingType)
    local building = GameInfo.Buildings[buildingType]
    if building == nil or (tonumber(building.Cost) or -1) <= 0 then return false end
    local class = GameInfo.BuildingClasses[building.BuildingClass]
    if class == nil then return false end
    return (tonumber(class.MaxGlobalInstances) or -1) <= 0
        and (tonumber(class.MaxTeamInstances) or -1) <= 0
        and (tonumber(class.MaxPlayerInstances) or -1) <= 0
end

local function onCityTrained(playerID, cityID, unitID, boughtWithGold, boughtWithFaith)
    local player = Players[playerID]
    if not isLuna(player) or truth(boughtWithGold) or truth(boughtWithFaith) then return end
    local city, unit = player:GetCityByID(cityID), player:GetUnitByID(unitID)
    if city == nil or not isMilitary(unit) then return end

    local unitType = unit:GetUnitType()
    if unitType ~= PACKET_SETTLER then
        addRefund(playerID, city, productionRefund(city:GetUnitProductionNeeded(unitType)))
    end
    if isRapidDomain(unit) then
        unit:SetHasPromotion(RAPID_RESPONSE, true)
        state(playerID).units[unitID] = currentTurn() + 2
        persist(playerID)
    end
end

local function onCityConstructed(playerID, cityID, buildingType, boughtWithGold, boughtWithFaith)
    local player = Players[playerID]
    if not isLuna(player) or truth(boughtWithGold) or truth(boughtWithFaith) then return end
    local city = player:GetCityByID(cityID)
    if city == nil or not eligibleBuilding(buildingType) then return end
    addRefund(playerID, city, productionRefund(city:GetBuildingProductionNeeded(buildingType)))
end

local function cleanCityState(playerID, player)
    local data, changed = state(playerID), false
    for cityID, record in pairs(data.cities) do
        local city = player:GetCityByID(cityID)
        if city == nil or city:GetX() ~= record.x or city:GetY() ~= record.y then
            data.cities[cityID] = nil
            changed = true
        else
            tryApplyPending(playerID, city)
        end
    end
    return changed
end

local function cleanRapidResponse(playerID, player)
    local data, changed = state(playerID), false
    for unitID, expiry in pairs(data.units) do
        local unit = player:GetUnitByID(unitID)
        if unit == nil or not unit:IsHasPromotion(RAPID_RESPONSE) then
            data.units[unitID] = nil
            changed = true
        elseif currentTurn() >= (tonumber(expiry) or 0) then
            unit:SetHasPromotion(RAPID_RESPONSE, false)
            data.units[unitID] = nil
            changed = true
        end
    end
    return changed
end

local function onPlayerTurn(playerID)
    local player = Players[playerID]
    if not isLuna(player) then return end
    local changed = cleanCityState(playerID, player)
    if cleanRapidResponse(playerID, player) then changed = true end
    if changed then persist(playerID) end
end

local function onUnitCreated(playerID, unitID)
    local player = Players[playerID]
    if not isLuna(player) then return end
    local data = state(playerID)
    if data.units[unitID] ~= nil then
        data.units[unitID] = nil
        local unit = player:GetUnitByID(unitID)
        if unit ~= nil then unit:SetHasPromotion(RAPID_RESPONSE, false) end
        persist(playerID)
    end
end

local function onUnitConverted(oldPlayerID, newPlayerID, oldUnitID, newUnitID)
    local oldData = state(oldPlayerID)
    local expiry = oldData.units[oldUnitID]
    if expiry == nil then return true end
    oldData.units[oldUnitID] = nil
    persist(oldPlayerID)

    local newPlayer = Players[newPlayerID]
    local newUnit = newPlayer and newPlayer:GetUnitByID(newUnitID) or nil
    if isLuna(newPlayer) and newUnit ~= nil and currentTurn() < expiry then
        newUnit:SetHasPromotion(RAPID_RESPONSE, true)
        state(newPlayerID).units[newUnitID] = expiry
        persist(newPlayerID)
    elseif newUnit ~= nil then
        newUnit:SetHasPromotion(RAPID_RESPONSE, false)
    end
    return true
end

local function clearCityAt(playerID, x, y)
    if playerID == nil or playerID < 0 then return end
    local data, changed = state(playerID), false
    for cityID, record in pairs(data.cities) do
        if record.x == x and record.y == y then data.cities[cityID] = nil; changed = true end
    end
    if changed then persist(playerID) end
end

local function onCityCaptureComplete(oldOwnerID, _, x, y, newOwnerID)
    clearCityAt(oldOwnerID, x, y)
    clearCityAt(newOwnerID, x, y)
end

-- Exposed for deterministic Lua mocks and diagnostics.
L.GetState = state
L.TryApplyPending = tryApplyPending
L.OnCityTrained = onCityTrained
L.OnCityConstructed = onCityConstructed
L.OnPlayerTurn = onPlayerTurn
L.OnUnitCreated = onUnitCreated
L.OnUnitConverted = onUnitConverted
L.OnCityCaptureComplete = onCityCaptureComplete

GameEvents.PlayerDoTurn.Add(onPlayerTurn)
GameEvents.CityTrained.Add(onCityTrained)
GameEvents.CityConstructed.Add(onCityConstructed)
GameEvents.CityCaptureComplete.Add(onCityCaptureComplete)
if GameEvents.UnitCreated then GameEvents.UnitCreated.Add(onUnitCreated) end
if GameEvents.UnitConverted then GameEvents.UnitConverted.Add(onUnitConverted) end
