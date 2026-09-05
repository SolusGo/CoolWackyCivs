-- The Rou'ls Ascendancy: deterministic gameplay and save-backed consciousnesses.
-- BNW + Community Patch. Loaded once by the InGameUIAddin, never by UI replacements.
MapModData.Rouls = MapModData.Rouls or {}
local R = MapModData.Rouls
if R.CoreLoaded then return end
R.CoreLoaded = true
R.SuppressDeaths = 0

local function ID(name) return GameInfoTypes[name] end
R.ids = {
    Civilization = ID("CIVILIZATION_ROULS_ASCENDANCY"),
    Hollowhound = ID("UNIT_ROULS_HOLLOWHOUND"), Buddy = ID("UNIT_ROULS_BUDDY"),
    Matriarch = ID("UNIT_ROULS_MATRIARCH"),
    Lattice = ID("BUILDING_ROULS_SOMATIC_LATTICE"),
    Choir = ID("BUILDING_ROULS_CHOIR_ETERNAL"),
    CapitalScience = ID("BUILDING_ROULS_CAPITAL_SCIENCE"),
    SecondSkin = ID("PROMOTION_ROULS_SECOND_SKIN"),
    SecondSkinCooldown = ID("PROMOTION_ROULS_SECOND_SKIN_COOLDOWN"),
    ActionLock = ID("PROMOTION_ROULS_ACTION_LOCK"),
    BuddyAura = ID("PROMOTION_ROULS_BUDDY_AURA"),
    BuddyInvasion = ID("PROMOTION_ROULS_BUDDY_INVASION"),
    Everlasting = ID("PROMOTION_ROULS_EVERLASTING_PASSENGER")
}
local I, LAND, SEA, AIR = R.ids, DomainTypes.DOMAIN_LAND, DomainTypes.DOMAIN_SEA, DomainTypes.DOMAIN_AIR
local save = Modding.OpenSaveData()
local states, battles, resolving = {}, {}, false
local function turn() return Game.GetGameTurn() end
local function truth(v) return v == true or v == 1 end
local function key(p, u) return tostring(p) .. ":" .. tostring(u) end
local function alive(unit) return unit and not unit:IsDead() and not unit:IsDelayedDeath() end

-- Length-prefixed values keep Unicode names and other mods' script data intact.
-- No loadstring/eval: save data is data, including after importing a saved game.
local function encode(v)
    local t = type(v)
    if t == "number" then return "n" .. tostring(v) .. ";" end
    if t == "boolean" then return v and "b1" or "b0" end
    if t == "string" then return "s" .. #v .. ":" .. v end
    if t ~= "table" then error("Rouls: unsupported save value " .. t) end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return type(a) .. tostring(a) < type(b) .. tostring(b) end)
    local out = {"t", tostring(#keys), ":"}
    for _, k in ipairs(keys) do out[#out + 1] = encode(k); out[#out + 1] = encode(v[k]) end
    return table.concat(out)
end
local function decode(s)
    local pos = 1
    local function read(depth)
        if depth > 12 then error("Rouls: malformed save nesting") end
        local tag = s:sub(pos, pos); pos = pos + 1
        if tag == "b" then local b = s:sub(pos, pos); pos = pos + 1; return b == "1" end
        local delimiter = tag == "n" and ";" or ":"
        local stop = s:find(delimiter, pos, true)
        if not stop then error("Rouls: incomplete save") end
        local n = tonumber(s:sub(pos, stop - 1)); pos = stop + 1
        if not n then error("Rouls: invalid save number") end
        if tag == "n" then return n end
        if n < 0 or n > 1000000 or n ~= math.floor(n) then error("Rouls: invalid save length") end
        if tag == "s" then
            if pos + n - 1 > #s then error("Rouls: truncated save string") end
            local value = s:sub(pos, pos + n - 1); pos = pos + n; return value
        end
        if tag ~= "t" then error("Rouls: invalid save tag") end
        local value = {}
        for _ = 1, n do local k = read(depth + 1); value[k] = read(depth + 1) end
        return value
    end
    local value = read(0)
    if pos ~= #s + 1 then error("Rouls: trailing save data") end
    return value
end
function R.GetState(playerID)
    if not states[playerID] then
        local raw = save.GetValue("ROULS_V1_PLAYER_" .. tostring(playerID))
        local state
        if type(raw) == "string" and raw ~= "" then
            local ok, value = pcall(decode, raw)
            if not ok or type(value) ~= "table" then error("Rouls: could not read persistent player state: " .. tostring(value)) end
            state = value
        end
        state = state or {}
        local defaults = {anima = 0, rebirthTurn = -1, rebirthCount = 0, choirTurn = -1,
            lastTurn = -1, turnSerial = 0, passiveReadyTurn = turn() + 10, nextSerial = 0,
            swapReadyTurn = 0, migrationUsed = false}
        for k, v in pairs(defaults) do if state[k] == nil then state[k] = v end end
        state.deaths = state.deaths or {}
        states[playerID] = state
    end
    return states[playerID]
end
function R.Save(playerID)
    save.SetValue("ROULS_V1_PLAYER_" .. tostring(playerID), encode(R.GetState(playerID)))
    if LuaEvents.RoulsStateChanged then LuaEvents.RoulsStateChanged(playerID) end
end
function R.IsRouls(player)
    if type(player) == "number" then player = Players[player] end
    return player ~= nil and I.Civilization ~= nil and player:GetCivilizationType() == I.Civilization
end
local function hasBuilding(player, building)
    if not player or not building then return false end
    for city in player:Cities() do if city:GetNumRealBuilding(building) > 0 then return true end end
    return false
end
function R.GetCap(playerID) return hasBuilding(Players[playerID], I.Choir) and 7 or 5 end
function R.GetAnima(playerID)
    local state = R.GetState(playerID)
    local clamped = math.max(0, math.min(R.GetCap(playerID), math.floor(state.anima)))
    if state.anima ~= clamped then state.anima = clamped; R.Save(playerID) end
    return clamped
end
function R.ChangeAnima(playerID, delta)
    local state, old = R.GetState(playerID), R.GetAnima(playerID)
    state.anima = math.max(0, math.min(R.GetCap(playerID), old + math.floor(delta)))
    R.Save(playerID)
    return state.anima - old
end
function R.IsMilitary(unit)
    if not unit then return false end
    local info = GameInfo.Units[unit:GetUnitType()]
    if not info or truth(info.Suicide) or (tonumber(info.NukeDamageLevel) or -1) >= 0 then return false end
    if truth(info.Found) or truth(info.SpreadReligion) or truth(info.RemoveHeresy) or info.Special == "SPECIALUNIT_PEOPLE" then return false end
    return (tonumber(info.Combat) or 0) > 0 or (tonumber(info.RangedCombat) or 0) > 0
end
function R.EquivalentType(playerID, classID)
    local player = Players[playerID]
    local class = GameInfo.UnitClasses[classID]
    if not player or not class then return nil end
    local civ = GameInfo.Civilizations[player:GetCivilizationType()]
    for row in GameInfo.Civilization_UnitClassOverrides() do
        if row.CivilizationType == civ.Type and row.UnitClassType == class.Type then
            return row.UnitType and ID(row.UnitType) or nil
        end
    end
    return class.DefaultUnit and ID(class.DefaultUnit) or nil
end

-- Own a small tagged section; never overwrite another mod's script data.
local marker = "%[ROULS1:([^%]]*)%]"
function R.GetUnitState(unit)
    local value = (unit:GetScriptData() or ""):match(marker)
    local data = {skinReady = 0, rebornTurn = -1, lockUntil = 0, serial = 0, suppressed = 0, deathTurn = -1}
    if value then
        local i, fields = 1, {"skinReady", "rebornTurn", "lockUntil", "serial", "suppressed", "deathTurn"}
        for n in value:gmatch("[^,]+") do if fields[i] then data[fields[i]] = tonumber(n) or data[fields[i]] end; i = i + 1 end
    end
    return data
end
function R.SetUnitState(unit, data)
    local text = (unit:GetScriptData() or ""):gsub(marker, "")
    unit:SetScriptData(text .. "[ROULS1:" .. table.concat({data.skinReady or 0, data.rebornTurn or -1,
        data.lockUntil or 0, data.serial or 0, data.suppressed or 0, data.deathTurn or -1}, ",") .. "]")
end
local function identify(unit)
    local data = R.GetUnitState(unit)
    if data.serial == 0 then
        local state = R.GetState(unit:GetOwner()); state.nextSerial = state.nextSerial + 1
        data.serial = state.nextSerial; R.SetUnitState(unit, data); R.Save(unit:GetOwner())
    end
    return data
end
local function exhaust(unit)
    -- SetMadeAttack increments, rather than assigns, in BNW/CP. Exhaust Blitz too.
    if unit.SetMadeAttack then for _ = 1, 128 do unit:SetMadeAttack(true) end end
    unit:SetMoves(0)
end
function R.LockUnit(unit)
    local data = identify(unit)
    data.lockUntil = R.GetState(unit:GetOwner()).turnSerial + 1
    R.SetUnitState(unit, data)
    if I.ActionLock then unit:SetHasPromotion(I.ActionLock, true) end
    exhaust(unit)
end
function R.IsLocked(unit)
    return unit and R.GetUnitState(unit).lockUntil > R.GetState(unit:GetOwner()).turnSerial
end
function R.WithSuppressedDeaths(fn)
    R.SuppressDeaths = R.SuppressDeaths + 1
    local results = {pcall(fn)}
    R.SuppressDeaths = R.SuppressDeaths - 1
    if not results[1] then error(results[2]) end
    return unpack(results, 2)
end

local transient = {}
for _, id in ipairs({I.BuddyAura or -1, I.BuddyInvasion or -1, I.SecondSkinCooldown or -1}) do transient[id] = true end
for n = 1, 5 do transient[ID("PROMOTION_ROULS_CHOIR_" .. n) or -1] = true end
function R.Snapshot(unit)
    local info, promotions = GameInfo.Units[unit:GetUnitType()], {}
    local data = identify(unit)
    for promotion in GameInfo.UnitPromotions() do
        if not transient[promotion.ID] and unit:IsHasPromotion(promotion.ID) then promotions[#promotions + 1] = promotion.ID end
    end
    table.sort(promotions)
    return {unitType = unit:GetUnitType(), classID = ID(info.Class), domain = unit:GetDomainType(),
        xp100 = unit.GetExperienceTimes100 and unit:GetExperienceTimes100() or unit:GetExperience() * 100,
        level = unit:GetLevel(), name = unit:GetNameNoDesc(), promotions = promotions,
        script = unit:GetScriptData() or "", unitState = data, x = unit:GetX(), y = unit:GetY(),
        owner = unit:GetOwner(), oldID = unit:GetID(), deathTurn = turn(),
        cost = tonumber(info.Cost) or 0, combatClass = info.CombatClass}
end
local function ignored(ignore, unit)
    return ignore and ignore[key(unit:GetOwner(), unit:GetID())] == true
end
local function occupancy(playerID, domain, plot, ignore)
    local player = Players[playerID]
    if plot:IsCity() and plot:GetOwner() ~= playerID then return false end
    for i = 0, plot:GetNumUnits() - 1 do
        local other = plot:GetUnit(i)
        if other and not ignored(ignore, other) and alive(other) then
            local otherPlayer = Players[other:GetOwner()]
            if otherPlayer and Teams[player:GetTeam()]:IsAtWar(otherPlayer:GetTeam()) then return false end
            if R.IsMilitary(other) and other:GetDomainType() == domain then return false end
        end
    end
    return true
end
function R.IsLegalTypePlot(playerID, unitType, plot, ignore)
    local player, info = Players[playerID], GameInfo.Units[unitType]
    if not player or not info or not plot then return false end
    local domain = ID(info.Domain)
    if domain ~= LAND and domain ~= SEA then return false end
    if plot:IsMountain() or plot:IsImpassable() then return false end
    if domain == LAND and plot:IsWater() then return false end
    if domain == SEA and not plot:IsWater() then
        local city = plot:GetPlotCity()
        if not city or city:GetOwner() ~= playerID or not city:IsCoastal(1) then return false end
    end
    local owner = plot:GetOwner()
    if owner >= 0 and owner ~= playerID then
        local team = Players[owner]:GetTeam()
        if team ~= player:GetTeam() and not Teams[player:GetTeam()]:IsAtWar(team)
            and not Teams[team]:IsAllowsOpenBordersToTeam(player:GetTeam()) then return false end
    end
    -- Type-level check is conservative; Restore also asks the actual new unit.
    for row in GameInfo.Unit_FreePromotions() do
        if row.UnitType == info.Type then
            local promotion = GameInfo.UnitPromotions[row.PromotionType]
            if promotion and truth(promotion.CannotOcean) and plot:GetTerrainType() == ID("TERRAIN_OCEAN") then return false end
            if promotion and truth(promotion.OceanImpassable) and plot:GetTerrainType() == ID("TERRAIN_OCEAN") then return false end
        end
    end
    return occupancy(playerID, domain, plot, ignore)
end
function R.IsLegalPlot(unit, plot, ignore)
    if not unit or not plot or unit:IsEmbarked() or unit:GetDomainType() == AIR then return false end
    local own = {}; if ignore then for k, v in pairs(ignore) do own[k] = v end end
    own[key(unit:GetOwner(), unit:GetID())] = true
    if not R.IsLegalTypePlot(unit:GetOwner(), unit:GetUnitType(), plot, own) then return false end
    -- CP CanMoveThrough calls canMoveInto without the destination stacking flag.
    -- We check real occupancy ourselves, excluding exactly the two swap partners.
    return unit:CanMoveThrough(plot)
end
function R.Restore(playerID, snapshot, plot, hpPercent)
    local player = Players[playerID]
    if not player or not player:IsAlive() or player:GetNumCities() == 0 then return nil end
    local unitType = R.EquivalentType(playerID, snapshot.classID) or snapshot.unitType
    if not unitType or not GameInfo.Units[unitType] or not R.IsLegalTypePlot(playerID, unitType, plot) then return nil end
    local unit = player:InitUnit(unitType, plot:GetX(), plot:GetY())
    if not unit then return nil end
    local ok, err = pcall(function()
        unit:SetScriptData(snapshot.script or "")
        local info = GameInfo.Units[unitType]
        for _, promotion in ipairs(snapshot.promotions or {}) do
            if GameInfo.UnitPromotions[promotion] and not transient[promotion]
                and (snapshot.unitType == unitType or promotion == I.SecondSkin or unit:IsPromotionValid(promotion)) then
                unit:SetHasPromotion(promotion, true)
            end
        end
        if unit.SetExperienceTimes100 then unit:SetExperienceTimes100(snapshot.xp100 or 0, -1)
        else unit:SetExperience(math.floor((snapshot.xp100 or 0) / 100), -1) end
        unit:SetLevel(snapshot.level or 1)
        if snapshot.name and snapshot.name ~= "" then unit:SetName(snapshot.name) end
        local maxHP = unit:GetMaxHitPoints()
        unit:SetDamage(maxHP - math.max(1, math.floor(maxHP * (hpPercent or 50) / 100)))
        local data = R.GetUnitState(unit)
        data.suppressed, data.deathTurn, data.rebornTurn = 0, -1, turn()
        R.SetUnitState(unit, data)
        if I.SecondSkinCooldown and unit:IsHasPromotion(I.SecondSkin) then
            unit:SetHasPromotion(I.SecondSkinCooldown, data.skinReady > turn())
        end
        R.LockUnit(unit)
    end)
    if not ok then
        R.WithSuppressedDeaths(function() unit:Kill(false, -1) end)
        print("Rouls: reconstruction failed: " .. tostring(err)); return nil
    end
    -- InitUnit can relocate on its own: require the exact promised city tile.
    if unit:GetX() ~= plot:GetX() or unit:GetY() ~= plot:GetY() then
        R.WithSuppressedDeaths(function() unit:Kill(false, -1) end); return nil
    end
    return unit
end

local function cityCandidates(playerID, snapshot, buddy)
    local player, choices = Players[playerID], {}
    local unitType = R.EquivalentType(playerID, snapshot.classID) or snapshot.unitType
    local capital = player:GetCapitalCity()
    for city in player:Cities() do
        local plot = city:Plot()
        local distance = Map.PlotDistance(snapshot.x, snapshot.y, city:GetX(), city:GetY())
        if buddy and capital then distance = Map.PlotDistance(capital:GetX(), capital:GetY(), city:GetX(), city:GetY()) end
        if R.IsLegalTypePlot(playerID, unitType, plot) then
            choices[#choices + 1] = {plot = plot, rank = buddy and city == capital and -1 or distance, index = plot:GetPlotIndex()}
        end
        if buddy and city:IsCoastal(1) then
            for direction = 0, 5 do
                local adjacent = Map.PlotDirection(city:GetX(), city:GetY(), direction)
                if adjacent and adjacent:IsWater() and adjacent:GetOwner() == playerID
                    and R.IsLegalTypePlot(playerID, unitType, adjacent) then
                    choices[#choices + 1] = {plot = adjacent, rank = distance + 0.5, index = adjacent:GetPlotIndex()}
                end
            end
        end
    end
    table.sort(choices, function(a, b) return a.rank < b.rank or (a.rank == b.rank and a.index < b.index) end)
    return choices
end
local function resurrect(playerID, snapshot, buddy)
    for _, candidate in ipairs(cityCandidates(playerID, snapshot, buddy)) do
        local unit = R.Restore(playerID, snapshot, candidate.plot, 50)
        if unit then return unit end
    end
end
local function hasBuddy(playerID)
    for unit in Players[playerID]:Units() do if alive(unit) and unit:GetUnitType() == I.Buddy then return true end end
    return false
end
local function notify(playerID, message, x, y)
    local player = Players[playerID]
    if player and player:IsHuman() and player.AddNotification then
        player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, "The Rou'ls Ascendancy", x or -1, y or -1)
    end
end
R.Notify = notify
local function priority(snapshot)
    if snapshot.level >= 4 then return 1 end
    if snapshot.combatClass == "UNITCOMBAT_SIEGE" then return 2 end
    if snapshot.combatClass == "UNITCOMBAT_ARCHER" then return 3 end
    if snapshot.unitType == I.Hollowhound then return 4 end
    if snapshot.cost >= 300 then return 5 end
    return 6
end
function R.ResolveDeaths(playerID)
    if resolving then return end
    local state, player = R.GetState(playerID), Players[playerID]
    if #state.deaths == 0 then return end
    resolving = true
    local pending = state.deaths; state.deaths = {}
    table.sort(pending, function(a, b)
        if a.deathTurn ~= b.deathTurn then return a.deathTurn < b.deathTurn end
        if not player:IsHuman() then
            if priority(a) ~= priority(b) then return priority(a) < priority(b) end
            if a.xp100 ~= b.xp100 then return a.xp100 > b.xp100 end
        end
        return a.unitState.serial < b.unitState.serial
    end)
    if player:IsAlive() and player:GetNumCities() > 0 then
        for _, snapshot in ipairs(pending) do
            if state.rebirthTurn ~= snapshot.deathTurn then state.rebirthTurn = snapshot.deathTurn; state.rebirthCount = 0 end
            if state.rebirthCount < 2 then
                local free = false
                for _, promotion in ipairs(snapshot.promotions) do
                    if promotion == I.SecondSkin and snapshot.unitState.skinReady <= snapshot.deathTurn then free = true end
                end
                local cost = free and 0 or 1
                if R.GetAnima(playerID) >= cost then
                    if free then
                        snapshot.unitState.skinReady = snapshot.deathTurn + 15
                        local data = snapshot.unitState
                        snapshot.script = (snapshot.script or ""):gsub(marker, "") .. "[ROULS1:" .. table.concat({data.skinReady,
                            data.rebornTurn, data.lockUntil, data.serial, 0, -1}, ",") .. "]"
                    end
                    local unit = resurrect(playerID, snapshot, false)
                    if unit then
                        state.rebirthCount = state.rebirthCount + 1
                        R.ChangeAnima(playerID, -cost)
                        notify(playerID, "Nothing Is Lost: " .. unit:GetName() .. " returns at half health.", unit:GetX(), unit:GetY())
                    end
                end
            end
        end
    end
    R.Save(playerID); resolving = false
end
local function resolveAll()
    for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do if R.IsRouls(playerID) then R.ResolveDeaths(playerID) end end
end
local function choirDeath(victimPlayerID, x, y)
    local victim = Players[victimPlayerID]
    for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local player = Players[playerID]
        if R.IsRouls(player) and player:IsAlive() and Teams[player:GetTeam()]:IsAtWar(victim:GetTeam()) then
            local state = R.GetState(playerID)
            if state.choirTurn ~= turn() and R.GetAnima(playerID) < R.GetCap(playerID) then
                for city in player:Cities() do
                    if city:GetNumRealBuilding(I.Choir) > 0 and Map.PlotDistance(x, y, city:GetX(), city:GetY()) <= 3 then
                        if Game.Rand(100, "Rouls Choir Eternal death reserve") < 20 then
                            state.choirTurn = turn(); R.ChangeAnima(playerID, 1)
                        end
                        break
                    end
                end
            end
        end
    end
end
local function attributedMilitaryKill(victimPlayerID, unitID, killerPlayerID)
    local battle = battles[#battles]
    if not battle then return false end
    local victimRole
    for role, member in pairs(battle.members) do
        if member.playerID == victimPlayerID and member.unitID == unitID and not member.isCity then victimRole = role end
    end
    if victimRole == nil then return false end
    if victimRole == 0 then
        for _, role in ipairs({2, 1}) do
            local killer = battle.members[role]
            if killer and killer.playerID == killerPlayerID and killer.military and not killer.isCity then return true end
        end
    else
        local killer = battle.members[0]
        if killer and killer.playerID == killerPlayerID and killer.military and not killer.isCity then return true end
    end
    return false
end
local function onPrekill(playerID, unitID, unitType, x, y, delay, killerPlayerID)
    local player = Players[playerID]
    local unit = player and player:GetUnitByID(unitID)
    if not unit then return end
    local data = R.GetUnitState(unit)
    if R.SuppressDeaths > 0 then data.suppressed = 1; R.SetUnitState(unit, data); return end
    if data.suppressed == 1 or data.deathTurn == turn() then return end
    -- Civ5 uses kill() for upgrades, gifts, capture conversion, scrapping and GP use.
    -- A hostile killer or lethal damage is required; healthy administrative removals are excluded.
    local killer = killerPlayerID and Players[killerPlayerID]
    local hostile = killer and killerPlayerID ~= playerID and Teams[player:GetTeam()]:IsAtWar(killer:GetTeam())
    if not hostile and unit:GetDamage() < unit:GetMaxHitPoints() then return end
    data.deathTurn = turn(); R.SetUnitState(unit, data)
    -- A recreated body cannot recursively generate any Rou'ls death bonuses this round.
    if data.rebornTurn == turn() then return end
    if hostile and R.IsMilitary(unit) and R.IsRouls(killer)
        and attributedMilitaryKill(playerID, unitID, killerPlayerID) then R.ChangeAnima(killerPlayerID, 1) end
    choirDeath(playerID, x, y)
    if not R.IsRouls(player) or not R.IsMilitary(unit) or not player:IsAlive() then return end
    local state = R.GetState(playerID)
    if unitType == I.Buddy then
        if state.buddy == nil and R.GetAnima(playerID) >= 3 then
            state.buddy = {snapshot = R.Snapshot(unit), readyTurn = turn() + 3}
            R.ChangeAnima(playerID, -3)
            notify(playerID, "Buddy's consciousness is safe. He will return in three turns when a coastal berth is available.", x, y)
        end
        return
    end
    if unit:GetDomainType() ~= LAND then return end
    local free = I.SecondSkin and unit:IsHasPromotion(I.SecondSkin) and data.skinReady <= turn()
    if not free and R.GetAnima(playerID) < 1 then return end
    state.deaths[#state.deaths + 1] = R.Snapshot(unit)
    R.Save(playerID)
end
local function refreshCapital(playerID)
    local player = Players[playerID]
    if not player or not I.CapitalScience then return end
    local capital = R.IsRouls(player) and player:GetCapitalCity() or nil
    for city in player:Cities() do
        local expected = city == capital and 1 or 0
        if city:GetNumRealBuilding(I.CapitalScience) ~= expected then city:SetNumRealBuilding(I.CapitalScience, expected) end
    end
    if R.IsRouls(player) then R.GetAnima(playerID) end
end
R.RefreshCapital = refreshCapital
local function onPlayerTurn(playerID)
    local player = Players[playerID]
    if not R.IsRouls(player) then return end
    local state = R.GetState(playerID)
    if state.lastTurn == turn() then return end
    state.lastTurn = turn(); state.turnSerial = state.turnSerial + 1
    refreshCapital(playerID)
    for unit in player:Units() do
        local data = R.GetUnitState(unit)
        if I.SecondSkinCooldown and I.SecondSkin and unit:IsHasPromotion(I.SecondSkin) then
            unit:SetHasPromotion(I.SecondSkinCooldown, data.skinReady > turn())
        end
        local locked = R.IsLocked(unit)
        if I.ActionLock then unit:SetHasPromotion(I.ActionLock, locked) end
        if locked then exhaust(unit) end
    end
    R.ResolveDeaths(playerID)
    if hasBuilding(player, I.Lattice) then
        if turn() >= state.passiveReadyTurn and R.GetAnima(playerID) == 0 then
            state.passiveReadyTurn = turn() + 10; R.ChangeAnima(playerID, 1)
        end
    else
        -- No banked progress from the eras before the first Lattice exists.
        state.passiveReadyTurn = turn() + 10
    end
    if state.buddy and state.buddy.readyTurn <= turn() and player:IsAlive() and not hasBuddy(playerID) then
        local unit = resurrect(playerID, state.buddy.snapshot, true)
        if unit then
            state.buddy = nil
            notify(playerID, "Buddy, Everlasting has returned!", unit:GetX(), unit:GetY())
        end
    end
    R.Save(playerID)
end
local function onConverted(oldOwner, newOwner, oldID, newID)
    local oldPlayer, newPlayer = Players[oldOwner], Players[newOwner]
    local oldUnit, newUnit = oldPlayer and oldPlayer:GetUnitByID(oldID), newPlayer and newPlayer:GetUnitByID(newID)
    if not oldUnit or not newUnit then return end
    local data = R.GetUnitState(oldUnit)
    if data.serial == 0 and data.skinReady == 0 then return end
    -- CP does not copy ScriptData in CvUnit::convert. Transfer our marker only.
    data.suppressed, data.deathTurn = 0, -1
    if oldOwner ~= newOwner then data.serial = 0; data.lockUntil = 0 end
    R.SetUnitState(newUnit, data)
    if I.SecondSkinCooldown then newUnit:SetHasPromotion(I.SecondSkinCooldown, data.skinReady > turn()) end
    if R.IsLocked(newUnit) then exhaust(newUnit) end
end

GameEvents.PlayerDoTurn.Add(onPlayerTurn)
GameEvents.UnitPrekill.Add(onPrekill)
GameEvents.BattleStarted.Add(function() battles[#battles + 1] = {members = {}} end)
GameEvents.BattleJoined.Add(function(playerID, unitID, role, isCity)
    local battle = battles[#battles]
    if not battle then return end
    local player = Players[playerID]
    local unit = not truth(isCity) and player and player:GetUnitByID(unitID)
    battle.members[role] = {playerID = playerID, unitID = unitID, isCity = truth(isCity), military = R.IsMilitary(unit)}
end)
GameEvents.BattleFinished.Add(function() if #battles > 0 then table.remove(battles) end; if #battles == 0 then resolveAll() end end)
GameEvents.CityTrained.Add(function(playerID, cityID, unitID, gold, faith)
    local player = Players[playerID]
    if not R.IsRouls(player) or truth(gold) or truth(faith) or R.SuppressDeaths > 0 then return end
    local city, unit = player:GetCityByID(cityID), player:GetUnitByID(unitID)
    if city and R.IsMilitary(unit) and city:GetNumRealBuilding(I.Lattice) > 0
        and R.GetAnima(playerID) < R.GetCap(playerID) and Game.Rand(100, "Rouls Lattice military completion") < 25 then
        R.ChangeAnima(playerID, 1)
    end
end)
GameEvents.PlayerCanTrain.Add(function(playerID, unitType)
    if unitType ~= I.Buddy then return true end
    return R.IsRouls(playerID) and R.GetState(playerID).buddy == nil and not hasBuddy(playerID)
end)
if GameEvents.UnitUpgraded then GameEvents.UnitUpgraded.Add(function(p, oldID, newID) onConverted(p, p, oldID, newID) end) end
if GameEvents.UnitConverted then GameEvents.UnitConverted.Add(onConverted) end
GameEvents.PlayerCityFounded.Add(function(playerID) refreshCapital(playerID) end)
GameEvents.CityCaptureComplete.Add(function(oldOwner, _, _, _, newOwner)
    refreshCapital(oldOwner); refreshCapital(newOwner)
end)
if GameEvents.CapitalChanged then GameEvents.CapitalChanged.Add(function(playerID) refreshCapital(playerID) end) end
-- Safe fallback for environmental deaths; never create units inside UnitPrekill.
if Events.SerialEventGameDataDirty then Events.SerialEventGameDataDirty.Add(function() if #battles == 0 then resolveAll() end end) end
for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
    if Players[playerID] then refreshCapital(playerID) end
end
print("Rouls: core loaded")
