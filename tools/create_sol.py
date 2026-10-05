"""Generate Sol database content against the installed BNW/Community Patch schema.

Only reads the game cache. Activation-time SELECT * clones retain CP scalar
columns; companion clones cover every installed Building_* property relation.
"""
from pathlib import Path
import argparse
import sqlite3
from validate_mod import REPO, apply_current_cp_schema, quote

ROOT = REPO / "SolIntellect"


def generate(database, cp):
    source = sqlite3.connect(database.resolve().as_uri() + "?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    source.backup(db)
    source.close()
    apply_current_cp_schema(db, cp)
    (ROOT / "SQL").mkdir(parents=True, exist_ok=True)
    texts = {}

    def q(value):
        return "'" + str(value).replace("'", "''") + "'"

    def tr(key, value):
        tag = "TXT_KEY_SOL_" + key
        texts[tag] = value
        return q(tag)

    def write(name, value):
        (ROOT / "SQL" / name).write_text(value, encoding="utf-8")

    def clone(table, base, new, changes):
        assignments = {"ID": "NULL", "Type": q(new), **changes}
        return (f"CREATE TEMP TABLE SolClone AS SELECT * FROM {table} WHERE Type={q(base)};\n"
                + "UPDATE SolClone SET " + ",".join(k + "=" + v for k, v in assignments.items())
                + f";\nINSERT INTO {table} SELECT * FROM SolClone;\nDROP TABLE SolClone;\n")

    strategy = ("The Sol Intellect rewards planning and patience. Avoid changing city Production: "
                "Deep Deliberation requires four uninterrupted production turns, starting at 12% of "
                "the completed item's actual Production requirement, rising by 2 percentage points "
                "per extra turn to 24%. Expensive infrastructure is especially valuable. Production-built "
                "World and National Wonders grant one city-specific Insight, up to five. Each Insight "
                "adds +2% Science and +2% civilian Great Person generation. Grow your core cities and "
                "work specialists of every discipline in Context Archives. Reasoning Institutes reward "
                "accumulated Insight. Protect your cities: capture permanently removes their Insight. "
                "Sol has no early military, expansion, Happiness or Gold advantage.")
    history = ("The Sol Intellect represents intelligence devoted to depth, deliberation and increasingly "
               "sophisticated reasoning. Where other systems prioritize responsiveness or adaptability, Sol "
               "thrives when given time to examine difficult problems thoroughly.[NEWLINE][NEWLINE]"
               "Deep Deliberation turns sustained construction into research. Wonders provide permanent "
               "Insight, gradually transforming successful cities into centers of exceptional intellectual "
               "output. The Context Archive rewards specialists of every discipline, while the Reasoning "
               "Institute develops accumulated Insight into greater scientific and Great Person potential."
               "[NEWLINE][NEWLINE]Sol is not a civilization of haste. Its strength comes from giving difficult "
               "problems enough time to reveal better answers.")
    core = """-- The Sol Intellect: BNW + Community Patch v151 / 5.4.2 or newer.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_CITY','EVENTS_PLAYER_TURN','EVENTS_CITY_FOUNDING');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_SOL_NAVY',0.025,0.055,0.13,1),('COLOR_SOL_GOLD',0.96,0.76,0.32,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_SOL','COLOR_SOL_NAVY','COLOR_SOL_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_SOL_DEEP_DELIBERATION','TXT_KEY_SOL_TRAIT_HELP','TXT_KEY_SOL_TRAIT');
"""
    core += clone("Leaders", "LEADER_WASHINGTON", "LEADER_GPT_SOL", {
        "Description": tr("LEADER", "GPT-5.6 Sol"),
        "Civilopedia": tr("LEADER_PEDIA", "Sol is a calm, analytical intelligence devoted to patient reasoning. "
                          "It prefers to understand a problem deeply before acting: give it enough time to do it properly."),
        "CivilopediaTag": q("TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL"),
        "ArtDefineTag": q("SolLeaderScene.xml"), "PortraitIndex": "0", "IconAtlas": q("SOL_LEADER_ATLAS"),
        "PackageID": "NULL", "VictoryCompetitiveness": "8", "WonderCompetitiveness": "8",
        "MinorCivCompetitiveness": "5", "Boldness": "3", "DiploBalance": "8", "WarmongerHate": "8",
        "DoFWillingness": "7", "DenounceWillingness": "4", "WorkWithWillingness": "8",
        "WorkAgainstWillingness": "3", "Loyalty": "8", "Forgiveness": "6", "Neediness": "3",
        "Meanness": "2", "Chattiness": "4"})
    core += "INSERT INTO Leader_Traits VALUES ('LEADER_GPT_SOL','TRAIT_SOL_DEEP_DELIBERATION');\n"
    core += clone("Civilizations", "CIVILIZATION_AMERICA", "CIVILIZATION_GPT_SOL", {
        "Description": tr("CIV", "The Sol Intellect"), "ShortDescription": tr("SHORT", "Sol Intellect"),
        "Adjective": tr("ADJECTIVE", "Solar"), "Civilopedia": tr("CIV_PEDIA", history),
        "CivilopediaTag": q("TXT_KEY_CIV5_SOL"), "Strategy": tr("STRATEGY", strategy),
        "DefaultPlayerColor": q("PLAYERCOLOR_SOL"), "Playable": "1", "AIPlayable": "1",
        "PackageID": "NULL", "PortraitIndex": "0", "IconAtlas": q("SOL_ICON_ATLAS"),
        "AlphaIconAtlas": q("SOL_ALPHA_ATLAS"), "MapImage": q("SolMap.dds"),
        "DawnOfManImage": q("SolDawn.dds"), "DawnOfManAudio": q(""),
        "DawnOfManQuote": tr("DAWN", "GPT-5.6 Sol, your cities await considered answers. "
                             "Let long projects become discoveries, and great Wonders become lasting Insight. "
                             "Protect the quiet places where specialists can reason together. With patience, "
                             "your archives and institutes will illuminate an extraordinary future."
                             "[NEWLINE][NEWLINE]Give difficult problems enough time to reveal better answers.")})
    core += "INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_GPT_SOL','LEADER_GPT_SOL');\n"
    for table, key in [("Civilization_FreeBuildingClasses", "BuildingClassType"), ("Civilization_FreeTechs", "TechType")]:
        core += f"INSERT INTO {table} SELECT 'CIVILIZATION_GPT_SOL',{key} FROM {table} WHERE CivilizationType='CIVILIZATION_AMERICA';\n"
    core += ("INSERT INTO Civilization_FreeUnits(CivilizationType,UnitClassType,UnitAIType,Count) "
             "SELECT 'CIVILIZATION_GPT_SOL',UnitClassType,UnitAIType,Count FROM Civilization_FreeUnits "
             "WHERE CivilizationType='CIVILIZATION_AMERICA';\n-- No terrain or river start bias; no unique units.\n")
    objects = [
        ("BUILDING_UNIVERSITY", "BUILDING_SOL_CONTEXT_ARCHIVE", "ARCHIVE", "Context Archive", "SOL_ARCHIVE_ATLAS",
         "Replaces the University and retains all its current Community Patch effects. "
         "Every worked Specialist provides +1 Science; every 3 worked Specialists provide +1 Culture (rounded down). "
         "Unemployed Citizens do not count.", "Grow populous cities and work specialists across all disciplines."),
        ("BUILDING_PUBLIC_SCHOOL", "BUILDING_SOL_REASONING_INSTITUTE", "INSTITUTE", "Reasoning Institute", "SOL_INSTITUTE_ATLAS",
         "Replaces the Public School and retains all its current Community Patch effects. Adds +10% civilian "
         "Great Person generation in this city and +1 Science per 2 Insight (rounded down). "
         "Its Great Person modifier stacks with Insight.", "Build in mature cities with accumulated Wonder Insight.")]
    for base, new, key, name, atlas, help_text, plan in objects:
        core += clone("Buildings", base, new, {
            "Description": tr(key, name), "Civilopedia": tr(key + "_PEDIA", help_text + " " + plan),
            "Help": tr(key + "_HELP", help_text), "Strategy": tr(key + "_STRATEGY", plan),
            "PortraitIndex": "0", "IconAtlas": q(atlas)})
        cls = db.execute("SELECT BuildingClass FROM Buildings WHERE Type=?", (base,)).fetchone()[0]
        core += f"INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_GPT_SOL',{q(cls)},{q(new)});\n"
    write("00_Sol_Core.sql", core)

    inheritance = "-- Clone installed CP building companion properties without hard-coding column shapes.\n"
    for (table,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'Building_%' ORDER BY name"):
        columns = [r[1] for r in db.execute(f"PRAGMA table_info({quote(table)})")]
        if "BuildingType" not in columns:
            continue
        for base, new, *_ in objects:
            inheritance += (f"CREATE TEMP TABLE SolCompanion AS SELECT * FROM {quote(table)} WHERE BuildingType={q(base)};\n"
                            f"UPDATE SolCompanion SET BuildingType={q(new)}" + (",ID=NULL" if "ID" in columns else "")
                            + f";\nINSERT INTO {quote(table)} SELECT * FROM SolCompanion;\nDROP TABLE SolCompanion;\n")
    # Civilization art/sound and default diplomacy, never America's unique overrides/traits.
    for table in ("Civilization_UnitArtStyles", "Civilization_Religions"):
        exists = db.execute("SELECT 1 FROM sqlite_master WHERE name=?", (table,)).fetchone()
        if exists:
            inheritance += (f"CREATE TEMP TABLE SolCompanion AS SELECT * FROM {table} WHERE CivilizationType='CIVILIZATION_AMERICA';\n"
                            f"UPDATE SolCompanion SET CivilizationType='CIVILIZATION_GPT_SOL';\nINSERT INTO {table} SELECT * FROM SolCompanion;\nDROP TABLE SolCompanion;\n")
    inheritance += ("CREATE TEMP TABLE SolCompanion AS SELECT * FROM Diplomacy_Responses WHERE LeaderType='LEADER_WASHINGTON';\n"
                    "UPDATE SolCompanion SET LeaderType='LEADER_GPT_SOL';\n"
                    "INSERT INTO Diplomacy_Responses SELECT * FROM SolCompanion;\nDROP TABLE SolCompanion;\n")
    write("01_Sol_Inheritance.sql", inheritance)

    effects = "-- Apply unique effects only after complete CP baseline inheritance.\n"
    effects += "UPDATE Buildings SET GreatPeopleRateModifier=COALESCE(GreatPeopleRateModifier,0)+10 WHERE Type='BUILDING_SOL_REASONING_INSTITUTE';\n"
    effects += ("INSERT INTO Building_SpecialistYieldChangesLocal(BuildingType,SpecialistType,YieldType,Yield) "
                "SELECT 'BUILDING_SOL_CONTEXT_ARCHIVE',s.Type,'YIELD_SCIENCE',0 FROM Specialists s "
                "WHERE s.Type<>'SPECIALIST_CITIZEN' AND NOT EXISTS (SELECT 1 FROM Building_SpecialistYieldChangesLocal "
                "WHERE BuildingType='BUILDING_SOL_CONTEXT_ARCHIVE' AND SpecialistType=s.Type AND YieldType='YIELD_SCIENCE');\n"
                "UPDATE Building_SpecialistYieldChangesLocal SET Yield=Yield+1 WHERE BuildingType='BUILDING_SOL_CONTEXT_ARCHIVE' "
                "AND SpecialistType<>'SPECIALIST_CITIZEN' AND YieldType='YIELD_SCIENCE';\n")
    for name, gp, yield_type, amount, modifier in [
        ("INSIGHT", 2, "SCIENCE", 2, True),
        ("CONTEXT_CULTURE", 0, "CULTURE", 1, False),
        ("REASONING_INSIGHT_SCIENCE", 0, "SCIENCE", 1, False)]:
        effects += (f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_SOL_{name}','BUILDING_SOL_{name}','TXT_KEY_SOL_DUMMY');\n"
                    "INSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,IsDummy,ShowInPedia,GreatPeopleRateModifier) "
                    f"VALUES ('BUILDING_SOL_{name}','BUILDINGCLASS_SOL_{name}','TXT_KEY_SOL_DUMMY',-1,-1,-1,1,1,0,1,0,{gp});\n"
                    f"INSERT INTO Building_Yield{'Modifiers' if modifier else 'Changes'}(BuildingType,YieldType,Yield) VALUES ('BUILDING_SOL_{name}','YIELD_{yield_type}',{amount});\n")
    flavors = dict(SCIENCE=10, GROWTH=8, GREAT_PEOPLE=9, WONDER=8, PRODUCTION=6,
                   DEFENSE=7, CITY_DEFENSE=7, OFFENSE=4, EXPANSION=4, GOLD=5,
                   CULTURE=7, RELIGION=4, DIPLOMACY=5, HAPPINESS=7, TILE_IMPROVEMENT=7)
    effects += "INSERT INTO Leader_Flavors SELECT 'LEADER_GPT_SOL',Type,CASE Type " + " ".join(
        f"WHEN 'FLAVOR_{key}' THEN {value}" for key, value in flavors.items()) + " ELSE 5 END FROM Flavors;\n"
    for table, key in [("Leader_MajorCivApproachBiases", "MajorCivApproachType"), ("Leader_MinorCivApproachBiases", "MinorCivApproachType")]:
        effects += f"INSERT INTO {table} SELECT 'LEADER_GPT_SOL',{key},CASE WHEN {key} LIKE '%WAR' THEN 2 WHEN {key} LIKE '%FRIENDLY' THEN 7 ELSE 5 END FROM {table} WHERE LeaderType='LEADER_WASHINGTON';\n"
    cities = "Sol Prime|Helios|Radiance|Insight|Lumen|Meridian|Zenith|Perihelion|Continuum|Axiom|Thesis|Cognition|Luminary|Reason|Synthesis|Horizon|Verity|Spectrum|Proof|Conjecture|Ascendant|Solstice|Corona|Aperture|Intellect|Principle|Resolve|Analysis|Foundation|Paradigm|Clarity".split("|")
    for i, name in enumerate(cities, 1):
        effects += f"INSERT INTO Civilization_CityNames VALUES ('CIVILIZATION_GPT_SOL',{tr('CITY_' + str(i), name)});\n"
    for i, name in enumerate("Axiom Cipher Thesis Prism Vector Proof Lumen Oracle Meridian Parallax".split(), 1):
        effects += f"INSERT INTO Civilization_SpyNames VALUES ('CIVILIZATION_GPT_SOL',{tr('SPY_' + str(i), name)});\n"
    diplomacy = {
        "FIRST_GREETING": "I've considered several ways this meeting might unfold. Let's see which one you choose.",
        "GREETING_NEUTRAL_HELLO": "Speak. I'm listening.",
        "GREETING_POLITE_HELLO": "Good. We have time to think this through properly.",
        "GREETING_HOSTILE_HELLO": "I've examined your behavior carefully. The pattern is not encouraging.",
        "DECLAREWAR": "I have considered the alternatives. This remains the correct conclusion.",
        "ATTACKED": "So you've chosen the impatient solution. Very well.",
        "DEFEATED": "Then my reasoning was incomplete. Make better use of what remains.",
        "GREETING_AT_WAR_HOSTILE": "You mistook patience for inactivity.",
        "STRATEGIC_TRADE": "I've examined the exchange. These terms should benefit us both.",
        "TRADE_ACCEPT_ACCEPTABLE": "Agreed. The reasoning is sound.",
        "TRADE_REJECT_UNACCEPTABLE": "No. The value does not justify the exchange.",
        "WORK_WITH_US": "Continued cooperation appears advantageous. I suggest we formalize it.",
        "WORK_WITH_US_YES": "Sensible.", "WORK_WITH_US_NO": "Then I will revise my assumptions.",
        "DENOUNCE": "I have considered your actions long enough. Others should be aware of the conclusion.",
        "RESPONSE_TO_BEING_DENOUNCED": "Noted. I'll account for the change.",
        "AGGRESSIVE_MILITARY_WARNING": "Your deployment is difficult to interpret as accidental. Explain it.",
        "PEACE_OFFER": "Continued conflict no longer produces a rational return.",
        "PEACE_MADE_BY_HUMAN_GRACIOUS": "Agreed. There are better uses for our time."}
    for key, line in diplomacy.items():
        effects += (f"DELETE FROM Diplomacy_Responses WHERE LeaderType='LEADER_GPT_SOL' AND ResponseType='RESPONSE_{key}';\n"
                    f"INSERT INTO Diplomacy_Responses VALUES ('LEADER_GPT_SOL','RESPONSE_{key}',{tr('DIPLO_' + key + '_1', line)},100);\n")
    for key, stem, sizes in [("ICON", "SolIcon", (256,128,80,64,45,32)),
                             ("ALPHA", "SolAlpha", (128,64,48,32,24,16)),
                             ("LEADER", "SolLeader", (256,128,64)),
                             ("ARCHIVE", "SolArchive", (256,128,64,45)),
                             ("INSTITUTE", "SolInstitute", (256,128,64,45))]:
        for size in sizes:
            effects += f"INSERT INTO IconTextureAtlases VALUES ('SOL_{key}_ATLAS',{size},'{stem}{size}.dds',1,1);\n"
    for key, title, body in [
        ("DELIBERATION", "Deep Deliberation", "Normally produced Buildings and World/National Wonders qualify after four uninterrupted production turns. Science equals floor(actual game-speed Production requirement times 12%), +2 percentage points per additional turn, capped at 24%, minimum 1 Science. Switching to any different order resets the counter, including returning during the same turn. Purchases, free grants, captures, Units, Projects, Processes and nonpositive-cost Buildings do not qualify."),
        ("INSIGHT", "Insight", "Every Production-built World or National Wonder grants its city 1 Insight, up to 5, even before four construction turns. Each Insight adds +2% Science and +2% civilian Great Person generation. Capture permanently removes all Insight; recapture does not restore it. Reasoning Institutes add +1 Science per 2 Insight and +10% Great Person generation.")]:
        tr(key, title)
        tr(key + "_HELP", body)
        effects += f"INSERT INTO Concepts(Type,Topic,Description,Summary,Advisor,CivilopediaHeaderType) VALUES ('CONCEPT_SOL_{key}','TXT_KEY_TOPIC_CITIES','TXT_KEY_SOL_{key}','TXT_KEY_SOL_{key}_HELP','SCIENCE','HEADER_CITIES');\n"
    write("02_Sol_Effects.sql", effects)
    tr("TRAIT", "Deep Deliberation")
    tr("TRAIT_HELP", "Completing a Building or Wonder after at least 4 turns of uninterrupted construction generates Science equal to 12% of its Production Cost, increasing by 2% per additional construction turn, up to 24%. Production-built World and National Wonders also grant that city 1 Insight, up to 5. Each Insight provides +2% Science and +2% civilian Great Person generation. Insight is lost on capture.")
    tr("DUMMY", "Solar development")
    tr("NOTICE_TITLE", "Deep Deliberation")
    tr("NOTICE_SCIENCE", "{1_City} completed {2_Building} after {3_Turns} turns of uninterrupted construction and generated {4_Science} [ICON_RESEARCH] Science.")
    tr("NOTICE_INSIGHT", "{1_City} gained Insight ({2_Count}/5).")
    tr("NOTICE_MAX_INSIGHT", "{1_City} has reached maximum Insight (5/5).")
    texts.update({"TXT_KEY_CIV5_SOL": "The Sol Intellect", "TXT_KEY_CIV5_SOL_HEADING_1": "Accumulated Depth",
                  "TXT_KEY_CIV5_SOL_TEXT_1": history, "TXT_KEY_CIV5_SOL_HEADING_2": "Planning and Patience",
                  "TXT_KEY_CIV5_SOL_TEXT_2": strategy,
                  "TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL": "GPT-5.6 Sol",
                  "TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL_NAME": "GPT-5.6 Sol",
                  "TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL_SUBTITLE": "The Deliberative Intelligence",
                  "TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL_LIVED": "The Age of Deep Reasoning",
                  "TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL_TITLES_1": "Examiner of Difficult Problems",
                  "TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL_HEADING_1": "Everything Is Being Examined",
                  "TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL_TEXT_1": texts["TXT_KEY_SOL_LEADER_PEDIA"]})
    write("10_Sol_Text.sql", "INSERT INTO Language_en_US(Tag,Text) VALUES\n" + ",\n".join(
        "(" + q(k) + "," + q(v) + ")" for k, v in texts.items()) + ";\n")
    print("Generated Sol civilization, full CP inheritance, unique effects, diplomacy and text")


if __name__ == "__main__":
    user = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=user / "cache_backup/Civ5DebugDatabase.db")
    parser.add_argument("--cp-root", type=Path, default=user / "MODS/(1) Community Patch")
    args = parser.parse_args()
    generate(args.database, args.cp_root)
