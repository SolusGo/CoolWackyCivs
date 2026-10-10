"""Generate Last City SQL against the real BNW/CP schema, without ModBuddy."""
from pathlib import Path
import sqlite3
from validate_mod import apply_current_cp_schema, quote
from lastcity_localization import TEXT

R=Path(__file__).resolve().parents[1]; V=R/'TheLastCity'
INFRA=[('BARRACKS',100,'TECH_MASONRY'),('RESIDENTIAL',220,'TECH_ENGINEERING'),
 ('SHELTER',400,'TECH_DYNAMITE'),('HOSPITAL',300,'TECH_BIOLOGY'),
 ('STORAGE',240,'TECH_METAL_CASTING'),('DEPOT',450,'TECH_RAILROAD'),
 ('WATER',300,'TECH_CHEMISTRY'),('DAWN',900,'TECH_ATOMIC_THEORY')]

def clone(table, old, new, **fields):
    fields={'ID':None,'Type':new,**fields}
    assignments=','.join(quote(k)+'='+('NULL' if v is None else str(v) if isinstance(v,int) else "'"+v.replace("'","''")+"'") for k,v in fields.items())
    return f"CREATE TEMP TABLE LCClone AS SELECT * FROM {quote(table)} WHERE Type='{old}';\nUPDATE LCClone SET {assignments};\nINSERT INTO {quote(table)} SELECT * FROM LCClone;\nDROP TABLE LCClone;\n"

def companions(d, prefix, column, old, new, skip=()):
    out=[]
    for (table,) in sorted(d.execute("SELECT name FROM sqlite_master WHERE type='table'")):
        columns=[r[1] for r in d.execute('PRAGMA table_info('+quote(table)+')')]
        if table.startswith(prefix) and column in columns and table not in skip:
            out.append(f"CREATE TEMP TABLE LCCompanion AS SELECT * FROM {quote(table)} WHERE {column}='{old}';\nUPDATE LCCompanion SET {column}='{new}';\nINSERT INTO {quote(table)} SELECT * FROM LCCompanion;\nDROP TABLE LCCompanion;\n")
    return ''.join(out)

def main():
    u=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    source=sqlite3.connect((u/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    d=sqlite3.connect(':memory:');source.backup(d);source.close();apply_current_cp_schema(d,u/'MODS/(1) Community Patch')
    (V/'SQL').mkdir(parents=True,exist_ok=True)
    core="""-- BNW + Community Patch v151. Stock art remains available without assets.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_CITY_FOUNDING','EVENTS_UNIT_CREATED','EVENTS_UNIT_PREKILL','EVENTS_UNIT_UPGRADES','EVENTS_UNIT_CONVERTS');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_LC_COAL',0.09,0.10,0.12,1),('COLOR_LC_FIRE',0.95,0.65,0.25,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_LC','COLOR_LC_COAL','COLOR_LC_FIRE','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_LC_FINAL_SANCTUARY','TXT_KEY_LC_TRAIT_HELP','TXT_KEY_LC_TRAIT');
"""
    core+=clone('Leaders','LEADER_WASHINGTON','LEADER_LC_WARDEN',Description='TXT_KEY_LC_LEADER',Civilopedia='TXT_KEY_LC_LEADER_PEDIA',CivilopediaTag='TXT_KEY_CIVILOPEDIA_LEADERS_LC_WARDEN',PackageID=None,Boldness=2,VictoryCompetitiveness=2,WonderCompetitiveness=3,MinorCivCompetitiveness=2,WarmongerHate=9,DoFWillingness=8,Loyalty=9,Meanness=1)
    core+="INSERT INTO Leader_Traits VALUES ('LEADER_LC_WARDEN','TRAIT_LC_FINAL_SANCTUARY');\n"
    core+=clone('Civilizations','CIVILIZATION_AMERICA','CIVILIZATION_LAST_CITY',Description='TXT_KEY_LC_CIV',ShortDescription='TXT_KEY_LC_SHORT',Adjective='TXT_KEY_LC_ADJECTIVE',Civilopedia='TXT_KEY_LC_CIV_PEDIA',CivilopediaTag='TXT_KEY_CIV5_LC',Strategy='TXT_KEY_LC_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_LC',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_LC_DAWN',DawnOfManAudio='')
    core+="INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_LAST_CITY','LEADER_LC_WARDEN');\n"
    core+=clone('Units','UNIT_SPEARMAN','UNIT_LC_LAST_WATCH',Description='TXT_KEY_LC_WATCH',Civilopedia='TXT_KEY_LC_WATCH_PEDIA',Help='TXT_KEY_LC_WATCH_HELP',Strategy='TXT_KEY_LC_WATCH_STRATEGY')
    core+=clone('Buildings','BUILDING_GRANARY','BUILDING_LC_DISTRICT',Description='TXT_KEY_LC_DISTRICT',Civilopedia='TXT_KEY_LC_DISTRICT_PEDIA',Help='TXT_KEY_LC_DISTRICT_HELP',Strategy='TXT_KEY_LC_DISTRICT_STRATEGY')
    core+="""INSERT INTO Civilization_UnitClassOverrides VALUES ('CIVILIZATION_LAST_CITY','UNITCLASS_SPEARMAN','UNIT_LC_LAST_WATCH');
INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_LAST_CITY','BUILDINGCLASS_GRANARY','BUILDING_LC_DISTRICT');
INSERT INTO Civilization_CityNames VALUES ('CIVILIZATION_LAST_CITY','TXT_KEY_LC_CAPITAL');
"""
    for i in range(1,11):core+=f"INSERT INTO Civilization_SpyNames VALUES ('CIVILIZATION_LAST_CITY','TXT_KEY_LC_SPY_{i}');\n"
    inherit=companions(d,'Leader_','LeaderType','LEADER_WASHINGTON','LEADER_LC_WARDEN',('Leader_Traits',))
    for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
        inherit+=f"CREATE TEMP TABLE LCCompanion AS SELECT * FROM {table} WHERE CivilizationType='CIVILIZATION_AMERICA';\nUPDATE LCCompanion SET CivilizationType='CIVILIZATION_LAST_CITY';\nINSERT INTO {table} SELECT * FROM LCCompanion;\nDROP TABLE LCCompanion;\n"
    inherit+=companions(d,'Unit_','UnitType','UNIT_SPEARMAN','UNIT_LC_LAST_WATCH')
    inherit+=companions(d,'Building_','BuildingType','BUILDING_GRANARY','BUILDING_LC_DISTRICT')
    inherit+="""UPDATE Leader_Flavors SET Flavor=CASE FlavorType
 WHEN 'FLAVOR_EXPANSION' THEN 0 WHEN 'FLAVOR_OFFENSE' THEN 1
 WHEN 'FLAVOR_DEFENSE' THEN 10 WHEN 'FLAVOR_CITY_DEFENSE' THEN 10
 WHEN 'FLAVOR_GROWTH' THEN 4 WHEN 'FLAVOR_PRODUCTION' THEN 9
 WHEN 'FLAVOR_SCIENCE' THEN 7 ELSE Flavor END WHERE LeaderType='LEADER_LC_WARDEN';
"""
    effects=[]
    for key,cost,tech in INFRA:
        effects.append(f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description,MaxPlayerInstances) VALUES ('BUILDINGCLASS_LC_{key}','BUILDING_LC_{key}','TXT_KEY_LC_BUILDING_{key}',1);\n")
        effects.append(f"INSERT INTO Buildings(Type,BuildingClass,Description,Civilopedia,Help,Strategy,Cost,FaithCost,PrereqTech,GoldMaintenance,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,PortraitIndex,IconAtlas,ArtDefineTag) SELECT 'BUILDING_LC_{key}','BUILDINGCLASS_LC_{key}','TXT_KEY_LC_BUILDING_{key}','TXT_KEY_LC_BUILDING_HELP_{key}','TXT_KEY_LC_BUILDING_HELP_{key}','TXT_KEY_LC_BUILDING_HELP_{key}',{cost},-1,'{tech}',0,-1,1,1,0,PortraitIndex,IconAtlas,ArtDefineTag FROM Buildings WHERE Type='BUILDING_GRANARY';\n")
        effects.append(f"INSERT INTO Building_ClassesNeededInCity VALUES ('BUILDING_LC_{key}','BUILDINGCLASS_GRANARY');\nINSERT INTO Building_Flavors VALUES ('BUILDING_LC_{key}','FLAVOR_CITY_DEFENSE',10);\nINSERT INTO Building_Flavors VALUES ('BUILDING_LC_{key}','FLAVOR_PRODUCTION',8);\n")
    dummies={'ENGINEERS':('YIELD_PRODUCTION',3),'SCIENTISTS':('YIELD_SCIENCE',3),'SCHOLARS':('YIELD_CULTURE',3),
     'UNITED':('YIELD_PRODUCTION',10),'ANXIOUS':('YIELD_PRODUCTION',-5),'UNREST':('YIELD_PRODUCTION',-15),'BREAKING':('YIELD_PRODUCTION',-30),
     'LEGACY':(None,2),'GATES_UP':(None,20),'GATES_DOWN':(None,-20),'ENDURES':('YIELD_PRODUCTION',5)}
    for key,(yield_type,value) in dummies.items():
        defense=value if yield_type is None else 0
        effects.append(f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_LC_{key}','BUILDING_LC_{key}','TXT_KEY_LC_DUMMY');\nINSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,IsDummy,ShowInPedia,GlobalDefenseMod) VALUES ('BUILDING_LC_{key}','BUILDINGCLASS_LC_{key}','TXT_KEY_LC_DUMMY',-1,-1,-1,1,1,0,1,0,{defense});\n")
        if yield_type:effects.append(f"INSERT INTO Building_YieldModifiers VALUES ('BUILDING_LC_{key}','{yield_type}',{value});\n")
    promotions={'SANCTUARY':({'DefenseMod':15},1),'NO_CONQUEST':({'NoCapture':1},0),
     'WATCH':({},0),'RESOLVE':({'DefenseMod':5},1),'INVADER':({'AttackMod':10},0),
     'BOSS':({'CombatPercent':25,'CityAttack':35},0),'COMMAND':({'CombatPercent':10},1),
     'PLAGUE':({},0),'ELITE':({'CombatPercent':15},0)}
    for n in range(1,6):
        promotions['VETERAN_'+str(n)]=({},0)
        promotions['VETERAN_ACTIVE_'+str(n)]=({'DefenseMod':3*n},1)
        promotions['TRAINING_'+str(n)]=({'DefenseMod':2*n},1)
    for key,(fields,lost) in promotions.items():
        extra=''.join(','+quote(k) for k in fields);values=''.join(','+str(v) for v in fields.values())
        effects.append(f"INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,LostOnGifting,PortraitIndex,IconAtlas,PediaType,PediaEntry{extra}) VALUES ('PROMOTION_LC_{key}','TXT_KEY_LC_PROMO_{key}','TXT_KEY_LC_PROMO_HELP_{key}',1,{lost},1,59,'PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LC_PROMO_{key}'{values});\n")
    effects.append("INSERT INTO Unit_FreePromotions VALUES ('UNIT_LC_LAST_WATCH','PROMOTION_LC_WATCH');\n")
    # Stock icon atlases and paths are inherited, rather than fabricated DDS.
    for key in ['ECONOMY','REFUGEES','SIEGES']:
        effects.append(f"INSERT INTO Concepts(Type,Topic,Description,Summary,Advisor,CivilopediaHeaderType) VALUES ('CONCEPT_LC_{key}','TXT_KEY_TOPIC_CITIES','TXT_KEY_LC_CONCEPT_{key}','TXT_KEY_LC_CONCEPT_HELP_{key}','MILITARY','HEADER_CITIES');\n")
    for response in ['FIRST_GREETING','GREETING_NEUTRAL_HELLO','GREETING_POLITE_HELLO','GREETING_HOSTILE_HELLO','DECLAREWAR','ATTACKED','DEFEATED']:
        effects.append(f"DELETE FROM Diplomacy_Responses WHERE LeaderType='LEADER_LC_WARDEN' AND ResponseType='RESPONSE_{response}';\nINSERT INTO Diplomacy_Responses VALUES ('LEADER_LC_WARDEN','RESPONSE_{response}','TXT_KEY_LC_DIPLO_{response}',100);\n")
    for name,content in [('00_LC_Core.sql',core),('01_LC_Inheritance.sql',inherit),('02_LC_Effects.sql',''.join(effects))]:
        (V/'SQL'/name).write_bytes(content.encode('utf-8'))
    text='-- Generated by tools/create_lastcity_database.py from lastcity_localization.py\n'
    for key,value in sorted(TEXT.items()):text+="INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_LC_"+key+"','"+value.replace("'","''")+"');\n"
    (V/'SQL/10_LC_Text.sql').write_bytes(text.encode('utf-8'))
    print('Generated Last City database and localization')

if __name__=='__main__':main()
