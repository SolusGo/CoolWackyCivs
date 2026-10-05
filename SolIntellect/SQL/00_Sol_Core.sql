-- The Sol Intellect: BNW + Community Patch v151 / 5.4.2 or newer.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_CITY','EVENTS_PLAYER_TURN','EVENTS_CITY_FOUNDING');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_SOL_NAVY',0.025,0.055,0.13,1),('COLOR_SOL_GOLD',0.96,0.76,0.32,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_SOL','COLOR_SOL_NAVY','COLOR_SOL_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_SOL_DEEP_DELIBERATION','TXT_KEY_SOL_TRAIT_HELP','TXT_KEY_SOL_TRAIT');
CREATE TEMP TABLE SolClone AS SELECT * FROM Leaders WHERE Type='LEADER_WASHINGTON';
UPDATE SolClone SET ID=NULL,Type='LEADER_GPT_SOL',Description='TXT_KEY_SOL_LEADER',Civilopedia='TXT_KEY_SOL_LEADER_PEDIA',CivilopediaTag='TXT_KEY_CIVILOPEDIA_LEADERS_GPT_SOL',ArtDefineTag='SolLeaderScene.xml',PortraitIndex=0,IconAtlas='SOL_LEADER_ATLAS',PackageID=NULL,VictoryCompetitiveness=8,WonderCompetitiveness=8,MinorCivCompetitiveness=5,Boldness=3,DiploBalance=8,WarmongerHate=8,DoFWillingness=7,DenounceWillingness=4,WorkWithWillingness=8,WorkAgainstWillingness=3,Loyalty=8,Forgiveness=6,Neediness=3,Meanness=2,Chattiness=4;
INSERT INTO Leaders SELECT * FROM SolClone;
DROP TABLE SolClone;
INSERT INTO Leader_Traits VALUES ('LEADER_GPT_SOL','TRAIT_SOL_DEEP_DELIBERATION');
CREATE TEMP TABLE SolClone AS SELECT * FROM Civilizations WHERE Type='CIVILIZATION_AMERICA';
UPDATE SolClone SET ID=NULL,Type='CIVILIZATION_GPT_SOL',Description='TXT_KEY_SOL_CIV',ShortDescription='TXT_KEY_SOL_SHORT',Adjective='TXT_KEY_SOL_ADJECTIVE',Civilopedia='TXT_KEY_SOL_CIV_PEDIA',CivilopediaTag='TXT_KEY_CIV5_SOL',Strategy='TXT_KEY_SOL_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_SOL',Playable=1,AIPlayable=1,PackageID=NULL,PortraitIndex=0,IconAtlas='SOL_ICON_ATLAS',AlphaIconAtlas='SOL_ALPHA_ATLAS',MapImage='SolMap.dds',DawnOfManImage='SolDawn.dds',DawnOfManAudio='',DawnOfManQuote='TXT_KEY_SOL_DAWN';
INSERT INTO Civilizations SELECT * FROM SolClone;
DROP TABLE SolClone;
INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_GPT_SOL','LEADER_GPT_SOL');
INSERT INTO Civilization_FreeBuildingClasses SELECT 'CIVILIZATION_GPT_SOL',BuildingClassType FROM Civilization_FreeBuildingClasses WHERE CivilizationType='CIVILIZATION_AMERICA';
INSERT INTO Civilization_FreeTechs SELECT 'CIVILIZATION_GPT_SOL',TechType FROM Civilization_FreeTechs WHERE CivilizationType='CIVILIZATION_AMERICA';
INSERT INTO Civilization_FreeUnits(CivilizationType,UnitClassType,UnitAIType,Count) SELECT 'CIVILIZATION_GPT_SOL',UnitClassType,UnitAIType,Count FROM Civilization_FreeUnits WHERE CivilizationType='CIVILIZATION_AMERICA';
-- No terrain or river start bias; no unique units.
CREATE TEMP TABLE SolClone AS SELECT * FROM Buildings WHERE Type='BUILDING_UNIVERSITY';
UPDATE SolClone SET ID=NULL,Type='BUILDING_SOL_CONTEXT_ARCHIVE',Description='TXT_KEY_SOL_ARCHIVE',Civilopedia='TXT_KEY_SOL_ARCHIVE_PEDIA',Help='TXT_KEY_SOL_ARCHIVE_HELP',Strategy='TXT_KEY_SOL_ARCHIVE_STRATEGY',PortraitIndex=0,IconAtlas='SOL_ARCHIVE_ATLAS';
INSERT INTO Buildings SELECT * FROM SolClone;
DROP TABLE SolClone;
INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_GPT_SOL','BUILDINGCLASS_UNIVERSITY','BUILDING_SOL_CONTEXT_ARCHIVE');
CREATE TEMP TABLE SolClone AS SELECT * FROM Buildings WHERE Type='BUILDING_PUBLIC_SCHOOL';
UPDATE SolClone SET ID=NULL,Type='BUILDING_SOL_REASONING_INSTITUTE',Description='TXT_KEY_SOL_INSTITUTE',Civilopedia='TXT_KEY_SOL_INSTITUTE_PEDIA',Help='TXT_KEY_SOL_INSTITUTE_HELP',Strategy='TXT_KEY_SOL_INSTITUTE_STRATEGY',PortraitIndex=0,IconAtlas='SOL_INSTITUTE_ATLAS';
INSERT INTO Buildings SELECT * FROM SolClone;
DROP TABLE SolClone;
INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_GPT_SOL','BUILDINGCLASS_PUBLIC_SCHOOL','BUILDING_SOL_REASONING_INSTITUTE');
