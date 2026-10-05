-- Native-order mock: PlayerDoneTurn -> next-turn city production -> PlayerDoTurn.
MapModData, persisted = {}, {}
Modding = {OpenSaveData=function() return {
    GetValue=function(k) return persisted[k] end,
    SetValue=function(k,v) persisted[k]=v end} end}
local function event()
    local e={handlers={}}
    e.Add=function(f) e.handlers[#e.handlers+1]=f end
    e.Fire=function(...) for _,f in ipairs(e.handlers) do f(...) end end
    return e
end
GameEvents,Events={},{}
for _,name in ipairs({'PlayerDoneTurn','PlayerDoTurn','CityConstructed','CityCaptureComplete',
    'PlayerCityFounded','CitySoldBuilding','CityTrained','CityCreated'}) do GameEvents[name]=event() end
for _,name in ipairs({'SpecificCityInfoDirty','SerialEventCityInfoDirty','SerialEventGameDataDirty',
    'SerialEventCityDestroyed','LoadScreenClose'}) do Events[name]=event() end
Game={turn=1,GetGameTurn=function() return Game.turn end,GetActivePlayer=function() return 0 end}
OrderTypes={ORDER_TRAIN=0,ORDER_CONSTRUCT=1,ORDER_CREATE=2,ORDER_MAINTAIN=3}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(s,...) return s..'|'..table.concat({...},'|') end}
GameInfoTypes={CIVILIZATION_GPT_SOL=1,BUILDING_SOL_CONTEXT_ARCHIVE=101,
    BUILDING_SOL_REASONING_INSTITUTE=102,BUILDING_SOL_INSIGHT=200,
    BUILDING_SOL_CONTEXT_CULTURE=201,BUILDING_SOL_REASONING_INSIGHT_SCIENCE=202}
GameInfo={Buildings={},BuildingClasses={
    NORMAL={MaxGlobalInstances=-1,MaxPlayerInstances=-1,MaxTeamInstances=-1},
    WORLD={MaxGlobalInstances=1,MaxPlayerInstances=-1,MaxTeamInstances=-1},
    NATIONAL={MaxGlobalInstances=-1,MaxPlayerInstances=1,MaxTeamInstances=-1},
    TEAM={MaxGlobalInstances=-1,MaxPlayerInstances=-1,MaxTeamInstances=1}}}
for _,row in ipairs({{100,100,'NORMAL'},{101,250,'NORMAL'},{102,400,'NORMAL'},
    {103,500,'WORLD'},{104,200,'NATIONAL'},{105,500,'TEAM'},{106,0,'WORLD'},
    {107,-1,'NORMAL'},{108,1,'NORMAL'},{110,500,'WORLD'},{111,500,'WORLD'},
    {112,500,'WORLD'},{113,500,'WORLD'},{114,500,'WORLD'}}) do
    GameInfo.Buildings[row[1]]={ID=row[1],Cost=row[2],BuildingClass=row[3],Description='BUILDING_'..row[1]}
end
GameInfo.Specialists=function()
    local names={'SCIENTIST','ENGINEER','MERCHANT','WRITER','ARTIST','MUSICIAN','CIVIL_SERVANT','CITIZEN'}
    local i=0
    return function() i=i+1; if names[i] then return {ID=i,Type='SPECIALIST_'..names[i]} end end
end
local function iter(t) local k;return function() k=next(t,k);if k then return t[k] end end end
Players,Teams={},{}
for id=0,2 do
    local p={id=id,civ=id==1 and 2 or 1,alive=true,human=id==0,cities={},tech=0,science=0,notes={}}
    function p:IsAlive() return self.alive end
    function p:IsHuman() return self.human end
    function p:GetCivilizationType() return self.civ end
    function p:GetCityByID(id) return self.cities[id] end
    function p:Cities() return iter(self.cities) end
    function p:GetTeam() return self.id end
    function p:GetCurrentResearch() return self.tech end
    function p:AddNotification(_,text) self.notes[#self.notes+1]=text end
    Players[id]=p
    local tt={}
    function tt:ChangeResearchProgress(tech,amount,playerID)
        assert(Players[playerID].tech==tech and tech>=0)
        Players[playerID].science=Players[playerID].science+amount
        -- Native research completion may dispatch dirty events synchronously.
        Events.SerialEventGameDataDirty.Fire()
    end
    Teams[id]={GetTeamTechs=function() return tt end}
end
function NewCity(id,owner,x)
    local c={id=id,owner=owner,x=x or id,y=1,b={},free={},spec={},order=-1,item=-1,things=0,
             speed=1,resistance=false,razing=false,production=0,overflow=0,modifier=0}
    function c:GetID() return self.id end
    function c:GetOwner() return self.owner end
    function c:GetX() return self.x end
    function c:GetY() return self.y end
    function c:GetName() return 'Sol Test '..self.id end
    function c:GetOrderFromQueue() return self.order,self.item,-1,false,false end
    function c:GetNumThingsProduced() return self.things end
    function c:GetNumRealBuilding(id) return self.b[id] or 0 end
    function c:GetNumBuilding(id) return (self.b[id] or 0)+(self.free[id] or 0) end
    function c:SetNumRealBuilding(id,n)
        assert(n>=0 and n==math.floor(n));self.b[id]=n
        Events.SerialEventCityInfoDirty.Fire()
    end
    function c:GetSpecialistCount(id) return self.spec[id] or 0 end
    function c:GetBuildingProductionNeeded(id) return math.floor(GameInfo.Buildings[id].Cost*self.speed) end
    function c:IsResistance() return self.resistance end
    function c:IsRazing() return self.razing end
    Players[owner].cities[id]=c
    return c
end
Map={GetPlot=function(x,y)
    for _,p in pairs(Players) do for _,c in pairs(p.cities) do
        if c.x==x and c.y==y then return {GetPlotCity=function() return c end} end
    end end
end}
function Select(c,order,item)
    c.order,c.item=order,item
    Events.SpecificCityInfoDirty.Fire(c.owner,c.id,2)
    Events.SerialEventCityInfoDirty.Fire()
end
function Complete(c,building,gold,faith,genuine)
    if genuine then c.things=c.things+1 end
    c.b[building]=1
    -- Dirty events during native construction precede the completion hook.
    Events.SpecificCityInfoDirty.Fire(c.owner,c.id,0)
    GameEvents.CityConstructed.Fire(c.owner,c.id,building,gold or false,faith or false)
end
function Tick(c,complete)
    GameEvents.PlayerDoneTurn.Fire(c.owner)
    Game.turn=Game.turn+1
    if complete then
        Complete(c,c.item,false,false,true)
        Select(c,-1,-1)
    end
    GameEvents.PlayerDoTurn.Fire(c.owner)
end
function ReloadSol()
    -- Simulate a fresh add-in _G while retaining the engine's MapModData.
    rawset(_G,'__SOL_RUNTIME_CONTEXT_LOADED',nil)
    for _,e in pairs(GameEvents) do e.handlers={} end
    for _,e in pairs(Events) do e.handlers={} end
    assert(loadstring(SolSource))()
end
