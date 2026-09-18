-- The Dual Order runtime: Twin Mandates, Balance Pressure, Zeal and Divided Templar conditions.

MapModData.DualOrder = MapModData.DualOrder or {}
local D = MapModData.DualOrder
if D.RuntimeLoaded then return end

local I = {
    Civilization = GameInfoTypes.CIVILIZATION_DUAL_ORDER,
    Hall = GameInfoTypes.BUILDING_DUAL_ORDER_HALL_CONCORDANCE,
    Mandate = GameInfoTypes.BUILDING_DUAL_ORDER_MANDATE_YIELDS,
    Golden = GameInfoTypes.BUILDING_DUAL_ORDER_GOLDEN_ARMAMENT,
    HallHappiness = GameInfoTypes.BUILDING_DUAL_ORDER_HALL_HAPPINESS,
    Zeal = GameInfoTypes.PROMOTION_DUAL_ORDER_ZEAL,
    ZealActive = GameInfoTypes.PROMOTION_DUAL_ORDER_ZEAL_ACTIVE,
    Schism = GameInfoTypes.PROMOTION_DUAL_ORDER_SCHISM_STRIKE,
    SchismWounded = GameInfoTypes.PROMOTION_DUAL_ORDER_SCHISM_WOUNDED,
    HolySupport = GameInfoTypes.PROMOTION_DUAL_ORDER_HOLY_SUPPORT,
}
I.BalanceBuildings, I.BalancePromotions = {}, {}
for level = 1, 5 do
    I.BalanceBuildings[level] = GameInfoTypes["BUILDING_DUAL_ORDER_BALANCE_" .. level]
    I.BalancePromotions[level] = GameInfoTypes["PROMOTION_DUAL_ORDER_BALANCE_" .. level]
end

local battles, states, excludedSupport = {}, {}, {}
local classRoles, buildingRoles, buildingClasses, religiousUnits = {}, {}, {}, {}

local function truth(value) return value == true or value == 1 end
local function isDual(value)
    local player = type(value) == "number" and Players[value] or value
    return player ~= nil and player:IsAlive() and player:GetCivilizationType() == I.Civilization
end
local function getUnit(playerID, unitID)
    local player = Players[playerID]
    return player and player:GetUnitByID(unitID) or nil
end
local function isMilitary(unit)
    if unit == nil then return false end
    if unit.IsCombatUnit then return unit:IsCombatUnit() end
    local info = GameInfo.Units[unit:GetUnitType()]
    return info ~= nil and ((info.Combat or 0) > 0 or (info.RangedCombat or 0) > 0)
end
local function setPromotion(unit, promotion, enabled)
    if unit ~= nil and promotion ~= nil and unit:IsHasPromotion(promotion) ~= enabled then
        unit:SetHasPromotion(promotion, enabled)
    end
end
local function setBuilding(city, building, count)
    if city ~= nil and building ~= nil and city:GetNumRealBuilding(building) ~= count then
        city:SetNumRealBuilding(building, count)
    end
end
local function hasBuilding(city, building)
    if city == nil or building == nil then return false end
    if city.IsHasBuilding then return city:IsHasBuilding(building) end
    return city:GetNumRealBuilding(building) > 0
end
local function adjacentPlot(plot, direction)
    if plot == nil then return nil end
    return Map.PlotDirection(plot:GetX(), plot:GetY(), direction)
end

local function buildLookups()
    if GameInfo.DualOrderBuildingRoles then
        for row in GameInfo.DualOrderBuildingRoles() do
            local role = classRoles[row.BuildingClassType] or {mandate=false, military=false, religious=false}
            if row.RoleType == "MANDATE" then role.mandate = true
            elseif row.RoleType == "MILITARY" then role.military = true
            elseif row.RoleType == "RELIGIOUS" then role.religious = true end
            classRoles[row.BuildingClassType] = role
        end
    end
    for row in GameInfo.Buildings() do
        local role = classRoles[row.BuildingClass]
        if role then
            buildingRoles[row.ID] = role
            buildingClasses[row.ID] = row.BuildingClass
        end
    end
    local supportClasses = {
        UNITCLASS_PROPHET=true, UNITCLASS_MISSIONARY=true, UNITCLASS_INQUISITOR=true,
    }
    for row in GameInfo.Units() do
        if supportClasses[row.Class] then religiousUnits[row.ID] = true end
    end
end
buildLookups()

local function cityInfrastructure(city)
    local mandates, military, religious = 0, false, false
    local countedMandateClasses = {}
    for buildingID, role in pairs(buildingRoles) do
        if hasBuilding(city, buildingID) then
            local buildingClass = buildingClasses[buildingID]
            if role.mandate and not countedMandateClasses[buildingClass] then
                mandates = mandates + 1
                countedMandateClasses[buildingClass] = true
            end
            military = military or role.military
            religious = religious or role.religious
        end
    end
    return mandates, military, religious
end

local function faithPerTurnTimes100(player)
    if player.GetTotalFaithPerTurnTimes100 then
        return player:GetTotalFaithPerTurnTimes100() or 0
    end
    if player.GetTotalFaithPerTurn then return (player:GetTotalFaithPerTurn() or 0) * 100 end
    if player.GetFaithPerTurn then return (player:GetFaithPerTurn() or 0) * 100 end
    return 0
end
local function activeWars(player)
    local count, teamID = 0, player:GetTeam()
    local team = Teams[teamID]
    if team == nil then return 0 end
    for otherID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local other = Players[otherID]
        if otherID ~= player:GetID() and other and other:IsAlive()
            and not other:IsMinorCiv() and not other:IsBarbarian()
            and other:GetTeam() ~= teamID and team:IsAtWar(other:GetTeam()) then
            count = count + 1
            if count >= 5 then return 5 end
        end
    end
    return count
end
local function isGoldenAge(player)
    if player.IsGoldenAge then return player:IsGoldenAge() end
    return player.GetGoldenAgeTurns and player:GetGoldenAgeTurns() > 0 or false
end
local function balanceState(player)
    local wars, faithTimes100 = activeWars(player), faithPerTurnTimes100(player)
    local active = wars > 0 and faithTimes100 > 0
    return {wars=wars, faith=faithTimes100 / 100, faithTimes100=faithTimes100, active=active,
        combat=active and wars * 2 or 0, production=active and wars or 0}
end
local function foundedReligion(player)
    if not player.GetReligionCreatedByPlayer then return -1 end
    local religion = player:GetReligionCreatedByPlayer()
    local pantheon = ReligionTypes and ReligionTypes.RELIGION_PANTHEON or 0
    return religion ~= nil and religion > pantheon and religion or -1
end

local function friendlyTerritory(unit)
    local player = Players[unit:GetOwner()]
    if player == nil then return false end
    local teamID, plot = player:GetTeam(), unit:GetPlot()
    local function friendly(candidate)
        if candidate == nil then return false end
        local owner = candidate:GetOwner()
        return owner ~= nil and owner >= 0 and Players[owner] ~= nil
            and Players[owner]:GetTeam() == teamID
    end
    if friendly(plot) then return true end
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        if friendly(adjacentPlot(plot, direction)) then return true end
    end
    return false
end
local function unitKey(playerID, unitID) return playerID .. ":" .. unitID end
local function hasHolySupport(unit)
    if unit == nil or not unit:IsHasPromotion(I.Schism) then return false end
    local plot = unit:GetPlot()
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local adjacent = adjacentPlot(plot, direction)
        if adjacent then
            for index = 0, adjacent:GetNumUnits() - 1 do
                local support = adjacent:GetUnit(index)
                if support and support:GetOwner() == unit:GetOwner()
                    and religiousUnits[support:GetUnitType()]
                    and not excludedSupport[unitKey(support:GetOwner(), support:GetID())] then return true end
            end
        end
    end
    return false
end
local function refreshUnit(unit, state)
    if unit == nil then return end
    local military, dual = isMilitary(unit), isDual(unit:GetOwner())
    -- Earned unique promotions remain meaningful if a unit is upgraded or changes owners.
    setPromotion(unit, I.ZealActive,
        military and unit:IsHasPromotion(I.Zeal) and friendlyTerritory(unit))
    setPromotion(unit, I.HolySupport, military and hasHolySupport(unit))
    for level = 1, 5 do
        setPromotion(unit, I.BalancePromotions[level],
            dual and state ~= nil and state.active and state.wars == level)
    end
end
local function refreshCity(player, city, state, golden, religion)
    local mandates = cityInfrastructure(city)
    setBuilding(city, I.Mandate, mandates)
    for level = 1, 5 do
        setBuilding(city, I.BalanceBuildings[level], state.active and state.wars == level and 1 or 0)
    end
    setBuilding(city, I.Golden, golden and 1 or 0)
    local follows = religion >= 0 and city.GetReligiousMajority
        and city:GetReligiousMajority() == religion
    setBuilding(city, I.HallHappiness,
        hasBuilding(city, I.Hall) and follows and 1 or 0)
end
local function changed(previous, current)
    return previous == nil or previous.wars ~= current.wars
        or previous.faithTimes100 ~= current.faithTimes100
        or previous.active ~= current.active or previous.golden ~= current.golden
end
local function refreshPlayer(playerID)
    local player = Players[playerID]
    if not isDual(player) then return nil end
    local state = balanceState(player)
    state.golden = isGoldenAge(player)
    local previous = states[playerID]
    states[playerID] = state
    local religion = foundedReligion(player)
    for city in player:Cities() do refreshCity(player, city, state, state.golden, religion) end
    for unit in player:Units() do refreshUnit(unit, state) end
    if changed(previous, state) and LuaEvents and LuaEvents.DualOrderStateChanged then
        LuaEvents.DualOrderStateChanged(playerID)
    end
    return state
end
local function refreshAll()
    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do refreshPlayer(playerID) end
end
local function refreshAllUnits()
    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[playerID]
        if player and player:IsAlive() then
            local dual, state = isDual(player), nil
            if dual then state = balanceState(player) end
            if dual then
                state.golden = isGoldenAge(player)
                states[playerID] = state
            end
            for unit in player:Units() do
                if dual or unit:IsHasPromotion(I.Zeal) or unit:IsHasPromotion(I.Schism) then
                    refreshUnit(unit, state)
                end
            end
        end
    end
end
local function refreshSchismUnits()
    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[playerID]
        if player and player:IsAlive() then
            local state = isDual(player) and balanceState(player) or nil
            for unit in player:Units() do
                if unit:IsHasPromotion(I.Schism) then refreshUnit(unit, state) end
            end
        end
    end
end

local function onPlayerDoTurn(playerID)
    local player = Players[playerID]
    local state = refreshPlayer(playerID)
    if state == nil then
        if player and player:IsAlive() then
            for unit in player:Units() do
                if unit:IsHasPromotion(I.Zeal) or unit:IsHasPromotion(I.Schism) then
                    refreshUnit(unit, nil)
                end
            end
        end
        return
    end
    local halls = 0
    for city in player:Cities() do if hasBuilding(city, I.Hall) then halls = halls + 1 end end
    if halls > 0 and player.ChangeCombatExperience then player:ChangeCombatExperience(halls) end
end
local function onCityTrained(playerID, cityID, unitID, boughtWithGold, boughtWithFaith)
    local player, unit = Players[playerID], getUnit(playerID, unitID)
    local city = player and player:GetCityByID(cityID) or nil
    if not isDual(player) or city == nil or unit == nil or not isMilitary(unit)
        or truth(boughtWithGold) or truth(boughtWithFaith) then return end
    local _, military, religious = cityInfrastructure(city)
    if military and religious then setPromotion(unit, I.Zeal, true) end
    if isGoldenAge(player) then unit:ChangeExperience(5) end
    refreshUnit(unit, balanceState(player))
end
local function onCityChanged(playerID)
    refreshPlayer(playerID)
end
local function onUnitCreated(playerID, unitID)
    local player, unit = Players[playerID], getUnit(playerID, unitID)
    excludedSupport[unitKey(playerID, unitID)] = nil
    if unit then
        local state = isDual(player) and balanceState(player) or nil
        refreshUnit(unit, state)
        if religiousUnits[unit:GetUnitType()] then refreshSchismUnits() end
    end
end
local function onUnitPrekill(playerID, unitID, unitType, _, _, _, killerPlayerID)
    local unit = getUnit(playerID, unitID)
    local actualType = unitType or (unit and unit:GetUnitType())
    if religiousUnits[actualType] then
        -- UnitPrekill fires while the unit can still occupy its plot, so explicitly ignore it.
        excludedSupport[unitKey(playerID, unitID)] = true
        refreshSchismUnits()
    end
    -- UnitPrekill gives reliable kill attribution while the victim still exists.
    local battle = battles[#battles]
    if battle and killerPlayerID ~= nil and killerPlayerID >= 0 and killerPlayerID ~= playerID then
        local victimRole = nil
        for role, member in pairs(battle.members or {}) do
            if member.playerID == playerID and member.id == unitID and not member.isCity then
                victimRole = role
                break
            end
        end
        if victimRole ~= nil then
            -- Role 0 is the attacker, role 1 the target, and role 2 an interceptor.
            local killerRoles = victimRole == 0 and {2, 1} or {0}
            for _, role in ipairs(killerRoles) do
                local member = battle.members[role]
                if member and member.playerID == killerPlayerID and not member.isCity
                    and not (member.playerID == playerID and member.id == unitID) then
                    local killer = getUnit(member.playerID, member.id)
                    if killer and killer:IsHasPromotion(I.Zeal) then
                        battle.zealKiller = member
                        break
                    end
                end
            end
        end
    end
end
local function onUnitConverted(_, newPlayerID, _, newUnitID)
    onUnitCreated(newPlayerID, newUnitID)
    refreshAllUnits()
    return true
end
local function onWarChanged()
    refreshAll()
end

local function maxHitPoints(unit)
    if unit.GetMaxHitPoints then return unit:GetMaxHitPoints() end
    return GameDefines.MAX_HIT_POINTS or 100
end
local function prepareBattle()
    local battle = battles[#battles]
    if battle == nil or battle.prepared or battle.attacker == nil or battle.defender == nil then return end
    battle.prepared = true
    local attacker = battle.attacker.isCity and nil or getUnit(battle.attacker.playerID, battle.attacker.id)
    local defender = battle.defender.isCity and nil or getUnit(battle.defender.playerID, battle.defender.id)
    battle.attackerUnit, battle.defenderUnit = attacker, defender
    if attacker then
        local owner = Players[attacker:GetOwner()]
        refreshUnit(attacker, isDual(owner) and balanceState(owner) or nil)
        local wounded = defender ~= nil and defender:GetCurrHitPoints() * 2 < maxHitPoints(defender)
            and attacker:IsHasPromotion(I.Schism)
        setPromotion(attacker, I.SchismWounded, wounded)
    end
    if defender then
        local owner = Players[defender:GetOwner()]
        refreshUnit(defender, isDual(owner) and balanceState(owner) or nil)
    end
end
local function onBattleStarted(battleType, x, y)
    battles[#battles + 1] = {battleType=battleType, x=x, y=y, prepared=false, members={}}
end
local function onBattleJoined(playerID, objectID, role, isCity)
    local battle = battles[#battles]
    if battle == nil then return end
    local participant = {playerID=playerID, id=objectID, isCity=truth(isCity)}
    battle.members[role] = participant
    if role == 0 then battle.attacker = participant
    elseif role == 1 then battle.defender = participant end
    prepareBattle()
end
local function healFromZeal(unit)
    if unit and unit:IsHasPromotion(I.Zeal) and unit:GetCurrHitPoints() < maxHitPoints(unit) then
        unit:ChangeDamage(-10)
    end
end
local function onBattleFinished()
    local battle = table.remove(battles)
    if battle == nil then return end
    local attacker = battle.attacker and not battle.attacker.isCity
        and getUnit(battle.attacker.playerID, battle.attacker.id) or nil
    local defender = battle.defender and not battle.defender.isCity
        and getUnit(battle.defender.playerID, battle.defender.id) or nil
    if attacker then setPromotion(attacker, I.SchismWounded, false) end
    local credited = battle.zealKiller
        and getUnit(battle.zealKiller.playerID, battle.zealKiller.id) or nil
    if credited then healFromZeal(credited)
    elseif attacker and battle.defenderUnit and defender == nil then healFromZeal(attacker)
    elseif defender and battle.attackerUnit and attacker == nil then healFromZeal(defender) end
    refreshAllUnits()
end

local function onUnitSetXY(playerID, unitID)
    local player, unit = Players[playerID], getUnit(playerID, unitID)
    if unit == nil then return end
    local state = isDual(player) and balanceState(player) or nil
    refreshUnit(unit, state)
    if religiousUnits[unit:GetUnitType()] then refreshSchismUnits() end
end
local function getState(playerID)
    local player = Players[playerID]
    if not isDual(player) then
        return {wars=0,faith=0,faithTimes100=0,active=false,combat=0,production=0,golden=false}
    end
    local state = balanceState(player)
    state.golden = isGoldenAge(player)
    return state
end

-- Exposed for the UI, deterministic tests and diagnostics.
D.IsDualOrder = isDual
D.GetState = getState
D.CityInfrastructure = cityInfrastructure
D.RefreshPlayer = refreshPlayer
D.RefreshAll = refreshAll
D.OnPlayerDoTurn = onPlayerDoTurn
D.OnCityTrained = onCityTrained
D.OnUnitCreated = onUnitCreated
D.OnUnitPrekill = onUnitPrekill
D.OnUnitSetXY = onUnitSetXY
D.OnBattleStarted = onBattleStarted
D.OnBattleJoined = onBattleJoined
D.OnBattleFinished = onBattleFinished
D.RefreshAllUnits = refreshAllUnits

GameEvents.PlayerDoTurn.Add(onPlayerDoTurn)
if GameEvents.PlayerDoneTurn then GameEvents.PlayerDoneTurn.Add(refreshPlayer) end
GameEvents.CityTrained.Add(onCityTrained)
if GameEvents.CityConstructed then GameEvents.CityConstructed.Add(onCityChanged) end
if GameEvents.CityCaptureComplete then GameEvents.CityCaptureComplete.Add(function(_, _, _, _, newOwner) refreshPlayer(newOwner) end) end
if GameEvents.UnitCreated then GameEvents.UnitCreated.Add(onUnitCreated) end
if GameEvents.UnitPrekill then GameEvents.UnitPrekill.Add(onUnitPrekill) end
if GameEvents.UnitSetXY then GameEvents.UnitSetXY.Add(onUnitSetXY) end
if GameEvents.UnitConverted then GameEvents.UnitConverted.Add(onUnitConverted) end
if GameEvents.UnitUpgraded then
    GameEvents.UnitUpgraded.Add(function(playerID, _, newUnitID) onUnitCreated(playerID, newUnitID); return true end)
end
if GameEvents.DeclareWar then GameEvents.DeclareWar.Add(onWarChanged) end
if GameEvents.MakePeace then GameEvents.MakePeace.Add(onWarChanged) end
if GameEvents.ReligionFounded then GameEvents.ReligionFounded.Add(function(playerID) refreshPlayer(playerID) end) end
if GameEvents.PlayerGoldenAge then GameEvents.PlayerGoldenAge.Add(function(playerID) refreshPlayer(playerID) end) end
GameEvents.BattleStarted.Add(onBattleStarted)
GameEvents.BattleJoined.Add(onBattleJoined)
GameEvents.BattleFinished.Add(onBattleFinished)

refreshAll()
D.RuntimeLoaded = true
print("The Dual Order: runtime loaded")
