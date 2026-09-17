-- Clone BNW companion tables at activation, preserving all columns added by CP.
-- Empty source tables are safe. No hard-coded Food/Morale/GG/build prerequisites.
CREATE TEMP TABLE FilthyUnitMap (OldType TEXT, NewType TEXT);
INSERT INTO FilthyUnitMap VALUES
('UNIT_GREAT_WAR_INFANTRY', 'UNIT_FILTHY_PEACE_LORD');
CREATE TEMP TABLE FilthyBuildingMap (OldType TEXT, NewType TEXT);
INSERT INTO FilthyBuildingMap VALUES
('BUILDING_BROADCAST_TOWER', 'BUILDING_FILTHY_KITCHEN');

-- Building_AreaYieldModifiers
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_AreaYieldModifiers WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_AreaYieldModifiers SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_BuildingClassHappiness
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_BuildingClassHappiness WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassHappiness SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_BuildingClassYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_BuildingClassYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ClassesNeededInCity
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ClassesNeededInCity WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ClassesNeededInCity SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_DomainFreeExperiencePerGreatWork
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiencePerGreatWork WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiencePerGreatWork SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_DomainFreeExperiences
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiences WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiences SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_DomainProductionModifiers
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_DomainProductionModifiers WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_DomainProductionModifiers SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_FeatureYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_FeatureYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_FeatureYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_Flavors
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_Flavors WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_Flavors SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_FreeSpecialistCounts
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_FreeSpecialistCounts WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_FreeSpecialistCounts SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_FreeUnits
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_FreeUnits WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_FreeUnits SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_GlobalYieldModifiers
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_GlobalYieldModifiers WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_GlobalYieldModifiers SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_HurryModifiers
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_HurryModifiers WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_HurryModifiers SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_LakePlotYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_LakePlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_LakePlotYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_LocalResourceAnds
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_LocalResourceAnds WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceAnds SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_LocalResourceOrs
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_LocalResourceOrs WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceOrs SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_LockedBuildingClasses
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_LockedBuildingClasses WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_LockedBuildingClasses SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_PrereqBuildingClasses
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_PrereqBuildingClasses WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_PrereqBuildingClasses SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ResourceCultureChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ResourceCultureChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ResourceCultureChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ResourceFaithChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ResourceFaithChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ResourceFaithChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ResourceQuantity
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ResourceQuantity WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantity SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ResourceQuantityRequirements
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ResourceQuantityRequirements WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantityRequirements SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ResourceYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ResourceYieldModifiers
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ResourceYieldModifiers WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldModifiers SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_RiverPlotYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_RiverPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_RiverPlotYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_SeaPlotYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_SeaPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_SeaPlotYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_SeaResourceYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_SeaResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_SeaResourceYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_SpecialistYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_SpecialistYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_SpecialistYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_TechAndPrereqs
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_TechAndPrereqs WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_TechAndPrereqs SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_TechEnhancedYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_TechEnhancedYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_TechEnhancedYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_TerrainYieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_TerrainYieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_TerrainYieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_ThemingBonuses
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_ThemingBonuses WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_ThemingBonuses SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_UnitCombatFreeExperiences
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_UnitCombatFreeExperiences WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatFreeExperiences SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_UnitCombatProductionModifiers
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_UnitCombatProductionModifiers WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatProductionModifiers SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_YieldChanges
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_YieldChanges WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_YieldChanges SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_YieldChangesPerPop
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_YieldChangesPerPop WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerPop SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_YieldChangesPerReligion
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_YieldChangesPerReligion WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerReligion SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Building_YieldModifiers
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Building_YieldModifiers WHERE BuildingType IN (SELECT OldType FROM FilthyBuildingMap);
UPDATE FilthyCompanionClone SET BuildingType =
 (SELECT NewType FROM FilthyBuildingMap WHERE OldType = FilthyCompanionClone.BuildingType);
INSERT INTO Building_YieldModifiers SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- UnitGameplay2DScripts
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM UnitGameplay2DScripts WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO UnitGameplay2DScripts SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- UnitPromotions_CivilianUnitType
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM UnitPromotions_CivilianUnitType WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO UnitPromotions_CivilianUnitType SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_AITypes
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_AITypes WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_AITypes SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_BuildingClassRequireds
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_BuildingClassRequireds WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_BuildingClassRequireds SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_Buildings
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_Buildings WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_Buildings SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_Builds
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_Builds WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_Builds SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_ClassUpgrades
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_ClassUpgrades WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_ClassUpgrades SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_Flavors
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_Flavors WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_Flavors SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_FreePromotions
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_FreePromotions WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_FreePromotions SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_GreatPersons
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_GreatPersons WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_GreatPersons SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_NotAITypes
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_NotAITypes WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_NotAITypes SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_ProductionModifierBuildings
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_ProductionModifierBuildings WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_ProductionModifierBuildings SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_ProductionTraits
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_ProductionTraits WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_ProductionTraits SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_ResourceQuantityRequirements
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_ResourceQuantityRequirements WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_ResourceQuantityRequirements SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_TechTypes
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_TechTypes WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_TechTypes SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

-- Unit_YieldFromKills
CREATE TEMP TABLE FilthyCompanionClone AS
 SELECT * FROM Unit_YieldFromKills WHERE UnitType IN (SELECT OldType FROM FilthyUnitMap);
UPDATE FilthyCompanionClone SET UnitType =
 (SELECT NewType FROM FilthyUnitMap WHERE OldType = FilthyCompanionClone.UnitType);
INSERT INTO Unit_YieldFromKills SELECT * FROM FilthyCompanionClone;
DROP TABLE FilthyCompanionClone;

DROP TABLE FilthyUnitMap;
DROP TABLE FilthyBuildingMap;
