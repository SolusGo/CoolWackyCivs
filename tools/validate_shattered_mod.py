"""Actual CP SQL, Lua 5.1 simulation, persistence, UI and package checks."""
from pathlib import Path
from xml.etree import ElementTree as ET
import sqlite3,sys,re
R=Path(__file__).resolve().parents[1];V=R/'TheShatteredEmpire'
sys.path[:0]=[str(R/'.tools/python'),str(R/'tools')]
from validate_mod import apply_current_cp_schema,quote
from lupa.lua51 import LuaRuntime
from PIL import Image


def database(cp_root=None):
    user=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    source=sqlite3.connect((user/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    d=sqlite3.connect(':memory:');source.backup(d);source.close();apply_current_cp_schema(d,cp_root or user/'MODS/(1) Community Patch');d.row_factory=sqlite3.Row
    d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
        pred=' OR '.join(f"INSTR(CAST({quote(c)} AS TEXT),'IMPERIAL_')>0 OR INSTR(CAST({quote(c)} AS TEXT),'SHATTERED_EMPIRE')>0 OR {quote(c)} IN ('LEADER_LAST_EMPEROR','TRAIT_WEIGHT_OF_EMPIRE')" for c in cols)
        if pred:
            try:d.execute('DELETE FROM '+quote(name)+' WHERE '+pred)
            except sqlite3.OperationalError:pass
    for f in sorted((V/'SQL').glob('*.sql')):
        try:d.executescript(f.read_text(encoding='utf-8'))
        except Exception as error:raise RuntimeError(str(f)+': '+str(error)) from error
    row=lambda table,kind:d.execute('SELECT * FROM '+table+' WHERE Type=?',(kind,)).fetchone()
    assert tuple(d.execute("SELECT Playable,AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_SHATTERED_EMPIRE'").fetchone())==(1,1)
    assert row('Units','UNIT_IMPERIAL_LEGION')['Combat']==10
    assert row('Units','UNIT_IMPERIAL_LEGION')['Cost']==(row('Units','UNIT_WARRIOR')['Cost']*115+99)//100
    assert row('Buildings','BUILDING_IMPERIAL_PALACE')['Cost']==row('Buildings','BUILDING_MONUMENT')['Cost']
    base=dict(d.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_MONUMENT'"));unique=dict(d.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_IMPERIAL_PALACE'"))
    base['YIELD_GOLD']=base.get('YIELD_GOLD',0)+1;assert base==unique
    for prefix,col,original,new in [('Unit_','UnitType','UNIT_WARRIOR','UNIT_IMPERIAL_LEGION'),('Building_','BuildingType','BUILDING_MONUMENT','BUILDING_IMPERIAL_PALACE')]:
        for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            fields=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
            if not name.startswith(prefix) or col not in fields or name in ['Building_YieldChanges','Unit_FreePromotions']:continue
            fields=[f for f in fields if f not in ['ID',col]]
            fetch=lambda key:sorted(tuple(r) for r in d.execute('SELECT '+','.join(map(quote,fields))+' FROM '+quote(name)+' WHERE '+col+'=?',(key,)))
            assert fetch(original)==fetch(new),(name,new)
    translated={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
    for table in ['Civilizations','Leaders','Units','Buildings','Traits','UnitPromotions']:
        for r in d.execute('SELECT * FROM '+table):
            for v in r:
                if isinstance(v,str) and v.startswith('TXT_KEY_IMPERIAL_'):assert v in translated,v
    for r in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'IMPERIAL_%'"):
        with Image.open(V/'Art'/r['Filename']) as im:im.load();assert im.size==(int(r['IconSize'])*int(r['IconsPerRow']),int(r['IconSize'])*int(r['IconsPerColumn'])),(r['Filename'],im.size)
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    print('PASS actual BNW/CP database, full inheritance, localization, AI selection and DDS atlases')
    return d


def fixture(d,speed=100,fallback=False):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().Translations=lua.table_from(dict(d.execute('SELECT Tag,Text FROM Language_en_US')))
    lua.execute((R/'tools/tests/shattered_mock.lua').read_text())
    types={};info=lua.table()
    for table in ['Civilizations','Units','Buildings','UnitPromotions','Resources','Builds','Improvement_ResourceTypes']:
        entries=d.execute('SELECT * FROM '+table).fetchall();info[table]=lua.globals().databaseTable(lua.table_from([lua.table_from(dict(r)) for r in entries]))
        for r in entries:
            if 'Type' in r.keys() and 'ID' in r.keys():types[r['Type']]=r['ID']
    for table in ['Improvements','Technologies','Eras']:
        for r in d.execute('SELECT ID,Type FROM '+table):types[r['Type']]=r['ID']
    info['GameSpeeds']=lua.table_from({0:lua.table_from({'TrainPercent':speed})})
    lua.globals().GameInfo=info;lua.globals().GameInfoTypes=lua.table_from(types)
    def include(name):
        p=V/'Lua'/(name+'.lua')
        if p.exists():lua.execute(p.read_text())
    lua.globals().include=include;lua.globals().setupPlayers(fallback);include('ImperialCore');return lua


def runtime(d):
    for p in V.rglob('*.lua'):
        lua=LuaRuntime(unpack_returned_tuples=True);ok,error=lua.eval('function(s,n) local f,e=loadstring(s,n);return f~=nil,e end')(p.read_text(),str(p));assert ok,error
        assert 'SetUpdate' not in p.read_text(),p
    for speed in [67,100,150,300]:
        for suite in ['lifecycle','conflict','progression']:
            lua=fixture(d,speed);lua.execute((R/f'tools/tests/shattered_{suite}_assertions.lua').read_text())
        lua=fixture(d,speed,True);lua.execute("local I=MapModData.TheShatteredEmpire;assert(Players[0]:GetNumCities()==1);assert(I.State(0).entitlements[1].kind=='settler');local n=0;for u in Players[0]:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_SETTLER then n=n+1 end end;assert(n==2);reload();local m=0;for u in Players[0]:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_SETTLER then m=m+1 end end;assert(m==2)")
        print('PASS starting cities/fallback, political lifecycle, conflict and restoration at speed',speed)
    lua=fixture(d);lua.globals().uiControls(','.join(e.attrib['ID'] for e in ET.parse(V/'UI/ImperialAdministration.xml').iter() if 'ID' in e.attrib));lua.execute((V/'UI/ImperialAdministration.lua').read_text());lua.execute((R/'tools/tests/shattered_ui_assertions.lua').read_text())
    print('PASS all seven UI tabs, decisions, succession, view visibility and Escape')
    lua=fixture(d);lua.execute("local I=MapModData.TheShatteredEmpire;for n=1,500 do nextTurn(0);GameEvents.PlayerDoTurn.Fire(1);if n%50==0 then reload();I=MapModData.TheShatteredEmpire end end;assert(I.State(1).lastTurn==Turn);assert(Players[1].notices==0);assert(#I.State(0).history<=300);assert(I.State(0).authority>=0);assert(I.RebelCount(I.State(0))<=24)")
    print('PASS 500 turns, 22-player fixture, AI politics, bounded records and ten fresh-context reloads')
    lua=fixture(d)
    lua.execute("local I=MapModData.TheShatteredEmpire;local p=Players[0];Turn=1;for n=10,89 do local x,y=2+(n%10)*11,18+math.floor(n/10)*9;assert(not cityAt(x,y),'Fixture city collision');local c=newCity(0,n,x,y);p.cities[n]=c end;for n=1000,1499 do p.units[n]=newUnit(0,n,GameInfoTypes.UNIT_WARRIOR) end;I.Reconcile(I.State(0));I.UnitTick(I.State(0),false);for n=1,30 do nextTurn(0) end;local s=I.State(0);assert(#I.Provinces(s)>=80);local count=0;for _ in pairs(s.units) do count=count+1 end;assert(count>=500);assert(I.RebelCount(s)<=24);I.Save(0);reload();assert(#MapModData.TheShatteredEmpire.Provinces(MapModData.TheShatteredEmpire.State(0))>=80)")
    print('PASS large-empire fixture: 80+ provinces, 500+ units, bounded conflict and reload')


def source_contracts():
    audit=R/'.tools/cp-v151-audit'
    if not (audit/'CvPlayer.cpp').exists():
        print('SKIP CP source audit: local audit source absent');return
    options=(audit/'CustomMods.h').read_text(encoding='utf-8')
    assert re.search(r'#define MOD_EVENTS_RED_COMBAT_ENDED\s+\(MOD_EVENTS_RED_COMBAT && gCustomMods.isEVENTS_RED_COMBAT_ENDED\(\)\)',options)
    source=(audit/'CvUnit.cpp').read_text(encoding='utf-8')
    conversion=source[source.index('void CvUnit::convert('):source.index('void CvUnit::kill(')]
    assert 'GAMEEVENT_UnitConverted, pUnit->getOwner(),getOwner(), pUnit->GetID(), GetID(), bIsUpgrade' in conversion
    assert conversion.index('GAMEEVENT_UnitConverted')<conversion.index('pUnit->kill(')
    combat=(audit/'CvUnitCombat.cpp').read_text(encoding='utf-8');ended=combat[combat.index('if (MOD_EVENTS_RED_COMBAT_ENDED)'):combat.index('"CombatEnded"')]
    assert re.findall(r'args->Push\((\w+)\);',ended)==['iAttackingPlayer','iAttackingUnit','attackerDamage','attackerFinalDamage','attackerMaxHP','iDefendingPlayer','iDefendingUnit','defenderDamage','defenderFinalDamage','defenderMaxHP','iInterceptingPlayer','iInterceptingUnit','interceptorDamage','plotX','plotY']
    player=(audit/'CvPlayer.cpp').read_text(encoding='utf-8')
    capture=player[player.index('"CityCaptureComplete"')-350:player.index('"CityCaptureComplete"')]
    for name in ['eOldOwner','bCapital','iCityX','iCityY','GetID()','iPopulation','bConquest']:assert name in capture
    for file,names in [('Lua_CvLuaPlayer.cpp',['CanFound','Found','CanBuild','GetStartingPlot','IsCapitalConnectedToCity','GetExcessHappiness','GetHandicapType','InitUnit']),('Lua_CvLuaCity.cpp',['CanConstruct','SetPopulation','SetName','GetGameTurnFounded','ChangeResistanceTurns','GetGarrisonedUnit','IsHasBuilding']),('Lua_CvLuaUnit.cpp',['IsCargo','IsEmbarked','SetExperience','GetExperience','PushMission','GetDomainType','GetGameTurnCreated','JumpToNearestValidPlot'])]:
        source=(audit/file).read_text(encoding='utf-8')
        for name in names:assert 'Method('+name+');' in source,(file,name)
    print('PASS native CP founding, conversion, capture, RED combat and Lua binding contracts')


def packaging():
    from build_shattered_mod import manifest
    from build_mod import create_manifest,package_name
    root=ET.parse(V/'The Shattered Empire (v 1).modinfo').getroot();assert ET.tostring(root)==ET.tostring(manifest().getroot())
    combined=ET.parse(R/(package_name()+'.modinfo')).getroot();assert ET.tostring(combined)==ET.tostring(create_manifest().getroot())
    files={e.text for e in root.findall('Files/File')};combined_files={e.text for e in combined.findall('Files/File')}
    assert {'TheShatteredEmpire/'+n for n in files}<=combined_files
    for p in (V/'Lua').glob('*.lua'):
        for name in re.findall(r"include\('([^']+)'\)",p.read_text()):assert 'Lua/'+name+'.lua' in files
    for root,file in [(root,'UI/ImperialAdministration.xml'),(combined,'TheShatteredEmpire/UI/ImperialAdministration.xml')]:assert len([e for e in root.findall('EntryPoints/EntryPoint') if e.get('file')==file])==1
    print('PASS standalone and collection registration, checksums and single simulation owner')


def main():
    d=database()
    baseline=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/Community Patch Backups/pre-5.4.6/(1) Community Patch (v 151)"
    if baseline.is_dir():database(baseline).close();print('PASS Shattered Empire SQL against retained CP v151 baseline schema')
    source_contracts();runtime(d);packaging()


if __name__=='__main__':main()
