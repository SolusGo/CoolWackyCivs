-- Preserve the Great General's essential actions/AI and the Garden's AI valuation.

CREATE TEMP TABLE MessiClone AS SELECT * FROM UnitGameplay2DScripts WHERE UnitType='UNIT_GREAT_GENERAL';
UPDATE MessiClone SET UnitType='UNIT_MESSI_NUMBER_TEN';
INSERT INTO UnitGameplay2DScripts SELECT * FROM MessiClone;
DROP TABLE MessiClone;
CREATE TEMP TABLE MessiClone AS SELECT * FROM Unit_AITypes WHERE UnitType='UNIT_GREAT_GENERAL';
UPDATE MessiClone SET UnitType='UNIT_MESSI_NUMBER_TEN';
INSERT INTO Unit_AITypes SELECT * FROM MessiClone;
DROP TABLE MessiClone;

CREATE TEMP TABLE MessiClone AS SELECT * FROM Unit_Builds WHERE UnitType='UNIT_GREAT_GENERAL';
UPDATE MessiClone SET UnitType='UNIT_MESSI_NUMBER_TEN';
INSERT INTO Unit_Builds SELECT * FROM MessiClone;
DROP TABLE MessiClone;

INSERT INTO Unit_Builds(UnitType,BuildType) VALUES
('UNIT_MESSI_NUMBER_TEN','BUILD_MESSI_FOOTBALL_ACADEMY');

CREATE TEMP TABLE MessiClone AS SELECT * FROM Unit_ResourceQuantityRequirements WHERE UnitType='UNIT_GREAT_GENERAL';
UPDATE MessiClone SET UnitType='UNIT_MESSI_NUMBER_TEN';
INSERT INTO Unit_ResourceQuantityRequirements SELECT * FROM MessiClone;
DROP TABLE MessiClone;

CREATE TEMP TABLE MessiClone AS SELECT * FROM Building_Flavors WHERE BuildingType='BUILDING_GARDEN';
UPDATE MessiClone SET BuildingType='BUILDING_MESSI_LA_MASIA';
INSERT INTO Building_Flavors SELECT * FROM MessiClone;
DROP TABLE MessiClone;

-- La Masia has its own exact visible yield rather than inheriting balance-mod-dependent Garden yields.
DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_MESSI_LA_MASIA';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES
('BUILDING_MESSI_LA_MASIA','YIELD_CULTURE',1);

-- Retain the Citadel's terrain/art validity and culture-bomb companion definitions.
CREATE TEMP TABLE MessiClone AS SELECT * FROM Improvement_ValidTerrains WHERE ImprovementType='IMPROVEMENT_CITADEL';
UPDATE MessiClone SET ImprovementType='IMPROVEMENT_MESSI_FOOTBALL_ACADEMY';
INSERT INTO Improvement_ValidTerrains SELECT * FROM MessiClone;
DROP TABLE MessiClone;

CREATE TEMP TABLE MessiClone AS SELECT * FROM Improvement_ValidFeatures WHERE ImprovementType='IMPROVEMENT_CITADEL';
UPDATE MessiClone SET ImprovementType='IMPROVEMENT_MESSI_FOOTBALL_ACADEMY';
INSERT INTO Improvement_ValidFeatures SELECT * FROM MessiClone;
DROP TABLE MessiClone;
