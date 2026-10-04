-- Additional mechanics after copying active Scout/Monument companion tables.
DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_PSJ_STARTER_HOUSE' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges VALUES ('BUILDING_PSJ_STARTER_HOUSE','YIELD_CULTURE',2);
INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry,NeutralHealChange,EnemyHealChange) VALUES ('PROMOTION_PSJ_LEARNING','TXT_KEY_PSJ_LEARNING','TXT_KEY_PSJ_LEARNING_HELP',1,0,2,'PSJ_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_PSJ_LEARNING',5,5);
INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry,VisibilityChange,DefenseMod) VALUES ('PROMOTION_PSJ_BEGINNING','TXT_KEY_PSJ_BEGINNING','TXT_KEY_PSJ_BEGINNING_HELP',1,0,3,'PSJ_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_PSJ_BEGINNING',1,10);
INSERT INTO Unit_FreePromotions VALUES ('UNIT_PSJ_SURVIVOR','PROMOTION_PSJ_LEARNING');
INSERT INTO UnitPromotions_UnitCombats(PromotionType,UnitCombatType,PediaType) SELECT p.Type,c.Type,'PEDIA_ATTRIBUTES' FROM UnitPromotions p CROSS JOIN UnitCombatInfos c WHERE p.Type IN ('PROMOTION_PSJ_LEARNING','PROMOTION_PSJ_BEGINNING') AND c.Type IN ('UNITCOMBAT_RECON','UNITCOMBAT_ARCHER','UNITCOMBAT_MELEE','UNITCOMBAT_GUN');
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_PSJ_HOME_1','BUILDING_PSJ_HOME_1','TXT_KEY_PSJ_HOME_1');
INSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,IsDummy,ShowInPedia,UnmoddedHappiness) VALUES ('BUILDING_PSJ_HOME_1','BUILDINGCLASS_PSJ_HOME_1','TXT_KEY_PSJ_HOME_1',-1,-1,-1,1,1,0,1,0,1);
INSERT INTO Building_YieldChanges VALUES ('BUILDING_PSJ_HOME_1','YIELD_CULTURE',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_PSJ_HOME_2','BUILDING_PSJ_HOME_2','TXT_KEY_PSJ_HOME_2');
INSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,IsDummy,ShowInPedia,UnmoddedHappiness) VALUES ('BUILDING_PSJ_HOME_2','BUILDINGCLASS_PSJ_HOME_2','TXT_KEY_PSJ_HOME_2',-1,-1,-1,1,1,0,1,0,2);
INSERT INTO Building_YieldChanges VALUES ('BUILDING_PSJ_HOME_2','YIELD_CULTURE',2);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_PSJ_HOME_3','BUILDING_PSJ_HOME_3','TXT_KEY_PSJ_HOME_3');
INSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,ConquestProb,IsDummy,ShowInPedia,UnmoddedHappiness) VALUES ('BUILDING_PSJ_HOME_3','BUILDINGCLASS_PSJ_HOME_3','TXT_KEY_PSJ_HOME_3',-1,-1,-1,1,1,0,1,0,3);
INSERT INTO Building_YieldChanges VALUES ('BUILDING_PSJ_HOME_3','YIELD_CULTURE',3);
