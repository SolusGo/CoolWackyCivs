"""Validate CR7 against installed CP SQL, DDS, Lua 5.1 and deterministic event sequences."""
from pathlib import Path
import re
import sqlite3
import sys
from xml.etree import ElementTree as ET
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from validate_mod import apply_current_cp_schema, directxtex_checks

def database():
    game=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    original=sqlite3.connect((game/'cache/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    db=sqlite3.connect(':memory:');original.backup(db);original.close()
    apply_current_cp_schema(db,game/'MODS/(1) Community Patch')
    db.row_factory=sqlite3.Row
    db.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag text primary key,Text text)')
    for path in sorted((R/'CristianoRonaldo/SQL').glob('*.sql')):db.executescript(path.read_text(encoding='utf-8'))
    return db

def static(db):
    core=(R/'CristianoRonaldo/SQL/00_CR7_Core.sql').read_text(encoding='utf-8')
    runtime=(R/'CristianoRonaldo/Lua/CR7Runtime.lua').read_text(encoding='utf-8')
    for option in ['EVENTS_BATTLES','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_UNIT_UPGRADES','EVENTS_UNIT_CONVERTS']:
        assert option in core,option
    assert 'GameEvents.CombatResult.Add(onCombatResult)' in runtime
    civ=db.execute("SELECT * FROM Civilizations WHERE Type='CIVILIZATION_RELENTLESS_SEVEN'").fetchone()
    assert (civ['Playable'],civ['AIPlayable'])==(1,0)
    unit=db.execute("SELECT * FROM Units WHERE Type='UNIT_CR7_COMPLETE_FORWARD'").fetchone()
    base=db.execute("SELECT * FROM Units WHERE Type='UNIT_CAVALRY'").fetchone()
    assert unit['Cost']==(base['Cost']*120+99)//100 and unit['Moves']==base['Moves']+1
    assert unit['Combat']==base['Combat']
    academy=db.execute("SELECT * FROM Buildings WHERE Type='BUILDING_CR7_SPORTING_ACADEMY'").fetchone()
    barracks=db.execute("SELECT * FROM Buildings WHERE Type='BUILDING_BARRACKS'").fetchone()
    for col in ['Experience','Cost','GoldMaintenance','PrereqTech','FreePromotion']:assert academy[col]==barracks[col]
    for table, in db.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
        if table.endswith('_new'):continue
        cols=[r[1] for r in db.execute('pragma table_info('+table+')')]
        for col,source,target in [('UnitType','UNIT_CAVALRY','UNIT_CR7_COMPLETE_FORWARD'),('BuildingType','BUILDING_BARRACKS','BUILDING_CR7_SPORTING_ACADEMY')]:
            if col not in cols or not table.startswith(('Unit_','UnitGameplay','Building_')) or table=='Building_YieldChanges':continue
            rest=[c for c in cols if c!=col]
            a=[tuple(r) for r in db.execute(f'SELECT {",".join(rest)} FROM {table} WHERE {col}=?',(source,))]
            b=[tuple(r) for r in db.execute(f'SELECT {",".join(rest)} FROM {table} WHERE {col}=?',(target,))]
            if table=='Unit_FreePromotions':assert all(r in b for r in a)
            else:assert a==b,table
    for name,values in {
        'HABIT':{'ExperiencePercent':15},'ACADEMY_TRAINING':{'ExperiencePercent':5},
        'FINISHER':{'AttackWoundedMod':15,'River':1,'ExtraAttacks':0},
        'FINISHER_VETERAN':{'AttackWoundedMod':8,'River':0,'ExtraAttacks':0},
        'EXPLOSIVE_OPEN':{'AttackMod':5,'DefenseMod':0},'CAPTAIN':{'DefenseMod':5,'RangedDefenseMod':5},
        'MADRID':{'AttackWoundedMod':5,'CityAttack':5},'MADRID_GG':{'GreatGeneralModifier':15},
    }.items():
        row=db.execute('select * from UnitPromotions where Type=?',('PROMOTION_CR7_'+name,)).fetchone()
        for k,v in values.items():assert row[k]==v,(name,k)
    for n in range(1,5):
        row=db.execute('select * from UnitPromotions where Type=?',(f'PROMOTION_CR7_REINVENTION_{n}',)).fetchone()
        assert row['CombatPercent']==n*2 and row['LostWithUpgrade']==0
    texts={r[0] for r in db.execute('select Tag from Language_en_US')}
    for path in (R/'CristianoRonaldo/SQL').glob('*.sql'):
        refs=set(re.findall(r"'(TXT_KEY_[^']+)'",path.read_text(encoding='utf-8')))
        assert refs<=texts,f'missing text: {refs-texts}'
    art={p.name:p for p in (R/'CristianoRonaldo/Art').glob('*.dds')}
    from PIL import Image
    for row in db.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'CR7_%'"):
        path=art[row['Filename']]
        with Image.open(path) as im:
            assert im.size==(row['IconSize']*int(row['IconsPerRow']),row['IconSize']*int(row['IconsPerColumn']))
            im.load()
    directxtex_checks(list(art.values()))
    print('PASS CR7 SQL: player-only, CP baseline inheritance, exact modifiers, localization, atlas slots')

def mock(db,pace=100):
    from lupa.lua51 import LuaRuntime
    lua=LuaRuntime(unpack_returned_tuples=True)
    types={};info={}
    for table in ['Civilizations','Units','UnitPromotions','Buildings','BuildingClasses','Policies','Technologies','Eras']:
        rows=[dict(r) for r in db.execute('select * from '+table)]
        entries={}
        for row in rows:
            types[row['Type']]=row['ID'];data=lua.table_from(row)
            entries[row['ID']]=data;entries[row['Type']]=data
        info[table]=lua.table_from(entries)
    lua.globals().GameInfoTypes=lua.table_from(types)
    info['GameSpeeds']=lua.table_from({0:lua.table_from(dict(TrainPercent=pace,ConstructPercent=pace,CulturePercent=pace,GoldenAgePercent=pace))})
    lua.globals().GameInfo=lua.table_from(info);lua.globals().TestSpeed=0
    lua.globals().FreePromotions=lua.table_from([lua.table_from(dict(r))for r in db.execute('select * from Unit_FreePromotions')])
    lua.execute((R/'tools/tests/ronaldo_mock.lua').read_text(encoding='utf-8'))
    runtime=(R/'CristianoRonaldo/Lua/CR7Runtime.lua').read_text(encoding='utf-8')
    lua.execute(runtime)
    return lua,runtime

def main():
    db=database();static(db)
    from lupa.lua51 import LuaRuntime
    for path in (R/'CristianoRonaldo').rglob('*.lua'):
        lua=LuaRuntime();lua.execute('assert(loadstring(...))',path.read_text(encoding='utf-8'))
    lua,runtime=mock(db)
    lua.execute((R/'tools/tests/ronaldo_assertions.lua').read_text(encoding='utf-8'))
    lua.execute('BeforeAmbition=Ambition();BeforeXP=TestForward.xp100;BeforePolicies=Players[0].freePolicies;MapModData.CR7=nil;ResetRuntimeEvents()')
    lua.execute(runtime)
    lua.execute('Equal(Ambition(),BeforeAmbition);Equal(TestForward.xp100,BeforeXP);Equal(Players[0].freePolicies,BeforePolicies);Equal(MapModData.CR7.GetUIState(0).legacy,7)')
    print('PASS CR7 reload: saved chapters, legacy, XP and one-time entitlements do not replay')
    lua.execute((R/'tools/tests/ronaldo_ui_assertions.lua').read_text(encoding='utf-8'))
    lua.execute((R/'CristianoRonaldo/UI/CR7Career.lua').read_text(encoding='utf-8'))
    lua.execute('''
assert(not Controls.Launcher.hidden and Controls.Career.hidden)
Controls.Launcher.callbacks[1]();assert(not Controls.Career.hidden)
Events.SerialEventEnterCityScreen();assert(Controls.Career.hidden and Controls.Launcher.hidden)
Events.SerialEventExitCityScreen();assert(not Controls.Career.hidden)
Events.AILeaderMessage();assert(Controls.Launcher.hidden)
Events.LeavingLeaderViewMode();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopup();assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown({Type=10});Events.SerialEventGameMessagePopupShown({Type=20})
Events.SerialEventGameMessagePopupProcessed(10);assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed(20);assert(not Controls.Launcher.hidden)
Events.InterfaceModeChanged(0,2);assert(Controls.Launcher.hidden)
Events.InterfaceModeChanged(2,0);assert(not Controls.Launcher.hidden)
LuaEvents.CR7ChapterUnlocked(0,3);LuaEvents.CR7ChapterUnlocked(0,4)
assert(not Controls.UnlockPopup.hidden and Controls.UnlockIcon.icon==17)
Controls.UnlockClose.callbacks[1]();assert(Controls.UnlockIcon.icon==18)
Controls.UnlockClose.callbacks[1]();assert(Controls.UnlockPopup.hidden)
assert(ContextPtr.input(1,27));assert(Controls.Career.hidden)
MapModData.CR7=nil;Events.ActivePlayerTurnStart();assert(Controls.Launcher.hidden)
''')
    print('PASS CR7 UI callbacks: opens/closes, queued popups, city/diplomacy/culture blockers, absent-runtime safety')
    lua,runtime=mock(db)
    lua.execute((R/'tools/tests/ronaldo_lifecycle_assertions.lua').read_text(encoding='utf-8'))
    # Save/load in the middle of a capped turn, then continue ordinary play.
    lua,runtime=mock(db)
    lua.execute('''
NewCity(0,1,0,0,1);u=NewUnit(0,1,'UNIT_WARRIOR')
for n=2,5 do u.level=n;GameEvents.UnitPromoted(0,1,GameInfoTypes.PROMOTION_SHOCK_1)end
Equal(Ambition(),3)
MapModData.CR7=nil;ResetRuntimeEvents()
''')
    lua.execute(runtime)
    lua.execute('u.level=5;GameEvents.UnitPromoted(0,1,GameInfoTypes.PROMOTION_SHOCK_2);Equal(Ambition(),3,"saved turn cap");CurrentTurn=1;GameEvents.UnitPromoted(0,1,GameInfoTypes.PROMOTION_SHOCK_2);Equal(Ambition(),4)')
    print('PASS CR7 mid-turn reload: cap persists and resets only on a new game turn')
    for pace in [67,100,150,300]:
        lua,_=mock(db,pace)
        lua.execute('NewCity(0,1,0,0,1);MapModData.CR7.AddAmbition(0,20,"test",true);assert(MapModData.CR7.GetUIState(0).unlocked[1]);Equal(Ambition(),20*'+str(pace)+'/100)')
    print('PASS CR7 game speeds: Quick, Standard, Epic and Marathon thresholds/rewards')
    for path in (R/'CristianoRonaldo').rglob('*.xml'):ET.parse(path)
    panel=(R/'CristianoRonaldo/UI/CR7Career.lua').read_text(encoding='utf-8')
    assert 'SetUpdate' not in panel and 'OpenSaveData' not in panel
    print('PASS CR7 Lua 5.1 syntax and event-driven UI structure')
if __name__=='__main__':main()
