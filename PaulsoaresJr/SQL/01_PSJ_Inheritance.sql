-- Clone BNW companion tables at activation, preserving all columns added by CP.
-- Empty source tables are safe. No hard-coded Food/Morale/GG/build prerequisites.
CREATE TEMP TABLE PSJUnitMap (OldType TEXT, NewType TEXT);
INSERT INTO PSJUnitMap VALUES
('UNIT_SCOUT', 'UNIT_PSJ_SURVIVOR');
CREATE TEMP TABLE PSJBuildingMap (OldType TEXT, NewType TEXT);
INSERT INTO PSJBuildingMap VALUES
('BUILDING_MONUMENT', 'BUILDING_PSJ_STARTER_HOUSE');

-- Building_AreaYieldModifiers
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_AreaYieldModifiers WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_AreaYieldModifiers SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_BuildingClassHappiness
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_BuildingClassHappiness WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassHappiness SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_BuildingClassYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_BuildingClassYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ClassesNeededInCity
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ClassesNeededInCity WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ClassesNeededInCity SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_DomainFreeExperiencePerGreatWork
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiencePerGreatWork WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiencePerGreatWork SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_DomainFreeExperiences
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiences WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiences SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_DomainProductionModifiers
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_DomainProductionModifiers WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_DomainProductionModifiers SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_FeatureYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_FeatureYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_FeatureYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_Flavors
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_Flavors WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_Flavors SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_FreeSpecialistCounts
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_FreeSpecialistCounts WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_FreeSpecialistCounts SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_FreeUnits
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_FreeUnits WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_FreeUnits SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_GlobalYieldModifiers
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_GlobalYieldModifiers WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_GlobalYieldModifiers SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_HurryModifiers
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_HurryModifiers WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_HurryModifiers SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_LakePlotYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_LakePlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_LakePlotYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_LocalResourceAnds
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_LocalResourceAnds WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceAnds SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_LocalResourceOrs
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_LocalResourceOrs WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceOrs SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_LockedBuildingClasses
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_LockedBuildingClasses WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_LockedBuildingClasses SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_PrereqBuildingClasses
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_PrereqBuildingClasses WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_PrereqBuildingClasses SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ResourceCultureChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ResourceCultureChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ResourceCultureChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ResourceFaithChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ResourceFaithChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ResourceFaithChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ResourceQuantity
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ResourceQuantity WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantity SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ResourceQuantityRequirements
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ResourceQuantityRequirements WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantityRequirements SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ResourceYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ResourceYieldModifiers
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ResourceYieldModifiers WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldModifiers SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_RiverPlotYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_RiverPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_RiverPlotYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_SeaPlotYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_SeaPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_SeaPlotYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_SeaResourceYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_SeaResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_SeaResourceYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_SpecialistYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_SpecialistYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_SpecialistYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_TechAndPrereqs
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_TechAndPrereqs WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_TechAndPrereqs SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_TechEnhancedYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_TechEnhancedYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_TechEnhancedYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_TerrainYieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_TerrainYieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_TerrainYieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_ThemingBonuses
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_ThemingBonuses WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_ThemingBonuses SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_UnitCombatFreeExperiences
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_UnitCombatFreeExperiences WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatFreeExperiences SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_UnitCombatProductionModifiers
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_UnitCombatProductionModifiers WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatProductionModifiers SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_YieldChanges
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_YieldChanges WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_YieldChanges SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_YieldChangesPerPop
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_YieldChangesPerPop WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerPop SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_YieldChangesPerReligion
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_YieldChangesPerReligion WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerReligion SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Building_YieldModifiers
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Building_YieldModifiers WHERE BuildingType IN (SELECT OldType FROM PSJBuildingMap);
UPDATE PSJCompanionClone SET BuildingType =
 (SELECT NewType FROM PSJBuildingMap WHERE OldType = PSJCompanionClone.BuildingType);
INSERT INTO Building_YieldModifiers SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- UnitGameplay2DScripts
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM UnitGameplay2DScripts WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO UnitGameplay2DScripts SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- UnitPromotions_CivilianUnitType
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM UnitPromotions_CivilianUnitType WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO UnitPromotions_CivilianUnitType SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_AITypes
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_AITypes WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_AITypes SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_BuildingClassRequireds
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_BuildingClassRequireds WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_BuildingClassRequireds SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_Buildings
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_Buildings WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_Buildings SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_Builds
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_Builds WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_Builds SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_ClassUpgrades
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_ClassUpgrades WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_ClassUpgrades SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_Flavors
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_Flavors WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_Flavors SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_FreePromotions
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_FreePromotions WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_FreePromotions SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_GreatPersons
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_GreatPersons WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_GreatPersons SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_NotAITypes
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_NotAITypes WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_NotAITypes SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_ProductionModifierBuildings
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_ProductionModifierBuildings WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_ProductionModifierBuildings SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_ProductionTraits
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_ProductionTraits WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_ProductionTraits SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_ResourceQuantityRequirements
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_ResourceQuantityRequirements WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_ResourceQuantityRequirements SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_TechTypes
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_TechTypes WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_TechTypes SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

-- Unit_YieldFromKills
CREATE TEMP TABLE PSJCompanionClone AS
 SELECT * FROM Unit_YieldFromKills WHERE UnitType IN (SELECT OldType FROM PSJUnitMap);
UPDATE PSJCompanionClone SET UnitType =
 (SELECT NewType FROM PSJUnitMap WHERE OldType = PSJCompanionClone.UnitType);
INSERT INTO Unit_YieldFromKills SELECT * FROM PSJCompanionClone;
DROP TABLE PSJCompanionClone;

DROP TABLE PSJUnitMap;
DROP TABLE PSJBuildingMap;


-- Community Patch companion effects, including currently empty tables.
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_PlotYieldChanges WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_PlotYieldChanges SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_GreatPersonProgressFromConstruction WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_GreatPersonProgressFromConstruction SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_GrowthExtraYield WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_GrowthExtraYield SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_InstantYield WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_InstantYield SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourceHappinessChange WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourceHappinessChange SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_DomainFreeExperiencePerGreatWorkCity WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_DomainFreeExperiencePerGreatWorkCity SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_DomainFreeExperiencePerGreatWorkGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_DomainFreeExperiencePerGreatWorkGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_DomainFreeExperiencesGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_DomainFreeExperiencesGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_UnitCombatProductionModifiersGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_UnitCombatProductionModifiersGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromYieldPercent WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromYieldPercent SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromYieldPercentGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromYieldPercentGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromTech WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromTech SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromConstruction WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromConstruction SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromSpyDefense WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromSpyDefense SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromSpyAttack WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromSpyAttack SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromSpyIdentify WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromSpyIdentify SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromSpyDefenseOrID WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromSpyDefenseOrID SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromSpyRigElection WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromSpyRigElection SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromInternationalTREnd WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromInternationalTREnd SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromInternalTREnd WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromInternalTREnd SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromProcessModifier WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromProcessModifier SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromInternalTR WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromInternalTR SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromDeath WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromDeath SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourcePlotsToPlace WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourcePlotsToPlace SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_BuildingClassYieldModifiers WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_BuildingClassYieldModifiers SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromVictory WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromVictory SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromVictoryGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromVictoryGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromVictoryGlobalPlayer WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromVictoryGlobalPlayer SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromBirth WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromBirth SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromBirthRetroactive WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromBirthRetroactive SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromUnitProduction WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromUnitProduction SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromBorderGrowth WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromBorderGrowth SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromPolicyUnlock WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromPolicyUnlock SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromPurchase WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromPurchase SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromFaithPurchase WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromFaithPurchase SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldPerXTerrainTimes100 WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldPerXTerrainTimes100 SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldPerXFeatureTimes100 WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldPerXFeatureTimes100 SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldPerXImprovementLocal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldPerXImprovementLocal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldPerXImprovementGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldPerXImprovementGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_HurryModifiersLocal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_HurryModifiersLocal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_SpecialistYieldChangesLocal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_SpecialistYieldChangesLocal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromGPExpend WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromGPExpend SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromPillage WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromPillage SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromPillageGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromPillageGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromPillageGlobalPlayer WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromPillageGlobalPlayer SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ThemingYieldBonus WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ThemingYieldBonus SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_GreatWorkYieldChanges WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_GreatWorkYieldChanges SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_GreatWorkYieldChangesLocal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_GreatWorkYieldChangesLocal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldPerFriendTimes100 WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldPerFriendTimes100 SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldPerAllyTimes100 WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldPerAllyTimes100 SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_WLTKDYieldMod WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_WLTKDYieldMod SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_GoldenAgeYieldMod WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_GoldenAgeYieldMod SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromUnitLevelUp WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromUnitLevelUp SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromUnitLevelUpGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromUnitLevelUpGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromCombatExperienceTimes100 WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromCombatExperienceTimes100 SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ClassNeededAnywhere WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ClassNeededAnywhere SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ClassNeededNowhere WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ClassNeededNowhere SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourceMonopolyOrs WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourceMonopolyOrs SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourceMonopolyAnds WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourceMonopolyAnds SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_LocalFeatureOrs WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_LocalFeatureOrs SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_LocalFeatureAnds WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_LocalFeatureAnds SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ImprovementYieldChanges WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ImprovementYieldChanges SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ImprovementYieldChangesGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ImprovementYieldChangesGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourceYieldChangesGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourceYieldChangesGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesPerPopInEmpire WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesPerPopInEmpire SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_BuildingClassLocalHappiness WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_BuildingClassLocalHappiness SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_BuildingClassLocalYieldChanges WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_BuildingClassLocalYieldChanges SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangeWorldWonder WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangeWorldWonder SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangeWorldWonderGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangeWorldWonderGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_SpecificGreatPersonRateModifier WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_SpecificGreatPersonRateModifier SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldPerFranchise WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldPerFranchise SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourceQuantityPerXFranchises WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourceQuantityPerXFranchises SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourceQuantityFromPOP WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourceQuantityFromPOP SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_FreeSpecUnits WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_FreeSpecUnits SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_UnitClassTrainingAllowed WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_UnitClassTrainingAllowed SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ResourceClaim WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ResourceClaim SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_LakePlotYieldChangesGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_LakePlotYieldChangesGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromGoldenAgeStart WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromGoldenAgeStart SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesPerGoldenAge WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesPerGoldenAge SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldModifiersFromDistanceToCapital WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldModifiersFromDistanceToCapital SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromPurchaseGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromPurchaseGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_GreatPersonPointFromConstruction WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_GreatPersonPointFromConstruction SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesPerLocalTheme WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesPerLocalTheme SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromUnitGiftGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromUnitGiftGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesPerCityStrengthTimes100 WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesPerCityStrengthTimes100 SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromLongCount WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromLongCount SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesEraScalingTimes100 WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesEraScalingTimes100 SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesPerXBuilding WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesPerXBuilding SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesPerXTiles WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesPerXTiles SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesFromXCityStateStrategicResource WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesFromXCityStateStrategicResource SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesPerMonopoly WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesPerMonopoly SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesFromPassingTR WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesFromPassingTR SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_LuxuryYieldChanges WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_LuxuryYieldChanges SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_CityConnectionPlotYieldChanges WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_CityConnectionPlotYieldChanges SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_CityConnectionPlotYieldChangesGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_CityConnectionPlotYieldChangesGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_InstantYieldFromWLTKDStart WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_InstantYieldFromWLTKDStart SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_WLTKDFromProject WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_WLTKDFromProject SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldChangesFromAccomplishments WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldChangesFromAccomplishments SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldModifiersFromAccomplishments WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldModifiersFromAccomplishments SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_BonusFromAccomplishments WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_BonusFromAccomplishments SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldModifiersEraScaling WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldModifiersEraScaling SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromGPBirthScaledWithWriterBulb WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromGPBirthScaledWithWriterBulb SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromGPBirthScaledWithArtistBulb WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromGPBirthScaledWithArtistBulb SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_YieldFromGPBirthScaledWithPerTurnYield WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_YieldFromGPBirthScaledWithPerTurnYield SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ExtraPlayerInstancesFromAccomplishments WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ExtraPlayerInstancesFromAccomplishments SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ReligionYieldFromFaithPurchasableBuildings WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ReligionYieldFromFaithPurchasableBuildings SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Building_ReligionYieldFromFaithPurchasableBuildingsGlobal WHERE BuildingType='BUILDING_MONUMENT';
UPDATE PSJCPClone SET BuildingType='BUILDING_PSJ_STARTER_HOUSE';
INSERT INTO Building_ReligionYieldFromFaithPurchasableBuildingsGlobal SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_YieldFromBarbarianKills WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_YieldFromBarbarianKills SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_YieldOnCompletion WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_YieldOnCompletion SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_Bounties WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_Bounties SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_BuildOnFound WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_BuildOnFound SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_BuildingClassPurchaseRequireds WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_BuildingClassPurchaseRequireds SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_EraCombatStrength WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_EraCombatStrength SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_EraCombatType WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_EraCombatType SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_EraUnitPromotions WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_EraUnitPromotions SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_ResourceQuantityExpended WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_ResourceQuantityExpended SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_ResourceQuantityTotals WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_ResourceQuantityTotals SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
CREATE TEMP TABLE PSJCPClone AS SELECT * FROM Unit_ScalingFromOwnedImprovements WHERE UnitType='UNIT_SCOUT';
UPDATE PSJCPClone SET UnitType='UNIT_PSJ_SURVIVOR';
INSERT INTO Unit_ScalingFromOwnedImprovements SELECT * FROM PSJCPClone;
DROP TABLE PSJCPClone;
