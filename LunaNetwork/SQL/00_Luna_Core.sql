-- The Luna Network: Civilization V Brave New World + Community Patch.
-- Scalar rows are cloned at activation so CP-added columns remain compatible.
UPDATE CustomModOptions SET Value = 1 WHERE Name IN
('EVENTS_CITY', 'EVENTS_UNIT_CREATED', 'EVENTS_UNIT_UPGRADES',
 'EVENTS_UNIT_CONVERTS', 'EVENTS_UNIT_CAPTURE', 'EVENTS_PLAYER_TURN');

INSERT INTO Colors (Type, Red, Green, Blue, Alpha) VALUES
('COLOR_LUNA_PRIMARY', 0.025, 0.055, 0.145, 1),
('COLOR_LUNA_SECONDARY', 0.54, 0.91, 0.98, 1);
INSERT INTO PlayerColors (Type, PrimaryColor, SecondaryColor, TextColor) VALUES
('PLAYERCOLOR_LUNA', 'COLOR_LUNA_PRIMARY', 'COLOR_LUNA_SECONDARY', 'COLOR_PLAYER_WHITE_TEXT');

INSERT INTO IconTextureAtlases (Atlas, IconSize, Filename, IconsPerRow, IconsPerColumn) VALUES
('LUNA_ICON_ATLAS', 256, 'LunaIcon256.dds', 1, 1),
('LUNA_ICON_ATLAS', 128, 'LunaIcon128.dds', 1, 1),
('LUNA_ICON_ATLAS', 80, 'LunaIcon80.dds', 1, 1),
('LUNA_ICON_ATLAS', 64, 'LunaIcon64.dds', 1, 1),
('LUNA_ICON_ATLAS', 45, 'LunaIcon45.dds', 1, 1),
('LUNA_ICON_ATLAS', 32, 'LunaIcon32.dds', 1, 1),
('LUNA_ALPHA_ATLAS', 256, 'LunaAlpha256.dds', 1, 1),
('LUNA_ALPHA_ATLAS', 128, 'LunaAlpha128.dds', 1, 1),
('LUNA_ALPHA_ATLAS', 80, 'LunaAlpha80.dds', 1, 1),
('LUNA_ALPHA_ATLAS', 64, 'LunaAlpha64.dds', 1, 1),
('LUNA_ALPHA_ATLAS', 45, 'LunaAlpha45.dds', 1, 1),
('LUNA_ALPHA_ATLAS', 32, 'LunaAlpha32.dds', 1, 1);

INSERT INTO Traits (Type, Description, ShortDescription) VALUES
('TRAIT_LUNA_LOW_LATENCY', 'TXT_KEY_TRAIT_LUNA_HELP', 'TXT_KEY_TRAIT_LUNA_SHORT');

CREATE TEMP TABLE LunaCloneLeader AS SELECT * FROM Leaders WHERE Type = 'LEADER_WASHINGTON';
UPDATE LunaCloneLeader SET ID = NULL, Type = 'LEADER_GPT_LUNA',
 Description = 'TXT_KEY_LEADER_GPT_LUNA', Civilopedia = 'TXT_KEY_LEADER_GPT_LUNA_PEDIA',
 CivilopediaTag = 'TXT_KEY_CIVILOPEDIA_LEADERS_GPT_LUNA', ArtDefineTag = 'LunaLeaderScene.xml',
 PortraitIndex = 0, IconAtlas = 'LUNA_ICON_ATLAS',
 VictoryCompetitiveness = 8, WonderCompetitiveness = 2, MinorCivCompetitiveness = 7,
 Boldness = 7, DiploBalance = 6, WarmongerHate = 4, DoFWillingness = 6,
 DenounceWillingness = 5, WorkWithWillingness = 7, WorkAgainstWillingness = 6,
 Loyalty = 6, Forgiveness = 5, Neediness = 4, Meanness = 4, Chattiness = 7,
 PackageID = NULL;
INSERT INTO Leaders SELECT * FROM LunaCloneLeader;
DROP TABLE LunaCloneLeader;
INSERT INTO Leader_Traits (LeaderType, TraitType) VALUES
('LEADER_GPT_LUNA', 'TRAIT_LUNA_LOW_LATENCY');

CREATE TEMP TABLE LunaCloneCivilization AS SELECT * FROM Civilizations WHERE Type = 'CIVILIZATION_AMERICA';
UPDATE LunaCloneCivilization SET ID = NULL, Type = 'CIVILIZATION_GPT_LUNA',
 Description = 'TXT_KEY_CIV_LUNA_DESC', ShortDescription = 'TXT_KEY_CIV_LUNA_SHORT_DESC',
 Adjective = 'TXT_KEY_CIV_LUNA_ADJECTIVE', Civilopedia = 'TXT_KEY_CIV_LUNA_PEDIA',
 CivilopediaTag = 'TXT_KEY_CIV5_LUNA', Strategy = 'TXT_KEY_CIV_LUNA_STRATEGY',
 DefaultPlayerColor = 'PLAYERCOLOR_LUNA', Playable = 1, AIPlayable = 0,
 PortraitIndex = 0, IconAtlas = 'LUNA_ICON_ATLAS', AlphaIconAtlas = 'LUNA_ALPHA_ATLAS',
 DawnOfManQuote = 'TXT_KEY_LUNA_DAWN_OF_MAN', DawnOfManImage = 'LunaLeader.dds',
 DawnOfManAudio = '', PackageID = NULL;
INSERT INTO Civilizations SELECT * FROM LunaCloneCivilization;
DROP TABLE LunaCloneCivilization;
INSERT INTO Civilization_Leaders (CivilizationType, LeaderheadType) VALUES
('CIVILIZATION_GPT_LUNA', 'LEADER_GPT_LUNA');
INSERT INTO Civilization_FreeBuildingClasses
 SELECT 'CIVILIZATION_GPT_LUNA', BuildingClassType
 FROM Civilization_FreeBuildingClasses WHERE CivilizationType = 'CIVILIZATION_AMERICA';
INSERT INTO Civilization_FreeUnits (CivilizationType, UnitClassType, UnitAIType, Count)
 SELECT 'CIVILIZATION_GPT_LUNA', UnitClassType, UnitAIType, Count
 FROM Civilization_FreeUnits WHERE CivilizationType = 'CIVILIZATION_AMERICA';
INSERT INTO Civilization_FreeTechs
 SELECT 'CIVILIZATION_GPT_LUNA', TechType
 FROM Civilization_FreeTechs WHERE CivilizationType = 'CIVILIZATION_AMERICA';
-- No terrain, coast, river, or religion bias is added.

CREATE TEMP TABLE LunaCloneUnit AS SELECT * FROM Units WHERE Type = 'UNIT_SETTLER';
UPDATE LunaCloneUnit SET ID = NULL, Type = 'UNIT_LUNA_PACKET_SETTLER',
 Description = 'TXT_KEY_UNIT_LUNA_PACKET_SETTLER', Civilopedia = 'TXT_KEY_UNIT_LUNA_PACKET_SETTLER_PEDIA',
 Strategy = 'TXT_KEY_UNIT_LUNA_PACKET_SETTLER_STRATEGY', Help = 'TXT_KEY_UNIT_LUNA_PACKET_SETTLER_HELP',
 Cost = (Cost * 90) / 100, Moves = Moves + 1;
INSERT INTO Units SELECT * FROM LunaCloneUnit;
DROP TABLE LunaCloneUnit;
INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType) VALUES
('CIVILIZATION_GPT_LUNA', 'UNITCLASS_SETTLER', 'UNIT_LUNA_PACKET_SETTLER');

CREATE TEMP TABLE LunaCloneBuilding AS SELECT * FROM Buildings WHERE Type = 'BUILDING_LIBRARY';
UPDATE LunaCloneBuilding SET ID = NULL, Type = 'BUILDING_LUNA_CACHE_NODE',
 Description = 'TXT_KEY_BUILDING_LUNA_CACHE_NODE', Civilopedia = 'TXT_KEY_BUILDING_LUNA_CACHE_NODE_PEDIA',
 Strategy = 'TXT_KEY_BUILDING_LUNA_CACHE_NODE_STRATEGY', Help = 'TXT_KEY_BUILDING_LUNA_CACHE_NODE_HELP',
 Cost = (Cost * 85) / 100;
INSERT INTO Buildings SELECT * FROM LunaCloneBuilding;
DROP TABLE LunaCloneBuilding;
INSERT INTO Civilization_BuildingClassOverrides (CivilizationType, BuildingClassType, BuildingType) VALUES
('CIVILIZATION_GPT_LUNA', 'BUILDINGCLASS_LIBRARY', 'BUILDING_LUNA_CACHE_NODE');

INSERT INTO UnitPromotions
(Type, Description, Help, CannotBeChosen, LostWithUpgrade, MovesChange,
 PortraitIndex, IconAtlas, PediaType, PediaEntry) VALUES
('PROMOTION_LUNA_RAPID_RESPONSE', 'TXT_KEY_PROMOTION_LUNA_RAPID_RESPONSE',
 'TXT_KEY_PROMOTION_LUNA_RAPID_RESPONSE_HELP', 1, 0, 1,
 59, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_LUNA_RAPID_RESPONSE');
