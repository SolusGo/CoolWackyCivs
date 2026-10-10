"""Verify Sol against an in-memory copy of real BNW/CP data and Lua 5.1 native-order mocks."""
from pathlib import Path
from collections import Counter
from xml.etree import ElementTree as ET
import argparse
import re
import sqlite3
import struct
import sys

from build_mod import REPO, NS, read_project, create_manifest, package_name
from validate_mod import apply_current_cp_schema, directxtex_checks, quote
sys.path.insert(0, str(REPO / ".tools/python"))
ROOT = REPO / "SolIntellect"


def database_checks(database, cp):
    src = sqlite3.connect(database.resolve().as_uri() + "?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    src.backup(db)
    src.close()
    apply_current_cp_schema(db, cp)
    db.execute("CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)")
    # Deliberately nonvanilla baseline: test activation-time inheritance rather
    # than snapshots of Standard BNW numbers, including a future scalar column.
    db.execute("ALTER TABLE Buildings ADD SolInheritanceProbe INTEGER DEFAULT 17")
    db.execute("UPDATE Buildings SET Cost=391,GreatPeopleRateModifier=7 WHERE Type='BUILDING_PUBLIC_SCHOOL'")
    db.execute("UPDATE Buildings SET Cost=287 WHERE Type='BUILDING_UNIVERSITY'")
    db.execute("DELETE FROM Building_SpecialistYieldChangesLocal WHERE BuildingType='BUILDING_UNIVERSITY' AND SpecialistType='SPECIALIST_SCIENTIST' AND YieldType='YIELD_SCIENCE'")
    db.execute("INSERT INTO Building_SpecialistYieldChangesLocal VALUES ('BUILDING_UNIVERSITY','SPECIALIST_SCIENTIST','YIELD_SCIENCE',3)")
    for file in sorted((ROOT / "SQL").glob("*.sql")):
        try:
            db.executescript(file.read_text(encoding="utf-8-sig"))
        except sqlite3.Error as error:
            raise RuntimeError(f"{file.name}: {error}") from error

    def one(sql, args=()): return db.execute(sql, args).fetchone()[0]
    assert tuple(db.execute("SELECT Playable,AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_GPT_SOL'").fetchone()) == (1,0)
    assert one("SELECT COUNT(*) FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_GPT_SOL'") == 0
    assert one("SELECT COUNT(*) FROM Civilization_BuildingClassOverrides WHERE CivilizationType='CIVILIZATION_GPT_SOL'") == 2
    changed = {"ID","Type","Description","Civilopedia","Strategy","Help","PortraitIndex","IconAtlas"}
    for base,new,extra_gp in [("BUILDING_UNIVERSITY","BUILDING_SOL_CONTEXT_ARCHIVE",0),
                              ("BUILDING_PUBLIC_SCHOOL","BUILDING_SOL_REASONING_INSTITUTE",10)]:
        columns = [r[1] for r in db.execute("PRAGMA table_info(Buildings)")]
        a = dict(zip(columns,db.execute("SELECT * FROM Buildings WHERE Type=?",(base,)).fetchone()))
        b = dict(zip(columns,db.execute("SELECT * FROM Buildings WHERE Type=?",(new,)).fetchone()))
        for col in columns:
            if col in changed: continue
            expected = (a[col] or 0)+extra_gp if col=="GreatPeopleRateModifier" else a[col]
            assert b[col]==expected, f"{new} lost scalar CP baseline {col}"
        for (table,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'Building_%'"):
            columns = [r[1] for r in db.execute(f"PRAGMA table_info({quote(table)})")]
            if "BuildingType" not in columns or table=="Building_SpecialistYieldChangesLocal": continue
            columns = [c for c in columns if c not in {"ID","BuildingType"}]
            select = ",".join(quote(c) for c in columns)
            before = Counter(db.execute(f"SELECT {select} FROM {quote(table)} WHERE BuildingType=?",(base,)).fetchall())
            after = Counter(db.execute(f"SELECT {select} FROM {quote(table)} WHERE BuildingType=?",(new,)).fetchall())
            assert before==after, f"{new} companion inheritance failed: {table}"
    for (specialist,) in db.execute("SELECT Type FROM Specialists WHERE Type<>'SPECIALIST_CITIZEN'"):
        before=one("SELECT COALESCE(SUM(Yield),0) FROM Building_SpecialistYieldChangesLocal WHERE BuildingType='BUILDING_UNIVERSITY' AND SpecialistType=? AND YieldType='YIELD_SCIENCE'",(specialist,))
        after=one("SELECT SUM(Yield) FROM Building_SpecialistYieldChangesLocal WHERE BuildingType='BUILDING_SOL_CONTEXT_ARCHIVE' AND SpecialistType=? AND YieldType='YIELD_SCIENCE'",(specialist,))
        assert after==before+1
        assert one("SELECT COUNT(*) FROM Building_SpecialistYieldChangesLocal WHERE BuildingType='BUILDING_SOL_CONTEXT_ARCHIVE' AND SpecialistType=? AND YieldType='YIELD_SCIENCE'",(specialist,))==1
    assert one("SELECT COUNT(*) FROM Building_SpecialistYieldChangesLocal WHERE BuildingType='BUILDING_SOL_CONTEXT_ARCHIVE' AND SpecialistType='SPECIALIST_CITIZEN'")==0
    for name,gp in [("INSIGHT",2),("CONTEXT_CULTURE",0),("REASONING_INSIGHT_SCIENCE",0)]:
        assert tuple(db.execute("SELECT Cost,FaithCost,IsDummy,ShowInPedia,NeverCapture,ConquestProb,GreatPeopleRateModifier FROM Buildings WHERE Type=?",('BUILDING_SOL_'+name,)).fetchone())==(-1,-1,1,0,1,0,gp)
    assert one("SELECT Yield FROM Building_YieldModifiers WHERE BuildingType='BUILDING_SOL_INSIGHT' AND YieldType='YIELD_SCIENCE'")==2
    assert one("SELECT Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_SOL_CONTEXT_CULTURE' AND YieldType='YIELD_CULTURE'")==1
    assert one("SELECT Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_SOL_REASONING_INSIGHT_SCIENCE' AND YieldType='YIELD_SCIENCE'")==1
    assert one("SELECT COUNT(*) FROM Leader_Flavors l LEFT JOIN Flavors f ON f.Type=l.FlavorType WHERE l.LeaderType='LEADER_GPT_SOL' AND f.Type IS NULL")==0
    for option in ("EVENTS_CITY","EVENTS_PLAYER_TURN","EVENTS_CITY_FOUNDING"):
        assert one("SELECT Value FROM CustomModOptions WHERE Name=?",(option,))==1
    tags={r[0] for r in db.execute("SELECT Tag FROM Language_en_US")}
    for sql in (ROOT/"SQL").glob("*.sql"):
        for tag in re.findall(r"'(TXT_KEY_[^']*(?:SOL)[^']*)'",sql.read_text()): assert tag in tags,tag
    assert one("SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType='CIVILIZATION_GPT_SOL'")==31
    assert one("SELECT COUNT(*) FROM Civilization_SpyNames WHERE CivilizationType='CIVILIZATION_GPT_SOL'")==10
    assert one("SELECT COUNT(*) FROM Diplomacy_Responses WHERE LeaderType='LEADER_GPT_SOL' AND Response LIKE 'TXT_KEY_SOL_DIPLO_%'")==19
    print("PASS Sol SQL: actual CP schema, all scalar/companion inheritance, additive specialist yields, exact modifiers, names/diplomacy, valid flavors and localization")


def runtime_checks():
    from lupa.lua51 import LuaRuntime
    source=(ROOT/"Lua/SolRuntime.lua").read_text()
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().SolSource=source
    lua.execute((REPO/"tools/tests/sol_mock.lua").read_text())
    lua.execute(source)
    lua.execute((REPO/"tools/tests/sol_assertions.lua").read_text())
    assert "SetUpdate" not in source and "Game.GetNumPlots" not in source


def packaging_checks():
    _,props,_,files=read_project()
    selected=[(n,i) for n,i in files if n.startswith('SolIntellect/')]
    actual={p.relative_to(REPO).as_posix() for p in ROOT.rglob('*') if p.suffix in {'.sql','.lua','.xml','.dds'}}
    assert actual=={n for n,_ in selected}
    for name,imported in selected: assert imported==(not name.endswith('.sql'))
    assert any(e.text=='SolIntellect/Lua/SolRuntime.lua' for e in props.findall('m:ModContent/m:Content/m:FileName',NS))
    assert ET.tostring(ET.parse(REPO/f'{package_name()}.modinfo').getroot())==ET.tostring(create_manifest().getroot())
    paths=[]
    from PIL import Image
    for file in (ROOT/'Art').glob('*.dds'):
        header=file.read_bytes()[:128]
        assert header[:4]==b'DDS ' and header[84:88]!=b'DX10'
        height,width=struct.unpack_from('<II',header,12)
        size=re.search(r'(\d+)\.dds$',file.name)
        if size: assert width==height==int(size[1])
        image=Image.open(file);image.load()
        if size: assert image.convert('RGBA').getchannel('A').getextrema()==(0,255)
        paths.append(file)
    assert len(paths)==26
    assert ET.parse(ROOT/'Art/SolLeaderScene.xml').getroot().get('FallbackImage')=='SolLeader.dds'
    directxtex_checks(paths)
    print('PASS Sol project/VFS, manifest hashes, 26 legacy DDS dimensions/alpha and leader scene')


def source_contracts():
    audit=REPO/'.tools/cp-v151-audit'
    if not (audit/'CvCity.cpp').exists():
        print('SKIP local CP source contract snapshot; see docs/Validation.md for upstream source links')
        return
    city=(audit/'CvCity.cpp').read_text(encoding='utf-8')
    player=(audit/'CvPlayer.cpp').read_text(encoding='utf-8')
    produce=city[city.index('void CvCity::produce(BuildingTypes'):city.index('void CvCity::produce(ProjectTypes')]
    assert produce.index('m_iThingsProduced++')<produce.index('CreateBuilding')<produce.index('GAMEEVENT_CityConstructed')
    pop=city[city.index('void CvCity::popOrder('):city.index('void CvCity::swapOrder(')]
    assert pop.index('produce(eConstructBuilding)')<pop.index('m_orderQueue.deleteNode')
    assert player.index('pLoopCity->doTurn();')<player.index('"PlayerDoTurn"')
    assert 'GAMEEVENT_PlayerDoneTurn, GetID()' in player
    assert 'GAMEEVENT_CityConstructed, getOwner(), GetID(), eBuildingType, true, false' in city
    assert 'GAMEEVENT_CityConstructed, getOwner(), GetID(), eBuildingType, false, true' in city
    assert 'SetSpecificCityInfoDirty(pCity.get(), CITY_UPDATE_TYPE_PRODUCTION)' in city
    assert 'pBuildingInfo->GetSpecialistYieldChangeLocal(iI, iJ) * iChange' in city
    assert 'GetSpecialistRateModifierFromBuildings(eSpecialist)' in city
    for method in ('GetOrderFromQueue','GetNumThingsProduced','GetBuildingProductionNeeded','GetSpecialistCount'):
        assert 'Method('+method+');' in (audit/'Lua_CvLuaCity.cpp').read_text()
    print('PASS CP source contracts: native turn order, genuine completions/purchases, queue-head timing, specialist and civilian GP effects')


if __name__=='__main__':
    user=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database',type=Path,default=user/'cache_backup/Civ5DebugDatabase.db')
    parser.add_argument('--cp-root',type=Path,default=user/'MODS/(1) Community Patch')
    args=parser.parse_args()
    database_checks(args.database,args.cp_root)
    runtime_checks()
    packaging_checks()
    source_contracts()
    print('Sol automated validation passed. Live Civ V smoke tests remain outstanding.')
