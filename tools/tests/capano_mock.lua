MapModData = {}
persisted = {}
Modding = {OpenSaveData=function()
    return {GetValue=function(_, key) return persisted[key] end,
        SetValue=function(_, key, value) persisted[key] = value end}
end}

Game = {turn=20, active=0, GetGameTurn=function() return Game.turn end,
    GetActivePlayer=function() return Game.active end, Rand=function() return 99 end}
GameDefines = {MAX_CIV_PLAYERS=3, MAX_MAJOR_CIVS=3, MOVE_DENOMINATOR=60}
DomainTypes = {DOMAIN_LAND=0}
DirectionTypes = {NUM_DIRECTION_TYPES=6}
NotificationTypes = {NOTIFICATION_GENERIC=1}
Locale = {ConvertTextKey=function(key, ...) return key end}
Events = {GameplayAlertMessage=function() end, AddPopupTextEvent=function() end}

GameEvents = setmetatable({}, {__index=function(table, key)
    local event = {handlers={}}
    event.Add = function(handler) event.handlers[#event.handlers + 1] = handler end
    rawset(table, key, event)
    return event
end})

GameInfoTypes = {
    CIVILIZATION_CAPANO_CIRCUIT=1,
    UNIT_CAPANO_ROUTE_SETTER=2,
    BUILDING_CAPANO_COMPETITION_CENTRE=3,
    IMPROVEMENT_CAPANO_BOULDER_SECTOR=4,
    BUILD_CAPANO_BOULDER_SECTOR=5,
    TECH_ARCHITECTURE=6, TECH_PLASTICS=7,
    PROMOTION_CAPANO_ROUTE_SETTER=10,
    PROMOTION_CAPANO_SETTER_HILLS_WORK=11,
    PROMOTION_CAPANO_BETA_1=12, PROMOTION_CAPANO_BETA_2=13,
    PROMOTION_CAPANO_BETA_3=14, PROMOTION_CAPANO_BETA_4=15,
    PROMOTION_CAPANO_BETA_ATTACK_5=16, PROMOTION_CAPANO_BETA_ATTACK_10=17,
    PROMOTION_CAPANO_BETA_ATTACK_15=18, PROMOTION_CAPANO_BETA_ATTACK_20=19,
    PROMOTION_CAPANO_AWKWARD_BLUE=20, PROMOTION_CAPANO_AWKWARD_PURPLE=21,
    PROMOTION_CAPANO_READ_SEQUENCE=22,
    PROMOTION_CAPANO_COMPETITION_MOVEMENT=23,
    PROMOTION_CAPANO_COMPETITION_ACTIVE=24,
    PROMOTION_CAPANO_FOOTWORK=25,
    PROMOTION_CAPANO_BODY_POSITION=26, PROMOTION_CAPANO_BODY_ACTIVE=27,
    PROMOTION_CAPANO_COORDINATION=28,
    PROMOTION_CAPANO_COMMIT=29, PROMOTION_CAPANO_COMMIT_ACTIVE=30,
    PROMOTION_CAPANO_COMPLETE_CLIMBER=31,
    PROMOTION_CAPANO_COMPLETE_HILLS=32,
    PROMOTION_CAPANO_YELLOW_CIRCUIT=33,
    DIPLOMODIFIER_CAPANO_RESPECT_SEND=40,
    DIPLOMODIFIER_CAPANO_ABANDONED_PROJECT=41,
    DIPLOMODIFIER_CAPANO_STRONG_CLIMBERS=42
}

GameInfo = {Units={}}
GameInfo.Units[2] = {Suicide=0, NukeDamageLevel=-1}
GameInfo.Units[100] = {Suicide=0, NukeDamageLevel=-1}

local function iterator(values)
    local key = nil
    return function()
        key = next(values, key)
        return key and values[key]
    end
end

function NewTeam(id)
    local team = {id=id, tech={}, wars={}}
    function team:IsHasTech(tech) return self.tech[tech] or false end
    function team:IsAtWar(other) return self.wars[other] or false end
    return team
end

Teams = {[0]=NewTeam(0), [1]=NewTeam(1), [2]=NewTeam(2)}
Teams[0].wars[1] = true
Teams[1].wars[0] = true

function NewPlot(x, y)
    local plot = {x=x, y=y, owner=-1, improvement=-1, hills=false, mountain=false,
        water=false, city=nil, terrain=0, pillaged=false, visible=true}
    function plot:GetX() return self.x end
    function plot:GetY() return self.y end
    function plot:GetOwner() return self.owner end
    function plot:GetImprovementType() return self.improvement end
    function plot:IsImprovementPillaged() return self.pillaged end
    function plot:IsHills() return self.hills end
    function plot:IsMountain() return self.mountain end
    function plot:IsWater() return self.water end
    function plot:IsCity() return self.city ~= nil end
    function plot:GetPlotCity() return self.city end
    function plot:GetTerrainType() return self.terrain end
    function plot:GetPlotIndex() return self.x * 100 + self.y end
    function plot:IsVisible() return self.visible end
    return plot
end

plots = {}
function PutPlot(plot) plots[plot.x .. ':' .. plot.y] = plot; return plot end
for x = 0, 8 do
    for y = 0, 3 do PutPlot(NewPlot(x, y)) end
end
local directions = {{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
Map = {
    GetPlot=function(x, y) return plots[x .. ':' .. y] end,
    PlotDirection=function(x, y, direction)
        local offset = directions[direction + 1]
        return offset and Map.GetPlot(x + offset[1], y + offset[2]) or nil
    end,
    PlotDistance=function(x1, y1, x2, y2)
        return math.max(math.abs(x1 - x2), math.abs(y1 - y2))
    end
}

function NewPlayer(id, civilization, team)
    local player = {id=id, civilization=civilization, team=team, era=2,
        units={}, cities={}, science=0, culture=0, golden=0}
    function player:IsAlive() return true end
    function player:IsHuman() return self.id == 0 end
    function player:IsMinorCiv() return false end
    function player:IsBarbarian() return false end
    function player:GetCivilizationType() return self.civilization end
    function player:GetTeam() return self.team end
    function player:GetCurrentEra() return self.era end
    function player:Units() return iterator(self.units) end
    function player:GetUnitByID(id) return self.units[id] end
    function player:GetCityByID(id) return self.cities[id] end
    function player:ChangeOverflowResearch(amount) self.science = self.science + amount end
    function player:ChangeJONSCulture(amount) self.culture = self.culture + amount end
    function player:GetGoldenAgeLength() return 8 end
    function player:ChangeGoldenAgeTurns(amount) self.golden = self.golden + amount end
    return player
end

Players = {[0]=NewPlayer(0, 1, 0), [1]=NewPlayer(1, 99, 1), [2]=NewPlayer(2, 99, 2)}

function NewUnit(owner, id, unitType, plot)
    local unit = {owner=owner, id=id, kind=unitType, plot=plot, promotions={}, script='',
        moves=180, maxMoves=180, damage=30, experience=0, base=10, strength=1000,
        defense=1000, ranged=false, build=-1, level=1}
    function unit:GetOwner() return self.owner end
    function unit:GetID() return self.id end
    function unit:GetUnitType() return self.kind end
    function unit:GetX() return self.plot.x end
    function unit:GetY() return self.plot.y end
    function unit:GetPlot() return self.plot end
    function unit:SetPlot(plot) self.plot = plot end
    function unit:GetDomainType() return DomainTypes.DOMAIN_LAND end
    function unit:IsCombatUnit() return true end
    function unit:IsCanAttackRanged() return self.ranged end
    function unit:IsEmbarked() return false end
    function unit:GetBaseCombatStrength() return self.base end
    function unit:GetBaseRangedCombatStrength() return 0 end
    function unit:GetMaxAttackStrength() return self.strength end
    function unit:GetMaxRangedCombatStrength() return self.strength end
    function unit:GetMaxDefenseStrength() return self.defense end
    function unit:GetMeleeAttackFromPlot() return self.plot end
    function unit:IgnoreBuildingDefense() return false end
    function unit:GetScriptData() return self.script end
    function unit:SetScriptData(value) self.script = value end
    function unit:IsHasPromotion(id) return self.promotions[id] or false end
    function unit:SetHasPromotion(id, value) self.promotions[id] = value end
    function unit:GetCurrHitPoints() return 100 - self.damage end
    function unit:ChangeDamage(amount) self.damage = math.max(0, self.damage + amount) end
    function unit:ChangeExperience(amount) self.experience = self.experience + amount end
    function unit:GetExperience() return self.experience end
    function unit:GetLevel() return self.level end
    function unit:GetMoves() return self.moves end
    function unit:SetMoves(value) self.moves = value end
    function unit:MaxMoves() return self.maxMoves end
    function unit:GetBuildType() return self.build end
    function unit:GetName() return 'Test Climber' end
    return unit
end

function NewCity(owner, id, plot)
    local city = {owner=owner, id=id, plot=plot, buildings={}, damage=0}
    plot.city = city
    function city:GetOwner() return self.owner end
    function city:GetID() return self.id end
    function city:GetX() return self.plot.x end
    function city:GetY() return self.plot.y end
    function city:Plot() return self.plot end
    function city:GetStrengthValue() return 1800 end
    function city:GetDamage() return self.damage end
    function city:GetMaxHitPoints() return 200 end
    function city:GetNumRealBuilding(id) return self.buildings[id] or 0 end
    return city
end

attacker = NewUnit(0, 1, 100, Map.GetPlot(1, 1))
defender = NewUnit(1, 2, 100, Map.GetPlot(2, 1))
defender.defense = 1500
Players[0].units[1] = attacker
Players[1].units[2] = defender

setter = NewUnit(0, 3, 2, Map.GetPlot(4, 1))
Players[0].units[3] = setter
enemyMover = NewUnit(1, 4, 100, Map.GetPlot(5, 1))
Players[1].units[4] = enemyMover
