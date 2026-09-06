local T=MapModData.TerraFramework
local function mode(expected)
    local count=0;for i=10,13 do count=count+(city.b[i] or 0) end
    assert(count==(expected and 1 or 0),'mode stacked or absent')
    if expected then assert(city.b[expected]==1) end
end
local function config(id)
    local n=0;for i=20,22 do if unit.p[i] then n=n+1 end end
    assert(n==(id and 1 or 0));if id then assert(unit.p[id]) end
end
T.Constructed(0,1,30,false,false);mode(10)
local m,e=T.GetMode(city);assert(m=='RESEARCH' and e==15)
Game.turn=8;T.Constructed(0,1,30,0,0);local _,expiry=T.GetMode(city);assert(expiry==18)
T.Constructed(0,1,3,true,false);mode(10)
T.Constructed(0,1,3,false,true);mode(10)
T.Constructed(0,1,3,nil,nil);mode(10)
T.Constructed(0,1,33,false,false);mode(10)
T.Constructed(0,1,34,false,false);mode(10)
city.b[31]=1;T.Initialize();mode(10) -- Free building must not trigger.
T.Constructed(0,1,3,false,false);mode(11)
T.Constructed(0,2,30,false,false);assert(other.b[10]==1);mode(11)
T.Constructed(0,1,31,false,false);mode(12)
T.Constructed(0,1,32,false,false);mode(13)
Game.turn=17;T.Turn(0);mode(13)
Game.turn=18;T.Turn(0);mode(nil)
T.Constructed(0,1,30,false,false);T.Initialize();mode(10)
city.b[3]=1;Players[0].routes={{FromCity=city},{FromCity=city},{FromCity=city},{FromCity=other}};T.RefreshTrade(0);assert(city.b[4]==3 and other:GetNumRealBuilding(4)==0)
Players[0].routes={{FromCity=city}};T.RefreshTrade(0);assert(city.b[4]==1)
Players[0].routes={};T.RefreshTrade(0);assert(city.b[4]==0)
T.Capture(0,false,1,1,2);mode(nil)
T.Constructed(0,1,30,false,false);city.founded=22;T.Initialize();mode(nil)
plot.owner=0;plot.rough=true;T.Turn(0);config(20)
plot.owner=1;T.Turn(0);config(20) -- teammate counts, not open borders
plot.owner=2;T.Turn(0);config(21)
plot.rough=false;T.Moved(0,1);config(21)
T.Initialize();config(21) -- load cannot change configuration
T.Turn(0);config(22)
plot.owner=-1;plot.rough=true;T.Turn(0);config(21)
unit.embarked=true;T.Moved(0,1);config(nil)
unit.embarked=false;T.Moved(0,1);config(nil)
T.Turn(0);config(21)
unit.kind=999;T.Upgraded(0,2,1);config(nil);assert(not unit.p[5])
city.b[3]=0;T.RefreshTrade(0);assert(city.b[4]==0)
T.Constructed(0,1,30,false,false);Players[0].civ=99;T.Turn(0);mode(nil)
