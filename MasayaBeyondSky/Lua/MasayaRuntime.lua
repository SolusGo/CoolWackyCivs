-- Masaya Hinata: Joy of Flight, combat participation, exploration, training,
-- and the Junior FC Prodigy. Loaded once as an InGameUIAddin under CP v151+.

MapModData = MapModData or {}
MapModData.MasayaKid = MapModData.MasayaKid or {}
local M = MapModData.MasayaKid
if M.RuntimeLoaded then return end
M.RuntimeLoaded = true

local function ID(name) return GameInfoTypes[name] end
local I = {
    Civilization = ID("CIVILIZATION_MASAYA_KID"),
    Prodigy = ID("UNIT_MASAYA_KID_FC_PRODIGY"),
    GravRoom = ID("BUILDING_MASAYA_KID_GRAV_ROOM"),
    Inherent = ID("PROMOTION_MASAYA_KID_PRODIGY_INHERENT"),
    MoreFlight = ID("PROMOTION_MASAYA_KID_JUST_ONE_MORE_FLIGHT"),
    Natural = ID("PROMOTION_MASAYA_KID_NATURAL_PRODIGY"),
    CantPut = ID("PROMOTION_MASAYA_KID_CANT_PUT_THEM_DOWN"),
    CantPutActive = ID("PROMOTION_MASAYA_KID_CANT_PUT_ACTIVE"),
    CantStopXP = ID("PROMOTION_MASAYA_KID_CANT_STOP_XP"),
    CantStopMove = ID("PROMOTION_MASAYA_KID_CANT_STOP_MOVE"),
    Beyond = ID("PROMOTION_MASAYA_KID_BEYOND_SKY"),
    ProdigyZOC = ID("PROMOTION_MASAYA_KID_PRODIGY_ZOC"),
    NaturalXP = ID("PROMOTION_MASAYA_KID_NATURAL_XP_15"),
    NaturalLevel = ID("PROMOTION_MASAYA_KID_NATURAL_LEVEL_10"),
    Recon = ID("UNITCOMBAT_RECON"),
    Mounted = ID("UNITCOMBAT_MOUNTED"),
    MountedArcher = ID("UNITCOMBAT_MOUNTED_ARCHER")
}
M.IDs = I

local LAND = DomainTypes.DOMAIN_LAND
local MOVE = GameDefines.MOVE_DENOMINATOR or 60
local save = Modding.OpenSaveData()
local battles, revealed = {}, {}

local function truth(value) return value == true or value == 1 end
local function turn() return Game.GetGameTurn() end
local function log(message) print("[MasayaKid] " .. tostring(message)) end
local function L(key, ...)
    return Locale and Locale.ConvertTextKey and Locale.ConvertTextKey(key, ...) or tostring(key)
end
local function setPromo(unit, promotion, enabled)
    if unit and promotion and promotion >= 0 and unit:IsHasPromotion(promotion) ~= enabled then
        unit:SetHasPromotion(promotion, enabled)
    end
end
local function getUnit(playerID, unitID)
    local player = Players[playerID]
    return player and player:GetUnitByID(unitID) or nil
end
local function getCity(playerID, cityID)
    local player = Players[playerID]
    return player and player:GetCityByID(cityID) or nil
end
local function isMasaya(player)
    if type(player) == "number" then player = Players[player] end
    return player ~= nil and I.Civilization ~= nil and player:GetCivilizationType() == I.Civilization
end
local function isMilitary(unit)
    if unit == nil or unit.IsCombatUnit == nil or not unit:IsCombatUnit() then return false end
    local row = GameInfo.Units[unit:GetUnitType()]
    return row ~= nil and not truth(row.Suicide) and (tonumber(row.NukeDamageLevel) or -1) < 0
end
local function isLandMilitary(unit)
    return isMilitary(unit) and unit:GetDomainType() == LAND
end
local function isReconOrMounted(unit)
    if not unit or not unit.GetUnitCombatType then return false end
    local combat = unit:GetUnitCombatType()
    return combat == I.Recon or combat == I.Mounted or combat == I.MountedArcher
end
local function changed(playerID)
    if LuaEvents and LuaEvents.MasayaKidStateChanged then LuaEvents.MasayaKidStateChanged(playerID) end
end
local function notify(player, key, ...)
    if not player or not player:IsHuman() then return end
    local text = L(key, ...)
    if player.AddNotification and NotificationTypes then
        player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, text)
    elseif Events and Events.GameplayAlertMessage then Events.GameplayAlertMessage(text) end
end

local function playerKey(playerID, suffix)
    return "MASAYA_KID_V1_P" .. tostring(playerID) .. "_" .. suffix
end
local function loadPlayer(playerID, suffix, default)
    local value = save.GetValue(playerKey(playerID, suffix))
    if value == nil then return default end
    return value
end
local function storePlayer(playerID, suffix, value)
    save.SetValue(playerKey(playerID, suffix), value)
end

local function getState(playerID)
    M.PlayerState = M.PlayerState or {}
    local state = M.PlayerState[playerID]
    if not state then
        state = {
            joy = math.max(0, math.min(100, tonumber(loadPlayer(playerID, "JOY", 0)) or 0)),
            beyondEnd = tonumber(loadPlayer(playerID, "BEYOND_END", -1)) or -1
        }
        M.PlayerState[playerID] = state
    end
    return state
end
local function beyondActive(state)
    return state ~= nil and state.beyondEnd > turn()
end

-- Namespaced unit script data persists with saves and coexists with other mods.
local marker = "%[MASAYAKID1:([^%]]*)%]"
local fields = {"serial", "levelFour", "prodigyCombats", "createdTurn", "exploreXP",
    "firstCombatJoy", "combatJoyTurn"}
local defaults = {serial=0,levelFour=0,prodigyCombats=0,createdTurn=-1,exploreXP=0,
    firstCombatJoy=0,combatJoyTurn=-1}

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
    if not unit then return end
    local original = (unit:GetScriptData() or ""):gsub(marker, "")
    local values = {}
    for index, key in ipairs(fields) do values[index] = data[key] or defaults[key] end
    unit:SetScriptData(original .. "[MASAYAKID1:" .. table.concat(values, ",") .. "]")
end
local function identify(unit)
    local data = getUnitState(unit)
    if data.serial == 0 then
        local serial = (tonumber(save.GetValue("MASAYA_KID_V1_NEXT_SERIAL")) or 0) + 1
        save.SetValue("MASAYA_KID_V1_NEXT_SERIAL", serial)
        data.serial = serial
        setUnitState(unit, data)
    end
    return data
end

local refreshPlayer
local function refreshUnit(unit, state)
    if not unit then return end
    local ownerMasaya = isMasaya(unit:GetOwner())
    local land = ownerMasaya and isLandMilitary(unit)
    local beyond = land and beyondActive(state)
    local cantStop = land and not beyond and state.joy >= 50
    setPromo(unit, I.CantStopXP, cantStop)
    setPromo(unit, I.CantStopMove, cantStop and isReconOrMounted(unit))
    setPromo(unit, I.Beyond, beyond)

    local data = identify(unit)
    local cantPutActive = ownerMasaya and unit:IsHasPromotion(I.CantPut)
        and data.createdTurn >= 0 and turn() - data.createdTurn < 10
    setPromo(unit, I.CantPutActive, cantPutActive)

    local zoc = ownerMasaya and unit:GetUnitType() == I.Prodigy and unit:GetMoves() > MOVE
    setPromo(unit, I.ProdigyZOC, zoc)
end
refreshPlayer = function(playerID)
    local player = Players[playerID]
    if not isMasaya(player) then return end
    local state = getState(playerID)
    for unit in player:Units() do refreshUnit(unit, state) end
end

local function activateBeyond(playerID, player, state)
    if beyondActive(state) then return false end
    state.joy, state.beyondEnd = 100, turn() + 6
    storePlayer(playerID, "JOY", state.joy)
    storePlayer(playerID, "BEYOND_END", state.beyondEnd)
    refreshPlayer(playerID)
    notify(player, "TXT_KEY_MASAYA_KID_NOTIFICATION_BEYOND")
    log("Beyond the Sky activated for player " .. playerID .. " until turn " .. state.beyondEnd)
    changed(playerID)
    return true
end

local function changeJoy(playerID, amount, sourceKey)
    local player = Players[playerID]
    amount = math.floor(tonumber(amount) or 0)
    if not isMasaya(player) or amount == 0 then return false end
    local state = getState(playerID)
    if amount < 0 and beyondActive(state) then return false end
    local previous = state.joy
    state.joy = math.max(0, math.min(100, state.joy + amount))
    storePlayer(playerID, "JOY", state.joy)
    if state.joy ~= previous then
        log("Joy increased: " .. previous .. " -> " .. state.joy .. " (" ..
            (amount > 0 and "+" or "") .. amount .. " " .. tostring(sourceKey or "") .. ")")
    end
    if state.joy >= 100 and not beyondActive(state) then
        activateBeyond(playerID, player, state)
    elseif (previous < 50 and state.joy >= 50) or (previous >= 50 and state.joy < 50) then
        refreshPlayer(playerID)
    end
    changed(playerID)
    return state.joy ~= previous
end

local function expireBeyond(playerID, player, state)
    if state.beyondEnd >= 0 and state.beyondEnd <= turn() then
        state.beyondEnd, state.joy = -1, 25
        storePlayer(playerID, "BEYOND_END", -1)
        storePlayer(playerID, "JOY", 25)
        refreshPlayer(playerID)
        notify(player, "TXT_KEY_MASAYA_KID_NOTIFICATION_BEYOND_END")
        log("Beyond the Sky ended for player " .. playerID .. "; Joy reset to 25")
        changed(playerID)
    end
end

-- Exploration is event-driven.  The in-memory team cache is reconstructed from
-- the save game's revealed plots on load, so old tiles can never be re-awarded.
local function plotByIndex(index)
    if Map.GetPlotByIndex then return Map.GetPlotByIndex(index) end
    return nil
end
local function initializeRevealed(teamID)
    if revealed[teamID] then return revealed[teamID] end
    local known = {}
    local count = Map.GetNumPlots and Map.GetNumPlots() or 0
    for index = 0, count - 1 do
        local plot = plotByIndex(index)
        if plot and plot:IsRevealed(teamID, false) then known[index] = true end
    end
    revealed[teamID] = known
    return known
end
local function newlyRevealedBy(unit)
    local player = Players[unit:GetOwner()]
    if not player then return 0 end
    local teamID, known = player:GetTeam(), initializeRevealed(player:GetTeam())
    local radius = math.max(1, (unit.VisibilityRange and unit:VisibilityRange() or 2) + 1)
    local found = 0
    if Map.PlotXYWithRangeCheck then
        for dx = -radius, radius do for dy = -radius, radius do
            local plot = Map.PlotXYWithRangeCheck(unit:GetX(), unit:GetY(), dx, dy, radius)
            if plot and plot:IsRevealed(teamID, false) then
                local index = plot:GetPlotIndex()
                if not known[index] then known[index], found = true, found + 1 end
            end
        end end
    end
    return found
end
local function awardExploration(playerID, amount)
    if amount <= 0 then return end
    local now = turn()
    local savedTurn = tonumber(loadPlayer(playerID, "EXPLORE_TURN", -1)) or -1
    local used = tonumber(loadPlayer(playerID, "EXPLORE_COUNT", 0)) or 0
    if savedTurn ~= now then savedTurn, used = now, 0 end
    local grant = math.min(amount, math.max(0, 5 - used))
    storePlayer(playerID, "EXPLORE_TURN", savedTurn)
    storePlayer(playerID, "EXPLORE_COUNT", used + grant)
    if grant > 0 then changeJoy(playerID, grant, "TXT_KEY_MASAYA_KID_SOURCE_EXPLORATION") end
end
local function onUnitSetXY(playerID, unitID)
    local unit = getUnit(playerID, unitID)
    if not isMasaya(playerID) or not unit then return end
    local amount = newlyRevealedBy(unit)
    awardExploration(playerID, amount)
    if amount > 0 and unit:IsHasPromotion(I.CantPut) then
        local data = identify(unit)
        if data.createdTurn >= 0 and turn() - data.createdTurn < 10 and data.exploreXP < 5 then
            local xp = math.min(amount, 5 - data.exploreXP)
            data.exploreXP = data.exploreXP + xp
            setUnitState(unit, data)
            unit:ChangeExperience(xp)
        end
    end
    refreshUnit(unit, getState(playerID))
end

-- Effective combat-strength helpers are based on the CP Lua unit wrappers and
-- return hundredths of a combat point.
local function baseStrength(unit)
    if not unit then return 0 end
    local melee = tonumber(unit:GetBaseCombatStrength()) or 0
    local ranged = unit.GetBaseRangedCombatStrength and
        (tonumber(unit:GetBaseRangedCombatStrength()) or 0) or 0
    return math.max(melee, ranged) * 100
end
local function attackStrength(attacker, target)
    if not attacker then return 0 end
    local ok, value
    if attacker.IsCanAttackRanged and attacker:IsCanAttackRanged() then
        ok, value = pcall(function() return attacker:GetMaxRangedCombatStrength(target, nil, true) end)
    else
        local targetPlot = target and target:GetPlot() or nil
        local fromPlot = targetPlot and attacker.GetMeleeAttackFromPlot and
            attacker:GetMeleeAttackFromPlot(targetPlot) or attacker:GetPlot()
        ok, value = pcall(function()
            return attacker:GetMaxAttackStrength(fromPlot, targetPlot, target)
        end)
    end
    return ok and (tonumber(value) or 0) > 0 and tonumber(value) or baseStrength(attacker)
end
local function defenseStrength(defender, attacker)
    if not defender then return 0 end
    local ok, value = pcall(function()
        return defender:GetMaxDefenseStrength(defender:GetPlot(), attacker, attacker:GetPlot(),
            attacker.IsCanAttackRanged and attacker:IsCanAttackRanged())
    end)
    return ok and (tonumber(value) or 0) > 0 and tonumber(value) or baseStrength(defender)
end
local function clearNatural(unit)
    setPromo(unit, I.NaturalXP, false)
    setPromo(unit, I.NaturalLevel, false)
end
local function applyNatural(unit, opponent)
    if not unit or not opponent or unit:GetUnitType() ~= I.Prodigy then return end
    local moreXP = opponent:GetExperience() > unit:GetExperience()
    setPromo(unit, I.NaturalXP, moreXP)
    setPromo(unit, I.NaturalLevel, moreXP and opponent:GetLevel() >= unit:GetLevel() + 1)
end
local function prepareBattle()
    local battle = battles[#battles]
    if not battle or battle.prepared or not battle.attacker or not battle.defender then return end
    battle.prepared = true
    if battle.attacker.isCity or battle.defender.isCity then return end
    local attacker = getUnit(battle.attacker.playerID, battle.attacker.id)
    local defender = getUnit(battle.defender.playerID, battle.defender.id)
    if not isMilitary(attacker) or not isMilitary(defender) then return end
    local ap, dp = Players[attacker:GetOwner()], Players[defender:GetOwner()]
    if not ap or not dp or ap:GetTeam() == dp:GetTeam() then return end

    battle.valid, battle.attackerUnit, battle.defenderUnit = true, attacker, defender
    battle.attackStrength = attackStrength(attacker, defender)
    battle.defenseStrength = defenseStrength(defender, attacker)
    battle.members = {
        {playerID=attacker:GetOwner(),unitID=attacker:GetID(),xp=attacker:GetExperience(),
            enemyPlayerID=defender:GetOwner(),enemyUnitID=defender:GetID(),
            strong=battle.defenseStrength >= battle.attackStrength},
        {playerID=defender:GetOwner(),unitID=defender:GetID(),xp=defender:GetExperience(),
            enemyPlayerID=attacker:GetOwner(),enemyUnitID=attacker:GetID(),
            strong=battle.attackStrength >= battle.defenseStrength}
    }
    if isMasaya(ap) then applyNatural(attacker, defender) end
    if isMasaya(dp) then applyNatural(defender, attacker) end
end
local function onBattleStarted(battleType, x, y)
    battles[#battles + 1] = {battleType=battleType,x=x,y=y,prepared=false}
end
local function onBattleJoined(playerID, objectID, role, isCity)
    local battle = battles[#battles]
    if not battle then return end
    if role == 0 then battle.attacker = {playerID=playerID,id=objectID,isCity=truth(isCity)}
    elseif role == 1 then battle.defender = {playerID=playerID,id=objectID,isCity=truth(isCity)} end
    prepareBattle()
end
local function processSurvivingCombat(member, unit)
    local playerID = member.playerID
    local data = identify(unit)
    local gainedCombatXP = unit:GetExperience() > member.xp
    if gainedCombatXP and data.combatJoyTurn ~= turn() then
        data.combatJoyTurn = turn()
        changeJoy(playerID, 2, "TXT_KEY_MASAYA_KID_SOURCE_COMBAT")
    end
    if gainedCombatXP and unit:IsHasPromotion(I.CantPut) and data.firstCombatJoy == 0 then
        data.firstCombatJoy = 1
        changeJoy(playerID, 2, "TXT_KEY_MASAYA_KID_SOURCE_CANT_PUT")
    end
    if unit:IsHasPromotion(I.MoreFlight) then
        unit:ChangeExperience(1)
        if data.prodigyCombats < 3 then
            data.prodigyCombats = data.prodigyCombats + 1
            changeJoy(playerID, 2, "TXT_KEY_MASAYA_KID_SOURCE_MORE_FLIGHT")
        end
    end
    setUnitState(unit, data)
end
local function onBattleFinished()
    local battle = table.remove(battles)
    if not battle or not battle.valid then return end
    for _, member in ipairs(battle.members) do
        if isMasaya(member.playerID) then
            if member.strong then
                changeJoy(member.playerID, 3, "TXT_KEY_MASAYA_KID_SOURCE_STRONG")
            end
            local unit = getUnit(member.playerID, member.unitID)
            if unit then processSurvivingCombat(member, unit); clearNatural(unit) end
        else
            clearNatural(getUnit(member.playerID, member.unitID))
        end
    end
end

local function onUnitPromoted(playerID, unitID)
    local unit = getUnit(playerID, unitID)
    if not isMasaya(playerID) or not isMilitary(unit) then return end
    local state = getState(playerID)
    local wasBeyond = beyondActive(state)
    changeJoy(playerID, 5, "TXT_KEY_MASAYA_KID_SOURCE_PROMOTION")
    local data = identify(unit)
    if data.levelFour == 0 and unit:GetLevel() >= 4 then
        data.levelFour = 1
        setUnitState(unit, data)
        changeJoy(playerID, 10, "TXT_KEY_MASAYA_KID_SOURCE_LEVEL_FOUR")
    end
    if wasBeyond then unit:ChangeDamage(-25) end
end

local function hasBuilding(city, building)
    if not city or not building then return false end
    if city.IsHasBuilding then return city:IsHasBuilding(building) end
    return city:GetNumRealBuilding(building) > 0
end
local function cityHasGarrison(city, playerID)
    if city.GetGarrisonedUnit then
        local ok, unit = pcall(function() return city:GetGarrisonedUnit() end)
        if ok and type(unit) == "number" and unit >= 0 then unit = getUnit(playerID, unit) end
        if ok and unit and isMilitary(unit) then return true end
    end
    local plot = city.Plot and city:Plot() or Map.GetPlot(city:GetX(), city:GetY())
    if not plot then return false end
    for index = 0, plot:GetNumUnits() - 1 do
        local unit = plot:GetUnit(index)
        if unit and unit:GetOwner() == playerID and isMilitary(unit) then return true end
    end
    return false
end
local function processPracticeRooms(playerID, player)
    for city in player:Cities() do
        if hasBuilding(city, I.GravRoom) and cityHasGarrison(city, playerID) then
            local plot = city.Plot and city:Plot() or Map.GetPlot(city:GetX(), city:GetY())
            local suffix = "ROOM_" .. tostring(plot and plot:GetPlotIndex() or city:GetID())
            local count = (tonumber(loadPlayer(playerID, suffix, 0)) or 0) + 1
            if count >= 3 then
                count = 0
                changeJoy(playerID, 1, "TXT_KEY_MASAYA_KID_SOURCE_GRAV_ROOM")
            end
            storePlayer(playerID, suffix, count)
        end
    end
end
local function onCityTrained(playerID, cityID, unitID)
    local player, unit = Players[playerID], getUnit(playerID, unitID)
    local city = player and getCity(playerID, cityID) or nil
    if not isMasaya(player) or not city or not isMilitary(unit) then return end
    local data = identify(unit)
    if hasBuilding(city, I.GravRoom) then
        data.createdTurn, data.exploreXP, data.firstCombatJoy = turn(), 0, 0
        setUnitState(unit, data)
        setPromo(unit, I.CantPut, true)
    end
    local state = getState(playerID)
    if state.joy >= 50 and not beyondActive(state) then unit:ChangeExperience(5) end
    refreshUnit(unit, state)
end
local function onUnitCreated(playerID, unitID)
    local unit = getUnit(playerID, unitID)
    if not unit then return end
    identify(unit)
    clearNatural(unit)
    if isMasaya(playerID) then
        if unit:GetUnitType() == I.Prodigy then
            setPromo(unit, I.Inherent, true)
            setPromo(unit, I.MoreFlight, true)
            setPromo(unit, I.Natural, true)
        end
        refreshUnit(unit, getState(playerID))
    end
end
local function onUnitConverted(oldPlayerID, newPlayerID, oldUnitID, newUnitID, isUpgrade)
    local oldUnit, newUnit = getUnit(oldPlayerID, oldUnitID), getUnit(newPlayerID, newUnitID)
    if not newUnit then return true end
    local data = oldUnit and getUnitState(oldUnit) or identify(newUnit)
    if oldPlayerID ~= newPlayerID and not isMasaya(oldPlayerID) then
        data = identify(newUnit)
        if newUnit:GetLevel() >= 4 then data.levelFour = 1 end
    end
    setUnitState(newUnit, data)
    clearNatural(newUnit)
    if isMasaya(newPlayerID) then refreshUnit(newUnit, getState(newPlayerID))
    else
        setPromo(newUnit, I.CantStopXP, false)
        setPromo(newUnit, I.CantStopMove, false)
        setPromo(newUnit, I.Beyond, false)
        setPromo(newUnit, I.ProdigyZOC, false)
        setPromo(newUnit, I.CantPutActive, false)
        setPromo(newUnit, I.CantPut, false)
    end
    return true
end

local function onPlayerDoTurn(playerID)
    local player = Players[playerID]
    if not isMasaya(player) then return end
    local state = getState(playerID)
    expireBeyond(playerID, player, state)
    initializeRevealed(player:GetTeam())
    processPracticeRooms(playerID, player)
    refreshPlayer(playerID)
    changed(playerID)
end

local function getUIState(playerID)
    if not isMasaya(playerID) then return nil end
    local state = getState(playerID)
    local beyond = beyondActive(state)
    return {joy=state.joy,beyond=beyond,cantStop=state.joy >= 50 and not beyond,
        turns=beyond and math.max(0, state.beyondEnd - turn()) or 0}
end

local function initialize()
    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[playerID]
        if player and player:IsAlive() then
            if isMasaya(player) then initializeRevealed(player:GetTeam()) end
            for unit in player:Units() do
                clearNatural(unit)
                local data = identify(unit)
                if isMasaya(player) then
                    if data.levelFour == 0 and unit:GetLevel() >= 4 then
                        data.levelFour = 1
                        setUnitState(unit, data)
                    end
                    refreshUnit(unit, getState(playerID))
                else
                    setPromo(unit, I.CantStopXP, false)
                    setPromo(unit, I.CantStopMove, false)
                    setPromo(unit, I.Beyond, false)
                    setPromo(unit, I.ProdigyZOC, false)
                    setPromo(unit, I.CantPutActive, false)
                    setPromo(unit, I.CantPut, false)
                end
            end
        end
    end
end

M.IsMasaya = isMasaya
M.GetState = getState
M.GetUIState = getUIState
M.GetUnitState = getUnitState
M.SetUnitState = setUnitState
M.ChangeJoy = changeJoy
M.RefreshPlayer = refreshPlayer
M.OnPlayerDoTurn = onPlayerDoTurn
M.OnUnitSetXY = onUnitSetXY
M.OnUnitPromoted = onUnitPromoted
M.OnUnitCreated = onUnitCreated
M.OnCityTrained = onCityTrained
M.OnBattleStarted = onBattleStarted
M.OnBattleJoined = onBattleJoined
M.OnBattleFinished = onBattleFinished
M.Initialize = initialize

GameEvents.PlayerDoTurn.Add(onPlayerDoTurn)
GameEvents.CityTrained.Add(onCityTrained)
if GameEvents.UnitSetXY then GameEvents.UnitSetXY.Add(onUnitSetXY) end
if GameEvents.UnitCreated then GameEvents.UnitCreated.Add(onUnitCreated) end
if GameEvents.UnitPromoted then GameEvents.UnitPromoted.Add(onUnitPromoted) end
if GameEvents.UnitConverted then GameEvents.UnitConverted.Add(onUnitConverted) end
if GameEvents.UnitUpgraded then
    GameEvents.UnitUpgraded.Add(function(playerID, oldUnitID, newUnitID)
        return onUnitConverted(playerID, playerID, oldUnitID, newUnitID, true)
    end)
end
if GameEvents.BattleStarted then GameEvents.BattleStarted.Add(onBattleStarted) end
if GameEvents.BattleJoined then GameEvents.BattleJoined.Add(onBattleJoined) end
if GameEvents.BattleFinished then GameEvents.BattleFinished.Add(onBattleFinished) end

initialize()
log("runtime loaded")
