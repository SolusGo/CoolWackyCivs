"""Repeatable mock event workload; counts work, not native game frame time."""
import argparse,json,subprocess,time
from validate_shattered_mod import database,fixture

WORKLOAD='''
local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0];Turn=1
for n=10,109 do p.cities[n]=newCity(0,n,2+(n%10)*11,18+math.floor(n/10)*9) end
for n=1000,1599 do p.units[n]=newUnit(0,n,GameInfoTypes.UNIT_WARRIOR) end
I.Reconcile(s);I.UnitTick(s,false);I.Commit(0)
Metrics={buildings=0,unitVisits=0,saves=0,writes=0,ui=0}
local building=I.Building;I.Building=function(...) Metrics.buildings=Metrics.buildings+1;return building(...) end
local units=p.Units;p.Units=function(self) local it=units(self);return function() local u=it();if u then Metrics.unitVisits=Metrics.unitVisits+1 end;return u end end
local save=I.Save;I.Save=function(...) Metrics.saves=Metrics.saves+1;return save(...) end
LuaEvents.ImperialChanged.Add(function(pid) if pid==0 then Metrics.ui=Metrics.ui+1 end end)
-- Persistence has already opened storage, so count its writes through the mock.
SaveWriteCount=0
for n=1,50 do p:InitUnit(GameInfoTypes.UNIT_WARRIOR,10,10,1) end
for n=1,200 do GameEvents.CombatEnded.Fire(0,0,0,10,100,2,0,0,10,100,-1,-1,0,10,10) end
Metrics.writes=SaveWriteCount
-- A political turn nests two native imperial deaths inside a rebellion.
local g=I.Provinces(s)[1];local c=I.City(g,0);c:SetPopulation(30,true)
for k=1,2 do local u=p:InitUnit(GameInfoTypes.UNIT_IMPERIAL_LEGION,c.x+2,c.y+k,1);local r=s.units[u:GetID()];r.home=g.key;r.governor=g.id;r.oath=5 end
g.loyalty=5;g.critical=1;g.rebelNext=0;s.authority=40;s.nextPolitical=Turn
local before=Metrics.saves;I.Turn(0);Metrics.nestedSaves=Metrics.saves-before
assert(g.faction and s.factions[g.faction].defections==2)
Metrics.writes=SaveWriteCount
assert(#I.Provinces(s)>=100);assert(I.RebelCount(s)<=24)
'''

def run(ref=None):
    source=None
    if ref:
        cache={}
        def source(name):
            if name not in cache:cache[name]=subprocess.check_output(['git','show',f'{ref}:TheShatteredEmpire/Lua/{name}.lua'],text=True)
            return cache[name]
    lua=fixture(database(),source=source)
    begin=time.perf_counter();lua.execute(WORKLOAD);elapsed=time.perf_counter()-begin
    result=dict(lua.globals().Metrics);result['seconds']=round(elapsed,3);result['source']=ref or 'working tree'
    print(json.dumps(result,sort_keys=True));return result

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--ref');run(parser.parse_args().ref)
