"""Real BNW/CP SQL, Lua 5.1 lifecycle simulation, save/reload, AI and UI checks."""
from pathlib import Path
from xml.etree import ElementTree as ET
import re,sqlite3,sys,hashlib
R=Path(__file__).resolve().parents[1];V=R/'TheKingdoms'
sys.path[:0]=[str(R/'.tools/python'),str(R/'tools')]
from validate_mod import apply_current_cp_schema,quote
from lupa.lua51 import LuaRuntime
from PIL import Image

def database(cp=None):
    user=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    src=sqlite3.connect((user/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    d=sqlite3.connect(':memory:');src.backup(d);src.close();apply_current_cp_schema(d,cp or user/'MODS/(1) Community Patch');d.row_factory=sqlite3.Row
    d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
        pred=' OR '.join(f"INSTR(CAST({quote(c)} AS TEXT),'KINGDOMS')>0 OR {quote(c)}='LEADER_THE_THRONE'" for c in cols)
        if pred:
            try:d.execute('DELETE FROM '+quote(name)+' WHERE '+pred)
            except sqlite3.OperationalError:pass
    events=('EVENTS_CITY','EVENTS_CITY_FOUNDING','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_PREKILL','EVENTS_BARBARIANS','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_ENDED')
    # Start with disabled options so the mod must enable them, independent of the cached state.
    d.executemany('UPDATE CustomModOptions SET Value=0 WHERE Name=?',[(name,) for name in events])
    for f in sorted((V/'SQL').glob('*.sql')):d.executescript(f.read_text(encoding='utf-8'))
    for name in events:
        enabled=d.execute('SELECT Value FROM CustomModOptions WHERE Name=?',(name,)).fetchone()
        assert enabled and enabled[0]==1,('Missing CP event enablement',name)
    row=lambda table,kind:d.execute('SELECT * FROM '+table+' WHERE Type=?',(kind,)).fetchone()
    assert tuple(d.execute("SELECT Playable,AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_KINGDOMS'").fetchone())==(1,1)
    assert row('Units','UNIT_KINGDOMS_GUARD')['Combat']==28 and row('Units','UNIT_KINGDOMS_GUARD')['ObsoleteTech'] is None
    wall,base=row('Buildings','BUILDING_KINGDOMS_WALL'),row('Buildings','BUILDING_WALLS')
    assert wall['Defense']==base['Defense'] and wall['Happiness']==base['Happiness']+1
    yields=lambda name:dict(d.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(name,)))
    assert yields(wall['Type']).get('YIELD_PRODUCTION',0)==yields(base['Type']).get('YIELD_PRODUCTION',0)+2
    assert dict(d.execute("SELECT YieldType,Yield FROM Building_YieldModifiers WHERE BuildingType='BUILDING_KINGDOMS_CIVILWAR'"))=={'YIELD_FOOD':-25,'YIELD_PRODUCTION':-30,'YIELD_GOLD':-20,'YIELD_SCIENCE':-15}
    assert row('Buildings','BUILDING_KINGDOMS_CIVILWAR')['UnmoddedHappiness']==-3
    for name in ['GUARD','HONOURABLE','BRUTAL','PROTECTOR','DUELIST','COMMANDER','UNYIELDING','RIDER','SIEGEBREAKER','VETERAN','GUARDIAN','AGGRESSIVE','CAUTIOUS','LOYAL','AMBITIOUS','PENDING']:
        assert row('UnitPromotions','PROMOTION_KINGDOMS_'+name)['LostWithUpgrade']==0
    for table,col,base,unique in [('Unit_','UnitType','UNIT_LONGSWORDSMAN','UNIT_KINGDOMS_GUARD'),('Building_','BuildingType','BUILDING_WALLS','BUILDING_KINGDOMS_WALL')]:
        for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
            if not name.startswith(table) or col not in cols or name=='Building_YieldChanges':continue
            fields=[c for c in cols if c not in ['ID',col]]
            fetch=lambda key:sorted(tuple(r) for r in d.execute('SELECT '+','.join(map(quote,fields))+' FROM '+quote(name)+' WHERE '+col+'=?',(key,)))
            assert fetch(base)==fetch(unique),(name,unique)
    translated={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
    for table in ['Civilizations','Leaders','Units','Buildings','Traits','UnitPromotions']:
        for r in d.execute('SELECT * FROM '+table+" WHERE Type LIKE '%KINGDOMS%' OR Type='LEADER_THE_THRONE'"):
            for v in r:
                if isinstance(v,str) and v.startswith('TXT_KEY_KINGDOMS_'):assert v in translated,v
    for r in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'KINGDOMS_%'"):
        p=V/'Art'/r['Filename']
        with Image.open(p) as im:im.load();assert im.size==(int(r['IconSize'])*int(r['IconsPerRow']),int(r['IconSize'])*int(r['IconsPerColumn']))
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    return d

def fixture(d,speed=100,missing=False):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().Translations=lua.table_from(dict(d.execute('SELECT Tag,Text FROM Language_en_US')))
    lua.execute((R/'tools/tests/kingdoms_mock.lua').read_text())
    types={};info=lua.table()
    for table in ['Civilizations','Units','Buildings','UnitPromotions','Technologies','Resources','Specialists','Builds','Improvement_ResourceTypes']:
        entries=d.execute('SELECT * FROM '+table).fetchall()
        data=lua.table_from([lua.table_from(dict(r)) for r in entries]);info[table]=lua.globals().databaseTable(data)
        for r in entries:
            if 'Type' in r.keys() and 'ID' in r.keys():types[r['Type']]=r['ID']
    for table in ['Improvements','Eras']:
        for r in d.execute('SELECT ID,Type FROM '+table):types[r['Type']]=r['ID']
    info['GameSpeeds']=lua.table_from({0:lua.table_from({'TrainPercent':speed})})
    lua.globals().GameInfo=info;lua.globals().GameInfoTypes=lua.table_from(types)
    def include(name):
        p=V/'Lua'/(name+'.lua')
        if p.exists():lua.execute(p.read_text(encoding='utf-8'))
    lua.globals().include=include;lua.globals().setupPlayers()
    if missing:lua.execute('GameEvents.UnitCreated=nil;GameEvents.UnitConverted=nil;GameEvents.CombatEnded=nil')
    include('KingdomsCore');return lua

def runtime(d):
    for f in V.rglob('*.lua'):
        lua=LuaRuntime();ok,err=lua.eval('function(s,n) local f,e=loadstring(s,n);return f~=nil,e end')(f.read_text(),str(f));assert ok,err
        assert 'SetUpdate' not in f.read_text(),f
    for speed in [67,100,150,300]:
        lua=fixture(d,speed);lua.execute((R/'tools/tests/kingdoms_assertions.lua').read_text());print('PASS Kingdoms lifecycle at speed',speed)
        for name in ['correctness','combat']:
            lua=fixture(d,speed);lua.execute((R/f'tools/tests/kingdoms_{name}_assertions.lua').read_text())
        print('PASS neutral/support/oath/save, unique rivalry, Farm baseline and CP combat edge cases at speed',speed)
    lua=fixture(d)
    lua.globals().uiControls(','.join(e.attrib['ID'] for e in ET.parse(V/'UI/KingdomsOverview.xml').iter() if 'ID' in e.attrib))
    lua.globals().UISource=(V/'UI/KingdomsOverview.lua').read_text()
    lua.execute((R/'tools/tests/kingdoms_ui_assertions.lua').read_text());print('PASS Kingdoms UI decision callbacks, visibility and reload')
    missing=fixture(d,missing=True)
    missing.execute("local K=MapModData.TheKingdoms;for i=1,100 do nextTurn(0) end;assert(K.State(0).realm>=0);K.Save(0);reload();assert(#K.State(0).history>5)")
    print('PASS optional-hook fallback and reload')
    lua=fixture(d)
    lua.execute("""
local K=MapModData.TheKingdoms
for i=1,500 do nextTurn(0);GameEvents.PlayerDoTurn.Fire(1);if i%50==0 then reload();K=MapModData.TheKingdoms end end
local s=K.State(0);assert(s.nextHouse>2 and s.nextCharacter>2 and #s.history>50)
local id={};for n,h in pairs(s.houses) do assert(not id[h.name]);id[h.name]=true;assert(n==h.id) end
assert(K.State(1).lastTurn==Turn and Players[1].notices==0)
""")
    print('PASS 500-turn two-player AI simulation with ten fresh-context reloads')

def packaging():
    from build_kingdoms_mod import manifest
    path=V/'The Kingdoms (v 1).modinfo'
    assert ET.tostring(ET.parse(path).getroot())==ET.tostring(manifest().getroot()),'Stale standalone manifest'
    names={e.text for e in ET.parse(path).findall('Files/File')}
    for p in (V/'Lua').glob('*.lua'):
        for name in re.findall(r"include\('([^']+)'\)",p.read_text()):assert 'Lua/'+name+'.lua' in names,name
    assert {p.relative_to(V).as_posix() for p in V.rglob('*') if p.is_file() and p.suffix in ['.lua','.sql','.xml','.dds']}==names
    from build_mod import create_manifest,package_name
    integrated=ET.parse(R/(package_name()+'.modinfo')).getroot()
    assert ET.tostring(integrated)==ET.tostring(create_manifest().getroot()),'Stale integrated manifest'
    assert {'TheKingdoms/'+name for name in names}<={e.text for e in integrated.findall('Files/File')}
    sql={p.relative_to(V).as_posix() for p in (V/'SQL').glob('*.sql')}
    assert sql=={e.text for e in ET.parse(path).findall('Actions/OnModActivated/UpdateDatabase')}
    assert {'TheKingdoms/'+name for name in sql}<={e.text for e in integrated.findall('Actions/OnModActivated/UpdateDatabase')}
    for root,name in [(ET.parse(path).getroot(),'UI/KingdomsOverview.xml'),(integrated,'TheKingdoms/UI/KingdomsOverview.xml')]:
        assert len([e for e in root.findall('EntryPoints/EntryPoint') if e.get('type')=='InGameUIAddin' and e.get('file')==name])==1
    print('PASS standalone and integrated manifests, MD5s, database actions, UI entry points and module imports')

def source_contracts():
    audit=R/'.tools/cp-v151-audit'
    if not (audit/'CvUnit.cpp').exists():return
    source=(audit/'CvUnit.cpp').read_text(encoding='utf-8')
    convert=source[source.index('void CvUnit::convert('):source.index('void CvUnit::kill(')]
    assert 'setName(pUnit->getNameNoDesc())' in convert and 'setScriptData' not in convert
    assert convert.index('setHasPromotion')<convert.index('GAMEEVENT_UnitConverted')<convert.index('pUnit->kill(')
    assert 'GAMEEVENT_UnitConverted, pUnit->getOwner(),getOwner(), pUnit->GetID(), GetID(), bIsUpgrade' in convert
    options=(audit/'CustomMods.h').read_text(encoding='utf-8')
    assert re.search(r'#define MOD_EVENTS_RED_COMBAT_ENDED\s+\(MOD_EVENTS_RED_COMBAT && gCustomMods.isEVENTS_RED_COMBAT_ENDED\(\)\)',options)
    combat=(audit/'CvUnitCombat.cpp').read_text(encoding='utf-8')
    ended=combat[combat.index('if (MOD_EVENTS_RED_COMBAT_ENDED)'):combat.index('"CombatEnded"')]
    assert re.findall(r'args->Push\((\w+)\);',ended)==['iAttackingPlayer','iAttackingUnit','attackerDamage','attackerFinalDamage','attackerMaxHP','iDefendingPlayer','iDefendingUnit','defenderDamage','defenderFinalDamage','defenderMaxHP','iInterceptingPlayer','iInterceptingUnit','interceptorDamage','plotX','plotY']
    player=(audit/'CvPlayer.cpp').read_text(encoding='utf-8');capture=player[player.index('"CityCaptureComplete"')-350:player.index('"CityCaptureComplete"')]
    for argument in ['eOldOwner','bCapital','iCityX','iCityY','GetID()','iPopulation','bConquest']:assert argument in capture
    city=(audit/'CvCity.cpp').read_text(encoding='utf-8');assert 'GAMEEVENT_CityTrained, getOwner(), GetID(), pUnit->GetID(), false, false' in city
    for name in ['CanBuild','GetTradeRoutes','GetTradeRoutesAvailable','GetNumMilitaryUnits','GetCurrentResearch','CalculateGoldRate','GetTotalFaithPerTurn']:
        assert 'Method('+name+');' in (audit/'Lua_CvLuaPlayer.cpp').read_text(encoding='utf-8'),name
    for name in ['IsNoOccupiedUnhappiness','CanConstruct','CanTrain','FoodDifference','GetGameTurnFounded']:
        assert 'Method('+name+');' in (audit/'Lua_CvLuaCity.cpp').read_text(encoding='utf-8'),name
    for name in ['GetScriptData','SetScriptData','GetGameTurnCreated','SetName','FinishMoves']:
        assert 'Method('+name+');' in (audit/'Lua_CvLuaUnit.cpp').read_text(encoding='utf-8'),name
    print('PASS CP native contracts: CombatEnded parent/signature, conversion copy/order, capture/training and player/city/unit APIs')

def main():
    d=database();print('PASS Kingdoms SQL against installed CP schema, inheritance, localization and DDS')
    baseline=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/Community Patch Backups/pre-5.4.6/(1) Community Patch (v 151)"
    if baseline.exists():database(baseline).close();print('PASS Kingdoms SQL against retained CP v151 schema')
    runtime(d);packaging();source_contracts()

if __name__=='__main__':main()
