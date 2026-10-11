"""CP database, art/package, Lua 5.1 lifecycle and event-driven UI checks for Paradise."""
from pathlib import Path
from xml.etree import ElementTree as ET
import re
import sqlite3
import struct
import sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from validate_mod import apply_current_cp_schema,directxtex_checks
from build_mod import read_project,create_manifest
C=R/'TheBoyWhoTouchedParadise'

def database_checks():
    game=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    src=sqlite3.connect((game/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    db=sqlite3.connect(':memory:');src.backup(db);src.close()
    apply_current_cp_schema(db,game/'MODS/(1) Community Patch');db.row_factory=sqlite3.Row
    db.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    # Paradise must work without any other civilization enabling these hooks.
    db.execute("UPDATE CustomModOptions SET Value=0 WHERE Name LIKE 'EVENTS_%'")
    for path in sorted((C/'SQL').glob('*.sql')):db.executescript(path.read_text(encoding='utf-8'))
    expected={'EVENTS_CITY','EVENTS_CITY_CAPITAL','EVENTS_GOLDEN_AGE','EVENTS_MINORS',
        'EVENTS_MINORS_INTERACTION','EVENTS_UNIT_CREATED','EVENTS_UNIT_PREKILL','EVENTS_UNIT_CAPTURE','EVENTS_UNIT_CONVERTS'}
    assert {r[0] for r in db.execute("SELECT Name FROM CustomModOptions WHERE Name LIKE 'EVENTS_%' AND Value=1")}==expected
    def row(table,key):return db.execute(f'SELECT * FROM {table} WHERE Type=?',(key,)).fetchone()
    assert tuple(row('Civilizations','CIVILIZATION_BOY_TOUCHED_PARADISE')[k] for k in ['Playable','AIPlayable'])==(1,0)
    assert row('Traits','TRAIT_PARADISE_POINT_OF_DIFFERENCE')['GreatPeopleRateModifier']==5
    hero=row('Units','UNIT_PARADISE_EL_DIEZ')
    for key,value in dict(Cost=-1,Moves=2,Combat=0,RangedCombat=0,Found=0,WorkRate=0,FoundReligion=0,NoMaintenance=1).items():assert hero[key]==value,(key,hero[key])
    assert hero['Special'] is None and hero['Capture'] is None
    assert hero['UnitArtInfo']=='ART_DEF_UNIT_GREAT_MERCHANT'
    assert not db.execute("SELECT 1 FROM Unit_Builds WHERE UnitType='UNIT_PARADISE_EL_DIEZ'").fetchone()
    assert row('UnitClasses','UNITCLASS_PARADISE_EL_DIEZ')['MaxPlayerInstances']==1
    base=row('Buildings','BUILDING_AMPHITHEATER');potrero=row('Buildings','BUILDING_PARADISE_POTRERO')
    excluded={'ID','Type','Description','Civilopedia','Strategy','Help','GreatPeopleRateModifier','PortraitIndex','IconAtlas'}
    for k in base.keys():
        if k not in excluded:assert potrero[k]==base[k],('Amphitheater scalar inheritance',k)
    assert potrero['GreatPeopleRateModifier']==base['GreatPeopleRateModifier']+10
    for table, in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'Building_%'").fetchall():
        if table.endswith('_new'):continue
        columns=[r[1] for r in db.execute('PRAGMA table_info('+table+')')]
        if 'BuildingType' not in columns:continue
        rest=[c for c in columns if c!='BuildingType']
        a=[tuple(r) for r in db.execute(f'SELECT {",".join(rest)} FROM {table} WHERE BuildingType=?',('BUILDING_AMPHITHEATER',))]
        b=[tuple(r) for r in db.execute(f'SELECT {",".join(rest)} FROM {table} WHERE BuildingType=?',('BUILDING_PARADISE_POTRERO',))]
        if table=='Building_YieldChanges':
            assert sum(r[1] for r in b if r[0]=='YIELD_CULTURE')==sum(r[1] for r in a if r[0]=='YIELD_CULTURE')+1
        else:assert a==b,('Amphitheater companion inheritance',table)
    assert row('BuildingClasses','BUILDINGCLASS_PARADISE_LAST_DANCE')['MaxPlayerInstances']==1
    assert row('Buildings','BUILDING_PARADISE_LAST_DANCE')['Cost']==450
    assert row('Buildings','BUILDING_PARADISE_HOPE')['BuildingDefenseModifier']==15
    fulfilled=row('Buildings','BUILDING_PARADISE_FULFILLED')
    assert dict(db.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_PARADISE_PRESENCE'"))=={'YIELD_CULTURE':2,'YIELD_GOLDEN_AGE_POINTS':2}
    assert tuple(fulfilled[k] for k in ['UnmoddedHappiness','GlobalCultureRateModifier','GlobalGreatPeopleRateModifier'])==(2,10,10)
    assert dict(db.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_PARADISE_MEMORIAL'"))=={'YIELD_CULTURE':2,'YIELD_TOURISM':4}
    for table in ['Civilizations','Leaders','Traits','Units','UnitClasses','Buildings','BuildingClasses']:
        assert not db.execute(f"SELECT Type FROM {table} WHERE Type LIKE '%PARADISE%' GROUP BY Type HAVING COUNT(*)<>1").fetchall()
    texts={r[0] for r in db.execute('SELECT Tag FROM Language_en_US')}
    for path in (C/'SQL').glob('*.sql'):
        assert set(re.findall(r"'(TXT_KEY_[^']+)'",path.read_text(encoding='utf-8')))<=texts,path
    from PIL import Image
    art={p.name:p for p in (C/'Art').glob('*.dds')}
    for row_ in db.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'PARADISE_%'"):
        with Image.open(art[row_['Filename']]) as im:
            assert im.size==(row_['IconSize']*int(row_['IconsPerRow']),row_['IconSize']*int(row_['IconsPerColumn'])),(row_['Filename'],im.size);im.load()
    for path in art.values():assert struct.unpack_from('<I',path.read_bytes(),28)[0]>1,('Missing mipmaps',path)
    directxtex_checks(list(art.values()))
    assert db.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    print('PASS Paradise SQL: human-only, complete live Amphitheater inheritance, hero/wonder restrictions, exact native effects, localization and 39 mipmapped DDS textures')

def static_checks():
    runtime=(C/'Lua/ParadiseRuntime.lua').read_text(encoding='utf-8')
    panel=(C/'UI/ParadiseJourney.lua').read_text(encoding='utf-8')
    assert 'SetUpdate' not in panel and 'PlayerDoTurn' not in panel and 'ParadiseRuntime' not in panel
    assert 'SetValue' not in panel and 'SetNumRealBuilding' not in panel
    assert 'MESSI_' not in runtime and 'Messi|' not in runtime
    entries=[e.get('file') for e in create_manifest().getroot().findall('EntryPoints/EntryPoint')]
    assert entries.count('TheBoyWhoTouchedParadise/Lua/ParadiseRuntime.lua')==1
    assert entries.count('TheBoyWhoTouchedParadise/UI/ParadiseJourney.xml')==1
    assert entries.index('TheBoyWhoTouchedParadise/Lua/ParadiseRuntime.lua')<entries.index('TheBoyWhoTouchedParadise/UI/ParadiseJourney.xml')
    names={name for name,_ in read_project()[3]}
    assert all(p.relative_to(R).as_posix() in names for p in C.rglob('*') if p.is_file() and p.suffix.lower() in ['.lua','.xml','.sql','.dds'])
    print('PASS Paradise packaging: independent gameplay/UI add-ins, separate namespace, all files registered, no UI polling or gameplay ownership')

def fixture():
    from lupa.lua51 import LuaRuntime
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute((R/'tools/tests/paradise_mock.lua').read_text(encoding='utf-8'))
    def include(name):
        if name=='ParadisePersistence':lua.execute((C/'Lua/ParadisePersistence.lua').read_text(encoding='utf-8'))
        else:raise AssertionError('Unexpected gameplay include '+name)
    lua.globals().include=include
    def reload():
        lua.execute('MapModData.Paradise=nil;ResetEvents()')
        lua.execute((C/'Lua/ParadiseRuntime.lua').read_text(encoding='utf-8'))
    lua.globals().ReloadParadise=reload
    reload()
    return lua

def gameplay_checks():
    lua=fixture();lua.execute((R/'tools/tests/paradise_assertions.lua').read_text(encoding='utf-8'))
    print('PASS Paradise gameplay: native rewards/exclusions, all magic, three acts, pressure, recovery, capture/deletion, reload, final eligibility and once-only fulfillment')
    for speed,turns in [(0,3),(1,5),(2,8),(3,15)]:
        lua=fixture();lua.execute(f'SetSpeed({speed});Hero():Kill(false,-1);assert(S().recoveryRemaining=={turns});NextTurn({turns});assert(HeroCount()==1)')
        lua.execute('Players[1].alive=false;Hero():Kill(false,-1);NextTurn(50);assert(HeroCount()==0)')
    lua=fixture();lua.execute('''
        AdvanceEra(4);local first=S().challenge.serial;NextTurn(26)
        assert(not S().challenge and S().comebackDue and not S().recovered)
        NextTurn(8);assert(S().challenge.serial>first)
        GoldenStart();assert(S().recovered and S().dreams==8)
    ''')
    lua=fixture();lua.execute('''
        NativeGP(80,'generated');AdvanceEra(4);NextTurn()
        assert(not S().recovered,'birth preceding challenge must not qualify')
        NativeGP(80,'generated');NextTurn();assert(S().recovered)
    ''')
    lua=fixture();lua.execute('''
        NativeConstruct(Players[1].cities[1],20,'built');AdvanceEra(4)
        NextTurn(8);assert(S().recovered)
        GoldenStart();GoldenEnd();GoldenStart()
        for i=1,16 do NativeGP(80,'generated')end;NextTurn();AdvanceEra(5)
        assert(S().eligible,'no-loss / no-CS / no-Wonder route must be viable')
        for id=2,5 do Players[id].alive=false end
        assert(MapModData.Paradise.UseMagic(1,'BEAUTY'))
    ''')
    lua=fixture();lua.execute('''
        AdvanceEra(3);NextTurn(225)
        assert(S().pressure==100 and Players[1].cities[1]:GetNumRealBuilding(33)==1)
        NativeGP(80,'generated');NextTurn();local reduced=S().pressure
        NativeGP(80,'generated');NextTurn();assert(S().pressure==reduced,'era pressure relief cap')
        local c=Players[1].cities[2];c.buildings[34]=1
        Players[1].cities[2]=nil;Players[0].cities[2]=c;c.owner=0
        GameEvents.CityCaptureComplete(1,false,5,3,0,4,true)
        local loss=S().pressure
        assert(c:GetNumRealBuilding(34)==0,'temporary effect on capture')
        Players[0].cities[2]=nil;Players[1].cities[2]=c;c.owner=1
        GameEvents.CityCaptureComplete(0,false,5,3,1,4,true)
        Players[1].cities[2]=nil;Players[0].cities[2]=c;c.owner=0
        GameEvents.CityCaptureComplete(1,false,5,3,0,4,true)
        assert(S().pressure==loss and S().dreams==4,'stable city loss prevents repeatable effects')
    ''')
    lua=fixture();lua.execute('''
        NativeConstruct(Players[1].cities[1],22,'built');AdvanceEra(1)
        NativeConstruct(Players[1].cities[1],23,'built');GameEvents.MinorAlliesChanged(2,1,true,20,60)
        GameEvents.MinorAlliesChanged(3,1,true,20,60);NativeConstruct(Players[1].cities[1],20,'built')
        NativeConstruct(Players[1].cities[2],20,'built');Players[1].greatWorks=2;GameEvents.GreatWorkCreated(1,1,1)
        local s=S();assert(s.objectives[3].done and s.objectives[4].done and s.objectives[6].done)
        local data=ParadisePersistence.Read(1)
        data.memories[#data.memories+1]={id='unicode',title='Rosario: alegría; 10',category='journey',description='A | : ; \\" dream',turn=1,era=0,city='Rosario'}
        ParadisePersistence.Write(1,data);ReloadParadise()
        assert(S().memories[#S().memories].title=='Rosario: alegría; 10','typed save codec roundtrip')
    ''')
    print('PASS Paradise adversarial: Quick/Standard/Epic/Marathon recovery, elimination, failed crisis retry, post-activation achievements and no-loss/no-CS/no-Wonder route')

def stability_checks():
    # Every native GP class, every exclusion, non-capital births and early duplicates.
    for typ in range(80,89):
        lua=fixture()
        lua.execute(f"""
            for _,source in ipairs({{'free','scripted','purchased'}})do NativeGP({typ},source,2)end
            NextTurn();assert(S().gp==0 and S().dreams==0 and S().lifetime==0)
            local converted=NativeGP({typ},'scripted',2)
            GameEvents.UnitConverted(0,1,99,converted.id,false)
            local pending=ParadisePersistence.Read(1).pending
            assert(pending[next(pending)].excluded,'conversion birth was not excluded')
            NextTurn();assert(S().gp==0)
            local u=NativeGP({typ},'generated',2,function(unit)
                GameEvents.UnitCreated(1,unit.id,unit.typ,unit.x,unit.y)
                assert(next(ParadisePersistence.Read(1).pending),'early duplicate erased native evidence')
            end)
            NextTurn();assert(S().gp==1 and S().dreams==2 and S().lifetime==2)
            GameEvents.UnitCreated(1,u.id,u.typ,u.x,u.y);NextTurn();assert(S().gp==1)
        """)
        lua=fixture()
        lua.execute(f"""
            NativeGP({typ},'generated',2,function()ReloadParadise()end)
            NextTurn();assert(S().gp==1 and S().dreams==2,'creation/save/load/native settlement')
        """)
    lua=fixture();lua.execute('''
        for typ=80,88 do NativeGP(typ,'scripted',2);NativeGP(typ,'generated',2)end
        NextTurn();assert(S().gp==9 and S().dreams==18 and S().lifetime==18,'nearby shared/distinct counter births')
        local gift=GameEvents.PlayerCanGiftUnit.handlers[1]
        assert(not gift(1,2,Hero().id) and gift(1,2,99999))
        local ordinary=Players[1]:InitUnit(80,3,3);local foreign=Players[0]:InitUnit(80,1,1)
        assert(gift(1,2,ordinary.id) and gift(0,2,foreign.id),'unrelated unit gifting changed')
        Players[2].alive=false;assert(not gift(1,2,Hero().id) and gift(1,99,ordinary.id))
        local foreignHero=Players[0]:InitUnit(10,1,1)
        assert(foreignHero:IsDelayedDeath() and Players[0]:GetUnitByID(foreignHero.id)==nil,'foreign hero retained')
    ''')
    lua=fixture();lua.execute('''
        AdvanceEra(3);local baseline=S().pressure
        NativeGP(80,'generated',2);NextTurn();assert(S().pressure==baseline-8)
        NativeGP(85,'generated',2);NextTurn();assert(S().pressure==baseline-8,'per-era GP relief repeated')
        AdvanceEra(4);baseline=S().pressure
        NativeGP(84,'generated',2);NextTurn()
        -- Third owner turn also adds the unchanged Act II passive +1 Pressure.
        assert(S().gp==3 and S().recovered and S().dreams==11 and S().pressure==baseline-37)
    ''')
    lua=fixture();lua.execute('''
        for i=1,3 do NativeGP(80,'generated')end;NextTurn()
        assert(MapModData.Paradise.UseMagic(1,'HOPE'))
        GoldenStart();GameEvents.MinorAlliesChanged(2,1,true,20,60);AdvanceEra(4)
        Hero():Kill(false,-1)
        local encoded=Saved['PARADISE_v1|1'];local before=ParadisePersistence.Read(1)
        assert(before.lifetime>before.dreams and before.challenge and before.recoveryDue>before.clock)
        assert(before.act==2 and before.crisis and before.pressure>0 and #before.memories>0)
        ReloadParadise();assert(Saved['PARADISE_v1|1']==encoded,'existing save values or format changed')
        assert(S().lifetime==before.lifetime and S().dreams==before.dreams and S().story==before.story)
        local clock=S().clock;GameEvents.PlayerDoTurn(1);GameEvents.PlayerDoTurn(1)
        assert(S().clock==clock,'reloaded duplicate owner-turn advanced timers')
    ''')
    lua=fixture();lua.execute((C/'Lua/ParadiseRuntime.lua').read_text(encoding='utf-8'))
    lua.execute('for name,event in pairs(GameEvents)do assert(#event.handlers==1,name.." registered twice")end')
    # Serialized by the actual v24 runtime at commit 484cf33, not a new schema.
    lua=fixture()
    lua.execute('''
        Hero():Kill(false,-1);SetTurn(1);Players[1].era=4;Players[1].ga=10
        for i=1,3 do Unit(1,80,3,3)end;Unit(1,81,5,3)
        Players[1].thresholds[100]=400;Players[1].thresholds[101]=200
    ''')
    data=(R/'tools/tests/paradise_v24_save.txt').read_text(encoding='utf-8')
    lua.globals().Saved['PARADISE_v1|1']=data
    lua.execute('''
        local encoded=Saved['PARADISE_v1|1'];ReloadParadise()
        assert(Saved['PARADISE_v1|1']==encoded,'v24 save reset or rewritten during reconciliation')
        assert(S().dreams==5 and S().lifetime==11 and S().gp==3 and S().pressure==65)
        assert(S().challenge and not S().recovered and S().recoveryRemaining==5 and S().story=='DENIED')
        assert(S().claims['MagicEra|0'] and S().distinctAllies['2'] and not S().fulfilled)
        NextTurn();assert(S().gp==4 and S().recovered and S().dreams==12 and S().lifetime==18)
        ReloadParadise();NextTurn();assert(S().gp==4 and S().dreams==12,'v24 pending birth/recovery duplicated')
    ''')
    print('PASS Paradise stability: nine GP classes, early duplicates, non-capital/shared counters, pending-birth reload, gifting isolation, unchanged save bytes and single event registration')


def ui_checks():
    lua=fixture()
    lua.execute((R/'tools/tests/paradise_ui_mock.lua').read_text(encoding='utf-8'))
    panel=(C/'UI/ParadiseJourney.lua').read_text(encoding='utf-8')
    def reload_ui():
        lua.execute('if ContextPtr and ContextPtr.shutdown then ContextPtr.shutdown()end;SetupJourneyUI()')
        lua.execute(panel)
    lua.globals().ReloadJourneyUI=reload_ui
    def include(name):
        if name=='ParadisePersistence':lua.execute((C/'Lua/ParadisePersistence.lua').read_text(encoding='utf-8'))
        elif name not in ['IconSupport','InstanceManager']:raise AssertionError(name)
    lua.globals().include=include
    reload_ui()
    lua.execute((R/'tools/tests/paradise_ui_assertions.lua').read_text(encoding='utf-8'))
    lua.execute('MapModData.Paradise=nil;SetActive(1)');reload_ui()
    lua.execute('assert(Controls.JourneyLauncher.hidden and Controls.JourneyPanel.hidden and Controls.JourneyCinematic.hidden)')
    print('PASS Paradise UI: normal/reversed/missing/nested popup lifecycles, synchronous toggle-close, city/diplomacy/fullscreen returns, repeated events, modal ownership/shutdown, pending-finale reload and explicit acknowledgement')

if __name__=='__main__':
    database_checks();static_checks();gameplay_checks();stability_checks();ui_checks()
    print('Paradise validation passed. Live Civ V rendering/capture timing remains on the smoke-test checklist.')
