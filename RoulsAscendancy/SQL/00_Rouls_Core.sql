-- The Rou'ls Ascendancy: Civilization V Brave New World + Community Patch.
-- All scalar columns are cloned at activation, including columns added by CP.
-- Companion rows are cloned in 01_Rouls_Inheritance.sql before unique additions.

UPDATE CustomModOptions SET Value = 1 WHERE Name IN
('EVENTS_CITY', 'EVENTS_CITY_CAPITAL', 'EVENTS_UNIT_PREKILL',
 'EVENTS_UNIT_CREATED', 'EVENTS_UNIT_UPGRADES', 'EVENTS_UNIT_CONVERTS',
 'EVENTS_UNIT_CAPTURE', 'EVENTS_UNIT_ACTIONS', 'EVENTS_UNIT_DATA',
 'EVENTS_BATTLES',
 'EVENTS_RED_COMBAT', 'EVENTS_RED_COMBAT_RESULT', 'EVENTS_RED_COMBAT_ENDED',
 'EVENTS_PLAYER_TURN');

INSERT INTO Colors (Type, Red, Green, Blue, Alpha) VALUES
('COLOR_ROULS_PRIMARY', 0.19, 0.10, 0.27, 1),
('COLOR_ROULS_SECONDARY', 0.48, 0.91, 0.83, 1);
INSERT INTO PlayerColors (Type, PrimaryColor, SecondaryColor, TextColor) VALUES
('PLAYERCOLOR_ROULS', 'COLOR_ROULS_PRIMARY', 'COLOR_ROULS_SECONDARY', 'COLOR_PLAYER_WHITE_TEXT');
INSERT INTO IconTextureAtlases (Atlas, IconSize, Filename, IconsPerRow, IconsPerColumn) VALUES
('ROULS_ICON_ATLAS', 256, 'RoulsIcon256.dds', 1, 1),
('ROULS_ICON_ATLAS', 128, 'RoulsIcon128.dds', 1, 1),
('ROULS_ICON_ATLAS', 80, 'RoulsIcon80.dds', 1, 1),
('ROULS_ICON_ATLAS', 64, 'RoulsIcon64.dds', 1, 1),
('ROULS_ICON_ATLAS', 45, 'RoulsIcon45.dds', 1, 1),
('ROULS_ICON_ATLAS', 32, 'RoulsIcon32.dds', 1, 1),
('ROULS_ALPHA_ATLAS', 256, 'RoulsAlpha256.dds', 1, 1),
('ROULS_ALPHA_ATLAS', 128, 'RoulsAlpha128.dds', 1, 1),
('ROULS_ALPHA_ATLAS', 80, 'RoulsAlpha80.dds', 1, 1),
('ROULS_ALPHA_ATLAS', 64, 'RoulsAlpha64.dds', 1, 1),
('ROULS_ALPHA_ATLAS', 45, 'RoulsAlpha45.dds', 1, 1),
('ROULS_ALPHA_ATLAS', 32, 'RoulsAlpha32.dds', 1, 1);

INSERT INTO Traits (Type, Description, ShortDescription) VALUES
('TRAIT_ROULS_FLESH_IS_A_COAT', 'TXT_KEY_TRAIT_ROULS_HELP', 'TXT_KEY_TRAIT_ROULS_SHORT');

CREATE TEMP TABLE RoulsCloneLeader AS SELECT * FROM Leaders WHERE Type = 'LEADER_WASHINGTON';
UPDATE RoulsCloneLeader SET ID = NULL, Type = 'LEADER_TRENT_ROULS',
 Description = 'TXT_KEY_LEADER_TRENT_ROULS', Civilopedia = 'TXT_KEY_LEADER_TRENT_ROULS_PEDIA',
 CivilopediaTag = 'TXT_KEY_CIVILOPEDIA_LEADERS_TRENT_ROULS', ArtDefineTag = 'RoulsLeaderScene.xml',
 PortraitIndex = 0, IconAtlas = 'ROULS_ICON_ATLAS',
 VictoryCompetitiveness = 8, WonderCompetitiveness = 2, MinorCivCompetitiveness = 5,
 Boldness = 7, DiploBalance = 5, WarmongerHate = 3, DoFWillingness = 5,
 DenounceWillingness = 5, WorkWithWillingness = 5, WorkAgainstWillingness = 7,
 Loyalty = 7, Forgiveness = 4, Neediness = 3, Meanness = 5, Chattiness = 4,
 PackageID = NULL;
INSERT INTO Leaders SELECT * FROM RoulsCloneLeader;
DROP TABLE RoulsCloneLeader;
INSERT INTO Leader_Traits (LeaderType, TraitType) VALUES
('LEADER_TRENT_ROULS', 'TRAIT_ROULS_FLESH_IS_A_COAT');

CREATE TEMP TABLE RoulsCloneCivilization AS SELECT * FROM Civilizations WHERE Type = 'CIVILIZATION_AMERICA';
UPDATE RoulsCloneCivilization SET ID = NULL, Type = 'CIVILIZATION_ROULS_ASCENDANCY',
 Description = 'TXT_KEY_CIV_ROULS_DESC', ShortDescription = 'TXT_KEY_CIV_ROULS_SHORT_DESC',
 Adjective = 'TXT_KEY_CIV_ROULS_ADJECTIVE', Civilopedia = 'TXT_KEY_CIV_ROULS_PEDIA',
 CivilopediaTag = 'TXT_KEY_CIV5_ROULS', Strategy = 'TXT_KEY_CIV_ROULS_STRATEGY',
 DefaultPlayerColor = 'PLAYERCOLOR_ROULS', Playable = 1, AIPlayable = 1,
 PortraitIndex = 0, IconAtlas = 'ROULS_ICON_ATLAS', AlphaIconAtlas = 'ROULS_ALPHA_ATLAS',
 DawnOfManQuote = 'TXT_KEY_ROULS_DAWN_OF_MAN', DawnOfManImage = 'RoulsLeader.dds',
 DawnOfManAudio = '', PackageID = NULL;
INSERT INTO Civilizations SELECT * FROM RoulsCloneCivilization;
DROP TABLE RoulsCloneCivilization;
INSERT INTO Civilization_Leaders (CivilizationType, LeaderheadType) VALUES
('CIVILIZATION_ROULS_ASCENDANCY', 'LEADER_TRENT_ROULS');
INSERT INTO Civilization_FreeBuildingClasses SELECT 'CIVILIZATION_ROULS_ASCENDANCY', BuildingClassType
 FROM Civilization_FreeBuildingClasses WHERE CivilizationType = 'CIVILIZATION_AMERICA';
INSERT INTO Civilization_FreeUnits SELECT 'CIVILIZATION_ROULS_ASCENDANCY', UnitClassType, UnitAIType, Count
 FROM Civilization_FreeUnits WHERE CivilizationType = 'CIVILIZATION_AMERICA';
-- Standard BNW starts with Agriculture. The brief also says no bonus tech;
-- follow that requirement instead of granting Mining as an additional tech.
INSERT INTO Civilization_FreeTechs SELECT 'CIVILIZATION_ROULS_ASCENDANCY', TechType
 FROM Civilization_FreeTechs WHERE CivilizationType = 'CIVILIZATION_AMERICA';
-- No terrain/coast/river start bias and no preferred religion are inserted.

CREATE TEMP TABLE RoulsCloneUnits AS
 SELECT * FROM Units WHERE Type IN ('UNIT_RIFLEMAN', 'UNIT_GREAT_GENERAL', 'UNIT_DESTROYER');
UPDATE RoulsCloneUnits SET ID = NULL;
UPDATE RoulsCloneUnits SET Type = 'UNIT_ROULS_HOLLOWHOUND',
 Description = 'TXT_KEY_UNIT_ROULS_HOLLOWHOUND', Civilopedia = 'TXT_KEY_UNIT_ROULS_HOLLOWHOUND_PEDIA',
 Strategy = 'TXT_KEY_UNIT_ROULS_HOLLOWHOUND_STRATEGY', Help = 'TXT_KEY_UNIT_ROULS_HOLLOWHOUND_HELP',
 Cost = (Cost * 110 + 99) / 100, Moves = 2 WHERE Type = 'UNIT_RIFLEMAN';
UPDATE RoulsCloneUnits SET Type = 'UNIT_ROULS_MATRIARCH',
 Description = 'TXT_KEY_UNIT_ROULS_MATRIARCH', Civilopedia = 'TXT_KEY_UNIT_ROULS_MATRIARCH_PEDIA',
 Strategy = 'TXT_KEY_UNIT_ROULS_MATRIARCH_STRATEGY', Help = 'TXT_KEY_UNIT_ROULS_MATRIARCH_HELP'
 WHERE Type = 'UNIT_GREAT_GENERAL';
UPDATE RoulsCloneUnits SET Type = 'UNIT_ROULS_BUDDY', Class = 'UNITCLASS_ROULS_BUDDY',
 Description = 'TXT_KEY_UNIT_ROULS_BUDDY', Civilopedia = 'TXT_KEY_UNIT_ROULS_BUDDY_PEDIA',
 Strategy = 'TXT_KEY_UNIT_ROULS_BUDDY_STRATEGY', Help = 'TXT_KEY_UNIT_ROULS_BUDDY_HELP',
 Cost = 350, FaithCost = 0, RequiresFaithPurchaseEnabled = 0, HurryCostModifier = -1,
 Combat = 45, RangedCombat = 0, Range = 0, Moves = 5, BaseSightRange = 3,
 PrereqTech = 'TECH_BIOLOGY', ObsoleteTech = NULL, GoodyHutUpgradeUnitClass = NULL,
 CombatClass = 'UNITCOMBAT_NAVALMELEE', DefaultUnitAI = 'UNITAI_ATTACK_SEA',
 AirInterceptRange = 0,
 UnitArtInfo = (SELECT UnitArtInfo FROM Units WHERE Type = 'UNIT_BATTLESHIP'),
 UnitFlagIconOffset = (SELECT UnitFlagIconOffset FROM Units WHERE Type = 'UNIT_BATTLESHIP'),
 UnitFlagAtlas = (SELECT UnitFlagAtlas FROM Units WHERE Type = 'UNIT_BATTLESHIP'),
 PortraitIndex = (SELECT PortraitIndex FROM Units WHERE Type = 'UNIT_BATTLESHIP'),
 IconAtlas = (SELECT IconAtlas FROM Units WHERE Type = 'UNIT_BATTLESHIP')
 WHERE Type = 'UNIT_DESTROYER';
INSERT INTO Units SELECT * FROM RoulsCloneUnits;
DROP TABLE RoulsCloneUnits;

-- A real but unbuildable default avoids making Buddy available to other civs,
-- including civs loaded after this mod. Lua also enforces the reserve lock.
CREATE TEMP TABLE RoulsCloneDisabledBuddy AS SELECT * FROM Units WHERE Type = 'UNIT_ROULS_BUDDY';
UPDATE RoulsCloneDisabledBuddy SET ID = NULL, Type = 'UNIT_ROULS_BUDDY_DISABLED',
 Cost = -1, FaithCost = 0, ShowInPedia = 0;
INSERT INTO Units SELECT * FROM RoulsCloneDisabledBuddy;
DROP TABLE RoulsCloneDisabledBuddy;
INSERT INTO UnitClasses (Type, Description, DefaultUnit, MaxPlayerInstances) VALUES
('UNITCLASS_ROULS_BUDDY', 'TXT_KEY_UNIT_ROULS_BUDDY', 'UNIT_ROULS_BUDDY_DISABLED', 1);
INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType) VALUES
('CIVILIZATION_ROULS_ASCENDANCY', 'UNITCLASS_RIFLEMAN', 'UNIT_ROULS_HOLLOWHOUND'),
('CIVILIZATION_ROULS_ASCENDANCY', 'UNITCLASS_GREAT_GENERAL', 'UNIT_ROULS_MATRIARCH'),
('CIVILIZATION_ROULS_ASCENDANCY', 'UNITCLASS_ROULS_BUDDY', 'UNIT_ROULS_BUDDY');

CREATE TEMP TABLE RoulsCloneBuildings AS
 SELECT * FROM Buildings WHERE Type IN ('BUILDING_HOSPITAL', 'BUILDING_HEROIC_EPIC');
UPDATE RoulsCloneBuildings SET ID = NULL;
UPDATE RoulsCloneBuildings SET Type = 'BUILDING_ROULS_SOMATIC_LATTICE',
 Description = 'TXT_KEY_BUILDING_ROULS_SOMATIC_LATTICE',
 Civilopedia = 'TXT_KEY_BUILDING_ROULS_SOMATIC_LATTICE_PEDIA',
 Strategy = 'TXT_KEY_BUILDING_ROULS_SOMATIC_LATTICE_STRATEGY',
 Help = 'TXT_KEY_BUILDING_ROULS_SOMATIC_LATTICE_HELP' WHERE Type = 'BUILDING_HOSPITAL';
UPDATE RoulsCloneBuildings SET Type = 'BUILDING_ROULS_CHOIR_ETERNAL',
 Description = 'TXT_KEY_BUILDING_ROULS_CHOIR_ETERNAL',
 Civilopedia = 'TXT_KEY_BUILDING_ROULS_CHOIR_ETERNAL_PEDIA',
 Strategy = 'TXT_KEY_BUILDING_ROULS_CHOIR_ETERNAL_STRATEGY',
 Help = 'TXT_KEY_BUILDING_ROULS_CHOIR_ETERNAL_HELP', Experience = Experience + 5,
 Quote = 'TXT_KEY_BUILDING_ROULS_CHOIR_ETERNAL_QUOTE' WHERE Type = 'BUILDING_HEROIC_EPIC';
INSERT INTO Buildings SELECT * FROM RoulsCloneBuildings;
DROP TABLE RoulsCloneBuildings;
INSERT INTO Civilization_BuildingClassOverrides (CivilizationType, BuildingClassType, BuildingType) VALUES
('CIVILIZATION_ROULS_ASCENDANCY', 'BUILDINGCLASS_HOSPITAL', 'BUILDING_ROULS_SOMATIC_LATTICE'),
('CIVILIZATION_ROULS_ASCENDANCY', 'BUILDINGCLASS_HEROIC_EPIC', 'BUILDING_ROULS_CHOIR_ETERNAL');

INSERT INTO BuildingClasses (Type, Description, DefaultBuilding) VALUES
('BUILDINGCLASS_ROULS_CAPITAL_SCIENCE', 'TXT_KEY_BUILDING_ROULS_CAPITAL_SCIENCE', 'BUILDING_ROULS_CAPITAL_SCIENCE');
INSERT INTO Buildings
(Type, BuildingClass, Description, Help, Cost, FaithCost, GoldMaintenance,
 GreatWorkCount, NeverCapture, NukeImmune, ConquestProb, HurryCostModifier,
 IconAtlas, PortraitIndex) VALUES
('BUILDING_ROULS_CAPITAL_SCIENCE', 'BUILDINGCLASS_ROULS_CAPITAL_SCIENCE',
 'TXT_KEY_BUILDING_ROULS_CAPITAL_SCIENCE', 'TXT_KEY_BUILDING_ROULS_CAPITAL_SCIENCE_HELP',
 -1, -1, 0, -1, 1, 1, 0, -1, 'BW_ATLAS_1', 0);
INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield) VALUES
('BUILDING_ROULS_CAPITAL_SCIENCE', 'YIELD_SCIENCE', 1);

INSERT INTO UnitPromotions
(Type, Description, Help, CannotBeChosen, LostWithUpgrade, PortraitIndex, IconAtlas, PediaType, PediaEntry, OnlyDefensive, RangeChange) VALUES
('PROMOTION_ROULS_SECOND_SKIN', 'TXT_KEY_PROMOTION_ROULS_SECOND_SKIN', 'TXT_KEY_PROMOTION_ROULS_SECOND_SKIN_HELP', 1, 0, 59, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_ROULS_SECOND_SKIN', 0, 0),
('PROMOTION_ROULS_SECOND_SKIN_COOLDOWN', 'TXT_KEY_PROMOTION_ROULS_SECOND_SKIN_COOLDOWN', 'TXT_KEY_PROMOTION_ROULS_SECOND_SKIN_COOLDOWN_HELP', 1, 0, 59, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_ROULS_SECOND_SKIN_COOLDOWN', 0, 0),
('PROMOTION_ROULS_EVERLASTING_PASSENGER', 'TXT_KEY_PROMOTION_ROULS_EVERLASTING_PASSENGER', 'TXT_KEY_PROMOTION_ROULS_EVERLASTING_PASSENGER_HELP', 1, 0, 59, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_ROULS_EVERLASTING_PASSENGER', 0, 0),
('PROMOTION_ROULS_ACTION_LOCK', 'TXT_KEY_PROMOTION_ROULS_ACTION_LOCK', 'TXT_KEY_PROMOTION_ROULS_ACTION_LOCK_HELP', 1, 0, 59, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_ROULS_ACTION_LOCK', 1, -99);
-- The cooldown has no engine timer: Lua saves an absolute expiry turn.
-- The cooldown is an ordinary hidden-choice promotion. Some CP-compatible
-- database builds omit UI-only visibility columns, so the Lua owns its state.
INSERT INTO UnitPromotions
(Type, Description, Help, CannotBeChosen, LostWithUpgrade, CombatPercent, PortraitIndex, IconAtlas) VALUES
('PROMOTION_ROULS_CHOIR_1', 'TXT_KEY_PROMOTION_ROULS_CHOIR', 'TXT_KEY_PROMOTION_ROULS_CHOIR_1_HELP', 1, 1, 3, 59, 'ABILITY_ATLAS'),
('PROMOTION_ROULS_CHOIR_2', 'TXT_KEY_PROMOTION_ROULS_CHOIR', 'TXT_KEY_PROMOTION_ROULS_CHOIR_2_HELP', 1, 1, 6, 59, 'ABILITY_ATLAS'),
('PROMOTION_ROULS_CHOIR_3', 'TXT_KEY_PROMOTION_ROULS_CHOIR', 'TXT_KEY_PROMOTION_ROULS_CHOIR_3_HELP', 1, 1, 9, 59, 'ABILITY_ATLAS'),
('PROMOTION_ROULS_CHOIR_4', 'TXT_KEY_PROMOTION_ROULS_CHOIR', 'TXT_KEY_PROMOTION_ROULS_CHOIR_4_HELP', 1, 1, 12, 59, 'ABILITY_ATLAS'),
('PROMOTION_ROULS_CHOIR_5', 'TXT_KEY_PROMOTION_ROULS_CHOIR', 'TXT_KEY_PROMOTION_ROULS_CHOIR_5_HELP', 1, 1, 15, 59, 'ABILITY_ATLAS'),
('PROMOTION_ROULS_BUDDY_AURA', 'TXT_KEY_PROMOTION_ROULS_BUDDY_AURA', 'TXT_KEY_PROMOTION_ROULS_BUDDY_AURA_HELP', 1, 1, 10, 59, 'ABILITY_ATLAS'),
('PROMOTION_ROULS_BUDDY_INVASION', 'TXT_KEY_PROMOTION_ROULS_BUDDY_INVASION', 'TXT_KEY_PROMOTION_ROULS_BUDDY_INVASION_HELP', 1, 1, -10, 59, 'ABILITY_ATLAS');
-- Healing is applied by Lua once per owner's turn, never duplicated here.
