MapModData={}; persisted={}
Modding={OpenSaveData=function() return {GetValue=function(k) return persisted[k] end,SetValue=function(k,v) persisted[k]=v end} end}
Game={turn=5,GetGameTurn=function() return Game.turn end};GameDefines={MAX_CIV_PLAYERS=3}
GameEvents=setmetatable({},{__index=function(t,k) local v={handlers={},Add=function(f) end};rawset(t,k,v);return v end})
NotificationTypes={NOTIFICATION_GENERIC=1};Locale={ConvertTextKey=function(s,...) return s end}
GameInfoTypes={CIVILIZATION_GPT_TERRA=1,UNIT_TERRA_ADAPTIVE_OPERATIVE=2,BUILDING_TERRA_MULTIMODAL_HUB=3,BUILDING_TERRA_TRADE_PRODUCTION=4,PROMOTION_TERRA_RECONFIGURATION=5,
BUILDING_TERRA_MODE_RESEARCH=10,BUILDING_TERRA_MODE_COMMERCE=11,BUILDING_TERRA_MODE_CREATIVE=12,BUILDING_TERRA_MODE_EXECUTION=13,
PROMOTION_TERRA_CONFIG_RECOVERY=20,PROMOTION_TERRA_CONFIG_ROUGH=21,PROMOTION_TERRA_CONFIG_OPEN=22}
GameInfo={Buildings={[30]={BuildingClass='LIBRARY'},[3]={BuildingClass='MARKET'},[31]={BuildingClass='MONUMENT'},[32]={BuildingClass='WORKSHOP'},[33]={BuildingClass='GRANARY'},[34]={BuildingClass='WONDER'}},BuildingClasses={}}
for _,c in ipairs({'LIBRARY','MARKET','MONUMENT','WORKSHOP','GRANARY','WONDER'}) do GameInfo.BuildingClasses[c]={MaxGlobalInstances=-1,MaxTeamInstances=-1,MaxPlayerInstances=-1} end
GameInfo.BuildingClasses.WONDER.MaxGlobalInstances=1
GameInfo.TerraBuildingModes=function()
    local rows={{BuildingClassType='LIBRARY',ModeType='RESEARCH'},{BuildingClassType='MARKET',ModeType='COMMERCE'},{BuildingClassType='MONUMENT',ModeType='CREATIVE'},{BuildingClassType='WORKSHOP',ModeType='EXECUTION'},{BuildingClassType='WONDER',ModeType='RESEARCH'}}
    local i=0;return function() i=i+1;return rows[i] end
end
function iter(t) local k=nil;return function() k=next(t,k);return k and t[k] end end
function NewCity(id,owner)
    local c={id=id,owner=owner,original=owner,founded=0,b={},x=id,y=1}
    function c:GetID() return self.id end
    function c:GetOwner() return self.owner end
    function c:GetOriginalOwner() return self.original end
    function c:GetGameTurnFounded() return self.founded end
    function c:GetX() return self.x end
    function c:GetY() return self.y end
    function c:GetName() return 'Test City' end
    function c:GetNumRealBuilding(id) return self.b[id] or 0 end
    c.GetNumBuilding=c.GetNumRealBuilding
    function c:SetNumRealBuilding(id,n) self.b[id]=n end
    return c
end
function NewPlayer(civ,team)
    local p={civ=civ,team=team,cities={},units={},routes={},notices=0}
    function p:IsAlive() return true end
    function p:IsHuman() return true end
    function p:GetCivilizationType() return self.civ end
    function p:GetTeam() return self.team end
    function p:Cities() return iter(self.cities) end
    function p:Units() return iter(self.units) end
    function p:GetCityByID(id) return self.cities[id] end
    function p:GetUnitByID(id) return self.units[id] end
    function p:GetTradeRoutes() return self.routes end
    function p:AddNotification(...) self.notices=self.notices+1 end
    return p
end
Players={[0]=NewPlayer(1,0),[1]=NewPlayer(99,0),[2]=NewPlayer(99,2)}
city=NewCity(1,0);other=NewCity(2,0);Players[0].cities={city,other}
plot={owner=-1,rough=false,water=false}
function plot:GetOwner() return self.owner end
function plot:IsRoughGround() return self.rough end
function plot:IsWater() return self.water end
function plot:GetPlotCity() return city end
Map={GetPlot=function() return plot end}
unit={kind=2,p={},embarked=false}
function unit:GetUnitType() return self.kind end
function unit:GetPlot() return plot end
function unit:IsEmbarked() return self.embarked end
function unit:IsHasPromotion(id) return self.p[id] or false end
function unit:SetHasPromotion(id,v) self.p[id]=v end
function unit:IsTrade() return false end
Players[0].units[1]=unit
