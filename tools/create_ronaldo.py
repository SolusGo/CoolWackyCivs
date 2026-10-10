"""Generate Ronaldo's database definitions from the installed BNW/CP schema.

Only the disposable read-only cache clone is inspected. Generated inheritance
SQL reads the active game's baseline, so other balance mods remain supported.
"""
from pathlib import Path
import sqlite3
import sys
from validate_mod import apply_current_cp_schema

R = Path(__file__).resolve().parents[1]
OUT = R / 'CristianoRonaldo/SQL'
CHAPTERS = [
 ('The Island Boy',20,0,'On the steep streets of Funchal, talent appeared before opportunity. The dream was enormous, but its beginnings were small.',
  'Capital: +1 Food and +1 Production; one free Sporting Academy once its requirements are met. First military unit trained in the capital each era: +5 XP. Workers trained there: +1 Sight.'),
 ('Alone in Lisbon',45,1,'The child leaves his island, his family and everything familiar. Talent has opened the door; discipline must now keep it open.',
  'Newly trained military units: +5 XP. Earned promotions heal 10 HP, once per unit per turn. Sporting Academies: +1 additional Production.'),
 ('The Theatre of Dreams',80,3,'The tricks become purpose. The boy becomes an athlete, the winger becomes a match-winner, and potential becomes expectation.',
  'Level 4+ military units: Explosive Athlete (+1 Movement on turns begun above 90 HP; ignore rivers; +5% strength attacking from open terrain). Military Gold purchases: 5% rebate. Great Generals: +10% generation.'),
 ('The Standard of Madrid',120,4,'Records cease to be distant targets. Every season begins with the expectation that yesterday\'s impossible number will be surpassed.',
  'Level 4+ units: +5% strength against wounded units and cities; +15% General points fighting major-civ units. Veteran city captures: Culture and Golden Age Points equal to 3 x population, heal captor 15 HP (25-turn civ cooldown). Each distinct original capital: 2-turn Golden Age and +3 XP to surviving war participants.'),
 ("The Captain's Crown",165,5,'Individual brilliance brought admiration. Leadership brings something greater: the belief that an entire nation can finally cross the line together.',
  'Ordinary General aura: +3 percentage points. Military units within 2 tiles: +5% defense, +5% ranged defense, heal 3 HP at turn start. An enemy declaration of war grants 50 Golden Age Points and heals friendly-territory military units 5 HP (30-turn cooldown).'),
 ('Different League, Same Standard',215,6,'The shirt changes. The country changes. The role changes. The demand placed upon himself does not.',
  'Military upgrades: -15% Gold; retain all XP; Reinvention IV available; upgrades below 35% HP heal 15 HP. First 3 currently eligible overseas cities: +1 Gold, +1 Culture, +1 Tourism after Flight, +3% military production.'),
 ('Beyond Time',275,7,'Opponents change, generations change, and football itself changes. The number seven remains, still measuring himself against tomorrow.',
  'Immediately: 6-turn Golden Age, free Social Policy, +8 XP to all military units, full healing, 2 turns of We Love the King Day in all cities. During Golden Ages: +5% military production, Culture and Tourism; veterans heal 3 HP each turn. Every further 60 Ambition: 1-turn Golden Age, 15 x era Culture, +1% permanent military production AND Tourism (each capped at +5%; rewards continue).'),
]

def q(value): return "'" + str(value).replace("'", "''") + "'"
def clone(table, source, target, assignments):
 return f"CREATE TEMP TABLE CR7Clone AS SELECT * FROM {table} WHERE Type={q(source)};\nUPDATE CR7Clone SET ID=NULL,Type={q(target)}," + ','.join(f'{k}={v}' for k,v in assignments.items()) + f';\nINSERT INTO {table} SELECT * FROM CR7Clone;\nDROP TABLE CR7Clone;\n'

def generate():
 OUT.mkdir(parents=True,exist_ok=True)
 game = Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
 source=sqlite3.connect((game/'cache/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
 db=sqlite3.connect(':memory:'); source.backup(db);source.close()
 apply_current_cp_schema(db,game/'MODS/(1) Community Patch')
 core="""-- Brave New World + installed Community Patch v151 (5.4.6).
UPDATE CustomModOptions SET Value=1 WHERE Name IN
('EVENTS_BATTLES','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_CITY','EVENTS_GOLDEN_AGE','EVENTS_UNIT_CREATED',
 'EVENTS_UNIT_PREKILL','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES','EVENTS_WAR_AND_PEACE');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
('COLOR_CR7_RED',0.48,0.025,0.065,1),('COLOR_CR7_GOLD',0.94,0.74,0.24,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES('PLAYERCOLOR_CR7','COLOR_CR7_RED','COLOR_CR7_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
('TRAIT_CR7_HABIT','TXT_KEY_CR7_TRAIT_HELP','TXT_KEY_CR7_TRAIT');
"""
 core+=clone('Leaders','LEADER_WASHINGTON','LEADER_CRISTIANO_RONALDO',dict(
  Description=q('TXT_KEY_CR7_LEADER'),Civilopedia=q('TXT_KEY_CR7_LEADER_PEDIA'),CivilopediaTag=q('TXT_KEY_CIVILOPEDIA_LEADERS_CR7'),ArtDefineTag=q('CR7LeaderScene.xml'),PortraitIndex='0',IconAtlas=q('CR7_LEADER_ATLAS'),PackageID='NULL',VictoryCompetitiveness='10',WonderCompetitiveness='6',MinorCivCompetitiveness='5',Boldness='8',DiploBalance='6',WarmongerHate='4',WorkAgainstWillingness='4',WorkWithWillingness='7',DenounceWillingness='4',DoFWillingness='7',Loyalty='7',Neediness='3',Forgiveness='4',Chattiness='5',Meanness='4'))
 core+="INSERT INTO Leader_Traits VALUES('LEADER_CRISTIANO_RONALDO','TRAIT_CR7_HABIT');\n"
 core+=clone('Civilizations','CIVILIZATION_PORTUGAL','CIVILIZATION_RELENTLESS_SEVEN',dict(
  Description=q('TXT_KEY_CR7_CIV'),ShortDescription=q('TXT_KEY_CR7_CIV'),Adjective=q('TXT_KEY_CR7_ADJECTIVE'),Civilopedia=q('TXT_KEY_CR7_CIV_PEDIA'),CivilopediaTag=q('TXT_KEY_CIV5_CR7'),Strategy=q('TXT_KEY_CR7_STRATEGY'),DefaultPlayerColor=q('PLAYERCOLOR_CR7'),Playable='1',AIPlayable='0',PackageID='NULL',PortraitIndex='0',IconAtlas=q('CR7_ICON_ATLAS'),AlphaIconAtlas=q('CR7_ALPHA_ATLAS'),MapImage=q('CR7Map.dds'),DawnOfManImage=q('CR7Dawn.dds'),DawnOfManQuote=q('TXT_KEY_CR7_DAWN'),DawnOfManAudio=q(''),SoundtrackTag=q('PORTUGAL')))
 core+="INSERT INTO Civilization_Leaders VALUES('CIVILIZATION_RELENTLESS_SEVEN','LEADER_CRISTIANO_RONALDO');\n"
 for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
  cols=[r[1] for r in db.execute('pragma table_info('+table+')')]
  core+=f"INSERT INTO {table}({','.join(cols)}) SELECT " + ','.join(q('CIVILIZATION_RELENTLESS_SEVEN') if c=='CivilizationType' else c for c in cols) + f" FROM {table} WHERE CivilizationType='CIVILIZATION_PORTUGAL';\n"
 core+=clone('Units','UNIT_CAVALRY','UNIT_CR7_COMPLETE_FORWARD',dict(Description=q('TXT_KEY_CR7_UNIT'),Civilopedia=q('TXT_KEY_CR7_UNIT_PEDIA'),Strategy=q('TXT_KEY_CR7_UNIT_STRATEGY'),Help=q('TXT_KEY_CR7_UNIT_HELP'),Cost='(Cost*120+99)/100',Moves='Moves+1',PortraitIndex='0',IconAtlas=q('CR7_OBJECT_ATLAS'),UnitFlagIconOffset='0',UnitFlagAtlas=q('CR7_FLAG_ATLAS')))
 core+=clone('Buildings','BUILDING_BARRACKS','BUILDING_CR7_SPORTING_ACADEMY',dict(Description=q('TXT_KEY_CR7_ACADEMY'),Civilopedia=q('TXT_KEY_CR7_ACADEMY_PEDIA'),Strategy=q('TXT_KEY_CR7_ACADEMY_STRATEGY'),Help=q('TXT_KEY_CR7_ACADEMY_HELP'),PortraitIndex='1',IconAtlas=q('CR7_OBJECT_ATLAS')))
 core+="""INSERT INTO Civilization_UnitClassOverrides VALUES('CIVILIZATION_RELENTLESS_SEVEN','UNITCLASS_CAVALRY','UNIT_CR7_COMPLETE_FORWARD');
INSERT INTO Civilization_BuildingClassOverrides VALUES('CIVILIZATION_RELENTLESS_SEVEN','BUILDINGCLASS_BARRACKS','BUILDING_CR7_SPORTING_ACADEMY');
"""
 (OUT/'00_CR7_Core.sql').write_text(core,encoding='utf-8',newline='\n')
 # All current CP companion tables, including zero-row tables, inherit at activation.
 inheritance='-- Inherit active CP/balance-mod companion definitions, not hard-coded BNW stats.\n'
 for table, in db.execute("select name from sqlite_master where type='table' order by name").fetchall():
  if table.endswith('_new'):continue
  cols=[r[1] for r in db.execute('pragma table_info('+table+')')]
  for col,baseline,target in [('UnitType','UNIT_CAVALRY','UNIT_CR7_COMPLETE_FORWARD'),('BuildingType','BUILDING_BARRACKS','BUILDING_CR7_SPORTING_ACADEMY')]:
   if col not in cols or not table.startswith(('Unit_','UnitGameplay','Building_')):continue
   inheritance+=f'INSERT INTO {table}({",".join(cols)}) SELECT '+','.join(q(target) if c==col else c for c in cols)+f' FROM {table} WHERE {col}={q(baseline)};\n'
 inheritance+="""-- Aggregate additions so a baseline yield and the added yield never conflict.
CREATE TEMP TABLE CR7Yields AS SELECT YieldType,SUM(Yield) AS Yield FROM
(SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_CR7_SPORTING_ACADEMY'
 UNION ALL SELECT 'YIELD_PRODUCTION',1 UNION ALL SELECT 'YIELD_CULTURE',1) GROUP BY YieldType;
DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_CR7_SPORTING_ACADEMY';
INSERT INTO Building_YieldChanges SELECT 'BUILDING_CR7_SPORTING_ACADEMY',YieldType,Yield FROM CR7Yields;
DROP TABLE CR7Yields;
"""
 (OUT/'01_CR7_Inheritance.sql').write_text(inheritance,encoding='utf-8',newline='\n')
 effects='-- Native effects, with event-dependent effects implemented in CR7Runtime.lua.\n'
 promotions={
  'HABIT':(2,{'ExperiencePercent':15}), 'ACADEMY_TRAINING':(3,{'ExperiencePercent':5}),
  'FINISHER':(4,{'AttackWoundedMod':15,'River':1}), 'FINISHER_VETERAN':(5,{'AttackWoundedMod':8}),
  'EXPLOSIVE':(10,{'River':1}), 'EXPLOSIVE_OPEN':(10,{'AttackMod':5}),
  'EXPLOSIVE_MOVE':(10,{'MovesChange':1}), 'MADRID_GG':(11,{'GreatGeneralModifier':15}),
  'MADRID':(11,{'AttackWoundedMod':5,'CityAttack':5}),
  'CAPTAIN':(12,{'DefenseMod':5,'RangedDefenseMod':5}), 'FIRST_IN':(13,{}), 'WORKER_SIGHT':(14,{'VisibilityChange':1}),
  'FORWARD_MOBILITY':(0,{'CanMoveAfterAttacking':1}),
 }
 for i in range(1,5):promotions['REINVENTION_'+str(i)]=(5+i,{'CombatPercent':i*2})
 for name,(icon,values) in promotions.items():
  typ='PROMOTION_CR7_'+name
  effects+=f"INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES({q(typ)},{q('TXT_KEY_'+typ)},{q('TXT_KEY_'+typ+'_HELP')},1,{1 if name in ['FINISHER','FORWARD_MOBILITY'] else 0},{icon},'CR7_OBJECT_ATLAS','PEDIA_ATTRIBUTES',{q('TXT_KEY_'+typ)});\n"
  if values:effects+=f'UPDATE UnitPromotions SET '+','.join(f'{k}={v}' for k,v in values.items())+f' WHERE Type={q(typ)};\n'
 effects+="INSERT INTO Unit_FreePromotions VALUES('UNIT_CR7_COMPLETE_FORWARD','PROMOTION_CR7_FINISHER');\nINSERT INTO Unit_FreePromotions VALUES('UNIT_CR7_COMPLETE_FORWARD','PROMOTION_CR7_FORWARD_MOBILITY');\n"
 for i in range(1,8):
  effects+=f"INSERT INTO Policies(Type,Description,Civilopedia,Help,IsDummy,PolicyBranchType,CultureCost,GridX,GridY,PortraitIndex,IconAtlas) VALUES('POLICY_CR7_CHAPTER_{i}','TXT_KEY_CR7_CHAPTER_{i}_TITLE','TXT_KEY_CR7_CHAPTER_{i}_STORY','TXT_KEY_CR7_CHAPTER_{i}_EFFECTS',1,NULL,-1,-1,-1,{14+i},'CR7_OBJECT_ATLAS');\n"
 effects+="""UPDATE Policies SET GreatGeneralRateModifier=10 WHERE Type='POLICY_CR7_CHAPTER_3';
UPDATE Policies SET GreatGeneralExtraBonus=3 WHERE Type='POLICY_CR7_CHAPTER_5';
UPDATE Policies SET UnitUpgradeCostMod=-15 WHERE Type='POLICY_CR7_CHAPTER_6';
INSERT INTO Policy_CapitalYieldChanges VALUES('POLICY_CR7_CHAPTER_1','YIELD_FOOD',1),('POLICY_CR7_CHAPTER_1','YIELD_PRODUCTION',1);
INSERT INTO Policy_GoldenAgeYieldMod VALUES('POLICY_CR7_CHAPTER_7','YIELD_CULTURE',5),('POLICY_CR7_CHAPTER_7','YIELD_TOURISM',5);
"""
 for i in range(1,6):
  effects+=f"INSERT INTO Policies(Type,Description,IsDummy,PolicyBranchType,CultureCost,GridX,GridY,MilitaryProductionModifier) VALUES('POLICY_CR7_LEGACY_{i}','TXT_KEY_CR7_LEGACY',1,NULL,-1,-1,-1,1);\nINSERT INTO Policy_YieldModifiers VALUES('POLICY_CR7_LEGACY_{i}','YIELD_TOURISM',1);\n"
 for name,military in [('ACADEMY_PRODUCTION',0),('OVERSEAS',3),('OVERSEAS_FLIGHT',0),('GOLDEN_PRODUCTION',5)]:
  effects+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES('BUILDINGCLASS_CR7_{name}','BUILDING_CR7_{name}','TXT_KEY_CR7_DUMMY');\nINSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,IsDummy,ShowInPedia,NeverCapture,NukeImmune,ConquestProb,MilitaryProductionModifier) VALUES('BUILDING_CR7_{name}','BUILDINGCLASS_CR7_{name}','TXT_KEY_CR7_DUMMY',-1,-1,-1,1,0,1,1,0,{military});\n"
 effects+="""INSERT INTO Building_YieldChanges VALUES('BUILDING_CR7_ACADEMY_PRODUCTION','YIELD_PRODUCTION',1),('BUILDING_CR7_OVERSEAS','YIELD_GOLD',1),('BUILDING_CR7_OVERSEAS','YIELD_CULTURE',1),('BUILDING_CR7_OVERSEAS_FLIGHT','YIELD_TOURISM',1);
INSERT INTO Leader_Flavors SELECT 'LEADER_CRISTIANO_RONALDO',Type,CASE Type
 WHEN 'FLAVOR_MILITARY_TRAINING' THEN 10 WHEN 'FLAVOR_MOBILE' THEN 9 WHEN 'FLAVOR_OFFENSE' THEN 8
 WHEN 'FLAVOR_GREAT_PEOPLE' THEN 9 WHEN 'FLAVOR_CULTURE' THEN 7 WHEN 'FLAVOR_GOLD' THEN 7
 WHEN 'FLAVOR_WONDER' THEN 6 WHEN 'FLAVOR_EXPANSION' THEN 5 WHEN 'FLAVOR_DIPLOMACY' THEN 5
 WHEN 'FLAVOR_SCIENCE' THEN 6 WHEN 'FLAVOR_NAVAL' THEN 4 WHEN 'FLAVOR_NUKE' THEN 3 ELSE 5 END FROM Flavors;
INSERT INTO Leader_MajorCivApproachBiases SELECT 'LEADER_CRISTIANO_RONALDO',MajorCivApproachType,CASE MajorCivApproachType WHEN 'MAJOR_CIV_APPROACH_DECEPTIVE' THEN 2 WHEN 'MAJOR_CIV_APPROACH_AFRAID' THEN 2 WHEN 'MAJOR_CIV_APPROACH_WAR' THEN 8 WHEN 'MAJOR_CIV_APPROACH_FRIENDLY' THEN 7 ELSE 5 END FROM Leader_MajorCivApproachBiases WHERE LeaderType='LEADER_WASHINGTON';
INSERT INTO Leader_MinorCivApproachBiases SELECT 'LEADER_CRISTIANO_RONALDO',MinorCivApproachType,5 FROM Leader_MinorCivApproachBiases WHERE LeaderType='LEADER_WASHINGTON';
INSERT INTO Civilization_SpyNames SELECT 'CIVILIZATION_RELENTLESS_SEVEN',SpyName FROM Civilization_SpyNames WHERE CivilizationType='CIVILIZATION_PORTUGAL';
INSERT INTO Diplomacy_Responses SELECT 'LEADER_CRISTIANO_RONALDO',ResponseType,Response,Bias FROM Diplomacy_Responses WHERE LeaderType='LEADER_WASHINGTON';
"""
 for response in ['FIRST_GREETING','DECLARE_WAR','ATTACKED','DEFEATED','VICTORY']:
  effects+=f"DELETE FROM Diplomacy_Responses WHERE LeaderType='LEADER_CRISTIANO_RONALDO' AND ResponseType='RESPONSE_{response}';\nINSERT INTO Diplomacy_Responses VALUES('LEADER_CRISTIANO_RONALDO','RESPONSE_{response}','TXT_KEY_CR7_DIPLO_{response}',1);\n"
 cities=['Funchal','Lisbon','Manchester','Madrid','Turin','Riyadh','Porto','Braga','Aveiro','Coimbra','Faro','Setúbal','Guimarães','Leiria','Viseu','Moscow','Cardiff','Paris','Doha','Jeddah']
 for i,_ in enumerate(cities,1):effects+=f"INSERT INTO Civilization_CityNames VALUES('CIVILIZATION_RELENTLESS_SEVEN','TXT_KEY_CITY_CR7_{i}');\n"
 (OUT/'02_CR7_Effects.sql').write_text(effects,encoding='utf-8',newline='\n')
 art='INSERT INTO IconTextureAtlases(Atlas,IconSize,Filename,IconsPerRow,IconsPerColumn) VALUES\n'
 rows=[]
 for atlas,stem,count,sizes in [('ICON','Icon',1,(256,128,80,64,48,45,32,24,16)),('ALPHA','Alpha',1,(256,128,80,64,48,45,32,24,16)),('LEADER','Leader',1,(256,128,64)),('OBJECT','Objects',24,(256,128,80,64,48,45,32,24,16)),('FLAG','Flag',1,(32,))]:
  for size in sizes:rows.append(f"('CR7_{atlas}_ATLAS',{size},'CR7{stem}{size}.dds',{count if count==1 else 6},{1 if count==1 else 4})")
 art+=',\n'.join(rows)+';\n'
 (OUT/'03_CR7_Art.sql').write_text(art,encoding='utf-8',newline='\n')
 texts={
  'TXT_KEY_CR7_CIV':'The Relentless Seven','TXT_KEY_CR7_ADJECTIVE':'Relentless','TXT_KEY_CR7_LEADER':'Cristiano Ronaldo',
  'TXT_KEY_CIVILOPEDIA_LEADERS_CR7':'Cristiano Ronaldo','TXT_KEY_CIV5_CR7':'The Relentless Seven',
  'TXT_KEY_CR7_TITLE':'The Boy from Madeira Who Refused to Be Ordinary','TXT_KEY_CR7_TRAIT':'Work Until Greatness Becomes Habit',
  'TXT_KEY_CR7_TRAIT_HELP':'+15% Combat Experience for military units. Each genuine upgrade grants a permanent Reinvention tier: +2% strength and 3 HP healing per kill per tier (maximum III, IV after Chapter VI). Earn Ambition through development and victories to unlock seven permanent Career Chapters. Click CR7 to view your career.',
  'TXT_KEY_CR7_CIV_PEDIA':'A civilization inspired by Cristiano Ronaldo: Madeira, Sporting, Manchester, Madrid, Portugal, Juventus and Al-Nassr. Preserve veterans and pursue ambition across generations.',
  'TXT_KEY_CR7_LEADER_PEDIA':'Cristiano Ronaldo rose from Funchal through disciplined development, adapting across clubs and eras while captaining Portugal. This civilization celebrates training, longevity and continuing ambition; it assumes no future achievements.',
  'TXT_KEY_CR7_STRATEGY':'Train at Sporting Academies, preserve high-level units, and upgrade them through successive eras. Earn Ambition from worthy victories and civic achievements. Freedom, Domination and Culture suit a veteran-led empire; Diplomacy is a secondary path.',
  'TXT_KEY_CR7_UNIT':'Complete Forward','TXT_KEY_CR7_UNIT_HELP':'Cavalry replacement: active CP baseline, +20% Production cost, +1 Movement, move after attacking. Relentless Finisher: +15% vs wounded, ignore rivers, heal 8 HP on kills, restore 1 Movement after first kill each turn. After upgrade: +8% vs wounded, heal 5 HP on kills.',
  'TXT_KEY_CR7_UNIT_PEDIA':'An adaptable veteran whose explosive attack becomes a decisive finish. Uses standard Cavalry world art with a custom flag and portrait.',
  'TXT_KEY_CR7_UNIT_STRATEGY':'Finish wounded opponents; keep the Forward alive to preserve its reduced veteran promotion through upgrades.',
  'TXT_KEY_CR7_ACADEMY':'Sporting Academy','TXT_KEY_CR7_ACADEMY_HELP':'Barracks replacement. Retains all active CP Barracks effects; +1 Production, +1 Culture. Produced military units gain +5% Combat Experience and First In, Last Out. At Level 4: 15 Production and 10 Culture in their original training city, +1 Ambition; one rewarded unit per training city per era.',
  'TXT_KEY_CR7_ACADEMY_PEDIA':'Inspired by the lonely but formative years of training in Lisbon. Purchased units do not receive its training bonuses.',
  'TXT_KEY_CR7_ACADEMY_STRATEGY':'Build early, then protect and promote its graduates. Each training city can celebrate one Level 4 graduate per era.',
  'TXT_KEY_CR7_DUMMY':'Career bonus','TXT_KEY_CR7_LEGACY':'The Story Is Still Being Written',
  'TXT_KEY_CR7_DIPLO_FIRST_GREETING':'I came from a small island with a dream larger than the horizon. Tell me—what are you prepared to sacrifice for yours?',
  'TXT_KEY_CR7_DIPLO_DECLARE_WAR':'You have chosen the greatest test. I will meet it at my highest level.',
  'TXT_KEY_CR7_DIPLO_ATTACKED':'Pressure does not change the standard. It reveals who was prepared.',
  'TXT_KEY_CR7_DIPLO_DEFEATED':'You have won today. Tomorrow, the work begins again.',
  'TXT_KEY_CR7_DIPLO_VICTORY':'Greatness was never one moment. It was every day that came before it.',
 }
 texts['TXT_KEY_CR7_DAWN']='From the island of Madeira came a child unwilling to accept the limits placed before him. He left home while still young, carrying neither wealth nor certainty—only a conviction that talent must be sharpened until no weakness remained.[NEWLINE][NEWLINE]In Manchester, he transformed spectacle into purpose. In Madrid, goals became records and records became expectation. Across Europe and beyond it, new leagues brought new demands, yet the standard never fell. For Portugal, years of disappointment ended beneath the leadership of its eternal captain.[NEWLINE][NEWLINE]Cristiano Ronaldo, Boy from Madeira Who Refused to Be Ordinary, your people now inherit that relentless ambition. Train them until exhaustion becomes discipline. Preserve those who have survived the hardest trials. Strike when your opponents weaken, and let every age witness your reinvention.[NEWLINE][NEWLINE]Will your greatness fade with the passage of time—or will history discover that you have only just begun?'
 for i,(title,_,_,story,bonus) in enumerate(CHAPTERS,1):
  for suffix,text in [('TITLE',title),('STORY',story),('EFFECTS',bonus)]:texts[f'TXT_KEY_CR7_CHAPTER_{i}_{suffix}']=text
 promo_help={
 'HABIT':('Relentless Training','+15% Combat Experience.'),'ACADEMY_TRAINING':('Sporting Graduate','+5% Combat Experience.'),
 'FINISHER':('Relentless Finisher','+15% vs wounded; ignore rivers; heal 8 HP on kills; first kill each turn restores 1 Movement, without an additional attack.'),
 'FINISHER_VETERAN':('Veteran Finisher','+8% vs wounded; heal 5 HP on kills. Retained through upgrades.'),
  'EXPLOSIVE':('Explosive Athlete','Ignore rivers; +5% strength attacking FROM open terrain; gain 1 Movement on turns begun above 90 HP.'),
  'EXPLOSIVE_OPEN':('Explosive Athlete: open ground','+5% attacking strength while standing on open ground.'),
  'EXPLOSIVE_MOVE':('Explosive Athlete: fresh legs','+1 Movement for this turn, qualified at its beginning above 90 HP.'),
  'MADRID_GG':('Madrid: major opponent','+15% Great General points in the current combat against a major-civilization unit.'),
 'MADRID':('The Standard of Madrid','+5% vs wounded; +5% vs cities; +15% General points against major-civ units.'),
 'CAPTAIN':("Captain's Standard",'+5% defense; +5% ranged defense; heal 3 HP at turn start within 2 tiles of a friendly Great General.'),
 'FIRST_IN':('First In, Last Out','First time at Level 4: original training city gains 15 Production, 10 Culture; +1 Ambition. One rewarded graduate per city per era.'),
 'WORKER_SIGHT':('Madeiran Horizons','+1 Sight.'),'FORWARD_MOBILITY':('Complete Forward','Can move after attacking; does not grant additional attacks.'),
 }
 for i in range(1,5):promo_help['REINVENTION_'+str(i)]=('Reinvention '+['I','II','III','IV'][i-1],f'+{2*i}% strength; heal {3*i} HP after a kill. This is one total tier, not stacking tiers.')
 for name,(title,helptext) in promo_help.items():
  texts['TXT_KEY_PROMOTION_CR7_'+name]=title;texts['TXT_KEY_PROMOTION_CR7_'+name+'_HELP']=helptext
 for i,city in enumerate(cities,1):texts[f'TXT_KEY_CITY_CR7_{i}']=city
 (OUT/'10_CR7_Text.sql').write_text('INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES\n'+',\n'.join(f'({q(k)},{q(v)})' for k,v in texts.items())+';\n',encoding='utf-8',newline='\n')
 print('Generated CR7 database, inherited companion tables, localization and art registration')

if __name__=='__main__':generate()
