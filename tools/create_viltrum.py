"""Author Viltrum SQL using the installed CP schema; preserve supplied artwork."""
from pathlib import Path
import sqlite3, sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'tools'))
from validate_mod import apply_current_cp_schema,quote
V=R/'ViltrumEmpire'
for folder in ['SQL','Lua','UI','Art','docs']: (V/folder).mkdir(parents=True,exist_ok=True)
U=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
s=sqlite3.connect((U/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
d=sqlite3.connect(':memory:');s.backup(d);s.close();apply_current_cp_schema(d,U/'MODS/(1) Community Patch')
def save(n,t): (V/n).write_text(t,encoding='utf-8')
def q(v): return "'"+str(v).replace("'","''")+"'"
text={}
def tr(k,v): text['TXT_KEY_VILTRUM_'+k]=v;return q('TXT_KEY_VILTRUM_'+k)
core="""-- Community Patch v151. Enable hooks used here; never disable another mod's hooks.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
('EVENTS_BATTLES','EVENTS_CITY','EVENTS_UNIT_CREATED','EVENTS_UNIT_UPGRADES','EVENTS_PARADROPS','EVENTS_WAR_AND_PEACE','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_VILTRUM_CRIMSON',0.48,0.025,0.04,1);
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_VILTRUM_WHITE',0.96,0.96,0.93,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
('PLAYERCOLOR_VILTRUM','COLOR_VILTRUM_CRIMSON','COLOR_VILTRUM_WHITE','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_VILTRUM_CONQUEST','TXT_KEY_VILTRUM_TRAIT_HELP','TXT_KEY_VILTRUM_TRAIT');
"""
def clone(table,old,new,changes):
 return f"CREATE TEMP TABLE VILTRUM_Clone AS SELECT * FROM {table} WHERE Type={q(old)};\nUPDATE VILTRUM_Clone SET ID=NULL,Type={q(new)},"+','.join(k+'='+v for k,v in changes.items())+f";\nINSERT INTO {table} SELECT * FROM VILTRUM_Clone;\nDROP TABLE VILTRUM_Clone;\n"
strategy='Conquer aggressively before the guaranteed Scourge. Each 1300-Production Viltrumite is an enormous investment: keep conventional Infantry, artillery, anti-air and aircraft. Breeding Complexes protect citizens. Stockpile Gold and position defensively after Replaceable Parts. Quarantine preserves more survivors; continuing the crusade creates powerful Last Purebloods at devastating risk.'
core+=clone('Leaders','LEADER_WASHINGTON','LEADER_VILTRUM_THRAGG',dict(Description=tr('LEADER','Grand Regent Thragg'),Civilopedia=tr('LEADER_PEDIA','Thragg, Grand Regent of the Viltrum Empire, rules through absolute strength and the preservation of Viltrumite blood. His empire must survive a catastrophe that military force cannot defeat.'),CivilopediaTag=q('TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM'),ArtDefineTag=q('ViltrumLeaderScene.xml'),PortraitIndex='1',IconAtlas=q('VILTRUM_ICON_ATLAS'),PackageID='NULL',VictoryCompetitiveness='10',WonderCompetitiveness='2',MinorCivCompetitiveness='8',Boldness='10',DiploBalance='2',WarmongerHate='0',DoFWillingness='2',Meanness='10'))
core+="INSERT INTO Leader_Traits VALUES ('LEADER_VILTRUM_THRAGG','TRAIT_VILTRUM_CONQUEST');\n"
core+=clone('Civilizations','CIVILIZATION_AMERICA','CIVILIZATION_VILTRUM',dict(Description=tr('CIV','The Viltrum Empire'),ShortDescription=tr('SHORT','Viltrum'),Adjective=tr('ADJECTIVE','Viltrumite'),Civilopedia=tr('CIV_PEDIA','The Viltrum Empire conquered countless worlds, sustained by genetically extraordinary warriors. The Great Purge forged its ideology; the Scourge Virus nearly extinguished its people. Conventional subject armies and a handful of survivors must rebuild the dominion.'),CivilopediaTag=q('TXT_KEY_CIV5_VILTRUM'),Strategy=tr('STRATEGY',strategy),DefaultPlayerColor=q('PLAYERCOLOR_VILTRUM'),Playable='1',AIPlayable='0',PackageID='NULL',PortraitIndex='0',IconAtlas=q('VILTRUM_ICON_ATLAS'),AlphaIconAtlas=q('VILTRUM_ALPHA_ATLAS'),MapImage=q('ViltrumMap.dds'),DawnOfManImage=q('ViltrumDawn.dds'),DawnOfManQuote=q('TXT_KEY_VILTRUM_DAWN'),DawnOfManAudio=q(''),SoundtrackTag=q('ROME')))
core+="INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_VILTRUM','LEADER_VILTRUM_THRAGG');\n"
for table,key in [('Civilization_FreeBuildingClasses','BuildingClassType'),('Civilization_FreeTechs','TechType')]:
 core+=f"INSERT INTO {table} SELECT 'CIVILIZATION_VILTRUM',{key} FROM {table} WHERE CivilizationType='CIVILIZATION_AMERICA';\n"
core+="INSERT INTO Civilization_FreeUnits(CivilizationType,UnitClassType,UnitAIType,Count) SELECT 'CIVILIZATION_VILTRUM',UnitClassType,UnitAIType,Count FROM Civilization_FreeUnits WHERE CivilizationType='CIVILIZATION_AMERICA';\n"
core+=clone('Units','UNIT_INFANTRY','UNIT_VILTRUM_WARRIOR',dict(Description=tr('WARRIOR','Viltrumite Warrior'),Civilopedia=tr('WARRIOR_PEDIA','A flying strategic breakthrough warrior. One costs about 3.47 ordinary Infantry. Biological Bloodline, Flight, March, Relentless Execution and Planetbreaker are free. Only genuine outbreak survivors receive the strongest survivor promotions.'),Strategy=tr('WARRIOR_STRATEGY',strategy),Help=tr('WARRIOR_HELP','82 Strength, 3 Movement, 1300 Production; Replaceable Parts. Ignores terrain costs, crosses mountains and coasts, deploys 7 tiles from friendly territory, attacks after deployment, and captures cities. Heals 35 HP on personal capture. Relentless Execution: +15% against targets below 50 HP; Planetbreaker: +20% against cities below half health.'),Combat='82',Moves='3',Cost='1300',FaithCost='2600',PrereqTech=q('TECH_REPLACEABLE_PARTS'),ResourceType='NULL',PortraitIndex='0',IconAtlas=q('VILTRUM_OBJECT_ATLAS'),UnitFlagAtlas=q('VILTRUM_UNIT_FLAG_ATLAS'),UnitFlagIconOffset='0'))
core+="INSERT INTO Civilization_UnitClassOverrides VALUES ('CIVILIZATION_VILTRUM','UNITCLASS_INFANTRY','UNIT_VILTRUM_WARRIOR');\n"
# A second, Viltrum-only class retains ordinary Infantry at the current ruleset's tech/cost.
core+="INSERT INTO UnitClasses(Type,Description,DefaultUnit) VALUES ('UNITCLASS_VILTRUM_AUXILIARY','TXT_KEY_VILTRUM_AUXILIARY',NULL);\n"
core+=clone('Units','UNIT_INFANTRY','UNIT_VILTRUM_AUXILIARY',dict(Class=q('UNITCLASS_VILTRUM_AUXILIARY'),Description=tr('AUXILIARY','Auxiliary Infantry'),Civilopedia=tr('AUXILIARY_PEDIA','Conventional subject-world Infantry. Retains the installed ruleset Infantry statistics, requirements, upgrades and model. Auxiliaries are unaffected by biological Scourge casualties.'),PortraitIndex='0',IconAtlas=q('VILTRUM_OBJECT_ATLAS')))
core+="INSERT INTO Civilization_UnitClassOverrides VALUES ('CIVILIZATION_VILTRUM','UNITCLASS_VILTRUM_AUXILIARY','UNIT_VILTRUM_AUXILIARY');\n"
core+=clone('Buildings','BUILDING_MILITARY_ACADEMY','BUILDING_VILTRUM_COMPLEX',dict(Description=tr('COMPLEX','Viltrumite Breeding Complex'),Civilopedia=tr('COMPLEX_PEDIA','Replaces the Military Academy and retains its ruleset effects. Adds 15 XP, 2 Production, 1 Food and 5% military Production. First construction grants one citizen once per original city. Each Complex protects one additional citizen during the Scourge.'),Strategy=tr('COMPLEX_STRATEGY','Build before the Scourge to protect population and condition land troops.'),Help=tr('COMPLEX_HELP','Military Academy effects plus 15 XP, +2 Production, +1 Food, +5% military Production. First construction: +1 Population. Trained land troops gain Imperial Conditioning. Protects one additional citizen during the Scourge.'),PortraitIndex='1',IconAtlas=q('VILTRUM_OBJECT_ATLAS'),MilitaryProductionModifier='MilitaryProductionModifier+5',Experience='Experience+15'))
core+="INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_VILTRUM','BUILDINGCLASS_MILITARY_ACADEMY','BUILDING_VILTRUM_COMPLEX');\n"
save('SQL/00_Viltrum_Core.sql',core)
inherit='-- Companion-table inheritance generated against the installed Community Patch schema.\n'
tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
for key,old,new,scalar in [('UnitType','UNIT_INFANTRY','UNIT_VILTRUM_WARRIOR','Units'),('UnitType','UNIT_INFANTRY','UNIT_VILTRUM_AUXILIARY','Units'),('BuildingType','BUILDING_MILITARY_ACADEMY','BUILDING_VILTRUM_COMPLEX','Buildings')]:
 for table in tables:
  cols=[r[1] for r in d.execute(f'PRAGMA table_info({quote(table)})')]
  if table==scalar or key not in cols: continue
  # Only true companion tables: foreign civ overrides and building free-unit
  # grants reference Infantry but are not Infantry properties to duplicate.
  if key=='UnitType' and not (table.startswith('Unit_') or table=='UnitGameplay2DScripts'):continue
  if key=='BuildingType' and not table.startswith('Building_'):continue
  if new=='UNIT_VILTRUM_WARRIOR' and table in ('Unit_ResourceQuantityRequirements','Unit_ResourceQuantityExpended'):continue
  inherit+=f'CREATE TEMP TABLE VILTRUM_Clone AS SELECT * FROM {quote(table)} WHERE {quote(key)}={q(old)};\nUPDATE VILTRUM_Clone SET {quote(key)}={q(new)}'+(',ID=NULL' if 'ID' in cols else '')+f';\nINSERT INTO {quote(table)} SELECT * FROM VILTRUM_Clone;\nDROP TABLE VILTRUM_Clone;\n'
save('SQL/01_Viltrum_Inheritance.sql',inherit)
effects='-- All effects are scoped to newly declared Viltrum types.\n'
def promo(n,label,help,idx=2,**fields):
 global effects
 effects+='INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry'+(' ,'+','.join(fields) if fields else '')+') VALUES ('+','.join([q('PROMOTION_VILTRUM_'+n),tr(n,label),tr(n+'_HELP',help),'1','0',str(idx),q('VILTRUM_OBJECT_ATLAS'),q('PEDIA_ATTRIBUTES'),q('TXT_KEY_VILTRUM_'+n)]+[str(v) for v in fields.values()])+');\n'
promo('BLOODLINE','Viltrumite Bloodline','Biological marker retained through upgrades; targeted by the Scourge.',ShowInUnitPanel=0,IsVisibleAboveFlag=0)
promo('FLIGHT','Viltrumite Flight','Ignore terrain costs; cross mountains and shallow water; deploy 7 tiles and attack after deployment.',0,IgnoreTerrainCost=1,HoveringUnit=1,CanCrossMountains=1,DropRange=7)
promo('EXECUTION','Relentless Execution','+15% combat strength against an enemy combat unit below 50 HP.',2)
promo('PLANETBREAKER','Planetbreaker','+20% when attacking a city below 50% HP; heal 35 HP on personal city capture.',2)
promo('EXECUTION_ACTIVE','Relentless Execution bonus','Temporary target-conditioned combat modifier.',CombatPercent=15,ShowInUnitPanel=0,IsVisibleAboveFlag=0)
promo('PLANET_ACTIVE','Planetbreaker bonus','Temporary wounded-city attack modifier.',CityAttack=20,ShowInUnitPanel=0,IsVisibleAboveFlag=0)
promo('MOMENTUM','Imperial Momentum','+5% strength attacking cities while Momentum is active.',4,CityAttack=5)
promo('CONDITIONING','Imperial Conditioning','+5% strength outside friendly territory. Healing +1 HP in friendly or neutral territory (rounded native approximation of 5%).',1,FriendlyHealChange=1,NeutralHealChange=1)
promo('CONDITION_ACTIVE','Conditioned abroad','+5% outside friendly territory.',CombatPercent=5,ShowInUnitPanel=0,IsVisibleAboveFlag=0)
promo('HARDENED','Scourge-Hardened','True quarantine survivor: +10% strength, +1 sight, native healing +4 friendly/+2 neutral/+2 enemy HP (approximately 20%).',3,CombatPercent=10,VisibilityChange=1,FriendlyHealChange=4,NeutralHealChange=2,EnemyHealChange=2)
promo('PUREBLOOD','Last Pureblood','True crusade survivor: +20% strength, +1 move, Blitz, +20% combat XP. +20% strength below 50 HP; fully heals on personal enemy current-capital capture.',0,CombatPercent=20,MovesChange=1,ExperiencePercent=20)
promo('PURE_ACTIVE','Last Pureblood fury','+20% strength while below 50 HP.',CombatPercent=20,ShowInUnitPanel=0,IsVisibleAboveFlag=0)
promo('GENOME','Hardened Genome','Post-crisis Viltrumite trained by Viltrum: +5% strength.',3,CombatPercent=5)
promo('WARNING','Impossible Illness','Native healing -5 friendly/-3 neutral/-3 enemy HP (approximately 25% of normal field healing).',3,FriendlyHealChange=-5,NeutralHealChange=-3,EnemyHealChange=-3)
promo('QUARANTINE','Total Quarantine','Native healing -10 friendly/-5 neutral/-5 enemy HP (approximately 50% of normal field healing).',3,FriendlyHealChange=-10,NeutralHealChange=-5,EnemyHealChange=-5)
promo('NO_HEAL','Dying Empire','Cannot passively heal outside friendly territory.',3,CannotHeal=1)
effects+="INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES "+','.join("('UNIT_VILTRUM_WARRIOR',"+q(p)+')' for p in ['PROMOTION_VILTRUM_BLOODLINE','PROMOTION_VILTRUM_FLIGHT','PROMOTION_MARCH','PROMOTION_VILTRUM_EXECUTION','PROMOTION_VILTRUM_PLANETBREAKER'])+';\n'
effects+="INSERT INTO UnitPromotions_UnitCombats(PromotionType,UnitCombatType,PediaType) SELECT p.Type,c.Type,'PEDIA_ATTRIBUTES' FROM UnitPromotions p CROSS JOIN UnitCombatInfos c WHERE p.Type LIKE 'PROMOTION_VILTRUM_%';\n"
for n,fields,yields,mods in [
 ('GARRISON',dict(Happiness=1,Defense=300),dict(YIELD_PRODUCTION=1),{}),
 ('MOMENTUM',dict(MilitaryProductionModifier=15),{},{}),
 ('PURGE',dict(MilitaryProductionModifier=3),{},{}),
 ('QUARANTINE',dict(MilitaryProductionModifier=-50),{},dict(YIELD_PRODUCTION=-40)),
 ('DYING',{}, {},dict(YIELD_PRODUCTION=-50)),
 ('RECOVERY',dict(Happiness=1),{},dict(YIELD_PRODUCTION=15)),
 ('HAPPY',dict(Happiness=1),{},{}),
 ]:
 effects+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_VILTRUM_{n}','BUILDING_VILTRUM_{n}','TXT_KEY_VILTRUM_DUMMY');\n"
 effects+='INSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,IsDummy,ShowInPedia'+(','+','.join(fields) if fields else '')+') VALUES ('+','.join([q('BUILDING_VILTRUM_'+n),q('BUILDINGCLASS_VILTRUM_'+n),q('TXT_KEY_VILTRUM_DUMMY'),'-1','-1','-1','1','1','0','1','0']+[str(v) for v in fields.values()])+');\n'
 for t,values in [('Building_YieldChanges',yields),('Building_YieldModifiers',mods)]:
  for y,value in values.items():effects+=f'INSERT INTO {t}(BuildingType,YieldType,Yield) VALUES ({q("BUILDING_VILTRUM_"+n)},{q(y)},{value});\n'
# Add to inherited yields without duplicate keys.
for y,val in [('YIELD_PRODUCTION',2),('YIELD_FOOD',1)]:
 effects+=f"UPDATE Building_YieldChanges SET Yield=Yield+{val} WHERE BuildingType='BUILDING_VILTRUM_COMPLEX' AND YieldType='{y}';\nINSERT INTO Building_YieldChanges SELECT 'BUILDING_VILTRUM_COMPLEX','{y}',{val} WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_VILTRUM_COMPLEX' AND YieldType='{y}');\n"
for n,fields in [('PURGE_GROWTH',dict(CityGrowthMod=10)),('QUARANTINE',dict(CityGrowthMod=-100)),('DYING',dict(CityGrowthMod=-75,ExtraHappiness=-10)),('RECOVERY_A',dict(CityGrowthMod=25)),('RECOVERY_B',dict(CityGrowthMod=15)),('ILLUSION',dict(StealTechSlowerModifier=25,CityStrengthMod=10))]:
 effects+='INSERT INTO Policies(Type,Description,Civilopedia,Help,PortraitIndex,IconAtlas,IconAtlasAchieved,IsDummy'+','+','.join(fields)+') VALUES ('+','.join([q('POLICY_VILTRUM_'+n),q('TXT_KEY_VILTRUM_DUMMY'),q('TXT_KEY_VILTRUM_DUMMY'),q('TXT_KEY_VILTRUM_DUMMY'),'3',q('VILTRUM_OBJECT_ATLAS'),q('VILTRUM_OBJECT_ATLAS'),'1']+[str(v) for v in fields.values()])+');\n'
# Native growth clamping: offset additive bonuses using bounded, hidden policies.
for i in range(14):
 effects+=f"INSERT INTO Policies(Type,Description,Civilopedia,Help,PortraitIndex,IconAtlas,IconAtlasAchieved,IsDummy,CityGrowthMod) VALUES ('POLICY_VILTRUM_GROWTH_LOCK_{i}','TXT_KEY_VILTRUM_DUMMY','TXT_KEY_VILTRUM_DUMMY','TXT_KEY_VILTRUM_DUMMY',3,'VILTRUM_OBJECT_ATLAS','VILTRUM_OBJECT_ATLAS',1,{-2**i});\n"
flavors={'OFFENSE':10,'DEFENSE':7,'CITY_DEFENSE':7,'EXPANSION':9,'MILITARY_TRAINING':10,'SCIENCE':7,'PRODUCTION':9,'GOLD':6,'CULTURE':3,'DIPLOMACY':2,'WONDER':2,'AIR':8,'NUKE':8,'NAVAL':5}
effects+="INSERT INTO Leader_Flavors SELECT 'LEADER_VILTRUM_THRAGG',Type,CASE Type "+' '.join(f"WHEN 'FLAVOR_{k}' THEN {v}" for k,v in flavors.items())+' ELSE 5 END FROM Flavors;\n'
for table,key in [('Leader_MajorCivApproachBiases','MajorCivApproachType'),('Leader_MinorCivApproachBiases','MinorCivApproachType')]:
 effects+=f"INSERT INTO {table} SELECT 'LEADER_VILTRUM_THRAGG',{key},CASE WHEN {key} LIKE '%WAR' OR {key} LIKE '%CONQUEST' THEN 10 WHEN {key} LIKE '%FRIENDLY' THEN 2 ELSE 6 END FROM {table} WHERE LeaderType='LEADER_WASHINGTON';\n"
effects+="UPDATE Building_Flavors SET Flavor=40 WHERE BuildingType='BUILDING_VILTRUM_COMPLEX' AND FlavorType='FLAVOR_MILITARY_TRAINING';\nUPDATE Unit_Flavors SET Flavor=8 WHERE UnitType='UNIT_VILTRUM_WARRIOR';\n"
cities=["Viltrum","Argall's Reach","Regent's Citadel","Kregg's Bastion","Conquest's Rest","Anissa's Spear","Thula's Vigil","Lucan's March","Vidor Prime","The Gene-Forges","Red Sun Colony","Dominion's Edge","Purity World","Unbroken Sky","Planetbreaker Station","The Regent's Hand","Bloodline Nexus","The Fifty's Refuge","Ascendant World","Last Horizon","Imperial Crucible","Silent Conquest","The Outer Dominion","Argall's Legacy","Throne of Worlds"]
for i,name in enumerate(cities):effects+=f"INSERT INTO Civilization_CityNames VALUES ('CIVILIZATION_VILTRUM',{tr('CITY_'+str(i),name)});\n"
for i,name in enumerate(['Kregg','Anissa','Thula','Lucan','Vidor','Conquest','Argall','Nolan']):effects+=f"INSERT INTO Civilization_SpyNames VALUES ('CIVILIZATION_VILTRUM',{tr('SPY_'+str(i),name)});\n"
diplo={'FIRST_GREETING':'You have mistaken independence for strength. Your world now belongs to Viltrum.','GREETING_NEUTRAL_HELLO':'Speak. The Empire has permitted you a moment of its attention.','GREETING_POLITE_HELLO':'You have demonstrated value. Continue to do so.','GREETING_HOSTILE_HELLO':'Every day you remain free is an administrative delay.','DECLAREWAR':'Your species has been measured. It has been found unnecessary.','GREETING_HUMAN_AT_WAR':'You have saved us the inconvenience of inventing a justification.','REQUEST':'Surrender what has been requested. Refusal will only increase the final cost.','DEFEATED':'Viltrum is not a world. It is blood. So long as one of us remains, the Empire remains.'}
for response,line in diplo.items():effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_VILTRUM_THRAGG','RESPONSE_{response}',{tr('DIPLO_'+response,line)},100);\n"
sizes=(256,128,80,64,48,45,32,24,16)
for atlas,file,cols,rows in [('ICON','ViltrumIcon',2,1),('ALPHA','ViltrumAlpha',1,1),('OBJECT','ViltrumObjects',4,2)]:
 for size in sizes:effects+=f"INSERT INTO IconTextureAtlases VALUES ('VILTRUM_{atlas}_ATLAS',{size},'{file}{size}.dds',{cols},{rows});\n"
effects+="INSERT INTO IconTextureAtlases VALUES ('VILTRUM_UNIT_FLAG_ATLAS',32,'ViltrumUnitFlag32.dds',1,1);\n"
for name in ['MOMENTUM','PURGE_EVENT','SCOURGE_EVENT','EXTINCTION']:
 effects+=f"INSERT INTO Concepts(Type,Topic,Description,Summary,Advisor,CivilopediaHeaderType) VALUES ('CONCEPT_VILTRUM_{name}','TXT_KEY_TOPIC_COMBAT','TXT_KEY_VILTRUM_{name}','TXT_KEY_VILTRUM_{name}_HELP','MILITARY','HEADER_COMBAT');\n"
save('SQL/02_Viltrum_Effects.sql',effects)
tr('TRAIT','Blood of Conquest');tr('TRAIT_HELP','Land combat kills heal 15 HP (no civilians or barbarians). First foreign-city conquests give +1 capital Population, resistance reduced by rounded-up 20% (minimum 1 turn if resistance exists) and Imperial Momentum: +15% military Production, +3 trained military XP, +5% city attack for 8 turns, extended by 3 up to 18. Garrisoned cities gain +1 Production, +1 Happiness and +3 strength. A Great Purge and a guaranteed Scourge shape the empire. Quarantine disables conquest bonuses; Crusade reduces kill healing to 10. Durations scale with game speed.')
tr('DUMMY','Viltrum imperial administration')
tr('DAWN','The Viltrum Empire was built upon a single truth: strength confers the right to rule.[NEWLINE][NEWLINE]The weak among your own people were purged. The survivors crossed the stars, bringing countless worlds beneath the Viltrumite banner. Their armies broke, their governments surrendered, and their resources sustained an empire that appeared invincible.[NEWLINE][NEWLINE]Yet something now moves unseen through Viltrumite blood. An enemy too small to strike, too numerous to conquer, and too patient to intimidate.[NEWLINE][NEWLINE]Grand Regent Thragg, will you build an empire capable of surviving its own extinction? Will the galaxy witness the death of Viltrum—or learn that even a handful of Viltrumites are enough to rule the stars?')
tr('PURGE_EVENT','The Great Purge');tr('PURGE_EVENT_HELP','Viltrum has turned its strength inward. Those judged unworthy are being hunted by their own people. Entire cities have become battlegrounds as the Empire determines whether survival itself is proof of superiority.[NEWLINE][NEWLINE]The weak plead for protection. The warriors demand that the purge continue.')
tr('SCOURGE_EVENT','The Scourge Virus');tr('SCOURGE_EVENT_HELP','The Scourge has reached Viltrum. Quarantine loses 75% population and 80% Bloodline units (at least two survive if available). Survivors have 25 HP and Scourge-Hardened. Population growth stops (starvation remains possible), Production -40%, military Production another -50%, healing slows, conquest bonuses stop and training/purchasing new Settlers, Caravans and Cargo Ships is blocked for 20 turns. Recovery: 20 turns of +25% Growth, +15% Production and +1 Happiness/city.[NEWLINE][NEWLINE]Crusade loses 85% population and 90% Bloodline units (at least one survives), with 10 HP and Last Pureblood. For 25 turns: -75% Growth, -50% Production, -10 Happiness and no field healing abroad. Kill healing becomes 10; first conquests shorten the crisis. Peace is blocked for the first 10 turns. Recovery gives +15% Growth for 15 turns. Capitals retain 2 citizens; Complexes protect one extra. All durations scale with speed.')
tr('MOMENTUM_HELP','First conquests activate 8 turns of +15% military Production, +3 XP to trained military units and +5% city attack. Additional first conquests extend by 3 up to 18 remaining turns. Quarantine suspends all conquest rewards.')
tr('EXTINCTION','Conceal the Extinction');tr('EXTINCTION_HELP','The galaxy must not know how few Viltrumites remain. If subject worlds discover the truth, rebellion will spread faster than the virus itself.[NEWLINE][NEWLINE]Maintain the illusion: pay two turns of net Gold income, at least 500 (speed-scaled), for 20 turns of +25% spy defense and +10% city strength. Demonstrate fear: free Great General, survivors +10 XP, 5 turns of Momentum, and two rebels near an occupied city. Custom diplomatic penalties are unavailable; no fabricated DLL calls are made.')
text.update({
 'TXT_KEY_CIV5_VILTRUM':'The Viltrum Empire',
 'TXT_KEY_CIV5_VILTRUM_HEADING_1':'Strength Confers the Right to Rule',
 'TXT_KEY_CIV5_VILTRUM_TEXT_1':text['TXT_KEY_VILTRUM_CIV_PEDIA'],
 'TXT_KEY_CIV5_VILTRUM_HEADING_2':'The Surviving Empire',
 'TXT_KEY_CIV5_VILTRUM_TEXT_2':strategy,
 'TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM':'Grand Regent Thragg',
 'TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM_NAME':'Grand Regent Thragg',
 'TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM_SUBTITLE':'Regent of the Viltrum Empire',
 'TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM_LIVED':'A fictional leader from Invincible',
 'TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM_TITLES':'Grand Regent',
 'TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM_HEADING_1':'Blood and Dominion',
 'TXT_KEY_CIVILOPEDIA_LEADERS_VILTRUM_TEXT_1':text['TXT_KEY_VILTRUM_LEADER_PEDIA'],
})
save('SQL/10_Viltrum_Text.sql','INSERT INTO Language_en_US(Tag,Text) VALUES\n'+',\n'.join('('+q(k)+','+q(v)+')' for k,v in text.items())+';\n')
print('Authored Viltrum SQL')
