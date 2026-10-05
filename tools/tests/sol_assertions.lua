local C,U,P,X=1,0,2,3
local p=Players[0]
local c=NewCity(1,0)
local function S() return MapModData.SolIntellect end
local function r(city) return S().GetState(city.owner).cities[city.id] end
local function build(city,item,turns)
    Select(city,C,item)
    for i=1,turns do Tick(city,i==turns) end
end

-- Explicit fourth-turn boundary, escalation/cap, rounding/minimum and cost basis.
for _,case in ipairs({{3,0},{4,12},{5,14},{7,18},{10,24},{15,24}}) do
    local before=p.science
    build(c,100,case[1])
    assert(p.science-before==case[2],'construction duration boundary '..case[1])
end
assert(S().ScienceBurst(250,7)==45 and S().ScienceBurst(500,15)==120)
assert(S().ScienceBurst(1,4)==1 and S().ScienceBurst(109,5)==15)
assert(S().ScienceBurst(0,10)==0 and S().ScienceBurst(-1,10)==0)
for _,speed in ipairs({.67,1,1.5,3,2.35}) do
    c.speed=speed;c.overflow=999;c.modifier=300;c.production=5000
    local before=p.science
    build(c,101,7)
    assert(p.science-before==math.floor(math.floor(250*speed)*18/100),'speed/cost rather than investment')
end
c.speed=1

-- Every order/ID change resets, including switch-away-and-back inside one turn.
for _,nextOrder in ipairs({{U,1},{C,102},{C,103},{P,1},{X,1},{-1,-1}}) do
    Select(c,C,101)
    for i=1,3 do Tick(c) end
    assert(r(c).turns==3)
    Select(c,nextOrder[1],nextOrder[2]);Select(c,C,101)
    assert(r(c).turns==0,'same-turn switch retained prior work')
    local before=p.science
    for i=1,3 do Tick(c,i==3) end
    assert(p.science==before,'combined interrupted durations qualified')
end
Select(c,C,101);for i=1,3 do Tick(c) end
Select(c,U,7);Tick(c);Select(c,C,101)
local before=p.science;for i=1,4 do Tick(c,i==4) end
assert(p.science-before==30)

-- Buying actively produced buildings, free grants and counterfeit event hooks.
for _,flags in ipairs({{true,false},{false,true}}) do
    Select(c,C,101);for i=1,8 do Tick(c) end
    before=p.science;Complete(c,101,flags[1],flags[2],false)
    assert(p.science==before and r(c).turns==0)
end
Select(c,C,103);for i=1,5 do Tick(c) end
before=p.science;local insight=r(c).insight
Complete(c,103,false,false,false)
assert(p.science==before and r(c).insight==insight,'free grant rewarded')
GameEvents.PlayerDoneTurn.Fire(0);Game.turn=Game.turn+1
Complete(c,103,false,false,false) -- armed but native completion counter unchanged
assert(p.science==before and r(c).insight==insight,'fake hook passed genuine production guard')
GameEvents.PlayerDoTurn.Fire(0)

-- Purchases and instant completions in the active turn do not exploit stale arms.
Select(c,C,100);for i=1,5 do Tick(c) end
GameEvents.PlayerDoneTurn.Fire(0)
before=p.science;Complete(c,100,false,false,true)
assert(p.science==before,'same-turn instant completion rewarded')
Select(c,-1,-1);Game.turn=Game.turn+1;GameEvents.PlayerDoTurn.Fire(0)
for _,id in ipairs({106,107}) do before=p.science;build(c,id,10);assert(p.science==before) end

-- Unit/project completions cannot lend their counter delta to later free grants.
for _,case in ipairs({{U,'CityTrained'},{P,'CityCreated'}}) do
    Select(c,case[1],7);GameEvents.PlayerDoneTurn.Fire(0);Game.turn=Game.turn+1
    c.things=c.things+1;GameEvents[case[2]].Fire(0,c.id,7,false,false)
    Select(c,C,103);local insight=r(c).insight;before=p.science
    Complete(c,103,false,false,false)
    assert(p.science==before and r(c).insight==insight,'free grant borrowed unit/project counter')
    GameEvents.PlayerDoTurn.Fire(0)
end

-- Wonders earn Insight independently of the four-turn science threshold.
for i,item in ipairs({103,104,110,111,112,113}) do
    before=p.science;build(c,item,i==1 and 1 or 4)
    assert(r(c).insight==math.min(i,5) and c.b[200]==math.min(i,5))
    if i==1 then assert(p.science==before) else assert(p.science>before) end
end
local notes=#p.notes;build(c,114,4);assert(#p.notes==notes+1,'cap emitted extra insight gain')
before=p.science;build(c,105,4);assert(p.science-before==60 and r(c).insight==5)

-- Native science per specialist is checked in SQL; dynamic culture excludes slackers.
c.b[101]=1
for _,count in ipairs({0,1,2,3,5,6,9,10}) do
    c.spec={};for i=1,count do local kind=(i-1)%7+1;c.spec[kind]=(c.spec[kind] or 0)+1 end
    c.spec[8]=20
    Events.SpecificCityInfoDirty.Fire(0,c.id,3)
    assert(c:GetNumRealBuilding(201)==math.floor(count/3),'specialist floor or unemployed-citizen contamination')
end
c.b[101]=nil;GameEvents.CitySoldBuilding.Fire(0,c.id);assert(c.b[201]==0)
c.free[101]=1;Events.SerialEventCityInfoDirty.Fire();assert(c.b[201]==3)
c.free[101]=nil
c.b[102]=1
for insight=0,5 do
    r(c).insight=insight;S().RefreshCity(0,c.id)
    assert(c:GetNumRealBuilding(200)==insight and c:GetNumRealBuilding(202)==math.floor(insight/2))
end
c.b[102]=nil;GameEvents.CitySoldBuilding.Fire(0,c.id);assert(c.b[202]==0)

-- Independent city and player records, AI behavior and human-only notifications.
local other=NewCity(2,0);Select(other,C,100);Tick(other)
assert(r(other).insight==0 and r(c).insight==5)
local ai=NewCity(3,2);build(ai,103,4)
assert(Players[2].science==60 and r(ai).insight==1 and #Players[2].notes==0)
local foreign=NewCity(4,1);build(foreign,103,5);assert(Players[1].science==0 and not foreign.b[200])

-- Save/load during a construction and a pending native turn preserve exact counts.
Select(c,C,101);for i=1,3 do Tick(c) end
assert(r(c).turns==3);local original=p.science
ReloadSol();assert(r(c).turns==3 and r(c).insight==5)
GameEvents.PlayerDoneTurn.Fire(0);ReloadSol()
Game.turn=Game.turn+1;Complete(c,101,false,false,true)
assert(p.science-original==30)
local rewarded=p.science
GameEvents.CityConstructed.Fire(0,c.id,101,false,false)
ReloadSol();GameEvents.CityConstructed.Fire(0,c.id,101,false,false)
assert(p.science==rewarded,'duplicate completion or reload duplicated research')
Select(c,-1,-1);GameEvents.PlayerDoTurn.Fire(0)
local n=r(c).turns;GameEvents.PlayerDoTurn.Fire(0);assert(r(c).turns==n)

-- Research bank survives no selected technology and flushes once on selection.
p.tech=-1;original=p.science;build(c,100,4)
assert(p.science==original and S().GetState(0).pendingScience==12)
ReloadSol();assert(S().GetState(0).pendingScience==12)
p.tech=2;Events.SerialEventGameDataDirty.Fire()
assert(p.science-original==12 and S().GetState(0).pendingScience==0)
Events.SerialEventGameDataDirty.Fire();ReloadSol();assert(p.science-original==12)

-- Capture, recapture, removal, city ID reuse and missing-destruction fallback.
c.b[101]=1;c.b[102]=1;r(c).insight=5;S().RefreshCity(0,c.id)
Players[0].cities[c.id]=nil;Players[1].cities[c.id]=c;c.owner=1
GameEvents.CityCaptureComplete.Fire(0,false,c.x,c.y,1,true,10)
assert(c.b[200]==0 and c.b[201]==0 and c.b[202]==0 and not S().GetState(0).cities[c.id])
Players[1].cities[c.id]=nil;Players[0].cities[c.id]=c;c.owner=0
GameEvents.CityCaptureComplete.Fire(1,false,c.x,c.y,0,true,10)
assert(r(c).insight==0 and r(c).turns==0 and c.b[200]==0)
Players[0].cities[c.id]=nil;Events.SerialEventCityDestroyed.Fire({},0,c.id)
assert(not S().GetState(0).cities[c.id])
c=NewCity(1,0,20);GameEvents.PlayerCityFounded.Fire(0,c.x,c.y)
assert(r(c).insight==0 and r(c).turns==0)
Players[0].cities[c.id]=nil;GameEvents.PlayerDoTurn.Fire(0)
assert(not S().GetState(0).cities[c.id])

-- Lost turns cannot create retrospective rewards; resistance resets a streak.
c=NewCity(5,0);Select(c,C,100);Tick(c);Tick(c)
c.resistance=true;Tick(c);assert(r(c).turns==0)
c.resistance=false;Tick(c);assert(r(c).turns==1)
GameEvents.PlayerDoneTurn.Fire(0);Game.turn=Game.turn+3;GameEvents.PlayerDoTurn.Fire(0)
assert(r(c).turns==0,'skipped player turns retained a continuous streak')
local savedTurns=r(c).turns
r(c).turns=999 -- unsaved data retained in the old MapModData closure
ReloadSol();assert(r(c).turns==savedTurns,'stale shared runtime state survived fresh context')
local handlers=#GameEvents.PlayerDoTurn.handlers
assert(loadstring(SolSource))()
assert(#GameEvents.PlayerDoTurn.handlers==handlers,'same-context duplicate listeners')
print('PASS Sol Lua 5.1: duration boundaries, every switch, purchases/free grants, all speeds, wonders/cap, specialist floors, AI, research bank, save-load/deduplication, capture and removal')
