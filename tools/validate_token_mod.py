"""Verify Token SQL against real BNW/CP schema and adversarial Lua 5.1 doubles."""
from pathlib import Path
import re,sqlite3,sys
from xml.etree import ElementTree as ET
R=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(R/'.tools/python'),str(R/'tools')]
from validate_mod import apply_current_cp_schema,quote
from PIL import Image
from lupa.lua51 import LuaRuntime
V=R/'TokenizedIntelligence'
def database(cp_root=None):
    u=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    s=sqlite3.connect((u/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    d=sqlite3.connect(':memory:');s.backup(d);s.close();d.row_factory=sqlite3.Row
    apply_current_cp_schema(d,cp_root or u/'MODS/(1) Community Patch')
    d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    # Clear only namespaced rows in this disposable database copy.
    for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
        where=' OR '.join(f"INSTR(CAST({quote(c)} AS TEXT),'TOKEN_')>0" for c in cols)
        if where:
            try:d.execute('DELETE FROM '+quote(t)+' WHERE '+where)
            except sqlite3.OperationalError:pass
    d.execute("INSERT INTO Building_FreeUnits(BuildingType,UnitType,NumUnits) VALUES ('BUILDING_TOKEN_TEST_REFERENCE','UNIT_INFANTRY',1)")
    for f in sorted((V/'SQL').glob('*.sql')):d.executescript(f.read_text(encoding='utf-8'))
    assert d.execute("SELECT COUNT(*) FROM Building_FreeUnits WHERE BuildingType='BUILDING_TOKEN_TEST_REFERENCE'").fetchone()[0]==1
    def row(t,k):return d.execute('SELECT * FROM '+quote(t)+' WHERE Type=?',(k,)).fetchone()
    for table,base,unique in [('Units','UNIT_INFANTRY','UNIT_TOKEN_AGENT'),('Buildings','BUILDING_UNIVERSITY','BUILDING_TOKEN_CLUSTER'),('Buildings','BUILDING_LABORATORY','BUILDING_TOKEN_CENTRE')]:
        a,b=row(table,base),row(table,unique)
        for field in a.keys():
            if field not in ('ID','Type','Description','Civilopedia','Help','Strategy','PortraitIndex','IconAtlas','UnitFlagAtlas','UnitFlagIconOffset'):
                assert a[field]==b[field],(unique,field,a[field],b[field])
        prefix,key=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE ?",(prefix+'%',)).fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')') if r[1] not in (key,'ID')]
            allcols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if key not in allcols or not cols or t=='Building_Flavors':continue
            def companions(k):return sorted(tuple(r) for r in d.execute('SELECT '+','.join(map(quote,cols))+' FROM '+quote(t)+' WHERE '+key+'=?',(k,)))
            assert companions(base)==companions(unique),(t,unique)
    assert row('Civilizations','CIVILIZATION_TOKEN_INTELLIGENCE')['AIPlayable']==1
    assert row('Buildings','BUILDING_TOKEN_HAPPINESS')['UnmoddedHappiness']==5
    assert row('Buildings','BUILDING_TOKEN_ADMIN')['UnmoddedHappiness']==8
    assert row('UnitPromotions','PROMOTION_TOKEN_TACTICAL')['CombatPercent']==15
    assert row('UnitPromotions','PROMOTION_TOKEN_TACTICAL')['VisibilityChange']==1
    assert row('UnitPromotions','PROMOTION_TOKEN_FORECAST')['VisibilityChange']==6
    assert row('UnitPromotions','PROMOTION_TOKEN_MOBILITY')['MovesChange']==1
    for name in ('TACTICAL','SIMULATION','GRAND','FORECAST','OFFENSE','DEFENSE','MOBILITY','TARGET'):
        promotion=row('UnitPromotions','PROMOTION_TOKEN_'+name)
        assert promotion['LostOnGifting']==1 and promotion['LostWithUpgrade']==1
    assert d.execute("SELECT Modifier FROM UnitPromotions_Domains WHERE PromotionType='PROMOTION_TOKEN_TARGET'").fetchone()[0]==25
    assert dict(d.execute("SELECT BuildingClassType,BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType='CIVILIZATION_TOKEN_INTELLIGENCE'"))=={'BUILDINGCLASS_UNIVERSITY':'BUILDING_TOKEN_CLUSTER','BUILDINGCLASS_LABORATORY':'BUILDING_TOKEN_CENTRE'}
    assert dict(d.execute("SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_TOKEN_INTELLIGENCE'"))=={'UNITCLASS_INFANTRY':'UNIT_TOKEN_AGENT'}
    translated={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
    for table in ('Civilizations','Leaders','Units','Buildings','UnitPromotions','Traits','Concepts'):
        for r in d.execute('SELECT * FROM '+table+" WHERE Type LIKE '%TOKEN_%'"):
            for value in r:
                if isinstance(value,str) and value.startswith('TXT_KEY_TOKEN_'):assert value in translated,value
    assert len(d.execute("SELECT Type FROM Concepts WHERE Type LIKE 'CONCEPT_TOKEN_%'").fetchall())==7
    textures=[]
    for a in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'TOKEN_%'"):
        path=V/'Art'/a['Filename'];textures.append(path)
        with Image.open(path) as im:
            im.load();assert im.size==(int(a['IconSize'])*int(a['IconsPerRow']),int(a['IconSize'])*int(a['IconsPerColumn']))
            assert im.mode=='RGBA' and im.getpixel((0,0))[3]==0,path
        header=path.read_bytes()[:128];assert header[:4]==b'DDS '
    assert len(textures)==28
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    print('PASS Token SQL: installed CP schema, exact Infantry/University/Lab inheritance, overrides, localization, 28 atlases')
def fixture(percent):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute((R/'tools/tests/token_mock.lua').read_text(encoding='utf-8'))
    lua.globals().GameInfo.GameSpeeds[0].TrainPercent=percent
    src=(V/'Lua/TokenRuntime.lua').read_text(encoding='utf-8');lua.globals().RuntimeSource=src;lua.execute(src)
    return lua
def runtime():
    for f in V.rglob('*.lua'):
        lua=LuaRuntime(unpack_returned_tuples=True)
        ok,error=lua.eval('function(s,n) local f,e=loadstring(s,n);return f~=nil,e end')(f.read_text(encoding='utf-8'),str(f));assert ok,error
    for percent in (67,100,150,300):
        fixture(percent).execute((R/'tools/tests/token_assertions.lua').read_text(encoding='utf-8'))
        fixture(percent).execute((R/'tools/tests/token_hardening_assertions.lua').read_text(encoding='utf-8'))
        # Count actual reduced income ticks, including the expiry boundary.
        saturation=fixture(percent)
        saturation.execute("""
local T=MapModData.TokenizedIntelligence
bank(0,T.Stats(0).capacity);assert(T.Use(0,'PRODUCTION',0));bank(0,0)
assert(T.Stats(0).penalty==25)
for i=1,T.Scale(3) do
    local before=T.Tokens(0);nextTurn(0)
    assert(T.Tokens(0)-before==22,'congestion income tick '..i)
end
local before=T.Tokens(0);nextTurn(0);assert(T.Tokens(0)-before==30 and T.Stats(0).penalty==0)
""")
        print('PASS speed',percent)
    lua=fixture(100)
    lua.execute("""
local T=MapModData.TokenizedIntelligence
local p=Players[0];p.era=7;T.Invalidate(0);bank(0,10000)
assert(T.Use(0,'GOLD'));assert(T.Use(0,'RESEARCH'));assert(T.Use(0,'CULTURE'))
assert(#T.Active(0)==3 and not T.Use(0,'TACTICAL',0))
assert(T.Use(0,'CLEAR'));assert(#T.Active(0)==0)
bank(0,10000);assert(T.Use(0,'ROUTE',0));local movement=p.units[0].moves
-- Reopening/reloading and clearing do not permit a second route grant.
reload();T=MapModData.TokenizedIntelligence
assert(not T.Use(0,'ROUTE',0) and p.units[0].moves==movement)
assert(loadstring(RuntimeSource))() -- same-context include must not duplicate hooks
local before=T.Tokens(0);nextTurn(0);assert(T.Tokens(0)>before)
for i=1,500 do nextTurn(0) end
assert(T.Tokens(0)==T.Stats(0).capacity)
p.human=false;Teams[0].war=1;p.units[0].damage=30
bank(0,10000);nextTurn(0);assert(#T.Active(0)==1)
assert(p.units[0]:IsHasPromotion(GameInfoTypes.PROMOTION_TOKEN_DEFENSE))
""")
    # Literal API assertions against source snapshots, when available.
    audit=R/'.tools/cp-v151-audit'
    if (audit/'Lua_CvLuaTeamTech.cpp').exists():
        source=(audit/'Lua_CvLuaTeamTech.cpp').read_text(encoding='utf-8')
        for name in ('GetResearchCost','GetResearchProgress','ChangeResearchProgress'):assert 'Method('+name+');' in source
        city=(audit/'CvCity.cpp').read_text(encoding='utf-8');section=city[city.index('LuaSupport::CallHook(pkScriptSystem, "SetPopulation"')-230:]
        assert 'args->Push(getX())' in section and 'args->Push(getY())' in section
        unit=(audit/'CvUnit.cpp').read_text(encoding='utf-8');assert 'GAMEEVENT_UnitConverted, pUnit->getOwner(),getOwner(), pUnit->GetID(), GetID(), bIsUpgrade' in unit
        convert=unit[unit.index('void CvUnit::convert('):unit.index('void CvUnit::kill(')]
        assert convert.index('setHasPromotion')<convert.index('GAMEEVENT_UnitConverted')<convert.index('pUnit->kill(')
        gift=unit[unit.index('void CvUnit::gift('):]
        assert 'pGiftUnit->convert(this, false, true)' in gift
        assert 'GAMEEVENT_UnitPrekill, eUnitOwner, GetID(), getUnitType(), getX(), getY(), bDelay, ePlayer' in unit
        minor=(audit/'CvMinorCivAI.cpp').read_text(encoding='utf-8')
        apply=minor[minor.index('void CvMinorCivIncomingUnitGift::applyToUnit'):minor.index('void CvMinorCivIncomingUnitGift::applyToUnit')+3500]
        assert '(bReturn || !pkPromotionInfo->IsLostOnGifting())' in apply
        player=(audit/'CvPlayer.cpp').read_text(encoding='utf-8')
        incoming=player[player.index('void CvPlayer::AddIncomingUnit('):player.index('void CvPlayer::AddIncomingUnit(')+2500]
        assert incoming.index('unitGift.init(')<incoming.index('pUnit->kill(') and 'UnitConverted' not in incoming
        citizens=(audit/'CvCityCitizens.cpp').read_text(encoding='utf-8')
        for function in ('DoAddSpecialistToBuilding','DoRemoveSpecialistFromBuilding'):
            section=citizens[citizens.index('void CvCityCitizens::'+function):]
            section=section[:section.index('\n}\n')]
            assert 'setDirty(GameData_DIRTY_BIT, true)' in section and 'setDirty(CityInfo_DIRTY_BIT, true)' in section
        print('PASS CP source contracts: research, population, conversion copy/hook/kill order, direct/distant gifts, prekill, specialist dirty events')
    assert 'SetUpdate' not in (V/'UI/TokenPanel.lua').read_text(encoding='utf-8')
    assert 'Map.GetNumPlots' not in (V/'Lua/TokenRuntime.lua').read_text(encoding='utf-8')
    print('PASS Lua 5.1 runtime, all-speed adversarial lifecycle and 500-turn endurance')
def ui():
    lua=fixture(100)
    lua.globals().ControlNames=','.join(e.attrib['ID'] for e in ET.parse(V/'UI/TokenPanel.xml').iter() if 'ID' in e.attrib)
    lua.globals().UISource=(V/'UI/TokenPanel.lua').read_text(encoding='utf-8')
    lua.execute((R/'tools/tests/token_ui_assertions.lua').read_text(encoding='utf-8'))
if __name__=='__main__':
    if '--runtime-only' not in sys.argv:
        database()
        baseline=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/Community Patch Backups/pre-5.4.6/(1) Community Patch (v 151)"
        if baseline.is_dir():
            database(baseline);print('PASS Token SQL against retained CP v151 baseline schema')
    runtime()
    ui()
