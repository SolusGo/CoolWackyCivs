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
    for path in sorted((C/'SQL').glob('*.sql')):db.executescript(path.read_text(encoding='utf-8'))
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

def ui_checks():
    lua=fixture()
    lua.execute(r'''
      Locale={ConvertTextKey=function(key)return key end};Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
      InterfaceModeTypes={INTERFACEMODE_SELECTION=1};UI={IsCityScreenUp=function()return false end}
      UIManager={modal=0,GetScreenSizeVal=function()return 1024,768 end,
       PushModal=function(self)self.modal=self.modal+1 end,PopModal=function(self)self.modal=self.modal-1 end}
      Vector4=function(...)return {...}end
      ContextPtr={SetInputHandler=function(self,f)self.input=f end}
      function Control()
       local c={hidden=false,disabled=false}
       function c:SetHide(v)self.hidden=v end;function c:SetDisabled(v)self.disabled=v end
       function c:SetText(v)self.text=v end;function c:SetTexture(v)self.texture=v end
       function c:SetColor(v)self.color=v end;function c:SetSizeVal(x,y)self.size={x,y}end
       function c:SetToolTipString(v)self.tooltip=v end;function c:RegisterCallback(button,f)self.callback=f end
       function c:CalculateSize()end;function c:ReprocessAnchoring()end;function c:CalculateInternalSize()end
       return c
      end
      Controls=setmetatable({},{__index=function(t,k)local c=Control();rawset(t,k,c);return c end})
      IconHookup=function(n,size,atlas,c)c.icon=n end
      InstanceManager={new=function()return {ResetInstances=function()end,GetInstance=function()return {
       MemoryRoot=Control(),MemoryIcon=Control(),MemoryTitle=Control(),MemoryText=Control()}end}end}
      Events={}
      for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','ActivePlayerTurnEnd','SerialEventEnterCityScreen',
       'SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopup',
       'SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed','InterfaceModeChanged'})do Events[name]=Event()end
    ''')
    lua.globals().include=lambda name: None if name in ['IconSupport','InstanceManager'] else (_ for _ in ()).throw(AssertionError(name))
    panel=(C/'UI/ParadiseJourney.lua').read_text(encoding='utf-8')
    lua.execute(panel)
    lua.execute('''
       assert(not Controls.JourneyLauncher.hidden and Controls.JourneyPanel.hidden)
       Controls.JourneyLauncher.callback();assert(not Controls.JourneyPanel.hidden and UIManager.modal==1)
       Controls.MagicTab.callback();assert(not Controls.MagicStack.hidden and Controls.PassButton.disabled)
       Events.SerialEventEnterCityScreen();assert(Controls.JourneyLauncher.hidden and Controls.JourneyPanel.hidden and UIManager.modal==0)
       Events.SerialEventExitCityScreen();assert(not Controls.JourneyPanel.hidden)
       Controls.JourneyClose.callback();assert(UIManager.modal==0)
       for i=1,3 do NativeGP(80,'generated')end;NextTurn()
       Controls.JourneyLauncher.callback();Controls.MagicTab.callback()
       assert(not Controls.PassButton.disabled)
       Controls.PassButton.callback();assert(S().dreams==0 and Players[1].science==30,'button executes authoritative magic')
       Controls.JourneyClose.callback()
       AdvanceEra(4);assert(not Controls.JourneyCinematic.hidden and Controls.CinematicArt.texture=='ParadiseHeartbreak.dds')
       Controls.CinematicContinue.callback();assert(Controls.JourneyCinematic.hidden)
       Events.SerialEventGameMessagePopup({Type=1});Events.SerialEventGameMessagePopupShown({Type=1})
       assert(Controls.JourneyLauncher.hidden);Events.SerialEventGameMessagePopupProcessed(1)
       assert(not Controls.JourneyLauncher.hidden)
       Events.AILeaderMessage();assert(Controls.JourneyLauncher.hidden);Events.LeavingLeaderViewMode()
       assert(not Controls.JourneyLauncher.hidden)
       NativeConstruct(Players[1].cities[1],20,'built');NextTurn(8)
       Controls.CinematicContinue.callback()
       GoldenStart();GoldenEnd();GoldenStart()
       for i=1,16 do NativeGP(80,'generated')end;NextTurn();AdvanceEra(5)
       NativeConstruct(Players[1].cities[1],21,'built')
       assert(not Controls.JourneyCinematic.hidden and Controls.CinematicArt.texture=='ParadiseFinalPeak.dds')
       assert(Controls.CinematicMemories.text:find('The Final Peak',1,true) and UIManager.modal==1)
       Controls.CinematicContinue.callback();assert(S().finalShown and UIManager.modal==0)
       SetActive(0);Events.GameplaySetActivePlayer();assert(Controls.JourneyLauncher.hidden)
    ''')
    lua.execute('MapModData.Paradise=nil;SetActive(1)');lua.execute(panel)
    lua.execute('assert(Controls.JourneyLauncher.hidden and Controls.JourneyPanel.hidden and Controls.JourneyCinematic.hidden)')
    print('PASS Paradise UI: safe absent runtime, functional tabs, modal lifecycle, pending illustrated story and hidden city/diplomacy/popup launcher')

if __name__=='__main__':
    database_checks();static_checks();gameplay_checks();ui_checks()
    print('Paradise validation passed. Live Civ V rendering/capture timing remains on the smoke-test checklist.')
