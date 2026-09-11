"""Validate Luna packaging, art, Lua behavior, and SQL against BNW + CP."""
from __future__ import annotations

import argparse
import hashlib
import re
import sqlite3
import struct
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

from build_mod import REPO, NS, create_manifest, package_name, read_project
from validate_mod import apply_current_cp_schema

ROOT = REPO / "LunaNetwork"
PREFIX = "LunaNetwork/"

sys.path.insert(0, str(REPO / ".tools" / "python"))


def check_packaging() -> None:
    _, props, values, project_files = read_project()
    files = [(name.removeprefix(PREFIX), imported)
             for name, imported in project_files if name.startswith(PREFIX)]
    names = {name for name, _ in files}
    actual = {
        path.relative_to(ROOT).as_posix()
        for folder in ("SQL", "Lua", "Art")
        for path in (ROOT / folder).rglob("*")
        if path.is_file() and path.suffix.lower() in (".sql", ".lua", ".xml", ".dds")
    }
    assert len(names) == len(files), "Duplicate project content"
    assert actual == names, f"Project/package file mismatch: {actual ^ names}"
    assert all((ROOT / name).is_file() for name in names), "Project contains missing files"
    for name, imported in files:
        if name.endswith(".sql"):
            assert not imported, f"Database SQL imported into VFS: {name}"
        elif name.endswith(".lua") or name.startswith("Art/"):
            assert imported, f"Runtime/art missing VFS import: {name}"
    actions = [e.text.removeprefix(PREFIX).replace("\\", "/")
               for e in props.findall("m:ModActions/m:Action/m:FileName", NS)
               if e.text.startswith(PREFIX)]
    assert actions == sorted(name for name in names if name.endswith(".sql")), "SQL actions missing or unordered"
    entries = [e.text.removeprefix(PREFIX)
               for e in props.findall("m:ModContent/m:Content/m:FileName", NS)
               if e.text.startswith(PREFIX)]
    assert entries == ["Lua/LunaLowLatency.lua"], "Luna runtime must have one direct InGameUIAddin entry"
    dependencies = {e.text for e in props.findall("m:ModDependencies/m:Association/m:Id", NS)}
    assert "d1b6328c-ff44-4b0d-aad7-c657f83610cd" in dependencies, "Missing CP dependency"
    assert values["SupportsMultiplayer"] == "false" and values["SupportsHotSeat"] == "false"

    manifest = ET.parse(REPO / f"{package_name()}.modinfo").getroot()
    expected = create_manifest().getroot()
    assert ET.tostring(manifest) == ET.tostring(expected), "Stale Luna manifest"
    for item in manifest.findall("Files/File"):
        source = REPO / item.text.replace("\\", "/")
        assert item.attrib["md5"].lower() == hashlib.md5(source.read_bytes()).hexdigest(), f"Stale hash: {source}"
    print(f"PASS Luna project + manifest: {len(files)} files, runtime entry wired")


def check_art_and_lua_syntax() -> None:
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval("function(source, name) local f, err=loadstring(source, name); return f~=nil, err end")
    source = (ROOT / "Lua/LunaLowLatency.lua").read_text(encoding="utf-8-sig")
    passed, message = compile_lua(source, "LunaLowLatency.lua")
    assert passed, message
    scene = ET.parse(ROOT / "Art/LunaLeaderScene.xml").getroot()
    assert scene.attrib.get("FallbackImage") == "LunaLeader.dds"
    for path in (ROOT / "Art").glob("*.dds"):
        header = path.read_bytes()[:128]
        assert len(header) == 128 and header[:4] == b"DDS ", f"Bad DDS: {path}"
        height, width = struct.unpack_from("<II", header, 12)
        assert width > 0 and height > 0
        if path.name == "LunaLeader.dds":
            assert (width, height) == (1600, 900)
    print("PASS Luna Lua 5.1 syntax, leader scene, and DDS headers")


def remove_luna_rows(database: sqlite3.Connection) -> None:
    tables = [r[0] for r in database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    for table in tables:
        columns = [r[1] for r in database.execute(f"PRAGMA table_info({quote(table)})")]
        predicate = " OR ".join(f"CAST({quote(column)} AS TEXT) LIKE '%LUNA%'" for column in columns)
        if predicate:
            try:
                database.execute(f"DELETE FROM {quote(table)} WHERE {predicate}")
            except sqlite3.OperationalError:
                pass


def quote(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def check_database(path: Path, cp_root: Path) -> None:
    assert path.is_file(), f"No gameplay cache at {path}"
    source = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    database = sqlite3.connect(":memory:")
    source.backup(database)
    source.close()
    database.row_factory = sqlite3.Row
    apply_current_cp_schema(database, cp_root)
    remove_luna_rows(database)
    database.execute("CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)")
    for sql_path in sorted((ROOT / "SQL").glob("*.sql")):
        database.executescript(sql_path.read_text(encoding="utf-8-sig"))

    def row(table: str, item_type: str):
        result = database.execute(f"SELECT * FROM {quote(table)} WHERE Type=?", (item_type,)).fetchone()
        assert result is not None, f"Missing {item_type}"
        return result

    civ = row("Civilizations", "CIVILIZATION_GPT_LUNA")
    assert (civ["Playable"], civ["AIPlayable"]) == (1, 0), "Luna must be human-only"
    america_units = {tuple(r) for r in database.execute(
        "SELECT UnitClassType,UnitAIType,Count FROM Civilization_FreeUnits WHERE CivilizationType='CIVILIZATION_AMERICA'")}
    luna_units = {tuple(r) for r in database.execute(
        "SELECT UnitClassType,UnitAIType,Count FROM Civilization_FreeUnits WHERE CivilizationType='CIVILIZATION_GPT_LUNA'")}
    assert luna_units == america_units and luna_units, "Luna did not inherit normal starting units"

    settler = row("Units", "UNIT_SETTLER")
    packet = row("Units", "UNIT_LUNA_PACKET_SETTLER")
    assert packet["Cost"] == settler["Cost"] * 90 // 100
    assert packet["Moves"] == settler["Moves"] + 1
    library = row("Buildings", "BUILDING_LIBRARY")
    cache = row("Buildings", "BUILDING_LUNA_CACHE_NODE")
    assert cache["Cost"] == library["Cost"] * 85 // 100
    for field in ("BuildingClass", "PrereqTech", "GoldMaintenance"):
        assert cache[field] == library[field], f"Cache Node lost {field}"

    mappings = (("Unit_AITypes", "UnitType", "UNIT_SETTLER", "UNIT_LUNA_PACKET_SETTLER"),
                ("Unit_Builds", "UnitType", "UNIT_SETTLER", "UNIT_LUNA_PACKET_SETTLER"),
                ("Unit_Flavors", "UnitType", "UNIT_SETTLER", "UNIT_LUNA_PACKET_SETTLER"),
                ("Building_YieldChangesPerPop", "BuildingType", "BUILDING_LIBRARY", "BUILDING_LUNA_CACHE_NODE"),
                ("Building_Flavors", "BuildingType", "BUILDING_LIBRARY", "BUILDING_LUNA_CACHE_NODE"))
    for table, column, base, unique in mappings:
        base_count = database.execute(f"SELECT COUNT(*) FROM {quote(table)} WHERE {quote(column)}=?", (base,)).fetchone()[0]
        unique_count = database.execute(f"SELECT COUNT(*) FROM {quote(table)} WHERE {quote(column)}=?", (unique,)).fetchone()[0]
        if table == "Building_Flavors":
            assert unique_count >= base_count
        else:
            assert unique_count == base_count, f"{unique} lost rows in {table}"
    base_prod = database.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType='BUILDING_LIBRARY' AND YieldType='YIELD_PRODUCTION'").fetchone()[0]
    cache_prod = database.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType='BUILDING_LUNA_CACHE_NODE' AND YieldType='YIELD_PRODUCTION'").fetchone()[0]
    assert cache_prod == base_prod + 1
    promotion = row("UnitPromotions", "PROMOTION_LUNA_RAPID_RESPONSE")
    assert promotion["MovesChange"] == 1 and promotion["LostWithUpgrade"] == 0 and promotion["CannotBeChosen"] == 1
    assert database.execute("SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType='CIVILIZATION_GPT_LUNA'").fetchone()[0] == 35
    assert database.execute("SELECT COUNT(*) FROM Civilization_SpyNames WHERE CivilizationType='CIVILIZATION_GPT_LUNA'").fetchone()[0] == 10

    translated = {r[0] for r in database.execute("SELECT Tag FROM Language_en_US")}
    unresolved = set()
    for table in ("Civilizations", "Leaders", "Units", "Buildings", "UnitPromotions", "Traits"):
        for item in database.execute(f"SELECT * FROM {quote(table)} WHERE Type LIKE '%LUNA%'"):
            for field in ("Description", "ShortDescription", "Adjective", "Civilopedia", "Strategy", "Help", "DawnOfManQuote"):
                if field in item.keys() and isinstance(item[field], str) and item[field].startswith("TXT_KEY_") and item[field] not in translated:
                    unresolved.add(item[field])
    assert not unresolved, f"Missing Luna localization: {sorted(unresolved)}"
    assert database.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    print("PASS Luna SQL against BNW + installed CP: inheritance, costs, AI exclusion, metadata, localization")
    database.close()


def check_lua_behavior() -> None:
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
MapModData = {}
GameInfoTypes = {CIVILIZATION_GPT_LUNA=10, UNIT_LUNA_PACKET_SETTLER=11, PROMOTION_LUNA_RAPID_RESPONSE=12}
DomainTypes = {DOMAIN_LAND=1, DOMAIN_SEA=2, DOMAIN_AIR=3}
GameInfo = {Buildings={}, BuildingClasses={}}
GameInfo.BuildingClasses.NORMAL={MaxGlobalInstances=-1,MaxTeamInstances=-1,MaxPlayerInstances=-1}
GameInfo.BuildingClasses.WONDER={MaxGlobalInstances=1,MaxTeamInstances=-1,MaxPlayerInstances=-1}
GameInfo.Buildings[20]={Cost=300,BuildingClass='NORMAL'}
GameInfo.Buildings[21]={Cost=500,BuildingClass='WONDER'}
local storage={}
Modding={OpenSaveData=function() return {GetValue=function(k)return storage[k]end,SetValue=function(k,v)storage[k]=v end} end}
Game={turn=5,GetGameTurn=function()return Game.turn end}
local function event() local e={handlers={}}; e.Add=function(f)e.handlers[#e.handlers+1]=f end; return e end
GameEvents={PlayerDoTurn=event(),CityTrained=event(),CityConstructed=event(),CityCaptureComplete=event(),UnitCreated=event(),UnitConverted=event()}
function NewCity(id)
 local c={id=id,x=id,y=id,production=0,unit=-1,building=-1,project=-1,unitCost=200,buildingCost=300}
 function c:GetID()return self.id end; function c:GetX()return self.x end; function c:GetY()return self.y end
 function c:GetProductionUnit()return self.unit end; function c:GetProductionBuilding()return self.building end
 function c:GetProductionProject()return self.project end; function c:ChangeProduction(n)self.production=self.production+n end
 function c:GetUnitProductionNeeded()return self.unitCost end; function c:GetBuildingProductionNeeded()return self.buildingCost end
 return c
end
function NewUnit(id,kind,domain,military)
 local u={id=id,kind=kind,domain=domain,military=military,promotions={}}
 function u:GetUnitType()return self.kind end; function u:GetDomainType()return self.domain end
 function u:IsCombatUnit()return self.military end; function u:SetHasPromotion(p,v)self.promotions[p]=v end
 function u:IsHasPromotion(p)return self.promotions[p]==true end
 return u
end
city=NewCity(1); player={cities={[1]=city},units={},alive=true,civ=10}
function player:IsAlive()return self.alive end; function player:GetCivilizationType()return self.civ end
function player:GetCityByID(id)return self.cities[id] end; function player:GetUnitByID(id)return self.units[id] end
Players={[0]=player}
''')
    lua.execute((ROOT / "Lua/LunaLowLatency.lua").read_text(encoding="utf-8-sig"))
    lua.execute(r'''
local L=MapModData.LunaNetwork
city.building=20
player.units[1]=NewUnit(1,30,DomainTypes.DOMAIN_LAND,true)
L.OnCityTrained(0,1,1,false,false)
assert(city.production==20,'military refund must use 10% current production requirement')
assert(player.units[1]:IsHasPromotion(12),'land unit missing Rapid Response')
Game.turn=6; L.OnPlayerTurn(0); assert(player.units[1]:IsHasPromotion(12),'Rapid Response expired after one turn')
Game.turn=7; L.OnPlayerTurn(0); assert(not player.units[1]:IsHasPromotion(12),'Rapid Response did not expire after two turns')

city.production=0
player.units[2]=NewUnit(2,31,DomainTypes.DOMAIN_SEA,true)
L.OnCityTrained(0,1,2,true,false)
assert(city.production==0 and not player.units[2]:IsHasPromotion(12),'Gold purchase triggered Low Latency')

city.building=-1; city.unit=-1; city.project=-1; city.production=0
L.OnCityConstructed(0,1,20,false,false)
assert(city.production==0 and L.GetState(0).cities[1].pending==30,'empty queue did not retain refund')
city.building=20; L.OnPlayerTurn(0)
assert(city.production==30 and L.GetState(0).cities[1].pending==0,'pending production was not applied once')
L.OnPlayerTurn(0); assert(city.production==30,'pending production applied twice')

city.production=0; L.OnCityConstructed(0,1,21,false,false)
assert(city.production==0,'World Wonder generated refund')
player.units[3]=NewUnit(3,32,DomainTypes.DOMAIN_AIR,true)
L.OnCityTrained(0,1,3,false,false)
assert(city.production==20 and not player.units[3]:IsHasPromotion(12),'air unit refund/deployment rules incorrect')

city.building=-1; city.production=0; L.OnCityConstructed(0,1,20,false,false)
assert(L.GetState(0).cities[1].pending==30)
L.OnCityCaptureComplete(0,false,1,1,1)
assert(L.GetState(0).cities[1]==nil,'captured city retained pending production')

city.building=20; player.units[4]=NewUnit(4,33,DomainTypes.DOMAIN_LAND,true)
Game.turn=10; L.OnCityTrained(0,1,4,false,false)
player.units[5]=NewUnit(5,33,DomainTypes.DOMAIN_LAND,true)
L.OnUnitConverted(0,0,4,5,true)
assert(L.GetState(0).units[4]==nil and L.GetState(0).units[5]==12,'upgrade did not transfer expiration')
''')
    print("PASS Luna Lua mock: refunds, purchases, pending cache, wonders, air units, timer, capture, upgrade")


def main() -> None:
    user_game = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=user_game / "cache_backup/Civ5DebugDatabase.db")
    parser.add_argument("--cp-root", type=Path, default=user_game / "MODS/(1) Community Patch")
    args = parser.parse_args()
    check_packaging()
    check_art_and_lua_syntax()
    check_database(args.database, args.cp_root)
    check_lua_behavior()
    print("Luna validation passed. Final Civ V animation/UI timing still requires an in-game smoke test.")


if __name__ == "__main__":
    main()
