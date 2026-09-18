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
    assert "UNITCLASS_SETTLER','UNIT_ROMAN_GLADIUS_SERVER_OWNER" in core
    assert "BUILDINGCLASS_MONUMENT','BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE" in core
    assert "('BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE','YIELD_CULTURE',2)" in effects
    assert "('BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE','YIELD_GOLD',1)" in effects
    assert "('UNIT_SETTLER', 'UNIT_ROMAN_GLADIUS_SERVER_OWNER')" in inheritance
    assert "('BUILDING_MONUMENT', 'BUILDING_ROMAN_GLADIUS_SERVER_CONSOLE')" in inheritance
    for token in ("R.PromoteModerator", "R.PromoteAdministrator", "R.ResolveEvent", "R.GetRoster",
                  "R.GetServers", "R.GetNetworkState", "PlayerCityFounded", "PlayerCanFoundCity"):
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
 CityPopulationChanged=event(),CapitalChanged=event()}
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
Game={current=0,GetGameTurn=function()return Game.current end,Rand=function()return 99 end,
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
 function c:ChangeFood(n)self.food=self.food+n end
 return c
end
function NewPlayer(id,civ)
 local p={id=id,civ=civ,alive=true,human=id==0,gold=1000,culture=0,research=0,cityList={},unitList={}}
 function p:IsAlive()return self.alive end; function p:IsHuman()return self.human end
 function p:GetCivilizationType()return self.civ end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:GetCapitalCity()return self.cityList[1] end
 function p:GetGold()return self.gold end; function p:ChangeGold(n)self.gold=self.gold+n end
 function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:ChangeOverflowResearch(n)self.research=self.research+n end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id then return u end end end
 function p:AddNotification()end
 return p
end
function NewUnit(id,kind)local u={id=id,kind=kind};function u:GetUnitType()return self.kind end;return u end
Players={[0]=NewPlayer(0,1),[1]=NewPlayer(1,99)}
local capital=NewCity(0,1,0,0,10,'Main Server',0);Players[0].cityList={capital}
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
 and #GameEvents.CityTrained.handlers==1 and #GameEvents.PlayerCanTrain.handlers==1,
 'runtime handlers missing or duplicated')
assert(city.buildings[21]==5 and city.buildings[22]==2 and city.buildings[23]==2,
 'population threshold yields are incorrect')
assert(city.buildings[30]==1,'Owner Online is missing from the Capital')
local s=R.GetCityState(city);assert(s.reputation==50 and s.band=='Stable' and s.hasConsole)
R.ChangeReputation(city,42,'test');s=R.GetCityState(city)
assert(s.reputation==92 and s.band=='Legendary' and city.buildings[25]==1,'Legendary band failed')
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

local second=NewCity(0,2,5,5,1,'Survival Server',2);second.buildings[20]=0
Players[0].cityList[#Players[0].cityList+1]=second;PutCity(second)
Game.current=2;R.OnCityFounded(0,5,5)
local secondState=R.GetCityState(second)
assert(Players[0].gold==673 and second.buildings[20]==1,'launch fee or free Console failed')
assert(secondState.reputation==60 and secondState.opening and second.buildings[31]==1,'Grand Opening failed')

local replacement=NewCity(0,2,8,8,4,'Replacement Server',99);Players[0].cityList[2]=replacement;PutCity(replacement)
assert(R.GetCityState(replacement).reputation==50,'refounded City inherited old Server state')
local roster=R.GetRoster(city);assert(#roster==12 and roster[1].role=='Administrator','Player roster roles failed')
print('PASS RomanGladius Lua runtime: yields, reputation, staff, events, milestones, founding, roster, and identity')
''')


def main() -> None:
    static_checks()
    runtime_checks()


if __name__ == "__main__":
    main()
