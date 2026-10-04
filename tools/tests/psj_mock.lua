-- Minimal engine doubles: events exercise production callbacks, never test APIs.
Saved = Saved or {}
Modding={OpenSaveData=function() return {GetValue=function(k) return Saved[k] end,
    SetValue=function(k,v) Saved[k]=v end} end}
GameInfoTypes={CIVILIZATION_PSJ_FIRST_NIGHT=100,UNIT_PSJ_SURVIVOR=200,BUILDING_PSJ_STARTER_HOUSE=300,
    PROMOTION_PSJ_LEARNING=400,PROMOTION_PSJ_BEGINNING=401,ERA_ANCIENT=0,ERA_CLASSICAL=1,ERA_MODERN=5,
    BUILDING_PSJ_HOME_1=301,BUILDING_PSJ_HOME_2=302,BUILDING_PSJ_HOME_3=303,IMPROVEMENT_MINE=500,IMPROVEMENT_FARM=501}
GameDefines={MAX_MAJOR_CIVS=4,MAX_CIV_PLAYERS=5}
T=0; Active=2
Game={GetGameTurn=function() return T end,GetGameSpeedType=function() return 0 end,GetActivePlayer=function() return Active end}
Locale={ConvertTextKey=function(k,...) return k end}
NotificationTypes={NOTIFICATION_GENERIC=1}
function callable(rows)
    return setmetatable(rows,{__call=function(self,filter)
        local n=0
        return function()
            while true do n=n+1; local r=self[n]; if not r then return nil end
                local valid=true; for k,v in pairs(filter) do if r[k]~=v then valid=false end end
                if valid then return r end
            end
        end
    end})
end
GameInfo={GameSpeeds={[0]={CulturePercent=100,ResearchPercent=100,GrowthPercent=100}},
    Eras={[0]={Type='ERA_ANCIENT'},[1]={Type='ERA_CLASSICAL'},[2]={Type='ERA_MEDIEVAL'},
        [3]={Type='ERA_RENAISSANCE'},[4]={Type='ERA_INDUSTRIAL'},[5]={Type='ERA_MODERN'},[6]={Type='ERA_POSTMODERN'},[7]={Type='ERA_INFORMATION'}},
    Builds={[1]={ImprovementType='IMPROVEMENT_MINE'},[2]={ImprovementType='IMPROVEMENT_FARM'}},
    Resources={[600]={Type='RESOURCE_WHEAT',ResourceClassType='RESOURCECLASS_BONUS'},
        [601]={Type='RESOURCE_IRON',ResourceClassType='RESOURCECLASS_RUSH'}},
    Resource_YieldChanges=callable({{ResourceType='RESOURCE_WHEAT',YieldType='YIELD_FOOD',Yield=1}}),
    Improvement_ResourceTypes=callable({{ImprovementType='IMPROVEMENT_FARM',ResourceType='RESOURCE_WHEAT'}})}
function resetEvents()
    GameEvents={}
    for _,n in ipairs({'PlayerDoTurn','PlayerCityFounded','CityConstructed','CityCaptureComplete','PlayerBuilt',
        'UnitPrekill','TeamSetEra','TeamMeet','NaturalWonderDiscovered','GoodyHutReceivedBonus',
        'UnitSetXY','UnitCreated','UnitUpgraded','UnitConverted'}) do
        local event={callbacks={}}
        event.Add=function(fn) table.insert(event.callbacks,fn) end
        event.Fire=function(...) for _,fn in ipairs(event.callbacks) do fn(...) end end
        GameEvents[n]=event
    end
end
resetEvents()
Plots={}
function plot(x,y,owner)
    local p={x=x,y=y,owner=owner or -1,area=1,resource=-1,improvement=-1,pillaged=false}
    function p:GetOwner() return self.owner end
    function p:IsWater() return self.water or false end
    function p:GetArea() return self.area end
    function p:GetPlotCity() return self.city end
    function p:GetResourceType() return self.resource end
    function p:GetImprovementType() return self.improvement end
    function p:IsImprovementPillaged() return self.pillaged end
    function p:IsNaturalWonder() return self.wonder or false end
    function p:IsRevealed(team) return self.revealed and self.revealed[team] or false end
    Plots[x..':'..y]=p
    return p
end
Map={GetGridSize=function() return 64,40 end,GetPlot=function(x,y) return Plots[x..':'..y] end,
    PlotDistance=function(x,y,a,b) return math.max(math.abs(x-a),math.abs(y-b)) end,
    GetNumPlots=function() return 0 end,GetPlotByIndex=function(i) return nil end}
Players={};Teams={}
function newPlayer(pid,civ,human)
    local p={id=pid,civ=civ,era=0,team=pid,alive=true,human=human,cities={},units={},culture=0,science=0,notifications={},research=10}
    function p:GetID() return self.id end
    function p:IsAlive() return self.alive end
    function p:IsMinorCiv() return self.minor or false end
    function p:IsBarbarian() return self.barbarian or false end
    function p:IsHuman() return self.human end
    function p:GetCivilizationType() return self.civ end
    function p:GetTeam() return self.team end
    function p:GetCurrentEra() return self.era end
    function p:GetCurrentResearch() return self.research end
    function p:GetCapitalCity() return self.capital end
    function p:GetNumCities() return #self.cities end
    function p:Cities() local i=0;return function() i=i+1;return self.cities[i] end end
    function p:Units() local i=0;return function() i=i+1;return self.units[i] end end
    function p:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
    function p:ChangeJONSCulture(n) self.culture=self.culture+n end
    function p:ChangeOverflowResearch(n) self.science=self.science+n end
    function p:AddNotification(_,body,title) table.insert(self.notifications,{body=body,title=title}) end
    Players[pid]=p
    local tech={ChangeResearchProgress=function(self,id,n,owner) Players[owner].science=Players[owner].science+n end}
    Teams[pid]={met={},GetTeamTechs=function() return tech end,IsHasMet=function(self,t) return self.met[t] end}
    return p
end
function newCity(p,x,y)
    local c={owner=p.id,original=p.id,x=x,y=y,found=T,buildings={},food=0}
    function c:GetX() return self.x end; function c:GetY() return self.y end
    function c:GetOwner() return self.owner end; function c:GetOriginalOwner() return self.original end
    function c:GetGameTurnFounded() return self.found end
    function c:GetNumBuilding(id) return self.buildings[id] or 0 end
    function c:SetNumRealBuilding(id,n) self.buildings[id]=n end
    function c:ChangeFood(n) self.food=self.food+n end
    table.insert(p.cities,c); p.capital=p.capital or c
    plot(x,y,p.id).city=c
    return c
end
function newUnit(p,id,typ)
    local u={owner=p.id,id=id,typ=typ or 200,x=0,y=0,xp=0,script='[OTHER:keep]',promotions={[400]=true}}
    function u:GetOwner() return self.owner end
    function u:GetUnitType() return self.typ end
    function u:GetX() return self.x end; function u:GetY() return self.y end
    function u:GetPlot() return Map.GetPlot(self.x,self.y) end
    function u:GetScriptData() return self.script end
    function u:SetScriptData(s) self.script=s end
    function u:IsHasPromotion(id) return self.promotions[id] or false end
    function u:SetHasPromotion(id,v) self.promotions[id]=v end
    function u:ChangeExperience(n) self.xp=self.xp+n end
    table.insert(p.units,u)
    return u
end
P=newPlayer(2,100,true); AI=newPlayer(1,100,false); Foreign=newPlayer(0,99,true)
Barb=newPlayer(4,99,false);Barb.barbarian=true
plot(0,0,2)
