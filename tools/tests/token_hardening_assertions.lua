-- Execute public actions/events; fixture resets represent independent saved games.
local T,p,c,u
local function setup(era)
    Saved={};Turn=0;Players[0]=newPlayer(0);Players[1]=newPlayer(1);Players[2]=newPlayer(2,99)
    for pid=0,2 do Players[pid].cities[0]=newCity(pid,0);Players[pid].units[0]=newUnit(pid,0) end
    Teams[0].techs.progress=0;Teams[0].war=0;Teams[0].known=false
    p=Players[0];p.era=era or 4;c=p.cities[0];u=p.units[0];c.needed=100000
    reload();T=MapModData.TokenizedIntelligence
end
local function use(id,target)
    bank(0,T.Stats(0).capacity)
    local ok,why=T.Use(0,id,target);assert(ok,id..': '..tostring(why))
end
local function advance(n) for i=1,n do nextTurn(0) end end
local function tier(level,duration)
    assert(T.Get(0,'satLevel')==level)
    assert(T.Get(0,'satExpiry')==T.Get(0,'clock')+T.Scale(duration))
end
local function heavy(critical)
    use('PRODUCTION',0);tier(1,2) -- none -> Light
    use('QUERY');use('ROUTE',0);tier(2,3) -- Light -> Heavy
    if critical then use('GOLD');use('PRODUCTION',0);tier(3,4) end -- Heavy -> Critical
end
setup();use('PRODUCTION',0);tier(1,2)
local first=T.Get(0,'satExpiry');nextTurn(0);use('QUERY');tier(1,2)
assert(T.Get(0,'satExpiry')>first) -- Light refresh
for _,level in ipairs({2,3}) do
    setup();heavy(level==3);local expiry=T.Get(0,'satExpiry')
    advance(T.Scale(level==3 and 4 or 3)-1)
    reload();T=MapModData.TokenizedIntelligence
    assert(T.Get(0,'satLevel')==level and T.Get(0,'satExpiry')==expiry)
    use('QUERY') -- new own-turn spending is Light, stronger tier has one tick left
    assert(T.Get(0,'satLevel')==level and T.Get(0,'satExpiry')==expiry,'weak spend extended stronger saturation')
    reload();T=MapModData.TokenizedIntelligence
    assert(T.Get(0,'satLevel')==level and T.Get(0,'satExpiry')==expiry)
    bank(0,0);nextTurn(0);assert(T.Tokens(0)==(level==3 and 18 or 22))
    nextTurn(0);assert(T.Tokens(0)==(level==3 and 48 or 52) and T.Stats(0).penalty==0)
end
setup();c.b[3]=1;GameEvents.CityConstructed.Fire(0)
use('PRODUCTION',0);tier(1,2);use('FORECAST');tier(3,4) -- direct Light -> Critical
for level=1,3 do
    setup();if level==1 then use('PRODUCTION',0) else heavy(level==3) end
    bank(0,0);local income=({27,22,18})[level]
    for tick=1,T.Scale(level+1) do
        local before=T.Tokens(0);nextTurn(0);assert(T.Tokens(0)-before==income)
    end
    local before=T.Tokens(0);nextTurn(0);assert(T.Tokens(0)-before==30 and T.Stats(0).penalty==0)
end
for _,era in ipairs({6,7}) do
    setup(era);use('GRAND');tier(1,2) -- would be Heavy without Frontier reduction
    use('QUERY');if era==7 then use('PRODUCTION',0);use('ROUTE',0);use('PRODUCTION',0) end
    tier(2,3) -- would be Critical without reduction
    setup(era);use('PRODUCTION',0);assert(T.Get(0,'satLevel')==0)
end
-- Clear restores exactly a quarter window, clears persistent effects/cache,
-- and preserves saturation, cumulative spend and both instant restrictions.
setup();heavy(true);local spent,level,expiry=T.Get(0,'spent'),T.Get(0,'satLevel'),T.Get(0,'satExpiry')
bank(0,1000);assert(T.Use(0,'CLEAR'))
assert(T.Tokens(0)==1000+math.floor(T.Stats(0).capacity*.25))
assert(#T.Active(0)==0 and c.b[GameInfoTypes.BUILDING_TOKEN_GOLD]==0)
assert(T.Get(0,'lastPrompt','')=='' and T.Get(0,'cacheUses')==0)
assert(T.Get(0,'spent')==spent and T.Get(0,'satLevel')==level and T.Get(0,'satExpiry')==expiry)
assert(not T.Use(0,'QUERY') and not T.Use(0,'ROUTE',0) and not T.Use(0,'CLEAR'))
reload();T=MapModData.TokenizedIntelligence;p.tech=1
assert(not T.Use(0,'QUERY') and not T.Use(0,'ROUTE',0))
advance(T.Scale(15)-1);assert(not T.Check(0,'CLEAR'));nextTurn(0);assert(T.Check(0,'CLEAR'))
-- Cache last valid tick survives reload; the following tick returns normal price.
setup();use('PRODUCTION',0)
local normal=T.Scale(500);assert(T.Cost(0,'PRODUCTION')==math.floor(normal*.75+.5))
use('PRODUCTION',0);assert(T.Cost(0,'PRODUCTION')==math.floor(normal*7/12+.5))
advance(T.Scale(10));reload();T=MapModData.TokenizedIntelligence
assert(T.Cost(0,'PRODUCTION')==math.floor(normal*7/12+.5));nextTurn(0)
assert(T.Cost(0,'PRODUCTION')==normal)
-- Every era/speed and each infrastructure increment, before aggregate scaling.
for era,cap in ipairs({1000,1500,2250,3250,4500,6000,8000,10000}) do
    setup(era-1);assert(T.Stats(0).capacity==T.Scale(cap))
    c.b[2]=1;GameEvents.CityConstructed.Fire(0);assert(T.Stats(0).capacity==T.Scale(cap+75))
    c.b[3]=1;GameEvents.CityConstructed.Fire(0);assert(T.Stats(0).capacity==T.Scale(cap+575))
end
setup();local b=newCity(0,1);b.pop=20;p.cities[1]=b
c.spec[11]=2;c.b[2]=1;c.b[3]=1;b.spec[12]=3
GameEvents.CityConstructed.Fire(0)
-- A=30+30+25+50=135; B=50+30=80. Only A gets +13.5.
assert(T.Stats(0).base==215 and T.Stats(0).modifier==13.5 and T.Stats(0).income==228)
b.b[3]=1;GameEvents.CityConstructed.Fire(0)
assert(T.Stats(0).base==265 and T.Stats(0).modifier==26.5 and T.Stats(0).income==291)
-- Native conversion hook sees both objects, after promotion copying, before kill.
for _,name in ipairs({'OFFENSE','DEFENSE','MOBILITY','TARGET','TACTICAL','SIMULATION','FORECAST','GRAND'}) do
    for _,recipient in ipairs({0,1,2}) do
        setup(7);use(name,(name=='FORECAST' or name=='GRAND') and nil or 0)
        local id=GameInfoTypes['PROMOTION_TOKEN_'..name];assert(u:IsHasPromotion(id))
        local dest=newUnit(recipient,7,99);dest.p[id]=true;Players[recipient].units[7]=dest
        GameEvents.UnitConverted.Fire(0,recipient,0,7,recipient==0)
        if name=='FORECAST' or name=='GRAND' then
            assert(#T.Active(0)==1) -- source empire Prompt survives; only owned armies qualify
            assert(dest:IsHasPromotion(id)==(recipient==0))
        else
            assert(#T.Active(0)==0 and T.Get(0,'effects','')=='')
            assert(not dest:IsHasPromotion(id) and not u:IsHasPromotion(id))
        end
    end
end
-- Death/distant gift removes source record immediately, before native deletion.
setup(7);use('OFFENSE',0);use('GOLD');GameEvents.UnitPrekill.Fire(0,0,4,0,0,true,-1)
assert(#T.Active(0)==1 and not T.Get(0,'effects',''):find('OFFENSE',1,true))
assert(not u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_OFFENSE));u.delayed=true
assert(not T.Check(0,'TACTICAL',0));GameEvents.UnitCreated.Fire(0,9,4,0,0)
assert(not u:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_OFFENSE))
-- Capture and recapture strip the record; ID reuse cannot resurrect it.
setup();use('GROWTH',0);p.cities[0]=nil;c.owner=2;Players[2].cities[7]=c;c.id=7
GameEvents.CityCaptureComplete.Fire(0,false,c.x,c.y,2)
assert(#T.Active(0)==0 and T.Get(0,'effects','')=='')
Players[2].cities[7]=nil;c.owner=0;c.id=0;p.cities[0]=c
GameEvents.CityCaptureComplete.Fire(2,false,c.x,c.y,0)
assert(c.b[GameInfoTypes.BUILDING_TOKEN_GROWTH]==0 and #T.Active(0)==0)
p.cities[0]=nil;nextTurn(0);local replacement=newCity(0,0);replacement.founded=Turn;replacement.x=5
p.cities[0]=replacement;GameEvents.PlayerCityFounded.Fire(0,5,0)
assert(replacement:GetNumBuilding(GameInfoTypes.BUILDING_TOKEN_GROWTH)==0 and #T.Active(0)==0)
setup();use('GROWTH',0);local reuse=newCity(0,0);reuse.founded=9;reuse.x=8;p.cities[0]=reuse
assert(#T.Active(0)==0);GameEvents.PlayerCityFounded.Fire(0,8,0)
assert(T.Get(0,'effects','')=='' and reuse:GetNumBuilding(GameInfoTypes.BUILDING_TOKEN_GROWTH)==0)
setup();use('TACTICAL',0);local reuseUnit=newUnit(0,0);reuseUnit.birth=9;p.units[0]=reuseUnit
assert(#T.Active(0)==0);GameEvents.UnitCreated.Fire(0,0,4,0,0)
assert(T.Get(0,'effects','')=='' and not reuseUnit:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_TACTICAL))
-- AI priorities and the one-success-per-turn guarantee use real turn handlers.
for _,scenario in ipairs({'low','happiness','war','production','research'}) do
    setup(4);p.human=false
    if scenario=='low' then bank(0,0)
    elseif scenario=='happiness' then p.happy=-1;bank(0,T.Stats(0).capacity)
    elseif scenario=='war' then Teams[0].war=1;u.damage=30;bank(0,T.Stats(0).capacity)
    elseif scenario=='production' then c.building=80;bank(0,T.Stats(0).capacity)
    else bank(0,T.Stats(0).capacity) end
    local count=0;local original=T.Use
    T.Use=function(...) local ok,reason=original(...);if ok then count=count+1 end;return ok,reason end
    nextTurn(0);assert(count==(scenario=='low' and 0 or 1))
    local action=T.Get(0,'lastPrompt','')
    assert(scenario=='low' or action==({happiness='HAPPINESS',war='DEFENSE',production='PRODUCTION',research='QUERY'})[scenario])
    GameEvents.PlayerDoTurn.Fire(0);assert(count<=1)
end
print('PASS Token hardening: tier protection/reload, Clear invariants, cache expiry, all-era capacity, local centres, native transfer ordering, city identity, AI priorities')
