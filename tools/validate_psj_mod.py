"""Validate First Night SQL against installed CP, DDS dimensions and Lua lifecycle."""
from pathlib import Path
from collections import Counter
import sqlite3
import sys
import re
from xml.etree import ElementTree as ET

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / '.tools/python'))
sys.path.insert(0, str(REPO / 'tools'))
from validate_mod import apply_current_cp_schema, quote
from build_mod import read_project, NS

ROOT = REPO / 'PaulsoaresJr'


def event_option_checks():
    # Audited dispatch sites in Release-5.4.2 and Release-5.4.6, documented in
    # the README: the other used hooks have base CallHook paths, with adequate
    # argument ordering. Do not depend on another civ enabling these five.
    required={'EVENTS_NW_DISCOVERY','EVENTS_GOODY_CHOICE','EVENTS_PLOT',
              'EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS'}
    core=(ROOT/'SQL/00_PSJ_Core.sql').read_text(encoding='utf-8')
    block=re.search(r'UPDATE CustomModOptions SET Value = 1 WHERE Name IN\s*\((.*?)\);',core,re.S)
    assert block, 'Missing PSJ event declarations'
    declared=re.findall(r"'(EVENTS_[A-Z_]+)'",block.group(1))
    assert len(declared)==len(set(declared)) and set(declared)==required, 'PSJ must declare only its five required event switches'
    assert not re.search(r'UPDATE\s+CustomModOptions\s+SET\s+Value\s*=\s*0',core,re.I), 'PSJ must not disable another civ event family'
    print('PASS PSJ event options: five necessary switches; base fallbacks and argument ordering audited against CP v151 source')


def database_checks():
    user = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    source = sqlite3.connect((user/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    db = sqlite3.connect(':memory:'); source.backup(db); source.close()
    db.row_factory = sqlite3.Row
    apply_current_cp_schema(db,user/'MODS/(1) Community Patch')
    db.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY, Text TEXT)')
    tables = [r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    for t in tables:
        cols = [r[1] for r in db.execute(f'PRAGMA table_info({quote(t)})')]
        where = ' OR '.join(f"INSTR(CAST({quote(c)} AS TEXT),'PSJ_')>0" for c in cols)
        if where:
            try: db.execute(f'DELETE FROM {quote(t)} WHERE {where}')
            except sqlite3.OperationalError: pass
    for sql in sorted((ROOT/'SQL').glob('*.sql')): db.executescript(sql.read_text(encoding='utf-8'))
    def row(t,typ):
        r=db.execute(f'SELECT * FROM {quote(t)} WHERE Type=?',(typ,)).fetchone()
        assert r is not None, typ
        return r
    scout=row('Units','UNIT_SCOUT'); survivor=row('Units','UNIT_PSJ_SURVIVOR')
    for c in ('Cost','Combat','Class','Domain','CombatClass','PrereqTech','ObsoleteTech','DefaultUnitAI','UnitArtInfo'):
        assert survivor[c]==scout[c], f'Survivor changed {c}'
    assert survivor['Moves']==2
    monument=row('Buildings','BUILDING_MONUMENT'); house=row('Buildings','BUILDING_PSJ_STARTER_HOUSE')
    for c in ('Cost','BuildingClass','PrereqTech','GoldMaintenance'):
        assert house[c]==monument[c],f'Starter House changed {c}'
    assert db.execute("SELECT SUM(Yield) FROM Building_YieldChanges WHERE BuildingType='BUILDING_PSJ_STARTER_HOUSE' AND YieldType='YIELD_CULTURE'").fetchone()[0]==2
    # Check every populated companion table, rather than guessing the upgrade
    # path or a list of terrain promotions for the installed CP/VP ruleset.
    for key,old,new,scalar,skip in (
        ('UnitType','UNIT_SCOUT','UNIT_PSJ_SURVIVOR','Units',set()),
        ('BuildingType','BUILDING_MONUMENT','BUILDING_PSJ_STARTER_HOUSE','Buildings',{'Building_YieldChanges'})):
        for t in tables:
            columns=[r[1] for r in db.execute(f'PRAGMA table_info({quote(t)})')]
            if t==scalar or t in skip or key not in columns: continue
            cols=[c for c in columns if c.lower()!='id']
            expected=Counter(tuple(new if c==key else r[c] for c in cols) for r in db.execute(f'SELECT * FROM {quote(t)} WHERE {quote(key)}=?',(old,)))
            actual=Counter(tuple(r[c] for c in cols) for r in db.execute(f'SELECT * FROM {quote(t)} WHERE {quote(key)}=?',(new,)))
            assert not expected-actual,f'Missing inherited {t}'
    learn=row('UnitPromotions','PROMOTION_PSJ_LEARNING')
    assert (learn['NeutralHealChange'],learn['EnemyHealChange'],learn['FriendlyHealChange'],learn['LostWithUpgrade'])==(5,5,0,0)
    veteran=row('UnitPromotions','PROMOTION_PSJ_BEGINNING')
    assert (veteran['VisibilityChange'],veteran['DefenseMod'],veteran['LostWithUpgrade'])==(1,10,0)
    for i in range(1,4):
        home=row('Buildings',f'BUILDING_PSJ_HOME_{i}')
        assert (home['Cost'],home['UnmoddedHappiness'],home['NeverCapture'],home['IsDummy'],home['ShowInPedia'])==(-1,i,1,1,0)
        assert db.execute('SELECT SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType=?',(home['Type'],'YIELD_CULTURE')).fetchone()[0]==i
    civ=row('Civilizations','CIVILIZATION_PSJ_FIRST_NIGHT')
    assert civ['Playable']==civ['AIPlayable']==1
    assert list(db.execute("SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_PSJ_FIRST_NIGHT'"))[0][0]=='UNIT_PSJ_SURVIVOR'
    assert list(db.execute("SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType='CIVILIZATION_PSJ_FIRST_NIGHT'"))[0][0]=='BUILDING_PSJ_STARTER_HOUSE'
    assert db.execute("SELECT TraitType FROM Leader_Traits WHERE LeaderType='LEADER_PSJ_PAUL'").fetchone()[0]=='TRAIT_PSJ_SURVIVE_THRIVE'
    translated={r[0] for r in db.execute('SELECT Tag FROM Language_en_US')}
    for t in ('Civilizations','Leaders','Units','Buildings','BuildingClasses','UnitPromotions','Traits','Concepts'):
        for r in db.execute(f"SELECT * FROM {quote(t)} WHERE Type LIKE '%PSJ_%'"):
            for v in r:
                if isinstance(v,str) and v.startswith('TXT_KEY_') and 'PSJ' in v:
                    assert v in translated,f'Missing translation {v}'
        assert not list(db.execute(f"SELECT Type FROM {quote(t)} WHERE Type LIKE '%PSJ_%' GROUP BY Type HAVING COUNT(*)>1")),f'Duplicate {t} Types'
    lua=(ROOT/'Lua/PSJRuntime.lua').read_text()
    # Fixed Lua strings plus dynamic memory/narrative suffixes.
    for k in re.findall(r'"(TXT_KEY_PSJ_[A-Z_]+)"',lua):
        if k not in {'TXT_KEY_PSJ_'}: assert k in translated,k
    for prefix in ('FIRST_SHELTER','FIRST_NIGHT','FIRST_DANGER','FIRST_MINE','FIRST_HARVEST',
        'FIRST_JOURNEY','FIRST_FRIEND','FIRST_WONDER','BEYOND_HOME','SOMETHING_NEW'):
        assert 'TXT_KEY_PSJ_'+prefix in translated and 'TXT_KEY_PSJ_'+prefix+'_NOTICE' in translated
    from PIL import Image
    for a in db.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'PSJ_%'"):
        with Image.open(ROOT/'Art'/a['Filename']) as image:
            image.load()
            assert image.size==(int(a['IconSize'])*int(a['IconsPerRow']),int(a['IconSize'])*int(a['IconsPerColumn'])),a['Filename']
            assert image.mode=='RGBA'
            assert image.getpixel((0,0))[3]==0,'icon lacks transparent corners'
    assert db.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    db.close()
    print('PASS PSJ SQL: CP inheritance, yields, overrides, promotions, localization, atlas dimensions and duplicate IDs')


def lua_checks():
    from lupa.lua51 import LuaRuntime
    lua=LuaRuntime(unpack_returned_tuples=True)
    source=(ROOT/'Lua/PSJRuntime.lua').read_text()
    lua.execute((REPO/'tools/tests/psj_mock.lua').read_text())
    lua.execute(source)
    lua.execute((REPO/'tools/tests/psj_assertions.lua').read_text())
    # Recreate the gameplay context while preserving authoritative engine/save data.
    lua.execute('__PSJ_RUNTIME_LOADED=nil; resetEvents()')
    lua.execute(source)
    lua.execute("""
GameEvents.TeamSetEra.Fire(2,7,true)
GameEvents.PlayerDoTurn.Fire(2)
assert(P.culture==ReloadC and P.science==ReloadS and #P.notifications==ReloadNotes,'reload repeated yields or finale')
-- Razing/refounding on the same coordinates must not inherit the original Home.
local replacement=newCity(Foreign,0,0)
replacement.buildings[300]=1
T=17;GameEvents.PlayerDoTurn.Fire(2)
assert(not replacement.buildings[301] and not replacement.buildings[302] and not replacement.buildings[303],'refounded Home inherited bonuses')
-- No retroactive eras for an advanced start; new units cannot become Ancient.
local late=newPlayer(3,100,false);late.era=5;newCity(late,30,0)
local fresh=newUnit(late,50)
GameEvents.UnitCreated.Fire(3,50)
T=18;GameEvents.PlayerDoTurn.Fire(3)
assert(not fresh.promotions[401] and not Saved.PSJ_V1_P3_NARRATIVE_1,'late start invented history')
print('PASS PSJ reload, refounding and advanced-start safety')
""")
    # Independently vary every instant-yield scaling channel.
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute((REPO/'tools/tests/psj_mock.lua').read_text())
    lua.execute('GameInfo.GameSpeeds[0]={CulturePercent=67,ResearchPercent=150,GrowthPercent=200};newCity(P,0,0)')
    lua.execute(source)
    lua.execute("""
T=1;GameEvents.PlayerDoTurn.Fire(2)
assert(P.culture==3 and P.science==8,'GameSpeed channels or rounding wrong')
local field=plot(1,0,2);field.improvement=501;field.resource=600
GameEvents.PlayerBuilt.Fire(2,1,1,0,2)
assert(P.capital.food==10,'Food did not scale')
print('PASS PSJ GameSpeed: independent Culture/Research/Growth scaling')
""")
    # Fresh fixture specifically uses the actual Survivor type on transfer,
    # rather than only an upgraded descendant. The script recreates contexts.
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute((REPO/'tools/tests/psj_mock.lua').read_text())
    lua.globals().PSJRuntimeSource=source
    lua.execute(source)
    lua.execute((REPO/'tools/tests/psj_lineage_assertions.lua').read_text())


def main():
    event_option_checks(); database_checks(); lua_checks()
    entries=[e.text for e in read_project()[1].findall('m:ModContent/m:Content/m:FileName',NS)]
    assert entries.count('PaulsoaresJr/Lua/PSJRuntime.lua')==1
    ET.parse(ROOT/'Art/PSJLeaderScene.xml')
    print('First Night validation passed; engine smoke tests remain in README.')


if __name__=='__main__': main()
