-- Terra: all yield/promotion changes run on gameplay hooks, never UI callbacks.
MapModData.TerraFramework = MapModData.TerraFramework or {}
local T = MapModData.TerraFramework
if T.Loaded then return end
T.Loaded = true
local CIV = GameInfoTypes.CIVILIZATION_GPT_TERRA
local OPERATIVE = GameInfoTypes.UNIT_TERRA_ADAPTIVE_OPERATIVE
local HUB = GameInfoTypes.BUILDING_TERRA_MULTIMODAL_HUB
local TRADE = GameInfoTypes.BUILDING_TERRA_TRADE_PRODUCTION
local MARKER = GameInfoTypes.PROMOTION_TERRA_RECONFIGURATION
local modes = {"RESEARCH", "COMMERCE", "CREATIVE", "EXECUTION"}
local configs = {"RECOVERY", "ROUGH", "OPEN"}
local modeBuildings, promotions, categories = {}, {}, {}
for _, mode in ipairs(modes) do modeBuildings[mode] = GameInfoTypes["BUILDING_TERRA_MODE_" .. mode] end
for _, config in ipairs(configs) do promotions[config] = GameInfoTypes["PROMOTION_TERRA_CONFIG_" .. config] end
for row in GameInfo.TerraBuildingModes() do categories[row.BuildingClassType] = row.ModeType end
local save = Modding.OpenSaveData()
local function truth(v) return v == true or v == 1 end
local function isTerra(p) return p and p:IsAlive() and p:GetCivilizationType() == CIV end
local function setBuilding(city, id, count)
    if city:GetNumRealBuilding(id) ~= count then city:SetNumRealBuilding(id, count) end
end
-- Plot + founding turn + original owner identify a city independently of reused IDs.
-- Capture also invalidates the plot record, including Terra -> Terra transfers.
local function key(city) return "TERRA_V1_CITY_" .. city:GetX() .. "_" .. city:GetY() end
local function identity(city)
    return city:GetOwner() .. ":" .. city:GetOriginalOwner() .. ":" .. city:GetGameTurnFounded()
end
local function readMode(city)
    local raw = save.GetValue(key(city))
    if type(raw) ~= "string" then return nil end
    local owner, original, founded, mode, expiry = raw:match("^(%-?%d+):(%-?%d+):(%-?%d+):(%u+):(%d+)$")
    if not owner or owner .. ":" .. original .. ":" .. founded ~= identity(city) or not modeBuildings[mode] then return nil end
    return mode, tonumber(expiry)
end
local function applyMode(city, mode)
    for _, candidate in ipairs(modes) do setBuilding(city, modeBuildings[candidate], candidate == mode and 1 or 0) end
end
local function clearMode(city)
    save.SetValue(key(city), "")
    applyMode(city, nil)
end
local function syncCity(city, expire)
    local mode, expiry = readMode(city)
    if not isTerra(Players[city:GetOwner()]) or not mode or (expire and Game.GetGameTurn() >= expiry) then
        clearMode(city)
    else
        applyMode(city, mode)
    end
end
local function refreshTrade(playerID)
    local p = Players[playerID]
    if not p or not p:IsAlive() then return end
    local counts = {}
    -- FromCity is the origin city object supplied by CP's Player:GetTradeRoutes().
    -- Both domestic and international routes are included; destination never gets this bonus.
    if isTerra(p) then
        for _, route in ipairs(p:GetTradeRoutes()) do
            local city = route.FromCity
            if city and city:GetOwner() == playerID then
                counts[city:GetID()] = (counts[city:GetID()] or 0) + 1
            end
        end
    end
    for city in p:Cities() do
        local count = isTerra(p) and city:GetNumBuilding(HUB) > 0 and (counts[city:GetID()] or 0) or 0
        setBuilding(city, TRADE, count)
    end
end
local function refreshAllTrade()
    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do refreshTrade(playerID) end
end
local function constructed(playerID, cityID, buildingID, gold, faith)
    local p = Players[playerID]
    if not isTerra(p) then return end
    local city = p:GetCityByID(cityID)
    if not city then return end
    if buildingID == HUB then refreshTrade(playerID) end
    -- CP CityConstructed is fired by completed production and purchase, not SetNumRealBuilding.
    -- Require explicit production flags; fail closed if a foreign hook omits them.
    if gold == nil or faith == nil or truth(gold) or truth(faith) then return end
    local building = GameInfo.Buildings[buildingID]
    local class = building and GameInfo.BuildingClasses[building.BuildingClass]
    local mode = class and categories[building.BuildingClass]
    if not mode or (class.MaxGlobalInstances or -1) >= 0 or (class.MaxTeamInstances or -1) >= 0 or (class.MaxPlayerInstances or -1) >= 0 then return end
    local expiry = Game.GetGameTurn() + 10
    save.SetValue(key(city), identity(city) .. ":" .. mode .. ":" .. expiry)
    applyMode(city, mode)
    if p:IsHuman() then
        p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
            Locale.ConvertTextKey("TXT_KEY_TERRA_MODE_NOTIFICATION", city:GetName(), Locale.ConvertTextKey("TXT_KEY_TERRA_MODE_" .. mode)),
            Locale.ConvertTextKey("TXT_KEY_TRAIT_TERRA_SHORT"), city:GetX(), city:GetY())
    end
end
local function clearConfigs(unit)
    for _, config in ipairs(configs) do unit:SetHasPromotion(promotions[config], false) end
end
local function configure(p, unit)
    clearConfigs(unit)
    if not isTerra(p) or unit:GetUnitType() ~= OPERATIVE then
        unit:SetHasPromotion(MARKER, false)
        return
    end
    unit:SetHasPromotion(MARKER, true)
    local plot = unit:GetPlot()
    if unit:IsEmbarked() or not plot or plot:IsWater() then return end
    local owner = Players[plot:GetOwner()]
    local config
    if owner and owner:GetTeam() == p:GetTeam() then config = "RECOVERY"
    elseif plot:IsRoughGround() then config = "ROUGH"
    else config = "OPEN" end
    unit:SetHasPromotion(promotions[config], true)
end
local function turn(playerID)
    local p = Players[playerID]
    if not p or not p:IsAlive() then return end
    for city in p:Cities() do syncCity(city, true) end
    refreshTrade(playerID)
    for unit in p:Units() do
        if unit:GetUnitType() == OPERATIVE or unit:IsHasPromotion(MARKER) then configure(p, unit) end
    end
end
local function capture(oldOwner, capital, x, y, newOwner)
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city then clearMode(city); setBuilding(city, TRADE, 0) end
    refreshAllTrade()
end
local function founded(playerID, x, y)
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city then clearMode(city) end
end
local function moved(playerID, unitID)
    local p = Players[playerID]
    local unit = p and p:GetUnitByID(unitID)
    -- Embarkation clears configs but disembarkation never chooses a new one mid-turn.
    if unit and unit:IsHasPromotion(MARKER) and unit:IsEmbarked() then clearConfigs(unit) end
    -- Trade visuals moving and the source caravan being consumed are gameplay hooks.
    -- Idempotent snapshots also cover route creation/removal without a UI dependency.
    if unit and unit:IsTrade() then refreshTrade(playerID) end
end
local function upgraded(playerID, oldID, newID)
    local p = Players[playerID]
    local unit = p and p:GetUnitByID(newID)
    if unit and unit:GetUnitType() ~= OPERATIVE then clearConfigs(unit); unit:SetHasPromotion(MARKER, false) end
end
local function initialize()
    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local p = Players[playerID]
        if p and p:IsAlive() then
            -- Never recalculate unit configurations on load: their promotions are saved by the game.
            -- Expiry is processed on player turn, not while loading during another player's turn.
            for city in p:Cities() do syncCity(city, false) end
        end
    end
    refreshAllTrade()
end
T.GetMode = readMode
T.Constructed, T.Turn, T.Capture, T.Founded = constructed, turn, capture, founded
T.RefreshTrade, T.Moved, T.Upgraded, T.Initialize = refreshTrade, moved, upgraded, initialize
GameEvents.CityConstructed.Add(constructed)
GameEvents.PlayerDoTurn.Add(turn)
GameEvents.PlayerDoneTurn.Add(refreshAllTrade)
GameEvents.CityCaptureComplete.Add(capture)
GameEvents.PlayerCityFounded.Add(founded)
GameEvents.UnitSetXY.Add(moved)
GameEvents.UnitUpgraded.Add(upgraded)
GameEvents.UnitPrekill.Add(refreshAllTrade)
GameEvents.PlayerTradeRouteCompleted.Add(refreshAllTrade)
GameEvents.PlayerPlunderedTradeRoute.Add(refreshAllTrade)
initialize()
