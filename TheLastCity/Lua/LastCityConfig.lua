-- Global survival balance. Event templates/outcomes live alongside their
-- narrative modules; SQL-backed percentages are fixed in 02_LC_Effects.sql.
-- Time and lump costs scale; income does not.
local L=MapModData.TheLastCity
L.Config={Version=1,StartProvisions=45,Storage=200,StartMorale=65,Housing=12,
 BaseIncome=4,DistrictIncome=2,DistrictHousing=6,PopulationConsumption=.6,MilitaryConsumption=.4,
 ExpertCap=5,FarmerIncome=2,RefugeeMin=8,RefugeeMax=14,
 QuarantineTurns=3,RefugeeExpiry=6,PolicyCooldown=5,CrisisMin=9,CrisisMax=16,
 FirstWave=24,WaveMin=20,WaveMax=24,Warning=3,WaveTimeout=18,SpawnMin=4,SpawnMax=8,
 MaxEnemies=18,MajorEvery=5,MaxDefense=30,MaxVeteran=5,
 StarvePopulationAfter=4,HistoryLimit=90,Debug=false}
L.Skills={'ENGINEERS','SCIENTISTS','PHYSICIANS','VETERANS','FARMERS','SCHOLARS'}
L.Rations={
 GENEROUS={consumption=1.5,morale=.3,growth=15},STANDARD={consumption=1,morale=0,growth=0},
 STRICT={consumption=.75,morale=-.4,growth=-15},EMERGENCY={consumption=.5,morale=-.9,growth=-35}}
L.RationOrder={'GENEROUS','STANDARD','STRICT','EMERGENCY'}
L.Infrastructure={
 {key='BARRACKS',housing=4,cost=100,tech='TECH_MASONRY'},
 {key='RESIDENTIAL',housing=8,cost=220,tech='TECH_ENGINEERING'},
 {key='SHELTER',housing=10,cost=400,tech='TECH_DYNAMITE'},
 {key='HOSPITAL',medical=2,cost=300,tech='TECH_BIOLOGY'},
 {key='STORAGE',storage=75,cost=240,tech='TECH_METAL_CASTING'},
 {key='DEPOT',storage=100,cost=450,tech='TECH_RAILROAD'},
 {key='WATER',income=4,cost=300,tech='TECH_CHEMISTRY'},
 {key='DAWN',cost=900,tech='TECH_ATOMIC_THEORY'}}
L.EraForces={
 {name='SCAVENGERS',land={'UNIT_WARRIOR','UNIT_ARCHER','UNIT_WARRIOR','UNIT_SPEARMAN'},sea={'UNIT_TRIREME'}},
 {name='MARAUDERS',land={'UNIT_SWORDSMAN','UNIT_COMPOSITE_BOWMAN','UNIT_CATAPULT','UNIT_HORSEMAN'},sea={'UNIT_TRIREME','UNIT_GALLEASS'}},
 {name='CULTS',land={'UNIT_LONGSWORDSMAN','UNIT_CROSSBOWMAN','UNIT_TREBUCHET','UNIT_KNIGHT'},sea={'UNIT_CARAVEL','UNIT_GALLEASS'}},
 {name='PLAGUEBOUND',land={'UNIT_MUSKETMAN','UNIT_CROSSBOWMAN','UNIT_CANNON','UNIT_LANCER'},sea={'UNIT_PRIVATEER','UNIT_FRIGATE'}},
 {name='REAVERS',land={'UNIT_RIFLEMAN','UNIT_GATLINGGUN','UNIT_ARTILLERY','UNIT_CAVALRY'},sea={'UNIT_IRONCLAD','UNIT_FRIGATE'}},
 {name='REMNANTS',land={'UNIT_GREAT_WAR_INFANTRY','UNIT_MACHINE_GUN','UNIT_ARTILLERY','UNIT_LANDSHIP'},sea={'UNIT_DESTROYER','UNIT_BATTLESHIP'}},
 {name='HARBINGERS',land={'UNIT_INFANTRY','UNIT_BAZOOKA','UNIT_ARTILLERY','UNIT_TANK'},sea={'UNIT_DESTROYER','UNIT_BATTLESHIP'}},
 {name='HARBINGERS',land={'UNIT_MECHANIZED_INFANTRY','UNIT_BAZOOKA','UNIT_ROCKET_ARTILLERY','UNIT_MODERN_ARMOR'},sea={'UNIT_DESTROYER','UNIT_MISSILE_CRUISER'}}}
