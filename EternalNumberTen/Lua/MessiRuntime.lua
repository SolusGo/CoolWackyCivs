-- The Eternal Number Ten runtime: Legacy, Career Chapters, formations, Assists, and Resilience.

MapModData.MessiLegacy = MapModData.MessiLegacy or {}
local M = MapModData.MessiLegacy
if M.RuntimeLoaded then return end

local DEBUG = false
local save = Modding.OpenSaveData()
local I = {
    Civilization = GameInfoTypes.CIVILIZATION_ETERNAL_NUMBER_TEN,
    NumberTen = GameInfoTypes.UNIT_MESSI_NUMBER_TEN,
    LaMasia = GameInfoTypes.BUILDING_MESSI_LA_MASIA,
    Academy = GameInfoTypes.IMPROVEMENT_MESSI_FOOTBALL_ACADEMY,
    CapitalScience = GameInfoTypes.BUILDING_MESSI_CAPITAL_SPECIALIST_SCIENCE,
    SpecialistFood = GameInfoTypes.BUILDING_MESSI_LA_MASIA_SPECIALIST_FOOD,
    TalentProduction = GameInfoTypes.BUILDING_MESSI_LA_MASIA_PRODUCTION,
    WonderCulture = GameInfoTypes.BUILDING_MESSI_WORLD_WONDER_CULTURE,
    ResilienceProduction = GameInfoTypes.BUILDING_MESSI_RESILIENCE_PRODUCTION,
    AlliedCityState = GameInfoTypes.BUILDING_MESSI_ALLIED_CITY_STATE,
    AcademyGold = GameInfoTypes.BUILDING_MESSI_ACADEMY_GOLD,
    OneTwo = GameInfoTypes.PROMOTION_MESSI_ONE_TWO,
    OneTwoChapter3 = GameInfoTypes.PROMOTION_MESSI_ONE_TWO_CHAPTER_3,
    Vision = GameInfoTypes.PROMOTION_MESSI_VISION,
    CapitalVision = GameInfoTypes.PROMOTION_MESSI_CAPITAL_VISION,
    Resilience = GameInfoTypes.PROMOTION_MESSI_RESILIENCE,
    Theology = GameInfoTypes.TECH_THEOLOGY,
    ScoutClass = GameInfoTypes.UNITCLASS_SCOUT,
}

local chapters = {
    {threshold=25, era=-1, policy=GameInfoTypes.POLICY_MESSI_CHAPTER_1,
     title='TXT_KEY_MESSI_CHAPTER_1_TITLE', effects='TXT_KEY_MESSI_CHAPTER_1_EFFECTS', story='TXT_KEY_MESSI_CHAPTER_1_STORY'},
    {threshold=55, era=GameInfoTypes.ERA_CLASSICAL, policy=GameInfoTypes.POLICY_MESSI_CHAPTER_2,
     title='TXT_KEY_MESSI_CHAPTER_2_TITLE', effects='TXT_KEY_MESSI_CHAPTER_2_EFFECTS', story='TXT_KEY_MESSI_CHAPTER_2_STORY'},
    {threshold=90, era=GameInfoTypes.ERA_RENAISSANCE, policy=GameInfoTypes.POLICY_MESSI_CHAPTER_3,
     title='TXT_KEY_MESSI_CHAPTER_3_TITLE', effects='TXT_KEY_MESSI_CHAPTER_3_EFFECTS', story='TXT_KEY_MESSI_CHAPTER_3_STORY'},
    {threshold=130, era=GameInfoTypes.ERA_INDUSTRIAL, policy=GameInfoTypes.POLICY_MESSI_CHAPTER_4,
     title='TXT_KEY_MESSI_CHAPTER_4_TITLE', effects='TXT_KEY_MESSI_CHAPTER_4_EFFECTS', story='TXT_KEY_MESSI_CHAPTER_4_STORY'},
    {threshold=180, era=GameInfoTypes.ERA_MODERN, policy=GameInfoTypes.POLICY_MESSI_CHAPTER_5,
     title='TXT_KEY_MESSI_CHAPTER_5_TITLE', effects='TXT_KEY_MESSI_CHAPTER_5_EFFECTS', story='TXT_KEY_MESSI_CHAPTER_5_STORY'},
    {threshold=240, era=GameInfoTypes.ERA_ATOMIC, policy=GameInfoTypes.POLICY_MESSI_CHAPTER_6,
     title='TXT_KEY_MESSI_CHAPTER_6_TITLE', effects='TXT_KEY_MESSI_CHAPTER_6_EFFECTS', story='TXT_KEY_MESSI_CHAPTER_6_STORY'},
}
local epiloguePolicies = {}
for index = 1, 6 do epiloguePolicies[index] = GameInfoTypes['POLICY_MESSI_EPILOGUE_' .. index] end

local states, battles = {}, {}
local specialistIDs, specialistBuildings, worldWonders = {}, {}, {}

local function log(message)
    if DEBUG then print('Eternal Number Ten: ' .. tostring(message)) end
end
local function truth(value) return value == true or value == 1 end
local function key(playerID, suffix) return 'Messi|' .. playerID .. '|' .. suffix end
local function load(playerID, suffix, fallback)
    local value = save.GetValue(key(playerID, suffix))
    if value == nil then return fallback end
    return value
end
local function store(playerID, suffix, value) save.SetValue(key(playerID, suffix), value) end
local function cityKey(city, suffix)
    return 'City|' .. city:GetX() .. '|' .. city:GetY() .. '|' .. suffix
end
local function isMessi(value)
    local player = type(value) == 'number' and Players[value] or value
    return player ~= nil and player:IsAlive() and player:GetCivilizationType() == I.Civilization
end
local function getState(playerID)
    if states[playerID] then return states[playerID] end
    local state = {
        legacy=tonumber(load(playerID, 'Legacy', 0)) or 0,
        assists=tonumber(load(playerID, 'AssistCount', 0)) or 0,
        assistTurn=tonumber(load(playerID, 'AssistTurn', -1)) or -1,
        resilienceEnd=tonumber(load(playerID, 'ResilienceEnd', -1)) or -1,
        resilienceNext=tonumber(load(playerID, 'ResilienceNext', -1)) or -1,
        epilogue=tonumber(load(playerID, 'EpilogueCount', 0)) or 0,
        tourism=tonumber(load(playerID, 'EpilogueTourism', 0)) or 0,
        golden=truth(load(playerID, 'GoldenState', 0)),
        unlocked={},
    }
    for index = 1, 6 do state.unlocked[index] = truth(load(playerID, 'Chapter' .. index, 0)) end
    states[playerID] = state
    return state
end
local function L(tag, ...)
    if Locale and Locale.ConvertTextKey then return Locale.ConvertTextKey(tag, ...) end
    return tag
end
local function notify(player, bodyKey, summaryKey, ...)
    if not player or not player:IsHuman() or not player.AddNotification then return end
    local body = L(bodyKey, ...)
    local summary = L(summaryKey)
    local capital = player:GetCapitalCity()
    player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, body, summary,
        capital and capital:GetX() or -1, capital and capital:GetY() or -1)
end
local function changed(playerID)
    if LuaEvents and LuaEvents.MessiLegacyChanged then LuaEvents.MessiLegacyChanged(playerID) end
end
local function setBuilding(city, building, count)
    if city and building and city:GetNumRealBuilding(building) ~= count then
        city:SetNumRealBuilding(building, count)
    end
end
local function hasBuilding(city, building)
    if not city or not building then return false end
    if city.IsHasBuilding then return city:IsHasBuilding(building) end
    return city:GetNumRealBuilding(building) > 0
end
local function setPromotion(unit, promotion, enabled)
    if unit and promotion and unit:IsHasPromotion(promotion) ~= enabled then
        unit:SetHasPromotion(promotion, enabled)
    end
end
local function isMilitary(unit)
    if not unit then return false end
    if unit.IsCombatUnit then return unit:IsCombatUnit() end
    local row = GameInfo.Units[unit:GetUnitType()]
    return row and ((row.Combat or 0) > 0 or (row.RangedCombat or 0) > 0) or false
end
local function adjacent(plot, direction)
    if not plot then return nil end
    return Map.PlotDirection(plot:GetX(), plot:GetY(), direction)
end
local function isGoldenAge(player)
    if player.IsGoldenAge then return player:IsGoldenAge() end
    return player.GetGoldenAgeTurns and player:GetGoldenAgeTurns() > 0 or false
end
local function gameTurn() return Game.GetGameTurn and Game.GetGameTurn() or 0 end

local function buildLookups()
    for row in GameInfo.Specialists() do
        if row.Type ~= 'SPECIALIST_CITIZEN' then specialistIDs[#specialistIDs + 1] = row.ID end
    end
    for row in GameInfo.Buildings() do
        if (row.SpecialistCount or 0) > 0 then specialistBuildings[row.ID] = true end
        local class = row.BuildingClass and GameInfo.BuildingClasses[row.BuildingClass]
        if class and (class.MaxGlobalInstances or -1) > 0 then worldWonders[row.ID] = true end
    end
end
buildLookups()

local function specialistCount(city)
    local count = 0
    if not city.GetSpecialistCount then return 0 end
    for _, specialist in ipairs(specialistIDs) do count = count + (city:GetSpecialistCount(specialist) or 0) end
    return count
end
local function cityHasSpecialistBuilding(city)
    for building in pairs(specialistBuildings) do
        if hasBuilding(city, building) then return true end
    end
    return false
end
local function wonderCount(city)
    local count = 0
    for building in pairs(worldWonders) do if hasBuilding(city, building) then count = count + 1 end end
    return count
end
local function alliedCityStates(playerID)
    local count, ids = 0, {}
    for minorID = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do
        local minor = Players[minorID]
        if minor and minor:IsAlive() and minor:IsMinorCiv() and minor.GetAlly and minor:GetAlly() == playerID then
            count = count + 1
            ids[#ids + 1] = minorID
        end
    end
    table.sort(ids)
    return count, table.concat(ids, ',')
end
local function academyGold(city)
    if not cityHasSpecialistBuilding(city) then return 0 end
    local count = 0
    local limit = GameDefines.NUM_CITY_PLOTS or 37
    for index = 0, limit - 1 do
        local plot = city:GetCityIndexPlot(index)
        if plot and plot:GetImprovementType() == I.Academy
            and plot.GetWorkingCity and plot:GetWorkingCity() == city then
            count = count + 1
        end
    end
    return count
end
local function resilienceActive(state) return gameTurn() < state.resilienceEnd end

local function refreshCity(playerID, player, city, state)
    local specialists = specialistCount(city)
    setBuilding(city, I.SpecialistFood, hasBuilding(city, I.LaMasia) and math.floor(specialists / 2) or 0)
    setBuilding(city, I.CapitalScience,
        state.unlocked[2] and city:IsCapital() and specialists or 0)
    setBuilding(city, I.WonderCulture, state.unlocked[3] and wonderCount(city) or 0)
    setBuilding(city, I.ResilienceProduction, resilienceActive(state) and 1 or 0)
    local productionUntil = tonumber(load(playerID, cityKey(city, 'TalentProductionUntil'), -1)) or -1
    setBuilding(city, I.TalentProduction, gameTurn() < productionUntil and 1 or 0)
    setBuilding(city, I.AlliedCityState,
        state.unlocked[5] and city:IsCapital() and alliedCityStates(playerID) or 0)
    setBuilding(city, I.AcademyGold, academyGold(city))
end

local function adjacentMilitaryCount(unit)
    local count, plot = 0, unit:GetPlot()
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local candidate = adjacent(plot, direction)
        if candidate then
            for index = 0, candidate:GetNumUnits() - 1 do
                local other = candidate:GetUnit(index)
                if other and other:GetOwner() == unit:GetOwner() and isMilitary(other) then
                    count = count + 1
                    if count >= 2 then return count end
                end
            end
        end
    end
    return count
end
local function besideNumberTen(unit)
    local plot = unit:GetPlot()
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local candidate = adjacent(plot, direction)
        if candidate then
            for index = 0, candidate:GetNumUnits() - 1 do
                local other = candidate:GetUnit(index)
                if other and other:GetOwner() == unit:GetOwner() and other:GetUnitType() == I.NumberTen then return true end
            end
        end
    end
    return false
end
local function refreshUnit(unit, state, formation)
    if not unit then return end
    local land = isMilitary(unit) and (not unit.GetDomainType or unit:GetDomainType() == DomainTypes.DOMAIN_LAND)
    if formation then
        local triangle = land and adjacentMilitaryCount(unit) >= 2
        local vision = land and besideNumberTen(unit)
        setPromotion(unit, I.OneTwo, triangle)
        setPromotion(unit, I.OneTwoChapter3, triangle and state.unlocked[3])
        setPromotion(unit, I.Vision, vision)
    end
    setPromotion(unit, I.Resilience, isMilitary(unit) and resilienceActive(state))
end
local function refreshPlayer(playerID, formation)
    local player = Players[playerID]
    if not isMessi(player) then return end
    local state = getState(playerID)
    for city in player:Cities() do refreshCity(playerID, player, city, state) end
    for unit in player:Units() do refreshUnit(unit, state, formation == true) end
    changed(playerID)
end

local function grantFreeLaMasia(playerID, player)
    local state = getState(playerID)
    if not state.unlocked[2] or truth(load(playerID, 'FreeLaMasiaGranted', 0)) then return end
    local team = Teams[player:GetTeam()]
    if not team or not team:IsHasTech(I.Theology) then return end
    local capital = player:GetCapitalCity()
    if capital then
        setBuilding(capital, I.LaMasia, 1)
        store(playerID, 'FreeLaMasiaGranted', 1)
        log('free La Masia granted')
    end
end

local function chapterSix(playerID, player, state)
    if player.ChangeGoldenAgeTurns then player:ChangeGoldenAgeTurns(6) end
    if player.ChangeNumFreePolicies then player:ChangeNumFreePolicies(1) end
    for city in player:Cities() do
        if city.ChangeWeLoveTheKingDayCounter then city:ChangeWeLoveTheKingDayCounter(3) end
    end
    for unit in player:Units() do
        if unit:GetUnitType() == I.NumberTen and unit.GetDamage and unit.ChangeDamage then
            unit:ChangeDamage(-unit:GetDamage())
        end
        if isMilitary(unit) and unit.ChangeExperience then unit:ChangeExperience(8) end
    end
end

local function applyChapter(playerID, player, state, index)
    local chapter = chapters[index]
    if chapter.policy and not player:HasPolicy(chapter.policy) then player:SetHasPolicy(chapter.policy, true) end
    state.unlocked[index] = true
    store(playerID, 'Chapter' .. index, 1)
    if index == 2 then grantFreeLaMasia(playerID, player) end
    if index == 6 then chapterSix(playerID, player, state) end
    notify(player, 'TXT_KEY_MESSI_NOTIFICATION_CHAPTER', 'TXT_KEY_MESSI_NOTIFICATION_CHAPTER_SUMMARY',
        L(chapter.title), L(chapter.effects))
    log('chapter ' .. index .. ' unlocked')
end

local function processEpilogue(playerID, player, state)
    if not state.unlocked[6] then return end
    local earned = math.max(0, math.floor((state.legacy - chapters[6].threshold) / 55))
    while state.epilogue < earned do
        state.epilogue = state.epilogue + 1
        store(playerID, 'EpilogueCount', state.epilogue)
        store(playerID, 'EpilogueTurn' .. state.epilogue, gameTurn())
        if player.ChangeGoldenAgeTurns then player:ChangeGoldenAgeTurns(2) end
        local culture = 15 * ((player.GetCurrentEra and player:GetCurrentEra() or 0) + 1)
        if player.ChangeJONSCulture then player:ChangeJONSCulture(culture) end
        if state.tourism < 6 then
            state.tourism = state.tourism + 1
            store(playerID, 'EpilogueTourism', state.tourism)
            local policy = epiloguePolicies[state.tourism]
            if policy and not player:HasPolicy(policy) then player:SetHasPolicy(policy, true) end
        end
        notify(player, 'TXT_KEY_MESSI_NOTIFICATION_EPILOGUE', 'TXT_KEY_MESSI_NOTIFICATION_EPILOGUE_SUMMARY',
            culture, state.tourism)
    end
end

local function checkChapters(playerID)
    local player = Players[playerID]
    if not isMessi(player) then return end
    local state, era = getState(playerID), player:GetCurrentEra()
    for index, chapter in ipairs(chapters) do
        if not state.unlocked[index] and state.legacy >= chapter.threshold
            and (chapter.era < 0 or era >= chapter.era) then applyChapter(playerID, player, state, index) end
    end
    grantFreeLaMasia(playerID, player)
    processEpilogue(playerID, player, state)
    refreshPlayer(playerID, false)
end

local function changeLegacy(playerID, amount, sourceKey)
    local player = Players[playerID]
    amount = math.floor(tonumber(amount) or 0)
    if not isMessi(player) or amount == 0 then return false end
    local state = getState(playerID)
    state.legacy = math.max(0, state.legacy + amount)
    store(playerID, 'Legacy', state.legacy)
    if amount > 0 and sourceKey and sourceKey ~= 'TXT_KEY_MESSI_SOURCE_ASSIST' then
        notify(player, 'TXT_KEY_MESSI_NOTIFICATION_LEGACY', 'TXT_KEY_MESSI_NOTIFICATION_LEGACY_SUMMARY',
            amount, L(sourceKey), state.legacy)
    end
    checkChapters(playerID)
    changed(playerID)
    return true
end

local function activateResilience(playerID, reason)
    local player = Players[playerID]
    if not isMessi(player) then return false end
    local state, turn = getState(playerID), gameTurn()
    if not state.unlocked[4] or turn < state.resilienceNext then return false end
    state.resilienceEnd, state.resilienceNext = turn + 4, turn + 22
    store(playerID, 'ResilienceEnd', state.resilienceEnd)
    store(playerID, 'ResilienceNext', state.resilienceNext)
    store(playerID, 'ResilienceWasActive', 1)
    notify(player, 'TXT_KEY_MESSI_NOTIFICATION_RESILIENCE', 'TXT_KEY_MESSI_NOTIFICATION_RESILIENCE_SUMMARY')
    refreshPlayer(playerID, false)
    log('resilience: ' .. tostring(reason))
    return true
end

local function firstEraReward(playerID, suffix, amount, source)
    local player = Players[playerID]
    if not isMessi(player) then return end
    local era = player:GetCurrentEra()
    local flag = suffix .. 'Era' .. era
    if not truth(load(playerID, flag, 0)) then
        store(playerID, flag, 1)
        changeLegacy(playerID, amount, source)
    end
end

local function onCityFounded(playerID, x, y)
    local player = Players[playerID]
    if not isMessi(player) then return end
    local state = getState(playerID)
    local city = x and y and Map.GetPlot(x, y) and Map.GetPlot(x, y):GetPlotCity() or nil
    if state.unlocked[1] and city and city.ChangeFood then city:ChangeFood(10) end
    refreshPlayer(playerID, false)
end
local function onCityTrained(playerID, cityID, unitID)
    local player = Players[playerID]
    if not isMessi(player) or not getState(playerID).unlocked[1] then return end
    local city, unit = player:GetCityByID(cityID), player:GetUnitByID(unitID)
    if not city or not city:IsCapital() or not unit then return end
    local row = GameInfo.Units[unit:GetUnitType()]
    if not isMilitary(unit) or (row and row.Class == 'UNITCLASS_SCOUT') then setPromotion(unit, I.CapitalVision, true) end
end
local function onCityConstructed(playerID, cityID, buildingID)
    local player = Players[playerID]
    if not isMessi(player) then return end
    if worldWonders[buildingID] then changeLegacy(playerID, 4, 'TXT_KEY_MESSI_SOURCE_WONDER') end
    refreshPlayer(playerID, false)
end
local function isGreatPerson(unit)
    local row = unit and GameInfo.Units[unit:GetUnitType()]
    return row and (row.Special == 'SPECIALUNIT_PEOPLE' or (row.Class and string.find(row.Class, 'GREAT_') ~= nil)) or false
end
local function onUnitCreated(playerID, unitID)
    local player = Players[playerID]
    if not isMessi(player) then return end
    local unit = player:GetUnitByID(unitID)
    if not unit or not isGreatPerson(unit) then return end
    changeLegacy(playerID, 2, 'TXT_KEY_MESSI_SOURCE_GREAT_PERSON')
    local plot = unit:GetPlot()
    local city = plot and plot.GetPlotCity and plot:GetPlotCity() or nil
    if city and hasBuilding(city, I.LaMasia) then
        changeLegacy(playerID, 1, 'TXT_KEY_MESSI_SOURCE_LA_MASIA')
        if city.ChangeWeLoveTheKingDayCounter then city:ChangeWeLoveTheKingDayCounter(1) end
        store(playerID, cityKey(city, 'TalentProductionUntil'), gameTurn() + 6)
        setBuilding(city, I.TalentProduction, 1)
    end
end

local function onPlayerGoldenAge(playerID, started)
    local player = Players[playerID]
    if not isMessi(player) then return end
    local state = getState(playerID)
    local active = truth(started)
    if active then firstEraReward(playerID, 'Golden', 3, 'TXT_KEY_MESSI_SOURCE_GOLDEN_AGE')
    elseif state.golden then activateResilience(playerID, 'Golden Age ended') end
    state.golden = active
    store(playerID, 'GoldenState', active and 1 or 0)
end
local function recordAllianceEvent(playerID, minorID, isAlly)
    local ids = {}
    for value in string.gmatch(tostring(load(playerID, 'AllyList', '')), '[^,]+') do
        local id = tonumber(value)
        if id then ids[id] = true end
    end
    if truth(isAlly) then ids[minorID] = true else ids[minorID] = nil end
    local ordered = {}
    for id in pairs(ids) do ordered[#ordered + 1] = id end
    table.sort(ordered)
    for index, id in ipairs(ordered) do ordered[index] = tostring(id) end
    store(playerID, 'AllyList', table.concat(ordered, ','))
end
local function onMinorAlliesChanged(minorID, majorID, isAlly, oldFriendship, newFriendship)
    if not isMessi(majorID) then return end
    if truth(isAlly) then
        firstEraReward(majorID, 'Alliance', 3, 'TXT_KEY_MESSI_SOURCE_ALLIANCE')
    else
        activateResilience(majorID, 'City-State ally lost')
    end
    recordAllianceEvent(majorID, minorID, isAlly)
    refreshPlayer(majorID, false)
end

local function questSnapshot(playerID, award)
    local state = getState(playerID)
    if not state.unlocked[5] then return end
    local totalTypes = MinorCivQuestTypes and MinorCivQuestTypes.NUM_MINOR_CIV_QUEST_TYPES
        or (GameDefines and GameDefines.NUM_MINOR_CIV_QUEST_TYPES) or 0
    for minorID = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do
        local minor = Players[minorID]
        if minor and minor:IsAlive() and minor:IsMinorCiv() then
            local count = 0
            if minor.GetMinorCivNumDisplayedQuestsForPlayer then
                count = minor:GetMinorCivNumDisplayedQuestsForPlayer(playerID) or 0
            elseif minor.IsMinorCivDisplayedQuestForPlayer then
                for quest = 0, totalTypes - 1 do
                    if minor:IsMinorCivDisplayedQuestForPlayer(playerID, quest) then count = count + 1 end
                end
            end
            local influence = minor.GetMinorCivFriendshipWithMajor
                and minor:GetMinorCivFriendshipWithMajor(playerID) or 0
            local prefix = 'Quest|' .. minorID .. '|'
            local previousCount = tonumber(load(playerID, prefix .. 'Count', count)) or count
            local previousInfluence = tonumber(load(playerID, prefix .. 'Influence', influence)) or influence
            if award and count < previousCount and influence > previousInfluence then
                local era = Players[playerID]:GetCurrentEra()
                local usedKey = 'QuestLegacyEra' .. era
                local used = tonumber(load(playerID, usedKey, 0)) or 0
                local grants = math.min(previousCount - count, 2 - used)
                for _ = 1, math.max(0, grants) do
                    changeLegacy(playerID, 1, 'TXT_KEY_MESSI_SOURCE_QUEST')
                    used = used + 1
                end
                store(playerID, usedKey, used)
            end
            store(playerID, prefix .. 'Count', count)
            store(playerID, prefix .. 'Influence', influence)
        end
    end
end

local function checkAllianceFallback(playerID)
    local player = Players[playerID]
    local count, list = alliedCityStates(playerID)
    local old = tostring(load(playerID, 'AllyList', list))
    if list ~= old then
        local current, previous = {}, {}
        for id in string.gmatch(list, '[^,]+') do current[id] = true end
        for id in string.gmatch(old, '[^,]+') do previous[id] = true end
        local gained, lost = false, false
        for id in pairs(current) do if not previous[id] then gained = true end end
        for id in pairs(previous) do if not current[id] then lost = true end end
        if gained then firstEraReward(playerID, 'Alliance', 3, 'TXT_KEY_MESSI_SOURCE_ALLIANCE') end
        if lost then activateResilience(playerID, 'City-State ally lost') end
    end
    store(playerID, 'AllyList', list)
    return count
end

local function resetAssists(playerID, state)
    local turn = gameTurn()
    if state.assistTurn ~= turn then
        state.assistTurn, state.assists = turn, 0
        store(playerID, 'AssistTurn', turn)
        store(playerID, 'AssistCount', 0)
    end
end
local function onPlayerDoTurn(playerID)
    local player = Players[playerID]
    if not isMessi(player) then return end
    local state = getState(playerID)
    resetAssists(playerID, state)
    local wasActive = truth(load(playerID, 'ResilienceWasActive', 0))
    if wasActive and not resilienceActive(state) then
        store(playerID, 'ResilienceWasActive', 0)
        notify(player, 'TXT_KEY_MESSI_NOTIFICATION_RESILIENCE_END', 'TXT_KEY_MESSI_NOTIFICATION_RESILIENCE_END_SUMMARY')
    end
    local golden = isGoldenAge(player)
    if golden and not state.golden then firstEraReward(playerID, 'Golden', 3, 'TXT_KEY_MESSI_SOURCE_GOLDEN_AGE') end
    if not golden and state.golden then activateResilience(playerID, 'Golden Age ended') end
    state.golden = golden
    store(playerID, 'GoldenState', golden and 1 or 0)
    checkAllianceFallback(playerID)
    questSnapshot(playerID, truth(load(playerID, 'QuestInitialized', 0)))
    store(playerID, 'QuestInitialized', 1)
    checkChapters(playerID)
    refreshPlayer(playerID, true)
end

local function onTeamTechResearched(teamID, techID)
    if techID ~= I.Theology then return end
    for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local player = Players[playerID]
        if isMessi(player) and player:GetTeam() == teamID then grantFreeLaMasia(playerID, player) end
    end
end

local function onBattleStarted(battleType, x, y)
    battles[#battles + 1] = {battleType=battleType,x=x,y=y,members={}}
end
local function onBattleJoined(playerID, objectID, role, isCity)
    local battle = battles[#battles]
    if battle then battle.members[role] = {playerID=playerID,id=objectID,isCity=truth(isCity)} end
end
local function onBattleFinished() table.remove(battles) end
local function battleKiller(victimPlayerID, victimUnitID, killerPlayerID)
    local battle = battles[#battles]
    if not battle then return nil end
    local victimRole = nil
    for role, member in pairs(battle.members) do
        if not member.isCity and member.playerID == victimPlayerID and member.id == victimUnitID then victimRole = role end
    end
    if victimRole == nil then return nil end
    local roles = victimRole == 0 and {1,2} or {0,2}
    for _, role in ipairs(roles) do
        local member = battle.members[role]
        if member and not member.isCity and member.playerID == killerPlayerID then
            local player = Players[killerPlayerID]
            return player and player:GetUnitByID(member.id) or nil
        end
    end
    return nil
end
local function hasAssistingUnit(plot, killer)
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local candidate = adjacent(plot, direction)
        if candidate then
            for index = 0, candidate:GetNumUnits() - 1 do
                local unit = candidate:GetUnit(index)
                if unit and unit:GetOwner() == killer:GetOwner() and isMilitary(unit)
                    and unit:GetID() ~= killer:GetID() then return true end
            end
        end
    end
    return false
end
local function grantAssist(playerID, killer, victim)
    local state = getState(playerID)
    resetAssists(playerID, state)
    if state.assists >= 2 then return end
    local row = GameInfo.Units[victim:GetUnitType()]
    local strength = row and math.max(row.Combat or 0, row.RangedCombat or 0) or 0
    local reward = math.max(2, math.min(12, math.floor(strength * 0.15 + 0.5)))
    if state.unlocked[3] then reward = math.max(2, math.min(12, math.floor(reward * 1.15 + 0.5))) end
    local player = Players[playerID]
    if player.ChangeJONSCulture then player:ChangeJONSCulture(reward) end
    if player.ChangeGoldenAgeProgressMeter then player:ChangeGoldenAgeProgressMeter(reward)
    elseif player.ChangeGoldenAgeProgress then player:ChangeGoldenAgeProgress(reward) end
    changeLegacy(playerID, 1, 'TXT_KEY_MESSI_SOURCE_ASSIST')
    state.assists = state.assists + 1
    store(playerID, 'AssistCount', state.assists)
    if killer:IsHasPromotion(I.Vision) and killer.ChangeDamage then killer:ChangeDamage(-5) end
end
local function onUnitPrekill(victimPlayerID, victimUnitID, unitType, x, y, delay, killerPlayerID)
    local victimPlayer = Players[victimPlayerID]
    local victim = victimPlayer and victimPlayer:GetUnitByID(victimUnitID) or nil
    if isMessi(victimPlayer) and victim and isMilitary(victim)
        and killerPlayerID ~= nil and killerPlayerID >= 0 and killerPlayerID ~= victimPlayerID then
        activateResilience(victimPlayerID, 'military unit killed')
    end
    if killerPlayerID == nil or killerPlayerID < 0 or killerPlayerID == victimPlayerID or not isMessi(killerPlayerID) or not victim then return end
    local killer = battleKiller(victimPlayerID, victimUnitID, killerPlayerID)
    if killer and isMilitary(killer) and hasAssistingUnit(victim:GetPlot(), killer) then
        grantAssist(killerPlayerID, killer, victim)
    end
end

local function onUnitConverted(oldPlayerID, newPlayerID, oldUnitID, newUnitID, isUpgrade)
    local player = Players[newPlayerID]
    local unit = player and player:GetUnitByID(newUnitID) or nil
    if isMessi(player) then
        refreshUnit(unit, getState(newPlayerID), false)
    elseif unit and isMessi(oldPlayerID) then
        setPromotion(unit, I.OneTwo, false)
        setPromotion(unit, I.OneTwoChapter3, false)
        setPromotion(unit, I.Vision, false)
        setPromotion(unit, I.Resilience, false)
    end
    return true
end
local function onUnitUpgraded(playerID, _, newUnitID)
    local player = Players[playerID]
    if isMessi(player) then refreshUnit(player:GetUnitByID(newUnitID), getState(playerID), false) end
    return true
end
local function onCityChanged(playerID) if isMessi(playerID) then refreshPlayer(playerID, false) end end

local function uiState(playerID)
    local player = Players[playerID]
    if not isMessi(player) then return nil end
    local state = getState(playerID)
    local nextIndex = nil
    for index = 1, 6 do if not state.unlocked[index] then nextIndex = index; break end end
    return {legacy=state.legacy,unlocked=state.unlocked,nextIndex=nextIndex,
        nextChapter=nextIndex and chapters[nextIndex] or nil,epilogue=state.epilogue,tourism=state.tourism,
        resilienceTurns=math.max(0,state.resilienceEnd-gameTurn())}
end

M.IsMessi = isMessi
M.GetState = getState
M.GetUIState = uiState
M.GetChapter = function(index) return chapters[index] end
M.ChangeMessiLegacy = changeLegacy
M.CheckChapters = checkChapters
M.RefreshPlayer = refreshPlayer
M.ActivateResilience = activateResilience
M.OnPlayerDoTurn = onPlayerDoTurn
M.OnUnitCreated = onUnitCreated
M.OnCityFounded = onCityFounded
M.OnCityTrained = onCityTrained
M.OnCityConstructed = onCityConstructed
M.OnUnitPrekill = onUnitPrekill
M.OnMinorAlliesChanged = onMinorAlliesChanged
M.OnBattleStarted = onBattleStarted
M.OnBattleJoined = onBattleJoined
M.OnBattleFinished = onBattleFinished

GameEvents.PlayerDoTurn.Add(onPlayerDoTurn)
GameEvents.PlayerCityFounded.Add(onCityFounded)
GameEvents.CityTrained.Add(onCityTrained)
if GameEvents.CityConstructed then GameEvents.CityConstructed.Add(onCityConstructed) end
if GameEvents.CityCaptureComplete then GameEvents.CityCaptureComplete.Add(function(_, oldOwner, x, y, newOwner)
    if oldOwner and isMessi(oldOwner) then refreshPlayer(oldOwner, false) end
    if newOwner and isMessi(newOwner) then refreshPlayer(newOwner, false) end
end) end
if GameEvents.UnitCreated then GameEvents.UnitCreated.Add(onUnitCreated) end
if GameEvents.UnitPrekill then GameEvents.UnitPrekill.Add(onUnitPrekill) end
if GameEvents.UnitConverted then GameEvents.UnitConverted.Add(onUnitConverted) end
if GameEvents.UnitUpgraded then GameEvents.UnitUpgraded.Add(onUnitUpgraded) end
if GameEvents.TeamTechResearched then GameEvents.TeamTechResearched.Add(onTeamTechResearched) end
if GameEvents.PlayerGoldenAge then GameEvents.PlayerGoldenAge.Add(onPlayerGoldenAge) end
if GameEvents.MinorAlliesChanged then GameEvents.MinorAlliesChanged.Add(onMinorAlliesChanged) end
if GameEvents.BattleStarted then GameEvents.BattleStarted.Add(onBattleStarted) end
if GameEvents.BattleJoined then GameEvents.BattleJoined.Add(onBattleJoined) end
if GameEvents.BattleFinished then GameEvents.BattleFinished.Add(onBattleFinished) end

for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
    if isMessi(playerID) then
        local player, state = Players[playerID], getState(playerID)
        for index, chapter in ipairs(chapters) do
            if state.unlocked[index] and chapter.policy and not player:HasPolicy(chapter.policy) then
                player:SetHasPolicy(chapter.policy, true)
            end
        end
        for index = 1, math.min(6, state.tourism) do
            if epiloguePolicies[index] and not player:HasPolicy(epiloguePolicies[index]) then
                player:SetHasPolicy(epiloguePolicies[index], true)
            end
        end
        state.golden = isGoldenAge(player)
        store(playerID, 'GoldenState', state.golden and 1 or 0)
        local _, allies = alliedCityStates(playerID)
        if load(playerID, 'AllyList', nil) == nil then store(playerID, 'AllyList', allies) end
        questSnapshot(playerID, false)
        store(playerID, 'QuestInitialized', 1)
        checkChapters(playerID)
        refreshPlayer(playerID, true)
    end
end

M.RuntimeLoaded = true
print('The Eternal Number Ten: runtime loaded')
