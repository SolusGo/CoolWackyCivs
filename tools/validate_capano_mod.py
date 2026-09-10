"""Validate Capano SQL, project/manifest wiring, art, and Lua 5.1 syntax."""
from __future__ import annotations

import argparse
import re
import sqlite3
import struct
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

from build_capano_mod import ROOT, REPO, NS, create_manifest, package_name, read_project
from validate_mod import apply_current_cp_schema

sys.path.insert(0, str(REPO / ".tools" / "python"))


def quote(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def prepare_database(path: Path, cp_root: Path) -> sqlite3.Connection:
    source = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    database = sqlite3.connect(":memory:")
    source.backup(database)
    source.close()
    apply_current_cp_schema(database, cp_root)
    # Some cache backups predate CP-created companion relations. Recreate only
    # official table shapes in this disposable validation database.
    for xml_path in sorted((cp_root / "Database Changes").rglob("*.xml")):
        try:
            tree = ET.parse(xml_path)
        except ET.ParseError:
            continue
        for table in tree.findall("Table"):
            name = table.get("name")
            if not name or not (name.startswith("Building_") or name.startswith("Unit_")
                                or name in {"DiploModifiers"}):
                continue
            columns = []
            for column in table.findall("Column"):
                default = column.get("default")
                default_sql = "" if default is None else " DEFAULT '" + default.replace("'", "''") + "'"
                columns.append(quote(column.get("name")) + " " + column.get("type", "text") + default_sql)
            if columns:
                database.execute(f"CREATE TABLE IF NOT EXISTS {quote(name)}({','.join(columns)})")
    database.execute("CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)")
    return database


def database_checks(path: Path, cp_root: Path) -> None:
    assert path.is_file(), f"No gameplay cache at {path}"
    database = prepare_database(path, cp_root)
    database.row_factory = sqlite3.Row
    for sql_path in sorted((ROOT / "SQL").glob("*.sql")):
        try:
            database.executescript(sql_path.read_text(encoding="utf-8-sig"))
        except sqlite3.Error as error:
            raise RuntimeError(f"{sql_path.name}: {error}") from error

    def one(sql: str):
        return database.execute(sql).fetchone()[0]

    assert one("SELECT COUNT(*) FROM Civilizations WHERE Type='CIVILIZATION_CAPANO_CIRCUIT'") == 1
    assert one("SELECT Playable FROM Civilizations WHERE Type='CIVILIZATION_CAPANO_CIRCUIT'") == 1
    assert one("SELECT AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_CAPANO_CIRCUIT'") == 1
    worker = database.execute("SELECT * FROM Units WHERE Type='UNIT_WORKER'").fetchone()
    setter = database.execute("SELECT * FROM Units WHERE Type='UNIT_CAPANO_ROUTE_SETTER'").fetchone()
    assert setter and setter["Moves"] == 3 and setter["WorkRate"] == worker["WorkRate"]
    assert one("SELECT COUNT(*) FROM Unit_Builds WHERE UnitType='UNIT_CAPANO_ROUTE_SETTER' AND BuildType='BUILD_CAPANO_BOULDER_SECTOR'") == 1
    worker_builds = {row[0] for row in database.execute("SELECT BuildType FROM Unit_Builds WHERE UnitType='UNIT_WORKER'")}
    setter_builds = {row[0] for row in database.execute("SELECT BuildType FROM Unit_Builds WHERE UnitType='UNIT_CAPANO_ROUTE_SETTER'")}
    assert worker_builds <= setter_builds

    armory = database.execute("SELECT * FROM Buildings WHERE Type='BUILDING_ARMORY'").fetchone()
    centre = database.execute("SELECT * FROM Buildings WHERE Type='BUILDING_CAPANO_COMPETITION_CENTRE'").fetchone()
    for column in ("Cost", "GoldMaintenance", "Experience", "PrereqTech", "BuildingClass"):
        assert centre[column] == armory[column], f"Armory inheritance lost {column}"
    for yield_type in ("YIELD_SCIENCE", "YIELD_CULTURE"):
        base = one(f"SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType='BUILDING_ARMORY' AND YieldType='{yield_type}'")
        unique = one(f"SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE' AND YieldType='{yield_type}'")
        assert unique == base + 2

    assert one("SELECT NoTwoAdjacent FROM Improvements WHERE Type='IMPROVEMENT_CAPANO_BOULDER_SECTOR'") == 1
    assert one("SELECT COUNT(*) FROM Improvement_Yields WHERE ImprovementType='IMPROVEMENT_CAPANO_BOULDER_SECTOR'") == 3
    assert one("SELECT COUNT(*) FROM Improvement_TechYieldChanges WHERE ImprovementType='IMPROVEMENT_CAPANO_BOULDER_SECTOR'") == 5
    assert one("SELECT WorkRateMod FROM UnitPromotions WHERE Type='PROMOTION_CAPANO_SETTER_HILLS_WORK'") == 25
    assert one("SELECT AttackMod FROM UnitPromotions WHERE Type='PROMOTION_CAPANO_BETA_ATTACK_20'") == 20
    assert one("SELECT CombatPercent FROM UnitPromotions WHERE Type='PROMOTION_CAPANO_AWKWARD_PURPLE'") == -12
    assert one("SELECT MovesChange FROM UnitPromotions WHERE Type='PROMOTION_CAPANO_COMPLETE_CLIMBER'") == 1
    assert one("SELECT IgnoreZOC FROM UnitPromotions WHERE Type='PROMOTION_CAPANO_COMPLETE_HILLS'") == 1
    assert one("SELECT COUNT(*) FROM DiploModifiers WHERE Type LIKE 'DIPLOMODIFIER_CAPANO_%'") == 3
    assert one("SELECT Flavor FROM Leader_Flavors WHERE LeaderType='LEADER_ENRICO_CAPANO' AND FlavorType='FLAVOR_TILE_IMPROVEMENT'") == 10
    for option in ("EVENTS_BATTLES", "EVENTS_DIPLO_MODIFIERS", "EVENTS_PLOT", "EVENTS_PLAYER_TURN"):
        assert one(f"SELECT Value FROM CustomModOptions WHERE Name='{option}'") == 1

    localized = {row[0] for row in database.execute("SELECT Tag FROM Language_en_US")}
    unresolved = set()
    for sql_path in (ROOT / "SQL").glob("*.sql"):
        for tag in re.findall(r"'((?:TXT_KEY_)[^']*CAPANO[^']*)'", sql_path.read_text(encoding="utf-8-sig")):
            if tag.endswith("%"):
                if not any(candidate.startswith(tag[:-1]) for candidate in localized):
                    unresolved.add(tag)
            elif tag not in localized:
                unresolved.add(tag)
    assert not unresolved, f"Missing Capano localization: {sorted(unresolved)}"
    assert database.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    database.close()
    print("PASS SQL: CP schema, inheritance, exact yields/promotions, improvement, AI and localization")


def packaging_checks() -> None:
    _, props, values, files = read_project()
    expected = {name for name, _ in files}
    actual = {path.relative_to(ROOT).as_posix() for folder in ("SQL", "Lua", "Art")
              for path in (ROOT / folder).rglob("*")
              if path.is_file() and path.suffix.lower() in {".sql", ".lua", ".xml", ".dds"}}
    assert actual == expected, f"Project/package mismatch: {sorted(actual ^ expected)}"
    assert ET.tostring(ET.parse(ROOT / f"{package_name()}.modinfo").getroot()) == ET.tostring(create_manifest().getroot())
    actions = [node.text.replace("\\", "/") for node in props.findall("m:ModActions/m:Action/m:FileName", NS)]
    assert actions == sorted(name for name in expected if name.endswith(".sql"))
    assert values["SupportsMultiplayer"] == "false"
    assert "d1b6328c-ff44-4b0d-aad7-c657f83610cd" in {
        node.text for node in props.findall("m:ModDependencies/m:Association/m:Id", NS)}
    solution = (REPO / "CapanoCircuit.civ5sln").read_text(encoding="utf-8-sig")
    assert values["ProjectGuid"] in solution and "F5FC21B5-7CC2-458A-ABBA-992F515BBA20" in solution

    for path in (ROOT / "Art").glob("*.dds"):
        header = path.read_bytes()[:128]
        assert len(header) == 128 and header[:4] == b"DDS " and header[84:88] != b"DX10"
        height, width = struct.unpack_from("<II", header, 12)
        if path.name == "CapanoLeader.dds": assert (width, height) == (1600, 900)
        elif path.name == "CapanoMap.dds": assert (width, height) == (360, 412)
        elif path.name.startswith("CapanoObjects"):
            size = int(re.search(r"(\d+)\.dds$", path.name).group(1))
            assert (width, height) == (size * 14, size)
        else:
            size = int(re.search(r"(\d+)\.dds$", path.name).group(1))
            assert (width, height) == (size, size)

    from lupa.lua51 import LuaRuntime
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval("function(source) local f,e=loadstring(source); return f~=nil,e end")
    for path in (ROOT / "Lua").glob("*.lua"):
        ok, error = compile_lua(path.read_text(encoding="utf-8-sig"))
        assert ok, error
    lua.execute((REPO / "tools/tests/capano_mock.lua").read_text(encoding="utf-8-sig"))
    lua.execute((ROOT / "Lua/CapanoRuntime.lua").read_text(encoding="utf-8-sig"))
    lua.execute((REPO / "tools/tests/capano_assertions.lua").read_text(encoding="utf-8-sig"))
    print(f"PASS packaging: {len(files)} files, manifest/project/solution, legacy DDS geometry, Lua 5.1 behavior")


if __name__ == "__main__":
    user = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=user / "cache_backup/Civ5DebugDatabase.db")
    parser.add_argument("--cp-root", type=Path, default=user / "MODS/(1) Community Patch")
    args = parser.parse_args()
    database_checks(args.database, args.cp_root)
    packaging_checks()
    print("Capano validation passed. Final gameplay and visuals still require an in-game smoke test.")
