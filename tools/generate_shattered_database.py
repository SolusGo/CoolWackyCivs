"""Generate explicit BNW/CP inheritance and definitions from a read-only cache clone."""
from pathlib import Path
import sqlite3
import sys

R = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(R / '.tools/python'), str(R / 'tools')]
from validate_mod import apply_current_cp_schema, quote

V = R / 'TheShatteredEmpire/SQL'


def literal(value):
    return "'" + value.replace("'", "''") + "'" if isinstance(value, str) else str(value)


def insert(table, fields):
    return f"INSERT INTO {table}({','.join(fields)}) VALUES ({','.join(map(literal, fields.values()))});"


def main():
    user = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    source = sqlite3.connect((user / 'cache_backup/Civ5DebugDatabase.db').as_uri() + '?mode=ro', uri=True)
    db = sqlite3.connect(':memory:'); source.backup(db); source.close()
    apply_current_cp_schema(db, user / 'MODS/(1) Community Patch')
    V.mkdir(parents=True, exist_ok=True)
    core = ["-- The Shattered Empire: BNW with Community Patch v151. No custom DLL.",
            "UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_CITY','EVENTS_CITY_FOUNDING','EVENTS_PLAYER_TURN','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_PREKILL','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_ENDED');",
            "INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_IMPERIAL_CRIMSON',0.32,0.02,0.035,1),('COLOR_IMPERIAL_GOLD',0.94,0.73,0.28,1);",
            "INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_SHATTERED_EMPIRE','COLOR_IMPERIAL_CRIMSON','COLOR_IMPERIAL_GOLD','COLOR_PLAYER_WHITE_TEXT');",
            "INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_WEIGHT_OF_EMPIRE','TXT_KEY_IMPERIAL_TRAIT_HELP','TXT_KEY_IMPERIAL_TRAIT');"]

    def clone(table, base, fields):
        core.extend([f"CREATE TEMP TABLE ImperialClone AS SELECT * FROM {table} WHERE Type='{base}';",
                     'UPDATE ImperialClone SET ' + ','.join(k + '=' + ('NULL' if v is None else literal(v)) for k, v in fields.items()) + ';',
                     f'INSERT INTO {table} SELECT * FROM ImperialClone;', 'DROP TABLE ImperialClone;'])

    clone('Leaders', 'LEADER_AUGUSTUS', dict(ID=None, Type='LEADER_LAST_EMPEROR', Description='TXT_KEY_IMPERIAL_LEADER', Civilopedia='TXT_KEY_IMPERIAL_LEADER_PEDIA', CivilopediaTag='TXT_KEY_CIVILOPEDIA_LEADERS_IMPERIAL', ArtDefineTag='ImperialLeaderScene.xml', PortraitIndex=1, IconAtlas='IMPERIAL_OBJECT_ATLAS', PackageID=None, VictoryCompetitiveness=7, Boldness=7, DiploBalance=6, Loyalty=7, Forgiveness=4))
    core += ["INSERT INTO Leader_Traits VALUES ('LEADER_LAST_EMPEROR','TRAIT_WEIGHT_OF_EMPIRE');",
             "INSERT INTO Leader_Flavors SELECT 'LEADER_LAST_EMPEROR',FlavorType,Flavor FROM Leader_Flavors WHERE LeaderType='LEADER_AUGUSTUS';"]
    clone('Civilizations', 'CIVILIZATION_ROME', dict(ID=None, Type='CIVILIZATION_SHATTERED_EMPIRE', Description='TXT_KEY_IMPERIAL_CIV', ShortDescription='TXT_KEY_IMPERIAL_SHORT', Adjective='TXT_KEY_IMPERIAL_ADJECTIVE', Civilopedia='TXT_KEY_IMPERIAL_CIV_PEDIA', CivilopediaTag='TXT_KEY_CIV5_IMPERIAL', Strategy='TXT_KEY_IMPERIAL_STRATEGY', DefaultPlayerColor='PLAYERCOLOR_SHATTERED_EMPIRE', Playable=1, AIPlayable=0, PackageID=None, PortraitIndex=0, IconAtlas='IMPERIAL_OBJECT_ATLAS', AlphaIconAtlas='IMPERIAL_ALPHA_ATLAS', MapImage='ImperialMap.dds', DawnOfManImage='ImperialDawn.dds', DawnOfManAudio='', DawnOfManQuote='TXT_KEY_IMPERIAL_DAWN'))
    core += ["INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_SHATTERED_EMPIRE','LEADER_LAST_EMPEROR');"]
    for table, fields in [('Civilization_FreeBuildingClasses', 'BuildingClassType'), ('Civilization_FreeTechs', 'TechType'), ('Civilization_FreeUnits', 'UnitClassType,UnitAIType,Count')]:
        core += [f"INSERT INTO {table}(CivilizationType,{fields}) SELECT 'CIVILIZATION_SHATTERED_EMPIRE',{fields} FROM {table} WHERE CivilizationType='CIVILIZATION_ROME';"]
    clone('Units', 'UNIT_WARRIOR', dict(ID=None, Type='UNIT_IMPERIAL_LEGION', Description='TXT_KEY_IMPERIAL_LEGION', Civilopedia='TXT_KEY_IMPERIAL_LEGION_PEDIA', Strategy='TXT_KEY_IMPERIAL_LEGION_STRATEGY', Help='TXT_KEY_IMPERIAL_LEGION_HELP', Combat=10, PortraitIndex=2, IconAtlas='IMPERIAL_OBJECT_ATLAS', UnitFlagAtlas='IMPERIAL_UNIT_FLAG_ATLAS', UnitFlagIconOffset=0))
    core += ["UPDATE Units SET Cost=CAST((Cost*115+99)/100 AS INTEGER) WHERE Type='UNIT_IMPERIAL_LEGION';",
             "INSERT INTO Civilization_UnitClassOverrides VALUES ('CIVILIZATION_SHATTERED_EMPIRE','UNITCLASS_WARRIOR','UNIT_IMPERIAL_LEGION');"]
    clone('Buildings', 'BUILDING_MONUMENT', dict(ID=None, Type='BUILDING_IMPERIAL_PALACE', Description='TXT_KEY_IMPERIAL_PALACE', Civilopedia='TXT_KEY_IMPERIAL_PALACE_PEDIA', Strategy='TXT_KEY_IMPERIAL_PALACE_STRATEGY', Help='TXT_KEY_IMPERIAL_PALACE_HELP', PortraitIndex=3, IconAtlas='IMPERIAL_OBJECT_ATLAS'))
    core += ["INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_SHATTERED_EMPIRE','BUILDINGCLASS_MONUMENT','BUILDING_IMPERIAL_PALACE');"]
    (V / '00_Imperial_Core.sql').write_text('\n'.join(core) + '\n', encoding='utf-8')
    inheritance = ['-- Copy every registered companion table, exactly once, from the active ruleset.']
    for prefix, column, base, new in [('Unit_', 'UnitType', 'UNIT_WARRIOR', 'UNIT_IMPERIAL_LEGION'), ('Building_', 'BuildingType', 'BUILDING_MONUMENT', 'BUILDING_IMPERIAL_PALACE')]:
        for (name,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").fetchall():
            columns = [r[1] for r in db.execute('PRAGMA table_info(' + quote(name) + ')')]
            if not name.startswith(prefix) or column not in columns: continue
            inheritance += [f"CREATE TEMP TABLE ImperialCompanion AS SELECT * FROM {quote(name)} WHERE {column}='{base}';",
                            f"UPDATE ImperialCompanion SET {column}='{new}';", f'INSERT INTO {quote(name)} SELECT * FROM ImperialCompanion;', 'DROP TABLE ImperialCompanion;']
    inheritance += ["UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='BUILDING_IMPERIAL_PALACE' AND YieldType='YIELD_GOLD';",
                    "INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_IMPERIAL_PALACE','YIELD_GOLD',1 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_IMPERIAL_PALACE' AND YieldType='YIELD_GOLD');"]
    (V / '01_Imperial_Inheritance.sql').write_text('\n'.join(inheritance) + '\n', encoding='utf-8')
    effects = []

    def dummy(name, modifiers=None, **extra):
        kind = 'BUILDING_IMPERIAL_' + name
        effects.append(insert('BuildingClasses', dict(Type='BUILDINGCLASS_IMPERIAL_' + name, DefaultBuilding=kind, Description='TXT_KEY_IMPERIAL_DUMMY')))
        effects.append(insert('Buildings', dict(Type=kind, BuildingClass='BUILDINGCLASS_IMPERIAL_' + name, Description='TXT_KEY_IMPERIAL_DUMMY', Cost=-1, FaithCost=-1, GreatWorkCount=-1, NeverCapture=1, NukeImmune=1, ConquestProb=0, IsDummy=1, ShowInPedia=0, **extra)))
        for y, amount in (modifiers or {}).items(): effects.append(insert('Building_YieldModifiers', dict(BuildingType=kind, YieldType='YIELD_' + y, Yield=amount)))

    dummy('LOYALIST', {'GOLD': 5}); dummy('MILITARIST', MilitaryProductionModifier=10)
    dummy('MERCHANT', {'GOLD': 10}); dummy('POPULIST', {'FOOD': 10}, Happiness=1)
    dummy('AMBITIOUS', {'PRODUCTION': 10})
    dummy('DISCONTENT', {'GOLD': -10}); dummy('DEFIANCE', {'GOLD': -20, 'PRODUCTION': -10}, UnmoddedHappiness=-1)
    dummy('REVOLT', {'GOLD': -35, 'PRODUCTION': -30, 'FOOD': -15, 'CULTURE': -20}, UnmoddedHappiness=-2)
    dummy('FEDERATION', {'PRODUCTION': -10}); dummy('MONARCHY', MilitaryProductionModifier=10)
    dummy('COUNCIL', {'PRODUCTION': -10}); dummy('RESTORATION', {'PRODUCTION': 10, 'CULTURE': 10})
    dummy('ADMINISTRATION', GoldMaintenance=1)
    columns = {r[1] for r in db.execute('PRAGMA table_info(UnitPromotions)')}
    barbarian = next(c for c in ['BarbarianCombatBonus', 'BarbCombatBonus', 'BarbarianCombatModifier'] if c in columns)
    for name, extra in [('DISCIPLINE', {}), ('DISCIPLINE_ACTIVE', {'FriendlyLandsModifier': 15}), ('REBEL_COMBAT', {barbarian: 10})]:
        effects.append(insert('UnitPromotions', dict(Type='PROMOTION_IMPERIAL_' + name, Description='TXT_KEY_IMPERIAL_PROMO_' + name, Help='TXT_KEY_IMPERIAL_PROMO_HELP_' + name, CannotBeChosen=1, LostWithUpgrade=0 if name=='DISCIPLINE' else 1, LostOnGifting=1, PortraitIndex=2, IconAtlas='IMPERIAL_OBJECT_ATLAS', PediaType='PEDIA_ATTRIBUTES', PediaEntry='TXT_KEY_IMPERIAL_PROMO_' + name, **extra)))
    effects.append("INSERT INTO Unit_FreePromotions VALUES ('UNIT_IMPERIAL_LEGION','PROMOTION_IMPERIAL_DISCIPLINE');")
    for size in [16, 24, 32, 45, 48, 64, 80, 128, 256]:
        effects.append(f"INSERT INTO IconTextureAtlases VALUES ('IMPERIAL_OBJECT_ATLAS',{size},'ImperialObjects{size}.dds',2,2);")
        effects.append(f"INSERT INTO IconTextureAtlases VALUES ('IMPERIAL_ALPHA_ATLAS',{size},'ImperialAlpha{size}.dds',1,1);")
    effects.append("INSERT INTO IconTextureAtlases VALUES ('IMPERIAL_UNIT_FLAG_ATLAS',32,'ImperialUnitFlag32.dds',1,1);")
    (V / '02_Imperial_Effects.sql').write_text('\n'.join(effects) + '\n', encoding='utf-8')
    from shattered_localization import TEXT, DIALOGUE
    rows = dict(TEXT)
    for i, name in enumerate(['Aeternum','Valoria','Vespera','Aquila','Corvinum','Solaria','Marcellia','Dravena','Elyria','Carinum','Caelestis','Nova Aeternum','Vallum','Severia','Flavium','Portus Aureus','Vindex','Altoria','Valentia','Lucania','Magnara','Neravum','Tiberia','Justinia']): rows['CITY_' + str(i)] = name
    for name, text in DIALOGUE.items(): rows['DIPLO_' + name] = text
    statements = [insert('Language_en_US', {'Tag': 'TXT_KEY_IMPERIAL_' + k, 'Text': v}) for k, v in rows.items()]
    for i in range(24): statements.append(f"INSERT INTO Civilization_CityNames VALUES ('CIVILIZATION_SHATTERED_EMPIRE','TXT_KEY_IMPERIAL_CITY_{i}');")
    statements += [insert('Language_en_US', {'Tag': 'TXT_KEY_CIVILOPEDIA_LEADERS_IMPERIAL_HEADING_1', 'Text': 'The Last Emperor'}), insert('Language_en_US', {'Tag': 'TXT_KEY_CIVILOPEDIA_LEADERS_IMPERIAL_TEXT_1', 'Text': TEXT['LEADER_PEDIA']})]
    statements += ["INSERT INTO Diplomacy_Responses SELECT 'LEADER_LAST_EMPEROR',ResponseType,Response,Bias FROM Diplomacy_Responses WHERE LeaderType='LEADER_AUGUSTUS';"]
    for response in DIALOGUE:
        statements += [f"DELETE FROM Diplomacy_Responses WHERE LeaderType='LEADER_LAST_EMPEROR' AND ResponseType='RESPONSE_{response}';", f"INSERT INTO Diplomacy_Responses VALUES ('LEADER_LAST_EMPEROR','RESPONSE_{response}','TXT_KEY_IMPERIAL_DIPLO_{response}',1);"]
    (V / '10_Imperial_Text.sql').write_text('\n'.join(statements) + '\n', encoding='utf-8')
    print('Generated Shattered Empire database, inheritance, effects and English localization')


if __name__ == '__main__': main()
