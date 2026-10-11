"""Generate Paradise SQL from the installed read-only BNW/CP v151 schema.

Only generation needs the local cache. Installation uses the finished SQL/DDS.
Companion cloning includes every active BuildingType table, with no schema guesses.
"""
from pathlib import Path
import sqlite3
import sys

R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'tools'))
from validate_mod import apply_current_cp_schema
DEST=R/'TheBoyWhoTouchedParadise/SQL'

def q(value):
    if value is None:return 'NULL'
    if isinstance(value,(int,float)):return str(value)
    return "'"+value.replace("'","''")+"'"

def generate():
    game=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    source=sqlite3.connect((game/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    db=sqlite3.connect(':memory:');source.backup(db);source.close()
    apply_current_cp_schema(db,game/'MODS/(1) Community Patch')
    db.row_factory=sqlite3.Row
    DEST.mkdir(parents=True,exist_ok=True)
    core=["-- Separate Messi civilization. BNW + Community Patch v151; PARADISE namespace only.",
        "UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_CITY','EVENTS_CITY_CAPITAL','EVENTS_GOLDEN_AGE','EVENTS_MINORS','EVENTS_UNIT_CREATED','EVENTS_UNIT_PREKILL','EVENTS_UNIT_CAPTURE','EVENTS_UNIT_CONVERTS');",
        "INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_PARADISE_SKY',0.36,0.72,0.91,1),('COLOR_PARADISE_WHITE',0.97,0.97,0.94,1);",
        "INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_PARADISE','COLOR_PARADISE_SKY','COLOR_PARADISE_WHITE','COLOR_PLAYER_WHITE_TEXT');",
        "INSERT INTO Traits(Type,Description,ShortDescription,GreatPeopleRateModifier) VALUES ('TRAIT_PARADISE_POINT_OF_DIFFERENCE','TXT_KEY_PARADISE_UA_HELP','TXT_KEY_PARADISE_UA',5);"]
    def clone(table,base,target,values):
        cols={r[1] for r in db.execute('PRAGMA table_info('+table+')')}
        assert set(values)<=cols,(table,set(values)-cols)
        core.extend([f"CREATE TEMP TABLE ParadiseClone AS SELECT * FROM {table} WHERE Type={q(base)};",
            'UPDATE ParadiseClone SET ID=NULL,Type='+q(target)+','+','.join(k+'='+q(v) for k,v in values.items())+';',
            f'INSERT INTO {table} SELECT * FROM ParadiseClone;', 'DROP TABLE ParadiseClone;'])
    clone('Leaders','LEADER_WASHINGTON','LEADER_PARADISE_MESSI',dict(
        Description='TXT_KEY_PARADISE_LEADER',Civilopedia='TXT_KEY_PARADISE_LEADER_PEDIA',
        CivilopediaTag='TXT_KEY_CIVILOPEDIA_LEADERS_PARADISE',ArtDefineTag='ParadiseLeaderScene.xml',
        PortraitIndex=0,IconAtlas='PARADISE_LEADER_ATLAS',PackageID=None))
    core.append("INSERT INTO Leader_Traits VALUES ('LEADER_PARADISE_MESSI','TRAIT_PARADISE_POINT_OF_DIFFERENCE');")
    clone('Civilizations','CIVILIZATION_AMERICA','CIVILIZATION_BOY_TOUCHED_PARADISE',dict(
        Description='TXT_KEY_PARADISE_CIV',ShortDescription='TXT_KEY_PARADISE_SHORT',Adjective='TXT_KEY_PARADISE_ADJECTIVE',
        Civilopedia='TXT_KEY_PARADISE_PEDIA',CivilopediaTag='TXT_KEY_CIV5_PARADISE',Strategy='TXT_KEY_PARADISE_STRATEGY',
        DefaultPlayerColor='PLAYERCOLOR_PARADISE',Playable=1,AIPlayable=0,PackageID=None,
        PortraitIndex=0,IconAtlas='PARADISE_ICON_ATLAS',AlphaIconAtlas='PARADISE_ALPHA_ATLAS',
        MapImage='ParadiseMap.dds',DawnOfManImage='ParadiseDawn.dds',DawnOfManQuote='TXT_KEY_PARADISE_DAWN',
        DawnOfManAudio='',SoundtrackTag='BRAZIL',ArtDefineTag='ART_DEF_CIVILIZATION_BRAZIL',
        ArtStyleType='ARTSTYLE_EUROPEAN',ArtStyleSuffix='_EURO',ArtStylePrefix='EUROPEAN '))
    core.append("INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_BOY_TOUCHED_PARADISE','LEADER_PARADISE_MESSI');")
    for table in ('Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits'):
        columns=[r[1] for r in db.execute('PRAGMA table_info('+table+')')]
        expr=[q('CIVILIZATION_BOY_TOUCHED_PARADISE') if c=='CivilizationType' else c for c in columns]
        core.append(f"INSERT INTO {table}({','.join(columns)}) SELECT {','.join(expr)} FROM {table} WHERE CivilizationType='CIVILIZATION_AMERICA';")
    core.append("INSERT INTO UnitClasses(Type,Description,DefaultUnit,MaxPlayerInstances) VALUES ('UNITCLASS_PARADISE_EL_DIEZ','TXT_KEY_PARADISE_EL_DIEZ','UNIT_PARADISE_EL_DIEZ',1);")
    # Worker skeleton/model with no Build rows, combat, religion or expend actions.
    clone('Units','UNIT_WORKER','UNIT_PARADISE_EL_DIEZ',dict(
        Class='UNITCLASS_PARADISE_EL_DIEZ',Description='TXT_KEY_PARADISE_EL_DIEZ',Civilopedia='TXT_KEY_PARADISE_EL_DIEZ_PEDIA',
        Strategy='TXT_KEY_PARADISE_EL_DIEZ_STRATEGY',Help='TXT_KEY_PARADISE_EL_DIEZ_HELP',Cost=-1,FaithCost=0,
        RequiresFaithPurchaseEnabled=1,HurryCostModifier=-1,Moves=2,Combat=0,RangedCombat=0,CombatClass=None,
        Special=None,Capture=None,WorkRate=0,Found=0,FoundAbroad=0,FoundReligion=0,SpreadReligion=0,
        ReligionSpreads=0,ReligiousStrength=0,GoldenAgeTurns=0,CultureBombRadius=0,NoMaintenance=1,
        ExtraMaintenanceCost=0,UnitArtInfo='ART_DEF_UNIT_GREAT_MERCHANT',PortraitIndex=0,
        IconAtlas='PARADISE_OBJECT_ATLAS',UnitFlagIconOffset=0,UnitFlagAtlas='PARADISE_UNIT_FLAG_ATLAS'))
    core.append("INSERT INTO Civilization_UnitClassOverrides VALUES ('CIVILIZATION_BOY_TOUCHED_PARADISE','UNITCLASS_PARADISE_EL_DIEZ','UNIT_PARADISE_EL_DIEZ');")
    clone('Buildings','BUILDING_AMPHITHEATER','BUILDING_PARADISE_POTRERO',dict(
        Description='TXT_KEY_PARADISE_POTRERO',Civilopedia='TXT_KEY_PARADISE_POTRERO_PEDIA',
        Strategy='TXT_KEY_PARADISE_POTRERO_STRATEGY',Help='TXT_KEY_PARADISE_POTRERO_HELP',
        GreatPeopleRateModifier=db.execute("SELECT GreatPeopleRateModifier FROM Buildings WHERE Type='BUILDING_AMPHITHEATER'").fetchone()[0]+10,
        PortraitIndex=1,IconAtlas='PARADISE_OBJECT_ATLAS'))
    core.append("INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_BOY_TOUCHED_PARADISE','BUILDINGCLASS_AMPHITHEATER','BUILDING_PARADISE_POTRERO');")
    core.extend([
        "INSERT INTO BuildingClasses(Type,DefaultBuilding,Description,MaxPlayerInstances) VALUES ('BUILDINGCLASS_PARADISE_LAST_DANCE','BUILDING_PARADISE_LAST_DANCE','TXT_KEY_PARADISE_LAST_DANCE',1);",
        "INSERT INTO Buildings(Type,BuildingClass,Description,Civilopedia,Strategy,Help,Cost,PrereqTech,GoldMaintenance,GreatWorkCount,ConquestProb,NeverCapture,HurryCostModifier,PortraitIndex,IconAtlas) VALUES ('BUILDING_PARADISE_LAST_DANCE','BUILDINGCLASS_PARADISE_LAST_DANCE','TXT_KEY_PARADISE_LAST_DANCE','TXT_KEY_PARADISE_LAST_DANCE_PEDIA','TXT_KEY_PARADISE_LAST_DANCE_STRATEGY','TXT_KEY_PARADISE_LAST_DANCE_HELP',450,'TECH_RADIO',0,-1,0,1,-1,2,'PARADISE_OBJECT_ATLAS');"])
    for atlas,stem,sizes,columns in [
        ('ICON','Icon',(256,128,80,64,48,45,32,24,16),1),('ALPHA','Alpha',(256,128,80,64,48,45,32,24,16),1),
        ('LEADER','Leader',(256,128,64),1),('OBJECT','Objects',(256,128,80,64,48,45,32,24,16),8),('UNIT_FLAG','UnitFlag',(32,),1)]:
        for size in sizes:
            core.append(f"INSERT INTO IconTextureAtlases(Atlas,IconSize,Filename,IconsPerRow,IconsPerColumn) VALUES ('PARADISE_{atlas}_ATLAS',{size},'Paradise{stem}{size}.dds',{columns},1);")
    (DEST/'00_Paradise_Core.sql').write_text('\n'.join(core)+'\n',encoding='utf-8')
    companion=['-- Clone all installed Amphitheater companion tables, preserving CP/BNW effects.']
    tables=[r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
    for table in tables:
        if table.endswith('_new') or not table.startswith('Building_'):continue
        columns=[r[1] for r in db.execute('PRAGMA table_info('+table+')')]
        if 'BuildingType' not in columns:continue
        # Include even currently-empty tables so upstream CP rows still inherit at activation.
        companion.extend([f"CREATE TEMP TABLE ParadiseClone AS SELECT * FROM {table} WHERE BuildingType='BUILDING_AMPHITHEATER';",
            "UPDATE ParadiseClone SET BuildingType='BUILDING_PARADISE_POTRERO';",
            f'INSERT INTO {table} SELECT * FROM ParadiseClone;','DROP TABLE ParadiseClone;'])
    for table in ('Unit_FreePromotions','Unit_AITypes','UnitGameplay2DScripts'):
        companion.extend([f"CREATE TEMP TABLE ParadiseClone AS SELECT * FROM {table} WHERE UnitType='UNIT_WORKER';",
            "UPDATE ParadiseClone SET UnitType='UNIT_PARADISE_EL_DIEZ';",f'INSERT INTO {table} SELECT * FROM ParadiseClone;','DROP TABLE ParadiseClone;'])
    companion.extend(["UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='BUILDING_PARADISE_POTRERO' AND YieldType='YIELD_CULTURE';",
        "INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_PARADISE_POTRERO','YIELD_CULTURE',1 WHERE NOT EXISTS(SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_PARADISE_POTRERO' AND YieldType='YIELD_CULTURE');"])
    (DEST/'01_Paradise_Inheritance.sql').write_text('\n'.join(companion)+'\n',encoding='utf-8')
    effects=['-- Idempotently managed native city effects; no permanent stat increments in Lua.']
    for name,portrait in [('PRESENCE',0),('CAPITAL',7),('PRESSURE_5',7),('PRESSURE_10',7),('HOPE',5),('MEMORIAL',3),('FULFILLED',3)]:
        effects.append(f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_PARADISE_{name}','BUILDING_PARADISE_{name}','TXT_KEY_PARADISE_{name}');")
        effects.append(f"INSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,IsDummy,ShowInPedia,PortraitIndex,IconAtlas) VALUES ('BUILDING_PARADISE_{name}','BUILDINGCLASS_PARADISE_{name}','TXT_KEY_PARADISE_{name}',-1,-1,-1,1,1,0,1,0,{portrait},'PARADISE_OBJECT_ATLAS');")
    effects.extend([
        "UPDATE Buildings SET GreatPeopleRateModifier=10 WHERE Type='BUILDING_PARADISE_PRESENCE';",
        # CP's supported BuildingDefenseModifier increases the building contribution, not total defense.
        "UPDATE Buildings SET BuildingDefenseModifier=15 WHERE Type='BUILDING_PARADISE_HOPE';",
        "UPDATE Buildings SET GlobalCultureRateModifier=10,GlobalGreatPeopleRateModifier=10,UnmoddedHappiness=2 WHERE Type='BUILDING_PARADISE_FULFILLED';",
        "INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_PARADISE_PRESENCE','YIELD_CULTURE',2),('BUILDING_PARADISE_PRESENCE','YIELD_GOLDEN_AGE_POINTS',2),('BUILDING_PARADISE_CAPITAL','YIELD_CULTURE',1),('BUILDING_PARADISE_MEMORIAL','YIELD_CULTURE',2),('BUILDING_PARADISE_MEMORIAL','YIELD_TOURISM',4);",
        "INSERT INTO Building_YieldModifiers(BuildingType,YieldType,Yield) VALUES ('BUILDING_PARADISE_HOPE','YIELD_PRODUCTION',20),('BUILDING_PARADISE_PRESSURE_5','YIELD_CULTURE',-5),('BUILDING_PARADISE_PRESSURE_5','YIELD_PRODUCTION',-5),('BUILDING_PARADISE_PRESSURE_10','YIELD_CULTURE',-10),('BUILDING_PARADISE_PRESSURE_10','YIELD_PRODUCTION',-10);",
        "INSERT INTO Leader_Flavors(LeaderType,FlavorType,Flavor) SELECT 'LEADER_PARADISE_MESSI',Type,CASE Type WHEN 'FLAVOR_CULTURE' THEN 9 WHEN 'FLAVOR_GREAT_PEOPLE' THEN 10 WHEN 'FLAVOR_DIPLOMACY' THEN 8 WHEN 'FLAVOR_SCIENCE' THEN 7 ELSE 5 END FROM Flavors;",
        "INSERT INTO Leader_MajorCivApproachBiases SELECT 'LEADER_PARADISE_MESSI',MajorCivApproachType,Bias FROM Leader_MajorCivApproachBiases WHERE LeaderType='LEADER_WASHINGTON';",
        "INSERT INTO Leader_MinorCivApproachBiases SELECT 'LEADER_PARADISE_MESSI',MinorCivApproachType,Bias FROM Leader_MinorCivApproachBiases WHERE LeaderType='LEADER_WASHINGTON';"])
    names=['Buenos Aires','Rosario','Cordoba','Mendoza','La Plata','Mar del Plata','San Miguel de Tucuman','Salta','Santa Fe','San Juan','Neuquen','Bahia Blanca','San Luis','Posadas','Ushuaia']
    for n,name in enumerate(names):effects.append(f"INSERT INTO Civilization_CityNames VALUES ('CIVILIZATION_BOY_TOUCHED_PARADISE','TXT_KEY_PARADISE_CITY_{n}');")
    effects.append("INSERT INTO Diplomacy_Responses SELECT 'LEADER_PARADISE_MESSI',ResponseType,Response,Bias FROM Diplomacy_Responses WHERE LeaderType='LEADER_WASHINGTON';")
    for response,key in [('FIRST_GREETING','GREETING'),('DEFEATED','DEFEAT')]:
        effects.extend([f"DELETE FROM Diplomacy_Responses WHERE LeaderType='LEADER_PARADISE_MESSI' AND ResponseType='RESPONSE_{response}';",
            f"INSERT INTO Diplomacy_Responses VALUES ('LEADER_PARADISE_MESSI','RESPONSE_{response}','TXT_KEY_PARADISE_{key}',1);"])
    effects.append("INSERT INTO Civilization_SpyNames SELECT 'CIVILIZATION_BOY_TOUCHED_PARADISE',SpyName FROM Civilization_SpyNames WHERE CivilizationType='CIVILIZATION_AMERICA';")
    (DEST/'02_Paradise_Effects.sql').write_text('\n'.join(effects)+'\n',encoding='utf-8')
    texts={
        'CIV':'Argentina - The Boy Who Touched Paradise','SHORT':'The Boy Who Touched Paradise','ADJECTIVE':'Argentine',
        'LEADER':'Lionel Messi','LEADER_PEDIA':'A footballing genius from Rosario whose gifts were apparent long before international fulfillment. This civilization explores brilliance, expectation and redemption as a separate three-act journey.',
        'PEDIA':'A child, a ball, and a street in Rosario. From these small beginnings came a gift that moved people far beyond football. Greatness endured through joy and disappointment. The ultimate international prize completed a dream; it did not create the genius.',
        'STRATEGY':'Develop Great People and El Potrero early. Save or spend Dreams on once-per-era magic. In the Renaissance, ease national pressure through real achievements. Recover from the Industrial crisis, reach the Modern Era, earn 40 lifetime Dreams and complete three alternative objectives to build The Last Dance. Culture and Diplomacy are natural choices; every normal victory remains open.',
        'UA':'He Was Always the Point of Difference','UA_HELP':'+5% Great Person generation throughout the game; +1 Culture in the capital. Earn Dreams from genuine Great Person births (2), World Wonders (4), the first Golden Age (3), first new City-State alliance (2), and first constructed El Potrero (1) each era. Golden Age and alliance rewards are capped per era; each City-State rewards only its first alliance ever. Complete recovery for 5 Dreams. El Diez performs one 6-Dream Moment of Magic per era. National Pressure begins in the Renaissance; pursue The Last Dance in the Modern Era.',
        'EL_DIEZ':'El Diez','EL_DIEZ_HELP':'One unique noncombat hero, created in your first capital. 2 Movement, no maintenance, no production, purchases or expend actions. In an owned city: +2 Culture, +2 Golden Age Points each owner turn and +10% Great Person generation. Returns after five scaled owner turns if lost; no loss rewards. Use The Journey to perform Moments of Magic.',
        'EL_DIEZ_PEDIA':'The number ten sees a possibility in an ordinary patch of ground. His gift inspires the people around him during every act of the journey.',
        'EL_DIEZ_STRATEGY':'Station El Diez in a city developing Great People, or move him to the city that needs a Moment of Magic. During recovery, inspire an El Potrero city for eight scaled owner turns as a reliable alternative objective.',
        'POTRERO':'El Potrero','POTRERO_HELP':'Replaces the active Amphitheater, preserving its costs, prerequisites, slots and companion effects. Adds +1 Culture and +10% Great Person generation. Your first Production-completed El Potrero each era earns 1 Dream. Purchases and free buildings do not earn Dreams.',
        'POTRERO_PEDIA':'A humble local football ground, where invention matters more than perfection and a child learns to love the game.',
        'POTRERO_STRATEGY':'Supports Culture and Great People in every age, and provides a dependable home for the recovery objective.',
        'LAST_DANCE':'The Last Dance','LAST_DANCE_HELP':'Unique National Wonder: 450 base Production at Radio (Modern Era). Requires 40 lifetime Dreams and three distinct Journey objectives. Current Dreams are not consumed. Completes The Final Peak once: 15 scaled Golden Age turns, zero Pressure forever, +2 global Happiness, +10% global Culture and Great Person generation, three scaled celebration turns in all current cities, and a capital memorial with +2 Culture/+4 Tourism. Does not grant victory.',
        'LAST_DANCE_PEDIA':'One final opportunity to turn a lifelong dream into something real. The nation has already witnessed greatness; now it hopes to witness fulfillment.',
        'LAST_DANCE_STRATEGY':'Review the Final Peak tab for eligibility. Its persistent, alternative objectives recognize your whole game, including Dreams already spent on magic.',
        'MEMORIAL':'The Eternal Number Ten','MEMORIAL_HELP':'+2 Culture and +4 Tourism. A unique capital memorial granted at the Final Peak; follows the capital without duplication.',
        'CAPITAL':'The First Promise','PRESENCE':'Inspirational Presence','PRESSURE_5':'The Weight of Expectation','PRESSURE_10':'A Nation Waiting','HOPE':'When All Hope Was Lost','FULFILLED':'The Dream Fulfilled',
        'TITLE':'THE JOURNEY','OVERVIEW':'Overview','MEMORIES':'Memories','MAGIC':'Moments of Magic','PEAK':'Final Peak',
        'PASS':'A Pass Nobody Saw','BEAUTY':'The Beautiful Game','BURDEN_TITLE':'THE WEIGHT OF EXPECTATION',
        'BURDEN_STORY':'The gift is as bright as ever. The streets that once watched in wonder now speak of what it must accomplish. You carry their hope with you. Let real progress make that burden lighter.',
        'DENIED_TITLE':'A DREAM DENIED','DENIED_STORY':'The nation felt the dream within reach, and now its uncertain ending is harder to bear. The beauty has not vanished. Give the people a reason to believe again: begin a Golden Age, generate a Great Person, build a World Wonder, form a first alliance, or inspire an El Potrero city for eight scaled owner turns. You have twenty-five scaled owner turns. If this chance passes, another will open.',
        'RECOVERY_TITLE':'WE RISE AGAIN','RECOVERY_STORY':'A difficult ending did not become the end of the story. Patient work has made a new beginning possible. The nation remembers the hurt, and also remembers how you answered it.',
        'FINAL_TITLE':'HE HAS SHAKEN HANDS WITH PARADISE',
        'FINAL_STORY':'A child once followed a ball through the streets of Rosario. His gift brought wonder long before this night. He carried hope through joyful days and quiet disappointments, and kept creating beauty when certainty disappeared.[NEWLINE][NEWLINE]Now the dream has a shape the whole nation can hold. The trophy completes the wish; it does not explain the genius.[NEWLINE][NEWLINE]The dream is complete. The beauty remains.',
        'DAWN':'In Rosario, a little boy follows a ball until the street becomes his whole world. Before there are trophies, there is delight: a turn, an unexpected pass, a possibility only he can see. As the gift grows, so does the hope placed upon it. There will be days when brilliance feels effortless, and days when the one dream he wants seems impossibly far away. Yet the love of the game will endure. Lionel Messi, guide Argentina through its own story, and discover how far a beautiful beginning can lead.',
        'GREETING':'Welcome. There is always another possibility, if we give ourselves time to see it.',
        'DEFEAT':'We could not finish the dream. But I will remember the beautiful things we made along the way.'}
    for n,name in enumerate(names):texts['CITY_'+str(n)]=name
    # Civilopedia heading keys are real localization entries, too.
    texts['CIVILOPEDIA_LEADERS_PARADISE']='Lionel Messi';texts['CIV5_PARADISE']='The Boy Who Touched Paradise'
    rows=[('TXT_KEY_'+k if k.startswith(('CIVILOPEDIA_','CIV5_')) else 'TXT_KEY_PARADISE_'+k,v) for k,v in texts.items()]
    (DEST/'10_Paradise_Text.sql').write_text('INSERT INTO Language_en_US(Tag,Text) VALUES\n'+',\n'.join('('+q(k)+','+q(v)+')' for k,v in rows)+';\n',encoding='utf-8')
    db.close()
    print('Generated Paradise core, complete CP companion inheritance, native effects and original text.')

if __name__=='__main__':generate()
