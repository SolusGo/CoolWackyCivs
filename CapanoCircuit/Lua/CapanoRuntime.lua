-- The Capano Circuit: target-specific projecting, Boulder Sectors, training,
-- Competition Movement, technique progression, Ammagamma, and AI respect.
-- Loaded once as an InGameUIAddin. Requires Brave New World + Community Patch.

MapModData.Capano = MapModData.Capano or {}
local C = MapModData.Capano
if C.RuntimeLoaded then return end
C.RuntimeLoaded = true

local function ID(name) return GameInfoTypes[name] end
local I = {
    Civilization = ID("CIVILIZATION_CAPANO_CIRCUIT"),
    RouteSetter = ID("UNIT_CAPANO_ROUTE_SETTER"),
    CoachingCentre = ID("BUILDING_CAPANO_COMPETITION_CENTRE"),
    BoulderSector = ID("IMPROVEMENT_CAPANO_BOULDER_SECTOR"),
    BoulderBuild = ID("BUILD_CAPANO_BOULDER_SECTOR"),
    Architecture = ID("TECH_ARCHITECTURE"), Plastics = ID("TECH_PLASTICS"),
    RouteSetterPromo = ID("PROMOTION_CAPANO_ROUTE_SETTER"),
    SetterWork = ID("PROMOTION_CAPANO_SETTER_HILLS_WORK"),
    Beta = {ID("PROMOTION_CAPANO_BETA_1"), ID("PROMOTION_CAPANO_BETA_2"),
        ID("PROMOTION_CAPANO_BETA_3"), ID("PROMOTION_CAPANO_BETA_4")},
    BetaAttack = {ID("PROMOTION_CAPANO_BETA_ATTACK_5"), ID("PROMOTION_CAPANO_BETA_ATTACK_10"),
        ID("PROMOTION_CAPANO_BETA_ATTACK_15"), ID("PROMOTION_CAPANO_BETA_ATTACK_20")},
    AwkwardBlue = ID("PROMOTION_CAPANO_AWKWARD_BLUE"),
    AwkwardPurple = ID("PROMOTION_CAPANO_AWKWARD_PURPLE"),
    ReadSequence = ID("PROMOTION_CAPANO_READ_SEQUENCE"),
    Competition = ID("PROMOTION_CAPANO_COMPETITION_MOVEMENT"),
    CompetitionActive = ID("PROMOTION_CAPANO_COMPETITION_ACTIVE"),
    Footwork = ID("PROMOTION_CAPANO_FOOTWORK"),
    BodyPosition = ID("PROMOTION_CAPANO_BODY_POSITION"),
    BodyActive = ID("PROMOTION_CAPANO_BODY_ACTIVE"),
    Coordination = ID("PROMOTION_CAPANO_COORDINATION"),
    Commit = ID("PROMOTION_CAPANO_COMMIT"), CommitActive = ID("PROMOTION_CAPANO_COMMIT_ACTIVE"),
    Complete = ID("PROMOTION_CAPANO_COMPLETE_CLIMBER"),
    CompleteHills = ID("PROMOTION_CAPANO_COMPLETE_HILLS"),
    Yellow = ID("PROMOTION_CAPANO_YELLOW_CIRCUIT"),
    DiploRespect = ID("DIPLOMODIFIER_CAPANO_RESPECT_SEND"),
    DiploAbandoned = ID("DIPLOMODIFIER_CAPANO_ABANDONED_PROJECT"),
    DiploStrong = ID("DIPLOMODIFIER_CAPANO_STRONG_CLIMBERS")
}
C.IDs = I

local LAND = DomainTypes.DOMAIN_LAND
local MOVE = GameDefines.MOVE_DENOMINATOR or 60
local MAX_BETA = 4
local save = Modding.OpenSaveData()
local battles, movement = {}, {}

local function truth(value) return value == true or value == 1 end
local function turn() return Game.GetGameTurn() end
local function setPromo(unit, promotion, enabled)
    if unit and promotion and promotion >= 0 and unit:IsHasPromotion(promotion) ~= enabled then
        unit:SetHasPromotion(promotion, enabled)
    end
end
local function isCapano(player)
    if type(player) == "number" then player = Players[player] end
    return player ~= nil and I.Civilization ~= nil and player:GetCivilizationType() == I.Civilization
end
local function isMilitary(unit)
    if unit == nil or unit.IsCombatUnit == nil or not unit:IsCombatUnit() then return false end
    local info = GameInfo.Units[unit:GetUnitType()]
    if info == nil or truth(info.Suicide) or (tonumber(info.NukeDamageLevel) or -1) >= 0 then return false end
    return true
end
local function plotAt(x, y)
    if x == nil or y == nil or x < 0 or y < 0 then return nil end
    return Map.GetPlot(x, y)
end
local function adjacentPlot(plot, direction)
    if plot == nil then return nil end
    return Map.PlotDirection(plot:GetX(), plot:GetY(), direction)
end
local function isPillaged(plot)
    return plot and plot.IsImprovementPillaged and plot:IsImprovementPillaged()
end
local function isSector(plot)
    return plot ~= nil and plot:GetImprovementType() == I.BoulderSector and not isPillaged(plot)
end
local function hasTech(player, tech)
    if player == nil or tech == nil then return false end
    local team = Teams[player:GetTeam()]
    return team ~= nil and team:IsHasTech(tech)
end

-- One tagged record preserves every other mod's unit script data. The target
-- serial prevents recycled unit IDs from inheriting somebody else's Project.
local marker = "%[CAPANO1:([^%]]*)%]"
local fields = {"serial", "targetKind", "targetOwner", "targetID", "targetSerial",
    "targetX", "targetY", "stacks", "qualifies", "ammagamma", "targetStrength",
    "lastTrainingEra", "readUntil", "yellow", "sends"}
local defaults = {serial=0, targetKind=0, targetOwner=-1, targetID=-1, targetSerial=0,
    targetX=-1, targetY=-1, stacks=0, qualifies=0, ammagamma=0, targetStrength=0,
    lastTrainingEra=-1, readUntil=-1, yellow=0, sends=0}

local function getUnitState(unit)
    local data = {}
    for key, value in pairs(defaults) do data[key] = value end
    local raw = unit and (unit:GetScriptData() or ""):match(marker)
    if raw then
        local index = 1
        for value in raw:gmatch("[^,]+") do
            if fields[index] then data[fields[index]] = tonumber(value) or data[fields[index]] end
            index = index + 1
        end
    end
    return data
end

local function setUnitState(unit, data)
    if unit == nil then return end
    local original = (unit:GetScriptData() or ""):gsub(marker, "")
    local values = {}
    for index, key in ipairs(fields) do values[index] = data[key] or defaults[key] end
    unit:SetScriptData(original .. "[CAPANO1:" .. table.concat(values, ",") .. "]")
end

local function identify(unit)
    local data = getUnitState(unit)
    if data.serial == 0 then
        local nextValue = (tonumber(save:GetValue("CAPANO_V1_NEXT_SERIAL")) or 0) + 1
        save:SetValue("CAPANO_V1_NEXT_SERIAL", nextValue)
        data.serial = nextValue
        setUnitState(unit, data)
    end
    return data
end

local function clearTemporary(unit)
    if unit == nil then return end
    for _, promotion in ipairs(I.BetaAttack) do setPromo(unit, promotion, false) end
    setPromo(unit, I.CommitActive, false)
end

local function updateBeta(unit, stacks)
    for index, promotion in ipairs(I.Beta) do setPromo(unit, promotion, index == stacks) end
end

local function clearProject(unit)
    if unit == nil then return end
    local data = getUnitState(unit)
    data.targetKind, data.targetOwner, data.targetID, data.targetSerial = 0, -1, -1, 0
    data.targetX, data.targetY, data.stacks = -1, -1, 0
    data.qualifies, data.ammagamma, data.targetStrength = 0, 0, 0
    setUnitState(unit, data)
    updateBeta(unit, 0)
    clearTemporary(unit)
end

local techniquePromotions = {I.Footwork, I.BodyPosition, I.Coordination, I.Commit, I.Complete}
local function refreshTechniques(unit, data)
    if unit == nil then return end
    data = data or getUnitState(unit)
    for threshold, promotion in ipairs(techniquePromotions) do
        setPromo(unit, promotion, data.sends >= threshold)
    end
    setPromo(unit, I.Yellow, data.yellow == 1)
end

local function terrainDiversity(plot)
    local found, count = {}, 0
    if plot == nil then return 0 end
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local adjacent = adjacentPlot(plot, direction)
        if adjacent ~= nil then
            local terrain = adjacent:GetTerrainType()
            if found[terrain] == nil then found[terrain] = true; count = count + 1 end
        end
    end
    return count
end

local function refreshPositionPromotions(unit)
    if unit == nil then return end
    local plot = unit:GetPlot()
    setPromo(unit, I.BodyActive, unit:IsHasPromotion(I.BodyPosition) and terrainDiversity(plot) >= 2)
    setPromo(unit, I.CompleteHills, unit:IsHasPromotion(I.Complete) and plot ~= nil and plot:IsHills())
end

local function refreshPersistent(unit)
    if unit == nil then return end
    local data = identify(unit)
    if isCapano(unit:GetOwner()) then updateBeta(unit, math.max(0, math.min(MAX_BETA, data.stacks)))
    else updateBeta(unit, 0) end
    setPromo(unit, I.ReadSequence, data.readUntil > turn())
    refreshTechniques(unit, data)
    refreshPositionPromotions(unit)
end

local function notify(playerID, key, ...)
    local player = Players[playerID]
    if player and player:IsHuman() and Events and Events.GameplayAlertMessage then
        Events.GameplayAlertMessage(Locale.ConvertTextKey(key, ...))
    end
end

local function playerStat(name, playerID)
    return tonumber(save:GetValue("CAPANO_V1_" .. name .. "_" .. tostring(playerID))) or 0
end
local function setPlayerStat(name, playerID, value)
    save:SetValue("CAPANO_V1_" .. name .. "_" .. tostring(playerID), value)
end
local function changePlayerStat(name, playerID, delta, maximum)
    local value = playerStat(name, playerID) + delta
    if maximum then value = math.min(maximum, value) end
    value = math.max(0, value)
    setPlayerStat(name, playerID, value)
    return value
end

local function activeWarKey(playerID, teamID, suffix)
    return "WAR_" .. tostring(playerID) .. "_" .. tostring(teamID) .. "_" .. suffix
end
local function recordWarSuccess(attackerID, targetOwnerID)
    local attacker, target = Players[attackerID], Players[targetOwnerID]
    if attacker == nil or target == nil then return end
    local teamID = target:GetTeam()
    if playerStat(activeWarKey(attackerID, teamID, "ACTIVE"), 0) > 0 then
        setPlayerStat(activeWarKey(attackerID, teamID, "SUCCESS"), 0, 1)
    end
end

-- playerStat normally addresses a player. War records encode both player and
-- team into the name and use slot 0 so the same safe numeric store is reused.
local function warValue(playerID, teamID, suffix)
    return playerStat(activeWarKey(playerID, teamID, suffix), 0)
end
local function setWarValue(playerID, teamID, suffix, value)
    setPlayerStat(activeWarKey(playerID, teamID, suffix), 0, value)
end

-- Strength values from Civ V are hundredths of a combat point.
local function baseStrength(unit)
    if unit == nil then return 0 end
    local melee = tonumber(unit:GetBaseCombatStrength()) or 0
    local ranged = unit.GetBaseRangedCombatStrength and (tonumber(unit:GetBaseRangedCombatStrength()) or 0) or 0
    return math.max(melee, ranged) * 100
end

local function attackStrength(attacker, targetUnit, targetCity)
    if attacker == nil then return 0 end
    local ok, value
    if attacker.IsCanAttackRanged and attacker:IsCanAttackRanged() then
        ok, value = pcall(function() return attacker:GetMaxRangedCombatStrength(targetUnit, targetCity, true) end)
    else
        local targetPlot = targetUnit and targetUnit:GetPlot() or (targetCity and targetCity:Plot())
        local fromPlot = targetPlot and attacker.GetMeleeAttackFromPlot and attacker:GetMeleeAttackFromPlot(targetPlot)
            or attacker:GetPlot()
        ok, value = pcall(function() return attacker:GetMaxAttackStrength(fromPlot, targetPlot, targetUnit) end)
    end
    return ok and (tonumber(value) or 0) > 0 and tonumber(value) or baseStrength(attacker)
end

local function defenseStrength(attacker, targetUnit, targetCity)
    if targetCity then
        local ok, value = pcall(function()
            return targetCity:GetStrengthValue(false, attacker.IgnoreBuildingDefense and attacker:IgnoreBuildingDefense() or false)
        end)
        return ok and (tonumber(value) or 0) or 0
    end
    if targetUnit == nil then return 0 end
    local ok, value
    if attacker.IsCanAttackRanged and attacker:IsCanAttackRanged() then
        if targetUnit.IsEmbarked and targetUnit:IsEmbarked() and targetUnit.GetEmbarkedUnitDefense then
            ok, value = pcall(function() return targetUnit:GetEmbarkedUnitDefense() end)
        elseif targetUnit.IsCanAttackRanged and targetUnit:IsCanAttackRanged() then
            ok, value = pcall(function() return targetUnit:GetMaxRangedCombatStrength(attacker, nil, false) end)
        else
            ok, value = pcall(function()
                return targetUnit:GetMaxDefenseStrength(targetUnit:GetPlot(), attacker, attacker:GetPlot(), true)
            end)
        end
    else
        ok, value = pcall(function()
            return targetUnit:GetMaxDefenseStrength(targetUnit:GetPlot(), attacker, attacker:GetPlot(), false)
        end)
    end
    return ok and (tonumber(value) or 0) > 0 and tonumber(value) or baseStrength(targetUnit)
end

local function getUnit(playerID, unitID)
    local player = Players[playerID]
    return player and player:GetUnitByID(unitID) or nil
end

local function getCity(playerID, cityID)
    local player = Players[playerID]
    return player and player:GetCityByID(cityID) or nil
end

local function targetMatches(data, battle)
    if data.targetKind ~= battle.targetKind or data.targetOwner ~= battle.targetOwner then return false end
    if battle.targetKind == 1 then
        return data.targetID == battle.targetID and data.targetSerial == battle.targetSerial
    end
    return data.targetID == battle.targetID and data.targetX == battle.targetX and data.targetY == battle.targetY
end

local function applyProjectToBattle(attacker, battle)
    local data = identify(attacker)
    if targetMatches(data, battle) and data.stacks > 0 then
        battle.startingStacks = math.min(MAX_BETA, data.stacks)
        battle.qualifies, battle.ammagamma = data.qualifies, data.ammagamma
        battle.rewardStrength = data.targetStrength
        setPromo(attacker, I.BetaAttack[battle.startingStacks], true)
    else
        clearProject(attacker)
        data = getUnitState(attacker)
        data.targetKind, data.targetOwner, data.targetID = battle.targetKind, battle.targetOwner, battle.targetID
        data.targetSerial, data.targetX, data.targetY = battle.targetSerial, battle.targetX, battle.targetY
        data.qualifies = battle.targetStrength >= battle.attackerStrength and 1 or 0
        data.ammagamma = battle.targetStrength * 2 >= battle.baseAttackerStrength * 3 and 1 or 0
        data.targetStrength = math.max(1, math.floor(battle.targetStrength / 100 + 0.5))
        battle.qualifies, battle.ammagamma, battle.rewardStrength = data.qualifies, data.ammagamma, data.targetStrength
        battle.newProject = data
    end
    if attacker:IsHasPromotion(I.Commit) and attacker:GetCurrHitPoints() < 50 then
        setPromo(attacker, I.CommitActive, true)
    end
end

local function prepareBattle()
    local battle = battles[#battles]
    if battle == nil or battle.prepared or battle.attacker == nil or battle.defender == nil then return end
    battle.prepared = true
    if battle.attacker.isCity then return end
    local attacker = getUnit(battle.attacker.playerID, battle.attacker.id)
    if attacker == nil or not isMilitary(attacker) then return end
    local attackerPlayer, defenderPlayer = Players[battle.attacker.playerID], Players[battle.defender.playerID]
    if attackerPlayer == nil or defenderPlayer == nil or attackerPlayer:GetTeam() == defenderPlayer:GetTeam() then return end
    local targetUnit, targetCity
    if battle.defender.isCity then targetCity = getCity(battle.defender.playerID, battle.defender.id)
    else targetUnit = getUnit(battle.defender.playerID, battle.defender.id) end
    if targetUnit == nil and targetCity == nil then return end

    battle.valid = true
    battle.attackerUnit = attacker
    battle.targetOwner, battle.targetID = battle.defender.playerID, battle.defender.id
    battle.targetKind = targetCity and 2 or 1
    battle.targetX = targetCity and targetCity:GetX() or targetUnit:GetX()
    battle.targetY = targetCity and targetCity:GetY() or targetUnit:GetY()
    battle.targetSerial = targetUnit and identify(targetUnit).serial or 0
    battle.ranged = attacker.IsCanAttackRanged and attacker:IsCanAttackRanged()
    battle.attackerStrength = attackStrength(attacker, targetUnit, targetCity)
    battle.baseAttackerStrength = math.max(1, baseStrength(attacker))
    battle.targetStrength = defenseStrength(attacker, targetUnit, targetCity)
    battle.targetEra = math.max(attackerPlayer:GetCurrentEra(), defenderPlayer:GetCurrentEra())
    battle.hardWin = battle.targetStrength >= battle.attackerStrength
    if isCapano(attackerPlayer) then applyProjectToBattle(attacker, battle) end
end

local function onBattleStarted(battleType, x, y)
    battles[#battles + 1] = {battleType=battleType, x=x, y=y, prepared=false,
        startingStacks=0, targetKilled=false, targetCaptured=false}
end

local function onBattleJoined(playerID, objectID, role, isCity)
    local battle = battles[#battles]
    if battle == nil then return end
    if role == 0 then battle.attacker = {playerID=playerID, id=objectID, isCity=truth(isCity)}
    elseif role == 1 then battle.defender = {playerID=playerID, id=objectID, isCity=truth(isCity)} end
    prepareBattle()
end

local function clearProjectsAimedAtUnit(ownerID, unitID, serial)
    for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local player = Players[playerID]
        if isCapano(player) then
            for unit in player:Units() do
                local data = getUnitState(unit)
                if data.targetKind == 1 and data.targetOwner == ownerID and data.targetID == unitID
                    and (serial == nil or data.targetSerial == serial) then clearProject(unit) end
            end
        end
    end
end

local function clearProjectsAimedAtCity(ownerID, x, y)
    for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local player = Players[playerID]
        if isCapano(player) then
            for unit in player:Units() do
                local data = getUnitState(unit)
                if data.targetKind == 2 and data.targetOwner == ownerID
                    and data.targetX == x and data.targetY == y then clearProject(unit) end
            end
        end
    end
end

local function onUnitPrekill(ownerID, unitID)
    local victim = getUnit(ownerID, unitID)
    local serial = victim and getUnitState(victim).serial or nil
    local battle = battles[#battles]
    if battle and battle.valid and battle.targetKind == 1
        and battle.targetOwner == ownerID and battle.targetID == unitID
        and (serial == nil or battle.targetSerial == serial) then battle.targetKilled = true end
    clearProjectsAimedAtUnit(ownerID, unitID, serial)
end

local function onUnitCaptured(_, _, capturedPlayer, capturedUnit, willBeKilled)
    local battle = battles[#battles]
    if not truth(willBeKilled) and battle and battle.valid and battle.targetKind == 1
        and battle.targetOwner == capturedPlayer and battle.targetID == capturedUnit then
        battle.targetKilled, battle.targetCaptured = true, true
    end
end

local function grantTechnique(unit, data)
    data.sends = math.min(5, data.sends + 1)
    setUnitState(unit, data)
    refreshTechniques(unit, data)
    refreshPositionPromotions(unit)
end

local function completeSend(battle, attacker)
    local data = getUnitState(attacker)
    data.qualifies, data.ammagamma, data.targetStrength = battle.qualifies or 0,
        battle.ammagamma or 0, battle.rewardStrength or 0
    attacker:ChangeDamage(-25)
    attacker:ChangeExperience(10)
    local eraFactor = 1 + 0.5 * (battle.targetEra or 0)
    local amount = math.max(10, math.floor((battle.rewardStrength or 1) * eraFactor + 0.5))
    if battle.targetKind == 2 then amount = math.floor(amount * 2.5 + 0.5) end
    if data.yellow == 1 then amount = math.floor(amount * 1.15 + 0.5) end
    local playerID, player = attacker:GetOwner(), Players[attacker:GetOwner()]
    player:ChangeOverflowResearch(amount)
    player:ChangeJONSCulture(amount)
    grantTechnique(attacker, data)
    notify(playerID, "TXT_KEY_CAPANO_SEND_NOTIFICATION", attacker:GetName(), amount)
    if battle.ammagamma == 1 and playerStat("AMMAGAMMA", playerID) == 0 then
        setPlayerStat("AMMAGAMMA", playerID, 1)
        player:ChangeOverflowResearch(500)
        player:ChangeJONSCulture(500)
        local length = player.GetGoldenAgeLength and player:GetGoldenAgeLength() or 10
        player:ChangeGoldenAgeTurns(math.max(1, length))
        notify(playerID, "TXT_KEY_CAPANO_AMMAGAMMA_NOTIFICATION", attacker:GetName())
    end
end

local function targetDefeated(battle)
    if battle.targetKilled or battle.targetCaptured then return true end
    if battle.targetKind == 1 then
        local unit = getUnit(battle.targetOwner, battle.targetID)
        return unit == nil or getUnitState(unit).serial ~= battle.targetSerial
    end
    local plot = plotAt(battle.targetX, battle.targetY)
    local city = plot and plot:GetPlotCity() or nil
    if city == nil or city:GetOwner() ~= battle.targetOwner then return true end
    return not battle.ranged and city:GetDamage() >= math.max(0, city:GetMaxHitPoints() - 1)
end

local function finishProjectAttempt(battle, attacker, defeated)
    if not isCapano(attacker:GetOwner()) then return end
    if defeated then
        if battle.startingStacks >= MAX_BETA and battle.qualifies == 1 then completeSend(battle, attacker) end
        clearProject(attacker)
        return
    end
    local data = battle.newProject or getUnitState(attacker)
    data.stacks = math.min(MAX_BETA, battle.startingStacks + 1)
    setUnitState(attacker, data)
    updateBeta(attacker, data.stacks)
end

local function onBattleFinished()
    local battle = table.remove(battles)
    if battle == nil or not battle.valid then return end
    local attacker = getUnit(battle.attacker.playerID, battle.attacker.id)
    if attacker == nil then return end
    local defeated = targetDefeated(battle)
    clearTemporary(attacker)
    if defeated then
        if battle.hardWin then changePlayerStat("HARD_WINS", battle.attacker.playerID, 1, 3) end
        recordWarSuccess(battle.attacker.playerID, battle.targetOwner)
        if attacker:IsHasPromotion(I.Coordination) then
            attacker:SetMoves(math.min(attacker:MaxMoves(), attacker:GetMoves() + MOVE))
        end
    end
    finishProjectAttempt(battle, attacker, defeated)
end

local function onCityCaptureComplete(oldOwner, _, x, y, newOwner)
    local battle = battles[#battles]
    if battle and battle.valid and battle.targetKind == 2 and battle.targetOwner == oldOwner
        and battle.targetX == x and battle.targetY == y and battle.attacker.playerID == newOwner then
        battle.targetKilled, battle.targetCaptured = true, true
    end
    recordWarSuccess(newOwner, oldOwner)
    clearProjectsAimedAtCity(oldOwner, x, y)
end

local function hasAdjacentMountain(plot)
    if plot == nil then return false end
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local adjacent = adjacentPlot(plot, direction)
        if adjacent and adjacent:IsMountain() then return true end
    end
    return false
end

local function canBuildSector(playerID, unitID, x, y, buildID)
    if buildID ~= I.BoulderBuild then return true end
    local player, plot = Players[playerID], plotAt(x, y)
    local unit = player and player:GetUnitByID(unitID) or nil
    if not isCapano(player) or unit == nil or unit:GetUnitType() ~= I.RouteSetter or plot == nil
        or plot:IsWater() or plot:IsMountain() or plot:IsCity() then return false end
    if not plot:IsHills() and not hasAdjacentMountain(plot) then return false end
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local adjacent = adjacentPlot(plot, direction)
        if adjacent and adjacent:GetImprovementType() == I.BoulderSector then return false end
    end
    return true
end

local function refreshSetterWork(unit)
    if unit == nil or unit:GetUnitType() ~= I.RouteSetter then return end
    local plot = unit:GetPlot()
    local building = unit.GetBuildType and unit:GetBuildType() or -1
    setPromo(unit, I.SetterWork, plot ~= nil and plot:IsHills() and building ~= nil and building >= 0)
end

local function onPlayerBuilding(playerID, unitID, x, y, _, starting)
    local unit = getUnit(playerID, unitID)
    if unit and unit:GetUnitType() == I.RouteSetter then
        local plot = plotAt(x, y)
        setPromo(unit, I.SetterWork, truth(starting) and plot ~= nil and plot:IsHills())
    end
end

local function onPlayerBuilt(playerID, unitID)
    local unit = getUnit(playerID, unitID)
    if unit then setPromo(unit, I.SetterWork, false) end
end

local memeLines = {"Who set this?", "Surely this isn't Purple.", "What is this foot?",
    "There HAS to be another beta.", "This felt harder than the Black."}
local function showSectorMessage(unit, plot)
    local data = identify(unit)
    local index = plot:GetPlotIndex()
    local key = "CAPANO_V1_SECTOR_SEEN_" .. tostring(data.serial) .. "_" .. tostring(index)
    if save:GetValue(key) ~= nil then return end
    save:SetValue(key, 1)
    local active = Game.GetActivePlayer and Game.GetActivePlayer() or -1
    local activePlayer = Players[active]
    if activePlayer == nil or not plot:IsVisible(activePlayer:GetTeam(), false) then return end
    local roll = Game.Rand(100, "Capano BlocHaus first entry")
    local message
    if roll == 0 then message = "ENRICO."
    elseif roll < 26 then message = memeLines[Game.Rand(#memeLines, "Capano BlocHaus line") + 1] end
    if message and Events and Events.AddPopupTextEvent and HexToWorld and ToHexFromGrid and Vector2 then
        local hex = ToHexFromGrid(Vector2(plot:GetX(), plot:GetY()))
        Events.AddPopupTextEvent(HexToWorld(hex), "[COLOR_MAGENTA]" .. message .. "[ENDCOLOR]", true)
    end
end

local function applySectorEntry(unit, plot, previous)
    if unit == nil or plot == nil or previous == nil or not isSector(plot) then return end
    local sectorOwner = plot:GetOwner()
    local owner = Players[unit:GetOwner()]
    local sectorPlayer = Players[sectorOwner]
    if sectorPlayer == nil or not isCapano(sectorPlayer) then return end
    local movesNow = unit:GetMoves()
    local spent = math.max(0, (previous.moves or movesNow) - movesNow)
    if unit:GetOwner() == sectorOwner then
        if spent > MOVE then unit:SetMoves(math.min(unit:MaxMoves(), movesNow + spent - MOVE)) end
    elseif owner and Teams[owner:GetTeam()]:IsAtWar(sectorPlayer:GetTeam()) then
        unit:SetMoves(math.max(0, movesNow - MOVE))
        local purple = hasTech(sectorPlayer, I.Architecture)
        setPromo(unit, I.AwkwardBlue, not purple)
        setPromo(unit, I.AwkwardPurple, purple)
        showSectorMessage(unit, plot)
    end
end

local function moveKey(playerID, unitID) return tostring(playerID) .. ":" .. tostring(unitID) end
local function onUnitSetXY(playerID, unitID, x, y)
    local unit, destination = getUnit(playerID, unitID), plotAt(x, y)
    if unit == nil or destination == nil then return end
    local key, previous = moveKey(playerID, unitID), movement[moveKey(playerID, unitID)]
    if previous and unit:GetDomainType() == LAND
        and Map.PlotDistance(previous.x, previous.y, x, y) == 1 then
        previous.tiles = (previous.tiles or 0) + 1
        applySectorEntry(unit, destination, previous)
        if unit:IsHasPromotion(I.Competition) and previous.tiles >= 2 then
            setPromo(unit, I.CompetitionActive, true)
        end
    end
    movement[key] = {x=x, y=y, moves=unit:GetMoves(), tiles=previous and previous.tiles or 0}
    setPromo(unit, I.SetterWork, false)
    refreshPositionPromotions(unit)
end

local function trainOnSector(playerID)
    local player = Players[playerID]
    if not isCapano(player) then return end
    local era = player:GetCurrentEra()
    for unit in player:Units() do
        local plot = unit:GetPlot()
        if isMilitary(unit) and unit:GetDomainType() == LAND and isSector(plot)
            and plot:GetOwner() == playerID then
            local data = identify(unit)
            if data.lastTrainingEra ~= era then
                data.lastTrainingEra = era
                data.readUntil = turn() + 11
                unit:ChangeExperience(5)
                setPromo(unit, I.ReadSequence, true)
                local firstYellow = data.yellow == 0 and hasTech(player, I.Plastics)
                if firstYellow then data.yellow = 1; setPromo(unit, I.Yellow, true) end
                setUnitState(unit, data)
                notify(playerID, "TXT_KEY_CAPANO_TRAINING_NOTIFICATION", unit:GetName())
                if firstYellow then notify(playerID, "TXT_KEY_CAPANO_YELLOW_NOTIFICATION", unit:GetName()) end
            end
        end
    end
end

local function onCityTrained(playerID, cityID, unitID, boughtWithGold, boughtWithFaith)
    if truth(boughtWithGold) or truth(boughtWithFaith) then return end
    local player, unit = Players[playerID], getUnit(playerID, unitID)
    local city = player and player:GetCityByID(cityID) or nil
    if isCapano(player) and city and unit and isMilitary(unit) and unit:GetDomainType() == LAND
        and city:GetNumRealBuilding(I.CoachingCentre) > 0 then
        setPromo(unit, I.Competition, true)
    end
end

local function onPlayerDoTurn(playerID)
    local player = Players[playerID]
    if player == nil then return end
    for unit in player:Units() do
        clearTemporary(unit)
        setPromo(unit, I.CompetitionActive, false)
        setPromo(unit, I.AwkwardBlue, false)
        setPromo(unit, I.AwkwardPurple, false)
        movement[moveKey(playerID, unit:GetID())] = {
            x=unit:GetX(), y=unit:GetY(), moves=unit:GetMoves(), tiles=0}
        if isCapano(player) then
            local data = identify(unit)
            if data.readUntil <= turn() then setPromo(unit, I.ReadSequence, false) end
            refreshPersistent(unit)
            refreshSetterWork(unit)
        else
            updateBeta(unit, 0)
        end
    end
end

local function onUnitCreated(playerID, unitID)
    local unit = getUnit(playerID, unitID)
    if unit == nil then return end
    identify(unit)
    clearTemporary(unit)
    movement[moveKey(playerID, unitID)] = {x=unit:GetX(), y=unit:GetY(), moves=unit:GetMoves(), tiles=0}
    if isCapano(playerID) then refreshPersistent(unit) end
end

local function onUnitConverted(oldPlayerID, newPlayerID, oldUnitID, newUnitID, isUpgrade)
    local oldUnit, newUnit = getUnit(oldPlayerID, oldUnitID), getUnit(newPlayerID, newUnitID)
    if newUnit == nil then return true end
    local data = oldUnit and getUnitState(oldUnit) or identify(newUnit)
    if oldPlayerID ~= newPlayerID or not truth(isUpgrade) then
        data.targetKind, data.targetOwner, data.targetID, data.targetSerial = 0, -1, -1, 0
        data.targetX, data.targetY, data.stacks = -1, -1, 0
        data.qualifies, data.ammagamma, data.targetStrength = 0, 0, 0
    end
    setUnitState(newUnit, data)
    clearTemporary(newUnit)
    refreshPersistent(newUnit)
    movement[moveKey(newPlayerID, newUnitID)] = {
        x=newUnit:GetX(), y=newUnit:GetY(), moves=newUnit:GetMoves(), tiles=0}
    return true
end

local function onDeclareWar(playerID, againstTeam, aggressor)
    if truth(aggressor) and Players[playerID] and not Players[playerID]:IsMinorCiv()
        and not Players[playerID]:IsBarbarian() then
        setWarValue(playerID, againstTeam, "ACTIVE", 1)
        setWarValue(playerID, againstTeam, "SUCCESS", 0)
    end
end

local function onMakePeace(playerID, againstTeam)
    if warValue(playerID, againstTeam, "ACTIVE") > 0 then
        if warValue(playerID, againstTeam, "SUCCESS") == 0 then
            changePlayerStat("ABANDONED", playerID, 1, 2)
        end
        setWarValue(playerID, againstTeam, "ACTIVE", 0)
        setWarValue(playerID, againstTeam, "SUCCESS", 0)
    end
end

local function strongClimberCount(player)
    local count = 0
    if player == nil then return 0 end
    for unit in player:Units() do
        if isMilitary(unit) and ((unit.GetLevel and unit:GetLevel() >= 4) or unit:GetExperience() >= 45) then
            count = count + 1
            if count >= 4 then return count end
        end
    end
    return count
end

local function getDiploModifier(eventID, fromPlayerID, toPlayerID)
    if not isCapano(fromPlayerID) or fromPlayerID == toPlayerID then return 0 end
    if eventID == I.DiploRespect then return playerStat("HARD_WINS", toPlayerID) >= 3 and 10 or 0 end
    if eventID == I.DiploAbandoned then return playerStat("ABANDONED", toPlayerID) >= 2 and -10 or 0 end
    if eventID == I.DiploStrong then return strongClimberCount(Players[toPlayerID]) >= 4 and 5 or 0 end
    return 0
end

local function initialize()
    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[playerID]
        if player and player:IsAlive() then
            for unit in player:Units() do
                clearTemporary(unit)
                movement[moveKey(playerID, unit:GetID())] = {
                    x=unit:GetX(), y=unit:GetY(), moves=unit:GetMoves(), tiles=0}
                if isCapano(player) then refreshPersistent(unit) end
            end
        end
    end
end

-- Exposed for deterministic tests and diagnostics.
C.IsCapano = isCapano
C.GetUnitState = getUnitState
C.SetUnitState = setUnitState
C.ClearProject = clearProject
C.CanBuildSector = canBuildSector
C.OnBattleStarted = onBattleStarted
C.OnBattleJoined = onBattleJoined
C.OnBattleFinished = onBattleFinished
C.OnUnitPrekill = onUnitPrekill
C.OnUnitSetXY = onUnitSetXY
C.TrainOnSector = trainOnSector
C.OnCityTrained = onCityTrained
C.OnPlayerDoTurn = onPlayerDoTurn
C.OnDeclareWar = onDeclareWar
C.OnMakePeace = onMakePeace
C.GetDiploModifier = getDiploModifier
C.Initialize = initialize

GameEvents.BattleStarted.Add(onBattleStarted)
GameEvents.BattleJoined.Add(onBattleJoined)
GameEvents.BattleFinished.Add(onBattleFinished)
GameEvents.PlayerCanBuild.Add(canBuildSector)
GameEvents.PlayerBuilding.Add(onPlayerBuilding)
GameEvents.PlayerBuilt.Add(onPlayerBuilt)
GameEvents.PlayerDoTurn.Add(onPlayerDoTurn)
GameEvents.PlayerDoneTurn.Add(trainOnSector)
GameEvents.CityTrained.Add(onCityTrained)
GameEvents.CityCaptureComplete.Add(onCityCaptureComplete)
if GameEvents.UnitPrekill then GameEvents.UnitPrekill.Add(onUnitPrekill) end
if GameEvents.UnitCaptured then GameEvents.UnitCaptured.Add(onUnitCaptured) end
if GameEvents.UnitCreated then GameEvents.UnitCreated.Add(onUnitCreated) end
if GameEvents.UnitUpgraded then
    GameEvents.UnitUpgraded.Add(function(playerID, oldUnitID, newUnitID)
        return onUnitConverted(playerID, playerID, oldUnitID, newUnitID, true)
    end)
end
if GameEvents.UnitConverted then GameEvents.UnitConverted.Add(onUnitConverted) end
if GameEvents.DeclareWar then GameEvents.DeclareWar.Add(onDeclareWar) end
if GameEvents.MakePeace then GameEvents.MakePeace.Add(onMakePeace) end
if GameEvents.GetDiploModifier then GameEvents.GetDiploModifier.Add(getDiploModifier) end

initialize()
print("Capano Circuit: runtime loaded")
