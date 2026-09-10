-- Clone BNW companion tables at activation, preserving all columns added by CP.
-- Empty source tables are safe. No hard-coded Food/Morale/GG/build prerequisites.
CREATE TEMP TABLE CapanoUnitMap (OldType TEXT, NewType TEXT);
INSERT INTO CapanoUnitMap VALUES
('UNIT_WORKER', 'UNIT_CAPANO_ROUTE_SETTER');
CREATE TEMP TABLE CapanoBuildingMap (OldType TEXT, NewType TEXT);
INSERT INTO CapanoBuildingMap VALUES
('BUILDING_ARMORY', 'BUILDING_CAPANO_COMPETITION_CENTRE');

-- Building_AreaYieldModifiers
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_AreaYieldModifiers WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_AreaYieldModifiers SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_BuildingClassHappiness
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_BuildingClassHappiness WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassHappiness SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_BuildingClassYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_BuildingClassYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ClassesNeededInCity
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ClassesNeededInCity WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ClassesNeededInCity SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_DomainFreeExperiencePerGreatWork
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiencePerGreatWork WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiencePerGreatWork SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_DomainFreeExperiences
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiences WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiences SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_DomainProductionModifiers
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_DomainProductionModifiers WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_DomainProductionModifiers SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_FeatureYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_FeatureYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_FeatureYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_Flavors
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_Flavors WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_Flavors SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_FreeSpecialistCounts
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_FreeSpecialistCounts WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_FreeSpecialistCounts SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_FreeUnits
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_FreeUnits WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_FreeUnits SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_GlobalYieldModifiers
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_GlobalYieldModifiers WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_GlobalYieldModifiers SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_HurryModifiers
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_HurryModifiers WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_HurryModifiers SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_LakePlotYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_LakePlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_LakePlotYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_LocalResourceAnds
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_LocalResourceAnds WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceAnds SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_LocalResourceOrs
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_LocalResourceOrs WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceOrs SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_LockedBuildingClasses
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_LockedBuildingClasses WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_LockedBuildingClasses SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_PrereqBuildingClasses
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_PrereqBuildingClasses WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_PrereqBuildingClasses SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ResourceCultureChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ResourceCultureChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ResourceCultureChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ResourceFaithChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ResourceFaithChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ResourceFaithChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ResourceQuantity
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ResourceQuantity WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantity SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ResourceQuantityRequirements
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ResourceQuantityRequirements WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantityRequirements SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ResourceYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ResourceYieldModifiers
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ResourceYieldModifiers WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldModifiers SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_RiverPlotYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_RiverPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_RiverPlotYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_SeaPlotYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_SeaPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_SeaPlotYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_SeaResourceYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_SeaResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_SeaResourceYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_SpecialistYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_SpecialistYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_SpecialistYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_TechAndPrereqs
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_TechAndPrereqs WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_TechAndPrereqs SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_TechEnhancedYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_TechEnhancedYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_TechEnhancedYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_TerrainYieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_TerrainYieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_TerrainYieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_ThemingBonuses
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_ThemingBonuses WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_ThemingBonuses SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_UnitCombatFreeExperiences
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_UnitCombatFreeExperiences WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatFreeExperiences SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_UnitCombatProductionModifiers
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_UnitCombatProductionModifiers WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatProductionModifiers SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_YieldChanges
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_YieldChanges WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_YieldChanges SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_YieldChangesPerPop
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_YieldChangesPerPop WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerPop SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_YieldChangesPerReligion
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_YieldChangesPerReligion WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerReligion SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Building_YieldModifiers
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Building_YieldModifiers WHERE BuildingType IN (SELECT OldType FROM CapanoBuildingMap);
UPDATE CapanoCompanionClone SET BuildingType =
 (SELECT NewType FROM CapanoBuildingMap WHERE OldType = CapanoCompanionClone.BuildingType);
INSERT INTO Building_YieldModifiers SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- UnitGameplay2DScripts
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM UnitGameplay2DScripts WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO UnitGameplay2DScripts SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- UnitPromotions_CivilianUnitType
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM UnitPromotions_CivilianUnitType WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO UnitPromotions_CivilianUnitType SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_AITypes
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_AITypes WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_AITypes SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_BuildingClassRequireds
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_BuildingClassRequireds WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_BuildingClassRequireds SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_Buildings
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_Buildings WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_Buildings SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_Builds
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_Builds WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_Builds SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_ClassUpgrades
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_ClassUpgrades WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_ClassUpgrades SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_Flavors
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_Flavors WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_Flavors SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_FreePromotions
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_FreePromotions WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_FreePromotions SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_GreatPersons
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_GreatPersons WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_GreatPersons SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_NotAITypes
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_NotAITypes WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_NotAITypes SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_ProductionModifierBuildings
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_ProductionModifierBuildings WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_ProductionModifierBuildings SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_ProductionTraits
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_ProductionTraits WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_ProductionTraits SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_ResourceQuantityRequirements
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_ResourceQuantityRequirements WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_ResourceQuantityRequirements SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_TechTypes
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_TechTypes WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_TechTypes SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

-- Unit_YieldFromKills
CREATE TEMP TABLE CapanoCompanionClone AS
 SELECT * FROM Unit_YieldFromKills WHERE UnitType IN (SELECT OldType FROM CapanoUnitMap);
UPDATE CapanoCompanionClone SET UnitType =
 (SELECT NewType FROM CapanoUnitMap WHERE OldType = CapanoCompanionClone.UnitType);
INSERT INTO Unit_YieldFromKills SELECT * FROM CapanoCompanionClone;
DROP TABLE CapanoCompanionClone;

DROP TABLE CapanoUnitMap;
DROP TABLE CapanoBuildingMap;


-- Community Patch companion effects, including currently empty tables.
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_PlotYieldChanges WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_PlotYieldChanges SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_GreatPersonProgressFromConstruction WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_GreatPersonProgressFromConstruction SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_GrowthExtraYield WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_GrowthExtraYield SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_InstantYield WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_InstantYield SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourceHappinessChange WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourceHappinessChange SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_DomainFreeExperiencePerGreatWorkCity WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_DomainFreeExperiencePerGreatWorkCity SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_DomainFreeExperiencePerGreatWorkGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_DomainFreeExperiencePerGreatWorkGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_DomainFreeExperiencesGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_DomainFreeExperiencesGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_UnitCombatProductionModifiersGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_UnitCombatProductionModifiersGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromYieldPercent WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromYieldPercent SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromYieldPercentGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromYieldPercentGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromTech WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromTech SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromConstruction WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromConstruction SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromSpyDefense WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromSpyDefense SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromSpyAttack WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromSpyAttack SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromSpyIdentify WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromSpyIdentify SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromSpyDefenseOrID WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromSpyDefenseOrID SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromSpyRigElection WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromSpyRigElection SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromInternationalTREnd WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromInternationalTREnd SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromInternalTREnd WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromInternalTREnd SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromProcessModifier WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromProcessModifier SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromInternalTR WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromInternalTR SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromDeath WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromDeath SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourcePlotsToPlace WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourcePlotsToPlace SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_BuildingClassYieldModifiers WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_BuildingClassYieldModifiers SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromVictory WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromVictory SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromVictoryGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromVictoryGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromVictoryGlobalPlayer WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromVictoryGlobalPlayer SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromBirth WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromBirth SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromBirthRetroactive WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromBirthRetroactive SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromUnitProduction WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromUnitProduction SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromBorderGrowth WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromBorderGrowth SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromPolicyUnlock WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromPolicyUnlock SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromPurchase WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromPurchase SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromFaithPurchase WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromFaithPurchase SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldPerXTerrainTimes100 WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldPerXTerrainTimes100 SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldPerXFeatureTimes100 WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldPerXFeatureTimes100 SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldPerXImprovementLocal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldPerXImprovementLocal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldPerXImprovementGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldPerXImprovementGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_HurryModifiersLocal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_HurryModifiersLocal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_SpecialistYieldChangesLocal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_SpecialistYieldChangesLocal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromGPExpend WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromGPExpend SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromPillage WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromPillage SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromPillageGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromPillageGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromPillageGlobalPlayer WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromPillageGlobalPlayer SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ThemingYieldBonus WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ThemingYieldBonus SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_GreatWorkYieldChanges WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_GreatWorkYieldChanges SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_GreatWorkYieldChangesLocal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_GreatWorkYieldChangesLocal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldPerFriendTimes100 WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldPerFriendTimes100 SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldPerAllyTimes100 WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldPerAllyTimes100 SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_WLTKDYieldMod WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_WLTKDYieldMod SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_GoldenAgeYieldMod WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_GoldenAgeYieldMod SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromUnitLevelUp WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromUnitLevelUp SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromUnitLevelUpGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromUnitLevelUpGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromCombatExperienceTimes100 WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromCombatExperienceTimes100 SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ClassNeededAnywhere WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ClassNeededAnywhere SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ClassNeededNowhere WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ClassNeededNowhere SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourceMonopolyOrs WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourceMonopolyOrs SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourceMonopolyAnds WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourceMonopolyAnds SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_LocalFeatureOrs WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_LocalFeatureOrs SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_LocalFeatureAnds WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_LocalFeatureAnds SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ImprovementYieldChanges WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ImprovementYieldChanges SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ImprovementYieldChangesGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ImprovementYieldChangesGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourceYieldChangesGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourceYieldChangesGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesPerPopInEmpire WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesPerPopInEmpire SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_BuildingClassLocalHappiness WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_BuildingClassLocalHappiness SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_BuildingClassLocalYieldChanges WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_BuildingClassLocalYieldChanges SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangeWorldWonder WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangeWorldWonder SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangeWorldWonderGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangeWorldWonderGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_SpecificGreatPersonRateModifier WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_SpecificGreatPersonRateModifier SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldPerFranchise WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldPerFranchise SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourceQuantityPerXFranchises WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourceQuantityPerXFranchises SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourceQuantityFromPOP WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourceQuantityFromPOP SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_FreeSpecUnits WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_FreeSpecUnits SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_UnitClassTrainingAllowed WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_UnitClassTrainingAllowed SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ResourceClaim WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ResourceClaim SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_LakePlotYieldChangesGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_LakePlotYieldChangesGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromGoldenAgeStart WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromGoldenAgeStart SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesPerGoldenAge WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesPerGoldenAge SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldModifiersFromDistanceToCapital WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldModifiersFromDistanceToCapital SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromPurchaseGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromPurchaseGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_GreatPersonPointFromConstruction WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_GreatPersonPointFromConstruction SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesPerLocalTheme WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesPerLocalTheme SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromUnitGiftGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromUnitGiftGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesPerCityStrengthTimes100 WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesPerCityStrengthTimes100 SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromLongCount WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromLongCount SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesEraScalingTimes100 WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesEraScalingTimes100 SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesPerXBuilding WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesPerXBuilding SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesPerXTiles WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesPerXTiles SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesFromXCityStateStrategicResource WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesFromXCityStateStrategicResource SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesPerMonopoly WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesPerMonopoly SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesFromPassingTR WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesFromPassingTR SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_LuxuryYieldChanges WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_LuxuryYieldChanges SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_CityConnectionPlotYieldChanges WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_CityConnectionPlotYieldChanges SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_CityConnectionPlotYieldChangesGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_CityConnectionPlotYieldChangesGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_InstantYieldFromWLTKDStart WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_InstantYieldFromWLTKDStart SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_WLTKDFromProject WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_WLTKDFromProject SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldChangesFromAccomplishments WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldChangesFromAccomplishments SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldModifiersFromAccomplishments WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldModifiersFromAccomplishments SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_BonusFromAccomplishments WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_BonusFromAccomplishments SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldModifiersEraScaling WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldModifiersEraScaling SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromGPBirthScaledWithWriterBulb WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromGPBirthScaledWithWriterBulb SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromGPBirthScaledWithArtistBulb WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromGPBirthScaledWithArtistBulb SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_YieldFromGPBirthScaledWithPerTurnYield WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_YieldFromGPBirthScaledWithPerTurnYield SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ExtraPlayerInstancesFromAccomplishments WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ExtraPlayerInstancesFromAccomplishments SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ReligionYieldFromFaithPurchasableBuildings WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ReligionYieldFromFaithPurchasableBuildings SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ReligionYieldFromFaithPurchasableBuildingsGlobal WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ReligionYieldFromFaithPurchasableBuildingsGlobal SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Building_ThemingBonuses_new WHERE BuildingType='BUILDING_ARMORY';
UPDATE CapanoCPClone SET BuildingType='BUILDING_CAPANO_COMPETITION_CENTRE';
INSERT INTO Building_ThemingBonuses_new SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_YieldFromBarbarianKills WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_YieldFromBarbarianKills SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_YieldOnCompletion WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_YieldOnCompletion SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_Bounties WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_Bounties SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_BuildOnFound WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_BuildOnFound SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_BuildingClassPurchaseRequireds WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_BuildingClassPurchaseRequireds SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_EraCombatStrength WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_EraCombatStrength SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_EraCombatType WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_EraCombatType SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_EraUnitPromotions WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_EraUnitPromotions SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_ResourceQuantityExpended WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_ResourceQuantityExpended SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_ResourceQuantityTotals WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_ResourceQuantityTotals SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
CREATE TEMP TABLE CapanoCPClone AS SELECT * FROM Unit_ScalingFromOwnedImprovements WHERE UnitType='UNIT_WORKER';
UPDATE CapanoCPClone SET UnitType='UNIT_CAPANO_ROUTE_SETTER';
INSERT INTO Unit_ScalingFromOwnedImprovements SELECT * FROM CapanoCPClone;
DROP TABLE CapanoCPClone;
