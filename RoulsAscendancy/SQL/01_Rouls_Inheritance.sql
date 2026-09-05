-- Clone BNW companion tables at activation, preserving all columns added by CP.
-- Empty source tables are safe. No hard-coded Food/Morale/GG/build prerequisites.
CREATE TEMP TABLE RoulsUnitMap (OldType TEXT, NewType TEXT);
INSERT INTO RoulsUnitMap VALUES
('UNIT_RIFLEMAN', 'UNIT_ROULS_HOLLOWHOUND'),
('UNIT_GREAT_GENERAL', 'UNIT_ROULS_MATRIARCH');
CREATE TEMP TABLE RoulsBuildingMap (OldType TEXT, NewType TEXT);
INSERT INTO RoulsBuildingMap VALUES
('BUILDING_HOSPITAL', 'BUILDING_ROULS_SOMATIC_LATTICE'),
('BUILDING_HEROIC_EPIC', 'BUILDING_ROULS_CHOIR_ETERNAL');

-- Building_AreaYieldModifiers
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_AreaYieldModifiers WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_AreaYieldModifiers SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_BuildingClassHappiness
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_BuildingClassHappiness WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassHappiness SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_BuildingClassYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_BuildingClassYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ClassesNeededInCity
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ClassesNeededInCity WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ClassesNeededInCity SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_DomainFreeExperiencePerGreatWork
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiencePerGreatWork WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiencePerGreatWork SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_DomainFreeExperiences
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiences WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiences SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_DomainProductionModifiers
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_DomainProductionModifiers WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_DomainProductionModifiers SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_FeatureYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_FeatureYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_FeatureYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_Flavors
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_Flavors WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_Flavors SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_FreeSpecialistCounts
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_FreeSpecialistCounts WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_FreeSpecialistCounts SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_FreeUnits
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_FreeUnits WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_FreeUnits SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_GlobalYieldModifiers
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_GlobalYieldModifiers WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_GlobalYieldModifiers SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_HurryModifiers
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_HurryModifiers WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_HurryModifiers SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_LakePlotYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_LakePlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_LakePlotYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_LocalResourceAnds
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_LocalResourceAnds WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceAnds SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_LocalResourceOrs
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_LocalResourceOrs WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceOrs SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_LockedBuildingClasses
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_LockedBuildingClasses WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_LockedBuildingClasses SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_PrereqBuildingClasses
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_PrereqBuildingClasses WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_PrereqBuildingClasses SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ResourceCultureChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ResourceCultureChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ResourceCultureChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ResourceFaithChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ResourceFaithChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ResourceFaithChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ResourceQuantity
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ResourceQuantity WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantity SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ResourceQuantityRequirements
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ResourceQuantityRequirements WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantityRequirements SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ResourceYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ResourceYieldModifiers
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ResourceYieldModifiers WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldModifiers SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_RiverPlotYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_RiverPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_RiverPlotYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_SeaPlotYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_SeaPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_SeaPlotYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_SeaResourceYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_SeaResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_SeaResourceYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_SpecialistYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_SpecialistYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_SpecialistYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_TechAndPrereqs
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_TechAndPrereqs WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_TechAndPrereqs SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_TechEnhancedYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_TechEnhancedYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_TechEnhancedYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_TerrainYieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_TerrainYieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_TerrainYieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_ThemingBonuses
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_ThemingBonuses WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_ThemingBonuses SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_UnitCombatFreeExperiences
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_UnitCombatFreeExperiences WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatFreeExperiences SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_UnitCombatProductionModifiers
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_UnitCombatProductionModifiers WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatProductionModifiers SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_YieldChanges
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_YieldChanges WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_YieldChanges SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_YieldChangesPerPop
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_YieldChangesPerPop WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerPop SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_YieldChangesPerReligion
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_YieldChangesPerReligion WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerReligion SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Building_YieldModifiers
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Building_YieldModifiers WHERE BuildingType IN (SELECT OldType FROM RoulsBuildingMap);
UPDATE RoulsCompanionClone SET BuildingType =
 (SELECT NewType FROM RoulsBuildingMap WHERE OldType = RoulsCompanionClone.BuildingType);
INSERT INTO Building_YieldModifiers SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- UnitGameplay2DScripts
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM UnitGameplay2DScripts WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO UnitGameplay2DScripts SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- UnitPromotions_CivilianUnitType
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM UnitPromotions_CivilianUnitType WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO UnitPromotions_CivilianUnitType SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_AITypes
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_AITypes WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_AITypes SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_BuildingClassRequireds
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_BuildingClassRequireds WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_BuildingClassRequireds SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_Buildings
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_Buildings WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_Buildings SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_Builds
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_Builds WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_Builds SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_ClassUpgrades
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_ClassUpgrades WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_ClassUpgrades SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_Flavors
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_Flavors WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_Flavors SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_FreePromotions
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_FreePromotions WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_FreePromotions SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_GreatPersons
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_GreatPersons WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_GreatPersons SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_NotAITypes
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_NotAITypes WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_NotAITypes SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_ProductionModifierBuildings
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_ProductionModifierBuildings WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_ProductionModifierBuildings SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_ProductionTraits
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_ProductionTraits WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_ProductionTraits SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_ResourceQuantityRequirements
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_ResourceQuantityRequirements WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_ResourceQuantityRequirements SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_TechTypes
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_TechTypes WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_TechTypes SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

-- Unit_YieldFromKills
CREATE TEMP TABLE RoulsCompanionClone AS
 SELECT * FROM Unit_YieldFromKills WHERE UnitType IN (SELECT OldType FROM RoulsUnitMap);
UPDATE RoulsCompanionClone SET UnitType =
 (SELECT NewType FROM RoulsUnitMap WHERE OldType = RoulsCompanionClone.UnitType);
INSERT INTO Unit_YieldFromKills SELECT * FROM RoulsCompanionClone;
DROP TABLE RoulsCompanionClone;

DROP TABLE RoulsUnitMap;
DROP TABLE RoulsBuildingMap;
