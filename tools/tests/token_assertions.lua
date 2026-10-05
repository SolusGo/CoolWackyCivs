local T=MapModData.TokenizedIntelligence
local p,c,u=Players[0],Players[0].cities[0],Players[0].units[0]
local function inv() T.Invalidate(0) end
local function rich() bank(0,T.Stats(0).capacity) end
local function use(id,target) local ok,reason=T.Use(0,id,target);assert(ok,id..': '..tostring(reason)) end
assert(T.Tokens(0)==T.Scale(250) and T.Tokens(1)==T.Scale(250) and not T.IsToken(2))
assert(T.Stats(0).income==30)
nextTurn(0);assert(T.Tokens(0)==T.Scale(250)+30)
local unchanged=T.Tokens(0);GameEvents.PlayerDoTurn.Fire(0);assert(T.Tokens(0)==unchanged)
rich();nextTurn(0);assert(T.Tokens(0)==T.Stats(0).capacity)
bank(0,0);assert(not T.Use(0,'PRODUCTION',0));assert(c.production==0 and T.Tokens(0)==0)
rich();use('PRODUCTION',0);assert(c.production==T.Scale(100))
assert(T.Cost(0,'PRODUCTION')==math.floor(T.Scale(500)*0.75+0.5))
rich();use('PRODUCTION',0);assert(T.Cost(0,'PRODUCTION')==math.floor(T.Scale(500)*7/12+0.5))
assert(T.Stats(0).penalty>=25)
c.production=c.needed-2;rich();use('PRODUCTION',0);assert(c.production==c.needed-1)
assert(not T.Use(0,'PRODUCTION',0))
use('CLEAR');assert(T.Stats(0).penalty==0 and #T.Active(0)==0)
assert(not T.Use(0,'CLEAR'))
rich();use('QUERY');assert(Teams[0].techs.progress==50)
p.tech=1;rich();assert(not T.Use(0,'QUERY')) -- switching tech cannot reset query limit
nextTurn(0);Teams[0].techs.progress=998;rich();use('QUERY');assert(Teams[0].techs.progress==999)
nextTurn(0);rich();assert(not T.Use(0,'QUERY'))
p.tech=-1;assert(not T.Use(0,'QUERY'));p.tech=0
rich();use('ROUTE',0);assert(u.moves==240)
assert(not T.Use(0,'ROUTE',0));assert(T.Cost(0,'PRODUCTION')==T.Scale(500))
u.trade=true;assert(not T.Use(0,'ROUTE',0));u.trade=false
assert(not T.Use(0,'FORECAST'))
rich();use('TACTICAL',0);assert(u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_TACTICAL))
rich();assert(not T.Use(0,'GOLD')) -- one persistent slot in early eras
local tokens=T.Tokens(0);reload();T=MapModData.TokenizedIntelligence
assert(T.Tokens(0)==tokens and #T.Active(0)==1 and u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_TACTICAL))
for i=1,T.Scale(3) do nextTurn(0) end
assert(not u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_TACTICAL) and #T.Active(0)==0)
for i=1,T.Scale(4) do nextTurn(0) end
assert(T.Stats(0).penalty==0)
p.era=5;GameEvents.TeamTechResearched.Fire(0);assert(T.Stats(0).capacity==T.Scale(6000))
nextTurn(0);assert(p.notices==1 and T.Model(0)=='Large Model' and T.Limit(0)==2)
c.b[2]=1;c.b[3]=1;c.spec[11]=2
GameEvents.CityConstructed.Fire(0,0,3,false,false)
assert(T.Stats(0).capacity==T.Scale(6575))
assert(T.Stats(0).base==135 and T.Stats(0).income==148) -- 30 city+pop,30 scientist,25 cluster,50 centre; +10%
c.pop=11;GameEvents.SetPopulation.Fire(c.x,c.y,10,11);assert(T.Stats(0).population==22)
rich();use('OFFENSE',0);assert(u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_OFFENSE))
rich();use('DEFENSE',0);assert(not u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_OFFENSE) and u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_DEFENSE) and #T.Active(0)==1)
rich();use('MOBILITY',0);rich();use('TARGET',0)
rich();use('GOLD');assert(c.b[GameInfoTypes.BUILDING_TOKEN_GOLD]==1)
assert(T.Tokens(1)==T.Scale(250)) -- player isolation
local new=newUnit(0,0,99);new.birth=Turn+1;new.p[GameInfoTypes.PROMOTION_TOKEN_TARGET]=true
p.units[0]=new;GameEvents.UnitConverted.Fire(0,0,0,0,true)
assert(not new:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_TARGET) and #T.Active(0)==1)
p.units[0]=u;u.birth=Turn+2;inv()
for i=1,T.Scale(5) do nextTurn(0) end
assert(c.b[GameInfoTypes.BUILDING_TOKEN_GOLD]==0)
rich();use('GROWTH',0);assert(c.b[GameInfoTypes.BUILDING_TOKEN_GROWTH]==1)
-- Capture strips effect markers and rejects old city identity, including Token -> Token.
p.cities[0]=nil;c.owner=1;Players[1].cities[7]=c;c.id=7
GameEvents.CityCaptureComplete.Fire(0,false,c.x,c.y,1)
assert(c.b[GameInfoTypes.BUILDING_TOKEN_GROWTH]==0 and #T.Active(0)==0)
assert(not T.Use(0,'GROWTH',7))
p.cities[0]=newCity(0,0);c=p.cities[0];u=newUnit(0,0);p.units[0]=u;inv()
p.era=7;GameEvents.TeamTechResearched.Fire(0);assert(T.Limit(0)==3)
for _,id in ipairs({'RESEARCH','TRADE','HAPPINESS','CULTURE','ADMIN','SIMULATION','FORECAST','GRAND'}) do
    for i=1,T.Scale(15) do nextTurn(0) end
    use('CLEAR');rich();use(id,id=='SIMULATION' and 0 or nil)
    if id=='TRADE' then p.routes={{FromCity=c},{FromCity=c}};GameEvents.CityConstructed.Fire(0);assert(c.b[GameInfoTypes.BUILDING_TOKEN_TRADE]==2) end
    if id=='HAPPINESS' then assert(c.b[GameInfoTypes.BUILDING_TOKEN_HAPPINESS]==1) end
    if id=='GRAND' then assert(c.b[GameInfoTypes.BUILDING_TOKEN_GRAND]==1 and u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_GRAND)) end
    if id=='FORECAST' then assert(u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_FORECAST)) end
end
for i=1,T.Scale(15) do nextTurn(0) end
use('CLEAR');assert(#T.Active(0)==0 and not u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_GRAND))
-- Dying unit does not retain a slot or create nil references.
rich();use('TACTICAL',0);p.units[0]=nil;assert(#T.Active(0)==0);nextTurn(0)
-- AI spends at capacity, once per turn, without UI functions.
p.human=false;c.production=0;c.needed=100000;c.building=80;rich()
local before=T.Tokens(0);nextTurn(0);assert(T.Tokens(0)<before)
local after=T.Tokens(0);GameEvents.PlayerDoTurn.Fire(0);assert(T.Tokens(0)==after)
Network=true;assert(not T.Use(0,'CLEAR'));local t=T.Tokens(0);nextTurn(0);assert(T.Tokens(0)==t);Network=false
assert(T.Tokens(0)>=0 and T.Stats(0).capacity>0)
print('PASS Tokens: generation/cap, overflow guards, cache, saturation, limits, persistence, expiry, upgrades, capture, all Prompts and AI')
