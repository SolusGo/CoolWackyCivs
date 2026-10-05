"""Validate Viltrum with the installed CP schema and Lua 5.1 engine doubles."""
from pathlib import Path
import sqlite3,sys,re
R=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(R/'.tools/python'),str(R/'tools')]
from validate_mod import apply_current_cp_schema,quote
from build_mod import read_project,NS
from PIL import Image
from lupa.lua51 import LuaRuntime
V=R/'ViltrumEmpire'

def source_audit():
 """Check locally downloaded Release-5.4.2 call sites; never fetch during tests."""
 root=R/'.tools/cp-v151-audit'
 if not (root/'CvCity.cpp').exists():
  print('SKIP CP source snapshot assertions (see Validation.md for audited release and call sites)');return
 def source(name):return (root/name).read_text(encoding='utf-8')
 city=source('CvCity.cpp');unit=source('CvUnit.cpp');combat=source('CvUnitCombat.cpp');team=source('CvTeam.cpp')
 assert 'return max(-100, iTotalMod);' in city
 growth=city[city.index('int CvCity::getYieldRateTimes100(YieldTypes eYield, bool bIgnoreTrade, bool bIgnoreProcess, int'):]
 assert growth.index('if (iTotalYield > 0)')<growth.index('iTotalYield *= 100 + getGrowthMods')
 assert 'else if (getFoodTimes100() == 0 && iFoodPerTurn100 < 0 && getPopulation()>1)' in city
 assert 'canTrain(eUnitType, bAlreadyUnderConstruction, !bTestTrainable, false /*bIgnoreCost*/, true /*bWillPurchase*/)' in city
 assert 'canTrain(eUnitType, false, !bTestTrainable, true /*bIgnoreCost*/, true /*bWillPurchase*/)' in city
 assert 'LuaSupport::CallTestAll(pkScriptSystem, "CityCanTrain", args.get(), bResult)' in city
 drop=unit[unit.index('bool CvUnit::paradrop(int'):unit.index('bool CvUnit::canMakeTradeRoute')]
 assert drop.index('setMoves(GD_INT_GET(MOVE_DENOMINATOR))')<drop.index('setMadeAttack(true)')<drop.index('GAMEEVENT_ParadropAt, getOwner(), GetID(), fromPlot->getX(), fromPlot->getY(), pPlot->getX(), pPlot->getY()')
 made=unit[unit.index('void CvUnit::setMadeAttack(bool'):unit.index('int CvUnit::GetNumInterceptions()')]
 assert 'm_iAttacksMade = 0;' in made
 assert 'GAMEEVENT_UnitUpgraded, getOwner(), GetID(), pNewUnit->GetID(), false' in unit
 assert 'GAMEEVENT_UnitCreated, getOwner(), GetID(), getUnitType(), getX(), getY()' in unit
 assert 'GAMEEVENT_DeclareWar, eOriginatingPlayer, eTeam, bAggressor' in team
 assert 'GAMEEVENT_MakePeace, eOriginatingPlayer, eTeam, bPacifier' in team
 assert 'gDLL->GameplayWarStateChanged(GetID(), eIndex, bNewValue);' in team
 assert 'GAMEEVENT_CityTrained, getOwner(), GetID(), pUnit->GetID(), false, false' in city
 assert 'GAMEEVENT_CityConstructed, getOwner(), GetID(), eConstructBuilding, false, false' in city
 assert 'GAMEEVENTINVOKE_TESTALL(GAMEEVENT_PlayerCanMakePeace, ePlayer, eToTeam)' in source('CvDealClasses.cpp')
 assert 'LuaSupport::CallHook(pkScriptSystem, \"PlayerDoTurn\", args.get(), bResult)' in source('CvPlayer.cpp')
 assert 'LuaSupport::CallHook(pkScriptSystem, \"TeamTechResearched\", args.get(), bResult)' in team
 assert 'BATTLE_JOINED(unit, unitType, false);' in source('CvGameCoreStructs.cpp')
 assert 'MOD_EVENTS_RED_COMBAT_RESULT' in combat and 'LuaSupport::CallHook(pkScriptSystem, "CombatResult", args.get(), bResult)' in combat
 assert 'pDefender->CheckWithdrawal(kAttacker)' in combat and 'eSupportResult = AttackRanged(*pFireSupportUnit' in combat
 assert 'Cities ceded in a peace treaty have both bConquest=true and bGift=true' in source('CvPlayer.cpp')
 print('PASS CP Release-5.4.2 source assertions: native clamp/starvation, Gold/Faith canTrain, callback identities, nested combat and drop counter')
def database(cp_path=None):
 u=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
 source=sqlite3.connect((u/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
 d=sqlite3.connect(':memory:');source.backup(d);source.close();d.row_factory=sqlite3.Row
 apply_current_cp_schema(d,cp_path or u/'MODS/(1) Community Patch')
 d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
 for t, in d.execute("select name from sqlite_master where type='table' and name not like 'sqlite_%'").fetchall():
  cols=[r[1] for r in d.execute('pragma table_info('+quote(t)+')')]
  where=' OR '.join(f"INSTR(CAST({quote(c)} AS TEXT),'VILTRUM')>0" for c in cols)
  if where:
   try:d.execute('delete from '+quote(t)+' where '+where)
   except sqlite3.OperationalError:pass
 # References to Infantry are not its properties. Seed nonempty rows so an
 # overly broad inheritance generator cannot pass merely because CP leaves them empty.
 d.execute("INSERT INTO Civilization_UnitClassOverrides(CivilizationType,UnitClassType,UnitType) VALUES ('CIVILIZATION_VILTRUM_TEST_REFERENCE','UNITCLASS_INFANTRY','UNIT_INFANTRY')")
 d.execute("INSERT INTO Building_FreeUnits(BuildingType,UnitType,NumUnits) VALUES ('BUILDING_VILTRUM_TEST_REFERENCE','UNIT_INFANTRY',1)")
 for f in sorted((V/'SQL').glob('*.sql')):d.executescript(f.read_text(encoding='utf-8'))
 assert d.execute("SELECT COUNT(*) FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_VILTRUM_TEST_REFERENCE'").fetchone()[0]==1
 assert d.execute("SELECT COUNT(*) FROM Building_FreeUnits WHERE BuildingType='BUILDING_VILTRUM_TEST_REFERENCE'").fetchone()[0]==1
 def row(t,k):return d.execute('select * from '+quote(t)+' where Type=?',(k,)).fetchone()
 w=row('Units','UNIT_VILTRUM_WARRIOR');assert (w['Cost'],w['Combat'],w['Moves'],w['PrereqTech'],w['Domain'])==(1300,82,3,'TECH_REPLACEABLE_PARTS','DOMAIN_LAND')
 assert w['ResourceType'] is None
 ordinary=row('Units','UNIT_INFANTRY');aux=row('Units','UNIT_VILTRUM_AUXILIARY')
 for c in ('Cost','Combat','Moves','PrereqTech','ObsoleteTech','UnitArtInfo'):assert ordinary[c]==aux[c],c
 for c in ordinary.keys():
  if c not in ('ID','Type','Class','Description','Civilopedia','PortraitIndex','IconAtlas'):assert ordinary[c]==aux[c],('auxiliary scalar',c)
 def companions(table,key,typ):
  cols=[r[1] for r in d.execute('pragma table_info('+quote(table)+')') if r[1] not in (key,'ID')]
  return sorted(tuple(r) for r in d.execute('select '+','.join(map(quote,cols))+' from '+quote(table)+' where '+quote(key)+'=?',(typ,)))
 for table in ('Unit_AITypes','Unit_NotAITypes','Unit_ClassUpgrades','Unit_ResourceQuantityRequirements','Unit_FreePromotions','Unit_Flavors'):
  assert companions(table,'UnitType','UNIT_INFANTRY')==companions(table,'UnitType','UNIT_VILTRUM_AUXILIARY'),table
 assert not d.execute("SELECT 1 FROM Unit_FreePromotions WHERE UnitType='UNIT_VILTRUM_AUXILIARY' AND PromotionType LIKE 'PROMOTION_VILTRUM_%'").fetchall()
 overrides=dict(d.execute("SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_VILTRUM'"))
 assert overrides['UNITCLASS_INFANTRY']=='UNIT_VILTRUM_WARRIOR' and overrides['UNITCLASS_VILTRUM_AUXILIARY']=='UNIT_VILTRUM_AUXILIARY'
 assert row('UnitClasses','UNITCLASS_VILTRUM_AUXILIARY')['DefaultUnit'] is None
 assert d.execute("select count(*) from Unit_ResourceQuantityRequirements where UnitType='UNIT_VILTRUM_WARRIOR'").fetchone()[0]==0
 assert d.execute("select count(*) from Unit_ResourceQuantityExpended where UnitType='UNIT_VILTRUM_WARRIOR'").fetchone()[0]==0
 academy=row('Buildings','BUILDING_MILITARY_ACADEMY');b=row('Buildings','BUILDING_VILTRUM_COMPLEX')
 assert b['Experience']==academy['Experience']+15 and b['MilitaryProductionModifier']==academy['MilitaryProductionModifier']+5
 assert b['Cost']==academy['Cost'] and b['PrereqTech']==academy['PrereqTech']
 for table in ('Building_ClassesNeededInCity','Building_PrereqBuildingClasses','Building_TechAndPrereqs','Building_DomainFreeExperiences','Building_ResourceQuantityRequirements'):
  assert companions(table,'BuildingType','BUILDING_MILITARY_ACADEMY')==companions(table,'BuildingType','BUILDING_VILTRUM_COMPLEX'),table
 assert row('Policies','POLICY_VILTRUM_QUARANTINE')['CityGrowthMod']==-100
 for i in range(14):
  lock=row('Policies',f'POLICY_VILTRUM_GROWTH_LOCK_{i}');assert lock['IsDummy']==1 and lock['CityGrowthMod']==-2**i
 for option in ('EVENTS_BATTLES','EVENTS_CITY','EVENTS_UNIT_CREATED','EVENTS_UNIT_UPGRADES','EVENTS_PARADROPS','EVENTS_WAR_AND_PEACE','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT'):
  assert d.execute('SELECT Value FROM CustomModOptions WHERE Name=?',(option,)).fetchone()[0]==1,option
 for n in ('BLOODLINE','FLIGHT','HARDENED','PUREBLOOD','GENOME','CONDITIONING'):assert row('UnitPromotions','PROMOTION_VILTRUM_'+n)['LostWithUpgrade']==0
 flight=row('UnitPromotions','PROMOTION_VILTRUM_FLIGHT');assert (flight['DropRange'],flight['CanCrossMountains'],flight['HoveringUnit'],flight['IgnoreTerrainCost'])==(7,1,1,1)
 g=row('Buildings','BUILDING_VILTRUM_GARRISON');assert g['Defense']==300 and g['Happiness']==1
 for n in ('QUARANTINE','DYING','RECOVERY_A','RECOVERY_B','ILLUSION'):assert row('Policies','POLICY_VILTRUM_'+n)['IsDummy']==1
 translated={r[0] for r in d.execute('select Tag from Language_en_US')}
 for prefix in ('TXT_KEY_CIV5_VILTRUM','TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM'):
  assert prefix in translated and prefix+'_HEADING_1' in translated and prefix+'_TEXT_1' in translated
 for n in ('MOMENTUM','PURGE_EVENT','SCOURGE_EVENT','EXTINCTION'):
  assert row('Concepts','CONCEPT_VILTRUM_'+n)['CivilopediaHeaderType']=='HEADER_COMBAT'
 for t in ('Civilizations','Leaders','Units','Buildings','BuildingClasses','UnitPromotions','Traits','Concepts','Policies'):
  assert not d.execute(f"select Type from {t} where Type like '%VILTRUM%' group by Type having count(*)>1").fetchall()
  for r in d.execute(f"select * from {t} where Type like '%VILTRUM%'"):
   for v in r:
    if isinstance(v,str) and v.startswith('TXT_KEY_VILTRUM_'):assert v in translated,v
 for a in d.execute("select * from IconTextureAtlases where Atlas like 'VILTRUM_%'"):
  with Image.open(V/'Art'/a['Filename']) as im:
   im.load();assert im.size==(int(a['IconSize'])*int(a['IconsPerRow']),int(a['IconSize'])*int(a['IconsPerColumn']));assert im.mode=='RGBA'
   assert im.getpixel((0,0))[3]==0,a['Filename']
 assert d.execute('pragma integrity_check').fetchone()[0]=='ok'
 print('PASS Viltrum SQL: installed CP schema, Infantry/Academy inheritance, values, survivor promotions, localization and 28 atlases')
def fixture(percent=100):
 lua=LuaRuntime(unpack_returned_tuples=True)
 mock=(R/'tools/tests/viltrum_mock.lua').read_text(encoding='utf-8')
 lua.globals().MockSource=mock;lua.execute(mock)
 lua.globals().GameInfo.GameSpeeds[0].TrainPercent=percent
 src=(V/'Lua/ViltrumRuntime.lua').read_text(encoding='utf-8');lua.globals().RuntimeSource=src;lua.execute(src)
 return lua
def runtime():
 for f in V.rglob('*.lua'):
  lua=LuaRuntime(unpack_returned_tuples=True);ok,error=lua.eval('function(s,n)local f,e=loadstring(s,n);return f~=nil,e end')(f.read_text(encoding='utf-8'),str(f));assert ok,error
 fixture().execute((R/'tools/tests/viltrum_assertions.lua').read_text(encoding='utf-8'))
 # Exhaustively test both casualty floors for small and large armies.
 for choice in (1,2):
  for count in (0,1,2,3,5,10,30):
   lua=fixture();lua.execute(f"""
local V=MapModData.ViltrumEmpire
local cap=newCity(P,0,20,0,0);local small=newCity(P,1,1,5,0);small.buildings[300]=1
for n=1,{count} do newUnit(P,n,200) end
newUnit(P,100,202);newUnit(P,101,208,false);state('pending',2);state('outbreak',1)
assert(V.Choose(0,2,{choice}));local survivors=0
for u in P:Units()do if u.typ==200 then survivors=survivors+1 end end
local floor=math.min({count},{2 if choice==1 else 1})
local expected=math.max(floor,{count}-math.floor({count}*{.8 if choice==1 else .9}+0.5))
assert(survivors==expected and P.units[100] and P.units[101],'casualty floor/biological filter')
assert(small.pop==1,'Complex protection must not increase pre-outbreak population')
""")
 print('PASS Viltrum both casualty branches: 14 army-size scenarios including zero, one, two and thirty')
 fixture().execute("""
local V=MapModData.ViltrumEmpire;local I=GameInfoTypes
local cap=newCity(P,0,20,0,0);local c=newCity(P,1,10,5,0);P.ga=10;Teams[0].war[1]=true;Teams[1].war[0]=true;Teams[0].permanent[2]=true
local a=newUnit(P,1,200);newUnit(P,2,200);state('pending',2);state('outbreak',1)
assert(V.Choose(0,2,2));assert(cap.pop==3 and c.pop==1 and P.ga==0,'Crusade population/GA')
local pure=nil;for u in P:Units()do if u:IsHasPromotion(I.PROMOTION_VILTRUM_PUREBLOOD)then pure=u end end
assert(pure and pure.damage==90 and pure:IsHasPromotion(I.PROMOTION_VILTRUM_PURE_ACTIVE),'pureblood fury')
assert(not V.CanPeace(0,1) and not V.CanPeace(1,0) and Teams[0]:IsPermanentWarPeace(1),'two-way native voluntary peace lock')
pure.tile=plot(1,1,-1);GameEvents.UnitSetXY.Fire(0,pure.uid);assert(pure:IsHasPromotion(I.PROMOTION_VILTRUM_NO_HEAL),'Dying field healing')
local city=newCity(P,2,5,10,0,1);city.originalCapital=true;transferCity(city,Foreign);Foreign.capital=city
GameEvents.BattleStarted.Fire(0,10,0);GameEvents.BattleJoined.Fire(0,pure.uid,0,false);GameEvents.BattleJoined.Fire(1,2,1,true)
transferCity(city,P);GameEvents.CityCaptureComplete.Fire(1,true,10,0,0,5,true);GameEvents.BattleFinished.Fire()
assert(pure.damage==0 and V.Remaining(0,'dying')==24 and V.Remaining(0,'momentum')==8,'pureblood original capital full heal/crisis shortening')
T=3;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'pending')==3);assert(V.Choose(0,3,2))
assert(pure.xp==10 and P.units[1000] and Barb.units[1000] and Barb.units[1001],'demonstration General/XP/rebels')
-- Promotions survive an engine upgrade; new unit IDs cannot inherit from dead IDs.
local upgraded=newUnit(P,99,202);upgraded.promotions=pure.promotions;pure:Kill();GameEvents.UnitUpgraded.Fire(0,pure.uid,99)
local reused=newUnit(P,pure.uid,200);GameEvents.UnitCreated.Fire(0,pure.uid)
assert(upgraded:IsHasPromotion(I.PROMOTION_VILTRUM_PUREBLOOD) and not reused:IsHasPromotion(I.PROMOTION_VILTRUM_PUREBLOOD),'unit ID reuse/upgrade')
reload();V=MapModData.ViltrumEmpire;assert(V.Remaining(0,'dying')==21)
T=10;GameEvents.PlayerDoTurn.Fire(0);assert(V.CanPeace(0,1) and not Teams[0]:IsPermanentWarPeace(1) and Teams[0]:IsPermanentWarPeace(2),'native peace lock expiry/scenario preservation')
T=24;GameEvents.PlayerDoTurn.Fire(0);assert(V.Remaining(0,'recovery')==15 and P:HasPolicy(I.POLICY_VILTRUM_RECOVERY_B) and not P:HasPolicy(I.POLICY_VILTRUM_DYING),'Crusade recovery cleanup')
assert(cap.buildings[I.BUILDING_VILTRUM_RECOVERY]==0,'Crusade got larger recovery')
print('PASS Viltrum Crusade, Pureblood combat/capture, two-way peace, rebels, upgrades, ID reuse and recovery')
""")
 fixture().execute("""
local V=MapModData.ViltrumEmpire
newCity(P,0,8);newCity(P,1,7);P.era=2;T=1;GameEvents.PlayerDoTurn.Fire(0)
assert(V.Choose(0,1,2));assert(P.culture==98 and V.Remaining(0,'purgeGrowth')==20 and V.Remaining(0,'purgeHappy')==10,'Purge preservation formula')
P.human=false;state('purgeTriggered',0);state('purgeChoice',0);T=2;P.happy=-1;GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'purgeChoice')==2,'AI stressed population decision')
-- No cities and elimination do not error. Revival uses original persistent state.
P.alive=false;T=30;GameEvents.PlayerDoTurn.Fire(0);P.alive=true;P.cities={};P.capital=nil;GameEvents.PlayerDoTurn.Fire(0)
print('PASS Viltrum Purge preservation, AI stress decision, zero cities, elimination and revival')
""")
 for percent,start,outbreak in ((67,8,13),(100,12,20),(150,18,30),(300,36,60)):
  lua=fixture(percent);lua.execute(f"""
local V=MapModData.ViltrumEmpire;newCity(P,0,10);Teams[0].tech[10]=true;GameEvents.TeamTechResearched.Fire(0,10)
T={start-1};GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'countdown',-1)==-1,'early fallback')
T={start};GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'countdown',-1)==T,'late fallback')
reload();V=MapModData.ViltrumEmpire;T={outbreak};GameEvents.PlayerDoTurn.Fire(0);assert(V.Get(0,'pending')==2,'speed/reload outbreak')
""")
 print('PASS Viltrum guaranteed no-Warrior fallback and save/reload at all four game speeds')
 fixture().execute("""
local V=MapModData.ViltrumEmpire;newCity(P,0,8);newCity(P,1,7);P.era=2
GameEvents.PlayerDoTurn.Fire(0);assert(V.Choose(0,1,1))
for n=1,20 do T=n;GameEvents.PlayerDoTurn.Fire(0)end
assert(P.general==20,'Purge did not grant exactly twenty General progress ticks')
""")
 # Supplemental safety cases use real production callbacks, not internal state APIs.
 fixture().execute("""
local V=MapModData.ViltrumEmpire;local cap=newCity(P,0,10);local a=newUnit(P,1,200);a.damage=50
state('quarantine',10)
local d=newUnit(Foreign,1,202)
GameEvents.BattleStarted.Fire(0,1,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,1,1,false);d:Kill();GameEvents.BattleFinished.Fire();assert(a.damage==50,'quarantine kill heal enabled')
state('quarantine',0);state('dying',10)
d=newUnit(Foreign,2,202)
GameEvents.BattleStarted.Fire(0,1,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(1,2,1,false);d:Kill();GameEvents.BattleFinished.Fire();assert(a.damage==40,'crusade kill heal not ten')
local c=newCity(P,1,5,5,0,1);c.damage=100
GameEvents.BattleStarted.Fire(0,5,0);GameEvents.BattleJoined.Fire(0,1,0,false);GameEvents.BattleJoined.Fire(0,1,1,true)
assert(not a:IsHasPromotion(GameInfoTypes.PROMOTION_VILTRUM_PLANET_ACTIVE),'exactly half-health city bonus');GameEvents.BattleFinished.Fire()
local trader=newUnit(P,3,209,false);state('pending',2);state('outbreak',1);assert(V.Choose(0,2,1));assert(trader.recalled,'route recall missing')
-- Losing city/capital during a crisis clears owner-specific buildings.
P.cities[1]=nil;Foreign.cities[1]=c;c.owner=1;GameEvents.CityCaptureComplete.Fire(0,false,5,0,1,5,true)
for _,i in ipairs({'GARRISON','MOMENTUM','PURGE','QUARANTINE','DYING','RECOVERY','HAPPY'})do assert(c.buildings[GameInfoTypes['BUILDING_VILTRUM_'..i]]==0,'foreign dummy leakage')end
-- Refounding the same tile creates a distinct original city reward.
local rebuilt=newCity(P,5,4,5,0,1);rebuilt.founded=2;state('quarantine',0)
local before=cap.pop;conquerCity(rebuilt);assert(cap.pop==before+1,'refounded city inherited capture reward history')
state('noPeace',10);Teams[0].war[1]=true;Teams[1].war[0]=true;Events.WarStateChanged.Fire(0,1,true);assert(Teams[0]:IsPermanentWarPeace(1))
Teams[0].war[1]=false;Teams[1].war[0]=false;Events.WarStateChanged.Fire(0,1,false);assert(not Teams[0]:IsPermanentWarPeace(1),'forced peace lock cleanup')
print('PASS Viltrum crisis healing, exact city threshold, trader recall, foreign dummy cleanup, refounding and forced peace')
""")
def ui_checks():
 lua=fixture()
 lua.execute("""
function event()local e={handlers={}};function e.Add(f)e.handlers[#e.handlers+1]=f end;function e.Fire(...)for _,f in ipairs(e.handlers)do f(...)end end;return setmetatable(e,{__call=function(_,...)e.Fire(...)end})end
LuaEvents.ViltrumChanged=event();Events.LoadScreenClose=event();Events.GameplaySetActivePlayer=event();Events.ActivePlayerTurnStart=event();for _,n in ipairs({'SerialEventEnterCityScreen','SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed'})do Events[n]=event()end
Mouse={eLClick=1};PopupPriority={InGameUtmost=1};Queues=0;Dequeues=0
UIManager={QueuePopup=function()Queues=Queues+1 end,DequeuePopup=function()Dequeues=Dequeues+1 end};ContextPtr={SetHide=function()end}
Locale={ConvertTextKey=function(k)return k end};IconHookup=function()end;include=function(n)if n=='ViltrumRuntime'then assert(loadstring(RuntimeSource))()end end
Controls={}
for _,n in ipairs({'Launcher','Status','Panel','Emblem','Title','State','EventIcon','EventTitle','EventText','ChoiceA','ChoiceB','Close'})do
 local c={};Controls[n]=c
 function c:SetHide(b)self.hidden=b end;function c:SetText(t)self.text=t end;function c:SetToolTipString(t)self.tooltip=t end
 function c:SetDisabled(b)self.disabled=b end;function c:RegisterCallback(_,f)self.click=f end
end
newCity(P,0,10);state('pending',3);P.gold=100
""")
 lua.execute((V/'UI/ViltrumPanel.lua').read_text(encoding='utf-8'))
 lua.execute("""
assert(Queues==1 and Controls.ChoiceA.disabled and Controls.Close.hidden,'saved decision not modal/affordable')
Controls.ChoiceB.click();assert(MapModData.ViltrumEmpire.Get(0,'pending')==0 and Dequeues==1,'popup choice/runtime dispatch')
assert(not Controls.Launcher.hidden,'world launcher absent')
Controls.Status.click();assert(not Controls.Panel.hidden,'status did not open')
Events.SerialEventEnterCityScreen.Fire();assert(Controls.Launcher.hidden and Controls.Panel.hidden,'city screen overlay')
Events.SerialEventExitCityScreen.Fire();assert(not Controls.Launcher.hidden and not Controls.Panel.hidden,'city exit restoration')
Events.AILeaderMessage.Fire();assert(Controls.Launcher.hidden and Controls.Panel.hidden,'diplomacy overlay')
Events.LeavingLeaderViewMode.Fire();assert(not Controls.Launcher.hidden,'diplomacy exit restoration')
Events.SerialEventGameMessagePopupShown.Fire({Type=11});Events.SerialEventGameMessagePopupShown.Fire({Type=12})
assert(Controls.Launcher.hidden and Controls.Panel.hidden,'overview overlay')
Events.SerialEventGameMessagePopupProcessed.Fire(11,0);assert(Controls.Launcher.hidden,'nested popup restored prematurely')
state('pending',1);Events.ActivePlayerTurnStart.Fire();assert(not Controls.Panel.hidden and Controls.Launcher.hidden,'mandatory choice hidden by overview')
Controls.ChoiceB.click();assert(Controls.Panel.hidden,'optional panel visible over remaining popup')
Events.SerialEventGameMessagePopupProcessed.Fire(12,0);assert(not Controls.Launcher.hidden,'popup exit restoration')
state('pending',1);Events.ActivePlayerTurnStart.Fire();assert(Queues==3)
P.alive=false;Events.ActivePlayerTurnStart.Fire();assert(Dequeues==3 and Controls.Panel.hidden,'elimination left modal popup queued')
for n,e in pairs(GameEvents)do local expected=(n=='DeclareWar' or n=='MakePeace')and 0 or 1;assert(#e.handlers==expected,'UI listener count '..n)end
print('PASS Viltrum popup saved choice, affordability, runtime dispatch, queue/dequeue and duplicate-listener guard')
""")
def main():
 source_audit();database()
 baseline=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/Community Patch Backups/pre-5.4.6/(1) Community Patch (v 151)"
 if baseline.is_dir():
  database(baseline);print('PASS installed CP v151 backup DDL on the read-only cache clone')
 runtime();ui_checks()
 entries=[e.text for e in read_project()[1].findall('m:ModContent/m:Content/m:FileName',NS)]
 assert entries.count('ViltrumEmpire/UI/ViltrumPanel.xml')==1
 for f in (V/'Lua/ViltrumRuntime.lua',V/'UI/ViltrumPanel.lua'):
  src=f.read_text(encoding='utf-8');assert 'math.random' not in src and 'SetUpdate' not in src
 print('Viltrum automated checks passed; actual engine/IGE and multiplayer remain untested.')
if __name__=='__main__':main()
