"""Focused Terra SQL inheritance, assets, packaging and Lua 5.1 behavior checks.

Reads a gameplay cache into memory; never changes the game's cache or saves.
"""
from pathlib import Path
import argparse, sqlite3, sys, re, struct
from xml.etree import ElementTree as ET
from build_mod import REPO, NS, read_project, create_manifest, package_name
from validate_mod import apply_current_cp_schema
ROOT=REPO/'TerraFramework'
PREFIX='TerraFramework/'
sys.path.insert(0,str(REPO/'.tools/python'))

def database_checks(path,cp):
    src=sqlite3.connect(path.resolve().as_uri()+'?mode=ro',uri=True)
    db=sqlite3.connect(':memory:');src.backup(db);src.close()
    apply_current_cp_schema(db,cp)
    # A stale cache may predate newer CP companion tables. Use the installed
    # official XML schema, not permissive guessed columns, in this disposable DB.
    for path in sorted((cp/'Database Changes').rglob('*.xml')):
        try: tree=ET.parse(path)
        except ET.ParseError: continue
        for t in tree.findall('Table'):
            name=t.get('name')
            if not name or not (name.startswith('Building_') or name.startswith('Unit_')): continue
            cols=[]
            for col in t.findall('Column'):
                default=col.get('default')
                default_sql='' if default is None else ' DEFAULT '+("'"+default.replace("'","''")+"'")
                cols.append('"'+col.get('name')+'" '+col.get('type','text')+default_sql)
            if cols: db.execute(f'CREATE TABLE IF NOT EXISTS "{name}"('+','.join(cols)+')')
    db.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    # Test fresh activation against clean cache; repeat callers must supply a cache without Terra.
    db.executescript('DROP TABLE IF EXISTS TerraBuildingModes;')
    for sql in sorted((ROOT/'SQL').glob('*.sql')):
        try: db.executescript(sql.read_text(encoding='utf-8-sig'))
        except sqlite3.Error as e: raise RuntimeError(f'{sql.name}: {e}') from e
    def one(sql): return db.execute(sql).fetchone()[0]
    assert one("SELECT COUNT(*) FROM Civilizations WHERE Type='CIVILIZATION_GPT_TERRA'")==1
    assert one('SELECT COUNT(*) FROM TerraBuildingModes')==34
    assert one('SELECT COUNT(*) FROM TerraBuildingModes m LEFT JOIN BuildingClasses c ON c.Type=m.BuildingClassType WHERE c.Type IS NULL')==0
    for table,base,new,ignored in [('Buildings','BUILDING_MARKET','BUILDING_TERRA_MULTIMODAL_HUB',{'ID','Type','Description','Civilopedia','Strategy','Help','PortraitIndex','IconAtlas'}),('Units','UNIT_MUSKETMAN','UNIT_TERRA_ADAPTIVE_OPERATIVE',{'ID','Type','Description','Civilopedia','Strategy','Help','PortraitIndex','IconAtlas'})]:
        columns=[r[1] for r in db.execute(f'PRAGMA table_info({table})')]
        a=db.execute(f'SELECT * FROM {table} WHERE Type=?',(base,)).fetchone()
        b=db.execute(f'SELECT * FROM {table} WHERE Type=?',(new,)).fetchone()
        assert b is not None
        assert all(x==y for c,x,y in zip(columns,a,b) if c not in ignored),f'{table} scalar inheritance differs'
    for table,column,base,new in [('Unit_ResourceQuantityRequirements','UnitType','UNIT_MUSKETMAN','UNIT_TERRA_ADAPTIVE_OPERATIVE'),('Unit_ClassUpgrades','UnitType','UNIT_MUSKETMAN','UNIT_TERRA_ADAPTIVE_OPERATIVE'),('Building_YieldModifiers','BuildingType','BUILDING_MARKET','BUILDING_TERRA_MULTIMODAL_HUB')]:
        cols=[r[1] for r in db.execute(f'PRAGMA table_info({table})') if r[1]!=column]
        selected=','.join('"'+c+'"' for c in cols)
        assert db.execute(f'SELECT {selected} FROM {table} WHERE {column}=?',(base,)).fetchall()==db.execute(f'SELECT {selected} FROM {table} WHERE {column}=?',(new,)).fetchall()
    for yield_ in ['SCIENCE','CULTURE']:
        a=one(f"SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType='BUILDING_MARKET' AND YieldType='YIELD_{yield_}'")
        b=one(f"SELECT SUM(Yield) FROM Building_YieldChanges WHERE BuildingType='BUILDING_TERRA_MULTIMODAL_HUB' AND YieldType='YIELD_{yield_}'")
        assert b==a+1
    assert one("SELECT FriendlyHealChange FROM UnitPromotions WHERE Type='PROMOTION_TERRA_CONFIG_RECOVERY'")==10
    for config,field in [('ROUGH','Rough'),('OPEN','Open')]:
        assert db.execute(f"SELECT {field}Attack,{field}Defense,LostWithUpgrade FROM UnitPromotions WHERE Type='PROMOTION_TERRA_CONFIG_{config}'").fetchone()==(15,15,1)
    for row in db.execute("SELECT Tag,Text FROM Language_en_US WHERE Tag LIKE '%TERRA%'"): assert row[1],f'Empty localization: {row[0]}'
    tags={r[0] for r in db.execute('SELECT Tag FROM Language_en_US')}
    for sql in (ROOT/'SQL').glob('*.sql'):
        for tag in re.findall(r"'((?:TXT_KEY_)[^']*TERRA[^']*)'",sql.read_text()): assert tag in tags,tag
    print('PASS SQL: BNW + installed CP schema, scalar inheritance, resources/upgrades, mode map, exact bonuses, localization')

def packaging():
    _,props,_,project_files=read_project()
    files=[(name.removeprefix(PREFIX),imp) for name,imp in project_files if name.startswith(PREFIX)]
    actual={p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*') if p.suffix in ['.sql','.lua','.xml','.dds']}
    assert actual=={n for n,_ in files}
    assert ET.tostring(ET.parse(REPO/f'{package_name()}.modinfo').getroot())==ET.tostring(create_manifest().getroot())
    for name,imp in files:
        assert imp==(not name.endswith('.sql'))
        if name.endswith('.dds'):
            h=(ROOT/name).read_bytes()[:128];assert h[:4]==b'DDS '
            height,width=struct.unpack_from('<II',h,12)
            match=re.search(r'(\d+)\.dds$',name)
            if match: assert width==height==int(match[1])
            assert h[84:88]!=b'DX10','Civ V needs legacy DDS'
    from lupa.lua51 import LuaRuntime
    lua=LuaRuntime(unpack_returned_tuples=True)
    source=(ROOT/'Lua/TerraRuntime.lua').read_text()
    ok,error=lua.eval('function(s) local f,e=loadstring(s); return f~=nil,e end')(source)
    assert ok,error
    lua.execute((REPO/'tools/tests/terra_mock.lua').read_text())
    lua.execute(source)
    lua.execute((REPO/'tools/tests/terra_assertions.lua').read_text())
    print('PASS DDS sizes, manifest hashes, project wiring, Lua 5.1 syntax and behavior scenarios')

if __name__=='__main__':
    user=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    p=argparse.ArgumentParser();p.add_argument('--database',type=Path,default=user/'cache_backup/Civ5DebugDatabase.db');p.add_argument('--cp-root',type=Path,default=user/'MODS/(1) Community Patch')
    a=p.parse_args();database_checks(a.database,a.cp_root);packaging()
    print('Terra checks passed. In-game visuals/save-load still require a smoke test.')
