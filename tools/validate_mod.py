"""Validate packaging, UI wiring, Lua 5.1 syntax and actual Civ V/CP SQL.

The gameplay cache is opened read-only and backed up to memory. It is never
edited. Use --database to supply another BNW + Community Patch debug cache.
"""
from __future__ import annotations

import argparse
import hashlib
import re
import sqlite3
import struct
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

from build_mod import ROOT, REPO, NS, read_project, create_manifest, package_name

sys.path.insert(0, str(REPO / ".tools" / "python"))


def check_packaging():
    tree, props, values, files = read_project()
    names = {name for name, _ in files}
    assert len(names) == len(files), "Duplicate project content"
    assert all((ROOT / name).is_file() for name in names), "Project contains missing files"
    civ_roots = ("RoulsAscendancy", "LunaNetwork", "TerraFramework", "CapanoCircuit")
    actual = {
        p.relative_to(ROOT).as_posix()
        for folder in civ_roots
        for p in (ROOT / folder).rglob("*")
        if p.is_file() and p.suffix.lower() in (".sql", ".lua", ".xml", ".dds")
    }
    assert actual == names, f"Project/package file mismatch: {actual ^ names}"
    for name, imported in files:
        if name.endswith(".sql") or name == "RoulsAscendancy/UI/RoulsPanel.xml":
            assert not imported, f"Database SQL must not import into VFS: {name}"
        else:
            assert imported, f"Included runtime/art missing VFS import: {name}"
    actions = [e.text.replace("\\", "/") for e in props.findall("m:ModActions/m:Action/m:FileName", NS)]
    assert len(actions) == len(set(actions)), "SQL action registered more than once"
    expected_actions = [
        f"{folder}/SQL/{path.name}"
        for folder in civ_roots
        for path in sorted((ROOT / folder / "SQL").glob("*.sql"))
    ]
    assert actions == expected_actions, "SQL actions missing or out of order"
    entries = props.findall("m:ModContent/m:Content/m:FileName", NS)
    assert [e.text for e in entries] == [
        "RoulsAscendancy/UI/RoulsPanel.xml",
        "LunaNetwork/Lua/LunaLowLatency.lua",
        "TerraFramework/Lua/TerraRuntime.lua",
        "CapanoCircuit/Lua/CapanoRuntime.lua",
    ], "Combined runtime entry points are incomplete or out of order"
    assert values["SupportsMultiplayer"] == "false", "Unvalidated multiplayer must remain disabled"
    dependencies = props.findall("m:ModDependencies/m:Association/m:Id", NS)
    assert "d1b6328c-ff44-4b0d-aad7-c657f83610cd" in {e.text for e in dependencies}, "Missing CP dependency"
    checked_in = ET.parse(ROOT / f"{package_name()}.modinfo").getroot()
    expected = create_manifest().getroot()
    assert ET.tostring(checked_in) == ET.tostring(expected), "Stale .modinfo: run tools/build_mod.py --manifest-only"
    for file in checked_in.findall("Files/File"):
        source = ROOT / file.text.replace("\\", "/")
        assert file.attrib["md5"].lower() == hashlib.md5(source.read_bytes()).hexdigest(), f"Stale hash: {source}"
    modbuddy_manifest = REPO / "Build" / values["SafeName"] / f"{package_name()}.modinfo"
    if modbuddy_manifest.is_file():
        def file_signature(manifest):
            return {
                (node.text.replace("\\", "/"), node.get("md5", "").lower(), node.get("import"))
                for node in manifest.findall("Files/File")
            }
        assert file_signature(checked_in) == file_signature(ET.parse(modbuddy_manifest).getroot()), (
            "Official ModBuddy output differs from the checked-in manifest"
        )
    basenames = [Path(name).name.lower() for name in names]
    assert len(basenames) == len(set(basenames)), "VFS filename collision between civilizations"
    solution = (REPO / "CoolWackyCivs.civ5sln").read_text(encoding="utf-8-sig")
    assert '{F5FC21B5-7CC2-458A-ABBA-992F515BBA20}' in solution, "Wrong ModBuddy project factory"
    assert values["ProjectGuid"] in solution, "Solution/project GUID mismatch"
    print(f"PASS project + manifest: {len(files)} files, {len(actions)} ordered SQL actions")


def check_ui_and_lua():
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError as error:
        raise RuntimeError("Install requirements-dev.txt to run Lua 5.1 validation") from error
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval("function(source, name) local f, err=loadstring(source, name); return f~=nil, err end")
    project_files = [ROOT / name for name, _ in read_project()[3]]
    lua_files = [path for path in project_files if path.suffix.lower() == ".lua"]
    for path in lua_files:
        passed, message = compile_lua(path.read_text(encoding="utf-8-sig"), str(path))
        assert passed, message
    for path in (path for path in project_files if path.suffix.lower() == ".xml"):
        xml = ET.parse(path)
        controls = [e.attrib["ID"] for e in xml.iter() if "ID" in e.attrib]
        assert len(controls) == len(set(controls)), f"Duplicate control ID: {path}"
        paired_lua = path.with_suffix(".lua")
        if paired_lua.is_file():
            references = set(re.findall(r"Controls\.([A-Za-z0-9_]+)", paired_lua.read_text(encoding="utf-8-sig")))
            assert references <= set(controls), f"Missing XML controls: {references - set(controls)}"
        for element in xml.iter():
            if "Font" in element.attrib:
                assert element.attrib["Font"] in {"TwCenMT14", "TwCenMT16", "TwCenMT18", "TwCenMT20", "TwCenMT24"}, f"Unknown Civ5 font: {element.attrib['Font']}"
    for path in (path for path in project_files if path.suffix.lower() == ".dds"):
        header = path.read_bytes()[:128]
        assert len(header) == 128 and header[:4] == b"DDS ", f"Bad DDS: {path}"
        height, width = struct.unpack_from("<II", header, 12)
        assert width > 0 and height > 0, f"Empty DDS: {path}"
        if path.name == "RoulsLeader.dds":
            assert (width, height) == (1600, 900), "Static leader scene must be 1600x900"
    print(f"PASS XML/control wiring, DDS headers and Lua 5.1 syntax ({len(lua_files)} scripts)")


def quote(value):
    return '"' + value.replace('"', '""') + '"'


def apply_current_cp_schema(database, cp_root: Path):
    """Bring a stale disposable cache clone up to the installed CP table shape.

    Civ V rewrites its live cache whenever a different mod set is selected. The
    user's backup retains the CP-created relation tables, while these official
    ALTER files supply columns added by the currently installed CP release.
    """
    assert cp_root.is_dir(), f"Community Patch folder not found: {cp_root}"
    changes = (
        "Database Changes/City/Buildings/BuildingTableChanges.sql",
        "Database Changes/UnitPromotions/PromotionTableChanges.sql",
        "Database Changes/Units/UnitTableChanges.sql",
        "Database Changes/AI/LeaderTableChanges.sql",
        "Database Changes/Civilizations/CivilizationTableChanges.sql",
    )
    for relative in changes:
        source = (cp_root / relative).read_text(encoding="utf-8-sig")
        for statement in re.findall(r"ALTER\s+TABLE\s+[^;]+?\s+ADD\s+.*?;", source, re.I | re.S):
            try:
                database.execute(statement)
            except sqlite3.OperationalError as error:
                if "duplicate column name" not in str(error).lower():
                    raise RuntimeError(f"Failed CP schema statement from {relative}: {statement}") from error
    database.execute("CREATE TABLE IF NOT EXISTS CustomModOptions (Name TEXT, Value INTEGER, Class INTEGER, DbUpdates INTEGER)")
    options = ET.parse(cp_root / "Database Changes/NewCustomModOptions.xml")
    for entry in options.iter("Row"):
        name = entry.attrib.get("Name")
        if name:
            database.execute("DELETE FROM CustomModOptions WHERE Name=?", (name,))
            database.execute("INSERT INTO CustomModOptions(Name,Value,Class,DbUpdates) VALUES(?,?,?,?)",
                             (name, int(entry.attrib.get("Value", 0)), int(entry.attrib.get("Class", 0)),
                              int(entry.attrib.get("DbUpdates", 0))))
    # Recreate official CP companion relations which may not exist in an older
    # cache backup. Only table shapes declared by the installed CP are used.
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


def check_database(path: Path, cp_root: Path):
    assert path.is_file(), f"No gameplay cache at {path}; use --database"
    source = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    database = sqlite3.connect(":memory:")
    source.backup(database)
    source.close()
    database.row_factory = sqlite3.Row
    apply_current_cp_schema(database, cp_root)
    # Allow validation against a cache which already contains this mod by
    # removing only its namespaced rows from the disposable in-memory clone.
    tables = [r[0] for r in database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    for table in tables:
        columns = [r[1] for r in database.execute(f"PRAGMA table_info({quote(table)})")]
        predicate = " OR ".join(
            f"CAST({quote(c)} AS TEXT) LIKE '%{prefix}%'"
            for c in columns
            for prefix in ("ROULS", "LUNA", "TERRA", "CAPANO")
        )
        if predicate:
            try:
                database.execute(f"DELETE FROM {quote(table)} WHERE {predicate}")
            except sqlite3.OperationalError:
                pass  # Engine virtual tables can be read-only.
    database.execute("CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)")
    props = read_project()[1]
    for action in props.findall("m:ModActions/m:Action/m:FileName", NS):
        database.executescript((ROOT / action.text).read_text(encoding="utf-8-sig"))

    for civilization in (
        "CIVILIZATION_ROULS_ASCENDANCY",
        "CIVILIZATION_GPT_LUNA",
        "CIVILIZATION_GPT_TERRA",
        "CIVILIZATION_CAPANO_CIRCUIT",
    ):
        assert database.execute(
            "SELECT COUNT(*) FROM Civilizations WHERE Type=?", (civilization,)
        ).fetchone()[0] == 1, f"Combined activation is missing {civilization}"

    def row(table, unit_type):
        result = database.execute(f"SELECT * FROM {quote(table)} WHERE Type=?", (unit_type,)).fetchone()
        assert result is not None, f"Missing {unit_type}"
        return result

    rifle = row("Units", "UNIT_RIFLEMAN")
    hollow = row("Units", "UNIT_ROULS_HOLLOWHOUND")
    assert hollow["Combat"] == rifle["Combat"] and hollow["Moves"] == 2
    assert hollow["Cost"] == (rifle["Cost"] * 110 + 99) // 100, "Hollowhound cost must round up +10%"
    buddy = row("Units", "UNIT_ROULS_BUDDY")
    assert (buddy["Combat"], buddy["Moves"], buddy["Cost"], buddy["HurryCostModifier"]) == (45, 5, 350, -1)
    assert buddy["PrereqTech"] == "TECH_BIOLOGY" and buddy["Domain"] == "DOMAIN_SEA" and buddy["RangedCombat"] == 0
    buddy_class = row("UnitClasses", "UNITCLASS_ROULS_BUDDY")
    assert buddy_class["MaxPlayerInstances"] == 1
    assert row("Units", buddy_class["DefaultUnit"])["Cost"] == -1, "Other civilizations can train Buddy"
    hero = row("Buildings", "BUILDING_HEROIC_EPIC")
    choir = row("Buildings", "BUILDING_ROULS_CHOIR_ETERNAL")
    assert choir["Experience"] == hero["Experience"] + 5
    for base, unique in (("BUILDING_HOSPITAL", "BUILDING_ROULS_SOMATIC_LATTICE"), ("BUILDING_HEROIC_EPIC", "BUILDING_ROULS_CHOIR_ETERNAL")):
        base_row, unique_row = row("Buildings", base), row("Buildings", unique)
        for field in ("Cost", "GoldMaintenance", "FoodKept", "FreePromotion", "PrereqTech", "BuildingClass"):
            if field in base_row.keys():
                assert base_row[field] == unique_row[field], f"Lost inherited {field}: {unique}"
    def yield_value(building, kind):
        return database.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType=?", (building, kind)).fetchone()[0]
    for kind in ("YIELD_SCIENCE", "YIELD_PRODUCTION"):
        assert yield_value("BUILDING_ROULS_SOMATIC_LATTICE", kind) == yield_value("BUILDING_HOSPITAL", kind) + 2
    assert yield_value("BUILDING_ROULS_CAPITAL_SCIENCE", "YIELD_SCIENCE") == 1
    assert row("UnitPromotions", "PROMOTION_ROULS_SECOND_SKIN")["LostWithUpgrade"] == 0
    lock = row("UnitPromotions", "PROMOTION_ROULS_ACTION_LOCK")
    assert lock["OnlyDefensive"] == 1 and lock["RangeChange"] <= -99, "Action lock must suppress melee and ranged attacks"
    start_techs = lambda civ: {r[0] for r in database.execute("SELECT TechType FROM Civilization_FreeTechs WHERE CivilizationType=?", (civ,))}
    assert start_techs("CIVILIZATION_ROULS_ASCENDANCY") == start_techs("CIVILIZATION_AMERICA"), "Bonus starting technology added"
    assert database.execute("SELECT Value FROM CustomModOptions WHERE Name='EVENTS_UNIT_PREKILL'").fetchone()[0] == 1
    assert database.execute("SELECT Value FROM CustomModOptions WHERE Name='EVENTS_BATTLES'").fetchone()[0] == 1
    unresolved = set()
    translated = {r[0] for r in database.execute("SELECT Tag FROM Language_en_US")}
    for table in ("Civilizations", "Leaders", "Units", "Buildings", "UnitPromotions", "Traits"):
        for item in database.execute(f"SELECT * FROM {quote(table)} WHERE Type LIKE '%ROULS%'"):
            for field in ("Description", "ShortDescription", "Adjective", "Civilopedia", "Strategy", "Help", "Quote", "DawnOfManQuote"):
                if field in item.keys() and isinstance(item[field], str) and "ROULS" in item[field] and item[field].startswith("TXT_KEY_") and item[field] not in translated:
                    unresolved.add(item[field])
    assert not unresolved, f"Missing localized text: {sorted(unresolved)}"
    assert database.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    print("PASS SQL against read-only cache clone + installed CP schema: stats, inherited effects, exclusivity, promotions, events and localization")
    database.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    user_game = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    parser.add_argument("--database", type=Path, default=user_game / "cache_backup/Civ5DebugDatabase.db")
    parser.add_argument("--cp-root", type=Path, default=user_game / "MODS/(1) Community Patch")
    parser.add_argument("--no-database", action="store_true", help="Only static/package checks; does not certify SQL compatibility")
    args = parser.parse_args()
    check_packaging()
    check_ui_and_lua()
    if not args.no_database:
        check_database(args.database, args.cp_root)
    print("Validation passed. Engine gameplay still requires the documented in-game smoke tests.")


if __name__ == "__main__":
    main()
