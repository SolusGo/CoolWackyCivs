"""Actual CP SQL, strict Lua 5.1 survival simulation and Council/package checks."""
from pathlib import Path
from xml.etree import ElementTree as ET
from collections import Counter
import hashlib,re,sqlite3,sys
R=Path(__file__).resolve().parents[1];V=R/'TheLastCity'
sys.path[:0]=[str(R/'.tools/python'),str(R/'tools')]
from lupa.lua51 import LuaRuntime
from validate_mod import apply_current_cp_schema,quote
from build_lastcity_mod import manifest
from lastcity_localization import TEXT

def database():
    user=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    s=sqlite3.connect((user/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    d=sqlite3.connect(':memory:');s.backup(d);s.close();apply_current_cp_schema(d,user/'MODS/(1) Community Patch')
    d.row_factory=sqlite3.Row
    d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    for (table,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(table)+')')]
        pred=' OR '.join(f"INSTR(CAST({quote(c)} AS TEXT),'_LC_')>0 OR INSTR(CAST({quote(c)} AS TEXT),'LAST_CITY')>0" for c in cols)
        if pred:
            try:d.execute('DELETE FROM '+quote(table)+' WHERE '+pred)
            except sqlite3.OperationalError:pass
    for p in sorted((V/'SQL').glob('*.sql')):d.executescript(p.read_text(encoding='utf-8'))
    assert tuple(d.execute("SELECT Playable,AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_LAST_CITY'").fetchone())==(1,0)
    for table,old,new,allowed in [
     ('Units','UNIT_SPEARMAN','UNIT_LC_LAST_WATCH',{'ID','Type','Description','Civilopedia','Help','Strategy'}),
     ('Buildings','BUILDING_GRANARY','BUILDING_LC_DISTRICT',{'ID','Type','Description','Civilopedia','Help','Strategy'})]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone();b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for key in a.keys():
            if key not in allowed:assert a[key]==b[key],(table,key)
        prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for (comp,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(comp)+')')]
            if not comp.startswith(prefix) or col not in cols:continue
            fields=[k for k in cols if k not in [col,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(comp)+' WHERE '+col+'=?'
            original=Counter(tuple(r) for r in d.execute(query,(old,)))
            unique=Counter(tuple(r) for r in d.execute(query,(new,)))
            assert not original-unique,(comp,new)
    for key,text in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_LC_'+key,)).fetchone()[0]==text
    for table in ['Civilizations','Leaders','Traits','Units','Buildings','UnitPromotions','Concepts']:
        for row in d.execute('SELECT * FROM '+table):
            for value in row:
                if isinstance(value,str) and value.startswith('TXT_KEY_LC_'):assert value[11:] in TEXT,value
    assert d.execute("SELECT Count FROM Civilization_FreeUnits WHERE CivilizationType='CIVILIZATION_LAST_CITY' AND UnitClassType='UNITCLASS_SETTLER'").fetchone()[0]==1
    assert d.execute("SELECT GlobalDefenseMod FROM Buildings WHERE Type='BUILDING_LC_LEGACY'").fetchone()[0]==2
    assert d.execute("SELECT DefenseMod FROM UnitPromotions WHERE Type='PROMOTION_LC_SANCTUARY'").fetchone()[0]==15
    assert d.execute("SELECT NoCapture FROM UnitPromotions WHERE Type='PROMOTION_LC_NO_CONQUEST'").fetchone()[0]==1
    assert d.execute("SELECT Cost FROM Buildings WHERE Type='BUILDING_LC_DAWN'").fetchone()[0]==900
    for (atlas,index) in d.execute("SELECT IconAtlas,PortraitIndex FROM Units WHERE Type='UNIT_LC_LAST_WATCH' UNION ALL SELECT IconAtlas,PortraitIndex FROM Buildings WHERE Type='BUILDING_LC_DISTRICT' UNION ALL SELECT IconAtlas,PortraitIndex FROM Civilizations WHERE Type='CIVILIZATION_LAST_CITY' UNION ALL SELECT IconAtlas,PortraitIndex FROM Leaders WHERE Type='LEADER_LC_WARDEN' UNION ALL SELECT IconAtlas,PortraitIndex FROM UnitPromotions WHERE Type LIKE 'PROMOTION_LC_%'"):
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone(),(atlas,index)
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    print('PASS actual BNW/CP SQL: complete inheritance, stock art atlases, localization, AI, production costs and effect schema')
    return d

def fixture(d,speed=100):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().Translations=lua.table_from({'TXT_KEY_LC_'+k:v for k,v in TEXT.items()})
    lua.execute((R/'tools/tests/lastcity_mock.lua').read_text(encoding='utf-8'))
    info=lua.table();types={}
    for table in ['Civilizations','Units','Buildings','UnitPromotions','Technologies','Eras','Improvements','Features','Unit_FreePromotions']:
        rows=[dict(r) for r in d.execute('SELECT * FROM '+table)]
        info[table]=lua.globals().dbTable(lua.table_from([lua.table_from(r) for r in rows]))
        for row in rows:
            if 'Type' in row and 'ID' in row:types[row['Type']]=row['ID']
    info.GameSpeeds=lua.table_from({0:lua.table_from({'TrainPercent':speed})})
    lua.globals().GameInfo=info;lua.globals().GameInfoTypes=lua.table_from(types)
    def include(name):
        p=V/'Lua'/(name+'.lua')
        if p.is_file():lua.execute(p.read_text(encoding='utf-8'))
    lua.globals().include=include;lua.globals().setup();include('LastCityCore')
    lua.execute('L=MapModData.TheLastCity; S=L.State(0); C=Players[0].cities[0]')
    return lua

def scenario(d,name,source,speed=100):
    lua=fixture(d,speed);lua.execute(source);print('PASS '+name);return lua

def simulations(d):
    scenario(d,'founding, settler veto, normal-player isolation and safe city return',"""
      assert(C.name==L.Text('CAPITAL') and S.provisions==45 and S.morale==65)
      assert(not GameEvents.PlayerCanFoundCity.Test(0,5,5))
      assert(not GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_SETTLER))
      assert(GameEvents.PlayerCanTrain.Test(0,GameInfoTypes.UNIT_LC_LAST_WATCH))
      assert(GameEvents.PlayerCanFoundCity.Test(1,5,5) and GameEvents.PlayerCanTrain.Test(1,GameInfoTypes.UNIT_SETTLER))
      local u=Players[0]:InitUnit(GameInfoTypes.UNIT_SETTLER,2,0,1,0);advance(1);assert(not Players[0]:GetUnitByID(u:GetID()))
      local gift=newCity(0,2,12,0);gift.original=1;gift.previous=1;Players[0].cities[2]=gift
      L.ReturnExtraCities(S);assert(gift.owner==1 and Players[0]:GetNumCities()==1)
      local orphan=newCity(0,3,20,0);orphan.original=2;orphan.previous=2;Players[2].alive=false;Players[0].cities[3]=orphan
      L.ReturnExtraCities(S);assert(orphan.owner==0 and orphan.puppet)
    """)
    scenario(d,'supply accounting, pillage, civilian exclusion, assignments and cooldowns',"""
      C.population=10;L.Building(C,'DISTRICT',1)
      plot(1,0).improvement=GameInfoTypes.IMPROVEMENT_FARM
      plot(0,1).improvement=GameInfoTypes.IMPROVEMENT_FISHING_BOATS;plot(0,1).pillaged=true
      Players[0]:InitUnit(GameInfoTypes.UNIT_WORKER,2,0,1,0)
      S.experts.FARMERS=9;S.assigned.FARMERS=5;S.experts.ENGINEERS=5
      assert(L.Stats(S).income==17 and L.Stats(S).consumption==7 and L.Stats(S).military==1)
      for _=1,5 do assert(L.Assign(S,'ENGINEERS',1)) end
      assert(not L.Assign(S,'ENGINEERS',1));L.ApplyEffects(S)
      assert(C:GetNumRealBuilding(GameInfoTypes.BUILDING_LC_ENGINEERS)==5)
      assert(L.SetRation(S,'STRICT'));assert(not L.SetRation(S,'GENEROUS'))
      assert(L.Stats(S).consumption==6);TURN=S.rationNext;assert(L.SetRation(S,'EMERGENCY'))
      S.provisions=10000;L.ApplyEffects(S);assert(S.provisions==S.capacity)
      for _=1,5 do L.LoseExpert(S,'ENGINEERS') end;assert(S.assigned.ENGINEERS==0)
    """)
    scenario(d,'quarantine, refusal, expired/stale decisions and exactly-once Population',"""
      L.Building(C,'DISTRICT',1);L.ApplyEffects(S);L.NewRefugee(S);S.provisions=100
      local r=S.refugee;local cost=r.cost;local pop=C.population
      assert(L.ResolveRefugee(S,r.id,'QUARANTINE'));assert(C.population==pop and r.paid==math.ceil(cost/2))
      assert(not L.ResolveRefugee(S,r.id,'ACCEPT'));L.Save(0)
      L.States={};S=L.State(0);assert(S.refugee.status=='QUARANTINE');TURN=S.refugee.due;L.RefugeeTurn(S)
      r=S.refugee;r.riskRoll=100;local id=r.id
      assert(L.ResolveRefugee(S,id,'ACCEPT'));assert(C.population==pop+r.population and S.provisions==100-cost)
      assert(not L.ResolveRefugee(S,id,'ACCEPT'));assert(C.population==pop+r.population)
      L.NewRefugee(S);local old=C.population;local skill=S.refugee.skill;local expertise=S.experts[skill]
      assert(L.ResolveRefugee(S,S.refugee.id,'REFUSE'));assert(C.population==old and S.experts[skill]==expertise)
      L.NewRefugee(S);TURN=S.refugee.expiry+1;L.RefugeeTurn(S);assert(not S.refugee)
    """)
    scenario(d,'starvation, fractional growth, morale thresholds and recovery',"""
      S.nextWave=99999;S.nextRefugee=99999;S.nextCrisis=99999
      C.population=30;S.provisions=0;advance(12);assert(S.starvation==12 and C.population>=1 and S.morale>=0)
      C.population=3;S.provisions=150;advance(6);assert(S.starvation==0)
      S.morale=81;L.ApplyEffects(S);assert(C:GetNumRealBuilding(GameInfoTypes.BUILDING_LC_UNITED)==1)
      S.morale=10;L.ApplyEffects(S);L.ApplyEffects(S)
      assert(C:GetNumRealBuilding(GameInfoTypes.BUILDING_LC_BREAKING)==1 and C:GetNumRealBuilding(GameInfoTypes.BUILDING_LC_UNITED)==0)
      S.provisions=150;S.starvation=0;S.ration='STRICT';C.food=30;S.foodRemainder=0
      advance(10);assert(math.abs(C.food-24)<.001 and S.provisions>=0 and S.provisions<=S.capacity)
    """)
    scenario(d,'all crises resolve exactly once with real effects and safe Production costs',"""
      for _,key in ipairs(L.Crises) do
       for choice=1,3 do
        C.population=15;C.production=100;S.provisions=200;S.morale=65;S.housingDamage=3
        for _,skill in ipairs(L.Skills) do S.experts[skill]=5;S.assigned[skill]=3 end
        S.crisis={id=S.nextEvent,key=key,expert='ENGINEERS',expiry=999};S.nextEvent=S.nextEvent+1
        local id=S.crisis.id;assert(L.CrisisCheck(S,id,choice),key..choice)
        assert(L.ResolveCrisis(S,id,choice),key..choice);assert(not L.ResolveCrisis(S,id,choice))
        assert(S.provisions>=0 and C.population>=1 and S.morale>=0 and S.morale<=100)
       end
      end
      S.crisis={id=400,key='GATES'};S.provisions=200;C.production=0
      assert(not L.ResolveCrisis(S,400,1));assert(S.crisis and C.production==0)
      C.production=100;local before=S.provisions;assert(L.ResolveCrisis(S,400,1));assert(C.production==80 and S.provisions==before-20)
      S.crisis={id=401,key='GATES'};C.population=3;assert(L.ResolveCrisis(S,401,2));assert(#S.temporary>0)
      TURN=S.temporary[#S.temporary].expiry;L.EconomyTurn(S);assert(#S.temporary==0)
    """)
    scenario(d,'blocked/failed spawns, safe land routes, genuine victories and retreats',"""
      local land,sea=L.SpawnPlots(S);assert(#land>0 and #sea==0)
      for _,p in ipairs(land) do assert(not p:IsCity() and p.owner==-1 and p:GetNumUnits()==0 and dist(0,0,p.x,p.y)>=4) end
      FAIL_UNITS=true;assert(not L.BeginWave(S));assert(not S.wave and S.wavesSurvived==0 and S.waveNumber==0)
      FAIL_UNITS=false;assert(L.BeginWave(S));defeatWave();assert(S.wavesSurvived==1)
      assert(L.BeginWave(S));local w=S.wave;TURN=w.expiry;L.InvasionTurn(S);assert(not S.wave and S.wavesSurvived==1)
      L.Near(0,0,8,function(p) if dist(0,0,p.x,p.y)>=4 then p.owner=1 end end)
      assert(not L.BeginWave(S));assert(S.wavesSurvived==1)
    """)
    scenario(d,'island naval domains, foreign terrain exclusion and bounded local work',"""
      L.Near(0,0,8,function(p) if dist(0,0,p.x,p.y)>1 then p.water=true end end)
      plot(4,0).feature=GameInfoTypes.FEATURE_ICE;plot(5,0).owner=1
      PLOT_VISITS=0;assert(L.BeginWave(S));assert(S.wave.naval and PLOT_VISITS<500)
      for _,r in ipairs(S.wave.units) do local u=L.Unit(r);local def=GameInfo.Units[u:GetUnitType()]
       assert(def.Domain=='DOMAIN_SEA' and plot(u.x,u.y).water and plot(u.x,u.y).owner==-1)
       assert(plot(u.x,u.y).feature~=GameInfoTypes.FEATURE_ICE)
       assert(not u:IsHasPromotion(GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE))
      end
    """)
    scenario(d,'Major Siege veteran progression, upgrade identity, defense cap and ID reuse',"""
      S.waveNumber=4;local watch=Players[0]:GetUnitByID(0);assert(L.BeginWave(S));assert(S.wave.major)
      local oldID=watch:GetID();local promoted=Players[0]:InitUnit(GameInfoTypes.UNIT_PIKEMAN,1,0,3,0)
      promoted.promos=watch.promos;watch:Kill(false,-1);GameEvents.UnitUpgraded.Fire(0,oldID,promoted:GetID(),false)
      defeatWave();assert(S.majorSieges==1 and promoted:IsHasPromotion(GameInfoTypes.PROMOTION_LC_VETERAN_1))
      local fresh=Players[0]:InitUnit(GameInfoTypes.UNIT_LC_LAST_WATCH,2,0,3,0);assert(not fresh:IsHasPromotion(GameInfoTypes.PROMOTION_LC_VETERAN_1))
      for n=1,5 do S.waveNumber=n*5-1;assert(L.BeginWave(S));defeatWave() end
      assert(promoted:IsHasPromotion(GameInfoTypes.PROMOTION_LC_VETERAN_5))
      S.majorSieges=999;L.ApplyEffects(S);assert(C:GetNumRealBuilding(GameInfoTypes.BUILDING_LC_LEGACY)==15)
      assert(L.BeginWave(S));local r=S.wave.units[1];local old=L.Unit(r);old:Kill(false,-1)
      local replacement=newUnit(r.owner,r.id,GameInfoTypes.UNIT_WARRIOR,5,0);Players[r.owner].units[r.id]=replacement
      assert(not L.Unit(r));local victories=S.wavesSurvived
      for i=2,#S.wave.units do local u=L.Unit(S.wave.units[i]);if u then u:Kill(true,0) end end
      L.InvasionTurn(S);assert(S.wavesSurvived==victories and replacement==Players[r.owner]:GetUnitByID(r.id))
    """)
    scenario(d,'Dawn Production eligibility, Final Night, achievement and Endless Survival',"""
      grantTechs();L.Building(C,'DISTRICT',1);Players[0].era=6;WORLD_ERA=6;S.wavesSurvived=12;S.morale=65;S.provisions=200
      assert(L.CanInfrastructure(S,'DAWN'));assert(L.QueueInfrastructure(S,'DAWN'));assert(C.lastOrder.kind==GameInfoTypes.BUILDING_LC_DAWN)
      L.Building(C,'DAWN',1);GameEvents.CityConstructed.Fire(0,C.id,GameInfoTypes.BUILDING_LC_DAWN,false,false)
      assert(S.dawn=='FINAL_PENDING' and S.provisions==50)
      GameEvents.CityConstructed.Fire(0,C.id,GameInfoTypes.BUILDING_LC_DAWN,false,false);assert(S.provisions==50)
      TURN=S.nextWave;L.InvasionTurn(S);assert(S.wave.final and S.dawn=='FINAL_ACTIVE')
      defeatWave();assert(S.dawn=='ENDURES' and S.achievement and C:GetNumRealBuilding(GameInfoTypes.BUILDING_LC_ENDURES)==1)
      TURN=S.nextWave;L.InvasionTurn(S);assert(S.wave and not S.wave.final)
    """)
    scenario(d,'foreign unit conversion, invader effects and delayed casualty deduplication',"""
      local watch=Players[0]:GetUnitByID(0);local before=S.losses
      GameEvents.UnitPrekill.Fire(0,0,watch:GetUnitType(),1,0,true,1)
      GameEvents.UnitPrekill.Fire(0,0,watch:GetUnitType(),1,0,false,1)
      assert(S.losses==before+1)
      local copy=Players[1]:InitUnit(GameInfoTypes.UNIT_LC_LAST_WATCH,2,0,1,0);copy.promos=watch.promos
      GameEvents.UnitConverted.Fire(0,1,watch:GetID(),copy:GetID(),false)
      assert(not copy:IsHasPromotion(GameInfoTypes.PROMOTION_LC_SANCTUARY) and not copy:IsHasPromotion(GameInfoTypes.PROMOTION_LC_NO_CONQUEST))
      local captured=Players[0]:InitUnit(GameInfoTypes.UNIT_TRIREME,3,0,1,0)
      L.Promotion(captured,'INVADER',true);L.Promotion(captured,'BOSS',true);captured:SetHasPromotion(GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE,false)
      GameEvents.UnitConverted.Fire(63,0,999,captured:GetID(),false)
      assert(not captured:IsHasPromotion(GameInfoTypes.PROMOTION_LC_BOSS) and captured:IsHasPromotion(GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE))
    """)
    scenario(d,'save/reload, turn deduplication, guarded snapshot parsing and bank recovery',"""
      L.NewRefugee(S);S.experts.ENGINEERS=3;S.assigned.ENGINEERS=2;S.morale=63.7;S.foodRemainder=.4
      assert(L.BeginWave(S));L.Save(0);local raw=L.Encode(S);assert(L.Encode(L.Decode(raw))==raw)
      assert(not pcall(L.Decode,'m1:n1;s999:'))
      local id=S.refugee.id;local wave=S.wave.number
      L.States={};S=L.State(0);assert(S.refugee.id==id and S.wave.number==wave and S.morale==63.7 and S.assigned.ENGINEERS==2)
      TURN=1;L.Turn(0);local provisions=S.provisions;L.Turn(0);assert(S.provisions==provisions)
      local active=SAVE_DATA.LASTCITY_P0_active;SAVE_DATA['LASTCITY_P0_'..active..'_sum']=-1
      L.States={};S=L.State(0);assert(not S.incompatible and S.refugee.id==id)
      resetEvents();__LAST_CITY_LOADED=nil;MapModData={};include('LastCityCore')
      assert(#GameEvents.PlayerDoTurn.handlers==1);include('LastCityCore');assert(#GameEvents.PlayerDoTurn.handlers==1)
    """)
    for speed in [67,100,150,300]:
        scenario(d,f'AI, speed {speed}%, schedules and bounded economy over 160 turns',"""
          local factor=L.Speed;assert(S.nextWave==L.Scale(24));assert(S.nextRefugee>=L.Scale(8) and S.nextRefugee<=L.Scale(14))
          Players[0].human=false;grantTechs();L.Building(C,'DISTRICT',1)
          for _,skill in ipairs(L.Skills) do S.experts[skill]=5 end
          for n=1,160 do
           advance(1)
           if S.wave then defeatWave() end
           assert(S.provisions>=0 and S.provisions<=S.capacity and S.morale>=0 and S.morale<=100)
           for _,skill in ipairs(L.Skills) do assert(S.assigned[skill]<=5 and S.assigned[skill]<=S.experts[skill]) end
          end
          assert(#S.history<=90 and S.wavesSurvived>0 and S.lastTurn==160)
        """,speed)

def packaging():
    current=ET.parse(V/'The Last City (v 1).modinfo').getroot();expected=manifest().getroot()
    assert ET.tostring(current)==ET.tostring(expected),'Stale standalone manifest'
    entries=current.findall('EntryPoints/EntryPoint');assert len(entries)==1 and entries[0].get('file')=='UI/SanctuaryCouncil.xml'
    for e in current.findall('Files/File'):
        p=V/e.text;assert e.get('md5').lower()==hashlib.md5(p.read_bytes()).hexdigest()
        assert e.get('import')==str(int(p.suffix!='.sql' and p.name!='SanctuaryCouncil.xml'))
    names=[e.text for e in current.findall('Actions/OnModActivated/UpdateDatabase')]
    assert names==['SQL/'+p.name for p in sorted((V/'SQL').glob('*.sql'))]
    lua=LuaRuntime();compiler=lua.eval('function(s) local f,e=loadstring(s);return f~=nil,e end')
    for p in V.rglob('*.lua'):
        result=compiler(p.read_text(encoding='utf-8'));assert result[0],(p,result[1])
    ui=(V/'UI/SanctuaryCouncil.lua').read_text(encoding='utf-8');xml=ET.parse(V/'UI/SanctuaryCouncil.xml')
    ids={e.get('ID') for e in xml.iter() if e.get('ID')}
    assert set(re.findall(r'Controls\.(\w+)',ui))<=ids
    assert 'SetUpdate' not in ui and 'include(\'LastCityCore\')' in ui
    print('PASS standalone manifest hashes, VFS/SQL order, sole runtime owner, Lua 5.1 syntax and Council controls')

def main():
    d=database();packaging();simulations(d);ui_simulation(d);d.close()
    print('Last City automated validation passed. Native in-game smoke tests remain outstanding.')

def ui_simulation(d):
    lua=fixture(d)
    lua.globals().ControlNames=','.join(sorted({e.get('ID') for e in ET.parse(V/'UI/SanctuaryCouncil.xml').iter() if e.get('ID')}))
    lua.globals().UISource=(V/'UI/SanctuaryCouncil.lua').read_text(encoding='utf-8')
    lua.execute((R/'tools/tests/lastcity_ui_assertions.lua').read_text(encoding='utf-8'))
    print('PASS Council open/close, seven tabs, real commands, preview/confirmation, stale events and modal visibility')

if __name__=='__main__':main()
