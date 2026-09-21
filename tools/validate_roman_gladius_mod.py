"""Focused static and Lua-runtime validation for The RomanGladius Network."""
from __future__ import annotations

import re
import struct
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))


def static_checks() -> None:
    root = REPO / "RomanGladiusNetwork"
    required = {
        root / "SQL/00_RomanGladius_Core.sql",
        root / "SQL/01_RomanGladius_Inheritance.sql",
        root / "SQL/02_RomanGladius_UniqueEffects.sql",
        root / "SQL/10_RomanGladius_Text.sql",
        root / "Lua/RomanGladiusRuntime.lua",
        root / "UI/RomanGladiusPanel.lua",
        root / "UI/RomanGladiusPanel.xml",
        root / "Art/RomanGladiusLeader.dds",
        root / "Art/RomanGladiusDawn.dds",
        root / "Art/RomanGladiusMap.dds",
    }
    assert all(path.is_file() for path in required), "RomanGladius source or art file is missing"
    core = (root / "SQL/00_RomanGladius_Core.sql").read_text(encoding="utf-8-sig")
    effects = (root / "SQL/02_RomanGladius_UniqueEffects.sql").read_text(encoding="utf-8-sig")
    inheritance = (root / "SQL/01_RomanGladius_Inheritance.sql").read_text(encoding="utf-8-sig")
    runtime = (root / "Lua/RomanGladiusRuntime.lua").read_text(encoding="utf-8-sig")
    assert "Cost=(Cost*160+99)/100" in core
    assert "'EVENTS_CITY_FOUNDING'" in core
    assert "'EVENTS_CITY_CAPITAL'" in core
    assert "UNITCLASS_SETTLER','UNIT_ROMAN_GLADIUS_SERVER_OWNER" in core
    assert "BUILDINGCLASS_MONUMENT','BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE" in core
    assert "('BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE','YIELD_CULTURE',2)" in effects
    assert "('BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE','YIELD_GOLD',1)" in effects
    assert "('UNIT_SETTLER', 'UNIT_ROMAN_GLADIUS_SERVER_OWNER')" in inheritance
    assert "('BUILDING_MONUMENT', 'BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE')" in inheritance
    for token in ("R.PromoteModerator", "R.PromoteAdministrator", "R.ResolveEvent", "R.GetRoster",
                  "R.GetServers", "R.GetNetworkState", "PlayerCityFounded", "PlayerCanFoundCity",
                  "BALANCE_SETTLERS_CONSUME_POPULATION", "InitializeRomanServerCity", "SetPopulation"):
        assert token in runtime, f"Runtime feature missing: {token}"
    panel = ET.parse(root / "UI/RomanGladiusPanel.xml")
    ids = {node.attrib["ID"] for node in panel.iter() if "ID" in node.attrib}
    references = set(re.findall(r"Controls\.([A-Za-z0-9_]+)", (root / "UI/RomanGladiusPanel.lua").read_text(encoding="utf-8-sig")))
    assert references <= ids, f"Dashboard references missing controls: {references - ids}"
    expected = {
        "RomanGladiusIcon": (256, 128, 80, 64, 48, 45, 32, 24, 16),
        "RomanGladiusAlpha": (256, 128, 80, 64, 48, 45, 32, 24, 16),
        "RomanGladiusObjects": (256, 128, 80, 64, 45, 32, 16),
        "RomanGladiusLeader": (256, 128, 64),
    }
    for stem, sizes in expected.items():
        for size in sizes:
            path = root / "Art" / f"{stem}{size}.dds"
            assert path.is_file(), f"Missing atlas slot {path.name}"
            header = path.read_bytes()[:128]
            height, width = struct.unpack_from("<II", header, 12)
            columns = 4 if stem == "RomanGladiusObjects" else 1
            assert (width, height) == (size * columns, size), f"Wrong atlas geometry: {path.name}"
            assert header[84:88] == (b"DXT5" if width % 4 == 0 and height % 4 == 0 else b"\0\0\0\0")
    print("PASS RomanGladius static: source, UI, inheritance, hooks, and DDS atlas geometry")


def runtime_checks() -> None:
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
local saved={}
Modding={OpenSaveData=function() return {
 GetValue=function(key)return saved[key] end,
 SetValue=function(key,value)saved[key]=value end,
} end}
function event()
 local e={handlers={}}
 e.Add=function(callback)e.handlers[#e.handlers+1]=callback end
 return e
end
GameEvents={PlayerDoTurn=event(),PlayerCityFounded=event(),CityTrained=event(),PlayerCanTrain=event(),
 CityCanTrain=event(),PlayerCanFoundCity=event(),CityCaptureComplete=event(),CityConstructed=event(),
 SetPopulation=event(),CapitalChanged=event()}
LuaEvents={}
Events={}
NotificationTypes={NOTIFICATION_GENERIC=1}
GameInfoTypes={
 CIVILIZATION_ROMAN_GLADIUS_NETWORK=1,UNIT_ROMAN_GLADIUS_SERVER_OWNER=10,
 BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE=20,BUILDING_ROMAN_GLADIUS_PLAYER_GOLD=21,
 BUILDING_ROMAN_GLADIUS_PLAYER_SCIENCE=22,BUILDING_ROMAN_GLADIUS_PLAYER_CULTURE=23,
 BUILDING_ROMAN_GLADIUS_MODERATOR=24,BUILDING_ROMAN_GLADIUS_LEGENDARY=25,
 BUILDING_ROMAN_GLADIUS_THRIVING=26,BUILDING_ROMAN_GLADIUS_TROUBLED=27,
 BUILDING_ROMAN_GLADIUS_TOXIC=28,BUILDING_ROMAN_GLADIUS_DEAD=29,
 BUILDING_ROMAN_GLADIUS_OWNER_ONLINE=30,BUILDING_ROMAN_GLADIUS_GRAND_OPENING=31,
 BUILDING_ROMAN_GLADIUS_PEAK_HOURS=32,BUILDING_ROMAN_GLADIUS_MILESTONE_HAPPINESS=33,
 BUILDING_ROMAN_GLADIUS_SUCCESSFUL_NETWORK=34,
}
GameDefines={MAX_MAJOR_CIVS=2}
BUILT_IN_SETTLER_POPULATION=false
Game={current=0,GetGameTurn=function()return Game.current end,Rand=function()return 99 end,
 IsCustomModOption=function(name)return name=='BALANCE_SETTLERS_CONSUME_POPULATION' and BUILT_IN_SETTLER_POPULATION end,
 IsNetworkMultiPlayer=function()return false end}

function NewCity(owner,id,x,y,pop,name,founded)
 local c={owner=owner,id=id,x=x,y=y,pop=pop,name=name,founded=founded or 0,buildings={[20]=1},production=0,food=0}
 function c:GetOwner()return self.owner end; function c:GetID()return self.id end
 function c:GetX()return self.x end; function c:GetY()return self.y end
 function c:GetName()return self.name end; function c:GetPopulation()return self.pop end
 function c:ChangePopulation(n)self.pop=math.max(1,self.pop+n) end
 function c:GetGameTurnFounded()return self.founded end
 function c:GetNumRealBuilding(id)return self.buildings[id] or 0 end
 function c:SetNumRealBuilding(id,n)self.buildings[id]=n end
 function c:IsHasBuilding(id)return (self.buildings[id] or 0)>0 end
 function c:ChangeProduction(n)self.production=self.production+n end
 function c:GetProduction()return self.production end
 function c:ChangeFood(n)self.food=self.food+n end
 return c
end
function NewPlayer(id,civ)
 local p={id=id,civ=civ,alive=true,human=id==0,gold=1000,culture=0,research=0,capitalID=nil,cityList={},unitList={}}
 function p:IsAlive()return self.alive end; function p:IsHuman()return self.human end
 function p:GetCivilizationType()return self.civ end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:GetCapitalCity()
  if self.capitalID then return self:GetCityByID(self.capitalID) end
  return self.cityList[1]
 end
 function p:GetGold()return self.gold end; function p:ChangeGold(n)self.gold=self.gold+n end
 function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:ChangeOverflowResearch(n)self.research=self.research+n end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id then return u end end end
 function p:AddNotification()end
 return p
end
function NewUnit(id,kind)local u={id=id,kind=kind};function u:GetUnitType()return self.kind end;return u end
Players={[0]=NewPlayer(0,1),[1]=NewPlayer(1,99)}
local capital=NewCity(0,1,0,0,10,'Main Server',0);capital.buildings[20]=0;Players[0].cityList={capital}
local plots={}
Map={GetPlot=function(x,y)return plots[x..':'..y] end}
function PutCity(city)plots[city.x..':'..city.y]={GetPlotCity=function()return city end}end
PutCity(capital)
MapModData={}
''')
    source = (REPO / "RomanGladiusNetwork/Lua/RomanGladiusRuntime.lua").read_text(encoding="utf-8-sig")
    lua.execute(source)
    lua.execute(source)  # include from the UI must not duplicate handlers
    lua.execute(r'''
local R=MapModData.RomanGladiusNetwork
local city=Players[0].cityList[1]
assert(#GameEvents.PlayerDoTurn.handlers==1 and #GameEvents.PlayerCityFounded.handlers==1
 and #GameEvents.CityTrained.handlers==1 and #GameEvents.PlayerCanTrain.handlers==1
 and #GameEvents.CityCanTrain.handlers==1 and #GameEvents.PlayerCanFoundCity.handlers==1
 and #GameEvents.CityCaptureComplete.handlers==1 and #GameEvents.SetPopulation.handlers==1
 and #GameEvents.CapitalChanged.handlers==1,
 'runtime handlers missing or duplicated')
assert(R.Loaded,'runtime marked itself loaded before successful initialization')
assert(city.buildings[21]==5 and city.buildings[22]==2 and city.buildings[23]==2,
 'population threshold yields are incorrect')
assert(city.buildings[30]==1,'Owner Online is missing from the Capital')
city.pop=20;GameEvents.SetPopulation.handlers[1](0,0,10,20)
assert(city.buildings[21]==10 and city.buildings[22]==5 and city.buildings[23]==4,
 'population increase did not immediately refresh Server yields')
city.pop=3;GameEvents.SetPopulation.handlers[1](0,0,20,3)
assert(city.buildings[21]==1 and city.buildings[22]==0 and city.buildings[23]==0,
 'population decrease did not immediately refresh Server yields')
city.pop=10;GameEvents.SetPopulation.handlers[1](0,0,3,10)
local initialLogCount=#R.GetLogs(city)
R.OnCityFounded(0,0,0)
local s=R.GetCityState(city)
assert(s.reputation==60 and s.band=='Stable' and s.hasConsole and s.opening and Players[0].gold==1000,
 'first Server did not receive its free Console and Grand Opening')
assert(#R.GetLogs(city)==initialLogCount,'duplicate founding replayed one-time Server initialization')
R.ChangeReputation(city,32,'test');s=R.GetCityState(city)
assert(s.reputation==92 and s.band=='Legendary' and city.buildings[25]==1,'Legendary band failed')

local canFound=GameEvents.PlayerCanFoundCity.handlers[1]
local canTrain=GameEvents.PlayerCanTrain.handlers[1]
local cityCanTrain=GameEvents.CityCanTrain.handlers[1]
Players[0].gold=99;assert(not canFound(0,9,9),'second Server launch ignored its 100 Gold gate')
Players[0].gold=100;assert(canFound(0,9,9),'valid second Server launch was blocked')
city.pop=2;assert(not canTrain(0,10) and not cityCanTrain(0,1,10),'low-Population Server could train an Owner')
city.pop=10;assert(canTrain(0,10) and cityCanTrain(0,1,10),'eligible Server could not train an Owner')
Players[0].gold=1000

local ok,msg=R.PromoteModerator(0,1);assert(ok,msg)
ok,msg=R.PromoteModerator(0,1);assert(ok,msg)
ok,msg=R.PromoteAdministrator(0,1);assert(ok,msg)
s=R.GetCityState(city);assert(s.moderators==1 and s.admin==1 and Players[0].gold==675,'staff transaction failed')
assert(city.buildings[24]==1,'Moderator Culture dummy count failed')
assert(R.SetEvent(city,'CHEATER'));ok,msg=R.ResolveEvent(0,1,1);assert(ok,msg)
s=R.GetCityState(city);assert(city.pop==9 and s.event=='' and s.reputation==100,'event outcome failed')
local network=R.GetNetworkState(0);assert(network.banned==1 and network.administrators==1)

city.pop=100;Game.current=1;R.OnPlayerTurn(0)
network=R.GetNetworkState(0)
assert(network.maxPopulation==100 and city.buildings[33]==1 and city.buildings[34]==1,'milestones failed')
assert(Players[0].gold==773,'10-player reward or Administrator upkeep failed')
local owner=NewUnit(1,10);Players[0].unitList={owner}
R.OnCityTrained(0,1,1,false,false);assert(city.pop==98,'Server Owner did not consume two Population')
R.OnCityTrained(0,1,1,true,false);assert(city.pop==96,'purchased Server Owner bypassed its Population cost')

local second=NewCity(0,2,5,5,1,'Survival Server',2);second.buildings[20]=0
Players[0].cityList[#Players[0].cityList+1]=second;PutCity(second)
Game.current=2;R.OnCityFounded(0,5,5)
local secondState=R.GetCityState(second)
assert(Players[0].gold==673 and second.buildings[20]==1,'launch fee or free Console failed')
assert(secondState.reputation==60 and secondState.opening and second.buildings[31]==1,'Grand Opening failed')
second.pop=20;GameEvents.SetPopulation.handlers[1](5,5,1,20)
assert(second.buildings[21]==10 and second.buildings[22]==5 and second.buildings[23]==4,
 'SetPopulation did not resolve the changed City from x/y')
second.pop=1;GameEvents.SetPopulation.handlers[1](5,5,20,1)
Players[0].gold=199;assert(not canFound(0,9,9),'third Server launch ignored its 200 Gold gate')
Players[0].gold=200;assert(canFound(0,9,9),'valid third Server launch was blocked')
Players[0].gold=673
Players[0].capitalID=2;GameEvents.CapitalChanged.handlers[1](0,2,1)
assert(city.buildings[30]==0 and second.buildings[30]==1,'Owner Online did not follow a Capital change')
Players[0].capitalID=1;GameEvents.CapitalChanged.handlers[1](0,1,2)
assert(city.buildings[30]==1 and second.buildings[30]==0,'Owner Online did not return to the restored Capital')

local replacement=NewCity(0,2,8,8,4,'Replacement Server',99);Players[0].cityList[2]=replacement;PutCity(replacement)
assert(R.GetCityState(replacement).reputation==50,'refounded City inherited old Server state')
local roster=R.GetRoster(city);assert(#roster==12 and roster[1].role=='Administrator','Player roster roles failed')

-- A pending incident cannot be overwritten, and paid responses cannot resolve for free.
Players[0].gold=49
assert(R.SetEvent(replacement,'GRIEFER'))
assert(not R.SetEvent(replacement,'CRASH') and R.GetCityState(replacement).event=='GRIEFER','pending incident was overwritten')
ok,msg=R.ResolveEvent(0,2,nil);assert(not ok and R.GetCityState(replacement).event=='GRIEFER','invalid event choice crashed or resolved')
ok,msg=R.ResolveEvent(0,2,1);assert(not ok and Players[0].gold==49 and R.GetCityState(replacement).event=='GRIEFER',msg)
Players[0].gold=50;ok,msg=R.ResolveEvent(0,2,1);assert(ok and Players[0].gold==0 and R.GetCityState(replacement).event=='',msg)
replacement.production=49;assert(R.SetEvent(replacement,'DUPLICATION'))
ok,msg=R.ResolveEvent(0,2,1);assert(not ok and replacement.production==49 and R.GetCityState(replacement).event=='DUPLICATION',msg)
replacement.production=50;ok,msg=R.ResolveEvent(0,2,1);assert(ok and replacement.production==0,msg)

-- Invalid staff actions preserve the incident instead of falling through to another choice.
assert(R.SetEvent(replacement,'CIVIL_WAR'))
ok,msg=R.ResolveEvent(0,2,2);assert(not ok and R.GetCityState(replacement).event=='CIVIL_WAR',msg)
ok,msg=R.ResolveEvent(0,2,3);assert(ok and R.GetCityState(replacement).event=='',msg)

-- Staff is clamped after severe Population loss; an Administrator can still handle griefing.
city.pop=1;s=R.GetCityState(city)
assert(s.moderators==0 and s.admin==1,'staff count exceeded the remaining Player roster')
assert(R.SetEvent(city,'GRIEFER'));ok,msg=R.ResolveEvent(0,1,2);assert(ok,msg)
assert(R.SetEvent(city,'CHEATER'));ok,msg=R.ResolveEvent(0,1,1)
assert(not ok and R.GetCityState(city).event=='CHEATER','one-Player Server allowed a free ban')
ok,msg=R.ResolveEvent(0,1,2);assert(ok,msg)

-- AI Administrators fall back from an unaffordable preferred response instead of deadlocking.
R.ChangeReputation(city,-100,'AI fallback setup')
local researchBefore=Players[0].research
Players[0].human=false;Game.current=7
Game.Rand=function(maximum,label)if label=='RomanGladius incident choice' then return 3 else return 0 end end
R.OnPlayerTurn(0)
assert(R.GetCityState(city).event=='' and Players[0].research==researchBefore+45,
 'AI failed to choose an affordable fallback for a Duplication Exploit')
Players[0].human=true;Game.Rand=function()return 99 end

-- Capture and recapture reset the new owner's state and strip foreign dummy effects.
second.owner=1;GameEvents.CityCaptureComplete.handlers[1](0,false,5,5,1,1,true)
assert((second.buildings[21] or 0)==0 and (second.buildings[31] or 0)==0,
 'foreign capture retained RomanGladius dummy effects')
second.owner=0;GameEvents.CityCaptureComplete.handlers[1](1,false,5,5,0,1,true)
local captured=R.GetCityState(second)
assert(captured.reputation==40 and captured.moderators==0 and captured.admin==0 and captured.event=='','Roman recapture kept stale Server state')
print('PASS RomanGladius Lua runtime: gating, purchases, events, staff clamps, capture, founding, roster, and identity')
''')

    # When CP/VP already removes one Population from a produced Settler, Lua removes only the second.
    lua.execute(r'''
MapModData={};BUILT_IN_SETTLER_POPULATION=true
local compat=NewCity(0,3,12,12,5,'Compatibility Server',3)
Players[0].cityList={compat};PutCity(compat)
local compatOwner=NewUnit(2,10);Players[0].unitList={compatOwner}
''')
    lua.execute(source)
    lua.execute(r'''
local R=MapModData.RomanGladiusNetwork
local city=Players[0].cityList[1]
city.pop=city.pop-1 -- the enabled CP rule consumes the first Player
R.OnCityTrained(0,3,2,false,false)
assert(city.pop==3,'CP Settler Population compatibility charged more or less than two Players')
city.pop=5;R.OnCityTrained(0,3,2,true,false)
assert(city.pop==3,'purchased Owner did not pay the full two-Player cost under CP compatibility')
 print('PASS RomanGladius CP Settler Population compatibility')
 ''')

    # Scenario/Advanced Start cities present before Lua loads receive the same
    # one-time setup without launch fees, and captured cities remain at 40 Rep.
    lua.execute(r'''
MapModData={};BUILT_IN_SETTLER_POPULATION=false;Game.current=30
GameEvents={PlayerDoTurn=event(),PlayerCityFounded=event(),CityTrained=event(),PlayerCanTrain=event(),
 CityCanTrain=event(),PlayerCanFoundCity=event(),CityCaptureComplete=event(),CityConstructed=event(),
 SetPopulation=event(),CapitalChanged=event()}
local preA=NewCity(0,10,50,50,6,'Preplaced A',30);preA.buildings[20]=0
local preB=NewCity(0,11,52,50,7,'Preplaced B',30);preB.buildings[20]=0
local foreign=NewCity(1,12,54,50,5,'Foreign Server',30);foreign.buildings[20]=0
Players[0].cityList={preA,preB};Players[0].capitalID=10;Players[0].gold=777
Players[1].cityList={foreign};PutCity(preA);PutCity(preB);PutCity(foreign)
''')
    lua.execute(source)
    lua.execute(r'''
local R=MapModData.RomanGladiusNetwork
local a,b=Players[0].cityList[1],Players[0].cityList[2]
assert(R.GetCityState(a).reputation==60 and R.GetCityState(b).reputation==60
 and a.buildings[20]==1 and b.buildings[20]==1 and a.buildings[31]==1 and b.buildings[31]==1,
 'preplaced Roman Servers missed full one-time initialization')
assert(Players[0].gold==777 and #R.GetLogs(a)==1 and #R.GetLogs(b)==1,
 'preplaced initialization charged launch fees or duplicated logs')
assert(not R.InitializeRomanServerCity(a,false) and #R.GetLogs(a)==1,
 'preplaced initialization was not idempotent across reload')
local captured=Players[1].cityList[1];captured.owner=0;Players[0].cityList[#Players[0].cityList+1]=captured
GameEvents.CityCaptureComplete.handlers[1](1,false,54,50,0,5,true)
assert(R.GetCityState(captured).reputation==40 and not R.InitializeRomanServerCity(captured,false),
 'captured Roman Server replayed founding rewards')
print('PASS RomanGladius preplaced/reload/capture initialization')
''')


def main() -> None:
    static_checks()
    runtime_checks()


if __name__ == "__main__":
    main()
