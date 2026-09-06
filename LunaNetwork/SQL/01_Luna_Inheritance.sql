-- Clone BNW companion tables at activation, preserving all columns added by CP.
-- Empty source tables are safe. No hard-coded Food/Morale/GG/build prerequisites.
CREATE TEMP TABLE LunaUnitMap (OldType TEXT, NewType TEXT);
INSERT INTO LunaUnitMap VALUES
('UNIT_SETTLER', 'UNIT_LUNA_PACKET_SETTLER');
CREATE TEMP TABLE LunaBuildingMap (OldType TEXT, NewType TEXT);
INSERT INTO LunaBuildingMap VALUES
('BUILDING_LIBRARY', 'BUILDING_LUNA_CACHE_NODE');

-- Building_AreaYieldModifiers
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_AreaYieldModifiers WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_AreaYieldModifiers SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_BuildingClassHappiness
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_BuildingClassHappiness WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassHappiness SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_BuildingClassYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_BuildingClassYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_BuildingClassYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ClassesNeededInCity
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ClassesNeededInCity WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ClassesNeededInCity SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_DomainFreeExperiencePerGreatWork
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiencePerGreatWork WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiencePerGreatWork SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_DomainFreeExperiences
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_DomainFreeExperiences WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_DomainFreeExperiences SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_DomainProductionModifiers
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_DomainProductionModifiers WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_DomainProductionModifiers SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_FeatureYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_FeatureYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_FeatureYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_Flavors
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_Flavors WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_Flavors SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_FreeSpecialistCounts
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_FreeSpecialistCounts WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_FreeSpecialistCounts SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_FreeUnits
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_FreeUnits WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_FreeUnits SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_GlobalYieldModifiers
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_GlobalYieldModifiers WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_GlobalYieldModifiers SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_HurryModifiers
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_HurryModifiers WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_HurryModifiers SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_LakePlotYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_LakePlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_LakePlotYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_LocalResourceAnds
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_LocalResourceAnds WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceAnds SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_LocalResourceOrs
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_LocalResourceOrs WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_LocalResourceOrs SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_LockedBuildingClasses
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_LockedBuildingClasses WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_LockedBuildingClasses SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_PrereqBuildingClasses
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_PrereqBuildingClasses WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_PrereqBuildingClasses SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ResourceCultureChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ResourceCultureChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ResourceCultureChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ResourceFaithChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ResourceFaithChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ResourceFaithChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ResourceQuantity
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ResourceQuantity WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantity SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ResourceQuantityRequirements
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ResourceQuantityRequirements WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ResourceQuantityRequirements SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ResourceYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ResourceYieldModifiers
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ResourceYieldModifiers WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ResourceYieldModifiers SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_RiverPlotYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_RiverPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_RiverPlotYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_SeaPlotYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_SeaPlotYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_SeaPlotYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_SeaResourceYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_SeaResourceYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_SeaResourceYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_SpecialistYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_SpecialistYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_SpecialistYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_TechAndPrereqs
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_TechAndPrereqs WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_TechAndPrereqs SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_TechEnhancedYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_TechEnhancedYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_TechEnhancedYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_TerrainYieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_TerrainYieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_TerrainYieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_ThemingBonuses
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_ThemingBonuses WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_ThemingBonuses SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_UnitCombatFreeExperiences
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_UnitCombatFreeExperiences WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatFreeExperiences SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_UnitCombatProductionModifiers
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_UnitCombatProductionModifiers WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_UnitCombatProductionModifiers SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_YieldChanges
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_YieldChanges WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_YieldChanges SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_YieldChangesPerPop
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_YieldChangesPerPop WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerPop SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_YieldChangesPerReligion
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_YieldChangesPerReligion WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_YieldChangesPerReligion SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Building_YieldModifiers
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Building_YieldModifiers WHERE BuildingType IN (SELECT OldType FROM LunaBuildingMap);
UPDATE LunaCompanionClone SET BuildingType =
 (SELECT NewType FROM LunaBuildingMap WHERE OldType = LunaCompanionClone.BuildingType);
INSERT INTO Building_YieldModifiers SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- UnitGameplay2DScripts
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM UnitGameplay2DScripts WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO UnitGameplay2DScripts SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- UnitPromotions_CivilianUnitType
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM UnitPromotions_CivilianUnitType WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO UnitPromotions_CivilianUnitType SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_AITypes
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_AITypes WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_AITypes SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_BuildingClassRequireds
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_BuildingClassRequireds WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_BuildingClassRequireds SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_Buildings
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_Buildings WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_Buildings SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_Builds
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_Builds WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_Builds SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_ClassUpgrades
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_ClassUpgrades WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_ClassUpgrades SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_Flavors
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_Flavors WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_Flavors SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_FreePromotions
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_FreePromotions WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_FreePromotions SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_GreatPersons
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_GreatPersons WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_GreatPersons SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_NotAITypes
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_NotAITypes WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_NotAITypes SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_ProductionModifierBuildings
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_ProductionModifierBuildings WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_ProductionModifierBuildings SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_ProductionTraits
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_ProductionTraits WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_ProductionTraits SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_ResourceQuantityRequirements
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_ResourceQuantityRequirements WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_ResourceQuantityRequirements SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_TechTypes
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_TechTypes WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_TechTypes SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

-- Unit_YieldFromKills
CREATE TEMP TABLE LunaCompanionClone AS
 SELECT * FROM Unit_YieldFromKills WHERE UnitType IN (SELECT OldType FROM LunaUnitMap);
UPDATE LunaCompanionClone SET UnitType =
 (SELECT NewType FROM LunaUnitMap WHERE OldType = LunaCompanionClone.UnitType);
INSERT INTO Unit_YieldFromKills SELECT * FROM LunaCompanionClone;
DROP TABLE LunaCompanionClone;

DROP TABLE LunaUnitMap;
DROP TABLE LunaBuildingMap;

