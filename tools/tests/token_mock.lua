Saved={};MapModData={};Turn=0;Network=false
function event()
    local handlers={}
    return {Add=function(f) handlers[#handlers+1]=f end,Fire=function(...) for _,f in ipairs(handlers) do f(...) end end}
end
function resetEvents()
    GameEvents={};Events={LoadScreenClose=event()}
    for _,name in ipairs({'PlayerDoTurn','CityConstructed','PlayerCityFounded','CityCaptureComplete','UnitCreated','UnitConverted','UnitPrekill','SetPopulation','TeamTechResearched'}) do GameEvents[name]=event() end
    LuaEvents={TokenStateChanged=setmetatable({Add=function() end},{__call=function() end})}
end
resetEvents()
GameInfoTypes={CIVILIZATION_TOKEN_INTELLIGENCE=1,BUILDING_TOKEN_CLUSTER=2,BUILDING_TOKEN_CENTRE=3,UNIT_TOKEN_AGENT=4}
for i,n in ipairs({'ANCIENT','CLASSICAL','MEDIEVAL','RENAISSANCE','INDUSTRIAL','MODERN','POSTMODERN','FUTURE'}) do GameInfoTypes['ERA_'..n]=i-1 end
for i,n in ipairs({'SCIENTIST','ENGINEER','MERCHANT','WRITER','ARTIST','MUSICIAN'}) do GameInfoTypes['SPECIALIST_'..n]=10+i end
for i,n in ipairs({'GOLD','GROWTH','RESEARCH','CULTURE','HAPPINESS','ADMIN','GRAND','TRADE'}) do GameInfoTypes['BUILDING_TOKEN_'..n]=20+i end
for i,n in ipairs({'TACTICAL','SIMULATION','GRAND','FORECAST','OFFENSE','DEFENSE','MOBILITY','TARGET'}) do GameInfoTypes['PROMOTION_TOKEN_'..n]=40+i end
Modding={OpenSaveData=function() return {GetValue=function(k) return Saved[k] end,SetValue=function(k,v) Saved[k]=v end} end}
Game={GetGameTurn=function() return Turn end,GetGameSpeedType=function() return 0 end,IsNetworkMultiPlayer=function() return Network end}
GameDefines={MAX_CIV_PLAYERS=3,MOVE_DENOMINATOR=60}
GameInfo={GameSpeeds={[0]={TrainPercent=100}},Buildings={[80]={BuildingClass='WONDER'}},BuildingClasses={WONDER={MaxGlobalInstances=1}}}
NotificationTypes={NOTIFICATION_GENERIC=1}
function iter(t) local k=nil;return function() k=next(t,k);return k and t[k] end end
function newCity(owner,id)
    local c={owner=owner,id=id,pop=10,b={},spec={},production=0,needed=500,process=-1,building=-1,unit=-1,x=id,y=owner,original=owner,founded=0}
    function c:GetOwner() return self.owner end
    function c:GetOriginalOwner() return self.original end
    function c:GetID() return self.id end
    function c:GetGameTurnFounded() return self.founded end
    function c:GetX() return self.x end
    function c:GetY() return self.y end
    function c:GetPopulation() return self.pop end
    function c:GetName() return 'Context '..self.id end
    function c:GetNumBuilding(i) return self.b[i] or 0 end
    c.GetNumRealBuilding=c.GetNumBuilding
    function c:SetNumRealBuilding(i,v) self.b[i]=v end
    function c:GetSpecialistCount(i) return self.spec[i] or 0 end
    function c:GetProductionProcess() return self.process end
    function c:GetProduction() return self.production end
    function c:GetProductionNeeded() return self.needed end
    function c:GetProductionBuilding() return self.building end
    function c:GetProductionUnit() return self.unit end
    function c:ChangeProduction(v) self.production=self.production+v end
    return c
end
function newUnit(owner,id,kind)
    local u={owner=owner,id=id,kind=kind or 4,birth=0,p={},moves=120,combat=true,trade=false,damage=0}
    function u:GetID() return self.id end
    function u:GetOwner() return self.owner end
    function u:GetUnitType() return self.kind end
    function u:GetGameTurnCreated() return self.birth end
    function u:IsCombatUnit() return self.combat end
    function u:IsDead() return self.dead or false end
    function u:IsDelayedDeath() return self.delayed or false end
    function u:IsTrade() return self.trade end
    function u:GetName() return 'Inference Agent' end
    function u:GetX() return 0 end
    function u:GetY() return 0 end
    function u:MaxMoves() return 120 end
    function u:GetDamage() return self.damage end
    function u:ChangeMoves(v) self.moves=self.moves+v end
    function u:IsHasPromotion(i) return self.p[i] or false end
    function u:SetHasPromotion(i,v) self.p[i]=v end
    return u
end
function newPlayer(id,civ)
    local p={id=id,civ=civ or 1,era=0,cities={},units={},routes={},human=true,happy=5,tech=0,notices=0}
    function p:IsAlive() return true end
    function p:GetID() return self.id end
    function p:IsHuman() return self.human end
    function p:GetCivilizationType() return self.civ end
    function p:GetTeam() return self.id end
    function p:GetCurrentEra() return self.era end
    function p:Cities() return iter(self.cities) end
    function p:Units() return iter(self.units) end
    function p:GetCityByID(id) return self.cities[id] end
    function p:GetUnitByID(id) return self.units[id] end
    function p:GetCapitalCity() return self.cities[self.capital or 0] end
    function p:GetTradeRoutes() return self.routes end
    function p:GetCurrentResearch() return self.tech end
    function p:GetExcessHappiness() return self.happy end
    function p:AddNotification(...) self.notices=self.notices+1 end
    return p
end
Players={[0]=newPlayer(0),[1]=newPlayer(1),[2]=newPlayer(2,99)}
Teams={}
for pid=0,2 do
    local tech={cost=1000,progress=0}
    function tech:GetResearchCost(id) return self.cost end
    function tech:GetResearchProgress(id) return self.progress end
    function tech:ChangeResearchProgress(id,n,pid) self.progress=self.progress+n end
    Teams[pid]={techs=tech,war=0,known=false}
    local team=Teams[pid]
    function team:GetTeamTechs() return self.techs end
    function team:IsHasTech(id) return self.known end
    function team:GetAtWarCount() return self.war end
end
for pid=0,2 do Players[pid].cities[0]=newCity(pid,0);Players[pid].units[0]=newUnit(pid,0) end
Map={GetPlot=function(x,y)
    for _,p in pairs(Players) do for _,c in pairs(p.cities) do if c.x==x and c.y==y then return {GetPlotCity=function() return c end} end end end
end}
function bank(pid,value) Saved['TOKEN_V1_P'..pid..'_tokens']=value end
function nextTurn(pid) Turn=Turn+1;GameEvents.PlayerDoTurn.Fire(pid) end
function reload()
    _G.__TOKEN_RUNTIME_CONTEXT_LOADED=nil
    -- Simulate a fresh context while retaining stale shared MapModData.
    resetEvents();assert(loadstring(RuntimeSource))()
end
