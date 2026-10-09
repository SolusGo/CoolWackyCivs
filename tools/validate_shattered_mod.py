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


def fixture(d,speed=100,fallback=False,before_core=None,source=None):
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
        if p.exists():lua.execute(source(name) if source else p.read_text())
    lua.globals().include=include;lua.globals().setupPlayers(fallback)
    if before_core:lua.execute(before_core)
    include('ImperialCore');return lua


def runtime(d):
    for p in V.rglob('*.lua'):
        lua=LuaRuntime(unpack_returned_tuples=True);ok,error=lua.eval('function(s,n) local f,e=loadstring(s,n);return f~=nil,e end')(p.read_text(),str(p));assert ok,error
        assert 'SetUpdate' not in p.read_text(),p
    for speed in [67,100,150,300]:
        for suite in ['lifecycle','conflict','progression','hardening','defection']:
            lua=fixture(d,speed);lua.execute((R/f'tools/tests/shattered_{suite}_assertions.lua').read_text())
        lua=fixture(d,speed,True);lua.execute("local I=MapModData.TheShatteredEmpire;assert(Players[0]:GetNumCities()==1);assert(I.State(0).entitlements[1].kind=='settler');local n=0;for u in Players[0]:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_SETTLER then n=n+1 end end;assert(n==2);reload();local m=0;for u in Players[0]:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_SETTLER then m=m+1 end end;assert(m==2)")
        print('PASS starting cities/fallback, political lifecycle, conflict and restoration at speed',speed)
    lua=fixture(d);lua.globals().uiControls(','.join(e.attrib['ID'] for e in ET.parse(V/'UI/ImperialAdministration.xml').iter() if 'ID' in e.attrib));lua.execute((V/'UI/ImperialAdministration.lua').read_text());lua.execute((R/'tools/tests/shattered_ui_assertions.lua').read_text())
    print('PASS all seven UI tabs, decisions, succession, view visibility and Escape')
    lua=fixture(d);lua.globals().uiControls(','.join(e.attrib['ID'] for e in ET.parse(V/'UI/ImperialAdministration.xml').iter() if 'ID' in e.attrib));lua.execute((V/'UI/ImperialAdministration.lua').read_text())
    lua.execute("""
local I=MapModData.TheShatteredEmpire;local s=I.State(0);local g=I.Provinces(s)[1];I.City(g,0).b[GameInfoTypes.BUILDING_IMPERIAL_PALACE]=1
Controls.ImperialStatus.click();Instances.ImperialTabs[3].TabChoice.click()
local found=false;local price=I.CharterCost(s,g)
for _,row in ipairs(Instances.ImperialActions) do local action=row.ActionChoice;if action.text:find(I.Text('ACTION_CHARTER'),1,true) then found=true;assert(action.text:find(tostring(price),1,true) and action.text:find('5 Authority',1,true));assert(action.tooltip==I.Text('CHARTER_COST')) end end
assert(found);I.BeginRevolt(s,g);g.actionNext=0;s.authority=80;LuaEvents.ImperialChanged(0);found=false;price=I.CharterCost(s,g)
for _,row in ipairs(Instances.ImperialActions) do local action=row.ActionChoice;if action.text:find(I.Text('ACTION_SETTLEMENT'),1,true) then found=true;assert(action.text:find(tostring(price),1,true) and action.text:find('10 Authority',1,true));assert(action.tooltip==I.Text('SETTLEMENT_COST')) end end
assert(found)
-- Closed status ignores battles when the displayed Authority is unchanged.
Controls.ImperialClose.click();LuaEvents.ImperialChanged(0);local refreshes=0;local text=Controls.ImperialStatus.SetText
Controls.ImperialStatus.SetText=function(self,value) refreshes=refreshes+1;return text(self,value) end
for n=1,10 do LuaEvents.ImperialChanged(0) end;assert(refreshes==0)
I.Authority(s,1);LuaEvents.ImperialChanged(0);assert(refreshes==1)
""")
    print('PASS actual charter/settlement UI costs, consequence tooltips and closed-screen refresh filtering')
    lua=fixture(d);lua.execute("local I=MapModData.TheShatteredEmpire;for n=1,500 do nextTurn(0);GameEvents.PlayerDoTurn.Fire(1);if n%50==0 then reload();I=MapModData.TheShatteredEmpire end end;assert(I.State(1).lastTurn==Turn);assert(Players[1].notices==0);assert(#I.State(0).history<=300);assert(I.State(0).authority>=0);assert(I.RebelCount(I.State(0))<=24)")
    print('PASS 500 turns, 22-player fixture, AI politics, bounded records and ten fresh-context reloads')
    lua=fixture(d)
    lua.execute("local I=MapModData.TheShatteredEmpire;local p=Players[0];Turn=1;for n=10,89 do local x,y=2+(n%10)*11,18+math.floor(n/10)*9;assert(not cityAt(x,y),'Fixture city collision');local c=newCity(0,n,x,y);p.cities[n]=c end;for n=1000,1499 do p.units[n]=newUnit(0,n,GameInfoTypes.UNIT_WARRIOR) end;I.Reconcile(I.State(0));I.UnitTick(I.State(0),false);for n=1,30 do nextTurn(0) end;local s=I.State(0);assert(#I.Provinces(s)>=80);local count=0;for _ in pairs(s.units) do count=count+1 end;assert(count>=500);assert(I.RebelCount(s)<=24);I.Save(0);reload();assert(#MapModData.TheShatteredEmpire.Provinces(MapModData.TheShatteredEmpire.State(0))>=80)")
    print('PASS large-empire fixture: 80+ provinces, 500+ units, bounded conflict and reload')
    lua=fixture(d);lua.execute((R/'tools/tests/shattered_stress_assertions.lua').read_text())
    print('PASS 100+ provinces/650+ units: combat, creation, dirty effects, war, demands, decisions, 100 turns, reloads, restoration and AI save coalescing')
    starting_maps(d)


def starting_maps(d):
    common="""
for pid=1,21 do Players[pid].alive=false;Players[pid].cities={};Players[pid].units={} end
local p=Players[0];local native=p.CanFound
p.CanFound=function(self,x,y) local plot=Map.GetPlot(x,y);if not plot then return false end;local reveal=plot.revealed;plot.revealed=true;local result=native(self,x,y);plot.revealed=reveal;return result end
"""
    profiles={
        'pangaea':('',3),
        'continents':("for y=0,30 do Map.GetPlot(12,y).water=true end",3),
        'terra':("for y=0,30 do for x=12,18 do Map.GetPlot(x,y).water=true end end",3),
        'islands':("for x=7,13 do for y=7,13 do if x==7 or x==13 or y==7 or y==13 then Map.GetPlot(x,y).water=true end end end",1),
        'mountain basin':("for x=7,13 do for y=7,13 do if x==7 or x==13 or y==7 or y==13 then Map.GetPlot(x,y).mountain=true end end end",1),
        'unrevealed':("for x=2,18 do for y=2,18 do Map.GetPlot(x,y).revealed=false end end",1),
        'foreign ownership':("for x=2,18 do for y=2,18 do Map.GetPlot(x,y).owner=2 end end",1),
        'occupied':("for x=2,18 do for y=2,18 do if Map.PlotDistance(10,10,x,y)>3 then local u=newUnit(2,x*20+y,GameInfoTypes.UNIT_WARRIOR);u.x=x;u.y=y;Players[2].units[u.id]=u end end end",1),
        'rival start':("Players[2].alive=true;Players[2].GetStartingPlot=function() return Map.GetPlot(10,10) end",3),
        'no valid plots':("Players[0].noFound=true",1),
        'wrapped boundary':("WrapX=true;Players[0].cities[0].x=1",3),
        'small torus':("WrapX=true;WrapY=true;MapWidth=7;MapHeight=7;Players[0].cities[0].x=3;Players[0].cities[0].y=3;Players[0].units[0].x=3;Players[0].units[0].y=3",1),
    }
    for name,(setup,cities) in profiles.items():
        lua=fixture(d,before_core=common+setup)
        lua.globals().ExpectedCities=cities
        lua.globals().CheckRival=name=='rival start'
        lua.execute("""
local I=MapModData.TheShatteredEmpire;local s=I.State(0);assert(Players[0]:GetNumCities()==ExpectedCities)
if CheckRival then for c in Players[0]:Cities() do if not c:IsCapital() then assert(Map.PlotDistance(10,10,c.x,c.y)>6) end end end
assert(s.startComplete and s.entitlements[1] and s.entitlements[2]);local keys={}
for slot=1,2 do local e=s.entitlements[slot];if e.kind=='city' then assert(not keys[e.key]);keys[e.key]=true end end
local units=0;for _ in pairs(Players[0].units) do units=units+1 end
reload();I=MapModData.TheShatteredEmpire;local after=0;for _ in pairs(Players[0].units) do after=after+1 end
assert(after==units and Players[0]:GetNumCities()==ExpectedCities)
""")
    # Save from the founding callback, then reload that interrupted snapshot.
    lua=fixture(d,before_core=common+"""
GameEvents.PlayerCityFounded.Add(function(pid)
 local I=MapModData.TheShatteredEmpire;if pid==0 and not Interrupted then I.Save(0);Interrupted={};for k,v in pairs(Saved) do Interrupted[k]=v end end
end)
""")
    lua.execute("""
-- The first callback ran before the mod's handler, leaving a pending ledger entry.
local p=Players[0];for id,c in pairs(p.cities) do if c.name==Translations.TXT_KEY_IMPERIAL_PROVINCE_II then p.cities[id]=nil end end
Saved=Interrupted;reload();assert(p:GetNumCities()==3)
local I=MapModData.TheShatteredEmpire;assert(I.State(0).startComplete);reload();assert(p:GetNumCities()==3)
""")
    lua=fixture(d,100,True,before_core=common+"""
GameEvents.UnitCreated.Add(function(pid,uid,kind)
 local I=MapModData.TheShatteredEmpire;if pid==0 and kind==GameInfoTypes.UNIT_SETTLER and not Interrupted then I.Save(0);Interrupted={};for k,v in pairs(Saved) do Interrupted[k]=v end;FirstSettler=uid end
end)
""")
    lua.execute("for uid,u in pairs(Players[0].units) do if u.kind==GameInfoTypes.UNIT_SETTLER and uid~=FirstSettler then Players[0].units[uid]=nil end end;Saved=Interrupted;reload();local n=0;for u in Players[0]:Units() do if u.kind==GameInfoTypes.UNIT_SETTLER then n=n+1 end end;assert(n==2);reload();n=0;for u in Players[0]:Units() do if u.kind==GameInfoTypes.UNIT_SETTLER then n=n+1 end end;assert(n==2)")
    for turn,founded in [(20,0),(1,0),(20,20)]:
        lua=fixture(d,before_core=common+f'Turn={turn};Players[0].cities[0].founded={founded}')
        lua.execute('assert(Players[0]:GetNumCities()==1 and Players[0].cities[0].pop==1);assert(MapModData.TheShatteredEmpire.State(0).startComplete);reload();assert(Players[0]:GetNumCities()==1)')
    lua=fixture(d,100,True,before_core=common+"local p=Players[0];local init=p.InitUnit;local failed=false;p.InitUnit=function(self,kind,...) if kind==GameInfoTypes.UNIT_SETTLER and not failed then failed=true;return nil end;return init(self,kind,...) end")
    lua.execute("assert(not MapModData.TheShatteredEmpire.State(0).startComplete);reload();local n=0;for u in Players[0]:Units() do if u.kind==GameInfoTypes.UNIT_SETTLER then n=n+1 end end;assert(n==2 and MapModData.TheShatteredEmpire.State(0).startComplete);reload();n=0;for u in Players[0]:Units() do if u.kind==GameInfoTypes.UNIT_SETTLER then n=n+1 end end;assert(n==2)")
    print('PASS twelve local map profiles, wrapping, fog, barriers, rival starts, occupancy, interrupted/failed grants and old-save exclusions')


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
